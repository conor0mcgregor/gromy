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

export const recordMatchResult = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesion.");
  }

  const data = request.data as {
    bracketId?: string;
    matchId?: string;
    winnerId?: string;
    loserId?: string;
    scoreParticipant1?: number;
    scoreParticipant2?: number;
  };

  const bracketId = requireString(data.bracketId, "bracketId");
  const matchId = requireString(data.matchId, "matchId");
  const winnerId = requireString(data.winnerId, "winnerId");
  const loserId = requireString(data.loserId, "loserId");
  const scoreParticipant1 = requireNonNegativeInt(
    data.scoreParticipant1,
    "scoreParticipant1",
  );
  const scoreParticipant2 = requireNonNegativeInt(
    data.scoreParticipant2,
    "scoreParticipant2",
  );

  const db = getFirestore("gromy-db");
  const bracket = await assertBracketAdmin(db, bracketId, request.auth.uid);
  if (bracket.status === "draft" || bracket.status === "cancelled") {
    throw new HttpsError(
      "failed-precondition",
      "Solo se pueden registrar resultados en brackets publicados o activos."
    );
  }

  const matchRef = matchCollection(db, bracketId).doc(matchId);
  const matchDoc = await matchRef.get();
  if (!matchDoc.exists) {
    throw new HttpsError("not-found", "Match no encontrado.");
  }

  const match = matchDoc.data()!;
  if (match.status === "bye" || match.status === "cancelled") {
    throw new HttpsError(
      "failed-precondition",
      "Este match no admite resultado manual."
    );
  }
  if (!match.participant1Id || !match.participant2Id) {
    throw new HttpsError(
      "failed-precondition",
      "El match todavia no tiene ambos participantes asignados."
    );
  }

  const validWinner =
    winnerId === match.participant1Id || winnerId === match.participant2Id;
  const expectedLoser = winnerId === match.participant1Id ?
    match.participant2Id :
    match.participant1Id;
  if (!validWinner || loserId !== expectedLoser) {
    throw new HttpsError(
      "invalid-argument",
      "El ganador y perdedor deben pertenecer al match."
    );
  }

  const now = admin.firestore.Timestamp.now();
  await matchRef.update({
    winnerId,
    loserId,
    scoreParticipant1,
    scoreParticipant2,
    status: "completed",
    startedAt: match.startedAt ?? now,
    completedAt: now,
  });

  await db.collection("brackets").doc(bracketId).update({updatedAt: now});

  return {success: true};
});

export const updateMatchSchedule = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesion.");
  }

  const data = request.data as {
    bracketId?: string;
    matchId?: string;
    scheduledAtMillis?: number;
  };

  const bracketId = requireString(data.bracketId, "bracketId");
  const matchId = requireString(data.matchId, "matchId");
  const scheduledAtMillis = requireNonNegativeInt(
    data.scheduledAtMillis,
    "scheduledAtMillis",
  );

  const db = getFirestore("gromy-db");
  const bracket = await assertBracketAdmin(db, bracketId, request.auth.uid);
  if (bracket.status === "completed" || bracket.status === "cancelled") {
    throw new HttpsError(
      "failed-precondition",
      "No se pueden editar horarios de brackets cerrados."
    );
  }

  const matchRef = matchCollection(db, bracketId).doc(matchId);
  const matchDoc = await matchRef.get();
  if (!matchDoc.exists) {
    throw new HttpsError("not-found", "Match no encontrado.");
  }

  const match = matchDoc.data()!;
  if (match.status === "completed" || match.status === "bye") {
    throw new HttpsError(
      "failed-precondition",
      "No se puede programar un match ya resuelto."
    );
  }

  const now = admin.firestore.Timestamp.now();
  await matchRef.update({
    scheduledAt: admin.firestore.Timestamp.fromMillis(scheduledAtMillis),
    status: match.status === "inProgress" ? "inProgress" : "scheduled",
  });
  await db.collection("brackets").doc(bracketId).update({updatedAt: now});

  return {success: true};
});

