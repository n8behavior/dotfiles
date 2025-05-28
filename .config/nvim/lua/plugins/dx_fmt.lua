local conform = require("conform")
local util    = require("conform.util")

conform.setup({
  -- turn on format-on-save (LazyVim may already do this globally)
  format_on_save = {
    enabled = true,
    -- you can list more types here if you like
    filetypes = { "rust" },
  },

  -- register a new “dioxus” formatter
  formatters = {
    dioxus = {
      -- point to whichever CLI you want (“dx” or absolute path)
      command = util.find_executable({ "dx" }, "dx"),
      -- run “dx fmt --stdin-file-path <filename>”
      args    = { "fmt", "--stdin-file-path", "$FILENAME" },
      stdin   = true,
    },
  },

  -- tell Conform which formatter(s) to run per filetype
  filetype = {
    -- use only “dioxus” for Rust
    rust = { "dioxus" },
    -- if you want both, you can chain them:
    -- rust = { "rustfmt", "dioxus" },
  },
})
