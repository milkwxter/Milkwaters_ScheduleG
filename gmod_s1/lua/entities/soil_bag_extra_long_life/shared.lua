AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Soil Bag - Extra Long Life"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

ENT.Model = "models/soil_bag_extra_long_life/soil_bag_extra_long_life.mdl"

local SoilRefillAmount = 3

function ENT:Initialize()
    self:SetModel(self.Model)
	self:SetMaterial(self.Material)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(25)
    end
end

function ENT:PhysicsCollide(data, phys)
    local hitEnt = data.HitEntity

	-- hit a grow tent
    if IsValid(hitEnt) and hitEnt:GetClass() == "grow_tent" then
        local current = hitEnt:GetNWInt("SoilUsesLeft", 0)
		
		-- only refill if there is no soil
		if current >= 1 then return end
		
        hitEnt:SetNWInt("SoilUsesLeft", math.min(current + SoilRefillAmount, SoilRefillAmount))
        hitEnt:EmitSound("physics/plaster/drywall_impact_hard1.wav")
		
		-- effects
        local effect = EffectData()
        effect:SetOrigin(data.HitPos)
        util.Effect("dirt_boom", effect)
		
		self:Remove()
    end
end
