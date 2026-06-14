local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Debris = game:GetService("Debris")

local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/icons.lua"))() or {}

local Theme = {
    -- Xerion Design System — Monochrome / Silver
    Background = Color3.fromRGB(0, 0, 0),           -- #000000
    Surface = Color3.fromRGB(7, 7, 7),               -- #070707
    Card = Color3.fromRGB(15, 15, 15),               -- #0f0f0f
    CardHover = Color3.fromRGB(20, 20, 20),
    Border = Color3.fromRGB(25, 25, 25),             -- rgba(192,192,192,0.10)
    BorderHover = Color3.fromRGB(56, 56, 56),        -- rgba(255,255,255,0.22)
    Accent = Color3.fromRGB(192, 192, 192),          -- Silver brand-mid #c0c0c0
    Success = Color3.fromRGB(34, 197, 94),           -- #22c55e
    Warning = Color3.fromRGB(245, 158, 11),          -- #f59e0b
    Error = Color3.fromRGB(239, 68, 68),             -- #ef4444
    TextPrimary = Color3.fromRGB(237, 237, 237),     -- rgba(255,255,255,0.93)
    TextSecondary = Color3.fromRGB(128, 128, 128),   -- rgba(255,255,255,0.50)
    TextDisabled = Color3.fromRGB(46, 46, 46),       -- rgba(255,255,255,0.18)
    SidebarActive = Color3.fromRGB(10, 10, 10),
    TopBar = Color3.fromRGB(5, 5, 5),
    Sidebar = Color3.fromRGB(3, 3, 3),
    BrandLo = Color3.fromRGB(85, 85, 85),            -- #555555
    BrandMid = Color3.fromRGB(192, 192, 192),        -- #c0c0c0
    BrandHi = Color3.fromRGB(242, 242, 242),         -- #f2f2f2
}

-- Weak table to register component references (avoids setting arbitrary properties on Roblox instances)
local CompRegistry = setmetatable({}, { __mode = "k" })

-- Dimension constants (Xerion Design System)
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
APTX._lastVisiblePos = nil  -- FIX #2b: track last visible position for restore after hide

-- Reference resolution for scaling
local REF_W = 1920
local REF_H = 1080

local TI_HOVER = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_FAST = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BACK = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_SLOW = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)


--- Helpers

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function log(...)
    if APTX.DevMode then
        print("[APTX]", ...)
    end
end

-- Safe no-op proxy returned when a component fails to create.
-- Prevents "attempt to index nil with 'Edit'/'Disable'/etc." errors in user scripts
-- that call methods on the returned component without checking for nil.
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
    -- FIX #3: Use a dark semi-transparent overlay (not white). The black at 0.5
    -- transparency creates a proper disabled dimming effect.
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

--- Unified click handler for Frames (InputBegan, supports mouse + touch)
local function connectClick(frame, fn)
    return frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            fn()
        end
    end)
end

--- Card creation — Xerion-style: returns card frame, border stroke, and layout
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

    -- Inner highlight stroke — Border mode only, never Contextual (avoids whitening child elements)
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

--- Initialize the UIScale system for responsive design
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

--- Public API

function APTX:Config(title, draggable, devmode)
    APTX.Title = title or "APTX GUI"
    APTX.Draggable = draggable ~= false
    APTX.DevMode = devmode == true
    log("Inicializando APTX GUI...")
    APTX:CreateGUI()
    APTX:CreateHideButton()
    log("GUI creado exitosamente")
    return APTX
end

