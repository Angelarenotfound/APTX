local module = {}

function module:Create()
    local p = game:GetService("Players")
    local rs = game:GetService("RunService")
    local uis = game:GetService("UserInputService")
    local l = p.LocalPlayer
    local g = l:WaitForChild("PlayerGui")
    
    local function getRoot(c)
        return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
    end
    
    local sit
    local target
    
    -- Eliminar GUI anterior si existe
    if g:FindFirstChild("CreamHelper") then
        g:FindFirstChild("CreamHelper"):Destroy()
    end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "CreamHelper"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Enabled = false  -- Inicialmente oculto
    sg.Parent = g
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    main.BorderSizePixel = 0
    main.Position = UDim2.new(0.5, -60, 0.5, -80)  -- Ajustado: -150 → -60, -200 → -80
    main.Size = UDim2.new(0, 120, 0, 160)  -- Reducido: 300 → 120, 400 → 160 (60% más pequeño)
    main.Parent = sg
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)  -- Reducido: 12 → 8
    corner.Parent = main
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1  -- Reducido: 2 → 1
    stroke.Parent = main
    
    local top = Instance.new("Frame")
    top.Name = "Top"
    top.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    top.BorderSizePixel = 0
    top.Size = UDim2.new(1, 0, 0, 18)  -- Reducido: 45 → 18
    top.Parent = main
    
    local topcorner = Instance.new("UICorner")
    topcorner.CornerRadius = UDim.new(0, 8)  -- Reducido: 12 → 8
    topcorner.Parent = top
    
    local fix = Instance.new("Frame")
    fix.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    fix.BorderSizePixel = 0
    fix.Position = UDim2.new(0, 0, 1, -8)  -- Ajustado: -12 → -8
    fix.Size = UDim2.new(1, 0, 0, 8)  -- Reducido: 12 → 8
    fix.Parent = top
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = "CreamHelper"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 10  -- Reducido: 18 → 10
    title.TextScaled = true  -- Añadido para mejor ajuste
    title.Parent = top
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Scroll"
    scroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.new(0, 4, 0, 22)  -- Ajustado: 10 → 4, 55 → 22
    scroll.Size = UDim2.new(1, -8, 1, -26)  -- Ajustado: -20 → -8, -65 → -26
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 3  -- Reducido: 6 → 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    scroll.Parent = main
    
    local scrollcorner = Instance.new("UICorner")
    scrollcorner.CornerRadius = UDim.new(0, 5)  -- Reducido: 8 → 5
    scrollcorner.Parent = scroll
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.Name
    layout.Padding = UDim.new(0, 3)  -- Reducido: 8 → 3
    layout.Parent = scroll
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 3)  -- Reducido: 8 → 3
    padding.PaddingBottom = UDim.new(0, 3)
    padding.PaddingLeft = UDim.new(0, 3)
    padding.PaddingRight = UDim.new(0, 3)
    padding.Parent = scroll
    
    local drag = false
    local dragstart
    local startpos
    
    local function updatedrag(input)
        local delta = input.Position - dragstart
        main.Position = UDim2.new(startpos.X.Scale, startpos.X.Offset + delta.X, startpos.Y.Scale, startpos.Y.Offset + delta.Y)
    end
    
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragstart = input.Position
            startpos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    drag = false
                end
            end)
        end
    end)
    
    uis.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updatedrag(input)
        end
    end)
    
    local function headsit(selectedPlayer)
        if sit then sit:Disconnect() end
        target = selectedPlayer
        
        if l.Character and l.Character:FindFirstChildOfClass("Humanoid") then
            l.Character:FindFirstChildOfClass("Humanoid").Sit = true
            
            sit = rs.Heartbeat:Connect(function()
                if p:FindFirstChild(selectedPlayer.Name) and selectedPlayer.Character and getRoot(selectedPlayer.Character) and l.Character and getRoot(l.Character) and l.Character:FindFirstChildOfClass("Humanoid").Sit == true then
                    getRoot(l.Character).CFrame = getRoot(selectedPlayer.Character).CFrame * CFrame.Angles(0, math.rad(0), 0) * CFrame.new(0, 1.6, 0.4)
                else
                    if sit then sit:Disconnect() end
                    target = nil
                end
            end)
        end
    end
    
    local function createbutton(selectedPlayer)
        local btn = Instance.new("TextButton")
        btn.Name = selectedPlayer.Name
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(1, -6, 0, 16)  -- Reducido: -16 → -6, 40 → 16
        btn.Font = Enum.Font.Gotham
        btn.Text = selectedPlayer.Name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 8  -- Reducido: 14 → 8
        btn.TextScaled = true  -- Añadido para mejor ajuste
        btn.AutoButtonColor = false
        btn.Parent = scroll
        
        local btncorner = Instance.new("UICorner")
        btncorner.CornerRadius = UDim.new(0, 5)  -- Reducido: 8 → 5
        btncorner.Parent = btn
        
        local btnstroke = Instance.new("UIStroke")
        btnstroke.Color = Color3.fromRGB(40, 40, 40)
        btnstroke.Thickness = 0.5  -- Reducido: 1 → 0.5
        btnstroke.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            headsit(selectedPlayer)
            
            for _, b in pairs(scroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    b:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(40, 40, 40)
                end
            end
            
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            btnstroke.Color = Color3.fromRGB(255, 255, 255)
        end)
        
        btn.MouseEnter:Connect(function()
            if target ~= selectedPlayer then
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            end
        end)
        
        btn.MouseLeave:Connect(function()
            if target ~= selectedPlayer then
                btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            end
        end)
        
        return btn
    end
    
    local function update()
        for _, child in pairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for _, otherPlayer in pairs(p:GetPlayers()) do
            if otherPlayer ~= l then
                createbutton(otherPlayer)
            end
        end
        
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)  -- Ajustado: 16 → 6
    end
    
    p.PlayerAdded:Connect(update)
    p.PlayerRemoving:Connect(update)
    update()
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
    end)
    
    -- Retornar el ScreenGui para control externo
    return sg
end

return module