local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Dagger = {}

local Config = {
    Mode = "Backstabber",
    Position = "Backstab_Standard",
    Movement = "Dash_Arc",
    Speed = "Speed_Standard",
    Behavior = "Behavior_Aggressive",
    Range = 15,
    BehindDist = 2.1,
    Cooldown = 1.5,
    HoldDuration = 0.5,
    SmartArcHeight = 1.8,
    DebugMode = false,
    Enabled = true,
    LastTP = 0,
    isTPActive = false,
    Keybind = Enum.KeyCode.Q
}

local Presets = {
    Backstabber = {
        Position = "Backstab_Standard",
        Movement = "Dash_Arc",
        Speed = "Speed_Standard",
        Behavior = "Behavior_Aggressive",
        BehindDist = 2.1,
        SmartArcHeight = 1.8
    },
    Ghost = {
        Position = "Backstab_Close",
        Movement = "Dash_Direct",
        Speed = "Speed_Moderate",
        Behavior = "Behavior_Evade",
        BehindDist = 1.5,
        SmartArcHeight = 1.5
    },
    Berserker = {
        Position = "Front_Standard",
        Movement = "Dash_Direct",
        Speed = "Speed_Instant",
        Behavior = "Behavior_Aggressive",
        BehindDist = 3.0,
        SmartArcHeight = 1.2
    },
    Tactician = {
        Position = "Side_Random",
        Movement = "Dash_Spiral",
        Speed = "Speed_Fast",
        Behavior = "Behavior_Predictive",
        BehindDist = 2.5,
        SmartArcHeight = 2.5
    },
    Ninja = {
        Position = "Backstab_Far",
        Movement = "Dash_Arc",
        Speed = "Speed_Fast",
        Behavior = "Behavior_Circling",
        BehindDist = 3.5,
        SmartArcHeight = 2.0
    }
}

local Speeds = {
    Speed_Instant = 0.02,
    Speed_Fast = 0.05,
    Speed_Standard = 0.08,
    Speed_Moderate = 0.15,
    Speed_Slow = 0.3
}

local Positions = {
    Backstab_Standard = 2.1,
    Backstab_Close = 1.5,
    Backstab_Far = 3.5,
    Backstab_Slow = 2.1,
    Side_Left = 2.5,
    Side_Right = 2.5,
    Side_Random = 2.5,
    Front_Standard = 4.0,
    Front_Far = 7.0
}

local function DebugLog(...)
    if Config.DebugMode then
        print("[DAGGER]", ...)
    end
end

local function ApplyPreset(name)
    local preset = Presets[name]
    if not preset then return false end
    Config.Mode = name
    Config.Position = preset.Position
    Config.Movement = preset.Movement
    Config.Speed = preset.Speed
    Config.Behavior = preset.Behavior
    Config.BehindDist = preset.BehindDist
    Config.SmartArcHeight = preset.SmartArcHeight
    DebugLog("Preset aplicado:", name)
    return true
end

local function GetSpeedValue(speedName)
    return Speeds[speedName] or 0.08
end

local function GetPositionDistance(posName)
    return Positions[posName] or 2.1
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
    return lookVector:Dot(toKiller) < -0.3
end

local function GetBehaviorModifier(hrp, khrp)
    local behavior = Config.Behavior
    if behavior == "Behavior_Aggressive" then
        return 1.0
    elseif behavior == "Behavior_Defensive" then
        return 0.7
    elseif behavior == "Behavior_Predictive" then
        if khrp and khrp.AssemblyLinearVelocity then
            local vel = khrp.AssemblyLinearVelocity
            if vel.Magnitude > 2 then
                return 1.2
            end
        end
        return 1.0
    elseif behavior == "Behavior_Circling" then
        return 0.9
    elseif behavior == "Behavior_Evade" then
        if IsKillerBehind(khrp, hrp) then
            return 1.3
        end
        return 0.8
    end
    return 1.0
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
        hrp.CFrame = CFrame.new(currentPos, targetCFrame.Position + targetCFrame.LookVector)
        task.wait(stepTime)
    end
    hrp.CFrame = targetCFrame
