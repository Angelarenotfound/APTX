local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DEFAULT_CONFIG = {
    ENABLE_LOGGING = true,
    HUMAN_DELAY_MIN = 0.01,
    HUMAN_DELAY_MAX = 0.04,
    HIT_ZONE_MIN = 0.35,
    HIT_ZONE_MAX = 0.65
}

local function log(message, level)
    if not _CONFIG or not _CONFIG.ENABLE_LOGGING then return end
    print(string.format("[AutoStruggle][%s] %s", level or "INFO", message))
end

local function safeCall(func, ...)
    local ok, result = pcall(func, ...)
    if not ok then log(tostring(result), "ERROR") end
    return ok, result
end

local function extractKeyFromText(text)
    if type(text) ~= "string" or text == "" then return nil end
    local inner = text:match(">%s*(.-)%s*<")
    if not inner then inner = text:gsub("[>%s<]", "") end
    inner = string.upper(inner)

    if inner == "W" then return Enum.KeyCode.W
    elseif inner == "A" then return Enum.KeyCode.A
    elseif inner == "S" then return Enum.KeyCode.S
    elseif inner == "D" then return Enum.KeyCode.D
    end

    if inner == "UP" or inner == "▲" or inner == "↑" or inner == "⬆" then
        return Enum.KeyCode.DPadUp
    elseif inner == "DOWN" or inner == "▼" or inner == "↓" or inner == "" then
        return Enum.KeyCode.DPadDown
    elseif inner == "LEFT" or inner == "◄" or inner == "◀" or inner == "←" then
        return Enum.KeyCode.DPadLeft
    elseif inner == "RIGHT" or inner == "►" or inner == "▶" or inner == "→" then
        return Enum.KeyCode.DPadRight
    end

    return nil
end

local function simulateKeyPress(keyCode)
    if not keyCode then return false end
    return pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

local Struggle = {}
local _CONFIG = nil
local _heartbeatConn = nil
local _guiWatcherAddConn = nil
local _guiWatcherRemConn = nil
local _lastProcessedKey = nil
local _minigameGui = nil
local _keyDisplay = nil
local _leftHit = nil
local _rightHit = nil
local _isRunning = false

local function isInHitZone()
    if not _leftHit or not _rightHit then return false end
    if not _leftHit.Parent or not _rightHit.Parent then return false end

    local leftScale = _leftHit.Position.X.Scale
    local rightScale = _rightHit.Position.X.Scale

    local leftInZone = leftScale >= _CONFIG.HIT_ZONE_MIN and leftScale <= _CONFIG.HIT_ZONE_MAX
    local rightInZone = rightScale >= _CONFIG.HIT_ZONE_MIN and rightScale <= _CONFIG.HIT_ZONE_MAX

    return leftInZone or rightInZone
end

local function isBarAtStart()
    if not _leftHit or not _leftHit.Parent then return false end
    local scale = _leftHit.Position.X.Scale
    return scale < 0.1
end

local function onHeartbeat()
    if not _minigameGui or not _minigameGui.Parent then 
        return 
    end

    local container = _minigameGui:FindFirstChild("thecoolminigame")
    if not container then return end

    local leftBar = container:FindFirstChild("left")
    local rightBar = container:FindFirstChild("right")

    local isActive = false
    if leftBar then
        local lb = leftBar:FindFirstChild("leftBar")
        if lb and lb.ImageTransparency < 0.6 then isActive = true end
    end
    if rightBar then
        local rb = rightBar:FindFirstChild("rightBar")
        if rb and rb.ImageTransparency < 0.6 then isActive = true end
    end

    if not isActive then
        _lastProcessedKey = nil 
        return
    end

    if not _keyDisplay or not _keyDisplay.Parent then return end
    
    local _, text = safeCall(function() return _keyDisplay.Text end)
    
    if not text or text == "" then return end

    local keyCode = extractKeyFromText(text)
    if not keyCode then return end

    if isInHitZone() then
        local shouldPress = false

        if text ~= _lastProcessedKey then
            shouldPress = true
        else
            if isBarAtStart() then
                shouldPress = true
            end
        end

        if shouldPress then
            local delay = math.random() * (_CONFIG.HUMAN_DELAY_MAX - _CONFIG.HUMAN_DELAY_MIN) + _CONFIG.HUMAN_DELAY_MIN
            task.wait(delay)

            if _minigameGui and _minigameGui.Parent then
                if simulateKeyPress(keyCode) then
                    _lastProcessedKey = text
                    log("✅ Pressed " .. tostring(keyCode), "INFO")
                else
                    log("❌ Failed to press key", "ERROR")
                end
            end
        end
    end
