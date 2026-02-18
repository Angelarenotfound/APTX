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
    log("Titulo:", APTX.Title)
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
    log("Creando seccion:", text)
    
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
    log("Seleccionando seccion:", name)
    
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
        log("ERROR: Seccion no encontrada:", sectionName)
        return 
    end
    
    log("Creando boton:", text, "en seccion:", sectionName)
    
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
        log("Click en boton:", text)
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
        log("ERROR: Seccion no encontrada:", sectionName)
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
        log("ERROR: Seccion no encontrada:", sectionName)
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
        log("ERROR: Seccion no encontrada:", sectionName)
        return 
    end
    
    log("Creando menu:", text)
    
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
    arrow.Text = "v"
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
            log("Menu seleccion:", option)
            
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
        log("ERROR: Seccion no encontrada:", sectionName)
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
        log("ERROR: Seccion no encontrada:", sectionName)
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
--  APTX:Notify  (with size, flush-right, stackable)
-- ══════════════════════════════════════════════════════════════

local RunService = game:GetService("RunService")

local N_PALETTES = {
	warning = { Color3.fromRGB(255,210,0),   Color3.fromRGB(255,120,0)   },
	success = { Color3.fromRGB(0,255,110),   Color3.fromRGB(0,200,50)    },
	error   = { Color3.fromRGB(255,40,40),   Color3.fromRGB(255,0,130)   },
	neutral = { Color3.fromRGB(255,255,255), Color3.fromRGB(160,160,255) },
}

local NC = {
	BG      = Color3.fromRGB(0,  0,  0),
	TOPBAR  = Color3.fromRGB(10, 10, 10),
	DIVIDER = Color3.fromRGB(65, 65, 70),
	ACCENT  = Color3.fromRGB(88, 101,242),
	NEUTRAL = Color3.fromRGB(72, 72, 80),
	TXT_PRI = Color3.fromRGB(245,245,255),
	TXT_SEC = Color3.fromRGB(175,175,185),
	CLOSEBG = Color3.fromRGB(45, 45, 50),
	DECLINE = Color3.fromRGB(237,66, 69),
}

local NV = {
	W      = 272, TOPBAR = 32, BODY = 68, BODY_SLIM = 56,
	BTN_H  = 41,  PAD    = 12, BTN_W = 102, BTN_SZ = 26,
	ICON   = 31,  AVA    = 17,
}

-- Stack tracking: active notifications listed bottom-to-top
local NotifStack = {}
local NOTIF_GAP  = 6   -- gap between stacked notifications
local NOTIF_RIGHT_MARGIN = 5  -- 30% closer to right edge (was ~16px, now ~5px)

local function ntw(obj, props, t, style, dir)
	TweenService:Create(obj,
		TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
		props):Play()
end

local function nMake(cls, props, parent)
	local i = Instance.new(cls)
	for k, v in pairs(props) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

local function nCorner(parent, r)
	nMake("UICorner", {CornerRadius = UDim.new(0, r or 10)}, parent)
end

local function nStroke(parent, color, thick)
	nMake("UIStroke", {
		Color = color or Color3.fromRGB(60,60,60),
		Thickness = thick or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	}, parent)
end

local function nNeon(card, notifType)
	local pal = N_PALETTES[notifType] or N_PALETTES.neutral
	local c1, c2, t = pal[1], pal[2], 0
	local ns = nMake("UIStroke", {
		Thickness = 2.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = c1,
	}, card)
	local conn = RunService.Heartbeat:Connect(function(dt)
		t = (t + dt * 1.4) % 1
		ns.Color = c1:Lerp(c2, math.abs(math.sin(t * math.pi)))
	end)
	return conn
end

local function nImg(parent, img, props)
	return nMake("ImageLabel", {
		BackgroundTransparency = 1,
		Image = img or "",
		ScaleType = Enum.ScaleType.Fit,
	}, nil)
end

local function nBtn(parent, bg, text, textSize)
	local b = nMake("TextButton", {
		Size = UDim2.new(0, NV.BTN_W, 0, NV.BTN_SZ),
		BackgroundColor3 = bg,
		Text = text or "",
		Font = Enum.Font.GothamBold,
		TextSize = textSize or 10,
		TextColor3 = Color3.new(1,1,1),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ZIndex = 4,
	}, parent)
	nCorner(b, 7)
	nMake("UIStroke", {Color=Color3.new(1,1,1), Transparency=0.88, Thickness=1}, b)
	return b
end

local function nHover(btn, normal, hover)
	btn.MouseEnter:Connect(function() ntw(btn, {BackgroundColor3=hover}, 0.13) end)
	btn.MouseLeave:Connect(function() ntw(btn, {BackgroundColor3=normal}, 0.13) end)
