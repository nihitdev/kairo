local M = {}
M.header = {
  "██╗  ██╗ █████╗ ██╗██████╗  ██████╗ ",
  "██║ ██╔╝██╔══██╗██║██╔══██╗██╔═══██╗",
  "█████╔╝ ███████║██║██████╔╝██║   ██║",
  "██╔═██╗ ██╔══██║██║██╔══██╗██║   ██║",
  "██║  ██╗██║  ██║██║██║  ██║╚██████╔╝",
  "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ ",
  "",
  "A R C H N E M E S I S   /   N E O V I M",
}

function M.setup()
  local ns = vim.api.nvim_create_namespace("kairo_dashboard_header")
  local group = vim.api.nvim_create_augroup("KairoDashboardMotion", { clear = true })
  local timer = assert(vim.uv.new_timer())
  local frame = 0
  local function draw()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype ~= "snacks_dashboard" then
      timer:stop()
      return
    end
    local function rgb(name, fallback)
      local color = vim.api.nvim_get_hl(0, { name = name, link = false }).fg or fallback
      return { math.floor(color / 65536) % 256, math.floor(color / 256) % 256, color % 256 }
    end
    local a, b = rgb("Function", 0xc4a7e7), rgb("String", 0x9ccfd8)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      for index, art in ipairs(M.header) do
        if index <= 6 and line:find(art, 1, true) then
          local mix = (math.sin(frame * 0.09 + index * 0.5) + 1) / 2
          local color = {}
          for channel = 1, 3 do color[channel] = math.floor(a[channel] * (1 - mix) + b[channel] * mix) end
          local hl = "KairoDashboardGradient" .. index
          vim.api.nvim_set_hl(0, hl, { fg = string.format("#%02x%02x%02x", unpack(color)), bold = true })
          vim.api.nvim_buf_set_extmark(buf, ns, row - 1, 0, { end_col = #line, hl_group = hl, priority = 200 })
        end
      end
    end
    frame = frame + 1
  end
  local function start()
    if vim.bo.filetype ~= "snacks_dashboard" then return end
    timer:stop()
    draw()
    if vim.g.snacks_animate ~= false then
      timer:start(80, 80, vim.schedule_wrap(draw))
    end
  end
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = group,
    callback = function() vim.schedule(start) end,
  })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "SnacksDashboardUpdatePost", callback = start })
  vim.api.nvim_create_autocmd("BufLeave", { group = group, callback = function() timer:stop() end })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = function() timer:stop(); timer:close() end })
end
return M
