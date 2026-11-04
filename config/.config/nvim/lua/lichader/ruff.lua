local M = {}

-- Use the same project executable for formatting and linting.
function M.command(bufnr)
    local filename = vim.api.nvim_buf_get_name(bufnr or 0)
    local directory = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()

    while directory do
        local command = vim.fs.joinpath(directory, ".venv", "bin", "ruff")
        if vim.fn.executable(command) == 1 then
            return command
        end

        local parent = vim.fs.dirname(directory)
        if parent == directory then
            break
        end
        directory = parent
    end

    return "ruff"
end

return M
