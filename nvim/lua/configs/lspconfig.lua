local M = {}

M.servers = {
  "bashls",
  "cssls",
  "docker_compose_language_service",
  "dockerls",
  "emmet_language_server",
  "eslint",
  "graphql",
  "html",
  "jsonls",
  "lua_ls",
  "marksman",
  "postgres_lsp",
  "prismals",
  "svelte",
  "tailwindcss",
  "vtsls",
  "vue_ls",
  "yamlls",
}

function M.setup()
  require("nvchad.configs.lspconfig").defaults()

  local vue_language_server_path = vim.fn.stdpath("data")
    .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

  vim.lsp.config("vtsls", {
    settings = {
      vtsls = {
        tsserver = {
          globalPlugins = {
            {
              name = "@vue/typescript-plugin",
              location = vue_language_server_path,
              languages = { "vue" },
              configNamespace = "typescript",
            },
          },
        },
      },
    },
    filetypes = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
    },
  })

  vim.lsp.config("eslint", {
    settings = {
      workingDirectory = { mode = "auto" },
    },
  })

  vim.lsp.enable(M.servers)
end

return M
