local vaults = {
  { name = "airudder", path = "~/Documents/obsidian/airudder", attachments = "./attachments" },
  { name = "zhiwen", path = "~/Documents/obsidian/zhiwen", attachments = "./attachment" },
}

local events = {}
local workspaces = {}
for _, vault in ipairs(vaults) do
  local path = vim.fn.expand(vault.path)
  table.insert(events, "BufReadPre " .. path .. "/*.md")
  table.insert(events, "BufNewFile " .. path .. "/*.md")
  -- Match each vault's attachment folder from its Obsidian app.json.
  table.insert(workspaces, { name = vault.name, path = path, overrides = { attachments = { folder = vault.attachments } } })
end

---@type LazySpec
return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    event = events,
    cmd = "Obsidian",
    init = function()
      -- obsidian-ls already completes links in the vaults; marksman would list
      -- every note a second time.
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "Leave vault link completion to obsidian.nvim",
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not (client and client.name == "marksman") then return end
          local file = vim.api.nvim_buf_get_name(args.buf)
          for _, workspace in ipairs(workspaces) do
            if vim.startswith(file, workspace.path .. "/") then
              client.server_capabilities.completionProvider = nil
              return
            end
          end
        end,
      })
    end,
    ---@module "obsidian"
    ---@type obsidian.config
    opts = {
      legacy_commands = false,
      workspaces = workspaces,
      picker = { name = "snacks.picker" },
      -- Name new notes after their title, as the Obsidian app does.
      note_id_func = function(title)
        title = title and vim.trim(title) or ""
        return title ~= "" and title or require("obsidian.builtin").zettel_id()
      end,
      -- Never rewrite frontmatter (id/aliases/tags) of shared notes on save.
      frontmatter = { enabled = false },
    },
  },
}
