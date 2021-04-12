# NebulaFramework
A (very) early prototype of a feature-rich framework inspired by AGF.

# Installation
-- Roblox Studio --

The roblox file, located in the [latest release](https://github.com/ReturnedTrue/NebulaFramework/releases/latest) or on the [Roblox website](https://www.roblox.com/library/6654523308/NebulaFramework), will contain three folders named with where their contents must be placed.

-- Rojo --

In the zip file of the [latest release](https://github.com/ReturnedTrue/NebulaFramework/releases/latest), `src/` will contain three folders (Client, Server, Shared). Rename each to `NebulaInternal` and sync into Studio as follows:

Client - StarterPlayerScripts <br />
Server - ServerScriptService <br />
Shared - ReplicatedStorage <br />

# Usage
**NebulaClient is still under development, only server-side is supported at the moment.**

A folder named `Nebula` must be placed under either ServerScriptService, ServerStorage or ReplicatedStorage. Nebula will run any ModuleScript under these folders.
If a table is returned, it will inject the following properties into it:

LoadModule - a static method to load any module into Nebula, pass the ModuleScript and which table to add it to (ie. self.Server) <br />
Services - a table of all the Roblox services, ie. Services.Players <br />
Server - contains all the required modules from ServerScriptService/Nebula <br />
Storage - contains all the required modules from ServerStorage/Nebula <br />

Then, the table's optional Load method will be called. Once all Load methods are called on, the optional Start method will be called. This is the best place to use other modules.

However, if a function is returned then it will be called at the same time as when the Start methods are called with the injected properties passed as a table.

-- Attributes --

Modules with certain attributes can have different functionalities:

Nebula_Ignore (boolean) - the module will be ignored by Nebula if true, it won't be loaded even when LoadModule is called on it
Nebula_TopLevel (boolean) - the module will be added at top level (ie. self.Module or Nebula.Module), as well as under it's holding table. It is not recommended to use this on modules loaded with LoadModule, it will only be added to the top level of modules after it.

# Examples
ServerStorage/Nebula/EventDispatcher
```lua
local EventDispatcher = {};

function EventDispatcher:GetEvent()
	return self.Event;
end

function EventDispatcher:Load()
	self.Event = self.Services.Players.PlayerAdded;
end

return EventDispatcher;
```
<br />

ServerScriptService/Nebula/EventConnector
```lua
return function(Nebula)
	local event = Nebula.Storage.EventDispatcher:GetEvent();
	
	event:Connect(function(player)
		print(player, "has joined!");
	end)
end
```

OR

```lua
local EventConnector = {};

function EventConnector:Start()
	local event = self.Storage.EventDispatcher:GetEvent();
	
	event:Connect(function(player)
		print(player, "has joined!");
	end)
end

return EventConnector;
```