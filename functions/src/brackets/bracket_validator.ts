// ─────────────────────────────────────────────────────────────────────────────
//  Bracket Validator  ·  Cloud Functions
//
//  Utilidades de validación para garantizar la integridad del árbol
//  de brackets. Se usa antes de publicar y tras operaciones críticas.
// ─────────────────────────────────────────────────────────────────────────────

import {getFirestore} from "firebase-admin/firestore";

interface MatchDoc {
  id: string;
  bracketId: string;
  round: number;
  matchOrder: number;
  participant1Id?: string;
  participant2Id?: string;
  winnerId?: string;
  parentMatch1Id?: string;
  parentMatch2Id?: string;
  childMatchId?: string;
  positionInChild?: number;
  status: string;
}

/**
 * Resultado de la validación del bracket.
 */
export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

/**
 * Valida la integridad completa del árbol de matches de un bracket.
 * @param {string} bracketId ID del bracket a validar.
 * @param {string} databaseId ID de la base de datos Firestore.
 * @return {Promise<ValidationResult>} Resultado de la validación.
 */
export async function validateBracketIntegrity(
  bracketId: string,
  databaseId = "gromy-db",
): Promise<ValidationResult> {
  const db = getFirestore(databaseId);
  const errors: string[] = [];
  const warnings: string[] = [];

  // 1. Obtener todos los matches
  const matchesSnap = await db
    .collection("brackets")
    .doc(bracketId)
    .collection("matches")
    .get();

  if (matchesSnap.empty) {
    errors.push("El bracket no tiene matches.");
    return {valid: false, errors, warnings};
  }

  const matches: MatchDoc[] = matchesSnap.docs.map((doc) => ({
    ...doc.data(),
    id: doc.id,
  })) as MatchDoc[];

  const matchMap = new Map<string, MatchDoc>();
  for (const m of matches) {
    matchMap.set(m.id, m);
  }

  // 2. Validar referencias parent/child
  for (const match of matches) {
    // Verificar que childMatchId exista
    if (match.childMatchId && !matchMap.has(match.childMatchId)) {
      errors.push(
        `Match ${match.id}: childMatchId '${match.childMatchId}' no existe.`
      );
    }

    // Verificar que parentMatch1Id exista
    if (match.parentMatch1Id && !matchMap.has(match.parentMatch1Id)) {
      errors.push(
        `Match ${match.id}: parentMatch1Id '${match.parentMatch1Id}' no existe.`
      );
    }

    // Verificar que parentMatch2Id exista
    if (match.parentMatch2Id && !matchMap.has(match.parentMatch2Id)) {
      errors.push(
        `Match ${match.id}: parentMatch2Id '${match.parentMatch2Id}' no existe.`
      );
    }
  }

  // 3. Verificar que haya exactamente una final (match sin childMatchId)
  const finals = matches.filter(
    (m) => !m.childMatchId || m.childMatchId === ""
  );
  if (finals.length === 0) {
    errors.push("No se encontró match final (sin childMatchId).");
  } else if (finals.length > 1) {
    errors.push(
      `Se encontraron ${finals.length} matches finales. ` +
        "Debe haber exactamente 1."
    );
  }

  // 4. Verificar participantes duplicados en la primera ronda
  const firstRound = matches.filter((m) => m.round === 0);
  const participantIds = new Set<string>();
  for (const match of firstRound) {
    for (const pId of [match.participant1Id, match.participant2Id]) {
      if (pId && pId !== "" && pId !== "BYE") {
        if (participantIds.has(pId)) {
          errors.push(`Participante '${pId}' aparece duplicado en ronda 1.`);
        }
        participantIds.add(pId);
      }
    }
  }

  // 5. Detectar ciclos (un match no puede ser su propio ancestro)
  for (const match of matches) {
    const visited = new Set<string>();
    let current: MatchDoc | undefined = match;
    while (current?.childMatchId) {
      if (visited.has(current.id)) {
        errors.push(`Ciclo detectado involucrando match ${match.id}.`);
        break;
      }
      visited.add(current.id);
      current = matchMap.get(current.childMatchId);
    }
  }

  // 6. Verificar rounds inválidos
  const rounds = new Set(matches.map((m) => m.round));
  const maxRound = Math.max(...rounds);
  for (let r = 0; r <= maxRound; r++) {
    if (!rounds.has(r)) {
      warnings.push(`Round ${r} no tiene matches.`);
    }
  }

  // 7. Verificar matches huérfanos (rounds > 0 sin padres)
  for (const match of matches) {
    if (match.round > 0) {
      if (!match.parentMatch1Id && !match.parentMatch2Id) {
        warnings.push(
          `Match ${match.id} (round ${match.round}) no tiene padres.`
        );
      }
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}
