return function()
    -- NVIDIA is the primary renderer; Intel remains available for the internal panel.
    hl.env("AQ_DRM_DEVICES", "/dev/dri/card0:/dev/dri/card1")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")

    hl.env("XCURSOR_THEME", "Gruvbox-Retro")
    hl.env("XCURSOR_SIZE", "24")
    hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

    hl.env("GDK_BACKEND", "wayland,x11")
    hl.env("QT_QPA_PLATFORM", "wayland;xcb")
    hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
    hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
    hl.env("SDL_VIDEODRIVER", "wayland")
    hl.env("CLUTTER_BACKEND", "wayland")
    hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
    hl.env("MOZ_ENABLE_WAYLAND", "1")
    hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
end
