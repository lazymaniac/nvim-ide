local function ai_buffer(ai_type)
  local start_line, end_line = 1, vim.fn.line '$'
  if ai_type == 'i' then
    -- Skip first and last blank lines for `i` textobject
    local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
    -- Do nothing for buffer with all blanks
    if first_nonblank == 0 or last_nonblank == 0 then
      return { from = { line = start_line, col = 1 } }
    end
    start_line, end_line = first_nonblank, last_nonblank
  end

  local to_col = math.max(vim.fn.getline(end_line):len(), 1)
  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end

return {

  -- [[ TEXT OBJECTS ]] ---------------------------------------------------------------

  -- [mini.ai] - Better text object_scope
  -- see: `:h mini.ai`
  -- link: https://github.com/echasnovski/mini.ai
  {
    'echasnovski/mini.ai',
    branch = 'main',
    -- keys = {
    --   { "a", mode = { "x", "o" } },
    --   { "i", mode = { "x", "o" } },
    -- },
    event = 'VeryLazy',
    opts = function()
      local ai = require 'mini.ai'
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter { -- code block
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          },
          f = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' }, -- function
          c = ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' }, -- class
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
          d = { '%f[%d]%d+' }, -- digits
          e = { -- Word with case
            { '%u[%l%d]+%f[^%l%d]', '%f[%S][%l%d]+%f[^%l%d]', '%f[%P][%l%d]+%f[^%l%d]', '^[%l%d]+%f[^%l%d]' },
            '^().*()$',
          },
          g = ai_buffer, -- buffer
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call { name_pattern = '[%w_]' }, -- without dot in function name
        },
      }
    end,
    config = function(_, opts)
      require('mini.ai').setup(opts)
      -- register all text objects with which-key
      require('util').on_load('which-key.nvim', function()
        local objects = {
          { ' ', desc = 'whitespace' },
          { '"', desc = '" string' },
          { "'", desc = "' string" },
          { '(', desc = '() block' },
          { ')', desc = '() block with ws' },
          { '<', desc = '<> block' },
          { '>', desc = '<> block with ws' },
          { '?', desc = 'user prompt' },
          { 'U', desc = 'use/call without dot' },
          { '[', desc = '[] block' },
          { ']', desc = '[] block with ws' },
          { '_', desc = 'underscore' },
          { '`', desc = '` string' },
          { 'a', desc = 'argument' },
          { 'b', desc = ')]} block' },
          { 'c', desc = 'class' },
          { 'd', desc = 'digit(s)' },
          { 'e', desc = 'CamelCase / snake_case' },
          { 'f', desc = 'function' },
          { 'g', desc = 'entire file' },
          { 'i', desc = 'indent' },
          { 'o', desc = 'block, conditional, loop' },
          { 'q', desc = 'quote `"\'' },
          { 't', desc = 'tag' },
          { 'u', desc = 'use/call' },
          { '{', desc = '{} block' },
          { '}', desc = '{} with ws' },
        }
        ---@type wk.Spec[]
        local ret = { mode = { 'o', 'x' } }
        ---@type table<string, string>
        local mappings = vim.tbl_extend('force', {}, {
          around = 'a',
          inside = 'i',
          around_next = 'an',
          inside_next = 'in',
          around_last = 'al',
          inside_last = 'il',
        }, opts.mappings or {})
        mappings.goto_left = nil
        mappings.goto_right = nil
        for name, prefix in pairs(mappings) do
          name = name:gsub('^around_', ''):gsub('^inside_', '')
          ret[#ret + 1] = { prefix, group = name }
          for _, obj in ipairs(objects) do
            local desc = obj.desc
            if prefix:sub(1, 1) == 'i' then
              desc = desc:gsub(' with ws', '')
            end
            ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
          end
        end
        require('which-key').add(ret, { notify = false })
      end)
    end,
  },

  -- [nvim-various-textobjs] - Extends buildin text objects
  -- see: `:h nvim-various-textobjs`
  -- link: https://github.com/chrisgrieser/nvim-various-textobjs
  --
  -- ---------------------------------------------------------------------------------------------------------------
  -- textobject               description             inner / outer          forward-seeking    default  filetypes
  --                                                                                            keymaps  (for
  --                                                                                                     default
  --                                                                                                     keymaps)
  -- ------------------------ ----------------------- ---------------------- ----------------- --------- -----------
  -- indentation              surrounding lines with  see overview from      -                  ii, ai,  all
  --                          same or higher          vim-indent-object                        aI, (iI)
  --                          indentation
  --
  -- restOfIndentation        lines down with same or -                      -                     R     all
  --                          higher indentation
  --
  -- greedyOuterIndentation   outer indentation,      outer includes a       -                   ag/ig   all
  --                          expanded to blank       blank, like ap/ip
  --                          lines; useful to get
  --                          functions with
  --                          annotations
  --
  -- subword                  like iw, but treating   outer includes         -                   iS/aS   all
  --                          -, _, and . as word     trailing _,-, or space
  --                          delimiters and only
  --                          part of camelCase
  --
  -- toNextClosingBracket     from cursor to next     -                      small                 C     all
  --                          closing ], ), or }
  --
  -- toNextQuotationMark      from cursor to next     -                      small                 Q     all
  --                          unescaped[1] ", ', or `
  --
  -- anyQuote                 between any             outer includes the     small               iq/aq   all
  --                          unescaped[2] ", ', or ` quotation marks
  --                          in a line
  --
  -- anyBracket               between any (), [], or  outer includes the     small               io/ao   all
  --                          {} in a line            brackets
  --
  -- restOfParagraph          like }, but linewise    -                      -                     r     all
  --
  -- multiCommentedLines      consecutive, fully      -                      big                  gc     all
  --                          commented lines
  --
  -- entireBuffer             entire buffer as one    -                      -                    gG     all
  --                          text object
  --
  -- nearEoL                  from cursor position to -                      -                     n     all
  --                          end of line, minus one
  --                          character
  --
  -- lineCharacterwise        current line, but       outer includes         -                   i_/a_   all
  --                          characterwise           indentation and
  --                                                  trailing spaces
  --
  -- column                   column down until       -                      -                    \|     all
  --                          indent or shorter line.
  --                          Accepts {count} for
  --                          multiple columns.
  --
  -- value                    value of key-value      outer includes         small               iv/av   all
  --                          pair, or right side of  trailing commas or
  --                          a assignment, excl.     semicolons
  --                          trailing comment (in a
  --                          line)
  --
  -- key                      key of key-value pair,  outer includes the =   small               ik/ak   all
  --                          or left side of a       or :
  --                          assignment
  --
  -- url                      works with http[s] or   -                      big                   L     all
  --                          any other protocol
  --
  -- number                   numbers, similar to     inner: only pure       small               in/an   all
  --                          <C-a>                   digits, outer: number
  --                                                  including minus sign
  --                                                  and decimal point
  --
  -- diagnostic               LSP diagnostic          -                      big                   !     all
  --                          (requires built-in LSP)
  --
  -- closedFold               closed fold             outer includes one     big                 iz/az   all
  --                                                  line after the last
  --                                                  folded line
  --
  -- chainMember              field with the full     outer includes the     small               im/am   all
  --                          call, like              leading . (or :)
  --                          .encode(param)
  --
  -- visibleInWindow          all lines visible in    -                      -                    gw     all
  --                          the current window
  --
  -- restOfWindow             from the cursorline to  -                      -                    gW     all
  --                          the last line in the
  --                          window
  --
  -- lastChange               Last                    -                      -                    g;     all
  --                          non-deletion-change,
  --                          yank, or paste.[3]
  --
  -- mdlink                   markdown link like      inner is only the link small               il/al   markdown,
  --                          [title](url)            title (between the [])                             toml
  --
  -- mdEmphasis               markdown text enclosed  inner is only the      small               ie/ae   markdown
  --                          by *, **, _, __, ~~, or emphasis content
  --                          ==
  --
  -- mdFencedCodeBlock        markdown fenced code    outer includes the     big                 iC/aC   markdown
  --                          (enclosed by three      enclosing backticks
  --                          backticks)
  --
  -- cssSelector              class in CSS like       outer includes         small               ic/ac   css, scss
  --                          .my-class               trailing comma and
  --                                                  space
  --
  -- htmlAttribute            attribute in html/xml   inner is only the      small               ix/ax   html, xml,
  --                          like href="foobar.com"  value inside the                                   css, scss,
  --                                                  quotes trailing comma                              vue
  --                                                  and space
  --
  -- doubleSquareBrackets     text enclosed by [[]]   outer includes the     small               iD/aD   lua, shell,
  --                                                  four square brackets                               neorg,
  --                                                                                                     markdown
  --
  -- shellPipe                segment until a pipe    outer includes the     small               iP/aP   bash, zsh,
  --                          character (\|)          pipe to the right                                  fish, sh
  --
  -- pyTripleQuotes           python strings          inner excludes the """ -                   iy/ay   python
  --                          surrounded by three     or '''
  --                          quotes (regular or
  --                          f-string)
  --
  -- notebookCell             cell delimited by       outer includes the     -                   iN/aN   all
  --                          double percent comment, bottom cell border
  --                          such as # %%
  -- ---------------------------------------------------------------------------------------------------------------
  {
    'chrisgrieser/nvim-various-textobjs',
    branch = 'main',
    event = 'VeryLazy',
  },
}
