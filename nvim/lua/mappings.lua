require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
vim.api.nvim_create_user_command("HyprCheat", function()
  local buf = vim.api.nvim_create_buf(false, true)

  local width = math.floor(vim.o.columns * 0.75)
  local height = math.floor(vim.o.lines * 0.75)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
  })

  vim.cmd("read ~/.config/nvim/cheatsheet/hyprland.md")
  vim.cmd("setlocal buftype=nofile bufhidden=wipe nobuflisted")
  vim.cmd("setlocal nowrap nonumber norelativenumber")
end, {})

