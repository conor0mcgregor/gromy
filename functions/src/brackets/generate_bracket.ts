import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {Firestore, getFirestore} from "firebase-admin/firestore";

type ParticipantEntityType = "user" | "team";

interface ParticipantData {
  id: string;
  entityId: string;
  entityType: ParticipantEntityType;
  categoryId?: string | null;
  enrolledAt?: admin.firestore.Timestamp;
}

interface ParticipantInfo {
  name: string;
  photoUrl: string | null;
  entityType: ParticipantEntityType;
  memberIds: string[];
  memberNames: string[];
}

interface MatchSeed {
  id: string;
  round: number;
  matchOrder: number;
  childMatchId: string | null;
  positionInChild: number | null;
}

export interface BracketDocument {
  id: string;
  tournamentId: string;
  status: "draft" | "published" | "active" | "completed" | "cancelled";
  format: "singleElimination";
  totalRounds: number;
  totalMatches: number;
  participantCount: number;
  categoryId: string | null;
  categoryName: string | null;
  tournamentName: string | null;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  publishedAt: admin.firestore.Timestamp | null;
  completedAt: admin.firestore.Timestamp | null;
}

interface GenerationOptions {
  tournamentId: string;
  categoryId?: string | null;
}

export const generateBracket = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesion.");
  }

  const {tournamentId, categoryId} = request.data as GenerationOptions;
  if (!tournamentId) {
    throw new HttpsError("invalid-argument", "tournamentId es obligatorio.");
  }

  const db = getFirestore("gromy-db");
  const tournament = await getTournamentOrFail(db, tournamentId);
  assertTournamentAdmin(tournament, request.auth.uid);

  const generated = await generateSingleEliminationBrackets(db, {
    tournamentId,
    categoryId: categoryId ?? null,
  });

  return generated[0];
});

export async function generateSingleEliminationBrackets(
  db: Firestore,
  options: GenerationOptions,
): Promise<BracketDocument[]> {
  const tournament = await getTournamentOrFail(db, options.tournamentId);
  const categories = normalizeCategories(tournament.categories);
  const targetCategories = resolveTargetCategories(
    categories,
    options.categoryId ?? null,
  );
  const existingSnap = await db
    .collection("brackets")
    .where("tournamentId", "==", options.tournamentId)
    .get();

  for (const categoryId of targetCategories) {
    for (const doc of existingSnap.docs) {
      const data = doc.data();
      if (!sameCategory(data.categoryId ?? null, categoryId)) continue;
      if (data.status !== "draft") {
        throw new HttpsError(
          "failed-precondition",
          "Ya existe un bracket publicado para esta categoria."
        );
      }
    }
  }

  const participantsByCategory = new Map<string, ParticipantData[]>();
  for (const categoryId of targetCategories) {
    const participants = await readApprovedParticipants(
      db,
      options.tournamentId,
      categoryId,
    );
    if (participants.length >= 2) {
      assertNoDuplicateParticipants(participants, categoryId);
      participantsByCategory.set(categoryKey(categoryId), participants);
    }
  }

  if (participantsByCategory.size === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Se necesitan al menos 2 participantes aprobados por bracket."
    );
  }

  for (const doc of existingSnap.docs) {
    const data = doc.data();
    if (
      targetCategories.some((categoryId) =>
        sameCategory(data.categoryId ?? null, categoryId)
      ) &&
      data.status === "draft"
    ) {
      await deleteBracketDraft(db, doc.ref);
    }
  }

  const generated: BracketDocument[] = [];
  for (const categoryId of targetCategories) {
    const participants = participantsByCategory.get(categoryKey(categoryId));
    if (!participants) continue;

    const bracket = await createSingleEliminationBracket({
      db,
      tournamentId: options.tournamentId,
      tournament,
      categoryId,
      participants,
    });
    generated.push(bracket);
  }

  return generated;
}

