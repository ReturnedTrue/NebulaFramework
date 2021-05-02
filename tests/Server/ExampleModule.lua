local ExampleModule = {};

function ExampleModule:Client_Foo()
    return true;
end

function ExampleModule:Foo()
    return true;
end

function ExampleModule:Load()
    self:CreateEvents({"ExampleEvent"});
end

return ExampleModule;