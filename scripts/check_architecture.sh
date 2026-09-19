#!/usr/bin/env bash
# Architecture enforcement script.
# Fails if the "downward-only imports" rule is violated.
#
# Run manually: bash scripts/check_architecture.sh
# Run in CI: add to .github/workflows/verify.yml

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

violations=0

fail() {
  echo -e "${RED}✗ $1${NC}"
  violations=$((violations + 1))
}

pass() {
  echo -e "${GREEN}✓ $1${NC}"
}

# ============================================================================
# Rule 1: No Dio imports outside lib/backend/
# ============================================================================

echo "→ Rule 1: no package:dio outside lib/backend/"

dio_violations=$(grep -rn "import 'package:dio" lib/ \
  --include="*.dart" \
  2>/dev/null \
  | grep -v "^lib/backend/" \
  | grep -v "// ignore_architecture" \
  || true)

if [[ -n "$dio_violations" ]]; then
  echo "$dio_violations" | while read -r line; do
    fail "Dio imported outside backend: $line"
  done
  violations=$((violations + $(echo "$dio_violations" | wc -l)))
else
  pass "No Dio imports outside backend"
fi

# ============================================================================
# Rule 2: No upward imports
# ============================================================================

echo ""
echo "→ Rule 2: no upward imports"

# core/ must not import from domain, backend, features, app
core_violations=$(grep -rn "import 'package:golden_feather_eld/\(domain\|backend\|features\|app\)/" \
  lib/core/ --include="*.dart" 2>/dev/null \
  || true)

if [[ -n "$core_violations" ]]; then
  echo "$core_violations" | while read -r line; do
    fail "core/ imports upward: $line"
  done
  violations=$((violations + $(echo "$core_violations" | wc -l)))
else
  pass "core/ has no upward imports"
fi

# domain/ must not import from backend, features, app
domain_violations=$(grep -rn "import 'package:golden_feather_eld/\(backend\|features\|app\)/" \
  lib/domain/ --include="*.dart" 2>/dev/null \
  || true)

if [[ -n "$domain_violations" ]]; then
  echo "$domain_violations" | while read -r line; do
    fail "domain/ imports upward: $line"
  done
  violations=$((violations + $(echo "$domain_violations" | wc -l)))
else
  pass "domain/ has no upward imports"
fi

# backend/ must not import from features, app
backend_violations=$(grep -rn "import 'package:golden_feather_eld/\(features\|app\)/" \
  lib/backend/ --include="*.dart" 2>/dev/null \
  || true)

if [[ -n "$backend_violations" ]]; then
  echo "$backend_violations" | while read -r line; do
    fail "backend/ imports upward: $line"
  done
  violations=$((violations + $(echo "$backend_violations" | wc -l)))
else
  pass "backend/ has no upward imports"
fi

# ============================================================================
# Rule 3: No cross-feature imports
# ============================================================================

echo ""
echo "→ Rule 3: no cross-feature imports"

cross_feature=0
for feature_dir in lib/features/*/; do
  feature=$(basename "$feature_dir")
  # Skip if not a directory
  [[ -d "$feature_dir" ]] || continue

  # Check imports of other features
  other_features=$(grep -rn "import 'package:golden_feather_eld/features/" \
    "$feature_dir" --include="*.dart" 2>/dev/null \
    | grep -v "features/$feature/" \
    | grep -v "// ignore_architecture" \
    || true)

  if [[ -n "$other_features" ]]; then
    echo "$other_features" | while read -r line; do
      fail "features/$feature/ imports another feature: $line"
    done
    cross_feature=$((cross_feature + $(echo "$other_features" | wc -l)))
  fi
done

if [[ $cross_feature -eq 0 ]]; then
  pass "No cross-feature imports"
fi
violations=$((violations + cross_feature))

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "════════════════════════════════════════"
if [[ $violations -eq 0 ]]; then
  echo -e "${GREEN}✓ Architecture checks passed${NC}"
  exit 0
else
  echo -e "${RED}✗ $violations violation(s) found${NC}"
  exit 1
fi