async function createSingleEliminationBracket(params: {
  db: Firestore;
  tournamentId: string;
  tournament: FirebaseFirestore.DocumentData;
  categoryId: string | null;
  participants: ParticipantData[];
}): Promise<BracketDocument> {
  const {db, tournamentId, tournament, categoryId} = params;
  const participants = [...params.participants].sort((a, b) => {
    const aTime = a.enrolledAt?.toMillis?.() ?? 0;
    const bTime = b.enrolledAt?.toMillis?.() ?? 0;
    return aTime - bTime;
  });

  const participantCount = participants.length;
  const totalSlots = nextPowerOf2(participantCount);
  const totalRounds = Math.log2(totalSlots);
  const bracketRef = db.collection("brackets").doc();
  const now = admin.firestore.Timestamp.now();
  const categoryName = categoryId;
  const participantInfo = await resolveParticipantInfo(db, participants);
  const slots = buildSeededSlots(participants, totalSlots);
  const allMatchSeeds = buildMatchSeeds(db, bracketRef.id, totalSlots);

  const bracketData: BracketDocument = {
    id: bracketRef.id,
    tournamentId,
    status: "draft",
    format: "singleElimination",
    totalRounds,
    totalMatches: totalSlots - 1,
    participantCount,
    categoryId,
    categoryName,
    tournamentName: tournament.name ?? null,
    createdAt: now,
    updatedAt: now,
    publishedAt: null,
    completedAt: null,
  };

  await writeBracketAndMatches({
    db,
    bracketRef,
    bracketData,
    allMatchSeeds,
    slots,
    participantInfo,
    categoryId,
    now,
  });

  await propagateAutomaticWinners(db, bracketRef.id);

  console.log(
    `Bracket generado: ${bracketRef.id} ` +
      `(${participantCount} participantes, ${totalRounds} rounds)`
  );

  return bracketData;
}

