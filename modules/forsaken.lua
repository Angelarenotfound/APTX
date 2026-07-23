-- ============================================================
-- MÓDULO: VEE (Auto Sprint)
-- ============================================================
local VeeModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local VEE_CONFIG = {
    Platform = "Mobile",
    SprintKey = Enum.KeyCode.Space,
    ConsoleButton = Enum.KeyCode.ButtonA
}

local veeState = {
    enabled = false,
    activeMonitors = {},
    descendantAddedConn = nil,
    sprintBindName = "AutoSprintBind",
    pcConnection = nil,
    consoleConnection = nil
}

local function getBehaviorFolder()
    local assets = ReplicatedStorage:WaitForChild("Assets", 15)
    if not assets then return nil end
    local surv = assets:WaitForChild("Survivors", 15)
    if not surv then return nil end
    local vee = surv:WaitForChild("Veeronica", 15)
    if not vee then return nil end
    return vee:WaitForChild("Behavior", 15)
end

local function getSprintingButton()
    return player.PlayerGui:WaitForChild("MainUI"):WaitForChild("SprintingButton")
end

local function safeConnectPropertyChanged(instance, prop, fn)
    local ok, signal = pcall(function()
        return instance:GetPropertyChangedSignal(prop)
    end)
    if ok and signal then
        return signal:Connect(fn)
    end
    return nil
end

local function triggerSprint()
    if not veeState.enabled then return end
    local ok, btn = pcall(getSprintingButton)
    if ok and btn then
        for i, v in pairs(getconnections(btn.MouseButton1Down)) do
            pcall(function()
                if v.Function then v:Function() end
            end)
        end
    end
end

local function setupControlsVee()
    if VEE_CONFIG.Platform == "PC" then
        if veeState.pcConnection then veeState.pcConnection:Disconnect() end
        veeState.pcConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == VEE_CONFIG.SprintKey then
                triggerSprint()
            end
        end)
    elseif VEE_CONFIG.Platform == "Console" then
        if veeState.consoleConnection then 
            ContextActionService:UnbindAction(veeState.sprintBindName)
        end
        veeState.consoleConnection = function(actionName, inputState, inputObject)
            if actionName == veeState.sprintBindName and inputState == Enum.UserInputState.Begin then
                triggerSprint()
                return Enum.ContextActionResult.Sink
            end
            return Enum.ContextActionResult.Pass
        end
        ContextActionService:BindActionAtPriority(
            veeState.sprintBindName,
            veeState.consoleConnection,
            false,
            1,
            VEE_CONFIG.ConsoleButton,
            Enum.KeyCode.ButtonR1,
            Enum.KeyCode.ButtonL1
        )
    end
end

local function monitorHighlight(h)
    if not h or veeState.activeMonitors[h] then return end

    local connections = {}
    local prevState = false

    local function cleanup()
        for _, conn in ipairs(connections) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        veeState.activeMonitors[h] = nil
    end

    local function adorneeIsPlayerCharacter(h)
        if not h then return false end
        local adornee = h.Adornee
        local char = player.Character
        if not adornee or not char then return false end
        if adornee == char then return true end
        if adornee:IsDescendantOf(char) then return true end
        return false
    end

    local function onChanged()
        if not veeState.enabled then return end
        if not h or not h.Parent then cleanup() return end

        local currState = adorneeIsPlayerCharacter(h)
        if prevState ~= currState and currState then
            triggerSprint()
        end
        prevState = currState
    end

    local c = safeConnectPropertyChanged(h, "Adornee", onChanged)
    if c then table.insert(connections, c) end

    table.insert(connections, h.AncestryChanged:Connect(function(_, parent)
        if not parent then cleanup() else onChanged() end
    end))

    table.insert(connections, player.CharacterAdded:Connect(onChanged))
    table.insert(connections, player.CharacterRemoving:Connect(onChanged))

    veeState.activeMonitors[h] = cleanup
    task.spawn(onChanged)
end

