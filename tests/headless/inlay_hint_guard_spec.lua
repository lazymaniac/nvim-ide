local h = require('tests.headless.harness')

h.describe('inlay hint extmark guard', function()
  h.it('clamps a stale hint column without changing other extmarks', function()
    local api = vim.api
    local bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'x' })
    require('plugins.lsp.inlay_hint_guard').setup()

    local hint_ns = api.nvim_create_namespace('nvim.lsp.inlayhint')
    local other_ns = api.nvim_create_namespace('inlay_hint_guard_test')
    local hint_id = api.nvim_buf_set_extmark(bufnr, hint_ns, 0, 13, {
      virt_text = { { 'hint' } },
      virt_text_pos = 'inline',
    })
    h.deep_equal(api.nvim_buf_get_extmark_by_id(bufnr, hint_ns, hint_id, {}), { 0, 1 })
    h.raises("Invalid 'col': out of range", function()
      api.nvim_buf_set_extmark(bufnr, other_ns, 0, 13, {})
    end)

    api.nvim_buf_delete(bufnr, { force = true })
  end)

  h.it('lets Neovim redraw a hint after its line becomes shorter', function()
    local api = vim.api
    local bufnr = api.nvim_create_buf(false, true)
    api.nvim_set_current_buf(bufnr)
    api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'some long text' })

    local client = { id = 12345, offset_encoding = 'utf-16' }
    local original_get_client = vim.lsp.get_client_by_id
    local ok, err = xpcall(function()
      vim.lsp.get_client_by_id = function() return client end
      local inlay_hint = vim.lsp.inlay_hint
      inlay_hint.enable(true, { bufnr = bufnr })
      inlay_hint.on_inlayhint(nil, {
        { position = { line = 0, character = 13 }, label = 'hint' },
      }, {
        bufnr = bufnr,
        client_id = client.id,
        version = require('vim.lsp.util').buf_versions[bufnr],
      })
      api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'x' })
      api.nvim__redraw({ flush = true })
    end, debug.traceback)

    vim.lsp.get_client_by_id = original_get_client
    api.nvim_buf_delete(bufnr, { force = true })
    if not ok then error(err, 0) end
  end)
end)
