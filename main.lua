--[[
APTX LIB load: local APTX = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/main.lua"))()
]]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/icons.lua"))() or {}

local CONFIG_URL = "https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/config.lua"
local ConfigMod = nil
do
    local ok, mod = pcall(function() return loadstring(game:HttpGet(CONFIG_URL))() end)
    if ok and type(mod) == "table" and type(mod.Init) == "function" then ConfigMod = mod end
end

-- ═══════════════════════════════════════════════════════════════
--  THEME v2  —  paleta premium (mono "XERION" + acento frío)
-- ═══════════════════════════════════════════════════════════════
local Theme = {
Background    = Color3.fromRGB(8, 8, 10),
Surface       = Color3.fromRGB(14, 14, 17),
Card          = Color3.fromRGB(22, 22, 26),
CardHover     = Color3.fromRGB(31, 31, 37),
Border        = Color3.fromRGB(44, 44, 52),
BorderHover   = Color3.fromRGB(78, 78, 90),
Highlight     = Color3.fromRGB(255, 255, 255),   -- luz cenital
Accent        = Color3.fromRGB(228, 228, 234),
AccentTint    = Color3.fromRGB(150, 172, 214),   -- color de marca
Glow          = Color3.fromRGB(150, 172, 214),
Success       = Color3.fromRGB(46, 204, 113),
Warning       = Color3.fromRGB(245, 170, 40),
Error         = Color3.fromRGB(240, 82, 82),
TextPrimary   = Color3.fromRGB(240, 240, 244),
TextSecondary = Color3.fromRGB(152, 152, 162),
TextDisabled  = Color3.fromRGB(74, 74, 82),
SidebarActive = Color3.fromRGB(26, 26, 31),
TopBar        = Color3.fromRGB(12, 12, 15),
Sidebar       = Color3.fromRGB(10, 10, 12),
BrandLo       = Color3.fromRGB(96, 96, 104),
BrandMid      = Color3.fromRGB(196, 196, 204),
BrandHi       = Color3.fromRGB(244, 244, 248),
FloatingBg    = Color3.fromRGB(10, 10, 13),
FloatingBorder= Color3.fromRGB(40, 40, 48),
LogDefault    = Color3.fromRGB(186, 186, 194),
LogRemote     = Color3.fromRGB(110, 184, 255),
LogInvoke     = Color3.fromRGB(255, 184, 110),
LogEvent      = Color3.fromRGB(110, 240, 160),
LogWarning    = Color3.fromRGB(255, 204, 92),
LogError      = Color3.fromRGB(255, 96, 96),
LogSuccess    = Color3.fromRGB(96, 240, 132),
LogInfo       = Color3.fromRGB(110, 184, 255),
}

local CompRegistry = setmetatable({}, { __mode = "k" })

local TOP_BAR_H = 44
local HEADER_H  = 50
local CARD_H    = 44
local SIDEBAR_W = 168
local PAD_SM    = 12
local PAD_MD    = 14
local CORNER_R  = 12
local BTN_H     = 28

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
APTX._recording = false
APTX._sectionHideDelays = {}
APTX._lastVisiblePos = nil
APTX._floatingFrames = {}
APTX._notifStack = {}

local REF_W = 1920
local REF_H = 1080

local TI_HOVER  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED    = TweenInfo.new(0.2,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_FAST   = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BACK   = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_SLOW   = TweenInfo.new(0.3,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.3,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function log(...)
if APTX.DevMode then print("[APTX]", ...) end
end

-- ── Fallback de iconos: glifos unicode seguros cuando el asset falta ──
local ICON_GLYPH = {
settings = "⚙", gear = "⚙", star = "★", zap = "⚡",
heart = "♥", check = "✓", x = "✕", alert = "!",
}

local function fallbackGlyph(name)
if type(name) == "string" then
local g = ICON_GLYPH[name:lower()]
if g then return g end
end
return "●"
end

local function setIconColor(o, c)
if not o then return end
if o:IsA("ImageLabel") then
o.ImageColor3 = c
elseif o:IsA("TextLabel") then
o.TextColor3 = c
end
end

local function makeNilProxy(tag)
local proxy = {}
setmetatable(proxy, {
__index = function(_, key)
return function(...)
if APTX.DevMode then
warn("[APTX] Called '" .. tostring(key) .. "' on a failed component (" .. tostring(tag) .. ").")
end
end
end,
__newindex = function() end,
})
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

-- newI: ImageLabel si el asset existe; si no, TextLabel con glifo (nunca hueco roto)
local function newI(iconName, size, parent)
local sz = size or 16
local asset = iconName and Icons[iconName]
if asset and asset ~= "" then
local img = Instance.new("ImageLabel")
img.Name = "Icon"
img.Size = UDim2.new(0, sz, 0, sz)
img.BackgroundTransparency = 1
img.ImageColor3 = Theme.TextPrimary
img.Image = asset
img.Parent = parent
return img
else
local t = Instance.new("TextLabel")
t.Name = "Icon"
t.Size = UDim2.new(0, sz, 0, sz)
t.BackgroundTransparency = 1
t.Text = fallbackGlyph(iconName)
t.TextColor3 = Theme.TextPrimary
t.Font = Enum.Font.GothamBold
t.TextSize = math.max(8, math.floor(sz * 0.78))
t.TextXAlignment = Enum.TextXAlignment.Center
t.TextYAlignment = Enum.TextYAlignment.Center
t.Parent = parent
return t
end
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
dragging = true; dragStart = input.Position; startPos = target.Position
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
startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
if math.abs(delta.X) < 10 and math.abs(delta.Y) < 10 then fn() end
touchStart = nil
end
end)
table.insert(conns, c2)
return conns
end

-- makeCard: borde perimetral + InnerHL (luz cenital sutil, sin romper layout)
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
local ih = Instance.new("UIStroke")
ih.Name = "InnerHL"
ih.Color = Theme.Highlight
ih.Thickness = 1
ih.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ih.Transparency = 0.90
ih.Parent = c
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.FillDirection = Enum.FillDirection.Horizontal
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = c
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, PAD_SM)
pad.PaddingRight = UDim.new(0, PAD_SM)
pad.Parent = c
return c, borderStroke, layout
end

-- initHover: color + enciende la luz cenital (InnerHL) y el borde
local function initHover(comp, card, stroke)
local inner = card:FindFirstChild("InnerHL")
local c1 = card.MouseEnter:Connect(function()
if comp._disabled then return end
tw(card, {BackgroundColor3 = Theme.CardHover}, TI_HOVER)
if stroke then tw(stroke, {Color = Theme.BorderHover}, TI_HOVER) end
if inner then tw(inner, {Transparency = 0.62}, TI_HOVER) end
end)
local c2 = card.MouseLeave:Connect(function()
if comp._disabled then return end
tw(card, {BackgroundColor3 = Theme.Card}, TI_HOVER)
if stroke then tw(stroke, {Color = Theme.Border}, TI_HOVER) end
if inner then tw(inner, {Transparency = 0.90}, TI_HOVER) end
end)
table.insert(comp._connections, c1)
table.insert(comp._connections, c2)
end

-- ═══════════════════════════════════════════════════════════════
--  CONFIG  —  persistencia (delega en modules/config.lua o memoria)
-- ═══════════════════════════════════════════════════════════════
local _fsOk = (type(writefile) == "function" and type(readfile) == "function"
and type(isfolder) == "function" and type(isfile) == "function" and type(makefolder) == "function")

local function useRemote() return ConfigMod ~= nil and _fsOk end

local function cfgPath(key)
if type(key) == "table" then return key end
return { key }
end

local function cfgDeepGet(t, ks)
for _, k in ipairs(ks) do
if type(t) ~= "table" or t[k] == nil then return nil end
t = t[k]
end
return t
end