end

local function ArcMovement(hrp, khrp, targetCFrame, duration)
    local startPos = hrp.Position
    local endPos = targetCFrame.Position
    local dist = (endPos - startPos).Magnitude
    if dist < 3 then
        DirectMovement(hrp, targetCFrame, duration)
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
    local arcHeight = math.min(Config.SmartArcHeight, dist * 0.4)
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
        hrp.CFrame = CFrame.new(currentPos, khrp.Position)
        task.wait(stepTime)
    end
    hrp.CFrame = targetCFrame
end

local function SpiralMovement(hrp, khrp, targetCFrame, duration)
    local startPos = hrp.Position
    local endPos = targetCFrame.Position
    local steps = math.floor(duration / 0.015)
    if steps < 1 then steps = 1 end
    local stepTime = duration / steps
    local angle = 0
    local radius = 1.5
    for i = 1, steps do
        local alpha = i / steps
        local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
        local basePos = startPos:Lerp(endPos, smoothAlpha)
        angle = angle + 0.15
        local offset = Vector3.new(math.cos(angle) * radius * (1 - smoothAlpha), 0, math.sin(angle) * radius * (1 - smoothAlpha))
        local currentPos = basePos + offset
        hrp.CFrame = CFrame.new(currentPos, khrp.Position)
        task.wait(stepTime)
    end
    hrp.CFrame = targetCFrame
end

local function ZigZagMovement(hrp, khrp, targetCFrame, duration)
    local startPos = hrp.Position
    local endPos = targetCFrame.Position
    local steps = math.floor(duration / 0.015)
    if steps < 1 then steps = 1 end
    local stepTime = duration / steps
    local direction = (endPos - startPos).Unit
    local perpendicular = Vector3.new(-direction.Z, 0, direction.X).Unit
    local zigSize = 1.5
    for i = 1, steps do
        local alpha = i / steps
        local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
        local basePos = startPos:Lerp(endPos, smoothAlpha)
        local zig = math.sin(alpha * math.pi * 4) * zigSize * (1 - smoothAlpha)
        local currentPos = basePos + perpendicular * zig
        hrp.CFrame = CFrame.new(currentPos, khrp.Position)
        task.wait(stepTime)
    end
    hrp.CFrame = targetCFrame
end

local function ExecuteTP()
    if not Config.Enabled then
        DebugLog("Deshabilitado")
        return false
    end
    
    if Config.isTPActive then
        DebugLog("TP activo")
        return false
    end
    
    local currentTime = os.clock()
    if currentTime - Config.LastTP < Config.Cooldown then
        DebugLog("Cooldown")
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
    if dist > Config.Range then
        DebugLog("Fuera de rango")
        return false
    end
    
    local lv = khrp.CFrame.LookVector.Unit
    local behindDistance = Config.BehindDist
    
    local posName = Config.Position
    if posName == "Backstab_Close" then
        behindDistance = 1.5
    elseif posName == "Backstab_Far" then
        behindDistance = 3.5
    elseif posName == "Side_Left" or posName == "Side_Right" or posName == "Side_Random" then
        behindDistance = 2.5
        local side = 1
        if posName == "Side_Left" then side = -1
        elseif posName == "Side_Right" then side = 1
        elseif posName == "Side_Random" then side = (math.random() > 0.5 and 1) or -1
        end
        local right = khrp.CFrame.RightVector
        lv = right * side
    elseif posName == "Front_Standard" then
        behindDistance = -4.0
    elseif posName == "Front_Far" then
        behindDistance = -7.0
    end
    
    local bp = khrp.Position - (lv * behindDistance)
    local tp = Vector3.new(bp.X, phrp.Position.Y, bp.Z)
    local targetCFrame = CFrame.new(tp, tp + lv)
    
    local speed = GetSpeedValue(Config.Speed)
    local behaviorMod = GetBehaviorModifier(phrp, khrp)
    local finalDuration = speed * behaviorMod
    
    Config.isTPActive = true
    
    local suc
    local movement = Config.Movement
    if movement == "Dash_Direct" then
        suc = pcall(function() DirectMovement(phrp, targetCFrame, finalDuration) end)
    elseif movement == "Dash_Arc" then
        suc = pcall(function() ArcMovement(phrp, khrp, targetCFrame, finalDuration) end)
    elseif movement == "Dash_Spiral" then
        suc = pcall(function() SpiralMovement(phrp, khrp, targetCFrame, finalDuration) end)
    elseif movement == "Dash_ZigZag" then
        suc = pcall(function() ZigZagMovement(phrp, khrp, targetCFrame, finalDuration) end)
    else
        suc = pcall(function() ArcMovement(phrp, khrp, targetCFrame, finalDuration) end)
    end
    
    if suc then
        Config.LastTP = currentTime
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
        Config.isTPActive = false
        return true
    else
        Config.isTPActive = false
        return false
    end
