--[[
    APTX GUI Library - Professional Roblox GUI Framework
    Características:
    - Sistema de pestañas/secciones con navegación lateral
    - Componentes: Button, Toggle, Slider, Input, Dropdown, Label
    - Librería de iconos Lucide integrada
    - Diseño oscuro profesional y responsivo
    - Código optimizado con funciones reutilizables
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local APTX = {}
APTX.__index = APTX

-- ============================================
-- LIBRERÍA DE ICONOS LUCIDE (IDs de Roblox)
-- ============================================
local LucideIcons = {
    ["home"] = "rbxassetid://10723434711",
    ["settings"] = "rbxassetid://10734950309",
    ["user"] = "rbxassetid://10734942391",
    ["search"] = "rbxassetid://10734898355",
    ["plus"] = "rbxassetid://10734896206",
    ["minus"] = "rbxassetid://10734883356",
    ["x"] = "rbxassetid://10734896206",
    ["check"] = "rbxassetid://10734895566",
    ["arrow-up"] = "rbxassetid://10709790948",
    ["arrow-down"] = "rbxassetid://10709791437",
    ["arrow-left"] = "rbxassetid://10709791016",
    ["arrow-right"] = "rbxassetid://10709790644",
    ["chevron-up"] = "rbxassetid://10709791437",
    ["chevron-down"] = "rbxassetid://10709791437",
    ["chevron-left"] = "rbxassetid://10709791016",
    ["chevron-right"] = "rbxassetid://10709790644",
    ["menu"] = "rbxassetid://10734883356",
    ["star"] = "rbxassetid://10734896629",
    ["heart"] = "rbxassetid://10723434711",
    ["bell"] = "rbxassetid://10723376020",
    ["eye"] = "rbxassetid://10747372167",
    ["eye-off"] = "rbxassetid://10747384394",
    ["lock"] = "rbxassetid://10723407389",
    ["unlock"] = "rbxassetid://10734942991",
    ["info"] = "rbxassetid://10723407389",
    ["help-circle"] = "rbxassetid://10723434711",
    ["trash"] = "rbxassetid://10734896629",
    ["edit"] = "rbxassetid://10734883356",
    ["download"] = "rbxassetid://10723376020",
    ["upload"] = "rbxassetid://10734942991",
    ["file"] = "rbxassetid://10723404337",
    ["folder"] = "rbxassetid://10723404911",
    ["image"] = "rbxassetid://10723407389",
    ["video"] = "rbxassetid://10734942391",
    ["music"] = "rbxassetid://10734883356",
    ["mic"] = "rbxassetid://10734883356",
    ["camera"] = "rbxassetid://10723376020",
    ["phone"] = "rbxassetid://10734896206",
    ["mail"] = "rbxassetid://10734883356",
    ["send"] = "rbxassetid://10734898355",
    ["share"] = "rbxassetid://10734950309",
    ["link"] = "rbxassetid://10723426722",
    ["external-link"] = "rbxassetid://10723404337",
    ["cloud"] = "rbxassetid://10723376020",
    ["shield"] = "rbxassetid://10734950309",
    ["alert-circle"] = "rbxassetid://10723376020",
    ["alert-triangle"] = "rbxassetid://10723376020",
    ["refresh"] = "rbxassetid://10734898355",
    ["maximize"] = "rbxassetid://10734883356",
    ["minimize"] = "rbxassetid://10734883356",
}

-- ============================================
-- CONFIGURACIÓN DE COLORES Y ESTILOS
-- ============================================
local Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    TopBar = Color3.fromRGB(25, 25, 30),
    Sidebar = Color3.fromRGB(20, 20, 25),
    ContentBg = Color3.fromRGB(18, 18, 23),
    Border = Color3.fromRGB(45, 45, 50),
    Primary = Color3.fromRGB(100, 100, 255),
    PrimaryHover = Color3.fromRGB(120, 120, 255),
    Success = Color3.fromRGB(50, 200, 100),
    Text = Color3.fromRGB(245, 245, 255),
    TextSecondary = Color3.fromRGB(160, 160, 170),
    ButtonNormal = Color3.fromRGB(40, 40, 45),
    ButtonHover = Color3.fromRGB(50, 50, 60),
    SliderTrack = Color3.fromRGB(35, 35, 40),
    SliderFill = Color3.fromRGB(100, 100, 255),
}

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================

local function createCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function createStroke(color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return stroke
end

local function tween(object, properties, duration, style)
    local info = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(object, info, properties)
    tw:Play()
    return tw
end

local function createIcon(parent, iconName, size)
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, size or 20, 0, size or 20)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = Theme.Text
    icon.Image = LucideIcons[iconName] or ""
    icon.Parent = parent
    return icon
end

-- ============================================
-- CLASE PRINCIPAL APTX
-- ============================================

function APTX.new()
    local self = setmetatable({}, APTX)
    self.Sections = {}
    self.CurrentSection = nil
    self.IsVisible = true
    self.IconMode = "default"
    return self
end

function APTX:Config(config)
    config = config or {}
    self.IconMode = config.icons or "default"
    local showHideButton = config.hidebutton ~= false
    
    self:CreateGUI()
    
    if showHideButton then
        self:CreateHideButton()
    end
    
    return self
end

function APTX:CreateGUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Limpiar GUI anterior si existe
    local existing = playerGui:FindFirstChild("APTXGui")
    if existing then existing:Destroy() end
    
    -- ScreenGui principal
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "APTXGui"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.Parent = playerGui
    
    -- Frame principal (tamaño adaptado a pantallas)
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Size = UDim2.new(0, 650, 0, 420)
    self.MainFrame.Position = UDim2.new(0.5, -325, 0.5, -210)
    self.MainFrame.BackgroundColor3 = Theme.Background
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Parent = self.ScreenGui
    
    createCorner(8).Parent = self.MainFrame
    createStroke(Theme.Border, 1).Parent = self.MainFrame
    
    -- TopBar
    self:CreateTopBar()
    
    -- Contenedor de contenido
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -35)
    contentContainer.Position = UDim2.new(0, 0, 0, 35)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = self.MainFrame
    
    -- Sidebar (25%)
    self:CreateSidebar(contentContainer)
    
    -- Área de contenido (75%)
    self:CreateContentArea(contentContainer)
    
    -- Hacer el GUI draggable
    self:MakeDraggable(self.TopBar)
