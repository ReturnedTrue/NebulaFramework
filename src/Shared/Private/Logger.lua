--[[

    NebulaFramework/Logger
    > Author: ReturnedTrue
    > Date: 07/04/2021
    > License: MIT

--]]

local Logger = {};
Logger.__index = Logger;

function Logger.new(scriptName: string)
    local self = setmetatable({}, Logger);
    self.prefix = ("[%s]"):format(scriptName);

    return self;
end

function Logger:Log(...: string)
    print(self.prefix, ...);
end

function Logger:Warn(...: string)
    warn(self.prefix, ...)
end

function Logger:Fatal(...: string)
    local message = ("%s %s"):format(
        self.prefix,
        table.concat({...}, " ")
    );

    error(message, 0);
end

return Logger;