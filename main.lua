local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/icons.lua"))() or {}

local Theme = {
    Background = Color3.fromRGB(0, 0, 0),
    Surface = Color3.fromRGB(7, 7, 7),
    Card = Color3.fromRGB(15, 15, 15),
    CardHover = Color3.fromRGB(20, 20, 20),
    Border = Color3.fromRGB(25, 25, 25),
    BorderHover = Color3.fromRGB(56, 56, 56),
    Accent = Color3.fromRGB(192, 192, 192),
    Success = Color3.fromRGB(34, 197, 94),
    Warning = Color3.fromRGB(245, 158, 11),
    Error = Color3.fromRGB(239, 68, 68),
    TextPrimary = Color3.fromRGB(237, 237, 237),
    TextSecondary = Color3.fromRGB(128, 128, 128),
    TextDisabled = Color3.fromRGB(46, 46, 46),
    SidebarActive = Color3.fromRGB(10, 10, 10),
    TopBar = Color3.fromRGB(5, 5, 5),
    Sidebar = Color3.fromRGB(3, 3, 3),
    BrandLo = Color3.fromRGB(85, 85, 85),
    BrandMid = Color3.fromRGB(192, 192, 192),
    BrandHi = Color3.fromRGB(242, 242, 242),
    FloatingBg = Color3.fromRGB(5, 5, 5),
    FloatingBorder = Color3.fromRGB(30, 30, 30),
    LogDefault = Color3.fromRGB(180, 180, 180),
    LogRemote = Color3.fromRGB(100, 180, 255),
    LogInvoke = Color3.fromRGB(255, 180, 100),
    LogEvent = Color3.fromRGB(100, 255, 150),
    LogWarning = Color3.fromRGB(255, 200, 80),
    LogError = Color3.fromRGB(255, 80, 80),
    LogSuccess = Color3.fromRGB(80, 255, 120),
    LogInfo = Color3.fromRGB(100, 180, 255),
}

local CompRegistry = setmetatable({}, { __mode = "k" })

local TOP_BAR_H = 44
local CARD_H = 44
local SIDEBAR_W = 160
local PAD_SM = 12
local PAD_MD = 14
local CORNER_R = 12
local BTN_H = 28

local APTX = {}
APTX.__index = APTX

APTX.Sections = {}
APTX.CurrentSection = nil
APTX.DevMode = false
APTX.Title = "APTX"
APTX.Draggable = true
APTX.GUI = nil
APTX.MainFrame = nil
APTX.Shadow1 = nil
APTX.Shadow2 = nil
APTX.Shadow3 = nil
APTX.HideButton = nil
APTX.IsVisible = true
APTX._connections = {}
APTX._scale = 1
APTX._sectionHideDelays = {}
APTX._lastVisiblePos = nil
APTX._floatingFrames = {}
APTX._notifStack = {}
APTX._keybindings = {}
APTX._dialogStack = {}

local REF_W = 1920
local REF_H = 1080

local TI_HOVER = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_FAST = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BACK = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_SLOW = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function log(...)
    if APTX.DevMode then
        print("[APTX]", ...)
    end
end

local function makeNilProxy(tag)
    local proxy = {}
    local mt = {
        __index = function(_, key)
            return function(...)
                if APTX.DevMode then
                    warn("[APTX] Called '" .. tostring(key) .. "' on a failed component (" .. tostring(tag) .. "). Check earlier warnings.")
                end
            end
        end,
        __newindex = function() end,
    }
    setmetatable(proxy, mt)
    return proxy
end

local function tw(obj, props, info)
    local t = TweenService:Create(obj, info or TI_MED, props)
    t:Play()
    return t
end

local function newC(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = parent
    return c
end

local function newS(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function newF(props, parent)
    local f = Instance.new("Frame")
    for k, v in pairs(props) do f[k] = v end
    if parent then f.Parent = parent end
    return f
end

local function newL(props, parent)
    local l = Instance.new("TextLabel")
    for k, v in pairs(props) do l[k] = v end
    if parent then l.Parent = parent end
    return l
end

local function newB(props, parent)
    local b = Instance.new("TextButton")
    for k, v in pairs(props) do b[k] = v end
    if parent then b.Parent = parent end
    return b
end

local function newI(iconName, size, parent)
    local img = Instance.new("ImageLabel")
    img.Name = "Icon"
    img.Size = UDim2.new(0, size or 16, 0, size or 16)
    img.BackgroundTransparency = 1
    img.ImageColor3 = Theme.TextPrimary
    img.Image = Icons[iconName] or ""
    img.Parent = parent
    return img
end

local function makeShadow(w, h, scale, trans)
    local sw = w + scale * 8
    local sh = h + scale * 8
    local ox = -(sw - w) / 2
    local oy = -(sh - h) / 2
    return newF({
        Name = "Shadow",
        Size = UDim2.new(0, sw, 0, sh),
        Position = UDim2.new(0.5, ox, 0.5, oy),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = trans,
        BorderSizePixel = 0,
        ZIndex = 0,
    })
end

local function makeOverlay(parent)
    local o = newF({
        Name = "_DisabledOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, parent)
    newC(o, 10)
    return o
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragInput, dragStart, startPos
    local c1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    local c2 = handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    local c3 = handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    local c4 = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    return {c1, c2, c3, c4}
end

local function connectClick(frame, fn)
    local conns = {}
    local touchStart = nil

    local c1 = frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fn()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            touchStart = input.Position
        end
    end)
    table.insert(conns, c1)

    local c2 = frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and touchStart then
            local delta = input.Position - touchStart
            if math.abs(delta.X) < 10 and math.abs(delta.Y) < 10 then
                fn()
            end
            touchStart = nil
        end
    end)
    table.insert(conns, c2)

    return conns
end

local function makeCard(parent)
    local c = newF({
        Name = "Card",
        Size = UDim2.new(1, 0, 0, CARD_H),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Active = true,
    }, parent)
    newC(c, 10)
    local borderStroke = newS(c, Theme.Border, 1)

    do
        local ih = Instance.new("UIStroke")
        ih.Color = Theme.BrandLo
        ih.Thickness = 1
        ih.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        ih.Transparency = 0.85
        ih.Parent = c
    end

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.Parent = c

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, PAD_SM)
    pad.PaddingRight = UDim.new(0, PAD_SM)
    pad.PaddingTop = UDim.new(0, 0)
    pad.PaddingBottom = UDim.new(0, 0)
    pad.Parent = c

    return c, borderStroke, layout
end

local function initHover(comp, card, stroke)
    local c1 = card.MouseEnter:Connect(function()
        if comp._disabled then return end
        tw(card, {BackgroundColor3 = Theme.CardHover}, TI_HOVER)
        if stroke then tw(stroke, {Color = Theme.BorderHover}, TI_HOVER) end
    end)
    local c2 = card.MouseLeave:Connect(function()
        if comp._disabled then return end
        tw(card, {BackgroundColor3 = Theme.Card}, TI_HOVER)
        if stroke then tw(stroke, {Color = Theme.Border}, TI_HOVER) end
    end)
    table.insert(comp._connections, c1)
    table.insert(comp._connections, c2)
end

local function initResponsive()
    if not APTX.GUI then return end
    local existing = APTX.GUI:FindFirstChildOfClass("UIScale")
    if existing then existing:Destroy() end

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "APTXScale"
    uiScale.Parent = APTX.GUI

    local function updateScale()
        if not APTX.GUI then return end
        local screenSize = APTX.GUI.AbsoluteSize
        local isMobile = screenSize.X < 768
        local scale
        if isMobile then
            scale = screenSize.X / 580
            local heightScale = screenSize.Y / 400
            scale = math.min(scale, heightScale)
            scale = math.max(scale, 0.8)
        else
            scale = math.min(screenSize.X / REF_W, screenSize.Y / REF_H)
        end
        scale = clamp(scale, 0.8, 2.5)
        APTX._scale = scale
        uiScale.Scale = scale
    end

    local sizeConn = APTX.GUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
    table.insert(APTX._connections, sizeConn)
    updateScale()
end

function APTX:Config(title, draggable, devmode)
    APTX.Title = title or "APTX GUI"
    APTX.Draggable = draggable ~= false
    APTX.DevMode = devmode == true
    log("Inicializando APTX GUI...")
    APTX:CreateGUI()
    APTX:CreateHideButton()
    APTX:InitKeybindSystem()
    log("GUI creado exitosamente")
    return APTX
end

function APTX:CreateGUI()
    for _, conn in ipairs(APTX._connections) do
        conn:Disconnect()
    end
    APTX._connections = {}

    if APTX.Shadow1 then APTX.Shadow1:Destroy(); APTX.Shadow1 = nil end
    if APTX.Shadow2 then APTX.Shadow2:Destroy(); APTX.Shadow2 = nil end
    if APTX.Shadow3 then APTX.Shadow3:Destroy(); APTX.Shadow3 = nil end

    local player = Players.LocalPlayer
    if not player then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        player = Players.LocalPlayer
    end
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("APTXGui") then
        playerGui.APTXGui:Destroy()
    end

    APTX.GUI = Instance.new("ScreenGui")
    APTX.GUI.Name = "APTXGui"
    APTX.GUI.ResetOnSpawn = false
    APTX.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    APTX.GUI.Parent = playerGui

    initResponsive()

    local isMobile = APTX.GUI.AbsoluteSize.X < 768
    local mfW = isMobile and math.min(580, APTX.GUI.AbsoluteSize.X - 16) or 580
    local mfH = isMobile and math.min(400, APTX.GUI.AbsoluteSize.Y - 16) or 400

    APTX.MainFrame = newF({
        Name = "MainFrame",
        Size = UDim2.new(0, mfW, 0, mfH),
        Position = UDim2.new(0.5, -mfW/2, 0.5, -mfH/2),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
    }, APTX.GUI)
    newC(APTX.MainFrame, 12)
    newS(APTX.MainFrame, Theme.Border, 1)

    local ambientGlow = newF({
        Name = "AmbientGlow",
        Size = UDim2.new(1, 0, 0, 200),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(192, 192, 192),
        BackgroundTransparency = 0.97,
        BorderSizePixel = 0,
    }, APTX.MainFrame)

    local function syncShadow(s)
        s.Position = UDim2.new(0.5, APTX.MainFrame.Position.X.Offset - (s.Size.X.Offset - mfW) / 2, 0.5, APTX.MainFrame.Position.Y.Offset - (s.Size.Y.Offset - mfH) / 2)
    end

    local s1 = makeShadow(mfW, mfH, 1, 0.82)
    newC(s1, 14)
    s1.Parent = APTX.GUI
    syncShadow(s1)
    local s2 = makeShadow(mfW, mfH, 2, 0.90)
    newC(s2, 16)
    s2.Parent = APTX.GUI
    syncShadow(s2)
    local s3 = makeShadow(mfW, mfH, 3, 0.95)
    newC(s3, 18)
    s3.Parent = APTX.GUI
    syncShadow(s3)
    APTX.Shadow1 = s1
    APTX.Shadow2 = s2
    APTX.Shadow3 = s3

    for _, s in ipairs({s1, s2, s3}) do
        local sync = APTX.MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
            syncShadow(s)
        end)
        table.insert(APTX._connections, sync)
    end

    APTX:CreateTopBar()

    local container = newF({
        Name = "Container",
        Size = UDim2.new(1, 0, 1, -TOP_BAR_H),
        Position = UDim2.new(0, 0, 0, TOP_BAR_H),
        BackgroundTransparency = 1,
    }, APTX.MainFrame)

    APTX:CreateSidebar(container)
    APTX:CreateContentArea(container)

    if APTX.Draggable then
        local dragConns = makeDraggable(APTX.TopBar, APTX.MainFrame)
        for _, conn in ipairs(dragConns) do
            table.insert(APTX._connections, conn)
        end
    end
end

