local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- =====================
-- VARIABLES INTERNAS
-- =====================
local mfly1, mfly2
local flyKeyDown, flyKeyUp
local FLYING = false
local QEfly = true
local speaker = Players.LocalPlayer

local function randomString(length)
	length = length or 8
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local result = ""
	for i = 1, length do
		local idx = math.random(1, #chars)
		result = result .. chars:sub(idx, idx)
	end
	return result
end

local gyroHandlerName = randomString()
local velocityHandlerName = randomString()

local function getRoot(char)
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char:FindFirstChildOfClass("Humanoid").RootPart
	end
	return nil
end

-- =====================
-- UNFLY
-- =====================
local unfly = {}

function unfly:Normal()
	FLYING = false
	if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown = nil end
	if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp = nil end
	local char = speaker.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.PlatformStand = false end
	end
	pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

function unfly:Mobile()
	pcall(function()
		FLYING = false
		local root = getRoot(speaker.Character)
		if root then
			local vel = root:FindFirstChild(velocityHandlerName)
			local gyr = root:FindFirstChild(gyroHandlerName)
			if vel then vel:Destroy() end
			if gyr then gyr:Destroy() end
		end
		local humanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then humanoid.PlatformStand = false end
		if mfly1 then mfly1:Disconnect() mfly1 = nil end
		if mfly2 then mfly2:Disconnect() mfly2 = nil end
	end)
end

-- =====================
-- FLY
-- =====================
local fly = {}

function fly:Normal(speed)
	speed = speed or 1
	unfly:Normal()

	local char = speaker.Character or speaker.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
		humanoid = char:FindFirstChildOfClass("Humanoid")
	end

	local T = getRoot(char)
	local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local SPEED = 0

	local function FLY()
		FLYING = true
		local BG = Instance.new("BodyGyro")
		local BV = Instance.new("BodyVelocity")
		BG.P = 9e4
		BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		BG.CFrame = T.CFrame
		BG.Parent = T
		BV.Velocity = Vector3.new(0, 0, 0)
		BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		BV.Parent = T

		task.spawn(function()
			repeat task.wait()
				local camera = workspace.CurrentCamera
				humanoid.PlatformStand = true

				if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
					SPEED = 50
				elseif SPEED ~= 0 then
					SPEED = 0
				end

				if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
					BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
					lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
				elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
					BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
				else
					BV.Velocity = Vector3.new(0, 0, 0)
				end
				BG.CFrame = camera.CFrame
			until not FLYING

			CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			SPEED = 0
			BG:Destroy()
			BV:Destroy()
			humanoid.PlatformStand = false
		end)
	end

	flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		local camera = workspace.CurrentCamera
		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = speed
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = -speed
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = -speed
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = speed
		elseif input.KeyCode == Enum.KeyCode.E and QEfly then
			CONTROL.Q = speed * 2
		elseif input.KeyCode == Enum.KeyCode.Q and QEfly then
			CONTROL.E = -speed * 2
		end
		pcall(function() camera.CameraType = Enum.CameraType.Track end)
	end)

	flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
		elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
		elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
		elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
		elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
		elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0
		end
	end)

	FLY()
end

function fly:Mobile(speed)
	speed = speed or 1
	unfly:Mobile()
	FLYING = true

	local root = getRoot(speaker.Character)
	local camera = workspace.CurrentCamera
	local v3none = Vector3.new()
	local v3zero = Vector3.new(0, 0, 0)
	local v3inf = Vector3.new(9e9, 9e9, 9e9)

	local controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

	local function createHandlers(r)
		local bv = Instance.new("BodyVelocity")
		bv.Name = velocityHandlerName
		bv.MaxForce = v3zero
		bv.Velocity = v3zero
		bv.Parent = r

		local bg = Instance.new("BodyGyro")
		bg.Name = gyroHandlerName
		bg.MaxTorque = v3inf
		bg.P = 1000
		bg.D = 50
		bg.Parent = r
	end

	createHandlers(root)

	mfly1 = speaker.CharacterAdded:Connect(function(newChar)
		task.wait()
		local newRoot = getRoot(newChar)
		if newRoot then
			root = newRoot
			createHandlers(root)
		end
	end)

	mfly2 = RunService.RenderStepped:Connect(function()
		local currentRoot = getRoot(speaker.Character)
		camera = workspace.CurrentCamera

		if speaker.Character and currentRoot
			and currentRoot:FindFirstChild(velocityHandlerName)
			and currentRoot:FindFirstChild(gyroHandlerName) then

			local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
			local VelocityHandler = currentRoot:FindFirstChild(velocityHandlerName)
			local GyroHandler = currentRoot:FindFirstChild(gyroHandlerName)

			VelocityHandler.MaxForce = v3inf
			GyroHandler.MaxTorque = v3inf
			if humanoid then humanoid.PlatformStand = true end
			GyroHandler.CFrame = camera.CoordinateFrame
			VelocityHandler.Velocity = v3none

			local direction = controlModule:GetMoveVector()
			if direction.X ~= 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * (speed * 50))
			end
			if direction.Z ~= 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * (speed * 50))
			end
		end
	end)
end
return fly, unfly
