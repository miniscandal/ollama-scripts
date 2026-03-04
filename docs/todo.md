# Task 1: Implementación de detección automática de idioma

## 1. Descripción
Actualmente, el script `./src/bash/ollama/scripts/ask.sh` depende de los flags explícitos `--en` o `--es` para determinar el idioma de la respuesta. El objetivo es mejorar la lógica para que, en ausencia de estos flags, el sistema detecte y utilice el idioma del prompt original como lenguaje de salida.

## 2. Requerimientos Funcionales
El sistema debe determinar el idioma de respuesta basándose en la siguiente jerarquía de precedencia:
1. **Flags Explícitos:** Uso de `--en` o `--es` por parte del usuario.
2. **Detección Automática:** En ausencia de flags, se debe inyectar una instrucción en el System Prompt: "Respond in the same language as the following prompt".
3. **Lenguaje de Respaldo (Fallback):** Si la detección resulta ambigua, el idioma predeterminado será el inglés.

## 3. Especificaciones Técnicas
| Escenario | Entrada | Salida Esperada |
| :--- | :--- | :--- |
| Flag forzado | `ask.sh --en "Hola"` | Inglés |
| Auto-detección ES | `ask.sh "Ejemplo de DIP"` | Español |
| Auto-detección EN | `ask.sh "Explain Java"` | Inglés |

* **Inyección en el Prompt:** Si no se detectan flags de idioma, se debe concatenar la instrucción interna al prompt enviado a Ollama.


# Task 2: Formateo híbrido de salida (bat + glow)

## 1. Descripción
Optimizar la visualización de las respuestas generadas por Ollama en la terminal. Se busca segmentar el contenido para que el código fuente sea procesado por `bat` y el texto narrativo por `glow`.

## 2. Requerimientos Funcionales
La salida generada por el modelo debe segmentarse para ser procesada por la herramienta más adecuada:
* **Bloques de Código:** Todo contenido delimitado por triple backticks (\`\`\`) debe ser canalizado a `bat` para aprovechar el resaltado de sintaxis y la numeración de líneas.
* **Texto Narrativo/Markdown:** El resto del contenido (explicaciones, títulos, tablas) debe ser procesado por `glow` para un renderizado visual óptimo.

## 3. Especificaciones Técnicas
Para la separación de contenido, se sugiere una lógica de filtrado que:
* Identifique el inicio y fin de bloques de código.
