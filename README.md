# AstroNvim Template

**NOTE:** This is for AstroNvim v6+

A template for getting started with [AstroNvim](https://github.com/AstroNvim/AstroNvim)

## 🛠️ Installation

#### Make a backup of your current nvim and shared folder

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

#### Create a new user repository from this template

Press the "Use this template" button above to create a new repository to store your user configuration.

You can also just clone this repository directly if you do not want to track your user configuration in GitHub.

#### Clone the repository

```shell
git clone https://github.com/<your_user>/<your_repository> ~/.config/nvim
```

#### Install native dependencies

Chinese word motions and `<Leader>jw` use `neo451/jieba.nvim` with its native
`cppjieba` Lua rock. On macOS, install XMake before the first Neovim launch:

```shell
brew install xmake
```

A separate system-wide LuaRocks installation is not required. `lazy.nvim`
bootstraps Hererocks/LuaRocks and installs the native module under
`~/.local/share/nvim/lua-rocks`. Rocks support and its required root are
configured in `lua/lazy_setup.lua`; do not disable or rename them while using
`jieba.nvim`.

The first launch downloads and builds the native dependencies. Wait for Lazy
to finish, restart Neovim if requested, and use `:checkhealth lazy` if the build
does not complete. XMake 3.0.9 is the tested version for macOS arm64.

#### Start Neovim

```shell
nvim
```