local function startManager()
    if veeState.descendantAddedConn then return end

    local behaviorFolder = getBehaviorFolder()   -- ✅ lazy
    if not behaviorFolder then
        warn("[Vee] Behavior folder no disponible aún")
        return
    end

    for _, desc in ipairs(behaviorFolder:GetDescendants()) do
        if desc:IsA("Highlight") then
            monitorHighlight(desc)
        end
    end

    veeState.descendantAddedConn = behaviorFolder.DescendantAdded:Connect(function(child)
        if child:IsA("Highlight") then
            monitorHighlight(child)
        end
    end)
end

local function stopManager()
    if veeState.descendantAddedConn and veeState.descendantAddedConn.Connected then
        veeState.descendantAddedConn:Disconnect()
    end
    veeState.descendantAddedConn = nil

    local cleans = {}
    for h, cleanup in pairs(veeState.activeMonitors) do
        if type(cleanup) == "function" then
            table.insert(cleans, cleanup)
        end
    end
    for _, fn in ipairs(cleans) do
        pcall(fn)
    end
    veeState.activeMonitors = {}
end

function VeeModule.SetPlatform(platform)
    if platform ~= "PC" and platform ~= "Console" and platform ~= "Mobile" then
        return false
    end
    VEE_CONFIG.Platform = platform
    if veeState.enabled then
        setupControlsVee()
    end
    return true
end

function VeeModule.Start()
    if veeState.enabled then return end
    veeState.enabled = true
    setupControlsVee()
    startManager()
end

function VeeModule.Stop()
    if not veeState.enabled then return end
    veeState.enabled = false
    stopManager()
    if VEE_CONFIG.Platform == "Console" then
        ContextActionService:UnbindAction(veeState.sprintBindName)
    end
    if veeState.pcConnection then
        veeState.pcConnection:Disconnect()
        veeState.pcConnection = nil
    end
end

-- ============================================================
-- MÓDULO: KILLERS (Follow Up) - CORREGIDO
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

-- ============================================================
-- MÓDULO: GEN (Flow Game Solver)
-- ============================================================
local GenModule = {}

local genConfig = {
    enabled = false,
    speed = 0.03
}

-- Implementación de table.clone
if not table.clone then
    function table.clone(t)
        local result = {}
        for k, v in pairs(t) do
            result[k] = v
        end
        return result
    end
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Error en función: " .. tostring(result))
        return nil, result
    end
    return result
end

local function safeWait(delay)
    if type(delay) ~= "number" or delay < 0 then
        delay = 0.03
    end
    task.wait(delay)
end

local function getDirection(currentRow, currentCol, otherRow, otherCol)
    if not currentRow or not currentCol or not otherRow or not otherCol then
        return nil
    end

    if otherRow < currentRow then
        return "up"
    end
    if otherRow > currentRow then
        return "down"
    end
    if otherCol < currentCol then
        return "left"
    end
    if otherCol > currentCol then
        return "right"
    end
    return nil
end

local function getConnections(prev, curr, nextnode)
    local connections = {}

    if prev and curr then
        local dir = getDirection(curr.row, curr.col, prev.row, prev.col)
        if dir then
            if dir == "up" then
                dir = "down"
            elseif dir == "down" then
                dir = "up"
            elseif dir == "left" then
                dir = "right"
            elseif dir == "right" then
                dir = "left"
            end
            if dir ~= "" and dir then
                connections[dir] = true
            end
        end
    end

    if nextnode and curr then
        local dir = getDirection(curr.row, curr.col, nextnode.row, nextnode.col)
        if dir and dir ~= "" then
            connections[dir] = true
        end
    end

    return connections
end

local function isNeighbourLocal(r1, c1, r2, c2)
    if not r1 or not c1 or not r2 or not c2 then
        return false
    end

    if r2 == r1 - 1 and c2 == c1 then
        return "up"
    end
    if r2 == r1 + 1 and c2 == c1 then
        return "down"
    end
    if r2 == r1 and c2 == c1 - 1 then
        return "left"
    end
    if r2 == r1 and c2 == c1 + 1 then
        return "right"
    end
    return false
end

