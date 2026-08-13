local AutoBlock = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local TestService = game:GetService("TestService")

-- Configuración de depuración
local DEBUG = true
local function DebugLog(...)
    if DEBUG then
        print("[AutoBlock Debug]", ...)
    end
end

local State = {
autoBlockOn = false, autoBlockAudioOn = false, doubleblocktech = false,
blockdelay = 0, looseFacing = true, detectionRange = 18,
messageWhenAutoBlockOn = false, messageWhenAutoBlock = "", autoblocktype = "Block",
antiFlickOn = false, antiFlickParts = 4, antiFlickBaseOffset = 2.7,
antiFlickOffsetStep = 0, antiFlickDelay = 0, autoAdjustDBTFBPS = false,
blockPartsSizeMultiplier = 1, predictionStrength = 1, predictionTurnStrength = 1,
stagger = 0.02, predictiveBlockOn = false, edgeKillerDelay = 3,
autoPunchOn = false, messageWhenAutoPunchOn = false, messageWhenAutoPunch = "",
flingPunchOn = false, flingPower = 10000, hiddenfling = false,
aimPunch = false, predictionValue = 4, customBlockEnabled = false,
customBlockAnimId = "", customblockdelay = 2, customPunchEnabled = false,
customPunchAnimId = "", custompunchdelay = 2.7, customChargeEnabled = false,
customChargeAnimId = "", hitboxDraggingTech = false, Dspeed = 5.6, Ddelay = 0,
facingCheckEnabled = false, customFacingDot = -0.3, facingVisualOn = false,
killerCirclesVisible = false, espEnabled = true, controlChargeEnabled = false
}
AutoBlock.State = State

local autoBlockTriggerSounds = {
["102228729296384"] = true, ["140242176732868"] = true, ["112809109188560"] = true,
["136323728355613"] = true, ["115026634746636"] = true, ["84116622032112"] = true,
["108907358619313"] = true, ["127793641088496"] = true, ["86174610237192"] = true,
["95079963655241"] = true, ["101199185291628"] = true, ["119942598489800"] = true,
["84307400688050"] = true, ["113037804008732"] = true, ["105200830849301"] = true,
["75330693422988"] = true, ["82221759983649"] = true, ["81702359653578"] = true,
["108610718831698"] = true, ["112395455254818"] = true, ["109431876587852"] = true,
["109348678063422"] = true, ["85853080745515"] = true, ["12222216"] = true,
["105840448036441"] = true, ["114742322778642"] = true, ["119583605486352"] = true,
["79980897195554"] = true, ["71805956520207"] = true, ["79391273191671"] = true,
["89004992452376"] = true, ["101553872555606"] = true, ["101698569375359"] = true,
["106300477136129"] = true, ["116581754553533"] = true, ["117231507259853"] = true,
["119089145505438"] = true, ["121954639447247"] = true, ["125213046326879"] = true,
["131406927389838"] = true, ["71834552297085"] = true, ["805165833096"] = true,
}

local autoBlockTriggerAnims = {
"126830014841198", "126355327951215", "121086746534252", "18885909645", "98456918873918",
"105458270463374", "83829782357897", "125403313786645", "118298475669935", "82113744478546",
"70371667919898", "99135633258223", "97167027849946", "109230267448394", "139835501033932",
"126896426760253", "109667959938617", "126681776859538", "129976080405072", "121293883585738",
"81639435858902", "137314737492715", "92173139187970", "122709416391", "879895330952"
}

local killerDelayMap = {
["c00lkidd"] = 0, ["jason"] = 0.013, ["slasher"] = 0.01,
["1x1x1x1"] = 0.15, ["johndoe"] = 0.33, ["noli"] = 0.15,
}

local killerNames = {"c00lkidd", "Jason", "JohnDoe", "1x1x1x1", "Noli", "Slasher", "Sixer"}
local blockAnimIds = {
"72722244508749", "96959123077498", "95802026624883"
}
local punchAnimIds = {
"87259391926321", "140703210927645", "136007065400978", "129843313690921",
"86709774283672", "108807732150251", "138040001965654", "86096387000557"
}
local chargeAnimIds = { "106014898538300", "106014898528300" }

local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")
local KillersFolder = nil
local testRemote = nil
local refsReady = Instance.new("BindableEvent")

task.spawn(function()
    local pf = workspace:FindFirstChild("Players") or workspace:WaitForChild("Players")
    KillersFolder = pf:FindFirstChild("Killers") or pf:WaitForChild("Killers")
    testRemote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")
    refsReady:Fire()
    DebugLog("Referencias inicializadas")
end)

-- Variables de depuración
local lastBlockAttempt = 0
local BLOCK_COOLDOWN = 0.1

local lastReplaceTime = { block = 0, punch = 0, charge = 0 }
local lastAimTrigger = {}
local AIM_WINDOW = 0.5
local AIM_COOLDOWN = 0.6
local _lastPunchMessageTime = 0
local MESSAGE_PUNCH_COOLDOWN = 0.6
local _punchPrevPlaying = {}
local _lastBlockMessageTime = 0
local MESSAGE_BLOCK_COOLDOWN = 0.6
local _blockPrevPlaying = {}
local PRED_SECONDS_FORWARD = 0.25
local PRED_SECONDS_LATERAL = 0.18
local PRED_MAX_FORWARD = 6
local PRED_MAX_LATERAL = 4
local ANG_TURN_MULTIPLIER = 0.6
local SMOOTHING_LERP = 0.22
local killerState = {}
local predictiveCooldown = 0
local _hitboxDraggingDebounce = false
local HITBOX_DETECT_RADIUS = 6
local lastBlockTime = 0
local lastPunchTime = 0
local cachedAnimator = nil
local cachedPlayerGui = PlayerGui
local cachedPunchBtn, cachedBlockBtn, cachedCharges, cachedCooldown, cachedChargeBtn, cachedCloneBtn = nil, nil, nil, nil, nil, nil
local detectionRangeSq = State.detectionRange * State.detectionRange
local facingVisuals = {}
local detectionCircles = {}
local killerInRangeSince = nil
local _savedManualAntiFlickDelay = State.antiFlickDelay or 0
local soundHooks = {}
local soundBlockedUntil = {}
local AUDIO_PREDICT_DT = 0.08
local AUDIO_LOCAL_COOLDOWN = 0.35
local AUDIO_SOUND_THROTTLE = 1.0
local lastLocalBlockTime = 0
local ORIGINAL_DASH_SPEED = 60
local controlChargeActive = false
local overrideConnection = nil
local savedHumanoidState = {}
local chargeAimActive = false
local string_match = string.match
local tostring_local = tostring

-- Función mejorada para bloquear usando firesignal
local function FireBlockButton()
    if not cachedBlockBtn then
        DebugLog("Error: cachedBlockBtn es nil")
        return false
    end
    
    local now = tick()
    if now - lastBlockAttempt < BLOCK_COOLDOWN then
        DebugLog("Block en cooldown, ignorando")
        return false
    end
    
    lastBlockAttempt = now
    DebugLog("🔥 EJECUTANDO BLOCK VIA FIRESIGNAL")
    
    local success, err = pcall(function()
        cachedBlockBtn:FireSignal("MouseButton1Click")
    end)
    
    if success then
        DebugLog("✅ Block ejecutado exitosamente")
        return true
    else
        DebugLog("❌ Error al ejecutar block:", err)
        return false
    end
