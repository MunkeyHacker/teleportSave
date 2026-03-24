\local module = {}

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

-- root helper
local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- serialize cframe
local function packCF(cf)
    return {cf:GetComponents()}
end

local function unpackCF(t)
    return CFrame.new(unpack(t))
end

-- teleport
function module.teleport(cf)
    local root = getRoot()
    module.lastPosition = root.CFrame
    root.CFrame = cf
end

function module.teleportBack()
    if module.lastPosition then
        getRoot().CFrame = module.lastPosition
    end
end

-- rebuild ui
function module:rebuildSpawnUI()
    if not self.spawnBox then return end

    self.spawnBox:Clear() -- ⭐ LIBRARY SAFE CLEAR

    self.spawnBox:AddButton("Teleport Back", function()
        self.teleportBack()
    end)

    for i,data in ipairs(self.spawns) do

        self.spawnBox:AddButton(data.name, function()
            module.teleport(data.cf)
        end)

        self.spawnBox:AddButton("Remove "..data.name, function()
            table.remove(module.spawns,i)
            module:saveSpawns()
            module:rebuildSpawnUI()
        end)

        local rename = self.spawnBox:AddInput("Rename"..i,{
            Text="Rename "..data.name,
            Default=data.name
        })

        rename:OnFinished(function(val)
            if val ~= "" then
                data.name = val
                module:saveSpawns()
                module:rebuildSpawnUI()
            end
        end)

        if data.key and data.key ~= "" then
            local lbl = self.spawnBox:AddLabel(data.name.." Key")
            local kp = lbl:AddKeyPicker("TPKEY"..i,{
                Default=data.key,
                Mode="Toggle",
                Text="Teleport "..data.name
            })

            kp:OnClick(function()
                module.teleport(data.cf)
            end)
        end
    end
end

-- add spawn
function module.addSpawn(name,key)
    local cf = getRoot().CFrame

    table.insert(module.spawns,{
        name = name,
        key = key,
        cf = cf
    })

    module:saveSpawns()
    module:rebuildSpawnUI()
end

-- save
function module:saveSpawns()
    if not self.Config then return end

    local save = {}

    for _,v in ipairs(self.spawns) do
        table.insert(save,{
            name = v.name,
            key = v.key,
            cf = packCF(v.cf)
        })
    end

    pcall(function()
        self.Config.save("Teleports",save)
    end)
end

-- load
function module:loadSpawns()
    if not self.Config then return end

    local loaded = self.Config.load("Teleports") or {}

    self.spawns = {}

    for _,v in ipairs(loaded) do
        if v.cf then
            table.insert(self.spawns,{
                name = v.name,
                key = v.key,
                cf = unpackCF(v.cf)
            })
        end
    end

    self:rebuildSpawnUI()
end

-- init
function module.init(ctx)

    module.Config = ctx.Config

    local box = ctx.box

    local nameInput = box:AddInput("TPName",{Text="Spawn Name",Default="MySpawn"})
    local keyInput = box:AddInput("TPKey",{Text="Keybind",Default=""})

    box:AddButton("Set Spawn",function()
        if nameInput.Value ~= "" then
            module.addSpawn(nameInput.Value,keyInput.Value)
        end
    end)

    module.spawnBox = ctx.tab:AddRightGroupbox("Saved Spawns")

    module:loadSpawns()
end

return module
