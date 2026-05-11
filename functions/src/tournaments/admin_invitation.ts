import * as admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {NotificationDispatcher} from "../notifications/notification_dispatcher";

// ─────────────────────────────────────────────────────────────────────────────
//  Admin Invitation Functions  ·  Cloud Functions v2
//
//  Centraliza toda la lógica de invitaciones de administrador:
//  - Crear invitación + notificación in-app + push FCM
//  - Aceptar invitación: añadir a admin_ids
//  - Rechazar invitación: solo actualizar estado
//  - Cancelar invitación: solo el creador del torneo
//
//  Seguridad:
//  - Todas las funciones validan auth y permisos
//  - Nunca se confía en el frontend para añadir admins
// ─────────────────────────────────────────────────────────────────────────────

const DB_ID = "gromy-db";

/** Posibles estados de una invitación */
type InvitationStatus =
  | "pending"
  | "accepted"
  | "rejected"
  | "expired"
  | "cancelled";

/**
 * Crea una invitación de administrador y envía notificación push + in-app.
 *
 * Parámetros:
 *   - tournamentId: string
 *   - invitedUserId: string (UID del usuario invitado)
 *
 * Requisitos:
 *   - El llamante debe ser el creador (organizerUid) del torneo
 *   - No puede haber una invitación pendiente para el mismo usuario+torneo
 *   - El usuario invitado no puede ya ser admin del torneo
 */
