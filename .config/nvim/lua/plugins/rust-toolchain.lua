return {
  "mrcjkb/rustaceanvim",
  opts = function(_, opts)
    -- Merge with existing opts
    opts.server = opts.server or {}
    
    -- Let rustaceanvim handle the rust-analyzer command
    -- It will automatically use rustup to detect the correct toolchain
    -- based on rust-toolchain or rust-toolchain.toml files
    
    -- Configure rust-analyzer settings
    opts.server.settings = vim.tbl_deep_extend("force", opts.server.settings or {}, {
      ["rust-analyzer"] = {
        -- Use the project's rustc (via rustup)
        rustc = {
          source = "discover",
        },
        -- Use cargo from the project's toolchain
        cargo = {
          buildScripts = {
            enable = true,
          },
        },
        -- Check on save using the project's toolchain
        checkOnSave = {
          command = "clippy",
        },
      },
    })
    
    -- Set up automatic restart when toolchain files change
    local original_on_attach = opts.server.on_attach
    opts.server.on_attach = function(client, bufnr)
      -- Call the original on_attach if it exists
      if original_on_attach then
        original_on_attach(client, bufnr)
      end
      
      -- Watch for changes to toolchain files
      local group = vim.api.nvim_create_augroup("RustToolchainReload", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = group,
        pattern = { "rust-toolchain", "rust-toolchain.toml" },
        callback = function()
          vim.notify("Rust toolchain file changed. Restart LSP with :LspRestart", vim.log.levels.INFO)
        end,
      })
    end
    
    return opts
  end,
}