local function coordKey(node)
    if not node or not node.row or not node.col then
        return nil
    end
    return string.format("%d-%d", node.row, node.col)
end

local function orderPathFromEndpoints(path, endpoints)
    if not path or #path == 0 then
        return path or {}
    end

    local startEndpoint = nil

    if endpoints and type(endpoints) == "table" then
        for _, ep in endpoints do
            if ep and ep.row and ep.col then
                for _, n in path do
                    if n.row == ep.row and n.col == ep.col then
                        startEndpoint = { row = ep.row, col = ep.col }
                        break
                    end
                end
            end
            if startEndpoint then
                break
            end
        end
    end

    if not startEndpoint then
        local inPath = {}
        for _, n in path do
            local key = coordKey(n)
            if key then
                inPath[key] = n
            end
        end

        for _, n in path do
            local neighbours = 0
            local dirs = {
                { n.row - 1, n.col },
                { n.row + 1, n.col },
                { n.row, n.col - 1 },
                { n.row, n.col + 1 }
            }
            for _, dir in dirs do
                local r, c = dir[1], dir[2]
                local key = string.format("%d-%d", r, c)
                if inPath[key] ~= nil then
                    neighbours = neighbours + 1
                end
            end
            if neighbours == 1 then
                startEndpoint = { row = n.row, col = n.col }
                break
            end
        end
    end

    if not startEndpoint and path[1] then
        startEndpoint = { row = path[1].row, col = path[1].col }
    end

    if not startEndpoint then
        return path
    end

    local remaining = {}
    for _, n in path do
        local key = coordKey(n)
        if key then
            remaining[key] = { row = n.row, col = n.col }
        end
    end

    local ordered = {}
    local current = { row = startEndpoint.row, col = startEndpoint.col }
    table.insert(ordered, table.clone(current))

    local key = coordKey(current)
    if key then
        remaining[key] = nil
    end

    while true do
        local size = 0
        for _ in remaining do
            size = size + 1
        end
        if not (size > 0) then
            break
        end

        local foundNext = false
        for key, node in remaining do
            local neighbour = isNeighbourLocal(current.row, current.col, node.row, node.col)
            if neighbour then
                table.insert(ordered, table.clone(node))
                remaining[key] = nil
                current = node
                foundNext = true
                break
            end
        end
        if not foundNext then
            return path
        end
    end

    return ordered
end

local HintSystem = {}

function HintSystem:DrawSolutionOneByOne(puzzle, delayTime)
    if not genConfig.enabled then
        return nil
    end

    if not puzzle or not puzzle.Solution then
        warn("Puzzle no válido o sin solución")
        return nil
    end

    if delayTime == nil then
        delayTime = genConfig.speed
    end

    if type(delayTime) ~= "number" or delayTime < 0 then
        delayTime = 0.03
    end

    local totalPaths = #puzzle.Solution
    if totalPaths == 0 then
        warn("No hay caminos para dibujar")
        return nil
    end

    local indices = {}
    for i = 1, totalPaths do
        table.insert(indices, i)
    end

    for i = #indices - 1, 2, -1 do
        local j = math.random(1, i)
        local temp = indices[i + 1]
        indices[i + 1] = indices[j + 1]
        indices[j + 1] = temp
    end

    for _, colorIndex in indices do
        if puzzle.Solution[colorIndex] then
            local path = puzzle.Solution[colorIndex]
            local endpoints = puzzle.targetPairs and puzzle.targetPairs[colorIndex]
            local orderedPath = orderPathFromEndpoints(path, endpoints)

            if orderedPath and #orderedPath > 0 then
                if not puzzle.paths then
                    puzzle.paths = {}
                end
                puzzle.paths[colorIndex] = {}

                for i = 0, #orderedPath - 1 do
                    local node = orderedPath[i + 1]
                    if node and node.row and node.col then
                        table.insert(puzzle.paths[colorIndex], { row = node.row, col = node.col })

                        local prev = orderedPath[i]
                        local nextNode = orderedPath[i + 2]
                        local conn = getConnections(prev, node, nextNode)

                        if not puzzle.gridConnections then
                            puzzle.gridConnections = {}
                        end
                        local key = string.format("%d-%d", node.row, node.col)
                        puzzle.gridConnections[key] = conn

                        local success = safeCall(function()
                            if puzzle.updateGui then
                                puzzle:updateGui()
                            end
                        end)

                        if not success then
                            warn("Error al actualizar GUI")
                        end

                        safeWait(delayTime)
                    end
                end

                local success = safeCall(function()
                    if puzzle.checkForWin then
                        puzzle:checkForWin()
                    end
                end)

                if not success then
                    warn("Error al verificar victoria")
                end
            else
                warn("Camino ordenado vacío para color " .. tostring(colorIndex))
            end
        else
            warn("Índice de color " .. tostring(colorIndex) .. " no existe en la solución")
        end
    end

    local success = safeCall(function()
        if puzzle.checkForWin then
            puzzle:checkForWin()
        end
    end)

    if not success then
        warn("Error en verificación final")
    end
