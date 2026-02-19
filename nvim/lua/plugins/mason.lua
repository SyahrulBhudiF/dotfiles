return {
  "williamboman/mason.nvim",
  cmd = { "Mason" },
  build = ":MasonUpdate",
  opts_extend = { "ensure_installed" },
  opts = {
    ensure_installed = {
      "html-lsp",
      "css-lsp",
      "basedpyright",
      "gopls",
      "ruff",
      "intelephense",
      "pint",
      "astro-language-server",
      "tailwindcss-language-server",
      "yaml-language-server",
      "lua-language-server",
      "json-lsp",
      "tinymist",

      -- Rust
      "rust-analyzer",
      "rustfmt",
      "codelldb",

      -- Python
      "ruff-lsp",
      "black",
      "isort",

      -- Common extras
      "bash-language-server",
      "dockerfile-language-server",
      "eslint-lsp",
      "prettier",
      "stylua",
      "taplo",
      "marksman"
    }
  },
}
