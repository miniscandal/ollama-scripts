# ----------------------------------------------------------------------------
# SERVER AUTO-START LOGIC (WSL <-> Windows Interop)
# ----------------------------------------------------------------------------
# If the Ollama API is unreachable, we attempt to launch the Windows binary
# and wait (poll) until the socket is ready to accept HTTP requests.
# ----------------------------------------------------------------------------

if ! curl -s -I --connect-timeout 2 --max-time 3 "http://$OLLAMA_HOST" > /dev/null; then
  echo -n "Ollama not detected at $OLLAMA_HOST. Attempting to start service..."

  # Launch Ollama server in background via PowerShell Interop
  # 'Start-Process' prevents the WSL terminal from hanging on the process
  powershell.exe -command "Start-Process 'ollama' -ArgumentList 'serve'"

  # Polling loop: Wait until the server responds to a basic GET request
  # This prevents the script from proceeding before the model engine is ready
  until curl -s "http://$OLLAMA_HOST" > /dev/null; do
    printf "."
    sleep 1
  done

  echo -e "\nServer Connected | HOST: $OLLAMA_HOST\n"
fi
