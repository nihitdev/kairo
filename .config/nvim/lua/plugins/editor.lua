-- ============================================================================
-- 🚀 Editor Enhancements
-- ============================================================================

return {

  -- ==========================================================================
  -- 🤖 Auto pairs
  -- ==========================================================================
  { "windwp/nvim-autopairs", enabled = false }, -- mini.pairs owns pairing

  -- ==========================================================================
  -- 🏷️ Highlight TODO / FIXME / HACK / NOTE
  -- ==========================================================================
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },

    opts = {
      signs = true,

      keywords = {
        FIX = {
          icon = " ",
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
        },

        TODO = {
          icon = " ",
        },

        HACK = {
          icon = " ",
        },

        WARN = {
          icon = " ",
          alt = { "WARNING", "XXX" },
        },

        PERF = {
          icon = " ",
          alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" },
        },

        NOTE = {
          icon = " ",
          alt = { "INFO" },
        },
      },
    },
  },

  -- ==========================================================================
  -- 🎨 Color previews
  --
  -- #7aa2f7  ← actually shows the color
  -- ==========================================================================
  {
    "NvChad/nvim-colorizer.lua",

    event = { "BufReadPre", "BufNewFile" },

    opts = {
      filetypes = {
        "css",
        "scss",
        "html",
        "javascript",
        "typescript",
        "lua",
        "toml",
      },

      user_default_options = {
        RGB = true,
        RRGGBB = true,
        names = true,
        RRGGBBAA = true,
        css = true,
        css_fn = true,

        mode = "background",
      },
    },
  },

  -- ==========================================================================
  -- 🧠 Better comments
  --
  -- gcc → comment line
  -- gc  → comment selection
  -- ==========================================================================
  {
    "numToStr/Comment.nvim",

    event = "VeryLazy",

    opts = {
      padding = true,
      sticky = true,
    },
  },

  -- ==========================================================================
  -- 🔥 Git signs
  -- ==========================================================================

  {
    "lewis6991/gitsigns.nvim",

    opts = {
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "┃" },
        untracked = { text = "┃" },
      },

      current_line_blame = false,
    },

    keys = {
      {
        "]h",
        function()
          require("gitsigns").nav_hunk("next")
        end,
        desc = "Next Git hunk",
      },

      {
        "[h",
        function()
          require("gitsigns").nav_hunk("prev")
        end,
        desc = "Previous Git hunk",
      },

      {
        "<leader>gp",
        function()
          require("gitsigns").preview_hunk()
        end,
        desc = "Preview Git hunk",
      },

      {
        "<leader>gb",
        function()
          require("gitsigns").blame_line()
        end,
        desc = "Git blame",
      },
    },
  },

  -- ==========================================================================
  -- 🧱 Better text objects / surroundings
  --
  -- ys + motion → surround
  -- ds"         → remove quotes
  -- cs"'        → "hello" → 'hello'
  -- ==========================================================================
  {
    "kylechui/nvim-surround",

    version = "*",
    event = "VeryLazy",

    config = function()
      require("nvim-surround").setup({})
    end,
  },

  -- ==========================================================================
  -- 🔎 Illuminate matching words
  --
  -- Put cursor on variable → other uses become highlighted.
  -- ==========================================================================
  { "RRethy/vim-illuminate", enabled = false }, -- Snacks.words owns references

  -- ==========================================================================
  -- 📐 Indentation guides
  -- ==========================================================================
  { "lukas-reineke/indent-blankline.nvim", enabled = false }, -- Snacks.indent owns guides

  -- ==========================================================================
  -- 🧭 Breadcrumbs
  --
  -- function > loop > block
  -- ==========================================================================
  {
    "SmiteshP/nvim-navic",

    lazy = true,

    opts = {
      separator = "  ",
      highlight = true,
      depth_limit = 5,
    },
  },
}
