local function tpeve(delay, l)
    local speaker = l
    local allPlayers = game.Players:GetPlayers()
    local currentIndex = 1
    local isActive = true
    
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
        
        local targetPlayer = nil
        local attempts = 0
        
        while attempts < #allPlayers do
            local player = allPlayers[currentIndex]
            
            if player ~= speaker and player.Character and getRoot(player.Character) then
                targetPlayer = player
                break
            end
            
            currentIndex = currentIndex + 1
            if currentIndex > #allPlayers then
                currentIndex = 1
            end
            attempts = attempts + 1
        end
        
        if not targetPlayer then
            print("No hay más jugadores disponibles")
            stopLoop()
            return
        end
        
        speaker.Character:FindFirstChildOfClass('Humanoid').Sit = true
        headSit = RunService.Heartbeat:Connect(function()
            if not isActive then
                headSit:Disconnect()
                return
            end
            
            if Players:FindFirstChild(targetPlayer.Name) and targetPlayer.Character ~= nil and 
               getRoot(targetPlayer.Character) and getRoot(speaker.Character) and 
               speaker.Character:FindFirstChildOfClass('Humanoid').Sit == true then
                getRoot(speaker.Character).CFrame = getRoot(targetPlayer.Character).CFrame * 
                    CFrame.Angles(0, math.rad(0), 0) * CFrame.new(0, 1.6, 0.4)
            else
                headSit:Disconnect()
            end
        end)
        
        print("Teletransportado a: " .. targetPlayer.Name)
        
        currentIndex = currentIndex + 1
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