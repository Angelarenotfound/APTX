local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function tpeve(delay, l)
    local speaker = l
    local allPlayers = Players:GetPlayers()
    local currentIndex = 1
    local isActive = true
    local headSit

    local function stopLoop()
        isActive = false
        if headSit then 
            headSit:Disconnect()
            headSit = nil
        end
    end

    local function tpToNextPlayer()
        if not isActive then return end
        if headSit then headSit:Disconnect() end

        local targetPlayer
        local attempts = 0

        while attempts < #allPlayers do
            local player = allPlayers[currentIndex]

            if player ~= speaker and player.Character and getRoot(player.Character) then
                targetPlayer = player
                break
            end

            currentIndex += 1
            if currentIndex > #allPlayers then
                currentIndex = 1
            end
            attempts += 1
        end

        if not targetPlayer then
            print("No hay más jugadores disponibles")
            stopLoop()
            return
        end

        local humanoid = speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            stopLoop()
            return
        end

        humanoid.Sit = true

        headSit = RunService.Heartbeat:Connect(function()
            if not isActive then
                headSit:Disconnect()
                return
            end

            if Players:FindFirstChild(targetPlayer.Name)
               and targetPlayer.Character
               and getRoot(targetPlayer.Character)
               and getRoot(speaker.Character)
               and humanoid.Sit then

                getRoot(speaker.Character).CFrame =
                    getRoot(targetPlayer.Character).CFrame *
                    CFrame.new(0, 1.6, 0.4)
            else
                headSit:Disconnect()
            end
        end)

        print("Teletransportado a: " .. targetPlayer.Name)

        currentIndex += 1
        if currentIndex > #allPlayers then
            currentIndex = 1
        end

        if attempts < #allPlayers - 1 and isActive then
            task.delay(delay, tpToNextPlayer)
        else
            print("Ciclo completado")
            stopLoop()
        end
    end

    tpToNextPlayer()
    return stopLoop
end

return tpeve