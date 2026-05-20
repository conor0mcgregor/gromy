import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {Firestore, getFirestore} from "firebase-admin/firestore";

interface SlotData {
  id: string | null;
  type: string | null;
  name: string | null;
  photoUrl: string | null;
  memberIds: string[];
  memberNames: string[];
}

const EMPTY_SLOT: SlotData = {
  id: null,
  type: null,
  name: null,
  photoUrl: null,
  memberIds: [],
  memberNames: [],
};

interface PurgeOptions {
  categoryId?: string | null;
}

/**
 * Elimina todas las referencias de un participante (entityId) en los brackets
 * de un torneo. Recalcula BYEs y limpia avances cuando corresponde.
 */
export async function purgeEntityFromTournamentBrackets(
  db: Firestore,
  tournamentId: string,
  entityId: string,
  options: PurgeOptions = {},
): Promise<{bracketsUpdated: number; matchesUpdated: number}> {
  const bracketsSnap = await db
    .collection("brackets")
    .where("tournamentId", "==", tournamentId)
    .get();

  const now = admin.firestore.Timestamp.now();
  let bracketsUpdated = 0;
  let matchesUpdated = 0;

  for (const bracketDoc of bracketsSnap.docs) {
    const bracket = bracketDoc.data();
    const bracketStatus = String(bracket.status ?? "draft");

    if (bracketStatus === "cancelled" || bracketStatus === "completed") {
      continue;
    }

    if (options.categoryId !== undefined) {
      if (!sameCategory(bracket.categoryId ?? null, options.categoryId ?? null)) {
        continue;
      }
    }

    const matchesSnap = await matchCollection(db, bracketDoc.id).get();
    let bracketTouched = false;

    for (const matchDoc of matchesSnap.docs) {
      const match = matchDoc.data();
      for (const slot of [1, 2] as const) {
        const slotData = readSlot(match, slot);
        if (slotData.id !== entityId) continue;

        await removeEntityFromMatchSlot({
          db,
          bracketId: bracketDoc.id,
          bracketStatus,
          matchId: matchDoc.id,
          match,
          slot,
          entityId,
          now,
        });
        matchesUpdated++;
        bracketTouched = true;
      }
    }

    if (bracketTouched) {
      if (bracketStatus === "draft") {
        await propagateAutomaticWinners(db, bracketDoc.id);
      }
      await bracketDoc.ref.update({updatedAt: now});
      bracketsUpdated++;
    }
  }

  return {bracketsUpdated, matchesUpdated};
}

export const purgeParticipantFromBrackets = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesion.");
  }

  const data = request.data as {
    tournamentId?: string;
    entityId?: string;
    categoryId?: string | null;
  };

  const tournamentId = requireString(data.tournamentId, "tournamentId");
  const entityId = requireString(data.entityId, "entityId");

  const db = getFirestore("gromy-db");
  const tournament = await getTournamentOrFail(db, tournamentId);
  assertTournamentAdmin(tournament, request.auth.uid);

  const result = await purgeEntityFromTournamentBrackets(
    db,
    tournamentId,
    entityId,
    {categoryId: data.categoryId},
  );

  return {success: true, ...result};
});

async function removeEntityFromMatchSlot(params: {
  db: Firestore;
  bracketId: string;
  bracketStatus: string;
  matchId: string;
  match: FirebaseFirestore.DocumentData;
  slot: 1 | 2;
  entityId: string;
  now: admin.firestore.Timestamp;
}): Promise<void> {
  const {db, bracketId, bracketStatus, matchId, match, slot, entityId, now} =
    params;
  const matchRef = matchCollection(db, bracketId).doc(matchId);
  const hadWinner = match.winnerId === entityId;

  if (
    hadWinner &&
    match.childMatchId &&
    match.positionInChild &&
    bracketStatus !== "draft"
  ) {
    await invalidateDescendants(
      db,
      bracketId,
      match.childMatchId as string,
      match.positionInChild as number,
    );
  }

  const clearedMatch = {
    ...match,
    ...slotUpdate(slot, EMPTY_SLOT),
  };
  const p1 = readSlot(clearedMatch, 1).id;
  const p2 = readSlot(clearedMatch, 2).id;
  const byeWinnerId = getByeWinnerId(p1, p2);

  const update: Record<string, unknown> = {
    ...slotUpdate(slot, EMPTY_SLOT),
    status: byeWinnerId ? "bye" : "pending",
    winnerId: byeWinnerId,
    loserId: null,
    scoreParticipant1: null,
    scoreParticipant2: null,
    startedAt: null,
    completedAt: byeWinnerId ? now : null,
  };

  await matchRef.update(update);

  if (hadWinner && bracketStatus === "draft" && match.childMatchId) {
    await invalidateDescendants(
      db,
      bracketId,
      match.childMatchId as string,
      match.positionInChild as number,
    );
  }
}