export const swapMatchParticipants = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesion.");
  }

  const data = request.data as {
    bracketId?: string;
    matchId1?: string;
    slotInMatch1?: number;
    matchId2?: string;
    slotInMatch2?: number;
  };

  const bracketId = requireString(data.bracketId, "bracketId");
  const matchId1 = requireString(data.matchId1, "matchId1");
  const matchId2 = requireString(data.matchId2, "matchId2");
  const slotInMatch1 = requireSlot(data.slotInMatch1, "slotInMatch1");
  const slotInMatch2 = requireSlot(data.slotInMatch2, "slotInMatch2");

  const db = getFirestore("gromy-db");
  const bracket = await assertBracketAdmin(db, bracketId, request.auth.uid);
  if (bracket.status !== "draft") {
    throw new HttpsError(
      "failed-precondition",
      "Solo se pueden intercambiar participantes en brackets borrador."
    );
  }

  const match1Ref = matchCollection(db, bracketId).doc(matchId1);
  const match2Ref = matchCollection(db, bracketId).doc(matchId2);
  const now = admin.firestore.Timestamp.now();

  await db.runTransaction(async (transaction) => {
    const match1Doc = await transaction.get(match1Ref);
    const match2Doc = matchId1 === matchId2 ?
      match1Doc :
      await transaction.get(match2Ref);

    if (!match1Doc.exists || !match2Doc.exists) {
      throw new HttpsError("not-found", "Uno o ambos matches no existen.");
    }

    const match1 = match1Doc.data()!;
    const match2 = match2Doc.data()!;
    assertDraftSlotEditable(match1);
    assertDraftSlotEditable(match2);

    const slot1 = readSlot(match1, slotInMatch1);
    const slot2 = readSlot(match2, slotInMatch2);

    if (matchId1 === matchId2) {
      const updated = {
        ...match1,
        ...slotUpdate(slotInMatch1, slot2),
        ...slotUpdate(slotInMatch2, slot1),
      };
      transaction.update(match1Ref, {
        ...slotUpdate(slotInMatch1, slot2),
        ...slotUpdate(slotInMatch2, slot1),
        ...draftResultState(updated, now),
      });
      return;
    }

    const updated1 = {...match1, ...slotUpdate(slotInMatch1, slot2)};
    const updated2 = {...match2, ...slotUpdate(slotInMatch2, slot1)};

    transaction.update(match1Ref, {
      ...slotUpdate(slotInMatch1, slot2),
      ...draftResultState(updated1, now),
    });
    transaction.update(match2Ref, {
      ...slotUpdate(slotInMatch2, slot1),
      ...draftResultState(updated2, now),
    });
  });

  await db.collection("brackets").doc(bracketId).update({updatedAt: now});
  return {success: true};
});

async function assertBracketAdmin(
  db: Firestore,
  bracketId: string,
  uid: string,
): Promise<FirebaseFirestore.DocumentData> {
  const bracketDoc = await db.collection("brackets").doc(bracketId).get();
  if (!bracketDoc.exists) {
    throw new HttpsError("not-found", "Bracket no encontrado.");
  }

  const bracket = bracketDoc.data()!;
  const tournamentDoc = await db
    .collection("tournaments")
    .doc(bracket.tournamentId)
    .get();
  if (!tournamentDoc.exists) {
    throw new HttpsError("not-found", "Torneo no encontrado.");
  }

  const tournament = tournamentDoc.data()!;
  const adminIds = normalizeStringList(tournament.adminIds);
  if (tournament.organizerUid !== uid && !adminIds.includes(uid)) {
    throw new HttpsError(
      "permission-denied",
      "No tienes permisos de administrador."
    );
  }

  return bracket;
}

function assertDraftSlotEditable(match: FirebaseFirestore.DocumentData): void {
  if (match.round !== 0 || match.parentMatch1Id || match.parentMatch2Id) {
    throw new HttpsError(
      "failed-precondition",
      "Solo se pueden intercambiar participantes de la primera ronda."
    );
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

function draftResultState(
  match: FirebaseFirestore.DocumentData,
  now: admin.firestore.Timestamp,
): Record<string, unknown> {
  const byeWinnerId = getByeWinnerId(
    match.participant1Id,
    match.participant2Id,
  );
  return {
    status: byeWinnerId ? "bye" : "pending",
    winnerId: byeWinnerId,
    loserId: null,
    scoreParticipant1: null,
    scoreParticipant2: null,
    startedAt: null,
    completedAt: byeWinnerId ? now : null,
  };
}

function getByeWinnerId(
  participant1Id: string | null | undefined,
  participant2Id: string | null | undefined,
): string | null {
  if (participant1Id && !participant2Id) return participant1Id;
  if (!participant1Id && participant2Id) return participant2Id;
  return null;
}

function matchCollection(db: Firestore, bracketId: string) {
  return db.collection("brackets").doc(bracketId).collection("matches");
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} es obligatorio.`);
  }
  return value.trim();
}

function requireNonNegativeInt(value: unknown, field: string): number {
  if (
    typeof value !== "number" ||
    !Number.isInteger(value) ||
    value < 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      `${field} debe ser un entero no negativo.`
    );
  }
  return value;
}

function requireSlot(value: unknown, field: string): number {
  if (value !== 1 && value !== 2) {
    throw new HttpsError("invalid-argument", `${field} debe ser 1 o 2.`);
  }
  return value;
}

function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item)).filter((item) => item.length > 0);
}
