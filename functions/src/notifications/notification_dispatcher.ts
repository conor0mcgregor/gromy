import * as admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationDispatcher  ·  Servicio de despacho de notificaciones
//
//  Responsabilidad única: crear documentos en Firestore y enviar push via FCM.
//  Todas las features llaman a este dispatcher para emitir notificaciones.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Datos necesarios para crear una notificación.
 */
export interface NotificationPayload {
  userId: string;
  type: string;
  title: string;
  body: string;
  actionRoute?: string;
  data?: Record<string, unknown>;
  expiresAt?: admin.firestore.Timestamp;
}

/**
 * Opciones para el envío push.
 */
export interface PushOptions {
  /**
   * Si es true, se envía push notification además de persistir
   * en Firestore.
   */
  sendPush: boolean;
  /** Prioridad del mensaje FCM. */
  priority?: "high" | "normal";
}

const DEFAULT_PUSH_OPTIONS: PushOptions = {
  sendPush: true,
  priority: "high",
};

/**
 * Despacha notificaciones: las persiste en Firestore y opcionalmente
 * envía push notifications a todos los dispositivos del usuario.
 */
export class NotificationDispatcher {
  private db: admin.firestore.Firestore;

  /**
   * Crea una instancia del despachador.
   * @param {string} databaseId ID de la base de datos Firestore.
   */
  constructor(databaseId = "gromy-db") {
    this.db = getFirestore(databaseId);
  }

  /**
   * Crea una notificación en Firestore y opcionalmente envía push.
   *
   * @param {NotificationPayload} payload - Datos de la notificación.
   * @param {PushOptions} options - Opciones de envío push.
   * @return {Promise<string>} El ID del documento creado.
   */
  async dispatch(
    payload: NotificationPayload,
    options: PushOptions = DEFAULT_PUSH_OPTIONS,
  ): Promise<string> {
    // 1. Persistir en Firestore
    const docRef = this.db.collection("notifications").doc();
    const now = admin.firestore.Timestamp.now();

    await docRef.set({
      id: docRef.id,
      userId: payload.userId,
      type: payload.type,
      title: payload.title,
      body: payload.body,
      read: false,
      clicked: false,
      createdAt: now,
      readAt: null,
      expiresAt: payload.expiresAt || null,
      actionRoute: payload.actionRoute || null,
      data: payload.data || {},
    });

    // 2. Enviar push notification si se requiere
    if (options.sendPush) {
      await this.sendPushToUser(docRef.id, payload, options);
    }

    return docRef.id;
  }

  /**
   * Despacha la misma notificación a múltiples usuarios.
   * @param {string[]} userIds Lista de IDs de usuario.
   * @param {Omit<NotificationPayload, "userId">} payload Datos base.
   * @param {PushOptions} options Opciones de envío.
   * @return {Promise<string[]>} IDs de las notificaciones creadas.
   */
  async dispatchToMany(
    userIds: string[],
    payload: Omit<NotificationPayload, "userId">,
    options: PushOptions = DEFAULT_PUSH_OPTIONS,
  ): Promise<string[]> {
    const ids: string[] = [];
    for (const userId of userIds) {
      const id = await this.dispatch({...payload, userId}, options);
      ids.push(id);
    }
    return ids;
  }

  /**
   * Envía push notifications a todos los dispositivos del usuario.
   * @param {NotificationPayload} payload Datos de la notificación.
   * @param {PushOptions} options Opciones de configuración.
   * @return {Promise<void>}
   */
  private async sendPushToUser(
    notificationId: string,
    payload: NotificationPayload,
    options: PushOptions,
  ): Promise<void> {
    try {
      const tokensSnap = await this.db
        .collection("users")
        .doc(payload.userId)
        .collection("fcm_tokens")
        .get();

      if (tokensSnap.empty) return;

      const tokens = tokensSnap.docs.map((doc) => doc.data().token as string);
      const validTokens = tokens.filter((t) => t && t.length > 0);

      if (validTokens.length === 0) return;

      const message: admin.messaging.MulticastMessage = {
        tokens: validTokens,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: {
          notificationId,
          id: notificationId,
          type: payload.type,
          actionRoute: payload.actionRoute || "",
          ...(payload.data ?
            Object.fromEntries(
              Object.entries(payload.data).map(([k, v]) => [k, String(v)])
            ) :
            {}),
        },
        android: {
          priority: options.priority === "high" ? "high" : "normal",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      // Limpiar tokens inválidos
      if (response.failureCount > 0) {
        const invalidTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const code = resp.error?.code;
            if (
              code === "messaging/invalid-registration-token" ||
              code === "messaging/registration-token-not-registered"
            ) {
              invalidTokens.push(validTokens[idx]);
            }
          }
        });

        // Eliminar tokens inválidos automáticamente
        for (const token of invalidTokens) {
          await this.db
            .collection("users")
            .doc(payload.userId)
            .collection("fcm_tokens")
            .doc(token)
            .delete();
        }
      }
    } catch (error) {
      console.error("Error enviando push notification:", error);
    }
  }
}
