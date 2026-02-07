-- Hyprland Cheatsheet UI (NvChad Style)
-- ~/.config/nvim/lua/cheatsheet/init.lua

local M = {}

-- Badge colors matching NvChad theme
local badge_colors = {
  apps      = { fg = "#1e1e2e", bg = "#f9e2af" }, -- yellow
  windows   = { fg = "#1e1e2e", bg = "#a6da95" }, -- green
  switch    = { fg = "#1e1e2e", bg = "#74c7ec" }, -- blue
  move      = { fg = "#1e1e2e", bg = "#f5c2e7" }, -- pink
  resize    = { fg = "#1e1e2e", bg = "#89b4fa" }, -- lavender
  workspace = { fg = "#1e1e2e", bg = "#fab387" }, -- peach
  system    = { fg = "#1e1e2e", bg = "#eba0ac" }, -- red
  capture   = { fg = "#1e1e2e", bg = "#94e2d5" }, -- teal
  notify    = { fg = "#1e1e2e", bg = "#cba6f7" }, -- mauve
  misc      = { fg = "#1e1e2e", bg = "#f38ba8" }, -- rosewater
}

-- Setup highlight groups
local function setup_highlights()
  -- Define all highlight groups
  vim.api.nvim_set_hl(0, "HC_Title", { fg = "#8aadf4", bold = true })
  vim.api.nvim_set_hl(0, "HC_Border", { fg = "#6e738d" })
  vim.api.nvim_set_hl(0, "HC_Key", { fg = "#f5c2e7", bold = true })
  vim.api.nvim_set_hl(0, "HC_Desc", { fg = "#cad3f5" })
  vim.api.nvim_set_hl(0, "HC_Header", { fg = "#8aadf4", bold = true })
  
  -- Badge highlights
  for name, colors in pairs(badge_colors) do
    vim.api.nvim_set_hl(0, "HC_Badge_" .. name, { 
      fg = colors.fg, 
      bg = colors.bg, 
      bold = true 
    })
  end
end

-- Pad string to length
local function pad(str, len)
  return str .. string.rep(" ", math.max(0, len - #str))
end

-- Center window calculation
local function center(w, h)
  return {
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
  }
end

-- Render a single card/section
local function render_card(lines, hls, start_row, start_col, width, section)
  local current_row = start_row
  
  -- Card borders
  local top = "┌" .. string.rep("─", width - 2) .. "┐"
  local bot = "└" .. string.rep("─", width - 2) .. "┘"
  local empty = "│" .. string.rep(" ", width - 2) .. "│"
  
  -- Top border
  table.insert(lines, string.rep(" ", start_col) .. top)
  current_row = current_row + 1
  
  -- Badge + Title
  local badge_text = " " .. (section.badge or "item") .. " "
  local title_text = section.title
  local padding = math.max(1, width - 4 - #badge_text - #title_text)
  local header_line = "│ " .. badge_text .. string.rep(" ", padding) .. title_text .. " │"
  
  table.insert(lines, string.rep(" ", start_col) .. header_line)
  
  -- Highlight the badge
  local badge_hl_name = "HC_Badge_" .. (section.badge or "misc")
  table.insert(hls, { 
    badge_hl_name, 
    current_row, 
    start_col + 2, 
    start_col + 2 + #badge_text 
  })
  
  -- Highlight the title
  table.insert(hls, { 
    "HC_Title", 
    current_row, 
    start_col + 2 + #badge_text + padding,
    start_col + 2 + #badge_text + padding + #title_text 
  })
  
  current_row = current_row + 1
  
  -- Separator
  local sep = "├" .. string.rep("─", width - 2) .. "┤"
  table.insert(lines, string.rep(" ", start_col) .. sep)
  current_row = current_row + 1
  
  -- Items
  for _, item in ipairs(section.items) do
    local key = item[1]
    local desc = item[2]
    local key_width = 16
    local desc_width = width - key_width - 6
    
    local item_line = "│ " .. 
                      pad(key, key_width) .. 
                      " " .. 
                      pad(desc, desc_width) .. 
                      " │"
    
    table.insert(lines, string.rep(" ", start_col) .. item_line)
    
    -- Highlight key
    table.insert(hls, { 
      "HC_Key", 
      current_row, 
      start_col + 2, 
      start_col + 2 + #key 
    })
    
    -- Highlight description
    table.insert(hls, { 
      "HC_Desc", 
      current_row, 
      start_col + 2 + key_width + 1, 
      start_col + 2 + key_width + 1 + #desc 
    })
    
    current_row = current_row + 1
  end
  
  -- Bottom border
  table.insert(lines, string.rep(" ", start_col) .. bot)
  current_row = current_row + 1
  
  return current_row - start_row
end

-- Main open function
function M.open()
  setup_highlights()
  
  -- Load sections
  local sections = require("cheatsheet.hyprland")
  
  -- Window dimensions
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  local pos = center(width, height)
  
  -- Create buffer and window
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = pos.row,
    col = pos.col,
    style = "minimal",
    border = "rounded",
    title = " CHEATSHEET ",
    title_pos = "center",
  })
  
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  
  local lines = {}
  local highlights = {}
  
  -- Two column layout
  local col_width = math.floor(width / 2) - 4
  local left_col = 2
  local right_col = col_width + 6
  
  local left_row = 1
  local right_row = 1
  
  -- Render sections in alternating columns
  for i, section in ipairs(sections) do
    if i % 2 == 1 then
      -- Left column
      local card_height = render_card(lines, highlights, left_row, left_col, col_width, section)
      left_row = left_row + card_height + 1
    else
      -- Right column
      local card_height = render_card(lines, highlights, right_row, right_col, col_width, section)
      right_row = right_row + card_height + 1
    end
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Apply highlights
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, -1, hl[1], hl[2], hl[3], hl[4])
  end
  
  -- Buffer settings
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "cheatsheet")
  vim.api.nvim_win_set_option(win, "cursorline", false)
  vim.api.nvim_win_set_option(win, "winblend", 5)
  
  -- Close keymaps
  for _, key in ipairs({ "q", "<Esc>", "<C-c>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { 
      buffer = buf, 
      silent = true,
      nowait = true,
    })
  end
end

-- Create command
vim.api.nvim_create_user_command("HyprCheat", M.open, {})

return M