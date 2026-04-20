#!/bin/sh
set -eu

MODEL_DIR="${GEMMA4_MODEL_DIR:-/models/vlm/gemma-4-e4b-it-gguf}"
HF_REPO="${GEMMA4_HF_REPO:-unsloth/gemma-4-E4B-it-GGUF}"
HF_BASE="https://huggingface.co/${HF_REPO}/resolve/main"

MAIN_NAME="${GEMMA4_MAIN_NAME:-gemma-4-E4B-it-Q4_K_M.gguf}"
MMPROJ_NAME="${GEMMA4_MMPROJ_NAME:-mmproj-BF16.gguf}"

mkdir -p "${MODEL_DIR}"

fetch_if_missing() {
	name="$1"
	url="$2"
	dest="${MODEL_DIR}/${name}"

	if [ -f "${dest}" ]; then
		echo "[gemma4] present: ${dest}"
		return 0
	fi

	if ! command -v curl >/dev/null 2>&1; then
		echo "[gemma4] error: curl is required to download ${name}" >&2
		return 1
	fi

	echo "[gemma4] downloading ${name} ..."
	tmp="${dest}.tmp"
	rm -f "${tmp}"

	if [ -n "${HF_TOKEN:-}" ]; then
		curl -fL --retry 3 --retry-delay 5 \
			-H "Authorization: Bearer ${HF_TOKEN}" \
			-o "${tmp}" "${url}"
	else
		curl -fL --retry 3 --retry-delay 5 -o "${tmp}" "${url}"
	fi

	mv -f "${tmp}" "${dest}"
	echo "[gemma4] saved: ${dest}"
}

fetch_if_missing "${MAIN_NAME}" "${HF_BASE}/${MAIN_NAME}?download=true"
fetch_if_missing "${MMPROJ_NAME}" "${HF_BASE}/${MMPROJ_NAME}?download=true"

exec /app/llama-server "$@"
