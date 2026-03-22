local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

module.meta = {
    name = "Teleport",
    tab = "Misc",
    side = "Left",
    priority = 1
}

module.spawns = {}
module.lastPosition = nil
module.spawnBox = nil
module.Config = nil

local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- teleport functions
function module.teleport(cf)
    local root = getRoot()
    module.lastPosition = root.CFrame
    root.CFrame = cf
end

function module.teleportBack()
    if module.lastPosition then
        local root = getRoot()
        root.CFrame = module.lastPosition
    end
end

-- add spawn
function module.addSpawn(ctx,name,key)
    local root = getRoot()
    local data = {name = name, cf = root.CFrame, key = key}
    table.insert(module.spawns,data)
    
    -- add button
    module.spawnBox:AddButton(name,function()
        module.teleport(data.cf)
    end)

    -- keybind
    if key and key ~= "" then
        module.spawnBox:AddLabel(name.." Key")
        :AddKeyPicker("TPKEY_"..name,{
            Default = key,
            Mode = "Toggle",
            Text = "Teleport "..name
        })
        Options["TPKEY_"..name]:OnClick(function()
            module.teleport(data.cf)
        end)
    end

    -- save to config
    if module.Config then
        module.Config.Custom.Teleports = module.spawns
        module.Config.save()
    end
end

-- remove spawn
function module.removeSpawn(index)
    if module.spawns[index] then
        table.remove(module.spawns,index)
        -- rebuild spawnBox UI
        if module.spawnBox then
            module.spawnBox:ClearAllChildren()
            for _,v in pairs(module.spawns) do
                module.addSpawn({tab=nil},v.name,v.key)
            end
            module.spawnBox:AddButton("Teleport Back",module.teleportBack)
        end
        if module.Config then
            module.Config.Custom.Teleports = module.spawns
            module.Config.save()
        end
    end
end

-- rename spawn
function module.renameSpawn(index,newName)
    if module.spawns[index] then
        module.spawns[index].name = newName
        -- rebuild spawnBox UI
        if module.spawnBox then
            module.spawnBox:ClearAllChildren()
            for _,v in pairs(module.spawns) do
                module.addSpawn({tab=nil},v.name,v.key)
            end
            module.spawnBox:AddButton("Teleport Back",module.teleportBack)
        end
        if module.Config then
            module.Config.Custom.Teleports = module.spawns
            module.Config.save()
        end
    end
end

-- init UI
function module.init(ctx)
    local tab = ctx.tab
    local box = ctx.box

    module.Config = ctx.Config -- link config module

    -- load saved spawns
    module.spawns = module.Config and module.Config.Custom.Teleports or {}

    module.spawnBox = tab:AddRightGroupbox("Saved Spawns")
    module.spawnBox:AddButton("Teleport Back",module.teleportBack)

    for _,v in pairs(module.spawns) do
        module.addSpawn(ctx,v.name,v.key)
    end

    -- input to create new spawn
    box:AddInput("TPName",{Text="Spawn Name",Default="MySpawn"})
    box:AddInput("TPKey",{Text="Keybind (optional)",Default=""})
    box:AddButton("Set Spawn",function()
        local name = Options.TPName.Value
        local key = Options.TPKey.Value
        if name ~= "" then
            module.addSpawn(ctx,name,key)
        end
    end)
end

return module
