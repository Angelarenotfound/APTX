local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Module = {}
Module._cache = {}

function Module.Load(url)
    if Module._cache[url] ~= nil then
        return Module._cache[url]
    end
    local ok, body = pcall(game.HttpGet, game, url)
    if not ok then
        warn("[Module] HTTP error:", url, body)
        Module._cache[url] = nil
        return nil
    end
    local fn, compileErr = loadstring(body)
    if not fn then
        warn("[Module] Compile error:", url, compileErr)
        Module._cache[url] = nil
        return nil
    end
    local success, result = pcall(fn)
    if not success then
        warn("[Module] Runtime error:", url, result)
        Module._cache[url] = nil
        return nil
    end
    Module._cache[url] = result
    return result
end

function Module.ClearCache()
    Module._cache = {}
end

local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/icons.lua")()
if not Icons then
    Icons = {}
    warn("[APTX] Failed to load icons module")
end

local Theme = {
    Background = Color3.fromRGB(12, 12, 12),
    Surface = Color3.fromRGB(18, 18, 18),
    Card = Color3.fromRGB(24, 24, 24),
    CardHover = Color3.fromRGB(28, 28, 28),
    Border = Color3.fromRGB(38, 38, 38),
    BorderHover = Color3.fromRGB(55, 55, 55),
    Accent = Color3.fromRGB(60, 180, 255),
    AccentDim = Color3.fromRGB(60, 180, 255),
    Success = Color3.fromRGB(0, 200, 100),
    Error = Color3.fromRGB(255, 80, 80),
    TextPrimary = Color3.fromRGB(240, 240, 240),
    TextSecondary = Color3.fromRGB(130, 130, 130),
    TextDisabled = Color3.fromRGB(65, 65, 65),
    SidebarActive = Color3.fromRGB(30, 30, 30),
    TopBar = Color3.fromRGB(15, 15, 15),
    Sidebar = Color3.fromRGB(15, 15, 15),
}

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

local TI_HOVER = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_FAST = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BACK = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_SLOW = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_LINEAR = TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)


local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function log(...)
    if APTX.DevMode then
        print("[APTX]", ...)
    end
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
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
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

