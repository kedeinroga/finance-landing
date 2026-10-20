#!/usr/bin/env bash
# Security gate shared by finance-api, finance-app and finance-landing.
# Runs in CI (.github/workflows/security.yml) and locally with the same result.
#   Usage: .github/scripts/security-gate.sh <lockfile>     full gate
#          .github/scripts/security-gate.sh --secrets-only  registry + secrets only (finance-infra)
#   Needs on PATH: gitleaks, jq, git; the full gate also needs osv-scanner and semgrep.
# Checks (all run, then one verdict): exception registry integrity, secrets over the whole git
# history, dependency vulnerabilities (blocks on CVSS >= 9), SAST (blocks on Semgrep ERROR).
# Exceptions live in the repo: .gitleaksignore, osv-scanner.toml, .trivyignore.yaml and inline
# `nosemgrep` comments.
set -u

case "${1:-}" in
  "") echo "usage: security-gate.sh <lockfile> | --secrets-only" >&2; exit 2 ;;
  --secrets-only) MODE=secrets; LOCKFILE="" ;;
  *) MODE=full; LOCKFILE="$1" ;;
esac
TODAY=$(date -u +%F)
CRITICAL_CVSS=9
fail=0

say() { echo "$*"; [ -n "${GITHUB_STEP_SUMMARY:-}" ] && echo "$*" >> "$GITHUB_STEP_SUMMARY"; return 0; }
bad() { say "FAIL: $*"; fail=1; }

# expires=YYYY-MM-DD must be present and in the future (unless `never` is allowed) and a reason is mandatory.
check_annotation() { # $1 where, $2 annotation text, $3 allow_never(0|1)
  local where="$1" text="$2" allow_never="$3" date
  [[ $text == *'reason="'* ]] || { bad "$where: exception without reason=\"...\""; return; }
  if [[ $text =~ expires=([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    date="${BASH_REMATCH[1]}"
    [[ "$date" > "$TODAY" ]] || bad "$where: exception expired on $date"
  elif [[ $text == *expires=never* && $allow_never == 1 ]]; then
    :
  else
    bad "$where: exception without a valid expires=YYYY-MM-DD"
  fi
}

say "## Security gate ($TODAY)"

# --- 1. Exception registry integrity -----------------------------------------------------------
say "### Active exceptions"
if [ -f .gitleaksignore ]; then
  last_comment=""
  while IFS= read -r line; do
    case "$line" in
      "") ;;
      \#*) last_comment="$line" ;;
      *) say "- gitleaks: ${line%%:*}... ${last_comment}"; check_annotation ".gitleaksignore ($line)" "$last_comment" 1; last_comment="" ;;
    esac
  done < .gitleaksignore
fi
if [ -f osv-scanner.toml ]; then
  n_ids=$(grep -c '^\[\[IgnoredVulns\]\]' osv-scanner.toml || true)
  n_until=$(grep -c '^ignoreUntil *= *' osv-scanner.toml || true)
  n_reason=$(grep -c '^reason *= *"' osv-scanner.toml || true)
  [ "$n_ids" = "$n_until" ] && [ "$n_ids" = "$n_reason" ] || bad "osv-scanner.toml: every [[IgnoredVulns]] needs ignoreUntil and reason"
  grep -E '^(id|ignoreUntil) *=' osv-scanner.toml | paste -sd' ' - | sed 's/id =/\n- osv: id =/g' | sed '/^$/d' | while IFS= read -r l; do say "$l"; done
fi
if [ -f .trivyignore.yaml ]; then
  n_id=$(grep -c '^ *- id:' .trivyignore.yaml || true)
  n_st=$(grep -c '^ *statement:' .trivyignore.yaml || true)
  n_ex=$(grep -c '^ *expired_at:' .trivyignore.yaml || true)
  [ "$n_id" = "$n_st" ] && [ "$n_id" = "$n_ex" ] || bad ".trivyignore.yaml: every entry needs statement and expired_at"
  grep -E '^ *- id:' .trivyignore.yaml | while IFS= read -r l; do say "- trivy:${l#*id:}"; done
fi
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  say "- semgrep: $hit"
  check_annotation "${hit%%:*}:$(echo "$hit" | cut -d: -f2)" "$hit" 0
done < <(git grep -n 'nosemgrep' -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.mjs' '*.cjs' '*.astro' || true)

# --- 2. Secrets over the whole history ---------------------------------------------------------
say "### Secrets (gitleaks, full history)"
if gitleaks git . --no-banner --redact -l warn --exit-code 1; then say "ok"; else bad "gitleaks found secrets (rotate them, then add the fingerprint to .gitleaksignore with expires= and reason=)"; fi

if [ "$MODE" = secrets ]; then
  say "### Verdict: $([ "$fail" = 0 ] && echo PASS || echo FAIL)"
  exit "$fail"
fi

# --- 3. Dependencies ---------------------------------------------------------------------------
say "### Dependencies (osv-scanner on $LOCKFILE, blocks on CVSS >= $CRITICAL_CVSS)"
osv_args=(scan source --format json --lockfile "$LOCKFILE")
[ -f osv-scanner.toml ] && osv_args+=(--config osv-scanner.toml)
osv-scanner "${osv_args[@]}" > osv-report.json 2> osv-stderr.txt
osv_rc=$?
if [ "$osv_rc" -ne 0 ] && [ "$osv_rc" -ne 1 ]; then
  bad "osv-scanner failed (exit $osv_rc): $(tail -3 osv-stderr.txt)"
else
  crit=$(jq -r --argjson t "$CRITICAL_CVSS" '[.results[]?.packages[]? | .package as $p | .groups[]? | select(((.max_severity // "0") | tonumber) >= $t) | "\(.ids[0]) \($p.name)@\($p.version) cvss=\(.max_severity)"] | .[]' osv-report.json)
  high=$(jq -r --argjson t "$CRITICAL_CVSS" '[.results[]?.packages[]?.groups[]? | select(((.max_severity // "0") | tonumber) >= 7 and ((.max_severity // "0") | tonumber) < $t)] | length' osv-report.json)
  say "HIGH (7.0-8.9, informational, not blocking): $high"
  if [ -n "$crit" ]; then bad "CRITICAL vulnerabilities:"; echo "$crit" | while IFS= read -r l; do say "  - $l"; done; else say "ok (no CRITICAL)"; fi
fi
rm -f osv-report.json osv-stderr.txt

# --- 4. SAST -----------------------------------------------------------------------------------
say "### SAST (semgrep, blocks on ERROR)"
if semgrep scan --config p/typescript --config p/nodejs --config p/security-audit \
     --metrics=off --quiet --severity ERROR --error .; then say "ok"; else bad "semgrep found ERROR-level issues (fix, or annotate with nosemgrep: <rule> -- expires=YYYY-MM-DD reason=\"...\")"; fi

say "### Verdict: $([ "$fail" = 0 ] && echo PASS || echo FAIL)"
exit "$fail"
