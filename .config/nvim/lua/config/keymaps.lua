-- ============================================================================
-- 🎮 Keymaps
-- ============================================================================

local map = vim.keymap.set

-- ============================================================================
-- 🗿 Nano muscle memory
-- ============================================================================

-- 💾 Ctrl+O → Save
map({ "n", "i", "v" }, "<C-o>", function()
  vim.cmd("write")
end, { desc = "Save file" })

-- 🚪 Ctrl+X → Quit
map({ "n", "i", "v" }, "<C-x>", function()
  vim.cmd("quit")
end, { desc = "Quit Neovim" })

-- 💾 Ctrl+S → Save too
map({ "n", "i", "v" }, "<C-s>", function()
  vim.cmd("write")
end, { desc = "Save file" })

-- ============================================================================
-- ✍️ Editing
-- ============================================================================

-- ⚡ jk → Escape
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- ↔️ Keep selection while indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- 🔼🔽 Move selected lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ============================================================================
-- 🪟 Window navigation
-- ============================================================================

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- ============================================================================
-- 🧭 Navigation
-- ============================================================================

-- 🎯 Keep cursor centered
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })

map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })

-- ============================================================================
-- 📋 Clipboard
-- ============================================================================

map({ "n", "v" }, "<leader>y", [["+y]], {
  desc = "Copy to system clipboard",
})

map("n", "<leader>Y", [["+Y]], {
  desc = "Copy line to system clipboard",
})

-- ============================================================================
-- 🧹 Misc
-- ============================================================================

-- 🧹 Escape clears search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<CR>", {
  desc = "Clear search highlight",
})

-- Save without shadowing the window group
map("n", "<leader>bw", "<cmd>w<CR>", {
  desc = "Save file",
})

-- ❌ Close current buffer
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, {
  desc = "Close buffer",
})
