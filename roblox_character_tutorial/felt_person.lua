local instance = script.Parent
local humanoid = instance:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")



local idle = animator:LoadAnimation(script.Idle)
local runForward = animator:LoadAnimation(script.RunForward)
local destinations = workspace:WaitForChild("Waypoints"):GetChildren()

local PathfindingService = game:GetService("PathfindingService")
local path = PathfindingService:CreatePath({
	AgentRadius = 1.6,
	AgentHeight = 6.0,
	WaypointSpacing = 4,
	AgentCanClimb = false,
	AgentCanJump = true,
})

local CharacterController = require(script:WaitForChild("CharacterControllerScript"))
CharacterController.setCharacter(instance)
CharacterController.setAnimation("idle", idle)
CharacterController.setAnimation("runForward", runForward)
CharacterController.setPath(path)
CharacterController.setDestinations(destinations)
CharacterController.pickDestination()