function APTX:CreateTopBar()
    local topBar = newF({
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, TOP_BAR_H),
        BackgroundColor3 = Theme.TopBar,
        BorderSizePixel = 0,
    }, APTX.MainFrame)
    newC(topBar, CORNER_R)
    local clip = newF({
        Size = UDim2.new(1, 0, 0, PAD_SM),
        Position = UDim2.new(0, 0, 1, -PAD_SM),
        BackgroundColor3 = Theme.TopBar,
        BorderSizePixel = 0,
    }, topBar)
    newS(topBar, Theme.Border, 1)

    local titleContainer = newF({
        Size = UDim2.new(0, 240, 1, 0),
        Position = UDim2.new(0, PAD_SM, 0, 0),
        BackgroundTransparency = 1,
    }, topBar)

    local title = newL({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = APTX.Title,
        TextColor3 = Theme.BrandMid,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleContainer)

    local subtitle = newL({
        Name = "Subtitle",
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = "// XERION DESIGN",
        TextColor3 = Theme.BrandLo,
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleContainer)

    local btnFrame = newF({
        Name = "WindowControls",
        Size = UDim2.new(0, 96, 0, BTN_H),
        Position = UDim2.new(1, -108, 0.5, -BTN_H/2),
        BackgroundTransparency = 1,
    }, topBar)
    do
        local bl = Instance.new("UIListLayout")
        bl.FillDirection = Enum.FillDirection.Horizontal
        bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
        bl.VerticalAlignment = Enum.VerticalAlignment.Center
        bl.Padding = UDim.new(0, 4)
        bl.Parent = btnFrame
    end

    local minBtn = newB({
        Name = "MinBtn",
        Size = UDim2.new(0, BTN_H, 0, BTN_H),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(minBtn, 14)
    local minIcon = newI("minimize", 14, minBtn)
    minIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    minIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    minIcon.ImageColor3 = Color3.fromRGB(80, 80, 80)
    minBtn.MouseEnter:Connect(function()
        tw(minBtn, {BackgroundColor3 = Theme.Warning}, TI_HOVER)
        tw(minIcon, {ImageColor3 = Color3.new(1,1,1)}, TI_HOVER)
    end)
    minBtn.MouseLeave:Connect(function()
        tw(minBtn, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, TI_HOVER)
        tw(minIcon, {ImageColor3 = Color3.fromRGB(80, 80, 80)}, TI_HOVER)
    end)
    minBtn.MouseButton1Click:Connect(function()
        APTX:ToggleVisibility()
    end)

    local maxBtn = newB({
        Name = "MaxBtn",
        Size = UDim2.new(0, BTN_H, 0, BTN_H),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(maxBtn, 14)
    local maxIcon = newI("maximize", 14, maxBtn)
    maxIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    maxIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    maxIcon.ImageColor3 = Color3.fromRGB(80, 80, 80)

    local isMaximized = false
    local originalSize = APTX.MainFrame.Size
    local originalPosition = APTX.MainFrame.Position

    local function toggleMaximize()
        isMaximized = not isMaximized
        if isMaximized then
            originalSize = APTX.MainFrame.Size
            originalPosition = APTX.MainFrame.Position
            APTX.MainFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
            APTX.MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            APTX.MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        else
            APTX.MainFrame.Size = originalSize
            APTX.MainFrame.Position = originalPosition
            APTX.MainFrame.AnchorPoint = Vector2.new(0, 0)
        end
    end

    maxBtn.MouseEnter:Connect(function()
        tw(maxBtn, {BackgroundColor3 = Theme.Success}, TI_HOVER)
        tw(maxIcon, {ImageColor3 = Color3.new(1,1,1)}, TI_HOVER)
    end)
    maxBtn.MouseLeave:Connect(function()
        tw(maxBtn, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, TI_HOVER)
        tw(maxIcon, {ImageColor3 = Color3.fromRGB(80, 80, 80)}, TI_HOVER)
    end)
    maxBtn.MouseButton1Click:Connect(toggleMaximize)

    local closeBtn = newB({
        Name = "CloseBtn",
        Size = UDim2.new(0, BTN_H, 0, BTN_H),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(closeBtn, 14)
    local closeIcon = newI("x", 14, closeBtn)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIcon.ImageColor3 = Color3.fromRGB(80, 80, 80)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, {BackgroundColor3 = Theme.Error}, TI_HOVER)
        tw(closeIcon, {ImageColor3 = Color3.new(1,1,1)}, TI_HOVER)
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, TI_HOVER)
        tw(closeIcon, {ImageColor3 = Color3.fromRGB(80, 80, 80)}, TI_HOVER)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        APTX:ToggleVisibility()
    end)

    APTX.TopBar = topBar
end

function APTX:CreateSidebar(parent)
    local sidebar = newF({
        Name = "Sidebar",
        Size = UDim2.new(0, SIDEBAR_W, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
    }, parent)
    newC(sidebar, CORNER_R)
    local rightBorder = newF({
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
    }, sidebar)

    local sectionList = newF({
        Name = "SectionList",
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, sidebar)
    sectionList.ClipsDescendants = true

    local scrolling = Instance.new("ScrollingFrame")
    scrolling.Size = UDim2.new(1, 0, 1, 0)
    scrolling.BackgroundTransparency = 1
    scrolling.BorderSizePixel = 0
    scrolling.ScrollBarThickness = 4
    scrolling.ScrollBarImageColor3 = Theme.BrandLo
    scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrolling.ScrollBarImageTransparency = 0.6
    scrolling.ScrollingEnabled = true
    scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrolling.Parent = sectionList

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scrolling

    local layoutConn = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrolling.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)
    table.insert(APTX._connections, layoutConn)

    APTX.SectionList = scrolling
end

function APTX:CreateContentArea(parent)
    local content = newF({
        Name = "ContentArea",
        Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
        Position = UDim2.new(0, SIDEBAR_W, 0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    newC(content, CORNER_R)
    APTX.ContentArea = content
end

function APTX:CreateHideButton()
    local hideBtn = newB({
        Name = "HideButton",
        Size = UDim2.new(0, 44, 0, 44),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        ZIndex = 50,
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, APTX.GUI)
    
    local inverseScale = Instance.new("UIScale")
    inverseScale.Name = "InverseScale"
    inverseScale.Parent = hideBtn
    
    local function updateInverseScale()
        if APTX._scale and APTX._scale ~= 0 then
            inverseScale.Scale = 1 / APTX._scale
        end
    end
    
    local scaleConn = APTX.GUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateInverseScale)
    table.insert(APTX._connections, scaleConn)
    
    updateInverseScale()
    
    local hideIcon = newI("chevron-up", 26, hideBtn)
    hideIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    hideIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    hideIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)

    hideBtn.MouseEnter:Connect(function()
        tw(hideIcon, {ImageColor3 = Theme.BrandHi}, TI_HOVER)
    end)
    hideBtn.MouseLeave:Connect(function()
        tw(hideIcon, {ImageColor3 = Color3.fromRGB(200, 200, 200)}, TI_HOVER)
    end)
    hideBtn.MouseButton1Click:Connect(function()
        APTX:ToggleVisibility()
    end)

    APTX.HideButton = hideBtn
end

function APTX:ToggleVisibility()
    APTX.IsVisible = not APTX.IsVisible

    if APTX.IsVisible then
        local restorePos = APTX._lastVisiblePos or UDim2.new(0.5, -(APTX.MainFrame.Size.X.Offset / 2), 0.5, -(APTX.MainFrame.Size.Y.Offset / 2))
        for _, s in ipairs({APTX.Shadow1, APTX.Shadow2, APTX.Shadow3}) do
            if s then s.Visible = true end
        end
        tw(APTX.MainFrame, {Position = restorePos}, TI_BOUNCE)
    else
        APTX._lastVisiblePos = APTX.MainFrame.Position
        tw(APTX.MainFrame, {Position = UDim2.new(0.5, -(APTX.MainFrame.Size.X.Offset / 2), 1.5, 0)}, TI_BOUNCE)
        task.delay(TI_BOUNCE.Time, function()
            if not APTX.IsVisible then
                for _, s in ipairs({APTX.Shadow1, APTX.Shadow2, APTX.Shadow3}) do
                    if s then s.Visible = false end
                end
            end
        end)
    end

    if APTX.HideButton then
        local icon = APTX.HideButton:FindFirstChild("Icon")
        if icon then
            icon.Image = Icons[APTX.IsVisible and "chevron-up" or "chevron-down"] or ""
        end
    end
end

function APTX:Destroy()
    for _, section in ipairs(APTX.Sections) do
        if section._compRef and section._compRef._connections then
            for _, conn in ipairs(section._compRef._connections) do
                conn:Disconnect()
            end
            section._compRef._connections = {}
        end
        if section.Container then
            for _, child in ipairs(section.Container:GetChildren()) do
                local childComp = CompRegistry[child]
                if childComp and childComp._connections then
                    for _, conn in ipairs(childComp._connections) do
                        conn:Disconnect()
                    end
                    childComp._connections = {}
                end
                CompRegistry[child] = nil
            end
        end
    end

    for _, conn in ipairs(APTX._connections) do
        conn:Disconnect()
    end
    APTX._connections = {}

    for _, threadId in pairs(APTX._sectionHideDelays) do
        pcall(task.cancel, threadId)
    end
    APTX._sectionHideDelays = {}

    for _, ff in ipairs(APTX._floatingFrames) do
        pcall(function() ff:Destroy() end)
    end
    APTX._floatingFrames = {}

    APTX._notifStack = {}
    APTX._keybindings = {}

    APTX.Sections = {}
    APTX.CurrentSection = nil
    if APTX.GUI then
        APTX.GUI:Destroy()
        APTX.GUI = nil
    end
end

local function initComponent(comp, frame, sectionRef)
    comp._frame = frame
    comp._disabled = false
    comp._overlay = nil
    comp._section = sectionRef
    comp._connections = {}
    comp._tooltipObj = nil
    comp._tooltipCons = nil
    comp._tweens = {}
    CompRegistry[frame] = comp

    function comp:Remove()
        if self._tooltipObj then
            self._tooltipObj:Destroy()
            self._tooltipObj = nil
        end
        if self._tooltipCons then
            for _, conn in ipairs(self._tooltipCons) do
                conn:Disconnect()
            end
            self._tooltipCons = nil
        end
        if self._tweens then
            for _, t in ipairs(self._tweens) do
                t:Cancel()
            end
            self._tweens = {}
        end
        for _, conn in ipairs(self._connections) do
            conn:Disconnect()
        end
        self._connections = {}
        CompRegistry[self._frame] = nil
        if self._frame and self._frame.Parent then
            self._frame:Destroy()
            self._frame = nil
        end
    end

    function comp:Disable()
        if self._disabled then return end
        self._disabled = true
        if self._frame then
            self._overlay = makeOverlay(self._frame)
            if self._frame:IsA("ScrollingFrame") then
                self._frame.ScrollingEnabled = false
            end
        end
    end

    function comp:Enable()
        if not self._disabled then return end
        self._disabled = false
        if self._overlay then
            self._overlay:Destroy()
            self._overlay = nil
            if self._frame:IsA("ScrollingFrame") then
                self._frame.ScrollingEnabled = true
            end
        end
    end

    function comp:IsDisabled()
        return self._disabled
    end

    function comp:MoveTo(targetSectionName)
        local targetSection = APTX:GetSection(targetSectionName)
        if not targetSection then
            log("ERROR: Section not found:", targetSectionName)
            return
        end
        if self._frame then
            self._frame.Parent = targetSection.Container
            self._section = targetSection
        end
    end

    function comp:DisconnectAll()
        if self._tooltipCons then
            for _, conn in ipairs(self._tooltipCons) do
                conn:Disconnect()
            end
            self._tooltipCons = nil
        end
        if self._tweens then
            for _, t in ipairs(self._tweens) do
                t:Cancel()
            end
            self._tweens = {}
        end
        for _, conn in ipairs(self._connections) do
            conn:Disconnect()
        end
        self._connections = {}
    end

    function comp:SetTooltip(text, opts)
        if self._tooltipObj then
            self._tooltipObj:Destroy()
            self._tooltipObj = nil
        end
        if self._tooltipCons then
            for _, conn in ipairs(self._tooltipCons) do
                conn:Disconnect()
            end
            self._tooltipCons = nil
        end

        if not text or text == "" or not APTX.GUI then return end

        local opt = opts or {}
        local delay = opt.delay or 0.5
        local maxW = opt.maxWidth or 260
        local offX = opt.offsetX or 0
        local offY = opt.offsetY or 22

        local tip = newF({
            Name = "Tooltip",
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            ZIndex = 9999,
            Visible = false,
        }, APTX.GUI)
        newC(tip, 6)
        local tipStroke = newS(tip, Theme.BorderHover, 1)
        tipStroke.Transparency = 1

        local tipLbl = newL({
            Size = UDim2.new(0, maxW - 12, 0, 0),
            Position = UDim2.new(0, 6, 0, 4),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 9999 + 1,
        }, tip)

        local th = tipLbl.TextBounds.Y + 8
        tip.Size = UDim2.new(0, maxW, 0, math.max(22, th))
        tipLbl.Size = UDim2.new(0, maxW - 12, 0, tipLbl.TextBounds.Y)

        local tipVisible = false
        local showThread = nil

        self._tooltipObj = tip

        local function showTooltip()
            if not tip or not tip.Parent then return end
            if not self._frame or not self._frame.Parent then return end

            tip.Visible = true
            tipVisible = true
            tip.BackgroundTransparency = 1
            tipLbl.TextTransparency = 1

            local absPos = self._frame.AbsolutePosition
            local absSize = self._frame.AbsoluteSize
            local guiSize = APTX.GUI.AbsoluteSize

            local x = absPos.X + offX
            local y = absPos.Y - tip.AbsoluteSize.Y - 6

            local ts = tip.AbsoluteSize
            if x + ts.X > guiSize.X then x = guiSize.X - ts.X - 4 end
            if x < 0 then x = 4 end
            if y < 0 then
                y = absPos.Y + absSize.Y + offY
            end

            tip.Position = UDim2.new(0, x, 0, y)

            tw(tip, {BackgroundTransparency = 0}, TI_HOVER)
            tw(tipLbl, {TextTransparency = 0}, TI_HOVER)
            tw(tipStroke, {Transparency = 0}, TI_HOVER)
        end

        local function hideTooltip()
            tipVisible = false
            if showThread then
                task.cancel(showThread)
                showThread = nil
            end
            if not tip or not tip.Parent then return end
            tw(tip, {BackgroundTransparency = 1}, TI_FAST)
            tw(tipLbl, {TextTransparency = 1}, TI_FAST)
            tw(tipStroke, {Transparency = 1}, TI_FAST)
            task.delay(0.12, function()
                if tip and tip.Parent and not tipVisible then
                    tip.Visible = false
                end
            end)
        end

        local hEnter = self._frame.MouseEnter:Connect(function()
            if self._disabled then return end
            if showThread then task.cancel(showThread); showThread = nil end
            showThread = task.delay(delay, function()
                if not self._disabled then showTooltip() end
            end)
        end)

        local hLeave = self._frame.MouseLeave:Connect(function()
            hideTooltip()
        end)

        self._tooltipCons = {hEnter, hLeave}
    end

    return comp
end

local TI_ENTRY_FADE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function animEntry(container)
    if not container then return end
    local cards = {}
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding")
            and not child:IsA("UIGridLayout") and child.Name ~= "_EmptyPlaceholder" then
            table.insert(cards, child)
        end
    end
    for idx, card in ipairs(cards) do
        local stagger = (idx - 1) * 0.04

        if card:IsA("TextLabel") then
            card.TextTransparency = 1
            task.delay(stagger, function()
                local ok, err = pcall(function()
                    if not card or not card.Parent or card.Parent ~= container then return end
                    tw(card, {TextTransparency = 0}, TI_ENTRY_FADE)
                end)
                if not ok and APTX.DevMode then warn("[APTX] animEntry error:", err) end
            end)

        elseif card:IsA("Frame") then
            local origBGT = card.BackgroundTransparency
            card.BackgroundTransparency = 1
            task.delay(stagger, function()
                local ok, err = pcall(function()
                    if not card or not card.Parent or card.Parent ~= container then return end
                    tw(card, {BackgroundTransparency = origBGT}, TI_ENTRY_FADE)

                    for _, child in ipairs(card:GetChildren()) do
                        if child:IsA("TextLabel") then
                            child.TextTransparency = 1
                            tw(child, {TextTransparency = 0}, TI_ENTRY_FADE)

                        elseif child:IsA("TextButton") then
                            child.TextTransparency = 1
                            tw(child, {TextTransparency = 0}, TI_ENTRY_FADE)
                            if child.BackgroundTransparency < 0.9 then
                                local origT = child.BackgroundTransparency
                                child.BackgroundTransparency = 1
                                tw(child, {BackgroundTransparency = origT}, TI_ENTRY_FADE)
                            end

                        elseif child:IsA("ImageLabel") then
                            child.ImageTransparency = 1
                            tw(child, {ImageTransparency = 0}, TI_ENTRY_FADE)

                        elseif child:IsA("UIStroke") then
                            local origT = child.Transparency
                            child.Transparency = 1
                            tw(child, {Transparency = origT}, TI_ENTRY_FADE)

                        elseif child:IsA("Frame") and child.Name ~= "Icon"
                            and child.Name ~= "_DisabledOverlay" then
                            if child.BackgroundTransparency < 0.9 then
                                local origT = child.BackgroundTransparency
                                child.BackgroundTransparency = 1
                                tw(child, {BackgroundTransparency = origT}, TI_ENTRY_FADE)
                            end
                        end
                    end
                end)
                if not ok and APTX.DevMode then warn("[APTX] animEntry error:", err) end
            end)

        else
            card.Visible = true
        end
    end
end

function APTX:Section(text, icon, default)
    local ok, result = pcall(function()
        local section = {
            Name = text,
            Icon = icon,
            Container = nil,
            Button = nil,
            _compRef = nil,
            _entered = false,
        }

        section.Button = newB({
            Name = text,
            Size = UDim2.new(1, -4, 0, 38),
            Position = UDim2.new(0, 2, 0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
        }, APTX.SectionList)
        newC(section.Button, 8)

        local accentBar = newF({
            Name = "AccentBar",
            Size = UDim2.new(0, 3, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, section.Button)

        local row = newF({
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
        }, section.Button)

        local iconLabel
        if icon then
            iconLabel = newI(icon, 16, row)
            iconLabel.Position = UDim2.new(0, 0, 0.5, -8)
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, icon and -24 or 0, 1, 0),
            Position = UDim2.new(0, icon and 24 or 0, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextSecondary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)

        section.Container = Instance.new("ScrollingFrame")
        section.Container.Name = text .. "_Container"
        section.Container.Size = UDim2.new(1, 0, 1, 0)
        section.Container.BackgroundTransparency = 1
        section.Container.BorderSizePixel = 0
        section.Container.ScrollBarThickness = 4
        section.Container.ScrollBarImageColor3 = Theme.Border
        section.Container.ScrollBarImageTransparency = 0.5
        section.Container.ScrollingEnabled = true
        section.Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        section.Container.Visible = false
        section.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
        section.Container.Parent = APTX.ContentArea

        local compLayout = Instance.new("UIListLayout")
        compLayout.SortOrder = Enum.SortOrder.LayoutOrder
        compLayout.Padding = UDim.new(0, 6)
        compLayout.Parent = section.Container

        local sectionPad = Instance.new("UIPadding")
        sectionPad.PaddingTop = UDim.new(0, 6)
        sectionPad.PaddingBottom = UDim.new(0, 8)
        sectionPad.Parent = section.Container

        local emptyLabel = newL({
            Name = "_EmptyPlaceholder",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            Text = "No hay elementos en esta seccion.",
            TextColor3 = Theme.TextDisabled,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, section.Container)

        local sectionComp = {}
        initComponent(sectionComp, section.Container, nil)
        section._compRef = sectionComp

        local function syncCanvas()
            local hasContent = false
            for _, child in ipairs(section.Container:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding")
                    and not child:IsA("UIGridLayout") and child.Name ~= "_EmptyPlaceholder" then
                    hasContent = true
                    break
                end
            end
            emptyLabel.Visible = not hasContent
            section.Container.CanvasSize = UDim2.new(0, 0, 0, compLayout.AbsoluteContentSize.Y + 14)
        end

        local layoutConn = compLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
        table.insert(sectionComp._connections, layoutConn)

        task.defer(syncCanvas)

        local btnClickConn = section.Button.MouseButton1Click:Connect(function()
            APTX:SelectSection(text)
        end)
        table.insert(sectionComp._connections, btnClickConn)

        local btnEnterConn = section.Button.MouseEnter:Connect(function()
            if APTX.CurrentSection ~= text then
                tw(section.Button, {BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 0.85}, TI_HOVER)
                label.TextColor3 = Theme.TextPrimary
                if iconLabel then iconLabel.ImageColor3 = Theme.TextPrimary end
            end
        end)
        table.insert(sectionComp._connections, btnEnterConn)

        local btnLeaveConn = section.Button.MouseLeave:Connect(function()
            if APTX.CurrentSection ~= text then
                tw(section.Button, {BackgroundTransparency = 1}, TI_HOVER)
                label.TextColor3 = Theme.TextSecondary
                if iconLabel then iconLabel.ImageColor3 = Theme.TextSecondary end
            end
        end)
        table.insert(sectionComp._connections, btnLeaveConn)

        table.insert(APTX.Sections, section)

        if default == true or #APTX.Sections == 1 then
            APTX:SelectSection(text)
        end

        function sectionComp:Remove()
            for _, conn in ipairs(sectionComp._connections) do
                conn:Disconnect()
            end
            sectionComp._connections = {}
            if section.Container then
                for _, child in ipairs(section.Container:GetChildren()) do
                    CompRegistry[child] = nil
                end
                CompRegistry[section.Container] = nil
            end
            if section.Button and section.Button.Parent then
                section.Button:Destroy()
            end
            if section.Container and section.Container.Parent then
                section.Container:Destroy()
            end
            sectionComp._frame = nil
            sectionComp._section = nil
            section._compRef = nil
            for i = #APTX.Sections, 1, -1 do
                if APTX.Sections[i] == section then
                    table.remove(APTX.Sections, i)
                    break
                end
            end
            if APTX.CurrentSection == text then
                APTX.CurrentSection = nil
            end
        end

        function sectionComp:Clear()
            local toRemove = {}
            for _, child in ipairs(section.Container:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UIGridLayout") and child.Name ~= "_EmptyPlaceholder" then
                    table.insert(toRemove, child)
                end
            end
            for _, child in ipairs(toRemove) do
                local childComp = CompRegistry[child]
                if childComp and childComp._connections then
                    for _, conn in ipairs(childComp._connections) do
                        conn:Disconnect()
                    end
                    childComp._connections = {}
                end
                CompRegistry[child] = nil
                child:Destroy()
            end
        end

        return sectionComp
    end)
    if not ok then
        warn("[APTX:Section] Error creando seccion '" .. tostring(text) .. "': " .. tostring(result))
        return nil
    end
    return result
end

function APTX:SelectSection(name)
    for _, section in ipairs(APTX.Sections) do
        if section.Name == name then
            section.Container.Visible = true
            section.Container.CanvasPosition = Vector2.new(0, 0)
            if APTX.SectionList and section.Button then
                local btnAbsY = section.Button.AbsolutePosition.Y
                local scrollAbsY = APTX.SectionList.AbsolutePosition.Y
                local scrollH = APTX.SectionList.AbsoluteSize.Y
                local btnH = section.Button.AbsoluteSize.Y
                if btnAbsY < scrollAbsY or btnAbsY + btnH > scrollAbsY + scrollH then
                    local btnContentY = (btnAbsY - scrollAbsY) + APTX.SectionList.CanvasPosition.Y
                    local newY = math.max(0, btnContentY - scrollH / 2 + btnH / 2)
                    APTX.SectionList.CanvasPosition = Vector2.new(0, newY)
                end
            end
            if not section._entered then
                section._entered = true
                animEntry(section.Container)
            end

            section.Button.BackgroundColor3 = Theme.SidebarActive
            section.Button.BackgroundTransparency = 0
            local bar = section.Button:FindFirstChild("AccentBar")
            if bar then
                tw(bar, {BackgroundTransparency = 0}, TI_MED)
                bar.BackgroundColor3 = Theme.BrandMid
            end
            local iconImg = section.Button:FindFirstChild("Icon", true)
            if iconImg then iconImg.ImageColor3 = Theme.BrandMid end
            local lbl2 = section.Button:FindFirstChild("Label", true)
            if lbl2 then lbl2.TextColor3 = Theme.BrandHi end
            APTX.CurrentSection = name
        else
            section.Container.Visible = false

            section.Button.BackgroundTransparency = 1
            local bar = section.Button:FindFirstChild("AccentBar")
            if bar then
                tw(bar, {BackgroundTransparency = 1}, TI_MED)
                bar.BackgroundColor3 = Theme.Accent
            end
            local iconImg = section.Button:FindFirstChild("Icon", true)
            if iconImg then iconImg.ImageColor3 = Theme.TextSecondary end
            local lbl2 = section.Button:FindFirstChild("Label", true)
            if lbl2 then lbl2.TextColor3 = Theme.TextSecondary end
        end
    end
end

function APTX:GetSection(name)
    for _, section in ipairs(APTX.Sections) do
        if section.Name == name then
            return section
        end
    end
    return nil
end

function APTX:Button(sectionName, text, icon, callback)
    if type(icon) == "function" then
        callback = icon
        icon = nil
    end

    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, CARD_H)

        local iconImg
        if icon then
            iconImg = newI(icon, 16, card)
            iconImg.LayoutOrder = 1
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, 0, 1, 0),
            LayoutOrder = 2,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        initHover(comp, card, stroke)

        comp._tweens = {}

        local clickConns = connectClick(card, function()
            if comp._disabled then return end

            for _, t in ipairs(comp._tweens) do
                t:Cancel()
            end
            comp._tweens = {}

            local ts = TweenService:Create(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.BrandLo})
            ts:Play()
            table.insert(comp._tweens, ts)
            local tsConn = ts.Completed:Connect(function()
                if card and card.Parent then
                    tw(card, {BackgroundColor3 = Theme.Card}, TI_BACK)
                end
            end)
            table.insert(comp._connections, tsConn)

            local pt = TweenService:Create(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 42)})
            pt:Play()
            table.insert(comp._tweens, pt)
            local ptConn = pt.Completed:Connect(function()
                if card and card.Parent then
                    tw(card, {Size = UDim2.new(1, 0, 0, CARD_H)}, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
                end
            end)
            table.insert(comp._connections, ptConn)

            if cb then cb() end
        end)
        for _, c in ipairs(clickConns) do table.insert(comp._connections, c) end

        function comp:Edit(params)
            params = params or {}
            if params.text then
                card.Name = params.text
                label.Text = params.text
            end
            if params.callback then
                cb = params.callback
            end
            if params.loading then
                if params.loading then
                    comp:Disable()
                    label.Text = params.loadingText or "Cargando..."
                else
                    comp:Enable()
                    label.Text = params.text or text
                end
            end
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Button] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Button:" .. tostring(text))
    end
    return result
end

function APTX:Toggle(sectionName, text, icon, default, callback)
    if type(icon) == "function" then
        callback = icon
        icon = nil
    end

    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local isOn = default == true
        local debounce = false

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, CARD_H)

        local iconImg
        if icon then
            iconImg = newI(icon, 16, card)
            iconImg.LayoutOrder = 1
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, -(icon and 16+8 or 0) - 52, 1, 0),
            LayoutOrder = 2,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local track = newB({
            Name = "Track",
            Size = UDim2.new(0, 44, 0, 24),
            Position = UDim2.new(1, -(44 + PAD_SM), 0.5, -12),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 2,
        }, card)
        newC(track, CORNER_R)
        local trackStroke = newS(track, Theme.Border, 1)
        trackStroke.Transparency = 0.5

        local knob = newF({
            Name = "Knob",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 2, 0.5, -10),
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            BorderSizePixel = 0,
        }, track)
        newC(knob, 10)

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        initHover(comp, card, stroke)

        local function setToggleState(state, instant)
            isOn = state
            local kPos = isOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            local tColor = isOn and Color3.fromRGB(192, 192, 192) or Color3.fromRGB(30, 30, 30)
            local kColor = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
            if instant then
                knob.Position = kPos
                track.BackgroundColor3 = tColor
                knob.BackgroundColor3 = kColor
            else
                tw(knob, {Position = kPos}, TI_MED)
                tw(track, {BackgroundColor3 = tColor}, TI_MED)
                tw(knob, {BackgroundColor3 = kColor}, TI_MED)
            end
        end

        if isOn then
            setToggleState(true, true)
        end

        local function toggleAction()
            if comp._disabled then return end
            if debounce then return end
            debounce = true
            setToggleState(not isOn)
            if cb then cb(isOn) end
            task.delay(0.1, function()
                debounce = false
            end)
        end

        track.MouseButton1Click:Connect(toggleAction)

        track.MouseEnter:Connect(function()
            tw(knob, {Size = UDim2.new(0, 22, 0, 22)}, TI_HOVER)
        end)
        track.MouseLeave:Connect(function()
            tw(knob, {Size = UDim2.new(0, 20, 0, 20)}, TI_HOVER)
        end)

        function comp:Edit(params)
            params = params or {}
            if params.text then
                label.Text = params.text
                card.Name = params.text
            end
            if params.value ~= nil then
                setToggleState(params.value)
            end
            if params.callback then cb = params.callback end
        end

        function comp:GetValue()
            return isOn
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Toggle] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Toggle:" .. tostring(text))
    end
    return result
end

function APTX:Slider(sectionName, text, icon, min, max, default, callback)
    if type(icon) == "function" then
        callback = icon
        icon = nil
    end

    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        if max == min then
            max = min + 1
            log("WARNING: Slider min==max, adjusted max to", max)
        end

        local value = default or min
        local step = 1

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, 58)
        layout:Destroy()

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, PAD_SM)
        pad.PaddingRight = UDim.new(0, PAD_SM)
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.Parent = card

        local topRow = newF({
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }, card)

        if icon then
            local ip = newI(icon, 14, topRow)
            ip.ImageColor3 = Theme.TextSecondary
            ip.Position = UDim2.new(0, 0, 0.5, -7)
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, -50, 1, 0),
            Position = UDim2.new(0, icon and 20 or 0, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, topRow)

        local valueLabel = newL({
            Name = "ValueLabel",
            Size = UDim2.new(0, 40, 1, 0),
            Position = UDim2.new(1, -40, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(value),
            TextColor3 = Theme.TextSecondary,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, topRow)

        local trackHitbox = newF({
            Name = "TrackHitbox",
            Size = UDim2.new(1, 0, 0, 44),
            Position = UDim2.new(0, 0, 0, 7),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = true,
        }, card)

        local track = newF({
            Name = "Track",
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 19),
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            BorderSizePixel = 0,
            Active = true,
        }, trackHitbox)
        newC(track, 3)
        local trackBorder = newS(track, Theme.Border, 1)
        trackBorder.Transparency = 0.7

        local fill = newF({
            Name = "Fill",
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = Theme.BrandMid,
            BorderSizePixel = 0,
        }, track)
        newC(fill, 3)

        local knob = newF({
            Name = "Knob",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new((value - min) / (max - min), -9, 0.5, -9),
            BackgroundColor3 = Color3.fromRGB(220, 220, 220),
            BorderSizePixel = 0,
        }, track)
        newC(knob, 9)
        local knobBorder = newS(knob, Color3.fromRGB(255, 255, 255), 1)
        knobBorder.Transparency = 0.6

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        initHover(comp, card, stroke)
        local dragging = false

        local function updateSlider(input)
            if comp._disabled then return end
            if not card or not card.Parent then return end
            local relX = input.Position.X - track.AbsolutePosition.X
            local trackW = track.AbsoluteSize.X
            if trackW <= 0 then return end
            local pos = clamp(relX / trackW, 0, 1)
            local rawValue = min + (max - min) * pos
            if step and step > 0 then
                rawValue = math.round(rawValue / step) * step
            end
            value = clamp(rawValue, min, max)
            valueLabel.Text = tostring(value)
            local newPos = (value - min) / (max - min)
            fill.Size = UDim2.new(newPos, 0, 1, 0)
            knob.Position = UDim2.new(newPos, -9, 0.5, -9)
            if cb then cb(value) end
        end

        local ibConn = trackHitbox.InputBegan:Connect(function(input)
            if comp._disabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input)
                tw(knob, {Size = UDim2.new(0, 22, 0, 22)}, TI_HOVER)
            end
        end)
        table.insert(comp._connections, ibConn)

        local ieConn = UserInputService.InputEnded:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
                tw(knob, {Size = UDim2.new(0, 18, 0, 18)}, TI_HOVER)
            end
        end)
        table.insert(comp._connections, ieConn)

        local uiConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input)
            end
        end)
        table.insert(comp._connections, uiConn)

        function comp:Edit(params)
            params = params or {}
            if params.text then label.Text = params.text end
            if params.step then step = params.step end
            local minChanged = params.min ~= nil
            local maxChanged = params.max ~= nil
            if minChanged then min = params.min end
            if maxChanged then
                max = params.max
                if max == min then max = min + 1 end
            end
            if minChanged or maxChanged then
                value = clamp(value, min, max)
                local pos = (value - min) / (max - min)
                valueLabel.Text = tostring(value)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                knob.Position = UDim2.new(pos, -9, 0.5, -9)
            end
            if params.value ~= nil then
                value = clamp(params.value, min, max)
                local pos = (value - min) / (max - min)
                valueLabel.Text = tostring(value)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                knob.Position = UDim2.new(pos, -9, 0.5, -9)
            end
            if params.callback then cb = params.callback end
        end

        function comp:GetValue()
            return value
        end

        function comp:SetValue(v)
            value = clamp(v, min, max)
            local pos = (value - min) / (max - min)
            valueLabel.Text = tostring(value)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -9, 0.5, -9)
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Slider] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Slider:" .. tostring(text))
    end
    return result
