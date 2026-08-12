-- ============================================================
-- MÓDULO: DAGGER (TP Behind Killer)
-- ============================================================
local DaggerModule = {}

local DaggerPlayers = game:GetService("Players")
local DaggerWorkspace = game:GetService("Workspace")
local DaggerUIS = game:GetService("UserInputService")
local DaggerTweenService = game:GetService("TweenService")
local DaggerRunService = game:GetService("RunService")
local DaggerLocalPlayer = DaggerPlayers.LocalPlayer

local DaggerConfig = {
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

local DaggerState = {
    LastTP = 0,
    isTPActive = false,
    RangeIndicator = nil,
    TargetKiller = nil,
    ButtonConnected = false,
    ButtonConnection = nil
}

local function DaggerDebug(...)
    if DaggerConfig.Debug then
        print("[DAGGER]", ...)
    end
end

local function GetChar()
    local char = DaggerLocalPlayer.Character
    if not char then
        char = DaggerLocalPlayer.CharacterAdded:Wait()
    end
    return char
end

local function GetHRP(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetKiller()
    local pf = DaggerWorkspace:FindFirstChild("Players")
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
    local pg = DaggerLocalPlayer:FindFirstChild("PlayerGui")
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

    local arcHeight = math.min(DaggerConfig.ArcHeight, dist * 0.4)
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
    part.Parent = DaggerWorkspace

    local trail = Instance.new("Trail")
    trail.Parent = part
    trail.Lifetime = 0.15
    trail.MinLength = 0.3
    trail.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
    trail.Transparency = NumberSequence.new(0.7)

    local tween = DaggerTweenService:Create(part, TweenInfo.new(0.2), {
        Transparency = 1,
        Size = Vector3.new(0.1, 0.1, 0.1)
    })
    tween:Play()
    tween.Completed:Connect(function()
        part:Destroy()
    end)
end

local function UpdateRangeIndicator()
    if not DaggerConfig.ShowRange then
        if DaggerState.RangeIndicator then
            DaggerState.RangeIndicator:Destroy()
            DaggerState.RangeIndicator = nil
        end
        return
    end

    local killer = GetKiller()
    if not killer then
        if DaggerState.RangeIndicator then
            DaggerState.RangeIndicator:Destroy()
            DaggerState.RangeIndicator = nil
        end
        return
    end

    local khrp = GetHRP(killer)
    if not khrp then return end

    if not DaggerState.RangeIndicator then
        local circle = Instance.new("Part")
        circle.Size = Vector3.new(DaggerConfig.Range * 2, 0.1, DaggerConfig.Range * 2)
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

        DaggerState.RangeIndicator = circle
        DaggerState.RangeIndicator.Parent = DaggerWorkspace
    end

    DaggerState.RangeIndicator.Position = khrp.Position - Vector3.new(0, 0.5, 0)
    local inRange = false
    local char = GetChar()
    if char then
        local phrp = GetHRP(char)
        if phrp then
            local dist = (khrp.Position - phrp.Position).Magnitude
            if dist <= DaggerConfig.Range then
                inRange = true
            end
        end
    end

    if inRange then
        DaggerState.RangeIndicator.BrickColor = BrickColor.new("Bright green")
        DaggerState.RangeIndicator.Transparency = 0.5
    else
        DaggerState.RangeIndicator.BrickColor = BrickColor.new("Bright red")
        DaggerState.RangeIndicator.Transparency = 0.7
    end
end

local function DaggerTP()
    if not DaggerConfig.Enabled then
        DaggerDebug("Dagger desactivado")
        return false
    end

    if DaggerState.isTPActive then
        DaggerDebug("TP ya activo")
        return false
    end

    local currentTime = os.clock()
    local timeSinceLast = currentTime - DaggerState.LastTP
    if timeSinceLast < DaggerConfig.Cooldown then
        DaggerDebug("En cooldown:", timeSinceLast, "s")
        return false
    end

    local daggerCD = GetCooldown()
    if daggerCD and daggerCD > 0.1 then
        DaggerDebug("Daga en cooldown")
        return false
    end

    local char = GetChar()
    if not char then
        DaggerDebug("Personaje no disponible")
        return false
    end

    local phrp = GetHRP(char)
    if not phrp then
        DaggerDebug("HRP no encontrado")
        return false
    end

    local killer = GetKiller()
    if not killer then
        DaggerDebug("Killer no encontrado")
        return false
    end

    local khrp = GetHRP(killer)
    if not khrp then
        DaggerDebug("HRP del killer no encontrado")
        return false
    end

    local dist = (khrp.Position - phrp.Position).Magnitude
    if dist > DaggerConfig.Range then
        DaggerDebug("Fuera de rango:", dist, ">", DaggerConfig.Range)
        return false
    end

    local lv = khrp.CFrame.LookVector.Unit
    local bp = khrp.Position - (lv * DaggerConfig.BehindDist)
    local tp = Vector3.new(bp.X, phrp.Position.Y, bp.Z)
    local targetCFrame = CFrame.new(tp, tp + lv)

    DaggerState.isTPActive = true
    local startPos = phrp.Position
    local success = false

    local killerBehind = IsKillerBehind(phrp, khrp)

    if DaggerConfig.SmartMovement and killerBehind then
        success = pcall(function()
            SmartArcMovement(phrp, khrp, targetCFrame, DaggerConfig.TweenDuration)
        end)
    else
        success = pcall(function()
            DirectMovement(phrp, targetCFrame, DaggerConfig.TweenDuration)
        end)
    end

    if success then
        DaggerState.LastTP = currentTime
        DaggerDebug("TP exitoso")

        task.spawn(function()
            CreateDashEffect(startPos, tp)
        end)

        local startTime = tick()
        while tick() - startTime < DaggerConfig.HoldDuration do
            local killer = GetKiller()
            if killer then
                local khrp = GetHRP(killer)
                if khrp then
                    local lv = khrp.CFrame.LookVector.Unit
                    local bp = khrp.Position - (lv * DaggerConfig.BehindDist)
                    local tp = Vector3.new(bp.X, phrp.Position.Y, bp.Z)
                    phrp.CFrame = CFrame.new(tp, tp + lv)
                end
            end
            task.wait()
        end

        DaggerState.isTPActive = false
        return true
    else
        DaggerState.isTPActive = false
        DaggerDebug("TP falló")
        return false
    end
end

local function ConnectButtonListener()
    local button = GetDagger()
    if not button then
        DaggerDebug("Botón Dagger no encontrado para conectar listener")
        return false
    end

    if DaggerState.ButtonConnected then
        DaggerState.ButtonConnected = false
    end

    local connection
    connection = button.MouseButton1Click:Connect(function()
        DaggerDebug("Botón Dagger clickeado")
        local cd = GetCooldown()
        if cd and cd > 0.1 then
            DaggerDebug("Botón en cooldown:", cd)
            return
        end
        task.spawn(DaggerTP)
    end)

    DaggerState.ButtonConnection = connection
    DaggerState.ButtonConnected = true
    DaggerDebug("Listener del botón Dagger conectado exitosamente")
    return true
end

local function SetupButtonListener()
    local pg = DaggerLocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        DaggerLocalPlayer:WaitForChild("PlayerGui")
        pg = DaggerLocalPlayer.PlayerGui
    end

    local mui = pg:FindFirstChild("MainUI")
    if not mui then
        mui = pg:WaitForChild("MainUI")
    end

    local ac = mui:FindFirstChild("AbilityContainer")
    if not ac then
        ac = mui:WaitForChild("AbilityContainer")
    end

    local button = ac:FindFirstChild("Dagger")
    if not button then
        button = ac:WaitForChild("Dagger")
    end

    ConnectButtonListener()

    local function onButtonChanged()
        local newButton = ac:FindFirstChild("Dagger")
        if newButton and not DaggerState.ButtonConnected then
            ConnectButtonListener()
        elseif not newButton and DaggerState.ButtonConnected then
            DaggerState.ButtonConnected = false
            DaggerState.ButtonConnection = nil
        end
    end

    ac.ChildAdded:Connect(function(child)
        if child.Name == "Dagger" then
            task.wait(0.1)
            ConnectButtonListener()
        end
    end)

    ac.ChildRemoved:Connect(function(child)
        if child.Name == "Dagger" then
            DaggerState.ButtonConnected = false
            DaggerState.ButtonConnection = nil
        end
    end)
end

DaggerUIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not DaggerConfig.Enabled then return end

    if input.KeyCode == DaggerConfig.Keybind or input.KeyCode == DaggerConfig.AlternativeKey then
        task.spawn(DaggerTP)
    end
end)

DaggerRunService.Heartbeat:Connect(function()
    if DaggerConfig.ShowRange then
        UpdateRangeIndicator()
    elseif DaggerState.RangeIndicator then
        DaggerState.RangeIndicator:Destroy()
        DaggerState.RangeIndicator = nil
    end
end)

DaggerLocalPlayer.CharacterAdded:Connect(function()
    DaggerState.isTPActive = false
    if DaggerState.RangeIndicator then
        DaggerState.RangeIndicator:Destroy()
        DaggerState.RangeIndicator = nil
    end
    task.wait(1)
    SetupButtonListener()
end)

local function InitializeDagger()
    DaggerDebug("Inicializando Dagger...")
    local success = pcall(SetupButtonListener)
    if success then
        DaggerDebug("Listener del botón inicializado correctamente")
    else
        DaggerDebug("Error al inicializar el listener del botón")
    end
end

task.spawn(function()
    if DaggerLocalPlayer:FindFirstChild("PlayerGui")
       and DaggerLocalPlayer.PlayerGui:FindFirstChild("MainUI") then
        InitializeDagger()
        return
    end
    local pg = DaggerLocalPlayer:WaitForChild("PlayerGui", 30)
    if not pg then return end
    local mui = pg:WaitForChild("MainUI", 30)
    if not mui then return end
    InitializeDagger()
end)

function DaggerModule.State(enabled)
    DaggerConfig.Enabled = enabled == true
    DaggerDebug("Estado:", enabled and "Activado" or "Desactivado")
    return DaggerConfig.Enabled
end

function DaggerModule.Range(value)
    if value then
        DaggerConfig.Range = tonumber(value) or 15
        DaggerDebug("Rango:", DaggerConfig.Range)
    end
    return DaggerConfig.Range
end

function DaggerModule.BehindDist(value)
    if value then
        DaggerConfig.BehindDist = tonumber(value) or 2.1
        DaggerDebug("Distancia detrás:", DaggerConfig.BehindDist)
    end
    return DaggerConfig.BehindDist
end

function DaggerModule.Cooldown(value)
    if value then
        DaggerConfig.Cooldown = tonumber(value) or 1.5
        DaggerDebug("Cooldown:", DaggerConfig.Cooldown)
    end
    return DaggerConfig.Cooldown
end

function DaggerModule.Hold(value)
    if value then
        DaggerConfig.HoldDuration = tonumber(value) or 0.5
        DaggerDebug("Duración de mantenimiento:", DaggerConfig.HoldDuration)
    end
    return DaggerConfig.HoldDuration
end

function DaggerModule.Speed(value)
    if value then
        DaggerConfig.TweenDuration = tonumber(value) or 0.08
        DaggerDebug("Velocidad:", DaggerConfig.TweenDuration)
    end
    return DaggerConfig.TweenDuration
end

function DaggerModule.Smart(enabled)
    if enabled ~= nil then
        DaggerConfig.SmartMovement = enabled == true
        DaggerDebug("Movimiento inteligente:", DaggerConfig.SmartMovement and "Activado" or "Desactivado")
    end
    return DaggerConfig.SmartMovement
end

function DaggerModule.ArcHeight(value)
    if value then
        DaggerConfig.ArcHeight = tonumber(value) or 1.8
        DaggerDebug("Altura del arco:", DaggerConfig.ArcHeight)
    end
    return DaggerConfig.ArcHeight
end

function DaggerModule.Debug(enabled)
    if enabled ~= nil then
        DaggerConfig.Debug = enabled == true
        DaggerDebug("Debug:", DaggerConfig.Debug and "Activado" or "Desactivado")
    end
    return DaggerConfig.Debug
end

function DaggerModule.Ratio(enabled)
    if enabled ~= nil then
        DaggerConfig.ShowRange = enabled == true
        DaggerDebug("Indicador de rango:", DaggerConfig.ShowRange and "Activado" or "Desactivado")
        if not DaggerConfig.ShowRange and DaggerState.RangeIndicator then
            DaggerState.RangeIndicator:Destroy()
            DaggerState.RangeIndicator = nil
        end
    end
    return DaggerConfig.ShowRange
end

function DaggerModule.Keybind(key)
    if key then
        if type(key) == "string" then
            key = Enum.KeyCode[key]
        end
        if key then
            DaggerConfig.Keybind = key
            DaggerDebug("Tecla principal:", DaggerConfig.Keybind.Name)
        end
    end
    return DaggerConfig.Keybind
end

function DaggerModule.AltKey(key)
    if key then
        if type(key) == "string" then
            key = Enum.KeyCode[key]
        end
        if key then
            DaggerConfig.AlternativeKey = key
            DaggerDebug("Tecla alternativa:", DaggerConfig.AlternativeKey.Name)
        end
    end
    return DaggerConfig.AlternativeKey
end

function DaggerModule.GetStatus()
    print("=== DAGGER STATUS ===")
    print("Estado:", DaggerConfig.Enabled and "Activado" or "Desactivado")
    print("Rango:", DaggerConfig.Range)
    print("Distancia detrás:", DaggerConfig.BehindDist)
    print("Cooldown:", DaggerConfig.Cooldown)
    print("Duración de mantenimiento:", DaggerConfig.HoldDuration)
    print("Velocidad:", DaggerConfig.TweenDuration, "s")
    print("Movimiento inteligente:", DaggerConfig.SmartMovement and "Activado" or "Desactivado")
    print("Altura del arco:", DaggerConfig.ArcHeight)
    print("Indicador de rango:", DaggerConfig.ShowRange and "Activado" or "Desactivado")
    print("Debug:", DaggerConfig.Debug and "Activado" or "Desactivado")
    print("Tecla principal:", DaggerConfig.Keybind.Name)
    print("Tecla alternativa:", DaggerConfig.AlternativeKey.Name)
    print("TP Activo:", DaggerState.isTPActive)
    print("Listener del botón:", DaggerState.ButtonConnected and "Conectado" or "Desconectado")
    print("Killer:", GetKiller() and GetKiller().Name or "No encontrado")
    print("======================")
end

function DaggerModule.TP()
    return DaggerTP()
end

function DaggerModule.ReconnectButton()
    return ConnectButtonListener()
end

DaggerDebug("=== DAGGER LOADED ===")
DaggerDebug("Usa Dagger.GetStatus() para ver configuración")

return DaggerModule