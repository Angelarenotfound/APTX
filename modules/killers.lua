local Killers = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local config = {}
local active = false
local following = false
local target = nil
local connection = nil
local keyConnection = nil
local buttonConnection = nil

local function getPlayer()
    local char = player.Character
    if not char then return nil end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local closest = nil
    local minDist = math.huge
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local pChar = p.Character
            if pChar then
                local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                if pRoot then
                    local dist = (root.Position - pRoot.Position).Magnitude
                    if dist < minDist and dist < (config.MaxDistance or 100) then
                        minDist = dist
                        closest = p
                    end
                end
            end
        end
    end
    
    return closest
end

local function rotate()
    if not following or not target then
        return
    end
    
    local char = player.Character
    if not char then
        following = false
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    
    if not root or not torso then
        following = false
        return
    end
    
    local tChar = target.Character
    if not tChar then
        following = false
        return
    end
    
    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then
        following = false
        return
    end
    
    local dir = (tRoot.Position - root.Position).Unit
    local look = CFrame.lookAt(root.Position, root.Position + dir)
    
    pcall(function()
        root.CFrame = look
        torso.CFrame = CFrame.new(torso.Position, torso.Position + dir)
    end)
end

local function stopFollow()
    following = false
    target = nil
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

local function startFollow()
    if not active then
        return
    end
    
    if following then
        stopFollow()
    end
    
    target = getPlayer()
    
    if not target then
        return
    end
    
    following = true
    
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Stepped:Connect(rotate)
    
    task.wait(config.FollowUpTime or 10)
    
    if following then
        stopFollow()
    end
end

local function onKey(input, processed)
    if processed then
        return
    end
    
    if input.KeyCode == config.FollowUpKey then
        startFollow()
    end
end

local function setupButtonListener()
    if buttonConnection then
        buttonConnection:Disconnect()
        buttonConnection = nil
    end
    
    if not config.ButtonPath then
        return
    end
    
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then
        return
    end
    
    local button = gui:FindFirstChild(config.ButtonPath)
    if not button then
        return
    end
    
    buttonConnection = button.MouseButton1Click:Connect(function()
        if active then
            startFollow()
        end
    end)
end

function Killers.Init(cfg)
    if not cfg then
        error("Configuración requerida")
    end
    
    config = {
        FollowUpTime = cfg.FollowUpTime or 10,
        FollowUpKey = cfg.FollowUpKey or Enum.KeyCode.G,
        MaxDistance = cfg.MaxDistance or 100,
        ButtonPath = cfg.ButtonPath or "MainUI.AbilityContainer.Slash"
    }
    
    if keyConnection then
        keyConnection:Disconnect()
    end
    
    keyConnection = UserInputService.InputBegan:Connect(onKey)
    
    setupButtonListener()
    
    player:WaitForChild("PlayerGui"):ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") then
            setupButtonListener()
        end
    end)
end

function Killers.FollowUp(state)
    if state == nil then
        error("Estado requerido (true/false)")
    end
    
    active = state
    
    if not state then
        stopFollow()
    end
end

function Killers.Destroy()
    stopFollow()
    
    if keyConnection then
        keyConnection:Disconnect()
        keyConnection = nil
    end
    
    if buttonConnection then
        buttonConnection:Disconnect()
        buttonConnection = nil
    end
    
    active = false
    following = false
    target = nil
    config = {}
end

player.CharacterAdded:Connect(function()
    following = false
    target = nil
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
end)

return Killers