end

local function patchFlowGame()
    local success, ReplicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)

    if not success or not ReplicatedStorage then
        warn("No se pudo obtener ReplicatedStorage")
        return nil
    end

    local Modules = nil
    local attempts = 0
    while not Modules and attempts < 10 do
        local success, result = pcall(function()
            return ReplicatedStorage:FindFirstChild("Modules")
        end)
        if success and result then
            Modules = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    end

    if not Modules then
        warn("No se encontró el módulo Modules después de varios intentos")
        return nil
    end

    local Misc = nil
    attempts = 0
    while not Misc and attempts < 10 do
        local success, result = pcall(function()
            return Modules:FindFirstChild("Misc")
        end)
        if success and result then
            Misc = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    end

    if not Misc then
        warn("No se encontró el módulo Misc")
        return nil
    end

    local FlowGameManager = nil
    attempts = 0
    while not FlowGameManager and attempts < 10 do
        local success, result = pcall(function()
            return Misc:FindFirstChild("FlowGameManager")
        end)
        if success and result then
            FlowGameManager = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    end

    if not FlowGameManager then
        warn("No se encontró FlowGameManager")
        return nil
    end

    local FlowGameModule = nil
    attempts = 0
    while not FlowGameModule and attempts < 10 do
        local success, result = pcall(function()
            return FlowGameManager:FindFirstChild("FlowGame")
        end)
        if success and result then
            FlowGameModule = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    end

    if not FlowGameModule then
        warn("No se encontró el módulo FlowGame")
        return nil
    end

    local gameModule = nil
    local success, result = pcall(function()
        return require(FlowGameModule)
    end)

    if not success or not result then
        warn("No se pudo cargar el módulo FlowGame: " .. tostring(result))
        return nil
    end

    gameModule = result

    if gameModule.new then
        local oldNew = gameModule.new
        gameModule.new = function(...)
    local success, result = pcall(oldNew, ...)   -- ✅ ... usado en scope válido

    if not success or not result then
        warn("Error al crear nuevo FlowGame: " .. tostring(result))
        return result
    end

    local puzzle = result

    task.spawn(function()
        local success = safeCall(function()
            HintSystem:DrawSolutionOneByOne(puzzle)
        end)
        if not success then
            warn("Error al ejecutar HintSystem")
        end
    end)

    return puzzle
end
    else
        warn("El módulo FlowGame no tiene función 'new'")
        return nil
    end
end

function GenModule.State(enabled)
    if enabled ~= nil then
        genConfig.enabled = enabled
    end
    return genConfig.enabled
end

function GenModule.Speed(speed)
    if speed ~= nil and type(speed) == "number" and speed >= 0 then
        genConfig.speed = speed
    end
    return genConfig.speed
end

task.spawn(function()
    local success = safeCall(patchFlowGame)
    if not success then
        warn("Error al parchear FlowGame")
    end
end)

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

-- ============================================================
-- EXPORTACIÓN DE MÓDULOS
-- ============================================================
return {
    Vee = VeeModule,
    Killers = KillersModule,
    Gen = GenModule,
    Dagger = DaggerModule
}