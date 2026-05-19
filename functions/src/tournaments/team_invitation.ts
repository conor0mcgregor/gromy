import * as admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {NotificationDispatcher} from "../notifications/notification_dispatcher";

// ─────────────────────────────────────────────────────────────────────────────
//  Team Invitation Functions  ·  Cloud Functions v2
//
//  Espeja exactamente el sistema de admin_invitation.ts pero para equipos.
//
//  Flujo:
//  1. createTeamInvitation   → crea invitación pendiente + push + in-app
//  2. acceptTeamInvitation   → añade userId a team.members (transacción)
//  3. rejectTeamInvitation   → solo actualiza estado, notifica al creador
//  4. cancelTeamInvitation   → solo el admin del equipo puede cancelar
//
//  Seguridad:
//  - Todas validan auth y permisos
//  - La lógica de negocio crítica vive aquí, no en el cliente
//  - Transacciones atómicas para consistencia de datos
// ─────────────────────────────────────────────────────────────────────────────

const DB_ID = "gromy-db";

type InvitationStatus =
  | "pending"
  | "accepted"
  | "rejected"
  | "expired"
  | "cancelled";

/**
 * Crea una invitación de equipo y envía notificación push + in-app.
 *
 * Parámetros:
 *   - teamId: string
 *   - invitedUserId: string (UID del usuario invitado)
 *
 * Requisitos:
 *   - El llamante debe ser admin del equipo
 *   - No puede auto-invitarse
 *   - El usuario no puede ya ser miembro
 *   - No puede haber una invitación pendiente duplicada
 */
export const createTeamInvitation = onCall(
  {maxInstances: 10},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }

    const callerId = request.auth.uid;
    const {teamId, invitedUserId} = request.data as {
      teamId: string;
      invitedUserId: string;
    };

    logger.info("createTeamInvitation: request received", {
      callerId,
      teamId,
      invitedUserId,
    });

    // 1. Validar parámetros
    if (!teamId || !invitedUserId) {
      throw new HttpsError(
        "invalid-argument",
        "Se requieren teamId e invitedUserId."
      );
    }

    if (callerId === invitedUserId) {
      throw new HttpsError(
        "invalid-argument",
        "No puedes invitarte a ti mismo."
      );
    }

    const db = getFirestore(DB_ID);

    // 2. Obtener el equipo
    const teamDoc = await db.collection("teams").doc(teamId).get();
    const team = teamDoc.data();

    if (!teamDoc.exists || !team) {
      throw new HttpsError("not-found", "El equipo no existe.");
    }

    // 3. Validar que el llamante sea admin del equipo
    const adminIds: string[] = team.adminIds ?? [];
    if (!adminIds.includes(callerId)) {
      throw new HttpsError(
        "permission-denied",
        "Solo los administradores del equipo pueden invitar miembros."
      );
    }

    // 4. Verificar que el usuario invitado existe
    const invitedUserDoc = await db
      .collection("users")
      .doc(invitedUserId)
      .get();

    if (!invitedUserDoc.exists) {
      throw new HttpsError("not-found", "El usuario invitado no existe.");
    }

    // 5. Verificar que no sea ya miembro
    const members: string[] = team.members ?? [];
    if (members.includes(invitedUserId)) {
      throw new HttpsError(
        "already-exists",
        "Este usuario ya es miembro del equipo."
      );
    }

    // 6. Verificar que no haya una invitación pendiente duplicada
    const pendingInvitations = await db
      .collection("notifications")
      .where("userId", "==", invitedUserId)
      .where("type", "==", "team_invitation")
      .where("data.teamId", "==", teamId)
      .where("data.status", "==", "pending")
      .get();

    if (!pendingInvitations.empty) {
      throw new HttpsError(
        "already-exists",
        "Ya existe una invitación pendiente para este usuario."
      );
    }

    // 7. Obtener información del invitante
    const callerDoc = await db.collection("users").doc(callerId).get();
    const callerData = callerDoc.data();
    const callerName = callerData ?
      `${callerData.name ?? ""} ${callerData.lastName ?? ""}`.trim() ||
        callerData.nickname ||
        callerId :
      callerId;

    // 8. Crear la notificación de invitación con datos del equipo
    const dispatcher = new NotificationDispatcher(DB_ID);
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 días
    );

    const notificationId = await dispatcher.dispatch(
      {
        userId: invitedUserId,
        type: "team_invitation",
        title: "Invitación de equipo",
        body: `${callerName} te ha invitado a unirte al equipo ` +
          `"${team.name as string}".`,
        actionRoute: "/notification/team_invitation",
        data: {
          teamId,
          teamName: team.name,
          teamPhotoUrl: team.photoUrl ?? "",
          invitedBy: callerId,
          inviterName: callerName,
          memberCount: String(members.length + 1), // +1 por el creador
          status: "pending",
          invitedAt: admin.firestore.Timestamp.now().toMillis().toString(),
        },
        expiresAt,
      },
      {sendPush: true, priority: "high"}
    );

    // 9. Auditoría
    await db.collection("team_invitation_audit").add({
      teamId,
      invitedUserId,
      invitedBy: callerId,
      inviterName: callerName,
      action: "invitation_sent",
      notificationId,
      createdAt: admin.firestore.Timestamp.now(),
    });

    logger.info("createTeamInvitation: invitation created", {
      callerId,
      teamId,
      invitedUserId,
      notificationId,
    });

    return {
      success: true,
      notificationId,
      message: "Invitación enviada correctamente.",
    };
  }
);

