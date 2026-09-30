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

-- ARCHNEMESIS V2 START
local function archnemesis_dev_highlights()
  local links = {
    -- DAP
    DapBreakpoint = "DiagnosticError",
    DapBreakpointCondition = "DiagnosticWarn",
    DapBreakpointRejected = "DiagnosticHint",
    DapLogPoint = "DiagnosticInfo",
    DapStopped = "Visual",

    -- Neotest
    NeotestPassed = "DiagnosticOk",
    NeotestFailed = "DiagnosticError",
    NeotestRunning = "DiagnosticWarn",
    NeotestSkipped = "Comment",
    NeotestTest = "Normal",
    NeotestNamespace = "Directory",
    NeotestFile = "Directory",
    NeotestDir = "Directory",

    -- Overseer
    OverseerRUNNING = "DiagnosticWarn",
    OverseerSUCCESS = "DiagnosticOk",
    OverseerFAILURE = "DiagnosticError",
    OverseerCANCELED = "Comment",

    -- Diffview
    DiffviewFilePanelTitle = "Title",
    DiffviewFilePanelCounter = "Comment",
    DiffviewStatusAdded = "GitSignsAdd",
    DiffviewStatusModified = "GitSignsChange",
    DiffviewStatusDeleted = "GitSignsDelete",
  }

  for group, target in pairs(links) do
    vim.api.nvim_set_hl(0, group, {
      link = target,
      default = false,
    })
  end
end

local archnemesis_dev_group = vim.api.nvim_create_augroup("ArchNemesisDevHighlights", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = archnemesis_dev_group,
  callback = archnemesis_dev_highlights,
})

vim.schedule(archnemesis_dev_highlights)
-- ARCHNEMESIS V2 END
