-- Place this script inside ServerScriptService

-- === Place ID Verification Start ===
local allowedPlaceIds = {
	1234567890, -- Game 1 Place ID
	0987654321, -- Game 2 Place ID
	0000000000, -- Game 3 Place ID
	-- Add more Place IDs as needed
}

local isAuthorized = false
for _, id in ipairs(allowedPlaceIds) do
	if game.PlaceId == id then
		isAuthorized = true
		break
	end
end

if not isAuthorized then
	warn("[AntiCheat] Script not authorized for this game. Current PlaceId: " .. game.PlaceId)
	return -- Terminate the script if PlaceId does not match any allowed IDs
end
-- === Place ID Verification End ===

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings
local defaultWalkSpeed = 16
local defaultJumpPower = 50
local gravity = workspace.Gravity

-- Advanced Settings
local AntiCheatSettings = {
	-- Violation Thresholds
	ViolationThresholds = {
		Fly = 1,            -- Immediate action for fly detection
		WalkSpeed = 1,
		JumpPower = 1,
		Health = 1,
		Teleport = 1,       -- Immediate action for teleportation detection
	},
	-- Actions: 'Kick', 'Log', 'Rubberband'
	ViolationActions = {
		Fly = 'Kick',
		WalkSpeed = 'Kick',
		JumpPower = 'Kick',
		Health = 'Kick',
		Teleport = 'Kick',
	},
	-- Detection Toggles
	EnableDetections = {
		Fly = true,
		WalkSpeed = true,
		JumpPower = true,
		Health = true,
		Teleport = true,
	},
	-- Notification Messages
	Messages = {
		Kick = "[PEGASUS] Unauthorized activity detected. You have been removed from the game.",
		Log = "[PEGASUS] Activity logged for review.",
		Rubberband = "[PEGASUS] Movement anomaly detected. Position reset.",
	},
	-- Exemptions
	ExemptPlayers = {}, -- Add player UserIds who are exempt
}

-- Store player data
local playerData = {}

-- Function to handle violations
local function handleViolation(player, violationType)
	local action = AntiCheatSettings.ViolationActions[violationType]
	local message = AntiCheatSettings.Messages[action] or "Violation detected."
	local data = playerData[player]

	if action == 'Kick' then
		warn("[AntiCheat] Kicking player " .. player.Name .. " for " .. violationType)
		player:Kick(message)
	elseif action == 'Log' then
		warn("[AntiCheat Log] Player " .. player.Name .. " (" .. violationType .. ") at " .. os.time())
	elseif action == 'Rubberband' then
		warn("[AntiCheat] Rubberbanding player " .. player.Name .. " for " .. violationType)
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") and data then
			local hrp = character.HumanoidRootPart
			-- Move the player back to their last known valid position
			hrp.CFrame = data.lastValidCFrame or hrp.CFrame
			-- Notify the player
			-- Example: RemoteEvent:FireClient(player, "Notification", message)
		end
	end
end