async function invalidateDescendants(
  db: Firestore,
  bracketId: string,
  matchId: string,
  position: number,
): Promise<void> {
  const matchRef = matchCollection(db, bracketId).doc(matchId);
  const matchDoc = await matchRef.get();
  if (!matchDoc.exists) return;

  const matchData = matchDoc.data()!;
  const prefix = position === 1 ? "participant1" : "participant2";
  const updateData: Record<string, unknown> = {
    [`${prefix}Id`]: null,
    [`${prefix}Name`]: null,
    [`${prefix}PhotoUrl`]: null,
    [`${prefix}Type`]: null,
    [`${prefix}MemberIds`]: [],
    [`${prefix}MemberNames`]: [],
  };

  const hadWinner = Boolean(matchData.winnerId);
  if (hadWinner) {
    updateData.winnerId = null;
    updateData.loserId = null;
    updateData.scoreParticipant1 = null;
    updateData.scoreParticipant2 = null;
    updateData.status = "pending";
    updateData.completedAt = null;
  }

  await matchRef.update(updateData);

  if (hadWinner && matchData.childMatchId && matchData.positionInChild) {
    await invalidateDescendants(
      db,
      bracketId,
      matchData.childMatchId as string,
      matchData.positionInChild as number,
    );
  }
}

async function propagateAutomaticWinners(
  db: Firestore,
  bracketId: string,
): Promise<void> {
  const byeMatchesSnap = await matchCollection(db, bracketId)
    .where("status", "==", "bye")
    .get();

  for (const byeDoc of byeMatchesSnap.docs) {
    const byeData = byeDoc.data();
    const winnerId = byeData.winnerId as string | undefined;
    const childMatchId = byeData.childMatchId as string | undefined;
    const positionInChild = byeData.positionInChild as number | undefined;
    if (!winnerId || !childMatchId || !positionInChild) continue;

    const childRef = matchCollection(db, bracketId).doc(childMatchId);
    const prefix = positionInChild === 1 ? "participant1" : "participant2";
    const winnerPrefix =
      winnerId === byeData.participant1Id ? "participant1" : "participant2";

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

function readSlot(
  match: FirebaseFirestore.DocumentData,
  slot: number,
): SlotData {
  const prefix = slot === 1 ? "participant1" : "participant2";
  return {
    id: match[`${prefix}Id`] ?? null,
    type: match[`${prefix}Type`] ?? null,
    name: match[`${prefix}Name`] ?? null,
    photoUrl: match[`${prefix}PhotoUrl`] ?? null,
    memberIds: normalizeStringList(match[`${prefix}MemberIds`]),
    memberNames: normalizeStringList(match[`${prefix}MemberNames`]),
  };
}

function slotUpdate(slot: number, data: SlotData): Record<string, unknown> {
  const prefix = slot === 1 ? "participant1" : "participant2";
  return {
    [`${prefix}Id`]: data.id,
    [`${prefix}Type`]: data.type,
    [`${prefix}Name`]: data.name,
    [`${prefix}PhotoUrl`]: data.photoUrl,
    [`${prefix}MemberIds`]: data.memberIds,
    [`${prefix}MemberNames`]: data.memberNames,
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

function matchCollection(db: Firestore, bracketId: string) {
  return db.collection("brackets").doc(bracketId).collection("matches");
}

function sameCategory(left: string | null, right: string | null): boolean {
  return (left ?? null) === (right ?? null);
}

async function getTournamentOrFail(
  db: Firestore,
  tournamentId: string,
): Promise<FirebaseFirestore.DocumentData> {
  const publicRef = db.collection("tournaments").doc(tournamentId);
  const publicDoc = await publicRef.get();
  if (publicDoc.exists) {
    const data = publicDoc.data();
    if (!data) {
      throw new HttpsError("not-found", "Torneo no encontrado.");
    }
    return data;
  }

  const privateRef = db.collection("private_tournaments").doc(tournamentId);
  const privateDoc = await privateRef.get();
  if (!privateDoc.exists) {
    throw new HttpsError("not-found", "Torneo no encontrado.");
  }
  const data = privateDoc.data();
  if (!data) {
    throw new HttpsError("not-found", "Torneo no encontrado.");
  }
  return data;
}

function assertTournamentAdmin(
  tournament: FirebaseFirestore.DocumentData,
  uid: string,
): void {
  const adminIds = normalizeStringList(tournament.adminIds);
  if (tournament.organizerUid !== uid && !adminIds.includes(uid)) {
    throw new HttpsError(
      "permission-denied",
      "No tienes permisos de administrador en este torneo.",
    );
  }
}

function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item)).filter((item) => item.length > 0);
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} es obligatorio.`);
  }
  return value.trim();
}
