local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local CONFIG = {
    Platform = "Mobile",
    SprintKey = Enum.KeyCode.Space,
    ConsoleButton = Enum.KeyCode.ButtonA
}

local state = {
    enabled = false,
    activeMonitors = {},
    descendantAddedConn = nil,
    sprintBindName = "AutoSprintBind",
    pcConnection = nil,
    consoleConnection = nil
}

local function getBehaviorFolder()
    return ReplicatedStorage:WaitForChild("Assets")
        :WaitForChild("Survivors")
        :WaitForChild("Veeronica")
        :WaitForChild("Behavior")
end

local function getSprintingButton()
    return player.PlayerGui:WaitForChild("MainUI"):WaitForChild("SprintingButton")
end

local behaviorFolder = getBehaviorFolder()

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
    if not state.enabled then return end
    local ok, btn = pcall(getSprintingButton)
    if ok and btn then
        for i, v in pairs(getconnections(btn.MouseButton1Down)) do
            pcall(function()
                if v.Function then v:Function() end
            end)
        end
    end
end

local function setupControls()
    if CONFIG.Platform == "PC" then
        if state.pcConnection then state.pcConnection:Disconnect() end
        state.pcConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == CONFIG.SprintKey then
                triggerSprint()
            end
        end)
    elseif CONFIG.Platform == "Console" then
        if state.consoleConnection then 
            ContextActionService:UnbindAction(state.sprintBindName)
        end
        state.consoleConnection = function(actionName, inputState, inputObject)
            if actionName == state.sprintBindName and inputState == Enum.UserInputState.Begin then
                triggerSprint()
                return Enum.ContextActionResult.Sink
            end
            return Enum.ContextActionResult.Pass
        end
        ContextActionService:BindActionAtPriority(
            state.sprintBindName,
            state.consoleConnection,
            false,
            1,
            CONFIG.ConsoleButton,
            Enum.KeyCode.ButtonR1,
            Enum.KeyCode.ButtonL1
        )
    end
end

local function monitorHighlight(h)
    if not h or state.activeMonitors[h] then return end

    local connections = {}
    local prevState = false

    local function cleanup()
        for _, conn in ipairs(connections) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        state.activeMonitors[h] = nil
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
        if not state.enabled then return end
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

    state.activeMonitors[h] = cleanup
    task.spawn(onChanged)
end

local function startManager()
    if state.descendantAddedConn then return end

    for _, desc in ipairs(behaviorFolder:GetDescendants()) do
        if desc:IsA("Highlight") then
            monitorHighlight(desc)
        end
    end

    state.descendantAddedConn = behaviorFolder.DescendantAdded:Connect(function(child)
        if child:IsA("Highlight") then
            monitorHighlight(child)
        end
    end)
end

local function stopManager()
    if state.descendantAddedConn and state.descendantAddedConn.Connected then
        state.descendantAddedConn:Disconnect()
    end
    state.descendantAddedConn = nil

    local cleans = {}
    for h, cleanup in pairs(state.activeMonitors) do
        if type(cleanup) == "function" then
            table.insert(cleans, cleanup)
        end
    end
    for _, fn in ipairs(cleans) do
        pcall(fn)
    end
    state.activeMonitors = {}
end

function module.SetPlatform(platform)
    if platform ~= "PC" and platform ~= "Console" and platform ~= "Mobile" then
        return false
    end
    CONFIG.Platform = platform
    if state.enabled then
        setupControls()
    end
    return true
end

function module.Start()
    if state.enabled then return end
    state.enabled = true
    setupControls()
    startManager()
end

function module.Stop()
    if not state.enabled then return end
    state.enabled = false
    stopManager()
    if CONFIG.Platform == "Console" then
        ContextActionService:UnbindAction(state.sprintBindName)
    end
    if state.pcConnection then
        state.pcConnection:Disconnect()
        state.pcConnection = nil
    end
end

return module