end

function APTX:Menu(sectionName, text, placeholder, icon, options, default, callback)
    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        if not options or #options == 0 then
            options = {"(sin opciones)"}
        end

        local isOpen = false
        local selected = default or options[1]
        local currentOptions = {}
        for _, v in ipairs(options) do table.insert(currentOptions, v) end

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, CARD_H)
        card.ClipsDescendants = true
        layout:Destroy()

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, PAD_SM)
        pad.PaddingRight = UDim.new(0, PAD_SM)
        pad.Parent = card

        local topRow = newF({
            Size = UDim2.new(1, 0, 0, CARD_H),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }, card)

        local iconImg
        if icon then
            iconImg = newI(icon, 16, topRow)
            iconImg.Position = UDim2.new(0, 0, 0.5, -8)
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, -60, 1, 0),
            Position = UDim2.new(0, icon and 22 or 0, 0, 0),
            BackgroundTransparency = 1,
            Text = placeholder or text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, topRow)

        local chevron = newL({
            Name = "Chevron",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -16, 0.5, -8),
            BackgroundTransparency = 1,
            Text = "▾",
            TextColor3 = Theme.TextSecondary,
            Font = Enum.Font.Gotham,
            TextSize = 10,
        }, topRow)

        local dropBtn = newB({
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
        }, topRow)

        local optionsList = newF({
            Name = "OptionsList",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, CARD_H),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, card)

        local optLayout = Instance.new("UIListLayout")
        optLayout.SortOrder = Enum.SortOrder.LayoutOrder
        optLayout.Padding = UDim.new(0, 1)
        optLayout.Parent = optionsList

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        local optionBtns = {}
        local function closeOutside(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if isOpen then
                    local pos = input.Position
                    local absPos = card.AbsolutePosition
                    local absSize = card.AbsoluteSize
                    local expandedH = absSize.Y + 10
                    if pos.X < absPos.X or pos.X > absPos.X + absSize.X
                        or pos.Y < absPos.Y or pos.Y > absPos.Y + expandedH then
                        isOpen = false
                        tw(card, {Size = UDim2.new(1, 0, 0, CARD_H)}, TI_MED)
                        tw(optionsList, {Size = UDim2.new(1, 0, 0, 0)}, TI_MED)
                        tw(chevron, {Rotation = 0}, TI_MED)
                    end
                end
            end
        end

        local function rebuildOptions()
            for _, btn in ipairs(optionBtns) do
                btn:Destroy()
            end
            optionBtns = {}

            for _, opt in ipairs(currentOptions) do
                local ob = newB({
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                }, optionsList)

                local optLabel = newL({
                    Size = UDim2.new(1, -36, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = opt,
                    TextColor3 = opt == selected and Theme.BrandMid or Theme.TextSecondary,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, ob)

                local checkmark = newL({
                    Name = "Checkmark",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(1, -24, 0.5, -8),
                    BackgroundTransparency = 1,
                    Text = opt == selected and "✓" or "",
                    TextColor3 = Theme.BrandMid,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                }, ob)

                ob.MouseEnter:Connect(function()
                    tw(ob, {BackgroundColor3 = Color3.fromRGB(32, 32, 32), BackgroundTransparency = 0.85}, TI_HOVER)
                end)
                ob.MouseLeave:Connect(function()
                    tw(ob, {BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1}, TI_HOVER)
                end)
                ob.MouseButton1Click:Connect(function()
                    if comp._disabled then return end
                    selected = opt
                    label.Text = selected
                    if cb then cb(selected) end
                    for _, btn in ipairs(optionBtns) do
                        local ol = btn:FindFirstChildOfClass("TextLabel")
                        local cm = btn:FindFirstChild("Checkmark")
                        if ol then ol.TextColor3 = Theme.TextSecondary end
                        if cm then cm.Text = "" end
                    end
                    local ol = ob:FindFirstChildOfClass("TextLabel")
                    local cm = ob:FindFirstChild("Checkmark")
                    if ol then ol.TextColor3 = Theme.Accent end
                    if cm then cm.Text = "✓" end
                    isOpen = false
                    tw(card, {Size = UDim2.new(1, 0, 0, CARD_H)}, TI_MED)
                    tw(optionsList, {Size = UDim2.new(1, 0, 0, 0)}, TI_MED)
                    tw(chevron, {Rotation = 0}, TI_MED)
                end)
                table.insert(optionBtns, ob)
            end
        end

        rebuildOptions()
        if selected then label.Text = selected end

        dropBtn.MouseButton1Click:Connect(function()
            if comp._disabled then return end
            isOpen = not isOpen
            local listH = isOpen and (#currentOptions * 37) or 0
            local cardH = isOpen and (CARD_H + listH) or CARD_H
            tw(card, {Size = UDim2.new(1, 0, 0, cardH)}, TI_MED)
            tw(optionsList, {Size = UDim2.new(1, 0, 0, listH)}, TI_MED)
            tw(chevron, {Rotation = isOpen and 180 or 0}, TI_MED)
        end)

        local outsideConn = UserInputService.InputBegan:Connect(closeOutside)
        table.insert(comp._connections, outsideConn)

        function comp:Edit(params)
            params = params or {}
            if params.text then label.Text = params.text end
            if params.options then
                currentOptions = {}
                for _, v in ipairs(params.options) do table.insert(currentOptions, v) end
                rebuildOptions()
                if isOpen then
                    isOpen = false
                    tw(card, {Size = UDim2.new(1, 0, 0, CARD_H)}, TI_MED)
                    tw(optionsList, {Size = UDim2.new(1, 0, 0, 0)}, TI_MED)
                    tw(chevron, {Rotation = 0}, TI_MED)
                end
            end
            if params.selected then
                selected = params.selected
                label.Text = selected
                for _, btn in ipairs(optionBtns) do
                    local ol = btn:FindFirstChildOfClass("TextLabel")
                    local cm = btn:FindFirstChild("Checkmark")
                    if ol then ol.TextColor3 = Theme.TextSecondary end
                    if cm then cm.Text = "" end
                    local btnLabel = btn:FindFirstChildOfClass("TextLabel")
                    if btnLabel and btnLabel.Text == selected then
                        btnLabel.TextColor3 = Theme.Accent
                        if cm then cm.Text = "✓" end
                    end
                end
            end
            if params.callback then cb = params.callback end
        end

        function comp:GetValue()
            return selected
        end

        function comp:Select(value)
            for _, btn in ipairs(optionBtns) do
                local ol = btn:FindFirstChildOfClass("TextLabel")
                local cm = btn:FindFirstChild("Checkmark")
                if ol and ol.Text == value then
                    selected = value
                    label.Text = selected
                    if ol then ol.TextColor3 = Theme.Accent end
                    if cm then cm.Text = "✓" end
                    if cb then cb(selected) end
                else
                    if ol then ol.TextColor3 = Theme.TextSecondary end
                    if cm then cm.Text = "" end
                end
            end
        end

        function comp:SetOptions(newOptions)
            currentOptions = {}
            for _, v in ipairs(newOptions) do table.insert(currentOptions, v) end
            rebuildOptions()
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Menu] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Menu:" .. tostring(text))
    end
    return result
end

function APTX:Input(sectionName, text, icon, placeholder, callback)
    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, 60)
        layout:Destroy()

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, PAD_SM)
        pad.PaddingRight = UDim.new(0, PAD_SM)
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.Parent = card

        local topRow = newF({
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }, card)

        if icon then
            local ip = newI(icon, 14, topRow)
            ip.ImageColor3 = Theme.TextSecondary
            ip.Position = UDim2.new(0, 0, 0.5, -7)
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, icon and 20 or 0, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, topRow)

        local inputBox = Instance.new("TextBox")
        inputBox.Name = "InputBox"
        inputBox.Size = UDim2.new(1, 0, 0, 22)
        inputBox.Position = UDim2.new(0, 0, 0, 22)
        inputBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        inputBox.BorderSizePixel = 0
        inputBox.PlaceholderText = placeholder or ""
        inputBox.PlaceholderColor3 = Theme.TextDisabled
        inputBox.Text = ""
        inputBox.TextColor3 = Theme.TextPrimary
        inputBox.Font = Enum.Font.Gotham
        inputBox.TextSize = 12
        inputBox.TextXAlignment = Enum.TextXAlignment.Left
        inputBox.ClearTextOnFocus = false
        inputBox.Parent = card
        newC(inputBox, 6)
        local inputStroke = newS(inputBox, Theme.Border, 1)

        local inputPad = Instance.new("UIPadding")
        inputPad.PaddingLeft = UDim.new(0, 8)
        inputPad.Parent = inputBox

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        initHover(comp, card, stroke)

        inputBox.Focused:Connect(function()
            tw(inputStroke, {Color = Theme.BrandMid}, TI_HOVER)
            tw(inputBox, {BackgroundColor3 = Color3.fromRGB(15, 15, 15)}, TI_HOVER)
        end)

        inputBox.FocusLost:Connect(function(enterPressed)
            tw(inputStroke, {Color = Theme.Border}, TI_HOVER)
            tw(inputBox, {BackgroundColor3 = Color3.fromRGB(10, 10, 10)}, TI_HOVER)
            if comp._disabled then return end
            if enterPressed and cb then
                cb(inputBox.Text)
            end
        end)

        function comp:Edit(params)
            params = params or {}
            if params.text then label.Text = params.text end
            if params.placeholder then inputBox.PlaceholderText = params.placeholder end
            if params.value then inputBox.Text = params.value end
            if params.callback then cb = params.callback end
        end

        function comp:GetValue()
            return inputBox.Text
        end

        function comp:SetValue(v)
            inputBox.Text = v or ""
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Input] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Input:" .. tostring(text))
    end
    return result
