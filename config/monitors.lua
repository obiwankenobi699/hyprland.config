return function()
    hl.monitor({
        output = "eDP-1",
        -- The AUO panel is 8-bit and does not advertise VRR. Prefer 60 Hz for
        -- lower power usage; 144.15 Hz remains available when needed.
        mode = "1920x1080@60",
        position = "0x0",
        scale = 1,
    })

    hl.monitor({
        output = "HDMI-A-1",
        -- HP Z24i: native 1920x1200 at 60 Hz, portrait, no advertised VRR.
        mode = "1920x1200@60",
        position = "1920x0",
        scale = 1,
        transform = 1,
    })

    -- Keep unlisted dock, projector, and replacement displays usable without
    -- overriding the tuned rules above.
    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto-right",
        scale = 1,
    })
end
