--!nocheck
-- init.luau

if not game then
	warn("(lambda) unfortunately, lambda only supports roblox")
	return nil
end

-- promise library
local PromiseLibrary = require(script.Parent.Promise)

type Promise = PromiseLibrary.Promise
type LambdaModule = {
	init: (() -> ())?,
	start: (() -> ())?,
	priority: number?,
	[string]: any, -- other keys
}

return function(modules: { ModuleScript }): Promise
	-- check promise
	if not PromiseLibrary then
		warn("(lambda) did you properly write the path to your Promise library?")
		return nil
	end

	-- check args
	if not modules then
		warn("(lambda) did you properly pass your modules table?")
		return nil
	end

	local requiredModules: { LambdaModule } = {}

	-- require + collect
	for _, mod in ipairs(modules) do
		if mod:IsA("ModuleScript") then
			local ok, result = pcall(require, mod)
			if not ok then
				return PromiseLibrary.reject(("(lambda) failed to require %s -> %s"):format(mod.Name, result))
			end

			if type(result) == "table" then
				table.insert(requiredModules, result :: LambdaModule)
			end
		end
	end

	-- sort requiredModules by priority descending (default 1)
	-- 2 would require before 1
	-- to use priority ascending (1 before 2) switch the operator to <
	table.sort(requiredModules, function(a: LambdaModule, b: LambdaModule): boolean
		local pa: number? = rawget(a, "priority")
		local pb: number? = rawget(b, "priority")
		pa = (typeof(pa) == "number") and math.abs(pa :: number) or 1
		pb = (typeof(pb) == "number") and math.abs(pb :: number) or 1
		return pa > pb
	end)

	-- run all init
	local initPromises: { Promise } = {}
	for _: number, m: LambdaModule in ipairs(requiredModules) do
		if m.init and type(m.init) == "function" then
			local ok, res = pcall(m.init, m)
			if ok then
				if PromiseLibrary.is and PromiseLibrary.is(res) then
					table.insert(initPromises, res :: Promise)
				else
					table.insert(initPromises, PromiseLibrary.resolve(res))
				end
			else
				table.insert(initPromises, PromiseLibrary.reject(res))
			end
		end
	end

	-- wait for all inits, then run starts
	return PromiseLibrary.all(initPromises)
		:andThen(function()
			local startPromises: { Promise } = {}
			for _, m in ipairs(requiredModules) do
				if m.start then
					local ok, res = pcall(m.start, m)
					if ok then
						if PromiseLibrary.is and PromiseLibrary.is(res) then
							table.insert(startPromises, res :: Promise)
						else
							table.insert(startPromises, PromiseLibrary.resolve(res))
						end
					else
						table.insert(startPromises, PromiseLibrary.reject(res))
					end
				end
			end
			return PromiseLibrary.all(startPromises)
		end)
		:andThen(function()
			return PromiseLibrary.resolve(nil)
		end)
end
