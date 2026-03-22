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
module.Config = nil      -- Config module reference
module.uiElements = {}   -- store buttons/inputs for rebuild

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

-- Update the UI for a single spawn
function module:updateSpawnUI(data)
    self.uiElements[data.name] = self.uiElements[data.name] or {}

    -- Main teleport button
    local btn = self.spawnBox:AddButton(data.name, function()
        module.teleport(data.cf)
    end)
    self.uiElements[data.name].btn = btn

    -- Remove button
    local removeBtn = self.spawnBox:AddButton("Remove "..data.name, function()
        module.removeSpawn(data)
    end)
    self.uiElements[data.name].removeBtn = removeBtn

    -- Rename input
    local renameInput = self.spawnBox:AddInput("Rename_"..data.name,{
        Text="Rename "..data.name,
        Default=data.name
    })
    renameInput:OnChanged(function(value)
        if value ~= "" and value ~= data.name then
            module.renameSpawn(data, value)
        end
    end)
    self.uiElements[data.name].renameInput = renameInput

    -- Keybind (optional)
    if data.key and data.key ~= "" then
        local label = self.spawnBox:AddLabel(data.name.." Key")
        local keypicker = label:AddKeyPicker("TPKEY_"..data.name,{
            Default = data.key,
            Mode = "Toggle",
            Text = "Teleport "..data.name
        })
        keypicker:OnClick(function()
            module.teleport(data.cf)
        end)
        self.uiElements[data.name].keypicker = keypicker
    end
end

-- Rebuild all spawn UI safely
function module:rebuildSpawnUI()
    self.uiElements = {}
    if not self.spawnBox then return end

    -- Clear previous children
    for _,child in ipairs(self.spawnBox:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextBox") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    -- Teleport back button
    self.spawnBox:AddButton("Teleport Back", function()
        self.teleportBack()
    end)

    -- Rebuild all spawns
    for _,v in ipairs(self.spawns) do
        self:updateSpawnUI(v)
    end
end

-- Add a new spawn
function module.addSpawn(name,key,cf)
    cf = cf or getRoot().CFrame
    local data = {name=name,cf=cf,key=key}
    table.insert(module.spawns,data)
    module:rebuildSpawnUI()
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
    module:rebuildSpawnUI()
    module:saveSpawns()
end

-- Rename a spawn
function module.renameSpawn(data,newName)
    data.name = newName
    module:rebuildSpawnUI()
    module:saveSpawns()
end

-- Save all spawns using Config module
function module:saveSpawns()
    if self.Config and self.Config.save then
        local saveTable = {}
        for _,v in ipairs(self.spawns) do
            table.insert(saveTable,{name=v.name,cf=v.cf,key=v.key})
        end
        pcall(function() self.Config.save("Teleports",saveTable) end)
    end
end

-- Load saved spawns from Config
function module:loadSpawns()
    if self.Config and self.Config.load then
        local loaded = self.Config.load("Teleports") or {}
        self.spawns = {}
        for _,v in ipairs(loaded) do
            if v.name and v.cf then
                table.insert(self.spawns,{name=v.name,cf=v.cf,key=v.key})
            end
        end
        module:rebuildSpawnUI()
    end
end

-- INIT MODULE
function module.init(ctx)
    local tab = ctx.tab
    self.Config = ctx.Config

    local box = ctx.box

    -- Inputs for new spawns
    local TPNameInput = box:AddInput("TPName",{
        Text="Spawn Name",
        Default="MySpawn"
    })

    local TPKeyInput = box:AddInput("TPKey",{
        Text="Keybind (optional)",
        Default=""
    })

    -- Set Spawn button
    box:AddButton("Set Spawn",function()
        local name = TPNameInput.Value
        local key = TPKeyInput.Value
        if name ~= "" then
            module.addSpawn(name,key)
        end
    end)

    -- Saved spawns UI
    self.spawnBox = tab:AddRightGroupbox("Saved Spawns")

    -- Load saved spawns
    module:loadSpawns()
end

return module
