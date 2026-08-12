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

    local behaviorFolder = getBehaviorFolder()
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

return VeeModule