export const createAdminInvitation = onCall(
  {maxInstances: 10},
  async (request) => {
    // 1. Autenticación
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }

    const callerId = request.auth.uid;
    const {tournamentId, invitedUserId} = request.data as {
      tournamentId: string;
      invitedUserId: string;
    };
    logger.info("createAdminInvitation: request received", {
      callerId,
      tournamentId,
      invitedUserId,
    });

    // 2. Validación de parámetros
    if (!tournamentId || !invitedUserId) {
      logger.warn("createAdminInvitation: missing required params", {
        callerId,
        tournamentId,
        invitedUserId,
      });
      throw new HttpsError(
        "invalid-argument",
        "Se requieren tournamentId e invitedUserId."
      );
    }

    if (callerId === invitedUserId) {
      logger.warn("createAdminInvitation: self invitation rejected", {
        callerId,
        tournamentId,
      });
      throw new HttpsError(
        "invalid-argument",
        "No puedes invitarte a ti mismo."
      );
    }

    const db = getFirestore(DB_ID);

    // 3. Obtener torneo
    const tournamentDoc = await db
      .collection("tournaments")
      .doc(tournamentId)
      .get();

    const tournament = tournamentDoc.data();
    if (!tournamentDoc.exists || !tournament) {
      logger.error("createAdminInvitation: tournament not found", {
        callerId,
        tournamentId,
        invitedUserId,
      });
      throw new HttpsError("not-found", "El torneo no existe.");
    }

    // 4. Validar que el llamante sea el creador
    if (tournament.organizerUid !== callerId) {
      logger.warn("createAdminInvitation: caller is not organizer", {
        callerId,
        tournamentId,
        organizerUid: tournament.organizerUid,
      });
      throw new HttpsError(
        "permission-denied",
        "Solo el creador del torneo puede invitar administradores."
      );
    }

    // 5. Verificar que el usuario invitado existe
    const invitedUserDoc = await db
      .collection("users")
      .doc(invitedUserId)
      .get();

    if (!invitedUserDoc.exists) {
      logger.error("createAdminInvitation: invited user not found", {
        callerId,
        tournamentId,
        invitedUserId,
      });
      throw new HttpsError("not-found", "El usuario invitado no existe.");
    }

    // 6. Verificar que no sea ya administrador
    const adminIds: string[] = tournament.adminIds ?? [];
    if (adminIds.includes(invitedUserId)) {
      logger.warn("createAdminInvitation: user already admin", {
        callerId,
        tournamentId,
        invitedUserId,
      });
      throw new HttpsError(
        "already-exists",
        "Este usuario ya es administrador del torneo."
      );
    }

    // 7. Verificar que no haya una invitación pendiente duplicada
    const pendingInvitations = await db
      .collection("notifications")
      .where("userId", "==", invitedUserId)
      .where("type", "==", "admin_invitation")
      .where("data.tournamentId", "==", tournamentId)
      .where("data.status", "==", "pending")
      .get();

    if (!pendingInvitations.empty) {
      logger.warn("createAdminInvitation: duplicate pending invitation", {
        callerId,
        tournamentId,
        invitedUserId,
        matches: pendingInvitations.size,
      });
      throw new HttpsError(
        "already-exists",
        "Ya existe una invitación pendiente para este usuario."
      );
    }

    // 8. Obtener info del invitante
    const callerDoc = await db.collection("users").doc(callerId).get();
    const callerData = callerDoc.data();
    const callerName = callerData ?
      (`${callerData.name ?? ""} ${callerData.lastName ?? ""}`.trim() ||
        callerData.nickname ||
        callerId) :
      callerId;

    // 9. Crear notificación con invitación embebida
    const dispatcher = new NotificationDispatcher(DB_ID);
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 días
    );

    const notificationId = await dispatcher.dispatch(
      {
        userId: invitedUserId,
        type: "admin_invitation",
        title: "Invitación de administrador",
        body: `${callerName} te ha invitado a administrar el torneo ` +
              `"${tournament.name}".`,
        actionRoute: "/notification/admin_invitation",
        data: {
          tournamentId,
          tournamentName: tournament.name,
          tournamentPortadaUrl: tournament.portadaUrl ?? "",
          tournamentDescription: tournament.description ?? "",
          invitedBy: callerId,
          inviterName: callerName,
          status: "pending",
          invitedAt: admin.firestore.Timestamp.now().toMillis()
            .toString(),
        },
        expiresAt,
      },
      {sendPush: true, priority: "high"}
    );

    // 10. Registro de auditoría
    await db.collection("admin_invitation_audit").add({
      tournamentId,
      invitedUserId,
      invitedBy: callerId,
      inviterName: callerName,
      action: "invitation_sent",
      notificationId,
      createdAt: admin.firestore.Timestamp.now(),
    });

    logger.info("createAdminInvitation: invitation created", {
      callerId,
      tournamentId,
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
 * Acepta una invitación de administrador.
 * Añade al usuario como admin del torneo y actualiza el estado.
 *
 * Parámetros:
 *   - notificationId: string (ID de la notificación de invitación)
 */
export const acceptAdminInvitation = onCall(
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

    // 2. Validar que la notificación pertenece al usuario
    if (notif.userId !== callerId) {
      throw new HttpsError(
        "permission-denied",
        "Esta invitación no te pertenece."
      );
    }

    // 3. Validar tipo
    if (notif.type !== "admin_invitation") {
      throw new HttpsError(
        "invalid-argument",
        "Esta notificación no es una invitación de administrador."
      );
    }

    const data = notif.data as Record<string, string>;
    const status = data.status as InvitationStatus;

    // 4. Validar estado actual
    if (status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        `La invitación ya fue ${status}.`
      );
    }

    // 5. Verificar expiración
    if (notif.expiresAt) {
      const expiresAt = (notif.expiresAt as admin.firestore.Timestamp).toDate();
      if (new Date() > expiresAt) {
        // Actualizar estado a expired
        await notifDoc.ref.update({"data.status": "expired"});
        throw new HttpsError(
          "deadline-exceeded",
          "La invitación ha expirado."
        );
      }
    }

    const tournamentId = data.tournamentId;

    // 6. Obtener torneo
    const tournamentDoc = await db
      .collection("tournaments")
      .doc(tournamentId)
      .get();

    const tournament = tournamentDoc.data();
    if (!tournamentDoc.exists || !tournament) {
      // Actualizar a expirada si el torneo no existe
      await notifDoc.ref.update({"data.status": "expired"});
      throw new HttpsError(
        "not-found",
        "El torneo ya no existe."
      );
    }

    const adminIds: string[] = tournament.adminIds ?? [];

    // 7. Ejecutar transacción atómica
    await db.runTransaction(async (transaction) => {
      // Añadir a admin_ids si no está ya
      if (!adminIds.includes(callerId)) {
        transaction.update(tournamentDoc.ref, {
          adminIds: admin.firestore.FieldValue.arrayUnion(callerId),
          updatedAt: admin.firestore.Timestamp.now(),
        });
      }

      // Actualizar estado de la notificación
      transaction.update(notifDoc.ref, {
        "data.status": "accepted",
        "data.respondedAt": admin.firestore.Timestamp.now().toMillis()
          .toString(),
        "read": true,
        "readAt": admin.firestore.Timestamp.now(),
        "clicked": true,
      });
    });

    // 8. Notificar al creador del torneo (confirmación)
    const dispatcher = new NotificationDispatcher(DB_ID);
    const callerDoc = await db.collection("users").doc(callerId).get();
    const callerData = callerDoc.data();
    const callerName = callerData ?
      (`${callerData.name ?? ""} ${callerData.lastName ?? ""}`.trim() ||
        callerData.nickname ||
        callerId) :
      callerId;

    // Notificar al organizador
    await dispatcher.dispatch(
      {
        userId: tournament.organizerUid,
        type: "admin_added",
        title: "Invitación aceptada",
        body: `${callerName} ha aceptado ser administrador de ` +
              `"${tournament.name}".`,
        actionRoute: "/tournament/management",
        data: {tournamentId},
      },
      {sendPush: true, priority: "high"}
    );

    // 9. Auditoría
    await db.collection("admin_invitation_audit").add({
      tournamentId,
      invitedUserId: callerId,
      action: "invitation_accepted",
      notificationId,
      respondedAt: admin.firestore.Timestamp.now(),
    });

    return {
      success: true,
      message: "Invitación aceptada. Ahora eres administrador.",
    };
  }
);

