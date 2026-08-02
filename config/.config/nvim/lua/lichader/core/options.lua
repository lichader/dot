local set = vim.opt

set.syntax = "on"
set.clipboard:append("unnamedplus")

set.backspace = "eol,start,indent"
set.list = true
set.wrap = true
set.autoread = true
set.undofile = true

set.termguicolors = true

set.encoding = "utf-8"
set.fileencodings = "utf-8,chinese"

set.history = 3000
set.autowrite = true

set.dictionary = "/usr/share/dict/words"

-- search
set.incsearch = true
set.hlsearch = true
set.ignorecase = true
set.smartcase = true

set.showmatch = true
set.matchtime = 2
set.updatetime = 300
set.timeoutlen = 500

set.completeopt = { "menuone", "noinsert", "noselect" }
set.pumheight = 10

set.tabstop = 4
set.softtabstop = 4
set.shiftwidth = 4
set.expandtab = true
set.smarttab = true
set.autoindent = true
set.smartindent = true

set.number = true
set.relativenumber = true
set.signcolumn = "yes"
set.scrolloff = 10
set.sidescrolloff = 8

set.splitbelow = true
set.splitright = true
set.splitkeep = "screen"

set.wildmenu = true
set.wildmode = "longest:full,full"
set.wildignorecase = true
set.wildignore = ".git,.hg,*.class,*.so,*.obj,*.swp,.DS_Store,*.out,"

set.grepprg = "rg --vimgrep"
set.grepformat = "%f:%l:%c:%m"
set.path:append("**")

set.cursorline = true
-- set.cursorcolumn = true

set.foldenable = false -- Disable folding on opening files
set.foldlevel = 99
set.foldcolumn = "1"

set.diffopt:append("vertical")
set.diffopt:append("algorithm:patience")
set.diffopt:append("linematch:60")

set.swapfile = false
