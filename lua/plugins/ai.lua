-- Helper class definition

-- Code Extractor helper
local LSPTool = {}
LSPTool.__index = LSPTool

function LSPTool:new()
  local instance = setmetatable({}, LSPTool)
  return instance
end

LSPTool.LSP_TIMEOUT_MS = 10000
LSPTool.symbol_data = {}
LSPTool.filetype = ''

LSPTool.LSP_METHODS = {
  get_definition = vim.lsp.protocol.Methods.textDocument_definition,
  get_references = vim.lsp.protocol.Methods.textDocument_references,
  get_implementation = vim.lsp.protocol.Methods.textDocument_implementation,
}

LSPTool.TREESITTER_NODES = {
  -- Functions and Classes
  function_definition = true,
  method_definition = true,
  class_definition = true,
  function_declaration = true,
  method_declaration = true,
  constructor_declaration = true,
  class_declaration = true,
  -- Variables and Constants
  variable_declaration = true,
  const_declaration = true,
  let_declaration = true,
  field_declaration = true,
  property_declaration = true,
  const_item = true,
  -- Language-specific definitions
  struct_item = true,
  function_item = true,
  impl_item = true,
  enum_item = true,
  type_item = true,
  attribute_item = true,
  trait_item = true,
  static_item = true,
  interface_declaration = true,
  type_declaration = true,
  decorated_definition = true,
}

function LSPTool:is_valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

function LSPTool:get_buffer_lines(bufnr, start_row, end_row)
  return vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
end

function LSPTool:get_node_data(bufnr, node)
  local start_row, start_col, end_row, end_col = node:range()

  local lines = self:get_buffer_lines(bufnr, start_row, end_row + 1)
  if not lines or #lines == 0 then
    return { status = 'error', data = 'Symbol text range is empty. Tool could not extract symbol data.' }
  end

  local code_block
  if start_row == end_row then
    code_block = lines[1]:sub(start_col + 1, end_col)
  else
    lines[1] = lines[1]:sub(start_col + 1)
    lines[#lines] = lines[#lines]:sub(1, end_col)
    code_block = table.concat(lines, '\n')
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)

  return {
    status = 'success',
    data = {
      code_block = code_block,
      start_line = start_row + 1,
      end_line = end_row,
      filename = filename,
    },
  }
end

function LSPTool:get_symbol_data(bufnr, row, col)
  if not self:is_valid_buffer(bufnr) then
    return { status = 'error', data = 'Invalid buffer id: ' .. bufnr .. '. Internal tool error. Skip future tool calls.' }
  end

  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    return { status = 'error', data = "Can't initialize tree-sitter parser for buffer id: " .. bufnr .. '. Internal tool error. Skip future tool calls.' }
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  local node = root:named_descendant_for_range(row, col, row, col)

  while node do
    if self.TREESITTER_NODES[node:type()] then
      return self:get_node_data(bufnr, node)
    end
    node = node:parent()
  end

  return { status = 'error', data = 'No definition node found at position. Might be unsupported treesitter node type. Skip repeat of this tool calls.' }
end

function LSPTool:validate_lsp_params(bufnr, method)
  if not (bufnr and method) then
    return {
      status = 'error',
      data = 'Missing bufnr or method. buffer=' .. bufnr .. ' method=' .. method .. '. Tool could not find provided symbol in the code. Check spelling.',
    }
  end
  return { status = 'success', data = '' }
end

function LSPTool:execute_lsp_request(bufnr, method)
  local clients = vim.lsp.get_clients {
    bufnr = vim._resolve_bufnr(bufnr),
    method = method,
  }

  if #clients == 0 then
    return { status = 'error', data = 'No matching language servers with ' .. method .. ' capability. Internal tool error. Skip future tool calls.' }
  end

  local lsp_results = {}
  local errors = {}

  for _, client in ipairs(clients) do
    local position_params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    local lsp_result, err = client:request_sync(method, position_params, self.LSP_TIMEOUT_MS, bufnr)
    if err then
      table.insert(errors, 'LSP error: ' .. tostring(err))
    elseif lsp_result and lsp_result.result then
      if not lsp_results[client.name] then
        lsp_results[client.name] = {}
      end
      lsp_results[client.name] = lsp_result.result
    else
      table.insert(errors, 'No results for method: ' .. method .. ' for client: ' .. client.name)
    end
  end

  if next(lsp_results) == nil and #errors > 0 then
    return { status = 'error', data = table.concat(errors, '; ') .. '. Internal tool error. Skip future tool calls.' }
  end

  return { status = 'success', data = lsp_results }
