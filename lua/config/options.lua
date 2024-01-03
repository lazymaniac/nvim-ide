-- Set <space> as the leader key
-- See `:help mapleader`
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.g.autoformat = true

-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
vim.g.root_spec = { 'lsp', { '.git', 'lua' }, 'cwd' }

-- [[ Setting options ]]
-- See `:help vim.o`
vim.o.autowrite = true -- Enable auto write
vim.o.backup = false -- Creates a backup fles
vim.o.breakindent = true -- Align weapped with previous indent level
vim.o.breakindentopt = 'list:-1'
vim.o.clipboard = 'unnamedplus' -- Sync with system clipboard
vim.o.cmdheight = 1
vim.o.completeopt = 'menu,menuone,noselect'
vim.o.conceallevel = 2 -- Hide * markup for bold and italic, but no markers with substitution
vim.o.confirm = true -- Confirm to save changes before exiting modified buffer
vim.o.cursorline = true -- Enable highlighting of the current line
vim.o.expandtab = true -- Use spaces instead of tabs
vim.o.formatoptions = 'jcroqlnt' -- tcqj
vim.o.formatlistpat = '^\\s*[-~>]\\+\\s\\((.)\\s\\)\\?'
vim.o.grepformat = '%f:%l:%c:%m'
vim.o.grepprg = 'rg -u --vimgrep'
vim.o.hlsearch = true
vim.o.ignorecase = true -- Ignore case
vim.o.inccommand = 'nosplit' -- Preview incremental substitute
vim.o.laststatus = 3 -- Global statusline
vim.o.linebreak = true -- Break on words
vim.o.list = true -- Show some invisible characters (tabs...
vim.o.mouse = 'a' -- Enable mouse mode
vim.o.number = true -- Print line number
vim.o.pumblend = 10 -- Popup blend
vim.o.pumheight = 10 -- Maximum number of entries in a popup
vim.o.relativenumber = true -- Relative line numbers
vim.o.scrolloff = 8 -- Minimal number of screen lines to keep above and below cursor
vim.o.sessionoptions = 'buffers,curdir,tabpages,winsize,help,globals,skiprtp'
vim.o.shiftround = true -- Round indent
vim.o.shiftwidth = 2 -- Size of an indent
vim.o.shortmess = 'filnxtToOFWIcC'
vim.o.showmode = true -- Dont show mode since we have a statusline
vim.o.sidescrolloff = 8 -- Minimal number of screen lines to keep left and right of the cursor
vim.o.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
vim.o.smartcase = true -- Don't ignore case with capitals
vim.o.smartindent = true -- Insert indents automatically
vim.o.spelllang = 'en'
vim.o.splitbelow = true -- Put new windows below current
vim.o.splitkeep = 'screen'
vim.o.splitright = true -- Put new windows right of current
vim.o.tabstop = 2 -- Number of spaces tabs count for
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.termguicolors = true -- Terminal true color support
vim.o.timeout = true -- required by which-key
vim.o.timeoutlen = 500 -- Time to wait for a mapped sequence to complete (in ms)
vim.o.title = true -- Set the title of window to the value of the titlestrinf
vim.o.titlestring = '%<%F%=%l/%L - nvim'
vim.o.undofile = true -- Enable persistent undo
vim.o.undolevels = 10000
vim.o.updatetime = 250 -- Faster completion
vim.o.virtualedit = 'block' -- Allow cursor to move where there is no text in visual block mode
vim.o.wildmode = 'longest:full,full' -- Command-line completion mode
vim.o.winminwidth = 5 -- Minimum window width
vim.o.wrap = true -- Enable line wrap by default
vim.o.writebackup = false -- If a file is being edited by another program, it is not allowed to be edited
vim.o.fillchars = 'foldopen:,foldclose:,fold:⸱,foldsep: ,diff:/,eob: '

if vim.fn.has 'nvim-0.10' == 1 then
  vim.o.smoothscroll = true
end

-- Folding
vim.opt.foldlevel = 99
vim.opt.foldtext = "v:lua.require'util'.ui.foldtext()"

if vim.fn.has 'nvim-0.9.0' == 1 then
  vim.opt.statuscolumn = [[%!v:lua.require'util'.ui.statuscolumn()]]
end

-- HACK: causes freezes on <= 0.9, so only enable on >= 0.10 for now
if vim.fn.has 'nvim-0.10' == 1 then
  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = "v:lua.require'util'.ui.foldexpr()"
else
  vim.opt.foldmethod = 'indent'
end

vim.o.formatexpr = "v:lua.require'util'.format.formatexpr()"

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
