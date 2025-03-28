local TIMEOUT_MS = 10000
local content = ''
local filetype = ''
local codecompanion_winid = -1

local lsp_methods = {
  get_definition = 'textDocument/definition',
  get_references = 'textDocument/references',
  get_implementation = 'textDocument/implementation',
}

local DOC_NODE_TYPES = {
  -- Single line comments
  comment = true,
  line_comment = true,
  documentation_comment = true,
  -- Multi-line comments
  block_comment = true,
  comment_block = true,
  multiline_comment = true,
  doc_comment = true,
  documentation = true,
  -- Special documentation formats
  string = true, -- Python docstrings
  heredoc = true,
  javadoc = true,
  attribute = true,
  jsdoc = true,
  phpdoc = true,
  -- XML-style docs
  xml_comment = true,
  html_comment = true,
  -- Language specific
  roxygen_comment = true,
  luadoc = true,
  perldoc = true,
}

local DEFINITION_NODE_TYPES = {
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

-- Utility functions
local function is_valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function get_buffer_lines(bufnr, start_row, end_row)
  if not is_valid_buffer(bufnr) then
    return nil
  end
  return vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
end

local function get_node_text(bufnr, node)
  if not (node and bufnr) then
    return nil
  end

  local start_row, start_col, end_row, end_col = node:range()
  local lines = get_buffer_lines(bufnr, start_row, end_row + 1)

  if not lines then
    return nil
  end

  if start_row == end_row then
    return lines[1]:sub(start_col + 1, end_col)
  end

  lines[1] = lines[1]:sub(start_col + 1)
  lines[#lines] = lines[#lines]:sub(1, end_col)
  return table.concat(lines, '\n')
end

local function find_documentation_node(node)
  if not node then
    return nil
  end

  local prev = node:prev_sibling()
  if prev and DOC_NODE_TYPES[prev:type()] then
    return prev
  end

  return nil
end

local function get_definition_with_docs(bufnr, row, col)
  if not is_valid_buffer(bufnr) then
    return nil
  end

  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  local node = root:named_descendant_for_range(row, col, row, col)

  while node do
    if DEFINITION_NODE_TYPES[node:type()] then
      local doc_node = find_documentation_node(node)
      if doc_node then
        local doc_text = get_node_text(bufnr, doc_node)
        local def_text = get_node_text(bufnr, node)
        return doc_text and def_text and (doc_text .. '\n' .. def_text)
      end
      return get_node_text(bufnr, node)
    end
    node = node:parent()
  end

  return nil
end

local function call_lsp_method(bufnr, method)
  if not (bufnr and method) then
    return {}
  end

  local position_params = vim.lsp.util.make_position_params()
  position_params.context = { includeDeclaration = false }

  local results_by_client, err = vim.lsp.buf_request_sync(bufnr, method, position_params, TIMEOUT_MS)
  if err then
    vim.notify('LSP error: ' .. tostring(err), vim.log.levels.ERROR)
    return {}
  end

  local extracted_code = {}

  for _, lsp_results in pairs(results_by_client or {}) do
    local result = lsp_results.result or {}

    local function process_range(uri, range)
      if not (uri and range) then
        return
      end

      local target_bufnr = vim.uri_to_bufnr(uri)
      vim.fn.bufload(target_bufnr)

      local code = get_definition_with_docs(target_bufnr, range.start.line, range.start.character)
      if code then
        table.insert(extracted_code, code)
      end
    end

    if result.range then
      process_range(result.uri or result.targetUri, result.range)
    else
      for _, item in pairs(result) do
        process_range(item.uri or item.targetUri, item.range or item.targetSelectionRange)
      end
    end
  end

  return table.concat(extracted_code, '\n\n')
end

local function move_cursor_to_symbol(symbol)
  local bufs = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value('modifiable', { buf = bufnr }) then
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

      for i, line in ipairs(lines) do
        local col = line:find(symbol)

        if col then
          local win_ids = vim.fn.win_findbuf(bufnr)
          -- If there are windows displaying this buffer, set the cursor position
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

local config = {
  adapters = {
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
    ollama = function()
      return require('codecompanion.adapters').extend('ollama', {
        schema = {
          model = {
            default = 'llama3.3:latest',
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
  strategies = {
    -- CHAT STRATEGY ----------------------------------------------------------
    chat = {
      adapter = 'ollama',
      roles = {
        llm = function(adapter)
          return adapter.formatted_name
        end,
        user = 'Me',
      },
      tools = {
        ['code_crawler'] = {
          description = 'Expose LSP actions to the Agent so it can travers the code like a programmer.',
          opts = {
            user_approval = false,
          },
          callback = {
            name = 'code_crawler',
            cmds = {
              function(_, action, _)
                local symbol = action.symbol
                local type = action._attr.type

                local bufnr = move_cursor_to_symbol(symbol)

                if lsp_methods[type] then
                  content = call_lsp_method(bufnr, lsp_methods[type])
                  filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
                  return { status = 'success', msg = nil }
                end

                return { status = 'error', msg = 'No symbol found' }
              end,
            },
            schema = {
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_definition' },
                    symbol = '<![CDATA[UserRepository]]>',
                  },
                },
              },
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_references' },
                    symbol = '<![CDATA[saveUser]]>',
                  },
                },
              },
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_implementation' },
                    symbol = '<![CDATA[Comparable]]>',
                  },
                },
              },
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    {
                      _attr = { type = 'get_definition' },
                      symbol = '<![CDATA[UserService]]>',
                    },
                    {
                      _attr = { type = 'get_definition' },
                      symbol = '<![CDATA[refreshUser]]>',
                    },
                    {
                      _attr = { type = 'get_references' },
                      symbol = '<![CDATA[UserService]]>',
                    },
                  },
                },
              },
            },
            system_prompt = function(schema)
              return string.format(
                [[## Code Crawler Tool (`code_crawler`) - Enhanced Guidelines

### Purpose:
- Traversing the codebase like a regular programmer to find definition, references or implementation of specific code symbols like classes or functions.

### When to Use:
- !!!At the start of coding task!!!
- !!!Wait for the tool response and only then start to solve the task!!!
- Use this tool to gather the necessary context to deeply understand the code fragment you are working on without any assumptions about meaning of some symbols.
- Make sure the change will not break the code. Use get_references to find all usages of symbol if necessary.

### Execution Format:
- Always return an XML markdown code block.
- Each code symbol must:
  - Be wrapped in a CDATA section to preserve special characters (CDATA sections ensure that characters like '<' and '&' are not interpreted as XML markup).
  - Follow the XML schema exactly.

### XML Schema:
Each tool invocation should adhere to this structure:

a) **Get Definition Action:**
```xml
%s
```

b) **Get References Action:**
```xml
%s
```

c) **Get Implementation Action:**
```xml
%s
```

d) **Multiple Actions**: Combine actions in one response if needed:

