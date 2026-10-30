return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          pick = function(cmd, opts)
            return LazyVim.pick(cmd, opts)()
          end,

          header = "ARCHNEMESIS\n\n  neovim",

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
          { section = "header" },
          { section = "keys", gap = 0, padding = 1 },
          { icon = " ", title = "Recent files", section = "recent_files", limit = 4, indent = 2, padding = 1 },
          { icon = " ", title = "Projects", section = "projects", limit = 3, indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}
