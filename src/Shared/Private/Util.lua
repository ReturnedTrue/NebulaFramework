--[[

    NebulaFramework/Util
    > Author: ReturnedTrue
    > Date: 16/04/2021
    > License: MIT

--]]

local Util = {};

function Util.GetModuleAttributes(module: ModuleScript)
    local attributes = module:GetAttributes();

    return {
        Ignore = attributes["Nebula_Ignore"] == true,
        TopLevel = attributes["Nebula_TopLevel"] == true,
        NormalModule = attributes["Nebula_NormalModule"] == true
    };
end

function Util.Async(foo: any, ...: any)
    local success, message = coroutine.resume(coroutine.create(foo), ...);

    if (success == false) then
        error(message, 0);
    end
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