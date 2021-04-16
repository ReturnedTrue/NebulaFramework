--[[

    NebulaFramework/ModuleQueue
    > Author: ReturnedTrue
    > Date: 08/04/2021
    > License: MIT

--]]

local ModuleQueue = {};
ModuleQueue.__index = ModuleQueue;

function ModuleQueue.new(asynchonrous: boolean, logger: table)
    local self = setmetatable({}, ModuleQueue);

    self.Items = {};
    self.Debug = logger;
    self.Async = asynchonrous;
    self.Override = false;

    return self;
end

function ModuleQueue:Add(item: table)
    if (self.Override) then
        self.Override(item);
    else
        table.insert(self.Items, item);
    end
end

function ModuleQueue:IterateAndOverride(callback: (any) -> void)
    for _, item in ipairs(self.Items) do
        local response = {};

        if (self.Async) then
            response = { coroutine.resume(coroutine.create(callback), item) };
        else
            response = { pcall(callback, item) };
        end

        if (response[1] == false) then
            self.Debug:Warn("Module", item.Name, "errored:", response[2]);
        end
    end

    self.Override = callback;
end

return ModuleQueue;