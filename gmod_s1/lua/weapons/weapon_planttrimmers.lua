AddCSLuaFile()

SWEP.PrintName = "Plant Trimmers"
SWEP.Author = "Milkwater"
SWEP.Instructions = "Necessary to trim plants!"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.IconOverride = "weapons/weapon_planttrimmers.png"
SWEP.Category = "DarkRP (Schedule 1)"

if CLIENT then
    SWEP.WepSelectIcon = surface.GetTextureID("vgui/entities/weapon_planttrimmers")
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
SWEP.WorldModel = "models/plant_trimmers/plant_trimmers.mdl"

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
	
    self:EmitSound("physics/wood/wood_strain2.wav")
    self:SetNextPrimaryFire(CurTime() + 0.3)
end

if CLIENT then
    function SWEP:PostDrawViewModel(vm, wep, ply)
        if not IsValid(self.VMModel) then
            self.VMModel = ClientsideModel("models/plant_trimmers/plant_trimmers.mdl")
            self.VMModel:SetNoDraw(true)
        end
		
        local pos = EyePos() + (EyeAngles():Forward() * 20) + (EyeAngles():Right() * 5) + (EyeAngles():Up() * -5)
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