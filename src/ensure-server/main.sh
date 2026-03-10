#!/usr/bin/env bash

# ----------------------------------------------------------------------------
# SERVER AUTO-START LOGIC (WSL <-> Windows Interop)
# ----------------------------------------------------------------------------

if ! curl -s -I --connect-timeout 2 --max-time 3 "http://$OLLAMA_HOST" > /dev/null; then
  echo -n "Ollama not detected at $OLLAMA_HOST. Attempting to start service..."

  wt.exe -w -1 new-tab --title "OllamaServer" -p "PowerShell" powershell.exe -NoExit -Command "ollama serve"

  # Polling loop: Wait until the server responds to a basic GET request
  until curl -s "http://$OLLAMA_HOST" > /dev/null; do
    printf "."
    sleep 1
  done

  echo -e "\nServer Connected | HOST: $OLLAMA_HOST\n"
fi
