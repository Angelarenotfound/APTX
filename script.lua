-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local vim = game:GetService("VirtualInputManager")


-- MODULES
local CreamModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/cream.lua"))()
local APTX = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/main.lua"))()
local tpeve = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/kolossos-charge.lua"))()
local fly, unfly = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/fly.lua"))()
local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/icons.lua"))()
local cream = CreamModule:Create()


-- GLOBAL VARS
_G.player, player = Players.LocalPlayer, Players.LocalPlayer
_G.tpevesit = nil
local chractive
local chr
texe = false
xchr = false
mhealing = false
local exe = nil
local sit
local target


-- GLOBAL FUNCTIONS
local function getRoot(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

local function getChar()
    local rchar = workspace.Players:WaitForChild(player.Name):GetAttribute("Character")
    return rchar
end

local function getTeam()
    local team = Workspace.Players:WaitForChild(player.Name):GetAttribute("Team")
    return team
end

local function gameState()
    local gstate = Workspace.GameProperties.State.Value
    return gstate
end

local function getCooldown(ab)
    local abn = "AB" .. ab
    local cd = Players.LocalPlayer.PlayerGui.Round.Game.Ability.Bar:WaitForChild(abn).CD.Text
    return cd
end


-- STARTUP
APTX:Config("APTX By DrexusTeam", true, true)

local home = APTX:Section("Home", "home", true)
local playersec = APTX:Section("Player", "heart", false)
local combat = APTX:Section("Survivors", "shield", false)
local killer = APTX:Section("Killers", "eye", false)
local utils = APTX:Section("Utilities", "folder", false)


-- HOME VARS
local tpwalking = nil
local tpwalkStack = 0


-- HOME STARTUP
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


-- PLAYER STARTUP
APTX:Label(playersec, "Player modifications")

APTX:Slider(playersec, "Speed (game sync)", "star", 2, 100, 0, function(value)
    local at = Workspace.Players:WaitForChild(player.Name).ClientHandler
    at:SetAttribute("lockSpeed", value)
end)

APTX:Label(playersec, "Speed (game sync) It can affect the skills")

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

local n

APTX:Toggle(playersec, "Infinite Jump", "arrow-up", false, function(state)
    n = APTX:Notify({
        title = "Infinite Jump",
        content = "ni idea bro",
        size = 0.9,
        ["topbar-icon"] = Icons["check"],
        ["content-icon"] = Icons["book-open"],
        buttons = {
            { label = "Okay", color = Color3.fromRGB(88, 101, 242), callback = function() n:Destroy() end }
        },
        duration = 5,
        type = "success"
    })

    local plr = player

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


-- SURVIVORS VARS
local automc = false
local automcLoop = nil
local mcstarted = false
local ready = true
local inside = false
local mh = false


-- SURVIVORS FUNCTIONS
local function isMetalCh()
    local dmr = Workspace.Players:WaitForChild(player.Name)
    return dmr:GetAttribute("DamageReduction") == 1
end

local function mheal()
    local selected = nil

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        local obj = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(p.Name)
        if obj then
            local charAttr = obj:GetAttribute("Character")
            if charAttr == "Eggman" then
                selected = p
                break
            elseif charAttr == "Tails" and not selected then
                selected = p
            end
        end
    end

    if not selected then return end

    if sit then sit:Disconnect() end
    target = selected

    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid").Sit = true

        sit = RunService.Heartbeat:Connect(function()
            if selected and Players:FindFirstChild(selected.Name) and selected.Character and selected.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Sit == true then
                getRoot(player.Character).CFrame = getRoot(selected.Character).CFrame * CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 0, 5)
            else
                if sit then sit:Disconnect() end
                target = nil
            end
        end)
    end
end

local function tpexe()
    local selected = nil
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        local obj = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(p.Name)
        if obj and obj:GetAttribute("Team") == "EXE" then
            selected = p
            break
        end
    end

    if not selected then return end

    if sit then sit:Disconnect() end
    target = selected

    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid").Sit = true

        sit = RunService.Heartbeat:Connect(function()
            if selected and Players:FindFirstChild(selected.Name) and selected.Character and selected.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Sit == true then
                getRoot(player.Character).CFrame = getRoot(selected.Character).CFrame * CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 0, 5)
            else
                if sit then sit:Disconnect() end
                target = nil
            end
        end)
    end
end

local function metaltpc()
    local exep = nil
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        local obj = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(p.Name)
        if obj and obj:GetAttribute("Team") == "EXE" then
            exep = p
            break
        end
    end

    if not exep then return end

    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local exeRoot = exep.Character and exep.Character:FindFirstChild("HumanoidRootPart")

    if not myRoot or not exeRoot then return end
    if (myRoot.Position - exeRoot.Position).Magnitude > 20 then return end

    if sit then sit:Disconnect() end
    target = exep

    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Sit = true

        sit = RunService.Heartbeat:Connect(function()
            if exep and Players:FindFirstChild(exep.Name) and exep.Character and exep.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Sit == true then
                getRoot(player.Character).CFrame = getRoot(exep.Character).CFrame * CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 0, 5)
            else
                if sit then sit:Disconnect() end
                target = nil
            end
        end)
    end
end