end

local function connectHeartbeat()
    if _heartbeatConn then
        _heartbeatConn:Disconnect()
    end
    _heartbeatConn = RunService.Heartbeat:Connect(onHeartbeat)
end

local function disconnectAndClean()
    if _heartbeatConn then
        _heartbeatConn:Disconnect()
        _heartbeatConn = nil
    end
    
    _minigameGui = nil
    _keyDisplay = nil
    _leftHit = nil
    _rightHit = nil
    _lastProcessedKey = nil
end

local function startGuiWatcher()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    _guiWatcherAddConn = playerGui.ChildAdded:Connect(function(child)
        if child.Name == "Struggle" and _isRunning then
            log("Struggle GUI detected - Initializing", "INFO")
            _minigameGui = child

            task.spawn(function()
                local container = child:WaitForChild("thecoolminigame", 5)
                if container and _minigameGui == child then
                    _keyDisplay = container:WaitForChild("key2press", 5)

                    local left = container:WaitForChild("left", 5)
                    local right = container:WaitForChild("right", 5)
                    
                    if left and _minigameGui == child then 
                        _leftHit = left:WaitForChild("leftHit", 5) 
                    end
                    if right and _minigameGui == child then 
                        _rightHit = right:WaitForChild("rightHit", 5) 
                    end

                    if _keyDisplay and _leftHit and _rightHit then
                        log("GUI elements initialized - Starting AutoPlay", "INFO")
                        connectHeartbeat()
                    end
                end
            end)
        end
    end)

    _guiWatcherRemConn = playerGui.ChildRemoved:Connect(function(child)
        if child.Name == "Struggle" then
            log("Struggle GUI removed - Cleaning Up", "INFO")
            disconnectAndClean()
        end
    end)
end

function Struggle.Enable(config)
    if _isRunning then return end

    _CONFIG = config or DEFAULT_CONFIG
    for k, v in pairs(DEFAULT_CONFIG) do
        if _CONFIG[k] == nil then _CONFIG[k] = v end
    end

    _isRunning = true
    _lastProcessedKey = nil

    log("AutoStruggle System Enabled", "INFO")

    startGuiWatcher()
    
    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local existingStruggle = playerGui:FindFirstChild("Struggle")
        if existingStruggle then
            log("Struggle GUI already present, initializing immediately", "INFO")
            _minigameGui = existingStruggle
            task.spawn(function()
                local container = existingStruggle:WaitForChild("thecoolminigame", 5)
                if container then
                    _keyDisplay = container:WaitForChild("key2press", 5)
                    local left = container:WaitForChild("left", 5)
                    local right = container:WaitForChild("right", 5)
                    if left then _leftHit = left:WaitForChild("leftHit", 5) end
                    if right then _rightHit = right:WaitForChild("rightHit", 5) end
                    if _keyDisplay and _leftHit and _rightHit then
                        connectHeartbeat()
                    end
                end
            end)
        end
    end
end

function Struggle.Disable()
    if not _isRunning then return end

    _isRunning = false
    log("AutoStruggle System Disabled", "INFO")

    if _guiWatcherAddConn then
        _guiWatcherAddConn:Disconnect()
        _guiWatcherAddConn = nil
    end
    if _guiWatcherRemConn then
        _guiWatcherRemConn:Disconnect()
        _guiWatcherRemConn = nil
    end

    disconnectAndClean()
end

return Struggle