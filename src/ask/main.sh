#!/usr/bin/env bash

# ==============================================================================
# SCRIPT: ask.sh
# DESCRIPTION: CLI client for Ollama optimized for hybrid environments (WSL).
# REQUIREMENTS: ollama (host), glow/batcat (rendering), curl.
# ==============================================================================

# --- Environment Configuration (Fail-fast) ---
: "${OLLAMA_HOST:?Error: OLLAMA_HOST is not defined. Example: export OLLAMA_HOST=127.0.0.1:11434}"
export OLLAMA_HOST=$(ip route show default | awk '{print $3}'):11434

MODEL="granite4:latest"
FORMAT=""
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

# --- Infrastructure Management ---
# If the server is unreachable, it attempts to launch it on the Windows host via PowerShell.
# Designed for WSL workflows where Ollama runs on the Windows side.
check_server() {
  if ! curl -s -I --connect-timeout 2 "http://$OLLAMA_HOST" > /dev/null; then
    echo -n "Ollama not detected at $OLLAMA_HOST. Attempting to start service..."
    powershell.exe -command "Start-Process 'ollama' -ArgumentList 'serve'"

    # Polling loop: waits until the socket accepts connections
    until curl -s "http://$OLLAMA_HOST" > /dev/null; do
      printf "."
      sleep 1
    done

    echo -e "\nServer Connected | HOST: $OLLAMA_HOST\n"
  fi
}

# --- Argument Parsing ---
parse_params() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plain) FORMAT="plain" ;;
      --en) LANG_INST="Respond only in English." ;;
      --es) LANG_INST="Respond only in Spanish." ;;
      --verbose) VERBOSE=true ;;
      -h | --help) show_help ;;
      --*)
        echo "Error: Unrecognized flag '$1'" >&2
        show_help
        ;;
      *) break ;;
    esac
    shift
  done
  QUESTION="$*"
}

# --- Main Logic ---
main() {
  parse_params "$@"
  [[ -z "$QUESTION" ]] && show_help

  check_server

  # Format instruction injection based on the rendering tool
  local format_inst="Use Markdown."
  [[ "$FORMAT" == "plain" ]] && format_inst="Write in plain text. No markdown."

  # Technical Prompt Construction (System Prompt Emulation)
  local final_prompt="[SYSTEM][MANDATORY] $LANG_INST $BASE_INST $format_inst [/SYSTEM]\nUSER: $QUESTION"

  if [[ "$VERBOSE" == true ]]; then
    echo -e "--- VERBOSE ---\nHost: $OLLAMA_HOST\nModel: $MODEL\nPrompt: $final_prompt\n-------------"
  fi

  # Inference execution
  response=$(ollama run "$MODEL" "$final_prompt")

  echo $response
}

main "$@"
