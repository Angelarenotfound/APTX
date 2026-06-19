local OPT = {}

-- CONFIGURACI脫N POR DEFECTO
local CONFIG = {
    targetFPS = 60,
    recoverMargin = 10,
    sampleInterval = 1,
    confirmSamples = 3,
    particleScale = 0.6, -- Escala de reducci贸n de part铆culas
    fovReduction = 8,
    farPlaneTarget = 350,
    maxTier = 7,
    minFOV = 50,
    onTierChange = nil,
    lightShadowsTransparency = 0.5, -- Nueva configuraci贸n para transparencia de sombras de luces
    decalTransparency = 0.5, -- Nueva configuraci贸n para transparencia de calcoman铆as
    textureTransparency = 0.5, -- Nueva configuraci贸n para transparencia de texturas
    soundVolumeReduction = 0.5, -- Nueva configuraci贸n para reducci贸n de volumen de sonido
    explosionScale = 0.5, -- Nueva configuraci贸n para escala de explosiones
    explosionTransparency = 0.5, -- Nueva configuraci贸n para transparencia de explosiones
}

-- ESTADO INTERNO
local _isRunning = false
local _currentTier = 0
local _originalValues = {}
local _connectedEvents = {}
local _trackedEmitters = {}
local _trackedTrails = {}
local _trackedLights = {}
local _trackedDecals = {}
local _trackedTextures = {}
local _trackedSounds = {}
local _trackedHumanoids = {}
local _trackedParts = {}
local _trackedMeshParts = {}
local _trackedFaceInstances = {}
local _trackedShirtGraphics = {}
local _trackedPostEffects = {}
local _trackedExplosions = {}
local _trackedClothing = {}

local _fpsSamples = {}
local _fpsCounter = 0
local _fpsAverage = 0
local _lastSampleTime = 0
local _tierUpCounter = 0
local _tierDownCounter = 0

-- SERVICIOS DE ROBLOX
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local MaterialService = game:GetService("MaterialService")
local Debris = game:GetService("Debris")

-- VALORES ORIGINALES GLOBALES
local _originalCameraFOV = game.Workspace.CurrentCamera.FieldOfView
local _originalCameraFarPlane = game.Workspace.CurrentCamera.FarPlane
local _originalRenderingQualityLevel = settings().Rendering.QualityLevel
local _originalRenderingMeshPartDetailLevel = settings().Rendering.MeshPartDetailLevel
local _originalMaterialServiceUse2022Materials = MaterialService.Use2022Materials
local _originalMaterialServiceMaterials = {}

