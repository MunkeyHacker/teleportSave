local module = {}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

module.meta = {
    name = "Teleport",
    tab = "Misc",
    side = "Left",
    priority = 5
}

module.spawns = {}
module.lastPosition = nil

local spawnBox
local managerBox

local folder = "MunkeyHub/Teleports/"
local file = folder .. game.PlaceId .. ".json"

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

local function rebuildUI()

    spawnBox:ClearChildren()
    managerBox:ClearChildren()

    spawnBox:AddButton("Teleport Back",function()
        module.teleportBack()
    end)

    for i,data in ipairs(module.spawns) do

        spawnBox:AddButton(data.name,function()
            module.teleport(CFrame.new(unpack(data.cf)))
        end)

        managerBox:AddLabel(data.name)

        managerBox:AddButton("Remove "..data.name,function()
            table.remove(module.spawns,i)
            rebuildUI()
        end)

        managerBox:AddButton("Rename "..data.name,function()

            local new = Options.TPRename.Value
            if new ~= "" then
                data.name = new
                rebuildUI()
            end

        end)

    end

end

function module.save()

    if not isfolder("MunkeyHub") then
        makefolder("MunkeyHub")
    end

    if not isfolder(folder) then
        makefolder(folder)
    end

    writefile(file,HttpService:JSONEncode(module.spawns))

end

function module.load()

    if not isfile(file) then return end

    local data = HttpService:JSONDecode(readfile(file))

    module.spawns = data or {}

    rebuildUI()

end

function module.addSpawn(name)

    local root = getRoot()
    if not root then return end
    if name == "" then return end

    local cf = {root.CFrame:GetComponents()}

    table.insert(module.spawns,{
        name = name,
        cf = cf
    })

    rebuildUI()

end

function module.init(ctx)

    local box = ctx.box
    local tab = ctx.tab

    box:AddInput("TPName",{
        Text="Teleport Name",
        Default="MyTeleport"
    })

    box:AddButton("Save Position",function()
        module.addSpawn(Options.TPName.Value)
    end)

    box:AddInput("TPRename",{
        Text="Rename To",
        Default=""
    })

    box:AddButton("Save Teleports",function()
        module.save()
    end)

    box:AddButton("Load Teleports",function()
        module.load()
    end)

    spawnBox = tab:AddRightGroupbox("Saved Teleports")
    managerBox = tab:AddLeftGroupbox("Teleport Manager")

    module.load()

end

return module