end

function LSPTool:process_single_range(uri, range)
  if not (uri and range) then
    return { status = 'error', data = 'Missing uri or range. Internal tool error. Skip future tool calls.' }
  end

  local target_bufnr = vim.uri_to_bufnr(uri)
  vim.fn.bufload(target_bufnr)

  local symbol_result = self:get_symbol_data(target_bufnr, range.start.line, range.start.character)
  if symbol_result.status == 'success' then
    table.insert(self.symbol_data, symbol_result.data)
    return { status = 'success', data = 'Symbol processed' }
  else
    return { status = 'error', data = "Can't extract symbol data: " .. symbol_result.data }
  end
end

function LSPTool:process_lsp_result(result)
  if result.range then
    return self:process_single_range(result.uri or result.targetUri, result.range)
  end

  if #result > 20 then
    return { status = 'error', data = 'Too many results for symbol operation. Ignoring.' }
  end

  local errors = {}
  for _, item in pairs(result) do
    local process_result = self:process_single_range(item.uri or item.targetUri, item.range or item.targetSelectionRange)
    if process_result.status == 'error' then
      table.insert(errors, process_result.data)
    end
  end

  if #errors > 0 then
    return { status = 'error', data = table.concat(errors, '; ') }
  end

  return { status = 'success', data = 'Results processed' }
end

function LSPTool:call_lsp_method(bufnr, method)
  local validation = self:validate_lsp_params(bufnr, method)
  if validation.status == 'error' then
    return { status = 'error', data = validation.data }
  end

  local results = self:execute_lsp_request(bufnr, method)
  if results.status == 'error' then
    return { status = 'error', data = results.data }
  end

  local processed_result = self:process_all_lsp_results(results.data, method)
  if processed_result.status == 'success' then
    return { status = 'success', data = 'Tool executed successfully' }
  else
    return { status = 'error', data = processed_result.data }
  end
end

function LSPTool:process_all_lsp_results(results_by_client, method)
  local processed_count = 0
  local errors = {}

  for client_name, lsp_results in pairs(results_by_client) do
    local process_result = self:process_lsp_result(lsp_results or {})
    if process_result.status == 'success' then
      processed_count = processed_count + 1
    else
      table.insert(errors, 'Client ' .. client_name .. ': ' .. process_result.data)
    end
  end

  if #errors > 0 then
    return { status = 'error', data = table.concat(errors, '; ') }
  end

  return { status = 'success', data = processed_count }
end

function LSPTool:find_symbol_in_line(line, symbol)
  local pattern = '%f[%w_]' .. vim.pesc(symbol) .. '%f[^%w_]'
  local start_col = line:find(pattern)
  return start_col
end