end

function APTX:Label(sectionName, text)
    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local isSeparator = text:match("^[-=━]+$")
        local label
        if isSeparator then
            label = newF({
                Name = "Separator",
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
            }, section.Container)
        else
            label = newL({
                Name = text,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.BrandMid,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
            }, section.Container)
        end

        local comp = {}
        initComponent(comp, label, section)

        function comp:Edit(params)
            params = params or {}
            if params.text then
                if label:IsA("TextLabel") then
                    label.Text = params.text
                end
            end
            if params.color and label:IsA("TextLabel") then
                label.TextColor3 = params.color
            end
        end

        function comp:SetText(newText)
            if label:IsA("TextLabel") then
                label.Text = newText
            end
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Label] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Label:" .. tostring(text))
    end
    return result
end

function APTX:Separator(sectionName, text)
    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local sep = newF({
            Name = "Separator",
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, section.Container)

        local line = newF({
            Name = "Line",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0.5, -0.5),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel = 0,
        }, sep)

        if text and text ~= "" then
            local label = newL({
                Name = "Label",
                Size = UDim2.new(0, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.TextSecondary,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextScaled = false,
            }, sep)
            
            local function updateLabelSize()
                local textW = label.TextBounds.X + 16
                label.Size = UDim2.new(0, math.min(textW, 300), 1, 0)
                label.Position = UDim2.new(0.5, -textW/2, 0, 0)
            end
            
            label:GetPropertyChangedSignal("Text"):Connect(updateLabelSize)
            task.defer(updateLabelSize)
            
            local bg = newF({
                Name = "Background",
                Size = UDim2.new(1, 12, 1, 0),
                Position = UDim2.new(0.5, -6, 0, 0),
                BackgroundColor3 = Theme.Surface,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
            }, sep)
            label.Parent = bg
        end

        local comp = {}
        initComponent(comp, sep, section)

        function comp:Edit(params)
            params = params or {}
            if params.text then
                local label = sep:FindFirstChild("Label")
                if label then label.Text = params.text end
            end
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Separator] Error creando componente: " .. tostring(result))
        return makeNilProxy("Separator")
    end
    return result
end

function APTX:GroupBox(sectionName, title, params)
    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        params = params or {}
        local height = params.height or 100
        local collapsible = params.collapsible or false
        local defaultCollapsed = params.collapsed or false

        local container = newF({
            Name = "GroupBox_" .. title,
            Size = UDim2.new(1, 0, 0, height + 32),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = true,
        }, section.Container)
        newC(container, 8)
        local border = newS(container, Theme.Border, 1)

        local header = newF({
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.fromRGB(10, 10, 10),
            BorderSizePixel = 0,
        }, container)

        local titleLabel = newL({
            Name = "Title",
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, header)

        local content = newF({
            Name = "Content",
            Size = UDim2.new(1, -8, 0, height),
            Position = UDim2.new(0, 4, 0, 36),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, container)

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 4)
        contentLayout.Parent = content

        local contentPad = Instance.new("UIPadding")
        contentPad.PaddingLeft = UDim.new(0, 4)
        contentPad.PaddingRight = UDim.new(0, 4)
        contentPad.PaddingTop = UDim.new(0, 4)
        contentPad.PaddingBottom = UDim.new(0, 4)
        contentPad.Parent = content

        if collapsible then
            local toggleBtn = newB({
                Name = "ToggleBtn",
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(1, -36, 0, 0),
                BackgroundTransparency = 1,
                Text = defaultCollapsed and "▶" or "▼",
                TextColor3 = Theme.TextSecondary,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                BorderSizePixel = 0,
                AutoButtonColor = false,
            }, header)

            local isCollapsed = defaultCollapsed
            if isCollapsed then
                content.Visible = false
                container.Size = UDim2.new(1, 0, 0, 32)
            end

            toggleBtn.MouseButton1Click:Connect(function()
                isCollapsed = not isCollapsed
                content.Visible = not isCollapsed
                toggleBtn.Text = isCollapsed and "▶" or "▼"
                local newHeight = isCollapsed and 32 or (32 + height)
                tw(container, {Size = UDim2.new(1, 0, 0, newHeight)}, TI_MED)
                if not isCollapsed then
                    container.Size = UDim2.new(1, 0, 0, newHeight)
                end
            end)
        end

        local comp = {}
        initComponent(comp, container, section)

        function comp:AddComponent(component)
            if component and component._frame then
                component._frame.Parent = content
                component._section = section
            end
        end

        function comp:Clear()
            for _, child in ipairs(content:GetChildren()) do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    local childComp = CompRegistry[child]
                    if childComp then
                        childComp:Remove()
                    else
                        child:Destroy()
                    end
                end
            end
        end

        function comp:SetHeight(newHeight)
            height = newHeight
            content.Size = UDim2.new(1, -8, 0, height)
            if not isCollapsed then
                container.Size = UDim2.new(1, 0, 0, height + 32)
            end
        end

        function comp:GetContent()
            return content
        end

        return comp
    end)
    if not ok then
        warn("[APTX:GroupBox] Error creando componente: " .. tostring(result))
        return makeNilProxy("GroupBox")
    end
    return result
end

