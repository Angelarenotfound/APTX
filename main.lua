local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/modules/icons.lua"))()

local Theme = {
    TotalBlack = Color3.fromRGB(0, 0, 0),
    Background = Color3.fromRGB(8, 8, 8),
    TopBar = Color3.fromRGB(12, 12, 12),
    Sidebar = Color3.fromRGB(10, 10, 10),
    ContentBg = Color3.fromRGB(8, 8, 8),
    DarkGray = Color3.fromRGB(25, 25, 25),
    Gray = Color3.fromRGB(40, 40, 40),
    LightGray = Color3.fromRGB(60, 60, 60),
    Border = Color3.fromRGB(35, 35, 35),
    Green = Color3.fromRGB(0, 255, 0),
    GreenDark = Color3.fromRGB(0, 200, 0),
    White = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 180),
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
APTX.HideButton = nil
APTX.IsVisible = true

local function log(...)
    if APTX.DevMode then
        print("[APTX]", ...)
    end
end

local function createCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function createStroke(color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return stroke
end

local function tween(object, properties, duration)
    local info = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(object, info, properties):Play()
end

local function createIcon(parent, iconName, size)
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, size or 18, 0, size or 18)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = Theme.White
    icon.Image = Icons[iconName] or ""
    icon.Parent = parent
    return icon
end

function APTX:Config(title, draggable, devmode)
    APTX.Title = title or "APTX GUI"
    APTX.Draggable = draggable ~= false
    APTX.DevMode = devmode == true
    
    log("Inicializando APTX GUI...")
    log("Título:", APTX.Title)
    log("Draggable:", APTX.Draggable)
    log("DevMode:", APTX.DevMode)
    
    APTX:CreateGUI()
    APTX:CreateHideButton()
    
    log("GUI creado exitosamente")
    return APTX
end

function APTX:CreateGUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    if playerGui:FindFirstChild("APTXGui") then
        playerGui.APTXGui:Destroy()
        log("GUI anterior eliminado")
    end
    
    APTX.GUI = Instance.new("ScreenGui")
    APTX.GUI.Name = "APTXGui"
    APTX.GUI.ResetOnSpawn = false
    APTX.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    APTX.GUI.Parent = playerGui
    
    APTX.MainFrame = Instance.new("Frame")
    APTX.MainFrame.Name = "MainFrame"
    APTX.MainFrame.Size = UDim2.new(0, 539, 0, 353)
    APTX.MainFrame.Position = UDim2.new(0.5, -270, 0.5, -177)
    APTX.MainFrame.BackgroundColor3 = Theme.Background
    APTX.MainFrame.BorderSizePixel = 0
    APTX.MainFrame.Parent = APTX.GUI
    
    createCorner(10).Parent = APTX.MainFrame
    createStroke(Theme.Border, 2).Parent = APTX.MainFrame
    
    APTX:CreateTopBar()
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, -40)
    container.Position = UDim2.new(0, 0, 0, 40)
    container.BackgroundTransparency = 1
    container.Parent = APTX.MainFrame
    
    APTX:CreateSidebar(container)
    APTX:CreateContentArea(container)
    
    if APTX.Draggable then
        APTX:MakeDraggable()
        log("GUI draggable activado")
    end
end

function APTX:CreateTopBar()
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Theme.TopBar
    topBar.BorderSizePixel = 0
    topBar.Parent = APTX.MainFrame
    
    createCorner(10).Parent = topBar
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = APTX.Title
    title.TextColor3 = Theme.White
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    
    
    APTX.TopBar = topBar
end

function APTX:CreateSidebar(parent)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0.25, -5, 1, 0)
    sidebar.BackgroundColor3 = Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = parent
    
    createCorner(8).Parent = sidebar
    
    local sectionList = Instance.new("ScrollingFrame")
    sectionList.Name = "SectionList"
    sectionList.Size = UDim2.new(1, -10, 1, -10)
    sectionList.Position = UDim2.new(0, 5, 0, 5)
    sectionList.BackgroundTransparency = 1
    sectionList.BorderSizePixel = 0
    sectionList.ScrollBarThickness = 3
    sectionList.ScrollBarImageColor3 = Theme.Border
    sectionList.CanvasSize = UDim2.new(0, 0, 0, 0)
    sectionList.Parent = sidebar
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = sectionList
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sectionList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    APTX.SectionList = sectionList
end

function APTX:CreateContentArea(parent)
    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    content.Size = UDim2.new(0.75, -5, 1, 0)
    content.Position = UDim2.new(0.25, 5, 0, 0)
    content.BackgroundColor3 = Theme.ContentBg
    content.BorderSizePixel = 0
    content.Parent = parent
    
    createCorner(8).Parent = content
    createStroke(Theme.Border, 1).Parent = content
    
    APTX.ContentArea = content
