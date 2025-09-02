![Lambda logo stolen from half-life 2 - sorry not sorry](https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/9637b521-3a6a-4454-9dd0-618c21eab620/dbyq9rd-8d256ee4-a4f7-4731-acb8-3b0f78cafbd8.png/v1/fill/w_1024,h_576,q_80,strp/half_life_lambda_by_dragonshadesx_dbyq9rd-fullview.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7ImhlaWdodCI6Ijw9NTc2IiwicGF0aCI6IlwvZlwvOTYzN2I1MjEtM2E2YS00NDU0LTlkZDAtNjE4YzIxZWFiNjIwXC9kYnlxOXJkLThkMjU2ZWU0LWE0ZjctNDczMS1hY2I4LTNiMGY3OGNhZmJkOC5wbmciLCJ3aWR0aCI6Ijw9MTAyNCJ9XV0sImF1ZCI6WyJ1cm46c2VydmljZTppbWFnZS5vcGVyYXRpb25zIl19.TWGY4OxLGqkSEEyX-pe5jtvnWte27BPQFQLB6bfom58)

## **λ Lambda**
A lightweight lifecycle orchestrator for ModuleScripts. Lambda ensures a consistent init → start boot process across a list of modules, with full Promise support for async initialisation.

> [!IMPORTANT]
> **This module depends on a working lua Promise implementation (such as [`evaera/roblox-lua-promise`](https://github.com/evaera/roblox-lua-promise) ) - make sure you’ve required it correctly inside the library**


---

## 🚀 Key Features

- 🔁 **Consistent Lifecycle**: Each module can optionally export `init()` and `start()` for structured loading.
- ⏳ **Async Safety**: Modules are `required` safely, and `start()` is deferred until `init()` of all modules is complete.
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
