return {
  -- mini.pairs already owns pairing.
  {
    "windwp/nvim-autopairs",
    enabled = false,
  },

  -- Color previews: #7aa2f7
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
        RRGGBBAA = true,
        names = true,
        css = true,
        css_fn = true,
        mode = "background",
      },
    },
  },

  -- Surround editing:
  -- ysiw"  → surround word
  -- ds"     → delete quotes
  -- cs"'    → change quotes
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },

  -- Snacks.words owns reference highlighting.
  {
    "RRethy/vim-illuminate",
    enabled = false,
  },

  -- Snacks.indent owns indentation guides.
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = false,
  },

  -- Breadcrumb provider.
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