async function writeBracketAndMatches(params: {
  db: Firestore;
  bracketRef: FirebaseFirestore.DocumentReference;
  bracketData: BracketDocument;
  allMatchSeeds: MatchSeed[][];
  slots: Array<string | null>;
  participantInfo: Map<string, ParticipantInfo>;
  categoryId: string | null;
  now: admin.firestore.Timestamp;
}): Promise<void> {
  const {
    db,
    bracketRef,
    bracketData,
    allMatchSeeds,
    slots,
    participantInfo,
    categoryId,
    now,
  } = params;
  const batchLimit = 450;
  let batch = db.batch();
  let opCount = 0;

  batch.set(bracketRef, bracketData);
  opCount++;

  for (let round = 0; round < allMatchSeeds.length; round++) {
    for (const seed of allMatchSeeds[round]) {
      const matchRef = bracketRef.collection("matches").doc(seed.id);
      const parents = getParentMatchIds(allMatchSeeds, round, seed.matchOrder);
      const firstRoundSlots = getFirstRoundParticipants(seed, round, slots);
      const p1Info = firstRoundSlots.p1Id ?
        participantInfo.get(firstRoundSlots.p1Id) :
        undefined;
      const p2Info = firstRoundSlots.p2Id ?
        participantInfo.get(firstRoundSlots.p2Id) :
        undefined;
      const byeWinnerId = getByeWinnerId(
        firstRoundSlots.p1Id,
        firstRoundSlots.p2Id,
      );
      const status = byeWinnerId ? "bye" : "pending";

      batch.set(matchRef, {
        id: seed.id,
        bracketId: bracketRef.id,
        round: seed.round,
        matchOrder: seed.matchOrder,
        status,
        participant1Id: firstRoundSlots.p1Id,
        participant2Id: firstRoundSlots.p2Id,
        participant1Type: p1Info?.entityType ?? null,
        participant2Type: p2Info?.entityType ?? null,
        participant1Name: p1Info?.name ?? null,
        participant2Name: p2Info?.name ?? null,
        participant1PhotoUrl: p1Info?.photoUrl ?? null,
        participant2PhotoUrl: p2Info?.photoUrl ?? null,
        participant1MemberIds: p1Info?.memberIds ?? [],
        participant2MemberIds: p2Info?.memberIds ?? [],
        participant1MemberNames: p1Info?.memberNames ?? [],
        participant2MemberNames: p2Info?.memberNames ?? [],
        winnerId: byeWinnerId,
        loserId: null,
        parentMatch1Id: parents.parentMatch1Id,
        parentMatch2Id: parents.parentMatch2Id,
        childMatchId: seed.childMatchId,
        scheduledAt: null,
        startedAt: null,
        completedAt: byeWinnerId ? now : null,
        scoreParticipant1: null,
        scoreParticipant2: null,
        positionInChild: seed.positionInChild,
        categoryId,
      });
      opCount++;

      if (opCount >= batchLimit) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }
}

function buildMatchSeeds(
  db: Firestore,
  bracketId: string,
  totalSlots: number,
): MatchSeed[][] {
  const totalRounds = Math.log2(totalSlots);
  const allMatchSeeds: MatchSeed[][] = [];

  for (let round = 0; round < totalRounds; round++) {
    const matchesInRound = totalSlots / Math.pow(2, round + 1);
    const roundSeeds: MatchSeed[] = [];

    for (let order = 0; order < matchesInRound; order++) {
      const matchRef = db
        .collection("brackets")
        .doc(bracketId)
        .collection("matches")
        .doc();

      roundSeeds.push({
        id: matchRef.id,
        round,
        matchOrder: order,
        childMatchId: null,
        positionInChild: null,
      });
    }
    allMatchSeeds.push(roundSeeds);
  }

  for (let round = 0; round < totalRounds - 1; round++) {
    const currentRound = allMatchSeeds[round];
    const nextRound = allMatchSeeds[round + 1];

    for (let i = 0; i < currentRound.length; i++) {
      const childIndex = Math.floor(i / 2);
      currentRound[i].childMatchId = nextRound[childIndex].id;
      currentRound[i].positionInChild = (i % 2) + 1;
    }
  }

  return allMatchSeeds;
}

function buildSeededSlots(
  participants: ParticipantData[],
  totalSlots: number,
): Array<string | null> {
  const seedPositions = seededPositions(totalSlots);
  return seedPositions.map((seedNumber) => {
    const participant = participants[seedNumber - 1];
    return participant?.entityId ?? null;
  });
}

function seededPositions(size: number): number[] {
  let positions = [1, 2];
  while (positions.length < size) {
    const mirror = positions.length * 2 + 1;
    positions = positions.flatMap((seed) => [seed, mirror - seed]);
  }
  return positions.slice(0, size);
}

function getFirstRoundParticipants(
  seed: MatchSeed,
  round: number,
  slots: Array<string | null>,
): {p1Id: string | null; p2Id: string | null} {
  if (round !== 0) return {p1Id: null, p2Id: null};
  const slotIndex1 = seed.matchOrder * 2;
  const slotIndex2 = seed.matchOrder * 2 + 1;
  return {
    p1Id: slots[slotIndex1] ?? null,
    p2Id: slots[slotIndex2] ?? null,
  };
}

function getParentMatchIds(
  allMatchSeeds: MatchSeed[][],
  round: number,
  matchOrder: number,
): {parentMatch1Id: string | null; parentMatch2Id: string | null} {
  if (round === 0) {
    return {parentMatch1Id: null, parentMatch2Id: null};
  }

  const prevRound = allMatchSeeds[round - 1];
  const parent1Index = matchOrder * 2;
  const parent2Index = matchOrder * 2 + 1;
  return {
    parentMatch1Id: prevRound[parent1Index]?.id ?? null,
    parentMatch2Id: prevRound[parent2Index]?.id ?? null,
  };
}

function getByeWinnerId(
  participant1Id: string | null,
  participant2Id: string | null,
): string | null {
  if (participant1Id && !participant2Id) return participant1Id;
  if (!participant1Id && participant2Id) return participant2Id;
  return null;
}

async function propagateAutomaticWinners(
  db: Firestore,
  bracketId: string,
): Promise<void> {
  const byeMatchesSnap = await db
    .collection("brackets")
    .doc(bracketId)
    .collection("matches")
    .where("status", "==", "bye")
    .get();

  for (const byeDoc of byeMatchesSnap.docs) {
    const byeData = byeDoc.data();
    const winnerId = byeData.winnerId as string | undefined;
    const childMatchId = byeData.childMatchId as string | undefined;
    const positionInChild = byeData.positionInChild as number | undefined;
    if (!winnerId || !childMatchId || !positionInChild) continue;

    const childRef = db
      .collection("brackets")
      .doc(bracketId)
      .collection("matches")
      .doc(childMatchId);
    const prefix = positionInChild === 1 ? "participant1" : "participant2";
    const winnerPrefix = winnerId === byeData.participant1Id ?
      "participant1" :
      "participant2";

    await childRef.update({
      [`${prefix}Id`]: winnerId,
      [`${prefix}Type`]: byeData[`${winnerPrefix}Type`] ?? null,
      [`${prefix}Name`]: byeData[`${winnerPrefix}Name`] ?? null,
      [`${prefix}PhotoUrl`]: byeData[`${winnerPrefix}PhotoUrl`] ?? null,
      [`${prefix}MemberIds`]: byeData[`${winnerPrefix}MemberIds`] ?? [],
      [`${prefix}MemberNames`]: byeData[`${winnerPrefix}MemberNames`] ?? [],
    });
  }
}

async function resolveParticipantInfo(
  db: Firestore,
  participants: ParticipantData[],
): Promise<Map<string, ParticipantInfo>> {
  const info = new Map<string, ParticipantInfo>();

  for (const participant of participants) {
    if (participant.entityType === "team") {
      const teamDoc = await db
        .collection("teams")
        .doc(participant.entityId)
        .get();
      const teamData = teamDoc.data() ?? {};
      const memberIds = normalizeStringList(teamData.members);
      info.set(participant.entityId, {
        name: teamData.name ?? "Equipo",
        photoUrl: teamData.photoUrl ?? null,
        entityType: "team",
        memberIds,
        memberNames: await resolveUserNames(db, memberIds),
      });
      continue;
    }

    const userDoc = await db
      .collection("users")
      .doc(participant.entityId)
      .get();
    const userData = userDoc.data() ?? {};
    info.set(participant.entityId, {
      name: userDisplayName(userData),
      photoUrl: userData.photoUrl ?? null,
      entityType: "user",
      memberIds: [],
      memberNames: [],
    });
  }

  return info;
}

async function resolveUserNames(
  db: Firestore,
  userIds: string[],
): Promise<string[]> {
  const names: string[] = [];
  for (const uid of userIds) {
    const userDoc = await db.collection("users").doc(uid).get();
    names.push(userDisplayName(userDoc.data() ?? {}));
  }
  return names;
}

function userDisplayName(userData: FirebaseFirestore.DocumentData): string {
  const fullName = `${userData.name ?? ""} ${userData.lastName ?? ""}`.trim();
  return fullName || userData.nickname || userData.email || "Participante";
}

async function readApprovedParticipants(
  db: Firestore,
  tournamentId: string,
  categoryId: string | null,
): Promise<ParticipantData[]> {
  const tournamentRefs = await getTournamentRefsForParticipants(db, tournamentId);
  const participantDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];
  for (const tournamentRef of tournamentRefs) {
    const participantsSnap = await tournamentRef
      .collection("participants")
      .where("status", "in", ["approved", "active"])
      .get();
    participantDocs.push(...participantsSnap.docs);
  }

  const byId = new Map<string, ParticipantData>();
  participantDocs
    .map((doc) => ({...doc.data(), id: doc.id} as ParticipantData))
    .filter((participant) =>
      categoryId === null ?
        !participant.categoryId :
        participant.categoryId === categoryId
    )
    .forEach((participant) => byId.set(participant.id, participant));
  return [...byId.values()];
}