-- DEFINICI脫N DE TIERS DE OPTIMIZACI脫N (de menor a mayor impacto)
-- Cada tier aplica un conjunto de optimizaciones. Revertir un tier significa deshacer esas optimizaciones.
local TIERS = {
    [1] = {
        name = "Reducci贸n Sutil de Part铆culas y Trails",
        apply = function(instance)
            if instance:IsA("ParticleEmitter") or instance:IsA("Trail") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Enabled = instance.Enabled, Rate = instance.Rate, Transparency = instance.Transparency}
                    instance._origRate = instance.Rate -- Para restaurar Rate si es modificado por particleScale
                end
                instance.Transparency = math.max(instance.Transparency, 0.2) -- Hacerlas un poco transparentes
                instance.Rate = instance.Rate * CONFIG.particleScale -- Reducir tasa de emisi贸n
                table.insert(_trackedEmitters, instance)
            end
        end,
        revert = function(instance)
            if instance:IsA("ParticleEmitter") or instance:IsA("Trail") then
                local orig = _originalValues[instance]
                if orig then
                    instance.Enabled = orig.Enabled
                    instance.Rate = orig.Rate
                    instance.Transparency = orig.Transparency
                end
            end
        end,
        check = function(instance) return instance:IsA("ParticleEmitter") or instance:IsA("Trail") end,
        collect = function() return Workspace:GetDescendants() end,
        trackedList = _trackedEmitters,
    },
    [2] = {
        name = "Optimizaci贸n de Mallas y Texturas Ligeras",
        apply = function(instance)
            if instance:IsA("MeshPart") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {RenderFidelity = instance.RenderFidelity, LODX = instance.LODX, LODY = instance.LODY}
                end
                instance.RenderFidelity = Enum.RenderFidelity.Performance
                instance.LODX = Enum.LevelOfDetail.Coarse
                instance.LODY = Enum.LevelOfDetail.Coarse
                table.insert(_trackedMeshParts, instance)
            elseif instance:IsA("FaceInstance") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Transparency = instance.Transparency}
                end
                instance.Transparency = math.max(instance.Transparency, 0.2) -- Ligeramente transparentes
                table.insert(_trackedFaceInstances, instance)
            elseif instance:IsA("ShirtGraphic") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Transparency = instance.Transparency}
                end
                instance.Transparency = math.max(instance.Transparency, 0.2) -- Ligeramente transparentes
                table.insert(_trackedShirtGraphics, instance)
            end
        end,
        revert = function(instance)
            if instance:IsA("MeshPart") then
                local orig = _originalValues[instance]
                if orig then
                    instance.RenderFidelity = orig.RenderFidelity
                    instance.LODX = orig.LODX
                    instance.LODY = orig.LODY
                end
            elseif instance:IsA("FaceInstance") then
                local orig = _originalValues[instance]
                if orig then instance.Transparency = orig.Transparency end
            elseif instance:IsA("ShirtGraphic") then
                local orig = _originalValues[instance]
                if orig then instance.Transparency = orig.Transparency end
            end
        end,
        check = function(instance) return instance:IsA("MeshPart") or instance:IsA("FaceInstance") or instance:IsA("ShirtGraphic") end,
        collect = function() return Workspace:GetDescendants() end,
        trackedList = _trackedMeshParts,
    },
    [3] = {
        name = "Desactivaci贸n de Sombras y Reducci贸n de Volumen de Sonido",
        apply = function(instance)
            if instance:IsA("Light") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Shadows = instance.Shadows}
                end
                instance.Shadows = false -- Desactivar sombras
                table.insert(_trackedLights, instance)
            elseif instance:IsA("Sound") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Volume = instance.Volume}
                end
                instance.Volume = instance.Volume * CONFIG.soundVolumeReduction -- Reducir volumen
                table.insert(_trackedSounds, instance)
            end
        end,
        revert = function(instance)
            if instance:IsA("Light") then
                local orig = _originalValues[instance]
                if orig then instance.Shadows = orig.Shadows end
            elseif instance:IsA("Sound") then
                local orig = _originalValues[instance]
                if orig then instance.Volume = orig.Volume end
            end
        end,
        check = function(instance) return instance:IsA("Light") or instance:IsA("Sound") end,
        collect = function() return Workspace:GetDescendants() end,
        trackedList = _trackedLights,
    },
    [4] = {
        name = "Transparencia Sutil de Calcoman铆as y Texturas",
        apply = function(instance)
            if instance:IsA("Decal") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Transparency = instance.Transparency}
                end
                instance.Transparency = math.max(instance.Transparency, CONFIG.decalTransparency) -- Aumentar transparencia
                table.insert(_trackedDecals, instance)
            elseif instance:IsA("Texture") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Transparency = instance.Transparency}
                end
                instance.Transparency = math.max(instance.Transparency, CONFIG.textureTransparency) -- Aumentar transparencia
                table.insert(_trackedTextures, instance)
            end
        end,
        revert = function(instance)
            if instance:IsA("Decal") then
                local orig = _originalValues[instance]
                if orig then instance.Transparency = orig.Transparency end
            elseif instance:IsA("Texture") then
                local orig = _originalValues[instance]
                if orig then instance.Transparency = orig.Transparency end
            end
        end,
        check = function(instance) return instance:IsA("Decal") or instance:IsA("Texture") end,
        collect = function() return Workspace:GetDescendants() end,
        trackedList = _trackedDecals,
    },
    [5] = {
        name = "Optimizaci贸n de Partes y Explosiones Moderada",
        apply = function(instance)
            if instance:IsA("BasePart") and not instance:IsA("MeshPart") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {CastShadow = instance.CastShadow, Reflectance = instance.Reflectance}
                end
                instance.CastShadow = false -- Desactivar sombras de partes
                instance.Reflectance = math.min(instance.Reflectance, 0.1) -- Reducir reflectancia
                table.insert(_trackedParts, instance)
            elseif instance:IsA("Explosion") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {BlastPressure = instance.BlastPressure, BlastRadius = instance.BlastRadius, Visible = instance.Visible, Transparency = instance.Transparency}
                end
                instance.BlastPressure = instance.BlastPressure * CONFIG.explosionScale
                instance.BlastRadius = instance.BlastRadius * CONFIG.explosionScale
                instance.Transparency = math.max(instance.Transparency, CONFIG.explosionTransparency) -- Hacerlas m谩s transparentes
                table.insert(_trackedExplosions, instance)
            end
        end,
        revert = function(instance)
            if instance:IsA("BasePart") and not instance:IsA("MeshPart") then
                local orig = _originalValues[instance]
                if orig then
                    instance.CastShadow = orig.CastShadow
                    instance.Reflectance = orig.Reflectance
                end
            elseif instance:IsA("Explosion") then
                local orig = _originalValues[instance]
                if orig then
                    instance.BlastPressure = orig.BlastPressure
                    instance.BlastRadius = orig.BlastRadius
                    instance.Visible = orig.Visible
                    instance.Transparency = orig.Transparency
                end
            end
        end,
        check = function(instance) return (instance:IsA("BasePart") and not instance:IsA("MeshPart")) or instance:IsA("Explosion") end,
        collect = function() return Workspace:GetDescendants() end,
        trackedList = _trackedParts,
    },
    [6] = {
        name = "Eliminaci贸n de Ropa y Efectos Post-Procesado (Dr谩stico)",
        apply = function(instance)
            if instance:IsA("Clothing") or instance:IsA("SurfaceAppearance") or instance:IsA("BaseWrap") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Parent = instance.Parent}
                end
                instance.Parent = Debris -- Mover a Debris para eliminaci贸n eventual
                table.insert(_trackedClothing, instance)
            elseif instance:IsA("PostEffect") then
                if not _originalValues[instance] then
                    _originalValues[instance] = {Enabled = instance.Enabled}
                end
                instance.Enabled = false
                table.insert(_trackedPostEffects, instance)
            end
        end,
        revert = function(instance)
            if instance:IsA("Clothing") or instance:IsA("SurfaceAppearance") or instance:IsA("BaseWrap") then
                local orig = _originalValues[instance]
                if orig and orig.Parent then
                    instance.Parent = orig.Parent
                end
            elseif instance:IsA("PostEffect") then
                local orig = _originalValues[instance]
                if orig then instance.Enabled = orig.Enabled end
            end
        end,
        check = function(instance) return (instance:IsA("Clothing") or instance:IsA("SurfaceAppearance") or instance:IsA("BaseWrap")) or instance:IsA("PostEffect") end,
        collect = function() return Workspace:GetDescendants() end,
        trackedList = _trackedClothing,
    },
    [7] = {
        name = "Configuraci贸n de Renderizado Extrema y FOV/FarPlane (Dr谩stico)",
        apply = function()
            -- Aplicar a la c谩mara
            local camera = Workspace.CurrentCamera
            if not _originalValues.Camera then
                _originalValues.Camera = {FieldOfView = camera.FieldOfView, FarPlane = camera.FarPlane}
            end
            camera.FieldOfView = math.max(CONFIG.minFOV, camera.FieldOfView - CONFIG.fovReduction)
            camera.FarPlane = CONFIG.farPlaneTarget

            -- Aplicar a la configuraci贸n de renderizado
            if not _originalValues.Rendering then
                _originalValues.Rendering = {QualityLevel = settings().Rendering.QualityLevel, MeshPartDetailLevel = settings().Rendering.MeshPartDetailLevel}
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level1
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04

            -- Aplicar a MaterialService
            if not _originalValues.MaterialService then
                _originalValues.MaterialService = {Use2022Materials = MaterialService.Use2022Materials, Materials = {}}
                for _, mat in pairs(MaterialService:GetChildren()) do
                    _originalMaterialServiceMaterials[mat] = true
                end
            end
            MaterialService.Use2022Materials = false
            for _, mat in pairs(MaterialService:GetChildren()) do
                mat:Destroy()
            end

            -- Aplicar a Humanoids (desactivar accesorios y distancia de renderizado)
            for _, player in ipairs(Players:GetPlayers()) do
                local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if not _originalValues[humanoid] then
                        _originalValues[humanoid] = {DisplayDistanceType = humanoid.DisplayDistanceType}
                    end
                    humanoid.DisplayDistanceType = Enum.DisplayDistanceType.None
                    table.insert(_trackedHumanoids, humanoid)

                    local humanoidDescription = player.Character and player.Character:FindFirstChildOfClass("HumanoidDescription")
                    if humanoidDescription then
                        if not _originalValues[humanoidDescription] then
                            _originalValues[humanoidDescription] = {
                                HatAccessory = humanoidDescription.HatAccessory,
                                HairAccessory = humanoidDescription.HairAccessory,
                                FaceAccessory = humanoidDescription.FaceAccessory,
                                NeckAccessory = humanoidDescription.NeckAccessory,
                                ShoulderAccessory = humanoidDescription.ShoulderAccessory,
                                FrontAccessory = humanoidDescription.FrontAccessory,
                                BackAccessory = humanoidDescription.BackAccessory,
                                WaistAccessory = humanoidDescription.WaistAccessory,
                            }
                        end
                        humanoidDescription.HatAccessory = "0"
                        humanoidDescription.HairAccessory = "0"
                        humanoidDescription.FaceAccessory = "0"
                        humanoidDescription.NeckAccessory = "0"
                        humanoidDescription.ShoulderAccessory = "0"
                        humanoidDescription.FrontAccessory = "0"
                        humanoidDescription.BackAccessory = "0"
                        humanoidDescription.WaistAccessory = "0"
                    end
                end
            end
        end,
        revert = function()
            local camera = Workspace.CurrentCamera
            local origCamera = _originalValues.Camera
            if origCamera then
                camera.FieldOfView = origCamera.FieldOfView
                camera.FarPlane = origCamera.FarPlane
            end

            local origRendering = _originalValues.Rendering
            if origRendering then
                settings().Rendering.QualityLevel = origRendering.QualityLevel
                settings().Rendering.MeshPartDetailLevel = origRendering.MeshPartDetailLevel
            end

            local origMaterialService = _originalValues.MaterialService
            if origMaterialService then
                MaterialService.Use2022Materials = origMaterialService.Use2022Materials
                for mat in pairs(_originalMaterialServiceMaterials) do
                    if mat and not mat.Parent then
                        mat.Parent = MaterialService
                    end
                end
            end

            for _, humanoid in ipairs(_trackedHumanoids) do
                local orig = _originalValues[humanoid]
                if orig then humanoid.DisplayDistanceType = orig.DisplayDistanceType end
                local humanoidDescription = humanoid.Parent and humanoid.Parent:FindFirstChildOfClass("HumanoidDescription")
                if humanoidDescription then
                    local origDesc = _originalValues[humanoidDescription]
                    if origDesc then
                        humanoidDescription.HatAccessory = origDesc.HatAccessory
                        humanoidDescription.HairAccessory = origDesc.HairAccessory
                        humanoidDescription.FaceAccessory = origDesc.FaceAccessory
                        humanoidDescription.NeckAccessory = origDesc.NeckAccessory
                        humanoidDescription.ShoulderAccessory = origDesc.ShoulderAccessory
                        humanoidDescription.FrontAccessory = origDesc.FrontAccessory
                        humanoidDescription.BackAccessory = origDesc.BackAccessory
                        humanoidDescription.WaistAccessory = origDesc.WaistAccessory
                    end
                end
            end
        end,
        check = function(instance) return false end, -- Este tier se aplica globalmente, no a instancias individuales din谩micamente
        collect = function() return {} end,
        trackedList = {},
    },
}

