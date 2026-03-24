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
module.Config = nil
module.lastPosition = nil

local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function packCF(cf)
    return {cf:components()}
end

local function unpackCF(t)
    return CFrame.new(
        t[1],t[2],t[3],
        t[4],t[5],t[6],
        t[7],t[8],t[9],
        t[10],t[11],t[12]
    )
end

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

function module.refreshDropdown()
    if not module.dropdown then return end
    
    local names = {}
    for _,v in ipairs(module.spawns) do
        table.insert(names,v.name)
    end
    
    module.dropdown:SetValues(names)
end

function module.save()
    if not module.Config then return end
    
    local save = {}
    for _,v in ipairs(module.spawns) do
        table.insert(save,{
            name = v.name,
            cf = packCF(v.cf)
        })
    end
    
    pcall(function()
        module.Config.save("Teleports",save)
    end)
end

function module.load()
    if not module.Config then return end
    
    local loaded = module.Config.load("Teleports") or {}
    module.spawns = {}
    
    for _,v in ipairs(loaded) do
        if v.cf then
            table.insert(module.spawns,{
                name = v.name,
                cf = unpackCF(v.cf)
            })
        end
    end
end

function module.init(ctx)

    module.Config = ctx.Config
    
    local box = ctx.box
    
    local nameInput = box:AddInput("TPName",{Text="Spawn Name",Default="Spawn"})
    
    box:AddButton("Save Position",function()
        local name = nameInput.Value
        if name == "" then return end
        
        table.insert(module.spawns,{
            name = name,
            cf = getRoot().CFrame
        })
        
        module.refreshDropdown()
        module.save()
    end)
    
    module.dropdown = box:AddDropdown("TPList",{
        Text = "Saved Teleports",
        Values = {},
        Default = nil
    })
    
    box:AddButton("Teleport",function()
        local selected = module.dropdown.Value
        if not selected then return end
        
        for _,v in ipairs(module.spawns) do
            if v.name == selected then
                module.teleport(v.cf)
                break
            end
        end
    end)
    
    box:AddButton("Teleport Back",function()
        module.teleportBack()
    end)
    
    box:AddButton("Delete Selected",function()
        local selected = module.dropdown.Value
        if not selected then return end
        
        for i,v in ipairs(module.spawns) do
            if v.name == selected then
                table.remove(module.spawns,i)
                break
            end
        end
        
        module.refreshDropdown()
        module.save()
    end)
    
    module.load()
    module.refreshDropdown()
end

return module
