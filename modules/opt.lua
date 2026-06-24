local OPT = {}

-- ═══════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════
local CONFIG = {
    targetFPS             = 60,
    recoverMargin         = 10,
    sampleInterval        = 1,
    confirmSamples        = 3,
    particleScale         = 0.6,
    fovReduction          = 8,
    farPlaneTarget        = 350,
    maxTier               = 7,
    minFOV                = 50,
    decalTransparency     = 0.5,
    textureTransparency   = 0.5,
    soundVolumeReduction  = 0.5,
    explosionScale        = 0.5,
    explosionTransparency = 0.5,
    directory             = nil,
    onTierChange          = nil,
}

-- ═══════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════
local _running = false
local _tier    = 0
local _orig    = {}
local _events  = {}

-- Circular buffer for FPS samples (ring buffer — O(1) insert/remove)
local _fpsBuf      = {}
local _fpsBufSize  = 60
local _fpsBufHead  = 1
local _fpsBufCount = 0
local _fpsAvg      = 0
local _lastSample  = 0
local _upCount     = 0
local _downCount   = 0

-- ═══════════════════════════════════════════════════════════
-- STATS — public via OPT.GetStats()
-- ═══════════════════════════════════════════════════════════
local _stats = {
    tierChanges    = 0,
    instancesOpt   = 0,
    instancesRevert = 0,
    lastApplyTime  = 0,
    lastRevertTime = 0,
    totalApplyTime = 0,
    totalRevertTime = 0,
    errorsCaught   = 0,
}

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local Workspace       = game:GetService("Workspace")
local MaterialService = game:GetService("MaterialService")
local Debris          = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local function dir()
    return CONFIG.directory or Workspace
end

-- ═══════════════════════════════════════════════════════════
-- CIRCULAR BUFFER HELPERS
-- ═══════════════════════════════════════════════════════════
local function bufInsert(val)
    if _fpsBufCount < _fpsBufSize then
        _fpsBufCount = _fpsBufCount + 1
    end
    _fpsBuf[_fpsBufHead] = val
    _fpsBufHead = (_fpsBufHead % _fpsBufSize) + 1
end

local function bufAverage()
    if _fpsBufCount == 0 then return 0 end
    local sum = 0
    -- Iterate from oldest to newest
    local start = (_fpsBufHead - _fpsBufCount - 1 + _fpsBufSize) % _fpsBufSize + 1
    for i = 0, _fpsBufCount - 1 do
        local idx = (start + i - 1) % _fpsBufSize + 1
        sum = sum + _fpsBuf[idx]
    end
    return sum / _fpsBufCount
end

local function bufClear()
    _fpsBuf      = {}
    _fpsBufHead  = 1
    _fpsBufCount = 0
    _fpsAvg      = 0
end

-- ═══════════════════════════════════════════════════════════
-- pcall-safe apply/revert wrappers
-- ═══════════════════════════════════════════════════════════
local function safeApply(tier, inst)
    local ok, err = pcall(function()
        if inst then
            tier.apply(tier, inst)
        else
            tier.apply(tier)
        end
    end)
    if not ok then
        _stats.errorsCaught = _stats.errorsCaught + 1
        -- Silently skip destroyed/invalid instances
    end
    return ok
end

local function safeRevert(tier)
    local ok, err = pcall(function()
        tier.revert(tier)
    end)
    if not ok then
        _stats.errorsCaught = _stats.errorsCaught + 1
    end
    return ok
end

