return {

  -- [[ TEXT OBJECTS ]] ---------------------------------------------------------------

  -- [mini.ai] - Better text object_scope
  -- see: `:h mini.ai`
  {
    'echasnovski/mini.ai',
    -- keys = {
    --   { "a", mode = { "x", "o" } },
    --   { "i", mode = { "x", "o" } },
    -- },
    event = 'VeryLazy',
    opts = function()
      local ai = require 'mini.ai'
      local nn = require 'notebook-navigator'

      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          }, {}),
          f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
          c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }, {}),
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
          h = nn.miniai_spec,
        },
      }
    end,
    config = function(_, opts)
      require('mini.ai').setup(opts)
      -- register all text objects with which-key
      require('util').on_load('which-key.nvim', function()
        ---@type table<string, string|table>
        local i = {
          [' '] = 'Whitespace',
          ['"'] = 'Balanced "',
          ["'"] = "Balanced '",
          ['`'] = 'Balanced `',
          ['('] = 'Balanced (',
          [')'] = 'Balanced ) including white-space',
          ['>'] = 'Balanced > including white-space',
          ['<lt>'] = 'Balanced <',
          [']'] = 'Balanced ] including white-space',
          ['['] = 'Balanced [',
          ['}'] = 'Balanced } including white-space',
          ['{'] = 'Balanced {',
          ['?'] = 'User Prompt',
          _ = 'Underscore',
          a = 'Argument',
          b = 'Balanced ), ], }',
          c = 'Class',
          f = 'Function',
          o = 'Block, conditional, loop',
          q = 'Quote `, ", \'',
          t = 'Tag',
        }
        local a = vim.deepcopy(i)
        for k, v in pairs(a) do
          a[k] = v:gsub(' including.*', '')
        end

        local ic = vim.deepcopy(i)
        local ac = vim.deepcopy(a)
        for key, name in pairs { n = 'Next', l = 'Last' } do
          i[key] = vim.tbl_extend('force', { name = 'Inside ' .. name .. ' textobject' }, ic)
          a[key] = vim.tbl_extend('force', { name = 'Around ' .. name .. ' textobject' }, ac)
        end
        require('which-key').register {
          mode = { 'o', 'x' },
          i = i,
          a = a,
        }
      end)
    end,
  },

  -- [nvim-various-textobjs] - Extends buildin text objects
  -- see: `:h nvim-various-textobjs`
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

  -- restOfIndentation        lines down with same or -                      -                     R     all
  --                          higher indentation

  -- greedyOuterIndentation   outer indentation,      outer includes a       -                   ag/ig   all
  --                          expanded to blank       blank, like ap/ip
  --                          lines; useful to get
  --                          functions with
  --                          annotations

  -- subword                  like iw, but treating   outer includes         -                   iS/aS   all
  --                          -, _, and . as word     trailing _,-, or space
  --                          delimiters and only
  --                          part of camelCase

  -- toNextClosingBracket     from cursor to next     -                      small                 C     all
  --                          closing ], ), or }

  -- toNextQuotationMark      from cursor to next     -                      small                 Q     all
  --                          unescaped[1] ", ', or `

  -- anyQuote                 between any             outer includes the     small               iq/aq   all
  --                          unescaped[2] ", ', or ` quotation marks
  --                          in a line

  -- anyBracket               between any (), [], or  outer includes the     small               io/ao   all
  --                          {} in a line            brackets

  -- restOfParagraph          like }, but linewise    -                      -                     r     all

  -- multiCommentedLines      consecutive, fully      -                      big                  gc     all
  --                          commented lines

  -- entireBuffer             entire buffer as one    -                      -                    gG     all
  --                          text object

  -- nearEoL                  from cursor position to -                      -                     n     all
  --                          end of line, minus one
  --                          character

  -- lineCharacterwise        current line, but       outer includes         -                   i_/a_   all
  --                          characterwise           indentation and
  --                                                  trailing spaces

  -- column                   column down until       -                      -                    \|     all
  --                          indent or shorter line.
  --                          Accepts {count} for
  --                          multiple columns.

  -- value                    value of key-value      outer includes         small               iv/av   all
  --                          pair, or right side of  trailing commas or
  --                          a assignment, excl.     semicolons
  --                          trailing comment (in a
  --                          line)

  -- key                      key of key-value pair,  outer includes the =   small               ik/ak   all
  --                          or left side of a       or :
  --                          assignment

  -- url                      works with http[s] or   -                      big                   L     all
  --                          any other protocol

  -- number                   numbers, similar to     inner: only pure       small               in/an   all
  --                          <C-a>                   digits, outer: number
  --                                                  including minus sign
  --                                                  and decimal point

  -- diagnostic               LSP diagnostic          -                      big                   !     all
  --                          (requires built-in LSP)

  -- closedFold               closed fold             outer includes one     big                 iz/az   all
  --                                                  line after the last
  --                                                  folded line

  -- chainMember              field with the full     outer includes the     small               im/am   all
  --                          call, like              leading . (or :)
  --                          .encode(param)

  -- visibleInWindow          all lines visible in    -                      -                    gw     all
  --                          the current window

  -- restOfWindow             from the cursorline to  -                      -                    gW     all
  --                          the last line in the
  --                          window

  -- lastChange               Last                    -                      -                    g;     all
  --                          non-deletion-change,
  --                          yank, or paste.[3]

  -- mdlink                   markdown link like      inner is only the link small               il/al   markdown,
  --                          [title](url)            title (between the [])                             toml

  -- mdEmphasis               markdown text enclosed  inner is only the      small               ie/ae   markdown
  --                          by *, **, _, __, ~~, or emphasis content
  --                          ==

  -- mdFencedCodeBlock        markdown fenced code    outer includes the     big                 iC/aC   markdown
  --                          (enclosed by three      enclosing backticks
  --                          backticks)

  -- cssSelector              class in CSS like       outer includes         small               ic/ac   css, scss
  --                          .my-class               trailing comma and
  --                                                  space

  -- htmlAttribute            attribute in html/xml   inner is only the      small               ix/ax   html, xml,
  --                          like href="foobar.com"  value inside the                                   css, scss,
  --                                                  quotes trailing comma                              vue
  --                                                  and space

  -- doubleSquareBrackets     text enclosed by [[]]   outer includes the     small               iD/aD   lua, shell,
  --                                                  four square brackets                               neorg,
  --                                                                                                     markdown

  -- shellPipe                segment until a pipe    outer includes the     small               iP/aP   bash, zsh,
  --                          character (\|)          pipe to the right                                  fish, sh

  -- pyTripleQuotes           python strings          inner excludes the """ -                   iy/ay   python
  --                          surrounded by three     or '''
  --                          quotes (regular or
  --                          f-string)

  -- notebookCell             cell delimited by       outer includes the     -                   iN/aN   all
  --                          double percent comment, bottom cell border
  --                          such as # %%
  -- ---------------------------------------------------------------------------------------------------------------
  {
    'chrisgrieser/nvim-various-textobjs',
    lazy = false,
    opts = { useDefaultKeymaps = true },
  },
}