end

function APTX:CreateTopBar()
    self.TopBar = Instance.new("Frame")
    self.TopBar.Name = "TopBar"
    self.TopBar.Size = UDim2.new(1, 0, 0, 35)
    self.TopBar.BackgroundColor3 = Theme.TopBar
    self.TopBar.BorderSizePixel = 0
    self.TopBar.Parent = self.MainFrame
    
    createCorner(8).Parent = self.TopBar
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "APTX Framework"
    title.TextColor3 = Theme.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = self.TopBar
    
    -- Botón de cerrar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 25)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Theme.ButtonNormal
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = self.TopBar
    
    createCorner(4).Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, {BackgroundColor3 = Theme.ButtonHover})
    end)
    
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, {BackgroundColor3 = Theme.ButtonNormal})
    end)
end

function APTX:CreateSidebar(parent)
    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Name = "Sidebar"
    self.Sidebar.Size = UDim2.new(0.25, 0, 1, 0)
    self.Sidebar.BackgroundColor3 = Theme.Sidebar
    self.Sidebar.BorderSizePixel = 0
    self.Sidebar.Parent = parent
    
    -- Contenedor con scroll
    self.SectionList = Instance.new("ScrollingFrame")
    self.SectionList.Name = "SectionList"
    self.SectionList.Size = UDim2.new(1, -10, 1, -10)
    self.SectionList.Position = UDim2.new(0, 5, 0, 5)
    self.SectionList.BackgroundTransparency = 1
    self.SectionList.BorderSizePixel = 0
    self.SectionList.ScrollBarThickness = 4
    self.SectionList.ScrollBarImageColor3 = Theme.Border
    self.SectionList.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.SectionList.Parent = self.Sidebar
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = self.SectionList
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.SectionList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
end

function APTX:CreateContentArea(parent)
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "ContentArea"
    self.ContentArea.Size = UDim2.new(0.75, 0, 1, 0)
    self.ContentArea.Position = UDim2.new(0.25, 0, 0, 0)
    self.ContentArea.BackgroundColor3 = Theme.ContentBg
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.Parent = parent
end

function APTX:CreateHideButton()
    local hideBtn = Instance.new("TextButton")
    hideBtn.Name = "HideButton"
    hideBtn.Size = UDim2.new(0, 45, 0, 45)
    hideBtn.Position = UDim2.new(0, 15, 0, 15)
    hideBtn.BackgroundColor3 = Theme.TopBar
    hideBtn.BorderSizePixel = 0
    hideBtn.Text = ""
    hideBtn.Parent = self.ScreenGui
    
    createCorner(8).Parent = hideBtn
    createStroke(Theme.Border, 1).Parent = hideBtn
    
    createIcon(hideBtn, "menu", 24).Position = UDim2.new(0.5, -12, 0.5, -12)
    
    hideBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    hideBtn.MouseEnter:Connect(function()
        tween(hideBtn, {BackgroundColor3 = Theme.ButtonHover})
    end)
    
    hideBtn.MouseLeave:Connect(function()
        tween(hideBtn, {BackgroundColor3 = Theme.TopBar})
    end)
end