function LSPTool:is_searchable_buffer(bufnr)
  return self:is_valid_buffer(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value('modifiable', { buf = bufnr })
end

function LSPTool:search_symbol_in_buffer(bufnr, symbol)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for line_num, line_content in ipairs(lines) do
    local col = self:find_symbol_in_line(line_content, symbol)
    if col then
      return { line = line_num, col = col - 1 }
    end
  end

  return nil
end

function LSPTool:set_cursor_position(bufnr, position)
  local window_ids = vim.fn.win_findbuf(bufnr)
  if #window_ids == 0 then
    return false
  end

  vim.api.nvim_set_current_win(window_ids[1])
  vim.api.nvim_win_set_cursor(0, { position.line, position.col })
  return true
end

function LSPTool:move_cursor_to_symbol(symbol)
  if not symbol or symbol == '' then
    return { status = 'error', data = 'Symbol parameter is required and cannot be empty. Provide a symbol to look for.' }
  end

  local buffer_list = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(buffer_list) do
    if self:is_searchable_buffer(bufnr) then
      local symbol_position = self:search_symbol_in_buffer(bufnr, symbol)

      if symbol_position then
        local cursor_set = self:set_cursor_position(bufnr, symbol_position)
        if cursor_set then
          return { status = 'success', data = bufnr }
        end
      end
    end
  end

  return { status = 'error', data = 'Symbol not found in any loaded buffer. Double check the spelling of the symbol.' }
end

-- Helpers initialization
local lsp_tool = LSPTool:new()

local config = {
  adapters = {
    opts = {
      show_defaults = false,
      show_model_choices = true,
    },
    anthropic = function()
      return require('codecompanion.adapters').extend('anthropic', {
        env = {
          api_key = 'cmd:cat ~/.anthropic',
        },
      })
    end,
    openai = function()
      return require('codecompanion.adapters').extend('openai', {
        env = {
          api_key = 'cmd:cat ~/.gpt',
        },
      })
    end,
    copilot = function()
      return require('codecompanion.adapters').extend('copilot', {
        schema = {
          model = {
            default = 'claude-sonnet-4',
          },
        },
      })
    end,
    ollama = function()
      return require('codecompanion.adapters').extend('ollama', {
        schema = {
          model = {
            default = 'llama4:latest',
          },
          num_ctx = {
            default = 8192,
          },
          temperature = {
            default = 0.9,
          },
        },
      })
    end,
  },
  extensions = {
    history = {
      enabled = true,
      opts = {
        keymap = 'gh',
        auto_save = false,
        expiration_days = 0,
        picker = 'default', --- ("telescope", "snacks", "fzf-lua", or "default")
        picker_keymaps = {
          rename = { n = 'r', i = '<M-r>' },
          delete = { n = 'd', i = '<M-d>' },
          duplicate = { n = '<C-y>', i = '<C-y>' },
        },
        auto_generate_title = false,
        continue_last_chat = false,
        delete_on_clearing_chat = false,
        dir_to_save = vim.fn.stdpath 'data' .. '/codecompanion-history',
        enable_logging = true,
      },
    },
    mcphub = {
      callback = 'mcphub.extensions.codecompanion',
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true,
      },
    },
    vectorcode = {
      opts = {
        add_tool = true,
      },
    },
  },
  strategies = {
    -- CHAT STRATEGY ----------------------------------------------------------
    chat = {
      adapter = 'anthropic',
      opts = {
        completion_provider = 'blink', -- blink|cmp|coc|default
      },
      roles = {
        llm = function(adapter)
          if adapter.parameters and adapter.parameters.model then
            return adapter.formatted_name .. ' (model=' .. adapter.parameters.model .. ')'
          else
            return adapter.formatted_name
          end
        end,
        user = 'Me',
      },
      tools = {
        opts = {
          default_tools = {
            'lsp_tool',
            -- 'insert_edit_into_file',
          },
        },
        lsp_tool = {
          description = 'Use LSP methods to build the context around unknown or important code symbols.',
          opts = {
            user_approval = false,
          },
          callback = {
            name = 'lsp_tool',
            cmds = {
              function(_, args, _)
                local operation = args.operation
                local symbol = args.symbol

                local cursor_result = lsp_tool:move_cursor_to_symbol(symbol)

                if cursor_result.status == 'error' then
                  return cursor_result
                end

                local bufnr = cursor_result.data

                if not lsp_tool.LSP_METHODS[operation] then
                  return {
                    status = 'error',
                    data = 'Unsupported LSP method: ' .. operation .. '. Supported lsp methods are: ' .. table.concat(lsp_tool.LSP_METHODS, ', '),
                  }
                end

                local result = lsp_tool:call_lsp_method(bufnr, lsp_tool.LSP_METHODS[operation])
                if result.status == 'success' then
                  lsp_tool.filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
                  return { status = 'success', data = 'Tool executed successfully' }
                else
                  return { status = 'error', data = result.data }
                end
              end,
            },
            schema = {
              type = 'function',
              ['function'] = {
                name = 'lsp_tool',
                description = 'Use available LSP methods to build the context around unknown or important code symbols.',
                parameters = {
                  type = 'object',
                  properties = {
                    operation = {
                      type = 'string',
                      enum = {
                        'get_definition',
                        'get_references',
                        'get_implementation',
                      },
                      description = 'The LSP operation to be performed by the LSP tool.',
                    },
                    symbol = {
                      type = 'string',
                      description = 'The unknown or important code symbol that the LSP tool will use to perform LSP operations.',
                    },
                  },
                  required = {
                    'operation',
                  },
                  additionalProperties = false,
                },
                strict = true,
              },
            },
            system_prompt = [[## LSP Tool (`lsp_tool`) Guidelines

## MANDATORY USAGE
Use this tool AT THE START of a coding task to gather context about code symbols that are unknown to you and are important to solve the given problem before providing final answer. This tool should help you solve the problem without guessing or assuming anything.

## Purpose
Use LSP operations to build context around unknown code symbols to provide error proof solution without guessing.

## Important
- Wait for tool results before providing solutions
- Minimize explanations about the tool itself
- When looking for symbol, pass only the name of symbol without the object. E.g. use: `saveUsers` instead of `userRepository.saveUsers`
]],
            handlers = {
              on_exit = function(_, agent)
                lsp_tool.symbol_data = {}
                lsp_tool.filetype = ''
                return agent.chat:submit()
              end,
            },
            output = {
              success = function(self, agent, _, _)
                local operation = self.args.operation
                if operation == 'edit' then
                  return agent.chat:add_tool_output(self, 'Code successfully modified', 'Code successfully modified')
                end

                local symbol = self.args.symbol
                local buf_message_content = ''

                for _, code_block in ipairs(lsp_tool.symbol_data) do
                  buf_message_content = buf_message_content
                    .. string.format(
                      [[
---
The %s of symbol: `%s`
Filename: %s
Start line: %s
End line: %s
Content:
```%s
%s
```
]],
                      string.upper(operation),
                      symbol,
                      code_block.filename,
                      code_block.start_line,
                      code_block.end_line,
                      lsp_tool.filetype,
                      code_block.code_block
                    )
                end

                return agent.chat:add_tool_output(self, buf_message_content, buf_message_content)
              end,
              error = function(self, agent, _, stderr, _)
                return agent.chat:add_tool_output(self, tostring(stderr[1]), tostring(stderr[1]))
              end,
            },
          },
        },
      },
      slash_commands = {
        ['git_files'] = {
          description = 'List git files',
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local handle = io.popen 'git ls-files'
            if handle ~= nil then
              local result = handle:read '*a'
              handle:close()
              chat:add_reference({ content = result }, 'git', '<git_files>')
              return vim.notify 'Git files added to the chat.'
            else
              return vim.notify('No git files available', vim.log.levels.INFO, { title = 'CodeCompanion' })
            end
          end,
          opts = {
            contains_code = false,
          },
        },
      },
    },
    -- INLINE STRATEGY --------------------------------------------------------
    inline = {
      adapter = 'anthropic',
    },
    -- CMD STRATEGY -----------------------------------------------------------
    cmd = {
      adapter = 'anthropic',
    },
  },
  prompt_library = {
    ['Suggest Refactoring'] = {
      strategy = 'chat',
      description = 'Suggest refactoring for provided piece of code.',
      opts = {
        modes = { 'v' },
        short_name = 'refactor',
        auto_submit = false,
        is_slash_command = false,
        is_default = true,
        stop_context_insertion = true,
        user_prompt = false,
      },
      prompts = {
        {
          role = 'system',
          content = function(_)
            return [[ Your task is to suggest refactoring of a specified piece of code to improve its efficiency, readability, and maintainability without altering its functionality. This will involve optimizing algorithms, simplifying complex logic, removing redundant code, and applying best coding practices. Check every aspect of the code, including variable names, function structures, and overall design patterns. Your goal is to provide a cleaner, more efficient version of the code that adheres to modern coding standards. ]]
          end,
        },
        {
          role = 'user',
          content = function(context)
            local text = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
            return 'I have the following code:\n\n```' .. context.filetype .. '\n' .. text .. '\n```\n\n'
          end,
          opts = {
            contains_code = true,
          },
        },
      },
    },
  },
  -- DISPLAY OPTIONS ----------------------------------------------------------
  display = {
    action_palette = {
      width = 95,
      height = 10,
      prompt = 'Prompt ', -- Prompt used for interactive LLM calls
      provider = 'default', -- default|telescope
      opts = {
        show_default_actions = true, -- Show the default actions in the action palette?
        show_default_prompt_library = true, -- Show the default prompt library in the action palette?
      },
    },
    chat = {
      window = {
        layout = 'vertical', -- float|vertical|horizontal|buffer
        border = 'rounded',
        height = 0.8,
        width = 0.40,
        relative = 'editor',
        opts = {
          breakindent = true,
          cursorcolumn = false,
          cursorline = false,
          foldcolumn = '0',
          linebreak = true,
          list = false,
          signcolumn = 'no',
          spell = false,
          wrap = true,
        },
      },
      intro_message = 'Press ? for help',
      show_header_separator = false, -- Show header separators in the chat buffer? Set this to false if you're using an external markdown formatting plugin
      show_references = true, -- Show references (from slash commands and variables) in the chat buffer?
      separator = '─', -- The separator between the different messages in the chat buffer
      show_settings = false, -- Show LLM settings at the top of the chat buffer?
      show_token_count = true, -- Show the token count for each response?
      start_in_insert_mode = true, -- Open the chat buffer in insert mode?
    },
    diff = {
      enabled = true,
      close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
      layout = 'vertical', -- vertical|horizontal split for default provider
      opts = { 'internal', 'filler', 'closeoff', 'algorithm:patience', 'followwrap', 'linematch:120' },
      provider = 'default', -- default|mini_diff
    },
    inline = {
      -- If the inline prompt creates a new buffer, how should we display this?
      layout = 'vertical', -- vertical|horizontal|buffer
    },
  },
  -- GENERAL OPTIONS ----------------------------------------------------------
  opts = {
    log_level = 'ERROR', -- TRACE|DEBUG|ERROR|INFO
    -- If this is false then any default prompt that is marked as containing code
    -- will not be sent to the LLM. Please note that whilst I have made every
    -- effort to ensure no code leakage, using this is at your own risk
    send_code = true,
  },
}

