import {NotificationPayload} from "./notification_dispatcher";

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationTemplates  ·  Plantillas de notificación
//
//  Centraliza los textos y configuración de cada tipo de notificación.
//  Para añadir un nuevo tipo:
//    1. Agregar un método estático aquí.
//    2. Llamar a NotificationDispatcher.dispatch() con el payload generado.
//
//  NO contiene lógica de negocio — solo genera payloads.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Plantillas predefinidas para los tipos de notificación del sistema.
 */
export class NotificationTemplates {
  /**
   * Invitación a un torneo.
   * @param {Object} params Parámetros.
   * @param {string} params.userId ID del usuario.
   * @param {string} params.tournamentName Nombre del torneo.
   * @param {string} params.tournamentId ID del torneo.
   * @param {string} [params.inviterName] Nombre de quien invita.
   * @return {NotificationPayload} Payload de la notificación.
   */
  static invitation(params: {
    userId: string;
    tournamentName: string;
    tournamentId: string;
    inviterName?: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "invitation",
      title: "Nueva invitación",
      body: params.inviterName ?
        `${params.inviterName} te ha invitado al torneo ` +
        `"${params.tournamentName}".` :
        `Has sido invitado al torneo "${params.tournamentName}".`,
      actionRoute: "/tournament/detail",
      data: {tournamentId: params.tournamentId},
    };
  }

  /**
   * Cuadro/bracket publicado.
   * @param {Object} params Parámetros.
   * @param {string} params.userId ID del usuario.
   * @param {string} params.tournamentName Nombre del torneo.
   * @param {string} params.tournamentId ID del torneo.
   * @return {NotificationPayload} Payload.
   */
  static bracketPublished(params: {
    userId: string;
    tournamentName: string;
    tournamentId: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "bracket_published",
      title: "Cuadro publicado",
      body: `El cuadro del torneo "${params.tournamentName}" ` +
        "ya está disponible.",
      actionRoute: "/tournament/bracket",
      data: {tournamentId: params.tournamentId},
    };
  }

  /**
   * Torneo iniciado.
   * @param {Object} params Parámetros.
   * @param {string} params.userId ID del usuario.
   * @param {string} params.tournamentName Nombre del torneo.
   * @param {string} params.tournamentId ID del torneo.
   * @return {NotificationPayload} Payload.
   */
  static tournamentStarted(params: {
    userId: string;
    tournamentName: string;
    tournamentId: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "tournament_started",
      title: "¡Torneo en marcha!",
      body: `El torneo "${params.tournamentName}" ha comenzado. ¡Buena suerte!`,
      actionRoute: "/tournament/detail",
      data: {tournamentId: params.tournamentId},
    };
  }

  /**
   * Cambio de horario.
   * @param {Object} params Parámetros.
   * @param {string} params.userId ID del usuario.
   * @param {string} params.tournamentName Nombre del torneo.
   * @param {string} params.tournamentId ID del torneo.
   * @param {string} [params.newDate] Nueva fecha.
   * @return {NotificationPayload} Payload.
   */
  static scheduleChange(params: {
    userId: string;
    tournamentName: string;
    tournamentId: string;
    newDate?: string;
  }): NotificationPayload {
    const dateMsg = params.newDate ?
      ` Nueva fecha: ${params.newDate}.` :
      "";
    return {
      userId: params.userId,
      type: "schedule_change",
      title: "Cambio de horario",
      body: `El horario del torneo "${params.tournamentName}" ` +
        `ha sido modificado.${dateMsg}`,
      actionRoute: "/tournament/detail",
      data: {tournamentId: params.tournamentId},
    };
  }

  /**
   * Nuevo administrador añadido.
   * @param {Object} params Parámetros.
   * @param {string} params.userId ID del usuario.
   * @param {string} params.tournamentName Nombre del torneo.
   * @param {string} params.tournamentId ID del torneo.
   * @return {NotificationPayload} Payload.
   */
  static adminAdded(params: {
    userId: string;
    tournamentName: string;
    tournamentId: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "admin_added",
      title: "Nuevo rol: Administrador",
      body: "Has sido añadido como administrador del torneo " +
        `"${params.tournamentName}".`,
      actionRoute: "/tournament/management",
      data: {tournamentId: params.tournamentId},
    };
  }

  /**
   * Inscripción confirmada.
   * @param {Object} params Parámetros.
   * @param {string} params.userId ID del usuario.
   * @param {string} params.tournamentName Nombre del torneo.
   * @param {string} params.tournamentId ID del torneo.
   * @return {NotificationPayload} Payload.
   */
  static inscriptionConfirmed(params: {
    userId: string;
    tournamentName: string;
    tournamentId: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "inscription_confirmed",
      title: "Inscripción confirmada",
      body: `Tu inscripción al torneo "${params.tournamentName}" ` +
        "ha sido confirmada.",
      actionRoute: "/tournament/detail",
      data: {tournamentId: params.tournamentId},
    };
  }

  /**
   * Inscripción cancelada.
   * @param {Object} params Parámetros.
   * @param {string} params.userId ID del usuario.
   * @param {string} params.tournamentName Nombre del torneo.
   * @param {string} params.tournamentId ID del torneo.
   * @return {NotificationPayload} Payload.
   */
  static inscriptionCancelled(params: {
    userId: string;
    tournamentName: string;
    tournamentId: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "inscription_cancelled",
      title: "Inscripción cancelada",
      body: `Tu inscripción al torneo "${params.tournamentName}" ` +
        "ha sido cancelada.",
      actionRoute: "/tournament/detail",
      data: {tournamentId: params.tournamentId},
    };
  }

  /**
   * Invitación a equipo.
   * @param {Object} params Parámetros.
   * @param {string} params.userId ID del usuario.
   * @param {string} params.teamName Nombre del equipo.
   * @param {string} params.teamId ID del equipo.
   * @param {string} [params.inviterName] Nombre de quien invita.
   * @return {NotificationPayload} Payload.
   */
  static teamInvitation(params: {
    userId: string;
    teamName: string;
    teamId: string;
    inviterName?: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "team_invitation",
      title: "Invitación de equipo",
      body: params.inviterName ?
        `${params.inviterName} te ha invitado a unirte al ` +
        `equipo "${params.teamName}".` :
        `Has sido invitado a unirte al equipo "${params.teamName}".`,
      actionRoute: "/team/detail",
      data: {teamId: params.teamId},
    };
  }

  /**
   * Notificación del sistema (genérica).
   * @param {Object} params Parámetros.
   * @return {NotificationPayload} Payload.
   */
  static system(params: {
    userId: string;
    title: string;
    body: string;
    actionRoute?: string;
    data?: Record<string, unknown>;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "system",
      title: params.title,
      body: params.body,
      actionRoute: params.actionRoute,
      data: params.data,
    };
  }

  /**
   * Notificación de aviso/warning.
   * @param {Object} params Parámetros.
   * @return {NotificationPayload} Payload.
   */
  static warning(params: {
    userId: string;
    title: string;
    body: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "warning",
      title: params.title,
      body: params.body,
    };
  }

  /**
   * Notificación de error.
   * @param {Object} params Parámetros.
   * @return {NotificationPayload} Payload.
   */
  static error(params: {
    userId: string;
    title: string;
    body: string;
  }): NotificationPayload {
    return {
      userId: params.userId,
      type: "error",
      title: params.title,
      body: params.body,
    };
  }
}