-- FUNCIONES INTERNAS
local function applyTier(tierNum, instance)
    local tier = TIERS[tierNum]
    if tier and tier.apply then
        if tier.check(instance) then
            tier.apply(instance)
        elseif tierNum == 7 and not instance then -- Tier 7 es global
            tier.apply()
        end
    end
end

local function revertTier(tierNum, instance)
    local tier = TIERS[tierNum]
    if tier and tier.revert then
        if tier.check(instance) then
            tier.revert(instance)
        elseif tierNum == 7 and not instance then -- Tier 7 es global
            tier.revert()
        end
    end
end

local function applyAllTiersUpTo(targetTier)
    for i = 1, targetTier do
        local tier = TIERS[i]
        if tier then
            if i == 7 then -- Tier 7 es global
                tier.apply()
            else
                for _, instance in ipairs(tier.collect()) do
                    applyTier(i, instance)
                end
            end
        end
    end
end

local function revertAllTiersFrom(startTier)
    for i = startTier, 1, -1 do
        local tier = TIERS[i]
        if tier then
            if i == 7 then -- Tier 7 es global
                tier.revert()
            else
                for _, instance in ipairs(tier.trackedList) do
                    revertTier(i, instance)
                end
            end
        end
    end
end

local function updateTier(newTier, direction)
    if newTier == _currentTier then return end

    local oldTier = _currentTier
    _currentTier = math.clamp(newTier, 0, CONFIG.maxTier)

    if _currentTier > oldTier then
        for i = oldTier + 1, _currentTier do
            local tier = TIERS[i]
            if tier then
                if i == 7 then
                    tier.apply()
                else
                    for _, instance in ipairs(tier.collect()) do
                        applyTier(i, instance)
                    end
                end
            end
            if type(CONFIG.onTierChange) == "function" then
                CONFIG.onTierChange(i, "up")
            end
        end
    elseif _currentTier < oldTier then
        for i = oldTier, _currentTier + 1, -1 do
            local tier = TIERS[i]
            if tier then
                if i == 7 then
                    tier.revert()
                else
                    for _, instance in ipairs(tier.trackedList) do
                        revertTier(i, instance)
                    end
                end
            end
            if type(CONFIG.onTierChange) == "function" then
                CONFIG.onTierChange(i - 1, "down") -- Notificar el tier al que se baja
            end
        end
    end
