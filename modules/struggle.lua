local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuración por defecto
local DEFAULT_CONFIG = {
    ENABLE_LOGGING = true,
    HUMAN_DELAY_MIN = 0.01,
    HUMAN_DELAY_MAX = 0.04,
    -- Zona de éxito basada en escala (0-1). 
    -- Las barras deben estar entre el 30% y 70% del contenedor para presionar.
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
local _guiWatcherConn = nil
local _lastProcessedKey = nil
local _minigameGui = nil
local _keyDisplay = nil
local _leftHit = nil
local _rightHit = nil
local _isRunning = false

-- Verifica si alguna barra móvil está dentro de la zona de éxito (basado en escala X)
local function isInHitZone()
    if not _leftHit or not _rightHit then return false end
    
    local leftScale = _leftHit.Position.X.Scale
    local rightScale = _rightHit.Position.X.Scale
    
    -- Ajuste para rotaciones: si la barra está rotada -90 grados, 
    -- su movimiento principal podría estar en Y. 
    -- Pero basándonos en tu explorador, leftHit/rightHit usan Position X.
    
    local leftInZone = leftScale >= _CONFIG.HIT_ZONE_MIN and leftScale <= _CONFIG.HIT_ZONE_MAX
    local rightInZone = rightScale >= _CONFIG.HIT_ZONE_MIN and rightScale <= _CONFIG.HIT_ZONE_MAX
    
    return leftInZone or rightInZone
end

-- Bucle principal conectado a Heartbeat
local function onHeartbeat()
    if not _isRunning or not _minigameGui or not _minigameGui.Parent then 
        return 
    end
    
    -- Verificar si el minijuego sigue activo (barras visibles)
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
        _lastProcessedKey = nil -- Resetear cuando termina una ronda
        return
    end
    
    -- Leer tecla actual
    if not _keyDisplay then return end
    local _, text = safeCall(function() return _keyDisplay.Text end)
    if not text or text == "" or text == _lastProcessedKey then return end
    
    local keyCode = extractKeyFromText(text)
    if not keyCode then return end
    
    -- Esperar a que las barras entren en zona
    if isInHitZone() then
        local delay = math.random() * (_CONFIG.HUMAN_DELAY_MAX - _CONFIG.HUMAN_DELAY_MIN) + _CONFIG.HUMAN_DELAY_MIN
        task.wait(delay)
        
        if simulateKeyPress(keyCode) then
            _lastProcessedKey = text
            log("✅ Pressed " .. tostring(keyCode), "INFO")
        else
            log("❌ Failed to press key", "ERROR")
        end
    end
end

-- Vigila la aparición/desaparición de la GUI
local function startGuiWatcher()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    _guiWatcherConn = playerGui.ChildAdded:Connect(function(child)
        if child.Name == "Struggle" and _isRunning then
            log("Struggle GUI detected", "INFO")
            _minigameGui = child
            
            local container = child:WaitForChild("thecoolminigame", 5)
            if container then
                _keyDisplay = container:WaitForChild("key2press", 5)
                
                local left = container:WaitForChild("left", 5)
                local right = container:WaitForChild("right", 5)
                if left then _leftHit = left:WaitForChild("leftHit", 5) end
                if right then _rightHit = right:WaitForChild("rightHit", 5) end
                
                log("GUI elements initialized", "INFO")
            end
        end
    end)
    
    playerGui.ChildRemoved:Connect(function(child)
        if child.Name == "Struggle" then
            log("Struggle GUI removed", "INFO")
            _minigameGui = nil
            _keyDisplay = nil
            _leftHit = nil
            _rightHit = nil
            _lastProcessedKey = nil
        end
    end)
end

function Struggle.Enable(config)
    if _isRunning then return end
    
    _CONFIG = config or DEFAULT_CONFIG
    -- Fusionar config personalizada con defaults
    for k, v in pairs(DEFAULT_CONFIG) do
        if _CONFIG[k] == nil then _CONFIG[k] = v end
    end
    
    _isRunning = true
    _lastProcessedKey = nil
    
    log("AutoStruggle enabled", "INFO")
    
    -- Iniciar watcher de GUI
    startGuiWatcher()
    
    -- Conectar Heartbeat
    _heartbeatConn = RunService.Heartbeat:Connect(onHeartbeat)
end

function Struggle.Disable()
    if not _isRunning then return end
    
    _isRunning = false
    
    if _heartbeatConn then
        _heartbeatConn:Disconnect()
        _heartbeatConn = nil
    end
    
    if _guiWatcherConn then
        _guiWatcherConn:Disconnect()
        _guiWatcherConn = nil
    end
    
    _minigameGui = nil
    _keyDisplay = nil
    _leftHit = nil
    _rightHit = nil
    _lastProcessedKey = nil
    
    log("AutoStruggle disabled", "INFO")
end

return Struggle