-----------------------------------------------------------
-- Core globals
-----------------------------------------------------------
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "

-----------------------------------------------------------
-- Bootstrap lazy.nvim
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-----------------------------------------------------------
-- Load plugins (NvChad way)
-----------------------------------------------------------
local lazy_config = require("configs.lazy")

require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },
  { import = "plugins" },
}, lazy_config)

-----------------------------------------------------------
-- Load theme (Base46)
-----------------------------------------------------------
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

-----------------------------------------------------------
-- Core config files
-----------------------------------------------------------
require("options")
require("autocmds")

-----------------------------------------------------------
-- Custom modules (MUST load before mappings)
-----------------------------------------------------------
require("custom.hyprcheat")

-----------------------------------------------------------
-- Keymaps (loaded late, NvChad style)
-----------------------------------------------------------
vim.schedule(function()
  require("mappings")
end)
