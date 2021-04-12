--[[

    NebulaFramework/ModuleQueue
    > Author: ReturnedTrue
    > Date: 08/07/2021
    > License: MIT

--]]

local ModuleQueue = {};
ModuleQueue.__index = ModuleQueue;

function ModuleQueue.new()
    local self = setmetatable({}, ModuleQueue);

    self.Items = {};
    self.Override = false;

    return self;
end

function ModuleQueue:Add(item: any)
    if (self.Override) then
        self.Override(item);
    else
        table.insert(self.Items, item);
    end
end

function ModuleQueue:IterateAndOverride(callback)
    for _, item in ipairs(self.Items) do
        callback(item);
    end

    self.Override = callback;
end

return ModuleQueue;