
- **`APPEND_SYSTEM.md`:** Goes into `~/.pi/agent` or project root `.pi/`
directory for adjusting the LLM tone and general behavior.

- **`models.json`:** Goes into `~/.pi/agent` for reaching local LLM service.

  *Local LLM deployment:* Create an SSH tunnel from the host running the Pi coding agent to the
  host running the LLM server if the two are running on separate hosts.
  
  Example: Create SSH tunnel for local LLM API access
  
  ```bash
  ssh -N -L 1337:localhost:1337 LLM_SERVER_HOST
  ```

- **`keybindings.json`:** Goes into `~/.pi/agent` for more Emacs like keybindings.
