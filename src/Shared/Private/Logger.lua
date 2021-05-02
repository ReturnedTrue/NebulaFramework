--[[

    NebulaFramework/Logger
    > Author: ReturnedTrue
    > Date: 07/04/2021
    > License: MIT

--]]

local LogMessages = {
    StartingUp = {"Starting up on NebulaFramework %s", 1},
    WaitingForServer = {"Waiting for server", 2},
    Loaded = {"Fully loaded on the context", 3},
    IgnoredModule = {"Ignored module %s", 4}
};

local WarnMessages = {
    WrongReturnType = {"Module %s returned type %s which is not supported", 1},
    TopLevelDenied = {"Cannot add module %s at top level as that property already exists", 2},
    OverridingProperty = {"Overriding existing property %s on %s", 3},
    OnlyServerModules = {"Only modules in the Server can create events", 4},
    CannotUseMethod = {"This method is only avaliable for use in the Load method", 5}
};

local ErrorMessages = {

};

local Logger = {};
Logger.__index = Logger;

function Logger.new(scriptName: string)
    local self = setmetatable({}, Logger);
    self.Prefix = ("[%s]"):format(scriptName);

    self.LogMessages = LogMessages;
    self.WarnMessages = WarnMessages;
    self.ErrorMessages = ErrorMessages;

    return self;
end

function Logger:Log(message: table, ...: string)
    print(self.Prefix, message[1]:format(...), "[LOG-" .. message[2] .. "]");
end

function Logger:Warn(message: table, ...: string)
    warn(self.Prefix, message[1]:format(...), "[WARN-" .. message[2] .. "]");
end

function Logger:Fatal(message: table, ...: string)
    error(self.Prefix .. " " .. message[1]:format(...) .. " [ERROR-" .. message[2] .. "]", 0);
end

return Logger;