local function cfgDeepSet(t, ks, v)
for i = 1, #ks - 1 do
local k = ks[i]
if type(t[k]) ~= "table" then t[k] = {} end
t = t[k]
end
t[ks[#ks]] = v
end

local function cfgDeepRemove(t, ks)
for i = 1, #ks - 1 do
local k = ks[i]
if type(t[k]) ~= "table" then return end
t = t[k]
end
t[ks[#ks]] = nil
end

local _mem = {}
local _cfgInited = false

local APTXConfig = {}
APTX.Config = APTXConfig

function APTXConfig.Init(opts)
opts = opts or {}
if useRemote() then
local ok, err = pcall(ConfigMod.Init, opts)
if not ok then warn("[APTX.Config] Init:", err) end
end
_cfgInited = true
end

function APTXConfig.get(key)
if useRemote() then return ConfigMod.get(key) end
return cfgDeepGet(_mem, cfgPath(key))
end

function APTXConfig.set(key, value)
if useRemote() then
if not _cfgInited then APTXConfig.Init({ folder = "APTX", file = "config.json" }) end
ConfigMod.set(key, value)
return
end
cfgDeepSet(_mem, cfgPath(key), value)
end

function APTXConfig.has(key) return APTXConfig.get(key) ~= nil end

function APTXConfig.getOrDefault(key, default)
local v = APTXConfig.get(key)
return v ~= nil and v or default
end

function APTXConfig.remove(key)
if useRemote() then return ConfigMod.remove(key) end
cfgDeepRemove(_mem, cfgPath(key))
end

function APTXConfig.reset()
if useRemote() then return ConfigMod.reset() end
_mem = {}
end

function APTXConfig.flush()
if useRemote() then return ConfigMod.flush() end
end

function APTXConfig.toggle(key)
if useRemote() then return ConfigMod.toggle(key) end
local v = APTXConfig.get(key)
APTXConfig.set(key, not (type(v) == "boolean" and v or false))
end

function APTXConfig.add(key, n)
if useRemote() then return ConfigMod.add(key) end
local v = APTXConfig.get(key)
APTXConfig.set(key, (type(v) == "number" and v or 0) + (n or 1))
end

function APTXConfig.append(key, value)
if useRemote() then return ConfigMod.append(key, value) end
local list = APTXConfig.get(key)
if type(list) ~= "table" then list = {} end
table.insert(list, value)
APTXConfig.set(key, list)
end

function APTXConfig.pop(key)
if useRemote() then return ConfigMod.pop(key) end
local list = APTXConfig.get(key)
if type(list) ~= "table" or #list == 0 then return end
table.remove(list, #list)
APTXConfig.set(key, list)
end

function APTXConfig.keys(key)
if useRemote() then return ConfigMod.keys(key) end
local val = APTXConfig.get(key)
if type(val) ~= "table" then return {} end
local out = {}
for k in pairs(val) do table.insert(out, k) end
return out
end

function APTXConfig.strKeys(key)
if useRemote() then return ConfigMod.strKeys(key) end
local val = APTXConfig.get(key)
if type(val) ~= "table" then return {} end
local out = {}
for k in pairs(val) do
if type(k) == "string" then table.insert(out, k) end
end
return out
end

function APTXConfig.batch(fn)
if useRemote() then return ConfigMod.batch(fn) end
pcall(fn)
end

function APTXConfig.isRemote() return useRemote() end

local function bindConfig(comp, kind, configKey)
if not configKey or configKey == "" then return end
local saved = APTXConfig.get(configKey)
if saved == nil then return end
if kind == "toggle" then comp:Edit({ value = saved })
elseif kind == "slider" then comp:SetValue(saved)
elseif kind == "input" then comp:SetValue(saved)
elseif kind == "menu" then comp:Edit({ selected = saved }) end
end

local function wrapConfigCb(configKey, userCb)
return function(v)
APTXConfig.set(configKey, v)
if userCb then userCb(v) end
end
end

local function topInset()
local ok, v = pcall(function() return GuiService:GetGuiInset() end)
if ok and v then return v.Y end
return 0
end

local function hideOffsetY()
return 0
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
if APTX.HideButton then
APTX.HideButton.Position = UDim2.new(0.5, 0, 0, hideOffsetY())
end
end
local sizeConn = APTX.GUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
table.insert(APTX._connections, sizeConn)
updateScale()
end

function APTX:Config(title, draggable, devmode, persistOpts)
local success, err = pcall(function()
APTX.Title = title or "APTX GUI"
APTX.Draggable = draggable ~= false
APTX.DevMode = devmode == true
log("Inicializando APTX GUI (Premium)...")
APTX:CreateGUI()
APTX:CreateHideButton()
if type(persistOpts) == "table" then
APTXConfig.Init(persistOpts)
elseif persistOpts == true then
APTXConfig.Init()
end
log("GUI creado exitosamente")
end)
if not success then warn("[APTX:Config] Error: " .. tostring(err)) end
return APTX
end

function APTX:CreateGUI()
local success, err = pcall(function()
for _, conn in ipairs(APTX._connections) do conn:Disconnect() end
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
if playerGui:FindFirstChild("APTXGui") then playerGui.APTXGui:Destroy() end
APTX.GUI = Instance.new("ScreenGui")
APTX.GUI.Name = "APTXGui"
APTX.GUI.IgnoreGuiInset = true
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
-- Glow ambiental con tinte de marca (gradiente vertical)
local ambientGlow = newF({
Name = "AmbientGlow",
Size = UDim2.new(1, 0, 0, 220),
Position = UDim2.new(0, 0, 0, 0),
BackgroundColor3 = Theme.Glow,
BackgroundTransparency = 0,
BorderSizePixel = 0,
}, APTX.MainFrame)
local glowGrad = Instance.new("UIGradient")
glowGrad.Rotation = 90
glowGrad.Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.90),
NumberSequenceKeypoint.new(0.55, 0.985),
NumberSequenceKeypoint.new(1, 1),
})
glowGrad.Parent = ambientGlow
local function syncShadow(s)
s.Position = UDim2.new(0.5, APTX.MainFrame.Position.X.Offset - (s.Size.X.Offset - mfW) / 2,
0.5, APTX.MainFrame.Position.Y.Offset - (s.Size.Y.Offset - mfH) / 2)
end
local s1 = makeShadow(mfW, mfH, 1, 0.80); newC(s1, 14); s1.Parent = APTX.GUI; syncShadow(s1)
local s2 = makeShadow(mfW, mfH, 2, 0.88); newC(s2, 16); s2.Parent = APTX.GUI; syncShadow(s2)
local s3 = makeShadow(mfW, mfH, 3, 0.94); newC(s3, 18); s3.Parent = APTX.GUI; syncShadow(s3)
APTX.Shadow1, APTX.Shadow2, APTX.Shadow3 = s1, s2, s3
for _, s in ipairs({s1, s2, s3}) do
local sync = APTX.MainFrame:GetPropertyChangedSignal("Position"):Connect(function() syncShadow(s) end)
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
for _, conn in ipairs(dragConns) do table.insert(APTX._connections, conn) end
end
end)
if not success then warn("[APTX:CreateGUI] Error: " .. tostring(err)) end
end

function APTX:CreateTopBar()
local success, err = pcall(function()
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
TextColor3 = Theme.BrandHi,
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
-- divider vertical antes de los controles
local divider = newF({
Size = UDim2.new(0, 1, 0, 18),
Position = UDim2.new(1, -116, 0.5, -9),
BackgroundColor3 = Theme.Border,
BorderSizePixel = 0,
}, topBar)
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
local CTRL_BG = Color3.fromRGB(28, 28, 33)
local CTRL_ICON_REST = Color3.fromRGB(124, 124, 134)
local minBtn = newB({
Name = "MinBtn", Size = UDim2.new(0, BTN_H, 0, BTN_H),
BackgroundColor3 = CTRL_BG, Text = "", BorderSizePixel = 0, AutoButtonColor = false,
}, btnFrame)
newC(minBtn, 14)
local minIcon = newI("minimize", 14, minBtn)
minIcon.AnchorPoint = Vector2.new(0.5, 0.5); minIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
setIconColor(minIcon, CTRL_ICON_REST)
minBtn.MouseEnter:Connect(function() tw(minBtn, {BackgroundColor3 = Theme.Warning}, TI_HOVER); setIconColor(minIcon, Color3.new(1,1,1)) end)
minBtn.MouseLeave:Connect(function() tw(minBtn, {BackgroundColor3 = CTRL_BG}, TI_HOVER); setIconColor(minIcon, CTRL_ICON_REST) end)
minBtn.MouseButton1Click:Connect(function() APTX:ToggleVisibility() end)
local maxBtn = newB({
Name = "MaxBtn", Size = UDim2.new(0, BTN_H, 0, BTN_H),
BackgroundColor3 = CTRL_BG, Text = "", BorderSizePixel = 0, AutoButtonColor = false,
}, btnFrame)
newC(maxBtn, 14)
local maxIcon = newI("maximize", 14, maxBtn)
maxIcon.AnchorPoint = Vector2.new(0.5, 0.5); maxIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
setIconColor(maxIcon, CTRL_ICON_REST)
local isMaximized = false
local originalSize = APTX.MainFrame.Size
local originalPosition = APTX.MainFrame.Position
local function toggleMaximize()
isMaximized = not isMaximized
if isMaximized then
originalSize = APTX.MainFrame.Size; originalPosition = APTX.MainFrame.Position
APTX.MainFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
APTX.MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
APTX.MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
else
APTX.MainFrame.Size = originalSize; APTX.MainFrame.Position = originalPosition
APTX.MainFrame.AnchorPoint = Vector2.new(0, 0)
end
end
maxBtn.MouseEnter:Connect(function() tw(maxBtn, {BackgroundColor3 = Theme.Success}, TI_HOVER); setIconColor(maxIcon, Color3.new(1,1,1)) end)
maxBtn.MouseLeave:Connect(function() tw(maxBtn, {BackgroundColor3 = CTRL_BG}, TI_HOVER); setIconColor(maxIcon, CTRL_ICON_REST) end)
maxBtn.MouseButton1Click:Connect(toggleMaximize)
local closeBtn = newB({
Name = "CloseBtn", Size = UDim2.new(0, BTN_H, 0, BTN_H),
BackgroundColor3 = CTRL_BG, Text = "", BorderSizePixel = 0, AutoButtonColor = false,
}, btnFrame)
newC(closeBtn, 14)
local closeIcon = newI("x", 14, closeBtn)
closeIcon.AnchorPoint = Vector2.new(0.5, 0.5); closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
setIconColor(closeIcon, CTRL_ICON_REST)
closeBtn.MouseEnter:Connect(function() tw(closeBtn, {BackgroundColor3 = Theme.Error}, TI_HOVER); setIconColor(closeIcon, Color3.new(1,1,1)) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn, {BackgroundColor3 = CTRL_BG}, TI_HOVER); setIconColor(closeIcon, CTRL_ICON_REST) end)
closeBtn.MouseButton1Click:Connect(function() APTX:ToggleVisibility() end)
APTX.TopBar = topBar
end)
if not success then warn("[APTX:CreateTopBar] Error: " .. tostring(err)) end
end

function APTX:CreateSidebar(parent)
local success, err = pcall(function()
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
scrolling.ScrollBarThickness = 3
scrolling.ScrollBarImageColor3 = Theme.BrandLo
scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
scrolling.ScrollBarImageTransparency = 0.5
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
end)
if not success then warn("[APTX:CreateSidebar] Error: " .. tostring(err)) end
end

-- ContentArea: SectionHeader fijo + host de secciones
function APTX:CreateContentArea(parent)
local success, err = pcall(function()
local content = newF({
Name = "ContentArea",
Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
Position = UDim2.new(0, SIDEBAR_W, 0, 0),
BackgroundColor3 = Theme.Surface,
BorderSizePixel = 0,
ClipsDescendants = true,
}, parent)
newC(content, CORNER_R)
-- Header fijo
local header = newF({
Name = "SectionHeader",
Size = UDim2.new(1, 0, 0, HEADER_H),
BackgroundTransparency = 1,
BorderSizePixel = 0,
}, content)
local headerIcon = newI("home", 18, header)
headerIcon.Name = "HeaderIcon"
headerIcon.Position = UDim2.new(0, PAD_MD, 0.5, -9)
setIconColor(headerIcon, Theme.BrandMid)
local headerTitle = newL({
Name = "HeaderTitle",
Size = UDim2.new(1, -80, 0, 20),
Position = UDim2.new(0, PAD_MD + 26, 0, 9),
BackgroundTransparency = 1,
Text = APTX.Title,
TextColor3 = Theme.BrandHi,
Font = Enum.Font.GothamBold,
TextSize = 16,
TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd,
}, header)
local headerCaption = newL({
Name = "HeaderCaption",
Size = UDim2.new(1, -80, 0, 12),
Position = UDim2.new(0, PAD_MD + 26, 0, 29),
BackgroundTransparency = 1,
Text = "// SECTION",
TextColor3 = Theme.BrandLo,
Font = Enum.Font.Code,
TextSize = 9,
TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd,
}, header)
local headerLine = newF({
Size = UDim2.new(1, -PAD_MD*2, 0, 1),
Position = UDim2.new(0, PAD_MD, 1, -1),
BackgroundColor3 = Theme.Border,
BorderSizePixel = 0,
}, header)
local lineGrad = Instance.new("UIGradient")
lineGrad.Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.2),
NumberSequenceKeypoint.new(0.5, 0.6),
NumberSequenceKeypoint.new(1, 1),
})
lineGrad.Parent = headerLine
-- Host de secciones
local host = newF({
Name = "SectionsHost",
Size = UDim2.new(1, 0, 1, -HEADER_H),
Position = UDim2.new(0, 0, 0, HEADER_H),
BackgroundTransparency = 1,
ClipsDescendants = true,
}, content)
APTX.ContentArea = content
APTX.ContentHost = host
APTX.HeaderIcon = headerIcon
APTX.HeaderTitle = headerTitle
APTX.HeaderCaption = headerCaption
end)
if not success then warn("[APTX:CreateContentArea] Error: " .. tostring(err)) end
end

