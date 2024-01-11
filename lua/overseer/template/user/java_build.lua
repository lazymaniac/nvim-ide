return {
  name = "mvn clean install",
  builder = function()
    -- Full path to current file (see :help expand())
    return {
      cmd = { "mvn clean install" },
      args = { },
      components = { { "on_output_quickfix", open = true }, "default" },
    }
  end,
  condition = {
    filetype = { "java" },
  },
}
