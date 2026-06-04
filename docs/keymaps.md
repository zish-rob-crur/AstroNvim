# Keymap Quick Reference (My AstroNvim)

> `Leader` = `<Space>`, `LocalLeader` = `,`

## How To Find Keymaps

- `<Leader>fk`: Search all keymaps with the picker.
- Press `<Leader>` directly: wait for `which-key`, then continue with the next key.
- To see where a mapping is defined: use `:verbose nmap <key>`, for example `:verbose nmap <Leader>ff`.

## Navigation

### Flash

- `s`: Flash jump. Type 1-2 characters, then pick a label.
- `S`: Flash Treesitter jump by syntax node.
- `/` or `?`: Flash labels are enabled during search.
- `<C-s>` in command-line search: toggle Flash search labels.

Note: Flash overrides Vim's native `s` and `S`. Use `cl` for native `s`-like behavior and `cc` for native `S`-like behavior.

### Harpoon

- `<Leader>aa`: Add the current file to Harpoon.
- `<Leader>am`: Open or close the Harpoon quick menu.
- `<Leader>1`/`2`/`3`/`4`: Jump to marked file 1-4.
- `<Leader>an` / `<Leader>ap`: Next or previous mark.

## Files And Search

- `<C-p>` / `<D-p>`: Quick Open, similar to VS Code `Ctrl/Cmd + P`.
- `<C-S-p>` / `<D-S-p>`: Command Palette.
- `<Leader>ff`: Find files.
- `<Leader>fF`: Find all files.
- `<Leader>fo`: Reveal the current file in Finder, or open the current working directory for unnamed buffers.
- `<Leader>fO` / `-`: Open the current directory as an editable Oil buffer.
- `<Leader>fw`: Find words across the project.
- `<Leader>f/`: Find words in the current buffer.
- `<Leader>fb`: Find buffers.
- `<Leader>fp`: Quick switch buffers.
- `<Leader>fg`: Find changed, staged, and untracked Git files.
- `<Leader>fh`: Find help.
- `<Leader>f<CR>`: Resume the previous search.
- Press Enter in picker results to open the selected file or item.

Note: `<D-*>` mappings usually require GUI Neovim, such as Neovide, or terminal support for forwarding Cmd-key input. In plain terminals, the `<C-*>` variants are more reliable.

## Code Structure And Diagnostics

- `<Leader>lS`: Symbols outline with Aerial.
- `<Leader>ls`: Search symbols with the picker.
- `<Leader>lD`: Search diagnostics with the picker.
- `<Leader>ld`: Hover diagnostics.

### LSP Navigation

- `gd`: Go to definition.
- `gD`: Go to declaration.
- `gI`: Go to implementation.
- `gy`: Go to type definition.
- `K`: Hover documentation.
- `<Leader>lR`: Find references.
- `<Leader>lr`: Rename.
- `<Leader>la`: Code action.
- `<Leader>cf`: Format the current buffer with Conform.

Note: Most LSP mappings are buffer-local and only appear after a language server attaches to the current buffer. Use `<Leader>fk` to confirm available mappings.

## Windows And Buffers

- `<C-h/j/k/l>`: Move between splits.
- `<C-Up/Down/Left/Right>`: Resize splits.
- `]b` / `[b`: Next or previous buffer.
- `<Leader>c`: Close the current buffer.
- `<Leader>bb`: Pick a buffer from the tabline.
- `<Leader>bd`: Close a buffer from the tabline.

## Common Commands

- `<Leader>e`: Toggle Neo-tree.
- `<Leader>o`: Move focus between Neo-tree and the previous editor window.
- `<Leader>w`: Save.
- `<Leader>yp`: Copy the current file's relative path.
- `<Leader>yP`: Copy the current file's absolute path.
- `<Leader>q`: Quit the current window.
- `<Leader>h`: Return to the Home Screen dashboard.
- `<Leader>Ss`: Save session.
- `<Leader>Sl`: Load the last session.
- `<Leader>Sr`: Save session and reload AstroNvim.
- `<Leader>tf` / `<Leader>th` / `<Leader>tv`: ToggleTerm float, horizontal, or vertical terminal.
- `<Leader>gg`: Lazygit in ToggleTerm.
- `<Leader>sr`: Open GrugFar for project-wide search and replace.
- `<Leader>sw`: Search and replace the word under the cursor with GrugFar.
- `<Leader>tw`: Open a web page with `w3m` in a terminal after entering a URL.
- `<Leader>tW`: Open the URL under the cursor with `w3m` in a terminal.

## Markdown

> These mappings are registered only in Markdown buffers.

- `<Leader>mp`: Open the `render-markdown` preview.
- `<Leader>mb`: Open the Markdown browser preview.
- `<Leader>mm`: Toggle the Markdown browser preview with Mermaid support.
- `<Leader>mo`: Toggle the Markdown heading outline with Aerial.
- `<Leader>mn`: Toggle the Markdown section outline with Aerial.
- `<Leader>jj`: Toggle Jieba word motions for the current buffer. When enabled, `w`, `b`, `e`, and `ge` move by Chinese words.
- `]m` / `[m`: Jump to the next or previous Markdown heading.

### Neo-tree

- `<CR>`: Open the file or directory in the current window.
- `l`: Enter a directory. If it is already expanded, move to the first child. On files, this opens the file.
- `h`: Collapse the current directory. If already collapsed, move to the parent directory.
- `s` / `S`: Open the file in a vertical or horizontal split.
- `t`: Open the file in a new tab.
- `w`: Pick a target window, then open the file there.
- `q`: Close the Neo-tree window.
