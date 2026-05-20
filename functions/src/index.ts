/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import * as admin from "firebase-admin";

// ── Inicializar Firebase Admin SDK ───────────────────────────────────────────
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// ── Módulo de notificaciones ─────────────────────────────────────────────────
export {
  NotificationDispatcher,
  NotificationTemplates,
} from "./notifications";

// ── Módulo de torneos ────────────────────────────────────────────────────────
export {
  createAdminInvitation,
  acceptAdminInvitation,
  rejectAdminInvitation,
  cancelAdminInvitation,
  // Invitaciones de equipo
  createTeamInvitation,
  acceptTeamInvitation,
  rejectTeamInvitation,
  cancelTeamInvitation,
  // Triggers de notificaciones de torneos
  onTournamentCancelled,
  onTournamentDatesChanged,
  onTournamentLocationChanged,
} from "./tournaments";

// ── Módulo de brackets ──────────────────────────────────────────────────────
export {
  generateBracket,
  publishBracket,
  regenerateBracket,
  onMatchWinnerUpdated,
  recordMatchResult,
  updateMatchSchedule,
  swapMatchParticipants,
} from "./brackets";

// ── Módulo de usuarios ──────────────────────────────────────────────────────
export {
  getUserProfile,
  deleteUserAccount,
} from "./users";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// ─────────────────────────────────────────────────────────────────────────────
//  EJEMPLO: Cómo crear un trigger de notificación en el futuro
//
//  import {onDocumentCreated} from "firebase-functions/v2/firestore";
//  import {NotificationDispatcher, NotificationTemplates}
//    from "./notifications";
//
//  export const onBracketPublished = onDocumentCreated(
//    "tournaments/{tournamentId}/brackets/{bracketId}",
//    async (event) => {
//      const data = event.data?.data();
//      if (!data) return;
//
//      const dispatcher = new NotificationDispatcher();
//      const db = admin.app().firestore("gromy-db");
//
//      // Obtener participantes del torneo
//      const participants = await db
//        .collection("tournaments")
//        .doc(event.params.tournamentId)
//        .collection("participants")
//        .get();
//
//      // Notificar a cada participante
//      const userIds = participants.docs.map((doc) => doc.data().entityId);
//      const payload = NotificationTemplates.bracketPublished({
//        userId: "", // se rellena en dispatchToMany
//        tournamentName: data.tournamentName,
//        tournamentId: event.params.tournamentId,
//      });
//
//      await dispatcher.dispatchToMany(userIds, payload);
//      logger.info(`Notificaciones enviadas a ${userIds.length} usuarios`);
//    }
//  );
// ─────────────────────────────────────────────────────────────────────────────

