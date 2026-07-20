local Dagger = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    Range = 15,
    BehindDist = 2.1,
    Cooldown = 1.5,
    HoldDuration = 0.5,
    TweenDuration = 0.08,
    SmartMovement = true,
    ArcHeight = 1.8,
    Debug = false,
    ShowRange = false,
    Enabled = true,
    Keybind = Enum.KeyCode.Q,
    AlternativeKey = Enum.KeyCode.ButtonL2
}

local State = {
    LastTP = 0,
    isTPActive = false,
    RangeIndicator = nil,
    TargetKiller = nil
}

local function DebugLog(...)
    if Config.Debug then
        print("[DAGGER]", ...)
    end
end

local function GetChar()
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    return char
end

local function GetHRP(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetKiller()
    local pf = Workspace:FindFirstChild("Players")
    if not pf then return nil end
    local kf = pf:FindFirstChild("Killers")
    if not kf then return nil end
    for _, k in pairs(kf:GetChildren()) do
        if k:IsA("Model") then
            local hrp = k:FindFirstChild("HumanoidRootPart")
            local hum = k:FindFirstChildWhichIsA("Humanoid")
            if hrp and hum and hum.Health and hum.Health > 0 then
                return k
            end
        end
    end
    return nil
end

local function GetDagger()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local mui = pg:FindFirstChild("MainUI")
    if not mui then return nil end
    local ac = mui:FindFirstChild("AbilityContainer")
    if not ac then return nil end
    return ac:FindFirstChild("Dagger")
end

local function GetCooldown()
    local btn = GetDagger()
    if not btn then return 999 end
    local cd = btn:FindFirstChild("CooldownTime") or btn:FindFirstChild("Cooldown")
    if not cd then return 0 end
    if cd:IsA("NumberValue") then
        return cd.Value
    elseif cd:IsA("StringValue") then
        return tonumber(cd.Value) or 0
    elseif cd:IsA("TextLabel") or cd:IsA("TextBox") then
        return tonumber(cd.Text) or 0
    end
    return 0
end

local function IsKillerBehind(hrp, khrp)
    if not hrp or not khrp then return false end
    local lookVector = hrp.CFrame.LookVector
    local toKiller = (khrp.Position - hrp.Position).Unit
    local dotProduct = lookVector:Dot(toKiller)
    return dotProduct < -0.3
end

local function SmartArcMovement(hrp, khrp, targetCFrame, duration)
    local startPos = hrp.Position
    local endPos = targetCFrame.Position
    local dist = (endPos - startPos).Magnitude
    
    if dist < 3 then
        local steps = math.floor(duration / 0.02)
        if steps < 1 then steps = 1 end
        local stepTime = duration / steps
        for i = 1, steps do
            local alpha = i / steps
            local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
            local currentPos = startPos:Lerp(endPos, smoothAlpha)
            hrp.CFrame = CFrame.new(currentPos, endPos + targetCFrame.LookVector)
            task.wait(stepTime)
        end
        hrp.CFrame = targetCFrame
        return
    end
    
    local midPoint = (startPos + endPos) / 2
    local direction = (endPos - startPos).Unit
    local perpendicular = Vector3.new(-direction.Z, 0, direction.X).Unit
    local toKiller = (khrp.Position - startPos).Unit
    local side = 1
    if perpendicular:Dot(toKiller) < 0 then
        side = -1
    end
    
    local arcHeight = math.min(Config.ArcHeight, dist * 0.4)
    local arcPoint = midPoint + perpendicular * arcHeight * side + Vector3.new(0, 0.3, 0)
    
    local steps = math.floor(duration / 0.015)
    if steps < 1 then steps = 1 end
    local stepTime = duration / steps
    
    for i = 1, steps do
        local alpha = i / steps
        local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
        local p1 = startPos:Lerp(arcPoint, smoothAlpha)
        local p2 = arcPoint:Lerp(endPos, smoothAlpha)
        local currentPos = p1:Lerp(p2, smoothAlpha)
        local lookTarget = khrp.Position
        hrp.CFrame = CFrame.new(currentPos, lookTarget)
        task.wait(stepTime)
    end
    
    hrp.CFrame = targetCFrame
end

local function DirectMovement(hrp, targetCFrame, duration)
    local startPos = hrp.Position
    local endPos = targetCFrame.Position
    local steps = math.floor(duration / 0.015)
    if steps < 1 then steps = 1 end
    local stepTime = duration / steps
    for i = 1, steps do
        local alpha = i / steps
        local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
        local currentPos = startPos:Lerp(endPos, smoothAlpha)
        local currentCFrame = CFrame.new(currentPos, targetCFrame.Position + targetCFrame.LookVector)
        hrp.CFrame = currentCFrame
        task.wait(stepTime)
    end
    hrp.CFrame = targetCFrame
end

local function CreateDashEffect(startPos, endPos)
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.8, 0.8, 0.8)
    part.CFrame = CFrame.new(startPos, endPos)
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new("Bright blue")
    part.Transparency = 0.5
    part.Parent = Workspace
    
    local trail = Instance.new("Trail")
    trail.Parent = part
    trail.Lifetime = 0.15
    trail.MinLength = 0.3
    trail.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
    trail.Transparency = NumberSequence.new(0.7)
    
    local tween = TweenService:Create(part, TweenInfo.new(0.2), {
        Transparency = 1,
        Size = Vector3.new(0.1, 0.1, 0.1)
    })
    tween:Play()
    tween.Completed:Connect(function()
        part:Destroy()
    end)
