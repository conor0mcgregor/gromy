import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {
  getFirestore,
  Timestamp,
  FieldValue,
  Firestore,
  DocumentReference,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";

const DB_ID = "gromy-db";
const BATCH_LIMIT = 400;

type BlockingReason = {
  code: string;
  message: string;
  action: string;
};

export const deleteUserAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Debes iniciar sesion para eliminar tu cuenta."
    );
  }

  const userId = request.auth.uid;
  const db = getFirestore(DB_ID);

  const blockingReasons = await collectBlockingReasons(db, userId);
  if (blockingReasons.length > 0) {
    throw new HttpsError(
      "failed-precondition",
      blockingReasons[0].message,
      {blockingReasons}
    );
  }

  try {
    await purgeUserData(db, userId);
    await deleteProfileImage(userId);
    await admin.auth().deleteUser(userId);
    return {success: true};
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("deleteUserAccount error:", error);
    throw new HttpsError(
      "internal",
      "No se pudo eliminar la cuenta. Intentalo de nuevo."
    );
  }
});

async function collectBlockingReasons(
  db: Firestore,
  userId: string
): Promise<BlockingReason[]> {
  const reasons: BlockingReason[] = [];
  const now = Timestamp.now();

  const tournamentChecks = await Promise.all([
    soleOrganizerReasons(db, "tournaments", userId, now),
    soleOrganizerReasons(db, "private_tournaments", userId, now),
  ]);
  for (const list of tournamentChecks) {
    reasons.push(...list);
  }

  reasons.push(...await soleTeamOwnerReasons(db, userId));

  if (await hasPendingDocument(db, "payments", userId, ["pending", "processing", "in_progress"])) {
    reasons.push({
      code: "activePayments",
      message: "No puedes eliminar tu cuenta porque hay pagos en curso.",
      action: "Espera a que los pagos finalicen o contacta con soporte.",
    });
  }

  if (await hasPendingDocument(db, "critical_processes", userId, ["pending", "processing", "open"])) {
    reasons.push({
      code: "criticalProcesses",
      message: "No puedes eliminar tu cuenta porque hay procesos criticos pendientes.",
      action: "Completa o cancela esos procesos antes de continuar.",
    });
  }

  return reasons;
}

async function soleOrganizerReasons(
  db: Firestore,
  collection: string,
  userId: string,
  now: Timestamp
): Promise<BlockingReason[]> {
  const reasons: BlockingReason[] = [];
  try {
    const snapshot = await db
      .collection(collection)
      .where("organizerUid", "==", userId)
      .where("scheduledAt", ">=", now)
      .get();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const adminIds = new Set(
        (data.adminIds as string[] | undefined ?? []).map(String)
      );
      const hasOtherResponsible = [...adminIds].some((uid) => uid !== userId);
      if (!hasOtherResponsible) {
        const name = (data.name as string | undefined) ?? "un torneo activo";
        reasons.push({
          code: "soleTournamentOrganizer",
          message: `No puedes eliminar tu cuenta porque eres el unico organizador de "${name}".`,
          action: "Transfiere la organizacion antes de continuar.",
        });
      }
    }
  } catch (error) {
    console.warn(`soleOrganizerReasons(${collection}) skipped:`, error);
  }
  return reasons;
}

async function soleTeamOwnerReasons(
  db: Firestore,
  userId: string
): Promise<BlockingReason[]> {
  const reasons: BlockingReason[] = [];
  const docs = new Map<string, QueryDocumentSnapshot>();

  for (const field of ["adminIds", "creatorId"] as const) {
    try {
      const snapshot = field === "creatorId"
        ? await db.collection("teams").where("creatorId", "==", userId).get()
        : await db.collection("teams").where("adminIds", "array-contains", userId).get();
      for (const doc of snapshot.docs) {
        docs.set(doc.id, doc);
      }
    } catch (error) {
      console.warn(`soleTeamOwnerReasons(${field}) skipped:`, error);
    }
  }

  for (const doc of docs.values()) {
    const data = doc.data();
    const adminIds = new Set(
      (data.adminIds as string[] | undefined ?? []).map(String)
    );
    const creatorId = String(data.creatorId ?? "");
    if (adminIds.size === 0 && creatorId) {
      adminIds.add(creatorId);
    }
    const hasOtherResponsible = [...adminIds].some((uid) => uid !== userId);
    if (!hasOtherResponsible) {
      const name = (data.name as string | undefined) ?? "un equipo activo";
      reasons.push({
        code: "soleTeamOwner",
        message: `No puedes eliminar tu cuenta porque eres el unico responsable de "${name}".`,
        action: "Asigna otro administrador del equipo antes de continuar.",
      });
    }
  }

  return reasons;
}

async function hasPendingDocument(
  db: Firestore,
  collection: string,
  userId: string,
  statuses: string[]
): Promise<boolean> {
  try {
    const snapshot = await db
      .collection(collection)
      .where("userId", "==", userId)
      .where("status", "in", statuses)
      .limit(1)
      .get();
    return !snapshot.empty;
  } catch (error) {
    console.warn(`hasPendingDocument(${collection}) skipped:`, error);
    return false;
  }
}

async function purgeUserData(
  db: Firestore,
  userId: string
): Promise<void> {
  await deleteNotifications(db, userId);
  await deleteUserSubcollections(db, userId);
  await removeFromTeams(db, userId);
  await deleteParticipantRecords(db, userId);
  await deleteInvitations(db, userId);
  await anonymizeOrganizedTournaments(db, userId);
  await deleteDocInBatches(db, "users", userId);
}

