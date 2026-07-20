local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    Enabled = true,
    Debug = false,
    ShowRange = false,
    
    Behind = {
        Mode = "standard",
        Standard = {
            Range = 15,
            BehindDist = 2.1,
            Duration = 0.08
        },
        Larger = {
            Range = 30,
            BehindDist = 2.5,
            Duration = 0.7
        }
    },
    
    Front = {
        Mode = "rodear",
        Rodear = {
            Duration = 0.08,
            ArcHeight = 1.8,
            BehindDist = 2.1
        },
        Standard = {
            Duration = 0.15,
            BehindDist = 2.1
        }
    },
    
    HoldDuration = 0.5,
    Cooldown = 1.5
}

local isTPActive = false
local LastTP = 0
local CurrentMode = nil
local RangeCircle = nil
local RangeConnection = nil
local CurrentRange = 0

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

local function GetCurrentRange()
    local killer = GetKiller()
    if not killer then return 0 end
    
    local char = GetChar()
    if not char then return 0 end
    
    local phrp = GetHRP(char)
    local khrp = GetHRP(killer)
    if not phrp or not khrp then return 0 end
    
    local isBehind = IsKillerBehind(phrp, khrp)
    
    if isBehind then
        local mode = Config.Behind.Mode
        local modeConfig = Config.Behind[mode]
        if modeConfig then
            return modeConfig.Range or 15
        end
    else
        local mode = Config.Front.Mode
        local modeConfig = Config.Front[mode]
        if modeConfig then
            return modeConfig.Range or 12
        end
    end
    
    return 15
end

local function CreateRangeCircle()
    if RangeCircle then
        RangeCircle:Destroy()
        RangeCircle = nil
    end
    
    if not Config.ShowRange then return end
    
    local killer = GetKiller()
    if not killer then return end
    
    local khrp = GetHRP(killer)
    if not khrp then return end
    
    local range = GetCurrentRange()
    CurrentRange = range
    
    local circle = Instance.new("Part")
    circle.Name = "RangeCircle"
    circle.Size = Vector3.new(range * 2, 0.1, range * 2)
    circle.Shape = Enum.PartType.Cylinder
    circle.Anchored = true
    circle.CanCollide = false
    circle.CanQuery = false
    circle.CanTouch = false
    circle.Transparency = 0.7
    circle.Material = Enum.Material.Neon
    circle.BrickColor = BrickColor.new("Bright blue")
    circle.CFrame = CFrame.new(khrp.Position - Vector3.new(0, 1.5, 0))
    circle.Parent = Workspace
    
    -- Crear efecto de borde brillante
    local attachment = Instance.new("Attachment")
    attachment.Parent = circle
    
    local beam = Instance.new("Beam")
    beam.Parent = circle
    beam.Attachment0 = attachment
    beam.Attachment1 = attachment
    beam.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
    beam.Transparency = NumberSequence.new(0.7)
    beam.Width0 = 0.05
    beam.Width1 = 0.05
    beam.LightEmission = 0.5
    beam.Enabled = true
    
    RangeCircle = circle
    DebugLog("Círculo de rango creado:", range)
end

local function UpdateRangeCircle()
    if not Config.ShowRange then
        if RangeCircle then
            RangeCircle:Destroy()
            RangeCircle = nil
        end
        return
    end
    
    local killer = GetKiller()
    if not killer then
        if RangeCircle then
            RangeCircle:Destroy()
            RangeCircle = nil
        end
        return
    end
    
    local khrp = GetHRP(killer)
    if not khrp then
        if RangeCircle then
            RangeCircle:Destroy()
            RangeCircle = nil
        end
        return
    end
    
    local newRange = GetCurrentRange()
    
    if not RangeCircle then
        CreateRangeCircle()
        return
    end
    
    -- Actualizar si el rango cambió
    if CurrentRange ~= newRange then
        CurrentRange = newRange
        local targetSize = Vector3.new(newRange * 2, 0.1, newRange * 2)
        
        -- Animación suave al cambiar de tamaño
        local tween = TweenService:Create(RangeCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = targetSize,
            Transparency = 0.7
        })
        tween:Play()
        
        DebugLog("Rango actualizado:", newRange)
    end
    
    -- Actualizar posición (sigue al killer)
    RangeCircle.CFrame = CFrame.new(khrp.Position - Vector3.new(0, 1.5, 0))