/**
 * Rechaza una invitación de administrador.
 *
 * Parámetros:
 *   - notificationId: string
 */
export const rejectAdminInvitation = onCall(
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

    if (notif.type !== "admin_invitation") {
      throw new HttpsError(
        "invalid-argument",
        "Esta notificación no es una invitación."
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
      "data.respondedAt": admin.firestore.Timestamp.now().toMillis().toString(),
      "read": true,
      "readAt": admin.firestore.Timestamp.now(),
    });

    // Notificar al creador del torneo
    const tournamentId = data.tournamentId;
    const tournamentDoc = await db.collection("tournaments")
      .doc(tournamentId).get();

    const tournament = tournamentDoc.data();
    if (tournamentDoc.exists && tournament) {
      const callerDoc = await db.collection("users").doc(callerId).get();
      const callerData = callerDoc.data();
      const callerName = callerData ?
        (`${callerData.name ?? ""} ${callerData.lastName ?? ""}`.trim() ||
          callerData.nickname ||
          callerId) :
        callerId;

      const dispatcher = new NotificationDispatcher(DB_ID);
      await dispatcher.dispatch(
        {
          userId: tournament.organizerUid,
          type: "system",
          title: "Invitación rechazada",
          body: `${callerName} ha rechazado la invitación para ` +
                `administrar "${tournament.name}".`,
          actionRoute: "/tournament/management",
          data: {tournamentId},
        },
        {sendPush: false}
      );
    }

    // Auditoría
    await db.collection("admin_invitation_audit").add({
      tournamentId,
      invitedUserId: callerId,
      action: "invitation_rejected",
      notificationId,
      respondedAt: admin.firestore.Timestamp.now(),
    });

    return {success: true, message: "Invitación rechazada."};
  }
);

/**
 * Cancela una invitación pendiente (solo el creador del torneo).
 *
 * Parámetros:
 *   - notificationId: string
 */
export const cancelAdminInvitation = onCall(
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

    const notifDoc = await db.collection("notifications")
      .doc(notificationId).get();

    const notif = notifDoc.data();
    if (!notifDoc.exists || !notif) {
      throw new HttpsError("not-found", "La invitación no existe.");
    }

    if (notif.type !== "admin_invitation") {
      throw new HttpsError(
        "invalid-argument",
        "Esta notificación no es una invitación."
      );
    }

    const data = notif.data as Record<string, string>;
    const tournamentId = data.tournamentId;

    // Validar que el llamante sea el creador del torneo
    const tournamentDoc = await db.collection("tournaments")
      .doc(tournamentId).get();

    const tournament = tournamentDoc.data();
    if (!tournamentDoc.exists || !tournament) {
      throw new HttpsError("not-found", "El torneo no existe.");
    }

    if (tournament.organizerUid !== callerId) {
      throw new HttpsError(
        "permission-denied",
        "Solo el creador puede cancelar invitaciones."
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
      "data.cancelledAt": admin.firestore.Timestamp.now().toMillis().toString(),
    });

    // Auditoría
    await db.collection("admin_invitation_audit").add({
      tournamentId,
      invitedUserId: notif.userId,
      action: "invitation_cancelled",
      cancelledBy: callerId,
      notificationId,
      cancelledAt: admin.firestore.Timestamp.now(),
    });

    return {success: true, message: "Invitación cancelada."};
  }
);
