# llama.bash :: Support functions for running the model with llama-server
#
# Usage:
#
#   source llama.bash && LLM_MODEL_DIR=... LLM_MODEL_TUNING=1|2|3 llama_run_model
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
# Model: Qwen3.8-27B with MTP
#
llama_run_model() {
    if [ -z "$LLM_MODEL_DIR" ]; then
	echo "Error: env LLM_MODEL_DIR not set!"
	return 1
    fi

    # Regular model. Pick your poison!
    #local -a ARGS=(--model "$LLM_MODEL_DIR/Qwen3.8-27B-UD-Q8_K_XL.gguf")
    local -a ARGS=(--model "$LLM_MODEL_DIR/Qwen3.8-27B-UD-Q6_K_L.gguf")

    # Vision model
    ARGS+=(--mmproj "$LLM_MODEL_DIR/mmproj-F16.gguf")

    # Logging
    ARGS+=(--log-colors on --log-verbosity 4)

    # Service address
    ARGS+=(--host 127.0.0.1 --port 1337)

    # API protocol
    ARGS+=(--jinja --reasoning-format deepseek)

    # ROCm must haves
    ARGS+=(--no-mmap --flash-attn on)

    ARGS+=(--no-warmup)

    # KV cache tuning:
    #
    #   --kv-unified  Use a single KV buffer across all sequences
    #   --ctx-size    Context size in tokens
    #   --parallel    Number of server slots
    #
    #ARGS+=(--kv-unified --cache-type-k f16 --cache-type-v f16 --ctx-size 196608 --parallel 1)
    ARGS+=(--kv-unified --cache-type-k f16 --cache-type-v f16 --ctx-size 262144 --parallel 1)

    # Prompt cache tuning:
    #
    #   --cache-ram
    #   --ctx-checkpoints
    #   --batch-size
    #   --ubatch-size
    #
    ARGS+=(--cache-ram 8192 --ctx-checkpoints 32 --batch-size 1024 --ubatch-size 1024)

    # Multi Token Prediction (MTP), speeds up token generation.
    ARGS+=(--spec-type draft-mtp --spec-draft-n-max 3)

    # Model tuning: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF
    case "${LLM_MODEL_TUNING:=0}" in
	1)
	    echo "Official thinking mode"
	    ARGS+=(--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0 --reasoning on --reasoning-preserve)
	    # Tweaked chat template which supposedly fixes some issues.
	    ARGS+=(--chat-template-file chat_template-general.jinja )
	    ;;
	2)
	    echo "Custom thinking mode"
	    # Temperature for custom development centric chat template:
	    # - https://old.reddit.com/r/LocalLLaMA/comments/1vqvrh0/qwen_38_27b_overthinking_it_has_to_be_done_it_has/p48ot9f/
	    ARGS+=(--temp 0.7 --top-p 0.95 --top-k 20 --min-p 0.0 --reasoning on --reasoning-preserve)
	    # Tweaked chat template with additional steering for efficiency.
	    ARGS+=(--chat-template-file chat_template-devel.jinja )
	    ;;
	3)
	    echo "Instruct (or non-thinking) mode"
	    ARGS+=(--temp 0.7 --top-p 0.80 --top-k 20 --min-p 0.0 --presence-penalty 1.5 --reasoning off)
	    # Tweaked chat template which supposedly fixes some issues.
	    ARGS+=(--chat-template-file chat_template-general.jinja )
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
