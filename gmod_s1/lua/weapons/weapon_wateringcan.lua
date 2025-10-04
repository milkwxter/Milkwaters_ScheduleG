AddCSLuaFile()

SWEP.PrintName = "Watering Can"
SWEP.Author = "Milkwater"
SWEP.Instructions = "Left click to shoot water drops"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.UseHands = false
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/props_interiors/pot01a.mdl"

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local ent = ents.Create("water_drop")
    if not IsValid(ent) then return end

    local pos = owner:GetShootPos()
    local ang = owner:GetAimVector()

    ent:SetPos(pos + ang * 16)
    ent:SetAngles(ang:Angle())
    ent:SetOwner(owner)
    ent:Spawn()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(ang * 400) -- adjust speed here
    end

    self:EmitSound("ambient/water/water_spray1.wav")
    self:SetNextPrimaryFire(CurTime() + 0.3)
end

if CLIENT then
    function SWEP:PostDrawViewModel(vm, wep, ply)
        -- Don’t draw the default viewmodel
        render.SuppressEngineLighting(true)

        -- Create a clientside model of your pot
        if not IsValid(self.VMModel) then
            self.VMModel = ClientsideModel("models/props_interiors/pot01a.mdl")
            self.VMModel:SetNoDraw(true)
        end

        -- Position it relative to the player’s eye
        local pos = EyePos() + EyeAngles():Forward() * 30 + EyeAngles():Right() * 15 + EyeAngles():Up() * -5
        local ang = EyeAngles()
        ang:RotateAroundAxis(ang:Right(), 0)
        ang:RotateAroundAxis(ang:Up(), 0)

        self.VMModel:SetPos(pos)
        self.VMModel:SetAngles(ang)
        self.VMModel:DrawModel()

        render.SuppressEngineLighting(false)
    end

    function SWEP:OnRemove()
        if IsValid(self.VMModel) then
            self.VMModel:Remove()
        end
    end
end