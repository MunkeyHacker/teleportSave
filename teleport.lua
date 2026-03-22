local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Module metadata
module.meta = {
    name = "Teleport",
    tab = "Misc",
    side = "Right",
    priority = 1
}

module.spawns = {}       -- list of saved spawns
module.lastPosition = nil
module.spawnBox = nil
module.Config = nil      -- will store the Config module reference

-- Helper: Get player's root part
local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- Teleport to a given CFrame
function module.teleport(cf)
    local root = getRoot()
    module.lastPosition = root.CFrame
    root.CFrame = cf
end

-- Teleport back to last position
function module.teleportBack()
    if module.lastPosition then
        local root = getRoot()
        root.CFrame = module.lastPosition
    end
end

-- Add a new spawn
function module.addSpawn(name,key,cf)
    cf = cf or getRoot().CFrame
    local data = {name=name,cf=cf,key=key}
    table.insert(module.spawns,data)
    module:updateSpawnUI(data)
    module:saveSpawns()
end

-- Remove a spawn
function module.removeSpawn(data)
    for i,v in ipairs(module.spawns) do
        if v==data then
            table.remove(module.spawns,i)
            break
        end
    end
    module.spawnBox:Clear() -- rebuild UI
    for _,v in ipairs(module.spawns) do
        module:updateSpawnUI(v)
    end
    module:saveSpawns()
end

-- Rename a spawn
function module.renameSpawn(data,newName)
    data.name = newName
    module.spawnBox:Clear()
    for _,v in ipairs(module.spawns) do
        module:updateSpawnUI(v)
    end
    module:saveSpawns()
end

-- Update the UI for a single spawn
function module:updateSpawnUI(data)
    local btn = module.spawnBox:AddButton(data.name,function()
        module.teleport(data.cf)
    end)

    local removeBtn = module.spawnBox:AddButton("Remove "..data.name,function()
        module.removeSpawn(data)
    end)

    local renameInput = module.spawnBox:AddInput("Rename_"..data.name,{
        Text="Rename "..data.name,
        Default=data.name
    })
    renameInput:OnChanged(function(value)
        if value~="" then
            module.renameSpawn(data,value)
        end
    end)

    if data.key and data.key~="" then
        module.spawnBox:AddLabel(data.name.." Key")
            :AddKeyPicker("TPKEY_"..data.name,{
                Default = data.key,
                Mode = "Toggle",
                Text = "Teleport "..data.name
            })
        Options["TPKEY_"..data.name]:OnClick(function()
            module.teleport(data.cf)
        end)
    end
end

-- Save all spawns using Config module
function module:saveSpawns()
    if self.Config and self.Config.save then
        local saveTable = {}
        for _,v in ipairs(self.spawns) do
            table.insert(saveTable,{name=v.name,cf=v.cf, key=v.key})
        end
        pcall(function() self.Config.save("Teleports",saveTable) end)
    end
end

-- Load saved spawns from Config
function module:loadSpawns()
    if self.Config and self.Config.load then
        local loaded = self.Config.load("Teleports") or {}
        for _,v in ipairs(loaded) do
            self:addSpawn(v.name,v.key,v.cf)
        end
    end
end

-- INIT MODULE
function module.init(ctx)
    local tab = ctx.tab
    local box = ctx.box
    self.Config = ctx.Config

    box:AddInput("TPName",{
        Text="Spawn Name",
        Default="MySpawn"
    })

    box:AddInput("TPKey",{
        Text="Keybind (optional)",
        Default=""
    })

    box:AddButton("Set Spawn",function()
        local name = Options.TPName.Value
        local key = Options.TPKey.Value
        if name~="" then
            module.addSpawn(name,key)
        end
    end)

    -- Saved spawns UI
    module.spawnBox = tab:AddRightGroupbox("Saved Spawns")

    -- Teleport back button
    module.spawnBox:AddButton("Teleport Back",function()
        module.teleportBack()
    end)

    -- Load saved spawns
    module:loadSpawns()
end

return module
