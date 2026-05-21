import {Firestore} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";

export type TournamentCollectionId = "tournaments" | "private_tournaments";

export type ResolvedTournament = {
  ref: FirebaseFirestore.DocumentReference;
  data: FirebaseFirestore.DocumentData;
  collectionId: TournamentCollectionId;
};

/**
 * Busca un torneo en `tournaments` y, si no existe, en `private_tournaments`.
 */
export async function resolveTournament(
  db: Firestore,
  tournamentId: string,
): Promise<ResolvedTournament | null> {
  const publicRef = db.collection("tournaments").doc(tournamentId);
  const publicDoc = await publicRef.get();
  if (publicDoc.exists) {
    const data = publicDoc.data();
    if (data) {
      return {ref: publicRef, data, collectionId: "tournaments"};
    }
  }

  const privateRef = db.collection("private_tournaments").doc(tournamentId);
  const privateDoc = await privateRef.get();
  if (privateDoc.exists) {
    const data = privateDoc.data();
    if (data) {
      return {ref: privateRef, data, collectionId: "private_tournaments"};
    }
  }

  return null;
}

/**
 * Igual que [resolveTournament] pero lanza `not-found` si no existe en ninguna.
 */
export async function resolveTournamentOrThrow(
  db: Firestore,
  tournamentId: string,
  message = "El torneo no existe.",
): Promise<ResolvedTournament> {
  const resolved = await resolveTournament(db, tournamentId);
  if (!resolved) {
    throw new HttpsError("not-found", message);
  }
  return resolved;
}
