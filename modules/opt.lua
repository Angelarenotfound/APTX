
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local AutoOptimizer = {}

local CONFIG = {
    targetFPS = 50,
    recoverMargin = 10,
    sampleInterval = 1,
    confirmSamples = 3,
    particleScale = 0.6,
    fovReduction = 8,
    farPlaneTarget = 350,
    maxTier = 7,
    minFOV = 50,
}

local running = false
local currentTier = 0
local belowCount = 0
local aboveCount = 0
local frameTimes = {}

local original = {}
local emitters = {}

local renderConn, sampleThread, descendantConn

local function getCamera()
    return Workspace.CurrentCamera
end

local function getPostEffect(name)
    return Lighting:FindFirstChild(name)
end

local function registerEmitter(inst)
    if inst:IsA("ParticleEmitter") then
        if not inst:GetAttribute("_origRate") then
            inst:SetAttribute("_origRate", inst.Rate)
        end
        table.insert(emitters, inst)
    elseif inst:IsA("Trail") then
        table.insert(emitters, inst)
    end
end

local function collectEmitters()
    emitters = {}
    for _, inst in Workspace:GetDescendants() do
        registerEmitter(inst)
    end
end

local function captureOriginal()
    local cam = getCamera()
    original.shadows = Lighting.GlobalShadows
    original.shadowSoftness = Lighting.ShadowSoftness
    original.fov = cam and cam.FieldOfView or 70
    original.farPlane = cam and cam.FarPlaneDistance or 100000
    original.fogStart = Lighting.FogStart
    original.fogEnd = Lighting.FogEnd

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        original.terrainDecoration = terrain.Decoration
    end
end

local TIERS = {
    [1] = {
        apply = function()
            local sunRays = getPostEffect("SunRaysEffect")
            local dof = getPostEffect("DepthOfFieldEffect")
            if sunRays then sunRays.Enabled = false end
            if dof then dof.Enabled = false end
        end,
        revert = function()
            local sunRays = getPostEffect("SunRaysEffect")
            local dof = getPostEffect("DepthOfFieldEffect")
            if sunRays then sunRays.Enabled = true end
            if dof then dof.Enabled = true end
        end,
    },
    [2] = {
        apply = function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then terrain.Decoration = false end
        end,
        revert = function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain and original.terrainDecoration ~= nil then
                terrain.Decoration = original.terrainDecoration
            end
        end,
    },
    [3] = {
        apply = function()
            Lighting.ShadowSoftness = 0
        end,
        revert = function()
            Lighting.ShadowSoftness = original.shadowSoftness
        end,
    },
    [4] = {
        apply = function()
            Lighting.GlobalShadows = false
        end,
        revert = function()
            Lighting.GlobalShadows = original.shadows
        end,
    },
    [5] = {
        apply = function()
            for _, e in emitters do
                if e:IsA("ParticleEmitter") then
                    local orig = e:GetAttribute("_origRate")
                    if orig then
                        e.Rate = orig * CONFIG.particleScale
                    end
                end
            end
        end,
        revert = function()
            for _, e in emitters do
                if e:IsA("ParticleEmitter") then
                    local orig = e:GetAttribute("_origRate")
                    if orig then e.Rate = orig end
                end
            end
        end,
    },
    [6] = {
        apply = function()
            for _, e in emitters do
                if e:IsA("Trail") then
                    e.Enabled = false
                end
            end
        end,
        revert = function()
            for _, e in emitters do
                if e:IsA("Trail") then
                    e.Enabled = true
                end
            end
        end,
    },
    [7] = {
        apply = function()
            local cam = getCamera()
            if not cam then return end
            cam.FieldOfView = math.max(CONFIG.minFOV, original.fov - CONFIG.fovReduction)
            cam.FarPlaneDistance = CONFIG.farPlaneTarget
            Lighting.FogEnd = CONFIG.farPlaneTarget
            Lighting.FogStart = CONFIG.farPlaneTarget * 0.3
        end,
        revert = function()
            local cam = getCamera()
            if cam then
                cam.FieldOfView = original.fov
                cam.FarPlaneDistance = original.farPlane
            end
            Lighting.FogStart = original.fogStart
            Lighting.FogEnd = original.fogEnd
        end,
    },
}

local function avgFPS()
    if #frameTimes == 0 then return 60 end
    local sum = 0
    for _, dt in frameTimes do sum += dt end
    return 1 / (sum / #frameTimes)
end

local function increaseTier()
    if currentTier >= CONFIG.maxTier then return end
    currentTier += 1
    TIERS[currentTier].apply()
end

local function decreaseTier()
    if currentTier <= 0 then return end
    TIERS[currentTier].revert()
    currentTier -= 1
end

local function revertAll()
    while currentTier > 0 do
        decreaseTier()
    end
end

local function sampleLoop()
    while running do
        task.wait(CONFIG.sampleInterval)
        local fps = avgFPS()

        if fps < CONFIG.targetFPS then
            belowCount += 1
            aboveCount = 0
        elseif fps > CONFIG.targetFPS + CONFIG.recoverMargin then
            aboveCount += 1
            belowCount = 0
        else
            belowCount = 0
            aboveCount = 0
        end

        if belowCount >= CONFIG.confirmSamples then
            increaseTier()
            belowCount = 0
        elseif aboveCount >= CONFIG.confirmSamples then
            decreaseTier()
            aboveCount = 0
        end
    end
end

function AutoOptimizer.Init(userConfig)
    if running then
        warn("[AutoOptimizer] Init() ignored: optimizer is currently running")
        return
    end
    userConfig = userConfig or {}
    for key, value in userConfig do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
        else
            warn("[AutoOptimizer] Unknown config key: " .. tostring(key))
        end
    end
end

function AutoOptimizer.Enable()
    if running then return end
    running = true

    captureOriginal()
    collectEmitters()

    frameTimes = {}
    belowCount = 0
    aboveCount = 0

    renderConn = RunService.RenderStepped:Connect(function(dt)
        table.insert(frameTimes, dt)
        if #frameTimes > 60 then
            table.remove(frameTimes, 1)
        end
    end)

    descendantConn = Workspace.DescendantAdded:Connect(function(inst)
        registerEmitter(inst)
        if currentTier >= 5 and inst:IsA("ParticleEmitter") then
            local orig = inst:GetAttribute("_origRate") or inst.Rate
            inst:SetAttribute("_origRate", orig)
            inst.Rate = orig * CONFIG.particleScale
        elseif currentTier >= 6 and inst:IsA("Trail") then
            inst.Enabled = false
        end
    end)

    sampleThread = task.spawn(sampleLoop)
end

function AutoOptimizer.Disable()
    if not running then return end
    running = false

    if renderConn then renderConn:Disconnect() renderConn = nil end
    if descendantConn then descendantConn:Disconnect() descendantConn = nil end

    revertAll()
    emitters = {}
end

function AutoOptimizer.Toggle()
    if running then
        AutoOptimizer.Disable()
    else
        AutoOptimizer.Enable()
    end
    return running
end

function AutoOptimizer.IsRunning()
    return running
end

function AutoOptimizer.GetTier()
    return currentTier
end

return AutoOptimizer