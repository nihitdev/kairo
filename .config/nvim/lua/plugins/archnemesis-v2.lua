return {
  -- ==========================================================================
  -- Treesitter Textobjects — argument swapping + structural movement
  -- ==========================================================================

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",

    keys = {
      {
        "<leader>rj",
        function()
          require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
        end,
        desc = "Swap Argument Next",
      },

      {
        "<leader>rk",
        function()
          require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
        end,
        desc = "Swap Argument Previous",
      },

      {
        "]f",
        function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
        end,
        mode = { "n", "x", "o" },
        desc = "Next Function",
      },

      {
        "[f",
        function()
          require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
        end,
        mode = { "n", "x", "o" },
        desc = "Previous Function",
      },

      {
        "]c",
        function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
        end,
        mode = { "n", "x", "o" },
        desc = "Next Class",
      },

      {
        "[c",
        function()
          require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
        end,
        mode = { "n", "x", "o" },
        desc = "Previous Class",
      },
    },
  },

  -- ==========================================================================
  -- Diffview — serious Git diff/history UI
  -- ==========================================================================

  {
    "sindrets/diffview.nvim",

    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
      "DiffviewRefresh",
    },

    opts = {
      enhanced_diff_hl = true,
      show_help_hints = true,
      watch_index = true,

      signs = {
        fold_closed = "",
        fold_open = "",
        done = "✓",
      },
    },

    keys = {
      {
        "<leader>gv",
        "<cmd>DiffviewOpen<cr>",
        desc = "Diffview",
      },

      {
        "<leader>gV",
        "<cmd>DiffviewFileHistory<cr>",
        desc = "Repository History",
      },

      {
        "<leader>gH",
        "<cmd>DiffviewFileHistory %<cr>",
        desc = "File History",
      },

      {
        "<leader>gQ",
        "<cmd>DiffviewClose<cr>",
        desc = "Close Diffview",
      },
    },
  },

  -- ==========================================================================
  -- Neotest — add Vitest for JS/TS.
  -- Go/Rust/Zig adapters come from their LazyVim language extras.
  -- ==========================================================================

  {
    "nvim-neotest/neotest",

    dependencies = {
      "marilari88/neotest-vitest",
    },

    opts = {
      adapters = {
        ["neotest-vitest"] = {},
      },

      quickfix = {
        open = false,
      },

      output = {
        open_on_run = false,
      },

      summary = {
        animated = false,
      },
    },
  },

  -- ==========================================================================
  -- DAP polish
  -- ==========================================================================

  {
    "rcarriga/nvim-dap-ui",

    opts = {
      floating = {
        border = "rounded",
      },

      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.40 },
            { id = "breakpoints", size = 0.20 },
            { id = "stacks", size = 0.20 },
            { id = "watches", size = 0.20 },
          },
          size = 38,
          position = "left",
        },

        {
          elements = {
            { id = "repl", size = 0.50 },
            { id = "console", size = 0.50 },
          },
          size = 12,
          position = "bottom",
        },
      },
    },
  },

  {
    "theHamsta/nvim-dap-virtual-text",

    opts = {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      only_first_definition = true,
      all_references = false,
      clear_on_continue = false,

      display_callback = function(variable, _, _, _, options)
        if options.virt_text_pos == "inline" then
          return " = " .. variable.value
        end

        return variable.name .. " = " .. variable.value
      end,
    },
  },

  -- ==========================================================================
  -- Overseer — build/task runner
  -- ==========================================================================

  {
    "stevearc/overseer.nvim",

    opts = {
      task_list = {
        direction = "bottom",
        min_height = 8,
        max_height = 18,

        keymaps = {
          ["<C-j>"] = false,
          ["<C-k>"] = false,
        },
      },

      form = {
        border = "rounded",
      },

      confirm = {
        border = "rounded",
      },

      task_win = {
        border = "rounded",
      },
    },

    keys = {
      {
        "<leader>or",
        "<cmd>OverseerRun<cr>",
        desc = "Run Task",
      },

      {
        "<leader>ot",
        "<cmd>OverseerToggle<cr>",
        desc = "Toggle Tasks",
      },

      {
        "<leader>oa",
        "<cmd>OverseerTaskAction<cr>",
        desc = "Task Action",
      },
    },
  },

  -- ==========================================================================
  -- Snacks — explicit project navigation
  -- ==========================================================================

  {
    "folke/snacks.nvim",

    keys = {
      {
        "<leader>fp",
        function()
          Snacks.picker.projects()
        end,
        desc = "Projects",
      },
    },
  },

  -- ==========================================================================
  -- WhichKey grouping
  -- ==========================================================================

  {
    "folke/which-key.nvim",

    opts = {
      spec = {
        { "<leader>d", group = "Debug" },
        { "<leader>g", group = "Git" },
        { "<leader>o", group = "Tasks" },
        { "<leader>r", group = "Refactor" },
        { "<leader>t", group = "Test" },
      },
    },
  },
}
