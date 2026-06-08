# Keymap Quick Reference / 快捷键速查 (My AstroNvim)

> `Leader` = `<Space>`, `LocalLeader` = `,` / `Leader` 是空格键，`LocalLeader` 是逗号键。

## How To Find Keymaps / 如何查找快捷键

- `<Leader>fk`: Search all keymaps with the picker. / 使用选择器搜索所有快捷键。
- Press `<Leader>` directly: wait for `which-key`, then continue with the next key. / 直接按 `<Leader>`：等待 `which-key` 弹出，然后继续输入后续按键。
- To see where a mapping is defined: use `:verbose nmap <key>`, for example `:verbose nmap <Leader>ff`. / 查看某个映射的定义位置：使用 `:verbose nmap <key>`，例如 `:verbose nmap <Leader>ff`。

## Navigation / 导航

### Flash / Flash 跳转

- `s`: Flash jump. Type 1-2 characters, then pick a label. / Flash 跳转。输入 1 到 2 个字符，然后选择标签。
- `S`: Flash Treesitter jump by syntax node. / 按语法节点执行 Flash Treesitter 跳转。
- `/` or `?`: Flash labels are enabled during search. / 使用 `/` 或 `?` 搜索时会启用 Flash 标签。
- `<C-s>` in command-line search: toggle Flash search labels. / 在命令行搜索中按 `<C-s>`：切换 Flash 搜索标签。

Note: Flash overrides Vim's native `s` and `S`. Use `cl` for native `s`-like behavior and `cc` for native `S`-like behavior. / 注意：Flash 会覆盖 Vim 原生的 `s` 和 `S`。需要原生 `s` 类似行为时使用 `cl`，需要原生 `S` 类似行为时使用 `cc`。

### Harpoon / Harpoon 标记

- `<Leader>aa`: Add the current file to Harpoon. / 将当前文件加入 Harpoon。
- `<Leader>am`: Open or close the Harpoon quick menu. / 打开或关闭 Harpoon 快捷菜单。
- `<Leader>1`/`2`/`3`/`4`: Jump to marked file 1-4. / 跳转到第 1 到第 4 个标记文件。
- `<Leader>an` / `<Leader>ap`: Next or previous mark. / 跳到下一个或上一个标记。

## Files And Search / 文件与搜索

- `<C-p>` / `<D-p>`: Quick Open, similar to VS Code `Ctrl/Cmd + P`. / 快速打开，类似 VS Code 的 `Ctrl/Cmd + P`。
- `<C-S-f>` / `<D-S-f>`: Search text across all project files, including hidden and ignored files. / 在所有项目文件中搜索文本，包括隐藏文件和被忽略文件。
- `<C-S-p>` / `<D-S-p>`: Command Palette. / 打开命令面板。
- `<Leader>ff`: Find files. / 查找文件。
- `<Leader>fF`: Find all files. / 查找所有文件。
- `<Leader>fo`: Reveal the current file in Finder, or open the current working directory for unnamed buffers. / 在 Finder 中显示当前文件；如果是未命名缓冲区，则打开当前工作目录。
- `<Leader>fO` / `-`: Open the current directory as an editable Oil buffer. / 将当前目录作为可编辑的 Oil 缓冲区打开。
- `<Leader>fc`: Find the word under the cursor across the project. / 在项目中查找光标下的词。
- `<Leader>fw`: Find words across normal project files. / 在普通项目文件中全文搜索。
- `<Leader>fW`: Find words across all project files, including hidden and ignored files. / 在所有项目文件中全文搜索，包括隐藏文件和被忽略文件。
- `<Leader>f/`: Find words in the current buffer. / 在当前缓冲区中搜索文本。
- `<Leader>fb`: Find buffers. / 查找缓冲区。
- `<Leader>fp`: Quick switch buffers. / 快速切换缓冲区。
- `<Leader>fg`: Find changed, staged, and untracked Git files. / 查找已修改、已暂存和未跟踪的 Git 文件。
- `<Leader>fh`: Find help. / 查找帮助文档。
- `<Leader>f<CR>`: Resume the previous search. / 恢复上一次搜索。
- `<Leader>hp`: Preview the current HTML report in the default browser. / 在默认浏览器中预览当前 HTML 报告。
- `:GitUrlCopy` / `:GitUrlCopyPermalink` / `:GitUrlOpen`: Copy or open the current GitHub/GitLab file URL from the command palette. / 从命令面板复制或打开当前文件的 GitHub/GitLab URL。
- Press Enter in picker results to open the selected file or item. / 在选择器结果中按回车可打开选中的文件或条目。

