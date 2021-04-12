--[[

    NebulaFramework/NebulaServer
    > Author: ReturnedTrue
    > Date: 07/07/2021
    > License: MIT

--]]

local NebulaShared = game:GetService("ReplicatedStorage").NebulaInternal;

local ModuleQueue = require(NebulaShared.Private.ModuleQueue);
local Logger = require(NebulaShared.Private.Logger);

local NebulaServer = {
    Services = require(NebulaShared.Public.Services),
    Server = {},
    Storage = {},
    Replicated = {},
};

local Debug = Logger.new("NebulaServer");
local LoadingQueue = ModuleQueue.new();
local StartingQueue = ModuleQueue.new();

function NebulaServer.LoadModule(module: ModuleScript, holder: table)
    local response = require(module);
    local info = {
        Response = response,
        Type = typeof(response),
        Holder = holder,
        Name = module.Name,
        Attributes = GetModuleAttributes(module),
    }

    if (info.Attributes.Ignore) then
        Debug:Log("Ignored module", module.Name);
        return
    end

    if (info.Type == "function") then
        StartingQueue:Add(info);

    elseif (info.Type == "table") then
        Inject(info, NebulaServer);

        if (response.Load) then
            LoadingQueue:Add(info);
        end

        if (response.Start) then
            StartingQueue:Add(info);
        end
    else
        Debug:Warn("Module", module.Name, "returned type", info.Type, "which is not supported");
    end
end

function GetModuleAttributes(module: ModuleScript)
    return {
        Ignore = module:GetAttribute("Nebula_Ignore") == true,
        TopLevel = module:GetAttribute("Nebula_TopLevel") == true,
    };
end

function Inject(item, injectionTable: table)
    for key in pairs(injectionTable) do
        if (item.Response[key] ~= nil) then
            Debug:Warn("Overriding existing property", key, "on", item.Name);
        end

        item.Response[key] = injectionTable[key];
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
        {"ServerScriptService", NebulaServer.Server},
        {"ServerStorage", NebulaServer.Storage},
        {"ReplicatedStorage", NebulaServer.Replicated},
    };

    for _, container in ipairs(containers) do
        local folder = NebulaServer.Services[container[1]]:FindFirstChild("Nebula");

        if (folder) then
            LoadFolder(folder, container[2]);
        end
    end

    LoadingQueue:IterateAndOverride(function(item)
        item.Response:Load();

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

    Debug:Log("Loaded");
end

Main();