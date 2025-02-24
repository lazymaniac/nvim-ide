local function move_cursor_to_word(word, bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  for i, line in ipairs(lines) do
    local col = line:find(word)
    if col then
      vim.api.nvim_win_call(vim.api.nvim_get_current_win(), function()
        vim.api.nvim_win_set_cursor(0, { i, col - 1 })
      end)
      break
    end
  end
end

local function get_node_text(bufnr, node)
  local start_row, start_col, end_row, end_col = node:range()
  if start_row == end_row then
    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
    return line:sub(start_col + 1, end_col)
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  lines[1] = lines[1]:sub(start_col + 1)
  lines[#lines] = lines[#lines]:sub(1, end_col)
  return table.concat(lines, '\n')
end

local function find_documentation_node(node)
  -- Get previous siblings to check for documentation
  local prev = node:prev_sibling()

  -- Documentation node types for different languages
  local doc_types = {
    -- Single line comments
    'comment',
    'line_comment', -- JavaScript, Java, C++
    'documentation_comment',

    -- Multi-line comments
    'block_comment', -- Many languages
    'comment_block', -- PHP
    'multiline_comment', -- Some parsers
    'doc_comment', -- Rust, Java
    'documentation', -- Some parsers

    -- Special documentation formats
    'string', -- Python docstrings
    'heredoc', -- PHP, Ruby, Shell
    'javadoc', -- Java specific
    'attribute', -- C# attributes
    'jsdoc', -- JavaScript JSDoc
    'phpdoc', -- PHP DocBlocks

    -- XML-style docs
    'xml_comment', -- XML, HTML
    'html_comment', -- HTML specific

    -- Language specific
    'roxygen_comment', -- R
    'luadoc', -- Lua
    'perldoc', -- Perl
  }

  if prev then
    local node_type = prev:type()
    for _, doc_type in ipairs(doc_types) do
      if node_type == doc_type then
        return prev
      end
    end
  end

  return nil
end

local function get_definition_with_docs(bufnr, row, col)
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse()[1]
  local root = tree:root()

  local node = root:named_descendant_for_range(row, col, row, col)
  while node do
    local type = node:type()
    if
      -- Common function/method definitions
      type == 'function_definition'
      or type == 'method_definition'
      or type == 'class_definition'
      or type == 'function_declaration'
      or type == 'method_declaration'
      or type == 'class_declaration'
      -- Rust
      or type == 'struct_item'
      or type == 'enum_item'
      or type == 'type_item'
      or type == 'trait_item'
      or type == 'impl_item'
      -- C/C++
      or type == 'struct_specifier'
      or type == 'enum_specifier'
      or type == 'type_definition'
      or type == 'namespace_definition'
      -- TypeScript/JavaScript
      or type == 'interface_declaration'
      or type == 'type_alias_declaration'
      or type == 'enum_declaration'
      -- Go
      or type == 'type_declaration'
      or type == 'type_spec'
      -- Python
      or type == 'class_definition'
      or type == 'decorated_definition'
      -- Java
      or type == 'interface_declaration'
      or type == 'annotation_type_declaration'
      -- Kotlin
      or type == 'class_declaration'
      or type == 'object_declaration'
      -- Swift
      or type == 'protocol_declaration'
      or type == 'struct_declaration'
      -- PHP
      or type == 'class_declaration'
      or type == 'interface_declaration'
      or type == 'trait_declaration'
    then
      local doc_node = find_documentation_node(node)
      if doc_node then
        -- Combine documentation and definition
        local doc_text = get_node_text(bufnr, doc_node)
        local def_text = get_node_text(bufnr, node)
        return doc_text .. '\n' .. def_text
      end
      return get_node_text(bufnr, node)
    end
    node = node:parent()
  end
  return nil
end

function call_lsp_method(bufnr, method)
  local timeout_ms = 10000
  local position_params = vim.lsp.util.make_position_params()

  position_params.context = {
    includeDeclaration = true,
  }

  local results_by_client, err = vim.lsp.buf_request_sync(bufnr, method, position_params, timeout_ms)
  if err then
    return {}
  end

  local extracted_code = {}
  for _, lsp_results in pairs(assert(results_by_client)) do
    local result = lsp_results.result or {}

    if result.range then
      local target_uri = result.uri or result.targetUri
      local target_bufnr = vim.uri_to_bufnr(target_uri)
      vim.fn.bufload(target_bufnr)
      local code = get_definition_with_docs(target_bufnr, result.range.start.line, result.range.start.character)
      if code then
        table.insert(extracted_code, code)
      end
    else
      for _, item in pairs(result) do
        local target_uri = item.uri or item.targetUri
        local target_bufnr = vim.uri_to_bufnr(target_uri)
        vim.fn.bufload(target_bufnr)
        local range = item.range or item.targetSelectionRange
        if range then
          local code = get_definition_with_docs(target_bufnr, range.start.line, range.start.character)
          if code then
            table.insert(extracted_code, code)
          end
        end
      end
    end
  end

  return extracted_code
end

local config = {
  adapters = {
    anthropic = function()
      return require('codecompanion.adapters').extend('anthropic', {
        env = {
          api_key = 'cmd:cat ~/.anthropic',
        },
        schema = {
          max_tokens = {
            default = 8192,
          },
          temperature = {
            default = 0.2,
          },
        },
      })
    end,
    openai = function()
      return require('codecompanion.adapters').extend('openai', {
        env = {
          api_key = 'cmd:cat ~/.gpt',
        },
        schema = {
          max_tokens = {
            default = 8192,
          },
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
      agents = {
        tools = {
          ['code_crawler'] = {
            description = 'Expose LSP actions to the Agent so it can travers the code like a programmer.',
            cmds = {
              function(self, action, input)
                move_cursor_to_word(action.symbol, action.buffer)
                local type = action._attr.type
                -- Dictionary mapping type values to LSP methods
                local lsp_methods = {
                  get_definition = 'textDocument/definition',
                  get_references = 'textDocument/references',
                  get_implementation = 'textDocument/implementation',
                  get_type_definition = 'textDocument/typeDefinition',
                  get_incoming_calls = 'callHierarchy/incomingCalls',
                  get_outgoing_calls = 'callHierarchy/outgoingCalls',
                }

                -- Check if the type has a corresponding LSP method
                if lsp_methods[type] then
                  local result = call_lsp_method(action.buffer, lsp_methods[type])
                  vim.notify(result)
                  return result
                end

                -- If no matching LSP method is found, return an empty table or handle it as needed
                return {}
              end,
            },
            schema = {
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_definition' },
                    buffer = 1,
                    symbol = '<![CDATA[UserRepository]]>',
                  },
                },
              },
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_references' },
                    buffer = 4,
                    symbol = '<![CDATA[saveUser]]>',
                  },
                },
              },
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_implementation' },
                    buffer = 10,
                    symbol = '<![CDATA[Comparable]]>',
                  },
                },
              },
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_type_definition' },
                    buffer = 14,
                    symbol = '<![CDATA[Map]]>',
                  },
                },
              },
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_incoming_calls' },
                    buffer = 14,
                    symbol = '<![CDATA[sortItems]]>',
                  },
                },
              },
              {
                tool = {
                  _attr = { name = 'code_crawler' },
                  action = {
                    _attr = { type = 'get_outgoing_calls' },
                    buffer = 17,
                    symbol = '<![CDATA[functionName]]>',
                  },
                },
              },
            },
            system_prompt = function(schema)
              return string.format(
                [[## Code Crawler Tool (`code_crawler`) - Enhanced Guidelines

### Purpose:
- Traversing the codebase like a regular programmer to find definition, references, implementation, type definition, incoming or outgoing calls of specific code symbols like classes or functions.

### When to Use:
- At the start of coding task.
- Use this tool to gather the necessary context to deeply understand the code fragment you are working on without any assumptions about meaning of some symbols.

### Execution Format:
- Always return an XML markdown code block.
- Always include the buffer number that the user has shared with you, in the `<buffer></buffer>` tag. If the user has not supplied this, prompt them for it.
- Each code operation must:
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

d) **Get Type Definition Action**:
```xml
%s
```

e) **Get Incoming Calls Action**:
```xml
%s
```

f) **Get Outgoing Calls Action**:
```xml
%s
```

