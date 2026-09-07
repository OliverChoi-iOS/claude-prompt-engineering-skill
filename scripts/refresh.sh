#!/usr/bin/env bash
# Re-download the bundled Anthropic prompt-engineering docs from platform.claude.com.
#
# The docs site serves a plain-markdown version of every page at <page-url>.md, which is
# what the reference files in this skill are: verbatim copies, not summaries. Run this when
# a new model ships or when a bundled page looks out of date, then skim the diff — the
# symptom index in SKILL.md points at section headings, so a renamed section needs a
# matching edit there.
#
#   ./scripts/refresh.sh              # refresh the pages listed below
#   ./scripts/refresh.sh --check      # report drift without writing anything
#
# To add a model, append a "<local-name>|<doc-slug>" line to PAGES and add a row to the
# model table in SKILL.md.

set -euo pipefail

BASE="https://platform.claude.com/docs/en/build-with-claude/prompt-engineering"
REF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/references"

PAGES=(
  "core-techniques|claude-prompting-best-practices"
  "model-fable-5-1|prompting-claude-fable-5-1"
  "model-fable-5|prompting-claude-fable-5"
  "model-opus-5|prompting-claude-opus-5"
  "model-sonnet-5|prompting-claude-sonnet-5"
  "model-opus-4-8|prompting-claude-opus-4-8"
)

CHECK_ONLY=0
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=1

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

changed=0
failed=0

for entry in "${PAGES[@]}"; do
  local_name="${entry%%|*}"
  slug="${entry##*|}"
  dest="$REF_DIR/$local_name.md"
  src="$tmp/$local_name.md"

  code="$(curl -sSL --max-time 60 -o "$src" -w '%{http_code}' "$BASE/$slug.md" || echo 000)"

  if [[ "$code" != "200" ]] || [[ ! -s "$src" ]]; then
    printf '  FAIL  %-18s HTTP %s\n' "$local_name" "$code"
    failed=$((failed + 1))
    continue
  fi

  # A redirect to the SPA shell returns HTML, not front-matter markdown. Reject it rather
  # than overwriting a good reference file with a login page.
  if ! head -n 1 "$src" | grep -q '^---$'; then
    printf '  FAIL  %-18s not markdown (got %s bytes of something else)\n' \
      "$local_name" "$(wc -c <"$src" | tr -d ' ')"
    failed=$((failed + 1))
    continue
  fi

  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    printf '  same  %-18s\n' "$local_name"
    continue
  fi

  changed=$((changed + 1))
  if [[ "$CHECK_ONLY" == "1" ]]; then
    printf '  DRIFT %-18s (run without --check to update)\n' "$local_name"
  else
    cp "$src" "$dest"
    printf '  wrote %-18s %s bytes\n' "$local_name" "$(wc -c <"$dest" | tr -d ' ')"
  fi
done

echo
if [[ "$failed" -gt 0 ]]; then
  echo "$failed page(s) failed; existing copies left untouched."
  exit 1
fi
if [[ "$changed" -eq 0 ]]; then
  echo "All bundled docs are current."
else
  echo "$changed page(s) differ. Review the diff and update SKILL.md if section names moved."
fi