Note: `<D-*>` mappings usually require GUI Neovim, such as Neovide, or terminal support for forwarding Cmd-key input. In plain terminals, the `<C-*>` variants are more reliable. / 注意：`<D-*>` 映射通常需要 GUI Neovim（如 Neovide），或终端支持转发 Cmd 键输入。在普通终端中，`<C-*>` 变体更可靠。

## Code Structure And Diagnostics / 代码结构与诊断

- `<Leader>lS`: Symbols outline with Aerial. / 使用 Aerial 查看符号大纲。
- `<Leader>ls`: Search symbols with the picker. / 使用选择器搜索符号。
- `<Leader>lD`: Search diagnostics with the picker. / 使用选择器搜索诊断信息。
- `<Leader>ld`: Hover diagnostics. / 悬浮查看诊断信息。
- `<Leader>xx`: Open project diagnostics with Trouble. / 使用 Trouble 打开项目诊断。
- `<Leader>xX`: Open current buffer diagnostics with Trouble. / 使用 Trouble 打开当前缓冲区诊断。
- `<Leader>xs`: Open document symbols with Trouble. / 使用 Trouble 打开文档符号。
- `<Leader>xr`: Open LSP references and definitions with Trouble. / 使用 Trouble 打开 LSP 引用和定义。
- `<Leader>xQ`: Open the quickfix list with Trouble. / 使用 Trouble 打开 quickfix 列表。
- `<Leader>xL`: Open the location list with Trouble. / 使用 Trouble 打开 location 列表。

### LSP Navigation / LSP 导航

- `gd`: Go to definition. / 跳转到定义。
- `gD`: Go to declaration. / 跳转到声明。
- `gI`: Go to implementation. / 跳转到实现。
- `gy`: Go to type definition. / 跳转到类型定义。
- `K`: Hover documentation. / 悬浮查看文档。
- `<Leader>lR`: Find references. / 查找引用。
- `<Leader>lr`: Rename. / 重命名。
- `<Leader>la`: Code action. / 执行代码操作。
- `<Leader>cf`: Format the current buffer with Conform. / 使用 Conform 格式化当前缓冲区。

Note: Most LSP mappings are buffer-local and only appear after a language server attaches to the current buffer. Use `<Leader>fk` to confirm available mappings. / 注意：大多数 LSP 映射都是缓冲区局部的，只会在语言服务器附加到当前缓冲区后出现。可使用 `<Leader>fk` 确认可用映射。

## Windows And Buffers / 窗口与缓冲区

- `<C-h/j/k/l>`: Move between splits. / 在分屏之间移动。
- `<M-h/j/k/l>`: Move between splits with Alt/Meta. / 使用 Alt/Meta + hjkl 在分屏之间移动。
- `<C-Up/Down/Left/Right>`: Resize splits. / 调整分屏大小。
- `]b` / `[b`: Next or previous buffer. / 切换到下一个或上一个缓冲区。
- `<Leader>c`: Close the current buffer. / 关闭当前缓冲区。
- `<Leader>bb`: Pick a buffer from the tabline. / 从标签栏选择缓冲区。
- `<Leader>bd`: Close a buffer from the tabline. / 从标签栏关闭缓冲区。

## Common Commands / 常用命令