end

local function refreshAnimator()
    local char = lp.Character
    if not char then cachedAnimator = nil return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then cachedAnimator = hum:FindFirstChildOfClass("Animator") or nil
    else cachedAnimator = nil end
end

local function refreshUIRefs()
    cachedPlayerGui = lp:FindFirstChild("PlayerGui") or PlayerGui
    local main = cachedPlayerGui and cachedPlayerGui:FindFirstChild("MainUI")
    if main then
        local ability = main:FindFirstChild("AbilityContainer")
        cachedPunchBtn = ability and ability:FindFirstChild("Punch")
        cachedBlockBtn = ability and ability:FindFirstChild("Block")
        cachedChargeBtn = ability and ability:FindFirstChild("Charge")
        cachedCloneBtn = ability and ability:FindFirstChild("Clone")
        cachedCharges = cachedPunchBtn and cachedPunchBtn:FindFirstChild("Charges")
        cachedCooldown = cachedBlockBtn and cachedBlockBtn:FindFirstChild("CooldownTime")
        
        if cachedBlockBtn then
            DebugLog("✅ UI actualizada - Block button encontrado")
        else
            DebugLog("⚠️ UI actualizada - Block button NO encontrado")
        end
    else
        cachedPunchBtn, cachedBlockBtn, cachedCharges, cachedCooldown, cachedChargeBtn, cachedCloneBtn = nil, nil, nil, nil, nil, nil
        DebugLog("⚠️ MainUI no encontrado")
    end
end

local function isFacing(localRoot, targetRoot)
    if not State.facingCheckEnabled then return true end
    local dx = localRoot.Position.X - targetRoot.Position.X
    local dy = localRoot.Position.Y - targetRoot.Position.Y
    local dz = localRoot.Position.Z - targetRoot.Position.Z
    local mag = math.sqrt(dx*dx + dy*dy + dz*dz)
    if mag == 0 then return true end
    local invMag = 1 / mag
    local ux, uy, uz = dx * invMag, dy * invMag, dz * invMag
    local lv = targetRoot.CFrame.LookVector
    local lx, ly, lz = lv.X, lv.Y, lv.Z
    local dot = lx * ux + ly * uy + lz * uz
    return dot > (State.customFacingDot or -0.3)
end

local function updateFacingVisual(killer, visual)
    if not (killer and visual and visual.Parent) then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dot = math.clamp(State.customFacingDot or -0.3, -1, 1)
    local angle = math.acos(dot)
    local frac = angle / math.pi
    local minFrac = 0.20
    local radius = math.max(1, State.detectionRange * (minFrac + (1 - minFrac) * frac))
    visual.Radius = radius
    visual.Height = 0.12
    local forwardDist = State.detectionRange * (0.35 + 0.15 * frac)
    local yOffset = -(hrp.Size.Y / 2 + 0.05)
    visual.CFrame = CFrame.new(0, yOffset, -forwardDist) * CFrame.Angles(math.rad(90), 0, 0)
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local inRange, facingOkay = false, false
    if myRoot and hrp then
        local dist = (hrp.Position - myRoot.Position).Magnitude
        inRange = dist <= State.detectionRange
        facingOkay = (not State.facingCheckEnabled) or isFacing(myRoot, hrp)
    end
    if inRange and facingOkay then
        visual.Color3 = Color3.fromRGB(0, 255, 0)
        visual.Transparency = 0.40
    else
        visual.Color3 = Color3.fromRGB(255, 255, 0)
        visual.Transparency = 0.85
    end
end

local function addFacingVisual(killer)
    if not killer or not killer:IsA("Model") or facingVisuals[killer] then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local visual = Instance.new("CylinderHandleAdornment")
    visual.Name = "FacingCheckVisual"
    visual.Adornee = hrp
    visual.AlwaysOnTop = true
    visual.ZIndex = 2
    visual.Transparency = 0.55
    visual.Color3 = Color3.fromRGB(0, 255, 0)
    visual.Parent = hrp
    facingVisuals[killer] = visual
    updateFacingVisual(killer, visual)
end

local function removeFacingVisual(killer)
    local v = facingVisuals[killer]
    if v then v:Destroy() facingVisuals[killer] = nil end
end

local function refreshFacingVisuals()
    if not KillersFolder then return end
    for _, k in ipairs(KillersFolder:GetChildren()) do
        if State.facingVisualOn then
            local hrp = k:FindFirstChild("HumanoidRootPart") or k:WaitForChild("HumanoidRootPart", 5)
            if hrp then addFacingVisual(k) end
        else
            removeFacingVisual(k)
        end
    end
end

local function addKillerCircle(killer)
    if not killer:FindFirstChild("HumanoidRootPart") or detectionCircles[killer] then return end
    local hrp = killer.HumanoidRootPart
    local circle = Instance.new("CylinderHandleAdornment")
    circle.Name = "KillerDetectionCircle"
    circle.Adornee = hrp
    circle.Color3 = Color3.fromRGB(255, 0, 0)
    circle.AlwaysOnTop = true
    circle.ZIndex = 1
    circle.Transparency = 0.6
    circle.Radius = State.detectionRange
    circle.Height = 0.12
    local yOffset = -(hrp.Size.Y / 2 + 0.05)
    circle.CFrame = CFrame.new(0, yOffset, 0) * CFrame.Angles(math.rad(90), 0, 0)
    circle.Parent = hrp
    detectionCircles[killer] = circle
end

local function removeKillerCircle(killer)
    if detectionCircles[killer] then
        detectionCircles[killer]:Destroy()
        detectionCircles[killer] = nil
    end
end

local function refreshKillerCircles()
    if not KillersFolder then return end
    for _, killer in ipairs(KillersFolder:GetChildren()) do
        if State.killerCirclesVisible then addKillerCircle(killer) else removeKillerCircle(killer) end
    end
end

local function SendNotif(title, text, duration)
    StarterGui:SetCore("SendNotification", { Title = title or "Hello", Text = text or "hi", Duration = duration or 4 })
end

local function getNearestKillerModel()
    if not KillersFolder then return nil end
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, closestDist = nil, math.huge
    for _, k in ipairs(KillersFolder:GetChildren()) do
        if k and k:IsA("Model") then
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < closestDist then closest, closestDist = k, d end
            end
        end
    end
    return closest
end

local function applyDelayForKillerModel(killerModel)
    if not killerModel then
        if State.antiFlickDelay ~= _savedManualAntiFlickDelay then State.antiFlickDelay = _savedManualAntiFlickDelay end
        return
    end
    local key = (tostring(killerModel.Name) or ""):lower()
    local mapped = killerDelayMap[key]
    if mapped ~= nil then
        if State.antiFlickDelay ~= mapped then State.antiFlickDelay = mapped end
    else
        if State.antiFlickDelay ~= _savedManualAntiFlickDelay then State.antiFlickDelay = _savedManualAntiFlickDelay end
    end
end

