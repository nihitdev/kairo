-- Matugen writes a Base16-shaped palette here. Feed it into TokyoNight's
-- on_colors hook so Neovim follows the same wallpaper palette as Hyprland.
local uv = vim.uv or vim.loop
local COLORS = vim.fn.expand(vim.env.NVIM_PALETTE or "~/.cache/kairo/colors.json")
local palette_dir = vim.fn.fnamemodify(COLORS, ":h")
local palette_file = vim.fn.fnamemodify(COLORS, ":t")
vim.fn.mkdir(palette_dir, "p")

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
    -- A complete Rosé Pine inspired fallback also works without the palette daemon.
    p = {
      color0 = "#191724",
      color1 = "#eb6f92",
      color2 = "#9ccfd8",
      color3 = "#f6c177",
      color4 = "#c4a7e7",
      color5 = "#ebbcba",
      color6 = "#31748f",
      color7 = "#e0def4",
      color8 = "#908caa",
    }
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

-- Re-tint immediately when Matugen replaces the palette. The directory watcher
-- handles writes and atomic renames; FocusGained remains a fallback for cases
-- where the editor started before its cache directory existed.
local seen = (uv.fs_stat(COLORS) or {}).mtime
local function refresh_palette()
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
end

local debounce = uv.new_timer()
local function queue_refresh()
  debounce:stop()
  debounce:start(120, 0, function()
    vim.schedule(refresh_palette)
  end)
end

local palette_watch = uv.new_fs_event()
local watch_ok = pcall(function()
  palette_watch:start(palette_dir, {}, function(err, filename)
    if not err and (not filename or filename == palette_file) then
      vim.schedule(queue_refresh)
    end
  end)
end)
if not watch_ok then
  palette_watch:close()
end

local palette_group = vim.api.nvim_create_augroup("kairo_palette", { clear = true })
vim.api.nvim_create_autocmd("FocusGained", {
  group = palette_group,
  nested = true,
  callback = refresh_palette,
})
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = palette_group,
  once = true,
  callback = function()
    if not debounce:is_closing() then debounce:close() end
    if watch_ok and not palette_watch:is_closing() then palette_watch:close() end
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
