local OPT = {}
local shared = shared or _G

if shared.SmartMapOptimizer then
    if shared.SmartMapOptimizer.StopAll then
        pcall(shared.SmartMapOptimizer.StopAll)
    elseif shared.SmartMapOptimizer.Stop then
        pcall(shared.SmartMapOptimizer.Stop)
    end
end

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local MaterialService = game:GetService("MaterialService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local weakKeys = { __mode = "k" }

local tableClear = table.clear or function(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

local clamp = math.clamp or function(x, min, max)
    return x < min and min or x > max and max or x
end

local atan2 = math.atan2 or function(y, x)
    if x == 0 then
        return y >= 0 and math.pi / 2 or -math.pi / 2
    end
    local r = math.atan(y / x)
    if x < 0 then
        r = r + (y >= 0 and math.pi or -math.pi)
    end
    return r
end

local function trim(s)
    if type(s) ~= "string" then
        return s
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function toSet(list)
    local t = {}
    if type(list) == "table" then
        for k, v in pairs(list) do
            if type(v) == "string" then
                t[trim(v)] = true
            elseif type(k) == "string" and v then
                t[trim(k)] = true
            end
        end
    end
    return t
end

local cfg = {
    targetFPS = 60,
    recoverMargin = 10,
    sampleInterval = 1,
    confirmSamples = 3,
    particleScale = 0.6,
    fovReduction = 8,
    farPlaneTarget = 350,
    maxTier = 7,
    minFOV = 50,
    decalTransparency = 0.5,
    textureTransparency = 0.5,
    soundVolumeReduction = 0.5,
    explosionScale = 0.5,
    explosionTransparency = 0.5,
    directory = nil,
    onTierChange = nil,
    MapsFolder = "Maps",
    MapContentModelName = "MAP",
    OptimizeWholeMap = false,
    MapSmartMapChildren = {
        "Model",
        "WINDOW LIGHTS",
        "WEDGES",
        "Cells",
        "ETC",
        "WINDOWS",
        "TORCHES",
        "PLANTS",
        "STATUES"
    },
    MapNeverMapChildren = {
        "BARRIER",
        "GATE",
        "PR Barriers",
        "exitbarrier thing"
    },
    NeverNames = {
        "INFO",
        "Cameras",
        "Spawns",
        "Barriers",
        "Lighting",
        "oldLighting",
        "Final80",
        "Characters",
        "NPCs",
        "BARRIER",
        "Barrier",
        "barrier",
        "BARRIERWEDGE",
        "nullBarrier",
        "exitbarrier thing",
        "PR Barriers",
        "GATE",
        "Terrain"
    },
    NeverClasses = {
        "Script",
        "LocalScript",
        "ModuleScript",
        "RemoteEvent",
        "RemoteFunction",
        "BindableEvent",
        "BindableFunction"
    },
    SkipHumanoids = true,
    ShowDebug = false,
    UseFrustumCulling = true,
    UseDistanceQuality = true,
    UpdateInterval = 0.1,
    MaxVisibleDistance = 500,
    FarDistance = 200,
    FovMarginDeg = 5,
    HiddenDelay = 0.1,
    FarDelay = 0.2,
    FarExitRatio = 0.8,
    CenterViewBoost = 0.4,
    HighImportanceMultiplier = 1.5,
    HighImportanceHiddenDelay = 0.5,
    HideOffscreenParts = true,
    DisableOffscreenEffects = true,
    ReduceOffscreenParticles = true,
    DisableOffscreenSounds = true,
    DisableOffscreenShadows = true,
    HideOffscreenDecals = true,
    OptimizeTextures = false,
    OptimizeWorldUI = false,
    DisableOffscreenWorldUI = true,
    DisableFarShadows = true,
    DisableFarLights = true,
    ReduceFarParticles = true,
    FarParticleRateMultiplier = 0.4,
    DisableFarDecals = true,
    DisableFarWorldUI = true,
    PauseFarSounds = true,
    KeepCenterShadows = true,
    CenterShadowKeepThreshold = 0.5,
    KeepCenterLights = true,
    CenterLightKeepThreshold = 0.4,
    KeepCenterDecals = true,
    CenterDecalKeepThreshold = 0.5,
    BBoxCacheTime = 9e9
}

local neverNames = toSet(cfg.NeverNames)
local neverMapChildren = toSet(cfg.MapNeverMapChildren)
local neverClasses = toSet(cfg.NeverClasses)
local mapSmartSet = toSet(cfg.MapSmartMapChildren)
local mapNeverSet = toSet(cfg.MapNeverMapChildren)

local function rebuildSets()
    neverNames = toSet(cfg.NeverNames)
    neverMapChildren = toSet(cfg.MapNeverMapChildren)
    neverClasses = toSet(cfg.NeverClasses)
    mapSmartSet = toSet(cfg.MapSmartMapChildren)
    mapNeverSet = toSet(cfg.MapNeverMapChildren)
end

local TAG_NEVER = "Optimize.Never"
local TAG_HIGH = "Optimize.High"

local states = {}
local processed = setmetatable({}, weakKeys)
local handled = setmetatable({}, weakKeys)
local owner = setmetatable({}, weakKeys)
local globalConnections = {}
local instanceConnections = setmetatable({}, weakKeys)
local mapRunning = false

local flags = {
    dirty = false,
    restart = false
}

local function debugPrint(msg)
    if cfg.ShowDebug then
        print("[opt] " .. tostring(msg))
    end
end

local function setHas(set, name)
    if type(name) ~= "string" then
        return false
    end
    if set[name] then
        return true
    end
    local t = trim(name)
    return t ~= name and set[t] == true
end

local function nameMatches(name, target)
    if type(name) ~= "string" or type(target) ~= "string" then
        return false
    end
    if name == target then
        return true
    end
    local tt = trim(target)
    if name == tt then
        return true
    end
    return trim(name) == tt
end

local function hasTagSafe(inst, tag)
    local ok, result = pcall(CollectionService.HasTag, CollectionService, inst, tag)
    return ok and result
end

local function isNever(inst)
    if not inst then
        return false
    end
    local n = inst.Name
    if setHas(neverNames, n) or setHas(neverMapChildren, n) or setHas(neverClasses, inst.ClassName) then
        return true
    end
    return hasTagSafe(inst, TAG_NEVER)
end

local function shouldSkipHumanoid(inst)
    if not cfg.SkipHumanoids then
        return false
    end
    if inst:IsA("Humanoid") then
        return true
    end
    if inst:IsA("Model") then
        return inst:FindFirstChildOfClass("Humanoid") ~= nil
    end
    return false
end

local _running = false
local _tier = 0
local _orig = setmetatable({}, weakKeys)
local _origTier = setmetatable({}, weakKeys)
local _globalOrig = {}
local _events = {}
local _fpsBuf = {}
local _fpsBufSize = 60
local _fpsBufHead = 1
local _fpsBufCount = 0
local _fpsAvg = 0
local _lastSample = 0
local _upCount = 0
local _downCount = 0

local _stats = {
    tierChanges = 0,
    instancesOpt = 0,
    instancesRevert = 0,
    lastApplyTime = 0,
    lastRevertTime = 0,
    totalApplyTime = 0,
    totalRevertTime = 0,
    errorsCaught = 0
}

local TIERS = {}

local function dir()
    local d = cfg.directory
    if typeof(d) == "Instance" then
        return d
    end
    return Workspace
end

local accessoryKeys = {
    "HatAccessory",
    "HairAccessory",
    "FaceAccessory",
    "NeckAccessory",
    "ShoulderAccessory",
    "FrontAccessory",
    "BackAccessory",
    "WaistAccessory"
}

TIERS[1] = {
    tracked = setmetatable({}, weakKeys),
    check = function(inst)
        return inst:IsA("ParticleEmitter") or inst:IsA("Trail")
    end,
    collect = function()
        return dir():GetDescendants()
    end
}

TIERS[1].apply = function(t, inst)
    if _orig[inst] or isNever(inst) or owner[inst] then
        return false
    end
    local ok = pcall(function()
        if inst:IsA("ParticleEmitter") then
            _orig[inst] = {
                Transparency = inst.Transparency,
                Rate = inst.Rate
            }
            inst.Rate = inst.Rate * cfg.particleScale
        else
            _orig[inst] = {
                Transparency = inst.Transparency
            }
        end
        inst.Transparency = math.max(inst.Transparency, 0.2)
    end)
    if ok and _orig[inst] then
        _origTier[inst] = 1
        t.tracked[inst] = true
        return true
    end
    return false
end

TIERS[1].restore = function(t, inst)
    local o = _orig[inst]
    if not o then
        return false
    end
    pcall(function()
        inst.Transparency = o.Transparency
        if o.Rate then
            inst.Rate = o.Rate
        end
    end)
    t.tracked[inst] = nil
    _orig[inst] = nil
    _origTier[inst] = nil
    return true
end

TIERS[1].revert = function(t)
    local c = 0
    for inst in pairs(t.tracked) do
        if t.restore(t, inst) then
            c = c + 1
        end
    end
    return c
end

TIERS[2] = {
    tracked = setmetatable({}, weakKeys),
    check = function(inst)
        return inst:IsA("MeshPart") or inst:IsA("FaceInstance") or inst:IsA("ShirtGraphic")
    end,
    collect = function()
        return dir():GetDescendants()
    end
}

TIERS[2].apply = function(t, inst)
    if _orig[inst] or isNever(inst) then
        return false
    end
    if inst:IsA("MeshPart") and owner[inst] then
        return false
    end
    if inst:IsA("FaceInstance") and owner[inst] then
        return false
    end
    local ok = pcall(function()
        if inst:IsA("MeshPart") then
            local data = {}
            local okProps = pcall(function()
                data.RenderFidelity = inst.RenderFidelity
                data.LODX = inst.LODX
                data.LODY = inst.LODY
            end)
            if not okProps then
                return
            end
            _orig[inst] = data
            pcall(function()
                inst.RenderFidelity = Enum.RenderFidelity.Performance
                inst.LODX = Enum.LevelOfDetail.Coarse
                inst.LODY = Enum.LevelOfDetail.Coarse
            end)
        else
            _orig[inst] = {
                Transparency = inst.Transparency
            }
            inst.Transparency = math.max(inst.Transparency, 0.2)
        end
    end)
    if ok and _orig[inst] then
        _origTier[inst] = 2
        t.tracked[inst] = true
        return true
    end
    return false
end

TIERS[2].restore = function(t, inst)
    local o = _orig[inst]
    if not o then
        return false
    end
    pcall(function()
        if inst:IsA("MeshPart") then
            inst.RenderFidelity = o.RenderFidelity
            inst.LODX = o.LODX
            inst.LODY = o.LODY
        else
            inst.Transparency = o.Transparency
        end
    end)
    t.tracked[inst] = nil
    _orig[inst] = nil
    _origTier[inst] = nil
    return true
end

TIERS[2].revert = function(t)
    local c = 0
    for inst in pairs(t.tracked) do
        if t.restore(t, inst) then
            c = c + 1
        end
    end
    return c
end

TIERS[3] = {
    tracked = setmetatable({}, weakKeys),
    check = function(inst)
        return inst:IsA("Light") or inst:IsA("Sound")
    end,
    collect = function()
        return dir():GetDescendants()
    end
}

TIERS[3].apply = function(t, inst)
    if _orig[inst] or isNever(inst) or owner[inst] then
        return false
    end
    local ok = pcall(function()
        if inst:IsA("Light") then
            _orig[inst] = {
                Shadows = inst.Shadows
            }
            inst.Shadows = false
        else
            _orig[inst] = {
                Volume = inst.Volume
            }
            inst.Volume = inst.Volume * cfg.soundVolumeReduction
        end
    end)
    if ok and _orig[inst] then
        _origTier[inst] = 3
        t.tracked[inst] = true
        return true
    end
    return false
end

TIERS[3].restore = function(t, inst)
    local o = _orig[inst]
    if not o then
        return false
    end
    pcall(function()
        if inst:IsA("Light") then
            inst.Shadows = o.Shadows
        else
            inst.Volume = o.Volume
        end
    end)
    t.tracked[inst] = nil
    _orig[inst] = nil
    _origTier[inst] = nil
    return true
end

TIERS[3].revert = function(t)
    local c = 0
    for inst in pairs(t.tracked) do
        if t.restore(t, inst) then
            c = c + 1
        end
    end
    return c
end

TIERS[4] = {
    tracked = setmetatable({}, weakKeys),
    check = function(inst)
        return inst:IsA("Decal") or inst:IsA("Texture")
    end,
    collect = function()
        return dir():GetDescendants()
    end
}

TIERS[4].apply = function(t, inst)
    if _orig[inst] or isNever(inst) or owner[inst] then
        return false
    end
    local ok = pcall(function()
        local threshold = inst:IsA("Decal") and cfg.decalTransparency or cfg.textureTransparency
        _orig[inst] = {
            Transparency = inst.Transparency
        }
        inst.Transparency = math.max(inst.Transparency, threshold)
    end)
    if ok and _orig[inst] then
        _origTier[inst] = 4
        t.tracked[inst] = true
        return true
    end
    return false
end

TIERS[4].restore = function(t, inst)
    local o = _orig[inst]
    if not o then
        return false
    end
    pcall(function()
        inst.Transparency = o.Transparency
    end)
    t.tracked[inst] = nil
    _orig[inst] = nil
    _origTier[inst] = nil
    return true
end

TIERS[4].revert = function(t)
    local c = 0
    for inst in pairs(t.tracked) do
        if t.restore(t, inst) then
            c = c + 1
        end
    end
    return c
end

TIERS[5] = {
    tracked = setmetatable({}, weakKeys),
    check = function(inst)
        return (inst:IsA("BasePart") and not inst:IsA("MeshPart")) or inst:IsA("Explosion")
    end,
    collect = function()
        return dir():GetDescendants()
    end
}

TIERS[5].apply = function(t, inst)
    if _orig[inst] or isNever(inst) then
        return false
    end
    if inst:IsA("BasePart") and owner[inst] then
        return false
    end
    local ok = pcall(function()
        if inst:IsA("Explosion") then
            _orig[inst] = {
                BlastPressure = inst.BlastPressure,
                BlastRadius = inst.BlastRadius,
                Transparency = inst.Transparency
            }
            inst.BlastPressure = inst.BlastPressure * cfg.explosionScale
            inst.BlastRadius = inst.BlastRadius * cfg.explosionScale
            inst.Transparency = math.max(inst.Transparency, cfg.explosionTransparency)
        else
            _orig[inst] = {
                CastShadow = inst.CastShadow,
                Reflectance = inst.Reflectance
            }
            inst.CastShadow = false
            inst.Reflectance = math.min(inst.Reflectance, 0.1)
        end
    end)
    if ok and _orig[inst] then
        _origTier[inst] = 5
        t.tracked[inst] = true
        return true
    end
    return false
end

TIERS[5].restore = function(t, inst)
    local o = _orig[inst]
    if not o then
        return false
    end
    pcall(function()
        if inst:IsA("Explosion") then
            inst.BlastPressure = o.BlastPressure
            inst.BlastRadius = o.BlastRadius
            inst.Transparency = o.Transparency
        else
            inst.CastShadow = o.CastShadow
            inst.Reflectance = o.Reflectance
        end
    end)
    t.tracked[inst] = nil
    _orig[inst] = nil
    _origTier[inst] = nil
    return true
end

TIERS[5].revert = function(t)
    local c = 0
    for inst in pairs(t.tracked) do
        if t.restore(t, inst) then
            c = c + 1
        end
    end
    return c
end

TIERS[6] = {
    tracked = setmetatable({}, weakKeys),
    check = function(inst)
        return inst:IsA("Clothing") or inst:IsA("SurfaceAppearance") or inst:IsA("BaseWrap") or inst:IsA("PostEffect")
    end,
    collect = function()
        return dir():GetDescendants()
    end
}

TIERS[6].apply = function(t, inst)
    if _orig[inst] or isNever(inst) then
        return false
    end
    local ok = pcall(function()
        if inst:IsA("PostEffect") then
            _orig[inst] = {
                Enabled = inst.Enabled
            }
            inst.Enabled = false
        else
            _orig[inst] = {
                Parent = inst.Parent
            }
            inst.Parent = Debris
        end
    end)
    if ok and _orig[inst] then
        _origTier[inst] = 6
        t.tracked[inst] = true
        return true
    end
    return false
end

TIERS[6].restore = function(t, inst)
    local o = _orig[inst]
    if not o then
        return false
    end
    pcall(function()
        if o.Enabled ~= nil then
            inst.Enabled = o.Enabled
        elseif o.Parent then
            inst.Parent = o.Parent
        end
    end)
    t.tracked[inst] = nil
    _orig[inst] = nil
    _origTier[inst] = nil
    return true
end

TIERS[6].revert = function(t)
    local c = 0
    for inst in pairs(t.tracked) do
        if t.restore(t, inst) then
            c = c + 1
        end
    end
    return c
end

TIERS[7] = {
    tracked = setmetatable({}, weakKeys),
    global = true,
    conns = nil,
    check = function()
        return false
    end,
    collect = function()
        return {}
    end
}

TIERS[7].restore = function(t, inst)
    local o = _orig[inst]
    if not o then
        return false
    end
    pcall(function()
        if inst:IsA("Humanoid") then
            inst.DisplayDistanceType = o.DisplayDistanceType
        elseif inst:IsA("HumanoidDescription") then
            for _, k in ipairs(accessoryKeys) do
                inst[k] = o[k]
            end
        end
    end)
    t.tracked[inst] = nil
    _orig[inst] = nil
    _origTier[inst] = nil
    return true
end

TIERS[7].apply = function(t)
    t.conns = {}
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam and not _globalOrig.Camera then
            _globalOrig.Camera = {
                FieldOfView = cam.FieldOfView,
                FarPlane = cam.FarPlane
            }
            cam.FieldOfView = math.max(cfg.minFOV, cam.FieldOfView - cfg.fovReduction)
            cam.FarPlane = cfg.farPlaneTarget
        end
    end)
    pcall(function()
        if not _globalOrig.Rendering then
            local s = settings()
            _globalOrig.Rendering = {
                QualityLevel = s.Rendering.QualityLevel,
                MeshPartDetailLevel = s.Rendering.MeshPartDetailLevel
            }
            s.Rendering.QualityLevel = Enum.QualityLevel.Level1
            s.Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        end
    end)
    pcall(function()
        if not _globalOrig.Materials then
            _globalOrig.Materials = {
                Use2022 = MaterialService.Use2022Materials,
                list = setmetatable({}, weakKeys)
            }
            for _, m in ipairs(MaterialService:GetChildren()) do
                _globalOrig.Materials.list[m] = m.Parent
                pcall(function()
                    m.Parent = nil
                end)
            end
            MaterialService.Use2022Materials = false
        end
    end)
    local function optimizeChar(char)
        if not char then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and not _orig[hum] and not isNever(hum) then
            local ok = pcall(function()
                _orig[hum] = {
                    DisplayDistanceType = hum.DisplayDistanceType
                }
                hum.DisplayDistanceType = Enum.DisplayDistanceType.None
            end)
            if ok and _orig[hum] then
                _origTier[hum] = 7
                t.tracked[hum] = true
                _stats.instancesOpt = _stats.instancesOpt + 1
            end
        end
        local desc = char:FindFirstChildOfClass("HumanoidDescription")
        if desc and not _orig[desc] and not isNever(desc) then
            local ok = pcall(function()
                local data = {}
                for _, k in ipairs(accessoryKeys) do
                    data[k] = desc[k]
                    desc[k] = "0"
                end
                _orig[desc] = data
            end)
            if ok and _orig[desc] then
                _origTier[desc] = 7
                t.tracked[desc] = true
                _stats.instancesOpt = _stats.instancesOpt + 1
            end
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            optimizeChar(player.Character)
        end
        table.insert(t.conns, player.CharacterAdded:Connect(optimizeChar))
    end
    table.insert(t.conns, Players.PlayerAdded:Connect(function(pl)
        table.insert(t.conns, pl.CharacterAdded:Connect(optimizeChar))
        if pl.Character then
            optimizeChar(pl.Character)
        end
    end))
    return 0
end

TIERS[7].revert = function(t)
    if t.conns then
        for _, c in ipairs(t.conns) do
            pcall(c.Disconnect, c)
        end
        t.conns = nil
    end
    pcall(function()
        if _globalOrig.Camera then
            local cam = Workspace.CurrentCamera
            if cam then
                cam.FieldOfView = _globalOrig.Camera.FieldOfView
                cam.FarPlane = _globalOrig.Camera.FarPlane
            end
            _globalOrig.Camera = nil
        end
    end)
    pcall(function()
        if _globalOrig.Rendering then
            local s = settings()
            s.Rendering.QualityLevel = _globalOrig.Rendering.QualityLevel
            s.Rendering.MeshPartDetailLevel = _globalOrig.Rendering.MeshPartDetailLevel
            _globalOrig.Rendering = nil
        end
    end)
    pcall(function()
        if _globalOrig.Materials then
            MaterialService.Use2022Materials = _globalOrig.Materials.Use2022
            for m, parent in pairs(_globalOrig.Materials.list) do
                pcall(function()
                    m.Parent = parent
                end)
            end
            _globalOrig.Materials = nil
        end
    end)
    local c = 0
    for inst in pairs(t.tracked) do
        if t.restore(t, inst) then
            c = c + 1
        end
    end
    return c
end

local releaseOldInstance = function(inst)
    local idx = _origTier[inst]
    if not idx then
        return
    end
    local t = TIERS[idx]
    if t and t.restore then
        t.restore(t, inst)
    end
end

local originalProps = {
    BasePart = function(inst)
        return { inst.Transparency, inst.CastShadow, inst.Reflectance }
    end,
    MeshPart = function(inst)
        local data = { inst.Transparency, inst.CastShadow, inst.Reflectance }
        pcall(function()
            data[4] = inst.RenderFidelity
            data[5] = inst.LODX
            data[6] = inst.LODY
        end)
        return data
    end,
    ParticleEmitter = function(inst)
        return { inst.Enabled, inst.Rate, inst.Transparency }
    end,
    Beam = function(inst)
        return { inst.Enabled }
    end,
    Trail = function(inst)
        return { inst.Enabled, inst.Transparency }
    end,
    Fire = function(inst)
        return { inst.Enabled }
    end,
    Smoke = function(inst)
        return { inst.Enabled }
    end,
    Sparkles = function(inst)
        return { inst.Enabled }
    end,
    Light = function(inst)
        return { inst.Enabled, inst.Shadows }
    end,
    Decal = function(inst)
        return { inst.Transparency }
    end,
    Texture = function(inst)
        return { inst.Transparency }
    end,
    BillboardGui = function(inst)
        return { inst.Enabled }
    end,
    SurfaceGui = function(inst)
        return { inst.Enabled }
    end,
    Sound = function(inst)
        return { inst.Playing, inst.Volume }
    end
}

local function baseKey(inst)
    if not inst then
        return nil
    end
    local cn = inst.ClassName
    if cn == "MeshPart" then
        return "MeshPart"
    end
    if inst:IsA("BasePart") then
        return "BasePart"
    end
    if cn == "ParticleEmitter" then
        return "ParticleEmitter"
    end
    if cn == "Beam" then
        return "Beam"
    end
    if cn == "Trail" then
        return "Trail"
    end
    if cn == "Fire" then
        return "Fire"
    end
    if cn == "Smoke" then
        return "Smoke"
    end
    if cn == "Sparkles" then
        return "Sparkles"
    end
    if inst:IsA("Light") then
        return "Light"
    end
    if cn == "Decal" then
        return "Decal"
    end
    if cn == "Texture" then
        return "Texture"
    end
    if cn == "BillboardGui" then
        return "BillboardGui"
    end
    if cn == "SurfaceGui" then
        return "SurfaceGui"
    end
    if inst:IsA("Sound") then
        return "Sound"
    end
    return nil
end

local function captureOriginal(inst)
    local key = baseKey(inst)
    if not key then
        return nil
    end
    local fn = originalProps[key]
    if not fn then
        return nil
    end
    local ok, result = pcall(fn, inst)
    if ok and type(result) == "table" then
        return result
    end
    return nil
end

local setterFunctions = {}

setterFunctions.BasePart = function(inst, orig, mode, state)
    local t, cs, r = orig[1], orig[2], orig[3]
    local shadow = cs
    if mode == "hidden" then
        inst.Transparency = cfg.HideOffscreenParts and 1 or t
        if cfg.DisableOffscreenShadows then
            shadow = false
        end
    elseif mode == "far" then
        inst.Transparency = t
        if (cfg.DisableFarShadows and not state.important and not (cfg.KeepCenterShadows and state.centerWeight >= cfg.CenterShadowKeepThreshold)) or _tier >= 5 then
            shadow = false
        end
    else
        inst.Transparency = t
        if _tier >= 5 then
            shadow = false
        end
    end
    inst.CastShadow = shadow
    inst.Reflectance = _tier >= 5 and math.min(r, 0.1) or r
end

setterFunctions.MeshPart = function(inst, orig, mode, state)
    local t, cs, r = orig[1], orig[2], orig[3]
    local shadow = cs
    if mode == "hidden" then
        inst.Transparency = cfg.HideOffscreenParts and 1 or t
        if cfg.DisableOffscreenShadows then
            shadow = false
        end
    elseif mode == "far" then
        inst.Transparency = t
        if cfg.DisableFarShadows and not state.important and not (cfg.KeepCenterShadows and state.centerWeight >= cfg.CenterShadowKeepThreshold) then
            shadow = false
        end
    else
        inst.Transparency = t
    end
    inst.CastShadow = shadow
    inst.Reflectance = r
    if _tier >= 2 then
        pcall(function()
            inst.RenderFidelity = Enum.RenderFidelity.Performance
            inst.LODX = Enum.LevelOfDetail.Coarse
            inst.LODY = Enum.LevelOfDetail.Coarse
        end)
    elseif orig[4] ~= nil then
        pcall(function()
            inst.RenderFidelity = orig[4]
            inst.LODX = orig[5]
            inst.LODY = orig[6]
        end)
    end
end

setterFunctions.ParticleEmitter = function(inst, orig, mode, state)
    local en, rate, trans = orig[1], orig[2], orig[3]
    local enabled = en
    local r = rate
    local tr = trans
    if mode == "hidden" then
        enabled = not cfg.DisableOffscreenEffects and en or false
        r = cfg.ReduceOffscreenParticles and 0 or rate
    else
        enabled = en
        if mode == "far" and cfg.ReduceFarParticles then
            local m = cfg.FarParticleRateMultiplier
            if state.important and m < 0.85 then
                m = 0.85
            end
            r = rate * m
        end
    end
    if _tier >= 1 then
        r = r * cfg.particleScale
        tr = math.max(tr, 0.2)
    end
    inst.Enabled = enabled
    inst.Rate = r
    inst.Transparency = tr
end

setterFunctions.Trail = function(inst, orig, mode)
    local en, tr = orig[1], orig[2]
    inst.Enabled = (mode ~= "hidden" or not cfg.DisableOffscreenEffects) and en or false
    if _tier >= 1 then
        tr = math.max(tr, 0.2)
    end
    inst.Transparency = tr
end

for _, cls in ipairs({ "Beam", "Fire", "Smoke", "Sparkles" }) do
    setterFunctions[cls] = function(inst, orig, mode)
        inst.Enabled = (mode ~= "hidden" or not cfg.DisableOffscreenEffects) and orig[1] or false
    end
end

setterFunctions.Light = function(inst, orig, mode, state)
    local en, sh = orig[1], orig[2]
    local enabled = en
    if mode == "hidden" then
        enabled = not cfg.DisableOffscreenEffects and en or false
    elseif mode == "far" then
        if cfg.DisableFarLights and not state.important and not (cfg.KeepCenterLights and state.centerWeight >= cfg.CenterLightKeepThreshold) then
            enabled = false
        end
    end
    inst.Enabled = enabled
    inst.Shadows = _tier >= 3 and false or sh
end

setterFunctions.Decal = function(inst, orig, mode, state)
    local tr = orig[1]
    local v = tr
    if mode == "hidden" then
        if cfg.HideOffscreenDecals then
            v = 1
        end
    elseif mode == "far" then
        if cfg.DisableFarDecals and not state.important and not (cfg.KeepCenterDecals and state.centerWeight >= cfg.CenterDecalKeepThreshold) then
            v = 1
        end
    end
    if _tier >= 4 then
        v = math.max(v, cfg.decalTransparency)
    end
    inst.Transparency = v
end

setterFunctions.Texture = function(inst, orig, mode, state)
    local tr = orig[1]
    local v = tr
    if cfg.OptimizeTextures then
        if mode == "hidden" then
            if cfg.HideOffscreenDecals then
                v = 1
            end
        elseif mode == "far" then
            if cfg.DisableFarDecals and not state.important and not (cfg.KeepCenterDecals and state.centerWeight >= cfg.CenterDecalKeepThreshold) then
                v = 1
            end
        end
    end
    if _tier >= 4 then
        v = math.max(v, cfg.textureTransparency)
    end
    inst.Transparency = v
end

local function guiSetter(inst, orig, mode)
    local en = orig[1]
    if not cfg.OptimizeWorldUI then
        inst.Enabled = en
        return
    end
    if mode == "hidden" then
        inst.Enabled = cfg.DisableOffscreenWorldUI and false or en
    elseif mode == "far" then
        inst.Enabled = cfg.DisableFarWorldUI and false or en
    else
        inst.Enabled = en
    end
end

setterFunctions.BillboardGui = guiSetter
setterFunctions.SurfaceGui = guiSetter

setterFunctions.Sound = function(inst, orig, mode, state)
    local pl, vol = orig[1], orig[2]
    local playing = pl
    if mode == "hidden" then
        if cfg.DisableOffscreenSounds then
            playing = false
        end
    elseif mode == "far" then
        if cfg.PauseFarSounds and not state.important then
            playing = false
        end
    end
    inst.Playing = playing
    inst.Volume = _tier >= 3 and vol * cfg.soundVolumeReduction or vol
end

local restoreFunctions = {}

restoreFunctions.BasePart = function(inst, o)
    inst.Transparency = o[1]
    inst.CastShadow = o[2]
    inst.Reflectance = o[3]
end

restoreFunctions.MeshPart = function(inst, o)
    inst.Transparency = o[1]
    inst.CastShadow = o[2]
    inst.Reflectance = o[3]
    if o[4] ~= nil then
        pcall(function()
            inst.RenderFidelity = o[4]
            inst.LODX = o[5]
            inst.LODY = o[6]
        end)
    end
end

restoreFunctions.ParticleEmitter = function(inst, o)
    inst.Enabled = o[1]
    inst.Rate = o[2]
    inst.Transparency = o[3]
end

restoreFunctions.Trail = function(inst, o)
    inst.Enabled = o[1]
    inst.Transparency = o[2]
end

for _, cls in ipairs({ "Beam", "Fire", "Smoke", "Sparkles" }) do
    restoreFunctions[cls] = function(inst, o)
        inst.Enabled = o[1]
    end
end

restoreFunctions.Light = function(inst, o)
    inst.Enabled = o[1]
    inst.Shadows = o[2]
end

restoreFunctions.Decal = function(inst, o)
    inst.Transparency = o[1]
end

restoreFunctions.Texture = function(inst, o)
    inst.Transparency = o[1]
end

restoreFunctions.BillboardGui = function(inst, o)
    inst.Enabled = o[1]
end

restoreFunctions.SurfaceGui = function(inst, o)
    inst.Enabled = o[1]
end

restoreFunctions.Sound = function(inst, o)
    inst.Playing = o[1]
    inst.Volume = o[2]
end

local function restoreOriginal(inst, orig)
    if not inst or not inst.Parent then
        return
    end
    local key = baseKey(inst)
    local fn = key and restoreFunctions[key]
    if not fn then
        return
    end
    local ok = pcall(fn, inst, orig)
    if not ok then
        _stats.errorsCaught = _stats.errorsCaught + 1
    end
end

local function setInstanceMode(state, inst, mode)
    if not inst.Parent then
        return
    end
    local orig = state.originals[inst]
    if not orig and (mode ~= "near" or _tier > 0) then
        orig = captureOriginal(inst)
        if orig then
            state.originals[inst] = orig
        end
    end
    if not orig then
        return
    end
    local key = baseKey(inst)
    if not key then
        return
    end
    local fn = setterFunctions[key]
    if fn then
        local ok = pcall(fn, inst, orig, mode, state)
        if not ok then
            _stats.errorsCaught = _stats.errorsCaught + 1
        end
    end
end

local function ensureOriginals(state)
    for inst in pairs(state.scanned) do
        if not state.originals[inst] then
            local orig = captureOriginal(inst)
            if orig then
                state.originals[inst] = orig
            end
        end
    end
end

local function applyMode(state, mode, force)
    if not state then
        return
    end
    if not force and state.mode == mode then
        return
    end
    state.mode = mode
    if mode ~= "near" or _tier > 0 then
        ensureOriginals(state)
    end
    for inst in pairs(state.originals) do
        setInstanceMode(state, inst, mode)
    end
    if mode == "near" and _tier == 0 then
        tableClear(state.originals)
    end
end

local function scanInstance(state, inst)
    if state.scanned[inst] then
        return
    end
    if isNever(inst) or shouldSkipHumanoid(inst) then
        return
    end
    state.scanned[inst] = true
    if baseKey(inst) then
        owner[inst] = state.root
        releaseOldInstance(inst)
        if state.mode ~= "near" or _tier > 0 then
            local orig = captureOriginal(inst)
            if orig then
                state.originals[inst] = orig
                setInstanceMode(state, inst, state.mode)
            end
        end
    end
end

local function scanTree(state, inst)
    if not inst.Parent then
        return
    end
    if isNever(inst) or shouldSkipHumanoid(inst) then
        return
    end
    scanInstance(state, inst)
    local children = inst:GetChildren()
    for i = 1, #children do
        scanTree(state, children[i])
    end
end

local function connectInstance(inst, signal, fn)
    if not inst or not signal then
        return nil
    end
    local c = signal:Connect(fn)
    local t = instanceConnections[inst]
    if not t then
        t = {}
        instanceConnections[inst] = t
    end
    t[#t + 1] = c
    return c
end

local function disconnectInstance(inst)
    local conns = instanceConnections[inst]
    if conns then
        for i = 1, #conns do
            pcall(conns[i].Disconnect, conns[i])
        end
        instanceConnections[inst] = nil
    end
end

local function removeRoot(root, restore)
    local state = states[root]
    if state then
        if restore then
            for inst, orig in pairs(state.originals) do
                restoreOriginal(inst, orig)
            end
        end
        for inst in pairs(state.scanned) do
            owner[inst] = nil
        end
    end
    disconnectInstance(root)
    processed[root] = nil
    states[root] = nil
end

local function getBBox(root, state)
    local now = tick()
    if state.lastBBoxTime and (now - state.lastBBoxTime) < cfg.BBoxCacheTime then
        return state.cachedBBoxPos, state.cachedBBoxRadius
    end
    local pos, radius
    local ok, cf, size = pcall(function()
        if root:IsA("Model") then
            return root:GetBoundingBox()
        elseif root:IsA("BasePart") then
            return root.CFrame, root.Size
        end
    end)
    if ok and cf and size and size.Magnitude > 0 then
        pos = cf.Position
        radius = size.Magnitude * 0.5
    end
    if pos then
        state.lastBBoxTime = now
        state.cachedBBoxPos = pos
        state.cachedBBoxRadius = radius
        return pos, radius
    end
    return nil
end

local function evaluateVisibility(camera, pos, radius)
    local camCf = camera.CFrame
    local dx, dy, dz = pos.X - camCf.X, pos.Y - camCf.Y, pos.Z - camCf.Z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local maxVis = cfg.MaxVisibleDistance
    if dist > maxVis + radius then
        return false, dist, 0
    end
    if not cfg.UseFrustumCulling then
        return true, dist, 0.5
    end
    local relX = dx * camCf.RightVector.X + dy * camCf.RightVector.Y + dz * camCf.RightVector.Z
    local relY = dx * camCf.UpVector.X + dy * camCf.UpVector.Y + dz * camCf.UpVector.Z
    local depth = -(dx * camCf.LookVector.X + dy * camCf.LookVector.Y + dz * camCf.LookVector.Z)
    if depth <= 0 then
        return dist <= radius + 5, dist, 0
    end
    local vFov = math.rad(math.max(camera.FieldOfView, 1))
    local vp = camera.ViewportSize
    local aspect = vp.X / math.max(vp.Y, 1)
    local hFov = 2 * atan2(math.tan(vFov / 2) * aspect, 1)
    local margin = math.rad(cfg.FovMarginDeg)
    local angularRadius = atan2(radius, depth)
    local halfV = vFov / 2 + margin + angularRadius
    local halfH = hFov / 2 + margin + angularRadius
    local angleV = math.abs(atan2(relY, depth))
    local angleH = math.abs(atan2(relX, depth))
    local visible = angleV <= halfV and angleH <= halfH
    local edge = math.max(angleV / halfV, angleH / halfH)
    if edge > 1 then
        edge = 1
    end
    return visible, dist, 1 - edge
end

local function chooseMode(state, visible, dist, centerWeight, now)
    if visible then
        state.lastVisible = now
    end
    local hiddenDelay = state.important and cfg.HighImportanceHiddenDelay or cfg.HiddenDelay
    local farEnter = cfg.FarDistance
    if state.important then
        farEnter = farEnter * cfg.HighImportanceMultiplier
    end
    farEnter = farEnter * (1 + cfg.CenterViewBoost * centerWeight)
    local farExit = farEnter * cfg.FarExitRatio
    if not visible then
        if now - (state.lastVisible or 0) >= hiddenDelay then
            state.farTime = nil
            return "hidden"
        end
        return state.mode
    end
    if state.mode == "hidden" then
        state.farTime = nil
        if dist > farEnter then
            state.farTime = now
        end
        return "near"
    end
    if not cfg.UseDistanceQuality then
        return "near"
    end
    if dist > farEnter then
        state.farTime = state.farTime or now
        if now - state.farTime >= cfg.FarDelay then
            return "far"
        end
        return state.mode == "far" and "far" or "near"
    elseif dist < farExit then
        state.farTime = nil
        return "near"
    else
        return state.mode == "far" and "far" or "near"
    end
end

local function register(root)
    if processed[root] then
        return
    end
    if not (root:IsA("Model") or root:IsA("BasePart")) then
        return
    end
    if isNever(root) or shouldSkipHumanoid(root) then
        return
    end
    processed[root] = true
    local state = {
        root = root,
        originals = setmetatable({}, weakKeys),
        scanned = setmetatable({}, weakKeys),
        mode = "near",
        lastVisible = 0,
        farTime = nil,
        dist = 0,
        centerWeight = 0,
        important = hasTagSafe(root, TAG_HIGH),
        lastBBoxTime = nil,
        cachedBBoxPos = nil,
        cachedBBoxRadius = nil
    }
    states[root] = state
    scanTree(state, root)
    connectInstance(root, root.Destroying, function()
        removeRoot(root, false)
    end)
    connectInstance(root, root.AncestryChanged, function(_, parent)
        if not parent then
            removeRoot(root, true)
        else
            state.lastBBoxTime = nil
        end
    end)
    connectInstance(root, root.DescendantAdded, function(inst)
        scanTree(state, inst)
    end)
    connectInstance(root, root.DescendantRemoving, function(inst)
        local orig = state.originals[inst]
        if orig then
            restoreOriginal(inst, orig)
        end
        state.originals[inst] = nil
        state.scanned[inst] = nil
        owner[inst] = nil
    end)
    debugPrint("Registered " .. root:GetFullName())
end

local function removeHandled(inst)
    disconnectInstance(inst)
    handled[inst] = nil
end

local function processMap(mapModel)
    if handled[mapModel] then
        return
    end
    handled[mapModel] = true
    connectInstance(mapModel, mapModel.Destroying, function()
        removeHandled(mapModel)
    end)
    connectInstance(mapModel, mapModel.AncestryChanged, function(_, parent)
        if not parent then
            removeHandled(mapModel)
        end
    end)
    if cfg.OptimizeWholeMap then
        register(mapModel)
        debugPrint("Whole map registered " .. mapModel:GetFullName())
        return
    end
    local function handleChild(child)
        if not child then
            return
        end
        if setHas(mapNeverSet, child.Name) or isNever(child) then
            return
        end
        if setHas(mapSmartSet, child.Name) then
            register(child)
        end
    end
    for _, child in ipairs(mapModel:GetChildren()) do
        handleChild(child)
    end
    connectInstance(mapModel, mapModel.ChildAdded, handleChild)
    debugPrint("Map processed " .. mapModel:GetFullName())
end

local function processMapRoot(mapRoot)
    if handled[mapRoot] then
        return
    end
    handled[mapRoot] = true
    connectInstance(mapRoot, mapRoot.Destroying, function()
        removeHandled(mapRoot)
    end)
    connectInstance(mapRoot, mapRoot.AncestryChanged, function(_, parent)
        if not parent then
            removeHandled(mapRoot)
        end
    end)
    local function tryMap(obj)
        if obj and nameMatches(obj.Name, cfg.MapContentModelName) and (obj:IsA("Model") or obj:IsA("Folder")) then
            processMap(obj)
        end
    end
    for _, child in ipairs(mapRoot:GetChildren()) do
        tryMap(child)
    end
    connectInstance(mapRoot, mapRoot.ChildAdded, tryMap)
    debugPrint("Map root processed " .. mapRoot:GetFullName())
end

local function processMapsFolder(folder)
    if handled[folder] then
        return
    end
    handled[folder] = true
    connectInstance(folder, folder.Destroying, function()
        removeHandled(folder)
    end)
    connectInstance(folder, folder.AncestryChanged, function(_, parent)
        if not parent then
            removeHandled(folder)
        end
    end)
    local function tryMapRoot(obj)
        if obj and (obj:IsA("Model") or obj:IsA("Folder")) then
            processMapRoot(obj)
        end
    end
    for _, child in ipairs(folder:GetChildren()) do
        tryMapRoot(child)
    end
    connectInstance(folder, folder.ChildAdded, tryMapRoot)
    debugPrint("Maps folder processed " .. folder:GetFullName())
end

local function processExistingMaps()
    local folder = Workspace:FindFirstChild(cfg.MapsFolder) or Workspace:FindFirstChild(trim(cfg.MapsFolder))
    if folder and (folder:IsA("Model") or folder:IsA("Folder")) then
        processMapsFolder(folder)
    end
end

local function connectGlobal(signal, fn)
    if not signal then
        return nil
    end
    local c = signal:Connect(fn)
    globalConnections[#globalConnections + 1] = c
    return c
end

local function clearMapStates(restore)
    for root, state in pairs(states) do
        if restore then
            for inst, orig in pairs(state.originals) do
                restoreOriginal(inst, orig)
            end
        end
        for inst in pairs(state.scanned) do
            owner[inst] = nil
        end
        disconnectInstance(root)
    end
    tableClear(states)
    tableClear(processed)
    tableClear(handled)
    for inst, conns in pairs(instanceConnections) do
        for i = 1, #conns do
            pcall(conns[i].Disconnect, conns[i])
        end
        instanceConnections[inst] = nil
    end
end

local function restartMapInternal()
    clearMapStates(true)
    processExistingMaps()
    flags.dirty = false
end

local function heartbeatUpdate()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local now = tick()
    local removeList
    for root, state in pairs(states) do
        if not root.Parent then
            removeList = removeList or {}
            removeList[#removeList + 1] = root
        else
            local pos, radius = getBBox(root, state)
            if pos then
                local visible, dist, centerWeight = evaluateVisibility(camera, pos, radius)
                state.dist = dist
                state.centerWeight = centerWeight
                local mode = chooseMode(state, visible, dist, centerWeight, now)
                applyMode(state, mode)
            end
        end
    end
    if removeList then
        for i = 1, #removeList do
            removeRoot(removeList[i], true)
        end
    end
end

local function startMap()
    if mapRunning then
        return
    end
    mapRunning = true
    local updateAcc = 0
    connectGlobal(RunService.Heartbeat, function(dt)
        if not mapRunning then
            return
        end
        updateAcc = updateAcc + dt
        if updateAcc < cfg.UpdateInterval then
            return
        end
        updateAcc = 0
        if flags.restart then
            flags.restart = false
            restartMapInternal()
            return
        end
        if flags.dirty then
            flags.dirty = false
            for _, state in pairs(states) do
                applyMode(state, state.mode, true)
            end
        end
        heartbeatUpdate()
    end)
    connectGlobal(Workspace.ChildAdded, function(child)
        if nameMatches(child.Name, cfg.MapsFolder) and (child:IsA("Model") or child:IsA("Folder")) then
            processMapsFolder(child)
        end
    end)
    processExistingMaps()
    shared.SmartMapOptimizerRunning = true
    debugPrint("Map optimizer started")
end

local function stopMap(restore)
    if not mapRunning then
        return
    end
    mapRunning = false
    clearMapStates(restore ~= false)
    for _, c in ipairs(globalConnections) do
        pcall(c.Disconnect, c)
    end
    tableClear(globalConnections)
    shared.SmartMapOptimizerRunning = nil
    debugPrint("Map optimizer stopped")
end

local function requestMapRestart()
    if mapRunning then
        flags.restart = true
    end
end

local function notify(n, d)
    if type(cfg.onTierChange) == "function" then
        pcall(cfg.onTierChange, n, d)
    end
end

local function setTier(n)
    n = clamp(math.floor(n), 0, cfg.maxTier)
    if n == _tier then
        return
    end
    local old = _tier
    _tier = n
    if n > old then
        local t0 = os.clock()
        for i = old + 1, n do
            local t = TIERS[i]
            if t then
                local count = 0
                if t.global then
                    count = t.apply(t) or 0
                else
                    local instances = t.collect()
                    for _, inst in ipairs(instances) do
                        if t.check(inst) and t.apply(t, inst) then
                            count = count + 1
                        end
                    end
                end
                _stats.instancesOpt = _stats.instancesOpt + count
                notify(i, "up")
            end
        end
        _stats.tierChanges = _stats.tierChanges + 1
        _stats.lastApplyTime = os.clock() - t0
        _stats.totalApplyTime = _stats.totalApplyTime + _stats.lastApplyTime
    else
        local t0 = os.clock()
        for i = old, n + 1, -1 do
            local t = TIERS[i]
            if t and t.revert then
                local count = t.revert(t) or 0
                _stats.instancesRevert = _stats.instancesRevert + count
                notify(i - 1, "down")
            end
        end
        _stats.tierChanges = _stats.tierChanges + 1
        _stats.lastRevertTime = os.clock() - t0
        _stats.totalRevertTime = _stats.totalRevertTime + _stats.lastRevertTime
    end
    if mapRunning then
        flags.dirty = true
    end
end

local function refreshTiers()
    local current = _tier
    if current > 0 then
        setTier(0)
        setTier(current)
    end
end

local function onAdded(inst)
    if not _running then
        return
    end
    for i = 1, _tier do
        local t = TIERS[i]
        if t and not t.global and t.check(inst) then
            if t.apply(t, inst) then
                _stats.instancesOpt = _stats.instancesOpt + 1
            end
        end
    end
end

local function connectDirectoryAdded()
    if _events.Added then
        pcall(_events.Added.Disconnect, _events.Added)
        _events.Added = nil
    end
    _events.Added = dir().DescendantAdded:Connect(onAdded)
end

local function bufInsert(val)
    if _fpsBufCount < _fpsBufSize then
        _fpsBufCount = _fpsBufCount + 1
    end
    _fpsBuf[_fpsBufHead] = val
    _fpsBufHead = (_fpsBufHead % _fpsBufSize) + 1
end

local function bufAverage()
    if _fpsBufCount == 0 then
        return 0
    end
    local sum = 0
    local start = (_fpsBufHead - _fpsBufCount - 1 + _fpsBufSize) % _fpsBufSize + 1
    for i = 0, _fpsBufCount - 1 do
        local idx = (start + i - 1) % _fpsBufSize + 1
        sum = sum + _fpsBuf[idx]
    end
    return sum / _fpsBufCount
end

local function bufClear()
    _fpsBuf = {}
    _fpsBufHead = 1
    _fpsBufCount = 0
    _fpsAvg = 0
end

function OPT.Enable()
    if _running then
        return
    end
    _running = true
    _lastSample = tick()
    _stats.tierChanges = 0
    _stats.instancesOpt = 0
    _stats.instancesRevert = 0
    _stats.lastApplyTime = 0
    _stats.lastRevertTime = 0
    _stats.totalApplyTime = 0
    _stats.totalRevertTime = 0
    _stats.errorsCaught = 0
    connectDirectoryAdded()
    local frameSignal = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat
    _events.Stepped = frameSignal:Connect(function(dt)
        if dt <= 0 then
            return
        end
        bufInsert(1 / dt)
        local now = tick()
        if now - _lastSample < cfg.sampleInterval then
            return
        end
        _lastSample = now
        _fpsAvg = bufAverage()
        if _fpsAvg < cfg.targetFPS then
            _downCount = 0
            _upCount = _upCount + 1
            if _upCount >= cfg.confirmSamples and _tier < cfg.maxTier then
                _upCount = 0
                setTier(_tier + 1)
            end
        elseif _fpsAvg > cfg.targetFPS + cfg.recoverMargin then
            _upCount = 0
            _downCount = _downCount + 1
            if _downCount >= cfg.confirmSamples and _tier > 0 then
                _downCount = 0
                setTier(_tier - 1)
            end
        else
            _upCount = 0
            _downCount = 0
        end
    end)
end

function OPT.Disable()
    if not _running then
        return
    end
    _running = false
    for _, c in pairs(_events) do
        pcall(c.Disconnect, c)
    end
    _events = {}
    setTier(0)
    _upCount = 0
    _downCount = 0
    bufClear()
end

function OPT.Toggle()
    if _running then
        OPT.Disable()
        return false
    end
    OPT.Enable()
    return true
end

function OPT.IsRunning()
    return _running
end

function OPT.GetTier()
    return _tier
end

function OPT.GetFPS()
    return _fpsAvg
end

function OPT.GetStats()
    return {
        tierChanges = _stats.tierChanges,
        instancesOpt = _stats.instancesOpt,
        instancesRevert = _stats.instancesRevert,
        lastApplyTime = _stats.lastApplyTime,
        lastRevertTime = _stats.lastRevertTime,
        totalApplyTime = _stats.totalApplyTime,
        totalRevertTime = _stats.totalRevertTime,
        errorsCaught = _stats.errorsCaught,
        currentTier = _tier,
        fpsAvg = _fpsAvg,
        isRunning = _running,
        mapRunning = mapRunning
    }
end

function OPT.GetConfig()
    local copy = {}
    for k, v in pairs(cfg) do
        if type(v) == "table" then
            local t = {}
            for i, x in pairs(v) do
                t[i] = x
            end
            copy[k] = t
        else
            copy[k] = v
        end
    end
    return copy
end

function OPT.SetTier(n)
    setTier(n)
end

function OPT.OverrideTier(tierIdx, tierDef)
    if type(tierIdx) ~= "number" or tierIdx < 1 or tierIdx > cfg.maxTier then
        return false, "invalid tier index"
    end
    if type(tierDef) ~= "table" then
        return false, "tierDef must be a table"
    end
    local t = TIERS[tierIdx] or { tracked = setmetatable({}, weakKeys) }
    if tierDef.check ~= nil then
        t.check = tierDef.check
    end
    if tierDef.collect ~= nil then
        t.collect = tierDef.collect
    end
    if tierDef.apply ~= nil then
        t.apply = tierDef.apply
    end
    if tierDef.restore ~= nil then
        t.restore = tierDef.restore
    end
    if tierDef.revert ~= nil then
        t.revert = tierDef.revert
    end
    if tierDef.global ~= nil then
        t.global = tierDef.global
    end
    if t.tracked == nil then
        t.tracked = setmetatable({}, weakKeys)
    end
    TIERS[tierIdx] = t
    return true
end

function OPT.GetTiers()
    return TIERS
end

local _ctr = {
    gui = nil,
    conns = {}
}

local _cc = {
    muted = "rgb(90,90,90)",
    good = "rgb(34,197,94)",
    warn = "rgb(245,158,11)",
    bad = "rgb(239,68,68)"
}

local function ctrEnable()
    if _ctr.gui then
        return
    end
    local lp = Players.LocalPlayer
    if not lp then
        return
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "OPT_Counter"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local win = Instance.new("Frame")
    win.Name = "Win"
    win.Size = UDim2.new(0, 94, 0, 30)
    win.Position = UDim2.new(0, 14, 0, 14)
    win.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
    win.BackgroundTransparency = 0.04
    win.BorderSizePixel = 0
    win.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = win
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(192, 192, 192)
    stroke.Transparency = 0.88
    stroke.Thickness = 1
    stroke.Parent = win
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = win
    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.RichText = true
    lbl.Text = '<font color="' .. _cc.muted .. '">FPS</font> <font color="' .. _cc.muted .. '">--</font>'
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = win
    gui.Parent = lp:WaitForChild("PlayerGui")
    local dragging, ds, sp = false, nil, nil
    win.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            ds = inp.Position
            sp = win.Position
        end
    end)
    win.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(_ctr.conns, UserInputService.InputChanged:Connect(function(inp)
        if not dragging then
            return
        end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local d = inp.Position - ds
        win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end))
    local fps = 0
    table.insert(_ctr.conns, RunService.RenderStepped:Connect(function(dt)
        if dt <= 0 then
            return
        end
        fps = fps * 0.85 + (1 / dt) * 0.15
        local v = math.floor(fps + 0.5)
        local col = v >= 50 and _cc.good or v >= 30 and _cc.warn or _cc.bad
        lbl.Text = '<font color="' .. _cc.muted .. '">FPS</font> <b><font color="' .. col .. '">' .. v .. '</font></b>'
    end))
    _ctr.gui = gui
end

local function ctrDisable()
    if not _ctr.gui then
        return
    end
    for _, c in ipairs(_ctr.conns) do
        pcall(c.Disconnect, c)
    end
    _ctr.conns = {}
    if _ctr.gui then
        _ctr.gui:Destroy()
    end
    _ctr.gui = nil
end

function OPT.Counter(action)
    if action == "enable" then
        ctrEnable()
    elseif action == "disable" then
        ctrDisable()
    end
end

local mapRestartKeys = {
    MapsFolder = true,
    MapContentModelName = true,
    OptimizeWholeMap = true,
    MapSmartMapChildren = true,
    MapNeverMapChildren = true,
    NeverNames = true,
    NeverClasses = true,
    SkipHumanoids = true
}

local cullDirtyKeys = {
    UseFrustumCulling = true,
    UseDistanceQuality = true,
    MaxVisibleDistance = true,
    FarDistance = true,
    FovMarginDeg = true,
    HiddenDelay = true,
    FarDelay = true,
    FarExitRatio = true,
    CenterViewBoost = true,
    HighImportanceMultiplier = true,
    HighImportanceHiddenDelay = true,
    HideOffscreenParts = true,
    DisableOffscreenEffects = true,
    ReduceOffscreenParticles = true,
    DisableOffscreenSounds = true,
    DisableOffscreenShadows = true,
    HideOffscreenDecals = true,
    OptimizeTextures = true,
    OptimizeWorldUI = true,
    DisableOffscreenWorldUI = true,
    DisableFarShadows = true,
    DisableFarLights = true,
    ReduceFarParticles = true,
    FarParticleRateMultiplier = true,
    DisableFarDecals = true,
    DisableFarWorldUI = true,
    PauseFarSounds = true,
    KeepCenterShadows = true,
    CenterShadowKeepThreshold = true,
    KeepCenterLights = true,
    CenterLightKeepThreshold = true,
    KeepCenterDecals = true,
    CenterDecalKeepThreshold = true
}

local adaptiveRefreshKeys = {
    particleScale = true,
    decalTransparency = true,
    textureTransparency = true,
    soundVolumeReduction = true,
    explosionScale = true,
    explosionTransparency = true,
    fovReduction = true,
    farPlaneTarget = true,
    minFOV = true
}

function OPT.Set(k, v)
    if k == "tier" then
        if type(v) ~= "number" then
            return false, "invalid type"
        end
        setTier(v)
        return true
    end
    if cfg[k] == nil then
        return false, "invalid key: " .. tostring(k)
    end
    if type(v) == "number" and v ~= v then
        return false, "invalid number"
    end
    if v ~= nil and cfg[k] ~= nil and type(cfg[k]) ~= type(v) then
        return false, "invalid type"
    end
    cfg[k] = v
    if k == "directory" then
        if _running then
            connectDirectoryAdded()
        end
        if _tier > 0 then
            refreshTiers()
        end
    elseif k == "maxTier" then
        setTier(_tier)
    elseif adaptiveRefreshKeys[k] and _tier > 0 then
        refreshTiers()
    end
    if mapRestartKeys[k] then
        if k == "NeverNames" or k == "NeverClasses" or k == "MapNeverMapChildren" or k == "MapSmartMapChildren" then
            rebuildSets()
        end
        requestMapRestart()
    elseif cullDirtyKeys[k] then
        flags.dirty = true
    end
    return true
end

function OPT.Get(k)
    if k == "tier" then
        return _tier
    end
    return cfg[k]
end

function OPT.Init(input)
    if _running then
        return false, "already running"
    end
    if type(input) ~= "table" then
        return false, "invalid config"
    end
    for k in pairs(input) do
        if cfg[k] == nil and k ~= "tier" then
            return false, "invalid key: " .. tostring(k)
        end
    end
    for k, v in pairs(input) do
        OPT.Set(k, v)
    end
    return true
end

function OPT.StartMap()
    startMap()
end

function OPT.StopMap()
    stopMap(true)
end

function OPT.RestartMap()
    if mapRunning then
        flags.restart = true
    else
        startMap()
    end
end

local function restoreGlobalUnconditional()
    pcall(function()
        if _globalOrig.Camera then
            local cam = Workspace.CurrentCamera
            if cam then
                cam.FieldOfView = _globalOrig.Camera.FieldOfView
                cam.FarPlane = _globalOrig.Camera.FarPlane
            end
        end
    end)
    pcall(function()
        if _globalOrig.Rendering then
            local s = settings()
            s.Rendering.QualityLevel = _globalOrig.Rendering.QualityLevel
            s.Rendering.MeshPartDetailLevel = _globalOrig.Rendering.MeshPartDetailLevel
        end
    end)
    pcall(function()
        if _globalOrig.Materials then
            MaterialService.Use2022Materials = _globalOrig.Materials.Use2022
            for m, parent in pairs(_globalOrig.Materials.list) do
                pcall(function()
                    m.Parent = parent
                end)
            end
        end
    end)
    _globalOrig = {}
end

local function purgeTracked()
    for i = 1, cfg.maxTier do
        local t = TIERS[i]
        if t and t.tracked then
            for inst in pairs(t.tracked) do
                if t.restore then
                    pcall(t.restore, t, inst)
                end
            end
            t.tracked = setmetatable({}, weakKeys)
        end
    end
    _orig = setmetatable({}, weakKeys)
    _origTier = setmetatable({}, weakKeys)
end

local function hardReset()
    OPT.Disable()
    stopMap(true)
    ctrDisable()
    setTier(0)
    purgeTracked()
    restoreGlobalUnconditional()
    bufClear()
    _upCount = 0
    _downCount = 0
    shared.SmartMapOptimizerRunning = nil
end

OPT.HardReset = hardReset

local function stopAll()
    OPT.Disable()
    stopMap(true)
    OPT.Counter("disable")
    shared.SmartMapOptimizerRunning = nil
    shared.SmartMapOptimizer = nil
end

OPT.Stop = stopAll
OPT.StopAll = stopAll
OPT.Settings = cfg
OPT.States = states

pcall(startMap)

shared.SmartMapOptimizerRunning = true
shared.SmartMapOptimizer = {
    Stop = stopAll,
    StopAll = stopAll,
    StopMap = stopMap,
    Settings = cfg,
    States = states,
    Optimizer = OPT
}

return OPT