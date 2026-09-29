-- Dynamic colorscheme integration with a TokyoNight fallback.
--
-- An optional palette provider can write a Base16 palette for dynamic theming.
-- on every palette change -- the same file kitty and the shell read. We feed it
-- into tokyonight's on_colors so nvim matches the terminal, keep habamax as the
-- safety net, and re-tint a running editor when the palette changes.
local uv = vim.uv or vim.loop
local COLORS = vim.fn.expand(vim.env.NVIM_PALETTE or "~/.cache/kairo/colors.json")

local function palette()
  local f = io.open(COLORS, "r")
  if not f then
    return nil
  end
  local raw = f:read("*a")
  f:close()
  local ok, p = pcall(vim.json.decode, raw)
  if not ok or type(p) ~= "table" or not p.color0 then
    return nil
  end
  for i = 0, 8 do
    if type(p["color" .. i]) ~= "string" or not p["color" .. i]:match("^#%x%x%x%x%x%x$") then
      return nil
    end
  end
  return p
end

-- map the base16 palette onto tokyonight's colour slots (run on every apply)
local function tint(c)
  local p = palette()
  if not p then
    return
  end
  c.bg, c.bg_dark, c.bg_float = p.color0, p.color0, p.color0
  c.bg_popup, c.bg_sidebar, c.bg_statusline = p.color0, p.color0, p.color0
  c.fg, c.fg_dark, c.fg_gutter, c.comment = p.color7, p.color8, p.color8, p.color8
  c.red, c.green, c.yellow = p.color1, p.color2, p.color3
  c.blue, c.magenta, c.cyan = p.color4, p.color5, p.color6
  c.purple, c.teal, c.orange = p.color5, p.color6, p.color3
  -- TokyoNight computes some shades before on_colors; keep those in the palette too.
  local blend = require("tokyonight.util").blend
  c.blue0, c.blue1, c.blue2, c.blue5, c.blue6, c.blue7 = p.color4, p.color6, p.color4, p.color4, p.color6, p.color4
  c.magenta2, c.green1, c.green2 = p.color5, p.color2, p.color2
  c.dark3, c.dark5, c.terminal_black = p.color8, p.color8, p.color8
  c.bg_highlight = blend(p.color4, 0.12, p.color0)
  c.bg_visual = blend(p.color4, 0.22, p.color0)
  c.bg_search = blend(p.color4, 0.35, p.color0)
  c.border, c.border_highlight = blend(p.color8, 0.5, p.color0), p.color4
  c.fg_sidebar, c.fg_float = p.color7, p.color7
  c.error, c.warning, c.info, c.hint = p.color1, p.color3, p.color4, p.color6
  c.git = { add = p.color2, change = p.color4, delete = p.color1 }
  c.diff = {
    add = blend(p.color2, 0.12, p.color0),
    change = blend(p.color4, 0.12, p.color0),
    delete = blend(p.color1, 0.12, p.color0),
    text = blend(p.color4, 0.22, p.color0),
  }
end

