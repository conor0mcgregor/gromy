import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {Firestore, getFirestore} from "firebase-admin/firestore";
import {validateBracketIntegrity} from "./bracket_validator";
import {generateSingleEliminationBrackets} from "./generate_bracket";
import {
  NotificationDispatcher,
  NotificationTemplates,
} from "../notifications";

export const publishBracket = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesion.");
  }

  const {bracketId} = request.data as {bracketId?: string};
  if (!bracketId) {
    throw new HttpsError("invalid-argument", "bracketId es obligatorio.");
  }

  const db = getFirestore("gromy-db");
  const uid = request.auth.uid;
  const bracketRef = db.collection("brackets").doc(bracketId);
  const bracketDoc = await bracketRef.get();

  if (!bracketDoc.exists) {
    throw new HttpsError("not-found", "Bracket no encontrado.");
  }

  const bracketData = bracketDoc.data()!;
  if (bracketData.status !== "draft") {
    throw new HttpsError(
      "failed-precondition",
      "Solo se puede publicar un bracket en estado borrador."
    );
  }

  const tournamentData = await getTournamentAndAssertAdmin(
    db,
    bracketData.tournamentId,
    uid,
  );

  const validation = await validateBracketIntegrity(bracketId);
  if (!validation.valid) {
    throw new HttpsError(
      "failed-precondition",
      `Errores de integridad: ${validation.errors.join("; ")}`
    );
  }

  const now = admin.firestore.Timestamp.now();
  await bracketRef.update({
    status: "published",
    publishedAt: now,
    updatedAt: now,
  });

  await notifyBracketParticipants(db, bracketData, tournamentData);

  console.log(`Bracket publicado: ${bracketId}`);
  return {success: true, bracketId};
});

export const regenerateBracket = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesion.");
  }

  const {bracketId} = request.data as {bracketId?: string};
  if (!bracketId) {
    throw new HttpsError("invalid-argument", "bracketId es obligatorio.");
  }

  const db = getFirestore("gromy-db");
  const bracketDoc = await db.collection("brackets").doc(bracketId).get();
  if (!bracketDoc.exists) {
    throw new HttpsError("not-found", "Bracket no encontrado.");
  }

  const bracketData = bracketDoc.data()!;
  if (bracketData.status !== "draft") {
    throw new HttpsError(
      "failed-precondition",
      "Solo se puede regenerar un bracket en estado borrador."
    );
  }

  await getTournamentAndAssertAdmin(
    db,
    bracketData.tournamentId,
    request.auth.uid,
  );

  const generated = await generateSingleEliminationBrackets(db, {
    tournamentId: bracketData.tournamentId,
    categoryId: bracketData.categoryId ?? null,
  });

  return generated[0];
});

async function getTournamentAndAssertAdmin(
  db: Firestore,
  tournamentId: string,
  uid: string,
): Promise<FirebaseFirestore.DocumentData> {
  const tournamentDoc = await db
    .collection("tournaments")
    .doc(tournamentId)
    .get();
  if (!tournamentDoc.exists) {
    throw new HttpsError("not-found", "Torneo no encontrado.");
  }

  const tournamentData = tournamentDoc.data();
  if (!tournamentData) {
    throw new HttpsError("not-found", "Torneo no encontrado.");
  }
  const adminIds = normalizeStringList(tournamentData.adminIds);
  if (tournamentData.organizerUid !== uid && !adminIds.includes(uid)) {
    throw new HttpsError(
      "permission-denied",
      "No tienes permisos de administrador."
    );
  }
  return tournamentData;
}

async function notifyBracketParticipants(
  db: Firestore,
  bracketData: FirebaseFirestore.DocumentData,
  tournamentData: FirebaseFirestore.DocumentData,
): Promise<void> {
  try {
    let query: FirebaseFirestore.Query = db
      .collection("tournaments")
      .doc(bracketData.tournamentId)
      .collection("participants")
      .where("status", "==", "approved");

    if (bracketData.categoryId) {
      query = query.where("categoryId", "==", bracketData.categoryId);
    }

    const participantsSnap = await query.get();
    if (participantsSnap.empty) return;

    const userIds: string[] = [];
    for (const pDoc of participantsSnap.docs) {
      const participant = pDoc.data();
      if (participant.entityType === "team") {
        const teamDoc = await db
          .collection("teams")
          .doc(participant.entityId)
          .get();
        userIds.push(...normalizeStringList(teamDoc.data()?.members));
      } else if (participant.entityId) {
        userIds.push(String(participant.entityId));
      }
    }

    const uniqueUserIds = [...new Set(userIds)];
    if (uniqueUserIds.length === 0) return;

    const dispatcher = new NotificationDispatcher();
    const payload = NotificationTemplates.bracketPublished({
      userId: "",
      tournamentName: tournamentData.name || "Torneo",
      tournamentId: bracketData.tournamentId,
    });

    await dispatcher.dispatchToMany(uniqueUserIds, payload);
    console.log(
      `Notificaciones de bracket enviadas a ${uniqueUserIds.length} usuarios`
    );
  } catch (error) {
    console.error("Error enviando notificaciones de bracket:", error);
  }
}

function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item)).filter((item) => item.length > 0);
}
