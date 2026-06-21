-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")


-- MODULES
local CreamModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/cream.lua"))()
local APTX = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/main.lua"))()
local tpeve = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/kolossos-charge.lua"))()
local fly, unfly = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/fly.lua"))()
local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/icons.lua"))()
local Opt = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/opt.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/config.lua"))()

local cream = CreamModule:Create()

-- GLOBAL VARS
_G.player, player = Players.LocalPlayer, Players.LocalPlayer
_G.tpevesit = nil
local chractive
local chr
texe = false
xchr = false
local exe = nil
local sit
local target
local force

-- CACHED REFS — avoids WaitForChild per-frame/input
local playerFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(player.Name)
local gameProps = workspace:FindFirstChild("GameProperties")
local function refreshPlayerFolder()
    local pf = workspace:FindFirstChild("Players")
    if pf then playerFolder = pf:FindFirstChild(player.Name) end
end
local function refreshGameProps()
    gameProps = workspace:FindFirstChild("GameProperties")
end

-- GLOBAL FUNCTIONS
local function getRoot(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

-- PERF FIX: Use cached ref + FindFirstChild (no WaitForChild in hot paths)
local function getChar()
    if not playerFolder then refreshPlayerFolder() end
    if not playerFolder then return nil end
    return playerFolder:GetAttribute("Character")
end

local function getTeam()
    if not playerFolder then refreshPlayerFolder() end
    if not playerFolder then return nil end
    return playerFolder:GetAttribute("Team")
end

local function gameState()
    if not gameProps then refreshGameProps() end
    if not gameProps then return nil end
    local stateObj = gameProps:FindFirstChild("State")
    if not stateObj then return nil end
    return stateObj.Value
end

-- PERF FIX: Safe navigation instead of deep WaitForChild chain
local function getCooldown(ab)
    local ok, result = pcall(function()
        local bar = Players.LocalPlayer
            and Players.LocalPlayer:FindFirstChild("PlayerGui")
            and Players.LocalPlayer.PlayerGui:FindFirstChild("Round")
            and Players.LocalPlayer.PlayerGui.Round:FindFirstChild("Game")
            and Players.LocalPlayer.PlayerGui.Round.Game:FindFirstChild("Ability")
            and Players.LocalPlayer.PlayerGui.Round.Game.Ability:FindFirstChild("Bar")
        if not bar then return nil end
        local abObj = bar:FindFirstChild("AB" .. ab)
        if not abObj then return nil end
        local cdObj = abObj:FindFirstChild("CD")
        if not cdObj then return nil end
        return cdObj.Text
    end)
    return ok and result or nil
end


-- STARTUP
APTX:Config("APTX By DrexusTeam", true, true)

APTX:Section("Home", "home", true)
APTX:Section("Performance", "flag", false)
APTX:Section("Speed", "arrow-left-right", false)
APTX:Section("Player", "heart", false)
APTX:Section("Survivors", "shield", false)
APTX:Section("Killers", "eye", false)
APTX:Section("Utilities", "folder", false)
APTX:Section("Server", "server", false)
APTX:Section("Config", "settings", false)

-- HOME STARTUP
APTX:Label("Home", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Home", "APTX By DrexusTeam")
APTX:Label("Home", "Outcome Memories v0.2")
APTX:Label("Home", "Build \"Xerion\" — Silver Edition")
APTX:Label("Home", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local homeDiscordBtn = APTX:Button("Home", "Join Discord", "bell", function()
    setclipboard("https://discord.gg/mjY4sd3Un")
end)
homeDiscordBtn:SetTooltip("Copies the Discord invite link to your clipboard", { delay = 0.3 })

local homeBugInput = APTX:Input("Home", "Report Bugs", "edit", "Send feedback...", function(text)
    print("[APTX] Feedback:", text)
end)
homeBugInput:SetTooltip("Send feedback or report bugs to the development team", { delay = 0.3 })

-- PERFORMANCE VARS
op_min = 30
op_e = false

-- PERFORMANCE STARTUP
APTX:Label("Performance", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Performance", "Performance Optimization")
APTX:Label("Performance", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Performance", "Optimize your game without losing quality!")
local fpc = APTX:Label("Performance", "Current FPS: 60")

-- Bucle para actualizar FPS cada segundo
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            fpc:SetText("Current FPS: " .. math.floor(Opt.GetFPS()))
        end)
    end
end)

local perfToggle = APTX:Toggle("Performance", "Optimizer Enabled?", "option", false, function(state)
    op_e = state
    if op_e then
        if not Opt.IsRunning() then
            Opt.Init({
                directory = workspace.Maps,
                targetFPS = op_min,
                recoverMargin = 12,
                farPlaneTarget = 400,
                particleScale = 0.5,
            })
        end
        Opt.Enable()
    else
        Opt.Disable()
    end
end)
perfToggle:SetTooltip("Automatically optimizes graphics for smoother gameplay when FPS drops", { delay = 0.3 })

local perfMenu = APTX:Menu("Performance", "Min FPS to optimize", "Select...", "bell", {
    "20",
    "30",
    "40",
    "50",
    "60",
    "70",
    "80"
}, "50", function(op_f)
    op_min = tonumber(op_f)
    if Opt.IsRunning() then
        Opt.Init({
            directory = workspace.Maps,
            targetFPS = op_min,
        })
    end
end)
perfMenu:SetTooltip("Set the minimum FPS threshold before optimization activates", { delay = 0.3 })

local perfRefreshBtn = APTX:Button("Performance", "Refresh optimizer config", "refresh-cw", function()
    Opt.Disable()
    Opt.Init({
        directory = workspace.Maps,
        targetFPS = op_min,
        recoverMargin = 12,
        farPlaneTarget = 400,
        particleScale = 0.5,
    })
    if op_e then
        Opt.Enable()
    end
end)
perfRefreshBtn:SetTooltip("Reset and reapply all optimization settings", { delay = 0.3 })

-- SPEED VARS
local speedType = "TP Walk"
local speedValue = 0.1
local speedConnection = nil


-- SPEED FUNCTIONS
local function clearSpeed()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end

    if force then
        force:Destroy()
        force = nil
    end

    pcall(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
            end
        end
        local at = Workspace.Players:WaitForChild(player.Name).ClientHandler
        at:SetAttribute("lockSpeed", 0)
    end)
end

local function applySpeed()
    clearSpeed()

    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")

    if speedType == "TP Walk" then
        speedConnection = RunService.Heartbeat:Connect(function(delta)
            if not (char and hum and hum.Parent) then
                clearSpeed()
                return
            end
            if hum.MoveDirection.Magnitude > 0 then
                char:TranslateBy(hum.MoveDirection * speedValue * delta * 10)
            end
        end)

    elseif speedType == "WalkSpeed" then
        hum.WalkSpeed = 16 * (1 + speedValue)

    elseif speedType == "VectorForce" then
        if not hrp then return end

        local att = Instance.new("Attachment")
        att.Parent = hrp

        force = Instance.new("VectorForce")
        force.Attachment0 = att
        force.RelativeTo = Enum.ActuatorRelativeTo.World
        force.Parent = hrp

        speedConnection = RunService.Heartbeat:Connect(function()
            if not (char and hum and hum.Parent) then
                clearSpeed()
                return
            end
            if hum.MoveDirection.Magnitude > 0 then
                force.Force = hum.MoveDirection * (speedValue * 10000)
            else
                force.Force = Vector3.zero
            end
        end)

    elseif speedType == "Speed (game sync)" then
        pcall(function()
            local at = Workspace.Players:WaitForChild(player.Name).ClientHandler
            at:SetAttribute("lockSpeed", speedValue * 16)
        end)
    end
end


-- SPEED STARTUP
APTX:Label("Speed", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Speed", "Speed Modifications")
APTX:Label("Speed", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Speed", "Select speed type and set your multiplier")

local speedTypeMenu = APTX:Menu("Speed", "Speed Type", "Select...", "star", {
    "TP Walk",
    "WalkSpeed",
    "VectorForce",
    "Speed (game sync)"
}, "TP Walk", function(selected)
    speedType = selected
    clearSpeed()
end)
speedTypeMenu:SetTooltip("Choose how speed is applied to your character", { delay = 0.3 })

local speedInput = APTX:Input("Speed", "Speed Multiplier", "edit", "Recommended 0.1 - 1.0", function(text)
    local val = tonumber(text)
    if val and val >= 0 then
        speedValue = val
    end
end)
speedInput:SetTooltip("Enter the speed boost value (e.g. 0.1 = +10%, 0.5 = +50%)", { delay = 0.3 })

local speedSetBtn = APTX:Button("Speed", "Set Speed", "play", function()
    applySpeed()
end)
speedSetBtn:SetTooltip("Apply the selected speed type with your multiplier value", { delay = 0.3 })

local speedClearBtn = APTX:Button("Speed", "Clear Speed", "x", function()
    clearSpeed()
end)
speedClearBtn:SetTooltip("Remove all speed effects and reset character to defaults", { delay = 0.3 })

APTX:Label("Speed", "Speed cannot be automatically turned off by the game")




-- PLAYER STARTUP
APTX:Label("Player", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Player", "Player Modifications")
APTX:Label("Player", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local playerInfJump = APTX:Toggle("Player", "Infinite Jump", "arrow-up", false, function(state)
    local notif = APTX:Notify({
        title = "Infinite Jump",
        content = state and "Infinite Jump enabled! Press Space to fly high." or "Infinite Jump disabled.",
        size = 0.9,
        ["topbar-icon"] = Icons["arrow-up"],
        ["content-icon"] = Icons["info"],
        buttons = {
            { label = "Okay", color = Color3.fromRGB(88, 101, 242), callback = function() notif:Destroy() end }
        },
        duration = 4,
        type = state and "success" or "info"
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
playerInfJump:SetTooltip("Hold Space to jump repeatedly without touching the ground", { delay = 0.3 })

local playerBright = APTX:Toggle("Player", "Fullbright", "sun", false, function(state)
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
playerBright:SetTooltip("Remove all shadows and brighten the entire map for better visibility", { delay = 0.3 })

local playerFov = APTX:Slider("Player", "FOV", "camera", 70, 120, 70, function(value)
    workspace.CurrentCamera.FieldOfView = value
end)
playerFov:SetTooltip("Adjust the camera's field of view (70 = default, 120 = wide)", { delay = 0.3 })


-- SURVIVORS VARS
local automc = false
local automcLoop = nil
local mcstarted = false
local ready = true
local inside = false
local mh = false


-- SURVIVORS FUNCTIONS
-- PERF FIX: Use cached ref, no WaitForChild per frame
local function isMetalCh()
    if not playerFolder then refreshPlayerFolder() end
    if not playerFolder then return false end
    return playerFolder:GetAttribute("DamageReduction") == 1
end

local function mheal()
    local selected = nil

    for _, p in ipairs(Players:GetPlayers()) do
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
    for _, p in ipairs(Players:GetPlayers()) do
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
    for _, p in ipairs(Players:GetPlayers()) do
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

local automcCharConn = nil
local function startAutomc()
    if automcLoop then automcLoop:Disconnect() end
    if automcCharConn then automcCharConn:Disconnect() end
    -- Cache character ref once, refresh only on respawn
    local cachedChar = nil
    local function onCharacterAdded(newChar)
        cachedChar = newChar
    end
    if player.Character then cachedChar = player.Character end
    automcCharConn = player.CharacterAdded:Connect(onCharacterAdded)

    automcLoop = RunService.Heartbeat:Connect(function()
        if not automc then
            automcLoop:Disconnect()
            automcLoop = nil
            if automcCharConn then automcCharConn:Disconnect(); automcCharConn = nil end
            return
        end

        if not exe then return end

        -- PERF FIX: Use cached char ref instead of player.Character each frame
        local char = cachedChar
        if not char then return end
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        local exeRoot = exe.Character and exe.Character:FindFirstChild("HumanoidRootPart")

        if not myRoot or not exeRoot then return end

        local dist = (myRoot.Position - exeRoot.Position).Magnitude
        -- PERF FIX: Use cached playerFolder (no WaitForChild)
        local myChar = getChar()
        if myChar ~= "MetalSonic" and not isMetalCh() then return end
        if dist <= 20 and mh then
            if not inside then
                inside = true
                if ready and not target then
                    ready = false
                    tpexe()
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
APTX:Label("Survivors", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Survivors", "Survivor Assist")
APTX:Label("Survivors", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Survivors", "Auto-aim & utility assists for Survivor team")

local survCream = APTX:Toggle("Survivors", "Cream Helper", "users", false, function(state)
    cream.Enabled = state
end)
survCream:SetTooltip("Automatically use Cream's abilities to assist your team", { delay = 0.3 })

local survStun = APTX:Toggle("Survivors", "Auto metalsonic stun", "send", false, function(state)
    texe = state
end)
survStun:SetTooltip("Press Q (or L1) near EXE to automatically stun them", { delay = 0.3 })

local survHeal = APTX:Toggle("Survivors", "Auto metalsonic eggman heal", "redo", false, function(state)
    -- Feature controlled by E/R1 keybind in InputBegan
end)
survHeal:SetTooltip("Press E (or R1) near Eggman/Tails to auto-heal as MetalSonic", { delay = 0.3 })

local survHitbox = APTX:Toggle("Survivors", "Metalsonic Charge hitbox", "calculator", false, function(state)
    automc = state
    if state then
        if not mcstarted then
            startAutomc()
            mcstarted = true
        end
    else
        mcstarted = false
    end
end)
survHitbox:SetTooltip("Auto-target EXE within 20 studs when playing as MetalSonic", { delay = 0.3 })


-- KILLERS VARS
local s = nil


-- KILLERS FUNCTIONS
local function xcharge()
    local survivors = {}

    for _, p in ipairs(Players:GetPlayers()) do
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
APTX:Label("Killers", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Killers", "Killer Utilities")
APTX:Label("Killers", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Killers", "Auto-win minigames & charge assists for Killer team")

local killSilver = APTX:Toggle("Killers", "Auto Silver Minigame", "wind", false, function(state)
    if s then
        s:Disconnect()
        s = nil
    end

    if not state then return end

    -- PERF FIX: Use cached ref + FindFirstChild instead of WaitForChild
    local character = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(player.Name)
    if not character then return end

    -- PERF FIX: Guard against stacked escape coroutines
    local escapeRunning = false
    local function escape()
        if escapeRunning then return end
        escapeRunning = true
        for i = 1, 20 do
            pcall(mouse2click)
            pcall(mouse1click)
            task.wait(0.1)
        end
        escapeRunning = false
    end

    local function onAdd(child)
        if state and child:IsA("Highlight") then
            escape()
        end
    end

    s = character.ChildAdded:Connect(onAdd)
end)
killSilver:SetTooltip("Automatically click Silver's skill check highlights to win the minigame", { delay = 0.3 })

local killChargeStop = nil
local killChargeAll = APTX:Toggle("Killers", "Charge ALL", "check", false, function(state)
    if state then
        local plrs = Players:GetPlayers()
        killChargeStop = tpeve(0.5, plrs)
    else
        if killChargeStop then
            killChargeStop()
            killChargeStop = nil
        end
    end
end)
killChargeAll:SetTooltip("Unleash a charge attack on every player in the server", { delay = 0.3 })

local killAutoCharge = APTX:Toggle("Killers", "Auto 2011x charge", "send", false, function(state)
    xchr = state
end)
killAutoCharge:SetTooltip("Press E (or R1) as 2011x to auto-charge toward survivors", { delay = 0.3 })


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
APTX:Label("Utilities", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Utilities", "Utility Tools")
APTX:Label("Utilities", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Utilities", "Flight, character selection & misc tools")

local utilKeybind = APTX:Button("Utilities", "Set Fly Keybind", "key", function()
    if listening then return end
    listening = true
end)
utilKeybind:SetTooltip("Click then press any key to bind the fly toggle keybind", { delay = 0.3 })

local utilFlySpeed = APTX:Input("Utilities", "Fly Speed", "edit", "Recommended 1 - 3", function(text)
    flyspeed = tonumber(text) or 1
    if flystate then
        fly:Mobile(flyspeed)
    end
end)
utilFlySpeed:SetTooltip("Set how fast you move while flying (1 = normal, 3 = fast)", { delay = 0.3 })

local utilFly = APTX:Toggle("Utilities", "Fly", "cloud", false, function(state)
    setFly(state)
end)
utilFly:SetTooltip("Enable or disable flight mode to move freely through the map", { delay = 0.3 })

local utilAutoChar = APTX:Toggle("Utilities", "Auto Select Character", "check", false, function(state)
    chractive = state
end)
utilAutoChar:SetTooltip("Automatically vote for your chosen character when a new round starts", { delay = 0.3 })

local utilCharMenu = APTX:Menu("Utilities", "Select Character", "Select...", "user", {
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
    print("[APTX] Character selected:", chr)
end)
utilCharMenu:SetTooltip("Pick which character to auto-select when Auto Select is enabled", { delay = 0.3 })


-- SERVER VARS
local serverPingLabel = nil
local serverPlayersLabel = nil
local serverTimeLabel = nil
local serverJobIdLabel = nil


-- SERVER STARTUP
APTX:Label("Server", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Server", "Server Information")
APTX:Label("Server", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local plr = Players.LocalPlayer

serverJobIdLabel = APTX:Label("Server", "Job ID: " .. game.JobId)

local plIdLabel = APTX:Label("Server", "Place ID: " .. game.PlaceId)

serverPlayersLabel = APTX:Label("Server", "Players: " .. #Players:GetPlayers() .. "/" .. game:GetService("Players").MaxPlayers)

serverPingLabel = APTX:Label("Server", "Ping: 0 ms")

serverTimeLabel = APTX:Label("Server", "Server Time: 0s")

local serverNameLabel = APTX:Label("Server", "Server: " .. (game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"))

APTX:Label("Server", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Server", "Server Actions")
APTX:Label("Server", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local serverJoinInput = APTX:Input("Server", "Join by JobID", "edit", "Enter Job ID...", function(text)
    text = text:match("^%s*(.-)%s*$")
    if text and #text > 0 then
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, text, plr)
        end)
        if not success then
            warn("[APTX] Error joining server:", err)
        end
    end
end)
serverJoinInput:SetTooltip("Paste a server's Job ID and press Enter to teleport to that server", { delay = 0.3 })

local serverRejoin = APTX:Button("Server", "Rejoin Server", "refresh-cw", function()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, plr)
    end)
end)
serverRejoin:SetTooltip("Leave the current server and join a fresh instance of the same place", { delay = 0.3 })

local serverCopyJob = APTX:Button("Server", "Copy Job ID", "copy", function()
    setclipboard(game.JobId)
end)
serverCopyJob:SetTooltip("Copy the current server's unique Job ID to your clipboard", { delay = 0.3 })

local serverCopyPlace = APTX:Button("Server", "Copy Place ID", "copy", function()
    setclipboard(tostring(game.PlaceId))
end)
serverCopyPlace:SetTooltip("Copy the current game's Place ID to your clipboard", { delay = 0.3 })

-- CONFIG VARS
local configAutoLoad = false


-- CONFIG FUNCTIONS
Config:Init({
    folder = "APTX",
    file = "config.json",
    autoSave = false,
})

local function saveSettings()
    Config.batch(function()
        -- Auto Load
        Config.set("autoLoad", configAutoLoad)

        -- Performance
        Config.set("performance.optimizerEnabled", op_e)
        Config.set("performance.minFPS", op_min)

        -- Speed
        Config.set("speed.type", speedType)
        Config.set("speed.value", speedValue)

        -- Player
        Config.set("player.infiniteJump", _G.InfJumpConnection ~= nil)
        Config.set("player.fullbright", playerBright:GetValue())
        Config.set("player.fov", playerFov:GetValue())

        -- Survivors
        Config.set("survivors.creamHelper", survCream:GetValue())
        Config.set("survivors.autoStun", survStun:GetValue())
        Config.set("survivors.autoHeal", survHeal:GetValue())
        Config.set("survivors.chargeHitbox", survHitbox:GetValue())

        -- Killers
        Config.set("killers.autoSilver", killSilver:GetValue())
        Config.set("killers.autoCharge", killAutoCharge:GetValue())

        -- Utilities
        Config.set("utilities.flySpeed", flyspeed)
        Config.set("utilities.autoSelectChar", utilAutoChar:GetValue())
        Config.set("utilities.selectedChar", chr)
        Config.set("utilities.flyKeybind", flyKeybind and tostring(flyKeybind) or nil)
    end)

    APTX:Notify({
        title = "Config Saved",
        content = "All settings have been saved to disk.",
        size = 0.9,
        ["topbar-icon"] = Icons["check"],
        ["content-icon"] = Icons["save"],
        duration = 3,
        type = "success"
    })
end

local function loadSettings()
    Config.batch(function()
        -- Auto Load
        if Config.has("autoLoad") then
            configAutoLoad = Config.get("autoLoad")
            autoLoadToggle:Edit({ value = configAutoLoad })
        end

        -- Performance
        if Config.has("performance.optimizerEnabled") then
            op_e = Config.get("performance.optimizerEnabled")
            perfToggle:Edit({ value = op_e })
            if op_e then
                if not Opt.IsRunning() then
                    Opt.Init({
                        targetFPS = op_min,
                        recoverMargin = 12,
                        farPlaneTarget = 400,
                        particleScale = 0.5,
                    })
                end
                Opt.Enable()
            else
                Opt.Disable()
            end
        end
        if Config.has("performance.minFPS") then
            op_min = Config.get("performance.minFPS")
        end

        -- Speed
        if Config.has("speed.type") then
            speedType = Config.get("speed.type")
            speedTypeMenu:Edit({ selected = speedType })
        end
        if Config.has("speed.value") then
            speedValue = Config.get("speed.value")
            speedInput:SetValue(tostring(speedValue))
        end

        -- Player
        if Config.has("player.infiniteJump") and Config.get("player.infiniteJump") then
            _G.InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                local p = player
                if p.Character and p.Character:FindFirstChild("Humanoid") then
                    p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
        if Config.has("player.fullbright") then
            local fb = Config.get("player.fullbright")
            playerBright:Edit({ value = fb })
            if fb then
                game.Lighting.Brightness = 2
                game.Lighting.ClockTime = 14
                game.Lighting.FogEnd = 100000
                game.Lighting.GlobalShadows = false
                game.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            end
        end
        if Config.has("player.fov") then
            local fov = Config.get("player.fov")
            playerFov:SetValue(fov)
            workspace.CurrentCamera.FieldOfView = fov
        end

        -- Survivors
        if Config.has("survivors.creamHelper") then
            local ch = Config.get("survivors.creamHelper")
            survCream:Edit({ value = ch })
            cream.Enabled = ch
        end
        if Config.has("survivors.autoStun") then
            texe = Config.get("survivors.autoStun")
            survStun:Edit({ value = texe })
        end
        if Config.has("survivors.autoHeal") then
            mhealing = Config.get("survivors.autoHeal")
            survHeal:Edit({ value = mhealing })
        end
        if Config.has("survivors.chargeHitbox") then
            automc = Config.get("survivors.chargeHitbox")
            survHitbox:Edit({ value = automc })
            if automc and not mcstarted then
                startAutomc()
                mcstarted = true
            end
        end

        -- Killers
        if Config.has("killers.autoSilver") then
            killSilver:Edit({ value = Config.get("killers.autoSilver") })
        end
        if Config.has("killers.autoCharge") then
            xchr = Config.get("killers.autoCharge")
            killAutoCharge:Edit({ value = xchr })
        end

        -- Utilities
        if Config.has("utilities.flySpeed") then
            flyspeed = Config.get("utilities.flySpeed")
            utilFlySpeed:SetValue(tostring(flyspeed))
        end
        if Config.has("utilities.autoSelectChar") then
            chractive = Config.get("utilities.autoSelectChar")
            utilAutoChar:Edit({ value = chractive })
        end
        if Config.has("utilities.selectedChar") then
            chr = Config.get("utilities.selectedChar")
            utilCharMenu:Edit({ selected = chr })
        end
        if Config.has("utilities.flyKeybind") then
            local keyName = Config.get("utilities.flyKeybind")
            if keyName then
                flyKeybind = Enum.KeyCode[keyName]
            end
        end
    end)

    APTX:Notify({
        title = "Config Loaded",
        content = "All saved settings have been restored.",
        size = 0.9,
        ["topbar-icon"] = Icons["check"],
        ["content-icon"] = Icons["upload"],
        duration = 3,
        type = "success"
    })
end


-- CONFIG STARTUP
APTX:Label("Config", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Config", "Configuration Manager")
APTX:Label("Config", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
APTX:Label("Config", "Save and load all your settings across sessions")

local autoLoadToggle = APTX:Toggle("Config", "Auto Load Config", "refresh-cw", false, function(state)
    configAutoLoad = state
    Config.set("autoLoad", state)
end)
autoLoadToggle:SetTooltip("Automatically load saved settings when the script runs", { delay = 0.3 })

local configSaveBtn = APTX:Button("Config", "Save Config", "save", function()
    saveSettings()
end)
configSaveBtn:SetTooltip("Save all current toggle states, sliders, and selections to disk", { delay = 0.3 })

local configLoadBtn = APTX:Button("Config", "Load Config", "upload", function()
    loadSettings()
end)
configLoadBtn:SetTooltip("Restore all saved settings from disk and apply them", { delay = 0.3 })

local configResetBtn = APTX:Button("Config", "Reset Config", "trash", function()
    Config.reset()
    configAutoLoad = false
    autoLoadToggle:Edit({ value = false })
    APTX:Notify({
        title = "Config Reset",
        content = "All saved configuration has been erased.",
        size = 0.9,
        ["topbar-icon"] = Icons["check"],
        ["content-icon"] = Icons["trash"],
        duration = 3,
        type = "info"
    })
end)
configResetBtn:SetTooltip("Delete all saved configuration data from disk", { delay = 0.3 })

-- Auto-load saved config if enabled
task.spawn(function()
    task.wait(1)
    pcall(function()
        if Config.getOrDefault("autoLoad", false) then
            configAutoLoad = true
            autoLoadToggle:Edit({ value = true })
            loadSettings()
        end
    end)
end)


-- Loop para actualizar info del servidor cada 2 segundos
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local ping = math.floor(plr:GetNetworkPing() * 1000)
            local playerCount = #Players:GetPlayers()
            local maxPlayers = game:GetService("Players").MaxPlayers
            local serverTime = math.floor(workspace.DistributedGameTime)
            local jobId = game.JobId
            local hours = math.floor(serverTime / 3600)
            local minutes = math.floor((serverTime % 3600) / 60)
            local seconds = serverTime % 60
            local timeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)

            if serverPingLabel then
                serverPingLabel:SetText("Ping: " .. ping .. " ms")
            end
            if serverPlayersLabel then
                serverPlayersLabel:SetText("Players: " .. playerCount .. "/" .. maxPlayers)
            end
            if serverTimeLabel then
                serverTimeLabel:SetText("Server Time: " .. timeStr)
            end
            if serverJobIdLabel then
                serverJobIdLabel:SetText("Job ID: " .. jobId)
            end
        end)
    end
end)


-- LISTENERS
-- PERF FIX: Removed task.wait(7), added debounce to prevent stacked coroutines
local stateDebounce = false
Workspace.GameProperties.State.Changed:Connect(function(value)
    if stateDebounce then return end
    stateDebounce = true
    -- Wait for SEC phase to settle before acting
    task.delay(2, function()
        stateDebounce = false
        if value == "SEC" and chractive and chr then
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local voted = remotes:FindFirstChild("Voted")
                    if voted then
                        voted:FireServer(chr)
                    end
                end
            end)
        end
    end)
end)

-- PERF FIX: Consolidated InputBegan — early returns, debounce, no duplicate key checks
local keyDebounce = {}
local KEY_DEBOUNCE_CD = 0.15

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Unknown then return end

    local key = input.KeyCode

    -- Keybind listener (always allowed, no debounce needed)
    if listening then
        flyKeybind = key
        listening = false
        return
    end

    -- Fly keybind
    if flyKeybind and key == flyKeybind then
        toggleFly()
        return
    end

    -- PERF FIX: Early return — skip gameState/getChar for non-game keys
    local isGameKey = (key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonL1
                   or key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonR1)
    if not isGameKey then return end

    local state = gameState()
    if state ~= "ING" and state ~= "80s" then return end

    -- PERF FIX: Debounce per key to prevent coroutine spam
    local now = tick()
    if keyDebounce[key] and (now - keyDebounce[key]) < KEY_DEBOUNCE_CD then return end
    keyDebounce[key] = now

    local char = getChar()

    -- Consolidated Q/L1 handler (was two separate if blocks)
    if (key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonL1) and texe then
        if char == "Sonic" or char == "MetalSonic" then
            task.spawn(function()
                task.wait(1.5)
                tpexe()
            end)
        end
        if char == "MetalSonic" then
            local cd = getCooldown(1)
            if cd and tonumber(cd) == 0 then
                mh = true
                task.delay(10, function()
                    mh = false
                end)
            end
        end
    end

    -- Consolidated E/R1 handler (was two separate if blocks)
    if (key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonR1) and xchr then
        if char == "2011x" then
            task.spawn(function()
                task.wait(3)
                xcharge()
            end)
        elseif char == "MetalSonic" then
            mheal()
        end
    end
end)


-- PERF FIX: Event-driven EXE finder — no polling loop
local function refreshExePlayer()
    exe = nil
    local folder = workspace:FindFirstChild("Players")
    if not folder then return end
    for _, p in ipairs(Players:GetPlayers()) do
        local obj = folder:FindFirstChild(p.Name)
        if obj and obj:GetAttribute("Team") == "EXE" then
            exe = p
            break
        end
    end
end

-- Initial scan
refreshExePlayer()

-- Refresh when players join/leave
Players.PlayerAdded:Connect(function()
    task.wait(1)
    refreshExePlayer()
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    refreshExePlayer()
end)

-- Also refresh when player folder attributes change (team swaps)
local exePlayersFolder = workspace:FindFirstChild("Players")
if exePlayersFolder then
    exePlayersFolder.ChildAdded:Connect(function(child)
        task.wait(0.5)
        if child:GetAttribute("Team") == "EXE" then
            exe = Players:FindFirstChild(child.Name)
        end
    end)
    exePlayersFolder.ChildRemoved:Connect(function()
        task.wait(0.5)
        refreshExePlayer()
    end)
end