function APTX:ProgressBar(sectionName, text, icon, max, default, callback)
    if type(icon) == "function" then
        callback = icon
        icon = nil
    end

    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local value = default or 0
        local maxValue = max or 100

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, 52)
        layout:Destroy()

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, PAD_SM)
        pad.PaddingRight = UDim.new(0, PAD_SM)
        pad.PaddingTop = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)
        pad.Parent = card

        local topRow = newF({
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }, card)

        if icon then
            local ip = newI(icon, 14, topRow)
            ip.ImageColor3 = Theme.TextSecondary
            ip.Position = UDim2.new(0, 0, 0.5, -7)
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, -50, 1, 0),
            Position = UDim2.new(0, icon and 20 or 0, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, topRow)

        local valueLabel = newL({
            Name = "ValueLabel",
            Size = UDim2.new(0, 40, 1, 0),
            Position = UDim2.new(1, -40, 0, 0),
            BackgroundTransparency = 1,
            Text = string.format("%.0f%%", (value / maxValue) * 100),
            TextColor3 = Theme.TextSecondary,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, topRow)

        local track = newF({
            Name = "Track",
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 22),
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            BorderSizePixel = 0,
        }, card)
        newC(track, 3)
        local trackBorder = newS(track, Theme.Border, 1)
        trackBorder.Transparency = 0.7

        local fill = newF({
            Name = "Fill",
            Size = UDim2.new(value / maxValue, 0, 1, 0),
            BackgroundColor3 = Theme.BrandMid,
            BorderSizePixel = 0,
        }, track)
        newC(fill, 3)

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        function comp:SetValue(v)
            value = clamp(v, 0, maxValue)
            local progress = value / maxValue
            tw(fill, {Size = UDim2.new(progress, 0, 1, 0)}, TI_MED)
            valueLabel.Text = string.format("%.0f%%", progress * 100)
            if cb then cb(value) end
        end

        function comp:GetValue()
            return value
        end

        function comp:GetMax()
            return maxValue
        end

        function comp:SetMax(newMax)
            maxValue = newMax
            comp:SetValue(value)
        end

        function comp:Edit(params)
            params = params or {}
            if params.text then label.Text = params.text end
            if params.max then maxValue = params.max end
            if params.value ~= nil then comp:SetValue(params.value) end
            if params.color then fill.BackgroundColor3 = params.color end
            if params.callback then cb = params.callback end
        end

        return comp
    end)
    if not ok then
        warn("[APTX:ProgressBar] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("ProgressBar:" .. tostring(text))
    end
    return result
end

function APTX:Spinner(sectionName, text, icon)
    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, CARD_H)

        local iconImg
        if icon then
            iconImg = newI(icon, 16, card)
            iconImg.LayoutOrder = 1
            iconImg.ImageColor3 = Theme.TextSecondary
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, 0, 1, 0),
            LayoutOrder = 2,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextSecondary,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local spinner = newF({
            Name = "Spinner",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -30, 0.5, -9),
            BackgroundColor3 = Theme.BrandMid,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, card)
        newC(spinner, 9)
        spinner.BackgroundTransparency = 0.5

        local spinnerStroke = newS(spinner, Theme.BrandMid, 2)
        spinnerStroke.Transparency = 0.5

        local comp = {}
        initComponent(comp, card, section)

        local running = true
        local rotation = 0

        local function animateSpinner()
            if not running or not spinner or not spinner.Parent then return end
            rotation = (rotation + 15) % 360
            spinner.Rotation = rotation
            task.delay(0.03, animateSpinner)
        end

        task.delay(0.05, animateSpinner)

        function comp:Stop()
            running = false
            spinner.Visible = false
        end

        function comp:Start()
            running = true
            spinner.Visible = true
            task.delay(0.05, animateSpinner)
        end

        function comp:Edit(params)
            params = params or {}
            if params.text then label.Text = params.text end
            if params.color then
                spinner.BackgroundColor3 = params.color
                spinnerStroke.Color = params.color
            end
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Spinner] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Spinner:" .. tostring(text))
    end
    return result
end

function APTX:Checkbox(sectionName, text, icon, default, callback)
    if type(icon) == "function" then
        callback = icon
        icon = nil
    end

    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local checked = default == true

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, CARD_H)

        local iconImg
        if icon then
            iconImg = newI(icon, 16, card)
            iconImg.LayoutOrder = 1
        end

        local checkBox = newF({
            Name = "Checkbox",
            Size = UDim2.new(0, 20, 0, 20),
            LayoutOrder = 2,
            BackgroundColor3 = Color3.fromRGB(10, 10, 10),
            BorderSizePixel = 0,
        }, card)
        newC(checkBox, 4)
        local checkStroke = newS(checkBox, Theme.Border, 1)

        local checkMark = newL({
            Name = "CheckMark",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = checked and "✓" or "",
            TextColor3 = Theme.BrandMid,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
        }, checkBox)

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, -24, 1, 0),
            LayoutOrder = 3,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        initHover(comp, card, stroke)

        local function toggleCheck()
            if comp._disabled then return end
            checked = not checked
            checkMark.Text = checked and "✓" or ""
            checkBox.BackgroundColor3 = checked and Theme.BrandMid or Color3.fromRGB(10, 10, 10)
            if cb then cb(checked) end
        end

        local clickConns = connectClick(card, toggleCheck)
        for _, c in ipairs(clickConns) do table.insert(comp._connections, c) end

        local checkConns = connectClick(checkBox, toggleCheck)
        for _, c in ipairs(checkConns) do table.insert(comp._connections, c) end

        function comp:Edit(params)
            params = params or {}
            if params.text then label.Text = params.text end
            if params.value ~= nil then
                checked = params.value
                checkMark.Text = checked and "✓" or ""
                checkBox.BackgroundColor3 = checked and Theme.BrandMid or Color3.fromRGB(10, 10, 10)
            end
            if params.callback then cb = params.callback end
        end

        function comp:GetValue()
            return checked
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Checkbox] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Checkbox:" .. tostring(text))
    end
    return result
end

function APTX:Keybind(sectionName, text, icon, default, callback)
    if type(icon) == "function" then
        callback = icon
        icon = nil
    end

    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local key = default or "None"
        local listening = false

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, CARD_H)

        local iconImg
        if icon then
            iconImg = newI(icon, 16, card)
            iconImg.LayoutOrder = 1
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, -80, 1, 0),
            LayoutOrder = 2,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local bindBtn = newB({
            Name = "KeybindBtn",
            Size = UDim2.new(0, 70, 0, 26),
            Position = UDim2.new(1, -(70 + PAD_SM), 0.5, -13),
            BackgroundColor3 = Color3.fromRGB(10, 10, 10),
            Text = key,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 2,
        }, card)
        newC(bindBtn, 6)
        local bindStroke = newS(bindBtn, Theme.Border, 1)

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        initHover(comp, card, stroke)

        local function startListening()
            if comp._disabled then return end
            listening = true
            bindBtn.Text = "..."
            bindBtn.BackgroundColor3 = Theme.BrandLo
            bindStroke.Color = Theme.BrandMid
        end

        local function stopListening(newKey)
            listening = false
            if newKey then
                key = newKey
                bindBtn.Text = key
                if cb then cb(key) end
            else
                bindBtn.Text = key
            end
            bindBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            bindStroke.Color = Theme.Border
        end

        bindBtn.MouseButton1Click:Connect(startListening)

        local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not listening or gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local keyName = input.KeyCode.Name
                if keyName ~= "Unknown" then
                    stopListening(keyName)
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                stopListening("Mouse1")
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                stopListening("Mouse2")
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                stopListening("Mouse3")
            end
        end)
        table.insert(comp._connections, inputConn)

        local focusLostConn = UserInputService.InputEnded:Connect(function(input)
            if listening then
                stopListening()
            end
        end)
        table.insert(comp._connections, focusLostConn)

        function comp:Edit(params)
            params = params or {}
            if params.text then label.Text = params.text end
            if params.key then
                key = params.key
                bindBtn.Text = key
            end
            if params.callback then cb = params.callback end
        end

        function comp:GetValue()
            return key
        end

        function comp:StartListening()
            startListening()
        end

        function comp:StopListening()
            if listening then stopListening() end
        end

        return comp
    end)
    if not ok then
        warn("[APTX:Keybind] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("Keybind:" .. tostring(text))
    end
    return result
end

function APTX:ColorPicker(sectionName, text, icon, default, callback)
    if type(icon) == "function" then
        callback = icon
        icon = nil
    end

    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        local color = default or Color3.fromRGB(192, 192, 192)
        local isOpen = false

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, CARD_H)
        layout:Destroy()

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, PAD_SM)
        pad.PaddingRight = UDim.new(0, PAD_SM)
        pad.Parent = card

        local topRow = newF({
            Size = UDim2.new(1, 0, 0, CARD_H),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }, card)

        if icon then
            local ip = newI(icon, 16, topRow)
            ip.Position = UDim2.new(0, 0, 0.5, -8)
        end

        local label = newL({
            Name = "Label",
            Size = UDim2.new(1, -80, 1, 0),
            Position = UDim2.new(0, icon and 22 or 0, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, topRow)

        local colorPreview = newF({
            Name = "ColorPreview",
            Size = UDim2.new(0, 30, 0, 22),
            Position = UDim2.new(1, -40, 0.5, -11),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, topRow)
        newC(colorPreview, 4)
        local previewStroke = newS(colorPreview, Theme.Border, 1)

        local comp = {}
        local cb = callback
        initComponent(comp, card, section)

        initHover(comp, card, stroke)

        local pickerFrame = newF({
            Name = "ColorPicker",
            Size = UDim2.new(0, 180, 0, 200),
            Position = UDim2.new(1, -190, 0, CARD_H + 4),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 10,
            ClipsDescendants = true,
        }, card)
        newC(pickerFrame, 8)
        local pickerStroke = newS(pickerFrame, Theme.Border, 1)

        local hueSlider = newF({
            Name = "HueSlider",
            Size = UDim2.new(0, 20, 1, -20),
            Position = UDim2.new(0, 8, 0, 10),
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            BorderSizePixel = 0,
        }, pickerFrame)
        newC(hueSlider, 4)

        local satValPicker = newF({
            Name = "SatValPicker",
            Size = UDim2.new(1, -44, 1, -20),
            Position = UDim2.new(0, 32, 0, 10),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
        }, pickerFrame)
        newC(satValPicker, 4)

        local hueGradient = Instance.new("UIGradient")
        hueGradient.Rotation = 90
        hueGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }
        hueGradient.Parent = hueSlider

        local svGradient = Instance.new("UIGradient")
        svGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        }
        svGradient.Parent = satValPicker

        local hsv = Color3.toHSV(color)
        local selectedHue = hsv * 360

        local function updatePicker(force)
            local h = selectedHue / 360
            local svGrad = satValPicker:FindFirstChildOfClass("UIGradient")
            if svGrad then
                local c = Color3.fromHSV(h, 1, 1)
                svGrad.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, c),
                }
            end
        end
        updatePicker()

        local function updateColorFromPicker()
            local h = selectedHue / 360
            local svSize = satValPicker.AbsoluteSize
            if svSize.X <= 0 or svSize.Y <= 0 then return end
            local mousePos = UserInputService:GetMouseLocation()
            local svPos = satValPicker.AbsolutePosition
            local x = clamp((mousePos.X - svPos.X) / svSize.X, 0, 1)
            local y = clamp((mousePos.Y - svPos.Y) / svSize.Y, 0, 1)
            color = Color3.fromHSV(h, x, 1 - y)
            colorPreview.BackgroundColor3 = color
            if cb then cb(color) end
        end

        local function onHueClick(input)
            if comp._disabled then return end
            local hPos = clamp((input.Position.Y - hueSlider.AbsolutePosition.Y) / hueSlider.AbsoluteSize.Y, 0, 1)
            selectedHue = (1 - hPos) * 360
            updatePicker()
            updateColorFromPicker()
        end

        local function onSVClick(input)
            if comp._disabled then return end
            updateColorFromPicker()
        end

        local hueClick = hueSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                onHueClick(input)
            end
        end)
        table.insert(comp._connections, hueClick)

        local hueMove = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    onHueClick(input)
                end
            end
        end)
        table.insert(comp._connections, hueMove)

        local svClick = satValPicker.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                onSVClick(input)
            end
        end)
        table.insert(comp._connections, svClick)

        local svMove = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    onSVClick(input)
                end
            end
        end)
        table.insert(comp._connections, svMove)

        colorPreview.MouseButton1Click:Connect(function()
            if comp._disabled then return end
            isOpen = not isOpen
            pickerFrame.Visible = isOpen
            if isOpen then
                updatePicker()
                updateColorFromPicker()
                pickerFrame.Position = UDim2.new(1, -190, 0, CARD_H + 4)
            end
        end)

        function comp:Edit(params)
            params = params or {}
            if params.text then label.Text = params.text end
            if params.color then
                color = params.color
                colorPreview.BackgroundColor3 = color
                local h, s, v = Color3.toHSV(color)
                selectedHue = h * 360
                updatePicker()
                if cb then cb(color) end
            end
            if params.callback then cb = params.callback end
        end

        function comp:GetValue()
            return color
        end

        function comp:SetColor(newColor)
            color = newColor
            colorPreview.BackgroundColor3 = color
            local h, s, v = Color3.toHSV(color)
            selectedHue = h * 360
            updatePicker()
        end

        return comp
    end)
    if not ok then
        warn("[APTX:ColorPicker] Error creando componente '" .. tostring(text) .. "': " .. tostring(result))
        return makeNilProxy("ColorPicker:" .. tostring(text))
    end
    return result
end