-- Anti-Cheat Functions
local function antiCheatFunctions(player)
	if table.find(AntiCheatSettings.ExemptPlayers, player.UserId) then
		return -- Skip anti-cheat checks for exempt players
	end

	local data = {
		lastTime = tick(),
		Violations = {
			Fly = 0,
			WalkSpeed = 0,
			JumpPower = 0,
			Health = 0,
			Teleport = 0,
		},
		lastPosition = nil,
		lastValidCFrame = nil,
		lastVelocity = Vector3.new(0, 0, 0),
		flyDetectionTime = 0,
	}

	playerData[player] = data

	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid", 30)
		local hrp = character:WaitForChild("HumanoidRootPart", 30)
		if not humanoid or not hrp then
			warn("[AntiCheat] Could not find Humanoid or HumanoidRootPart for player " .. player.Name)
			return
		end

		data.lastTime = tick()
		data.lastPosition = hrp.Position
		data.lastValidCFrame = hrp.CFrame

		-- Set default WalkSpeed and JumpPower
		humanoid.WalkSpeed = defaultWalkSpeed
		humanoid.JumpPower = defaultJumpPower

		-- Monitor Humanoid properties
		local walkSpeedConnection
		walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if not AntiCheatSettings.EnableDetections.WalkSpeed then return end
			if humanoid.WalkSpeed > defaultWalkSpeed then
				handleViolation(player, 'WalkSpeed')
				humanoid.WalkSpeed = defaultWalkSpeed -- Reset to default
			end
		end)

		local jumpPowerConnection
		jumpPowerConnection = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
			if not AntiCheatSettings.EnableDetections.JumpPower then return end
			if humanoid.JumpPower > defaultJumpPower then
				handleViolation(player, 'JumpPower')
				humanoid.JumpPower = defaultJumpPower -- Reset to default
			end
		end)

		local healthConnection
		healthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			if not AntiCheatSettings.EnableDetections.Health then return end
			if humanoid.Health > humanoid.MaxHealth then
				handleViolation(player, 'Health')
				humanoid.Health = humanoid.MaxHealth -- Reset to max health
			end
		end)

		-- Fly Detection Variables
		data.flyDetectionTime = 0
		local flyDetectionThreshold = 3 -- Time in seconds before flagging for fly

		-- Main Anti-Cheat Loop
		local connection
		connection = RunService.Heartbeat:Connect(function(deltaTime)
			if not character.Parent then
				if connection then connection:Disconnect() end
				if walkSpeedConnection then walkSpeedConnection:Disconnect() end
				if jumpPowerConnection then jumpPowerConnection:Disconnect() end
				if healthConnection then healthConnection:Disconnect() end
				return
			end

			local currentTime = tick()
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then
				warn("[AntiCheat] HumanoidRootPart not found for player " .. player.Name)
				return
			end
			local currentPosition = hrp.Position
			local currentVelocity = hrp.Velocity

			-- Raycast to check if player is grounded
			local isGrounded = false
			local rayOrigin = hrp.Position
			local rayDirection = Vector3.new(0, -5, 0)
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character}
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist

			local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
			if rayResult then
				isGrounded = true
				data.flyDetectionTime = 0
				data.lastValidCFrame = hrp.CFrame -- Update last valid position
			else
				-- Player is not grounded
				data.flyDetectionTime = data.flyDetectionTime + deltaTime
				if data.flyDetectionTime > flyDetectionThreshold then
					handleViolation(player, 'Fly')
					data.flyDetectionTime = 0
				end
			end

			-- Teleportation Detection
			if AntiCheatSettings.EnableDetections.Teleport then
				-- Calculate horizontal distance only (ignore vertical movement)
				local deltaPosition = currentPosition - data.lastPosition
				local horizontalMovement = Vector3.new(deltaPosition.X, 0, deltaPosition.Z)
				local horizontalDistance = horizontalMovement.magnitude

				-- Get the player's current WalkSpeed
				local currentWalkSpeed = humanoid.WalkSpeed

				-- Max allowed horizontal distance
				local maxHorizontalDistance = currentWalkSpeed * deltaTime * 8 -- Increased leeway

				-- Adjust max distance if the player is in the air
				local state = humanoid:GetState()
				if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
					maxHorizontalDistance = maxHorizontalDistance * 2 -- Further increase allowed distance when in the air
				end

				if horizontalDistance > maxHorizontalDistance then
					data.Violations.Teleport = data.Violations.Teleport + 1
					if data.Violations.Teleport >= AntiCheatSettings.ViolationThresholds.Teleport then
						handleViolation(player, 'Teleport')
						data.Violations.Teleport = 0 -- Reset after action
					end
				else
					data.Violations.Teleport = 0 -- Reset if no violation
				end
			end

			-- Update last recorded data
			data.lastTime = currentTime
			data.lastPosition = currentPosition
			data.lastVelocity = currentVelocity
		end)
	end

	if player.Character then
		onCharacterAdded(player.Character)
	else
		warn("[AntiCheat] Player " .. player.Name .. " has no character.")
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Player Added Event
Players.PlayerAdded:Connect(function(player)
	antiCheatFunctions(player)
end)

-- Existing Players
for _, player in ipairs(Players:GetPlayers()) do
	antiCheatFunctions(player)
end

-- Clean up player data when they leave
Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)
