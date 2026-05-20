import {
  Firestore,
  Timestamp,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";

export type TournamentHistoryEntry = {
  tournamentId: string;
  tournamentName: string;
  scheduledAt: string | null;
  tournamentType: string;
  participantStatus: string;
  resultStatus: "won" | "participated" | "eliminated" | "pending";
  placementLabel: string;
  sport: string | null;
};

export type UserProfileStats = {
  totalPlayed: number;
  wins: number;
  losses: number;
  winRate: number;
  tournamentsWon: number;
};

type ParticipantRow = {
  tournamentId: string;
  entityId: string;
  status: string;
  enrolledAt: Timestamp | null;
};

export async function buildUserProfileExtras(
  db: Firestore,
  targetUid: string
): Promise<{stats: UserProfileStats; history: TournamentHistoryEntry[]}> {
  const entityIds = await resolveEntityIds(db, targetUid);
  const participants = await fetchParticipants(db, entityIds);
  const tournamentIds = [
    ...new Set(participants.map((p) => p.tournamentId)),
  ];

  let wins = 0;
  let losses = 0;
  let tournamentsWon = 0;

  const history: TournamentHistoryEntry[] = [];

  for (const tournamentId of tournamentIds) {
    const tournament = await loadTournament(db, tournamentId);
    if (!tournament) continue;

    const participant = participants.find((p) => p.tournamentId === tournamentId);
    const resultStatus = await resolveResultStatus(
      db,
      tournamentId,
      entityIds,
      tournament.scheduledAt
    );

    if (resultStatus === "won") {
      wins++;
      tournamentsWon++;
    } else if (resultStatus === "eliminated") {
      losses++;
    }

    history.push({
      tournamentId,
      tournamentName: tournament.name,
      scheduledAt: tournament.scheduledAt?.toDate().toISOString() ?? null,
      tournamentType: tournament.accessType,
      participantStatus: participant?.status ?? "unknown",
      resultStatus,
      placementLabel: placementLabel(resultStatus),
      sport: tournament.sport,
    });
  }

  history.sort((a, b) => {
    const aTime = a.scheduledAt ? Date.parse(a.scheduledAt) : 0;
    const bTime = b.scheduledAt ? Date.parse(b.scheduledAt) : 0;
    return bTime - aTime;
  });

  const totalPlayed = history.length;
  const decided = wins + losses;
  const winRate = decided > 0 ? Math.round((wins / decided) * 100) : 0;

  return {
    stats: {
      totalPlayed,
      wins,
      losses,
      winRate,
      tournamentsWon,
    },
    history,
  };
}

async function resolveEntityIds(
  db: Firestore,
  targetUid: string
): Promise<Set<string>> {
  const ids = new Set<string>([targetUid]);
  try {
    const teams = await db
      .collection("teams")
      .where("members", "array-contains", targetUid)
      .get();
    for (const doc of teams.docs) {
      ids.add(doc.id);
    }
  } catch (error) {
    console.warn("resolveEntityIds teams skipped:", error);
  }
  return ids;
}

async function fetchParticipants(
  db: Firestore,
  entityIds: Set<string>
): Promise<ParticipantRow[]> {
  const rows: ParticipantRow[] = [];
  const ids = [...entityIds];

  for (let i = 0; i < ids.length; i += 10) {
    const chunk = ids.slice(i, i + 10);
    try {
      const snapshot = await db
        .collectionGroup("participants")
        .where("entityId", "in", chunk)
        .get();

      for (const doc of snapshot.docs) {
        const data = doc.data();
        if (data.status === "rejected") continue;
        const tournamentId = doc.ref.parent.parent?.id;
        if (!tournamentId) continue;
        rows.push({
          tournamentId,
          entityId: String(data.entityId ?? ""),
          status: String(data.status ?? "unknown"),
          enrolledAt: (data.enrolledAt as Timestamp | undefined) ?? null,
        });
      }
    } catch (error) {
      console.warn("fetchParticipants chunk skipped:", error);
    }
  }

  return rows;
}

async function loadTournament(
  db: Firestore,
  tournamentId: string
): Promise<{
  name: string;
  scheduledAt: Timestamp | null;
  accessType: string;
  sport: string | null;
} | null> {
  for (const collection of ["tournaments", "private_tournaments"]) {
    const doc = await db.collection(collection).doc(tournamentId).get();
    if (!doc.exists) continue;
    const data = doc.data()!;
    return {
      name: String(data.name ?? "Torneo"),
      scheduledAt: (data.scheduledAt as Timestamp | undefined) ?? null,
      accessType: String(data.accessType ?? collection),
      sport: (data.sport as string | undefined) ?? null,
    };
  }
  return null;
}

async function resolveResultStatus(
  db: Firestore,
  tournamentId: string,
  entityIds: Set<string>,
  scheduledAt: Timestamp | null
): Promise<TournamentHistoryEntry["resultStatus"]> {
  const now = Date.now();
  const scheduledMs = scheduledAt?.toMillis() ?? 0;
  const isPast = scheduledMs > 0 && scheduledMs < now - 24 * 60 * 60 * 1000;

  try {
    const brackets = await db
      .collection("brackets")
      .where("tournamentId", "==", tournamentId)
      .get();

    if (brackets.empty) {
      return isPast ? "participated" : "pending";
    }

    let wonTournament = false;
    let lostMatch = false;

    for (const bracketDoc of brackets.docs) {
      const matches = await bracketDoc.ref.collection("matches").get();
      let maxRound = -1;
      const finalMatches: QueryDocumentSnapshot[] = [];

      for (const matchDoc of matches.docs) {
        const data = matchDoc.data();
        const round = Number(data.round ?? 0);
        if (round > maxRound) {
          maxRound = round;
          finalMatches.length = 0;
          finalMatches.push(matchDoc);
        } else if (round === maxRound) {
          finalMatches.push(matchDoc);
        }
      }

      for (const matchDoc of matches.docs) {
        const data = matchDoc.data();
        const winnerId = data.winnerId as string | undefined;
        const loserId = data.loserId as string | undefined;
        if (winnerId && entityIds.has(winnerId)) {
          const isFinal = finalMatches.some((m) => m.id === matchDoc.id);
          if (isFinal) wonTournament = true;
        }
        if (loserId && entityIds.has(loserId)) {
          lostMatch = true;
        }
      }
    }

    if (wonTournament) return "won";
    if (lostMatch) return "eliminated";
    return isPast ? "participated" : "pending";
  } catch (error) {
    console.warn("resolveResultStatus skipped:", error);
    return isPast ? "participated" : "pending";
  }
}

function placementLabel(
  status: TournamentHistoryEntry["resultStatus"]
): string {
  switch (status) {
  case "won":
    return "Campeon";
  case "eliminated":
    return "Eliminado";
  case "pending":
    return "En curso";
  default:
    return "Participo";
  }
}