local function applyRecording()
local btn = APTX.HideButton
if not btn then return end
local t = APTX._recording and 1 or 0
for _, d in ipairs(btn:GetDescendants()) do
if d:IsA("ImageLabel") then d.ImageTransparency = t
elseif d:IsA("TextLabel") then d.TextTransparency = t end
end
end

function APTX:Recording(state)
APTX._recording = state == true
applyRecording()
return APTX
end

function APTX:CreateHideButton()
local success, err = pcall(function()
local hideBtn = newB({
Name = "HideButton",
Size = UDim2.new(0, 44, 0, 44),
AnchorPoint = Vector2.new(0.5, 0),
Position = UDim2.new(0.5, 0, 0, hideOffsetY()),
ZIndex = 50,
BackgroundTransparency = 1,
Text = "",
BorderSizePixel = 0,
AutoButtonColor = false,
Visible = false,
}, APTX.GUI)
local inverseScale = Instance.new("UIScale")
inverseScale.Name = "InverseScale"
inverseScale.Parent = hideBtn
local function updateInverseScale()
if APTX._scale and APTX._scale ~= 0 then inverseScale.Scale = 1 / APTX._scale end
hideBtn.Position = UDim2.new(0.5, 0, 0, hideOffsetY())
end
local scaleConn = APTX.GUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateInverseScale)
table.insert(APTX._connections, scaleConn)
updateInverseScale()
local hideIcon = newI("chevron-down", 26, hideBtn)
hideIcon.AnchorPoint = Vector2.new(0.5, 0.5)
hideIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
setIconColor(hideIcon, Color3.fromRGB(210, 210, 216))
hideBtn.MouseEnter:Connect(function() setIconColor(hideIcon, Theme.BrandHi) end)
hideBtn.MouseLeave:Connect(function() setIconColor(hideIcon, Color3.fromRGB(210, 210, 216)) end)
hideBtn.MouseButton1Click:Connect(function() APTX:ToggleVisibility() end)
APTX.HideButton = hideBtn
applyRecording()
end)
if not success then warn("[APTX:CreateHideButton] Error: " .. tostring(err)) end
end

function APTX:ToggleVisibility()
local success, err = pcall(function()
APTX.IsVisible = not APTX.IsVisible
if APTX.IsVisible then
local restorePos = APTX._lastVisiblePos or UDim2.new(0.5, -(APTX.MainFrame.Size.X.Offset / 2), 0.5, -(APTX.MainFrame.Size.Y.Offset / 2))
for _, s in ipairs({APTX.Shadow1, APTX.Shadow2, APTX.Shadow3}) do if s then s.Visible = true end end
tw(APTX.MainFrame, {Position = restorePos}, TI_BOUNCE)
if APTX.HideButton then APTX.HideButton.Visible = false end
else
APTX._lastVisiblePos = APTX.MainFrame.Position
tw(APTX.MainFrame, {Position = UDim2.new(0.5, -(APTX.MainFrame.Size.X.Offset / 2), 1.5, 0)}, TI_BOUNCE)
task.delay(TI_BOUNCE.Time, function()
if not APTX.IsVisible then
for _, s in ipairs({APTX.Shadow1, APTX.Shadow2, APTX.Shadow3}) do if s then s.Visible = false end end
if APTX.HideButton then
APTX.HideButton.Position = UDim2.new(0.5, 0, 0, hideOffsetY())
APTX.HideButton.Visible = true
end
end
end)
end
end)
if not success then warn("[APTX:ToggleVisibility] Error: " .. tostring(err)) end
end

