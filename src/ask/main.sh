#!/usr/bin/env bash

# ==============================================================================
# SCRIPT: ask.sh
# DESCRIPTION: CLI client for Ollama.
# REQUIREMENTS: ollama Server, curl.
# ==============================================================================

# Environment Configuration
: "${OLLAMA_HOST:?}"

if ! curl -s -I --connect-timeout 2 --max-time 3 "http://$OLLAMA_HOST" > /dev/null; then
  echo "Error: Ollama server is unreachable at $OLLAMA_HOST" >&2
  exit 1
fi

TEXT_PLAIN=false
MODEL="granite4:latest"
LANG_INST="Respond only in Spanish."
BASE_INST="Be brief and concise."

show_help() {
  cat << EOF
Usage: $(basename "$0") [FLAGS] "PROMPT"

Description:
  Simple CLI interface for Ollama. Any arguments not recognized as flags
  are automatically concatenated as the message body (Prompt).

Options:
  --plain | -p   Render full response using plain text
  --en | --es    Response language (Default: Spanish)
  --debug | -d   Show metadata and the final constructed technical prompt
  -h, --help     Show this help message

Examples:
  $(basename "$0") --es "Explain what a container is"
  $(basename "$0") "Tell me a motivational quote"
EOF
  exit 0
}

parse_params() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plain | -p) TEXT_PLAIN=true ;;
      --en) LANG_INST="Respond only in English." ;;
      --es) LANG_INST="Respond only in Spanish." ;;
      --debug | -d) DEBUG=true ;;
      -h | --help) show_help ;;
      --)
        shift
        break
        ;;
      --* | -*)
        echo "Error: Unrecognized flag '$1'" >&2
        show_help
        ;;
      *) break ;;
    esac
    shift
  done
  QUESTION="$*"
}

main() {
  parse_params "$@"
  [[ -z "$QUESTION" ]] && show_help

  local input_data=""
  local has_input=false
  local line_count=0
  local byte_size=0

  if [[ ! -t 0 ]]; then
    input_data=$(cat -)
    has_input=true
    line_count=$(wc -l <<< "$input_data")
    byte_size=$(wc -c <<< "$input_data")
  fi

  local format_inst="Use Markdown."
  $TEXT_PLAIN && format_inst="Write in plain text. No markdown."

  local SYSTEM_PROMPT="[SYSTEM][MANDATORY]$LANG_INST $BASE_INST $format_inst[/SYSTEM]"
  local CONTEXT_BLOCK="[CONTEXT]${input_data:-"No stream data provided."}[/CONTEXT]"
  local FINAL_PROMPT="${SYSTEM_PROMPT}${CONTEXT_BLOCK}[USER]${QUESTION}[/USER]"

  if [[ "$DEBUG" == true ]]; then
    local DEBUG_PROMPT="${SYSTEM_PROMPT}[CONTEXT](Stream Data, lines: $line_count, size: $byte_size)[/CONTEXT][USER]${QUESTION}[/USER]"
    cat << EOF >&2
------- DEBUG -------
Host: $OLLAMA_HOST | Model: $MODEL
Format: $($TEXT_PLAIN && echo "Plain" || echo "Markdown")
Stream Data: $($has_input && echo "YES (lines: $line_count, size: $byte_size)" || echo "NO")
Prompt Structure:
$(echo "$DEBUG_PROMPT" | fold -s -w 80 | sed 's/^/  /')
---------------------
EOF
  fi

  echo -e "\n$(ollama run "$MODEL" "$FINAL_PROMPT")\n"
}

main "$@"