end

local function onDescendantAdded(instance)
    if not _isRunning then return end
    for i = 1, _currentTier do
        applyTier(i, instance)
    end
end

-- API P脷BLICA

function OPT.Init(userConfig)
    if _isRunning then
        return false, "Optimizer is already running. Disable it first to change configuration."
    end
    for k, v in pairs(userConfig) do
        if CONFIG[k] ~= nil then
            CONFIG[k] = v
        else
            return false, "Invalid configuration key: " .. k
        end
    end
    return true
end

function OPT.Enable()
    if _isRunning then return end
    _isRunning = true

    -- Capturar valores originales globales si no se han capturado ya
    _originalCameraFOV = game.Workspace.CurrentCamera.FieldOfView
    _originalCameraFarPlane = game.Workspace.CurrentCamera.FarPlane
    _originalRenderingQualityLevel = settings().Rendering.QualityLevel
    _originalRenderingMeshPartDetailLevel = settings().Rendering.MeshPartDetailLevel
    _originalMaterialServiceUse2022Materials = MaterialService.Use2022Materials
    _originalMaterialServiceMaterials = {}
    for _, mat in pairs(MaterialService:GetChildren()) do
        _originalMaterialServiceMaterials[mat] = true
    end

    -- Aplicar el tier actual a todos los descendientes existentes
    applyAllTiersUpTo(_currentTier)

    -- Conectar a DescendantAdded para nuevos objetos
    _connectedEvents.DescendantAdded = Workspace.DescendantAdded:Connect(onDescendantAdded)

    -- Iniciar el loop de sampling de FPS
    _lastSampleTime = tick()
    _connectedEvents.RenderStepped = RunService.RenderStepped:Connect(function(deltaTime)
        _fpsCounter = _fpsCounter + 1
        table.insert(_fpsSamples, 1 / deltaTime)
        if #_fpsSamples > 60 then
            table.remove(_fpsSamples, 1)
        end

        local currentTime = tick()
        if currentTime - _lastSampleTime >= CONFIG.sampleInterval then
            _lastSampleTime = currentTime

            local sumFPS = 0
            for _, fps in ipairs(_fpsSamples) do
                sumFPS = sumFPS + fps
            end
            _fpsAverage = sumFPS / #_fpsSamples

            if _fpsAverage < CONFIG.targetFPS then
                _tierUpCounter = _tierUpCounter + 1
                _tierDownCounter = 0
                if _tierUpCounter >= CONFIG.confirmSamples then
                    _tierUpCounter = 0
                    if _currentTier < CONFIG.maxTier then
                        updateTier(_currentTier + 1, "up")
                    end
                end
            elseif _fpsAverage > CONFIG.targetFPS + CONFIG.recoverMargin then
                _tierDownCounter = _tierDownCounter + 1
                _tierUpCounter = 0
                if _tierDownCounter >= CONFIG.confirmSamples then
                    _tierDownCounter = 0
                    if _currentTier > 0 then
                        updateTier(_currentTier - 1, "down")
                    end
                end
            else
                _tierUpCounter = 0
                _tierDownCounter = 0
            end
        end
    end)
