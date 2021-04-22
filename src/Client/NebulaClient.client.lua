--[[

    NebulaFramework/NebulaClient
    > Author: ReturnedTrue
    > Date: 16/04/2021
    > License: MIT

--]]

local InternalShared = game:GetService("ReplicatedStorage"):WaitForChild("NebulaInternal");

local ModuleQueue = require(InternalShared.Private.ModuleQueue);
local Logger = require(InternalShared.Private.Logger);
local Constants = require(InternalShared.Private.Constants);
local Util = require(InternalShared.Private.Util);

local NebulaClient = {
    Services = require(InternalShared.Public.Services),
    Server = {},
    Client = {},
    ClientStorage = {},
    Replicated = {},
};

local Debug = Logger.new("NebulaClient");

local LoadingQueue = ModuleQueue.new(false);
local AddingQueue = ModuleQueue.new(false);
local StartingQueue = ModuleQueue.new(true);
local UpdateList = {};

function NebulaClient.LoadModule(module: ModuleScript, holder: table, normalModule: boolean)
    local response = require(module);
    local info = {
        Response = response,
        Type = typeof(response),
        Holder = holder,
        Name = module.Name,
        Attributes = Util.GetModuleAttributes(module),
    }

    if (info.Attributes.Ignore) then
        Debug:Log("Ignored module", module.Name);
        return;
    end

    if (info.Type == "function") then
        StartingQueue:Add(info);

    elseif (info.Type == "table") then
        AddingQueue:Add(info);

        if ((not normalModule) and (not info.Attributes.NormalModule)) then
            Util.Inject(info, NebulaClient, Debug);

            if (response.Load) then
                LoadingQueue:Add(info);
            end

            if (response.Start) then
                StartingQueue:Add(info);
            end

            if (response.Update) then
                table.insert(UpdateList, response);
            end
        end
    else
        Debug:Warn("Module", module.Name, "returned type", info.Type, "which is not supported");
    end
end

function LoadFolder(folder: Folder, target: table, normalModules: boolean)
    for _, child in ipairs(folder:GetChildren()) do
        if (child:IsA("Folder")) then
            target[child.Name] = {};
            LoadFolder(child, target[child.Name], normalModules);

        elseif (child:IsA("ModuleScript")) then
            NebulaClient.LoadModule(child, target, normalModules);
        end
    end
end

function Main()
    Debug:Log("Starting up on NebulaFramework", require(InternalShared.Private.Version));

    NebulaClient.LocalPlayer = NebulaClient.Services.Players.LocalPlayer;

    local containers = {
        {NebulaClient.Services.StarterPlayer.StarterPlayerScripts, NebulaClient.Client, false},
        {NebulaClient.Services.ReplicatedFirst, NebulaClient.ClientStorage, false},
        {NebulaClient.Services.ReplicatedStorage, NebulaClient.Replicated, true},
    };

    for _, container in ipairs(containers) do
        local folder = container[1]:FindFirstChild("Nebula");

        if (folder) then
            LoadFolder(folder, container[2], container[3]);
        end
    end

    do
        local RemoteFolder = InternalShared:FindFirstChild(Constants.REMOTES_FOLDER_NAME);

        if (not RemoteFolder) then
            Debug:Log("Waiting on the server");
            RemoteFolder = InternalShared:WaitForChild(Constants.REMOTES_FOLDER_NAME);
        end

        for _, child in ipairs(RemoteFolder:GetChildren()) do
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


    LoadingQueue:IterateAndOverride(function(item)
        item.Response:Load();
    end)

    AddingQueue:IterateAndOverride(function(item)
        if (item.Attributes.TopLevel) then
            if (NebulaClient[item.Name]) then
                Debug:Warn("Cannot add module", item.Name, "at top level since that property already exists");
            else
                NebulaClient[item.Name] = item.Response;
            end
        end

        if (item.Holder) then
            item.Holder[item.Name] = item.Response;
        end
    end)

    StartingQueue:IterateAndOverride(function(item)
        if (item.Type == "function") then
            item.Response(NebulaClient);
        else
            item.Response:Start();
        end
    end)

    NebulaClient.Services.RunService.RenderStepped:Connect(function(deltaTime)
        for _, module in ipairs(UpdateList) do
            module:Update(deltaTime);
        end
    end)

    Debug:Log("Loaded");
end

Main();