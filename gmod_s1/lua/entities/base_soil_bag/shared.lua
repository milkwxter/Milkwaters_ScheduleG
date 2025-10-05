AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Base Soil Bag"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true

ENT.Model = "models/soil_bag/soil_bag.mdl"
ENT.SoilRefillAmount = 1
ENT.DirtColor = Color(139, 69, 19)

function ENT:Initialize()
    self:SetModel(self.Model)
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

    if IsValid(hitEnt) and hitEnt:GetClass() == "grow_tent" then
        local current = hitEnt:GetNWInt("SoilUsesLeft", 0)

        if current >= 1 then return end

		-- tell the grow tent some variables
        hitEnt:SetNWInt("SoilUsesLeft", self.SoilRefillAmount)
		hitEnt:SetNWVector("DirtColor", self.DirtColor:ToVector())
		
		-- effects
        hitEnt:EmitSound("physics/plaster/drywall_impact_hard1.wav")
        local effect = EffectData()
        effect:SetOrigin(data.HitPos)
        util.Effect("dirt_boom", effect)

        self:Remove()
    end
end