end

local function UpdateRangeIndicator()
    if not Config.ShowRange then
        if State.RangeIndicator then
            State.RangeIndicator:Destroy()
            State.RangeIndicator = nil
        end
        return
    end
    
    local killer = GetKiller()
    if not killer then
        if State.RangeIndicator then
            State.RangeIndicator:Destroy()
            State.RangeIndicator = nil
        end
        return
    end
    
    local khrp = GetHRP(killer)
    if not khrp then return end
    
    if not State.RangeIndicator then
        local circle = Instance.new("Part")
        circle.Size = Vector3.new(Config.Range * 2, 0.1, Config.Range * 2)
        circle.Shape = Enum.PartType.Cylinder
        circle.Anchored = true
        circle.CanCollide = false
        circle.Material = Enum.Material.Neon
        circle.BrickColor = BrickColor.new("Bright green")
        circle.Transparency = 0.7
        circle.TopSurface = Enum.SurfaceType.Smooth
        circle.BottomSurface = Enum.SurfaceType.Smooth
        
        local mesh = Instance.new("CylinderMesh")
        mesh.Parent = circle
        
        local attachment = Instance.new("Attachment")
        attachment.Parent = circle
        
        local highlight = Instance.new("Highlight")
        highlight.Parent = circle
        highlight.FillColor = Color3.fromRGB(0, 255, 100)
        highlight.OutlineColor = Color3.fromRGB(0, 255, 100)
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.5
        
        State.RangeIndicator = circle
        State.RangeIndicator.Parent = Workspace
    end
    
    State.RangeIndicator.Position = khrp.Position - Vector3.new(0, 0.5, 0)
    local inRange = false
    local char = GetChar()
    if char then
        local phrp = GetHRP(char)
        if phrp then
            local dist = (khrp.Position - phrp.Position).Magnitude
            if dist <= Config.Range then
                inRange = true
            end
        end
    end
    
    if inRange then
        State.RangeIndicator.BrickColor = BrickColor.new("Bright green")
        State.RangeIndicator.Transparency = 0.5
    else
        State.RangeIndicator.BrickColor = BrickColor.new("Bright red")
        State.RangeIndicator.Transparency = 0.7
    end
end

