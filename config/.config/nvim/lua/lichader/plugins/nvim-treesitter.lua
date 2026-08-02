return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    event = { "BufRead", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
        "windwp/nvim-ts-autotag",
        -- NOTE: this plugin is a bit buggy, not supporting C + f very well
        -- "nvim-treesitter/nvim-treesitter-context",
        { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
    config = function()
        local parsers = {
            "comment",
            "lua",
            "rust",
            "python",

            -- NOTE: JavaScript & Web
            "javascript",
            "typescript",
            "tsx",
            "json",
            "html",
            "css",

            -- NOTE: JDK
            "java",
            "kotlin",

            -- NOTE: golang
            "go",
            "gomod",
            "gowork",
            "gosum",
            "proto",

            -- NOTE: documentation
            "beancount",
            "markdown",
            "markdown_inline",

            -- NOTE: infrastructure
            "terraform",
            "hcl",
            "gitignore",
            "dockerfile",
            "toml",
            "yaml",
            "bash",

            -- NOTE: vim
            "c",
            "vim",
            "vimdoc",
        }

        local function install_parsers()
            -- main branch API: only parser management options are accepted here
            require("nvim-treesitter").install(parsers)
        end

        local function ensure_tree_sitter_cli()
            if vim.fn.executable("tree-sitter") == 1 then
                install_parsers()
                return
            end

            if vim.g.lichader_tree_sitter_cli_installing then
                return
            end

            if vim.fn.executable("cargo") == 0 then
                vim.notify("tree-sitter CLI not found and cargo is unavailable", vim.log.levels.WARN)
                return
            end

            vim.g.lichader_tree_sitter_cli_installing = true
            vim.notify("tree-sitter CLI not found, installing with cargo...", vim.log.levels.INFO)

            local output = {}
            vim.fn.jobstart({ "cargo", "install", "tree-sitter-cli" }, {
                stdout_buffered = true,
                stderr_buffered = true,
                on_stdout = function(_, data)
                    vim.list_extend(output, data or {})
                end,
                on_stderr = function(_, data)
                    vim.list_extend(output, data or {})
                end,
                on_exit = function(_, code)
                    vim.g.lichader_tree_sitter_cli_installing = false

                    vim.schedule(function()
                        if code == 0 then
                            if vim.fn.executable("tree-sitter") == 1 then
                                vim.notify("tree-sitter CLI installed successfully", vim.log.levels.INFO)
                                install_parsers()
                            else
                                vim.notify(
                                    "tree-sitter CLI installed, but is not on PATH. Check ~/.cargo/bin.",
                                    vim.log.levels.WARN
                                )
                            end
                        else
                            local message = "tree-sitter CLI install failed with exit code " .. code
                            local details = table.concat(
                                vim.tbl_filter(function(line)
                                    return line ~= ""
                                end, output),
                                "\n"
                            )

                            if details ~= "" then
                                message = message .. "\n" .. details
                            end

                            vim.notify(message, vim.log.levels.ERROR)
                        end
                    end)
                end,
            })
        end

        ensure_tree_sitter_cli()

        -- textobjects is now configured via its own plugin setup
        require("nvim-treesitter-textobjects").setup({
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
                    ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
                },
                selection_modes = {
                    ["@parameter.outer"] = "v",
                    ["@function.outer"] = "v",
                    ["@class.outer"] = "<c-v>",
                },
                include_surrounding_whitespace = true,
            },
        })

        require("nvim-ts-autotag").setup()

        -- main branch no longer auto-enables highlighting; do it per buffer
        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                if pcall(vim.treesitter.start) then
                    vim.wo.foldmethod = "expr"
                    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                end
            end,
        })
        -- handle buffers already loaded before this plugin finished lazy-loading
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
                pcall(vim.treesitter.start, buf)
            end
        end

        -- ft_to_lang was removed in nvim-treesitter main branch; telescope still uses it
        local ts_parsers = require("nvim-treesitter.parsers")
        if not ts_parsers.ft_to_lang then
            ts_parsers.ft_to_lang = function(ft)
                return vim.treesitter.language.get_lang(ft) or ft
            end
        end
    end,
}
