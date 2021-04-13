--[[

    NebulaFramework/Logger
    > Author: ReturnedTrue
    > Date: 07/07/2021
    > License: MIT

--]]

local Logger = {};
Logger.__index = Logger;

function Logger.new(scriptName: string)
    local self = setmetatable({}, Logger);
    self.Prefix = ("[%s]"):format(scriptName);

    return self;
end

function Logger:Log(...: string)
    print(self.Prefix, ...);
end

function Logger:Warn(...: string)
    warn(self.Prefix, ...)
end

function Logger:Fatal(...: string)
    local message = ("%s %s"):format(
        self.Prefix,
        table.concat({...}, " ")
    );

    error(message, 0);
end

return Logger;