function APTX:Destroy()
local success, err = pcall(function()
for _, section in ipairs(APTX.Sections) do
if section._compRef and section._compRef._connections then
for _, conn in ipairs(section._compRef._connections) do conn:Disconnect() end
section._compRef._connections = {}
end
if section.Container then
for _, child in ipairs(section.Container:GetChildren()) do
local childComp = CompRegistry[child]
if childComp and childComp._connections then
for _, conn in ipairs(childComp._connections) do conn:Disconnect() end
childComp._connections = {}
end
CompRegistry[child] = nil
end
end
end
for _, conn in ipairs(APTX._connections) do conn:Disconnect() end
APTX._connections = {}
for _, threadId in pairs(APTX._sectionHideDelays) do pcall(task.cancel, threadId) end
APTX._sectionHideDelays = {}
for _, ff in ipairs(APTX._floatingFrames) do pcall(function() ff:Destroy() end) end
APTX._floatingFrames = {}
APTX._notifStack = {}
APTX.Sections = {}
APTX.CurrentSection = nil
if APTX.GUI then APTX.GUI:Destroy(); APTX.GUI = nil end
end)
if not success then warn("[APTX:Destroy] Error: " .. tostring(err)) end
end

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
pcall(function()
if self._tooltipObj then self._tooltipObj:Destroy(); self._tooltipObj = nil end
if self._tooltipCons then for _, c in ipairs(self._tooltipCons) do c:Disconnect() end; self._tooltipCons = nil end
if self._tweens then for _, t in ipairs(self._tweens) do t:Cancel() end; self._tweens = {} end
for _, c in ipairs(self._connections) do c:Disconnect() end
self._connections = {}
CompRegistry[self._frame] = nil
if self._frame and self._frame.Parent then self._frame:Destroy(); self._frame = nil end
end)
end
function comp:Disable()
pcall(function()
if self._disabled then return end
self._disabled = true
if self._frame then
self._overlay = makeOverlay(self._frame)
if self._frame:IsA("ScrollingFrame") then self._frame.ScrollingEnabled = false end
end
end)
end
function comp:Enable()
pcall(function()
if not self._disabled then return end
self._disabled = false
if self._overlay then
self._overlay:Destroy(); self._overlay = nil
if self._frame:IsA("ScrollingFrame") then self._frame.ScrollingEnabled = true end
end
end)
end
function comp:IsDisabled() return self._disabled end
function comp:MoveTo(targetSectionName)
pcall(function()
local targetSection = APTX:GetSection(targetSectionName)
if not targetSection then log("ERROR: Section not found:", targetSectionName); return end
if self._frame then self._frame.Parent = targetSection.Container; self._section = targetSection end
end)
end
function comp:DisconnectAll()
pcall(function()
if self._tooltipCons then for _, c in ipairs(self._tooltipCons) do c:Disconnect() end; self._tooltipCons = nil end
if self._tweens then for _, t in ipairs(self._tweens) do t:Cancel() end; self._tweens = {} end
for _, c in ipairs(self._connections) do c:Disconnect() end
self._connections = {}
end)
end
function comp:SetTooltip(text, opts)
pcall(function()
if self._tooltipObj then self._tooltipObj:Destroy(); self._tooltipObj = nil end
if self._tooltipCons then for _, c in ipairs(self._tooltipCons) do c:Disconnect() end; self._tooltipCons = nil end
if not text or text == "" or not APTX.GUI then return end
local opt = opts or {}
local delay = opt.delay or 0.5
local maxW = opt.maxWidth or 260
local offX = opt.offsetX or 0
local offY = opt.offsetY or 22
local tip = newF({
Name = "Tooltip", Size = UDim2.new(0, 0, 0, 0),
BackgroundColor3 = Theme.Card, BorderSizePixel = 0, ZIndex = 9999, Visible = false,
}, APTX.GUI)
newC(tip, 6)
local tipStroke = newS(tip, Theme.AccentTint, 1); tipStroke.Transparency = 0.4
local tipLbl = newL({
Size = UDim2.new(0, maxW - 12, 0, 0), Position = UDim2.new(0, 6, 0, 4),
BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary,
Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 10000,
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
tip.Visible = true; tipVisible = true
tip.BackgroundTransparency = 1; tipLbl.TextTransparency = 1
local absPos = self._frame.AbsolutePosition
local absSize = self._frame.AbsoluteSize
local guiSize = APTX.GUI.AbsoluteSize
local x = absPos.X + offX
local y = absPos.Y - tip.AbsoluteSize.Y - 6
local ts = tip.AbsoluteSize
if x + ts.X > guiSize.X then x = guiSize.X - ts.X - 4 end
if x < 0 then x = 4 end
if y < 0 then y = absPos.Y + absSize.Y + offY end
tip.Position = UDim2.new(0, x, 0, y)
tw(tip, {BackgroundTransparency = 0}, TI_HOVER)
tw(tipLbl, {TextTransparency = 0}, TI_HOVER)
tw(tipStroke, {Transparency = 0}, TI_HOVER)
end
local function hideTooltip()
tipVisible = false
if showThread then task.cancel(showThread); showThread = nil end
if not tip or not tip.Parent then return end
tw(tip, {BackgroundTransparency = 1}, TI_FAST)
tw(tipLbl, {TextTransparency = 1}, TI_FAST)
tw(tipStroke, {Transparency = 0.4}, TI_FAST)
task.delay(0.12, function() if tip and tip.Parent and not tipVisible then tip.Visible = false end end)
end
local hEnter = self._frame.MouseEnter:Connect(function()
if self._disabled then return end
if showThread then task.cancel(showThread); showThread = nil end
showThread = task.delay(delay, function() if not self._disabled then showTooltip() end end)
end)
local hLeave = self._frame.MouseLeave:Connect(function() hideTooltip() end)
self._tooltipCons = {hEnter, hLeave}
end)
end
return comp
end

local TI_ENTRY_FADE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function animEntry(container)
pcall(function()
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
pcall(function()
if not card or not card.Parent or card.Parent ~= container then return end
tw(card, {TextTransparency = 0}, TI_ENTRY_FADE)
end)
end)
elseif card:IsA("Frame") then
local origBGT = card.BackgroundTransparency
card.BackgroundTransparency = 1
task.delay(stagger, function()
pcall(function()
if not card or not card.Parent or card.Parent ~= container then return end
tw(card, {BackgroundTransparency = origBGT}, TI_ENTRY_FADE)
for _, child in ipairs(card:GetChildren()) do
if child:IsA("TextLabel") then
child.TextTransparency = 1; tw(child, {TextTransparency = 0}, TI_ENTRY_FADE)
elseif child:IsA("TextButton") then
child.TextTransparency = 1; tw(child, {TextTransparency = 0}, TI_ENTRY_FADE)
if child.BackgroundTransparency < 0.9 then
local origT = child.BackgroundTransparency; child.BackgroundTransparency = 1
tw(child, {BackgroundTransparency = origT}, TI_ENTRY_FADE)
end
elseif child:IsA("ImageLabel") then
child.ImageTransparency = 1; tw(child, {ImageTransparency = 0}, TI_ENTRY_FADE)
elseif child:IsA("UIStroke") then
local origT = child.Transparency; child.Transparency = 1
tw(child, {Transparency = origT}, TI_ENTRY_FADE)
elseif child:IsA("Frame") and child.Name ~= "Icon" and child.Name ~= "_DisabledOverlay" then
if child.BackgroundTransparency < 0.9 then
local origT = child.BackgroundTransparency; child.BackgroundTransparency = 1
tw(child, {BackgroundTransparency = origT}, TI_ENTRY_FADE)
end
end
end
end)
end)
else
card.Visible = true
end
end
end)
end

function APTX:Section(text, icon, default)
local compRef = nil
local section = nil
local success, err = pcall(function()
section = { Name = text, Icon = icon, Container = nil, Button = nil, _compRef = nil, _entered = false }
section.Button = newB({
Name = text, Size = UDim2.new(1, -4, 0, 38), Position = UDim2.new(0, 2, 0, 0),
BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1,
Text = "", BorderSizePixel = 0, AutoButtonColor = false,
}, APTX.SectionList)
newC(section.Button, 8)
local accentBar = newF({
Name = "AccentBar", Size = UDim2.new(0, 3, 1, 0), Position = UDim2.new(0, 0, 0, 0),
BackgroundColor3 = Theme.AccentTint, BackgroundTransparency = 1, BorderSizePixel = 0,
}, section.Button)
local row = newF({
Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
}, section.Button)
local iconLabel
if icon then
iconLabel = newI(icon, 16, row)
iconLabel.Position = UDim2.new(0, 0, 0.5, -8)
setIconColor(iconLabel, Theme.TextSecondary)
end
local label = newL({
Name = "Label", Size = UDim2.new(1, icon and -24 or 0, 1, 0),
Position = UDim2.new(0, icon and 24 or 0, 0, 0), BackgroundTransparency = 1,
Text = text, TextColor3 = Theme.TextSecondary, Font = Enum.Font.GothamMedium,
TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, row)
section.Container = Instance.new("ScrollingFrame")
section.Container.Name = text .. "_Container"
section.Container.Size = UDim2.new(1, 0, 1, 0)
section.Container.BackgroundTransparency = 1
section.Container.BorderSizePixel = 0
section.Container.ScrollBarThickness = 3
section.Container.ScrollBarImageColor3 = Theme.BorderHover
section.Container.ScrollBarImageTransparency = 0.4
section.Container.ScrollingEnabled = true
section.Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
section.Container.Visible = false
section.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
section.Container.Parent = APTX.ContentHost
local compLayout = Instance.new("UIListLayout")
compLayout.SortOrder = Enum.SortOrder.LayoutOrder
compLayout.Padding = UDim.new(0, 6)
compLayout.Parent = section.Container
local sectionPad = Instance.new("UIPadding")
sectionPad.PaddingTop = UDim.new(0, 8)
sectionPad.PaddingBottom = UDim.new(0, 8)
sectionPad.PaddingLeft = UDim.new(0, 8)
sectionPad.PaddingRight = UDim.new(0, 8)
sectionPad.Parent = section.Container
local emptyLabel = newL({
Name = "_EmptyPlaceholder", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
Text = "No hay elementos en esta seccion.", TextColor3 = Theme.TextDisabled,
Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
}, section.Container)
local sectionComp = {}
initComponent(sectionComp, section.Container, nil)
section._compRef = sectionComp
local function syncCanvas()
local hasContent = false
for _, child in ipairs(section.Container:GetChildren()) do
if not child:IsA("UIListLayout") and not child:IsA("UIPadding")
and not child:IsA("UIGridLayout") and child.Name ~= "_EmptyPlaceholder" then
hasContent = true; break
end
end
emptyLabel.Visible = not hasContent
section.Container.CanvasSize = UDim2.new(0, 0, 0, compLayout.AbsoluteContentSize.Y + 16)
end
local layoutConn = compLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
table.insert(sectionComp._connections, layoutConn)
task.defer(syncCanvas)
local btnClickConn = section.Button.MouseButton1Click:Connect(function() APTX:SelectSection(text) end)
table.insert(sectionComp._connections, btnClickConn)
local btnEnterConn = section.Button.MouseEnter:Connect(function()
if APTX.CurrentSection ~= text then
tw(section.Button, {BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 0.7}, TI_HOVER)
label.TextColor3 = Theme.TextPrimary
if iconLabel then setIconColor(iconLabel, Theme.TextPrimary) end
end
end)
table.insert(sectionComp._connections, btnEnterConn)
local btnLeaveConn = section.Button.MouseLeave:Connect(function()
if APTX.CurrentSection ~= text then
tw(section.Button, {BackgroundTransparency = 1}, TI_HOVER)
label.TextColor3 = Theme.TextSecondary
if iconLabel then setIconColor(iconLabel, Theme.TextSecondary) end
end
end)
table.insert(sectionComp._connections, btnLeaveConn)
table.insert(APTX.Sections, section)
if default == true or #APTX.Sections == 1 then APTX:SelectSection(text) end
function sectionComp:Remove()
pcall(function()
for _, c in ipairs(sectionComp._connections) do c:Disconnect() end
sectionComp._connections = {}
if section.Container then
for _, child in ipairs(section.Container:GetChildren()) do CompRegistry[child] = nil end
CompRegistry[section.Container] = nil
end
if section.Button and section.Button.Parent then section.Button:Destroy() end
if section.Container and section.Container.Parent then section.Container:Destroy() end
sectionComp._frame = nil; sectionComp._section = nil; section._compRef = nil
for i = #APTX.Sections, 1, -1 do
if APTX.Sections[i] == section then table.remove(APTX.Sections, i); break end
end
if APTX.CurrentSection == text then APTX.CurrentSection = nil end
end)
end
function sectionComp:Clear()
pcall(function()
local toRemove = {}
for _, child in ipairs(section.Container:GetChildren()) do
if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UIGridLayout") and child.Name ~= "_EmptyPlaceholder" then
table.insert(toRemove, child)
end
end
for _, child in ipairs(toRemove) do
local childComp = CompRegistry[child]
if childComp and childComp._connections then
for _, c in ipairs(childComp._connections) do c:Disconnect() end
childComp._connections = {}
end
CompRegistry[child] = nil; child:Destroy()
end
end)
end
compRef = sectionComp
end)
if not success then
warn("[APTX:Section] Error creando seccion '" .. tostring(text) .. "': " .. tostring(err))
return nil
end
return compRef
end

function APTX:SelectSection(name)
pcall(function()
for _, section in ipairs(APTX.Sections) do
if section.Name == name then
section.Container.Visible = true
section.Container.CanvasPosition = Vector2.new(0, 0)
-- actualizar header
if APTX.HeaderTitle then APTX.HeaderTitle.Text = section.Name end
if APTX.HeaderCaption then APTX.HeaderCaption.Text = "// " .. string.upper(section.Name) end
if APTX.HeaderIcon then
local asset = section.Icon and Icons[section.Icon]
if asset and asset ~= "" then
APTX.HeaderIcon.Visible = true
if APTX.HeaderIcon:IsA("ImageLabel") then APTX.HeaderIcon.Image = asset end
setIconColor(APTX.HeaderIcon, Theme.BrandMid)
else
APTX.HeaderIcon.Visible = false
end
end
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
if not section._entered then section._entered = true; animEntry(section.Container) end
section.Button.BackgroundColor3 = Theme.SidebarActive
section.Button.BackgroundTransparency = 0
local bar = section.Button:FindFirstChild("AccentBar")
if bar then tw(bar, {BackgroundTransparency = 0}, TI_MED); bar.BackgroundColor3 = Theme.AccentTint end
local iconImg = section.Button:FindFirstChild("Icon", true)
if iconImg then setIconColor(iconImg, Theme.BrandMid) end
local lbl2 = section.Button:FindFirstChild("Label", true)
if lbl2 then lbl2.TextColor3 = Theme.BrandHi end
APTX.CurrentSection = name
else
section.Container.Visible = false
section.Button.BackgroundTransparency = 1
local bar = section.Button:FindFirstChild("AccentBar")
if bar then tw(bar, {BackgroundTransparency = 1}, TI_MED); bar.BackgroundColor3 = Theme.AccentTint end
local iconImg = section.Button:FindFirstChild("Icon", true)
if iconImg then setIconColor(iconImg, Theme.TextSecondary) end
local lbl2 = section.Button:FindFirstChild("Label", true)
if lbl2 then lbl2.TextColor3 = Theme.TextSecondary end
end
end
end)
end

function APTX:GetSection(name)
for _, section in ipairs(APTX.Sections) do if section.Name == name then return section end end
return nil
end

function APTX:Button(sectionName, text, icon, callback)
if type(icon) == "function" then callback = icon; icon = nil end
local compRef = nil
local success, err = pcall(function()
local section = APTX:GetSection(sectionName)
if not section then error("Section not found: " .. tostring(sectionName)) end
local card, stroke, layout = makeCard(section.Container)
card.Size = UDim2.new(1, 0, 0, CARD_H)
local iconImg
if icon then iconImg = newI(icon, 16, card); iconImg.LayoutOrder = 1; setIconColor(iconImg, Theme.TextSecondary) end
local label = newL({
Name = "Label", Size = UDim2.new(1, 0, 1, 0), LayoutOrder = 2, BackgroundTransparency = 1,
Text = text, TextColor3 = Theme.TextPrimary, Font = Enum.Font.GothamMedium,
TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, card)
local comp = {}; local cb = callback
initComponent(comp, card, section)
initHover(comp, card, stroke)
comp._tweens = {}
local clickConns = connectClick(card, function()
if comp._disabled then return end
for _, t in ipairs(comp._tweens) do t:Cancel() end
comp._tweens = {}
local ts = TweenService:Create(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.CardHover})
ts:Play(); table.insert(comp._tweens, ts)
local tsConn = ts.Completed:Connect(function() if card and card.Parent then tw(card, {BackgroundColor3 = Theme.Card}, TI_BACK) end end)
table.insert(comp._connections, tsConn)
local pt = TweenService:Create(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 42)})
pt:Play(); table.insert(comp._tweens, pt)
local ptConn = pt.Completed:Connect(function() if card and card.Parent then tw(card, {Size = UDim2.new(1, 0, 0, CARD_H)}, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)) end end)
table.insert(comp._connections, ptConn)
if cb then cb() end
end)
for _, c in ipairs(clickConns) do table.insert(comp._connections, c) end
function comp:Edit(params)
pcall(function()
params = params or {}
if params.text then card.Name = params.text; label.Text = params.text end
if params.callback then cb = params.callback end
end)
end
compRef = comp
end)
if not success then
warn("[APTX:Button] Error '" .. tostring(text) .. "': " .. tostring(err))
return makeNilProxy("Button:" .. tostring(text))
end
return compRef
end

