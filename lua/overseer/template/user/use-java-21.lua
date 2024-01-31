return {
  name = 'Use Java 21 Runtime',
  builder = function()
    return {
      cmd = { 'sdk' },
      args = { 'use', 'java', '21.0.1-tem' },
    }
  end,
  desc = 'sdk use java 21.0.1-tem',
}
