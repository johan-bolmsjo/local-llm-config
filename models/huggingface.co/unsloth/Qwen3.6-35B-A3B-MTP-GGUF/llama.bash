# llama.bash :: Support functions for running the model with llama-server
#
# Usage:
#
#   source llama.bash && LLM_MODEL_DIR=... LLM_MODEL_TUNING=1|2|3|4 llama_run_model
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
# Model: Qwen3.6-35B-A3B (8-bit quant, 128k context window, MTP)
#
llama_run_model() {
    if [ -z "$LLM_MODEL_DIR" ]; then
	echo "Error: env LLM_MODEL_DIR not set!"
	return 1
    fi

    # Regular model
    local -a ARGS=(--model "$LLM_MODEL_DIR/Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf")

    # Vision model
    ARGS+=(--mmproj "$LLM_MODEL_DIR/mmproj-F16.gguf")

    # Logging
    ARGS+=(--log-colors on --log-verbosity 4)

    # Service address
    ARGS+=(--host 127.0.0.1 --port 1337)

    # API protocol
    ARGS+=(--jinja)

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
    ARGS+=(--kv-unified --ctx-size 131072 --parallel 1)

    # Prompt cache tuning:
    #
    #   --cache-ram
    #   --ctx-checkpoints
    #   --batch-size
    #   --ubatch-size
    #
    ARGS+=(--cache-ram 2048 --ctx-checkpoints 16 --batch-size 1024 --ubatch-size 1024)

    # Multi Token Prediction (MTP), speeds up token generation.
    ARGS+=(--spec-type draft-mtp --spec-draft-n-max 2)

    # Model tuning: https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF
    case "${LLM_MODEL_TUNING:=0}" in
	1)
	    echo "Thinking mode for general tasks"
	    ARGS+=(--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 1.5 --repeat-penalty 1.0 --reasoning on)
	    ;;
	2)
	    echo "Thinking mode for precise coding tasks"
	    ARGS+=(--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 0.0 --repeat-penalty 1.0 --reasoning on)
	    ;;
	3)
	    echo "Instruct (or non-thinking) mode for general tasks"
	    ARGS+=(--temp 0.7 --top-p 0.8 --top-k 20 --min-p 0.0 --presence-penalty 1.5 --repeat-penalty 1.0 --reasoning off)
	    ;;
	4)
	    echo "Instruct (or non-thinking) mode for reasoning tasks"
	    ARGS+=(--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 1.5 --repeat-penalty 1.0 --reasoning off)
	    ;;
    esac
    ARGS+=(--image-min-tokens 1024)
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
