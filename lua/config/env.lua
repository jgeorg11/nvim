local function load_env(path)
	local f = io.open(path, "r")
	if not f then
		return
	end
	for line in f:lines() do
		local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if key and value and vim.env[key] == nil then
			value = value:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
			vim.env[key] = value
		end
	end
	f:close()
end

load_env(vim.fn.stdpath("config") .. "/.env")
