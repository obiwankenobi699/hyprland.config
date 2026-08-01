return {
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      auto_restore_enabled = true,
      auto_save_enabled = true,
      auto_session_suppress_dirs = {
        "~/",
        "~/Downloads",
      },
      session_lens = {
        load_on_setup = true,
      },
    },
  },
}
