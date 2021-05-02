--[[

    NebulaFramework/NebulaServer
    > Author: ReturnedTrue
    > Date: 07/04/2021
    > License: MIT

--]]

local InternalShared = game:GetService("ReplicatedStorage").NebulaInternal;

local Logger = require(InternalShared.Private.Logger);
local Constants = require(InternalShared.Private.Constants);
local Util = require(InternalShared.Private.Util);

local NebulaServer = {
    AddModule = InitModule,

    Services = require(InternalShared.Public.Services),
    Server = {},
    Storage = {},
    Replicated = {},
};

local Debug = Logger.new("NebulaServer");

local HoistingList = {};
local StartingList = {};
local UpdateList = {};

local RemotesFolder = Instance.new("Folder");

function InjectLoadMethods(module: table)
    local methodsAdded = {};
    local methods = {
        CreateEvents = function(self, events: table)
            if (not module.ModuleRemotesFolder) then
                Debug:Warn(Debug.WarnMessages.OnlyServerModules);
                return false;
            end

            if (self.Events ~= nil) then
                Debug:Warn(Debug.WarnMessages.OverridingProperty, "Events", module.Name);
            end

            self.Events = {};

            for _, eventName in ipairs(events) do
                local remoteEvent = Instance.new("RemoteEvent");
                remoteEvent.Name = eventName;
                remoteEvent.Parent = module.ModuleRemotesFolder;

                self.Events[eventName] = {
                    FireClient = function(_, player: Player, ...)
                        remoteEvent:FireClient(player, ...);
                    end,

                    FireEveryClient = function(_, ...)
                        remoteEvent:FireAllClients(...);
                    end,

                    FireEveryExcept = function(_, exceptionPlayer: Player, ...)
                        for _, player in ipairs(self.Services.Players:GetPlayers()) do
                            if (player ~= exceptionPlayer) then
                                remoteEvent:FireClient(player, ...);
                            end
                        end
                    end
                }
            end
        end
    };

    for methodName, methodBody in pairs(methods) do
        if (module.Response[methodName] ~= nil) then
            Debug:Warn(Debug.WarnMessages.OverridingProperty, methodName, module.Name);
        end

        module.Response[methodName] = methodBody;
        table.insert(methodsAdded, methodName);
    end

    return methodsAdded;
end

function RemoveLoadMethods(module: table, methods: table)
    local function Warning()
        Debug:Warn(Debug.WarnMessages.CannotUseMethod);
    end

    for _, methodName in ipairs(methods) do
        module.Response[methodName] = Warning
    end
end

function LoadModule(module: table)
    local methodsAdded = InjectLoadMethods(module);

    module.Response:Load();
    RemoveLoadMethods(module, methodsAdded);
end

function HoistModule(module: table)
    if (module.Attributes.TopLevel) then
        if (NebulaServer[module.Name]) then
            Debug:Warn(Debug.WarnMessages.TopLevelDenied, module.Name);
        else
            NebulaServer[module.Name] = module.PureResponse;
        end
    end

    if (module.Holder) then
        module.Holder[module.Name] = module.PureResponse;
    end
end

function InitHoistProcedure()
    for _, module in ipairs(HoistingList) do
        HoistModule(module);
    end

    HoistingList = false;
end

function StartModule(module: table)
    if (module.Type == "function") then
        Util.Async(module.Response, NebulaServer);
    else
        Util.Async(module.Response.Start, module.Response)
    end
end

function InitStartProcedure()
    for _, module in ipairs(StartingList) do
        StartModule(module);
    end

    StartingList = false;
end

function InitUpdateCycle()
    NebulaServer.Services.RunService.Heartbeat:Connect(function(deltaTime)
        for _, response in ipairs(UpdateList) do
            Util.Async(response.Update, response, deltaTime);
        end
    end)
end

function CreateModuleRemotes(module: table)
    if (module.Holder ~= NebulaServer.Server) then
        return false;
    end

    local moduleFolder = Instance.new("Folder");
    moduleFolder.Name = module.Name;

    for key in pairs(module.Response) do
        local methodName = key:match(Constants.CLIENT_METHOD_PATTERN);

        if (methodName) then
            local remoteFunction = Instance.new("RemoteFunction");
            remoteFunction.Name = methodName;

            remoteFunction.OnServerInvoke = function(...)
                return module.Response[key](module.Response, ...);
            end

            remoteFunction.Parent = moduleFolder;
        end
    end

    moduleFolder.Parent = RemotesFolder;

    return moduleFolder;
end

function InitModule(moduleScript: ModuleScript, holder: table, inheritedNormalModule: boolean)
    local response = require(moduleScript);
    local module = {
        Response = response,
        PureResponse = typeof(response) == "table" and Util.CloneTable(response) or response,
        Type = typeof(response),
        Holder = holder,
        Name = moduleScript.Name,
        Attributes = Util.GetModuleAttributes(moduleScript),
    }

    if (module.Attributes.Ignore) then
        Debug:Log(Debug.LogMessages.IgnoredModule, module.Name);
        return;
    end

    if (inheritedNormalModule or module.Attributes.NormalModule) then
        HoistModule(module);

    elseif (module.Type == "function") then
        if (StartingList) then
            table.insert(StartingList, module);
        else
            StartModule(module);
        end

    elseif (module.Type == "table") then
        module.ModuleRemotesFolder = CreateModuleRemotes(module);
        Util.Inject(module, NebulaServer, Debug);

        if (response.Load) then
            LoadModule(module)
        end

        if (HoistingList) then
            table.insert(HoistingList, module);
        else
            HoistModule(module);
        end

        if (response.Start) then
            if (StartingList) then
                table.insert(StartingList, module);
            else
                StartModule(module);
            end
        end

        if (response.Update) then
            table.insert(UpdateList, response);
        end

    else
        HoistModule(module);
    end
end

function InitFolder(folder: Folder, target: table, normalModules: boolean)
    for _, child in ipairs(folder:GetChildren()) do
        if (child:IsA("Folder")) then
            target[child.Name] = {};
            InitFolder(child, target[child.Name], normalModules);

        elseif (child:IsA("ModuleScript")) then
            InitModule(child, target, normalModules);
        end
    end
end

function InitContainers()
    local containers = {
        {NebulaServer.Services.ReplicatedStorage, NebulaServer.Replicated, true},
        {NebulaServer.Services.ServerStorage, NebulaServer.Storage, false},
        {NebulaServer.Services.ServerScriptService, NebulaServer.Server, false},
    };

    for _, container in ipairs(containers) do
        local folder = container[1]:FindFirstChild("Nebula");

        if (folder) then
            InitFolder(folder, container[2], container[3]);
        end
    end
end

function InitRemotes()
    RemotesFolder.Name = Constants.REMOTES_FOLDER_NAME;
    RemotesFolder.Parent = InternalShared;
end

function Main()
    Debug:Log(Debug.LogMessages.StartingUp, require(InternalShared.Private.Version));

    InitContainers();
    InitHoistProcedure();
    InitStartProcedure();
    InitRemotes();
    InitUpdateCycle();

    Debug:Log(Debug.LogMessages.Loaded);
end

Main();