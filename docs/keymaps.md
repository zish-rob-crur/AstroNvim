# 键位速查（我的 AstroNvim）

> `Leader` = `<Space>`（空格），`LocalLeader` = `,`

## 怎么查键位（最推荐）

- `<Leader>fk`：用 Telescope 搜索所有键位（最实用）
- 直接按 `<Leader>`：等 `which-key` 弹出菜单，再按下一层按键
- 不确定某个键是谁设的：用 `:verbose nmap <key>`（例如 `:verbose nmap <Leader>ff`）

## 跳转导航（重点）

### Flash（当前文件内快速跳转）

- `s`：Flash 跳转（输入 1–2 个字符 → 选标签跳过去）
- `S`：Flash 语法树跳转（按 Treesitter 语法节点跳）

提示：Flash 会覆盖 Vim 原生的 `s`/`S`（替代用法：`cl` ≈ 原 `s`，`cc` ≈ 原 `S`）。

### Harpoon（常用文件“传送门”）

- `<Leader>aa`：把当前文件加入 Harpoon
- `<Leader>am`：打开/关闭 Harpoon 快速菜单
- `<Leader>1`/`2`/`3`/`4`：跳到第 1–4 个标记文件
- `<Leader>an` / `<Leader>ap`：下一个 / 上一个标记

## 文件/搜索（Telescope）

- `<Leader>ff`：Find files
- `<Leader>fF`：Find all files
- `<Leader>fw`：Find words（项目内全文搜索）
- `<Leader>f/`：Find words in current buffer（当前文件搜索）
- `<Leader>fb`：Find buffers
- `<Leader>fh`：Find help
- `<Leader>f<CR>`：Resume previous search

## 代码结构 / 诊断（导航常用）

- `<Leader>lS`：Symbols outline（Aerial 侧栏）
- `<Leader>ls`：Search symbols（Telescope）
- `<Leader>lD`：Search diagnostics（Telescope）
- `<Leader>ld`：Hover diagnostics

### LSP 跳转（语言服务器 attach 后可用）

- `gd`：跳到定义（Definition）
- `gD`：跳到声明（Declaration）
- `gI`：跳到实现（Implementation）
- `gy`：跳到类型定义（Type Definition）
- `K`：Hover 文档
- `<Leader>lR`：查找引用（References）
- `<Leader>lr`：重命名（Rename）
- `<Leader>la`：Code action

说明：这些 LSP 键位大多是 **buffer-local**（只有语言服务器 attach 到当前 buffer 后才会出现），最稳的方式还是用 `<Leader>fk` 搜索确认。

## 窗口 / Buffer

- `<C-h/j/k/l>`：在分屏间移动
- `<C-Up/Down/Left/Right>`：调整分屏大小
- `]b` / `[b`：下一个 / 上一个 buffer
- `<Leader>c`：关闭当前 buffer
- `<Leader>bb`：从 tabline 选 buffer
- `<Leader>bd`：从 tabline 关 buffer

## 其它常用

- `<Leader>e`：Neo-tree 文件树开关
- `<Leader>w`：保存
- `<Leader>q`：退出当前窗口
- `<Leader>h`：回到 Home Screen（Dashboard）
- `<Leader>Ss`：保存 session；`<Leader>Sl`：加载上次 session
- `<Leader>tf` / `<Leader>th` / `<Leader>tv`：ToggleTerm（浮窗/水平/竖直）
- `<Leader>gg`：lazygit（ToggleTerm）
