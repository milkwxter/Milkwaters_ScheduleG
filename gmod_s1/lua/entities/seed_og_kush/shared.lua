AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Seed - OG Kush"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

ENT.Model = "models/seed_og_kush/seed_og_kush.mdl"

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
			draw.SimpleTextOutlined("OG Kush Seed", "DermaDefaultBold", 0, 0, Color(144, 165, 82, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
		cam.End3D2D()
	end
end