AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Weed"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

ENT.Model = "models/weed/weed.mdl"

ENT.SellPrice = 38
if SERVER then
    GAMEMODE.SellPrices = GAMEMODE.SellPrices or {}
    GAMEMODE.SellPrices["weed"] = ENT.SellPrice
end

if SERVER then
	-- called when you spawn it
	function ENT:Initialize()
		-- initialize model
		self:SetModel(self.Model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		self:SetUseType( SIMPLE_USE )
		
		-- enable physics
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
			phys:SetMass(5)
        end
	end

	-- called when someone presses "E" on it
	function ENT:Use(activator)
		if activator:IsPlayer() then
			-- max out health
			activator:SetHealth(activator:GetMaxHealth())
			
			-- effects
			local effectData = EffectData()
			effectData:SetOrigin(self:GetPos())
			util.Effect("smoke_boom", effectData)
			self:EmitSound("lighter_smoke.wav")
			
			-- remove self
			self:Remove()
		end
	end
end

if CLIENT then
	-- called every tick as well
	function ENT:Draw()
		-- do the basics
		self:DrawModel()
		
		-- setup where the text appears
		local pos = self:GetPos() + Vector(0, 0, 10)
		local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

		-- draw the main text
		cam.Start3D2D(pos, ang, 0.2)
			draw.SimpleTextOutlined("Weed", "DermaLarge", 0, -20, Color(112, 130, 23, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
            draw.SimpleTextOutlined("Price: $" .. self.SellPrice, "DermaDefault", 0, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
		cam.End3D2D()
	end
end