local adjustTicker = 0
local function doImmediateUpdate()
    if not State.autoAdjustDBTFBPS then return end
    applyDelayForKillerModel(getNearestKillerModel())
end

local function getHumanoid()
    if not lp or not lp.Character then return nil end
    return lp.Character:FindFirstChildOfClass("Humanoid")
end

local function saveHumState(hum)
    if not hum or savedHumanoidState[hum] then return end
    local s = {}
    pcall(function()
        s.WalkSpeed = hum.WalkSpeed
        local ok, _ = pcall(function() s.JumpPower = hum.JumpPower end)
        if not ok then pcall(function() s.JumpPower = hum.JumpHeight end) end
        local ok2, ar = pcall(function() return hum.AutoRotate end)
        if ok2 then s.AutoRotate = ar end
        s.PlatformStand = hum.PlatformStand
    end)
    savedHumanoidState[hum] = s
end

local function restoreHumState(hum)
    if not hum then return end
    local s = savedHumanoidState[hum]
    if not s then return end
    pcall(function()
        if s.WalkSpeed ~= nil then hum.WalkSpeed = s.WalkSpeed end
        if s.JumpPower ~= nil then
            local ok, _ = pcall(function() hum.JumpPower = s.JumpPower end)
            if not ok then pcall(function() hum.JumpHeight = s.JumpPower end) end
        end
        if s.AutoRotate ~= nil then pcall(function() hum.AutoRotate = s.AutoRotate end) end
        if s.PlatformStand ~= nil then hum.PlatformStand = s.PlatformStand end
    end)
    savedHumanoidState[hum] = nil
end

local function startOverride()
    if controlChargeActive then return end
    local hum = getHumanoid()
    if not hum then return end
    controlChargeActive = true
    saveHumState(hum)
    pcall(function() hum.WalkSpeed = ORIGINAL_DASH_SPEED hum.AutoRotate = false end)
    overrideConnection = RunService.RenderStepped:Connect(function()
        local humanoid = getHumanoid()
        local rootPart = humanoid and humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
        pcall(function() humanoid.WalkSpeed = ORIGINAL_DASH_SPEED humanoid.AutoRotate = false end)
        local direction = rootPart.CFrame.LookVector
        local horizontal = Vector3.new(direction.X, 0, direction.Z)
        if horizontal.Magnitude > 0 then humanoid:Move(horizontal.Unit) else humanoid:Move(Vector3.new(0,0,0)) end
    end)
end

local function stopOverride()
    if not controlChargeActive then return end
    controlChargeActive = false
    if overrideConnection then pcall(function() overrideConnection:Disconnect() end) overrideConnection = nil end
    local hum = getHumanoid()
    if hum then
        pcall(function()
            restoreHumState(hum)
            hum:Move(Vector3.new(0,0,0))
        end)
    end
end

