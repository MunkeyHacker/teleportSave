local module = {}
local HttpService = game:GetService("HttpService")

module.meta = {
    name = "Config",
    tab = "Misc",
    side = "Right",
    priority = 999
}

local folder = "MunkeyHub/Configs/"
local file = folder .. game.PlaceId .. ".json"

module.Custom = {}

local function ensureFolder()
    if not isfolder("MunkeyHub") then makefolder("MunkeyHub") end
    if not isfolder(folder) then makefolder(folder) end
end

function module.save()
    ensureFolder()

    local data = {
        Toggles = {},
        Options = {},
        Custom = module.Custom
    }

    if getgenv().Toggles then
        for k,v in pairs(getgenv().Toggles) do
            if v and v.Value ~= nil then
                data.Toggles[k] = v.Value
            end
        end
    end

    if getgenv().Options then
        for k,v in pairs(getgenv().Options) do
            if v and v.Value ~= nil then
                if typeof(v.Value) == "Color3" then
                    data.Options[k] = {__type="Color3",r=v.Value.R,g=v.Value.G,b=v.Value.B}
                else
                    data.Options[k] = v.Value
                end
            end
        end
    end

    pcall(function()
        writefile(file,HttpService:JSONEncode(data))
    end)
end

function module.load()
    if not isfile(file) then return end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(file))
    end)
    if not success or not data then return end

    if getgenv().Toggles and data.Toggles then
        for k,v in pairs(data.Toggles) do
            if getgenv().Toggles[k] then
                pcall(function() getgenv().Toggles[k]:SetValue(v) end)
            end
        end
    end

    if getgenv().Options and data.Options then
        for k,v in pairs(data.Options) do
            if getgenv().Options[k] then
                pcall(function()
                    if type(v) == "table" and v.__type == "Color3" then
                        getgenv().Options[k]:SetValue(Color3.new(v.r,v.g,v.b))
                    else
                        getgenv().Options[k]:SetValue(v)
                    end
                end)
            end
        end
    end

    module.Custom = data.Custom or {}
end

function module.save(key, value)
    if not key then
        module.save()
        return
    end

    ensureFolder()
    module.Custom[key] = value

    local data = {
        Toggles = {},
        Options = {},
        Custom = module.Custom
    }

    if getgenv().Toggles then
        for k,v in pairs(getgenv().Toggles) do
            if v and v.Value ~= nil then
                data.Toggles[k] = v.Value
            end
        end
    end

    if getgenv().Options then
        for k,v in pairs(getgenv().Options) do
            if v and v.Value ~= nil then
                if typeof(v.Value) == "Color3" then
                    data.Options[k] = {__type="Color3",r=v.Value.R,g=v.Value.G,b=v.Value.B}
                else
                    data.Options[k] = v.Value
                end
            end
        end
    end

    pcall(function()
        writefile(file,HttpService:JSONEncode(data))
    end)
end

function module.load(key)
    if not key then
        module.load()
        return
    end

    if not isfile(file) then return nil end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(file))
    end)
    if not success or not data then return nil end

    module.Custom = data.Custom or {}
    return module.Custom[key]
end

function module.init(ctx)
    local box = ctx.box
    box:AddButton("Save Config",function()
        module.save()
    end)
    box:AddButton("Load Config",function()
        module.load()
    end)
end

return module
