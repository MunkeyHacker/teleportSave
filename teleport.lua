local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

module.meta = {
    name = "Teleport",
    tab = "Teleport",
    side = "Left",
    priority = 1
}

module.spawns = {}
module.lastPosition = nil
module.spawnBox = nil

local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

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

function module.addSpawn(ctx,name,key)

    local root = getRoot()

    local data = {
        name = name,
        cf = root.CFrame,
        key = key
    }

    table.insert(module.spawns,data)

    module.spawnBox:AddButton(name,function()
        module.teleport(data.cf)
    end)

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

end

function module.init(ctx)

    local tab = ctx.tab
    local box = ctx.box

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
            module.addSpawn(ctx,name,key)
        end

    end)

    module.spawnBox = tab:AddRightGroupbox("Saved Spawns")

    module.spawnBox:AddButton("Teleport Back",function()
        module.teleportBack()
    end)

end

return module
