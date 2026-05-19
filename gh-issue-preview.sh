#!/usr/bin/env bash
# shellcheck disable=SC2155
#=============================================================================
#     FileName : gh-issue-preview.sh
#       Author : marslo
#      Created : 2026-05-18 20:50:00
#   LastChange : 2026-05-18 20:56:16
#  Description : fzf REMOTE preview for GitHub issues (text + inline images)
#       Syntax : gh-ops-issue-preview.sh <issue_id>
#=============================================================================

set -euo pipefail

declare _id="${1:?issue id required}"
declare _HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")"
declare _JQ_FILE="${_HERE}/gh-issue-preview.jq"

[[ -f "${_JQ_FILE}" ]] || { echo "ERROR: missing ${_JQ_FILE}"; exit 1; }

# fetch issue JSON once
declare _json
_json=$(gh issue view "${_id}" \
        --json state,stateReason,author,createdAt,updatedAt,labels,assignees,milestone,comments,body \
        2>/dev/null) || { echo "Failed to fetch issue #${_id}"; exit 1; }

# formatted text output
echo "${_json}" | jq -r "$(cat "${_JQ_FILE}")"

# ======================================================================== #
# inline image preview: extract image URLs from body, download & display   #
# ======================================================================== #
declare _body
_body=$(echo "${_json}" | jq -r '.body // ""')

declare -a _urls=()
while IFS= read -r _url; do
  [[ -n "${_url}" ]] && _urls+=("${_url}")
done < <(
  # <img ... src="URL" ...>
  echo "${_body}" | grep -oE 'src="[^"]+"' | sed 's/^src="//;s/"$//'
  # ![alt](URL)
  echo "${_body}" | grep -oE '!\[[^]]*\]\([^)]+\)' | sed 's/^!\[[^]]*\](//;s/)$//'
)

[[ ${#_urls[@]} -eq 0 ]] && exit 0

declare CHAFA_PATH="$(type -P chafa 2>/dev/null || true)"
declare -a CHAFA_CMD=( "${CHAFA_PATH}" --center on )

function _show_image() {
  local _file="${1:?}"
  local dim="${FZF_PREVIEW_COLUMNS:-80}x${FZF_PREVIEW_LINES:-40}"

  if { [[ ${KITTY_WINDOW_ID:-} ]] || [[ ${GHOSTTY_RESOURCES_DIR:-} ]]; } && type -P kitten >/dev/null 2>&1; then
    kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place="${dim}@0x0" "${_file}" | sed '$d' | sed $'$s/$/\e[m/'
  elif [[ -x "${CHAFA_PATH}" ]]; then
    "${CHAFA_CMD[@]}" --size "${dim}" "${_file}"
  elif type -P imgcat >/dev/null 2>&1; then
    imgcat -W "${FZF_PREVIEW_COLUMNS:-80}" -H "${FZF_PREVIEW_LINES:-40}" "${_file}"
  fi
}

declare -a _tmpfiles=()
trap 'rm -f "${_tmpfiles[@]}" 2>/dev/null' EXIT

printf '\n\033[2;3;37m── Images ──\033[0m\n'
for _url in "${_urls[@]:0:3}"; do
  _tmpfile="/tmp/gh_issue_img_$$_$(echo "${_url}" | md5sum 2>/dev/null | cut -c1-8 || echo "${RANDOM}")"
  _tmpfiles+=("${_tmpfile}")
  if curl -sL --max-time 5 -o "${_tmpfile}" "${_url}" 2>/dev/null; then
    _mime=$(file --brief --dereference --mime -- "${_tmpfile}" 2>/dev/null)
    if [[ ${_mime} =~ image/ ]]; then
      _show_image "${_tmpfile}"
    fi
  fi
done

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
