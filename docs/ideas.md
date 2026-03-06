alias ask='OLLAMA_HOST=$(ip route show default | awk "{print \$3}"):11434 /path/to/your/ask.sh'
