# NebulaFramework
An early in development feature-rich framework which makes communication between scripts seamless. 

Inspired by AGF.

# Installation
-- Roblox Studio --

The roblox file, located in the [latest release](https://github.com/ReturnedTrue/NebulaFramework/releases/latest) or on the [Roblox website](https://www.roblox.com/library/6654523308/NebulaFramework), will contain three folders named with where their contents must be placed.

-- Rojo --

In the zip file of the [latest release](https://github.com/ReturnedTrue/NebulaFramework/releases/latest), `src/` will contain three folders (Client, Server, Shared). Rename each to `NebulaInternal` and sync into Studio as follows:

Client - StarterPlayerScripts <br />
Server - ServerScriptService <br />
Shared - ReplicatedStorage <br />

# Usage
**NebulaFramework currently in early-development, please use with caution**

A folder named `Nebula` must be placed under certain services depending on the context. Nebula will run any ModuleScript under these folders.

On the server: ServerScriptService, ServerStorage or ReplicatedStorage. <br />
On the client: StarterPlayerScripts, ReplicatedFirst or ReplicatedStorage. <br />

-- Table injected properties -- <br />
If a table is returned by a module, attribute `Nebula_NormalModule` is false/nil (see below), then these properties are injected.

Both contexts:

`AddModule` - a static method to add any module into Nebula, pass the ModuleScript and which table to add it to (ie. self.Server) <br />
`Services` - a table of all the Roblox services, ie. Services.Players <br />
`Replicated` - contains all the modules from ReplicatedStorage/Nebula (these modules won't be injected nor ran in Nebula either) <br />

Server:

`Server` - contains all the modules from ServerScriptService/Nebula <br />
`Storage` - contains all the modules from ServerStorage/Nebula <br />

Client:

`Server` - contains all the modules from ServerScriptService/Nebula but only of the methods which are prefixed with `Client_` (the prefix is removed) <br />
`Client` - contains all the modules from StarterPlayerScripts/Nebula <br />
`ClientStorage` - contains all the modules from ReplicatedFirst/Nebula <br />

Then, the table's optional Load method will be called. Once all Load methods are called on, the optional Start method will be called. This is the best place to use other modules. Afterwards, the table's optional Update method will be called on either Heartbeat (server) or RenderStepped (client).

However, if a function is returned then it will be called at the same time as when the Start methods are called with the injected properties passed as a table.

-- Attributes --

Modules with certain attributes can have different functionalities:

`Nebula_Ignore` (**boolean**) - the module will be ignored by Nebula if true, it won't be loaded even when LoadModule is called on it <br />
`Nebula_NormalModule` (**boolean**) - the module won't be injected nor will any methods used by nebula be called <br />
`Nebula_TopLevel` (**boolean**) - the module will be added at top level (ie. self.Module or Nebula.Module), as well as under it's holding table. It is not recommended to use this on modules loaded with LoadModule, it will only be added to the top level of modules after it. <br />

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

___

ServerScriptService/Nebula/MessageGiver
```lua
local MessageGiver = {};

function MessageGiver:Client_GetMessage(player, theirMessage)
	return self.InnerMessage:format(player.Name, theirMessage);
end

function MessageGiver:Load()
	self.InnerMessage = "Hello, %s! You told me: %s";
end

return MessageGiver;
```
<br />

StarterPlayerScripts/Nebula/MessageAnnouncer
```lua
local MessageAnnouncer = {};

function MessageAnnouncer:Start()
	print(self.Server.MessageGiver:GetMessage("hi"));
end

return MessageAnnouncer;
```