import * as admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {NotificationDispatcher} from "../notifications/notification_dispatcher";

const DB_ID = "gromy-db";
const TYPE = "tournament_invitation";

export const createTournamentInvitation = onCall(
  {maxInstances: 10},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }

    const callerId = request.auth.uid;
    const {tournamentId, invitedUserId} = request.data as {
      tournamentId?: string;
      invitedUserId?: string;
    };
    if (!tournamentId || !invitedUserId) {
      throw new HttpsError(
        "invalid-argument",
        "Se requieren tournamentId e invitedUserId."
      );
    }
    if (callerId === invitedUserId) {
      throw new HttpsError("invalid-argument", "No puedes invitarte a ti mismo.");
    }

    const db = getFirestore(DB_ID);
    const tournamentRef = db.collection("private_tournaments").doc(tournamentId);
    const tournamentDoc = await tournamentRef.get();
    const tournament = tournamentDoc.data();
    if (!tournamentDoc.exists || !tournament) {
      throw new HttpsError("not-found", "El torneo privado no existe.");
    }

    const adminIds = normalizeStringList(tournament.adminIds);
    if (tournament.organizerUid !== callerId && !adminIds.includes(callerId)) {
      throw new HttpsError(
        "permission-denied",
        "No tienes permisos para invitar jugadores a este torneo."
      );
    }

    const invitedUserDoc = await db.collection("users").doc(invitedUserId).get();
    const invitedUser = invitedUserDoc.data();
    if (!invitedUserDoc.exists || !invitedUser) {
      throw new HttpsError("not-found", "El usuario invitado no existe.");
    }

    const participantSnap = await tournamentRef
      .collection("participants")
      .where("entityId", "==", invitedUserId)
      .limit(1)
      .get();
    if (!participantSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "Este usuario ya esta inscrito en el torneo."
      );
    }

    const requestSnap = await tournamentRef
      .collection("joinRequests")
      .where("entityId", "==", invitedUserId)
      .where("status", "==", "pending")
      .limit(1)
      .get();
    if (!requestSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "Este usuario ya tiene una solicitud pendiente."
      );
    }

    const duplicateSnap = await db
      .collection("notifications")
      .where("userId", "==", invitedUserId)
      .where("type", "==", TYPE)
      .where("data.tournamentId", "==", tournamentId)
      .where("data.status", "==", "pending")
      .limit(1)
      .get();
    if (!duplicateSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "Este usuario ya tiene una invitacion pendiente."
      );
    }

    const callerDoc = await db.collection("users").doc(callerId).get();
    const caller = callerDoc.data() ?? {};
    const inviterName = userDisplayName(caller);
    const scheduledAt = tournament.scheduledAt;
    const dispatcher = new NotificationDispatcher(DB_ID);
    const notificationId = await dispatcher.dispatch({
      userId: invitedUserId,
      type: TYPE,
      title: "Invitacion a torneo privado",
      body: `${inviterName} te ha invitado a "${tournament.name ?? "un torneo"}".`,
      actionRoute: "/tournament/preinscription",
      data: {
        status: "pending",
        tournamentId,
        tournamentName: tournament.name ?? "",
        tournamentDescription: tournament.description ?? "",
        tournamentPortadaUrl: tournament.portadaUrl ?? "",
        tournamentSport: tournament.sport ?? "",
        tournamentLocation: tournament.location ?? "",
        tournamentScheduledAt: scheduledAt?.toMillis?.() ?? null,
        tournamentParticipantCount: tournament.participantCount ?? 0,
        tournamentMaxParticipants: tournament.maxParticipants ?? 0,
        inviterId: callerId,
        inviterName,
        invitedAt: admin.firestore.Timestamp.now().toMillis(),
      },
    });

    return {notificationId};
  }
);

export const acceptTournamentInvitation = onCall(
  {maxInstances: 10},
  async (request) => updateInvitationStatus(request, "accepted")
);

export const rejectTournamentInvitation = onCall(
  {maxInstances: 10},
  async (request) => updateInvitationStatus(request, "rejected")
);

async function updateInvitationStatus(
  request: CallableRequest,
  status: "accepted" | "rejected",
): Promise<{ok: boolean}> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes estar autenticado.");
  }
  const {notificationId} = request.data as {notificationId?: string};
  if (!notificationId) {
    throw new HttpsError("invalid-argument", "notificationId es obligatorio.");
  }

  const db = getFirestore(DB_ID);
  const ref = db.collection("notifications").doc(notificationId);
  const doc = await ref.get();
  const data = doc.data();
  if (!doc.exists || !data || data.type !== TYPE) {
    throw new HttpsError("not-found", "Invitacion no encontrada.");
  }
  if (data.userId !== request.auth.uid) {
    throw new HttpsError(
      "permission-denied",
      "No puedes responder esta invitacion."
    );
  }
  await ref.update({
    "data.status": status,
    "data.respondedAt": admin.firestore.Timestamp.now().toMillis(),
    read: true,
    readAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {ok: true};
}

function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item)).filter((item) => item.length > 0);
}

function userDisplayName(userData: FirebaseFirestore.DocumentData): string {
  const fullName = `${userData.name ?? ""} ${userData.lastName ?? ""}`.trim();
  return fullName || userData.nickname || userData.email || "Organizador";
}