-- ═══════════════════════════════════════════════════════════
-- TIERS
-- ═══════════════════════════════════════════════════════════
local TIERS = {
    -- Tier 1: menos agresivo — partículas y trails
    [1] = {
        tracked = {},
        check   = function(i) return i:IsA("ParticleEmitter") or i:IsA("Trail") end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            local e = {Transparency = i.Transparency}
            if i:IsA("ParticleEmitter") then
                e.Rate = i.Rate
                i.Rate = i.Rate * CONFIG.particleScale
            end
            i.Transparency = math.max(i.Transparency, 0.2)
            _orig[i] = e
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    i.Transparency = o.Transparency
                    if o.Rate then i.Rate = o.Rate end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 2: meshes y decals de personaje
    [2] = {
        tracked = {},
        check   = function(i)
            return i:IsA("MeshPart") or i:IsA("FaceInstance") or i:IsA("ShirtGraphic")
        end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            if i:IsA("MeshPart") then
                _orig[i] = {RenderFidelity = i.RenderFidelity, LODX = i.LODX, LODY = i.LODY}
                i.RenderFidelity = Enum.RenderFidelity.Performance
                i.LODX = Enum.LevelOfDetail.Coarse
                i.LODY = Enum.LevelOfDetail.Coarse
            else
                _orig[i] = {Transparency = i.Transparency}
                i.Transparency = math.max(i.Transparency, 0.2)
            end
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("MeshPart") then
                        i.RenderFidelity = o.RenderFidelity
                        i.LODX = o.LODX
                        i.LODY = o.LODY
                    else
                        i.Transparency = o.Transparency
                    end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 3: luces y sonidos
    [3] = {
        tracked = {},
        check   = function(i) return i:IsA("Light") or i:IsA("Sound") end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            if i:IsA("Light") then
                _orig[i] = {Shadows = i.Shadows}
                i.Shadows = false
            else
                _orig[i] = {Volume = i.Volume}
                i.Volume = i.Volume * CONFIG.soundVolumeReduction
            end
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("Light") then i.Shadows = o.Shadows
                    else i.Volume = o.Volume end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 4: decals y texturas
    [4] = {
        tracked = {},
        check   = function(i) return i:IsA("Decal") or i:IsA("Texture") end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            local threshold = i:IsA("Decal") and CONFIG.decalTransparency or CONFIG.textureTransparency
            _orig[i] = {Transparency = i.Transparency}
            i.Transparency = math.max(i.Transparency, threshold)
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then i.Transparency = o.Transparency; _orig[i] = nil end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 5: partes base y explosiones
    [5] = {
        tracked = {},
        check   = function(i)
            return (i:IsA("BasePart") and not i:IsA("MeshPart")) or i:IsA("Explosion")
        end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            if i:IsA("Explosion") then
                _orig[i] = {BlastPressure = i.BlastPressure, BlastRadius = i.BlastRadius, Transparency = i.Transparency}
                i.BlastPressure = i.BlastPressure * CONFIG.explosionScale
                i.BlastRadius   = i.BlastRadius   * CONFIG.explosionScale
                i.Transparency  = math.max(i.Transparency, CONFIG.explosionTransparency)
            else
                _orig[i] = {CastShadow = i.CastShadow, Reflectance = i.Reflectance}
                i.CastShadow  = false
                i.Reflectance = math.min(i.Reflectance, 0.1)
            end
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("Explosion") then
                        i.BlastPressure = o.BlastPressure
                        i.BlastRadius   = o.BlastRadius
                        i.Transparency  = o.Transparency
                    else
                        i.CastShadow  = o.CastShadow
                        i.Reflectance = o.Reflectance
                    end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 6: ropa, apariencias, post-efectos
    [6] = {
        tracked = {},
        check   = function(i)
            return i:IsA("Clothing") or i:IsA("SurfaceAppearance") or i:IsA("BaseWrap") or i:IsA("PostEffect")
        end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            if i:IsA("PostEffect") then
                _orig[i] = {Enabled = i.Enabled}
                i.Enabled = false
            else
                _orig[i] = {Parent = i.Parent}
                i.Parent = Debris
            end
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("PostEffect") then i.Enabled = o.Enabled
                    elseif o.Parent then i.Parent = o.Parent end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 7: más agresivo — cámara, render global, materiales, accesorios
    [7] = {
        tracked = {},
        check   = function() return false end,
        collect = function() return {} end,
        apply = function(t)
            local cam = Workspace.CurrentCamera
            if not _orig.Camera then
                _orig.Camera = {FieldOfView = cam.FieldOfView, FarPlane = cam.FarPlane}
                cam.FieldOfView = math.max(CONFIG.minFOV, cam.FieldOfView - CONFIG.fovReduction)
                cam.FarPlane    = CONFIG.farPlaneTarget
            end

            if not _orig.Rendering then
                _orig.Rendering = {
                    QualityLevel        = settings().Rendering.QualityLevel,
                    MeshPartDetailLevel = settings().Rendering.MeshPartDetailLevel,
                }
                settings().Rendering.QualityLevel        = Enum.QualityLevel.Level1
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            end

            if not _orig.Materials then
                _orig.Materials = {Use2022 = MaterialService.Use2022Materials, list = {}}
                for _, m in pairs(MaterialService:GetChildren()) do
                    _orig.Materials.list[m] = true
                end
                MaterialService.Use2022Materials = false
                for _, m in pairs(MaterialService:GetChildren()) do
                    m:Destroy()
                end
            end

            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if not char then continue() end

                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and not _orig[hum] then
                    _orig[hum] = {DisplayDistanceType = hum.DisplayDistanceType}
                    hum.DisplayDistanceType = Enum.DisplayDistanceType.None
                    table.insert(t.tracked, hum)
                end

                local desc = char:FindFirstChildOfClass("HumanoidDescription")
                if desc and not _orig[desc] then
                    _orig[desc] = {
                        HatAccessory      = desc.HatAccessory,
                        HairAccessory     = desc.HairAccessory,
                        FaceAccessory     = desc.FaceAccessory,
                        NeckAccessory     = desc.NeckAccessory,
                        ShoulderAccessory = desc.ShoulderAccessory,
                        FrontAccessory    = desc.FrontAccessory,
                        BackAccessory     = desc.BackAccessory,
                        WaistAccessory    = desc.WaistAccessory,
                    }
                    desc.HatAccessory      = "0"
                    desc.HairAccessory     = "0"
                    desc.FaceAccessory     = "0"
                    desc.NeckAccessory     = "0"
                    desc.ShoulderAccessory = "0"
                    desc.FrontAccessory    = "0"
                    desc.BackAccessory     = "0"
                    desc.WaistAccessory    = "0"
                    table.insert(t.tracked, desc)
                end
            end
        end,
        revert = function(t)
            if _orig.Camera then
                local cam = Workspace.CurrentCamera
                cam.FieldOfView = _orig.Camera.FieldOfView
                cam.FarPlane    = _orig.Camera.FarPlane
                _orig.Camera = nil
            end
            if _orig.Rendering then
                settings().Rendering.QualityLevel        = _orig.Rendering.QualityLevel
                settings().Rendering.MeshPartDetailLevel = _orig.Rendering.MeshPartDetailLevel
                _orig.Rendering = nil
            end
            if _orig.Materials then
                MaterialService.Use2022Materials = _orig.Materials.Use2022
                for m in pairs(_orig.Materials.list) do
                    if m and m.Parent == nil then m.Parent = MaterialService end
                end
                _orig.Materials = nil
            end
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("Humanoid") then
                        i.DisplayDistanceType = o.DisplayDistanceType
                    elseif i:IsA("HumanoidDescription") then
                        i.HatAccessory      = o.HatAccessory
                        i.HairAccessory     = o.HairAccessory
                        i.FaceAccessory     = o.FaceAccessory
                        i.NeckAccessory     = o.NeckAccessory
                        i.ShoulderAccessory = o.ShoulderAccessory
                        i.FrontAccessory    = o.FrontAccessory
                        i.BackAccessory     = o.BackAccessory
                        i.WaistAccessory    = o.WaistAccessory
                    end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 2: ropa, apariencias, post-efectos
    [2] = {
        tracked = {},
        check   = function(i)
            return i:IsA("Clothing") or i:IsA("SurfaceAppearance") or i:IsA("BaseWrap") or i:IsA("PostEffect")
        end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            if i:IsA("PostEffect") then
                _orig[i] = {Enabled = i.Enabled}
                i.Enabled = false
            else
                _orig[i] = {Parent = i.Parent}
                i.Parent = Debris
            end
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("PostEffect") then i.Enabled = o.Enabled
                    elseif o.Parent then i.Parent = o.Parent end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 3: partes base y explosiones
    [3] = {
        tracked = {},
        check   = function(i)
            return (i:IsA("BasePart") and not i:IsA("MeshPart")) or i:IsA("Explosion")
        end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            if i:IsA("Explosion") then
                _orig[i] = {BlastPressure = i.BlastPressure, BlastRadius = i.BlastRadius, Transparency = i.Transparency}
                i.BlastPressure = i.BlastPressure * CONFIG.explosionScale
                i.BlastRadius   = i.BlastRadius   * CONFIG.explosionScale
                i.Transparency  = math.max(i.Transparency, CONFIG.explosionTransparency)
            else
                _orig[i] = {CastShadow = i.CastShadow, Reflectance = i.Reflectance}
                i.CastShadow  = false
                i.Reflectance = math.min(i.Reflectance, 0.1)
            end
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("Explosion") then
                        i.BlastPressure = o.BlastPressure
                        i.BlastRadius   = o.BlastRadius
                        i.Transparency  = o.Transparency
                    else
                        i.CastShadow  = o.CastShadow
                        i.Reflectance = o.Reflectance
                    end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 4: decals y texturas
    [4] = {
        tracked = {},
        check   = function(i) return i:IsA("Decal") or i:IsA("Texture") end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            local threshold = i:IsA("Decal") and CONFIG.decalTransparency or CONFIG.textureTransparency
            _orig[i] = {Transparency = i.Transparency}
            i.Transparency = math.max(i.Transparency, threshold)
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then i.Transparency = o.Transparency; _orig[i] = nil end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 5: luces y sonidos
    [5] = {
        tracked = {},
        check   = function(i) return i:IsA("Light") or i:IsA("Sound") end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            if i:IsA("Light") then
                _orig[i] = {Shadows = i.Shadows}
                i.Shadows = false
            else
                _orig[i] = {Volume = i.Volume}
                i.Volume = i.Volume * CONFIG.soundVolumeReduction
            end
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("Light") then i.Shadows = o.Shadows
                    else i.Volume = o.Volume end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 6: meshes y decals de personaje
    [6] = {
        tracked = {},
        check   = function(i)
            return i:IsA("MeshPart") or i:IsA("FaceInstance") or i:IsA("ShirtGraphic")
        end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            if i:IsA("MeshPart") then
                _orig[i] = {RenderFidelity = i.RenderFidelity, LODX = i.LODX, LODY = i.LODY}
                i.RenderFidelity = Enum.RenderFidelity.Performance
                i.LODX = Enum.LevelOfDetail.Coarse
                i.LODY = Enum.LevelOfDetail.Coarse
            else
                _orig[i] = {Transparency = i.Transparency}
                i.Transparency = math.max(i.Transparency, 0.2)
            end
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    if i:IsA("MeshPart") then
                        i.RenderFidelity = o.RenderFidelity
                        i.LODX = o.LODX
                        i.LODY = o.LODY
                    else
                        i.Transparency = o.Transparency
                    end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
    -- Tier 7: menos agresivo — partículas y trails
    [7] = {
        tracked = {},
        check   = function(i) return i:IsA("ParticleEmitter") or i:IsA("Trail") end,
        collect = function() return dir():GetDescendants() end,
        apply = function(t, i)
            if _orig[i] then return end
            local e = {Transparency = i.Transparency}
            if i:IsA("ParticleEmitter") then
                e.Rate = i.Rate
                i.Rate = i.Rate * CONFIG.particleScale
            end
            i.Transparency = math.max(i.Transparency, 0.2)
            _orig[i] = e
            table.insert(t.tracked, i)
        end,
        revert = function(t)
            for _, i in ipairs(t.tracked) do
                local o = _orig[i]
                if o then
                    i.Transparency = o.Transparency
                    if o.Rate then i.Rate = o.Rate end
                    _orig[i] = nil
                end
            end
            table.clear(t.tracked)
        end,
    },
}

-- ═══════════════════════════════════════════════════════════
-- TIER CHANGE: gradual recovery
-- ═══════════════════════════════════════════════════════════
local function notify(n, d)
    if type(CONFIG.onTierChange) == "function" then
        CONFIG.onTierChange(n, d)
    end
end

-- PERF FIX: Safe tier apply/revert with pcall guards
local function setTier(n)
    n = math.clamp(math.floor(n), 0, CONFIG.maxTier)
    if n == _tier then return end
    local old = _tier
    _tier = n

    if n > old then
        -- Escalando agresividad
        local t0 = os.clock()
        for i = old + 1, n do
            local t = TIERS[i]
            if not t then continue() end
            if i == CONFIG.maxTier then
                if safeApply(t) then
                    _stats.instancesOpt = _stats.instancesOpt + #t.tracked
                end
            else
                local instances = t.collect()
                for _, inst in ipairs(instances) do
                    if t.check(inst) then
                        if safeApply(t, inst) then
                            _stats.instancesOpt = _stats.instancesOpt + 1
                        end
                    end
                end
            end
            notify(i, "up")
        end
        _stats.tierChanges = _stats.tierChanges + 1
        _stats.lastApplyTime = os.clock() - t0
        _stats.totalApplyTime = _stats.totalApplyTime + _stats.lastApplyTime

    else
        -- Recuperando calidad — gradual: solo el tier más agresivo se revierte por vez
        local t0 = os.clock()
        for i = old, n + 1, -1 do
            local t = TIERS[i]
            if t then
                if safeRevert(t) then
                    _stats.instancesRevert = _stats.instancesRevert + #t.tracked
                end
            end
            notify(i - 1, "down")
        end
        _stats.tierChanges = _stats.tierChanges + 1
        _stats.lastRevertTime = os.clock() - t0
        _stats.totalRevertTime = _stats.totalRevertTime + _stats.lastRevertTime
    end
end

-- ═══════════════════════════════════════════════════════════
-- DESCENDANT ADDED HANDLER
-- ═══════════════════════════════════════════════════════════
local function onAdded(inst)
    if not _running then return end
    for i = 1, _tier do
        local t = TIERS[i]
        if t and i ~= CONFIG.maxTier and t.check(inst) then
            safeApply(t, inst)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════

--- Initialize the optimizer with custom config
function OPT.Init(cfg)
    if _running then return false, "already running" end
    for k, v in pairs(cfg) do
        if CONFIG[k] == nil then return false, "invalid key: " .. k end
        CONFIG[k] = v
    end
    -- Reinitialize buffer size if changed
    if cfg.sampleInterval then
        CONFIG.sampleInterval = cfg.sampleInterval
    end
    return true
end

--- Start monitoring and optimizing
function OPT.Enable()
    if _running then return end
    _running    = true
    _lastSample = tick()

    -- Reset stats on enable
    _stats.tierChanges     = 0
    _stats.instancesOpt    = 0
    _stats.instancesRevert = 0
    _stats.lastApplyTime   = 0
    _stats.lastRevertTime  = 0
    _stats.totalApplyTime  = 0
    _stats.totalRevertTime = 0
    _stats.errorsCaught    = 0

    _events.Added   = dir().DescendantAdded:Connect(onAdded)
    _events.Stepped = RunService.RenderStepped:Connect(function(dt)
        -- PERF FIX: Circular buffer O(1) insert instead of table.remove O(n)
        bufInsert(1 / dt)

        local now = tick()
        if now - _lastSample < CONFIG.sampleInterval then return end
        _lastSample = now

        -- PERF FIX: Single pass average from ring buffer
        _fpsAvg = bufAverage()

        if _fpsAvg < CONFIG.targetFPS then
            _downCount = 0
            _upCount   = _upCount + 1
            if _upCount >= CONFIG.confirmSamples and _tier < CONFIG.maxTier then
                _upCount = 0
                setTier(_tier + 1)
            end
        elseif _fpsAvg > CONFIG.targetFPS + CONFIG.recoverMargin then
            _upCount   = 0
            _downCount = _downCount + 1
            if _downCount >= CONFIG.confirmSamples and _tier > 0 then
                _downCount = 0
                -- PERF FIX: Gradual recovery — lower by 1 tier at a time
                setTier(_tier - 1)
            end
        else
            _upCount   = 0
            _downCount = 0
        end
    end)
end

--- Stop optimizing and revert all changes
function OPT.Disable()
    if not _running then return end
    _running = false

    for _, c in pairs(_events) do c:Disconnect() end
    _events = {}

    setTier(0)
    _orig       = {}
    _upCount    = 0
    _downCount  = 0
    bufClear()
end

--- Toggle optimizer on/off
function OPT.Toggle()
    if _running then OPT.Disable() return false end
    OPT.Enable()
    return true
end

--- Check if optimizer is running
function OPT.IsRunning() return _running end

--- Get current tier (0-7)
function OPT.GetTier() return _tier end

--- Get current FPS average
function OPT.GetFPS() return _fpsAvg end

--- Get full stats table
-- Returns: { tierChanges, instancesOpt, instancesRevert, lastApplyTime, lastRevertTime, totalApplyTime, totalRevertTime, errorsCaught }
function OPT.GetStats()
    return {
        tierChanges     = _stats.tierChanges,
        instancesOpt    = _stats.instancesOpt,
        instancesRevert = _stats.instancesRevert,
        lastApplyTime   = _stats.lastApplyTime,
        lastRevertTime  = _stats.lastRevertTime,
        totalApplyTime  = _stats.totalApplyTime,
        totalRevertTime = _stats.totalRevertTime,
        errorsCaught    = _stats.errorsCaught,
        currentTier     = _tier,
        fpsAvg          = _fpsAvg,
        isRunning       = _running,
    }
end

--- Get a copy of current config
function OPT.GetConfig()
    local copy = {}
    for k, v in pairs(CONFIG) do copy[k] = v end
    return copy
end

--- Manually set a tier (0 to maxTier)
function OPT.SetTier(n) setTier(n) end

--- Override a tier definition at runtime (for custom tier configs)
-- tierIdx: 1-7, tierDef: { check, collect, apply, revert }
function OPT.OverrideTier(tierIdx, tierDef)
    if type(tierIdx) ~= "number" or tierIdx < 1 or tierIdx > CONFIG.maxTier then
        return false, "invalid tier index"
    end
    if type(tierDef) ~= "table" then
        return false, "tierDef must be a table"
    end
    local t = TIERS[tierIdx] or { tracked = {} }
    if tierDef.check   then t.check   = tierDef.check   end
    if tierDef.collect then t.collect = tierDef.collect end
    if tierDef.apply   then t.apply   = tierDef.apply   end
    if tierDef.revert  then t.revert  = tierDef.revert  end
    TIERS[tierIdx] = t
    return true
end

--- Get the TIERS table reference (read-only recommended)
function OPT.GetTiers() return TIERS end
-- ═══════════════════════════════════════════════════════════
-- FPS COUNTER
-- ═══════════════════════════════════════════════════════════
local _ctr = { gui = nil, conns = {} }

local _cc = {
    muted = "rgb(90,90,90)",
    good  = "rgb(34,197,94)",
    warn  = "rgb(245,158,11)",
    bad   = "rgb(239,68,68)",
}

local function _ctrEnable()
    if _ctr.gui then return end
    local lp = Players.LocalPlayer
    if not lp then return end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "OPT_Counter"
    gui.ResetOnSpawn   = false
    gui.DisplayOrder   = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local win = Instance.new("Frame")
    win.Name                   = "Win"
    win.Size                   = UDim2.new(0, 94, 0, 30)
    win.Position               = UDim2.new(0, 14, 0, 14)
    win.BackgroundColor3       = Color3.fromRGB(11, 11, 11)
    win.BackgroundTransparency = 0.04
    win.BorderSizePixel        = 0
    win.Parent                 = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent       = win

    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(192, 192, 192)
    stroke.Transparency = 0.88
    stroke.Thickness    = 1
    stroke.Parent       = win

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft  = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent       = win

    local lbl = Instance.new("TextLabel")
    lbl.Name                   = "Label"
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.RichText               = true
    lbl.Text                   = '<font color="' .. _cc.muted .. '">FPS</font> <font color="' .. _cc.muted .. '">--</font>'
    lbl.Font                   = Enum.Font.Code
    lbl.TextSize               = 13
    lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = win

    gui.Parent = lp:WaitForChild("PlayerGui")

    local dragging, ds, sp = false, nil, nil

    win.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            ds = inp.Position
            sp = win.Position
        end
    end)

    win.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    table.insert(_ctr.conns,
        UserInputService.InputChanged:Connect(function(inp)
            if not dragging then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = inp.Position - ds
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end)
    )

    local fps = 0
    table.insert(_ctr.conns,
        RunService.RenderStepped:Connect(function(dt)
            if dt <= 0 then return end
            fps = fps * 0.85 + (1 / dt) * 0.15
            local v   = math.floor(fps + 0.5)
            local col = v >= 50 and _cc.good or v >= 30 and _cc.warn or _cc.bad
            lbl.Text  = '<font color="' .. _cc.muted .. '">FPS</font> <b><font color="' .. col .. '">' .. v .. '</font></b>'
        end)
    )

    _ctr.gui = gui
end

local function _ctrDisable()
    if not _ctr.gui then return end
    for _, c in ipairs(_ctr.conns) do c:Disconnect() end
    _ctr.conns = {}
    _ctr.gui:Destroy()
    _ctr.gui = nil
end

function OPT.Counter(action)
    if action == "enable" then
        _ctrEnable()
    elseif action == "disable" then
        _ctrDisable()
    end
end

return OPT