- `<Leader>e`: Toggle Neo-tree. / 切换 Neo-tree。
- `<Leader>o`: Move focus between Neo-tree and the previous editor window. / 在 Neo-tree 和上一个编辑器窗口之间移动焦点。
- `<Leader>w`: Save. / 保存。
- `<Leader>yp`: Copy the current file's relative path. / 复制当前文件的相对路径。
- `<Leader>yP`: Copy the current file's absolute path. / 复制当前文件的绝对路径。
- `<Leader>q`: Quit the current window. / 退出当前窗口。
- `<Leader>h`: Return to the Home Screen dashboard. / 返回 Home Screen 仪表板。
- `<Leader>Ss`: Save session. / 保存会话。
- `<Leader>Sl`: Load the last session. / 加载上一次会话。
- `<Leader>Sr`: Save session and reload AstroNvim. / 保存会话并重载 AstroNvim。
- `<Leader>tf` / `<Leader>th` / `<Leader>tv`: ToggleTerm float, horizontal, or vertical terminal. / 打开 ToggleTerm 浮动、水平或垂直终端。
- `<Leader>gg`: Lazygit in ToggleTerm. / 在 ToggleTerm 中打开 Lazygit。
- `<Leader>gdd`: Open the Git diff review view with Diffview. / 使用 Diffview 打开 Git 差异审阅视图。
- `<Leader>gdc`: Close the current Diffview tab. / 关闭当前 Diffview 标签页。
- `<Leader>gdf`: Focus the Diffview file panel. / 聚焦 Diffview 文件面板。
- `<Leader>gdt`: Toggle the Diffview file panel. / 切换 Diffview 文件面板。
- `<Leader>gdr`: Refresh the current Diffview. / 刷新当前 Diffview。
- `<Leader>gdh`: Show Git file history for the repo or selected paths. / 显示仓库或选中路径的 Git 文件历史。
- `<Leader>gdH`: Show Git history for the current file. / 显示当前文件的 Git 历史。
- `]x` / `[x`: Jump to the next or previous Git conflict. / 跳转到下一个或上一个 Git 冲突。
- `<Leader>gxo`: Resolve the current conflict with ours. / 使用 ours 解决当前冲突。
- `<Leader>gxt`: Resolve the current conflict with theirs. / 使用 theirs 解决当前冲突。
- `<Leader>gxb`: Keep both sides of the current conflict. / 保留当前冲突的双方内容。
- `<Leader>gxn`: Remove both sides of the current conflict. / 移除当前冲突的双方内容。
- `<Leader>gxq`: List Git conflicts in quickfix. / 在 quickfix 中列出 Git 冲突。
- `<Leader>gxr`: Refresh Git conflict detection. / 刷新 Git 冲突检测。
- `<Leader>sr`: Open GrugFar for project-wide search and replace. / 打开 GrugFar 执行项目级查找替换。
- `<Leader>sw`: Search and replace the word under the cursor with GrugFar. / 使用 GrugFar 查找并替换光标下的词。
- `<Leader>tw`: Open a web page with `w3m` in a terminal after entering a URL. / 输入 URL 后，在终端中用 `w3m` 打开网页。
- `<Leader>tW`: Open the URL under the cursor with `w3m` in a terminal. / 在终端中用 `w3m` 打开光标下的 URL。

## Markdown / Markdown 编辑

> These mappings are registered only in Markdown buffers. / 这些映射只会在 Markdown 缓冲区中注册。

- `<Leader>mp`: Open the `render-markdown` preview. / 打开 `render-markdown` 预览。
- `<Leader>mb`: Open the Markdown browser preview. / 打开 Markdown 浏览器预览。
- `<Leader>mm`: Toggle the Markdown browser preview with Mermaid support. / 切换带 Mermaid 支持的 Markdown 浏览器预览。
- `<Leader>mo`: Toggle the Markdown heading outline with Aerial. / 使用 Aerial 切换 Markdown 标题大纲。
- `<Leader>mn`: Toggle the Markdown section outline with Aerial. / 使用 Aerial 切换 Markdown 章节大纲。
- `<Leader>jj`: Toggle Jieba word motions for the current buffer. When enabled, `w`, `b`, `e`, and `ge` move by Chinese words. / 为当前缓冲区切换 Jieba 中文分词移动。启用后，`w`、`b`、`e` 和 `ge` 会按中文词移动。
- `]m` / `[m`: Jump to the next or previous Markdown heading. / 跳转到下一个或上一个 Markdown 标题。

### Neo-tree / Neo-tree 文件树

- `<CR>`: Open the file or directory in the current window. / 在当前窗口中打开文件或目录。
- `l`: Enter a directory. If it is already expanded, move to the first child. On files, this opens the file. / 进入目录；如果目录已展开，则移动到第一个子项。用于文件时会打开该文件。
- `h`: Collapse the current directory. If already collapsed, move to the parent directory. / 折叠当前目录；如果已经折叠，则移动到父目录。
- `s` / `S`: Open the file in a vertical or horizontal split. / 在垂直或水平分屏中打开文件。
- `t`: Open the file in a new tab. / 在新标签页中打开文件。
- `w`: Pick a target window, then open the file there. / 选择目标窗口，然后在该窗口中打开文件。
- `q`: Close the Neo-tree window. / 关闭 Neo-tree 窗口。