return {

  -- [[ AI ]] ---------------------------------------------------------------

  -- [codecompanion.nvim] - Integrates LLMs with neovim
  -- see: `:h codecompanion.txt`
  -- link: https://github.com/olimorris/codecompanion.nvim
  {
    'olimorris/codecompanion.nvim',
    event = 'VeryLazy',
    branch = 'main',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'ravitemer/codecompanion-history.nvim',
      {
        'ravitemer/mcphub.nvim',
        cmd = 'MCPHub',
        build = 'bundled_build.lua',
        config = {
          use_bundled_binary = true,
        },
      },
      {
        'Davidyz/VectorCode',
        version = '*',
        build = 'uv tool upgrade vectorcode',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
    },
    -- stylua: ignore
    keys = {
      { '<leader>ai', '<cmd>CodeCompanion<cr>',        mode = { 'n', 'v' }, desc = 'Inline Prompt [ai]' },
      { '<leader>ac', '<cmd>CodeCompanionChat<cr>',    mode = { 'n', 'v' }, desc = 'Open Chat [ac]' },
      { '<leader>at', '<cmd>CodeCompanionToggle<cr>',  mode = { 'n', 'v' }, desc = 'Toggle Chat [at]' },
      { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [aa]' },
      { '<leader>am', '<cmd>MCPHub<cr>', mode = { 'n' }, desc = 'MCP Hub [am]' },
    },
    config = function()
      -- mappings group
      local wk = require 'which-key'
      local defaults = {
        { '<leader>a', group = '+[AI]' },
      }
      wk.add(defaults)
      -- plugin setup
      require('codecompanion').setup(config)
    end,
  },

  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    enabled = true,
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        server_opts_overrides = {
          settings = {
            telemetry = {
              telemetryLevel = 'off',
            },
          },
        },
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = true,
        },
        filetypes = {
          yaml = false,
          markdown = false,
          help = false,
          gitcommit = false,
          gitrebase = false,
          hgcommit = false,
          svn = false,
          cvs = false,
          ['.'] = false,
        },
        copilot_model = '',
      }
    end,
  },
}
