#!/bin/sh
set -eu

mkdir -p /root/.pi/agent
cp /usr/local/share/pi-gemma4-models.json /root/.pi/agent/models.json

LLAMA_MODEL_PATH="${LLAMA_MODEL_PATH:-/models/vlm/gemma-4-e4b-it-gguf/gemma-4-E4B-it-Q4_K_M.gguf}"
LLAMA_MMPROJ_PATH="${LLAMA_MMPROJ_PATH:-/models/vlm/gemma-4-e4b-it-gguf/mmproj-BF16.gguf}"
LLAMA_ALIAS="${LLAMA_ALIAS:-gemma-4-e4b-it}"
LLAMA_PORT="${LLAMA_PORT:-8001}"
LLAMA_CHAT_TEMPLATE_KWARGS="${LLAMA_CHAT_TEMPLATE_KWARGS:-{\"enable_thinking\":true}}"

echo "[pi-agent] starting llama-server..."
/usr/local/bin/gemma4-entrypoint.sh \
    --model "${LLAMA_MODEL_PATH}" \
    --mmproj "${LLAMA_MMPROJ_PATH}" \
    --alias "${LLAMA_ALIAS}" \
    --host 0.0.0.0 \
    --port "${LLAMA_PORT}" \
    --temp 1.0 \
    --top-p 0.95 \
    --top-k 64 \
    --chat-template-kwargs "${LLAMA_CHAT_TEMPLATE_KWARGS}" &
LLAMA_PID=$!

cleanup() {
    if kill -0 "$LLAMA_PID" >/dev/null 2>&1; then
        kill "$LLAMA_PID" >/dev/null 2>&1 || true
        wait "$LLAMA_PID" 2>/dev/null || true
    fi
}
trap cleanup INT TERM EXIT

echo "[pi-agent] waiting for llama-server at http://127.0.0.1:${LLAMA_PORT}/health ..."
n=0
while ! curl -sf "http://127.0.0.1:${LLAMA_PORT}/health" >/dev/null 2>&1; do
    n=$((n + 1))
    if [ "$n" -gt 17280 ]; then
        echo "[pi-agent] timeout after 24h waiting for llama-server" >&2
        exit 1
    fi
    if [ $((n % 60)) -eq 0 ]; then
        echo "[pi-agent] still waiting for llama-server (${n}s) ..."
    fi
    sleep 5
done
echo "[pi-agent] llama-server is up."

cd /workspace
exec "$@"
