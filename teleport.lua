local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

module.meta = {
    name = "Teleport",
    tab = "Misc",
    side = "Right",
    priority = 5
}

module.spawns = {}
module.lastPosition = nil
module.dropdown = nil
module.Config = nil

local function root()
    local c = player.Character or player.CharacterAdded:Wait()
    return c:WaitForChild("HumanoidRootPart")
end

local function pack(cf)
    return {cf:components()}
end

local function unpackcf(t)
    return CFrame.new(
        t[1],t[2],t[3],
        t[4],t[5],t[6],
        t[7],t[8],t[9],
        t[10],t[11],t[12]
    )
end

function module.tp(cf)
    local r = root()
    module.lastPosition = r.CFrame
    r.CFrame = cf
end

function module.refresh()
    if not module.dropdown then return end
    
    local list = {}
    for _,v in ipairs(module.spawns) do
        table.insert(list,v.name)
    end
    
    module.dropdown:SetValues(list)
end

function module.save()
    if not module.Config then
        warn("Teleport: Config module not available")
        return
    end

    local s = {}
    for _,v in ipairs(module.spawns) do
        if v.name and v.cf then
            table.insert(s,{
                name=v.name,
                cf=pack(v.cf)
            })
        end
    end

    local ok, err = pcall(function()
        if module.Config.save then
            module.Config.save("Teleports",s)
        elseif module.Config.set then
            module.Config.set("Teleports",s)
        else
            warn("Teleport: Config has no save/set method")
        end
    end)

    if not ok then
        warn("Teleport save error:",err)
    end
end

function module.load()
    if not module.Config then
        warn("Teleport: Config module not available")
        return
    end

    local l
    local ok, err = pcall(function()
        if module.Config.load then
            l = module.Config.load("Teleports")
        elseif module.Config.get then
            l = module.Config.get("Teleports")
        end
    end)

    if not ok then
        warn("Teleport load error:",err)
        return
    end

    if not l or type(l) ~= "table" then
        return
    end

    for _,v in ipairs(l) do
        if v.name and v.cf and type(v.cf) == "table" and #v.cf == 12 then
            local success, result = pcall(function()
                return unpackcf(v.cf)
            end)

            if success and result then
                table.insert(module.spawns,{
                    name=v.name,
                    cf=result
                })
            else
                warn("Teleport: Failed to unpack CFrame for",v.name)
            end
        end
    end
end

function module.init(ctx)

    module.Config = ctx.Config

    if not module.Config then
        warn("Teleport: Config not passed in context")
    else
        print("Teleport: Config loaded successfully")
    end
    
    local box = ctx.box
    
    local name = box:AddInput("TPNAME",{Text="Spawn Name",Default="Spawn"})
    
    box:AddButton("Save Spawn",function()
        if name.Value == "" then return end
        
        table.insert(module.spawns,{
            name=name.Value,
            cf=root().CFrame
        })
        
        module.refresh()
        module.save()
    end)
    
    module.dropdown = box:AddDropdown("TPLIST",{
        Text="Saved Spawns",
        Values={}
    })
    
    box:AddButton("Teleport",function()
        local sel = module.dropdown.Value
        if not sel then return end
        
        for _,v in ipairs(module.spawns) do
            if v.name == sel then
                module.tp(v.cf)
                break
            end
        end
    end)
    
    box:AddButton("Teleport Back",function()
        if module.lastPosition then
            root().CFrame = module.lastPosition
        end
    end)
    
    box:AddButton("Delete",function()
        local sel = module.dropdown.Value
        if not sel then return end
        
        for i,v in ipairs(module.spawns) do
            if v.name == sel then
                table.remove(module.spawns,i)
                break
            end
        end
        
        module.refresh()
        module.save()
    end)
    
    module.load()
    module.refresh()
end

return module
