--[[

    NebulaFramework/Services
    > Author: ReturnedTrue
    > Date: 07/07/2021
    > License: MIT

--]]

local Services = {};

function Services:__index(name)
    self[name] = game:GetService(name);

    return rawget(self, name);
end

return setmetatable({}, Services);