-- ============================================================
-- MÓDULO: KILLERS (Follow Up)
-- ============================================================
local KillersModule = {}

local KillersPlayers = game:GetService("Players")
local KillersRunService = game:GetService("RunService")
local KillersUIS = game:GetService("UserInputService")

local killerPlayer = KillersPlayers.LocalPlayer
local killerConfig = {}
local killerActive = false
local killerFollowing = false
local killerTarget = nil
local killerConnection = nil
local killerKeyConnection = nil
local killerButtonConnection = nil

local function getPlayerKiller()
    local char = killerPlayer.Character
    if not char then return nil end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest = nil
    local minDist = math.huge

    for _, p in ipairs(KillersPlayers:GetPlayers()) do
        if p ~= killerPlayer then
            local pChar = p.Character
            if pChar then
                local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                if pRoot then
                    local dist = (root.Position - pRoot.Position).Magnitude
                    if dist < minDist and dist < (killerConfig.MaxDistance or 100) then
                        minDist = dist
                        closest = p
                    end
                end
            end
        end
    end

    return closest
end

local function rotateKiller()
    if not killerFollowing or not killerTarget then
        return
    end

    local char = killerPlayer.Character
    if not char then
        killerFollowing = false
        return
    end

    local root = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")

    if not root or not torso then
        killerFollowing = false
        return
    end

    local tChar = killerTarget.Character
    if not tChar then
        killerFollowing = false
        return
    end

    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then
        killerFollowing = false
        return
    end

    local dir = (tRoot.Position - root.Position).Unit
    local look = CFrame.lookAt(root.Position, root.Position + dir)

    pcall(function()
        root.CFrame = look
        torso.CFrame = CFrame.new(torso.Position, torso.Position + dir)
    end)
end

local function stopFollowKiller()
    killerFollowing = false
    killerTarget = nil

    if killerConnection then
        killerConnection:Disconnect()
        killerConnection = nil
    end
end

local function startFollowKiller()
    if not killerActive then
        return
    end

    if killerFollowing then
        stopFollowKiller()
    end

    killerTarget = getPlayerKiller()

    if not killerTarget then
        return
    end

    killerFollowing = true

    if killerConnection then
        killerConnection:Disconnect()
    end

    killerConnection = KillersRunService.Stepped:Connect(rotateKiller)

    task.wait(killerConfig.FollowUpTime or 10)

    if killerFollowing then
        stopFollowKiller()
    end
end

local function onKeyKiller(input, processed)
    if processed then
        return
    end

    if input.KeyCode == killerConfig.FollowUpKey then
        startFollowKiller()
    end
end

local function setupButtonListenerKiller()
    if killerButtonConnection then
        killerButtonConnection:Disconnect()
        killerButtonConnection = nil
    end

    if not killerConfig.ButtonPath then
        return
    end

    local gui = killerPlayer:FindFirstChild("PlayerGui")
    if not gui then
        return
    end

    local button = gui:FindFirstChild(killerConfig.ButtonPath)
    if not button then
        return
    end

    killerButtonConnection = button.MouseButton1Click:Connect(function()
        if killerActive then
            startFollowKiller()
        end
    end)
end

function KillersModule.Init(cfg)
    if not cfg then
        error("Configuración requerida")
    end

    killerConfig = {
        FollowUpTime = cfg.FollowUpTime or 10,
        FollowUpKey = cfg.FollowUpKey or Enum.KeyCode.G,
        MaxDistance = cfg.MaxDistance or 100,
        ButtonPath = cfg.ButtonPath or "MainUI.AbilityContainer.Slash"
    }

    if killerKeyConnection then
        killerKeyConnection:Disconnect()
    end

    killerKeyConnection = KillersUIS.InputBegan:Connect(onKeyKiller)

    setupButtonListenerKiller()

    killerPlayer:WaitForChild("PlayerGui").ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") then
            setupButtonListenerKiller()
        end
    end)
end

function KillersModule.FollowUp(state)
    if state == nil then
        error("Estado requerido (true/false)")
    end

    killerActive = state

    if not state then
        stopFollowKiller()
    end
end

function KillersModule.Destroy()
    stopFollowKiller()

    if killerKeyConnection then
        killerKeyConnection:Disconnect()
        killerKeyConnection = nil
    end

    if killerButtonConnection then
        killerButtonConnection:Disconnect()
        killerButtonConnection = nil
    end

    killerActive = false
    killerFollowing = false
    killerTarget = nil
    killerConfig = {}
end

-- Conexión para resetear estado cuando el personaje muere
killerPlayer.CharacterAdded:Connect(function()
    killerFollowing = false
    killerTarget = nil

    if killerConnection then
        killerConnection:Disconnect()
        killerConnection = nil
    end
end)

return KillersModule