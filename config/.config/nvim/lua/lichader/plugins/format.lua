return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        notify_on_error = false,
        format_on_save = {
            -- I recommend these options. See :help conform.format for details.
            lsp_fallback = true,
            timeout_ms = 500,
        },
        -- If this is set, Conform will run the formatter asynchronously after save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.
        format_after_save = {
            lsp_fallback = true,
        },
        formatters_by_ft = {
            lua = { "stylua" },
            go = { "gofumpt", "golines", "goimports" },
            -- NOTE: Javascript and Typescript
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
            svelte = { "prettier" },
            css = { "prettier" },
            html = { "prettier" },
            yaml = { "prettier" },
            json = { "fixjson" },
            graphql = { "prettier" },
            markdown = { "markdownlint" },
            python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
            -- NOTE: terraform
            terraform = { "terraform_fmt" },
            tf = { "terraform_fmt" },
            ["terraform-vars"] = { "terraform_fmt" },
        },
        formatters = {
            ruff_fix = {
                command = function(_, ctx)
                    return require("lichader.ruff").command(ctx.buf)
                end,
            },
            ruff_organize_imports = {
                command = function(_, ctx)
                    return require("lichader.ruff").command(ctx.buf)
                end,
            },
            ruff_format = {
                command = function(_, ctx)
                    return require("lichader.ruff").command(ctx.buf)
                end,
            },
        },
    },
}
