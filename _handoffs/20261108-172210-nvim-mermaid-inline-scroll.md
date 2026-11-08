# Neovim Mermaid 内嵌长图：尺寸与滚动问题交接

## Metadata

- Generated at: `2026-11-08T17:22:10+08:00`
- Intent: `continue`
- Base directory: `/Users/zhiwen.wang/GitHubRepos/zish-rob-crur/AstroNvim`
- Git repo root: `/Users/zhiwen.wang/GitHubRepos/zish-rob-crur/AstroNvim`
- Git branch: `main`

## 最新决定

用户决定暂停内嵌长图方案的研究，日常使用现有 live-preview.nvim 浏览器并排预览。临时 MermaidViewport 原型已关闭，命令已移除，未接入默认配置。原型及本机测试记录位于 Downloads/mermaid-viewport-prototype，不包含在本次提交中。下方 Next Steps 仅供以后恢复研究时参考。

## Summary

用户希望在 Neovim 的 Markdown 正文中边写边预览 Mermaid。图片已经能生成并显示，也已适配编辑器配色；未解决的是复杂图缩小后不可读，放大到超过一屏后又会在滚动时跳过中间。已验证 winrestview(topfill) 不能绕过 Nvim 0.12.3 的超高虚拟行限制。交接目标是继续验证正文内可读、可完整浏览的方案，而不是继续调主题或安装依赖。

## Status

- 环境：macOS + Ghostty（此前记录 1.4.0）+ tmux 3.7c；Nvim 0.12.3；Snacks 本地提交 e6fd58c；Mermaid CLI 12.2.0；ImageMagick 7.1.2-35。
- 已启用 Snacks.image；lua/user/mermaid.lua 根据 Normal/Type/Comment 高亮生成 mmdc 主题，透明背景、细边框、18px PingFang SC。docs/mermaid-review.md 是复杂流程图与时序图评审样例。
- 最初不显示图片的原因之一已修复：render-markdown 隐藏 closing fence 时也隐藏了挂在其后的 Snacks 图片，现设 code.border="thin"。含 Mermaid 或 Markdown 图片的文档已禁用 typewriter 自动居中，减少额外跳动；这不是超高虚拟行的根因。
- 当前持久配置仍是 doc.max_width=120、doc.max_height=40；`<Leader>m+` / `<Leader>m-` / `<Leader>m0` 只调整宽度，仍受高度上限约束。`<Leader>mv` 是另开标签页的备用查看器，使用真实空白 buffer 行承载图片，可滚动与缩放；它没有满足用户优先要求的正文内编辑预览体验。
- 已验证失败：直接扩大图片高度到 256 会产生超高 virt_lines，普通滚动跳过图片中段；此前 smoothscroll 开/关均不能解决。最新 topfill 实验在用户 %294 和 --clean 独立 Neovim UI 中均复现，详见下方证据。
- 仅概念验证成功：曾将约 163 行高图片的 placeholder 行截成 8 行，offset 从 0 改为 40，显示片段确实变化，源 Markdown 未变。没有交付图内滚动、滚轮衔接或实时刷新；该切片实验未写入仓库。

## Decisions

- 验收标准：正文内边写边预览；复杂图文字可读；能够连续浏览整张图而不跳过中段；编辑后能更新；不往源 Markdown 塞占位空行。独立标签页/浏览器只是备选，不能默认为已经满足目标。
- 保留现有渲染器与主题，优先最小、有界实验；不要重写 Mermaid 渲染器，不要把未验证的交互方案当成已完成修复。

## Next Steps

- 优先验证固定高度的图内视口：保留完整图像尺寸，仅截取 Snacks 已编码的 virt_lines 子区间，offset 决定显示位置。先用手动命令控制 offset，证明从图首到图尾都可读、无遗漏且源文件不变。
- 若上述实验通过，再完成图内滚动与正文滚动的边界衔接。鼠标滚轮、j/k、Ctrl-e/Ctrl-y 的具体行为尚未确认，不要全局重映射；先做 Markdown 局部可撤销原型供用户 review。
- 验证修改 Mermaid 后重新生成、窗口尺寸变化、多张图、重新进入 buffer 与 placement 清理。用 docs/mermaid-review.md 进行实际 %294 操作验证，不能仅凭内部 offset 数值宣称 UI 正常。完成后删繁复核，再写入持久配置。

## Open Questions