function APTX:CreateGUI()
    -- Clean up old connections before re-initializing
    for _, conn in ipairs(APTX._connections) do
        conn:Disconnect()
    end
    APTX._connections = {}

    -- FIX #1: Destroy old shadow instances so their Position signals don't fire
    -- against nil references after GUI is recreated (was causing "attempt to index nil with 'Edit'")
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

    -- Responsive scaling
    initResponsive()

    -- Detect mobile and adjust MainFrame size
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

    -- Xerion ambient glow (top-center radial glow)
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

    -- Xerion multi-layered shadows (more dramatic)
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
    -- Xerion Navigation Bar — pure black, subtle border, silver typography
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

    -- Title with Xerion silver aesthetic
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

    -- Window controls — Xerion style: subtle silver on hover
    local btnFrame = newF({
        Name = "WindowControls",
        Size = UDim2.new(0, 96, 0, BTN_H),
        Position = UDim2.new(1, -108, 0.5, -BTN_H/2),
        BackgroundTransparency = 1,
    }, topBar)
    -- Use a layout so buttons never overlap regardless of size changes
    do
        local bl = Instance.new("UIListLayout")
        bl.FillDirection = Enum.FillDirection.Horizontal
        bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
        bl.VerticalAlignment = Enum.VerticalAlignment.Center
        bl.Padding = UDim.new(0, 4)
        bl.Parent = btnFrame
    end

    -- Minimize button
    local minBtn = newB({
        Name = "MinBtn",
        Size = UDim2.new(0, BTN_H, 0, BTN_H),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(minBtn, 14)
    local minLine = newL({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "—",
        TextColor3 = Color3.fromRGB(80, 80, 80),
        Font = Enum.Font.Gotham,
        TextSize = 10,
    }, minBtn)
    minBtn.MouseEnter:Connect(function()
        tw(minBtn, {BackgroundColor3 = Theme.Warning}, TI_HOVER)
        tw(minLine, {TextColor3 = Color3.new(1,1,1)}, TI_HOVER)
    end)
    minBtn.MouseLeave:Connect(function()
        tw(minBtn, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, TI_HOVER)
        tw(minLine, {TextColor3 = Color3.fromRGB(80, 80, 80)}, TI_HOVER)
    end)

    -- Maximize button
    local maxBtn = newB({
        Name = "MaxBtn",
        Size = UDim2.new(0, BTN_H, 0, BTN_H),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(maxBtn, 14)
    local maxBox = newL({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "□",
        TextColor3 = Color3.fromRGB(80, 80, 80),
        Font = Enum.Font.Gotham,
        TextSize = 10,
    }, maxBtn)
    maxBtn.MouseEnter:Connect(function()
        tw(maxBtn, {BackgroundColor3 = Theme.Success}, TI_HOVER)
        tw(maxBox, {TextColor3 = Color3.new(1,1,1)}, TI_HOVER)
    end)
    maxBtn.MouseLeave:Connect(function()
        tw(maxBtn, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, TI_HOVER)
        tw(maxBox, {TextColor3 = Color3.fromRGB(80, 80, 80)}, TI_HOVER)
    end)

    -- Close button
    local closeBtn = newB({
        Name = "CloseBtn",
        Size = UDim2.new(0, BTN_H, 0, BTN_H),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(closeBtn, 14)
    local closeX = newL({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = Color3.fromRGB(80, 80, 80),
        Font = Enum.Font.Gotham,
        TextSize = 12,
    }, closeBtn)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, {BackgroundColor3 = Theme.Error}, TI_HOVER)
        tw(closeX, {TextColor3 = Color3.new(1,1,1)}, TI_HOVER)
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, TI_HOVER)
        tw(closeX, {TextColor3 = Color3.fromRGB(80, 80, 80)}, TI_HOVER)
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
    -- Xerion-style right divider: subtle silver line
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
    scrolling.ScrollBarThickness = 3
    scrolling.ScrollBarImageColor3 = Theme.BrandLo
    scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrolling.ScrollBarImageTransparency = 0.6
    scrolling.ElasticBehavior = Enum.ElasticBehavior.Always
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
    -- No UIPadding here — sections manage their own padding internally
    APTX.ContentArea = content
end

function APTX:CreateHideButton()
    local hideBtn = newB({
        Name = "HideButton",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, APTX.GUI)
    newC(hideBtn, 10)
    newS(hideBtn, Theme.Border, 1)
    local hideIcon = newI("menu", 20, hideBtn)
    hideIcon.ImageColor3 = Theme.BrandLo

    local function onEnter()
        tw(hideBtn, {BackgroundColor3 = Theme.CardHover}, TI_HOVER)
        local s = hideBtn:FindFirstChildOfClass("UIStroke")
        if s then tw(s, {Color = Theme.BorderHover}, TI_HOVER) end
        tw(hideIcon, {ImageColor3 = Theme.BrandMid}, TI_HOVER)
    end
    local function onLeave()
        tw(hideBtn, {BackgroundColor3 = Color3.fromRGB(10, 10, 10)}, TI_HOVER)
        local s = hideBtn:FindFirstChildOfClass("UIStroke")
        if s then tw(s, {Color = Theme.Border}, TI_HOVER) end
        tw(hideIcon, {ImageColor3 = Theme.BrandLo}, TI_HOVER)
    end

    hideBtn.MouseEnter:Connect(onEnter)
    hideBtn.MouseLeave:Connect(onLeave)
    hideBtn.MouseButton1Click:Connect(function()
        -- FIX #6: position update is now handled inside ToggleVisibility so all callers stay in sync
        APTX:ToggleVisibility()
    end)

    APTX.HideButton = hideBtn
end

function APTX:ToggleVisibility()
    APTX.IsVisible = not APTX.IsVisible

    if APTX.IsVisible then
        -- Restore last dragged position instead of hardcoded offset
        -- FIX #2a: use saved position so drag is preserved after hide/show
        local restorePos = APTX._lastVisiblePos or UDim2.new(0.5, -(APTX.MainFrame.Size.X.Offset / 2), 0.5, -(APTX.MainFrame.Size.Y.Offset / 2))
        for _, s in ipairs({APTX.Shadow1, APTX.Shadow2, APTX.Shadow3}) do
            if s then s.Visible = true end
        end
        tw(APTX.MainFrame, {Position = restorePos}, TI_BOUNCE)
    else
        -- Save current position before hiding
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

    -- FIX #6: Update HideButton position here so ALL callers keep it in sync
    if APTX.HideButton then
        if APTX.IsVisible then
            tw(APTX.HideButton, {Position = UDim2.new(0, 12, 0, 12)}, TI_SLOW)
        else
            tw(APTX.HideButton, {Position = UDim2.new(0, 12, 1, -(APTX.HideButton.Size.Y.Offset + 12))}, TI_SLOW)
        end
    end
end

function APTX:Destroy()
    -- Clean up ALL component connections (section-level + per-component)
    for _, section in ipairs(APTX.Sections) do
        -- Section-level connections
        if section._compRef and section._compRef._connections then
            for _, conn in ipairs(section._compRef._connections) do
                conn:Disconnect()
            end
            section._compRef._connections = {}
        end
        -- Per-component connections (Sliders: UIS.InputChanged, Menus: UIS.InputBegan, etc.)
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

    -- Clean up main connections
    for _, conn in ipairs(APTX._connections) do
        conn:Disconnect()
    end
    APTX._connections = {}

    -- Cancel any pending section hide delays
    for _, threadId in pairs(APTX._sectionHideDelays) do
        pcall(task.cancel, threadId)
    end
    APTX._sectionHideDelays = {}

    -- Clear notification stack
    APTX._notifStack = {}

    APTX.Sections = {}
    APTX.CurrentSection = nil
    if APTX.GUI then
        APTX.GUI:Destroy()
        APTX.GUI = nil
    end
end

--- Component initialization

local function initComponent(comp, frame, sectionRef)
    comp._frame = frame
    comp._disabled = false
    comp._overlay = nil
    comp._section = sectionRef
    comp._connections = {}
    comp._tooltipObj = nil
    comp._tooltipCons = nil
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
            -- Disable scrolling on ScrollingFrame to prevent bypass
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
            -- Re-enable scrolling
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

        -- FIX #8: Assign tooltipObj immediately so comp:Remove() can always destroy
        -- the tooltip instance, even if called during the show-delay window.
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
        -- FIX #8b: _tooltipObj already assigned above at creation time (not here at the end)
    end

    return comp
end

--- Animate cards entering a section for the first time
-- Uses pure fade-in (positions are managed by UIListLayout)
local TI_ENTRY_FADE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function animEntry(container)
    if not container then return end
    -- Collect all non-layout children
    local cards = {}
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding")
            and not child:IsA("UIGridLayout") and child.Name ~= "_EmptyPlaceholder" then
            table.insert(cards, child)
        end
    end
    -- Animate each with staggered delay
    for idx, card in ipairs(cards) do
        local stagger = (idx - 1) * 0.04

        if card:IsA("TextLabel") then
            -- Labels: only fade text, never touch background
            card.TextTransparency = 1
            task.delay(stagger, function()
                local ok, err = pcall(function()
                    if not card or not card.Parent or card.Parent ~= container then return end
                    tw(card, {TextTransparency = 0}, TI_ENTRY_FADE)
                end)
                if not ok and APTX.DevMode then warn("[APTX] animEntry error:", err) end
            end)

        elseif card:IsA("Frame") then
            -- Top-level card frames: snapshot original transparency and fade in from invisible
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
                            -- IMPORTANT: only animate text, never override BackgroundTransparency.
                            -- Many buttons (dropBtn, overlayBtn) are intentionally fully transparent (=1).
                            -- Fading their background to 0 makes them render as white opaque blocks.
                            child.TextTransparency = 1
                            tw(child, {TextTransparency = 0}, TI_ENTRY_FADE)
                            -- Only fade background if it was already meant to be visible (< 0.9)
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
                            -- Only fade sub-frames that are visible (not overlays already at 0.5+)
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
            -- ScrollingFrame and other non-Frame/non-Label: just appear
            card.Visible = true
        end
    end
end

--- Section

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

        -- Xerion silver accent bar (left border indicator)
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

        -- Xerion label — silver muted by default, bright on active
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
        section.Container.ScrollBarThickness = 3
        section.Container.ScrollBarImageColor3 = Theme.Border
        section.Container.ScrollBarImageTransparency = 0.5
        section.Container.ElasticBehavior = Enum.ElasticBehavior.Always
        section.Container.Visible = false
        section.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
        section.Container.Parent = APTX.ContentArea

        local compLayout = Instance.new("UIListLayout")
        compLayout.SortOrder = Enum.SortOrder.LayoutOrder
        compLayout.Padding = UDim.new(0, 6)
        compLayout.Parent = section.Container

        -- Top/bottom padding inside the section scroll area
        local sectionPad = Instance.new("UIPadding")
        sectionPad.PaddingTop = UDim.new(0, 6)
        sectionPad.PaddingBottom = UDim.new(0, 8)
        sectionPad.Parent = section.Container

        -- Empty state placeholder label
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
            -- +14 accounts for 6px PaddingTop + 8px PaddingBottom from sectionPad
            section.Container.CanvasSize = UDim2.new(0, 0, 0, compLayout.AbsoluteContentSize.Y + 14)
        end

        local layoutConn = compLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
        table.insert(sectionComp._connections, layoutConn)

        -- Track button connections so they can be cleaned up
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
                -- Clean up all CompRegistry entries for children and container
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
                -- Skip layout, padding, and empty placeholder; remove everything else
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
            -- Activate this section immediately
            section.Container.Visible = true
            -- Animate entry on first open
            if not section._entered then
                section._entered = true
                animEntry(section.Container)
            end

            -- Xerion active state: dark active bg + silver accent bar + bright text
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
            -- Hide inactive sections immediately (no delay)
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

--- Button component

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
        -- Keep the UIListLayout from makeCard — it handles icon + label alignment automatically

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

        -- Track tweens and their connections for proper cleanup
        comp._tweens = {}

        local clickConn = connectClick(card, function()
            if comp._disabled then return end

            -- Cancel previous pending tweens to prevent overlap
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
        table.insert(comp._connections, clickConn)

        function comp:Edit(params)
            params = params or {}
            if params.text then
                card.Name = params.text
                label.Text = params.text
            end
            if params.callback then
                cb = params.callback
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

--- Toggle component

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
        -- Keep UIListLayout from makeCard for icon + label

        local iconImg
        if icon then
            iconImg = newI(icon, 16, card)
            iconImg.LayoutOrder = 1
        end

        local label = newL({
            Name = "Label",
            -- Fill all horizontal space except the track (48px)
            Size = UDim2.new(1, -(icon and 16+8 or 0) - 52, 1, 0),
            LayoutOrder = 2,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        -- Track placed absolutely at right edge; UIListLayout handles left content
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
        -- Xerion silver border on track
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
            -- Xerion silver toggle: white when on, dark when off
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

        -- FIX #5: Removed connectClick(card, toggleAction) to prevent double-firing.
        -- Clicking the track already bubbles correctly; adding a second InputBegan on
        -- the parent card caused the toggle to fire twice (especially with Touch input).
        -- The card hover area still works visually via initHover.

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

--- Slider component

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

        local card, stroke, layout = makeCard(section.Container)
        card.Size = UDim2.new(1, 0, 0, 58)
        layout:Destroy()

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, PAD_SM)
        pad.PaddingRight = UDim.new(0, PAD_SM)
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.Parent = card

        -- Top row: icon + label + value. Height=18, anchored to top of padded area
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

        -- Track: 6px tall, positioned 8px below topRow (18+8=26px from padded top)
        local track = newF({
            Name = "Track",
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 26),
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            BorderSizePixel = 0,
            Active = true,
        }, card)
        newC(track, 3)
        -- Xerion silver border on track
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
        -- Xerion silver border on knob
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
            value = math.floor(min + (max - min) * pos + 0.5)
            valueLabel.Text = tostring(value)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -9, 0.5, -9)
            if cb then cb(value) end
        end

        -- Track these connections so they can be cleaned up
        local ibConn = track.InputBegan:Connect(function(input)
            if comp._disabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input)
                tw(knob, {Size = UDim2.new(0, 22, 0, 22)}, TI_HOVER)
            end
        end)
        table.insert(comp._connections, ibConn)

        local ieConn = track.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
            local minChanged = params.min ~= nil
            local maxChanged = params.max ~= nil
            if minChanged then min = params.min end
            if maxChanged then
                max = params.max
                if max == min then max = min + 1 end
            end
            -- Re-clamp value after min/max changes
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

--- Menu component

function APTX:Menu(sectionName, text, placeholder, icon, options, default, callback)
    local ok, result = pcall(function()
        local section = APTX:GetSection(sectionName)
        if not section then
            error("Section not found: " .. tostring(sectionName))
        end

        -- Validate options before any UI is created
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

        -- topRow fills the header portion only (CARD_H height, not the whole expanding card)
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
                    -- FIX #4: Use AbsolutePosition/Size which already account for scroll offset and UIScale
                    -- These are updated by Roblox in real time regardless of ScrollingFrame position
                    local pos = input.Position
                    local absPos = card.AbsolutePosition
                    local absSize = card.AbsoluteSize
                    local scale = APTX._scale or 1
                    -- Expand hit area by the full open height so clicks inside the dropdown list don't close it
                    local expandedH = absSize.Y + (#currentOptions * 37 * scale)
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
            end
            if params.callback then cb = params.callback end
        end

        function comp:GetValue()
            return selected
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

--- Input component

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

        -- Label row: 18px tall, at top of padded area
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

        -- InputBox: 22px tall, 4px below topRow (18+4=22px from padded top)
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

--- Label component

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

--- Notification system

local NOTIF_Z_BASE = 1000

APTX._notifStack = {}
local NOTIF_GAP = 6
local NOTIF_RIGHT_MARGIN = 2
local notifCounter = 0

local function repositionStack()
    -- First clean up dead entries from the stack
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

    -- Close the OLDEST notifications first (lower indices = older)
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
        -- FIX #9: Run all assertions BEFORE any side effects so notifCounter
        -- doesn't increment on a failed call
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

        -- FIX #11: Create notifications in a separate ScreenGui that is NOT under UIScale.
        -- If Card lived under APTX.GUI, the UIScale would scale pixel offsets making
        -- notifications fly off-screen on mobile. A dedicated gui bypasses this entirely.
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
            -- FIX #11c: Clean up the dedicated notif ScreenGui when its card is gone
            if notifGui and notifGui.Parent then
                notifGui:Destroy()
            end
        end)

        table.insert(APTX._notifStack, Notif)

        local function fallClose(cb)
            if not Notif._alive then return end
            Notif._alive = false

            if Notif._autoCloseThread then
                -- FIX: task.cancel throws if the thread already finished; pcall prevents the crash
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

APTX.Icons = Icons

return APTX
