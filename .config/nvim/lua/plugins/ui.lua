-- ============================================================================
-- 🧠 Personal Neovim overrides
-- ============================================================================

return {
  -- ==========================================================================
  -- 🎨 TokyoNight polish
  -- ==========================================================================

  {
    "folke/tokyonight.nvim",
    opts = function(_, opts)
      opts.transparent = true
      opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
        comments = { italic = true },
        keywords = { italic = false },
        sidebars = "transparent",
        floats = "dark",
      })

      return opts
    end,
  },

  -- ==========================================================================
  -- 🍿 Snacks.nvim
  -- ==========================================================================

  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local layouts = vim.deepcopy(require("snacks.picker.config.layouts"))
      layouts.default.layout.backdrop = false
      layouts.default.layout[1].border = "rounded"
      layouts.default.layout[2].border = "rounded"
      layouts.vertical.layout.border = "rounded"
      layouts.vertical.layout.min_width = 40
      layouts.vertical.layout.min_height = 12
      layouts.sidebar.layout.width = 34
      layouts.sidebar.layout.min_width = 28
      layouts.sidebar.layout[1].border = "rounded"
      local rice = {
        styles = {
          float = { border = "rounded", backdrop = false },
          notification = { border = "rounded", wo = { winblend = 0 } },
        },
        explorer = { enabled = true },
        picker = {
          enabled = true,
          layout = function()
            return vim.o.columns >= 120 and "default" or "vertical"
          end,
          sources = {
            explorer = {
              win = {
                list = { wo = { winhighlight = "Normal:Normal,NormalNC:NormalNC,CursorLine:CursorLine" } },
              },
            },
          },
        },
        notifier = { enabled = true, timeout = 2500, style = "compact", width = { min = 24, max = 60 } },
        terminal = { win = { position = "float", border = "rounded", width = 0.85, height = 0.75 } },
        lazygit = { win = { border = "rounded", width = 0.92, height = 0.9 } },
        indent = {
          enabled = true,
          indent = { char = "│" },
          scope = { enabled = true, only_current = true, char = "│" },
          animate = { enabled = false },
        },
        scroll = {
          enabled = true,
          animate = { duration = { step = 8, total = 100 } },
          animate_repeat = { duration = { step = 2, total = 25 } },
        },
        words = { enabled = true },
        bigfile = { enabled = true },
        quickfile = { enabled = true },
      }
      opts = vim.tbl_deep_extend("force", opts, rice)
      opts.picker.layouts = layouts
      return opts
    end,

    keys = {
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "Explorer",
      },

      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files",
      },

      {
        "<leader>fg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Find text",
      },

      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent files",
      },

      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },

      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "LazyGit",
      },

      {
        "<leader>`",
        function()
          Snacks.terminal()
        end,
        desc = "Terminal",
      },
    },
  },

  -- ==========================================================================
  -- 📊 Statusline
  -- ==========================================================================

  {
    "nvim-lualine/lualine.nvim",

    opts = function(_, opts)
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        theme = function()
          local function fg(group)
            local color = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
            return color and string.format("#%06x", color) or "NONE"
          end
          local theme = {}
          for mode, group in pairs({
            normal = "Function",
            insert = "String",
            visual = "Statement",
            replace = "DiagnosticError",
            command = "DiagnosticWarn",
            inactive = "Comment",
          }) do
            theme[mode] = {
              a = { fg = fg(group), bg = "NONE", gui = "bold" },
              b = { fg = fg("Comment"), bg = "NONE" },
              c = { fg = fg("Normal"), bg = "NONE" },
            }
          end
          return theme
        end,
      })
      opts.sections = {
        lualine_a = {
          {
            "mode",
            icon = "",
            fmt = function(mode)
              return mode:sub(1, 1)
            end,
          },
        },
        lualine_b = {
          { "branch", icon = "" },
          {
            "diff",
            source = function()
              local git = vim.b.gitsigns_status_dict
              if git then
                return { added = git.added, modified = git.changed, removed = git.removed }
              end
            end,
          },
        },
        lualine_c = {
          {
            "filename",
            path = 1,
            shorting_target = 60,
            symbols = { modified = " ●", readonly = " ", unnamed = "[New]" },
          },
          {
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = { error = " ", warn = " ", info = " ", hint = " " },
          },
        },
        lualine_x = {
          {
            function()
              local names = {}
              for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                names[#names + 1] = client.name
              end
              table.sort(names)
              return #names > 0 and (" " .. table.concat(names, ", ")) or ""
            end,
            cond = function()
              return vim.o.columns > 120
            end,
          },
          { "filetype", colored = false },
          {
            "encoding",
            cond = function()
              return vim.bo.fileencoding ~= "" and vim.bo.fileencoding ~= "utf-8"
            end,
          },
        },
        lualine_y = { "location" },
        lualine_z = { "progress" },
      }
      return opts
    end,
  },

  -- ==========================================================================
  -- 🌈 Better syntax highlighting
  -- ==========================================================================

  {
    "nvim-treesitter/nvim-treesitter",

    opts = {
      ensure_installed = {
        "bash",
        "css",
        "dockerfile",
        "git_config",
        "gitignore",
        "go",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "nu",
        "python",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
    },
  },

  -- ==========================================================================
  -- 💡 Better diagnostics
  -- ==========================================================================

  {
    "neovim/nvim-lspconfig",

    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,

        virtual_text = {
          spacing = 2,
          severity = { min = vim.diagnostic.severity.WARN },
          prefix = "●",
        },

        virtual_lines = false,
        float = { border = "rounded", source = "if_many", header = "", prefix = "" },
        severity_sort = true,

        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      },
    },
  },

  -- ==========================================================================
  -- 🧠 Completion
  -- ==========================================================================

  {
    "saghen/blink.cmp",

    opts = {
      completion = {
        menu = {
          border = "rounded",
          max_height = 8,
          draw = {
            gap = 1,
            columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
            components = { label = { width = { max = 40 } }, label_description = { width = { max = 20 } } },
          },
        },

        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
          window = {
            max_width = 64,
            max_height = 16,
            border = "rounded",
          },
        },
      },

      signature = {
        enabled = true,
        window = {
          border = "rounded",
        },
      },
    },
  },

  -- ==========================================================================
  -- 📁 Better icons
  -- ==========================================================================

  {
    "nvim-tree/nvim-web-devicons",
    enabled = false, -- LazyVim provides the compatible mini.icons adapter.

    opts = {
      default = true,
    },
  },

  -- ==========================================================================
  -- 🔧 Which-key
  -- ==========================================================================

  {
    "folke/which-key.nvim",

    opts = {
      preset = "modern",

      delay = 250,
      win = { border = "rounded", padding = { 1, 2 }, wo = { winblend = 0 } },

      icons = {
        mappings = true,
      },

      spec = {},
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        numbers = "none",
        separator_style = "thin",
        indicator = { style = "icon", icon = "▎" },
        modified_icon = "●",
        buffer_close_icon = "󰅖",
        show_close_icon = false,
        show_tab_indicators = false,
        always_show_bufferline = false,
        max_name_length = 24,
        tab_size = 20,
        offsets = {
          { filetype = "snacks_layout_box", text = "EXPLORER", text_align = "left", highlight = "Directory" },
        },
      },
    },
  },
  { "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } },
  {
    "folke/noice.nvim",
    opts = {
      -- Blink owns automatic signatures; Noice still handles manual LSP docs.
      lsp = { signature = { auto_open = { enabled = false } } },
      views = {
        hover = { border = { style = "rounded" }, size = { max_width = 72, max_height = 18 } },
        cmdline_popup = { border = { style = "rounded" } },
        popup = { border = { style = "rounded" } },
      },
    },
  },
}