local function makeCard(parent)
    local c = newF({
        Name = "Card",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
    }, parent)
    newC(c, 10)
    local s = newS(c, Theme.Border, 1)

    local innerHL = Instance.new("UIStroke")
    innerHL.Color = Color3.fromRGB(55, 55, 55)
    innerHL.Thickness = 1
    innerHL.ApplyStrokeMode = Enum.ApplyStrokeMode.Inner
    innerHL.Transparency = 0.7
    innerHL.Parent = c

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.Parent = c
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = c
    return c, s, layout
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
    local player = Players.LocalPlayer
    if not player then
        player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
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

    APTX.MainFrame = newF({
        Name = "MainFrame",
        Size = UDim2.new(0, 580, 0, 380),
        Position = UDim2.new(0.5, -290, 0.5, -190),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
    }, APTX.GUI)
    newC(APTX.MainFrame, 12)
    newS(APTX.MainFrame, Theme.Border, 1)

    local mfW, mfH = 580, 380
    local function syncShadow(s)
        s.Position = UDim2.new(0.5, APTX.MainFrame.Position.X.Offset - (s.Size.X.Offset - mfW) / 2, 0.5, APTX.MainFrame.Position.Y.Offset - (s.Size.Y.Offset - mfH) / 2)
    end

    local s1 = makeShadow(mfW, mfH, 1, 0.85)
    newC(s1, 14)
    s1.Parent = APTX.GUI
    syncShadow(s1)
    local s2 = makeShadow(mfW, mfH, 2, 0.92)
    newC(s2, 16)
    s2.Parent = APTX.GUI
    syncShadow(s2)
    local s3 = makeShadow(mfW, mfH, 3, 0.96)
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
        Size = UDim2.new(1, 0, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
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
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.TopBar,
        BorderSizePixel = 0,
    }, APTX.MainFrame)
    newC(topBar, 12)
    local clip = newF({
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.TopBar,
        BorderSizePixel = 0,
    }, topBar)
    newS(topBar, Theme.Border, 1)

    local titleContainer = newF({
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
    }, topBar)

    local title = newL({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = APTX.Title,
        TextColor3 = Theme.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleContainer)

    local subtitle = newL({
        Name = "Subtitle",
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = "by DrexusTeam",
        TextColor3 = Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleContainer)

    local btnFrame = newF({
        Name = "WindowControls",
        Size = UDim2.new(0, 108, 0, 28),
        Position = UDim2.new(1, -120, 0.5, -14),
        BackgroundTransparency = 1,
    }, topBar)

    local closeBtn = newB({
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 80, 0, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(closeBtn, 14)
    local closeX = newL({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 12,
    }, closeBtn)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 90, 90)}, TI_HOVER)
        tw(closeX, {TextColor3 = Color3.new(1, 1, 1)}, TI_HOVER)
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, TI_HOVER)
        tw(closeX, {TextColor3 = Theme.TextSecondary}, TI_HOVER)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        APTX:ToggleVisibility()
    end)

    local maxBtn = newB({
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 42, 0, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(maxBtn, 14)
    local maxBox = newL({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "□",
        TextColor3 = Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 10,
    }, maxBtn)
    maxBtn.MouseEnter:Connect(function()
        tw(maxBtn, {BackgroundColor3 = Color3.fromRGB(50, 200, 100)}, TI_HOVER)
        tw(maxBox, {TextColor3 = Color3.new(1, 1, 1)}, TI_HOVER)
    end)
    maxBtn.MouseLeave:Connect(function()
        tw(maxBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, TI_HOVER)
        tw(maxBox, {TextColor3 = Theme.TextSecondary}, TI_HOVER)
    end)

    local minBtn = newB({
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, btnFrame)
    newC(minBtn, 14)
    local minLine = newL({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "—",
        TextColor3 = Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 10,
    }, minBtn)
    minBtn.MouseEnter:Connect(function()
        tw(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 190, 50)}, TI_HOVER)
        tw(minLine, {TextColor3 = Color3.new(1, 1, 1)}, TI_HOVER)
    end)
    minBtn.MouseLeave:Connect(function()
        tw(minBtn, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, TI_HOVER)
        tw(minLine, {TextColor3 = Theme.TextSecondary}, TI_HOVER)
    end)

    APTX.TopBar = topBar
end

function APTX:CreateSidebar(parent)
    local sidebar = newF({
        Name = "Sidebar",
        Size = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
    }, parent)
    newC(sidebar, 12)
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
    scrolling.ScrollBarThickness = 2
    scrolling.ScrollBarImageColor3 = Theme.Border
    scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
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
    APTX._sidebarLayout = layout
end

function APTX:CreateContentArea(parent)
    local content = newF({
        Name = "ContentArea",
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 160, 0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, parent)
    newC(content, 12)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.Parent = content

    APTX.ContentArea = content
end

function APTX:CreateHideButton()
    local hideBtn = newB({
        Name = "HideButton",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Theme.Card,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, APTX.GUI)
    newC(hideBtn, 10)
    newS(hideBtn, Theme.Border, 1)
    newI("menu", 20, hideBtn)

    local hPos = UDim2.new(0, hideBtn.Position.X.Offset, 1, -(hideBtn.Size.Y.Offset + 12))

    local function onEnter()
        tw(hideBtn, {BackgroundColor3 = Theme.CardHover}, TI_HOVER)
        local s = hideBtn:FindFirstChildOfClass("UIStroke")
        if s then tw(s, {Color = Theme.BorderHover}, TI_HOVER) end
    end
    local function onLeave()
        tw(hideBtn, {BackgroundColor3 = Theme.Card}, TI_HOVER)
        local s = hideBtn:FindFirstChildOfClass("UIStroke")
        if s then tw(s, {Color = Theme.Border}, TI_HOVER) end
    end

    hideBtn.MouseEnter:Connect(onEnter)
    hideBtn.MouseLeave:Connect(onLeave)
    hideBtn.MouseButton1Click:Connect(function()
        APTX:ToggleVisibility()
        if APTX.IsVisible then
            tw(hideBtn, {Position = UDim2.new(0, 12, 0, 12)}, TI_SLOW)
        else
            tw(hideBtn, {Position = hPos}, TI_SLOW)
        end
    end)

    APTX.HideButton = hideBtn
end

function APTX:ToggleVisibility()
    APTX.IsVisible = not APTX.IsVisible
    local targetY = APTX.IsVisible and UDim2.new(0.5, -290, 0.5, -190) or UDim2.new(0.5, -290, 1.5, 0)
    tw(APTX.MainFrame, {Position = targetY}, TI_BOUNCE)
end

function APTX:Destroy()
    for _, conn in ipairs(APTX._connections) do
        conn:Disconnect()
    end
    APTX._connections = {}
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

    function comp:Remove()
        for _, conn in ipairs(self._connections) do
            conn:Disconnect()
        end
        self._connections = {}
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
        end
    end

    function comp:Enable()
        if not self._disabled then return end
        self._disabled = false
        if self._overlay then
            self._overlay:Destroy()
            self._overlay = nil
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
        for _, conn in ipairs(self._connections) do
            conn:Disconnect()
        end
        self._connections = {}
    end

    return comp
end

function APTX:Section(text, icon, default)
    local section = {
        Name = text,
        Icon = icon,
        Container = nil,
        Button = nil,
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
    section.Container.ScrollBarThickness = 3
    section.Container.ScrollBarImageColor3 = Theme.Border
    section.Container.Visible = false
    section.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    section.Container.Parent = APTX.ContentArea

    local compLayout = Instance.new("UIListLayout")
    compLayout.SortOrder = Enum.SortOrder.LayoutOrder
    compLayout.Padding = UDim.new(0, 6)
    compLayout.Parent = section.Container

    local sectionComp = {}
    initComponent(sectionComp, section.Container, nil)

    local layoutConn = compLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        section.Container.CanvasSize = UDim2.new(0, 0, 0, compLayout.AbsoluteContentSize.Y + 14)
    end)
    table.insert(sectionComp._connections, layoutConn)

    local currentBarStyle = false

    local function updateActive(active)
        label.TextColor3 = active and Theme.TextPrimary or Theme.TextSecondary
        if iconLabel then
            iconLabel.ImageColor3 = active and Theme.Accent or Theme.TextSecondary
        end
        if active then
            tw(accentBar, {BackgroundTransparency = 0}, TI_MED)
            tw(section.Button, {BackgroundTransparency = 0}, TI_MED)
            section.Button.BackgroundColor3 = Theme.SidebarActive
        else
            tw(accentBar, {BackgroundTransparency = 1}, TI_MED)
            tw(section.Button, {BackgroundTransparency = 1}, TI_MED)
        end
    end

    section.Button.MouseButton1Click:Connect(function()
        APTX:SelectSection(text)
    end)

    section.Button.MouseEnter:Connect(function()
        if APTX.CurrentSection ~= text then
            tw(section.Button, {BackgroundColor3 = Theme.CardHover}, TI_HOVER)
            label.TextColor3 = Theme.TextPrimary
            if iconLabel then iconLabel.ImageColor3 = Theme.TextPrimary end
        end
    end)

    section.Button.MouseLeave:Connect(function()
        if APTX.CurrentSection ~= text then
            tw(section.Button, {BackgroundTransparency = 1}, TI_HOVER)
            label.TextColor3 = Theme.TextSecondary
            if iconLabel then iconLabel.ImageColor3 = Theme.TextSecondary end
        end
    end)

    table.insert(APTX.Sections, section)

    if default == true or #APTX.Sections == 1 then
        APTX:SelectSection(text)
    end

    function sectionComp:Remove()
        for _, conn in ipairs(sectionComp._connections) do
            conn:Disconnect()
        end
        sectionComp._connections = {}
        if section.Button and section.Button.Parent then
            section.Button:Destroy()
        end
        if section.Container and section.Container.Parent then
            section.Container:Destroy()
        end
        sectionComp._frame = nil
        sectionComp._section = nil
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
            if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ScrollingFrame") then
                table.insert(toRemove, child)
            end
        end
        for _, child in ipairs(toRemove) do
            child:Destroy()
        end
    end

    return sectionComp
end

function APTX:SelectSection(name)
    for _, section in ipairs(APTX.Sections) do
        if section.Name == name then
            section.Container.Visible = true
            local lbl = section.Button:FindFirstChild("Layout", true)
            if not lbl then
                local lbl2 = section.Button:FindFirstChild("Label", true)
                if lbl2 then lbl2.TextColor3 = Theme.TextPrimary end
            end
            section.Button.BackgroundColor3 = Theme.SidebarActive
            section.Button.BackgroundTransparency = 0
            local bar = section.Button:FindFirstChild("AccentBar")
            if bar then tw(bar, {BackgroundTransparency = 0}, TI_MED) end
            local iconImg = section.Button:FindFirstChild("Icon", true)
            if iconImg then iconImg.ImageColor3 = Theme.Accent end
            local lbl2 = section.Button:FindFirstChild("Label", true)
            if lbl2 then lbl2.TextColor3 = Theme.TextPrimary end
            APTX.CurrentSection = name
        else
            task.delay(0.1, function()
                if section.Container then section.Container.Visible = false end
            end)
            section.Button.BackgroundTransparency = 1
            local bar = section.Button:FindFirstChild("AccentBar")
            if bar then tw(bar, {BackgroundTransparency = 1}, TI_MED) end
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

    local section = APTX:GetSection(sectionName)
    if not section then
        log("ERROR: Section not found:", sectionName)
        return
    end

    local card, stroke, layout = makeCard(section.Container)
    card.Size = UDim2.new(1, 0, 0, 44)

    local iconImg
    if icon then
        iconImg = newI(icon, 16, card)
        iconImg.Position = UDim2.new(0, 0, 0.5, -8)
    end

    local label = newL({
        Name = "Label",
        Size = UDim2.new(1, icon and -72 or -50, 1, 0),
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

    local    initHover(comp, card, stroke)

    card.MouseButton1Click:Connect(function()
        if comp._disabled then return end
        local ts = TweenService:Create(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Accent})
        ts:Play()
        ts.Completed:Connect(function()
            tw(card, {BackgroundColor3 = Theme.Card}, TI_BACK)
        end)
        local pt = TweenService:Create(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 42)})
        pt:Play()
        pt.Completed:Connect(function()
            tw(card, {Size = UDim2.new(1, 0, 0, 44)}, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        end)
        if cb then cb() end
    end)

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
end

function APTX:Toggle(sectionName, text, icon, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then
        log("ERROR: Section not found:", sectionName)
        return
    end

    local isOn = default == true
    local debounce = false

    local card, stroke, layout = makeCard(section.Container)
    card.Size = UDim2.new(1, 0, 0, 44)

    local iconImg
    if icon then
        iconImg = newI(icon, 16, card)
    end

    local label = newL({
        Name = "Label",
        Size = UDim2.new(1, -72, 1, 0),
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
        Position = UDim2.new(1, -44, 0.5, -12),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, card)
    newC(track, 12)

    local knob = newF({
        Name = "Knob",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 2, 0.5, -10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, track)
    newC(knob, 10)

    local comp = {}
    local cb = callback
    initComponent(comp, card, section)

    local    initHover(comp, card, stroke)

    local function setToggleState(state, instant)
        isOn = state
        local kPos = isOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        local tColor = isOn and Theme.Success or Color3.fromRGB(40, 40, 40)
        if instant then
            knob.Position = kPos
            track.BackgroundColor3 = tColor
        else
            tw(knob, {Position = kPos}, TI_MED)
            tw(track, {BackgroundColor3 = tColor}, TI_MED)
        end
    end

    if isOn then
        setToggleState(true, true)
    end

    track.MouseButton1Click:Connect(function()
        if comp._disabled then return end
        if debounce then return end
        debounce = true
        setToggleState(not isOn)
        if cb then cb(isOn) end
        task.delay(0.1, function()
            debounce = false
        end)
    end)

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
end

function APTX:Slider(sectionName, text, icon, min, max, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then
        log("ERROR: Section not found:", sectionName)
        return
    end

    if max == min then
        max = min + 1
        log("WARNING: Slider min==max, adjusted max to", max)
    end

    local value = default or min

    local card, stroke, layout = makeCard(section.Container)
    card.Size = UDim2.new(1, 0, 0, 56)
    layout:Destroy()
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = card

    local topRow = newF({
        Size = UDim2.new(1, 0, 0, 18),
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

    local track = newF({
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = Color3.fromRGB(38, 38, 38),
        BorderSizePixel = 0,
    }, card)
    newC(track, 3)

    local fill = newF({
        Name = "Fill",
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, track)
    newC(fill, 3)

    local knob = newF({
        Name = "Knob",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new((value - min) / (max - min), -9, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, track)
    newC(knob, 9)

    local comp = {}
    local cb = callback
    initComponent(comp, card, section)

    local    initHover(comp, card, stroke)
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

    track.InputBegan:Connect(function(input)
        if comp._disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
            tw(knob, {Size = UDim2.new(0, 22, 0, 22)}, TI_HOVER)
        end
    end)

    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            tw(knob, {Size = UDim2.new(0, 18, 0, 18)}, TI_HOVER)
        end
    end)

    local uisConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    table.insert(comp._connections, uisConn)

    function comp:Edit(params)
        params = params or {}
        if params.text then label.Text = params.text end
        if params.min ~= nil then min = params.min end
        if params.max ~= nil then
            max = params.max
            if max == min then max = min + 1 end
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
end

function APTX:Menu(sectionName, text, placeholder, icon, options, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then
        log("ERROR: Section not found:", sectionName)
        return
    end

    local isOpen = false
    local selected = default or options[1]
    local currentOptions = {}
    for _, v in ipairs(options) do table.insert(currentOptions, v) end

    local card, stroke, layout = makeCard(section.Container)
    card.Size = UDim2.new(1, 0, 0, 44)
    card.ClipsDescendants = true
    layout:Destroy()
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = card

    local topRow = newF({
        Size = UDim2.new(1, 0, 0, 44),
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
        Position = UDim2.new(0, 0, 0, 44),
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
    local function closeOutsideClick(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isOpen then
                local pos = input.Position
                local absPos = card.AbsolutePosition
                local absSize = card.AbsoluteSize
                if pos.X < absPos.X or pos.X > absPos.X + absSize.X or pos.Y < absPos.Y or pos.Y > absPos.Y + absSize.Y then
                    isOpen = false
                    tw(card, {Size = UDim2.new(1, 0, 0, 44)}, TI_MED)
                    tw(optionsList, {Size = UDim2.new(1, 0, 0, 0)}, TI_MED)
                    tw(chevron, {Rotation = 0}, TI_MED)
                end
            end
        end
    end

    local function rebuildOptions()
        for _, btn in ipairs(optionBtns) do
            if btn._parent then btn:Destroy() end
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

            local divider = newF({
                Size = UDim2.new(1, -12, 0, 1),
                Position = UDim2.new(0, 6, 0, 0),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
            }, ob)

            local optLabel = newL({
                Size = UDim2.new(1, -36, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = opt,
                TextColor3 = opt == selected and Theme.Accent or Theme.TextSecondary,
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
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
            }, ob)

            ob.MouseEnter:Connect(function()
                tw(ob, {BackgroundColor3 = Color3.fromRGB(32, 32, 32)}, TI_HOVER)
            end)
            ob.MouseLeave:Connect(function()
                tw(ob, {BackgroundColor3 = Color3.new(0, 0, 0)}, TI_HOVER)
                tw(ob, {BackgroundTransparency = 1}, TI_HOVER)
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
                tw(card, {Size = UDim2.new(1, 0, 0, 44)}, TI_MED)
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
        local cardH = isOpen and (44 + listH) or 44
        tw(card, {Size = UDim2.new(1, 0, 0, cardH)}, TI_MED)
        tw(optionsList, {Size = UDim2.new(1, 0, 0, listH)}, TI_MED)
        tw(chevron, {Rotation = isOpen and 180 or 0}, TI_MED)
    end)

    local outsideConn = UserInputService.InputBegan:Connect(closeOutsideClick)
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
                tw(card, {Size = UDim2.new(1, 0, 0, 44)}, TI_MED)
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
end

function APTX:Input(sectionName, text, icon, placeholder, callback)
    local section = APTX:GetSection(sectionName)
    if not section then
        log("ERROR: Section not found:", sectionName)
        return
    end

    local card, stroke, layout = makeCard(section.Container)
    card.Size = UDim2.new(1, 0, 0, 56)
    layout:Destroy()
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent = card

    local topRow = newF({
        Size = UDim2.new(1, 0, 0, 18),
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
    inputBox.Size = UDim2.new(1, 0, 0, 26)
    inputBox.Position = UDim2.new(0, 0, 1, -26)
    inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
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

    local    initHover(comp, card, stroke)

    inputBox.Focused:Connect(function()
        tw(inputStroke, {Color = Theme.Accent}, TI_HOVER)
    end)

    inputBox.FocusLost:Connect(function(enterPressed)
        tw(inputStroke, {Color = Theme.Border}, TI_HOVER)
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
end

function APTX:Label(sectionName, text)
    local section = APTX:GetSection(sectionName)
    if not section then
        log("ERROR: Section not found:", sectionName)
        return
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
            TextColor3 = Theme.TextSecondary,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
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
end

local NOTIF_Z_BASE = 1000

local NotifStack = {}
local NOTIF_GAP = 6
local NOTIF_RIGHT_MARGIN = 2
local notifCounter = 0

local function repositionStack()
    local bottomOffset = NOTIF_RIGHT_MARGIN
    local visible = {}
    for _, entry in ipairs(NotifStack) do
        if entry and entry._alive and entry._card and entry._card.Parent then
            table.insert(visible, entry)
        end
    end
    local maxVisible = math.min(#visible, 4)
    for idx = #visible, 1, -1 do
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
    for i = #NotifStack, 1, -1 do
        if NotifStack[i] == notif then
            table.remove(NotifStack, i)
            break
        end
    end
    repositionStack()
end

function APTX:Notify(params)
    assert(type(params) == "table", "[APTX:Notify] params debe ser una tabla")
    assert(params.title, "[APTX:Notify] params.title es requerido")
    assert(params.content, "[APTX:Notify] params.content es requerido")

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
    local CARD_H = sTOPBAR + sBODY + (hasBtns and (sBTN_H + 8) or 8) + 2

    local accentColors = {
        info = Theme.Accent,
        success = Theme.Success,
        error = Theme.Error,
        neutral = Theme.Accent,
    }

    assert(APTX.GUI, "[APTX:Notify] Llama APTX:Config() antes de usar Notify")
    local gui = APTX.GUI

    notifCounter = notifCounter + 1

    local Card = newF({
        Name = "NotifCard_" .. notifCounter,
        Size = UDim2.new(0, sW, 0, CARD_H),
        Position = UDim2.new(1, sW + 20, 1, -CARD_H),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = NOTIF_Z_BASE,
    }, gui)
    newC(Card, 12)
    local cardStroke = newS(Card, Theme.Border, 1)

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
        _cardH = CARD_H,
        _cardW = sW,
        _autoCloseThread = nil,
    }

    Card.Destroying:Connect(function()
        removeFromStack(Notif)
    end)

    table.insert(NotifStack, Notif)

    local function fallClose(cb)
        if not Notif._alive then return end
        Notif._alive = false

        if Notif._autoCloseThread then
            task.cancel(Notif._autoCloseThread)
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
                Position = UDim2.new(1, sW + 80, cur.Y.Scale, cur.Y.Offset + math.floor(CARD_H * 0.55)),
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
                task.cancel(self._autoCloseThread)
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
        local orig = self._card.Position
        for _, ox in ipairs({8, -8, 6, -6, 3, -3, 0}) do
            tw(self._card, {Position = UDim2.new(orig.X.Scale, orig.X.Offset + ox, orig.Y.Scale, orig.Y.Offset)}, TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            task.wait(0.045)
        end
        self._card.Position = orig
    end

    return Notif
end

return APTX
