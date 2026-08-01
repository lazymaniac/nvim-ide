local lockfile = assert(arg[1], 'lazy-lock.json path is required')
local name = assert(arg[2], 'plugin name is required')

local file = assert(io.open(lockfile, 'rb'))
local contents = file:read '*a'
file:close()

local decoded = vim.json.decode(contents)
local entry = assert(decoded[name], ('lazy-lock.json has no entry for %s'):format(name))
local branch = assert(entry.branch, ('lazy-lock.json has no branch for %s'):format(name))
local commit = assert(entry.commit, ('lazy-lock.json has no commit for %s'):format(name))
assert(#commit == 40 and commit:match '^%x+$', ('lazy-lock.json has an invalid commit for %s'):format(name))

io.stdout:write(('%s\t%s\n'):format(branch, commit))
