local ReplicatedStorage = game:GetService("ReplicatedStorage");

local ScriptObjectives = require(ReplicatedStorage.Tools.ScriptObjectives);

local Test = ScriptObjectives.new(
    "Client",
    {
        "RanLoad",
        "RanStart",
        "RanUpdate",
        "ReplicatedDoesLoad",
        "ClientStorageDoesLoad",
        "ClientDoesLoad",
        "ServerDoesLoad",
        "ServerEventsDoLoad"
    }
);

local ClientTest = {};

function ClientTest:Update()
    if (not Test.Completed) then
        Test:SetObjective("RanUpdate", true);
    end
end

function ClientTest:Start()
    Test:SetObjective("RanStart", true);

    Test:SetObjective("ClientStorageDoesLoad", self.ClientStorage.ExampleModule and self.ClientStorage.ExampleModule:Foo());
    Test:SetObjective("ClientDoesLoad", self.Client.ExampleModule and self.Client.ExampleModule:Foo());

    Test:SetObjective("ServerDoesLoad", self.Server.ExampleModule and self.Server.ExampleModule:Foo());
    Test:SetObjective("ServerEventsDoLoad", self.Server.ExampleModule and (self.Server.ExampleModule.ExampleEvent ~= nil));

    Test:OutputResults();
end

function ClientTest:Load()
    Test:SetObjective("RanLoad", true);
    Test:SetObjective("ReplicatedDoesLoad", self.Replicated.ExampleModule == true);
end

return ClientTest;