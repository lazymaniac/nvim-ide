local plugins = require 'nv_ide.toolchain.plugins'
local lazypath = plugins.bootstrap_lazy()
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require('lazy').setup(plugins.lazy_options())