end

function OPT.Disable()
    if not _isRunning then return end
    _isRunning = false

    -- Desconectar eventos
    for _, connection in pairs(_connectedEvents) do
        connection:Disconnect()
    end
    _connectedEvents = {}

    -- Revertir todos los tiers aplicados
    revertAllTiersFrom(_currentTier)

    -- Restaurar valores originales globales
    local camera = Workspace.CurrentCamera
    camera.FieldOfView = _originalCameraFOV
    camera.FarPlane = _originalCameraFarPlane
    settings().Rendering.QualityLevel = _originalRenderingQualityLevel
    settings().Rendering.MeshPartDetailLevel = _originalRenderingMeshPartDetailLevel
    MaterialService.Use2022Materials = _originalMaterialServiceUse2022Materials
    for mat in pairs(_originalMaterialServiceMaterials) do
        if mat and not mat.Parent then
            mat.Parent = MaterialService
        end
    end

    -- Limpiar listas de objetos rastreados y valores originales
    _trackedEmitters = {}
    _trackedTrails = {}
    _trackedLights = {}
    _trackedDecals = {}
    _trackedTextures = {}
    _trackedSounds = {}
    _trackedHumanoids = {}
    _trackedParts = {}
    _trackedMeshParts = {}
    _trackedFaceInstances = {}
    _trackedShirtGraphics = {}
    _trackedPostEffects = {}
    _trackedExplosions = {}
    _trackedClothing = {}
    _originalValues = {}

    -- Resetear contadores de FPS y tiers
    _fpsSamples = {}
    _fpsCounter = 0
    _fpsAverage = 0
    _lastSampleTime = 0
    _tierUpCounter = 0
    _tierDownCounter = 0
    _currentTier = 0
