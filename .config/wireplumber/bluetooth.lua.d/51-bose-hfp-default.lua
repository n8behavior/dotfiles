-- Default Bose QC Ultra Headphones to HSP/HFP profile (mic enabled)
table.insert(bluez_monitor.rules, {
  matches = {
    {
      { "device.name", "matches", "bluez_card.BC_87_FA_29_05_F6" },
    },
  },
  apply_properties = {
    ["device.profile"] = "headset-head-unit",
    ["bluez5.auto-connect"] = "[ hfp_hf hsp_hs a2dp_sink ]",
  },
})
