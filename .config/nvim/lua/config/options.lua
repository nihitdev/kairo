-- ============================================================================
-- ⚙️ Neovim Options
-- ============================================================================

local opt = vim.opt

-- ============================================================================
-- 🎨 UI
-- ============================================================================

opt.termguicolors = true

-- 📏 Line numbers
opt.number = true
opt.relativenumber = true

-- ✨ Highlight current line
opt.cursorline = true

-- 🚦 Always reserve sign column
opt.signcolumn = "yes"

-- 🌎 Global statusline
opt.laststatus = 3

-- 🙈 Don't show -- INSERT --
opt.showmode = false

-- 📜 Smooth scrolling
opt.smoothscroll = true

-- 🧾 Better command completion
opt.wildmode = "longest:full,full"

-- ============================================================================
-- ✍️ Editing
-- ============================================================================

-- 🚫 Don't wrap long lines
opt.wrap = false

-- 📐 Tabs = 2 spaces
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true

-- 🧠 Smart indentation
opt.smartindent = true
opt.autoindent = true

-- 🖱️ Mouse support
opt.mouse = "a"

-- ============================================================================
-- 🔎 Search
-- ============================================================================

-- 🔡 Ignore case...
opt.ignorecase = true

-- 🧠 ...unless uppercase letters are used
opt.smartcase = true

-- 🔦 Highlight matches
opt.hlsearch = true

-- ⚡ Search while typing
opt.incsearch = true

-- ============================================================================
-- 🪟 Windows
-- ============================================================================

-- ⬇️ Horizontal splits below
opt.splitbelow = true

-- ➡️ Vertical splits right
opt.splitright = true

-- ============================================================================
-- 📋 Clipboard
-- ============================================================================

-- 📋 Use system clipboard
opt.clipboard = "unnamedplus"

-- ============================================================================
-- ⚡ Performance
-- ============================================================================

-- ⚡ Faster CursorHold/plugins
opt.updatetime = 200

-- ⌨️ Faster mapped-key response
opt.timeoutlen = 300

-- ============================================================================
-- 💾 Files
-- ============================================================================

-- 💾 Persistent undo
opt.undofile = true

-- 🔒 Don't create swap files
opt.swapfile = false

-- 💿 Don't create backup files
opt.backup = false
opt.writebackup = false

-- ============================================================================
-- 👀 Scrolling
-- ============================================================================

-- Keep some context around the cursor
opt.scrolloff = 8
opt.sidescrolloff = 8

-- ============================================================================
-- 📝 Characters
-- ============================================================================

opt.list = true

opt.listchars = {
  tab = "» ",
  trail = "·",
  nbsp = "␣",
}

-- Quiet chrome; native borders also cover LSP floats without plugin overrides.
opt.winborder = "rounded"
opt.fillchars:append({
  eob = " ",
  vert = "│",
  horiz = "─",
  horizup = "┴",
  horizdown = "┬",
  vertleft = "┤",
  vertright = "├",
  verthoriz = "┼",
})
opt.pumheight = 10
opt.title = true
opt.titlestring = "%t — ARCHNEMESIS // KAIRO"
vim.g.trouble_lualine = false
