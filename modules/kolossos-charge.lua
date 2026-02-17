local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function tpeve(delay, speaker)
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

        local allPlayers = Players:GetPlayers() -- siempre fresco
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

            local targetRoot = getRoot(targetPlayer.Character)
            local speakerRoot = getRoot(speaker.Character)

            if targetRoot and speakerRoot and humanoid.Sit then
                speakerRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 1.6, 0.4)
            else
                headSit:Disconnect()
            end
        end)

        currentIndex += 1
        if currentIndex > #allPlayers then
            currentIndex = 1
        end

        if attempts < #allPlayers - 1 and isActive then
            task.delay(delay, tpToNextPlayer)
        else
            stopLoop()
        end
    end

    tpToNextPlayer()
    return stopLoop
end

return tpeve