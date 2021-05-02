local ReplicatedStorage = game:GetService("ReplicatedStorage");

local ScriptObjectives = require(ReplicatedStorage.Tools.ScriptObjectives);

local Test = ScriptObjectives.new(
    "Server",
    {"RanLoad", "RanStart", "ReplicatedDoesLoad"}
);

local ServerTest = {};

function ServerTest:Start()
    Test:SetObjective("RanStart", true);
    Test:OutputResults();
end

function ServerTest:Load()
    Test:SetObjective("RanLoad", true);
    Test:SetObjective("ReplicatedDoesLoad", self.Replicated.ExampleModule == "");
end

return ServerTest;