> [!IMPORTANT]
> **This module depends on a working lua Promise implementation (such as [`evaera/roblox-lua-promise`](https://github.com/evaera/roblox-lua-promise) ) - make sure you’ve required it correctly inside the library**

## **λ Lambda**
A lightweight lifecycle orchestrator for ModuleScripts. Lambda ensures a consistent init → start boot process across a list of modules, with full Promise support for async initialisation.

---

## 🚀 Key Features

- 🔁 **Consistent Lifecycle**: Each module can optionally export `init()` and `start()` for structured loading.
- ⏳ **Async Safety**: Modules are `required` safely, and `start()` is deferred until `init()` of all modules is complete.
- 🧩 **Dependency Coordination**: Use `waitFor("ModuleName")` to safely depend on another module’s completion.
- 📦 **Batch Loading**: Load all children or descendant `ModuleScripts` from a container.

---

## 📦 Installation
Place [`lambda/init.lua`](lib/init.lua) in your project, then call it once with your target ModuleScripts:

```lua
local Lambda = require(path.to.lambda)

local modules: {ModuleScript} = {
    script.Services.PlayerService,
    script.Services.InventoryService,
    script.Services.MatchService,
}

Lambda(modules)
    :andThen(function()
        print("✅ All services initialized and started")
    end)
    :catch(function(err)
        warn("❌ Lambda failed ->", err)
    end)
```

---

## 📜 Module Lifecycle

Each module you load can optionally export:

`init(): () | Promise`
- Called immediately after `require()`.
- Can return a Promise for async setup.
- All `init()` methods are awaited before any `start()`.

`start(): () | Promise`
- Called after every module’s `init()` has resolved.
- Can return a Promise for async startup.

> [!TIP]
> Both lifecycle functions are optional, you can mix and match.

### Example Module:

```lua
local PlayerService = {}

function PlayerService.init(): ()
    print("PlayerService initializing...")
    return Promise.delay(1):andThen(function()
        print("PlayerService init complete")
    end)
end

function PlayerService.start(): ()
    print("PlayerService starting...")
end

return PlayerService
```

---

## 🔍 Usage Notes
- If a module throws during require, Lambda rejects immediately.
- If `init()` or `start()` throws, it’s caught and wrapped in a rejected Promise.
- Non-Promise return values are automatically wrapped in `Promise.resolve()`.
