-- LazyVim already restores the cursor and highlights yanks.
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "markdown",
    "text",
    "gitcommit",
  },

  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})

-- Keep the current editing window in focus, without dimming entire buffers.
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "WinLeave" }, {
  group = vim.api.nvim_create_augroup("kairo_cursorline", { clear = true }),
  callback = function(event)
    vim.wo.cursorline = event.event ~= "WinLeave" and vim.bo.buftype == ""
  end,
})
