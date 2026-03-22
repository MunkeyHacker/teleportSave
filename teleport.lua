local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

module.meta = {
    name = "Teleport",
    tab = "Movement",
    side = "Right",
    priority = 5
}

module.spawns = {}
module.lastPosition = nil

local spawnBox

local function getRoot()

    local char = player.Character
    if not char then return end

    return char:FindFirstChild("HumanoidRootPart")

end

function module.teleport(cf)

    local root = getRoot()
    if not root then return end

    module.lastPosition = root.CFrame
    root.CFrame = cf

end

function module.teleportBack()

    if not module.lastPosition then return end

    local root = getRoot()
    if not root then return end

    root.CFrame = module.lastPosition

end

local function createSpawnButton(data)

    spawnBox:AddButton(data.name,function()
        module.teleport(data.cf)
    end)

    if data.key and data.key ~= "" then

        local id = "TPKEY_"..data.name..tostring(#module.spawns)

        spawnBox:AddLabel(data.name.." Key")
        :AddKeyPicker(id,{
            Default = data.key,
            Mode = "Toggle",
            Text = "Teleport "..data.name
        })

        Options[id]:OnClick(function()
            module.teleport(data.cf)
        end)

    end

end

function module.addSpawn(name,key)

    local root = getRoot()
    if not root then return end

    if name == "" then return end

    local data = {
        name = name,
        cf = root.CFrame,
        key = key
    }

    table.insert(module.spawns,data)

    createSpawnButton(data)

end

function module.init(ctx)

    local box = ctx.box
    local tab = ctx.tab

    box:AddInput("TPName",{
        Text="Spawn Name",
        Default="MySpawn"
    })

    box:AddInput("TPKey",{
        Text="Keybind (optional)",
        Default=""
    })

    box:AddButton("Save Current Position",function()

        local name = Options.TPName.Value
        local key = Options.TPKey.Value

        module.addSpawn(name,key)

    end)

    spawnBox = tab:AddLeftGroupbox("Saved Spawns")

    spawnBox:AddButton("Teleport Back",function()
        module.teleportBack()
    end)

end

return module
