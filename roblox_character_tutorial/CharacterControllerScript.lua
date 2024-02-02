local random = Random.new()

local characterController = {}

characterController.minDwellTime = 0.5
characterController.maxDwellTime = 3.0
characterController.runSpeed = 8

characterController.animations = {}

-- Supported animation names
-- idle
-- walkForward
-- runForward
-- jumpForward

local function playAnimation(name)
	if characterController.animations[name] then
		if not characterController.animations[name].IsPlaying then
			for n, animation in characterController.animations do
				if name == n then
					animation:Play()
				else
					animation:Stop()
				end
			end
		end

	end
end
characterController.setCharacter = function(character)
	characterController.character = character
	characterController.humanoid = character:WaitForChild("Humanoid")
	characterController.humanoid.Running:Connect(function(speed)
		if speed > characterController.runSpeed then
			playAnimation("runForward")
		elseif speed > 0 then
			playAnimation("walkForward")
		end

	end)
end

characterController.setAnimation = function(name, animation)
	characterController.animations[name] = animation
end

characterController.setDestinations = function (destinations)
	characterController.destinations = destinations
end

characterController.setPath = function (path)
	characterController.path = path
end

local walkCompleteEvent = Instance.new("BindableEvent")
local currentWaypointIndex = 1
local waypoints = nil

local function reachedWaypoint(reached)
	if not waypoints then
		walkCompleteEvent:Fire(false)
		return
	end

	if not reached then
		walkCompleteEvent:Fire(false)
		return
	end

	if currentWaypointIndex >= #waypoints then
		walkCompleteEvent:Fire(true)
		return
	end

	currentWaypointIndex += 1
	local currentWaypoint = waypoints[currentWaypointIndex]

	if currentWaypointIndex+2 < #waypoints and waypoints[currentWaypointIndex+2].Action == Enum.PathWaypointAction.Jump then
		playAnimation("jumpForward")
	end

	if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
		characterController.humanoid.Jump = true
	end

	task.spawn(function()
		characterController.character.PrimaryPart:SetNetworkOwner(nil)
		characterController.humanoid:MoveTo(currentWaypoint.Position)
	end)
end


local function walkTo(targetPosition)

	local success, errorMessage = pcall(function()
		characterController.path:ComputeAsync(characterController.character.PrimaryPart.Position, targetPosition)
	end)

	if not success or characterController.path.Status ~= Enum.PathStatus.Success then
		walkCompleteEvent:Fire(false)
		return
	end

	currentWaypointIndex = 1
	waypoints = characterController.path:GetWaypoints()

	if characterController.blockedConnection then
		characterController.blockedConnection:Disconnect()
	end
	characterController.blockedConnection = characterController.path.Blocked:Connect(function(blockedWaypointIndex)
		if blockedWaypointIndex >= currentWaypointIndex then
			characterController.blockedConnection:Disconnect()
			characterController.reachedConnection:Disconnect()
			characterController.walkCompleteEvent:Fire(false)
		end
	end)


	if characterController.reachedConnection then
		characterController.reachedConnection:Disconnect()
	end
	characterController.reachedConnection = characterController.humanoid.MoveToFinished:Connect(reachedWaypoint)
	reachedWaypoint(true)
end



local currentDestination
characterController.pickDestination = function ()
	if currentDestination then
		currentDestination = currentDestination:FindFirstChildWhichIsA("Part")
		if currentDestination then
			walkTo(currentDestination.Position)
			return
		end
	end

	local destinationIndex = random:NextInteger(1, #characterController.destinations)
	currentDestination = characterController.destinations[destinationIndex]
	walkTo(currentDestination.Position)
end

walkCompleteEvent.Event:Connect(function(succeeded)
	delay(0.5, function()
		playAnimation("idle")
	end)
	delay(random:NextNumber(characterController.minDwellTime, characterController.maxDwellTime), characterController.pickDestination)

end)


return characterController