function APTX:MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function APTX:Toggle()
    self.IsVisible = not self.IsVisible
    tween(self.MainFrame, {
        Position = self.IsVisible 
            and UDim2.new(0.5, -325, 0.5, -210) 
            or UDim2.new(0.5, -325, 1.5, 0)
    }, 0.3, Enum.EasingStyle.Back)
end

-- ============================================
-- SISTEMA DE SECCIONES
-- ============================================

function APTX:AddSection(name, icon)
    local section = {
        Name = name,
        Icon = icon or "home",
        Container = nil,
        Button = nil,
        Elements = {}
    }
    
    -- Botón de sección en sidebar
    section.Button = Instance.new("TextButton")
    section.Button.Name = name
    section.Button.Size = UDim2.new(1, -10, 0, 35)
    section.Button.BackgroundColor3 = Theme.ButtonNormal
    section.Button.Text = ""
    section.Button.Parent = self.SectionList
    
    createCorner(6).Parent = section.Button
    
    -- Icono
    if self.IconMode == "default" then
        createIcon(section.Button, section.Icon, 18).Position = UDim2.new(0, 8, 0.5, -9)
    end
    
    -- Texto
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -35, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.TextSecondary
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section.Button
    
    -- Contenedor de elementos
    section.Container = Instance.new("ScrollingFrame")
    section.Container.Name = name .. "Container"
    section.Container.Size = UDim2.new(1, -20, 1, -20)
    section.Container.Position = UDim2.new(0, 10, 0, 10)
    section.Container.BackgroundTransparency = 1
    section.Container.BorderSizePixel = 0
    section.Container.ScrollBarThickness = 4
    section.Container.ScrollBarImageColor3 = Theme.Border
    section.Container.Visible = false
    section.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    section.Container.Parent = self.ContentArea
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = section.Container
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        section.Container.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Evento de click
    section.Button.MouseButton1Click:Connect(function()
        self:SelectSection(name)
    end)
    
    section.Button.MouseEnter:Connect(function()
        if self.CurrentSection ~= name then
            tween(section.Button, {BackgroundColor3 = Theme.ButtonHover})
        end
    end)
    
    section.Button.MouseLeave:Connect(function()
        if self.CurrentSection ~= name then
            tween(section.Button, {BackgroundColor3 = Theme.ButtonNormal})
        end
    end)
    
    table.insert(self.Sections, section)
    
    -- Seleccionar primera sección automáticamente
    if #self.Sections == 1 then
        self:SelectSection(name)
    end
    
    return setmetatable({
        _section = section,
        _aptx = self
    }, {__index = self})
end

function APTX:SelectSection(name)
    for _, section in ipairs(self.Sections) do
        if section.Name == name then
            section.Container.Visible = true
            section.Button.BackgroundColor3 = Theme.Primary
            section.Button.Label.TextColor3 = Theme.Text
            self.CurrentSection = name
        else
            section.Container.Visible = false
            section.Button.BackgroundColor3 = Theme.ButtonNormal
            section.Button.Label.TextColor3 = Theme.TextSecondary
        end
    end
end

-- ============================================
-- COMPONENTES DE UI
-- ============================================

function APTX:AddButton(text, callback)
    local section = self._section
    
    local button = Instance.new("TextButton")
    button.Name = text
    button.Size = UDim2.new(1, 0, 0, 32)
    button.BackgroundColor3 = Theme.ButtonNormal
    button.Text = text
    button.TextColor3 = Theme.Text
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    button.Parent = section.Container
    
    createCorner(6).Parent = button
    
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
        tween(button, {BackgroundColor3 = Theme.Primary}, 0.1)
        wait(0.1)
        tween(button, {BackgroundColor3 = Theme.ButtonHover}, 0.1)
    end)
    
    button.MouseEnter:Connect(function()
        tween(button, {BackgroundColor3 = Theme.ButtonHover})
    end)
    
    button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = Theme.ButtonNormal})
    end)
    
    return button
end

function APTX:AddToggle(text, default, callback)
    local section = self._section
    local isOn = default or false
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = Theme.ButtonNormal
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Size = UDim2.new(0, 38, 0, 20)
    toggleBtn.Position = UDim2.new(1, -45, 0.5, -10)
    toggleBtn.BackgroundColor3 = isOn and Theme.Success or Theme.SliderTrack
    toggleBtn.Text = ""
    toggleBtn.Parent = container
    
    createCorner(10).Parent = toggleBtn
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 16, 0, 16)
    indicator.Position = isOn and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.Parent = toggleBtn
    
    createCorner(8).Parent = indicator
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        tween(indicator, {
            Position = isOn and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        })
        tween(toggleBtn, {
            BackgroundColor3 = isOn and Theme.Success or Theme.SliderTrack
        })
        if callback then callback(isOn) end
    end)
    
    return container
end

