local lspconfig = require "configs.lspconfig"

return {
  {
    "mason-org/mason-lspconfig.nvim",
    cmd = { "LspInstall", "LspUninstall" },
    event = "VeryLazy",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = lspconfig.servers,
      automatic_enable = false,
    },
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    cmd = {
      "MasonToolsInstall",
      "MasonToolsInstallSync",
      "MasonToolsUpdate",
      "MasonToolsUpdateSync",
    },
    event = "VeryLazy",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "markdownlint-cli2",
        "prettierd",
        "shellcheck",
        "shfmt",
        "sql-formatter",
        "stylua",
      },
      run_on_start = true,
      start_delay = 1000,
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    cmd = { "TSInstall", "TSInstallSync", "TSUpdate" },
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "css",
        "dockerfile",
        "graphql",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "markdown",
        "markdown_inline",
        "prisma",
        "regex",
        "scss",
        "sql",
        "svelte",
        "tsx",
        "typescript",
        "vue",
        "yaml",
      })

      return opts
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "InsertLeave" },
    config = function()
      local lint = require "lint"

      lint.linters_by_ft = {
        bash = { "shellcheck" },
        markdown = { "markdownlint-cli2" },
        sh = { "shellcheck" },
        zsh = { "shellcheck" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("ide_lint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP references" },
    },
  },

  {
    "jay-babu/mason-nvim-dap.nvim",
    event = "VeryLazy",
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    opts = {
      ensure_installed = { "js" },
      handlers = {},
    },
  },

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
      },
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dr", function() require("dap").repl.open() end, desc = "Debug REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Debug terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Debug UI" },
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      dapui.setup()

      dap.listeners.before.attach.ide_dapui = function()
        dapui.open()
      end
      dap.listeners.before.launch.ide_dapui = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.ide_dapui = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.ide_dapui = function()
        dapui.close()
      end
    end,
  },
}