- 固定高度的图内视口是否符合用户操作习惯，尚未获得实际体验确认；技术切片成功也不代表整套滚动交互已经成立。

## Risks And Assumptions

- 工作树未提交且有其他工作：lua/plugins/minuet.lua、lua/plugins/statusline.lua、scripts/check_writing_completion.lua、nvim.log 不属于本问题；docs/keymaps.md 也包含先前修改。只接续明确相关部分，不要覆盖或回滚其他改动。
- 候选切片方案触及 Snacks 内部 API，插件更新可能破坏。应尽量使用 placement 实例级包装并限制适用范围；不要直接修改 lazy 插件安装目录。

## Notes

- 关键文件：lua/plugins/snacks.lua:5-10（启用、尺寸与 Mermaid 转换）；lua/plugins/markdown.lua:10-13（快捷键）、102-136（typewriter）、154-160（closing fence）；lua/user/mermaid.lua:5-14（缩放）、16-65（备用查看器）、68-112（主题）；docs/keymaps.md:169-170（相关快捷键）；docs/mermaid-review.md（人工验收样例）。
- 最新实测（2026-11-08）：用 160 行编号 VIRTUAL 内容模拟图片，窗口高度 21。请求 topfill=160/159/120/80/40 时，winrestview 返回后立刻读到 topline=10、topfill=0；redraw 后变为 topline=11、topfill=10，屏幕首行是 VIRTUAL 151。请求 topfill=10 能保留。%294 与完全不加载插件的嵌入式 UI 结果相同；不是普通虚拟行完全不能滚，而是无法用此 API 浏览超高块的任意位置。测试 tab 已关闭，本轮实验没有更改持久配置。
- 源码依据（对应 v0.12.3）：[f_winrestview](https://github.com/neovim/neovim/blob/v0.12.3/src/nvim/eval/window.c#L887) 末尾调用 check_topfill；[check_topfill](https://github.com/neovim/neovim/blob/v0.12.3/src/nvim/move.c#L1633) 当 topfill 加真实行高度超过窗口时归零/裁减；之后 update_topline 还有保持真实光标可见的校正。单纯循环设置 topfill 或 scrolloff=0 不解决已确认的高度限制。
- 上游： [Snacks Discussion #2107](https://github.com/folke/snacks.nvim/discussions/2107) 与用户诉求几乎相同，社区脚本临时把 j/k 转为 Ctrl-e/Ctrl-y，只识别普通 Markdown 图片，未证明支持超长 Mermaid；不是官方合并修复。[Neovim #16166](https://github.com/neovim/neovim/issues/16166) 是 topfill 建议来源，不能当成超长图已解决。[#41519](https://github.com/neovim/neovim/pull/41519) 解释超高虚拟行的限制，但修的是 scrollbind，后由 [#41820](https://github.com/neovim/neovim/pull/41820) 撤回。不要据此建议升级即可解决。
- 候选实现接入点（推导，未完成）：~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/image/placement.lua 的 render_grid（约226行）、virt_lines 组装（约342行）、_render（约372行）、update 的 _state 相等提前返回（约531行）。可通过 doc.on_update_pre 给 inline=true、conceal=false 的 placement 安装一次 _render 包装，切片 virt_lines；保持完整 Kitty placement 宽高，调整 offset 后使 _state 失效并 update。不要覆盖 on_update，inline.lua 用它维护 extmark 索引；原始 _render 会修改传入 extmark 表，重复使用时需深拷贝。
- 会话：tmux pane %294。上次 Nvim PID=42007，RPC socket=/var/folders/ss/rt950myn5jq3tnk75wf24y2h0000gn/T/nvim.zhiwen.wang/9hXxYc/nvim.42007.0；这些标识会失效，使用前重新核对进程与 socket。通过 RPC 检查状态，保留用户未保存内容。浏览器自动化仅允许 Chrome 连接，不能使用 native GUI 或 IAB。
- 复现文件 /tmp/codex-topfill-probe.lua 的完整内容已附在下方；临时文件消失时可从文档恢复，需去掉代码左侧的行号与竖线。干净环境复现命令：

```sh
nvim --clean --headless -n '+lua local c=vim.fn.jobstart({"nvim","--clean","--embed","-n"},{rpc=true}); vim.rpcrequest(c,"nvim_ui_attach",80,24,{rgb=true}); local r=vim.rpcrequest(c,"nvim_exec_lua","return dofile(...)",{"/tmp/codex-topfill-probe.lua"}); print(vim.json.encode(r)); vim.fn.jobstop(c)' +qa
```

## Context Files

### `lua/plugins/snacks.lua` (lines 1-10)
Resolved path: `/Users/zhiwen.wang/GitHubRepos/zish-rob-crur/AstroNvim/lua/plugins/snacks.lua`

```text
 1 | return {
 2 |   {
 3 |     "folke/snacks.nvim",
 4 |     opts = function(_, opts)
 5 |       opts.image = {
 6 |         enabled = true,
 7 |         -- Inline images are overviews; use the image viewer for tall diagrams.
 8 |         doc = { max_width = 120, max_height = 40 },
 9 |         convert = { mermaid = function() return require("user.mermaid").args() end },
10 |       }
```

### `lua/user/mermaid.lua` (lines 3-14)
Resolved path: `/Users/zhiwen.wang/GitHubRepos/zish-rob-crur/AstroNvim/lua/user/mermaid.lua`

```text
 3 | -- Recreate this buffer's placements with the new document size. Image pixels
 4 | -- stay cached; zooming does not invoke Mermaid CLI again.
 5 | function M.zoom(delta)
 6 |   local image = require("snacks").image
 7 |   local doc = image.config.doc
 8 |   doc.max_width = delta == 0 and 120 or math.max(40, math.min(240, doc.max_width + delta))
 9 |   doc.height, doc.max_height = nil, 40
10 |   local buf = vim.api.nvim_get_current_buf()
11 |   image.placement.clean(buf)
12 |   vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = buf })
13 |   vim.notify(("Image width: up to %d columns (limited by window width)"):format(doc.max_width))
14 | end
```

### `/private/tmp/codex-topfill-probe.lua` (lines 1-31)
Resolved path: `/private/tmp/codex-topfill-probe.lua`

```text
 1 | local api = vim.api
 2 | local original_tab = api.nvim_get_current_tabpage()
 3 | vim.cmd('noautocmd tabnew')
 4 | local buf = api.nvim_get_current_buf()
 5 | vim.bo[buf].buftype, vim.bo[buf].bufhidden = 'nofile', 'wipe'
 6 | vim.wo.scrolloff, vim.wo.sidescrolloff = 0, 0
 7 | vim.wo.wrap, vim.wo.number, vim.wo.relativenumber = false, false, false
 8 | local lines = {}
 9 | for i = 1, 100 do lines[i] = ('SOURCE %03d'):format(i) end
10 | api.nvim_buf_set_lines(buf, 0, -1, false, lines)
11 | local virtual = {}
12 | for i = 1, 160 do virtual[i] = {{('VIRTUAL %03d'):format(i), 'Normal'}} end
13 | api.nvim_buf_set_extmark(buf, api.nvim_create_namespace('codex-topfill-probe'), 9, 0, {virt_lines = virtual})
14 | local results = {height=api.nvim_win_get_height(0), cases={}}
15 | for _, fill in ipairs({160, 159, 120, 80, 40, 10, 0}) do
16 |   vim.fn.winrestview({topline=11, lnum=11, col=0, topfill=fill})
17 |   local before = vim.fn.winsaveview()
18 |   vim.cmd('redraw!')
19 |   local after = vim.fn.winsaveview()
20 |   local screen = {}
21 |   local start = vim.fn.win_screenpos(0)[1]
22 |   for row=start,start+math.min(3,results.height)-1 do
23 |     local chars={}
24 |     for col=1,30 do chars[#chars+1]=vim.fn.screenstring(row,col) end
25 |     screen[#screen+1]=table.concat(chars)
26 |   end
27 |   results.cases[#results.cases+1]={requested=fill,before=before,after=after,screen=screen}
28 | end
29 | vim.cmd('noautocmd tabclose!')
30 | api.nvim_set_current_tabpage(original_tab)
31 | return results
```

## Command Outputs

### `git status --short`
- Exit code: `0`

#### stdout

```text
 M docs/keymaps.md
 M lua/plugins/markdown.lua
 M lua/plugins/minuet.lua
 M lua/plugins/snacks.lua
 M lua/plugins/statusline.lua
 M scripts/check_writing_completion.lua
?? docs/mermaid-review.md
?? lua/user/mermaid.lua
?? nvim.log
```

#### stderr

```text
(empty)
```
