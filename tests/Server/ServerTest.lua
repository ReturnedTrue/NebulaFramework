local ReplicatedStorage = game:GetService("ReplicatedStorage");

local ScriptObjectives = require(ReplicatedStorage.Tools.ScriptObjectives);

local Test = ScriptObjectives.new(
    "Server",
    {"RanLoad", "RanStart", "RanUpdate", "ReplicatedDoesLoad", "StorageDoesLoad", "ServerDoesLoad", "EventsAreCreated"}
);

local ServerTest = {};

function ServerTest:Update()
    if (not Test.Completed) then
        Test:SetObjective("RanUpdate", true);
        Test:OutputResults();
    end
end

function ServerTest:Start()
    Test:SetObjective("RanStart", true);

    Test:SetObjective("StorageDoesLoad", self.Storage.ExampleModule and self.Storage.ExampleModule:Foo());
    Test:SetObjective("ServerDoesLoad", self.Server.ExampleModule and self.Server.ExampleModule:Foo());
end

function ServerTest:Load()
    Test:SetObjective("RanLoad", true);
    Test:SetObjective("ReplicatedDoesLoad", self.Replicated.ExampleModule == true);

    self:CreateEvents({"Test"});
    Test:SetObjective("EventsAreCreated", self.Events and self.Events.Test);
end

return ServerTest;