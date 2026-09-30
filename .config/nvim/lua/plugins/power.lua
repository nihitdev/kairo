return {
  -- ==========================================================================
  -- Trouble — diagnostics, symbols, LSP, quickfix
  -- ==========================================================================

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},

    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Workspace Diagnostics",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics",
      },
      {
        "<leader>xs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Document Symbols",
      },
      {
        "<leader>xl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP References",
      },
      {
        "<leader>xq",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List",
      },
    },
  },

  -- ==========================================================================
  -- Gitsigns — hunks, blame, staging, diff
  -- ==========================================================================

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },

    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },

      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },

      current_line_blame = false,

      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 600,
        ignore_whitespace = true,
      },

      preview_config = {
        border = "rounded",
        style = "minimal",
      },
    },

    keys = {
      {
        "]h",
        function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            require("gitsigns").nav_hunk("next")
          end
        end,
        desc = "Next Git Hunk",
      },
      {
        "[h",
        function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            require("gitsigns").nav_hunk("prev")
          end
        end,
        desc = "Previous Git Hunk",
      },
      {
        "<leader>ghp",
        function()
          require("gitsigns").preview_hunk()
        end,
        desc = "Preview Hunk",
      },
      {
        "<leader>ghi",
        function()
          require("gitsigns").preview_hunk_inline()
        end,
        desc = "Preview Hunk Inline",
      },
      {
        "<leader>ghs",
        function()
          require("gitsigns").stage_hunk()
        end,
        desc = "Stage Hunk",
      },
      {
        "<leader>ghr",
        function()
          require("gitsigns").reset_hunk()
        end,
        desc = "Reset Hunk",
      },
      {
        "<leader>ghS",
        function()
          require("gitsigns").stage_buffer()
        end,
        desc = "Stage Buffer",
      },
      {
        "<leader>ghR",
        function()
          require("gitsigns").reset_buffer()
        end,
        desc = "Reset Buffer",
      },
      {
        "<leader>ghb",
        function()
          require("gitsigns").blame_line({ full = true })
        end,
        desc = "Blame Line",
      },
      {
        "<leader>gtb",
        function()
          require("gitsigns").toggle_current_line_blame()
        end,
        desc = "Toggle Line Blame",
      },
      {
        "<leader>ghd",
        function()
          require("gitsigns").diffthis()
        end,
        desc = "Diff File",
      },
      {
        "<leader>ghD",
        function()
          require("gitsigns").diffthis("~")
        end,
        desc = "Diff Against HEAD~",
      },
    },
  },

  -- ==========================================================================
  -- TODO Comments
  -- ==========================================================================

  {
    "folke/todo-comments.nvim",
    event = "LazyFile",
    dependencies = { "nvim-lua/plenary.nvim" },

    opts = {
      signs = true,

      highlight = {
        keyword = "wide_fg",
        after = "fg",
        comments_only = true,
      },
    },

    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next TODO",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous TODO",
      },
      {
        "<leader>xt",
        "<cmd>Trouble todo toggle<cr>",
        desc = "Project TODOs",
      },
    },
  },

  -- ==========================================================================
  -- Flash — stupid-fast movement
  -- ==========================================================================

  {
    "folke/flash.nvim",
    event = "VeryLazy",

    opts = {
      modes = {
        char = {
          jump_labels = true,
        },
      },
    },

    keys = {
      {
        "s",
        function()
          require("flash").jump()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash Jump",
      },
      {
        "S",
        function()
          require("flash").treesitter()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash Treesitter",
      },
      {
        "r",
        function()
          require("flash").remote()
        end,
        mode = "o",
        desc = "Flash Remote",
      },
      {
        "R",
        function()
          require("flash").treesitter_search()
        end,
        mode = { "o", "x" },
        desc = "Flash Treesitter Search",
      },
      {
        "<C-s>",
        function()
          require("flash").toggle()
        end,
        mode = "c",
        desc = "Toggle Flash Search",
      },
    },
  },

  -- ==========================================================================
  -- Conform — formatting
  -- ==========================================================================

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",

    opts = function(_, opts)
      opts = opts or {}

      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        rust = { "rustfmt" },

        zig = { "zigfmt" },

        go = {
          "goimports",
          "gofmt",
          stop_after_first = true,
        },

        javascript = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        javascriptreact = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        typescript = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        typescriptreact = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        json = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        jsonc = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        css = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        scss = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        html = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        yaml = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        markdown = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        ["markdown.mdx"] = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        lua = { "stylua" },

        python = {
          "ruff_format",
          "black",
          stop_after_first = true,
        },

        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },

        toml = { "taplo" },
      })

      opts.default_format_opts = vim.tbl_deep_extend("force", opts.default_format_opts or {}, {
        lsp_format = "fallback",
      })

      -- Don't overwrite LazyVim's existing format-on-save setup if it has one.
      if opts.format_on_save == nil then
        opts.format_on_save = {
          timeout_ms = 800,
          lsp_format = "fallback",
        }
      end

      opts.notify_on_error = true
      opts.notify_no_formatters = false

      return opts
    end,

    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({
            async = true,
            lsp_format = "fallback",
          })
        end,
        mode = { "n", "v" },
        desc = "Format Buffer",
      },
    },
  },

  -- ==========================================================================
  -- nvim-lint — only enables linters actually installed on the machine
  -- ==========================================================================

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },

    config = function()
      local lint = require("lint")

      local function exists(command)
        return vim.fn.executable(command) == 1
      end

      local linters = {}

      local js_linter = nil

      if exists("eslint_d") then
        js_linter = "eslint_d"
      elseif exists("eslint") then
        js_linter = "eslint"
      end

      if js_linter then
        linters.javascript = { js_linter }
        linters.javascriptreact = { js_linter }
        linters.typescript = { js_linter }
        linters.typescriptreact = { js_linter }
      end

      if exists("ruff") then
        linters.python = { "ruff" }
      end

      if exists("shellcheck") then
        linters.sh = { "shellcheck" }
        linters.bash = { "shellcheck" }
        linters.zsh = { "shellcheck" }
      end

      if exists("selene") then
        linters.lua = { "selene" }
      elseif exists("luacheck") then
        linters.lua = { "luacheck" }
      end

      if exists("golangci-lint") then
        linters.go = { "golangcilint" }
      end

      if exists("zlint") then
        linters.zig = { "zlint" }
      end

      if exists("yamllint") then
        linters.yaml = { "yamllint" }
      end

      if exists("markdownlint-cli2") then
        linters.markdown = { "markdownlint-cli2" }
      elseif exists("markdownlint") then
        linters.markdown = { "markdownlint" }
      end

      lint.linters_by_ft = linters

      local group = vim.api.nvim_create_augroup("ArchNemesisLint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = group,

        callback = function()
          if vim.bo.buftype ~= "" then
            return
          end

          lint.try_lint(nil, {
            ignore_errors = true,
          })
        end,
      })
    end,

    keys = {
      {
        "<leader>cl",
        function()
          require("lint").try_lint(nil, {
            ignore_errors = true,
          })
        end,
        desc = "Lint Buffer",
      },
    },
  },

  -- ==========================================================================
  -- Treesitter Autotag
  -- ==========================================================================

  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },

    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
    },
  },

  -- ==========================================================================
  -- Persistence — project sessions
  -- ==========================================================================

  {
    "folke/persistence.nvim",
    event = "BufReadPre",

    opts = {
      need = 1,
      branch = true,
    },

    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore Project Session",
      },
      {
        "<leader>qS",
        function()
          require("persistence").select()
        end,
        desc = "Select Session",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore Last Session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Don't Save Session",
      },
    },
  },

  -- ==========================================================================
  -- Zen Mode
  -- ==========================================================================

  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",

    opts = {
      window = {
        backdrop = 0.90,
        width = 0.82,
        height = 1,

        options = {
          signcolumn = "yes",
          number = true,
          relativenumber = true,
          cursorline = true,
          foldcolumn = "0",
          list = false,
        },
      },

      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
        },

        gitsigns = {
          enabled = false,
        },

        todo = {
          enabled = false,
        },
      },
    },

    keys = {
      {
        "<leader>uz",
        "<cmd>ZenMode<cr>",
        desc = "Zen Mode",
      },
    },
  },

  -- ==========================================================================
  -- Harpoon 2
  -- ==========================================================================

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",

    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    config = function(_, opts)
      local harpoon = require("harpoon")
      harpoon:setup(opts or {})
    end,

    keys = {
      {
        "<leader>ha",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon Add File",
      },

      {
        "<leader>hh",
        function()
          local harpoon = require("harpoon")
          require("harpoon.ui").toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon Menu",
      },

      {
        "<leader>h1",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "Harpoon File 1",
      },

      {
        "<leader>h2",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "Harpoon File 2",
      },

      {
        "<leader>h3",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "Harpoon File 3",
      },

      {
        "<leader>h4",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "Harpoon File 4",
      },

      {
        "[H",
        function()
          require("harpoon"):list():prev({
            ui_nav_wrap = true,
          })
        end,
        desc = "Previous Harpoon File",
      },

      {
        "]H",
        function()
          require("harpoon"):list():next({
            ui_nav_wrap = true,
          })
        end,
        desc = "Next Harpoon File",
      },
    },
  },
}
