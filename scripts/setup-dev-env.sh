#!/bin/bash
# ================================================
# Developer Environment Setup (Tmux + NvChad)
# ================================================

echo "🔧 Setting up Professional Developer Environment..."

# 1. Backup existing configs
echo "📦 Creating backups..."
cp ~/.config/hypr/tmux/tmux.conf ~/.config/hypr/tmux/tmux.conf.bak 2>/dev/null || true
cp ~/.config/hypr/nvim/lua/custom/plugins.lua ~/.config/hypr/nvim/lua/custom/plugins.lua.bak 2>/dev/null || true

# 2. Update tmux.conf
echo "🟢 Updating tmux config with persistence + Zettelkasten binds..."
cat > ~/.config/hypr/tmux/tmux.conf << 'TMUXCONF'
# ── Claude Cockpit — Professional Developer tmux ─────────────────
set -g mouse on
set -sg escape-time 10
set -g history-limit 50000
set -g renumber-windows on
set -g base-index 1
setw -g pane-base-index 1

# TPM Plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Persistence
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-processes 'lazygit nvim'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '10'

# Keybinds
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Zettelkasten Quick Access
bind n display-popup -E -w 85% -h 85% "nvim -c 'Telescope find_files' ~/notes"
bind N display-popup -E -w 80% -h 80% "nvim -c 'Telescope live_grep' ~/notes"

# Cockpit Popups
bind -n M-Space display-popup -E -w 70% -h 70% "~/.config/hypr/scripts/cc-mission.sh"
bind g display-popup -E -w 90% -h 90% -d "#{pane_current_path}" lazygit
bind r display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "~/.config/hypr/scripts/cc-review.sh"

bind R source-file ~/.config/tmux/tmux.conf \; display-message "tmux reloaded"

# Gruvbox Professional UI
set -g status-style "bg=#1d2021,fg=#a89984"
set -g status-left "#[bg=#fe8019,fg=#1d2021,bold] #S #[bg=#1d2021,fg=#fe8019]#[default] "
set -g status-right "#[fg=#83a598]#{pane_current_path} #[fg=#665c54]· #[fg=#fabd2f]%H:%M"
set -g pane-border-lines "heavy"
set -g pane-border-style "fg=#665c54"
set -g pane-active-border-style "fg=#fe8019,bold"
set -g pane-border-status top
set -g pane-border-format " #{?pane_active,#[fg=#fe8019#,bold],#[fg=#928374]}#{pane_title} #[default]#{?window_zoomed_flag,#[fg=#fabd2f][Z],}"

run '~/.tmux/plugins/tpm/tpm'
TMUXCONF

# 3. Setup NvChad plugins for Zettelkasten
echo "🟢 Adding Zettelkasten plugins to NvChad..."
mkdir -p ~/.config/hypr/nvim/lua/custom

cat > ~/.config/hypr/nvim/lua/custom/plugins.lua << 'NVIMCONF'
return {
  -- Existing plugins...

  -- Zettelkasten & Note Taking
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = {
        { name = "notes", path = "~/notes" },
      },
      daily_notes = { folder = "daily" },
    },
  },

  -- Optional: Better markdown support
  { "preservim/vim-markdown" },
}
NVIMCONF

# 4. Create Notes directory structure
echo "📁 Creating Zettelkasten folder structure..."
mkdir -p ~/notes/{inbox,facts,references,projects,hubs,daily}
cat > ~/notes/README.md << 'NOTE'
# My Second Brain - Zettelkasten

## Folders
- inbox/ → Quick capture
- facts/ → Small reusable facts & commands
- references/ → Links & resources
- hubs/ → Main topics (git, js, python...)
- daily/ → Daily notes
NOTE

echo "✅ Setup completed!"
echo "Now run these commands:"
echo "   tmux source ~/.config/tmux/tmux.conf"
echo "   tmux"
echo "   prefix + I   (inside tmux to install plugins)"