end

function APTX:CreateHideButton()
    local hideBtn = Instance.new("TextButton")
    hideBtn.Name = "HideButton"
    hideBtn.Size = UDim2.new(0, 45, 0, 45)
    hideBtn.Position = UDim2.new(0, 15, 0, 15)
    hideBtn.BackgroundColor3 = Theme.TopBar
    hideBtn.BorderSizePixel = 0
    hideBtn.Text = ""
    hideBtn.Parent = APTX.GUI
    
    createCorner(8).Parent = hideBtn
    createStroke(Theme.Border, 2).Parent = hideBtn
    
    createIcon(hideBtn, "menu", 24).Position = UDim2.new(0.5, -12, 0.5, -12)
    
    hideBtn.MouseButton1Click:Connect(function()
        APTX:ToggleVisibility()
    end)
    
    hideBtn.MouseEnter:Connect(function()
        tween(hideBtn, {BackgroundColor3 = Theme.Gray})
    end)
    
    hideBtn.MouseLeave:Connect(function()
        tween(hideBtn, {BackgroundColor3 = Theme.TopBar})
    end)
    
    APTX.HideButton = hideBtn
end

function APTX:ToggleVisibility()
    APTX.IsVisible = not APTX.IsVisible
    log("Visibilidad:", APTX.IsVisible)
    
    tween(APTX.MainFrame, {
        Position = APTX.IsVisible 
            and UDim2.new(0.5, -270, 0.5, -177) 
            or UDim2.new(0.5, -270, 1.5, 0)
    }, 0.3)
end

function APTX:MakeDraggable()
    local dragging = false
    local dragInput, dragStart, startPos
    
    APTX.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = APTX.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    APTX.TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            APTX.MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function APTX:Destroy()
    if APTX.GUI then
        APTX.GUI:Destroy()
        log("GUI destruido")
    end
end

function APTX:Section(text, icon, default)
    log("Creando sección:", text)
    
    local section = {
        Name = text,
        Icon = icon,
        Container = nil,
        Button = nil,
    }
    
    section.Button = Instance.new("TextButton")
    section.Button.Name = text
    section.Button.Size = UDim2.new(1, 0, 0, 36)
    section.Button.BackgroundColor3 = Theme.DarkGray
    section.Button.Text = ""
    section.Button.Parent = APTX.SectionList
    
    createCorner(6).Parent = section.Button
    
    if icon then
        local iconImg = createIcon(section.Button, icon, 18)
        iconImg.Position = UDim2.new(0, 8, 0.5, -9)
    end
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 32, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextSecondary
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section.Button
    
    section.Container = Instance.new("ScrollingFrame")
    section.Container.Name = text .. "_Container"
    section.Container.Size = UDim2.new(1, -15, 1, -15)
    section.Container.Position = UDim2.new(0, 8, 0, 8)
    section.Container.BackgroundTransparency = 1
    section.Container.BorderSizePixel = 0
    section.Container.ScrollBarThickness = 3
    section.Container.ScrollBarImageColor3 = Theme.Border
    section.Container.Visible = false
    section.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    section.Container.Parent = APTX.ContentArea
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = section.Container
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        section.Container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    section.Button.MouseButton1Click:Connect(function()
        APTX:SelectSection(text)
    end)
    
    section.Button.MouseEnter:Connect(function()
        if APTX.CurrentSection ~= text then
            tween(section.Button, {BackgroundColor3 = Theme.Gray})
        end
    end)
    
    section.Button.MouseLeave:Connect(function()
        if APTX.CurrentSection ~= text then
            tween(section.Button, {BackgroundColor3 = Theme.DarkGray})
        end
    end)
    
    table.insert(APTX.Sections, section)
    
    if default == true or #APTX.Sections == 1 then
        APTX:SelectSection(text)
    end
    
    return text
end

