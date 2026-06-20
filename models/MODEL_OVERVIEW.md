# Overview of LLM Models

llama.cpp configuration for running Qwen3.6 and Gemma-4 models on a
Strix Halo computer with 64 GB of memory.

The Qwen models have solid tool calling and are in general a much better
choice for coding tasks. The Gemma models seems to have better language.
The Gemma models are plagued by failed tool calls. I've mostly been
interested in having a coding assistant, but the Gemma models may be
useful for other things. They can write prose and do OCR tasks.
Gemma-4-31B also seems to be useful for code review or analyzing code
segments.

The dense models are much more confident than the MoE models but really
slow on the target hardware.

Multi-token prediction (MTP) is enabled for both the Qwen and Gemma
models in the configuration files herein. The token generation rate for
the MoE models are acceptable (even good) at 50+ tokens/s, while the
larger dense models only get 12+ tokens/s (Gemma-4-31B slightly higher
with 4-bit quant).
