--[[

    NebulaFramework/NebulaClient
    > Author: ReturnedTrue
    > Date: 16/04/2021
    > License: MIT

--]]

local InternalShared = game:GetService("ReplicatedStorage"):WaitForChild("NebulaInternal");

local Logger = require(InternalShared.Private.Logger);
local Constants = require(InternalShared.Private.Constants);
local Util = require(InternalShared.Private.Util);

local NebulaClient = {
    AddModule = LoadModule,

    Services = require(InternalShared.Public.Services),
    Server = {},
    Client = {},
    ClientStorage = {},
    Replicated = {},
};

local Debug = Logger.new("NebulaClient");

local HoistingList = {};
local StartingList = {};
local UpdateList = {};

function LoadModule(module: table)
    module.Response:Load();
end

function HoistModule(module: table)
    if (module.Attributes.TopLevel) then
        if (NebulaClient[module.Name]) then
            Debug:Warn(Debug.WarnMessages.TopLevelDenied, module.Name);
        else
            NebulaClient[module.Name] = module.Response;
        end
    end

    if (module.Holder) then
        module.Holder[module.Name] = module.Response;
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
        Util.Async(module.Response, NebulaClient);
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
    NebulaClient.Services.RunService.RenderStepped:Connect(function(deltaTime)
        for _, module in ipairs(UpdateList) do
            Util.Async(module.Response.Update, module.Response, deltaTime);
        end
    end)
end

function InitServerIntegration()
    local remoteFolder = InternalShared:FindFirstChild(Constants.REMOTES_FOLDER_NAME);

    if (not remoteFolder) then
        Debug:Log(Debug.LogMessages.WaitingForServer);
        remoteFolder = InternalShared:WaitForChild(Constants.REMOTES_FOLDER_NAME);
    end

    for _, child in ipairs(remoteFolder:GetChildren()) do
        if (child:IsA("Folder")) then
            local moduleTable = {};

            for _, remote in ipairs(child:GetChildren()) do
                if (remote:IsA("RemoteFunction")) then
                    moduleTable[remote.Name] = function(_, ...)
                        return remote:InvokeServer(...);
                    end
                end
            end

            NebulaClient.Server[child.Name] = moduleTable;
        end
    end
end

function InitModule(moduleScript: ModuleScript, holder: table, normalModule: boolean)
    local response = require(moduleScript);
    local module = {
        Response = response,
        Type = typeof(response),
        Holder = holder,
        Name = moduleScript.Name,
        Attributes = Util.GetModuleAttributes(moduleScript),
    }

    if (module.Attributes.Ignore) then
        Debug:Log(Debug.LogMessages.IgnoredModule, module.Name);
        return;
    end

    if (module.Type == "function") then
        if (StartingList) then
            table.insert(StartingList, module);
        else
            StartModule(module);
        end

    elseif (module.Type == "table") then
        if ((not normalModule) and (not module.Attributes.NormalModule)) then
            Util.Inject(module, NebulaClient, Debug);

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
    else
        Debug:Warn(Debug.WarnMessages.WrongReturnType, module.Name, module.Type);
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
        {NebulaClient.Services.StarterPlayer.StarterPlayerScripts, NebulaClient.Client, false},
        {NebulaClient.Services.ReplicatedFirst, NebulaClient.ClientStorage, false},
        {NebulaClient.Services.ReplicatedStorage, NebulaClient.Replicated, true},
    };

    for _, container in ipairs(containers) do
        local folder = container[1]:FindFirstChild("Nebula");

        if (folder) then
            InitFolder(folder, container[2], container[3]);
        end
    end
end

function Main()
    Debug:Log(Debug.LogMessages.StartingUp, require(InternalShared.Private.Version));

    NebulaClient.LocalPlayer = NebulaClient.Services.Players.LocalPlayer;

    InitContainers();
    InitServerIntegration();
    InitHoistProcedure();
    InitStartProcedure();
    InitUpdateCycle();

    Debug:Log(Debug.LogMessages.Loaded);
end

Main();