function APTX:SelectSection(name)
    log("Seleccionando sección:", name)
    
    for _, section in ipairs(APTX.Sections) do
        if section.Name == name then
            section.Container.Visible = true
            section.Button.BackgroundColor3 = Theme.Green
            section.Button.Label.TextColor3 = Theme.TotalBlack
            if section.Button:FindFirstChild("Icon") then
                section.Button.Icon.ImageColor3 = Theme.TotalBlack
            end
            APTX.CurrentSection = name
        else
            section.Container.Visible = false
            section.Button.BackgroundColor3 = Theme.DarkGray
            section.Button.Label.TextColor3 = Theme.TextSecondary
            if section.Button:FindFirstChild("Icon") then
                section.Button.Icon.ImageColor3 = Theme.White
            end
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
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando botón:", text, "en sección:", sectionName)
    
    local button = Instance.new("TextButton")
    button.Name = text
    button.Size = UDim2.new(1, 0, 0, 34)
    button.BackgroundColor3 = Theme.DarkGray
    button.Text = ""
    button.Parent = section.Container
    
    createCorner(6).Parent = button
    
    if icon then
        local iconImg = createIcon(button, icon, 16)
        iconImg.Position = UDim2.new(0, 8, 0.5, -8)
    end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, icon and 30 or 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button
    
    button.MouseButton1Click:Connect(function()
        log("Click en botón:", text)
        tween(button, {BackgroundColor3 = Theme.Green}, 0.1)
        wait(0.15)
        tween(button, {BackgroundColor3 = Theme.Gray}, 0.1)
        if callback then callback() end
    end)
    
    button.MouseEnter:Connect(function()
        tween(button, {BackgroundColor3 = Theme.Gray})
    end)
    
    button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = Theme.DarkGray})
    end)
    
    return button
end

function APTX:Toggle(sectionName, text, icon, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando toggle:", text)
    
    local isOn = default == true
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Theme.DarkGray
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    if icon then
        local iconImg = createIcon(container, icon, 16)
        iconImg.Position = UDim2.new(0, 8, 0.5, -8)
    end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, icon and 30 or 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleSwitch"
    toggleBtn.Size = UDim2.new(0, 42, 0, 22)
    toggleBtn.Position = UDim2.new(1, -48, 0.5, -11)
    toggleBtn.BackgroundColor3 = isOn and Theme.Green or Theme.Gray
    toggleBtn.Text = ""
    toggleBtn.Parent = container
    
    createCorner(11).Parent = toggleBtn
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = isOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    indicator.BackgroundColor3 = Theme.White
    indicator.Parent = toggleBtn
    
    createCorner(9).Parent = indicator
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        log("Toggle:", text, "=", isOn)
        
        tween(indicator, {
            Position = isOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        })
        tween(toggleBtn, {
            BackgroundColor3 = isOn and Theme.Green or Theme.Gray
        })
        
        if callback then callback(isOn) end
    end)
    
    return container
end

