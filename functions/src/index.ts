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
// Re-exportar para que otros módulos puedan importar directamente
export {
  NotificationDispatcher,
  NotificationTemplates,
} from "./notifications";

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

import {onRequest} from "firebase-functions/v2/https";
import {NotificationDispatcher, NotificationTemplates} from "./notifications";

// ─────────────────────────────────────────────────────────────────────────────
//  Función de prueba temporal
//  Punto de enlace HTTP para probar el envío de notificaciones.
//  Puedes llamarlo desde el navegador:
//  https://<region>-<proyecto>.cloudfunctions.net/testNotification?userId=TU_UID
// ─────────────────────────────────────────────────────────────────────────────

export const testNotification = onRequest(async (request, response) => {
  const userId = request.query.userId as string;

  if (!userId) {
    response.status(400).send("Falta el parámetro '?userId=TU_UID' en la URL");
    return;
  }

  try {
    const dispatcher = new NotificationDispatcher();
    const payload = NotificationTemplates.system({
      userId: userId,
      title: "Prueba de sistema",
      body: "Esta es una notificación de prueba desde Cloud Functions 🚀",
      actionRoute: "/home",
    });

    const docId = await dispatcher.dispatch(payload);

    response.status(200).send(
      `¡Éxito! Notificación creada con ID: ${docId} para el usuario: ${userId}`
    );
  } catch (error) {
    console.error("Error al enviar notificación de prueba", error);
    response.status(500).send("Error interno al enviar la notificación.");
  }
});