end

local function nDraggable(handle, card)
	local drag, input, start, sPos
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag, start, sPos = true, i.Position, card.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then drag = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then input = i end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if i == input and drag then
			local d = i.Position - start
			card.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset+d.X, sPos.Y.Scale, sPos.Y.Offset+d.Y)
		end
	end)
end

-- Recalculate positions for all active stacked notifications
local function repositionStack()
	local bottomOffset = NOTIF_RIGHT_MARGIN  -- small bottom margin
	for idx = 1, #NotifStack do
		local entry = NotifStack[idx]
		if entry and entry._alive and entry._card and entry._card.Parent then
			local scaledH = entry._scaledH
			local scaledW = entry._scaledW or math.floor(NV.W)
			local targetX = -(scaledW + NOTIF_RIGHT_MARGIN)
			local targetY = -(bottomOffset + scaledH)
			ntw(entry._card, {
				Position = UDim2.new(1, targetX, 1, targetY)
			}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			bottomOffset = bottomOffset + scaledH + NOTIF_GAP
		end
	end
end

-- Remove a notification from the stack and reposition
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
	assert(params.title,            "[APTX:Notify] params.title es requerido")
	assert(params.content,          "[APTX:Notify] params.content es requerido")

	local title      = params.title
	local body       = params.content
	local iconTop    = params["topbar-icon"]
	local iconBody   = params["content-icon"]
	local duration   = params.duration
	local sound      = params.sound
	local buttons    = params.buttons
	local notifType  = params.type or "neutral"
	local size       = params.size or 1  -- NEW: scale factor (1 = default, 0.5 = half, etc.)

	local hasTIcon   = iconTop  and iconTop  ~= ""
	local hasBIcon   = iconBody and iconBody ~= ""
	local hasBtns    = buttons  and #buttons  > 0
	local hasDur     = duration and duration  > 0

	-- Scale all dimensions by the size parameter
	local sW      = math.floor(NV.W * size)
	local sTOPBAR = math.floor(NV.TOPBAR * size)
	local sBODY   = math.floor((hasBIcon and NV.BODY or NV.BODY_SLIM) * size)
	local sBTN_H  = math.floor(NV.BTN_H * size)
	local sPAD    = math.floor(NV.PAD * size)
	local sBTN_W  = math.floor(NV.BTN_W * size)
	local sBTN_SZ = math.floor(NV.BTN_SZ * size)
	local sICON   = math.floor(NV.ICON * size)
	local sAVA    = math.floor(NV.AVA * size)

	local btnH   = hasBtns  and sBTN_H or 0
	local CARD_H = sTOPBAR + 1 + sBODY + (hasBtns and (2 + btnH) or math.floor(6 * size))

	-- Font sizes scaled
	local titleFontSize = math.max(8, math.floor(11 * size))
	local bodyFontSize  = math.max(7, math.floor(10 * size))
	local btnFontSize   = math.max(7, math.floor(10 * size))

	assert(APTX.GUI, "[APTX:Notify] Llama APTX:Config() antes de usar Notify")
	local gui = APTX.GUI

	-- Card starts off-screen to the right, flush to the right edge (offset 0)
	local Card = nMake("Frame", {
		Name = "NotifCard_"..tostring(tick()),
		Size = UDim2.new(0, sW, 0, CARD_H),
		Position = UDim2.new(1, sW + 20, 1, -CARD_H),  -- off-screen right
		BackgroundColor3 = NC.BG,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 10,
	}, gui)
	nCorner(Card, math.floor(13 * size))
	local neonConn = nNeon(Card, notifType)

	-- TopBar
	local TB = nMake("Frame", {
		Size = UDim2.new(1, 0, 0, sTOPBAR),
		BackgroundColor3 = NC.TOPBAR,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, Card)
	nCorner(TB, math.floor(13 * size))
	nMake("Frame", {
		Size = UDim2.new(1, 0, 0, math.floor(13 * size)),
		Position = UDim2.new(0, 0, 1, -math.floor(13 * size)),
		BackgroundColor3 = NC.TOPBAR,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, TB)

	-- TopBar icon (optional)
	local AvaImg
	local titleX = sPAD
	if hasTIcon then
		local af = nMake("Frame", {
			Size = UDim2.new(0, sAVA, 0, sAVA),
			Position = UDim2.new(0, sPAD, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = NC.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 12,
		}, TB)
		nCorner(af, 99)
		AvaImg = nMake("ImageLabel", {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Image = iconTop,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = 13,
		}, af)
		nCorner(AvaImg, 99)
		titleX = sAVA + sPAD + math.floor(6 * size)
	end

	-- Title
	local closeBtnSize = math.floor(20 * size)
	local TitleLbl = nMake("TextLabel", {
		Size = UDim2.new(1, -(titleX + math.floor(30 * size)), 1, 0),
		Position = UDim2.new(0, titleX, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = titleFontSize,
		TextColor3 = NC.TXT_PRI,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
	}, TB)

	-- Close button
	local CloseBtn = nMake("ImageButton", {
		Size = UDim2.new(0, closeBtnSize, 0, closeBtnSize),
		Position = UDim2.new(1, -(closeBtnSize + math.floor(6 * size)), 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = NC.CLOSEBG,
		Image = "rbxassetid://7072725342",
		ImageColor3 = Color3.fromRGB(190,190,200),
		ScaleType = Enum.ScaleType.Fit,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ZIndex = 13,
	}, TB)
	nCorner(CloseBtn, 99)
	nHover(CloseBtn, NC.CLOSEBG, NC.DECLINE)

	-- Divider topbar/body
	nMake("Frame", {
		Size = UDim2.new(1,0,0,1),
		Position = UDim2.new(0,0,0,sTOPBAR),
		BackgroundColor3 = NC.DIVIDER,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, Card)

	-- Body
	local Body = nMake("Frame", {
		Size = UDim2.new(1, 0, 0, sBODY),
		Position = UDim2.new(0, 0, 0, sTOPBAR + 1),
		BackgroundTransparency = 1,
		ZIndex = 11,
	}, Card)

	-- Body icon (optional)
	local IconFrame, IconImg
	local msgX = sPAD
	if hasBIcon then
		IconFrame = nMake("Frame", {
			Size = UDim2.new(0, sICON, 0, sICON),
			Position = UDim2.new(0, sPAD, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(18,18,20),
			BorderSizePixel = 0,
			ZIndex = 12,
		}, Body)
		nCorner(IconFrame, math.floor(10 * size))
		nStroke(IconFrame, NC.ACCENT, 1)
		IconImg = nMake("ImageLabel", {
			Size = UDim2.new(0.62,0,0.62,0),
			AnchorPoint = Vector2.new(0.5,0.5),
			Position = UDim2.new(0.5,0,0.5,0),
			BackgroundTransparency = 1,
			Image = iconBody,
			ImageColor3 = NC.ACCENT,
			ZIndex = 13,
		}, IconFrame)
		msgX = sICON + sPAD + math.floor(6 * size)
	end

	-- Message
	local MsgLbl = nMake("TextLabel", {
		Size = UDim2.new(1, -(msgX + sPAD), 1, -math.floor(8 * size)),
		Position = UDim2.new(0, msgX, 0, math.floor(4 * size)),
		BackgroundTransparency = 1,
		Text = body,
		Font = Enum.Font.Gotham,
		TextSize = bodyFontSize,
		TextColor3 = NC.TXT_SEC,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 12,
	}, Body)

	-- Progress divider
	local DividerFill
	if hasBtns or hasDur then
		local db = nMake("Frame", {
			Size = UDim2.new(1,0,0,2),
			Position = UDim2.new(0,0,0, sTOPBAR + 1 + sBODY),
			BackgroundColor3 = NC.DIVIDER,
			BorderSizePixel = 0,
			ZIndex = 11,
			ClipsDescendants = true,
		}, Card)
		DividerFill = nMake("Frame", {
			Size = UDim2.new(1,0,1,0),
			BackgroundColor3 = NC.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 12,
		}, db)
	end

	-- Buttons (optional)
	if hasBtns then
		local bc = nMake("Frame", {
			Size = UDim2.new(1,0,0,btnH),
			Position = UDim2.new(0,0,0, sTOPBAR + 1 + sBODY + 2),
			BackgroundTransparency = 1,
			ZIndex = 11,
		}, Card)
		local bl = nMake("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, math.floor(7 * size)),
		}, bc)

		for i = 1, math.min(#buttons, 3) do
			local bDef = buttons[i]
			local bg = bDef.color or NC.NEUTRAL
			local Btn = nMake("TextButton", {
				Size = UDim2.new(0, sBTN_W, 0, sBTN_SZ),
				BackgroundColor3 = bg,
				Text = bDef.label or ("Boton "..i),
				Font = Enum.Font.GothamBold,
				TextSize = btnFontSize,
				TextColor3 = Color3.new(1,1,1),
				BorderSizePixel = 0,
				AutoButtonColor = false,
				ZIndex = 4,
			}, bc)
			nCorner(Btn, math.floor(7 * size))
			nMake("UIStroke", {Color=Color3.new(1,1,1), Transparency=0.88, Thickness=1}, Btn)
			nHover(Btn, bg, bg:Lerp(Color3.new(1,1,1), 0.18))
			Btn.MouseButton1Down:Connect(function()
				ntw(Btn, {Size = UDim2.new(0, sBTN_W-4, 0, sBTN_SZ-2)}, 0.09, Enum.EasingStyle.Quad)
			end)
			Btn.MouseButton1Up:Connect(function()
				ntw(Btn, {Size = UDim2.new(0, sBTN_W, 0, sBTN_SZ)}, 0.14, Enum.EasingStyle.Back)
			end)
			Btn.MouseButton1Click:Connect(function()
				if bDef.callback then task.spawn(bDef.callback) end
			end)
		end
	end

	-- Sound (optional)
	if sound then
		local snd = nMake("Sound", {SoundId=sound, Volume=0.6}, gui)
		snd:Play()
		game:GetService("Debris"):AddItem(snd, 5)
	end

	nDraggable(TB, Card)

	-- Notif object
	local Notif = {
		_card = Card, _title = TitleLbl, _msg = MsgLbl,
		_avaImg = AvaImg, _bodyIcon = IconImg,
		_divFill = DividerFill, _neonConn = neonConn,
		_iconFrame = IconFrame, _alive = true,
		_scaledH = CARD_H,  -- store for stack repositioning
		_scaledW = sW,      -- store width for stack repositioning
	}

	-- Add to stack
	table.insert(NotifStack, Notif)

	local function fallClose(cb)
		if not Notif._alive then return end
		Notif._alive = false

		-- Remove from stack and reposition remaining
		removeFromStack(Notif)

		local cur = Card.Position
		ntw(Card, {Position=UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset-10), Rotation=-2}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(0.17)
		ntw(Card, {Position=UDim2.new(1, sW+80, cur.Y.Scale, cur.Y.Offset + math.floor(CARD_H*0.55)), Rotation=22}, 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		ntw(Card, {BackgroundTransparency=0.5}, 0.35, Enum.EasingStyle.Linear)
		task.delay(0.46, function()
			neonConn:Disconnect()
			if cb then pcall(cb) end
			Card:Destroy()
		end)
	end

	-- Slide in: flush to the right edge (X offset = 0), stacked position
	task.delay(0.05, function()
		repositionStack()
	end)

	-- Auto-close timer
	if hasDur and DividerFill then
		ntw(DividerFill, {Size=UDim2.new(0,0,1,0)}, duration, Enum.EasingStyle.Linear)
		task.delay(duration, function()
			if Notif._alive then fallClose() end
		end)
	end

	CloseBtn.MouseButton1Click:Connect(function()
		if Notif._alive then fallClose() end
	end)

	function Notif:Destroy() if self._alive then fallClose() end end
	function Notif:Close(cb) if self._alive then fallClose(cb) end end

	function Notif:Edit(p)
		if not self._alive then return end
		p = p or {}
		if p.title   then self._title.Text = p.title   end
		if p.content then self._msg.Text   = p.content end
		if p["topbar-icon"]  and self._avaImg   then self._avaImg.Image   = p["topbar-icon"]  end
		if p["content-icon"] and self._bodyIcon then self._bodyIcon.Image = p["content-icon"] end
		if p.resetTimer and p.resetTimer > 0 and self._divFill then
			self._divFill.Size = UDim2.new(1,0,1,0)
			ntw(self._divFill, {Size=UDim2.new(0,0,1,0)}, p.resetTimer, Enum.EasingStyle.Linear)
			task.delay(p.resetTimer, function() if self._alive then fallClose() end end)
		end
	end

	function Notif:Flash(c)
		if not self._alive then return end
		local s = self._card:FindFirstChildOfClass("UIStroke")
		if s then local o=s.Color; s.Color=c or Color3.new(1,1,1); ntw(s,{Color=o},0.6,Enum.EasingStyle.Quad) end
	end

	function Notif:SetBody(text, pulse)
		if not self._alive then return end
		self._msg.Text = text or ""
		if pulse then
			ntw(self._msg, {TextTransparency=0.6}, 0.1)
			task.delay(0.15, function() if self._alive then ntw(self._msg,{TextTransparency=0},0.25) end end)
		end
	end

	function Notif:SetAccent(color)
		if not self._alive then return end
		if self._iconFrame then
			local s = self._iconFrame:FindFirstChildOfClass("UIStroke")
			if s then s.Color = color end
		end
	end

	function Notif:Shake()
		if not self._alive then return end
		local orig = self._card.Position
		for _, ox in ipairs({8,-8,6,-6,3,-3,0}) do
			ntw(self._card, {Position=UDim2.new(orig.X.Scale, orig.X.Offset+ox, orig.Y.Scale, orig.Y.Offset)}, 0.04, Enum.EasingStyle.Quad)
			task.wait(0.045)
		end
		self._card.Position = orig
	end

	return Notif
end

return APTX
