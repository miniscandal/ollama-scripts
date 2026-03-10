# Commands

dirname
basename

powershell.exe -command "Start-Process 'ollama' -ArgumentList 'serve'"

wt.exe -w -1 --maximized new-tab --title "OllamaServer" -p "PowerShell" powershell.exe -NoExit -Command "ollama serve"