end

function Dagger.State(enabled)
    Config.Enabled = enabled == true
    DebugLog("Estado:", Config.Enabled and "Activado" or "Desactivado")
    return Config.Enabled
end

function Dagger.Toggle()
    Config.Enabled = not Config.Enabled
    DebugLog("Estado:", Config.Enabled and "Activado" or "Desactivado")
    return Config.Enabled
end

function Dagger.SetMode(name)
    return ApplyPreset(name)
end

function Dagger.SetPosition(pos)
    Config.Position = pos
    DebugLog("Posición:", pos)
end

function Dagger.SetMovement(mov)
    Config.Movement = mov
    DebugLog("Movimiento:", mov)
end

function Dagger.SetSpeed(spd)
    Config.Speed = spd
    DebugLog("Velocidad:", spd)
end

function Dagger.SetBehavior(beh)
    Config.Behavior = beh
    DebugLog("Comportamiento:", beh)
end

function Dagger.SetRange(value)
    Config.Range = tonumber(value) or 15
    DebugLog("Rango:", Config.Range)
end

function Dagger.SetDist(value)
    Config.BehindDist = tonumber(value) or 2.1
    DebugLog("Distancia:", Config.BehindDist)
end

function Dagger.SetCooldown(value)
    Config.Cooldown = tonumber(value) or 1.5
    DebugLog("Cooldown:", Config.Cooldown)
end

function Dagger.SetHold(value)
    Config.HoldDuration = tonumber(value) or 0.5
    DebugLog("Hold:", Config.HoldDuration)
end

function Dagger.SetArcHeight(value)
    Config.SmartArcHeight = tonumber(value) or 1.8
    DebugLog("Arc Height:", Config.SmartArcHeight)
end

function Dagger.SetDebug(enabled)
    Config.DebugMode = enabled == true
    DebugLog("Debug:", Config.DebugMode and "ON" or "OFF")
end

function Dagger.SetKeybind(key)
    if typeof(key) == "string" then
        key = Enum.KeyCode[key]
    end
    if key then
        Config.Keybind = key
        DebugLog("Keybind:", key.Name)
    end
end

function Dagger.Trigger()
    return ExecuteTP()
end

function Dagger.GetStatus()
    local status = {
        Enabled = Config.Enabled,
        Mode = Config.Mode,
        Position = Config.Position,
        Movement = Config.Movement,
        Speed = Config.Speed,
        Behavior = Config.Behavior,
        Range = Config.Range,
        BehindDist = Config.BehindDist,
        Cooldown = Config.Cooldown,
        HoldDuration = Config.HoldDuration,
        SmartArcHeight = Config.SmartArcHeight,
        DebugMode = Config.DebugMode,
        isTPActive = Config.isTPActive,
        Keybind = Config.Keybind.Name,
        Killer = GetKiller() and GetKiller().Name or "None"
    }
    return status
end

function Dagger.ListModes()
    local modes = {}
    for name, _ in pairs(Presets) do
        table.insert(modes, name)
    end
    return modes
end

function Dagger.GetConfig()
    return Config
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Config.Keybind then
        task.spawn(ExecuteTP)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    Config.isTPActive = false
    task.wait(0.5)
end)

ApplyPreset("Backstabber")
DebugLog("Cargado")

return Dagger