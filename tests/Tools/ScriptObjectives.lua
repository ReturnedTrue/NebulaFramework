local ScriptObjectives = {};
ScriptObjectives.__index = ScriptObjectives;

function ScriptObjectives.new(context: string, objectives: table)
    local self = setmetatable({}, ScriptObjectives);

    self.Completed = false;
    self.Context = context;
    self.Objectives = objectives;
    self.Results = {};

    for _, objective in ipairs(objectives) do
        self.Results[objective] = { Bool = false, DidRun = false }
    end

    return self;
end

function ScriptObjectives:SetObjective(objectiveName: string, bool: boolean)
    self.Results[objectiveName] = { Bool = bool, DidRun = true };
end

function ScriptObjectives:OutputResults()
    self.Completed = true;

    print(" ");
    print("===== Results for", self.Context, "testing =====");
    print(" ");

    local counts = {
        Success = 0,
        Error = 0,
        NeverRan = 0
    };

    for _, objectiveName in ipairs(self.Objectives) do
        local result = self.Results[objectiveName];
        local resultString;

        if (result.Bool) then
            resultString = "SUCCESS";
            counts.Success += 1;
        else
            if (result.DidRun == false) then
                resultString = "NEVER_RAN";
                counts.NeverRan += 1;
            else
                resultString = "ERROR";
                counts.Error += 1;
            end
        end

        local fullString = ("\t\t[%s] %s")
            :format(resultString, objectiveName, result.Time or 0);

        if (result.Bool) then
            print(fullString);
        else
            warn(fullString);
        end
    end

    print(" ");
    print(
        ("> Success: %d | Error: %d | NeverRan: %d")
            :format(counts.Success, counts.Error, counts.NeverRan)
    );
    print(" ");
end

return ScriptObjectives;