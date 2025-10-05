AddCSLuaFile()

ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.PrintName = "NPC Hardware Store"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

local categories = {
    {name = "Agriculture", items = {
        {name = "Grow Tent", price = 100, class = "grow_tent"},
        {name = "Soil Bag", price = 10, class = "soil_bag"},
    }},
    {name = "Tools", items = {
        {name = "Plant Trimmers", price = 10, class = "weapon_planttrimmers"},
        {name = "Watering Can", price = 15, class = "weapon_wateringcan"},
    }},
    {name = "Packaging", items = {
        {name = "Baggie", price = 1, class = "weed"},
        {name = "Jar", price = 3, class = "weed"},
    }},
}

if SERVER then
	-- initialize entity
	function ENT:Initialize()
		self:SetModel("models/Humans/Group02/male_06.mdl")
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
            net.Start("OpenShopMenu")
            net.Send(caller)
        end
    end
	
	-- when someone buys an item from the shop
	net.Receive("Shop_BuyItem", function(_, ply)
		local class = net.ReadString()
		local price = net.ReadInt(32)

		-- make sure item exists
		local foundItem
		for _, cat in ipairs(categories) do
			for _, it in ipairs(cat.items) do
				if it.class == class and it.price == price then
					foundItem = it
					break
				end
			end
			if foundItem then break end
		end
		if not foundItem then
			DarkRP.notify(ply, 1, 4, "Invalid item. WTF are you doing?")
			return
		end

		-- check if you had pocket space
		local max = RPExtraTeams[ply:Team()].maxpocket or GAMEMODE.Config.pocketitems
		if table.Count(ply.darkRPPocket or {}) >= max then
			DarkRP.notify(ply, 1, 4, "Your pocket is full!")
			return
		end

		-- check if you can afford
		if not ply:canAfford(price) then
			DarkRP.notify(ply, 1, 4, "You can’t afford this!")
			return
		end

		-- deduct money
		ply:addMoney(-price)

		-- add item to inventory
		local ent = ents.Create(class)
		if not IsValid(ent) then
			DarkRP.notify(ply, 1, 4, "Could not create item.")
			return
		end
		ent:SetPos(ply:GetPos())
		ent:Spawn()
		ply:addPocketItem(ent)

		-- tell player of results
		DarkRP.notify(ply, 0, 4, "Purchased " .. foundItem.name .. " for $" .. price)
	end)

    util.AddNetworkString("OpenShopMenu")
	util.AddNetworkString("Shop_BuyItem")
end

if CLIENT then
	local ShopTheme = {
		Background      = Color(255, 255, 255, 255),
		
		CardBackground  = Color(240, 240, 240, 255),
		CardBorder		= Color(240, 240, 240, 255),
		
		TabBackground   = Color(50, 91, 130, 255),
		TabForeground	= Color(79, 140, 197, 255),
		
		Text			= Color(0, 0, 0, 255),
		Price           = Color(90, 185, 90, 255),
	}

    function ENT:Draw()
        self:DrawModel()
		
        local pos = self:GetPos() + Vector(0, 0, 80)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

        cam.Start3D2D(pos, ang, 0.2)
			draw.SimpleTextOutlined("Hardware Store NPC", "DermaLarge", 0, -20, ShopTheme.TabForeground, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
			draw.SimpleTextOutlined("Buy stuff here!", "DermaDefaultBold", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
    end
	
	local function GetEntityModel(entClass)
		-- check entity
		local stored = scripted_ents.GetStored(entClass)
		if stored and stored.t and stored.t.Model then
			return stored.t.Model
		end
		
		-- check weapon
		local storedWep = weapons.GetStored(entClass)
		if storedWep and storedWep.WorldModel then
			return storedWep.WorldModel
		end
	
		 -- fallback
		return "models/props_junk/PopCan01a.mdl"
	end
	
	local function FitModelToPanel(panel, ent)
		if not IsValid(ent) then return end

		local mn, mx = ent:GetModelBounds()
		local size = 0
		if mn and mx then
			size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
		end
		
		local center = (mn + mx) * 0.5
		
		panel:SetFOV(45)
		panel:SetCamPos(center + Vector(size, size, size))
		panel:SetLookAt(center)
	end
	
	net.Receive("OpenShopMenu", function()
		local frame = vgui.Create("DFrame")
		frame:SetSize(700, 500)
		frame:Center()
		frame:SetTitle("Dan's Hardware")
		frame:MakePopup()
		frame.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, ShopTheme.TabBackground)
		end

		local propertySheet = vgui.Create("DPropertySheet", frame)
		propertySheet:Dock(FILL)
		function propertySheet:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, ShopTheme.CardBackground)
		end

		for _, cat in ipairs(categories) do
			local scroll = vgui.Create("DScrollPanel", propertySheet)

			local grid = vgui.Create("DIconLayout", scroll)
			grid:Dock(FILL)
			grid:SetSpaceX(10)
			grid:SetSpaceY(10)
			grid:DockMargin(10, 10, 10, 10)

			for _, item in ipairs(cat.items) do
				local card = grid:Add("DPanel")
				card:SetSize(180, 220)
				card.Paint = function(self, w, h)
					draw.RoundedBox(6, 0, 0, w, h, ShopTheme.Background)
					surface.SetDrawColor(ShopTheme.CardBackground)
					surface.DrawOutlinedRect(0, 0, w, h, 1)
				end

				-- model preview
				local mdl = GetEntityModel(item.class)
				local icon = vgui.Create("DModelPanel", card)
				icon:SetModel(mdl)
				icon:SetSize(160, 120)
				icon:SetPos(10, 10)
				FitModelToPanel(icon, icon.Entity)
				icon.Paint = function(self, w, h)
					draw.RoundedBox(6, 0, 0, w, h, ShopTheme.CardBackground)
					DModelPanel.Paint(self, w, h)
				end

				-- item name
				local nameLabel = vgui.Create("DLabel", card)
				nameLabel:SetText(item.name)
				nameLabel:SetFont("Trebuchet18")
				nameLabel:SetTextColor(ShopTheme.Text)
				nameLabel:SizeToContents()
				nameLabel:SetPos(10, 135)

				-- price
				local priceLabel = vgui.Create("DLabel", card)
				priceLabel:SetText("$" .. item.price)
				priceLabel:SetFont("Trebuchet18")
				priceLabel:SetTextColor(ShopTheme.Price)
				priceLabel:SizeToContents()
				priceLabel:SetPos(10, 160)

				-- buy button
				local buyBtn = vgui.Create("DButton", card)
				buyBtn:SetText("")
				buyBtn:SetSize(160, 25)
				buyBtn:SetPos(10, 180)
				buyBtn.Paint = function(self, w, h)
					local col = ShopTheme.TabForeground
					if self:IsHovered() then col = ShopTheme.TabBackground end
					draw.RoundedBox(4, 0, 0, w, h, col)
					draw.SimpleText("Purchase", "Trebuchet18", w/2, h/2, ShopTheme.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				buyBtn.DoClick = function()
					-- net message
					net.Start("Shop_BuyItem")
						net.WriteString(item.class)
						net.WriteInt(item.price, 32)
					net.SendToServer()
				end
			end

			propertySheet:AddSheet(cat.name, scroll, "icon16/box.png")
		end
	end)
end