function APTX:TabContainer(sectionName, title, tabs, default)
    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        if not tabs or #tabs == 0 then
            tabs = {{name = "Tab 1", content = {}}}
        end

        local container = newF({
            Name = "TabContainer_" .. title,
            Size = UDim2.new(1, 0, 0, 200),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, section.Container)

        local tabBar = newF({
            Name = "TabBar",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Color3.fromRGB(5, 5, 5),
            BorderSizePixel = 0,
        }, container)
        newC(tabBar, 6)

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.FillDirection = Enum.FillDirection.Horizontal
        tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        tabLayout.Padding = UDim.new(0, 4)
        tabLayout.Parent = tabBar

        local tabPad = Instance.new("UIPadding")
        tabPad.PaddingLeft = UDim.new(0, 8)
        tabPad.PaddingRight = UDim.new(0, 8)
        tabPad.Parent = tabBar

        local contentArea = newF({
            Name = "ContentArea",
            Size = UDim2.new(1, 0, 1, -36),
            Position = UDim2.new(0, 0, 0, 36),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, container)

        local comp = {}
        initComponent(comp, container, section)

        local tabButtons = {}
        local tabContents = {}
        local selectedTab = default or 1

        for i, tabData in ipairs(tabs) do
            local tabBtn = newB({
                Name = "TabBtn_" .. tabData.name,
                Size = UDim2.new(0, 80, 0, 28),
                BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                Text = tabData.name,
                TextColor3 = i == selectedTab and Theme.BrandMid or Theme.TextSecondary,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                BorderSizePixel = 0,
                AutoButtonColor = false,
            }, tabBar)
            newC(tabBtn, 4)
            local tabStroke = newS(tabBtn, Theme.Border, 1)
            tabStroke.Transparency = i == selectedTab and 0.3 or 0.8

            local tabContent = newF({
                Name = "TabContent_" .. tabData.name,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Visible = i == selectedTab,
                ClipsDescendants = true,
            }, contentArea)

            local contentLayout = Instance.new("UIListLayout")
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Padding = UDim.new(0, 4)
            contentLayout.Parent = tabContent

            local contentPad = Instance.new("UIPadding")
            contentPad.PaddingLeft = UDim.new(0, 4)
            contentPad.PaddingRight = UDim.new(0, 4)
            contentPad.PaddingTop = UDim.new(0, 4)
            contentPad.PaddingBottom = UDim.new(0, 4)
            contentPad.Parent = tabContent

            tabButtons[i] = tabBtn
            tabContents[i] = tabContent

            tabBtn.MouseButton1Click:Connect(function()
                if comp._disabled then return end
                for j, btn in ipairs(tabButtons) do
                    local stroke = btn:FindFirstChildOfClass("UIStroke")
                    local txtColor = j == i and Theme.BrandMid or Theme.TextSecondary
                    btn.TextColor3 = txtColor
                    if stroke then stroke.Transparency = j == i and 0.3 or 0.8 end
                    tabContents[j].Visible = j == i
                end
                selectedTab = i
            end)

            tabBtn.MouseEnter:Connect(function()
                if i ~= selectedTab then
                    tw(tabBtn, {BackgroundColor3 = Theme.CardHover}, TI_HOVER)
                end
            end)

            tabBtn.MouseLeave:Connect(function()
                if i ~= selectedTab then
                    tw(tabBtn, {BackgroundColor3 = Color3.fromRGB(10, 10, 10)}, TI_HOVER)
                end
            end)

            for _, child in ipairs(tabData.content or {}) do
                if child and child._frame then
                    child._frame.Parent = tabContent
                    child._section = section
                end
            end
        end

        function comp:SelectTab(index)
            if index < 1 or index > #tabButtons then return end
            for i, btn in ipairs(tabButtons) do
                local stroke = btn:FindFirstChildOfClass("UIStroke")
                local txtColor = i == index and Theme.BrandMid or Theme.TextSecondary
                btn.TextColor3 = txtColor
                if stroke then stroke.Transparency = i == index and 0.3 or 0.8 end
                tabContents[i].Visible = i == index
            end
            selectedTab = index
        end

        function comp:GetSelectedTab()
            return selectedTab
        end

        function comp:GetTabContent(index)
            return tabContents[index]
        end

        return comp
    end)
    if not ok then
        warn("[APTX:TabContainer] Error creando componente '" .. tostring(title) .. "': " .. tostring(result))
        return makeNilProxy("TabContainer:" .. tostring(title))
    end
    return result
end

local NOTIF_Z_BASE = 1000
local NOTIF_GAP = 6
local NOTIF_RIGHT_MARGIN = 2
local notifCounter = 0

local function repositionStack()
    for i = #APTX._notifStack, 1, -1 do
        if not APTX._notifStack[i] or not APTX._notifStack[i]._alive then
            table.remove(APTX._notifStack, i)
        end
    end

    local bottomOffset = NOTIF_RIGHT_MARGIN
    local visible = {}
    for _, entry in ipairs(APTX._notifStack) do
        if entry and entry._alive and entry._card and entry._card.Parent then
            table.insert(visible, entry)
        end
    end
    local maxVisible = math.min(#visible, 4)

    for idx = 1, #visible do
        local entry = visible[idx]
        if idx > maxVisible then
            if entry._alive then
                entry:Close()
            end
        else
            local ch = entry._cardH
            local cw = entry._cardW
            local targetX = -(cw + NOTIF_RIGHT_MARGIN + 2)
            local targetY = -(bottomOffset + ch)
            tw(entry._card, {Position = UDim2.new(1, targetX, 1, targetY)}, TI_BOUNCE)
            bottomOffset = bottomOffset + ch + NOTIF_GAP
        end
    end
end

local function removeFromStack(notif)
    for i = #APTX._notifStack, 1, -1 do
        if APTX._notifStack[i] == notif then
            table.remove(APTX._notifStack, i)
            break
        end
    end
    repositionStack()
end

function APTX:Notify(params)
    local ok, result = pcall(function()
        assert(type(params) == "table", "[APTX:Notify] params debe ser una tabla")
        assert(params.title, "[APTX:Notify] params.title es requerido")
        assert(params.content, "[APTX:Notify] params.content es requerido")
        assert(APTX.GUI, "[APTX:Notify] Llama APTX:Config() antes de usar Notify")

        local title = params.title
        local body = params.content
        local iconTop = params["topbar-icon"]
        local iconBody = params["content-icon"]
        local duration = params.duration
        local sound = params.sound
        local buttons = params.buttons
        local notifType = params.type or "neutral"
        local size = params.size or 1

        local hasDur = duration and duration > 0
        local hasBtns = buttons and #buttons > 0

        local s = math.max(0.5, math.min(1.5, size or 1))
        local sW = math.floor(300 * s)
        local sTOPBAR = math.floor(32 * s)
        local sBODY = math.floor(36 * s)
        local sBTN_H = math.floor(32 * s)
        local sBTN_W = math.floor(90 * s)
        local sBTN_SZ = math.floor(22 * s)
        local sPAD = math.floor(14 * s)
        local sICON = math.floor(14 * s)

        local btnH = hasBtns and sBTN_H or 0
        local notifH = sTOPBAR + sBODY + (hasBtns and (sBTN_H + 8) or 8) + 2

        local accentColors = {
            info = Color3.fromRGB(192, 192, 192),
            success = Theme.Success,
            error = Theme.Error,
            neutral = Color3.fromRGB(192, 192, 192),
            warning = Theme.Warning,
        }

        local notifGui = Instance.new("ScreenGui")
        notifGui.Name = "APTXNotifGui"
        notifGui.ResetOnSpawn = false
        notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notifGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        local gui = notifGui
        notifCounter = notifCounter + 1

        local Card = newF({
            Name = "NotifCard_" .. notifCounter,
            Size = UDim2.new(0, sW, 0, notifH),
            Position = UDim2.new(1, sW + 20, 1, -notifH),
            BackgroundColor3 = Color3.fromRGB(7, 7, 7),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = NOTIF_Z_BASE,
        }, gui)
        newC(Card, CORNER_R)
        local cardStroke = newS(Card, Theme.Border, 1)
        local notifInnerHL = Instance.new("UIStroke")
        notifInnerHL.Color = Theme.BrandLo
        notifInnerHL.Thickness = 1
        notifInnerHL.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        notifInnerHL.Transparency = 0.85
        notifInnerHL.Parent = Card

        local accentBar = newF({
            Name = "AccentBar",
            Size = UDim2.new(0, 3, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = accentColors[notifType] or Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = NOTIF_Z_BASE + 1,
        }, Card)
        newC(accentBar, 12)

        local TB = newF({
            Size = UDim2.new(1, -3, 0, sTOPBAR),
            Position = UDim2.new(0, 3, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = NOTIF_Z_BASE + 1,
        }, Card)

        local closeBtnSize = math.max(1, math.floor(20 * s))
        local titleX = sPAD
        if iconTop then
            local iconLabel = newI(iconTop, sICON, TB)
            iconLabel.Position = UDim2.new(0, sPAD, 0.5, -sICON / 2)
            iconLabel.ZIndex = NOTIF_Z_BASE + 2
            titleX = sPAD + sICON + 6
        end

        local TitleLbl = newL({
            Size = UDim2.new(1, -(titleX + closeBtnSize + 8), 1, 0),
            Position = UDim2.new(0, titleX, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = math.max(9, math.floor(13 * s)),
            TextColor3 = Theme.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = NOTIF_Z_BASE + 2,
        }, TB)

        local CloseBtn = newB({
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -(20 + 4), 0.5, -10),
            BackgroundTransparency = 1,
            Text = "✕",
            TextColor3 = Theme.TextSecondary,
            TextSize = math.max(9, math.floor(12 * s)),
            Font = Enum.Font.Gotham,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = NOTIF_Z_BASE + 3,
        }, TB)

        local BodyFrame = newF({
            Size = UDim2.new(1, -3, 0, sBODY),
            Position = UDim2.new(0, sPAD + 3, 0, sTOPBAR),
            BackgroundTransparency = 1,
            ZIndex = NOTIF_Z_BASE + 1,
        }, Card)

        local bodyIconFrame
        if iconBody then
            bodyIconFrame = newI(iconBody, 16, BodyFrame)
            bodyIconFrame.Position = UDim2.new(0, 0, 0, 0)
            bodyIconFrame.ImageColor3 = accentColors[notifType] or Theme.Accent
            bodyIconFrame.ZIndex = NOTIF_Z_BASE + 2
        end

        local MsgLbl = newL({
            Size = UDim2.new(1, -(sPAD + 3), 0, sBODY),
            Position = UDim2.new(0, iconBody and 22 or 0, 0, 0),
            BackgroundTransparency = 1,
            Text = body,
            Font = Enum.Font.Gotham,
            TextSize = math.max(8, math.floor(12 * s)),
            TextColor3 = Theme.TextSecondary,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = NOTIF_Z_BASE + 2,
        }, BodyFrame)

        local DividerFill
        if hasDur then
            local db = newF({
                Name = "DurationBar",
                Size = UDim2.new(1, -3, 0, 2),
                Position = UDim2.new(0, 3, 1, -2),
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                BorderSizePixel = 0,
                ZIndex = NOTIF_Z_BASE + 1,
            }, Card)
            DividerFill = newF({
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = accentColors[notifType] or Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = NOTIF_Z_BASE + 2,
            }, db)
        end

        if hasBtns then
            local bc = newF({
                Size = UDim2.new(1, -3, 0, sBTN_H),
                Position = UDim2.new(0, 3, 0, sTOPBAR + sBODY),
                BackgroundTransparency = 1,
                ZIndex = NOTIF_Z_BASE + 1,
            }, Card)
            local btnLayout = Instance.new("UIListLayout")
            btnLayout.FillDirection = Enum.FillDirection.Horizontal
            btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            btnLayout.Padding = UDim.new(0, 6)
            btnLayout.Parent = bc

            for i = 1, math.min(#buttons, 3) do
                local bDef = buttons[i]
                local bg = bDef.color or Color3.fromRGB(45, 45, 50)
                local Btn = newB({
                    Size = UDim2.new(0, sBTN_W, 0, sBTN_SZ),
                    BackgroundColor3 = bg,
                    Text = bDef.label or ("Button " .. i),
                    Font = Enum.Font.GothamBold,
                    TextSize = math.max(8, math.floor(11 * s)),
                    TextColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = NOTIF_Z_BASE + 3,
                }, bc)
                newC(Btn, math.floor(6 * s))
                local bs = newS(Btn, Color3.new(1, 1, 1), 1)
                bs.Transparency = 0.85

                Btn.MouseEnter:Connect(function()
                    tw(Btn, {BackgroundColor3 = bg:Lerp(Color3.new(1, 1, 1), 0.15)}, TI_HOVER)
                end)
                Btn.MouseLeave:Connect(function()
                    tw(Btn, {BackgroundColor3 = bg}, TI_HOVER)
                end)
                Btn.MouseButton1Down:Connect(function()
                    tw(Btn, {Size = UDim2.new(0, sBTN_W - 4, 0, sBTN_SZ - 2)}, TI_FAST)
                end)
                Btn.MouseButton1Up:Connect(function()
                    tw(Btn, {Size = UDim2.new(0, sBTN_W, 0, sBTN_SZ)}, TI_BACK)
                end)
                Btn.MouseButton1Click:Connect(function()
                    if bDef.callback then task.spawn(bDef.callback) end
                end)
            end
        end

        if sound then
            local snd = Instance.new("Sound")
            snd.SoundId = sound
            snd.Volume = 0.6
            snd.Parent = Card
            snd:Play()
            Debris:AddItem(snd, 5)
        end

        local Notif = {
            _card = Card,
            _title = TitleLbl,
            _msg = MsgLbl,
            _divFill = DividerFill,
            _alive = true,
            _cardH = notifH,
            _cardW = sW,
            _autoCloseThread = nil,
        }

        Card.Destroying:Connect(function()
            if Notif._alive then
                Notif._alive = false
                if Notif._autoCloseThread then
                    task.cancel(Notif._autoCloseThread)
                    Notif._autoCloseThread = nil
                end
                removeFromStack(Notif)
            end
            if notifGui and notifGui.Parent then
                notifGui:Destroy()
            end
        end)

        table.insert(APTX._notifStack, Notif)

        local function fallClose(cb)
            if not Notif._alive then return end
            Notif._alive = false

            if Notif._autoCloseThread then
                pcall(task.cancel, Notif._autoCloseThread)
                Notif._autoCloseThread = nil
            end

            removeFromStack(Notif)

            if not Card or not Card.Parent then
                if cb then pcall(cb) end
                return
            end

            local cur = Card.Position
            local t1 = TweenService:Create(Card, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset - 10),
                Rotation = -2,
            })
            t1.Completed:Connect(function()
                if not Card or not Card.Parent then
                    if cb then pcall(cb) end
                    return
                end
                local t2 = TweenService:Create(Card, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, sW + 80, cur.Y.Scale, cur.Y.Offset + math.floor(notifH * 0.55)),
                    Rotation = 22,
                })
                TweenService:Create(Card, TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.5,
                }):Play()
                t2.Completed:Connect(function()
                    if cb then pcall(cb) end
                    if Card and Card.Parent then
                        Card:Destroy()
                    end
                end)
                t2:Play()
            end)
            t1:Play()
        end

        task.delay(0.05, function()
            repositionStack()
        end)

        if hasDur and DividerFill then
            tw(DividerFill, {Size = UDim2.new(0, 0, 1, 0)}, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out))
            local autoThread = task.delay(duration, function()
                if Notif._alive then fallClose() end
            end)
            Notif._autoCloseThread = autoThread
        end

        CloseBtn.MouseButton1Click:Connect(function()
            if Notif._alive then fallClose() end
        end)

        CloseBtn.MouseEnter:Connect(function()
            tw(CloseBtn, {TextColor3 = Theme.TextPrimary}, TI_HOVER)
        end)
        CloseBtn.MouseLeave:Connect(function()
            tw(CloseBtn, {TextColor3 = Theme.TextSecondary}, TI_HOVER)
        end)

        function Notif:Destroy()
            if self._alive then
                fallClose()
            elseif self._card and self._card.Parent then
                self._card:Destroy()
            end
        end

        function Notif:Close(cb)
            if self._alive then fallClose(cb) end
        end

        function Notif:Edit(p)
            if not self._alive then return end
            p = p or {}
            if p.title then self._title.Text = p.title end
            if p.content then self._msg.Text = p.content end
            if p.resetTimer and p.resetTimer > 0 and self._divFill then
                if self._autoCloseThread then
                    pcall(task.cancel, self._autoCloseThread)
                    self._autoCloseThread = nil
                end
                self._divFill.Size = UDim2.new(1, 0, 1, 0)
                tw(self._divFill, {Size = UDim2.new(0, 0, 1, 0)}, TweenInfo.new(p.resetTimer, Enum.EasingStyle.Linear, Enum.EasingDirection.Out))
                local autoThread = task.delay(p.resetTimer, function()
                    if self._alive then fallClose() end
                end)
                self._autoCloseThread = autoThread
            end
        end

        function Notif:Flash(c)
            if not self._alive then return end
            local s = self._card:FindFirstChildOfClass("UIStroke")
            if s then
                local orig = s.Color
                s.Color = c or Color3.new(1, 1, 1)
                tw(s, {Color = orig}, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            end
        end

        function Notif:SetBody(text, pulse)
            if not self._alive then return end
            self._msg.Text = text or ""
            if pulse then
                tw(self._msg, {TextTransparency = 0.6}, TI_FAST)
                task.delay(0.15, function()
                    if self._alive then tw(self._msg, {TextTransparency = 0}, TI_SLOW) end
                end)
            end
        end

        function Notif:SetAccent(color)
            if not self._alive then return end
            local bar = self._card:FindFirstChild("AccentBar")
            if bar then bar.BackgroundColor3 = color end
            local db = self._card:FindFirstChild("DurationBar")
            if db then
                local fill = db:FindFirstChildOfClass("Frame")
                if fill then fill.BackgroundColor3 = color end
            end
        end

        function Notif:Shake()
            if not self._alive then return end
            local card = self._card
            local orig = card.Position
            local offsets = {8, -8, 6, -6, 3, -3, 0}
            local shakeInfo = TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

            local function runStep(idx)
                if not card or not card.Parent then return end
                if idx > #offsets then
                    card.Position = orig
                    return
                end
                local tween = TweenService:Create(card, shakeInfo, {
                    Position = UDim2.new(orig.X.Scale, orig.X.Offset + offsets[idx], orig.Y.Scale, orig.Y.Offset),
                })
                tween.Completed:Connect(function()
                    runStep(idx + 1)
                end)
                tween:Play()
            end
            runStep(1)
        end

        return Notif
    end)
    if not ok then
        warn("[APTX:Notify] Error creando notificacion: " .. tostring(result))
        return nil
    end
    return result
