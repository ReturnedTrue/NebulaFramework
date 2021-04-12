local ASSET_ID = "6654523308";

local file = remodel.readPlaceFile("place.rbxlx");
local packageFolder = Instance.new("Folder");
packageFolder.Name = "NebulaFramework";

local function CreateFolder(name, childFolder)
    local folder = Instance.new("Folder");
    folder.Name = name;

    childFolder.Parent = folder;
    folder.Parent = packageFolder;
end

CreateFolder("ServerScriptService", file.ServerScriptService.NebulaInternal);
CreateFolder("StarterPlayerScripts", file.StarterPlayer.StarterPlayerScripts.NebulaInternal);
CreateFolder("ReplicatedStorage", file.ReplicatedStorage.NebulaInternal);

remodel.writeModelFile(packageFolder, "release/NebulaFramework.rbxmx");
remodel.writeExistingModelAsset(packageFolder, ASSET_ID);