function APTX:Toggle(sectionName, text, icon, default, callback)
if type(icon) == "function" then callback = icon; icon = nil end
local configKey = nil
if type(callback) == "table" then configKey = callback.config or callback.configKey; callback = callback.callback end
local compRef = nil
local success, err = pcall(function()
local section = APTX:GetSection(sectionName)
if not section then error("Section not found: " .. tostring(sectionName)) end
local isOn = default == true
local debounce = false
local card, stroke, layout = makeCard(section.Container)
card.Size = UDim2.new(1, 0, 0, CARD_H)
local iconImg
if icon then iconImg = newI(icon, 16, card); iconImg.LayoutOrder = 1; setIconColor(iconImg, Theme.TextSecondary) end
local label = newL({
Name = "Label", Size = UDim2.new(1, -(icon and 24 or 0) - 52, 1, 0), LayoutOrder = 2,
BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary,
Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, card)
local track = newB({
Name = "Track", Size = UDim2.new(0, 44, 0, 24),
Position = UDim2.new(1, -(44 + PAD_SM), 0.5, -12),
BackgroundColor3 = Color3.fromRGB(40, 40, 46), Text = "", BorderSizePixel = 0,
AutoButtonColor = false, ZIndex = 2,
}, card)
newC(track, CORNER_R)
local trackStroke = newS(track, Theme.Border, 1); trackStroke.Transparency = 0.3
local knob = newF({
Name = "Knob", Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 2, 0.5, -10),
BackgroundColor3 = Color3.fromRGB(150, 150, 158), BorderSizePixel = 0,
}, track)
newC(knob, 10)
local comp = {}; local cb = callback
initComponent(comp, card, section)
initHover(comp, card, stroke)
local function setToggleState(state, instant)
isOn = state
local kPos = isOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
local tColor = isOn and Theme.AccentTint or Color3.fromRGB(40, 40, 46)
local kColor = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 158)
local sTrans = isOn and 0.85 or 0.3
if instant then
knob.Position = kPos; track.BackgroundColor3 = tColor; knob.BackgroundColor3 = kColor; trackStroke.Transparency = sTrans
else
tw(knob, {Position = kPos}, TI_MED); tw(track, {BackgroundColor3 = tColor}, TI_MED)
tw(knob, {BackgroundColor3 = kColor}, TI_MED); tw(trackStroke, {Transparency = sTrans}, TI_MED)
end
end
if isOn then setToggleState(true, true) end
local function toggleAction()
if comp._disabled or debounce then return end
debounce = true; setToggleState(not isOn)
if cb then cb(isOn) end
task.delay(0.1, function() debounce = false end)
end
track.MouseButton1Click:Connect(toggleAction)
track.MouseEnter:Connect(function() tw(knob, {Size = UDim2.new(0, 22, 0, 22)}, TI_HOVER) end)
track.MouseLeave:Connect(function() tw(knob, {Size = UDim2.new(0, 20, 0, 20)}, TI_HOVER) end)
function comp:Edit(params)
pcall(function()
params = params or {}
if params.text then label.Text = params.text; card.Name = params.text end
if params.value ~= nil then setToggleState(params.value) end
if params.callback then cb = params.callback end
end)
end
function comp:GetValue() return isOn end
if configKey then
bindConfig(comp, "toggle", configKey)
local _u = cb
cb = wrapConfigCb(configKey, _u)
end
compRef = comp
end)
if not success then
warn("[APTX:Toggle] Error '" .. tostring(text) .. "': " .. tostring(err))
return makeNilProxy("Toggle:" .. tostring(text))
end
return compRef
end

function APTX:Slider(sectionName, text, icon, min, max, default, callback)
if type(icon) == "function" then callback = icon; icon = nil end
local configKey = nil
if type(callback) == "table" then configKey = callback.config or callback.configKey; callback = callback.callback end
local compRef = nil
local success, err = pcall(function()
local section = APTX:GetSection(sectionName)
if not section then error("Section not found: " .. tostring(sectionName)) end
if max == min then max = min + 1 end
local value = default or min
local card, stroke, layout = makeCard(section.Container)
card.Size = UDim2.new(1, 0, 0, 58); layout:Destroy()
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, PAD_SM); pad.PaddingRight = UDim.new(0, PAD_SM)
pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 10); pad.Parent = card
local topRow = newF({ Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, card)
if icon then
local ip = newI(icon, 14, topRow); setIconColor(ip, Theme.TextSecondary); ip.Position = UDim2.new(0, 0, 0.5, -7)
end
local label = newL({
Name = "Label", Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, icon and 20 or 0, 0, 0),
BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary, Font = Enum.Font.GothamMedium,
TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, topRow)
local valueLabel = newL({
Name = "ValueLabel", Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0),
BackgroundTransparency = 1, Text = tostring(value), TextColor3 = Theme.AccentTint,
Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
}, topRow)
local trackHitbox = newF({ Name = "TrackHitbox", Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 0, 7), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true }, card)
local track = newF({ Name = "Track", Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 19), BackgroundColor3 = Color3.fromRGB(18, 18, 22), BorderSizePixel = 0, Active = true }, trackHitbox)
newC(track, 3)
local trackBorder = newS(track, Theme.Border, 1); trackBorder.Transparency = 0.5
local fill = newF({ Name = "Fill", Size = UDim2.new((value - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.AccentTint, BorderSizePixel = 0 }, track)
newC(fill, 3)
local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new(Theme.AccentTint:Lerp(Color3.new(1,1,1), 0.25), Theme.AccentTint)
fillGrad.Parent = fill
local knob = newF({ Name = "Knob", Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new((value - min) / (max - min), -9, 0.5, -9), BackgroundColor3 = Color3.fromRGB(235, 235, 240), BorderSizePixel = 0 }, track)
newC(knob, 9)
local knobBorder = newS(knob, Theme.AccentTint, 1.5); knobBorder.Transparency = 0.3
local comp = {}; local cb = callback
initComponent(comp, card, section)
initHover(comp, card, stroke)
local dragging = false
local function updateSlider(input)
if comp._disabled or not card or not card.Parent then return end
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
local ibConn = trackHitbox.InputBegan:Connect(function(input)
if comp._disabled then return end
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true; updateSlider(input); tw(knob, {Size = UDim2.new(0, 22, 0, 22)}, TI_HOVER)
end
end); table.insert(comp._connections, ibConn)
local ieConn = UserInputService.InputEnded:Connect(function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
dragging = false; tw(knob, {Size = UDim2.new(0, 18, 0, 18)}, TI_HOVER)
end
end); table.insert(comp._connections, ieConn)
local uiConn = UserInputService.InputChanged:Connect(function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input) end
end); table.insert(comp._connections, uiConn)
function comp:Edit(params)
pcall(function()
params = params or {}
if params.text then label.Text = params.text end
local minC = params.min ~= nil; local maxC = params.max ~= nil
if minC then min = params.min end
if maxC then max = params.max; if max == min then max = min + 1 end end
if minC or maxC then
value = clamp(value, min, max); local pos = (value - min) / (max - min)
valueLabel.Text = tostring(value); fill.Size = UDim2.new(pos, 0, 1, 0); knob.Position = UDim2.new(pos, -9, 0.5, -9)
end
if params.value ~= nil then
value = clamp(params.value, min, max); local pos = (value - min) / (max - min)
valueLabel.Text = tostring(value); fill.Size = UDim2.new(pos, 0, 1, 0); knob.Position = UDim2.new(pos, -9, 0.5, -9)
end
if params.callback then cb = params.callback end
end)
end
function comp:GetValue() return value end
function comp:SetValue(v)
pcall(function()
value = clamp(v, min, max); local pos = (value - min) / (max - min)
valueLabel.Text = tostring(value); fill.Size = UDim2.new(pos, 0, 1, 0); knob.Position = UDim2.new(pos, -9, 0.5, -9)
end)
end
if configKey then
bindConfig(comp, "slider", configKey)
local _u = cb
cb = wrapConfigCb(configKey, _u)
end
compRef = comp
end)
if not success then
warn("[APTX:Slider] Error '" .. tostring(text) .. "': " .. tostring(err))
return makeNilProxy("Slider:" .. tostring(text))
end
return compRef
end