```xml
%s
```

### Key Considerations:
- **Safety and Accuracy:** Validate all symbols are exactly the same as in code.
- **CDATA Usage:** Code is wrapped in CDATA blocks to protect special characters and prevent them from being misinterpreted by XML.
- **Patience:** Wait until tool provides all the data you requested before starting to solve the task.

### Reminder:
- Minimize extra explanations and focus on returning correct XML blocks with properly wrapped CDATA sections.
- Always use the structure above for consistency.]],
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[1] } }, -- Get Definition
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[2] } }, -- Get References
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[3] } }, -- Get Implementation
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[4] } }  -- Multiple actions
              )
            end,
            handlers = {
              setup = function(_)
                -- codecompanion_winid = vim.api.nvim_win_get_number(0)
              end,
              on_exit = function(_)
                -- vim.api.nvim_set_current_win(codecompanion_winid)
                codecompanion_winid = -1
              end,
            },
            output = {
              success = function(self, action, _)
                local type = action._attr.type
                local symbol = action.symbol

                self.chat:add_buf_message {
                  role = require('codecompanion.config').constants.USER_ROLE,
                  content = string.format(
                    [[The %s of symbol: `%s` is:

```%s
%s
```\n]],
                    string.upper(type),
                    symbol,
                    filetype,
                    content
                  ),
                }

                return self.chat:submit()
              end,
              error = function(self, action, err)
                return self.chat:add_buf_message {
                  role = require('codecompanion.config').constants.USER_ROLE,
                  content = string.format(
                    [[There was an error running the %s action:

```txt
%s
```]],
                    string.upper(action._attr.type),
                    err
                  ),
                }
              end,
              rejected = function(self, action)
                return self.chat:add_buf_message {
                  role = require('codecompanion.config').constants.USER_ROLE,
                  content = string.format('I rejected the %s action.\n\n', string.upper(action._attr.type)),
                }
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
              return vim.notify('Git files added to the chat.')
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
      adapter = 'ollama',
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
        stop_context_insertion = true,
        user_prompt = false,
      },
      prompts = {
        {
          role = 'system',
          content = function(context)
            return [[Act as a seasoned ]]
                .. context.filetype
                .. [[ programmer with over 20 years of commercial experience.
Your task is to suggest refactoring of a specified piece of code to improve its efficiency,
readability, and maintainability without altering its functionality. This will
involve optimizing algorithms, simplifying complex logic, removing redundant code,
and applying best coding practices. Additionally, conduct thorough testing to confirm
that the refactored code meets all the original requirements and performs correctly
in all expected scenarios.]]
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
      prompt = 'Prompt ',                   -- Prompt used for interactive LLM calls
      provider = 'default',                 -- default|telescope
      opts = {
        show_default_actions = true,        -- Show the default actions in the action palette?
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
      intro_message = 'Welcome to CodeCompanion ✨! Press ? for options',
      show_header_separator = false, -- Show header separators in the chat buffer? Set this to false if you're using an external markdown formatting plugin
      show_references = true, -- Show references (from slash commands and variables) in the chat buffer?
      separator = '─', -- The separator between the different messages in the chat buffer
      show_settings = false, -- Show LLM settings at the top of the chat buffer?
      show_token_count = true, -- Show the token count for each response?
      start_in_insert_mode = false, -- Open the chat buffer in insert mode?
    },
    diff = {
      enabled = true,
      close_chat_at = 240,  -- Close an open chat buffer if the total columns of your display are less than...
      layout = 'vertical',  -- vertical|horizontal split for default provider
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
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
    -- stylua: ignore
    keys = {
      { '<leader>ai', '<cmd>CodeCompanion<cr>',        mode = { 'n', 'v' }, desc = 'Inline Prompt [zi]' },
      { '<leader>ac', '<cmd>CodeCompanionChat<cr>',    mode = { 'n', 'v' }, desc = 'Open Chat [zz]' },
      { '<leader>at', '<cmd>CodeCompanionToggle<cr>',  mode = { 'n', 'v' }, desc = 'Toggle Chat [zt]' },
      { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [za]' },
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
}