end

local function StartRangeUpdater()
    if RangeConnection then
        RangeConnection:Disconnect()
        RangeConnection = nil
    end
    
    if not Config.ShowRange then return end
    
    RangeConnection = RunService.Heartbeat:Connect(function()
        UpdateRangeCircle()
    end)
    
    DebugLog("Updater de rango iniciado")
end

local function StopRangeUpdater()
    if RangeConnection then
        RangeConnection:Disconnect()
        RangeConnection = nil
    end
    
    if RangeCircle then
        RangeCircle:Destroy()
        RangeCircle = nil
    end
    
    DebugLog("Updater de rango detenido")
end

local function SmoothMovement(hrp, targetCFrame, duration)
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

local function ArcMovement(hrp, khrp, targetCFrame, duration, arcHeight)
    local startPos = hrp.Position
    local endPos = targetCFrame.Position
    
    local dist = (endPos - startPos).Magnitude
    if dist < 3 then
        SmoothMovement(hrp, targetCFrame, duration)
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
    
    local actualHeight = math.min(arcHeight, dist * 0.4)
    local arcPoint = midPoint + perpendicular * actualHeight * side + Vector3.new(0, 0.3, 0)
    
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

local function ExecuteTP()
    if not Config.Enabled then
        DebugLog("Deshabilitado")
        return false
    end
    
    if isTPActive then
        DebugLog("Ya activo")
        return false
    end
    
    local currentTime = os.clock()
    if currentTime - LastTP < Config.Cooldown then
        DebugLog("En cooldown")
        return false
    end
    
    local daggerCD = GetCooldown()
    if daggerCD and daggerCD > 0.1 then
        DebugLog("Daga en cooldown")
        return false
    end
    
    local char = GetChar()
    if not char then return false end
    
    local phrp = GetHRP(char)
    if not phrp then return false end
    
    local killer = GetKiller()
    if not killer then return false end
    
    local khrp = GetHRP(killer)
    if not khrp then return false end
    
    local dist = (khrp.Position - phrp.Position).Magnitude
    local isBehind = IsKillerBehind(phrp, khrp)
    
    local modeConfig
    local modeName
    local range
    
    if isBehind then
        modeName = Config.Behind.Mode
        modeConfig = Config.Behind[modeName]
        if not modeConfig then
            DebugLog("Modo detrás inválido:", modeName)
            return false
        end
        
        range = modeConfig.Range or 15
        if dist > range then
            DebugLog("Fuera de rango:", dist, ">", range)
            return false
        end
        
        DebugLog("Modo DETRÁS:", modeName)
    else
        modeName = Config.Front.Mode
        modeConfig = Config.Front[modeName]
        if not modeConfig then
            DebugLog("Modo enfrente inválido:", modeName)
            return false
        end
        
        range = modeConfig.Range or 12
        if dist > range then
            DebugLog("Fuera de rango:", dist, ">", range)
            return false
        end
        
        DebugLog("Modo ENFRENTE:", modeName)
    end
    
    local behindDist = modeConfig.BehindDist or 2.1
    local duration = modeConfig.Duration or 0.15
    local lv = khrp.CFrame.LookVector.Unit
    local bp = khrp.Position - (lv * behindDist)
    local tp = Vector3.new(bp.X, phrp.Position.Y, bp.Z)
    local targetCFrame = CFrame.new(tp, tp + lv)
    
    DebugLog("Posición actual:", phrp.Position)
    DebugLog("Posición killer:", khrp.Position)
    DebugLog("Destino:", tp)
    DebugLog("Duración:", duration, "s")
    
    isTPActive = true
    CurrentMode = modeName
    
    local success = false
    if isBehind then
        success = pcall(function()
            SmoothMovement(phrp, targetCFrame, duration)
        end)
    else
        if modeName == "rodear" then
            local arcHeight = modeConfig.ArcHeight or 1.8
            success = pcall(function()
                ArcMovement(phrp, khrp, targetCFrame, duration, arcHeight)
            end)
        else
            success = pcall(function()
                SmoothMovement(phrp, targetCFrame, duration)
            end)
        end
    end
    
    if success then
        LastTP = currentTime
        DebugLog("✓ TP exitoso!")
        
        local startTime = tick()
        while tick() - startTime < Config.HoldDuration do
            local killer = GetKiller()
            if killer then
                local khrp = GetHRP(killer)
                if khrp then
                    local lv = khrp.CFrame.LookVector.Unit
                    local bp = khrp.Position - (lv * behindDist)
                    local tp = Vector3.new(bp.X, phrp.Position.Y, bp.Z)
                    phrp.CFrame = CFrame.new(tp, tp + lv)
                end
            end
            task.wait()
        end
        
        isTPActive = false
        return true
    else
        isTPActive = false
        DebugLog("✗ TP falló")
        return false
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not Config.Enabled then return end
    
    if input.KeyCode == Enum.KeyCode.ButtonL2 or input.KeyCode == Enum.KeyCode.Q then
        task.spawn(ExecuteTP)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    isTPActive = false
    task.wait(1)
