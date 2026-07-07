--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local headSitConnection: RBXScriptConnection | nil = nil
local tweenSpeed: number = 0.5

local function getRoot(character: Model): Part | nil
    return character:FindFirstChild("HumanoidRootPart") as Part
end

local function getPlayer(name: string): Player | nil
    name = name:lower()
    for _, player in Players:GetPlayers() do
        if player.Name:lower():find(name) or player.DisplayName:lower():find(name) then
            return player
        end
    end
    return nil
end

local function pulsetp(username: string, duration: number?)
    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character or not getRoot(localPlayer.Character) then
        warn("pulsetp: Jugador local o personaje no encontrado.")
        return
    end

    local targetPlayer = getPlayer(username)
    if not targetPlayer or not targetPlayer.Character or not getRoot(targetPlayer.Character) then
        warn("pulsetp: Jugador objetivo no encontrado o sin personaje.")
        return
    end

    local localRoot = getRoot(localPlayer.Character)
    local targetRoot = getRoot(targetPlayer.Character)

    local startPos = localRoot.CFrame
    local seconds = duration or 1

    local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        humanoid.Sit = false
        task.wait(0.1)
    end

    localRoot.CFrame = targetRoot.CFrame + Vector3.new(3, 1, 0)
    task.wait(seconds)
    localRoot.CFrame = startPos
    print(string.format("pulsetp: Teletransporte de pulso a %s completado.", targetPlayer.Name))
end

local function tweentp(username: string)
    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character or not getRoot(localPlayer.Character) then
        warn("tweentp: Jugador local o personaje no encontrado.")
        return
    end

    local targetPlayer = getPlayer(username)
    if not targetPlayer or not targetPlayer.Character or not getRoot(targetPlayer.Character) then
        warn("tweentp: Jugador objetivo no encontrado o sin personaje.")
        return
    end

    local localRoot = getRoot(localPlayer.Character)
    local targetRoot = getRoot(targetPlayer.Character)

    local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        humanoid.Sit = false
        task.wait(0.1)
    end

    local tweenInfo = TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear)
    local goal = {CFrame = targetRoot.CFrame + Vector3.new(3, 1, 0)}
    local tween = TweenService:Create(localRoot, tweenInfo, goal)
    tween:Play()
    tween.Completed:Wait()
    print(string.format("tweentp: Teletransporte animado a %s completado.", targetPlayer.Name))
end

local function headsit(username: string)
    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character or not getRoot(localPlayer.Character) then
        warn("headsit: Jugador local o personaje no encontrado.")
        return
    end

    local targetPlayer = getPlayer(username)
    if not targetPlayer or not targetPlayer.Character or not getRoot(targetPlayer.Character) then
        warn("headsit: Jugador objetivo no encontrado o sin personaje.")
        return
    end

    local localRoot = getRoot(localPlayer.Character)
    local targetRoot = getRoot(targetPlayer.Character)
    local localHumanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")

    if not localHumanoid then
        warn("headsit: Humanoid del jugador local no encontrado.")
        return
    end

    if headSitConnection then
        headSitConnection:Disconnect()
        headSitConnection = nil
        print("headsit: Headsit anterior desconectado.")
    end

    localHumanoid.Sit = true

    headSitConnection = RunService.Heartbeat:Connect(function()
        if not targetPlayer.Character or not getRoot(targetPlayer.Character) or not localPlayer.Character or not getRoot(localPlayer.Character) or not localHumanoid.Sit then
            if headSitConnection then
                headSitConnection:Disconnect()
                headSitConnection = nil
            end
            localHumanoid.Sit = false
            print("headsit: Headsit terminado (objetivo/personaje inv谩lido o jugador se levant贸).")
            return
        end
        localRoot.CFrame = getRoot(targetPlayer.Character).CFrame * CFrame.Angles(0, math.rad(0), 0) * CFrame.new(0, 1.6, 0.4)
    end)
    print(string.format("headsit: Sentado en la cabeza de %s.", targetPlayer.Name))
end

local function unheadsit()
    if headSitConnection then
        headSitConnection:Disconnect()
        headSitConnection = nil
        local localPlayer = Players.LocalPlayer
        if localPlayer and localPlayer.Character then
            local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Sit = false
            end
        end
        print("unheadsit: Headsit detenido.")
    else
        print("unheadsit: No hay headsit activo para detener.")
    end
end

return {
    pulsetp = pulsetp,
    tweentp = tweentp,
    headsit = headsit,
    unheadsit = unheadsit,
}