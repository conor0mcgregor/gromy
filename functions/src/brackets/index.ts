// ─────────────────────────────────────────────────────────────────────────────
//  Brackets Module  ·  Barrel Export
//
//  Re-exporta todos los componentes del sistema de brackets.
// ─────────────────────────────────────────────────────────────────────────────

export {generateBracket} from "./generate_bracket";
export {publishBracket, regenerateBracket} from "./publish_bracket";
export {onMatchWinnerUpdated} from "./on_match_winner_updated";
export {validateBracketIntegrity} from "./bracket_validator";
export {
  recordMatchResult,
  updateMatchSchedule,
  swapMatchParticipants,
} from "./match_admin";