function APTX:Slider(sectionName, text, icon, min, max, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando slider:", text)
    
    local value = default or min
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Theme.DarkGray
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 20)
    header.Position = UDim2.new(0, 0, 0, 5)
    header.BackgroundTransparency = 1
    header.Parent = container
    
    if icon then
        local iconImg = createIcon(header, icon, 16)
        iconImg.Position = UDim2.new(0, 8, 0.5, -8)
    end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, icon and 30 or 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 1, 0)
    valueLabel.Position = UDim2.new(1, -65, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Theme.Green
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = header
    
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -16, 0, 8)
    track.Position = UDim2.new(0, 8, 1, -15)
    track.BackgroundColor3 = Theme.Gray
    track.Parent = container
    
    createCorner(4).Parent = track
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Green
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    createCorner(4).Parent = fill
    
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Theme.White
    knob.BorderSizePixel = 0
    knob.Parent = track
    
    createCorner(8).Parent = knob
    
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * pos)
        valueLabel.Text = tostring(value)
        
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -8, 0.5, -8)
        
        if callback then callback(value) end
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    track.InputEnded:Connect(function(input)
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

function APTX:Menu(sectionName, text, placeholder, icon, options, default, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando menú:", text)
    
    local isOpen = false
    local selected = default or options[1]
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = Theme.DarkGray
    container.ClipsDescendants = true
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -20, 0, 28)
    dropBtn.Position = UDim2.new(0, 10, 0, 27)
    dropBtn.BackgroundColor3 = Theme.Gray
    dropBtn.Text = ""
    dropBtn.Parent = container
    
    createCorner(5).Parent = dropBtn
    
    if icon then
        local iconImg = createIcon(dropBtn, icon, 14)
        iconImg.Position = UDim2.new(0, 6, 0.5, -7)
    end
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -50, 1, 0)
    selectedLabel.Position = UDim2.new(0, icon and 26 or 8, 0, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = selected
    selectedLabel.TextColor3 = Theme.White
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.TextSize = 12
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.Parent = dropBtn
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.White
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 10
    arrow.Parent = dropBtn
    
    local optionsList = Instance.new("Frame")
    optionsList.Name = "OptionsList"
    optionsList.Size = UDim2.new(1, -20, 0, 0)
    optionsList.Position = UDim2.new(0, 10, 0, 60)
    optionsList.BackgroundColor3 = Theme.Gray
    optionsList.BorderSizePixel = 0
    optionsList.ClipsDescendants = true
    optionsList.Parent = container
    
    createCorner(5).Parent = optionsList
    createStroke(Theme.Border, 1).Parent = optionsList
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = optionsList
    
    for _, option in ipairs(options) do
        local optionBtn = Instance.new("TextButton")
        optionBtn.Size = UDim2.new(1, 0, 0, 26)
        optionBtn.BackgroundColor3 = Theme.Gray
        optionBtn.Text = "  " .. option
        optionBtn.TextColor3 = Theme.White
        optionBtn.Font = Enum.Font.Gotham
        optionBtn.TextSize = 12
        optionBtn.TextXAlignment = Enum.TextXAlignment.Left
        optionBtn.Parent = optionsList
        
        optionBtn.MouseButton1Click:Connect(function()
            selected = option
            selectedLabel.Text = selected
            log("Menú selección:", option)
            
            if callback then callback(selected) end
            
            isOpen = false
            tween(container, {Size = UDim2.new(1, 0, 0, 60)}, 0.2)
            tween(optionsList, {Size = UDim2.new(1, -20, 0, 0)}, 0.2)
            tween(arrow, {Rotation = 0}, 0.2)
        end)
        
        optionBtn.MouseEnter:Connect(function()
            tween(optionBtn, {BackgroundColor3 = Theme.LightGray})
        end)
        
        optionBtn.MouseLeave:Connect(function()
            tween(optionBtn, {BackgroundColor3 = Theme.Gray})
        end)
    end
    
    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetHeight = isOpen and (60 + #options * 26 + 5) or 60
        local listHeight = isOpen and (#options * 26) or 0
        
        tween(container, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
        tween(optionsList, {Size = UDim2.new(1, -20, 0, listHeight)}, 0.2)
        tween(arrow, {Rotation = isOpen and 180 or 0}, 0.2)
    end)
    
    return container
end

function APTX:Input(sectionName, text, icon, placeholder, callback)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    log("Creando input:", text)
    
    local container = Instance.new("Frame")
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = Theme.DarkGray
    container.Parent = section.Container
    
    createCorner(6).Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.White
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 0, 28)
    inputBox.Position = UDim2.new(0, 10, 0, 27)
    inputBox.BackgroundColor3 = Theme.Gray
    inputBox.PlaceholderText = placeholder or ""
    inputBox.PlaceholderColor3 = Theme.TextSecondary
    inputBox.Text = ""
    inputBox.TextColor3 = Theme.White
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 12
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = container
    
    createCorner(5).Parent = inputBox
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.Parent = inputBox
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and callback then
            log("Input:", text, "=", inputBox.Text)
            callback(inputBox.Text)
        end
    end)
    
    return inputBox
end

function APTX:Label(sectionName, text)
    local section = APTX:GetSection(sectionName)
    if not section then 
        log("ERROR: Sección no encontrada:", sectionName)
        return 
    end
    
    local label = Instance.new("TextLabel")
    label.Name = text
    label.Size = UDim2.new(1, 0, 0, 20)
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

-- ══════════════════════════════════════════════════════════════
--  APTX:Notify  —  Sistema de notificaciones integrado
-- ══════════════════════════════════════════════════════════════

local RunService_N   = game:GetService("RunService")
local UserInputSvc_N = game:GetService("UserInputService")

local _NeonPalettes = {
	warning = { Color3.fromRGB(255, 210, 0),  Color3.fromRGB(255, 120, 0)   },
	success = { Color3.fromRGB(0,   255, 110), Color3.fromRGB(0,   200, 50)  },
	error   = { Color3.fromRGB(255, 40,  40),  Color3.fromRGB(255, 0,   130) },
	neutral = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 160, 255) },
}

local function _ntw(obj, props, t, style, dir)
	local info = TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
	TweenService:Create(obj, info, props):Play()
end

local function _nCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
end

local function _nStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(60, 60, 60)
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function _buildNeon(card, notifType)
	local pal = _NeonPalettes[notifType] or _NeonPalettes.neutral
	local c1, c2 = pal[1], pal[2]
	local ns = Instance.new("UIStroke")
	ns.Thickness = 2.5
	ns.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ns.Color  = c1
	ns.Parent = card
	local t = 0
	local conn = RunService_N.Heartbeat:Connect(function(dt)
		t = (t + dt * 1.4) % 1
		ns.Color = c1:Lerp(c2, math.abs(math.sin(t * math.pi)))
	end)
	return conn
