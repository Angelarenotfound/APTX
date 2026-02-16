local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Icons = {
    ["home"] = "rbxassetid://10723434711",
    ["settings"] = "rbxassetid://10734950309",
    ["user"] = "rbxassetid://10734942391",
    ["users"] = "rbxassetid://10747373176",
    ["search"] = "rbxassetid://10734898355",
    ["star"] = "rbxassetid://10734896629",
    ["heart"] = "rbxassetid://10723376020",
    ["plus"] = "rbxassetid://10734896206",
    ["minus"] = "rbxassetid://10734883356",
    ["check"] = "rbxassetid://10734895566",
    ["x"] = "rbxassetid://10734896206",
    ["menu"] = "rbxassetid://10734883356",
    ["more-vertical"] = "rbxassetid://10734883356",
    ["more-horizontal"] = "rbxassetid://10734883356",
    ["arrow-right"] = "rbxassetid://10709790644",
    ["arrow-left"] = "rbxassetid://10709791016",
    ["arrow-up"] = "rbxassetid://10709790948",
    ["arrow-down"] = "rbxassetid://10709791437",
    ["chevron-right"] = "rbxassetid://10709790644",
    ["chevron-left"] = "rbxassetid://10709791016",
    ["chevron-up"] = "rbxassetid://10709790948",
    ["chevron-down"] = "rbxassetid://10709791437",
    ["info"] = "rbxassetid://10723407389",
    ["bell"] = "rbxassetid://10723376020",
    ["lock"] = "rbxassetid://10723407389",
    ["unlock"] = "rbxassetid://10734942991",
    ["eye"] = "rbxassetid://10747372167",
    ["eye-off"] = "rbxassetid://10747384394",
    ["shield"] = "rbxassetid://10734950309",
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
    ["alert-circle"] = "rbxassetid://10723376020",
    ["alert-triangle"] = "rbxassetid://10723376020",
    ["alert-octagon"] = "rbxassetid://10723376020",
    ["refresh"] = "rbxassetid://10734898355",
    ["maximize"] = "rbxassetid://10734883356",
    ["minimize"] = "rbxassetid://10734883356",
    ["play"] = "rbxassetid://10734896206",
    ["pause"] = "rbxassetid://10734883356",
    ["stop"] = "rbxassetid://10734896206",
    ["skip-forward"] = "rbxassetid://10734898355",
    ["skip-back"] = "rbxassetid://10734898355",
    ["volume"] = "rbxassetid://10734883356",
    ["volume-x"] = "rbxassetid://10734883356",
    ["wifi"] = "rbxassetid://10747392839",
    ["wifi-off"] = "rbxassetid://10747392930",
    ["battery"] = "rbxassetid://10709752508",
    ["battery-charging"] = "rbxassetid://10709752508",
    ["zap"] = "rbxassetid://10747392931",
    ["zap-off"] = "rbxassetid://10747392931",
    ["activity"] = "rbxassetid://10709752035",
    ["airplay"] = "rbxassetid://10709752254",
    ["anchor"] = "rbxassetid://10709751939",
    ["aperture"] = "rbxassetid://10709751939",
    ["archive"] = "rbxassetid://10709751939",
    ["award"] = "rbxassetid://10709751939",
    ["bar-chart"] = "rbxassetid://10709751939",
    ["book"] = "rbxassetid://10723404337",
    ["bookmark"] = "rbxassetid://10723376020",
    ["box"] = "rbxassetid://10709751939",
    ["briefcase"] = "rbxassetid://10709751939",
    ["calendar"] = "rbxassetid://10709751939",
    ["cast"] = "rbxassetid://10709752254",
    ["clipboard"] = "rbxassetid://10709751939",
    ["clock"] = "rbxassetid://10709751939",
    ["code"] = "rbxassetid://10734883356",
    ["coffee"] = "rbxassetid://10709751939",
    ["command"] = "rbxassetid://10709751939",
    ["compass"] = "rbxassetid://10709751939",
    ["copy"] = "rbxassetid://10723404337",
    ["credit-card"] = "rbxassetid://10709751939",
    ["crop"] = "rbxassetid://10734883356",
    ["crosshair"] = "rbxassetid://10709751939",
    ["database"] = "rbxassetid://10709751939",
    ["delete"] = "rbxassetid://10734896629",
    ["disc"] = "rbxassetid://10709751939",
    ["dollar-sign"] = "rbxassetid://10709751939",
    ["droplet"] = "rbxassetid://10709751939",
    ["feather"] = "rbxassetid://10709751939",
    ["filter"] = "rbxassetid://10734883356",
    ["flag"] = "rbxassetid://10709751939",
    ["gift"] = "rbxassetid://10709751939",
    ["git-branch"] = "rbxassetid://10709751939",
    ["git-commit"] = "rbxassetid://10709751939",
    ["git-merge"] = "rbxassetid://10709751939",
    ["git-pull-request"] = "rbxassetid://10709751939",
    ["globe"] = "rbxassetid://10709751939",
    ["grid"] = "rbxassetid://10734883356",
    ["hash"] = "rbxassetid://10734883356",
    ["headphones"] = "rbxassetid://10734883356",
    ["help-circle"] = "rbxassetid://10723407389",
    ["hexagon"] = "rbxassetid://10709751939",
    ["inbox"] = "rbxassetid://10723404337",
    ["key"] = "rbxassetid://10723407389",
    ["layers"] = "rbxassetid://10734883356",
    ["layout"] = "rbxassetid://10734883356",
    ["life-buoy"] = "rbxassetid://10709751939",
    ["list"] = "rbxassetid://10734883356",
    ["loader"] = "rbxassetid://10734898355",
    ["log-in"] = "rbxassetid://10734942391",
    ["log-out"] = "rbxassetid://10734942391",
    ["map"] = "rbxassetid://10709751939",
    ["map-pin"] = "rbxassetid://10709751939",
    ["maximize-2"] = "rbxassetid://10734883356",
    ["message-circle"] = "rbxassetid://10734883356",
    ["message-square"] = "rbxassetid://10734883356",
    ["monitor"] = "rbxassetid://10734883356",
    ["moon"] = "rbxassetid://10709751939",
    ["move"] = "rbxassetid://10734883356",
    ["navigation"] = "rbxassetid://10709751939",
    ["octagon"] = "rbxassetid://10709751939",
    ["package"] = "rbxassetid://10709751939",
    ["paperclip"] = "rbxassetid://10723404337",
    ["percent"] = "rbxassetid://10734883356",
    ["pie-chart"] = "rbxassetid://10709751939",
    ["pocket"] = "rbxassetid://10709751939",
    ["power"] = "rbxassetid://10734896206",
    ["printer"] = "rbxassetid://10709751939",
    ["radio"] = "rbxassetid://10709751939",
    ["repeat"] = "rbxassetid://10734898355",
    ["rewind"] = "rbxassetid://10734898355",
    ["rotate-ccw"] = "rbxassetid://10734898355",
    ["rotate-cw"] = "rbxassetid://10734898355",
    ["rss"] = "rbxassetid://10709751939",
    ["save"] = "rbxassetid://10723376020",
    ["scissors"] = "rbxassetid://10734883356",
    ["server"] = "rbxassetid://10709751939",
    ["share-2"] = "rbxassetid://10734950309",
    ["shopping-bag"] = "rbxassetid://10709751939",
    ["shopping-cart"] = "rbxassetid://10709751939",
    ["shuffle"] = "rbxassetid://10734898355",
    ["sidebar"] = "rbxassetid://10734883356",
    ["sliders"] = "rbxassetid://10734883356",
    ["smartphone"] = "rbxassetid://10734896206",
    ["speaker"] = "rbxassetid://10734883356",
    ["square"] = "rbxassetid://10709751939",
    ["sun"] = "rbxassetid://10709751939",
    ["sunrise"] = "rbxassetid://10709751939",
    ["sunset"] = "rbxassetid://10709751939",
    ["tablet"] = "rbxassetid://10734896206",
    ["tag"] = "rbxassetid://10709751939",
    ["target"] = "rbxassetid://10709751939",
    ["terminal"] = "rbxassetid://10734883356",
    ["thermometer"] = "rbxassetid://10709751939",
    ["thumbs-up"] = "rbxassetid://10709751939",
    ["thumbs-down"] = "rbxassetid://10709751939",
    ["toggle-left"] = "rbxassetid://10734883356",
    ["toggle-right"] = "rbxassetid://10734883356",
    ["tool"] = "rbxassetid://10734883356",
    ["trash-2"] = "rbxassetid://10734896629",
    ["trending-up"] = "rbxassetid://10709790948",
    ["trending-down"] = "rbxassetid://10709791437",
    ["triangle"] = "rbxassetid://10709751939",
    ["truck"] = "rbxassetid://10709751939",
    ["tv"] = "rbxassetid://10734883356",
    ["twitter"] = "rbxassetid://10709751939",
    ["type"] = "rbxassetid://10734883356",
    ["umbrella"] = "rbxassetid://10709751939",
    ["underline"] = "rbxassetid://10734883356",
    ["watch"] = "rbxassetid://10709751939",
    ["wind"] = "rbxassetid://10709751939",
    ["youtube"] = "rbxassetid://10734883356",
}

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

return APTX
