--[[

    NebulaFramework/NebulaServer
    > Author: ReturnedTrue
    > Date: 07/04/2021
    > License: MIT

--]]

local NebulaShared = game:GetService("ReplicatedStorage").NebulaInternal;

local ModuleQueue = require(NebulaShared.Private.ModuleQueue);
local Logger = require(NebulaShared.Private.Logger);
local Util = require(NebulaShared.Private.Util);

local NebulaServer = {
    Services = require(NebulaShared.Public.Services),
    Server = {},
    Storage = {},
    Replicated = {},
};

local Debug = Logger.new("NebulaServer");

local LoadingQueue = ModuleQueue.new(false, Debug);
local AddingQueue = ModuleQueue.new(false, Debug);
local StartingQueue = ModuleQueue.new(true, Debug);
local UpdateList = {};

function NebulaServer.LoadModule(module: ModuleScript, holder: table)
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
        Util.Inject(info, NebulaServer, Debug);
        AddingQueue:Add(info);

        if (response.Load) then
            LoadingQueue:Add(info);
        end

        if (response.Start) then
            StartingQueue:Add(info);
        end

        if (response.Update) then
            table.insert(UpdateList, response);
        end
    else
        Debug:Warn("Module", module.Name, "returned type", info.Type, "which is not supported");
    end
end

function LoadFolder(folder: Folder, target: table)
    for _, child in ipairs(folder:GetChildren()) do
        if (child:IsA("Folder")) then
            target[child.Name] = {};
            LoadFolder(child, target[child.Name]);

        elseif (child:IsA("ModuleScript")) then
            NebulaServer.LoadModule(child, target);
        end
    end
end

function Main()
    Debug:Log("Starting up on NebulaFramework", require(NebulaShared.Private.Version));

    local containers = {
        {NebulaServer.Services.ServerScriptService, NebulaServer.Server},
        {NebulaServer.Services.ServerStorage, NebulaServer.Storage},
        {NebulaServer.Services.ReplicatedStorage, NebulaServer.Replicated},
    };

    for _, container in ipairs(containers) do
        local folder = container[1]:FindFirstChild("Nebula");

        if (folder) then
            LoadFolder(folder, container[2]);
        end
    end

    LoadingQueue:IterateAndOverride(function(item)
        item.Response:Load();
    end)

    AddingQueue:IterateAndOverride(function(item)
        if (item.Attributes.TopLevel) then
            if (NebulaServer[item.Name]) then
                Debug:Warn("Cannot add module", item.Name, "at top level since that property already exists");
            else
                NebulaServer[item.Name] = item.Response;
            end
        end

        if (item.Holder) then
            item.Holder[item.Name] = item.Response;
        end
    end)

    StartingQueue:IterateAndOverride(function(item)
        if (item.Type == "function") then
            item.Response(NebulaServer);
        else
            item.Response:Start();
        end
    end)

    NebulaServer.Services.RunService.Heartbeat:Connect(function(deltaTime)
        for _, module in ipairs(UpdateList) do
            module:Update(deltaTime);
        end
    end)

    Debug:Log("Loaded");
end

Main();