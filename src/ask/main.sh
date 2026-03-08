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
  --plain          Render full response using plain text
  --en | --es      Response language (Default: Spanish)
  --debug        Show metadata and the final constructed technical prompt
  -h, --help       Show this help message

Examples:
  $(basename "$0") --es "Explain what a container is"
  $(basename "$0") "Tell me a motivational quote"
EOF
  exit 0
}

parse_params() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plain) TEXT_PLAIN=true ;;
      --en) LANG_INST="Respond only in English." ;;
      --es) LANG_INST="Respond only in Spanish." ;;
      --debug) DEBUG=true ;;
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

  local pipe_content=""
  local is_piped="NO"
  local line_count=0
  local byte_size=0

  if [[ ! -t 0 ]]; then
    pipe_content=$(cat -)
    is_piped=true
    line_count=$(wc -l <<< "$pipe_content")
    byte_size=$(wc -c <<< "$pipe_content")
  fi

  # Technical Prompt Construction
  local format_inst="Use Markdown."
  [[ "$TEXT_PLAIN" == true ]] && format_inst="Write in plain text. No markdown."
  local SYSTEM_PROMPT="[SYSTEM][MANDATORY]$LANG_INST $BASE_INST $format_inst[/SYSTEM]"
  local FINAL_PROMPT="$SYSTEM_PROMPT[CONTEXT]$pipe_content[/CONTEXT][USER]$QUESTION[/USER]"

  if [[ "$DEBUG" == true ]]; then
    cat << EOF >&2

------- DEBUG -------
Host: $OLLAMA_HOST
Model: $MODEL
Format Style: $([[ "$TEXT_PLAIN" ]] && echo "Text plain" || echo "Markdown")
Stream Data: $([[ "$is_piped" == true ]] && echo "Yes ($line_count lines, $byte_size bytes)" || echo "No")
Prompt:
$(echo "$SYSTEM_PROMPT[CONTEXT](Stream Data...)[/CONTEXT][USER]$QUESTION[/USER]" | fold -s -w 80 | sed 's/^/ /')
---------------------
EOF
  fi

  # Inference execution
  response=$(ollama run "$MODEL" "$FINAL_PROMPT")

  echo -e "\n$response\n"
}

main "$@"