function APTX:Menu(sectionName, text, placeholder, icon, options, default, callback)
local configKey = nil
if type(callback) == "table" then configKey = callback.config or callback.configKey; callback = callback.callback end
local compRef = nil
local success, err = pcall(function()
local section = APTX:GetSection(sectionName)
if not section then error("Section not found: " .. tostring(sectionName)) end
if not options or #options == 0 then options = {"(sin opciones)"} end
local isOpen = false
local selected = default or options[1]
local currentOptions = {}
for _, v in ipairs(options) do table.insert(currentOptions, v) end
local card, stroke, layout = makeCard(section.Container)
card.Size = UDim2.new(1, 0, 0, CARD_H); card.ClipsDescendants = true; layout:Destroy()
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, PAD_SM); pad.PaddingRight = UDim.new(0, PAD_SM); pad.Parent = card
local topRow = newF({ Size = UDim2.new(1, 0, 0, CARD_H), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, card)
local iconImg
if icon then iconImg = newI(icon, 16, topRow); iconImg.Position = UDim2.new(0, 0, 0.5, -8); setIconColor(iconImg, Theme.TextSecondary) end
local label = newL({
Name = "Label", Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, icon and 22 or 0, 0, 0),
BackgroundTransparency = 1, Text = placeholder or text, TextColor3 = Theme.TextPrimary,
Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd,
}, topRow)
local chevron = newL({
Name = "Chevron", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -16, 0.5, -8),
BackgroundTransparency = 1, Text = "▾", TextColor3 = Theme.TextSecondary, Font = Enum.Font.Gotham, TextSize = 10,
}, topRow)
local dropBtn = newB({ Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", BorderSizePixel = 0, AutoButtonColor = false }, topRow)
local optionsList = newF({
Name = "OptionsList", Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, CARD_H),
BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
}, card)
local optLayout = Instance.new("UIListLayout")
optLayout.SortOrder = Enum.SortOrder.LayoutOrder; optLayout.Padding = UDim.new(0, 1); optLayout.Parent = optionsList
local comp = {}; local cb = callback
initComponent(comp, card, section)
local optionBtns = {}
local function closeOutside(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
if isOpen then
local pos = input.Position; local absPos = card.AbsolutePosition; local absSize = card.AbsoluteSize
local expandedH = absSize.Y + 10
if pos.X < absPos.X or pos.X > absPos.X + absSize.X or pos.Y < absPos.Y or pos.Y > absPos.Y + expandedH then
isOpen = false
tw(card, {Size = UDim2.new(1, 0, 0, CARD_H)}, TI_MED)
tw(optionsList, {Size = UDim2.new(1, 0, 0, 0)}, TI_MED)
tw(chevron, {Rotation = 0}, TI_MED)
end
end
end
end
local function rebuildOptions()
for _, btn in ipairs(optionBtns) do btn:Destroy() end
optionBtns = {}
for _, opt in ipairs(currentOptions) do
local ob = newB({
Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.new(0,0,0),
BackgroundTransparency = 1, Text = "", BorderSizePixel = 0, AutoButtonColor = false,
}, optionsList)
local optLabel = newL({
Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
Text = opt, TextColor3 = opt == selected and Theme.AccentTint or Theme.TextSecondary,
Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
}, ob)
local checkmark = newL({
Name = "Checkmark", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -24, 0.5, -8),
BackgroundTransparency = 1, Text = opt == selected and "✓" or "", TextColor3 = Theme.AccentTint,
Font = Enum.Font.GothamBold, TextSize = 12,
}, ob)
ob.MouseEnter:Connect(function() tw(ob, {BackgroundColor3 = Color3.fromRGB(36, 36, 42), BackgroundTransparency = 0.7}, TI_HOVER) end)
ob.MouseLeave:Connect(function() tw(ob, {BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1}, TI_HOVER) end)
ob.MouseButton1Click:Connect(function()
if comp._disabled then return end
selected = opt; label.Text = selected
if cb then cb(selected) end
for _, btn in ipairs(optionBtns) do
local ol = btn:FindFirstChildOfClass("TextLabel"); local cm = btn:FindFirstChild("Checkmark")
if ol then ol.TextColor3 = Theme.TextSecondary end
if cm then cm.Text = "" end
end
local ol = ob:FindFirstChildOfClass("TextLabel"); local cm = ob:FindFirstChild("Checkmark")
if ol then ol.TextColor3 = Theme.AccentTint end
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
pcall(function()
params = params or {}
if params.text then label.Text = params.text end
if params.options then
currentOptions = {}; for _, v in ipairs(params.options) do table.insert(currentOptions, v) end
rebuildOptions()
if isOpen then
isOpen = false
tw(card, {Size = UDim2.new(1, 0, 0, CARD_H)}, TI_MED)
tw(optionsList, {Size = UDim2.new(1, 0, 0, 0)}, TI_MED)
tw(chevron, {Rotation = 0}, TI_MED)
end
end
if params.selected then selected = params.selected; label.Text = selected end
if params.callback then cb = params.callback end
end)
end
function comp:GetValue() return selected end
function comp:SetOptions(newOptions)
pcall(function() currentOptions = {}; for _, v in ipairs(newOptions) do table.insert(currentOptions, v) end; rebuildOptions() end)
end
if configKey then
bindConfig(comp, "menu", configKey)
local _u = cb
cb = wrapConfigCb(configKey, _u)
end
compRef = comp
end)
if not success then
warn("[APTX:Menu] Error '" .. tostring(text) .. "': " .. tostring(err))
return makeNilProxy("Menu:" .. tostring(text))
end
return compRef
end

function APTX:Input(sectionName, text, icon, placeholder, callback)
local configKey = nil
if type(callback) == "table" then configKey = callback.config or callback.configKey; callback = callback.callback end
local compRef = nil
local success, err = pcall(function()
local section = APTX:GetSection(sectionName)
if not section then error("Section not found: " .. tostring(sectionName)) end
local card, stroke, layout = makeCard(section.Container)
card.Size = UDim2.new(1, 0, 0, 60); layout:Destroy()
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, PAD_SM); pad.PaddingRight = UDim.new(0, PAD_SM)
pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = card
local topRow = newF({ Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, card)
if icon then
local ip = newI(icon, 14, topRow); setIconColor(ip, Theme.TextSecondary); ip.Position = UDim2.new(0, 0, 0.5, -7)
end
local label = newL({
Name = "Label", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, icon and 20 or 0, 0, 0),
BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary, Font = Enum.Font.GothamMedium,
TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, topRow)
local inputBox = Instance.new("TextBox")
inputBox.Name = "InputBox"; inputBox.Size = UDim2.new(1, 0, 0, 24); inputBox.Position = UDim2.new(0, 0, 0, 24)
inputBox.BackgroundColor3 = Color3.fromRGB(12, 12, 15); inputBox.BorderSizePixel = 0
inputBox.PlaceholderText = placeholder or ""; inputBox.PlaceholderColor3 = Theme.TextDisabled
inputBox.Text = ""; inputBox.TextColor3 = Theme.TextPrimary; inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 12; inputBox.TextXAlignment = Enum.TextXAlignment.Left; inputBox.ClearTextOnFocus = false
inputBox.Parent = card
newC(inputBox, 6)
local inputStroke = newS(inputBox, Theme.Border, 1)
local inputPad = Instance.new("UIPadding"); inputPad.PaddingLeft = UDim.new(0, 8); inputPad.Parent = inputBox
local comp = {}; local cb = callback
initComponent(comp, card, section)
initHover(comp, card, stroke)
inputBox.Focused:Connect(function()
tw(inputStroke, {Color = Theme.AccentTint, Transparency = 0, Thickness = 1.5}, TI_HOVER)
tw(inputBox, {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}, TI_HOVER)
end)
inputBox.FocusLost:Connect(function(enterPressed)
tw(inputStroke, {Color = Theme.Border, Transparency = 0, Thickness = 1}, TI_HOVER)
tw(inputBox, {BackgroundColor3 = Color3.fromRGB(12, 12, 15)}, TI_HOVER)
if comp._disabled then return end
if enterPressed and cb then cb(inputBox.Text) end
end)
function comp:Edit(params)
pcall(function()
params = params or {}
if params.text then label.Text = params.text end
if params.placeholder then inputBox.PlaceholderText = params.placeholder end
if params.value then inputBox.Text = params.value end
if params.callback then cb = params.callback end
end)
end
function comp:GetValue() return inputBox.Text end
function comp:SetValue(v) pcall(function() inputBox.Text = v or "" end) end
if configKey then
bindConfig(comp, "input", configKey)
local _u = cb
cb = wrapConfigCb(configKey, _u)
end
compRef = comp
end)
if not success then
warn("[APTX:Input] Error '" .. tostring(text) .. "': " .. tostring(err))
return makeNilProxy("Input:" .. tostring(text))
end
return compRef
end

function APTX:Label(sectionName, text)
local compRef = nil
local success, err = pcall(function()
local section = APTX:GetSection(sectionName)
if not section then error("Section not found: " .. tostring(sectionName)) end
local isSeparator = text:match("^[-=━]+$")
local label
if isSeparator then
label = newF({
Name = "Separator", Size = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
}, section.Container)
local sg = Instance.new("UIGradient")
sg.Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.15, 0.2),
NumberSequenceKeypoint.new(0.85, 0.2),
NumberSequenceKeypoint.new(1, 1),
})
sg.Parent = label
else
label = newL({
Name = text, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
Text = text, TextColor3 = Theme.BrandMid, Font = Enum.Font.GothamBold,
TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
}, section.Container)
end
local comp = {}
initComponent(comp, label, section)
function comp:Edit(params)
pcall(function()
params = params or {}
if params.text and label:IsA("TextLabel") then label.Text = params.text end
if params.color and label:IsA("TextLabel") then label.TextColor3 = params.color end
end)
end
function comp:SetText(newText) pcall(function() if label:IsA("TextLabel") then label.Text = newText end end) end
compRef = comp
end)
if not success then
warn("[APTX:Label] Error '" .. tostring(text) .. "': " .. tostring(err))
return makeNilProxy("Label:" .. tostring(text))
end
return compRef
end

-- ═══════════════════════════════════════════════════════════════
--  NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════
local NOTIF_Z_BASE = 1000
local NOTIF_GAP = 6
local NOTIF_RIGHT_MARGIN = 2
local notifCounter = 0

