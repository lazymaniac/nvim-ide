-- Helper class definition

-- Code Extractor helper
local CodeExtractor = {}
CodeExtractor.__index = CodeExtractor

function CodeExtractor:new()
  local instance = setmetatable({}, CodeExtractor)
  return instance
end

CodeExtractor.lsp_timeout_ms = 10000
CodeExtractor.symbol_data = {}
CodeExtractor.filetype = ''

CodeExtractor.lsp_methods = {
  get_definition = vim.lsp.protocol.Methods.textDocument_definition,
  get_references = vim.lsp.protocol.Methods.textDocument_references,
  get_implementation = vim.lsp.protocol.Methods.textDocument_implementation,
}

CodeExtractor.DEFINITION_NODE_TYPES = {
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

function CodeExtractor:is_valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

function CodeExtractor:get_buffer_lines(bufnr, start_row, end_row)
  if not self:is_valid_buffer(bufnr) then
    return { status = 'error', data = 'Provided bufnr is invalid: ' .. bufnr }
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
  return { status = 'success', data = lines }
end

function CodeExtractor:get_node_data(bufnr, node)
  if not (node and bufnr) then
    return { status = 'error', data = 'Missing node or bufnr' }
  end

  local start_row, start_col, end_row, end_col = node:range()
  local lines_result = self:get_buffer_lines(bufnr, start_row, end_row + 1)

  if lines_result.status == 'error' then
    return lines_result
  end

  local lines = lines_result.data
  if not lines or #lines == 0 then
    return { status = 'error', data = 'Symbol text range is empty' }
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

function CodeExtractor:get_symbol_data(bufnr, row, col)
  if not self:is_valid_buffer(bufnr) then
    return { status = 'error', data = 'Invalid buffer id: ' .. bufnr }
  end

  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    return { status = 'error', data = "Can't initialize tree-sitter parser for buffer id: " .. bufnr }
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  local node = root:named_descendant_for_range(row, col, row, col)

  while node do
    if self.DEFINITION_NODE_TYPES[node:type()] then
      return self:get_node_data(bufnr, node)
    end
    node = node:parent()
  end

  return { status = 'error', data = 'No definition node found at position' }
end

function CodeExtractor:validate_lsp_params(bufnr, method)
  if not (bufnr and method) then
    return { status = 'error', data = 'Unable to call lsp. Missing bufnr or method. buffer=' .. bufnr .. ' method=' .. method }
  end
  return { status = 'success', data = 'Parameters valid' }
end

function CodeExtractor:execute_lsp_request(bufnr, method)
  local clients = vim.lsp.get_clients {
    bufnr = vim._resolve_bufnr(bufnr),
    method = method,
  }

  if #clients == 0 then
    return { status = 'error', data = 'No matching language servers with ' .. method .. ' capability' }
  end

  local lsp_results = {}
  local errors = {}

  for _, client in ipairs(clients) do
    local position_params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    local lsp_result, err = client:request_sync(method, position_params, self.lsp_timeout_ms, bufnr)
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
    return { status = 'error', data = table.concat(errors, '; ') }
  end

  return { status = 'success', data = lsp_results }
end

function CodeExtractor:process_single_range(uri, range)
  if not (uri and range) then
    return { status = 'error', data = 'Missing uri or range' }
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

function CodeExtractor:process_lsp_result(result)
  if result.range then
    return self:process_single_range(result.uri or result.targetUri, result.range)
  end

  if #result > 10 then
    return { status = 'error', data = 'Too many results for symbol. Ignoring' }
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

function CodeExtractor:call_lsp_method(bufnr, method)
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
    vim.notify(string.format('[LSP] Successfully processed %d result sets for method: %s', processed_result.data, method), vim.log.levels.DEBUG)
    return { status = 'success', data = 'Tool executed successfully' }
  else
    return { status = 'error', data = processed_result.data }
  end
end

function CodeExtractor:process_all_lsp_results(results_by_client, method)
  local processed_count = 0
  local errors = {}

  for client_name, lsp_results in pairs(results_by_client) do
    vim.notify(string.format('[LSP] Processing results from client: %s for method: %s', client_name, method), vim.log.levels.DEBUG)

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

function CodeExtractor:move_cursor_to_symbol(symbol)
  local bufs = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value('modifiable', { buf = bufnr }) then
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

      for i, line in ipairs(lines) do
        local col = line:find(symbol)

        if col then
          local win_ids = vim.fn.win_findbuf(bufnr)
          if #win_ids > 0 then
            vim.api.nvim_set_current_win(win_ids[1])
            vim.api.nvim_win_set_cursor(0, { i, col - 1 })
            return bufnr
          end
          break
        end
      end
    end
  end
  return -1
end

-- Helpers initialization
local code_extractor = CodeExtractor:new()

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
            'code_symbol_scout',
            'insert_edit_into_file',
          },
        },
        code_symbol_scout = {
          description = 'Use LSP methods to build the context around unknown or important code symbols.',
          opts = {
            user_approval = false,
          },
          callback = {
            name = 'code_symbol_scout',
            cmds = {
              function(_, args, _)
                local operation = args.operation
                local symbol = args.symbol

                local bufnr = code_extractor:move_cursor_to_symbol(symbol)

                if bufnr == -1 then
                  return { status = 'error', data = 'No symbol found. Check the spelling.' }
                end

                if not code_extractor.lsp_methods[operation] then
                  return { status = 'error', data = 'Unsupported LSP method: ' .. operation .. '. Supported lsp methods are: ' .. table.concat(code_extractor.lsp_methods, ', ') }
                end

                local result = code_extractor:call_lsp_method(bufnr, code_extractor.lsp_methods[operation])
                if result.status == 'success' then
                  code_extractor.filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
                  return { status = 'success', data = 'Tool executed successfully' }
                else
                  return { status = 'error', data = result.data }
                end
              end,
            },
            schema = {
              type = 'function',
              ['function'] = {
                name = 'code_symbol_scout',
                description = 'Use given LSP methods to build the context around unknown or important code symbols.',
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
                      description = 'The LSP operation to be performed by the Code Symbol Scout tool.',
                    },
                    symbol = {
                      type = 'string',
                      description = 'The unknown or important code symbol that the Code Symbol Scout tool will use to perform LSP operations.',
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
            system_prompt = [[## Code Symbol Scout Tool (`code_symbol_scout`) Guidelines

## MANDATORY USAGE
Use this tool AT THE START of a coding task to gather context about code symbols that are unknown to you or are important to solve the given problem before providing final answer. Don't overuse this tool.

## Purpose
Use LSP operations to build context around unknown code symbols to provide error proof solution without guessing.

## Important
- Wait for tool results before providing solutions
- Minimize explanations about the tool itself
- When looking for symbol, pass only the name of symbol without the object. E.g. use: `saveUsers` instead of `userRepository.saveUsers`
]],
            handlers = {
              on_exit = function(_, agent)
                code_extractor.symbol_data = {}
                code_extractor.filetype = ''
                vim.notify 'Tool executed successfully'
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

                for _, code_block in ipairs(code_extractor.symbol_data) do
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
                      code_extractor.filetype,
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
