local module = {}
local Players = game:GetService("Players")
local player = Players.LocalPlayer

module.meta = {
    name = "Teleport",
    tab = "Misc",
    side = "Right",
    priority = 1
}

module.spawns = {}
module.lastPosition = nil
module.spawnBox = nil
module.Config = nil

-- Helper to get player root
local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- Teleport
function module.teleport(cf)
    local root = getRoot()
    module.lastPosition = root.CFrame
    root.CFrame = cf
end

function module.teleportBack()
    if module.lastPosition then
        module.teleport(module.lastPosition)
    end
end

-- Convert CFrame to table for saving
local function cfToTable(cf)
    return {cf:GetComponents()}
end

local function tableToCf(t)
    return CFrame.new(unpack(t))
end

-- Add spawn
function module.addSpawn(name,key,cf)
    cf = cf or getRoot().CFrame
    local data = {name=name, cf=cf, key=key}
    table.insert(module.spawns,data)
    if module.spawnBox then
        module:updateSpawnUI(data)
    end
    module:saveSpawns()
end

-- Remove spawn
function module.removeSpawn(data)
    for i,v in ipairs(module.spawns) do
        if v==data then
            table.remove(module.spawns,i)
            break
        end
    end
    if module.spawnBox then
        module.spawnBox:Clear()
        for _,v in ipairs(module.spawns) do
            module:updateSpawnUI(v)
        end
    end
    module:saveSpawns()
end

-- Rename spawn
function module.renameSpawn(data,newName)
    data.name = newName
    if module.spawnBox then
        module.spawnBox:Clear()
        for _,v in ipairs(module.spawns) do
            module:updateSpawnUI(v)
        end
    end
    module:saveSpawns()
end

-- Update UI for single spawn
function module:updateSpawnUI(data)
    local btn = module.spawnBox:AddButton(data.name,function()
        module.teleport(data.cf)
    end)

    module.spawnBox:AddButton("Remove "..data.name,function()
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
                Default=data.key,
                Mode="Toggle",
                Text="Teleport "..data.name
            })
        if Options["TPKEY_"..data.name] then
            Options["TPKEY_"..data.name]:OnClick(function()
                module.teleport(data.cf)
            end)
        end
    end
end

-- Save all spawns via Config
function module:saveSpawns()
    if self.Config and self.Config.save then
        local saveTable = {}
        for _,v in ipairs(self.spawns) do
            table.insert(saveTable,{
                name=v.name,
                cf=cfToTable(v.cf),
                key=v.key
            })
        end
        pcall(function() self.Config.save("Teleports",saveTable) end)
    end
end

-- Load spawns via Config
function module:loadSpawns()
    if self.Config and self.Config.load then
        local loaded = self.Config.load("Teleports") or {}
        for _,v in ipairs(loaded) do
            local cf = v.cf and tableToCf(v.cf) or nil
            self:addSpawn(v.name,v.key,cf)
        end
    end
end

-- Init module
function module.init(ctx)
    local tab = ctx.tab
    local box = ctx.box
    self.Config = ctx.Config

    box:AddInput("TPName",{Text="Spawn Name",Default="MySpawn"})
    box:AddInput("TPKey",{Text="Keybind (optional)",Default=""})

    box:AddButton("Set Spawn",function()
        local name = Options.TPName and Options.TPName.Value or "MySpawn"
        local key = Options.TPKey and Options.TPKey.Value or ""
        if name ~= "" then
            module.addSpawn(name,key)
        end
    end)

    module.spawnBox = tab:AddRightGroupbox("Saved Spawns")
    module.spawnBox:AddButton("Teleport Back",function()
        module.teleportBack()
    end)

    -- Load saved spawns after UI exists
    module:loadSpawns()
end

return module
