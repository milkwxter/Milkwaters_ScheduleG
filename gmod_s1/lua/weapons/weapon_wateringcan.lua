AddCSLuaFile()

SWEP.PrintName = "Watering Can"
SWEP.Author = "Milkwater"
SWEP.Instructions = "Left click to water plants!"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.IconOverride = "weapons/weapon_wateringcan.png"
SWEP.Category = "DarkRP (Schedule 1)"

if CLIENT then
    SWEP.WepSelectIcon = surface.GetTextureID("vgui/entities/weapon_wateringcan")
	SWEP.DrawWeaponInfoBox = true
end

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
SWEP.WorldModel = "models/watering_can/watering_can.mdl"

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
        phys:SetVelocity(ang * 400)
    end

    self:EmitSound("ambient/water/water_spray1.wav")
    self:SetNextPrimaryFire(CurTime() + 0.3)
end

if CLIENT then
    function SWEP:PostDrawViewModel(vm, wep, ply)
        if not IsValid(self.VMModel) then
            self.VMModel = ClientsideModel("models/watering_can/watering_can.mdl")
            self.VMModel:SetNoDraw(true)
        end
		
        local pos = EyePos() + (EyeAngles():Forward() * 20) + (EyeAngles():Right() * 10) + (EyeAngles():Up() * -15)
        local ang = EyeAngles()
        ang:RotateAroundAxis(ang:Right(), 0)
        ang:RotateAroundAxis(ang:Up(), 0)

        self.VMModel:SetPos(pos)
        self.VMModel:SetAngles(ang)
        self.VMModel:DrawModel()
    end

    function SWEP:OnRemove()
        if IsValid(self.VMModel) then
            self.VMModel:Remove()
        end
    end
end