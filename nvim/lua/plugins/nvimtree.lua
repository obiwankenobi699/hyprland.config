return {
  {
    "nvim-tree/nvim-tree.lua",

    opts = function(_, opts)
      opts = opts or {}

      opts.view = vim.tbl_deep_extend("force", opts.view or {}, {
        adaptive_size = true,
      })

      opts.git = vim.tbl_deep_extend("force", opts.git or {}, {
        enable = true,
        ignore = false,
      })

      opts.filters = vim.tbl_deep_extend("force", opts.filters or {}, {
        dotfiles = false,
        git_clean = false,
      })

      opts.renderer = vim.tbl_deep_extend("force", opts.renderer or {}, {

        group_empty = true,
        highlight_git = true,
        highlight_opened_files = "name",

        indent_markers = {
          enable = true,
        },

        icons = {
          show = {
            git = true,
            folder = true,
            file = true,
            folder_arrow = true,
          },

          glyphs = {

            folder = {
              default = "",
              open = "",
              empty = "󰜌",
              empty_open = "󰜌",
              arrow_open = "",
              arrow_closed = "",
            },

            git = {
              unstaged = "M",
              staged = "A",
              renamed = "R",
              deleted = "D",
              untracked = "U",
              ignored = "I",
              unmerged = "!",
            },
          },
        },
      })

      return opts
    end,
  },
}
