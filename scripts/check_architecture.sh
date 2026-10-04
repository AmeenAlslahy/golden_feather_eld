#!/usr/bin/env bash
# Architecture enforcement script.
# Fails if the "downward-only imports" rule is violated.
#
# Run manually: bash scripts/check_architecture.sh
# Run strictly: bash scripts/check_architecture.sh --strict
# Run in CI: add to .github/workflows/verify.yml
#
# Modes
# ─────
#   default    Hard-fail on untagged package-import violations and Dio leaks.
#              Relative-import violations are REPORTED (count + pair summary)
#              but do not fail the gate, so delivery work is not blocked.
#   --strict   Relative-import violations also fail. This is the target mode
#              once the cross-feature refactor waves land.
#
# Lines carrying `// ignore_architecture` are treated as acknowledged:
# they are listed under ACKNOWLEDGED and never counted as failures.
#
# NOTE: this script now resolves RELATIVE imports as well. The previous
# version only matched `package:golden_feather_eld/...` imports, so the
# majority of cross-feature/upward violations (relative form) were invisible.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

STRICT=0
[[ "${1:-}" == "--strict" ]] && STRICT=1

hard_count=0
warn_count=0
tagged_count=0

fail() {
  echo -e "${RED}✗ $1${NC}"
  hard_count=$((hard_count + 1))
}

warn() {
  echo -e "${YELLOW}⚠ $1${NC}"
  warn_count=$((warn_count + 1))
}

acknowledged() {
  tagged_count=$((tagged_count + 1))
  echo "  acknowledged: $1"
}

pass() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Collapse "dir/../x" and "./x" path segments in pure bash (no subprocesses).
resolve_rel() {
  local dir="$1" imp="$2"
  local p="$dir/$imp"
  local out=() part n
  IFS='/' read -ra parts <<< "$p"
  for part in "${parts[@]}"; do
    case "$part" in
      "" | ".") continue ;;
      "..")
        n=${#out[@]}
        if ((n > 1)); then unset "out[$((n - 1))]"; fi
        ;;
      *) out+=("$part") ;;
    esac
  done
  local IFS='/'
  echo "${out[*]}"
}

