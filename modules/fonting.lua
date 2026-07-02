local Fonting = {}
Fonting.__index = Fonting

local SCOPE = {
    "Players",
    "CoreGui",
    "StarterGui",
    "Workspace",
    "Lighting",
    "ReplicatedStorage",
    "ReplicatedFirst"
}

local CLASSES = {
    "TextLabel",
    "TextButton",
    "TextBox"
}

local CATALOG = {
    ["Gotham"]             = "rbxasset://fonts/families/Gotham.json",
    ["FredokaOne"]         = "rbxasset://fonts/families/FredokaOne.json",
    ["Bangers"]            = "rbxasset://fonts/families/Bangers.json",
    ["Roboto"]             = "rbxasset://fonts/families/Roboto.json",
    ["LuckiestGuy"]        = "rbxasset://fonts/families/LuckiestGuy.json",
    ["Creepster"]          = "rbxasset://fonts/families/Creepster.json",
    ["Arcade"]             = "rbxasset://fonts/families/Arcade.json",
    ["Highway"]            = "rbxasset://fonts/families/Highway.json",
    ["Scifi"]              = "rbxasset://fonts/families/Scifi.json",
    ["Legacy"]             = "rbxasset://fonts/families/Legacy.json",
    ["SourceSans"]         = "rbxasset://fonts/families/SourceSans.json",
    ["SourceSansBold"]     = "rbxasset://fonts/families/SourceSansBold.json",
    ["SourceSansLight"]    = "rbxasset://fonts/families/SourceSansLight.json",
    ["SourceSansSemibold"] = "rbxasset://fonts/families/SourceSansSemibold.json",
    ["Arial"]              = "rbxasset://fonts/families/Arial.json",
    ["ArialBold"]          = "rbxasset://fonts/families/ArialBold.json",
    ["ComicNeon"]          = "rbxasset://fonts/families/ComicNeon.json",
    ["Garamond"]           = "rbxasset://fonts/families/Garamond.json",
    ["Merriweather"]       = "rbxasset://fonts/families/Merriweather.json",
    ["Nunito"]             = "rbxasset://fonts/families/Nunito.json",
    ["Oswald"]             = "rbxasset://fonts/families/Oswald.json",
    ["PatrickHand"]        = "rbxasset://fonts/families/PatrickHand.json",
    ["PermanentMarker"]    = "rbxasset://fonts/families/PermanentMarker.json",
    ["Ubuntu"]             = "rbxasset://fonts/families/Ubuntu.json"
}

local active   = nil
local sync     = false
local signals  = {}
local history  = {}
local registry = {}

local function respond(ok: boolean, message: string, data: any?)
    return {
        ok      = ok,
        message = message,
        data    = data
    }
end

local function verify(instance: Instance): boolean
    if not instance or not typeof(instance) == "Instance" then
        return false
    end
    for _, class in ipairs(CLASSES) do
        if instance:IsA(class) then
            return true
        end
    end
    return false
end

local function scan(): {Instance}
    local nodes = {}
    for _, serviceName in ipairs(SCOPE) do
        local service = game:GetService(serviceName)
        if service then
            for _, descendant in ipairs(service:GetDescendants()) do
                if verify(descendant) then
                    table.insert(nodes, descendant)
                end
            end
        end
    end
    return nodes
end

local function archive(instance: Instance)
    if not history[instance] then
        history[instance] = instance.FontFace
    end
end

local function assign(instance: Instance, font: string): boolean
    if not verify(instance) then
        return false
    end

    archive(instance)

    local source = CATALOG[font]
    if not source then
        return false
    end

    local ok = pcall(function()
        instance.FontFace = Font.new(source)
    end)

    if ok then
        registry[instance] = true
        instance.AncestryChanged:Connect(function()
            if instance.Parent == nil then
                registry[instance] = nil
                history[instance]  = nil
            end
        end)
    end

    return ok
end

local function listen()
    for _, serviceName in ipairs(SCOPE) do
        local service = game:GetService(serviceName)
        if service then
            local signal = service.DescendantAdded:Connect(function(instance)
                if sync and active and verify(instance) then
                    task.wait()
                    assign(instance, active)
                end
            end)
            table.insert(signals, signal)
        end
    end
