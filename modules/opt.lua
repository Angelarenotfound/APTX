local OPT = {}

local CONFIG = {
    targetFPS            = 60,
    recoverMargin        = 10,
    sampleInterval       = 1,
    confirmSamples       = 3,
    particleScale        = 0.6,
    fovReduction         = 8,
    farPlaneTarget       = 350,
    maxTier              = 7,
    minFOV               = 50,
    decalTransparency    = 0.5,
    textureTransparency  = 0.5,
    soundVolumeReduction = 0.5,
    explosionScale       = 0.5,
    explosionTransparency = 0.5,
    onTierChange         = nil,
}

local _running = false
local _tier    = 0
local _orig    = {}
local _events  = {}

local _fpsSamples = {}
local _fpsAvg     = 0
local _lastSample = 0
local _upCount    = 0
local _downCount  = 0

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local Workspace       = game:GetService("Workspace")
local MaterialService = game:GetService("MaterialService")
local Debris          = game:GetService("Debris")

local TIERS = {
    [1] = {
        tracked = {},
        check   = function(i) return i:IsA("ParticleEmitter") or i:IsA("Trail") end,
        collect = function() return Workspace:GetDescendants() end,
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
    [2] = {
        tracked = {},
        check   = function(i)
            return i:IsA("MeshPart") or i:IsA("FaceInstance") or i:IsA("ShirtGraphic")
        end,
        collect = function() return Workspace:GetDescendants() end,
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
    [3] = {
        tracked = {},
        check   = function(i) return i:IsA("Light") or i:IsA("Sound") end,
        collect = function() return Workspace:GetDescendants() end,
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
    [4] = {
        tracked = {},
        check   = function(i) return i:IsA("Decal") or i:IsA("Texture") end,
        collect = function() return Workspace:GetDescendants() end,
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
    [5] = {
        tracked = {},
        check   = function(i)
            return (i:IsA("BasePart") and not i:IsA("MeshPart")) or i:IsA("Explosion")
        end,
        collect = function() return Workspace:GetDescendants() end,
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
    [6] = {
        tracked = {},
        check   = function(i)
            return i:IsA("Clothing") or i:IsA("SurfaceAppearance") or i:IsA("BaseWrap") or i:IsA("PostEffect")
        end,
        collect = function() return Workspace:GetDescendants() end,
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
}

local function notify(n, dir)
    if type(CONFIG.onTierChange) == "function" then
        CONFIG.onTierChange(n, dir)
    end
end

local function setTier(n)
    n = math.clamp(math.floor(n), 0, CONFIG.maxTier)
    if n == _tier then return end
    local old = _tier
    _tier = n
    if n > old then
        for i = old + 1, n do
            local t = TIERS[i]
            if not t then continue() end
            if i == 7 then
                t.apply(t)
            else
                for _, inst in ipairs(t.collect()) do
                    if t.check(inst) then t.apply(t, inst) end
                end
            end
            notify(i, "up")
        end
    else
        for i = old, n + 1, -1 do
            local t = TIERS[i]
            if t then t.revert(t) end
            notify(i - 1, "down")
        end
    end
end

local function onAdded(inst)
    if not _running then return end
    for i = 1, _tier do
        local t = TIERS[i]
        if t and i ~= 7 and t.check(inst) then t.apply(t, inst) end
    end
end

function OPT.Init(cfg)
    if _running then return false, "already running" end
    for k, v in pairs(cfg) do
        if CONFIG[k] == nil then return false, "invalid key: " .. k end
        CONFIG[k] = v
    end
    return true
end

function OPT.Enable()
    if _running then return end
    _running    = true
    _lastSample = tick()

    _events.Added = Workspace.DescendantAdded:Connect(onAdded)
    _events.Stepped = RunService.RenderStepped:Connect(function(dt)
        table.insert(_fpsSamples, 1 / dt)
        if #_fpsSamples > 60 then table.remove(_fpsSamples, 1) end

        local now = tick()
        if now - _lastSample < CONFIG.sampleInterval then return end
        _lastSample = now

        local sum = 0
        for _, v in ipairs(_fpsSamples) do sum = sum + v end
        _fpsAvg = sum / #_fpsSamples

        if _fpsAvg < CONFIG.targetFPS then
            _downCount = 0
            _upCount  = _upCount + 1
            if _upCount >= CONFIG.confirmSamples and _tier < CONFIG.maxTier then
                _upCount = 0
                setTier(_tier + 1)
            end
        elseif _fpsAvg > CONFIG.targetFPS + CONFIG.recoverMargin then
            _upCount    = 0
            _downCount = _downCount + 1
            if _downCount >= CONFIG.confirmSamples and _tier > 0 then
                _downCount = 0
                setTier(_tier - 1)
            end
        else
            _upCount   = 0
            _downCount = 0
        end
    end)
end

function OPT.Disable()
    if not _running then return end
    _running = false

    for _, c in pairs(_events) do c:Disconnect() end
    _events = {}

    setTier(0)
    _orig      = {}
    _fpsSamples = {}
    _fpsAvg    = 0
    _upCount   = 0
    _downCount = 0
end

function OPT.Toggle()
    if _running then OPT.Disable() return false end
    OPT.Enable()
    return true
end

function OPT.IsRunning() return _running end
function OPT.GetTier()   return _tier    end
function OPT.GetFPS()    return _fpsAvg  end

function OPT.GetConfig()
    local copy = {}
    for k, v in pairs(CONFIG) do copy[k] = v end
    return copy
end

function OPT.SetTier(n) setTier(n) end

return OPT
