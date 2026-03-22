local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- MODULE META
module.meta = {
    name = "Teleport",
    tab = "Misc",
    side = "Right",
    priority = 1
}

module.spawns = {}         -- stored teleports
module.lastPosition = nil  -- teleport back
module.spawnBox = nil      -- UI group

-- Helper: get player's root part
local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- Teleport to CFrame
function module.teleport(cf)
    local root = getRoot()
    module.lastPosition = root.CFrame
    root.CFrame = cf
end

-- Teleport back
function module.teleportBack()
    if module.lastPosition then
        local root = getRoot()
        root.CFrame = module.lastPosition
    end
end

-- Add a spawn
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
        if v == data then
            table.remove(module.spawns,i)
            break
        end
    end
    module.spawnBox:Clear()
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

-- Update single spawn UI
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
        if value ~= "" then
            module.renameSpawn(data,value)
        end
    end)

    if data.key and data.key ~= "" then
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

-- Save spawns via SaveManager
function module:saveSpawns()
    if Options and SaveManager and SaveManager.save then
        SaveManager.save("Teleports",self.spawns)
    end
end

-- Load saved spawns
function module:loadSpawns()
    if Options and SaveManager and SaveManager.load then
        local loaded = SaveManager.load("Teleports") or {}
        for _,v in ipairs(loaded) do
            module:addSpawn(v.name,v.key,v.cf)
        end
    end
end

-- INIT
function module.init(ctx)
    local tab = ctx.tab
    local box = ctx.box

    -- Inputs for new spawn
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
        if name ~= "" then
            module.addSpawn(name,key)
        end
    end)

    -- Groupbox for saved spawns
    module.spawnBox = tab:AddRightGroupbox("Saved Spawns")

    -- Teleport back button
    module.spawnBox:AddButton("Teleport Back",function()
        module.teleportBack()
    end)

    -- Load previous spawns
    module:loadSpawns()
end

return module
