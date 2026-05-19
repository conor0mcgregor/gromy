import * as admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {NotificationDispatcher} from "../notifications/notification_dispatcher";
import {NotificationTemplates} from "../notifications/notification_templates";

// ─────────────────────────────────────────────────────────────────────────────
//  Tournament Notification Triggers  ·  Cloud Functions v2 (Firestore triggers)
//
//  Lanza notificaciones automáticas cuando:
//  A) Un torneo es cancelado (status → cancelled)
//  B) Las fechas del torneo cambian (scheduledAt, registrationDeadline, etc.)
//  C) La ubicación del torneo cambia (location, latitude, longitude)
//
//  Patrón:
//  - Se detectan cambios comparando before vs after del documento.
//  - Se obtiene la lista de participantes desde la subcolección.
//  - Se usa NotificationDispatcher.dispatchToMany para evitar duplicados.
//  - NO se duplica lógica: se reutilizan templates y dispatcher existentes.
// ─────────────────────────────────────────────────────────────────────────────

const DB_ID = "gromy-db";

/**
 * Obtiene los UIDs de todos los participantes de un torneo.
 * Soporta tanto torneos individuales como por equipos.
 */
async function getParticipantUserIds(
  db: admin.firestore.Firestore,
  tournamentId: string
): Promise<string[]> {
  const participantsSnap = await db
    .collection("tournaments")
    .doc(tournamentId)
    .collection("participants")
    .get();

  const userIds = new Set<string>();
  for (const doc of participantsSnap.docs) {
    const data = doc.data();
    // Participante individual: entityId es el UID del usuario
    if (data.entityType === "user" && data.entityId) {
      userIds.add(data.entityId as string);
    }
    // Participante por equipo: entityId es el teamId → buscar miembros del equipo
    if (data.entityType === "team" && data.entityId) {
      try {
        const teamDoc = await db
          .collection("teams")
          .doc(data.entityId as string)
          .get();
        const teamData = teamDoc.data();
        if (teamData?.members && Array.isArray(teamData.members)) {
          for (const uid of teamData.members as string[]) {
            userIds.add(uid);
          }
        }
      } catch (err) {
        logger.warn("getParticipantUserIds: error fetching team", {
          teamId: data.entityId,
          err,
        });
      }
    }
  }

  return Array.from(userIds);
}

// ─────────────────────────────────────────────────────────────────────────────
//  A) Cancelación de torneo
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Detecta cuando el status de un torneo cambia a 'cancelled' y
 * notifica a todos los participantes.
 */
export const onTournamentCancelled = onDocumentUpdated(
  {
    document: "tournaments/{tournamentId}",
    database: DB_ID,
    maxInstances: 10,
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;

    // Solo actuar si el status cambia a 'cancelled'
    if (before.status === after.status) return;
    if (after.status !== "cancelled") return;

    const tournamentId = event.params.tournamentId;
    const tournamentName = (after.name as string | undefined) ?? "Torneo";

    logger.info("onTournamentCancelled: tournament cancelled", {
      tournamentId,
      tournamentName,
    });

    const db = getFirestore(DB_ID);
    const userIds = await getParticipantUserIds(db, tournamentId);

    if (userIds.length === 0) {
      logger.info("onTournamentCancelled: no participants to notify", {
        tournamentId,
      });
      return;
    }

    const dispatcher = new NotificationDispatcher(DB_ID);
    await dispatcher.dispatchToMany(
      userIds,
      {
        type: "tournament_cancelled",
        title: "Torneo cancelado",
        body: `El torneo "${tournamentName}" ha sido cancelado.`,
        actionRoute: "/tournament/detail",
        data: {tournamentId},
      },
      {sendPush: true, priority: "high"}
    );

    logger.info("onTournamentCancelled: notifications sent", {
      tournamentId,
      recipientCount: userIds.length,
    });
  }
);

// ─────────────────────────────────────────────────────────────────────────────
//  B) Modificación de fechas
// ─────────────────────────────────────────────────────────────────────────────

/** Compara dos Timestamps de Firestore con tolerancia de null. */
function timestampChanged(
  a: admin.firestore.Timestamp | null | undefined,
  b: admin.firestore.Timestamp | null | undefined
): boolean {
  if (a === b) return false;
  if (!a && !b) return false;
  if (!a || !b) return true;
  return a.toMillis() !== b.toMillis();
}

/**
 * Detecta cambios en las fechas relevantes del torneo y notifica a
 * todos los participantes.
 *
 * Fechas monitorizadas:
 *   - scheduledAt         → fecha del evento
 *   - registrationDeadline → fecha límite de inscripción
 *   - bracketPublishDate   → fecha de publicación de brackets
 */