local function detectChargeAnimation()
    local hum = getHumanoid()
    if not hum then return false end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        local ok, animId = pcall(function() return tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
        if ok and animId and animId ~= "" then
            if table.find(chargeAnimIds, animId) then return true end
            if State.customChargeEnabled and State.customChargeAnimId and tostring(State.customChargeAnimId) ~= "" then
                if tostring(animId) == tostring(State.customChargeAnimId) then return true end
            end
        end
    end
    return false
end

local function addESP(obj)
    if not obj:IsA("Model") or not obj:FindFirstChild("HumanoidRootPart") then return end
    local plr = Players:GetPlayerFromCharacter(obj)
    if not plr or obj:FindFirstChild("ESP_Highlight") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = obj
    highlight.Parent = obj
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Adornee = obj:FindFirstChild("HumanoidRootPart")
    billboard.Parent = obj
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESP_Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = obj.Name
    textLabel.Parent = billboard
end

local function clearESP(obj)
    if obj:FindFirstChild("ESP_Highlight") then obj.ESP_Highlight:Destroy() end
    if obj:FindFirstChild("ESP_Billboard") then obj.ESP_Billboard:Destroy() end
end

local function refreshESP()
    if not KillersFolder then return end
    if not State.espEnabled then
        for _, killer in pairs(KillersFolder:GetChildren()) do clearESP(killer) end
        return
    end
    for _, killer in pairs(KillersFolder:GetChildren()) do addESP(killer) end
end

-- Funciones de acción con depuración
local function fireGuiBlock()
    DebugLog("🔥 fireGuiBlock: Usando FireSignal en Block button")
    FireBlockButton()
end

local function fireGuiPunch()
    if not cachedPunchBtn then 
        DebugLog("⚠️ fireGuiPunch: cachedPunchBtn es nil")
        return 
    end
    DebugLog("👊 EJECUTANDO PUNCH VIA FIRESIGNAL")
    local success, err = pcall(function()
        cachedPunchBtn:FireSignal("MouseButton1Click")
    end)
    if success then
        DebugLog("✅ Punch ejecutado exitosamente")
    else
        DebugLog("❌ Error al ejecutar punch:", err)
    end
end

local function fireGuiCharge()
    if not cachedChargeBtn then 
        DebugLog("⚠️ fireGuiCharge: cachedChargeBtn es nil")
        return 
    end
    DebugLog("⚡ EJECUTANDO CHARGE VIA FIRESIGNAL")
    local success, err = pcall(function()
        cachedChargeBtn:FireSignal("MouseButton1Click")
    end)
    if success then
        DebugLog("✅ Charge ejecutado exitosamente")
    else
        DebugLog("❌ Error al ejecutar charge:", err)
    end
end

local function fireGuiClone()
    if not cachedCloneBtn then 
        DebugLog("⚠️ fireGuiClone: cachedCloneBtn es nil")
        return 
    end
    DebugLog("👥 EJECUTANDO CLONE VIA FIRESIGNAL")
    local success, err = pcall(function()
        cachedCloneBtn:FireSignal("MouseButton1Click")
    end)
    if success then
        DebugLog("✅ Clone ejecutado exitosamente")
    else
        DebugLog("❌ Error al ejecutar clone:", err)
    end
end

local function playCustomAnim(animId, isPunch)
    local Humanoid = getHumanoid()
    if not Humanoid or not animId or animId == "" then return end
    local now = tick()
    local lastTime = isPunch and lastPunchTime or lastBlockTime
    if now - lastTime < 1 then return end
    for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
        local animNum = tostring(track.Animation and track.Animation.AnimationId):match("%d+")
        if table.find(isPunch and punchAnimIds or blockAnimIds, animNum) then pcall(function() track:Stop() end) end
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. animId
    local success, track = pcall(function() return Humanoid:LoadAnimation(anim) end)
    if success and track then
        track:Play()
        if isPunch then lastPunchTime = now else lastBlockTime = now end
        local duration = isPunch and State.custompunchdelay or State.customblockdelay
        task.delay(duration, function() pcall(function() if track and track.IsPlaying then track:Stop() end end) end)
    end
end

coroutine.wrap(function()
    local hrp, c, vel, movel = nil, nil, nil, 0.1
    while true do
        RunService.Heartbeat:Wait()
        if State.hiddenfling then
            while State.hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
                RunService.Heartbeat:Wait()
                c = lp.Character
                hrp = c and c:FindFirstChild("HumanoidRootPart")
            end
            if State.hiddenfling and hrp then
                vel = hrp.Velocity
                hrp.Velocity = vel * State.flingPower + Vector3.new(0, State.flingPower, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end
    end
end)()

local function sendChatMessage(text)
    if not text or text:match("^%s*$") then return end
    local TextChatService = game:GetService("TextChatService")
    local channel = TextChatService.TextChannels.RBXGeneral
    channel:SendAsync(text)
end

local function extractNumericSoundId(sound)
    if not sound then return nil end
    local sid = sound.SoundId
    if not sid then return nil end
    sid = (type(sid) == "string") and sid or tostring_local(sid)
    local num = string_match(sid, "rbxassetid://(%d+)") or string_match(sid, "://(%d+)") or string_match(sid, "^(%d+)$")
    if num and #num > 0 then 
        DebugLog("🎵 Sound ID detectado:", num)
        return num 
    end
    local hash = string_match(sid, "[&%?]hash=([^&]+)")
    if hash then return "&hash=" .. hash end
    local path = string_match(sid, "rbxasset://sounds/.+")
    if path then return path end
    return nil
end

local function getSoundWorldPosition(sound)
    if not sound then return nil end
    local parent = sound.Parent
    if parent then
        if parent:IsA("BasePart") then return parent.Position, parent end
        if parent:IsA("Attachment") then
            local gp = parent.Parent
            if gp and gp:IsA("BasePart") then return gp.Position, gp end
        end
    end
    if KillersFolder and sound:IsDescendantOf(KillersFolder) then
        local root = parent or sound
        local found = root:FindFirstChildWhichIsA("BasePart", true)
        if found then return found.Position, found end
    end
    return nil, nil
end

local function getCharacterFromDescendant(inst)
    if not inst then return nil end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return model end
    return nil
end

local function isPointInsidePart(part, point)
    if not (part and point) then return false end
    local rel = part.CFrame:PointToObjectSpace(point)
    local half = part.Size * 0.5
    return math.abs(rel.X) <= half.X + 0.001 and math.abs(rel.Y) <= half.Y + 0.001 and math.abs(rel.Z) <= half.Z + 0.001
end

local function distSq(a, b)
    local dx = a.X - b.X local dy = a.Y - b.Y local dz = a.Z - b.Z
    return dx*dx + dy*dy + dz*dz
end

local function stopChargeAim() chargeAimActive = false end

local function startChargeAimUntilChargeEnds(fallbackSec)
    stopChargeAim()
    chargeAimActive = true
    task.spawn(function()
        local fallback = tonumber(fallbackSec) or 1.2
        local function getCharObjects()
            local char = lp.Character
            if not char then return nil, nil, nil end
            return char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Animator")
        end
        local humanoid, myRoot, animator = getCharObjects()
        if humanoid then pcall(function() humanoid.AutoRotate = false end) end
        local seenChargeAnim = false
        local watchStart = tick()
        while chargeAimActive do
            humanoid, myRoot, animator = getCharObjects()
            if not myRoot then break end
            local killerModel = getNearestKillerModel()
            local targetHRP = (killerModel and killerModel:FindFirstChild("HumanoidRootPart")) or nil
            if targetHRP then
                local pred = (type(State.predictionValue) == "number") and State.predictionValue or 0
                local predictedPos = targetHRP.Position + (targetHRP.CFrame.LookVector * pred)
                pcall(function() myRoot.CFrame = CFrame.lookAt(myRoot.Position, predictedPos) end)
            end
            local stillPlaying = false
            if animator then
                local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
                if ok and tracks then
                    for _, track in ipairs(tracks) do
                        local animId = nil
                        pcall(function() animId = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                        if animId and table.find(chargeAnimIds, animId) then
                            stillPlaying = true
                            seenChargeAnim = true
                            break
                        end
                    end
                end
            end
            if seenChargeAnim and not stillPlaying then break end
            if not seenChargeAnim and (tick() - watchStart) > fallback then break end
            task.wait()
        end
        if humanoid then pcall(function() humanoid.AutoRotate = true end) end
        chargeAimActive = false
    end)
end

local function _attemptForSound(sound, idParam, mode)
    if not State.autoBlockAudioOn or not sound or not sound:IsA("Sound") or not sound.IsPlaying then return end
    local now = tick()
    local hook = soundHooks[sound]
    local id = idParam or (hook and hook.id) or extractNumericSoundId(sound)
    
    if not id then 
        DebugLog("⚠️ Sound sin ID válido")
        return 
    end
    
    if autoBlockTriggerSounds[id] then
        DebugLog("🎯 HIT DETECTED - Sound ID válido:", id, "Modo:", mode)
    else
        return
    end
    
    if soundBlockedUntil[sound] and now < soundBlockedUntil[sound] then return end
    if now - lastLocalBlockTime < AUDIO_LOCAL_COOLDOWN then return end
    
    if mode == "Block" or mode == "Charge" then
        if not cachedBlockBtn or not cachedCooldown or not cachedCharges then refreshUIRefs() end
    elseif mode == "Clone" then
        if not cachedCloneBtn then refreshUIRefs() end
    end
    
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local char = hook and hook.char
    local hrp = hook and hook.hrp
    
    if not hrp then
        local soundPos, soundPart = getSoundWorldPosition(sound)
        if not soundPart then return end
        char = getCharacterFromDescendant(soundPart)
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hook then hook.char = char hook.hrp = hrp
        else soundHooks[sound] = { id = id, char = char, hrp = hrp } hook = soundHooks[sound] end
    end
    
    if not hrp then return end
    
    local v = hrp.Velocity or Vector3.new()
    local predictedX = hrp.Position.X + v.X * AUDIO_PREDICT_DT
    local predictedY = hrp.Position.Y + v.Y * AUDIO_PREDICT_DT
    local predictedZ = hrp.Position.Z + v.Z * AUDIO_PREDICT_DT
    local dx = predictedX - myRoot.Position.X
    local dy = predictedY - myRoot.Position.Y
    local dz = predictedZ - myRoot.Position.Z
    local distSqPred = dx*dx + dy*dy + dz*dz
    
    if detectionRangeSq and distSqPred > detectionRangeSq then
        local dx2 = hrp.Position.X - myRoot.Position.X
        local dy2 = hrp.Position.Y - myRoot.Position.Y
        local dz2 = hrp.Position.Z - myRoot.Position.Z
        local distSqNow = dx2*dx2 + dy2*dy2 + dz2*dz2
        local grace = (State.detectionRange + 3) * (State.detectionRange + 3)
        if distSqNow > grace then return end
    end
    
    local soundPos, soundPart = getSoundWorldPosition(sound)
    if not soundPart then return end
    local model = soundPart and soundPart:FindFirstAncestorOfClass("Model") or nil
    if not model then return end
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    local plr = Players:GetPlayerFromCharacter(model)
    if not plr or plr == lp then return end
    
    if State.facingCheckEnabled and not isFacing(myRoot, hrp) then 
        DebugLog("🚫 Facing check falló, ignorando")
        return 
    end
    
    DebugLog("⏳ Esperando delay de block:", State.blockdelay)
    task.wait(State.blockdelay)
    
    if mode == "Block" then
        if cachedCooldown and cachedCooldown.Text == "" then 
            DebugLog("🛡️ Bloqueando por sonido")
            fireGuiBlock() 
            if State.doubleblocktech == true then 
                DebugLog("🔁 Double block tech activado")
                fireGuiPunch() 
            end
        else 
            DebugLog("⏳ Block en cooldown, ignorando")
            return 
        end
    elseif mode == "Charge" then
        if cachedChargeBtn and cachedChargeBtn:FindFirstChild("CooldownTime") and cachedChargeBtn.CooldownTime.Text == "" then 
            DebugLog("⚡ Cargando por sonido")
            fireGuiCharge() 
            startChargeAimUntilChargeEnds(0.4) 
        else 
            return 
        end
    elseif mode == "Clone" then
        if cachedCloneBtn and cachedCloneBtn:FindFirstChild("CooldownTime") and cachedCloneBtn.CooldownTime.Text == "" then 
            DebugLog("👥 Clonando por sonido")
            fireGuiClone() 
            startChargeAimUntilChargeEnds(0.4) 
        else 
            return 
        end
    end
    
    lastLocalBlockTime = now
    soundBlockedUntil[sound] = now + AUDIO_SOUND_THROTTLE
end

local function attemptBlockForSound(sound, idParam) return _attemptForSound(sound, idParam, "Block") end
local function attemptChargeForSound(sound, idParam) return _attemptForSound(sound, idParam, "Charge") end
local function attemptCloneForSound(sound, idParam) return _attemptForSound(sound, idParam, "Clone") end

local function attemptBDParts(sound)
    if not State.autoBlockAudioOn or not sound or not sound:IsA("Sound") or not sound.IsPlaying then return end
    local id = extractNumericSoundId(sound)
    
    if not id or not autoBlockTriggerSounds[id] then 
        return 
    end
    
    DebugLog("🎯 HIT DETECTED (BD Parts) - Sound ID:", id)
    
    local t = tick()
    if soundBlockedUntil[sound] and t < soundBlockedUntil[sound] then return end
    
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local soundPos, soundPart = getSoundWorldPosition(sound)
    if not soundPos or not soundPart then return end
    
    local char = getCharacterFromDescendant(soundPart)
    local plr = char and Players:GetPlayerFromCharacter(char)
    if not plr or plr == lp then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if State.antiFlickOn then
        DebugLog("🔄 Anti-flick activado, generando partes")
        local basePartSize = Vector3.new(5.5, 7.5, 8.5)
        local partSize = basePartSize * (State.blockPartsSizeMultiplier or 1)
        local count = math.max(1, State.antiFlickParts or 4)
        local base = State.antiFlickBaseOffset or 2.5
        local step = State.antiFlickOffsetStep or 0.2
        local lifeTime = 0.2
        
        task.spawn(function()
            local blocked = false
            task.wait(State.antiFlickDelay or 0)
            for i = 1, count do
                if not hrp or not myRoot then break end
                local dist = base + (i - 1) * step
                local st = killerState[char] or { vel = hrp.Velocity or Vector3.new(), angVel = 0 }
                local vel = st.vel or hrp.Velocity or Vector3.new()
                local forwardSpeed = vel:Dot(hrp.CFrame.LookVector)
                local lateralSpeed = vel:Dot(hrp.CFrame.RightVector)
                local pStrength = (type(State.predictionStrength) == "number") and State.predictionStrength or 1
                local pTurn = (type(State.predictionTurnStrength) == "number") and State.predictionTurnStrength or 1
                local forwardPredictRaw = forwardSpeed * PRED_SECONDS_FORWARD * pStrength
                local lateralPredictRaw = lateralSpeed * PRED_SECONDS_LATERAL * pStrength
                local turnLateralRaw = st.angVel * ANG_TURN_MULTIPLIER * pTurn
                local forwardClamp = PRED_MAX_FORWARD * pStrength
                local lateralClamp = PRED_MAX_LATERAL * pStrength
                local turnClamp = PRED_MAX_LATERAL * pTurn
                local forwardPredict = math.clamp(forwardPredictRaw, -forwardClamp, forwardClamp)
                local lateralPredict = math.clamp(lateralPredictRaw, -lateralClamp, lateralClamp)
                local turnLateral = math.clamp(turnLateralRaw, -turnClamp, turnClamp)
                local forwardDist = dist + forwardPredict
                local spawnPos = hrp.Position + hrp.CFrame.LookVector * forwardDist + hrp.CFrame.RightVector * (lateralPredict + turnLateral)
                
                local part = Instance.new("Part")
                part.Name = "AntiFlickZone"
                part.Size = partSize
                part.Transparency = 0.45
                part.Anchored = true
                part.CanCollide = false
                part.CFrame = CFrame.new(spawnPos, hrp.Position)
                part.BrickColor = BrickColor.new("Bright blue")
                part.Parent = workspace
                Debris:AddItem(part, lifeTime)
                
                if isPointInsidePart(part, myRoot.Position) then
                    blocked = true
                else
                    local touching = {}
                    pcall(function() touching = myRoot:GetTouchingParts() end)
                    for _, p in ipairs(touching) do if p == part then blocked = true break end end
                end
                
                if blocked then
                    DebugLog("🛡️ Bloqueando por parte de anti-flick")
                    if not (State.facingCheckEnabled and not isFacing(myRoot, hrp)) then
                        if State.autoblocktype == "Block" then 
                            fireGuiBlock()
                        elseif State.autoblocktype == "Charge" then 
                            fireGuiCharge()
                        elseif State.autoblocktype == "7n7 Clone" then 
                            fireGuiClone() 
                        end
                        soundBlockedUntil[sound] = t + 1.2
                    end
                    break
                end
                if State.stagger and State.stagger > 0 then task.wait(State.stagger) else task.wait(0) end
            end
        end)
    end
end

local function hookSound(sound)
    if not sound or not sound:IsA("Sound") or soundHooks[sound] then return end
    local preId = extractNumericSoundId(sound)
    if preId and autoBlockTriggerSounds[preId] then
        DebugLog("🔊 Sound hookeado con ID:", preId)
    end
    
    soundHooks[sound] = { id = preId, hrp = nil, char = nil }
    
    local function handleAttempt(snd, id)
        if not State.autoBlockAudioOn then return end
        if not State.antiFlickOn then
            local at = State.autoblocktype
            if at == "Block" then attemptBlockForSound(snd, id)
            elseif at == "Charge" then attemptChargeForSound(snd, id)
            elseif at == "7n7 Clone" then attemptCloneForSound(snd, id) end
        else
            attemptBDParts(snd, id)
        end
    end
    
    local playedConn = sound.Played:Connect(function() handleAttempt(sound, preId) end)
    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function() if sound.IsPlaying then handleAttempt(sound, preId) end end)
    local destroyConn
    destroyConn = sound.Destroying:Connect(function()
        if playedConn and playedConn.Connected then playedConn:Disconnect() end
        if propConn and propConn.Connected then propConn:Disconnect() end
        if destroyConn and destroyConn.Connected then destroyConn:Disconnect() end
        soundHooks[sound] = nil
        soundBlockedUntil[sound] = nil
    end)
    soundHooks[sound].playedConn = playedConn
    soundHooks[sound].propConn = propConn
    soundHooks[sound].destroyConn = destroyConn
    if sound.IsPlaying then handleAttempt(sound, preId) end
end

local function getKillerHRP(killerModel)
    if not killerModel then return nil end
    if killerModel:FindFirstChild("HumanoidRootPart") then return killerModel:FindFirstChild("HumanoidRootPart") end
    if killerModel.PrimaryPart then return killerModel.PrimaryPart end
    return killerModel:FindFirstChildWhichIsA("BasePart", true)
end

local function beginDragIntoKiller(killerModel)
    if _hitboxDraggingDebounce or not killerModel or not killerModel.Parent then return end
    local char = lp and lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    local targetHRP = getKillerHRP(killerModel)
    if not targetHRP then return end
    
    _hitboxDraggingDebounce = true
    DebugLog("🔄 Iniciando drag hacia killer:", killerModel.Name)
    
    local oldWalk = humanoid.WalkSpeed
    local oldJump = humanoid.JumpPower
    local oldPlatformStand = humanoid.PlatformStand
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.PlatformStand = false
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = hrp
    
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not _hitboxDraggingDebounce then
            conn:Disconnect()
            if bv and bv.Parent then pcall(function() bv:Destroy() end) end
            humanoid.WalkSpeed = oldWalk
            humanoid.JumpPower = oldJump
            humanoid.PlatformStand = oldPlatformStand
            return
        end
        if not (char and char.Parent) or not (killerModel and killerModel.Parent) then _hitboxDraggingDebounce = false return end
        targetHRP = getKillerHRP(killerModel)
        if not targetHRP then _hitboxDraggingDebounce = false return end
        local toTarget = (targetHRP.Position - hrp.Position)
        local dist = toTarget.Magnitude
        local horiz = Vector3.new(toTarget.X, 0, toTarget.Z)
        if horiz.Magnitude > 0.01 then
            local dir = horiz.Unit
            bv.Velocity = Vector3.new(dir.X * State.Dspeed, bv.Velocity.Y, dir.Z * State.Dspeed)
        else
            bv.Velocity = Vector3.new(0, bv.Velocity.Y, 0)
        end
        if dist <= 2.0 then _hitboxDraggingDebounce = false end
    end)
    
    task.delay(0.4, function() if _hitboxDraggingDebounce then _hitboxDraggingDebounce = false end end)
end

local function playCustomChargeWithAutoStop(animId)
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(animId)
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then return end
    track:Play()
    local stopped = false
    local touchConn
    local function stopTrack()
        if stopped then return end
        stopped = true
        pcall(function() track:Stop() end)
        if touchConn and touchConn.Connected then pcall(function() touchConn:Disconnect() end) end
    end
    touchConn = hrp.Touched:Connect(function(part)
        if stopped or not part or part:IsDescendantOf(char) then return end
        stopTrack()
    end)
    task.spawn(function()
        local start = tick()
        while not stopped and (tick() - start) < 4 do task.wait(0.05) end
        if not stopped then stopTrack() end
    end)
    pcall(function() if track.Stopped then track.Stopped:Connect(stopTrack) end end)
end

function AutoBlock.SetDetectionRange(val)
    State.detectionRange = val
    detectionRangeSq = val * val
    DebugLog("Detection range actualizado a:", val)
end

function AutoBlock.SetFacingVisual(val)
    State.facingVisualOn = val
    refreshFacingVisuals()
    DebugLog("Facing visual actualizado a:", val)
end

function AutoBlock.SetDetectionRangeVisual(val)
    State.killerCirclesVisible = val
    refreshKillerCircles()
    DebugLog("Killer circles visible actualizado a:", val)
end

function AutoBlock.SetESP(val)
    State.espEnabled = val
    refreshESP()
    DebugLog("ESP actualizado a:", val)
end

function AutoBlock.SetAutoAdjustDBTFBPS(val)
    State.autoAdjustDBTFBPS = val
    if val then
        _savedManualAntiFlickDelay = State.antiFlickDelay or 0
        doImmediateUpdate()
    else
        State.antiFlickDelay = _savedManualAntiFlickDelay
    end
    DebugLog("Auto adjust DBTFBPS actualizado a:", val)
end

function AutoBlock.SetControlCharge(val)
    State.controlChargeEnabled = val
    if _G.ControlCharge_SetEnabled then pcall(_G.ControlCharge_SetEnabled, val)
    else _G.ControlCharge_WantedEnabled = val end
    DebugLog("Control charge actualizado a:", val)
end

function AutoBlock.LoadFakeBlock()
    pcall(function()
        local fakeGui = PlayerGui:FindFirstChild("FakeBlockGui")
        if not fakeGui then
            local success, result = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/skibidi399/Auto-block-script/refs/heads/main/fakeblock"))() end)
            if not success then warn("Failed to load Fake Block GUI:", result) end
        else fakeGui.Enabled = true end
        DebugLog("Fake block cargado")
    end)
end

function AutoBlock.RunInfiniteYield()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    DebugLog("Infinite Yield cargado")
end

function AutoBlock.LoadC00lGui()
    loadstring(game:HttpGet("https://rawscripts.net/raw/Forsaken-c00lgui-v15-ESP-EDITABLE-STAMINA-41624"))()
    DebugLog("C00l Gui cargado")
end

function AutoBlock.RemoveSlowness()
    pcall(function() game:GetService("ReplicatedStorage").Modules.StatusEffects.Slowness:Destroy() end)
    DebugLog("Slowness removido")
end

function AutoBlock.KickPlayer()
    lp:Kick("u got banned from roblxo permandnenly very real not fake trust %100")
    DebugLog("Jugador expulsado")
end

function AutoBlock.FakeLagTech()
    pcall(function()
        local char = lp.Character or lp.CharacterAdded:Wait()
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            local id = tostring(t.Animation and t.Animation.AnimationId or ""):match("%d+")
            if id == "136252471123500" then pcall(function() t:Stop() end) end
        end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://136252471123500"
        local track = animator:LoadAnimation(anim)
        track:Play()
        DebugLog("Fake lag tech activado")
    end)
end

function AutoBlock.Init()
    if not (KillersFolder and testRemote) then refsReady.Event:Wait() end
    
    DebugLog("🚀 Iniciando AutoBlock")
    
    lp.CharacterAdded:Connect(function(char) 
        task.wait(0.5) 
        refreshAnimator() 
        task.delay(0.5, refreshUIRefs)
        DebugLog("Character añadido, UI refrescada")
    end)
    
    refreshUIRefs()
    
    if cachedPlayerGui then
        cachedPlayerGui.ChildAdded:Connect(function(child) 
            if child.Name == "MainUI" then 
                task.delay(0.02, refreshUIRefs)
                DebugLog("MainUI detectado, UI refrescada")
            end 
        end)
    end
    
    RunService.RenderStepped:Connect(function()
        for killer, visual in pairs(facingVisuals) do
            if not killer.Parent or not killer:FindFirstChild("HumanoidRootPart") then removeFacingVisual(killer)
            else updateFacingVisual(killer, visual) end
        end
    end)
    
    KillersFolder.ChildAdded:Connect(function(killer)
        DebugLog("👾 Nuevo killer detectado:", killer.Name)
        if State.facingVisualOn then task.spawn(function() local hrp = killer:WaitForChild("HumanoidRootPart", 5) if hrp then addFacingVisual(killer) end end) end
        if State.killerCirclesVisible then task.spawn(function() local hrp = killer:WaitForChild("HumanoidRootPart", 5) if hrp then addKillerCircle(killer) end end) end
        if State.espEnabled then task.wait(0.1) addESP(killer) end
        task.delay(0.05, doImmediateUpdate)
    end)
    
    KillersFolder.ChildRemoved:Connect(function(killer)
        DebugLog("👾 Killer removido:", killer.Name)
        removeFacingVisual(killer)
        removeKillerCircle(killer)
        clearESP(killer)
        task.delay(0.05, doImmediateUpdate)
    end)
    
    RunService.RenderStepped:Connect(function()
        for killer, circle in pairs(detectionCircles) do
            if circle and circle.Parent then circle.Radius = State.detectionRange end
        end
    end)
    
    RunService.Heartbeat:Connect(function(dt)
        if not State.autoAdjustDBTFBPS then return end
        adjustTicker = adjustTicker + dt
        if adjustTicker < 0.15 then return end
        adjustTicker = 0
        applyDelayForKillerModel(getNearestKillerModel())
    end)
    
    RunService.RenderStepped:Connect(function()
        if not State.controlChargeEnabled then if controlChargeActive then stopOverride() end return end
        local hum = getHumanoid()
        if not hum then if controlChargeActive then stopOverride() end return end
        local isCharging = detectChargeAnimation()
        if isCharging then if not controlChargeActive then startOverride() end
        else if controlChargeActive then stopOverride() end end
    end)
    
    RunService.RenderStepped:Connect(function()
        if not State.espEnabled then return end
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, killer in pairs(KillersFolder:GetChildren()) do
            local billboard = killer:FindFirstChild("ESP_Billboard")
            if billboard and billboard:FindFirstChild("ESP_Text") and killer:FindFirstChild("HumanoidRootPart") then
                local dist = (killer.HumanoidRootPart.Position - hrp.Position).Magnitude
                billboard.ESP_Text.Text = string.format("%s\n[%d]", killer.Name, dist)
            end
        end
    end)
    
    RunService.RenderStepped:Connect(function(dt)
        if dt <= 0 then return end
        for _, killer in ipairs(KillersFolder:GetChildren()) do
            if killer and killer.Parent then
                local hrp = killer:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local st = killerState[killer] or { prevPos = hrp.Position, prevLook = hrp.CFrame.LookVector, vel = Vector3.new(), angVel = 0 }
                    local newVel = (hrp.Position - st.prevPos) / math.max(dt, 1e-6)
                    st.vel = st.vel and st.vel:Lerp(newVel, SMOOTHING_LERP) or newVel
                    local prevLook = st.prevLook or hrp.CFrame.LookVector
                    local look = hrp.CFrame.LookVector
                    local dot = math.clamp(prevLook:Dot(look), -1, 1)
                    local angle = math.acos(dot)
                    local crossY = prevLook:Cross(look).Y
                    local angSign = (crossY >= 0) and 1 or -1
                    local newAngVel = (angle / math.max(dt, 1e-6)) * angSign
                    st.angVel = (st.angVel * (1 - SMOOTHING_LERP)) + (newAngVel * SMOOTHING_LERP)
                    st.prevPos = hrp.Position
                    st.prevLook = look
                    killerState[killer] = st
                end
            end
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if not State.hitboxDraggingTech then return end
        if not cachedAnimator then refreshAnimator() end
        local animator = cachedAnimator
        if not animator then return end
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local ok, animId = pcall(function() local a = track.Animation return a and tostring(a.AnimationId):match("%d+") end)
            if ok and animId and table.find(blockAnimIds, animId) then
                local timePos = 0
                pcall(function() timePos = track.TimePosition or 0 end)
                if timePos <= 0.12 then
                    local nearest = getNearestKillerModel()
                    if nearest then
                        task.wait(State.Ddelay)
                        task.spawn(function() beginDragIntoKiller(nearest) end)
                        startChargeAimUntilChargeEnds(0.4)
                    end
                end
            end
        end
    end)
    
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            if not (State.hitboxDraggingTech and State.antiFlickOn) then task.wait(0.15) continue end
            local char = lp.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if not myRoot then task.wait(0.15) continue end
            local found = nil
            for _, part in ipairs(workspace:GetDescendants()) do
                if not part:IsA("BasePart") or part.Name ~= "AntiFlickZone" then continue end
                if (part.Position - myRoot.Position).Magnitude <= HITBOX_DETECT_RADIUS then found = part break end
            end
            if found and not _hitboxDraggingDebounce then
                local nearest = getNearestKillerModel()
                if nearest then
                    task.wait(State.Ddelay)
                    task.spawn(function() beginDragIntoKiller(nearest) end)
                    startChargeAimUntilChargeEnds(0.4)
                end
            end
            task.wait(0.12)
        end
    end)
    
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            local char = lp.Character
            if not char then continue end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            if not animator then continue end
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local animId = tostring(track.Animation.AnimationId):match("%d+")
                if State.customBlockEnabled and State.customBlockAnimId ~= "" and table.find(blockAnimIds, animId) then
                    if animId == tostring(State.customBlockAnimId) then continue end
                    if tick() - lastReplaceTime.block >= 3 then
                        lastReplaceTime.block = tick()
                        track:Stop()
                        local newAnim = Instance.new("Animation")
                        newAnim.AnimationId = "rbxassetid://" .. State.customBlockAnimId
                        local newTrack = animator:LoadAnimation(newAnim)
                        newTrack:Play()
                        task.delay(State.customblockdelay, function() pcall(function() if newTrack and newTrack.IsPlaying then newTrack:Stop() end end) end)
                        break
                    end
                end
                if State.customPunchEnabled and State.customPunchAnimId ~= "" and table.find(punchAnimIds, animId) then
                    if animId == tostring(State.customPunchAnimId) then continue end
                    if tick() - lastReplaceTime.punch >= 3 then
                        lastReplaceTime.punch = tick()
                        track:Stop()
                        local newAnim = Instance.new("Animation")
                        newAnim.AnimationId = "rbxassetid://" .. State.customPunchAnimId
                        local newTrack = animator:LoadAnimation(newAnim)
                        newTrack:Play()
                        task.delay(State.custompunchdelay, function() pcall(function() if newTrack and newTrack.IsPlaying then newTrack:Stop() end end) end)
                        break
                    end
                end
                if State.customChargeEnabled and State.customChargeAnimId ~= "" and table.find(chargeAnimIds, animId) then
                    if animId == tostring(State.customChargeAnimId) then continue end
                    if tick() - lastReplaceTime.charge >= 3 then
                        lastReplaceTime.charge = tick()
                        track:Stop()
                        playCustomChargeWithAutoStop(State.customChargeAnimId)
                        break
                    end
                end
            end
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        local gui = PlayerGui:FindFirstChild("MainUI")
        local punchBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Punch")
        local charges = punchBtn and punchBtn:FindFirstChild("Charges")
        local blockBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Block")
        local cooldown = blockBtn and blockBtn:FindFirstChild("CooldownTime")
        local myChar = lp.Character
        if not myChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local Humanoid = myChar:FindFirstChildOfClass("Humanoid")
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local animTracks = hum and hum:FindFirstChildOfClass("Animator") and hum:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()
                if hrp and myRoot and (hrp.Position - myRoot.Position).Magnitude <= State.detectionRange then
                    for _, track in ipairs(animTracks or {}) do
                        local id = tostring(track.Animation.AnimationId):match("%d+")
                        if table.find(autoBlockTriggerAnims, id) then
                            DebugLog("🎯 HIT DETECTED - Animación válida:", id)
                            if State.autoBlockOn and (hrp.Position - myRoot.Position).Magnitude <= State.detectionRange then
                                if isFacing(myRoot, hrp) then
                                    if cooldown and cooldown.Text == "" then 
                                        DebugLog("🛡️ Bloqueando por animación")
                                        fireGuiBlock() 
                                    end
                                    if State.doubleblocktech == true and charges and charges.Text == "1" then 
                                        DebugLog("🔁 Double block tech por animación")
                                        fireGuiPunch() 
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if State.predictiveBlockOn and tick() > predictiveCooldown then
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHum = myChar and myChar:FindFirstChild("Humanoid")
            if myHRP and myHum then
                local killerInRange = false
                for _, killer in ipairs(KillersFolder:GetChildren()) do
                    local hrp = killer:FindFirstChild("HumanoidRootPart")
                    if hrp and (myHRP.Position - hrp.Position).Magnitude <= State.detectionRange then killerInRange = true break end
                end
                if killerInRange then
                    if not killerInRangeSince then killerInRangeSince = tick()
                    elseif tick() - killerInRangeSince >= State.edgeKillerDelay then
                        DebugLog("🛡️ Block predictivo activado")
                        fireGuiBlock()
                        predictiveCooldown = tick() + 2
                        killerInRangeSince = nil
                    end
                else killerInRangeSince = nil end
            end
        end
        
        if State.autoPunchOn then
            if charges and charges.Text == "1" then
                for _, name in ipairs(killerNames) do
                    local killer = KillersFolder:FindFirstChild(name)
                    if killer and killer:FindFirstChild("HumanoidRootPart") then
                        local root = killer.HumanoidRootPart
                        if root and myRoot and (root.Position - myRoot.Position).Magnitude <= 10 then
                            DebugLog("👊 Auto punch activado para:", name)
                            fireGuiPunch()
                            if State.flingPunchOn then
                                State.hiddenfling = true
                                local targetHRP = root
                                task.spawn(function()
                                    local start = tick()
                                    while tick() - start < 1 do
                                        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and targetHRP and targetHRP.Parent then
                                            local frontPos = targetHRP.Position + (targetHRP.CFrame.LookVector * 2)
                                            lp.Character.HumanoidRootPart.CFrame = CFrame.new(frontPos, targetHRP.Position)
                                        end
                                        task.wait()
                                    end
                                    State.hiddenfling = false
                                end)
                            end
                            if State.customPunchEnabled and State.customPunchAnimId ~= "" then playCustomAnim(State.customPunchAnimId, true) end
                            break
                        end
                    end
                end
            end
        end
    end)
    
    local currentPlayingPunch = {}
    if cachedAnimator then
        local ok, tracks = pcall(function() return cachedAnimator:GetPlayingAnimationTracks() end)
        if ok and tracks then
            for _, track in ipairs(tracks) do
                local okId, animId = pcall(function() return tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                if okId and animId and table.find(punchAnimIds, animId) then
                    currentPlayingPunch[animId] = true
                    if not _punchPrevPlaying[animId] then
                        if State.messageWhenAutoPunchOn and State.messageWhenAutoPunch and tostring(State.messageWhenAutoPunch):match("%S") and (tick() - _lastPunchMessageTime) > MESSAGE_PUNCH_COOLDOWN then
                            pcall(function() sendChatMessage(State.messageWhenAutoPunch) end)
                            _lastPunchMessageTime = tick()
                        end
                    end
                end
            end
        end
    end
    _punchPrevPlaying = currentPlayingPunch
    
    local currentPlayingBlock = {}
    if cachedAnimator then
        local ok, tracks = pcall(function() return cachedAnimator:GetPlayingAnimationTracks() end)
        if ok and tracks then
            for _, track in ipairs(tracks) do
                local okId, animId = pcall(function() return tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                if okId and animId and table.find(blockAnimIds, animId) then
                    currentPlayingBlock[animId] = true
                    if not _blockPrevPlaying[animId] then
                        if State.messageWhenAutoBlockOn and State.messageWhenAutoBlock and tostring(State.messageWhenAutoBlock):match("%S") and (tick() - _lastBlockMessageTime) > MESSAGE_BLOCK_COOLDOWN then
                            pcall(function() sendChatMessage(State.messageWhenAutoBlock) end)
                            _lastBlockMessageTime = tick()
                        end
                    end
                end
            end
        end
    end
    _blockPrevPlaying = currentPlayingBlock
    
    if State.aimPunch then
        if not cachedAnimator then refreshAnimator() end
        local animator = cachedAnimator
        if animator and myRoot and myChar then
            for _, name in ipairs(killerNames) do
                local killer = KillersFolder:FindFirstChild(name)
                if killer and killer:FindFirstChild("HumanoidRootPart") then
                    local root = killer.HumanoidRootPart
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        local animId = tostring(track.Animation.AnimationId):match("%d+")
                        if table.find(punchAnimIds, animId) then
                            local last = lastAimTrigger[track]
                            if last and tick() - last < AIM_COOLDOWN then continue end
                            local timePos = 0
                            pcall(function() timePos = track.TimePosition or 0 end)
                            if timePos <= 0.1 then
                                lastAimTrigger[track] = tick()
                                local humanoid = myChar:FindFirstChild("Humanoid")
                                if humanoid then humanoid.AutoRotate = false end
                                task.spawn(function()
                                    local start = tick()
                                    while tick() - start < AIM_WINDOW do
                                        if myRoot and root and root.Parent then
                                            local predictedPos = root.Position + (root.CFrame.LookVector * State.predictionValue)
                                            myRoot.CFrame = CFrame.lookAt(myRoot.Position, predictedPos)
                                        end
                                        task.wait()
                                    end
                                    if humanoid then humanoid.AutoRotate = true end
                                    task.delay(AIM_COOLDOWN - AIM_WINDOW, function() lastAimTrigger[track] = nil end)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
    
    for _, desc in ipairs(KillersFolder:GetDescendants()) do 
        if desc:IsA("Sound") then hookSound(desc) end 
    end
    
    KillersFolder.DescendantAdded:Connect(function(desc) 
        if desc:IsA("Sound") then 
            DebugLog("🔊 Nuevo sonido detectado")
            hookSound(desc) 
        end 
    end)
    
    DebugLog("✅ AutoBlock inicializado correctamente")
end

return AutoBlock