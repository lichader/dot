return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local lint = require("lint")
        lint.linters_by_ft = {
            markdown = { "markdownlint", "write_good" },
            go = { "golangcilint" },
            json = { "jsonlint" },
            javascript = { "eslint_d" },
            typescript = { "eslint_d" },
            javascriptreact = { "eslint_d" },
            typescriptreact = { "eslint_d" },
            terraform = { "tflint" },
            dockerfile = { "hadolint" },
            proto = { "protolint" },
            python = { "flake8" },
        }

        lint.linters.eslint_d.cmd = function()
            local local_eslint = vim.fn.findfile("node_modules/.bin/eslint", vim.fn.expand("%:p:h") .. ";")
            if local_eslint ~= "" then
                return vim.fn.fnamemodify(local_eslint, ":p")
            end
            return "eslint_d"
        end

        -- Create autocommand which carries out the actual linting
        -- on the specified events.
        local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = lint_augroup,
            callback = function()
                require("lint").try_lint()
            end,
        })
    end,
}