### Key Considerations:
- **Safety and Accuracy:** Validate all symbols are exactly the same as in codes.
- **CDATA Usage:** Code is wrapped in CDATA blocks to protect special characters and prevent them from being misinterpreted by XML.

### Reminder:
- Minimize extra explanations and focus on returning correct XML blocks with properly wrapped CDATA sections.
- Always use the structure above for consistency.]],
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[1] } }, -- Get Definition
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[2] } }, -- Get References
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[3] } }, -- Get Implementation
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[4] } }, -- Get Type Definition
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[5] } }, -- Get Incoming Calls
                require('codecompanion.utils.xml.xml2lua').toXml { tools = { schema[6] } } --  Get Outgoing Calls
              )
            end,
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
        auto_submit = true,
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
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
    -- stylua: ignore
    keys = {
      { '<leader>ai', '<cmd>CodeCompanion<cr>', mode = { 'n', 'v' }, desc = 'Inline Prompt [zi]' },
      { '<leader>ac', '<cmd>CodeCompanionChat<cr>', mode = { 'n', 'v' }, desc = 'Open Chat [zz]' },
      { '<leader>at', '<cmd>CodeCompanionToggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle Chat [zt]' },
      { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [za]' },
      { '<leader>ap', '<cmd>CodeCompanionAdd<cr>', mode = { 'v' }, desc = 'Paste Selected to the Chat [zp]' },
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
