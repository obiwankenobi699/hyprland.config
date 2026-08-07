local prettier = { "prettierd", "prettier", stop_after_first = true }

return {
  formatters_by_ft = {
    bash = { "shfmt" },
    css = prettier,
    graphql = prettier,
    html = prettier,
    javascript = prettier,
    javascriptreact = prettier,
    json = prettier,
    jsonc = prettier,
    less = prettier,
    lua = { "stylua" },
    markdown = prettier,
    prisma = prettier,
    scss = prettier,
    sh = { "shfmt" },
    sql = { "sql_formatter" },
    svelte = prettier,
    typescript = prettier,
    typescriptreact = prettier,
    vue = prettier,
    yaml = prettier,
    zsh = { "shfmt" },
  },

  default_format_opts = {
    lsp_format = "fallback",
  },

  format_on_save = {
    timeout_ms = 1000,
    lsp_format = "fallback",
  },
}