end

function OPT.Toggle()
    if _isRunning then
        OPT.Disable()
        return false
    else
        OPT.Enable()
        return true
    end
end

function OPT.IsRunning()
    return _isRunning
end

function OPT.GetTier()
    return _currentTier
end

function OPT.GetFPS()
    return _fpsAverage
}

function OPT.GetConfig()
    local configCopy = {}
    for k, v in pairs(CONFIG) do
        configCopy[k] = v
    end
    return configCopy
end

function OPT.SetTier(n)
    local clampedTier = math.clamp(math.floor(n), 0, CONFIG.maxTier)
    if clampedTier == _currentTier then return end

    local oldTier = _currentTier
    _currentTier = clampedTier

    if _currentTier > oldTier then
        for i = oldTier + 1, _currentTier do
            local tier = TIERS[i]
            if tier then
                if i == 7 then
                    tier.apply()
                else
                    for _, instance in ipairs(tier.collect()) do
                        applyTier(i, instance)
                    end
                end
            end
            if type(CONFIG.onTierChange) == "function" then
                CONFIG.onTierChange(i, "up")
            end
        end
    elseif _currentTier < oldTier then
        for i = oldTier, _currentTier + 1, -1 do
            local tier = TIERS[i]
            if tier then
                if i == 7 then
                    tier.revert()
                else
                    for _, instance in ipairs(tier.trackedList) do
                        revertTier(i, instance)
                    end
                end
            end
            if type(CONFIG.onTierChange) == "function" then
                CONFIG.onTierChange(i - 1, "down") -- Notificar el tier al que se baja
            end
        end
    end
end

return OPT
