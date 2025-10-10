AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Death Cache"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

ENT.StoredItems = {}
ENT.MaxItems = 10

-- le networking
function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "PlayerName")
end

if SERVER then
	-- net messages
	util.AddNetworkString("SG_OpenDeathCacheInventory")
	util.AddNetworkString("SG_TryTakeDeathCacheItem")
	
	-- initialize entity
	function ENT:Initialize()
		self:SetModel("models/fallout 3/backpack_2.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		self:SetUseType( SIMPLE_USE )
		
		-- enable physics
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
			phys:SetMass(50)
        end
		
		self.StoredItems = {}
	end

	-- when someone presses "E" on this entity
	function ENT:AcceptInput(inputName, activator, caller)
        if inputName ~= "Use" or not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- effects
		self:EmitSound("items/ammocrate_open.wav", 75, 100)

		-- open inventory for whoever is allowed at this point
		net.Start("SG_OpenDeathCacheInventory")
			net.WriteEntity(self)
			net.WriteTable(self.StoredItems or {})
		net.Send(caller)
    end
	
	-- helper function to add items to the drop
	function ENT:AddItem(classname)
		if not isstring(classname) then return end
		
		-- check if cache is already full
		if self:IsFull() then
			ErrorNoHalt("[DeathCache] Warning: Tried to add item but cache is already full!\n")
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
	
	-- helper function to see if the cache is full
	function ENT:IsFull()
		return #self.StoredItems >= self.MaxItems
	end
	
	-- helper function to see if the cache is empty
	function ENT:IsEmpty()
		return table.IsEmpty(self.StoredItems)
	end
	
	-- net message when player tries to take an item
	net.Receive("SG_TryTakeDeathCacheItem", function(_, ply)
		local cache = net.ReadEntity()
		local itemIndex = net.ReadUInt(16)

		if not IsValid(ply) or not ply:IsPlayer() then return end
		if not IsValid(cache) or cache:GetClass() ~= "death_cache" then return end
		if not cache.StoredItems or not cache.StoredItems[itemIndex] then return end
		
		-- stop from overflowing pockets
		local job = ply:Team()
		local max = RPExtraTeams[job].maxpocket or GAMEMODE.Config.pocketitems
		if table.Count(ply.darkRPPocket or {}) >= max then
			DarkRP.notify(ply, 1, 4, msg or "Your pocket is full!")
			return
		end

		local itemData = cache.StoredItems[itemIndex]
		cache.StoredItems[itemIndex] = nil

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
		
		-- remove the cache when emptied out
		if cache:IsEmpty() then
			-- effects
			local effect = EffectData()
			effect:SetOrigin(cache:GetPos() + cache:GetUp() * 10)
			util.Effect("StunstickImpact", effect, true, true)
			cache:EmitSound("DoSpark")
			
			cache:Remove()
		end
		
		-- send updated inventory back to client
		net.Start("SG_OpenDeathCacheInventory")
			net.WriteEntity(cache)
			net.WriteTable(cache.StoredItems)
		net.Send(ply)
	end)
end

if CLIENT then
	local ddFrame
	
	net.Receive("SG_OpenDeathCacheInventory", function()
		local ent = net.ReadEntity()
		local items = net.ReadTable()
		if not IsValid(ent) or not items then return end

		if IsValid(ddFrame) and ddFrame:IsVisible() then ddFrame:Close() end

		local count = ent.MaxItems
		ddFrame = vgui.Create("DFrame")
		ddFrame:SetSize(345, 32 + 64 * math.ceil(count / 5) + 3 * math.ceil(count / 5))
		ddFrame:SetTitle("Death Cache")
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
				net.Start("SG_TryTakeDeathCacheItem")
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
	
	-- called every tick as well
	function ENT:Draw()
		-- do the basics
		self:DrawModel()
		
		-- setup where the text appears
		local pos = self:GetPos() + Vector(0, 0, 20)
		local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

		-- show text
		local name = self:GetPlayerName()
		if not name or name == "" then
			name = "Unknown Player"
		end
        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.2)
            draw.SimpleTextOutlined(name .. "'s Death Cache", "DermaLarge", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
	end
end