local function TP()
    if not Config.Enabled then
        DebugLog("Dagger desactivado")
        return false
    end
    
    if State.isTPActive then
        DebugLog("TP ya activo")
        return false
    end
    
    local currentTime = os.clock()
    local timeSinceLast = currentTime - State.LastTP
    if timeSinceLast < Config.Cooldown then
        DebugLog("En cooldown:", timeSinceLast, "s")
        return false
    end
    
    local daggerCD = GetCooldown()
    if daggerCD and daggerCD > 0.1 then
        DebugLog("Daga en cooldown")
        return false
    end
    
    local char = GetChar()
    if not char then
        DebugLog("Personaje no disponible")
        return false
    end
    
    local phrp = GetHRP(char)
    if not phrp then
        DebugLog("HRP no encontrado")
        return false
    end
    
    local killer = GetKiller()
    if not killer then
        DebugLog("Killer no encontrado")
        return false
    end
    
    local khrp = GetHRP(killer)
    if not khrp then
        DebugLog("HRP del killer no encontrado")
        return false
    end
    
    local dist = (khrp.Position - phrp.Position).Magnitude
    if dist > Config.Range then
        DebugLog("Fuera de rango:", dist, ">", Config.Range)
        return false
    end
    
    local lv = khrp.CFrame.LookVector.Unit
    local bp = khrp.Position - (lv * Config.BehindDist)
    local tp = Vector3.new(bp.X, phrp.Position.Y, bp.Z)
    local targetCFrame = CFrame.new(tp, tp + lv)
    
    State.isTPActive = true
    local startPos = phrp.Position
    local success = false
    
    local killerBehind = IsKillerBehind(phrp, khrp)
    
    if Config.SmartMovement and killerBehind then
        success = pcall(function()
            SmartArcMovement(phrp, khrp, targetCFrame, Config.TweenDuration)
        end)
    else
        success = pcall(function()
            DirectMovement(phrp, targetCFrame, Config.TweenDuration)
        end)
    end
    
    if success then
        State.LastTP = currentTime
        DebugLog("TP exitoso")
        
        task.spawn(function()
            CreateDashEffect(startPos, tp)
        end)
        
        local startTime = tick()
        while tick() - startTime < Config.HoldDuration do
            local killer = GetKiller()
            if killer then
                local khrp = GetHRP(killer)
                if khrp then
                    local lv = khrp.CFrame.LookVector.Unit
                    local bp = khrp.Position - (lv * Config.BehindDist)
                    local tp = Vector3.new(bp.X, phrp.Position.Y, bp.Z)
                    phrp.CFrame = CFrame.new(tp, tp + lv)
                end
            end
            task.wait()
        end
        
        State.isTPActive = false
        return true
    else
        State.isTPActive = false
        DebugLog("TP falló")
        return false
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not Config.Enabled then return end
    
    if input.KeyCode == Config.Keybind or input.KeyCode == Config.AlternativeKey then
        task.spawn(TP)
    end
end)

RunService.Heartbeat:Connect(function()
    if Config.ShowRange then
        UpdateRangeIndicator()
    elseif State.RangeIndicator then
        State.RangeIndicator:Destroy()
        State.RangeIndicator = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    State.isTPActive = false
    if State.RangeIndicator then
        State.RangeIndicator:Destroy()
        State.RangeIndicator = nil
    end
end)

function Dagger.State(enabled)
    Config.Enabled = enabled == true
    DebugLog("Estado:", enabled and "Activado" or "Desactivado")
    return Config.Enabled
end

function Dagger.Range(value)
    if value then
        Config.Range = tonumber(value) or 15
        DebugLog("Rango:", Config.Range)
    end
    return Config.Range
end

function Dagger.BehindDist(value)
    if value then
        Config.BehindDist = tonumber(value) or 2.1
        DebugLog("Distancia detrás:", Config.BehindDist)
    end
    return Config.BehindDist
end

function Dagger.Cooldown(value)
    if value then
        Config.Cooldown = tonumber(value) or 1.5
        DebugLog("Cooldown:", Config.Cooldown)
    end
    return Config.Cooldown
end

function Dagger.Hold(value)
    if value then
        Config.HoldDuration = tonumber(value) or 0.5
        DebugLog("Duración de mantenimiento:", Config.HoldDuration)
    end
    return Config.HoldDuration
end

function Dagger.Speed(value)
    if value then
        Config.TweenDuration = tonumber(value) or 0.08
        DebugLog("Velocidad:", Config.TweenDuration)
    end
    return Config.TweenDuration
end