function assertNoDuplicateParticipants(
  participants: ParticipantData[],
  categoryId: string | null,
): void {
  const seen = new Set<string>();
  for (const participant of participants) {
    if (seen.has(participant.entityId)) {
      throw new HttpsError(
        "failed-precondition",
        `Participante duplicado en ${categoryId ?? "bracket"}: ` +
          participant.entityId
      );
    }
    seen.add(participant.entityId);
  }
}

async function getTournamentOrFail(
  db: Firestore,
  tournamentId: string,
): Promise<FirebaseFirestore.DocumentData> {
  const tournamentDoc = await getTournamentRefOrFail(db, tournamentId).then(
    (ref) => ref.get()
  );
  const data = tournamentDoc.data();
  if (!data) {
    throw new HttpsError("not-found", "Torneo no encontrado.");
  }
  return data;
}

async function getTournamentRefOrFail(
  db: Firestore,
  tournamentId: string,
): Promise<FirebaseFirestore.DocumentReference> {
  const publicRef = db.collection("tournaments").doc(tournamentId);
  const publicDoc = await publicRef.get();
  if (publicDoc.exists) return publicRef;

  const privateRef = db.collection("private_tournaments").doc(tournamentId);
  const privateDoc = await privateRef.get();
  if (privateDoc.exists) return privateRef;

  throw new HttpsError("not-found", "Torneo no encontrado.");
}