end

function Fonting.Apply(font: string)
    if type(font) ~= "string" or font == "" then
        return respond(false, "Invalid font name provided.")
    end

    if not CATALOG[font] then
        return respond(false, string.format("Font '%s' not found in catalog.", font))
    end

    local nodes = scan()
    local tally = 0

    for _, node in ipairs(nodes) do
        if assign(node, font) then
            tally += 1
        end
    end

    active = font
    return respond(true, string.format("Font '%s' applied to %d object(s).", font, tally), tally)
end

function Fonting.List()
    local fonts = {}
    for name in pairs(CATALOG) do
        table.insert(fonts, name)
    end
    table.sort(fonts)
    return respond(true, "Catalog retrieved successfully.", fonts)
end

function Fonting.Revert()
    local tally = 0

    for instance, original in pairs(history) do
        if instance and instance.Parent then
            local ok = pcall(function()
                instance.FontFace = original
            end)
            if ok then
                tally += 1
            end
        end
    end

    history  = {}
    registry = {}
    active   = nil

    return respond(true, string.format("Reverted %d object(s) to original font.", tally), tally)
end

function Fonting.Auto(state: boolean)
    if type(state) ~= "boolean" then
        return respond(false, "Auto state must be a boolean value.")
    end

    sync = state

    if state then
        Fonting.Sever()
        listen()
        return respond(true, "Auto tracking enabled.")
    else
        Fonting.Sever()
        return respond(true, "Auto tracking disabled.")
    end
end

function Fonting.Target(instance: Instance, font: string?)
    if not instance then
        return respond(false, "No instance provided.")
    end

    local typeface = font or active
    if not typeface then
        return respond(false, "No font specified and no active font set.")
    end

    if not CATALOG[typeface] then
        return respond(false, string.format("Font '%s' not found in catalog.", typeface))
    end

    if assign(instance, typeface) then
        return respond(true, string.format("Font '%s' applied to target instance.", typeface))
    else
        return respond(false, "Failed to apply font to target instance.")
    end
end

function Fonting.Active()
    if active then
        return respond(true, "Active font retrieved.", active)
    else
        return respond(false, "No active font is currently set.")
    end
end

function Fonting.Count()
    local tally = 0
    for _ in pairs(registry) do
        tally += 1
    end
    return respond(true, "Affected count retrieved.", tally)
end

function Fonting.Sever()
    for _, signal in ipairs(signals) do
        if signal then
            signal:Disconnect()
        end
    end
    signals = {}
    return respond(true, "All auto connections severed.")
end

function Fonting.Tracking()
    return respond(true, "Tracking state retrieved.", sync)
end

function Fonting.Register(name: string, source: any)
    if type(name) ~= "string" or name == "" then
        return respond(false, "Invalid font name provided.")
    end

    if not source then
        return respond(false, "No asset ID or path provided.")
    end

    if type(source) == "number" then
        CATALOG[name] = "rbxassetid://" .. tostring(source)
    elseif type(source) == "string" then
        CATALOG[name] = source
    else
        return respond(false, "Source must be a number (asset ID) or string (path).")
    end

    return respond(true, string.format("Font '%s' registered successfully.", name))
end

function Fonting.Unregister(name: string)
    if type(name) ~= "string" or name == "" then
        return respond(false, "Invalid font name provided.")
    end

    if CATALOG[name] then
        CATALOG[name] = nil
        return respond(true, string.format("Font '%s' unregistered.", name))
    end

    return respond(false, string.format("Font '%s' not found in catalog.", name))
end

function Fonting.Path(font: string)
    if type(font) ~= "string" or font == "" then
        return respond(false, "Invalid font name provided.")
    end

    local source = CATALOG[font]
    if source then
        return respond(true, "Font path retrieved.", source)
    end

    return respond(false, string.format("Font '%s' not found in catalog.", font))
end

function Fonting.Purge()
    Fonting.Revert()
    Fonting.Auto(false)
    Fonting.Sever()
    return respond(true, "Module purged successfully.")
end

return Fonting