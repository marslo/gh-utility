#!/usr/bin/env bash
# shellcheck disable=SC2207
#=============================================================================
#     FileName : gh-arsenal-completion.sh
#       Author : marslo
#      Created : 2026-02-27 23:04:41
#   LastChange : 2026-05-07 00:34:36
#  Description : bash_completion for $ gh-ops, $ gh ops, $ gh-new, $ gh new
#=============================================================================

function _compgen_nocase() {
  local cur="$1"
  local candidates="$2"
  local word

  COMPREPLY=()
  for word in ${candidates}; do
    if [[ "${word,,}" == "${cur,,}"* ]]; then
      COMPREPLY+=( "${word}" )
    fi
  done
}

#=============================================================================#
# gh-ops: passthrough completion after '--'                                   #
#   ops flag → gh pr subcommand, then ask gh's own __complete engine         #
#=============================================================================#
# map an ops flag to the gh-pr subcommand it delegates to
function __gh_ops_flag_to_subcmd() {
  case "$1" in
    -c | --checkout       ) echo 'checkout' ;;
    -C | --close          ) echo 'close'    ;;
    -s | --squash         ) echo 'merge'    ;;
    -r | --rebase         ) echo 'merge'    ;;
    -a | --approve        ) echo 'review'   ;;
    -M | --comment        ) echo 'review'   ;;
         --request-changes) echo 'review'   ;;
  esac
}

# dynamically fetch flags from `gh __complete pr <subcmd>`, strip meta-flags already handled by gh-ops itself (--help, --repo)
function __gh_ops_passthrough_complete() {
  local subcmd="${1}" cur="${2}"
  [[ -z "${subcmd}" ]] && return

  local raw flags
  raw=$(gh __complete pr "${subcmd}" '' "${cur}" 2>/dev/null) || true
  flags=$(
    printf '%s\n' "${raw}" \
      | sed 's/[[:space:]].*//' \
      | grep --color=never -E '^--' \
      | grep --color=never -vE '^--(help|repo)$' \
      || true
  )
  [[ -z "${flags}" ]] && return
  # shellcheck disable=SC2207
  COMPREPLY=( $(compgen -W "${flags}" -- "${cur}") )
}

#=============================================================================#
# gh-ops shared completion logic                                              #
#=============================================================================#
function __gh_ops_do_complete() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local opts="-c --checkout
              -C --close
              -o --open
              -A --auto-open
              -s --squash
              -r --rebase
              -l --add-label
              -L --remove-label
              -M --comment
              -a --approve
              --request-changes
              --ready
              --draft
              -S --state
              -B --base
              -R --repo
              -v --verbose
              --setup
              --dryrun
              -h --help"

  case "${prev}" in
    -S|--state ) COMPREPLY=( $(compgen -W "open closed all merged" -- "${cur}") ); return ;;
    -B|--base  ) COMPREPLY=( $(compgen -W "$(git branch --format='%(refname:short)' 2>/dev/null)" -- "${cur}") ); return ;;
    -R|--repo  ) local repos=''
                 repos="$(gh repo list --json nameWithOwner -q '.[].nameWithOwner' 2>/dev/null)"
                 local private_repos_file="${GH_OPS_REPOS_FILE:-${HOME}/.config/gh/repos}"
                 [[ -f "${private_repos_file}" ]] && repos+=$'\n'"$(cat "${private_repos_file}")"
                 _compgen_nocase "${cur}" "${repos}"; return ;;
    -l|--add-label|-L|--remove-label|-M|--comment|--request-changes|-a|--approve ) COMPREPLY=(); return ;;
  esac

  # ── after '--': context-sensitive passthrough completion ───────────────────
  local dashdash_pos=-1
  for (( i=1; i < COMP_CWORD; i++ )); do
    [[ "${COMP_WORDS[i]}" == "--" ]] && { dashdash_pos=${i}; break; }
  done

  if (( dashdash_pos >= 0 )); then
    local subcmd='' _w
    for (( i=1; i < dashdash_pos; i++ )); do
      _w="${COMP_WORDS[i]}"
      case "${_w}" in
        -c|--checkout        ) subcmd='checkout'; break ;;
        -C|--close           ) subcmd='close';    break ;;
        -s|--squash          ) subcmd='merge';    break ;;
        -r|--rebase          ) subcmd='merge';    break ;;
        -a|--approve         ) subcmd='review';   break ;;
        -M|--comment         ) subcmd='review';   break ;;
           --request-changes ) subcmd='review';   break ;;
      esac
    done
    __gh_ops_passthrough_complete "${subcmd}" "${cur}"
    return
  fi

  if [[ ${cur} == -* ]] || [[ ${COMP_CWORD} -ge 1 ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
  fi
}

#=============================================================================#
# gh-new shared completion logic                                              #
#=============================================================================#
function __gh_new_do_complete() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local opts="-o --open
              -l --label
              -v --verbose
              -a --auto
              -d --draft
              -D --dryrun
              -h --help"

  case "${prev}" in
    -l|--label ) COMPREPLY=(); return ;;
  esac

  for (( i=1; i < COMP_CWORD; i++ )); do
    [[ "${COMP_WORDS[i]}" == "--" ]] && return
  done

  if [[ ${cur} == -* ]] || [[ ${COMP_CWORD} -ge 1 ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
  fi
}

#=============================================================================#
# for $ gh-ops <tab>                                                          #
#=============================================================================#
function _gh_ops() { __gh_ops_do_complete; }
complete -F _gh_ops gh-ops

#=============================================================================#
# for $ gh-new <tab>                                                          #
#=============================================================================#
function _gh_new() { __gh_new_do_complete; }
complete -F _gh_new gh-new

#=============================================================================#
# for $ gh ops <tab> and $ gh new <tab>                                      #
#=============================================================================#
__orig_start_gh=$(declare -f __start_gh)
eval "${__orig_start_gh//__start_gh/__start_gh_orig}"

function __start_gh() {
  case "${COMP_WORDS[1]}" in
    ops ) [[ ${COMP_CWORD} -ge 2 ]] && { __gh_ops_do_complete; return; } ;;
    new ) [[ ${COMP_CWORD} -ge 2 ]] && { __gh_new_do_complete; return; } ;;
  esac
  __start_gh_orig "$@"
}

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
