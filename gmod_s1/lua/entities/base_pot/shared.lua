AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Base Pot"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true

ENT.Model = "models/props_junk/terracotta01.mdl"
ENT.PotType = "base"

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
        -- only install if no pot is currently set
        if hitEnt:GetNWString("PotType") == "" then
			hitEnt:SetNWString("PotType", self.PotType)
			
			-- effects
            hitEnt:EmitSound("physics/metal/metal_box_impact_bullet1.wav")

            self:Remove()
        end
    end
end
