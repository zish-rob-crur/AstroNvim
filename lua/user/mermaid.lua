local M = {}

-- Recreate this buffer's placements with the new document size. Image pixels
-- stay cached; zooming does not invoke Mermaid CLI again.
function M.zoom(delta)
  local image = require("snacks").image
  local doc = image.config.doc
  doc.max_width = delta == 0 and 120 or math.max(40, math.min(240, doc.max_width + delta))
  doc.height, doc.max_height = nil, 40
  local buf = vim.api.nvim_get_current_buf()
  image.placement.clean(buf)
  vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = buf })
  vim.notify(("Image width: up to %d columns (limited by window width)"):format(doc.max_width))
end

function M.view()
  local image = require("snacks").image
  local source_buf, line = vim.api.nvim_get_current_buf(), vim.fn.line "."
  image.doc.find(source_buf, function(matches)
    local selected, distance
    for _, match in ipairs(matches) do
      local range = match.range or { match.pos[1], 0, match.pos[1], 0 }
      local d = math.max(range[1] - line, line - range[3], 0)
      if not distance or d < distance then selected, distance = match, d end
    end
    if not selected then return vim.notify("No image or Mermaid diagram found") end
    vim.cmd "tabnew"
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype, vim.bo[buf].bufhidden = "nofile", "wipe"
    vim.wo.wrap, vim.wo.number, vim.wo.relativenumber = false, false, false
    vim.wo.scrolloff = 0
    vim.bo[buf].filetype, vim.bo[buf].modifiable = "image", false
    local placement = image.placement.new(buf, selected.src, {
      conceal = true,
      inline = true, -- preserve the scroll position when the placement updates
      auto_resize = true,
      width = 120,
      height = 256,
      max_height = 256,
      on_update_pre = function(p)
        -- Give each image row a real buffer line so the cursor can scroll
        -- through it. A virtual block taller than the viewport is skipped.
        local height = p:state().loc.height
        if vim.api.nvim_buf_line_count(buf) ~= height then
          local lines = {}
          for _ = 1, height do lines[#lines + 1] = " " end
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].modifiable = false
          vim.bo[buf].modified = false
        end
        p.opts.range = { 1, 0, height, 1 }
      end,
    })
    if not placement then return end
    local function resize(delta)
      placement.opts.width = delta == 0 and 120 or math.max(40, math.min(240, placement.opts.width + delta))
      placement:update()
    end
    for key, delta in pairs { ["+"] = 40, ["-"] = -40, ["0"] = 0 } do
      vim.keymap.set("n", key, function() resize(delta) end, { buffer = buf, desc = "Resize image" })
    end
    vim.keymap.set("n", "q", "<Cmd>tabclose<CR>", { buffer = buf, desc = "Close image viewer" })
  end)
end

-- Use the editor palette instead of Mermaid's unrelated built-in dark theme.
function M.args()
  local dark = vim.o.background == "dark"
  local function color(group, key, fallback)
    local value = vim.api.nvim_get_hl(0, { name = group, link = false })[key]
    return value and ("#%06x"):format(value) or fallback
  end
  local bg = color("Normal", "bg", dark and "#2d353b" or "#ffffff")
  local fg = color("Normal", "fg", dark and "#d3c6aa" or "#24292f")
  -- Match Codex's semantic styling: type-colored outlines, muted edges,
  -- and ordinary foreground text, with no raised or filled node cards.
  local accent = color("Type", "fg", dark and "#83c092" or "#0550ae")
  local config = {
    theme = "base",
    look = "classic",
    htmlLabels = true,
    flowchart = { wrappingWidth = 260 },
    themeCSS = [[
      .node rect, .node polygon, .node circle, .node ellipse, .node path {
        fill: transparent !important; filter: none !important; stroke-width: 1px !important;
      }
      .nodeLabel, .edgeLabel, .label, .label p {
        font-weight: 400 !important;
      }
    ]],
    themeVariables = {
      darkMode = dark,
      background = bg,
      primaryColor = bg,
      primaryTextColor = fg,
      primaryBorderColor = accent,
      secondaryColor = bg,
      tertiaryColor = bg,
      textColor = fg,
      lineColor = color("Comment", "fg", accent),
      edgeLabelBackground = bg,
      fontFamily = "PingFang SC, sans-serif",
      fontSize = "18px",
    },
  }
  local dir = vim.fn.stdpath "cache" .. "/mermaid"
  vim.fn.mkdir(dir, "p")
  local path = dir .. "/" .. vim.o.background .. ".json"
  vim.fn.writefile({ vim.json.encode(config) }, path)
  return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-c", path, "-s", "2" }
end

return M
