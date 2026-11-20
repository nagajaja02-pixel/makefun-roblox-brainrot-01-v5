-- CarryPose: while the player hauls a stolen brainrot, their arms go up
-- in a carry pose; when they put it down, the arms come back. It watches
-- the Carrying flag the server sets on the player and drives the two
-- shoulder joints directly, restoring their original angles afterwards.

local CarryPose = {}

local function applyPose(character, carrying)
	local torso = character:FindFirstChild("Torso")
	if not torso then
		return
	end
	local right = torso:FindFirstChild("Right Shoulder")
	local left = torso:FindFirstChild("Left Shoulder")
	if not right or not left then
		return
	end
	if carrying then
		if not right:GetAttribute("SavedC0") then
			right:SetAttribute("SavedC0", "saved")
			right:SetAttribute("SavedC0X", right.C0.X)
			right:SetAttribute("SavedC0Y", right.C0.Y)
			right:SetAttribute("SavedC0Z", right.C0.Z)
		end
		if not left:GetAttribute("SavedC0") then
			left:SetAttribute("SavedC0", "saved")
			left:SetAttribute("SavedC0X", left.C0.X)
			left:SetAttribute("SavedC0Y", left.C0.Y)
			left:SetAttribute("SavedC0Z", left.C0.Z)
		end
		-- Arms raised forward and up, as if holding something overhead.
		right.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-150), 0, math.rad(-10))
		left.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-150), 0, math.rad(10))
	else
		if right:GetAttribute("SavedC0") then
			right.C0 = CFrame.new(right:GetAttribute("SavedC0X"), right:GetAttribute("SavedC0Y"), right:GetAttribute("SavedC0Z"))
		end
		if left:GetAttribute("SavedC0") then
			left.C0 = CFrame.new(left:GetAttribute("SavedC0X"), left:GetAttribute("SavedC0Y"), left:GetAttribute("SavedC0Z"))
		end
	end
end

function CarryPose.watch(player)
	local function bindFlag()
		local flag = player:FindFirstChild("Carrying")
		if not flag then
			player.ChildAdded:Wait()
			flag = player:FindFirstChild("Carrying")
		end
		if not flag then
			return
		end
		local function refresh()
			local character = player.Character
			if character then
				applyPose(character, flag.Value)
			end
		end
		flag:GetPropertyChangedSignal("Value"):Connect(refresh)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 5)
			refresh()
		end)
		refresh()
	end
	task.spawn(bindFlag)
end

return CarryPose