local function repositionStack()
pcall(function()
for i = #APTX._notifStack, 1, -1 do
if not APTX._notifStack[i] or not APTX._notifStack[i]._alive then table.remove(APTX._notifStack, i) end
end
local bottomOffset = NOTIF_RIGHT_MARGIN
local visible = {}
for _, entry in ipairs(APTX._notifStack) do
if entry and entry._alive and entry._card and entry._card.Parent then table.insert(visible, entry) end
end
local maxVisible = math.min(#visible, 4)
for idx = 1, #visible do
local entry = visible[idx]
if idx > maxVisible then
if entry._alive then entry:Close() end
else
local ch = entry._cardH; local cw = entry._cardW
local targetX = -(cw + NOTIF_RIGHT_MARGIN + 2)
local targetY = -(bottomOffset + ch)
tw(entry._card, {Position = UDim2.new(1, targetX, 1, targetY)}, TI_BOUNCE)
bottomOffset = bottomOffset + ch + NOTIF_GAP
end
end
end)
end

local function removeFromStack(notif)
for i = #APTX._notifStack, 1, -1 do
if APTX._notifStack[i] == notif then table.remove(APTX._notifStack, i); break end
end
repositionStack()
end

function APTX:Notify(params)
local notifRef = nil
local success, err = pcall(function()
assert(type(params) == "table", "[APTX:Notify] params debe ser una tabla")
assert(params.title, "[APTX:Notify] params.title es requerido")
assert(params.content, "[APTX:Notify] params.content es requerido")
assert(APTX.GUI, "[APTX:Notify] Llama APTX:Config() antes de usar Notify")
local title = params.title; local body = params.content
local iconTop = params["topbar-icon"]; local iconBody = params["content-icon"]
local duration = params.duration; local sound = params.sound; local buttons = params.buttons
local notifType = params.type or "neutral"; local size = params.size or 1
local hasDur = duration and duration > 0
local hasBtns = buttons and #buttons > 0
local s = math.max(0.5, math.min(1.5, size or 1))
local sW = math.floor(300 * s); local sTOPBAR = math.floor(32 * s); local sBODY = math.floor(36 * s)
local sBTN_H = math.floor(32 * s); local sBTN_W = math.floor(90 * s); local sBTN_SZ = math.floor(22 * s)
local sPAD = math.floor(14 * s); local sICON = math.floor(14 * s)
local btnH = hasBtns and sBTN_H or 0
local notifH = sTOPBAR + sBODY + (hasBtns and (sBTN_H + 8) or 8) + 2
local accentColors = {
info = Theme.AccentTint, success = Theme.Success, error = Theme.Error,
neutral = Theme.Accent, warning = Theme.Warning,
}
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "APTXNotifGui"; notifGui.ResetOnSpawn = false
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local gui = notifGui
notifCounter = notifCounter + 1
local Card = newF({
Name = "NotifCard_" .. notifCounter, Size = UDim2.new(0, sW, 0, notifH),
Position = UDim2.new(1, sW + 20, 1, -notifH), BackgroundColor3 = Color3.fromRGB(12, 12, 15),
BorderSizePixel = 0, ClipsDescendants = true, ZIndex = NOTIF_Z_BASE,
}, gui)
newC(Card, CORNER_R)
local cardStroke = newS(Card, Theme.Border, 1)
local notifInnerHL = Instance.new("UIStroke")
notifInnerHL.Color = Theme.Highlight; notifInnerHL.Thickness = 1
notifInnerHL.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; notifInnerHL.Transparency = 0.88
notifInnerHL.Parent = Card
local accentBar = newF({
Name = "AccentBar", Size = UDim2.new(0, 3, 1, 0), Position = UDim2.new(0, 0, 0, 0),
BackgroundColor3 = accentColors[notifType] or Theme.Accent, BorderSizePixel = 0, ZIndex = NOTIF_Z_BASE + 1,
}, Card)
newC(accentBar, 12)
local TB = newF({ Size = UDim2.new(1, -3, 0, sTOPBAR), Position = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1, ZIndex = NOTIF_Z_BASE + 1 }, Card)
local closeBtnSize = math.max(1, math.floor(20 * s))
local titleX = sPAD
if iconTop then
local iconLabel = newI(iconTop, sICON, TB)
iconLabel.Position = UDim2.new(0, sPAD, 0.5, -sICON / 2); iconLabel.ZIndex = NOTIF_Z_BASE + 2
setIconColor(iconLabel, accentColors[notifType] or Theme.Accent)
titleX = sPAD + sICON + 6
end
local TitleLbl = newL({
Size = UDim2.new(1, -(titleX + closeBtnSize + 8), 1, 0), Position = UDim2.new(0, titleX, 0, 0),
BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold,
TextSize = math.max(9, math.floor(13 * s)), TextColor3 = Theme.TextPrimary,
TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = NOTIF_Z_BASE + 2,
}, TB)
local CloseBtn = newB({
Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -(20 + 4), 0.5, -10),
BackgroundTransparency = 1, Text = "✕", TextColor3 = Theme.TextSecondary,
TextSize = math.max(9, math.floor(12 * s)), Font = Enum.Font.Gotham, BorderSizePixel = 0,
AutoButtonColor = false, ZIndex = NOTIF_Z_BASE + 3,
}, TB)
local BodyFrame = newF({ Size = UDim2.new(1, -3, 0, sBODY), Position = UDim2.new(0, sPAD + 3, 0, sTOPBAR), BackgroundTransparency = 1, ZIndex = NOTIF_Z_BASE + 1 }, Card)
if iconBody then
local bodyIconFrame = newI(iconBody, 16, BodyFrame)
bodyIconFrame.Position = UDim2.new(0, 0, 0, 0)
setIconColor(bodyIconFrame, accentColors[notifType] or Theme.Accent)
bodyIconFrame.ZIndex = NOTIF_Z_BASE + 2
end
local MsgLbl = newL({
Size = UDim2.new(1, -(sPAD + 3), 0, sBODY), Position = UDim2.new(0, iconBody and 22 or 0, 0, 0),
BackgroundTransparency = 1, Text = body, Font = Enum.Font.Gotham,
TextSize = math.max(8, math.floor(12 * s)), TextColor3 = Theme.TextSecondary, TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = NOTIF_Z_BASE + 2,
}, BodyFrame)
local DividerFill
if hasDur then
local db = newF({ Name = "DurationBar", Size = UDim2.new(1, -3, 0, 2), Position = UDim2.new(0, 3, 1, -2), BackgroundColor3 = Color3.fromRGB(30, 30, 36), BorderSizePixel = 0, ZIndex = NOTIF_Z_BASE + 1 }, Card)
DividerFill = newF({ Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = accentColors[notifType] or Theme.Accent, BorderSizePixel = 0, ZIndex = NOTIF_Z_BASE + 2 }, db)
end
if hasBtns then
local bc = newF({ Size = UDim2.new(1, -3, 0, sBTN_H), Position = UDim2.new(0, 3, 0, sTOPBAR + sBODY), BackgroundTransparency = 1, ZIndex = NOTIF_Z_BASE + 1 }, Card)
local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal; btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center; btnLayout.Padding = UDim.new(0, 6); btnLayout.Parent = bc
for i = 1, math.min(#buttons, 3) do
local bDef = buttons[i]
local bg = bDef.color or Color3.fromRGB(45, 45, 52)
local Btn = newB({
Size = UDim2.new(0, sBTN_W, 0, sBTN_SZ), BackgroundColor3 = bg,
Text = bDef.label or ("Button " .. i), Font = Enum.Font.GothamBold,
TextSize = math.max(8, math.floor(11 * s)), TextColor3 = Color3.new(1,1,1),
BorderSizePixel = 0, AutoButtonColor = false, ZIndex = NOTIF_Z_BASE + 3,
}, bc)
newC(Btn, math.floor(6 * s))
local bs = newS(Btn, Color3.new(1,1,1), 1); bs.Transparency = 0.85
Btn.MouseEnter:Connect(function() tw(Btn, {BackgroundColor3 = bg:Lerp(Color3.new(1,1,1), 0.15)}, TI_HOVER) end)
Btn.MouseLeave:Connect(function() tw(Btn, {BackgroundColor3 = bg}, TI_HOVER) end)
Btn.MouseButton1Down:Connect(function() tw(Btn, {Size = UDim2.new(0, sBTN_W - 4, 0, sBTN_SZ - 2)}, TI_FAST) end)
Btn.MouseButton1Up:Connect(function() tw(Btn, {Size = UDim2.new(0, sBTN_W, 0, sBTN_SZ)}, TI_BACK) end)
Btn.MouseButton1Click:Connect(function() if bDef.callback then task.spawn(bDef.callback) end end)
end
end
if sound then
local snd = Instance.new("Sound"); snd.SoundId = sound; snd.Volume = 0.6; snd.Parent = Card; snd:Play(); Debris:AddItem(snd, 5)
end
local Notif = { _card = Card, _title = TitleLbl, _msg = MsgLbl, _divFill = DividerFill, _alive = true, _cardH = notifH, _cardW = sW, _autoCloseThread = nil }
Card.Destroying:Connect(function()
if Notif._alive then
Notif._alive = false
if Notif._autoCloseThread then pcall(task.cancel, Notif._autoCloseThread); Notif._autoCloseThread = nil end
removeFromStack(Notif)
end
if notifGui and notifGui.Parent then notifGui:Destroy() end
end)
table.insert(APTX._notifStack, Notif)
local function fallClose(cb)
if not Notif._alive then return end
Notif._alive = false
if Notif._autoCloseThread then pcall(task.cancel, Notif._autoCloseThread); Notif._autoCloseThread = nil end
removeFromStack(Notif)
if not Card or not Card.Parent then if cb then pcall(cb) end; return end
local cur = Card.Position
local t1 = TweenService:Create(Card, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
Position = UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset - 10), Rotation = -2 })
t1.Completed:Connect(function()
if not Card or not Card.Parent then if cb then pcall(cb) end; return end
local t2 = TweenService:Create(Card, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
Position = UDim2.new(1, sW + 80, cur.Y.Scale, cur.Y.Offset + math.floor(notifH * 0.55)), Rotation = 22 })
TweenService:Create(Card, TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 }):Play()
t2.Completed:Connect(function() if cb then pcall(cb) end; if Card and Card.Parent then Card:Destroy() end end)
t2:Play()
end)
t1:Play()
end
task.delay(0.05, function() repositionStack() end)
if hasDur and DividerFill then
tw(DividerFill, {Size = UDim2.new(0, 0, 1, 0)}, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out))
local autoThread = task.delay(duration, function() if Notif._alive then fallClose() end end)
Notif._autoCloseThread = autoThread
end
CloseBtn.MouseButton1Click:Connect(function() if Notif._alive then fallClose() end end)
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, {TextColor3 = Theme.TextPrimary}, TI_HOVER) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, {TextColor3 = Theme.TextSecondary}, TI_HOVER) end)
function Notif:Destroy() if self._alive then fallClose() elseif self._card and self._card.Parent then self._card:Destroy() end end
function Notif:Close(cb) if self._alive then fallClose(cb) end end
function Notif:Edit(p)
if not self._alive then return end
p = p or {}
if p.title then self._title.Text = p.title end
if p.content then self._msg.Text = p.content end
if p.resetTimer and p.resetTimer > 0 and self._divFill then
if self._autoCloseThread then pcall(task.cancel, self._autoCloseThread); self._autoCloseThread = nil end
self._divFill.Size = UDim2.new(1, 0, 1, 0)
tw(self._divFill, {Size = UDim2.new(0, 0, 1, 0)}, TweenInfo.new(p.resetTimer, Enum.EasingStyle.Linear, Enum.EasingDirection.Out))
local autoThread = task.delay(p.resetTimer, function() if self._alive then fallClose() end end)
self._autoCloseThread = autoThread
end
end
function Notif:Flash(c)
if not self._alive then return end
local s = self._card:FindFirstChildOfClass("UIStroke")
if s then local orig = s.Color; s.Color = c or Color3.new(1,1,1); tw(s, {Color = orig}, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)) end
end
function Notif:SetBody(text, pulse)
if not self._alive then return end
self._msg.Text = text or ""
if pulse then tw(self._msg, {TextTransparency = 0.6}, TI_FAST); task.delay(0.15, function() if self._alive then tw(self._msg, {TextTransparency = 0}, TI_SLOW) end end) end
end
function Notif:SetAccent(color)
if not self._alive then return end
local bar = self._card:FindFirstChild("AccentBar"); if bar then bar.BackgroundColor3 = color end
local db = self._card:FindFirstChild("DurationBar")
if db then local fill = db:FindFirstChildOfClass("Frame"); if fill then fill.BackgroundColor3 = color end end
end
function Notif:Shake()
if not self._alive then return end
local card = self._card; local orig = card.Position
local offsets = {8, -8, 6, -6, 3, -3, 0}
local shakeInfo = TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function runStep(idx)
if not card or not card.Parent then return end
if idx > #offsets then card.Position = orig; return end
local tween = TweenService:Create(card, shakeInfo, { Position = UDim2.new(orig.X.Scale, orig.X.Offset + offsets[idx], orig.Y.Scale, orig.Y.Offset) })
tween.Completed:Connect(function() runStep(idx + 1) end); tween:Play()
end
runStep(1)
end
notifRef = Notif
end)
if not success then
warn("[APTX:Notify] Error creando notificacion: " .. tostring(err)); return nil
end
return notifRef
end