local function startAutomc()
    if automcLoop then automcLoop:Disconnect() end
    automcLoop = RunService.Heartbeat:Connect(function()
        if not automc then
            automcLoop:Disconnect()
            automcLoop = nil
            return
        end

        if not exe then return end

        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local exeRoot = exe.Character and exe.Character:FindFirstChild("HumanoidRootPart")

        if not myRoot or not exeRoot then return end

        local dist = (myRoot.Position - exeRoot.Position).Magnitude
        if getChar() ~= "MetalSonic" and not isMetalCh() then return end
        if dist <= 20 and mh then
            if not inside then
                inside = true
                if ready and not target then
                    ready = false
                    metaltpc()
                    task.delay(5, function()
                        ready = true
                    end)
                end
            end
        else
            inside = false
        end
    end)
end


-- SURVIVORS STARTUP
APTX:Toggle(combat, "Cream Helper", "users", false, function(state)
    cream.Enabled = state
end)

APTX:Toggle(combat, "Auto metalsonic stun", "send", false, function(state)
    texe = state
end)

APTX:Toggle(combat, "Auto metalsonic eggman heal", "redo", false, function(state)
    mhealing = state
end)

APTX:Toggle(combat, "Metalsonic Charge hitbox", "calculator", false, function(state)
    automc = state
    if not mcstarted then
        startAutomc()
        mcstarted = true
    end
end)


-- KILLERS VARS
local s = nil


-- KILLERS FUNCTIONS
local function xcharge()
    local survivors = {}

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        local obj = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(p.Name)
        if obj and obj:GetAttribute("Team") == "Survivor" then
            table.insert(survivors, p)
        end
    end

    if #survivors == 0 then return end

    local selected = survivors[math.random(1, #survivors)]

    if sit then sit:Disconnect() end
    target = selected

    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid").Sit = true

        sit = RunService.Heartbeat:Connect(function()
            if selected and Players:FindFirstChild(selected.Name) and selected.Character and selected.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Sit == true then
                getRoot(player.Character).CFrame = getRoot(selected.Character).CFrame * CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 0, 5)
            else
                if sit then sit:Disconnect() end
                target = nil
            end
        end)
    end
end


-- KILLERS STARTUP
APTX:Toggle(killer, "Auto Silver Minigame", "wind", false, function(state)
    if s then
        s:Disconnect()
        s = nil
    end

    if not state then return end

    local character = workspace.Players:WaitForChild(player.Name, 10)

    local function escape()
        for i = 1, 20 do
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

APTX:Toggle(killer, "Charge ALL", "check", false, function(state)
    local plrs = Players:GetPlayers()
    tpeve(0.5, plrs)
end)

APTX:Toggle(killer, "Auto 2011x charge", "send", false, function(state)
    xchr = state
end)


-- UTILS VARS
local flyspeed = 1
local flystate = false
local flyKeybind = nil
local listening = false


-- UTILS FUNCTIONS
local function setFly(state)
    flystate = state

    if flystate then
        fly:Mobile(flyspeed)
    else
        unfly:Mobile()
    end
end

local function toggleFly()
    setFly(not flystate)
end


-- UTILS STARTUP
APTX:Button(utils, "Set Fly Keybind", "key", function()
    if listening then return end
    listening = true
end)

APTX:Input(utils, "Fly Speed", "edit", "Recomended 1 - 3", function(text)
    flyspeed = tonumber(text) or 1
    if flystate then
        fly:Mobile(flyspeed)
    end
end)

APTX:Toggle(utils, "Fly", "cloud", false, function(state)
    setFly(state)
end)

APTX:Toggle(utils, "Auto Select Character", "check", false, function(state)
    chractive = state
end)

APTX:Menu(utils, "Select Character", "Selecciona...", "user", {
    "MetalSonic",
    "Eggman",
    "Sonic",
    "Amy",
    "Shadow",
    "Silver",
    "Blaze",
    "Cream",
    "Tails",
    "Knuckles"
}, "Sonic", function(selected)
    chr = selected
    print(chr)
end)


-- LISTENERS
Workspace.GameProperties.State.Changed:Connect(function(value)
    task.wait(7)
    if value == "SEC" then
        if chractive then
            local args = { chr }
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Voted"):FireServer(unpack(args))
            print('fired con:')
            print('hecho')
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Unknown then return end

    local key = input.KeyCode

    if listening then
        flyKeybind = key
        listening = false
        return
    end

    if flyKeybind and key == flyKeybind then
        toggleFly()
    end

    local state = gameState()
    if state ~= "ING" and state ~= "80s" then return end

    local char = getChar()

    if (key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonL1) and texe then
        if char == "Sonic" or char == "MetalSonic" then
            task.wait(1.5)
            tpexe()
        end
    end

    if (key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonL1) and texe then
        if char == "MetalSonic" and tonumber(getCooldown(1)) == 0 then
            mh = true
            task.wait(10)
            mh = false
        end
    end

    if (key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonR1) and xchr then
        if char == "2011x" then
            task.wait(3)
            xcharge()
        end
    end

    if (key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonR1) and xchr then
        if char == "MetalSonic" then
            mheal()
        end
    end
end)


-- LOOPS
while true do
    task.wait(10)
    for _, p in ipairs(Players:GetPlayers()) do
        local folder = workspace:FindFirstChild("Players")
        if folder then
            local obj = folder:FindFirstChild(p.Name)
            if obj and obj:GetAttribute("Team") == "EXE" then
                exe = p
                break
            end
        end
    end
end
