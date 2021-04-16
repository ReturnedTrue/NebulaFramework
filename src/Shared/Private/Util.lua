--[[

    NebulaFramework/Util
    > Author: ReturnedTrue
    > Date: 16/04/2021
    > License: MIT

--]]

local Util = {};

function Util.GetModuleAttributes(module: ModuleScript)
    return {
        Ignore = module:GetAttribute("Nebula_Ignore") == true,
        TopLevel = module:GetAttribute("Nebula_TopLevel") == true,
    };
end

function Util.Inject(item: table, injectionTable: table, debug: table)
    for key in pairs(injectionTable) do
        if (item.Response[key] ~= nil) then
            debug:Warn("Overriding existing property", key, "on", item.Name);
        end

        item.Response[key] = injectionTable[key];
    end
end

return Util;