# Region of a lib/ path: core | domain | backend | app | feature:<name> | root
region_of() {
  case "$1" in
    lib/core/*) echo "core" ;;
    lib/domain/*) echo "domain" ;;
    lib/backend/*) echo "backend" ;;
    lib/app/*) echo "app" ;;
    lib/features/*) echo "feature:$(echo "$1" | cut -d/ -f3)" ;;
    *) echo "root" ;;
  esac
}

# Extract the lib/-relative target of an import. Sets globals TARGET and
# KIND (package|relative|external).
parse_import() {
  local imp="$1"
  TARGET=""
  KIND="external"
  if [[ "$imp" == package:golden_feather_eld/* ]]; then
    TARGET="${imp#package:golden_feather_eld/}"
    KIND="package"
  elif [[ "$imp" == ./* || "$imp" == ../* ]]; then
    TARGET="$imp"
    KIND="relative"
  fi
}

# ============================================================================
# Rule 1: No Dio imports outside lib/backend/
# ============================================================================

echo "→ Rule 1: no package:dio outside lib/backend/"

dio_violations=$(grep -rn "import 'package:dio" lib/ \
  --include="*.dart" \
  2>/dev/null \
  | grep -v "^lib/backend/" \
  || true)

if [[ -n "$dio_violations" ]]; then
  while read -r line; do
    if [[ "$line" == *ignore_architecture* ]]; then
      acknowledged "$line"
    else
      fail "Dio imported outside backend: $line"
    fi
  done <<< "$dio_violations"
else
  pass "No Dio imports outside backend"
fi

# ============================================================================
# Rules 2 + 3: upward imports and cross-feature imports
# (package: and relative: — relative was previously invisible to this script)
# ============================================================================

echo ""
echo "→ Rule 2: no upward imports (core/domain/backend)"
echo "→ Rule 3: no cross-feature imports"

upward_hard=0
cross_pkg_hard=0
cross_rel=0

# Pair summary for the cross-feature report (source feature -> target feature)
declare -A cross_pairs=()

while IFS= read -r -d '' f; do
  src_region=$(region_of "$f")
  src_dir=$(dirname "$f")

  while IFS= read -r line; do
    lineno="${line%%:*}"
    content="${line#*:}"
    imp=$(printf '%s\n' "$content" | sed -E "s/.*import ['\"]([^'\"]+)['\"].*/\1/")
    parse_import "$imp"

    [[ -z "$TARGET" ]] && continue
    tagged=no
    [[ "$content" == *ignore_architecture* ]] && tagged=yes

    label="$f:$lineno"

    # Resolve the target region.
    if [[ "$KIND" == "package" ]]; then
      tgt_region=$(region_of "lib/$TARGET")
    else
      resolved=$(resolve_rel "$src_dir" "$TARGET")
      tgt_region=$(region_of "$resolved")
    fi

    # Rule 2: upward imports.
    if [[ "$src_region" == "core" ]] &&
      [[ "$tgt_region" == "domain" || "$tgt_region" == "backend" || "$tgt_region" == "feature:"* || "$tgt_region" == "app" ]]; then
      if [[ "$tagged" == "yes" ]]; then
        acknowledged "core→${tgt_region#feature:} — $label"
      elif [[ "$KIND" == "package" ]] || ((STRICT)); then
        fail "core/ imports upward: $label → $imp"
        upward_hard=$((upward_hard + 1))
      else
        warn "core/ imports upward (relative): $label → $imp"
      fi
      continue
    fi

    if [[ "$src_region" == "domain" ]] &&
      [[ "$tgt_region" == "backend" || "$tgt_region" == "feature:"* || "$tgt_region" == "app" ]]; then
      if [[ "$tagged" == "yes" ]]; then
        acknowledged "domain↑ — $label"
      elif [[ "$KIND" == "package" ]] || ((STRICT)); then
        fail "domain/ imports upward: $label → $imp"
        upward_hard=$((upward_hard + 1))
      else
        warn "domain/ imports upward (relative): $label → $imp"
      fi
      continue
    fi

    if [[ "$src_region" == "backend" ]] &&
      [[ "$tgt_region" == "feature:"* || "$tgt_region" == "app" ]]; then
      if [[ "$tagged" == "yes" ]]; then
        acknowledged "backend↑ — $label"
      elif [[ "$KIND" == "package" ]] || ((STRICT)); then
        fail "backend/ imports upward: $label → $imp"
        upward_hard=$((upward_hard + 1))
      else
        warn "backend/ imports upward (relative): $label → $imp"
      fi
      continue
    fi

    # Rule 3: cross-feature imports.
    if [[ "$src_region" == "feature:"* && "$tgt_region" == "feature:"* ]]; then
      src_feat="${src_region#feature:}"
      tgt_feat="${tgt_region#feature:}"
      [[ "$src_feat" == "$tgt_feat" ]] && continue
      pair="$src_feat->$tgt_feat"
      cross_pairs["$pair"]=$(( ${cross_pairs["$pair"]:-0} + 1 ))
      if [[ "$tagged" == "yes" ]]; then
        acknowledged "cross-feature $pair — $label"
      elif [[ "$KIND" == "package" ]]; then
        fail "features/$src_feat/ imports another feature (package): $label → $imp"
        cross_pkg_hard=$((cross_pkg_hard + 1))
      elif ((STRICT)); then
        fail "features/$src_feat/ imports another feature (relative): $label → $imp"
        cross_rel=$((cross_rel + 1))
      else
        warn "features/$src_feat/ imports another feature (relative): $label → $imp"
        cross_rel=$((cross_rel + 1))
      fi
    fi
  done < <(grep -nE "import ['\"]" "$f" 2>/dev/null || true)
done < <(find lib -name "*.dart" -print0 | sort -z)

if ((upward_hard == 0)); then
  pass "No untagged upward imports (package or relative)"
fi

if ((cross_pkg_hard == 0)); then
  pass "No untagged package cross-feature imports"
fi

echo ""
echo "→ Relative cross-feature summary (informational; fails under --strict):"
if ((cross_rel == 0)); then
  echo "  none"
else
  for pair in "${!cross_pairs[@]}"; do
    echo "  $pair: ${cross_pairs[$pair]}"
  done | sort
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "════════════════════════════════════════"
echo "acknowledged via // ignore_architecture: $tagged_count"
echo "relative violations (warn-only; fail under --strict): $warn_count"

if ((hard_count == 0)); then
  echo -e "${GREEN}✓ Architecture checks passed${NC}"
  exit 0
else
  echo -e "${RED}✗ $hard_count violation(s) found${NC}"
  exit 1
fi
