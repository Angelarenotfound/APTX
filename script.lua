-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local vim = game:GetService("VirtualInputManager")

-- GLOBAL VARS
local player = Players.LocalPlayer


-- MODULES
local CreamModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/cream.lua"))()
local APTX = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/main.lua"))()
local tpeve = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/kolossos-charge.lua"))()


-- START MODULES
local cream = CreamModule:Create()





-- SECTIONS
APTX:Config("APTX By DrexusTeam", true, true)

local home = APTX:Section("Home", "home", true)
local playersec = APTX:Section("Player", "heart", false)
local combat = APTX:Section("Survivors", "shield", false)
local killer = APTX:Section("Killers", "eye", false)


-- HOME VARS
local tpwalking = nil
local tpwalkStack = 0

-- HOME

APTX:Label(home, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label(home, "APTX By DrexusTeam")
APTX:Label(home, "Outcome Memories v0.2")
APTX:Label(home, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

APTX:Button(home, "Join Discord", "bell", function()
    setclipboard("https://discord.gg/mjY4sd3Un")
end)

APTX:Input(home, "Report Bugs", "edit", "Send feedback", function(text)
    print("feedback:", text)
end)

APTX:Label(playersec, "Player modifications")


APTX:Slider(playersec, "Speed (game sync)", "star", 0, 5, 0, function(value)
    local at = Workspace.Players:WaitForChild(player.Name)
    at:SetAttribute("SpeedBoost", value)
end)

APTX:Label(playersec, "Speed (game sync) It can be automatically turned off by the anticheat")

APTX:Input(playersec, "Speed (game desync)", "edit", "Recomended 1.2 - 3", function(text)
    pcall(function() 
        if tpwalking then
            tpwalking:Disconnect() 
        end
    end)
    
    local speed = tonumber(text)
    
    if not speed or speed <= 0 then
        warn("invalid number")
        return
    end
    
    local character = player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    
    
    tpwalkStack = 0
    
    tpwalking = game:GetService("RunService").Heartbeat:Connect(function(delta)
        if not (character and humanoid and humanoid.Parent) then
            tpwalking:Disconnect()
            return
        end
        
        if humanoid.MoveDirection.Magnitude > 0 then
            character:TranslateBy(humanoid.MoveDirection * (speed + tpwalkStack) * delta * 10)
        end
    end)
    
end)

APTX:Label(playersec, "Speed (game desync) cannot be automatically turned off by the anticheat")

APTX:Toggle(playersec, "Infinite Jump", "arrow-up", false, function(state)
    local plr = game.Players.LocalPlayer
    
    if state then
        _G.InfJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                plr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if _G.InfJumpConnection then
            _G.InfJumpConnection:Disconnect()
        end
    end
end)


APTX:Toggle(playersec, "Fullbright", "sun", false, function(state)
    if state then
        game.Lighting.Brightness = 2
        game.Lighting.ClockTime = 14
        game.Lighting.FogEnd = 100000
        game.Lighting.GlobalShadows = false
        game.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        game.Lighting.Brightness = 1
        game.Lighting.ClockTime = 12
        game.Lighting.FogEnd = 100000
        game.Lighting.GlobalShadows = true
        game.Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    end
end)

APTX:Slider(playersec, "FOV", "camera", 70, 120, 70, function(value)
    workspace.CurrentCamera.FieldOfView = value
end)


APTX:Button(playersec, "Rejoin Server", "refresh", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
end)




-- Survivors section
APTX:Toggle(combat, "Cream Helper", "users", false, function(state)
    cream.Enabled = state
end)







-- Killers section
local s = nil

APTX:Toggle(killer, "Auto Silver Minigame", "wind", false, function(state)
    if s then
        s:Disconnect()
        s = nil
    end
    
    if not state then return end
    
    local character = workspace.Players:WaitForChild(player.Name, 10)
    

local function escape()
    for i = 1, 7 do
            mouse2click()
            mouse1click()
        task.wait(0.1)
    end
end
    
    local function onAdd(child)
        if state and child:IsA("Highlight") then
            escape()
        end
    end
    
    s = character.ChildAdded:Connect(onAdd)
end)

APTX:Toggle(killer, "Kolossos Charge ALL", "check", false, function(state)
    tpeve(0.5, player)
end)