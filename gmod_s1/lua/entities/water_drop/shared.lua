AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Water Drop"

function ENT:Initialize()
    self:SetModel("models/hunter/misc/sphere025x025.mdl")
    self:SetMaterial("models/shiny")
    self:SetColor(Color(100, 150, 255, 200))
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(1)
    end
end

function ENT:PhysicsCollide(data, phys)
    local hitEnt = data.HitEntity

    if IsValid(hitEnt) and hitEnt:GetClass() == "grow_tent" then
        local current = hitEnt:GetNWInt("Water", 0)
        hitEnt:SetNWInt("Water", math.min(current + 20, 100))
        hitEnt:EmitSound("ambient/water/water_splash1.wav")
    end

    self:Remove()
end