function APTX:AddSlider(text, min, max, default, callback)
    local section = self._section
    local value = default or min
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 45)
    container.BackgroundColor3 = Theme.ButtonNormal
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -55, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Theme.Primary
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Name = "Track"
    sliderTrack.Size = UDim2.new(1, -20, 0, 6)
    sliderTrack.Position = UDim2.new(0, 10, 1, -12)
    sliderTrack.BackgroundColor3 = Theme.SliderTrack
    sliderTrack.Parent = container
    
    createCorner(3).Parent = sliderTrack
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.SliderFill
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack
    
    createCorner(3).Parent = sliderFill
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Name = "Knob"
    sliderKnob.Size = UDim2.new(0, 14, 0, 14)
    sliderKnob.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Parent = sliderTrack
    
    createCorner(7).Parent = sliderKnob
    
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * pos)
        valueLabel.Text = tostring(value)
        
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        sliderKnob.Position = UDim2.new(pos, -7, 0.5, -7)
        
        if callback then callback(value) end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    sliderTrack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    return container
end

function APTX:AddInput(text, placeholder, callback)
    local section = self._section
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 55)
    container.BackgroundColor3 = Theme.ButtonNormal
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 0, 25)
    inputBox.Position = UDim2.new(0, 10, 0, 25)
    inputBox.BackgroundColor3 = Theme.SliderTrack
    inputBox.PlaceholderText = placeholder or ""
    inputBox.PlaceholderColor3 = Theme.TextSecondary
    inputBox.Text = ""
    inputBox.TextColor3 = Theme.Text
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 12
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = container
    
    createCorner(4).Parent = inputBox
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if callback and enterPressed then
            callback(inputBox.Text)
        end
    end)
    
    return inputBox
end

function APTX:AddLabel(text)
    local section = self._section
    
    local label = Instance.new("TextLabel")
    label.Name = text
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextSecondary
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = section.Container
    
    return label
end

function APTX:AddDropdown(text, options, default, callback)
    local section = self._section
    local isOpen = false
    local selected = default or options[1]
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 55)
    container.BackgroundColor3 = Theme.ButtonNormal
    container.ClipsDescendants = true
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(1, -20, 0, 25)
    dropdownBtn.Position = UDim2.new(0, 10, 0, 25)
    dropdownBtn.BackgroundColor3 = Theme.SliderTrack
    dropdownBtn.Text = "  " .. selected
    dropdownBtn.TextColor3 = Theme.Text
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 12
    dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropdownBtn.Parent = container
    
    createCorner(4).Parent = dropdownBtn
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.Text
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 10
    arrow.Parent = dropdownBtn
    
    local optionsList = Instance.new("Frame")
    optionsList.Name = "OptionsList"
    optionsList.Size = UDim2.new(1, -20, 0, 0)
    optionsList.Position = UDim2.new(0, 10, 0, 55)
    optionsList.BackgroundColor3 = Theme.SliderTrack
    optionsList.BorderSizePixel = 0
    optionsList.ClipsDescendants = true
    optionsList.Parent = container
    
    createCorner(4).Parent = optionsList
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = optionsList
    
    for _, option in ipairs(options) do
        local optionBtn = Instance.new("TextButton")
        optionBtn.Size = UDim2.new(1, 0, 0, 25)
        optionBtn.BackgroundColor3 = Theme.SliderTrack
        optionBtn.Text = "  " .. option
        optionBtn.TextColor3 = Theme.Text
        optionBtn.Font = Enum.Font.Gotham
        optionBtn.TextSize = 12
        optionBtn.TextXAlignment = Enum.TextXAlignment.Left
        optionBtn.Parent = optionsList
        
        optionBtn.MouseButton1Click:Connect(function()
            selected = option
            dropdownBtn.Text = "  " .. selected
            if callback then callback(selected) end
            
            isOpen = false
            tween(container, {Size = UDim2.new(1, 0, 0, 55)}, 0.2)
            tween(optionsList, {Size = UDim2.new(1, -20, 0, 0)}, 0.2)
            tween(arrow, {Rotation = 0}, 0.2)
        end)
        
        optionBtn.MouseEnter:Connect(function()
            tween(optionBtn, {BackgroundColor3 = Theme.ButtonHover})
        end)
        
        optionBtn.MouseLeave:Connect(function()
            tween(optionBtn, {BackgroundColor3 = Theme.SliderTrack})
        end)
    end
    
    dropdownBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetHeight = isOpen and (55 + #options * 25) or 55
        local listHeight = isOpen and (#options * 25) or 0
        
        tween(container, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
        tween(optionsList, {Size = UDim2.new(1, -20, 0, listHeight)}, 0.2)
        tween(arrow, {Rotation = isOpen and 180 or 0}, 0.2)
    end)
    
    return container
end

return APTX
