AddCSLuaFile()

ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.PrintName = "NPC Buyer"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

if SERVER then
	-- add network string for colored messages
	util.AddNetworkString("SimpleBuyer.Notify")
	
	-- list of stuff he buys
	local buyList = {
		weed = true,
	}
	
	-- initialize entity
	function ENT:Initialize()
		self:SetModel("models/Humans/Group02/male_07.mdl")
		self:SetHullType(0)
		self:SetHullSizeNormal()
		self:SetNPCState(NPC_STATE_SCRIPT)
		self:SetSolid(SOLID_BBOX)
		self:SetUseType(SIMPLE_USE)
		self:SetMoveType(MOVETYPE_NONE)
	end
	
	-- server side notification, for colored messages
	local function CustomNotify(ply, msg)
		net.Start("SimpleBuyer.Notify")
		net.WriteString(msg)
		net.Send(ply)
	end
	
	-- when someone presses "E" on this entity
	function ENT:AcceptInput(inputName, activator, caller)
		if inputName == "Use" and IsValid(caller) and caller:IsPlayer() then
			self:BuyFromPlayer(caller)
		end
	end
	
	-- this handles buying a players stuff
	function ENT:BuyFromPlayer(ply)
		-- get pocket items as an array
		local pocketItems = ply:getPocketItems()
		local itemsSold = 0
		local totalEarned = 0
		
		-- iterate through the array
		if #pocketItems > 0 then
			for _, pocketItem in ipairs(pocketItems) do
				local class = pocketItem.class
				if buyList[class] then
					local price = GAMEMODE.SellPrices[class] or 0
					if price > 0 then
						ply:removePocketItem(_)
						ply:addMoney(price)
						itemsSold = itemsSold + 1
						totalEarned = totalEarned + price
					end
				end
			end
			
			if itemsSold > 0 then
				self:EmitSound("garrysmod/save_load1.wav", 75, 100)
				local effectData = EffectData()
				effectData:SetOrigin(self:GetPos())
				util.Effect("money_boom", effectData)

				CustomNotify(ply, "You sold " .. itemsSold .. " item(s) for $" .. totalEarned)
			else
				CustomNotify(ply, "Your pocket had no sellable items! No deal.")
				self:EmitSound("vo/npc/male01/excuseme01.wav", 75, 100)
			end
		else
			-- if the player had zero pocket items
			CustomNotify(ply, "Your pocket had no items! No deal.")
			EmitSound( "vo/npc/male01/excuseme01.wav", self:GetPos(), 1, CHAN_AUTO, 1, 75, 0, 100 )
		end
	end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
		
        local pos = self:GetPos() + Vector(0, 0, 80)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

        cam.Start3D2D(pos, ang, 0.2)
			draw.SimpleTextOutlined("Buyer NPC", "DermaLarge", 0, -20, Color(220, 20, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
			draw.SimpleTextOutlined("Sell goods here!", "DermaDefault", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
    end
	
	local function Notify(msg)
		chat.AddText(Color(10, 80, 110), "Buyer NPC | ", Color(255, 255, 255), msg)
	end

	net.Receive("SimpleBuyer.Notify", function()
		Notify(net.ReadString())
	end)
end