-- ═══════════════════════════════════════════════════════════════
--  UTILIDADES EXPUESTAS
-- ═══════════════════════════════════════════════════════════════
local function formatArgs(...)
local args = {...}; local parts = {}
for i, v in ipairs(args) do
local t = typeof(v)
if t == "string" then
if #v > 80 then table.insert(parts, string.format('"%s..."', v:sub(1, 80))) else table.insert(parts, string.format('"%s"', v)) end
elseif t == "number" or t == "boolean" then table.insert(parts, tostring(v))
elseif t == "table" then
local keys = {}; for k in pairs(v) do table.insert(keys, tostring(k)) end
table.insert(parts, string.format("{%s}", #keys > 0 and table.concat(keys, ",") or "empty"))
elseif t == "Instance" then table.insert(parts, string.format("[%s: %s]", v.ClassName, v.Name))
elseif t == "RBXScriptSignal" then table.insert(parts, "[Signal]")
elseif t == "function" then local info = debug.getinfo(v); table.insert(parts, string.format("[Function: %s]", info.name or "?"))
else table.insert(parts, string.format("[%s]", t)) end
end
return table.concat(parts, ", ")
end

local function safeHook(func, hook)
local ok, orig = pcall(hookfunction, func, hook); if ok then return orig end; return nil
end

local function lastIndexOf(str, char)
for i = #str, 1, -1 do if str:sub(i, i) == char then return i end end; return nil
end

-- ═══════════════════════════════════════════════════════════════
--  FLOATING FRAMES
-- ═══════════════════════════════════════════════════════════════
local FF_Z_BASE = 600

function APTX:FloatingFrame(title, width, height, opts)
local ffRef = nil
local success, err = pcall(function()
opts = opts or {}
local player = Players.LocalPlayer
if not player then Players:GetPropertyChangedSignal("LocalPlayer"):Wait(); player = Players.LocalPlayer end
local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "FFrame_" .. tostring(#APTX._floatingFrames + 1); gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = playerGui
local w = width or 420; local h = height or 300; local headerH = 32
local x = opts.x or (80 + (#APTX._floatingFrames * 30)); local y = opts.y or (80 + (#APTX._floatingFrames * 30))
local frame = newF({
Name = "FloatingFrame", Size = UDim2.new(0, w, 0, h), Position = UDim2.new(0, x, 0, y),
BackgroundColor3 = Theme.FloatingBg, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = FF_Z_BASE + 1,
}, gui)
newC(frame, 10)
local frameStroke = newS(frame, Theme.FloatingBorder, 1)
local shadow = newF({
Size = UDim2.new(1, 12, 1, 12), Position = UDim2.new(0.5, -6, 0.5, -6),
BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = FF_Z_BASE,
}, gui)
newC(shadow, 12)
local posSync = frame:GetPropertyChangedSignal("Position"):Connect(function()
if shadow and shadow.Parent then shadow.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset - 6, frame.Position.Y.Scale, frame.Position.Y.Offset - 6) end
end)
local sizeSync = frame:GetPropertyChangedSignal("Size"):Connect(function()
if shadow and shadow.Parent then shadow.Size = UDim2.new(1, frame.Size.X.Offset + 12, 1, frame.Size.Y.Offset + 12) end
end)
shadow.Size = UDim2.new(1, w + 12, 1, h + 12); shadow.Position = UDim2.new(0, x - 6, 0, y - 6)
local header = newF({
Name = "FFHeader", Size = UDim2.new(1, 0, 0, headerH), BackgroundColor3 = Color3.fromRGB(14, 14, 18),
BorderSizePixel = 0, ZIndex = FF_Z_BASE + 2,
}, frame)
local headerHL = Instance.new("UIStroke")
headerHL.Color = Theme.Highlight; headerHL.Thickness = 1
headerHL.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; headerHL.Transparency = 0.88; headerHL.Parent = header
local titleLbl = newL({
Name = "FFTitle", Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 10, 0, 0),
BackgroundTransparency = 1, Text = title, TextColor3 = Theme.TextPrimary, Font = Enum.Font.GothamBold,
TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = FF_Z_BASE + 3,
}, header)
local btnFrame = newF({ Size = UDim2.new(0, 72, 1, 0), Position = UDim2.new(1, -76, 0, 0), BackgroundTransparency = 1, ZIndex = FF_Z_BASE + 3 }, header)
local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal; btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center; btnLayout.Padding = UDim.new(0, 4); btnLayout.Parent = btnFrame
local pinBtn = newB({
Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1, Text = "📌", TextColor3 = Theme.TextSecondary,
TextSize = 12, Font = Enum.Font.Gotham, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = FF_Z_BASE + 4,
}, btnFrame)
local pinned = false
pinBtn.MouseButton1Click:Connect(function() pinned = not pinned; pinBtn.TextColor3 = pinned and Theme.AccentTint or Theme.TextSecondary end)
local closeBtn = newB({
Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1, Text = "✕", TextColor3 = Theme.TextSecondary,
TextSize = 14, Font = Enum.Font.Gotham, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = FF_Z_BASE + 4,
}, btnFrame)
closeBtn.MouseEnter:Connect(function() tw(closeBtn, {TextColor3 = Theme.Error}, TI_HOVER) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn, {TextColor3 = Theme.TextSecondary}, TI_HOVER) end)
local content = newF({ Name = "FFContent", Size = UDim2.new(1, -4, 1, -(headerH + 4)), Position = UDim2.new(0, 2, 0, headerH + 2), BackgroundTransparency = 1, ZIndex = FF_Z_BASE + 2 }, frame)
local logList = Instance.new("ScrollingFrame")
logList.Name = "FFLogList"; logList.Size = UDim2.new(1, -4, 1, -30); logList.Position = UDim2.new(0, 2, 0, 0)
logList.BackgroundTransparency = 1; logList.BorderSizePixel = 0; logList.ScrollBarThickness = 2
logList.ScrollBarImageColor3 = Theme.BorderHover; logList.ScrollBarImageTransparency = 0.5
logList.ElasticBehavior = Enum.ElasticBehavior.Always; logList.CanvasSize = UDim2.new(0, 0, 0, 0); logList.Parent = content
local logLayout = Instance.new("UIListLayout")
logLayout.SortOrder = Enum.SortOrder.LayoutOrder; logLayout.Padding = UDim.new(0, 1); logLayout.Parent = logList
local logLayoutConn = logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
logList.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 2)
end)
local bottomBar = newF({ Size = UDim2.new(1, -4, 0, 26), Position = UDim2.new(0, 2, 1, -28), BackgroundTransparency = 1, ZIndex = FF_Z_BASE + 3 }, content)
local statusLabel = newL({
Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1, Text = "",
TextColor3 = Theme.TextDisabled, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = FF_Z_BASE + 4,
}, bottomBar)
local autoScroll = true
local autoScrollBtn = newB({
Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(1, -104, 0, 0), BackgroundTransparency = 1,
Text = "AUTO⏺", TextColor3 = Theme.AccentTint, TextSize = 9, Font = Enum.Font.GothamBold,
BorderSizePixel = 0, AutoButtonColor = false, ZIndex = FF_Z_BASE + 4,
}, bottomBar)
autoScrollBtn.MouseButton1Click:Connect(function() autoScroll = not autoScroll; autoScrollBtn.TextColor3 = autoScroll and Theme.AccentTint or Theme.TextDisabled end)
local clearBtn = newB({
Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(1, -52, 0, 0), BackgroundTransparency = 1,
Text = "CLEAR", TextColor3 = Theme.TextSecondary, TextSize = 9, Font = Enum.Font.GothamBold,
BorderSizePixel = 0, AutoButtonColor = false, ZIndex = FF_Z_BASE + 4,
}, bottomBar)
clearBtn.MouseButton1Click:Connect(function()
for _, child in ipairs(logList:GetChildren()) do
if child:IsA("TextLabel") or (child:IsA("Frame") and not child:IsA("UIListLayout")) then child:Destroy() end
end
logLayout.AbsoluteContentSize = UDim2.new(0, 0, 0, 0)
end)
local dragConns = makeDraggable(header, frame)
for _, conn in ipairs(dragConns) do table.insert(APTX._connections, conn) end
local zCounter = FF_Z_BASE + 5
local function bringToFront()
zCounter = zCounter + 1; frame.ZIndex = zCounter; shadow.ZIndex = zCounter - 1
for _, child in ipairs(frame:GetDescendants()) do if child:IsA("GuiObject") then child.ZIndex = child.ZIndex + 2 end end
end
frame.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then bringToFront() end
end)
local _alive = true
closeBtn.MouseButton1Click:Connect(function()
if _alive then
_alive = false
tw(frame, {Size = UDim2.new(0, w, 0, 0), BackgroundTransparency = 1}, TI_MED)
tw(shadow, {BackgroundTransparency = 1}, TI_MED)
task.delay(0.25, function() if gui and gui.Parent then gui:Destroy() end end)
end
end)
local floatingFrame = {
_frame = frame, _gui = gui, _logList = logList, _logLayout = logLayout,
_statusLabel = statusLabel, _autoScroll = autoScroll, _alive = _alive, _pinned = pinned, _visible = true,
AddLog = function(self, text, color, icon)
pcall(function()
if not self._alive then return end
local line = newF({Size = UDim2.new(1, -4, 0, 18), BackgroundTransparency = 1, ZIndex = FF_Z_BASE + 3}, logList)
if icon then newL({Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, 2, 0, 0), BackgroundTransparency = 1, Text = icon, TextColor3 = color or Theme.TextSecondary, TextSize = 10, Font = Enum.Font.Gotham, ZIndex = FF_Z_BASE + 4}, line) end
newL({Size = UDim2.new(1, icon and -22 or -6, 1, 0), Position = UDim2.new(0, icon and 20 or 4, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = color or Theme.LogDefault, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = FF_Z_BASE + 4}, line)
if autoScroll then task.delay(0.02, function() if logList and logList.Parent then logList.CanvasPosition = Vector2.new(0, math.huge) end end) end
end)
end,
AddRichLog = function(self, parts)
pcall(function()
if not self._alive then return end
local line = newF({Size = UDim2.new(1, -4, 0, 18), BackgroundTransparency = 1, ZIndex = FF_Z_BASE + 3}, logList)
local xOff = 4
for _, part in ipairs(parts) do
local seg = newL({Size = UDim2.new(0, part.width or 0, 1, 0), Position = UDim2.new(0, xOff, 0, 0), BackgroundTransparency = 1, Text = part.text or "", TextColor3 = part.color or Theme.LogDefault, TextSize = part.size or 11, Font = part.bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = FF_Z_BASE + 4}, line)
local w = seg.TextBounds.X + 4; seg.Size = UDim2.new(0, w, 1, 0); xOff = xOff + w
end
if autoScroll then task.delay(0.02, function() if logList and logList.Parent then logList.CanvasPosition = Vector2.new(0, math.huge) end end) end
end)
end,
SetStatus = function(self, text, color) pcall(function() if not self._alive then return end; statusLabel.Text = text or ""; statusLabel.TextColor3 = color or Theme.TextDisabled end) end,
Clear = function(self) pcall(function() if not self._alive then return end; for _, child in ipairs(logList:GetChildren()) do if child:IsA("TextLabel") or (child:IsA("Frame") and child.Name ~= "_noop") then pcall(child.Destroy, child) end end end) end,
Show = function(self) if not self._alive then return end; frame.Visible = true; shadow.Visible = true; self._visible = true end,
Hide = function(self) if not self._alive then return end; frame.Visible = false; shadow.Visible = false; self._visible = false end,
Toggle = function(self) if self._visible then self:Hide() else self:Show() end end,
SetTitle = function(self, t) if not self._alive then return end; titleLbl.Text = t or title end,
Destroy = function(self) self._alive = false; if gui and gui.Parent then gui:Destroy() end end,
BringToFront = bringToFront,
IsPinned = function(self) return pinned end,
}
table.insert(APTX._floatingFrames, floatingFrame)
ffRef = floatingFrame
end)
if not success then warn("[APTX:FloatingFrame] Error: " .. tostring(err)); return nil end
return ffRef
end

APTX.Theme = Theme
APTX.Icons = Icons
APTX.ConfigModule = ConfigMod
APTX.FormatArgs = formatArgs
APTX.SafeHook = safeHook
APTX.LastIndexOf = lastIndexOf

return APTX