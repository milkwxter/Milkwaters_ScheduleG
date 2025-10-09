AddCSLuaFile()

ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.PrintName = "Abstract Shop NPC"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true

-- Defaults (override in child classes)
ENT.ShopName   = "Generic Shop"
ENT.ShopModel  = "models/Humans/Group01/male_07.mdl"
ENT.Categories = {}
ENT.MaxItemsPerPurchase = 10

ENT.ShopTheme = {
    Background      = Color(255, 255, 255),
    CardBackground  = Color(240, 240, 240),
    TabBackground   = Color(50, 91, 130),
    TabForeground   = Color(79, 140, 197),
    Text            = Color(0, 0, 0),
    Price           = Color(90, 185, 90),
}

-- overridable behavior for child classes
function ENT:HandlePurchase(ply, item)
    local ent = ents.Create(item.class)
    if not IsValid(ent) then
        DarkRP.notify(ply, 1, 4, "Could not create item.")
        return
    end
    ent:SetPos(ply:GetPos())
    ent:Spawn()
    ply:addPocketItem(ent)
	DarkRP.notify(ply, 0, 4, "Purchased " .. foundItem.name .. " for $" .. price)
end

if SERVER then
    util.AddNetworkString("SG_OpenShopMenu")
    util.AddNetworkString("Shop_BuyItem")

    function ENT:Initialize()
        self:SetModel(self.ShopModel)
        self:SetHullType(0)
        self:SetHullSizeNormal()
        self:SetNPCState(NPC_STATE_SCRIPT)
        self:SetSolid(SOLID_BBOX)
        self:SetUseType(SIMPLE_USE)
        self:SetMoveType(MOVETYPE_NONE)
    end

    function ENT:AcceptInput(inputName, activator, caller)
        if inputName == "Use" and IsValid(caller) and caller:IsPlayer() then
            net.Start("SG_OpenShopMenu")
                net.WriteEntity(self)
                net.WriteTable(self.ShopTheme)
            net.Send(caller)
        end
    end

    net.Receive("Shop_BuyItem", function(_, ply)
        local ent = net.ReadEntity()
        local class = net.ReadString()
        local price = net.ReadInt(32)
		local amount = net.ReadInt(16)

        if not IsValid(ent) or not ent.Categories then return end

        -- find item
        local foundItem
        for _, cat in ipairs(ent.Categories) do
            for _, it in ipairs(cat.items) do
                if it.class == class and it.price == price then
                    foundItem = it
                    break
                end
            end
            if foundItem then break end
        end
        if not foundItem then
            DarkRP.notify(ply, 1, 4, "Invalid item.")
            return
        end

        -- pocket space
        local maxPocket = RPExtraTeams[ply:Team()].maxpocket or GAMEMODE.Config.pocketitems
		local currentPocketSpace = table.Count(ply.darkRPPocket or {})
		if currentPocketSpace + amount > maxPocket then
			DarkRP.notify(ply, 1, 4, "Not enough pocket space!")
			return
		end

        -- money
		local totalPrice = price * amount
        if not ply:canAfford(totalPrice) then
            DarkRP.notify(ply, 1, 4, "You can’t afford this!")
            return
        end

        ply:addMoney(-totalPrice)

        -- custom buy handler
        ent:HandlePurchase(ply, class, totalPrice, amount)
    end)
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
        local pos = self:GetPos() + Vector(0, 0, 80)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

        cam.Start3D2D(pos, ang, 0.2)
            draw.SimpleTextOutlined(self.ShopName, "DermaLarge", 0, -20, self.ShopTheme.TabForeground, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
            draw.SimpleTextOutlined("Press E to browse", "DermaDefaultBold", 0, 0, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
        cam.End3D2D()
    end

    local function GetEntityModel(entClass)
        local stored = scripted_ents.GetStored(entClass)
        if stored and stored.t and stored.t.Model then return stored.t.Model end
        local wep = weapons.GetStored(entClass)
        if wep and wep.WorldModel then return wep.WorldModel end
        return "models/props_junk/PopCan01a.mdl"
    end

    local function FitModelToPanel(panel, ent)
        if not IsValid(ent) then return end
        local mn, mx = ent:GetModelBounds()
        local size = math.max(math.abs(mn.x)+math.abs(mx.x), math.abs(mn.y)+math.abs(mx.y), math.abs(mn.z)+math.abs(mx.z))
        local center = (mn + mx) * 0.5
        panel:SetFOV(60)
        panel:SetCamPos(center + Vector(size, size, size))
        panel:SetLookAt(center)
    end

    net.Receive("SG_OpenShopMenu", function()
        local ent = net.ReadEntity()
        local theme = net.ReadTable() or {}
        if not IsValid(ent) or not ent.Categories then return end

        local ShopTheme = theme

        local frame = vgui.Create("DFrame")
        frame:SetSize(700, 500)
        frame:Center()
        frame:SetTitle(ent.ShopName)
        frame:MakePopup()
		frame.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, ShopTheme.TabBackground)
		end

        local propertySheet = vgui.Create("DPropertySheet", frame)
        propertySheet:Dock(FILL)
		function propertySheet:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, ShopTheme.CardBackground)
		end

        for _, cat in ipairs(ent.Categories) do
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

                local nameLabel = vgui.Create("DLabel", card)
                nameLabel:SetText(item.name)
                nameLabel:SetFont("Trebuchet18")
                nameLabel:SetTextColor(ShopTheme.Text)
                nameLabel:SizeToContents()
                nameLabel:SetPos(10, 135)
				
				local slider = vgui.Create("DNumSlider", card)
				slider:SetPos(40, 160)
				slider:SetSize(160, 20)
				slider:SetText("")
				slider:SetMin(1)
				slider:SetMax(ent.MaxItemsPerPurchase)
				slider:SetDecimals(0)
				slider:SetValue(1)

                local priceLabel = vgui.Create("DLabel", card)
                priceLabel:SetText("$" .. item.price)
                priceLabel:SetFont("Trebuchet18")
                priceLabel:SetTextColor(ShopTheme.Price)
                priceLabel:SizeToContents()
                priceLabel:SetPos(10, 160)

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
					local amount = math.floor(slider:GetValue())
                    net.Start("Shop_BuyItem")
                        net.WriteEntity(ent)
                        net.WriteString(item.class)
                        net.WriteInt(item.price, 32)
						net.WriteInt(amount, 16)
                    net.SendToServer()
                end
            end

            propertySheet:AddSheet(cat.name, scroll, "icon16/bullet_white.png")
        end
    end)
end
