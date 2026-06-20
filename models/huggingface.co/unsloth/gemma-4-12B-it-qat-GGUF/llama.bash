# llama.bash :: Support functions for running the model with llama-server
#
# Usage:
#
#   source llama.bash && LLM_MODEL_DIR=... llama_run_model
#   source llama.bash && llama_monitor_server
#

# The llama-sever log timestamp format is real silly.
# Timestamp each line with understandable time for troubleshooting server issues.
llama_timestamp_lines() {
    while IFS= read -r line; do
        printf '%(%Y-%m-%d %H:%M:%S)T %s\n' -1 "$line"
    done
}

# llama_run_model :: Run llama-server in a primitive restart loop, collect logs
#
# Model: Gemma-4-12B (4-bit QAT quant, 256k context window)
#
llama_run_model() {
    if [ -z "$LLM_MODEL_DIR" ]; then
	echo "Error: env LLM_MODEL_DIR not set!"
	return 1
    fi

    # Regular model
    local -a ARGS=(--model "$LLM_MODEL_DIR/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf")

    # Draft model (MTP)
    ARGS+=(--model-draft "$LLM_MODEL_DIR/mtp-gemma-4-12B-it.gguf")

    # Vision model
    ARGS+=(--mmproj "$LLM_MODEL_DIR/mmproj-F16.gguf")

    # Logging
    ARGS+=(--log-colors on --log-verbosity 4)

    # Service address
    ARGS+=(--host 127.0.0.1 --port 1337)

    # API protocol
    ARGS+=(--jinja)

    # Fix for broken tool calls caused by default Gemma-4 chat template (built into model)
    ARGS+=(--chat-template-file chat_template.jinja)

    # ROCm must haves
    ARGS+=(--no-mmap --flash-attn on)

    # KV cache tuning:
    #
    #   --kv-unified  Use a single KV buffer across all sequences
    #   --ctx-size    Context size in tokens
    #   --parallel    Number of server slots
    #
    # There's also `--cache-type-k` and `--cache-type-v` that results in model regressions.
    #
    ARGS+=(--kv-unified --ctx-size 262144 --parallel 1)

    # Prompt cache tuning:
    #
    #   --cache-ram
    #   --ctx-checkpoints
    #   --batch-size
    #   --ubatch-size
    #

    # Matched ubatch with batch size to avoid assert during image processing with this model
    ARGS+=(--cache-ram 8192 --ctx-checkpoints 32 --batch-size 1024 --ubatch-size 1024)

    # Multi Token Prediction (MTP), speeds up token generation.
    ARGS+=(--spec-type draft-mtp --spec-draft-n-max 5)

    # Model tuning: https://huggingface.co/google/gemma-4-31B-it
    ARGS+=(--temp 1.0 --top-p 0.95 --top-k 64 --min-p 0.0 --image-max-tokens 1120 --reasoning on)
    readonly ARGS

    # Crash loop
    while true; do
	# For monitoring
        mkdir -p logs

	# Launch the sucker
        llama-server "${ARGS[@]}" |& llama_timestamp_lines | tee -a "logs/llama-server-$(date +%Y%m%dT%H%M%S).txt"
        echo "Restart delay..."
        sleep 2
    done
}

# llama_monitor_server :: Server monitoring loop
llama_monitor_server() {
    mkdir -p logs
    while true; do
	free -h | llama_timestamp_lines
	sleep 60
    done | tee -a logs/server-status.txt
}
