return {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
        "neovim/nvim-lspconfig",
        "mason-org/mason-lspconfig.nvim",
        {
            "mason-org/mason.nvim",
            opts = {

                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            },
        },
    },
    opts = {
        -- list of servers for mason to install
        ensure_installed = {

            -- docker
            "dockerls",
            "docker_compose_language_service",
            "hadolint", --docker file linter

            -- web
            "html",
            "ts_ls",
            "cssls",
            "eslint_d",
            "fixjson",
            "json-lsp",
            "prettier",
            "tailwindcss-language-server",
            "jsonlint",

            "yamlls",

            -- golang
            "gofumpt",
            "golines",
            "goimports",
            "gopls",
            "golangci-lint",
            "pbls",
            "protolint",

            "markdownlint",
            -- python
            "pyright",
            "black",
            "flake8",

            -- lua
            "lua-language-server",
            "stylua",

            "write-good",
        },

        auto_update = true,
        run_on_start = true,
    },
}
