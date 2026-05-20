import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {buildUserProfileExtras} from "./user_profile_stats";

const DB_ID = "gromy-db";

export const getUserProfile = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "El usuario debe estar autenticado para ver perfiles."
    );
  }

  const {targetUid} = request.data;
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "Se requiere un targetUid valido."
    );
  }

  try {
    const db = getFirestore(DB_ID);
    const userDoc = await db.collection("users").doc(targetUid).get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "El usuario no existe.");
    }

    const userData = userDoc.data()!;

    if (userData.isDeleted === true) {
      throw new HttpsError("not-found", "Este perfil no esta disponible.");
    }

    const createdAt = userData.createdAt as Timestamp | undefined;
    let stats = {
      totalPlayed: 0,
      wins: 0,
      losses: 0,
      winRate: 0,
      tournamentsWon: 0,
    };
    let sportsStats = {};
    let tournamentHistory: unknown[] = [];
    try {
      const extras = await buildUserProfileExtras(db, targetUid);
      stats = extras.stats;
      sportsStats = extras.sportsStats;
      tournamentHistory = extras.history;
    } catch (extrasError) {
      console.warn("getUserProfile extras skipped:", extrasError);
    }

    return {
      uid: userData.uid,
      nickname: userData.nickname,
      name: userData.name,
      lastName: userData.lastName,
      photoUrl: userData.photoUrl,
      biography: userData.biography,
      memberSince: createdAt?.toDate().toISOString() ?? null,
      stats,
      sportsStats,
      tournamentHistory,
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError(
      "internal",
      "Ocurrio un error al consultar el perfil."
    );
  }
});
