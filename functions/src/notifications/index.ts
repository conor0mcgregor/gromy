// ─────────────────────────────────────────────────────────────────────────────
//  Notifications Module  ·  Barrel Export
//
//  Re-exporta todos los componentes del sistema de notificaciones para
//  facilitar la importación desde triggers y otros módulos.
//
//  Uso:
//    import { NotificationDispatcher, NotificationTemplates }
//      from "./notifications";
// ─────────────────────────────────────────────────────────────────────────────

export {
  NotificationDispatcher,
  NotificationPayload,
  PushOptions,
} from "./notification_dispatcher";

export {NotificationTemplates} from "./notification_templates";