end)

local Dagger = {
    State = function(enabled)
        Config.Enabled = enabled == true
        DebugLog("Estado:", enabled and "Activado" or "Desactivado")
        if not enabled then
            StopRangeUpdater()
        elseif Config.ShowRange then
            StartRangeUpdater()
        end
    end,
    
    SetBehindMode = function(mode)
        if mode == "standard" or mode == "larger" then
            Config.Behind.Mode = mode
            DebugLog("Modo detrás cambiado a:", mode)
            if Config.ShowRange then
                UpdateRangeCircle()
            end
        else
            DebugLog("Modo inválido. Usa: standard, larger")
        end
    end,
    
    SetFrontMode = function(mode)
        if mode == "rodear" or mode == "standard" then
            Config.Front.Mode = mode
            DebugLog("Modo enfrente cambiado a:", mode)
            if Config.ShowRange then
                UpdateRangeCircle()
            end
        else
            DebugLog("Modo inválido. Usa: rodear, standard")
        end
    end,
    
    SetCooldown = function(value)
        Config.Cooldown = tonumber(value) or 1.5
        DebugLog("Cooldown:", Config.Cooldown)
    end,
    
    SetHold = function(value)
        Config.HoldDuration = tonumber(value) or 0.5
        DebugLog("Hold duration:", Config.HoldDuration)
    end,
    
    SetDebug = function(enabled)
        Config.Debug = enabled == true
        DebugLog("Debug:", enabled and "Activado" or "Desactivado")
    end,
    
    Ratio = function(enabled)
        Config.ShowRange = enabled == true
        
        if enabled then
            DebugLog("Mostrando rango...")
            CreateRangeCircle()
            StartRangeUpdater()
        else
            DebugLog("Ocultando rango...")
            StopRangeUpdater()
        end
    end,
    
    GetStatus = function()
        print("=== DAGGER STATUS ===")
        print("Estado:", Config.Enabled and "Activado" or "Desactivado")
        print("Modo Detrás:", Config.Behind.Mode)
        print("Modo Enfrente:", Config.Front.Mode)
        print("Cooldown:", Config.Cooldown)
        print("Hold Duration:", Config.HoldDuration)
        print("Mostrar Rango:", Config.ShowRange and "Sí" or "No")
        print("TP Activo:", isTPActive)
        print("Último TP:", LastTP)
        print("Modo Actual:", CurrentMode or "Ninguno")
        print("Rango Actual:", CurrentRange)
        print("Killer:", GetKiller() and GetKiller().Name or "No encontrado")
        print("=====================")
    end,
    
    GetConfig = function()
        return Config
    end
}

DebugLog("=== DAGGER LOADED ===")
DebugLog("Modo detrás:", Config.Behind.Mode)
DebugLog("Modo enfrente:", Config.Front.Mode)
DebugLog("Usa Dagger.Ratio(true) para mostrar el rango")

return Dagger