-- One theme hook keeps chrome coherent on startup and every palette refresh.
local function chrome(h, c)
  local blend = require("tokyonight.util").blend
  local edge = blend(c.blue, 0.35, c.bg)
  local quiet = blend(c.comment, 0.35, c.bg)
  for _, group in ipairs({
    "Normal",
    "NormalNC",
    "SignColumn",
    "FoldColumn",
    "EndOfBuffer",
    "StatusLine",
    "StatusLineNC",
    "TabLineFill",
    "SnacksDashboardNormal",
  }) do
    h[group] = vim.tbl_extend("force", h[group] or {}, { bg = "NONE" })
  end
  h.NormalFloat = { fg = c.fg, bg = c.bg_float }
  h.FloatBorder = { fg = edge, bg = c.bg_float }
  h.FloatTitle = { fg = c.blue, bg = c.bg_float, bold = true }
  h.WinSeparator = { fg = edge, bg = "NONE" }
  h.CursorLine = { bg = blend(c.blue, 0.06, c.bg) }
  h.CursorLineNr = { fg = c.blue, bold = true }
  h.SnacksIndent = { fg = quiet }
  h.SnacksIndentScope = { fg = edge }
  h.SnacksDashboardHeader = { fg = c.blue, bold = true }
  h.SnacksDashboardDesc = { fg = c.fg }
  h.SnacksDashboardKey = { fg = c.cyan, bold = true }
  h.SnacksDashboardFooter = { fg = c.comment }
  for _, group in ipairs({
    "SnacksPickerNormal",
    "SnacksPickerPreview",
    "SnacksPickerList",
    "SnacksPickerInput",
    "SnacksPickerBox",
  }) do
    h[group] = { fg = c.fg, bg = c.bg_float }
  end
  for _, group in ipairs({
    "SnacksPickerBorder",
    "SnacksPickerInputBorder",
    "SnacksPickerBoxBorder",
    "BlinkCmpMenuBorder",
    "BlinkCmpDocBorder",
    "BlinkCmpSignatureHelpBorder",
    "NoicePopupBorder",
  }) do
    h[group] = { fg = edge, bg = c.bg_float }
  end
  for _, group in ipairs({ "SnacksPickerTitle", "SnacksPickerInputTitle", "SnacksPickerBoxTitle" }) do
    h[group] = { fg = c.blue, bg = c.bg_float, bold = true }
  end
  h.BlinkCmpMenuSelection = { bg = c.bg_visual, bold = true }
  for _, level in ipairs({ "Debug", "Error", "Info", "Trace", "Warn" }) do
    h["SnacksNotifier" .. level] = { fg = c.fg, bg = c.bg_float }
    h["SnacksNotifierBorder" .. level] = { fg = edge, bg = c.bg_float }
  end
  for _, group in ipairs({
    "BufferLineFill",
    "BufferLineBackground",
    "BufferLineBufferVisible",
    "BufferLineSeparator",
    "BufferLineSeparatorVisible",
    "BufferLineSeparatorSelected",
    "BufferLineOffsetSeparator",
  }) do
    h[group] = { fg = c.comment, bg = "NONE" }
  end
  h.BufferLineBufferSelected = { fg = c.fg, bg = c.bg_highlight, bold = true, italic = false }
  h.BufferLineIndicatorSelected = { fg = c.blue, bg = c.bg_highlight }
  h.BufferLineModifiedSelected = { fg = c.yellow, bg = c.bg_highlight }
  h.BufferLineCloseButtonSelected = { fg = c.comment, bg = c.bg_highlight }
end

-- Re-tint when the daemon rewrites the palette. Re-running :colorscheme re-invokes
-- on_colors (which re-reads the file), so no re-setup is needed; mtime-gated so a
-- focus change without a palette change never repaints.
local seen = (uv.fs_stat(COLORS) or {}).mtime
vim.api.nvim_create_autocmd("FocusGained", {
  group = vim.api.nvim_create_augroup("kairo_palette", { clear = true }),
  nested = true, -- Let ColorScheme consumers (lualine/bufferline) refresh too.
  callback = function()
    local st = uv.fs_stat(COLORS)
    if not st then
      return
    end
    if seen and st.mtime.sec == seen.sec and st.mtime.nsec == seen.nsec then
      return
    end
    seen = st.mtime
    local name = vim.g.colors_name
    if name and name:find("tokyonight") then
      pcall(vim.cmd.colorscheme, name)
    end
  end,
})

return {
  {
    "folke/tokyonight.nvim",
    opts = function(_, opts)
      opts.style = opts.style or "night"
      opts.on_colors = tint
      opts.on_highlights = chrome
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        if not pcall(vim.cmd.colorscheme, "tokyonight-night") then
          vim.cmd.colorscheme("habamax")
        end
      end,
    },
  },
}