/**
 * Acepta una invitación de equipo.
 * Añade al usuario como miembro del equipo en una transacción atómica.
 *
 * Parámetros:
 *   - notificationId: string
 */
export const acceptTeamInvitation = onCall(
  {maxInstances: 10},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }

    const callerId = request.auth.uid;
    const {notificationId} = request.data as {notificationId: string};

    if (!notificationId) {
      throw new HttpsError("invalid-argument", "Se requiere notificationId.");
    }

    const db = getFirestore(DB_ID);

    // 1. Obtener la notificación
    const notifDoc = await db
      .collection("notifications")
      .doc(notificationId)
      .get();

    const notif = notifDoc.data();
    if (!notifDoc.exists || !notif) {
      throw new HttpsError("not-found", "La invitación no existe.");
    }

    // 2. Validar que pertenece al usuario
    if (notif.userId !== callerId) {
      throw new HttpsError(
        "permission-denied",
        "Esta invitación no te pertenece."
      );
    }

    // 3. Validar tipo
    if (notif.type !== "team_invitation") {
      throw new HttpsError(
        "invalid-argument",
        "Esta notificación no es una invitación de equipo."
      );
    }

    const data = notif.data as Record<string, string>;
    const status = data.status as InvitationStatus;

    // 4. Validar estado
    if (status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        `La invitación ya fue ${status}.`
      );
    }

    // 5. Verificar expiración
    if (notif.expiresAt) {
      const expiresAt = (
        notif.expiresAt as admin.firestore.Timestamp
      ).toDate();
      if (new Date() > expiresAt) {
        await notifDoc.ref.update({"data.status": "expired"});
        throw new HttpsError("deadline-exceeded", "La invitación ha expirado.");
      }
    }

    const teamId = data.teamId;

    // 6. Obtener el equipo
    const teamDoc = await db.collection("teams").doc(teamId).get();
    const team = teamDoc.data();

    if (!teamDoc.exists || !team) {
      await notifDoc.ref.update({"data.status": "expired"});
      throw new HttpsError("not-found", "El equipo ya no existe.");
    }

    const members: string[] = team.members ?? [];

    // 7. Transacción atómica: añadir miembro + actualizar notificación
    await db.runTransaction(async (transaction) => {
      if (!members.includes(callerId)) {
        transaction.update(teamDoc.ref, {
          members: admin.firestore.FieldValue.arrayUnion(callerId),
          updatedAt: admin.firestore.Timestamp.now(),
        });
      }

      transaction.update(notifDoc.ref, {
        "data.status": "accepted",
        "data.respondedAt": admin.firestore.Timestamp.now()
          .toMillis()
          .toString(),
        "read": true,
        "readAt": admin.firestore.Timestamp.now(),
        "clicked": true,
      });
    });

    // 8. Notificar al admin del equipo (confirmación)
    const dispatcher = new NotificationDispatcher(DB_ID);
    const callerDoc = await db.collection("users").doc(callerId).get();
    const callerData = callerDoc.data();
    const callerName = callerData ?
      `${callerData.name ?? ""} ${callerData.lastName ?? ""}`.trim() ||
        callerData.nickname ||
        callerId :
      callerId;

    // Notificar al creador del equipo
    await dispatcher.dispatch(
      {
        userId: team.creatorId as string,
        type: "system",
        title: "Miembro incorporado",
        body: `${callerName} ha aceptado unirse al equipo ` +
          `"${team.name as string}".`,
        actionRoute: "/team/detail",
        data: {teamId},
      },
      {sendPush: true, priority: "high"}
    );

    // 9. Auditoría
    await db.collection("team_invitation_audit").add({
      teamId,
      invitedUserId: callerId,
      action: "invitation_accepted",
      notificationId,
      respondedAt: admin.firestore.Timestamp.now(),
    });

    logger.info("acceptTeamInvitation: invitation accepted", {
      callerId,
      teamId,
      notificationId,
    });

    return {
      success: true,
      message: "Invitación aceptada. ¡Ya eres miembro del equipo!",
    };
  }
);

