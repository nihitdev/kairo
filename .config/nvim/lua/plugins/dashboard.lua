return {
  {
    "folke/snacks.nvim",
    init = function()
      require("config.dashboard-motion").setup()
    end,
    keys = {
      { "<leader>ud", function() Snacks.dashboard() end, desc = "Dashboard" },
    },
    opts = {
      dashboard = {
        enabled = true,
        width = 60,
        pane_gap = 6,
        preset = {
          pick = function(cmd, opts)
            return LazyVim.pick(cmd, opts)()
          end,

          header = table.concat(require("config.dashboard-motion").header, "\n"),

          keys = {
            {
              icon = " ",
              key = "f",
              desc = "Find File",
              action = ":lua Snacks.dashboard.pick('files')",
            },
            {
              icon = " ",
              key = "n",
              desc = "New File",
              action = ":ene | startinsert",
            },
            {
              icon = " ",
              key = "g",
              desc = "Find Text",
              action = ":lua Snacks.dashboard.pick('live_grep')",
            },
            {
              icon = " ",
              key = "r",
              desc = "Recent Files",
              action = ":lua Snacks.dashboard.pick('oldfiles')",
            },
            {
              icon = " ",
              key = "e",
              desc = "Explorer",
              action = ":lua Snacks.explorer()",
            },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })",
            },
            {
              icon = " ",
              key = "s",
              desc = "Restore Session",
              section = "session",
            },
            {
              icon = "󰒲 ",
              key = "l",
              desc = "Lazy",
              action = ":Lazy",
            },
            {
              icon = " ",
              key = "q",
              desc = "Quit",
              action = ":qa",
            },
          },
        },

        sections = {
          { section = "header", padding = 1 },
          function()
            local hour = tonumber(os.date("%H"))
            local greeting = hour < 12 and "Good morning" or hour < 18 and "Good afternoon" or "Good evening"
            local account = (vim.uv or vim.loop).os_get_passwd()
            local username = account and account.username or vim.env.USER or vim.env.USERNAME or "there"
            return { text = { { greeting .. ", " .. username, hl = "SnacksDashboardDesc" },
              { "  /  " .. os.date("%a, %d %b"), hl = "SnacksDashboardFooter" } }, align = "center", padding = 1 }
          end,
          { section = "keys", gap = 0, padding = 1 },
          { icon = " ", title = "Recent files", section = "recent_files", limit = 4, indent = 2, padding = 1 },
          { icon = " ", title = "Projects", section = "projects", limit = 3, indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}
