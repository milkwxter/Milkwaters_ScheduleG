AddCSLuaFile()

ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.PrintName = "NPC Dealer"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

if SERVER then
	-- net messages
	util.AddNetworkString("SG_SetDeadDropMarker")
	
	-- global drop table
	ActiveDeadDrops = ActiveDeadDrops or {}
	
	-- initialize entity
	function ENT:Initialize()
		self:SetModel("models/odessa.mdl")
		self:SetHullType(0)
		self:SetHullSizeNormal()
		self:SetNPCState(NPC_STATE_SCRIPT)
		self:SetSolid(SOLID_BBOX)
		self:SetUseType(SIMPLE_USE)
		self:SetMoveType(MOVETYPE_NONE)
	end
	
	-- when someone presses "E" on this entity
	function ENT:AcceptInput(inputName, activator, caller)
		if inputName == "Use" and IsValid(caller) and caller:IsPlayer() then
			-- check if player has a outstanding drop
			if ActiveDeadDrops[caller] and IsValid(ActiveDeadDrops[caller]) then
				DarkRP.notify(caller, 1, 4, "You already have an active dead drop! Collect it first.")
				return
			end
			
			local successfulDeadDrop = self:PlaceDeadDrop(caller)
			
			-- if the drop failed, stop
			if successfulDeadDrop == nil then return end
			
			-- otherwise, place a cool marker
			net.Start("SG_SetDeadDropMarker")
				net.WriteEntity(successfulDeadDrop)
			net.Send(caller)
			
			-- lock the drop for other players
			successfulDeadDrop.LockedTo = caller
			
			-- assign the player in the global table
			ActiveDeadDrops[caller] = successfulDeadDrop
		end
	end
	
	-- this handles placing seeds on the dead drops
	function ENT:PlaceDeadDrop(ply)
		local deadDrops = ents.FindByClass("dead_drop")

		-- error if no dead drops are placed
		if #deadDrops == 0 then
			DarkRP.notify(ply, 1, 4, "There are no dead drops on this map! Contact an admin!")
			return nil
		end

		-- collect all valid, non-full drops
		local validDrops = {}
		for _, drop in ipairs(deadDrops) do
			if IsValid(drop) and not drop:IsFull() and drop:IsEmpty() then
				table.insert(validDrops, drop)
			end
		end

		-- if none are valid, bail
		if #validDrops == 0 then
			DarkRP.notify(ply, 1, 4, "All dead drops are currently full. Come back later!")
			return nil
		end

		-- pick one at random
		local chosenDrop = validDrops[math.random(#validDrops)]
		
		-- do awesome stuff
		chosenDrop:AddItem("weed")
		DarkRP.notify(ply, 0, 4, "Your dead drop is ready. Go get it!")
		return chosenDrop
	end
end

if CLIENT then
	-- draw the 3d2d text
    function ENT:Draw()
        self:DrawModel()
		
        local pos = self:GetPos() + Vector(0, 0, 80)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

        cam.Start3D2D(pos, ang, 0.2)
			draw.SimpleTextOutlined("Dealer NPC", "DermaLarge", 0, -20, Color(112, 130, 23, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
			draw.SimpleTextOutlined("Order seeds here!", "DermaDefault", 0, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
    end
	
	-- draw a marker for the player to find his package
	local markedDrop
	net.Receive("SG_SetDeadDropMarker", function()
		local ent = net.ReadEntity()
		if IsValid(ent) then
			markedDrop = ent
		end
	end)
	
	hook.Add("HUDPaint", "SG_DrawDeadDropMarker", function()
		if not IsValid(markedDrop) then return end

		local ply = LocalPlayer()
		local dropPos = markedDrop:GetPos()
		local screenPos = dropPos:ToScreen()
		
		local dist = ply:GetPos():Distance(dropPos)
		local meters = math.Round(dist * 0.01905)
		
		-- clear the marker once the player is close enough
		if meters <= 1 then
			markedDrop = nil
			return
		end

		draw.SimpleTextOutlined(
			"Dead Drop",
			"DermaLarge",
			screenPos.x, screenPos.y,
			Color(0, 255, 0),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
			1, Color(0,0,0)
		)

		draw.SimpleTextOutlined(
			meters .. "m",
			"DermaDefaultBold",
			screenPos.x, screenPos.y + 20,
			Color(255, 255, 255),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
			1, Color(0,0,0)
		)
	end)
end