end

local N_SCALE    = 0.85
local N_W        = math.floor(320 * N_SCALE)
local N_TOPBAR_H = math.floor(38  * N_SCALE)
local N_BODY_H   = math.floor(80  * N_SCALE)
local N_BTN_H    = math.floor(48  * N_SCALE)
local N_PAD      = math.floor(14  * N_SCALE)
local N_BTN_W    = math.floor(120 * N_SCALE)
local N_BTN_SZ   = math.floor(30  * N_SCALE)
local N_ICON_SZ  = math.floor(36  * N_SCALE)
local N_AVA_SZ   = math.floor(20  * N_SCALE)

local NC = {
	BG      = Color3.fromRGB(0,   0,   0),
	TOPBAR  = Color3.fromRGB(10,  10,  10),
	DIVIDER = Color3.fromRGB(65,  65,  70),
	ACCENT  = Color3.fromRGB(88,  101, 242),
	NEUTRAL = Color3.fromRGB(72,  72,  80),
	TXT_PRI = Color3.fromRGB(245, 245, 255),
	TXT_SEC = Color3.fromRGB(175, 175, 185),
	CLOSEBG = Color3.fromRGB(45,  45,  50),
	DECLINE = Color3.fromRGB(237, 66,  69),
}

function APTX:Notify(params)
	assert(type(params) == "table",  "[APTX:Notify] params debe ser una tabla")
	assert(params.title,             "[APTX:Notify] params.title es requerido")
	assert(params.content,           "[APTX:Notify] params.content es requerido")

	local title     = params.title
	local body      = params.content
	local iconTop   = params["topbar-icon"]
	local iconBody  = params["content-icon"]
	local duration  = params.duration
	local sound     = params.sound
	local buttons   = params.buttons
	local notifType = params.type or "neutral"

	local hasIconTop  = iconTop  ~= nil and iconTop  ~= ""
	local hasIconBody = iconBody ~= nil and iconBody ~= ""
	local hasButtons  = buttons  ~= nil and #buttons  > 0
	local hasDuration = duration ~= nil and duration  > 0

	local BODY_ACTUAL = hasIconBody and N_BODY_H or math.floor(60 * N_SCALE)
	local BTN_ACTUAL  = hasButtons  and N_BTN_H  or 0
	local CARD_H      = N_TOPBAR_H + BODY_ACTUAL + 2 + BTN_ACTUAL + (hasButtons and 0 or math.floor(6 * N_SCALE))

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local SG = Instance.new("ScreenGui")
	SG.Name           = "APTXNOTIFY"
	SG.ResetOnSpawn   = false
	SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SG.Parent         = playerGui

	local Card = Instance.new("Frame")
	Card.Name              = "Card"
	Card.Size              = UDim2.new(0, N_W, 0, CARD_H)
	Card.Position          = UDim2.new(1, N_W + 20, 1, -(CARD_H + 16))
	Card.BackgroundColor3  = NC.BG
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = SG
	_nCorner(Card, 13)

	local neonConn = _buildNeon(Card, notifType)

	local TB = Instance.new("Frame")
	TB.Name             = "TopBar"
	TB.Size             = UDim2.new(1, 0, 0, N_TOPBAR_H)
	TB.BackgroundColor3 = NC.TOPBAR
	TB.BorderSizePixel  = 0
	TB.ZIndex           = 2
	TB.Parent           = Card
	_nCorner(TB, 13)

	local TBpatch = Instance.new("Frame")
	TBpatch.Size             = UDim2.new(1, 0, 0, 14)
	TBpatch.Position         = UDim2.new(0, 0, 1, -14)
	TBpatch.BackgroundColor3 = NC.TOPBAR
	TBpatch.BorderSizePixel  = 0
	TBpatch.ZIndex           = 2
	TBpatch.Parent           = TB

	local AccLine = Instance.new("Frame")
	AccLine.Size             = UDim2.new(0, 3, 1, 0)
	AccLine.BackgroundColor3 = NC.ACCENT
	AccLine.BorderSizePixel  = 0
	AccLine.ZIndex           = 3
	AccLine.Parent           = TB
	_nCorner(AccLine, 2)

	local AvaImg
	local titleOffsetX = N_PAD + 6

	if hasIconTop then
		local AvaFrame = Instance.new("Frame")
		AvaFrame.Size             = UDim2.new(0, N_AVA_SZ, 0, N_AVA_SZ)
		AvaFrame.Position         = UDim2.new(0, N_PAD - 2, 0.5, 0)
		AvaFrame.AnchorPoint      = Vector2.new(0, 0.5)
		AvaFrame.BackgroundColor3 = NC.ACCENT
		AvaFrame.BorderSizePixel  = 0
		AvaFrame.ZIndex           = 3
		AvaFrame.Parent           = TB
		_nCorner(AvaFrame, 99)

		AvaImg = Instance.new("ImageLabel")
		AvaImg.Size                   = UDim2.new(1, 0, 1, 0)
		AvaImg.BackgroundTransparency = 1
		AvaImg.Image                  = iconTop
		AvaImg.ScaleType              = Enum.ScaleType.Crop
		AvaImg.ZIndex                 = 4
		AvaImg.Parent                 = AvaFrame
		_nCorner(AvaImg, 99)

		titleOffsetX = N_AVA_SZ + N_PAD + 8
	end

	local TitleLbl = Instance.new("TextLabel")
	TitleLbl.Size                   = UDim2.new(1, -(titleOffsetX + 34), 1, 0)
	TitleLbl.Position               = UDim2.new(0, titleOffsetX, 0, 0)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.Text                   = title
	TitleLbl.Font                   = Enum.Font.GothamBold
	TitleLbl.TextSize               = math.floor(12 * N_SCALE)
	TitleLbl.TextColor3             = NC.TXT_PRI
	TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	TitleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	TitleLbl.ZIndex                 = 3
	TitleLbl.Parent                 = TB

	local CloseBtn = Instance.new("ImageButton")
	CloseBtn.Size             = UDim2.new(0, math.floor(24 * N_SCALE), 0, math.floor(24 * N_SCALE))
	CloseBtn.Position         = UDim2.new(1, -math.floor(30 * N_SCALE), 0.5, 0)
	CloseBtn.AnchorPoint      = Vector2.new(0, 0.5)
	CloseBtn.BackgroundColor3 = NC.CLOSEBG
	CloseBtn.Image            = "rbxassetid://7072725342"
	CloseBtn.ImageColor3      = Color3.fromRGB(190, 190, 200)
	CloseBtn.ScaleType        = Enum.ScaleType.Fit
	CloseBtn.BorderSizePixel  = 0
	CloseBtn.AutoButtonColor  = false
	CloseBtn.ZIndex           = 4
	CloseBtn.Parent           = TB
	_nCorner(CloseBtn, 99)

	CloseBtn.MouseEnter:Connect(function()
		_ntw(CloseBtn, {BackgroundColor3 = NC.DECLINE}, 0.15)
	end)
	CloseBtn.MouseLeave:Connect(function()
		_ntw(CloseBtn, {BackgroundColor3 = NC.CLOSEBG}, 0.15)
	end)

	local DivTop = Instance.new("Frame")
	DivTop.Size             = UDim2.new(1, 0, 0, 1)
	DivTop.Position         = UDim2.new(0, 0, 0, N_TOPBAR_H)
	DivTop.BackgroundColor3 = NC.DIVIDER
	DivTop.BorderSizePixel  = 0
	DivTop.ZIndex           = 2
	DivTop.Parent           = Card

	local Body = Instance.new("Frame")
	Body.Size                   = UDim2.new(1, 0, 0, BODY_ACTUAL)
	Body.Position               = UDim2.new(0, 0, 0, N_TOPBAR_H + 1)
	Body.BackgroundTransparency = 1
	Body.ZIndex                 = 2
	Body.Parent                 = Card

	local IconFrame, IconImg
	local msgOffsetX = N_PAD

	if hasIconBody then
		IconFrame = Instance.new("Frame")
		IconFrame.Size             = UDim2.new(0, N_ICON_SZ, 0, N_ICON_SZ)
		IconFrame.Position         = UDim2.new(0, N_PAD, 0.5, 0)
		IconFrame.AnchorPoint      = Vector2.new(0, 0.5)
		IconFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
		IconFrame.BorderSizePixel  = 0
		IconFrame.ZIndex           = 3
		IconFrame.Parent           = Body
		_nCorner(IconFrame, 10)
		_nStroke(IconFrame, NC.ACCENT, 1)

		IconImg = Instance.new("ImageLabel")
		IconImg.Size                   = UDim2.new(0.62, 0, 0.62, 0)
		IconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
		IconImg.Position               = UDim2.new(0.5, 0, 0.5, 0)
		IconImg.BackgroundTransparency = 1
		IconImg.Image                  = iconBody
		IconImg.ImageColor3            = NC.ACCENT
		IconImg.ZIndex                 = 4
		IconImg.Parent                 = IconFrame

		msgOffsetX = N_ICON_SZ + N_PAD + 8
	end

	local MsgLbl = Instance.new("TextLabel")
	MsgLbl.Size                   = UDim2.new(1, -(msgOffsetX + N_PAD), 1, -10)
	MsgLbl.Position               = UDim2.new(0, msgOffsetX, 0, 5)
	MsgLbl.BackgroundTransparency = 1
	MsgLbl.Text                   = body
	MsgLbl.Font                   = Enum.Font.Gotham
	MsgLbl.TextSize               = math.floor(11 * N_SCALE)
	MsgLbl.TextColor3             = NC.TXT_SEC
	MsgLbl.TextWrapped            = true
	MsgLbl.TextXAlignment         = Enum.TextXAlignment.Left
	MsgLbl.TextYAlignment         = Enum.TextYAlignment.Top
	MsgLbl.ZIndex                 = 3
	MsgLbl.Parent                 = Body

	local DividerFill
	if hasButtons or hasDuration then
		local DividerBG = Instance.new("Frame")
		DividerBG.Size             = UDim2.new(1, 0, 0, 2)
		DividerBG.Position         = UDim2.new(0, 0, 0, N_TOPBAR_H + 1 + BODY_ACTUAL)
		DividerBG.BackgroundColor3 = NC.DIVIDER
		DividerBG.BorderSizePixel  = 0
		DividerBG.ZIndex           = 3
		DividerBG.ClipsDescendants = true
		DividerBG.Parent           = Card

		DividerFill = Instance.new("Frame")
		DividerFill.Size             = UDim2.new(1, 0, 1, 0)
		DividerFill.BackgroundColor3 = NC.ACCENT
		DividerFill.BorderSizePixel  = 0
		DividerFill.ZIndex           = 4
		DividerFill.Parent           = DividerBG
	end

	local createdBtns = {}
	if hasButtons then
		local BtnContainer = Instance.new("Frame")
		BtnContainer.Size                   = UDim2.new(1, 0, 0, BTN_ACTUAL)
		BtnContainer.Position               = UDim2.new(0, 0, 0, N_TOPBAR_H + 1 + BODY_ACTUAL + 2)
		BtnContainer.BackgroundTransparency = 1
		BtnContainer.ZIndex                 = 3
		BtnContainer.Parent                 = Card

		local BtnLayout = Instance.new("UIListLayout")
		BtnLayout.FillDirection       = Enum.FillDirection.Horizontal
		BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		BtnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
		BtnLayout.Padding             = UDim.new(0, math.floor(8 * N_SCALE))
		BtnLayout.Parent              = BtnContainer

		for i, bDef in ipairs(buttons) do
			if i > 3 then break end
			local bg = bDef.color or NC.NEUTRAL
			local Btn = Instance.new("TextButton")
			Btn.Size             = UDim2.new(0, N_BTN_W, 0, N_BTN_SZ)
			Btn.BackgroundColor3 = bg
			Btn.Text             = bDef.label or ("Botón " .. i)
			Btn.Font             = Enum.Font.GothamBold
			Btn.TextSize         = math.floor(11 * N_SCALE)
			Btn.TextColor3       = Color3.fromRGB(255, 255, 255)
			Btn.BorderSizePixel  = 0
			Btn.AutoButtonColor  = false
			Btn.ZIndex           = 4
			Btn.Parent           = BtnContainer
			_nCorner(Btn, 7)

			local bs = Instance.new("UIStroke")
			bs.Color        = Color3.new(1, 1, 1)
			bs.Transparency = 0.88
			bs.Thickness    = 1
			bs.Parent       = Btn

			local hoverColor = bg:Lerp(Color3.new(1, 1, 1), 0.18)
			Btn.MouseEnter:Connect(function()
				_ntw(Btn, {BackgroundColor3 = hoverColor}, 0.13)
			end)
			Btn.MouseLeave:Connect(function()
				_ntw(Btn, {BackgroundColor3 = bg}, 0.13)
			end)
			Btn.MouseButton1Down:Connect(function()
				_ntw(Btn, {Size = UDim2.new(0, N_BTN_W - 4, 0, N_BTN_SZ - 3)}, 0.09, Enum.EasingStyle.Quad)
			end)
			Btn.MouseButton1Up:Connect(function()
				_ntw(Btn, {Size = UDim2.new(0, N_BTN_W, 0, N_BTN_SZ)}, 0.14, Enum.EasingStyle.Back)
			end)
			Btn.MouseButton1Click:Connect(function()
				if bDef.callback then task.spawn(bDef.callback) end
			end)
			createdBtns[i] = Btn
		end
	end

	if sound then
		local snd = Instance.new("Sound")
		snd.SoundId = sound
		snd.Volume  = 0.6
		snd.Parent  = SG
		snd:Play()
		game:GetService("Debris"):AddItem(snd, 5)
	end

	local dragging, dragInput, dragStart, startPos
	TB.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = inp.Position
			startPos  = Card.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	TB.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = inp
		end
	end)
	UserInputSvc_N.InputChanged:Connect(function(inp)
		if inp == dragInput and dragging then
			local d = inp.Position - dragStart
			Card.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	local Notif         = {}
	Notif._sg           = SG
	Notif._card         = Card
	Notif._title        = TitleLbl
	Notif._msg          = MsgLbl
	Notif._avaImg       = AvaImg
	Notif._bodyIcon     = IconImg
	Notif._divFill      = DividerFill
	Notif._neonConn     = neonConn
	Notif._alive        = true
	Notif._buttons      = createdBtns
	Notif._accLine      = AccLine
	Notif._iconFrame    = IconFrame

	local function fallClose(cb)
		if not Notif._alive then return end
		Notif._alive = false
		local cur = Card.Position

		_ntw(Card, {
			Position = UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset - math.floor(12 * N_SCALE)),
			Rotation = -2,
		}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.wait(0.17)

		_ntw(Card, {
			Position = UDim2.new(1, N_W + 80, cur.Y.Scale, cur.Y.Offset + math.floor(CARD_H * 0.55)),
			Rotation = 22,
		}, 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		_ntw(Card, {BackgroundTransparency = 0.5}, 0.35, Enum.EasingStyle.Linear)

		task.delay(0.46, function()
			neonConn:Disconnect()
			if cb then pcall(cb) end
			SG:Destroy()
		end)
	end

	task.delay(0.05, function()
		_ntw(Card,
			{Position = UDim2.new(1, -(N_W + 16), 1, -(CARD_H + 16))},
			0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out
		)
	end)

	if hasDuration and DividerFill then
		_ntw(DividerFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)
		task.delay(duration, function()
			if Notif._alive then fallClose() end
		end)
	end

	CloseBtn.MouseButton1Click:Connect(function()
		if Notif._alive then fallClose() end
	end)

	function Notif:Destroy()
		if not self._alive then return end
		fallClose()
	end

	function Notif:Close(callback)
		if not self._alive then return end
		fallClose(callback)
	end

	function Notif:Edit(p)
		if not self._alive then return end
		p = p or {}
		if p.title   then self._title.Text = p.title   end
		if p.content then self._msg.Text   = p.content end
		if p["topbar-icon"]  and self._avaImg   then self._avaImg.Image   = p["topbar-icon"]  end
		if p["content-icon"] and self._bodyIcon then self._bodyIcon.Image = p["content-icon"] end
		if p.resetTimer and p.resetTimer > 0 and self._divFill then
			self._divFill.Size = UDim2.new(1, 0, 1, 0)
			_ntw(self._divFill, {Size = UDim2.new(0, 0, 1, 0)}, p.resetTimer, Enum.EasingStyle.Linear)
			task.delay(p.resetTimer, function()
				if self._alive then fallClose() end
			end)
		end
	end

	function Notif:Flash(flashColor)
		if not self._alive then return end
		local s = self._card:FindFirstChildOfClass("UIStroke")
		if s then
			local orig = s.Color
			s.Color = flashColor or Color3.new(1, 1, 1)
			_ntw(s, {Color = orig}, 0.6, Enum.EasingStyle.Quad)
		end
	end

	function Notif:SetBody(text, pulse)
		if not self._alive then return end
		self._msg.Text = text or ""
		if pulse then
			_ntw(self._msg, {TextTransparency = 0.6}, 0.1)
			task.delay(0.15, function()
				if self._alive then _ntw(self._msg, {TextTransparency = 0}, 0.25) end
			end)
		end
	end

	function Notif:SetAccent(color)
		if not self._alive then return end
		if self._iconFrame then
			local s = self._iconFrame:FindFirstChildOfClass("UIStroke")
			if s then s.Color = color end
		end
		self._accLine.BackgroundColor3 = color
	end

	function Notif:Shake()
		if not self._alive then return end
		local orig = self._card.Position
		for _, ox in ipairs({8, -8, 6, -6, 3, -3, 0}) do
			_ntw(self._card, {
				Position = UDim2.new(orig.X.Scale, orig.X.Offset + ox, orig.Y.Scale, orig.Y.Offset)
			}, 0.04, Enum.EasingStyle.Quad)
			task.wait(0.045)
		end
		self._card.Position = orig
	end

	return Notif
end

return APTX