end

function APTX:Snackbar(text, duration)
    local ok, result = pcall(function()
        if not APTX.GUI then
            error("APTX:Config must be called before Snackbar")
        end

        duration = duration or 3

        local snack = newF({
            Name = "Snackbar",
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 1, -16),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            ZIndex = 500,
            ClipsDescendants = true,
        }, APTX.GUI)
        newC(snack, 8)
        local snackStroke = newS(snack, Theme.Border, 1)
        snackStroke.Transparency = 0.7

        local label = newL({
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, snack)

        local function updateSize()
            local textW = label.TextBounds.X + 32
            local textH = math.max(24, label.TextBounds.Y + 16)
            snack.Size = UDim2.new(0, math.min(textW, 400), 0, textH)
            snack.Position = UDim2.new(0.5, -snack.Size.X.Offset / 2, 1, -16)
        end

        label:GetPropertyChangedSignal("Text"):Connect(updateSize)
        task.defer(updateSize)

        snack.BackgroundTransparency = 1
        snack.Size = UDim2.new(0, 0, 0, 0)
        snack.Position = UDim2.new(0.5, 0, 1, 16)

        task.delay(0.05, function()
            tw(snack, {BackgroundTransparency = 0}, TI_BOUNCE)
            tw(snack, {Size = UDim2.new(0, snack.Size.X.Offset, 0, snack.Size.Y.Offset)}, TI_BOUNCE)
            tw(snack, {Position = UDim2.new(0.5, -snack.Size.X.Offset / 2, 1, -16)}, TI_BOUNCE)
        end)

        task.delay(duration, function()
            if not snack or not snack.Parent then return end
            tw(snack, {Position = UDim2.new(0.5, -snack.Size.X.Offset / 2, 1, 16)}, TI_MED)
            tw(snack, {BackgroundTransparency = 1}, TI_MED)
            task.delay(0.25, function()
                if snack and snack.Parent then snack:Destroy() end
            end)
        end)

        local function dismiss()
            if snack and snack.Parent then
                tw(snack, {Position = UDim2.new(0.5, -snack.Size.X.Offset / 2, 1, 16)}, TI_FAST)
                tw(snack, {BackgroundTransparency = 1}, TI_FAST)
                task.delay(0.15, function()
                    if snack and snack.Parent then snack:Destroy() end
                end)
            end
        end

        return {
            Destroy = dismiss,
            SetText = function(newText)
                if snack and snack.Parent then
                    label.Text = newText
                end
            end,
        }
    end)
    if not ok then
        warn("[APTX:Snackbar] Error: " .. tostring(result))
        return nil
    end
    return result
end