/**
 * Rechaza una invitación de equipo.
 *
 * Parámetros:
 *   - notificationId: string
 */
export const rejectTeamInvitation = onCall(
  {maxInstances: 10},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }

    const callerId = request.auth.uid;
    const {notificationId} = request.data as {notificationId: string};

    if (!notificationId) {
      throw new HttpsError("invalid-argument", "Se requiere notificationId.");
    }

    const db = getFirestore(DB_ID);

    const notifDoc = await db
      .collection("notifications")
      .doc(notificationId)
      .get();

    const notif = notifDoc.data();
    if (!notifDoc.exists || !notif) {
      throw new HttpsError("not-found", "La invitación no existe.");
    }

    if (notif.userId !== callerId) {
      throw new HttpsError(
        "permission-denied",
        "Esta invitación no te pertenece."
      );
    }

    if (notif.type !== "team_invitation") {
      throw new HttpsError(
        "invalid-argument",
        "Esta notificación no es una invitación de equipo."
      );
    }

    const data = notif.data as Record<string, string>;
    const status = data.status as InvitationStatus;

    if (status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        `La invitación ya fue ${status}.`
      );
    }

    // Actualizar estado
    await notifDoc.ref.update({
      "data.status": "rejected",
      "data.respondedAt": admin.firestore.Timestamp.now()
        .toMillis()
        .toString(),
      "read": true,
      "readAt": admin.firestore.Timestamp.now(),
    });

    // Notificar al creador del equipo
    const teamId = data.teamId;
    const teamDoc = await db.collection("teams").doc(teamId).get();
    const team = teamDoc.data();

    if (teamDoc.exists && team) {
      const callerDoc = await db.collection("users").doc(callerId).get();
      const callerData = callerDoc.data();
      const callerName = callerData
        ? `${callerData.name ?? ""} ${callerData.lastName ?? ""}`.trim() ||
          callerData.nickname ||
          callerId
        : callerId;

      const dispatcher = new NotificationDispatcher(DB_ID);
      await dispatcher.dispatch(
        {
          userId: team.creatorId as string,
          type: "system",
          title: "Invitación rechazada",
          body: `${callerName} ha rechazado la invitación para unirse a "${team.name as string}".`,
          actionRoute: "/team/detail",
          data: {teamId},
        },
        {sendPush: false}
      );
    }

    // Auditoría
    await db.collection("team_invitation_audit").add({
      teamId,
      invitedUserId: callerId,
      action: "invitation_rejected",
      notificationId,
      respondedAt: admin.firestore.Timestamp.now(),
    });

    return {success: true, message: "Invitación rechazada."};
  }
);

/**
 * Cancela una invitación pendiente de equipo.
 * Solo los admins del equipo pueden cancelar.
 *
 * Parámetros:
 *   - notificationId: string
 */
export const cancelTeamInvitation = onCall(
  {maxInstances: 10},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }

    const callerId = request.auth.uid;
    const {notificationId} = request.data as {notificationId: string};

    if (!notificationId) {
      throw new HttpsError("invalid-argument", "Se requiere notificationId.");
    }

    const db = getFirestore(DB_ID);

    const notifDoc = await db
      .collection("notifications")
      .doc(notificationId)
      .get();

    const notif = notifDoc.data();
    if (!notifDoc.exists || !notif) {
      throw new HttpsError("not-found", "La invitación no existe.");
    }

    if (notif.type !== "team_invitation") {
      throw new HttpsError(
        "invalid-argument",
        "Esta notificación no es una invitación de equipo."
      );
    }

    const data = notif.data as Record<string, string>;
    const teamId = data.teamId;

    // Validar que el llamante sea admin del equipo
    const teamDoc = await db.collection("teams").doc(teamId).get();
    const team = teamDoc.data();

    if (!teamDoc.exists || !team) {
      throw new HttpsError("not-found", "El equipo no existe.");
    }

    const adminIds: string[] = team.adminIds ?? [];
    if (!adminIds.includes(callerId)) {
      throw new HttpsError(
        "permission-denied",
        "Solo los administradores pueden cancelar invitaciones."
      );
    }

    if (data.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        `La invitación ya fue ${data.status}.`
      );
    }

    await notifDoc.ref.update({
      "data.status": "cancelled",
      "data.cancelledAt": admin.firestore.Timestamp.now()
        .toMillis()
        .toString(),
    });

    // Auditoría
    await db.collection("team_invitation_audit").add({
      teamId,
      invitedUserId: notif.userId,
      action: "invitation_cancelled",
      cancelledBy: callerId,
      notificationId,
      cancelledAt: admin.firestore.Timestamp.now(),
    });

    return {success: true, message: "Invitación cancelada."};
  }
);
