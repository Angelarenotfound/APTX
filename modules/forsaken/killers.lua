local Killers = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local config = {
    Distance = 20,
    Duration = 1,
    Platform = "pc",
    Enabled = false
}

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local isFollowing = false
local followConnection = nil
local currentTarget = nil
local buttonConnection = nil
local buttonObject = nil
local uiConnections = {}

local function getNearestPlayer()
    if not character then return nil end
    
    local nearest = nil
    local shortestDist = config.Distance + 1
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then return nil end
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
                local targetRoot = otherChar.HumanoidRootPart
                local dist = (rootPart.Position - targetRoot.Position).Magnitude
                
                if dist < shortestDist then
                    shortestDist = dist
                    nearest = otherChar
                end
            end
        end
    end
    
    return nearest
end

local function startFollowing(target, duration)
    if isFollowing then return end
    if not target or not character or not humanoid then return end
    
    isFollowing = true
    currentTarget = target
    humanoid.AutoRotate = false
    
    local startTime = tick()
    
    followConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        
        if elapsed >= duration then
            stopFollowing()
            return
        end
        
        if not target or not target:FindFirstChild("HumanoidRootPart") then
            stopFollowing()
            return
        end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local targetRoot = target:FindFirstChild("HumanoidRootPart")
        
        if rootPart and targetRoot then
            local dist = (rootPart.Position - targetRoot.Position).Magnitude
            
            if dist > config.Distance then
                stopFollowing()
                return
            end
            
            local direction = (targetRoot.Position - rootPart.Position)
            local angle = math.atan2(direction.X, direction.Z)
            local correctedAngle = angle + math.pi
            
            rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, correctedAngle, 0)
        end
    end)
end

local function stopFollowing()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
    
    if humanoid then
        humanoid.AutoRotate = true
    end
    
    isFollowing = false
    currentTarget = nil
end

local function executeFollowUp()
    if isFollowing then return end
    if not config.Enabled then return end
    
    local target = getNearestPlayer()
    if target then
        startFollowing(target, config.Duration)
    end
end

local function setupInputs()
    if buttonConnection then
        buttonConnection:Disconnect()
        buttonConnection = nil
    end
    
    for _, conn in pairs(uiConnections) do
        conn:Disconnect()
    end
    uiConnections = {}
    
    if config.Platform == "phone" then
        local function findSlashButton()
            local mainUI = player.PlayerGui:FindFirstChild("MainUI")
            if mainUI then
                local abilityContainer = mainUI:FindFirstChild("AbilityContainer")
                if abilityContainer then
                    return abilityContainer:FindFirstChild("Slash")
                end
            end
            return nil
        end
        
        local function connectButton()
            if buttonConnection then
                buttonConnection:Disconnect()
                buttonConnection = nil
            end
            
            local button = findSlashButton()
            if button then
                buttonObject = button
                buttonConnection = button.MouseButton1Click:Connect(executeFollowUp)
            end
        end
        
        local function setupUIListener()
            local mainUI = player.PlayerGui:FindFirstChild("MainUI")
            if mainUI then
                local abilityContainer = mainUI:FindFirstChild("AbilityContainer")
                if abilityContainer then
                    local childAddedConn = abilityContainer.ChildAdded:Connect(function(child)
                        if child.Name == "Slash" then
                            connectButton()
                        end
                    end)
                    table.insert(uiConnections, childAddedConn)
                    
                    local childRemovedConn = abilityContainer.ChildRemoved:Connect(function(child)
                        if child.Name == "Slash" then
                            if buttonConnection then
                                buttonConnection:Disconnect()
                                buttonConnection = nil
                            end
                            buttonObject = nil
                        end
                    end)
                    table.insert(uiConnections, childRemovedConn)
                end
            end
        end
        
        connectButton()
        setupUIListener()
        
    elseif config.Platform == "console" then
        buttonConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.ButtonR2 then
                executeFollowUp()
            end
        end)
        
    else
        buttonConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                executeFollowUp()
            end
        end)
    end
end

function Killers.State(state)
    config.Enabled = state
    
    if state then
        character = player.Character or player.CharacterAdded:Wait()
        humanoid = character:WaitForChild("Humanoid")
    else
        stopFollowing()
    end
end

function Killers.Set(key, value)
    if key == "Distance" then
        config.Distance = tonumber(value) or 20
    elseif key == "Duration" then
        config.Duration = tonumber(value) or 1
    elseif key == "Platform" then
        if value == "pc" or value == "phone" or value == "console" then
            config.Platform = value
            setupInputs()
        end
    elseif key == "Enabled" then
        Killers.State(value)
    end
end

function Killers.GetConfig()
    return config
end

function Killers.Execute()
    executeFollowUp()
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
end)

setupInputs()

return Killers