function APTX:Dialog(params)
    local ok, result = pcall(function()
        assert(type(params) == "table", "[APTX:Dialog] params debe ser una tabla")
        assert(params.title, "[APTX:Dialog] params.title es requerido")
        assert(params.content, "[APTX:Dialog] params.content es requerido")
        assert(APTX.GUI, "[APTX:Dialog] Llama APTX:Config() antes de usar Dialog")

        local dialogGui = Instance.new("ScreenGui")
        dialogGui.Name = "APTXDialogGui"
        dialogGui.ResetOnSpawn = false
        dialogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        dialogGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

        local overlay = newF({
            Name = "DialogOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            ZIndex = 2000,
        }, dialogGui)

        local card = newF({
            Name = "DialogCard",
            Size = UDim2.new(0, 400, 0, 0),
            Position = UDim2.new(0.5, -200, 0.5, -100),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 2001,
        }, overlay)
        newC(card, 12)
        newS(card, Theme.Border, 1)

        local header = newF({
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = Color3.fromRGB(5, 5, 5),
            BorderSizePixel = 0,
        }, card)
        local headerStroke = newS(header, Theme.Border, 1)
        headerStroke.Transparency = 0.5

        local titleLabel = newL({
            Name = "Title",
            Size = UDim2.new(1, -50, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = params.title,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, header)

        local closeBtn = newB({
            Name = "CloseBtn",
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(1, -36, 0.5, -16),
            BackgroundTransparency = 1,
            Text = "✕",
            TextColor3 = Theme.TextSecondary,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            BorderSizePixel = 0,
            AutoButtonColor = false,
        }, header)
        closeBtn.MouseEnter:Connect(function()
            tw(closeBtn, {TextColor3 = Theme.Error}, TI_HOVER)
        end)
        closeBtn.MouseLeave:Connect(function()
            tw(closeBtn, {TextColor3 = Theme.TextSecondary}, TI_HOVER)
        end)

        local content = newF({
            Name = "Content",
            Size = UDim2.new(1, -24, 0, 0),
            Position = UDim2.new(0, 12, 0, 48),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, card)

        local contentLabel = newL({
            Name = "ContentLabel",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = params.content,
            TextColor3 = Theme.TextSecondary,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
        }, content)

        local buttonContainer = newF({
            Name = "ButtonContainer",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, card)

        local btnLayout = Instance.new("UIListLayout")
        btnLayout.FillDirection = Enum.FillDirection.Horizontal
        btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        btnLayout.Padding = UDim.new(0, 8)
        btnLayout.Parent = buttonContainer

        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingRight = UDim.new(0, 12)
        btnPad.PaddingBottom = UDim.new(0, 8)
        btnPad.Parent = buttonContainer

        local buttons = params.buttons or {
            {text = "Aceptar", callback = function() end}
        }

        local buttonObjects = {}

        for _, btnData in ipairs(buttons) do
            local btn = newB({
                Size = UDim2.new(0, 80, 0, 32),
                BackgroundColor3 = btnData.color or Theme.BrandLo,
                Text = btnData.text,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                ZIndex = 2002,
            }, buttonContainer)
            newC(btn, 6)
            local btnStroke = newS(btn, Color3.fromRGB(255, 255, 255), 1)
            btnStroke.Transparency = 0.6

            btn.MouseEnter:Connect(function()
                tw(btn, {BackgroundColor3 = btnData.color:Lerp(Color3.new(1, 1, 1), 0.2)}, TI_HOVER)
            end)
            btn.MouseLeave:Connect(function()
                tw(btn, {BackgroundColor3 = btnData.color or Theme.BrandLo}, TI_HOVER)
            end)

            btn.MouseButton1Click:Connect(function()
                if btnData.callback then
                    btnData.callback()
                end
                if btnData.close ~= false then
                    dialogGui:Destroy()
                end
            end)

            table.insert(buttonObjects, btn)
        end

        closeBtn.MouseButton1Click:Connect(function()
            dialogGui:Destroy()
        end)

        local function updateSize()
            local textBounds = contentLabel.TextBounds
            local textH = math.max(20, textBounds.Y + 8)
            contentLabel.Size = UDim2.new(1, 0, 0, textH)
            content.Size = UDim2.new(1, -24, 0, textH)

            local btnH = 40
            buttonContainer.Size = UDim2.new(1, 0, 0, btnH)

            local totalH = 44 + textH + btnH + 16
            card.Size = UDim2.new(0, 400, 0, totalH)
            card.Position = UDim2.new(0.5, -200, 0.5, -totalH / 2)

            card.BackgroundTransparency = 1
            tw(card, {BackgroundTransparency = 0}, TI_BOUNCE)

            for _, child in ipairs(card:GetChildren()) do
                if child:IsA("UIStroke") then
                    child.Transparency = 1
                    tw(child, {Transparency = 0}, TI_BOUNCE)
                end
            end
        end

        task.defer(updateSize)

        local dialog = {
            _gui = dialogGui,
            _card = card,
            _buttons = buttonObjects,
            _title = titleLabel,
            _content = contentLabel,

            Destroy = function()
                if dialogGui and dialogGui.Parent then
                    dialogGui:Destroy()
                end
            end,

            SetTitle = function(self, newTitle)
                titleLabel.Text = newTitle
            end,

            SetContent = function(self, newContent)
                contentLabel.Text = newContent
                updateSize()
            end,

            AddButton = function(self, text, callback, color)
                local btn = newB({
                    Size = UDim2.new(0, 80, 0, 32),
                    BackgroundColor3 = color or Theme.BrandLo,
                    Text = text,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 2002,
                }, buttonContainer)
                newC(btn, 6)
                local btnStroke = newS(btn, Color3.fromRGB(255, 255, 255), 1)
                btnStroke.Transparency = 0.6

                btn.MouseEnter:Connect(function()
                    tw(btn, {BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.2)}, TI_HOVER)
                end)
                btn.MouseLeave:Connect(function()
                    tw(btn, {BackgroundColor3 = color or Theme.BrandLo}, TI_HOVER)
                end)

                btn.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)

                table.insert(self._buttons, btn)
                updateSize()
                return btn
            end,

            RemoveButton = function(self, index)
                if self._buttons[index] then
                    self._buttons[index]:Destroy()
                    table.remove(self._buttons, index)
                    updateSize()
                end
            end,
        }

        table.insert(APTX._dialogStack, dialog)

        return dialog
    end)
    if not ok then
        warn("[APTX:Dialog] Error: " .. tostring(result))
        return nil
    end
    return result
end

function APTX:Prompt(params)
    local ok, result = pcall(function()
        assert(type(params) == "table", "[APTX:Prompt] params debe ser una tabla")
        assert(params.title, "[APTX:Prompt] params.title es requerido")
        assert(params.content, "[APTX:Prompt] params.content es requerido")
        assert(APTX.GUI, "[APTX:Prompt] Llama APTX:Config() antes de usar Prompt")

        local dialog = APTX:Dialog({
            title = params.title,
            content = params.content,
            buttons = {
                {text = "Cancelar", callback = function() end},
                {text = "Aceptar", callback = function() end},
            }
        })

        if not dialog then return nil end

        local content = dialog._card:FindFirstChild("Content")
        if content then
            local inputBox = Instance.new("TextBox")
            inputBox.Name = "PromptInput"
            inputBox.Size = UDim2.new(1, 0, 0, 30)
            inputBox.Position = UDim2.new(0, 0, 1, 4)
            inputBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            inputBox.BorderSizePixel = 0
            inputBox.PlaceholderText = params.placeholder or ""
            inputBox.PlaceholderColor3 = Theme.TextDisabled
            inputBox.Text = params.default or ""
            inputBox.TextColor3 = Theme.TextPrimary
            inputBox.Font = Enum.Font.Gotham
            inputBox.TextSize = 13
            inputBox.TextXAlignment = Enum.TextXAlignment.Left
            inputBox.ClearTextOnFocus = false
            inputBox.Parent = content
            newC(inputBox, 6)
            newS(inputBox, Theme.Border, 1)

            local inputPad = Instance.new("UIPadding")
            inputPad.PaddingLeft = UDim.new(0, 8)
            inputPad.Parent = inputBox

            local contentLabel = content:FindFirstChild("ContentLabel")
            if contentLabel then
                contentLabel.Size = UDim2.new(1, 0, 0, contentLabel.Size.Y.Offset)
            end

            local function updatePromptSize()
                local textBounds = contentLabel.TextBounds
                local textH = math.max(20, textBounds.Y + 8)
                contentLabel.Size = UDim2.new(1, 0, 0, textH)
                inputBox.Position = UDim2.new(0, 0, 1, 6)
                content.Size = UDim2.new(1, -24, 0, textH + 36)

                local btnH = 40
                local buttonContainer = dialog._card:FindFirstChild("ButtonContainer")
                if buttonContainer then
                    buttonContainer.Size = UDim2.new(1, 0, 0, btnH)
                end

                local totalH = 44 + textH + 36 + btnH + 16
                dialog._card.Size = UDim2.new(0, 400, 0, totalH)
                dialog._card.Position = UDim2.new(0.5, -200, 0.5, -totalH / 2)
            end

            task.defer(updatePromptSize)

            local buttons = dialog._buttons
            for _, btn in ipairs(buttons) do
                local oldClick = btn.MouseButton1Click
                btn.MouseButton1Click:Connect(function()
                    if btn.Text == "Aceptar" then
                        if params.callback then
                            params.callback(inputBox.Text)
                        end
                        dialog:Destroy()
                    end
                end)
            end

            inputBox.Focused:Connect(function()
                task.delay(0.05, function()
                    inputBox.Text = inputBox.Text
                end)
            end)

            return {
                GetValue = function()
                    return inputBox.Text
                end,
                SetValue = function(text)
                    inputBox.Text = text or ""
                end,
                Destroy = function()
                    dialog:Destroy()
                end,
            }
        end

        return nil
    end)
    if not ok then
        warn("[APTX:Prompt] Error: " .. tostring(result))
        return nil
    end
    return result
end

function APTX:BindKey(key, callback, description)
    if not key or not callback then return end
    APTX._keybindings[key] = {
        callback = callback,
        description = description or "",
    }
end

function APTX:UnbindKey(key)
    APTX._keybindings[key] = nil
end

function APTX:ClearKeybinds()
    APTX._keybindings = {}
end

function APTX:InitKeybindSystem()
    local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            local binding = APTX._keybindings[keyName]
            if binding and binding.callback then
                binding.callback()
            end
        end
    end)
    table.insert(APTX._connections, inputConn)
end

function APTX:IsKeyDown(key)
    return UserInputService:IsKeyDown(Enum.KeyCode[key])
end

function APTX:GetKeybindings()
    local result = {}
    for key, binding in pairs(APTX._keybindings) do
        result[key] = binding.description
    end
    return result
end

APTX._floatingFrames = {}
local FF_Z_BASE = 600

function APTX:FloatingFrame(title, width, height, opts)
    local ok, result = pcall(function()
        opts = opts or {}
        local player = Players.LocalPlayer
        if not player then
            Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
            player = Players.LocalPlayer
        end
        local playerGui = player:WaitForChild("PlayerGui")

        local gui = Instance.new("ScreenGui")
        gui.Name = "FFrame_" .. tostring(#APTX._floatingFrames + 1)
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = playerGui

        local w = width or 420
        local h = height or 300
        local headerH = 32
        local x = opts.x or (80 + (#APTX._floatingFrames * 30))
        local y = opts.y or (80 + (#APTX._floatingFrames * 30))

        local frame = newF({
            Name = "FloatingFrame",
            Size = UDim2.new(0, w, 0, h),
            Position = UDim2.new(0, x, 0, y),
            BackgroundColor3 = Theme.FloatingBg,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = FF_Z_BASE + 1,
        }, gui)
        newC(frame, 10)
        local frameStroke = newS(frame, Theme.FloatingBorder, 1)

        local shadow = newF({
            Size = UDim2.new(1, 12, 1, 12),
            Position = UDim2.new(0.5, -6, 0.5, -6),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            ZIndex = FF_Z_BASE,
        }, gui)
        newC(shadow, 12)
        local posSync = frame:GetPropertyChangedSignal("Position"):Connect(function()
            if shadow and shadow.Parent then
                shadow.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset - 6, frame.Position.Y.Scale, frame.Position.Y.Offset - 6)
            end
        end)
        local sizeSync = frame:GetPropertyChangedSignal("Size"):Connect(function()
            if shadow and shadow.Parent then
                shadow.Size = UDim2.new(1, frame.Size.X.Offset + 12, 1, frame.Size.Y.Offset + 12)
            end
        end)
        shadow.Size = UDim2.new(1, w + 12, 1, h + 12)
        shadow.Position = UDim2.new(0, x - 6, 0, y - 6)

        local header = newF({
            Name = "FFHeader",
            Size = UDim2.new(1, 0, 0, headerH),
            BackgroundColor3 = Color3.fromRGB(8, 8, 8),
            BorderSizePixel = 0,
            ZIndex = FF_Z_BASE + 2,
        }, frame)
        local headerHL = Instance.new("UIStroke")
        headerHL.Color = Theme.BrandLo
        headerHL.Thickness = 1
        headerHL.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        headerHL.Transparency = 0.85
        headerHL.Parent = header

        local titleLbl = newL({
            Name = "FFTitle",
            Size = UDim2.new(1, -80, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = FF_Z_BASE + 3,
        }, header)

        local btnFrame = newF({
            Size = UDim2.new(0, 72, 1, 0),
            Position = UDim2.new(1, -76, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = FF_Z_BASE + 3,
        }, header)
        local btnLayout = Instance.new("UIListLayout")
        btnLayout.FillDirection = Enum.FillDirection.Horizontal
        btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        btnLayout.Padding = UDim.new(0, 4)
        btnLayout.Parent = btnFrame

        local pinBtn = newB({
            Size = UDim2.new(0, 22, 0, 22),
            BackgroundTransparency = 1,
            Text = "\u{1F4CC}",
            TextColor3 = Theme.TextSecondary,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = FF_Z_BASE + 4,
        }, btnFrame)
        local pinned = false
        pinBtn.MouseButton1Click:Connect(function()
            pinned = not pinned
            pinBtn.TextColor3 = pinned and Theme.BrandMid or Theme.TextSecondary
        end)

        local closeBtn = newB({
            Size = UDim2.new(0, 22, 0, 22),
            BackgroundTransparency = 1,
            Text = "\u{2715}",
            TextColor3 = Theme.TextSecondary,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = FF_Z_BASE + 4,
        }, btnFrame)
        closeBtn.MouseEnter:Connect(function() tw(closeBtn, {TextColor3 = Theme.Error}, TI_HOVER) end)
        closeBtn.MouseLeave:Connect(function() tw(closeBtn, {TextColor3 = Theme.TextSecondary}, TI_HOVER) end)

        local content = newF({
            Name = "FFContent",
            Size = UDim2.new(1, -4, 1, -(headerH + 4)),
            Position = UDim2.new(0, 2, 0, headerH + 2),
            BackgroundTransparency = 1,
            ZIndex = FF_Z_BASE + 2,
        }, frame)

        local logList = Instance.new("ScrollingFrame")
        logList.Name = "FFLogList"
        logList.Size = UDim2.new(1, -4, 1, -30)
        logList.Position = UDim2.new(0, 2, 0, 0)
        logList.BackgroundTransparency = 1
        logList.BorderSizePixel = 0
        logList.ScrollBarThickness = 2
        logList.ScrollBarImageColor3 = Theme.Border
        logList.ScrollBarImageTransparency = 0.6
        logList.ElasticBehavior = Enum.ElasticBehavior.Always
        logList.CanvasSize = UDim2.new(0, 0, 0, 0)
        logList.Parent = content

        local logLayout = Instance.new("UIListLayout")
        logLayout.SortOrder = Enum.SortOrder.LayoutOrder
        logLayout.Padding = UDim.new(0, 1)
        logLayout.Parent = logList
        local logLayoutConn = logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            logList.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 2)
        end)

        local bottomBar = newF({
            Size = UDim2.new(1, -4, 0, 26),
            Position = UDim2.new(0, 2, 1, -28),
            BackgroundTransparency = 1,
            ZIndex = FF_Z_BASE + 3,
        }, content)

        local statusLabel = newL({
            Size = UDim2.new(0, 100, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Theme.TextDisabled,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = FF_Z_BASE + 4,
        }, bottomBar)

        local autoScroll = true
        local autoScrollBtn = newB({
            Size = UDim2.new(0, 50, 1, 0),
            Position = UDim2.new(1, -104, 0, 0),
            BackgroundTransparency = 1,
            Text = "AUTO⏺",
            TextColor3 = Theme.BrandMid,
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = FF_Z_BASE + 4,
        }, bottomBar)
        autoScrollBtn.MouseButton1Click:Connect(function()
            autoScroll = not autoScroll
            autoScrollBtn.TextColor3 = autoScroll and Theme.BrandMid or Theme.TextDisabled
        end)

        local clearBtn = newB({
            Size = UDim2.new(0, 50, 1, 0),
            Position = UDim2.new(1, -52, 0, 0),
            BackgroundTransparency = 1,
            Text = "CLEAR",
            TextColor3 = Theme.TextSecondary,
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = FF_Z_BASE + 4,
        }, bottomBar)
        clearBtn.MouseButton1Click:Connect(function()
            for _, child in ipairs(logList:GetChildren()) do
                if child:IsA("TextLabel") or (child:IsA("Frame") and not child:IsA("UIListLayout")) then
                    child:Destroy()
                end
            end
            logLayout.AbsoluteContentSize = UDim2.new(0, 0, 0, 0)
        end)

        local dragConns = makeDraggable(header, frame)
        for _, conn in ipairs(dragConns) do table.insert(APTX._connections, conn) end

        local zCounter = FF_Z_BASE + 5
        local function bringToFront()
            zCounter = zCounter + 1
            frame.ZIndex = zCounter
            shadow.ZIndex = zCounter - 1
            for _, child in ipairs(frame:GetDescendants()) do
                if child:IsA("GuiObject") then
                    child.ZIndex = child.ZIndex + 2
                end
            end
        end
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                bringToFront()
            end
        end)

        local _alive = true
        closeBtn.MouseButton1Click:Connect(function()
            if _alive then
                _alive = false
                tw(frame, {Size = UDim2.new(0, w, 0, 0), BackgroundTransparency = 1}, TI_MED)
                tw(shadow, {BackgroundTransparency = 1}, TI_MED)
                task.delay(0.25, function()
                    if gui and gui.Parent then gui:Destroy() end
                end)
            end
        end)

        local floatingFrame = {
            _frame = frame, _gui = gui,
            _logList = logList, _logLayout = logLayout,
            _statusLabel = statusLabel, _autoScroll = autoScroll,
            _alive = _alive, _pinned = pinned, _visible = true,

            AddLog = function(self, text, color, icon)
                if not self._alive then return end
                local line = newF({Size = UDim2.new(1, -4, 0, 18), BackgroundTransparency = 1, ZIndex = FF_Z_BASE + 3}, logList)
                if icon then
                    newL({Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, 2, 0, 0), BackgroundTransparency = 1, Text = icon, TextColor3 = color or Theme.TextSecondary, TextSize = 10, Font = Enum.Font.Gotham, ZIndex = FF_Z_BASE + 4}, line)
                end
                newL({Size = UDim2.new(1, icon and -22 or -6, 1, 0), Position = UDim2.new(0, icon and 20 or 4, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = color or Theme.LogDefault, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = FF_Z_BASE + 4}, line)
                if autoScroll then
                    task.delay(0.02, function()
                        if logList and logList.Parent then logList.CanvasPosition = Vector2.new(0, math.huge) end
                    end)
                end
                return line
            end,

            AddRichLog = function(self, parts)
                if not self._alive then return end
                local line = newF({Size = UDim2.new(1, -4, 0, 18), BackgroundTransparency = 1, ZIndex = FF_Z_BASE + 3}, logList)
                local xOff = 4
                for _, part in ipairs(parts) do
                    local seg = newL({Size = UDim2.new(0, part.width or 0, 1, 0), Position = UDim2.new(0, xOff, 0, 0), BackgroundTransparency = 1, Text = part.text or "", TextColor3 = part.color or Theme.LogDefault, TextSize = part.size or 11, Font = part.bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = FF_Z_BASE + 4}, line)
                    local w = seg.TextBounds.X + 4
                    seg.Size = UDim2.new(0, w, 1, 0)
                    xOff = xOff + w
                end
                if autoScroll then
                    task.delay(0.02, function()
                        if logList and logList.Parent then logList.CanvasPosition = Vector2.new(0, math.huge) end
                    end)
                end
                return line
            end,

            SetStatus = function(self, text, color)
                if not self._alive then return end
                statusLabel.Text = text or ""
                statusLabel.TextColor3 = color or Theme.TextDisabled
            end,

            Clear = function(self)
                if not self._alive then return end
                for _, child in ipairs(logList:GetChildren()) do
                    if child:IsA("TextLabel") or (child:IsA("Frame") and child.Name ~= "_noop") then pcall(child.Destroy, child) end
                end
            end,

            Show = function(self) if not self._alive then return end; frame.Visible = true; shadow.Visible = true; self._visible = true end,
            Hide = function(self) if not self._alive then return end; frame.Visible = false; shadow.Visible = false; self._visible = false end,
            Toggle = function(self) if self._visible then self:Hide() else self:Show() end end,
            SetTitle = function(self, t) if not self._alive then return end; titleLbl.Text = t or title end,
            Destroy = function(self) self._alive = false; if gui and gui.Parent then gui:Destroy() end end,
            BringToFront = bringToFront,
            IsPinned = function(self) return pinned end,

            GetContent = function(self)
                return content
            end,

            AddComponent = function(self, component)
                if not self._alive then return end
                if component and component._frame then
                    component._frame.Parent = content
                end
            end,

            AddContainer = function(self, container)
                if not self._alive then return end
                if container and container._frame then
                    container._frame.Parent = content
                end
            end,
        }

        local ffContent = content

        function floatingFrame:CreateSection(name, icon)
            local section = APTX:Section(name, icon, true)
            if section then
                section._frame.Parent = ffContent
                return section
            end
            return nil
        end

        function floatingFrame:CreateButton(text, icon, callback)
            return APTX:Button("Section", text, icon, callback)
        end

        function floatingFrame:CreateToggle(text, icon, default, callback)
            return APTX:Toggle("Section", text, icon, default, callback)
        end

        function floatingFrame:CreateSlider(text, icon, min, max, default, callback)
            return APTX:Slider("Section", text, icon, min, max, default, callback)
        end

        function floatingFrame:CreateMenu(text, placeholder, icon, options, default, callback)
            return APTX:Menu("Section", text, placeholder, icon, options, default, callback)
        end

        function floatingFrame:CreateInput(text, icon, placeholder, callback)
            return APTX:Input("Section", text, icon, placeholder, callback)
        end

        function floatingFrame:CreateLabel(text)
            return APTX:Label("Section", text)
        end

        function floatingFrame:CreateSeparator(text)
            return APTX:Separator("Section", text)
        end

        function floatingFrame:CreateGroupBox(title, params)
            return APTX:GroupBox("Section", title, params)
        end

        function floatingFrame:CreateProgressBar(text, icon, max, default, callback)
            return APTX:ProgressBar("Section", text, icon, max, default, callback)
        end

        function floatingFrame:CreateSpinner(text, icon)
            return APTX:Spinner("Section", text, icon)
        end

        function floatingFrame:CreateCheckbox(text, icon, default, callback)
            return APTX:Checkbox("Section", text, icon, default, callback)
        end

        function floatingFrame:CreateKeybind(text, icon, default, callback)
            return APTX:Keybind("Section", text, icon, default, callback)
        end

        function floatingFrame:CreateColorPicker(text, icon, default, callback)
            return APTX:ColorPicker("Section", text, icon, default, callback)
        end

        function floatingFrame:CreateTabContainer(title, tabs, default)
            return APTX:TabContainer("Section", title, tabs, default)
        end

        table.insert(APTX._floatingFrames, floatingFrame)
        return floatingFrame
    end)
    if not ok then
        warn("[APTX:FloatingFrame] Error: " .. tostring(result))
        return nil
    end
    return result
end

function APTX:GetFloatingFrames()
    return APTX._floatingFrames
end

function APTX:DestroyFloatingFrame(index)
    if APTX._floatingFrames[index] then
        APTX._floatingFrames[index]:Destroy()
        table.remove(APTX._floatingFrames, index)
    end
end

local function formatArgs(...)
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "string" then
            if #v > 80 then
                table.insert(parts, string.format('"%s..."', v:sub(1, 80)))
            else
                table.insert(parts, string.format('"%s"', v))
            end
        elseif t == "number" then
            table.insert(parts, tostring(v))
        elseif t == "boolean" then
            table.insert(parts, tostring(v))
        elseif t == "table" then
            local keys = {}
            for k in pairs(v) do table.insert(keys, tostring(k)) end
            table.insert(parts, string.format("{%s}", #keys > 0 and table.concat(keys, ",") or "empty"))
        elseif t == "Instance" then
            table.insert(parts, string.format("[%s: %s]", v.ClassName, v.Name))
        elseif t == "RBXScriptSignal" then
            table.insert(parts, "[Signal]")
        elseif t == "function" then
            local info = debug.getinfo(v)
            table.insert(parts, string.format("[Function: %s]", info.name or "?"))
        else
            table.insert(parts, string.format("[%s]", t))
        end
    end
    return table.concat(parts, ", ")
end

local function safeHook(func, hook)
    local ok, orig = pcall(hookfunction, func, hook)
    if ok then return orig end
    return nil
end

local function lastIndexOf(str, char)
    for i = #str, 1, -1 do
        if str:sub(i, i) == char then return i end
    end
    return nil
end

APTX.Theme = Theme
APTX.Icons = Icons
APTX.FormatArgs = formatArgs
APTX.SafeHook = safeHook
APTX.LastIndexOf = lastIndexOf

return APTX