import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";

// ─────────────────────────────────────────────────────────────────────────────
//  onTournamentBracketCompleted
//
//  Se ejecuta cuando cualquier documento de la colección "brackets" es
//  creado, actualizado o eliminado.
//
//  Lógica:
//    1. Leer todos los brackets del torneo al que pertenece el bracket
//       modificado.
//    2. Si TODOS los brackets tienen status = "completed", marcar el torneo
//       como "completed" en Firestore.
//    3. Si algún bracket vuelve a estar activo (resultado corregido), se
//       revierte el torneo a "in_progress".
//
//  Nota: Los torneos privados usan la colección "private_tournaments".
//        Esta función comprueba ambas colecciones.
// ─────────────────────────────────────────────────────────────────────────────

export const onTournamentBracketCompleted = onDocumentWritten(
  {
    document: "brackets/{bracketId}",
    database: "gromy-db",
  },
  async (event) => {
    const afterData = event.data?.after?.data();

    // Si el documento fue eliminado, no hay nada que comprobar
    if (!afterData) return;

    const tournamentId = afterData.tournamentId as string | undefined;
    if (!tournamentId) {
      console.warn(
        `Bracket ${event.params.bracketId} no tiene tournamentId. Ignorando.`
      );
      return;
    }

    const db = getFirestore("gromy-db");
    const now = admin.firestore.Timestamp.now();

    // 1. Obtener todos los brackets del torneo
    const bracketsSnap = await db
      .collection("brackets")
      .where("tournamentId", "==", tournamentId)
      .get();

    if (bracketsSnap.empty) return;

    const brackets = bracketsSnap.docs.map((doc) => doc.data());

    // 2. Comprobar si TODOS los brackets están completados
    const allCompleted = brackets.every(
      (b) => b.status === "completed"
    );

    // 3. Comprobar si algún bracket está activo (juego en curso)
    const anyActive = brackets.some(
      (b) => b.status === "active" || b.status === "published"
    );

    // Resolver referencia al torneo (puede ser público o privado)
    const publicRef = db.collection("tournaments").doc(tournamentId);
    const privateRef = db.collection("private_tournaments").doc(tournamentId);

    const [publicDoc, privateDoc] = await Promise.all([
      publicRef.get(),
      privateRef.get(),
    ]);

    const tournamentRef = publicDoc.exists
      ? publicRef
      : privateDoc.exists
        ? privateRef
        : null;

    if (!tournamentRef) {
      console.warn(
        `Torneo ${tournamentId} no encontrado en tournaments ni private_tournaments.`
      );
      return;
    }

    const tournamentData = (publicDoc.exists ? publicDoc : privateDoc).data()!;
    const currentStatus = tournamentData.status as string;

    if (allCompleted && currentStatus !== "completed") {
      // ── Transición a "completed" ──────────────────────────────────────────
      console.info(
        "Torneo " + tournamentId + ": todos los brackets completados. " +
        "Marcando como 'completed'."
      );
      await tournamentRef.update({
        status: "completed",
        completedAt: now,
        updatedAt: now,
      });
    } else if (
      anyActive &&
      currentStatus === "completed"
    ) {
      // ── Reversión a "in_progress" si se corrige un resultado ──────────────
      console.info(
        "Torneo " + tournamentId + ": resultado corregido. " +
        "Revirtiendo a 'in_progress'."
      );
      await tournamentRef.update({
        status: "in_progress",
        completedAt: null,
        updatedAt: now,
      });
    }
    // Si el torneo ya está en el estado correcto, no hay nada que hacer
  }
);
