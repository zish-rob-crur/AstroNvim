local function nvm_node_command()
  return {
    vim.env.SHELL or "/bin/zsh",
    "-lc",
    table.concat({
      'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"',
      '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"',
      'nvm use --silent default >/dev/null 2>&1 || true',
      'exec node "$@"',
    }, "; "),
    "copilot-node",
  }
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      copilot_node_command = nvm_node_command(),
      filetypes = {
        yaml = true,
        markdown = true,
        toml = true,
        gitcommit = true,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
    },
  },
}
