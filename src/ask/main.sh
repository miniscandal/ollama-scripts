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
  --verbose        Show metadata and the final constructed technical prompt
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
      --verbose) VERBOSE=true ;;
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

  # Format instruction injection based on the rendering tool
  local format_inst="Use Markdown."
  [[ "$TEXT_PLAIN" == true ]] && format_inst="Write in plain text. No markdown."

  # Technical Prompt Construction (System Prompt Emulation)
  local final_prompt="[SYSTEM][MANDATORY] $LANG_INST $BASE_INST $format_inst [/SYSTEM]\nUSER: $QUESTION"

  if [[ "$VERBOSE" == true ]]; then
    echo -e "--- VERBOSE ---\nHost: $OLLAMA_HOST\nModel: $MODEL\nPrompt: $final_prompt\n-------------"
  fi

  # Inference execution
  response=$(ollama run "$MODEL" "$final_prompt")

  echo "$response"
}

main "$@"
