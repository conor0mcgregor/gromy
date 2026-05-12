import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";

export const onMatchWinnerUpdated = onDocumentUpdated(
  {
    document: "brackets/{bracketId}/matches/{matchId}",
    database: "gromy-db",
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) return;

    const oldWinnerId = beforeData.winnerId || null;
    const newWinnerId = afterData.winnerId || null;
    if (oldWinnerId === newWinnerId) return;

    const db = getFirestore("gromy-db");
    const bracketId = event.params.bracketId;
    const matchId = event.params.matchId;
    const childMatchId = afterData.childMatchId as string | undefined;
    const positionInChild = afterData.positionInChild as number | undefined;
    const now = admin.firestore.Timestamp.now();

    if (!childMatchId) {
      await updateFinalState(db, bracketId, newWinnerId, oldWinnerId, now);
      return;
    }

    if (!positionInChild) {
      console.error(
        `Match ${matchId}: tiene childMatchId pero no positionInChild`
      );
      return;
    }

    if (oldWinnerId) {
      await invalidateDescendants(db, bracketId, childMatchId, positionInChild);
    }

    if (newWinnerId) {
      await propagateWinnerToChild(
        db,
        bracketId,
        childMatchId,
        positionInChild,
        newWinnerId,
        afterData,
      );
      await markBracketActiveIfNeeded(db, bracketId, now);
    }
  }
);

async function updateFinalState(
  db: admin.firestore.Firestore,
  bracketId: string,
  newWinnerId: string | null,
  oldWinnerId: string | null,
  now: admin.firestore.Timestamp,
): Promise<void> {
  if (newWinnerId) {
    await db.collection("brackets").doc(bracketId).update({
      status: "completed",
      completedAt: now,
      updatedAt: now,
    });
    return;
  }

  if (oldWinnerId) {
    await db.collection("brackets").doc(bracketId).update({
      status: "active",
      completedAt: null,
      updatedAt: now,
    });
  }
}

async function propagateWinnerToChild(
  db: admin.firestore.Firestore,
  bracketId: string,
  childMatchId: string,
  positionInChild: number,
  winnerId: string,
  sourceMatch: FirebaseFirestore.DocumentData,
): Promise<void> {
  const childRef = db
    .collection("brackets")
    .doc(bracketId)
    .collection("matches")
    .doc(childMatchId);
  const targetPrefix = positionInChild === 1 ? "participant1" : "participant2";
  const sourcePrefix = winnerId === sourceMatch.participant1Id ?
    "participant1" :
    "participant2";

  await childRef.update({
    [`${targetPrefix}Id`]: winnerId,
    [`${targetPrefix}Name`]: sourceMatch[`${sourcePrefix}Name`] || null,
    [`${targetPrefix}PhotoUrl`]:
      sourceMatch[`${sourcePrefix}PhotoUrl`] || null,
    [`${targetPrefix}Type`]: sourceMatch[`${sourcePrefix}Type`] || null,
    [`${targetPrefix}MemberIds`]:
      sourceMatch[`${sourcePrefix}MemberIds`] || [],
    [`${targetPrefix}MemberNames`]:
      sourceMatch[`${sourcePrefix}MemberNames`] || [],
  });
}

async function markBracketActiveIfNeeded(
  db: admin.firestore.Firestore,
  bracketId: string,
  now: admin.firestore.Timestamp,
): Promise<void> {
  const bracketDoc = await db.collection("brackets").doc(bracketId).get();
  if (bracketDoc.exists && bracketDoc.data()?.status === "published") {
    await bracketDoc.ref.update({
      status: "active",
      updatedAt: now,
    });
  }
}

async function invalidateDescendants(
  db: admin.firestore.Firestore,
  bracketId: string,
  matchId: string,
  position: number,
): Promise<void> {
  const matchRef = db
    .collection("brackets")
    .doc(bracketId)
    .collection("matches")
    .doc(matchId);

  const matchDoc = await matchRef.get();
  if (!matchDoc.exists) return;

  const matchData = matchDoc.data()!;
  const prefix = position === 1 ? "participant1" : "participant2";
  const updateData: Record<string, unknown> = {
    [`${prefix}Id`]: null,
    [`${prefix}Name`]: null,
    [`${prefix}PhotoUrl`]: null,
    [`${prefix}Type`]: null,
    [`${prefix}MemberIds`]: [],
    [`${prefix}MemberNames`]: [],
  };

  const hadWinner = Boolean(matchData.winnerId);
  if (hadWinner) {
    updateData.winnerId = null;
    updateData.loserId = null;
    updateData.scoreParticipant1 = null;
    updateData.scoreParticipant2 = null;
    updateData.status = "pending";
    updateData.completedAt = null;
  }

  await matchRef.update(updateData);

  if (hadWinner && matchData.childMatchId && matchData.positionInChild) {
    await invalidateDescendants(
      db,
      bracketId,
      matchData.childMatchId,
      matchData.positionInChild,
    );
  }
}
