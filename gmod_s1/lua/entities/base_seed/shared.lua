AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Base Seed"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true

-- override me!
ENT.Model        = "models/props_junk/garbage_metalcan001a.mdl"
ENT.ProductClass = "weed"
ENT.GrowthTime   = 600
ENT.PlantColor   = Color(144, 165, 82, 255)
ENT.SeedName     = "Base Seed"

if SERVER then
    function ENT:Initialize()
        self:SetModel(self.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(5)
        end
    end
	
	function ENT:PhysicsCollide(data, phys)
		local hitEnt = data.HitEntity

		-- only if we hit a grow tent
		if IsValid(hitEnt) and hitEnt:GetClass() == "grow_tent" then
			-- skip tents with no pot
			if hitEnt:GetNWString("PotType") == "" then return end
			
			-- skip tents with no soil
			if hitEnt:GetNWString("SoilUsesLeft") <= 0 then return end
			
			-- skip tents with a seed already
			if hitEnt:GetNWString("PlantName") ~= "" then return end
			
			-- install the weed
			hitEnt:SetNWVector("PlantColor", self.PlantColor:ToVector())
			hitEnt:SetNWString("Product", self.ProductClass)
			hitEnt:SetNWString("PlantName", self.SeedName)
			hitEnt:SetNWInt("MaxGrowth", self.GrowthTime)
			
			-- effects
			hitEnt:EmitSound("physics/plaster/drywall_impact_hard1.wav")
			local effect = EffectData()
			effect:SetOrigin(data.HitPos)
			util.Effect("dirt_boom", effect)

			self:Remove()
		end
	end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local pos = self:GetPos() + Vector(0, 0, 10)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

        cam.Start3D2D(pos, ang, 0.2)
            draw.SimpleTextOutlined(
                self.SeedName or "Seed",
                "DermaDefaultBold",
                0, 0,
                self.PlantColor or Color(255,255,255),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                1, Color(0,0,0)
            )
        cam.End3D2D()
    end
end
