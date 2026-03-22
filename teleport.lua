local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

module.spawns = {}
module.lastPosition = nil

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

function module.addSpawn(name,key)

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

    if key ~= "" then
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

function module.init(window)

    local tab = window:AddTab("Teleport")

    local main = tab:AddLeftGroupbox("Create Spawn")

    main:AddInput("TPName",{
        Text="Spawn Name",
        Default="MySpawn"
    })

    main:AddInput("TPKey",{
        Text="Keybind (optional)",
        Default=""
    })

    main:AddButton("Set Spawn",function()

        local name = Options.TPName.Value
        local key = Options.TPKey.Value

        if name ~= "" then
            module.addSpawn(name,key)
        end

    end)

    module.spawnBox = tab:AddRightGroupbox("Saved Spawns")

    module.spawnBox:AddButton("Teleport Back",function()
        module.teleportBack()
    end)

end

return module