export const onTournamentDatesChanged = onDocumentUpdated(
  {
    document: "tournaments/{tournamentId}",
    database: DB_ID,
    maxInstances: 10,
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;

    // Solo notificar si el torneo está activo (no cancelado)
    if (after.status === "cancelled") return;

    const datesChanged =
      timestampChanged(
        before.scheduledAt as admin.firestore.Timestamp,
        after.scheduledAt as admin.firestore.Timestamp
      ) ||
      timestampChanged(
        before.registrationDeadline as admin.firestore.Timestamp,
        after.registrationDeadline as admin.firestore.Timestamp
      ) ||
      timestampChanged(
        before.bracketPublishDate as admin.firestore.Timestamp,
        after.bracketPublishDate as admin.firestore.Timestamp
      );

    if (!datesChanged) return;

    const tournamentId = event.params.tournamentId;
    const tournamentName = (after.name as string | undefined) ?? "Torneo";

    // Construir mensaje con la nueva fecha del evento si cambió
    let newDateStr: string | undefined;
    if (
      timestampChanged(
        before.scheduledAt as admin.firestore.Timestamp,
        after.scheduledAt as admin.firestore.Timestamp
      ) &&
      after.scheduledAt
    ) {
      const d = (after.scheduledAt as admin.firestore.Timestamp).toDate();
      newDateStr = d.toLocaleDateString("es-ES", {
        day: "numeric",
        month: "long",
        year: "numeric",
      });
    }

    logger.info("onTournamentDatesChanged: dates changed", {
      tournamentId,
      tournamentName,
      newDateStr,
    });

    const db = getFirestore(DB_ID);
    const userIds = await getParticipantUserIds(db, tournamentId);

    if (userIds.length === 0) return;

    const dispatcher = new NotificationDispatcher(DB_ID);
    const payload = NotificationTemplates.scheduleChange({
      userId: "", // se rellena en dispatchToMany
      tournamentName,
      tournamentId,
      newDate: newDateStr,
    });

    await dispatcher.dispatchToMany(
      userIds,
      {
        type: payload.type,
        title: payload.title,
        body: payload.body,
        actionRoute: payload.actionRoute,
        data: payload.data,
      },
      {sendPush: true, priority: "high"}
    );

    logger.info("onTournamentDatesChanged: notifications sent", {
      tournamentId,
      recipientCount: userIds.length,
    });
  }
);

// ─────────────────────────────────────────────────────────────────────────────
//  C) Modificación de ubicación
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Detecta cambios en la ubicación del torneo y notifica a todos los
 * participantes.
 *
 * Campos monitorizados:
 *   - location  → nombre/dirección de la ubicación
 *   - latitude  → coordenada latitud
 *   - longitude → coordenada longitud
 */
export const onTournamentLocationChanged = onDocumentUpdated(
  {
    document: "tournaments/{tournamentId}",
    database: DB_ID,
    maxInstances: 10,
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;

    // Solo notificar si el torneo está activo
    if (after.status === "cancelled") return;

    const locationChanged =
      before.location !== after.location ||
      before.latitude !== after.latitude ||
      before.longitude !== after.longitude;

    if (!locationChanged) return;

    // Evitar disparar si solo cambió la ubicación como parte de la cancelación
    // (ya manejado por onTournamentCancelled)
    if (!after.location && !before.location) return;

    const tournamentId = event.params.tournamentId;
    const tournamentName = (after.name as string | undefined) ?? "Torneo";
    const newLocation = (after.location as string | undefined) ?? "";

    logger.info("onTournamentLocationChanged: location changed", {
      tournamentId,
      tournamentName,
      newLocation,
    });

    const db = getFirestore(DB_ID);
    const userIds = await getParticipantUserIds(db, tournamentId);

    if (userIds.length === 0) return;

    const dispatcher = new NotificationDispatcher(DB_ID);
    await dispatcher.dispatchToMany(
      userIds,
      {
        type: "location_changed",
        title: "Ubicación actualizada",
        body: newLocation
          ? `La ubicación del torneo "${tournamentName}" ha cambiado a: ${newLocation}.`
          : `La ubicación del torneo "${tournamentName}" ha sido actualizada.`,
        actionRoute: "/tournament/detail",
        data: {tournamentId, newLocation},
      },
      {sendPush: true, priority: "high"}
    );

    logger.info("onTournamentLocationChanged: notifications sent", {
      tournamentId,
      recipientCount: userIds.length,
    });
  }
);
