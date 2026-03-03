#!/usr/bin/env bash
# Requisitos técnicos
# Example: export OLLAMA_HOST=$(ip route show default | awk '{print $3}'):11434
# NOTA: OLLAMA_HOST depende de ser declarada previamente en el script de inicio.

# Requisitos técnicos de binarios
command -v glow > /dev/null 2>&1 || {
  echo "Error: glow not found." >&2
  exit 1
}
command -v batcat > /dev/null 2>&1 || {
  echo "Error: batcat not found." >&2
  exit 1
}

# Requisito de variable de entorno (Fail-fast)
: "${OLLAMA_HOST:?Error: OLLAMA_HOST is not defined. Declare it before running.}"

# Configuración de Bash segura
set -euo pipefail
IFS=$'\n\t'

# Valores por defecto

MODEL="granite4:latest"
FORMAT="plain"
LANG_INST="Respond only in Spanish."
BASE_INST="Be brief and concise."
DEBUG=false

show_help() {
  cat << EOF
Use Example: $(basename "$0") [FLAGS] "Prompt"

Options:
  --model [nombre]  LLM (Default: $MODEL)
  --glow | --bat    Output format (Default: plain text)
  --en | --es       Output language (Default: ES)
  --debug           Muestra el prompt enviado
EOF
  exit 0
}

check_server() {
  if ! curl -s -I --connect-timeout 2 http://$OLLAMA_HOST > /dev/null; then
    echo "Ollama Serve Starting..."
    powershell.exe -command "Start-Process 'ollama' -ArgumentList 'serve'"

    until curl -s http://$OLLAMA_HOST > /dev/null; do
      printf "."
      sleep 1
    done

    echo -e "Server Connected | HOST: $OLLAMA_HOST\n"
  fi
}

parse_params() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model)
        MODEL="$2"
        shift
        ;;
      --glow) FORMAT="glow" ;;
      --bat) FORMAT="bat" ;;
      --en) LANG_INST="Respond only in English." ;;
      --es) LANG_INST="Respond only in Spanish." ;;
      --debug) DEBUG=true ;;
      -h | --help) show_help ;;
      *) break ;;
    esac
    shift
  done
  QUESTION="$*"
}

main() {
  parse_params "$@"
  [[ -z "$QUESTION" ]] && show_help

  check_server

  local format_inst="Use Markdown."
  [[ "$FORMAT" == "plain" ]] && format_inst="Write in plain text. No markdown."

  local final_prompt="[SYSTEM][MANDATORY] $LANG_INST $BASE_INST $format_inst [/SYSTEM]\nUSER: $QUESTION"

  if [[ "$DEBUG" == true ]]; then
    echo -e "--- DEBUG ---\nHost: $OLLAMA_HOST\nModel: $MODEL\nPrompt: $final_prompt\n-------------"
  fi

  response=$(ollama run "$MODEL" "$final_prompt")

  case "$FORMAT" in
    glow)
      echo "$response" | glow -
      ;;
    bat)
      echo "$response" | batcat --style=plain -l md --paging=never
      ;;
    *)
      echo "$response"
      ;;
  esac

}

main "$@"
