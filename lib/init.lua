--!nocheck
-- init.lua

-- types
export type Status = "Started" | "Resolved" | "Rejected" | "Cancelled"

export type Promise = {
	andThen: (
		self: Promise,
		successHandler: (...any) -> ...any,
		failureHandler: ((...any) -> ...any)?
	) -> Promise,
	andThenCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> any,
	andThenReturn: (self: Promise, ...any) -> Promise,

	await: (self: Promise) -> (boolean, ...any),
	awaitStatus: (self: Promise) -> (Status, ...any),

	cancel: (self: Promise) -> (),
	catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,
	expect: (self: Promise) -> ...any,

	finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,
	finallyCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	finallyReturn: (self: Promise, ...any) -> Promise,

	getStatus: (self: Promise) -> Status,
	now: (self: Promise, rejectionValue: any?) -> Promise,
	tap: (self: Promise, tapHandler: (...any) -> ...any) -> Promise,
	timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

export type TypedPromise<T...> = {
	andThen: (self: Promise, successHandler: (T...) -> ...any, failureHandler: ((...any) -> ...any)?) -> Promise,
	andThenCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	andThenReturn: (self: Promise, ...any) -> Promise,

	await: (self: Promise) -> (boolean, T...),
	awaitStatus: (self: Promise) -> (Status, T...),

	cancel: (self: Promise) -> (),
	catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,
	expect: (self: Promise) -> T...,

	finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,
	finallyCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	finallyReturn: (self: Promise, ...any) -> Promise,

	getStatus: (self: Promise) -> Status,
	now: (self: Promise, rejectionValue: any?) -> Promise,
	tap: (self: Promise, tapHandler: (T...) -> ...any) -> Promise,
	timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ...any) -> SignalConnection,
}

type SignalConnection = {
	Disconnect: (self: SignalConnection) -> ...any,
	[any]: any,
}

type PromiseLibrary = {
	Error: any,

	all: <T>(promises: { TypedPromise<T> }) -> TypedPromise<{ T }>,
	allSettled: <T>(promise: { TypedPromise<T> }) -> TypedPromise<{ Status }>,
	any: <T>(promise: { TypedPromise<T> }) -> TypedPromise<T>,
	defer: <TReturn...>(
		executor: (
			resolve: (TReturn...) -> (),
			reject: (...any) -> (),
			onCancel: (abortHandler: (() -> ())?) -> boolean
		) -> ()
	) -> TypedPromise<TReturn...>,
	delay: (seconds: number) -> TypedPromise<number>,
	each: <T, TReturn>(
		list: { T | TypedPromise<T> },
		predicate: (value: T, index: number) -> TReturn | TypedPromise<TReturn>
	) -> TypedPromise<{ TReturn }>,
	fold: <T, TReturn>(
		list: { T | TypedPromise<T> },
		reducer: (accumulator: TReturn, value: T, index: number) -> TReturn | TypedPromise<TReturn>
	) -> TypedPromise<TReturn>,
	fromEvent: <TReturn...>(
		event: Signal<TReturn...>,
		predicate: ((TReturn...) -> boolean)?
	) -> TypedPromise<TReturn...>,
	is: (object: any) -> boolean,
	new: <TReturn...>(
		executor: (
			resolve: (TReturn...) -> (),
			reject: (...any) -> (),
			onCancel: (abortHandler: (() -> ())?) -> boolean
		) -> ()
	) -> TypedPromise<TReturn...>,
	onUnhandledRejection: (callback: (promise: TypedPromise<any>, ...any) -> ()) -> () -> (),
	promisify: <TArgs..., TReturn...>(callback: (TArgs...) -> TReturn...) -> (TArgs...) -> TypedPromise<TReturn...>,
	race: <T>(promises: { TypedPromise<T> }) -> TypedPromise<T>,
	reject: (...any) -> TypedPromise<...any>,
	resolve: <TReturn...>(TReturn...) -> TypedPromise<TReturn...>,
	retry: <TArgs..., TReturn...>(
		callback: (TArgs...) -> TypedPromise<TReturn...>,
		times: number,
		TArgs...
	) -> TypedPromise<TReturn...>,
	retryWithDelay: <TArgs..., TReturn...>(
		callback: (TArgs...) -> TypedPromise<TReturn...>,
		times: number,
		seconds: number,
		TArgs...
	) -> TypedPromise<TReturn...>,
	some: <T>(promise: { TypedPromise<T> }, count: number) -> TypedPromise<{ T }>,
	try: <TArgs..., TReturn...>(callback: (TArgs...) -> TReturn..., TArgs...) -> TypedPromise<TReturn...>,
}

-- interface
type LambdaModule = {
	init: (() -> () | TypedPromise<any>)?,
	start: (() -> () | TypedPromise<any>)?,
	[string]: any,
}

-- promise library
local PromiseLibrary = require(script.Parent.Promise) :: PromiseLibrary -- path to your promise library

-- api
return function(modules: { ModuleScript }): TypedPromise<nil>
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
	table.sort(requiredModules, function(a: LambdaModule, b: LambdaModule): boolean
		local pa: number? = rawget(a, "priority")
		local pb: number? = rawget(b, "priority")
		pa = (typeof(pa) == "number") and math.abs(pa :: number) or 1
		pb = (typeof(pb) == "number") and math.abs(pb :: number) or 1
		return pa > pb
	end)

	-- run all init
	local initPromises: { TypedPromise<any> } = {}
	for _: number, m: LambdaModule in ipairs(requiredModules) do
		if m.init and type(m.init) == "function" then
			local ok, res = pcall(m.init, m)
			if ok then
				if PromiseLibrary.is and PromiseLibrary.is(res) then
					table.insert(initPromises, res :: TypedPromise<any>)
				else
					table.insert(initPromises, PromiseLibrary.resolve(res))
				end
			else
				table.insert(initPromises, PromiseLibrary.reject(res))
			end
		else
			print("not func")
		end
	end

	-- wait for all inits, then run starts
	return PromiseLibrary.all(initPromises)
		:andThen(function()
			local startPromises: { TypedPromise<any> } = {}
			for _, m in ipairs(requiredModules) do
				if m.start then
					local ok, res = pcall(m.start, m)
					if ok then
						if PromiseLibrary.is and PromiseLibrary.is(res) then
							table.insert(startPromises, res :: TypedPromise<any>)
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
