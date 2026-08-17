local KillersModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

if not player then
    function KillersModule.Init() end
    function KillersModule.FollowUp() end
    function KillersModule.Destroy() end
    return KillersModule
end

local UserInputService = game:GetService("UserInputService")

local config = {}
local active = false
local following = false
local target = nil
local stepConn = nil
local keyConn = nil
local btnConn = nil
local btnAncestryConn = nil
local guiConn = nil
local guiDestroyConn = nil
local playerConn = nil
local charConn = nil
local token = 0
local pathParts = {}
local lastName = ""
local bindPending = false
local running = false

local function getAliveRoot(p)
    local char = p.Character
    if not char then
        return nil
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if hum and root and hum.Health > 0 then
        return root
    end

    return nil
end

local function getClosest()
    local root = getAliveRoot(player)
    if not root then
        return nil
    end

    local closest = nil
    local minDist = math.huge
    local maxDist = config.MaxDistance or 100

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local pRoot = getAliveRoot(p)
            if pRoot then
                local dist = (root.Position - pRoot.Position).Magnitude
                if dist < minDist and dist <= maxDist then
                    minDist = dist
                    closest = p
                end
            end
        end
    end

    return closest
end

local function stopFollow()
    token += 1
    following = false
    target = nil

    if stepConn then
        stepConn:Disconnect()
        stepConn = nil
    end
end

local function rotate()
    if not following or not target then
        return
    end

    local root = getAliveRoot(player)
    local tRoot = getAliveRoot(target)

    if not root or not tRoot then
        stopFollow()
        return
    end

    local delta = tRoot.Position - root.Position
    delta = Vector3.new(delta.X, 0, delta.Z)

    if delta.Magnitude < 0.1 then
        return
    end

    root.CFrame = CFrame.lookAt(root.Position, root.Position + delta.Unit)
end

local function startFollow()
    if not active then
        return
    end

    if following then
        stopFollow()
    end

    target = getClosest()
    if not target then
        return
    end

    following = true
    token += 1
    local current = token

    if stepConn then
        stepConn:Disconnect()
    end

    stepConn = RunService.Stepped:Connect(rotate)

    task.delay(config.FollowUpTime or 10, function()
        if current == token and following then
            stopFollow()
        end
    end)
end

local function splitPath(path)
    local parts = {}
    for name in string.gmatch(path, "[^%.]+") do
        table.insert(parts, name)
    end
    return parts
end

local function toPathParts(value)
    if type(value) == "table" then
        local parts = {}
        for _, name in ipairs(value) do
            table.insert(parts, tostring(name))
        end
        return parts
    end

    return splitPath(tostring(value))
end

local function resolveButton(gui)
    local current = gui

    for _, name in ipairs(pathParts) do
        current = current and current:FindFirstChild(name)
        if not current then
            return nil
        end
    end

    if current and current:IsA("GuiButton") then
        return current
    end

    return nil
end

local function unbindButton()
    if btnConn then
        btnConn:Disconnect()
        btnConn = nil
    end

    if btnAncestryConn then
        btnAncestryConn:Disconnect()
        btnAncestryConn = nil
    end
end

local bindButton

local function requestBind()
    if bindPending or not running then
        return
    end

    bindPending = true

    task.defer(function()
        bindPending = false
        if running then
            bindButton()
        end
    end)
end

bindButton = function()
    unbindButton()

    if not running then
        return
    end

    local gui = player:FindFirstChildOfClass("PlayerGui")
    if not gui then
        return
    end

    local button = resolveButton(gui)
    if not button then
        return
    end

    btnConn = button.MouseButton1Click:Connect(function()
        if active then
            startFollow()
        end
    end)

    btnAncestryConn = button.AncestryChanged:Connect(function()
        unbindButton()
        requestBind()
    end)
end

local function attachGui(gui)
    if guiConn then
        guiConn:Disconnect()
        guiConn = nil
    end

    if guiDestroyConn then
        guiDestroyConn:Disconnect()
        guiDestroyConn = nil
    end

    guiConn = gui.DescendantAdded:Connect(function(child)
        if child.Name == lastName then
            requestBind()
        end
    end)

    guiDestroyConn = gui.Destroying:Connect(function()
        if guiConn then
            guiConn:Disconnect()
            guiConn = nil
        end

        if guiDestroyConn then
            guiDestroyConn:Disconnect()
            guiDestroyConn = nil
        end

        unbindButton()
    end)

    bindButton()
end

local function watchPlayerGui()
    if playerConn then
        playerConn:Disconnect()
        playerConn = nil
    end

    playerConn = player.ChildAdded:Connect(function(child)
        if child:IsA("PlayerGui") then
            attachGui(child)
        end
    end)

    local gui = player:FindFirstChildOfClass("PlayerGui")
    if gui then
        attachGui(gui)
    end
end

function KillersModule.Init(cfg)
    if type(cfg) ~= "table" then
        error("Config required")
    end

    running = true
    active = false

    stopFollow()
    unbindButton()

    if keyConn then
        keyConn:Disconnect()
        keyConn = nil
    end

    if guiConn then
        guiConn:Disconnect()
        guiConn = nil
    end

    if guiDestroyConn then
        guiDestroyConn:Disconnect()
        guiDestroyConn = nil
    end

    if playerConn then
        playerConn:Disconnect()
        playerConn = nil
    end

    if charConn then
        charConn:Disconnect()
        charConn = nil
    end

    config = {
        FollowUpTime = math.max(0, tonumber(cfg.FollowUpTime) or 10),
        FollowUpKey = cfg.FollowUpKey or Enum.KeyCode.G,
        MaxDistance = math.max(0, tonumber(cfg.MaxDistance) or 100),
        ButtonPath = cfg.ButtonPath or "MainUI.AbilityContainer.Slash"
    }

    pathParts = toPathParts(config.ButtonPath)
    lastName = pathParts[#pathParts] or ""

    keyConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.KeyCode == config.FollowUpKey then
            startFollow()
        end
    end)

    charConn = player.CharacterAdded:Connect(function()
        stopFollow()
    end)

    watchPlayerGui()
end

function KillersModule.FollowUp(state)
    if type(state) ~= "boolean" then
        error("State required")
    end

    active = state

    if not state then
        stopFollow()
    end
end

function KillersModule.Destroy()
    running = false
    active = false

    stopFollow()
    unbindButton()

    if keyConn then
        keyConn:Disconnect()
        keyConn = nil
    end

    if guiConn then
        guiConn:Disconnect()
        guiConn = nil
    end

    if guiDestroyConn then
        guiDestroyConn:Disconnect()
        guiDestroyConn = nil
    end

    if playerConn then
        playerConn:Disconnect()
        playerConn = nil
    end

    if charConn then
        charConn:Disconnect()
        charConn = nil
    end

    config = {}
    pathParts = {}
    lastName = ""
    target = nil
end

return KillersModule