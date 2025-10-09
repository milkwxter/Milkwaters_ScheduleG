DEFINE_BASECLASS("base_shop_npc")

ENT.PrintName = "NPC Dealer"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true
ENT.ShopName = "Bud's Seeds"
ENT.ShopModel = "models/odessa.mdl"
ENT.MaxItemsPerPurchase = 5

ENT.ShopTheme = {
    Background = Color(255, 255, 255),
    CardBackground = Color(240, 240, 240),
    TabBackground = Color(112, 130, 23, 255),
    TabForeground = Color(102, 120, 13, 255),
    Text = Color(0, 0, 0),
    Price = Color(90, 185, 90),
}

ENT.Categories = {
    {name = "Seeds", items = {
        {name = "OG Kush Seed", price = 30, class = "seed_og_kush"},
        {name = "Sour Diesel Seed", price = 60, class = "seed_sour_diesel"},
        {name = "Green Crack Seed", price = 90, class = "seed_og_kush"},
        {name = "Granddaddy Purple Seed", price = 120, class = "seed_og_kush"},
    }},
}

function ENT:HandlePurchase(ply, class, price, amount)
	-- check if player has a outstanding drop
	if ActiveDeadDrops[ply] and IsValid(ActiveDeadDrops[ply]) then
		DarkRP.notify(ply, 1, 4, "You already have an active dead drop! Collect it first.")
		return
	end
	
	local successfulDeadDrop = self:PlaceDeadDrop(ply, class, amount)
	
	-- if the drop failed, stop
	if successfulDeadDrop == nil then return end
	
	-- otherwise, place a cool marker
	net.Start("SG_SetDeadDropMarker")
		net.WriteEntity(successfulDeadDrop)
	net.Send(ply)
	
	-- lock the drop for other players
	successfulDeadDrop.LockedTo = ply
	
	-- assign the player in the global table
	ActiveDeadDrops[ply] = successfulDeadDrop
end

if SERVER then
	-- net messages
	util.AddNetworkString("SG_SetDeadDropMarker")
	
	-- global drop table
	ActiveDeadDrops = ActiveDeadDrops or {}
	
	-- this handles placing seeds on the dead drops
	function ENT:PlaceDeadDrop(ply, item, amount)
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
		for i = 1, amount do
			chosenDrop:AddItem(item)
		end
		DarkRP.notify(ply, 0, 4, "Your dead drop is ready. Go get it!")
		return chosenDrop
	end
end

if CLIENT then
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
		
		-- clear the marker once the player is close enough and its empty
		local hasItems = markedDrop:GetHasItems()
		if meters <= 5 and not hasItems then
			markedDrop = nil
			return
		end

		draw.SimpleTextOutlined(
			"Dead Drop",
			"DermaLarge",
			screenPos.x, screenPos.y,
			Color(112, 130, 23, 255),
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