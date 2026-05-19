import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";

const DB_ID = "gromy-db";

export const getUserProfile = onCall(async (request) => {
  // 1. Verify authentication
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
      "Se requiere un targetUid válido."
    );
  }

  try {
    const db = getFirestore(DB_ID);
    const userDoc = await db.collection("users").doc(targetUid).get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "El usuario no existe.");
    }

    const userData = userDoc.data()!;

    // Here we can apply privacy blocks in the future (HU22, HU25, HU27)
    // For now, we only expose public fields.
    const publicProfile = {
      uid: userData.uid,
      nickname: userData.nickname,
      name: userData.name,
      lastName: userData.lastName,
      photoUrl: userData.photoUrl,
      biography: userData.biography,
    };

    return publicProfile;
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError(
      "internal",
      "Ocurrió un error al consultar el perfil."
    );
  }
});