async function deleteNotifications(
  db: Firestore,
  userId: string
): Promise<void> {
  try {
    const snapshot = await db
      .collection("notifications")
      .where("userId", "==", userId)
      .get();
    await commitDeletes(db, snapshot.docs.map((doc) => doc.ref));
  } catch (error) {
    console.warn("deleteNotifications skipped:", error);
  }
}

async function deleteUserSubcollections(
  db: Firestore,
  userId: string
): Promise<void> {
  const userRef = db.collection("users").doc(userId);
  for (const sub of ["fcm_tokens", "favorites"]) {
    try {
      const snapshot = await userRef.collection(sub).get();
      await commitDeletes(db, snapshot.docs.map((doc) => doc.ref));
    } catch (error) {
      console.warn(`deleteUserSubcollections(${sub}) skipped:`, error);
    }
  }
}

async function removeFromTeams(
  db: Firestore,
  userId: string
): Promise<void> {
  const refs: DocumentReference[] = [];
  for (const field of ["members", "adminIds"] as const) {
    try {
      const snapshot = await db
        .collection("teams")
        .where(field, "array-contains", userId)
        .get();
      for (const doc of snapshot.docs) {
        refs.push(doc.ref);
      }
    } catch (error) {
      console.warn(`removeFromTeams(${field}) skipped:`, error);
    }
  }

  const uniqueRefs = [...new Map(refs.map((ref) => [ref.path, ref])).values()];
  let batch = db.batch();
  let count = 0;
  for (const ref of uniqueRefs) {
    batch.update(ref, {
      members: FieldValue.arrayRemove(userId),
      adminIds: FieldValue.arrayRemove(userId),
    });
    count++;
    if (count >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) await batch.commit();
}

async function deleteParticipantRecords(
  db: Firestore,
  userId: string
): Promise<void> {
  try {
    const snapshot = await db
      .collectionGroup("participants")
      .where("entityId", "==", userId)
      .get();

    const tournamentCounts = new Map<string, number>();

    for (const doc of snapshot.docs) {
      const tournamentId = doc.ref.parent.parent?.id;
      if (tournamentId) {
        tournamentCounts.set(
          tournamentId,
          (tournamentCounts.get(tournamentId) ?? 0) + 1
        );
      }
    }

    await commitDeletes(db, snapshot.docs.map((doc) => doc.ref));

    for (const [tournamentId, removed] of tournamentCounts) {
      await decrementParticipantCount(db, tournamentId, removed);
    }
  } catch (error) {
    console.warn("deleteParticipantRecords skipped:", error);
  }
}

async function decrementParticipantCount(
  db: Firestore,
  tournamentId: string,
  removed: number
): Promise<void> {
  for (const collection of ["tournaments", "private_tournaments"]) {
    const ref = db.collection(collection).doc(tournamentId);
    const doc = await ref.get();
    if (!doc.exists) continue;
    const current = (doc.data()?.participantCount as number | undefined) ?? 0;
    const next = Math.max(0, current - removed);
    await ref.update({participantCount: next});
    return;
  }
}

async function deleteInvitations(
  db: Firestore,
  userId: string
): Promise<void> {
  try {
    const snapshot = await db
      .collection("tournamentInvitations")
      .where("createdByUid", "==", userId)
      .get();
    await commitDeletes(db, snapshot.docs.map((doc) => doc.ref));
  } catch (error) {
    console.warn("deleteInvitations skipped:", error);
  }
}

async function anonymizeOrganizedTournaments(
  db: Firestore,
  userId: string
): Promise<void> {
  for (const collection of ["tournaments", "private_tournaments"]) {
    try {
      const snapshot = await db
        .collection(collection)
        .where("organizerUid", "==", userId)
        .get();

      let batch = db.batch();
      let count = 0;
      for (const doc of snapshot.docs) {
        batch.update(doc.ref, {
          organizerUid: null,
          organizerDisplayName: "Organizador eliminado",
          organizerEmail: null,
          contactEmail: null,
          contactPhone: null,
          updatedAt: FieldValue.serverTimestamp(),
        });
        count++;
        if (count >= BATCH_LIMIT) {
          await batch.commit();
          batch = db.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    } catch (error) {
      console.warn(`anonymizeOrganizedTournaments(${collection}) skipped:`, error);
    }
  }
}

async function deleteDocInBatches(
  db: Firestore,
  collection: string,
  docId: string
): Promise<void> {
  const ref = db.collection(collection).doc(docId);
  const doc = await ref.get();
  if (doc.exists) {
    await ref.delete();
  }

  try {
    const auditRef = db.collection("account_deletions").doc(docId);
    const auditDoc = await auditRef.get();
    if (auditDoc.exists) {
      await auditRef.delete();
    }
  } catch (error) {
    console.warn("delete account_deletions audit skipped:", error);
  }
}

async function commitDeletes(
  db: Firestore,
  refs: DocumentReference[]
): Promise<void> {
  if (refs.length === 0) return;

  let batch = db.batch();
  let count = 0;
  for (const ref of refs) {
    batch.delete(ref);
    count++;
    if (count >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) await batch.commit();
}

async function deleteProfileImage(userId: string): Promise<void> {
  try {
    const bucket = admin.storage().bucket();
    await bucket.file(`profile_images/${userId}.jpg`).delete();
  } catch (error: unknown) {
    const code = (error as {code?: number})?.code;
    if (code === 404) return;
    console.warn("deleteProfileImage skipped:", error);
  }
}
