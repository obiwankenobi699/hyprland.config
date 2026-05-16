return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre',
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "andweeb/presence.nvim",
    lazy = false,
    config = function()
      require("presence").setup({
  show_time = false,
  workspace_text = "Neovim",
  editing_text = "Working • 127h+",
  main_image = nil,
  buttons = false,
})

    end,
  },
}
