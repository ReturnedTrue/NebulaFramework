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

function Util.Inject(module: table, injectionTable: table, debug: table)
    for key in pairs(injectionTable) do
        if (module.Response[key] ~= nil) then
            debug:Warn(debug.WarnMessages.OverridingProperty, key, module.Name);
        end

        module.Response[key] = injectionTable[key];
    end
end

function Util.CloneTable(t: table)
    local clone = {};

    for key, value in pairs(t) do
        clone[key] = value;
    end

    return clone;
end

function Util.Async(foo: any, ...: any)
    local success, message = coroutine.resume(coroutine.create(foo), ...);

    if (success == false) then
        error(message, 0);
    end
end



return Util;