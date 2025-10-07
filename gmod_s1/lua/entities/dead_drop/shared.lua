AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Dead Drop"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

ENT.StoredItems = {}
ENT.MaxItems = 5

if SERVER then
	-- net messages
	util.AddNetworkString("SG_OpenDeadDropInventory")
	util.AddNetworkString("SG_TryTakeDeadDropItem")
	
	-- initialize entity
	function ENT:Initialize()
		self:SetModel("models/props_lab/lockerdoorleft.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end
		
		self.StoredItems = {}
		self:AddItem("weed")
	end

	-- when someone presses "E" on this entity
	function ENT:AcceptInput(inputName, activator, caller)
        if inputName == "Use" and IsValid(caller) and caller:IsPlayer() then
            net.Start("SG_OpenDeadDropInventory")
			net.WriteEntity(self)
			net.WriteTable(self.StoredItems or {})
            net.Send(caller)
        end
    end
	
	-- helper function to add items to the drop
	function ENT:AddItem(classname)
		if not isstring(classname) then return end
		
		-- check if drop is already full
		if self:IsFull() then
			ErrorNoHalt("[DeadDrop] Warning: Tried to add item but drop is already full!\n")
			return
		end
		
		local model, name
		local fallbackModel = "models/props_junk/PopCan01a.mdl"
		
		local swep = weapons.GetStored(classname)
		if swep then
			model = swep.WorldModel or fallbackModel
			name  = swep.PrintName or classname
		else
			local sent = scripted_ents.GetStored(classname)
			if sent and sent.t then
				model = sent.t.Model or fallbackModel
				name  = sent.t.PrintName or classname
			else
				model = fallbackModel
				name  = classname
			end
		end
		
		table.insert(self.StoredItems, {
			class = classname,
			model = model,
			name  = name,
			id    = #self.StoredItems + 1
		})
	end
	
	-- helper function to see how many items are in the drop
	function ENT:IsFull()
		return #self.StoredItems >= self.MaxItems
	end
	
	-- net message when player tries to take an item
	net.Receive("SG_TryTakeDeadDropItem", function(_, ply)
		local deadDropEntity = net.ReadEntity()
		local itemIndex = net.ReadUInt(16)

		if not IsValid(ply) or not ply:IsPlayer() then return end
		if not IsValid(deadDropEntity) or deadDropEntity:GetClass() ~= "dead_drop" then return end
		if not deadDropEntity.StoredItems or not deadDropEntity.StoredItems[itemIndex] then return end
		
		-- stop from overflowing pockets
		local job = ply:Team()
		local max = RPExtraTeams[job].maxpocket or GAMEMODE.Config.pocketitems
		if table.Count(ply.darkRPPocket or {}) >= max then
			DarkRP.notify(ply, 1, 4, msg or "Your pocket is full!")
			return
		end

		local itemData = deadDropEntity.StoredItems[itemIndex]
		deadDropEntity.StoredItems[itemIndex] = nil

		local class = itemData.class
		local ent = ents.Create(class)
		if not IsValid(ent) then
			DarkRP.notify(ply, 1, 4, "Could not create item. Please contact an admin for help.")
			return
		end
		
		ent:SetPos(ply:GetPos())
		ent:Spawn()

		local success, msg = ply:addPocketItem(ent)
		if not success then
			ent:Remove()
			DarkRP.notify(ply, 1, 4, msg or "Could not add to pocket.")
		else
			DarkRP.notify(ply, 0, 4, "Added " .. (itemData.name or class) .. " to your pocket.")
		end
		
		-- send updated inventory back to client
		net.Start("SG_OpenDeadDropInventory")
			net.WriteEntity(deadDropEntity)
			net.WriteTable(deadDropEntity.StoredItems)
		net.Send(ply)
	end)
end

if CLIENT then
	local ddFrame
	
	net.Receive("SG_OpenDeadDropInventory", function()
		local ent = net.ReadEntity()
		local items = net.ReadTable()
		if not IsValid(ent) or not items then return end

		if IsValid(ddFrame) and ddFrame:IsVisible() then ddFrame:Close() end

		local count = ent.MaxItems
		ddFrame = vgui.Create("DFrame")
		ddFrame:SetSize(345, 32 + 64 * math.ceil(count / 5) + 3 * math.ceil(count / 5))
		ddFrame:SetTitle("Dead Drop")
		ddFrame.btnMaxim:SetVisible(false)
		ddFrame.btnMinim:SetVisible(false)
		ddFrame:SetDraggable(false)
		ddFrame:MakePopup()
		ddFrame:Center()

		local Scroll = vgui.Create("DScrollPanel", ddFrame)
		Scroll:Dock(FILL)

		local sbar = Scroll:GetVBar()
		sbar:SetWide(3)

		local list = vgui.Create("DIconLayout", Scroll)
		list:Dock(FILL)
		list:SetSpaceY(3)
		list:SetSpaceX(3)

		-- populate with items
		for itemIndex, itemData in pairs(items) do
			local ListItem = list:Add("DPanel")
			ListItem:SetSize(64, 64)

			local icon = vgui.Create("SpawnIcon", ListItem)
			icon:SetModel(itemData.model)
			icon:SetSize(64, 64)
			icon:SetTooltip(itemData.name or itemData.class)
			icon.DoClick = function()
				net.Start("SG_TryTakeDeadDropItem")
					net.WriteEntity(ent)
					net.WriteUInt(itemIndex, 16)
				net.SendToServer()
				ddFrame:Close()
			end
		end

		-- pad empty slots to keep grid consistent
		local itemCount = table.Count(items)
		if itemCount < count then
			for _ = 1, count - itemCount do
				local ListItem = list:Add("DPanel")
				ListItem:SetSize(64, 64)
			end
		end

		ddFrame:SetSkin(GAMEMODE.Config.DarkRPSkin)
	end)
end