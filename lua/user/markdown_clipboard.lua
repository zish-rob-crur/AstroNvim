local M = {}

-- Pass clipboard contents through stdin, never through shell interpolation.
local write_clipboard = [[
ObjC.import('AppKit');
ObjC.import('Foundation');
const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
const payload = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding)));
const item = $.NSPasteboardItem.alloc.init;
if (!item.setStringForType($(payload.html), $.NSPasteboardTypeHTML) ||
    !item.setStringForType($(payload.text), $.NSPasteboardTypeString)) {
  throw new Error('Could not prepare rich text clipboard data');
}
const clipboard = $.NSPasteboard.generalPasteboard;
clipboard.clearContents;
if (!clipboard.writeObjects($.NSArray.arrayWithObject(item))) {
  throw new Error('Could not write rich text to clipboard');
}
]]

function M.copy(line1, line2)
  if vim.fn.has "mac" == 0 then
    vim.notify("MarkdownCopyRich currently requires macOS", vim.log.levels.ERROR)
    return
  end
  if vim.fn.executable "pandoc" ~= 1 then
    vim.notify("MarkdownCopyRich requires pandoc (brew install pandoc)", vim.log.levels.ERROR)
    return
  end

  local markdown = table.concat(vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false), "\n")
  local output = {}
  for _, format in ipairs { "html5", "plain" } do
    local result = vim
      .system({ "pandoc", "--from=gfm", "--to=" .. format, "--wrap=none" }, {
        stdin = markdown,
        text = true,
      })
      :wait(10000)
    if result.code ~= 0 then
      vim.notify("Markdown conversion failed: " .. (result.stderr or "pandoc timed out"), vim.log.levels.ERROR)
      return
    end
    output[format] = result.stdout
  end

  local html = '<!DOCTYPE html><html><head><meta charset="utf-8"></head><body>' .. output.html5 .. "</body></html>"
  local result = vim
    .system({ "osascript", "-l", "JavaScript", "-e", write_clipboard }, {
      stdin = vim.json.encode { html = html, text = output.plain },
      text = true,
    })
    :wait(10000)
  if result.code ~= 0 then
    vim.notify("Rich text copy failed: " .. (result.stderr or "osascript timed out"), vim.log.levels.ERROR)
    return
  end
  vim.notify(("Copied Markdown as rich text (%d lines)"):format(line2 - line1 + 1))
end

return M