async function getTournamentRefsForParticipants(
  db: Firestore,
  tournamentId: string,
): Promise<FirebaseFirestore.DocumentReference[]> {
  const privateRef = db.collection("private_tournaments").doc(tournamentId);
  const privateDoc = await privateRef.get();
  if (privateDoc.exists) {
    return [privateRef, db.collection("tournaments").doc(tournamentId)];
  }
  return [await getTournamentRefOrFail(db, tournamentId)];
}

function assertTournamentAdmin(
  tournament: FirebaseFirestore.DocumentData,
  uid: string,
): void {
  const adminIds = normalizeStringList(tournament.adminIds);
  if (tournament.organizerUid !== uid && !adminIds.includes(uid)) {
    throw new HttpsError(
      "permission-denied",
      "No tienes permisos de administrador en este torneo."
    );
  }
}

function normalizeCategories(value: unknown): string[] {
  return normalizeStringList(value).filter((category) => category.length > 0);
}

function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item)).filter((item) => item.length > 0);
}

function resolveTargetCategories(
  categories: string[],
  requestedCategoryId: string | null,
): Array<string | null> {
  if (requestedCategoryId) {
    if (categories.length > 0 && !categories.includes(requestedCategoryId)) {
      throw new HttpsError(
        "invalid-argument",
        "La categoria indicada no pertenece al torneo."
      );
    }
    return [requestedCategoryId];
  }

  return categories.length > 0 ? categories : [null];
}

function sameCategory(
  left: string | null,
  right: string | null,
): boolean {
  return (left ?? null) === (right ?? null);
}

function categoryKey(categoryId: string | null): string {
  return categoryId ?? "__default__";
}

async function deleteBracketDraft(
  db: Firestore,
  bracketRef: FirebaseFirestore.DocumentReference,
): Promise<void> {
  await deleteCollectionInBatches(bracketRef.collection("matches"), db);
  await bracketRef.delete();
}

async function deleteCollectionInBatches(
  query: FirebaseFirestore.Query,
  db: Firestore,
): Promise<void> {
  const batchSize = 450;
  let moreDocs = true;
  while (moreDocs) {
    const snapshot = await query.limit(batchSize).get();
    if (snapshot.empty) {
      moreDocs = false;
    } else {
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  }
}

function nextPowerOf2(n: number): number {
  let power = 1;
  while (power < n) power *= 2;
  return power;
}