function Dagger.Smart(enabled)
    if enabled ~= nil then
        Config.SmartMovement = enabled == true
        DebugLog("Movimiento inteligente:", Config.SmartMovement and "Activado" or "Desactivado")
    end
    return Config.SmartMovement
end

function Dagger.ArcHeight(value)
    if value then
        Config.ArcHeight = tonumber(value) or 1.8
        DebugLog("Altura del arco:", Config.ArcHeight)
    end
    return Config.ArcHeight
end

function Dagger.Debug(enabled)
    if enabled ~= nil then
        Config.Debug = enabled == true
        DebugLog("Debug:", Config.Debug and "Activado" or "Desactivado")
    end
    return Config.Debug
end

function Dagger.Ratio(enabled)
    if enabled ~= nil then
        Config.ShowRange = enabled == true
        DebugLog("Indicador de rango:", Config.ShowRange and "Activado" or "Desactivado")
        if not Config.ShowRange and State.RangeIndicator then
            State.RangeIndicator:Destroy()
            State.RangeIndicator = nil
        end
    end
    return Config.ShowRange
end

function Dagger.Keybind(key)
    if key then
        if type(key) == "string" then
            key = Enum.KeyCode[key]
        end
        if key then
            Config.Keybind = key
            DebugLog("Tecla principal:", Config.Keybind.Name)
        end
    end
    return Config.Keybind
end

function Dagger.AltKey(key)
    if key then
        if type(key) == "string" then
            key = Enum.KeyCode[key]
        end
        if key then
            Config.AlternativeKey = key
            DebugLog("Tecla alternativa:", Config.AlternativeKey.Name)
        end
    end
    return Config.AlternativeKey
end

function Dagger.GetStatus()
    print("=== DAGGER STATUS ===")
    print("Estado:", Config.Enabled and "Activado" or "Desactivado")
    print("Rango:", Config.Range)
    print("Distancia detrás:", Config.BehindDist)
    print("Cooldown:", Config.Cooldown)
    print("Duración de mantenimiento:", Config.HoldDuration)
    print("Velocidad:", Config.TweenDuration, "s")
    print("Movimiento inteligente:", Config.SmartMovement and "Activado" or "Desactivado")
    print("Altura del arco:", Config.ArcHeight)
    print("Indicador de rango:", Config.ShowRange and "Activado" or "Desactivado")
    print("Debug:", Config.Debug and "Activado" or "Desactivado")
    print("Tecla principal:", Config.Keybind.Name)
    print("Tecla alternativa:", Config.AlternativeKey.Name)
    print("TP Activo:", State.isTPActive)
    print("Killer:", GetKiller() and GetKiller().Name or "No encontrado")
    print("======================")
end

function Dagger.TP()
    return TP()
end

DebugLog("=== DAGGER LOADED ===")
DebugLog("Usa Dagger.GetStatus() para ver configuración")
DebugLog("Comandos disponibles:")
DebugLog("  Dagger.State(true/false) - Activar/desactivar")
DebugLog("  Dagger.Ratio(true/false) - Mostrar indicador de rango")
DebugLog("  Dagger.Range(numero) - Cambiar rango")
DebugLog("  Dagger.BehindDist(numero) - Cambiar distancia detrás")
DebugLog("  Dagger.Cooldown(numero) - Cambiar cooldown")
DebugLog("  Dagger.Hold(numero) - Cambiar duración de mantenimiento")
DebugLog("  Dagger.Speed(numero) - Cambiar velocidad (0.05-0.2)")
DebugLog("  Dagger.Smart(true/false) - Activar movimiento inteligente")
DebugLog("  Dagger.ArcHeight(numero) - Cambiar altura del arco")
DebugLog("  Dagger.Keybind('Q') - Cambiar tecla principal")
DebugLog("  Dagger.AltKey('ButtonL2') - Cambiar tecla alternativa")
DebugLog("  Dagger.Debug(true/false) - Activar/desactivar debug")
DebugLog("  Dagger.GetStatus() - Ver estado actual")
DebugLog("  Dagger.TP() - Ejecutar TP manualmente")

return Dagger