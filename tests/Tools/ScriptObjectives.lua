local ScriptObjectives = {};
ScriptObjectives.__index = ScriptObjectives;

function ScriptObjectives.new(context: string, objectives: table)
    local self = setmetatable({}, ScriptObjectives);

    self.Context = context;
    self.Results = {};

    for _, objective in ipairs(objectives) do
        self.Results[objective] = { Bool = false, Time = false }
    end

    return self;
end

function ScriptObjectives:SetObjective(objectiveName: string, bool: boolean)
    self.Results[objectiveName] = { Bool = bool, Time = os.time() };
end

function ScriptObjectives:OutputResults()
    print("\n");
    print("===== Results for", self.Context, "testing =====");

    local counts = {
        Success = 0,
        Error = 0,
        NeverRan = 0
    };

    for objectiveName, result in pairs(self.Results) do
        local resultString;

        if (result.Bool) then
            resultString = "SUCCESS";
            counts.Success += 1;
        else
            if (result.Time == false) then
                resultString = "NEVER_RAN";
                counts.NeverRan += 1;
            else
                resultString = "ERROR";
                counts.Error += 1;
            end
        end

        local fullString = ("\t[%s] %s <%s>")
            :format(resultString, objectiveName, result.Time and os.date("%X", result.Time) or "---");

        if (result.Bool) then
            print(fullString);
        else
            warn(fullString);
        end
    end

    print(
        ("===== Success: %d | Error: %d | NeverRan: %d =====")
            :format(counts.Success, counts.Error, counts.NeverRan)
    );
    print("\n");
end

return ScriptObjectives;