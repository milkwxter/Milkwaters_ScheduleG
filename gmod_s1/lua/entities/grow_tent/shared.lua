AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Grow Tent"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

ENT.Model = "models/grow_tent/grow_tent.mdl"

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
			phys:SetMass(200)
        end
		
		-- custom stats
        self:SetNWBool("Growing", false)
        self:SetNWInt("Growth", 0)
        self:SetNWInt("Water", 0)
		self:SetNWInt("ShearCount", 0)
		self:SetNWInt("SoilUsesLeft", 0)
		self:SetNWVector("DirtColor", Vector(139/255, 69/255, 19/255))
	end
	
	-- called when a player uses it
	function ENT:Use(ply)
        -- make sure the guy using it exists
        if not IsValid(ply) or not ply:IsPlayer() then return end
		
		-- fully grown? time to shear
        if self:GetNWInt("Growth") >= 100 then
			-- only allow when trimmers are equipped
			local wep = ply:GetActiveWeapon()
			if not IsValid(wep) or wep:GetClass() ~= "weapon_planttrimmers" then
				DarkRP.notify(ply, 1, 4, "You need plant trimmers equipped to shear this plant!")
				return
			end
            local shears = self:GetNWInt("ShearCount", 0)

            -- not yet fully sheared
            if shears < 10 then
                self:SetNWInt("ShearCount", shears + 1)

                -- effects
                self:EmitSound("physics/wood/wood_strain2.wav", 75, 100)
                local effect = EffectData()
				local particleOrigin = self:GetPos() + self:GetUp() * 50
				particleOrigin = particleOrigin + Vector(0, 0, math.Rand(-20, 20))
                effect:SetOrigin(particleOrigin)
                util.Effect("weed_boom", effect, true, true)

                -- drop the product if that was the last shear
                if self:GetNWInt("ShearCount") >= 10 then
                    self:SetNWBool("Growing", false)
                    self:SetNWInt("Growth", 0)
                    self:SetNWInt("ShearCount", 0)
                    self:SetNWInt("SoilUsesLeft", self:GetNWInt("SoilUsesLeft") - 1)

                    local product = ents.Create("weed")
                    if IsValid(product) then
                        local ang = self:GetAngles()
                        product:SetPos(self:GetPos() + (ang:Up() * 50) + (ang:Forward() * 40))
                        product:Spawn()
                    end
                end
                return
            end
		end
	
        -- otherwise, start growing
        if not self:GetNWBool("Growing") then
			-- check if there is soil left
			if self:GetNWInt("SoilUsesLeft") <= 0 then return end
			
			-- if we passed every check, start growing
            self:SetNWBool("Growing", true)
        end
    end
	
	-- run every tick
    function ENT:Think()
        if self:GetNWBool("Growing") then
            local growth = self:GetNWInt("Growth")
            local water = self:GetNWInt("Water")

            if water > 0 and growth < 100 then
                self:SetNWInt("Water", math.max(water - 1, 0))
                self:SetNWInt("Growth", math.min(growth + 2, 100))
            end
			
			-- stop growing once fully grown
			if self:GetNWInt("Growth") >= 100 then
				self:SetNWBool("Growing", false)
			end
        end

        self:NextThink(CurTime() + 1)
        return true
    end
end

if CLIENT then
	-- make some clientside models
	function ENT:Initialize()
        self.PlantModel = ClientsideModel("models/weed_plant/weed_plant.mdl")
        if IsValid(self.PlantModel) then
            self.PlantModel:SetNoDraw(true)
        end
		
		self.PotModel = ClientsideModel("models/weed_pot/weed_pot.mdl")
		
		self.DirtModel = ClientsideModel("models/hunter/tubes/circle2x2.mdl")
		self.DirtModel:SetMaterial("models/props_c17/FurnitureMetal001a")
		if IsValid(self.DirtModel) then
            self.DirtModel:SetNoDraw(true)
        end
    end
	
	-- delete some clientside models
	function ENT:OnRemove()
        if IsValid(self.PlantModel) then
            self.PlantModel:Remove()
        end
		
		if IsValid(self.PotModel) then
            self.PotModel:Remove()
        end
		
		if IsValid(self.DirtModel) then
            self.DirtModel:Remove()
        end
    end
	
	-- called every tick as well
	function ENT:Draw()
		-- do the basics
		self:DrawModel()
		
		-- set text positions and angles
		local ang = self:GetAngles()
        local pos = self:GetPos() + (ang:Up() * 80) + (ang:Forward() * 25)
		ang:RotateAroundAxis(ang:Right(), -90)
        ang:RotateAroundAxis(ang:Up(), 90)
		
		-- plant stats
		local plantName = "Grow Tent"
        local growth = self:GetNWInt("Growth", 0)
        local water = self:GetNWInt("Water", 0)
        local growing = self:GetNWBool("Growing", false)
		local shears = self:GetNWInt("ShearCount", 0)
		local soil = self:GetNWInt("SoilUsesLeft", 0)
		
		-- add the text
        cam.Start3D2D(pos, ang, 0.2)
		if growing then
			draw.SimpleTextOutlined("Plant Growing...", "DermaLarge", 0, -40, Color(0,255,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
			draw.SimpleTextOutlined("Growth: " .. growth .. "%", "DermaDefaultBold", 0, -20, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
			draw.SimpleTextOutlined("Water: " .. water .. "%", "DermaDefaultBold", 0, 0, Color(0,150,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
			draw.SimpleTextOutlined("Soil Uses Left: " .. soil, "DermaDefaultBold", 0, 20, Color(139,69,19), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
		else
			if growth >= 100 then
				draw.SimpleTextOutlined("Press E to Shear!", "DermaLarge", 0, -20, Color(255,255,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
				draw.SimpleTextOutlined("Shears left: " .. shears .. "/10", "DermaDefaultBold", 0, 0, Color(0,150,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
			else
				if soil > 0 then
					draw.SimpleTextOutlined("Press E to Start Growing", "DermaLarge", 0, -20, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
				else
					draw.SimpleTextOutlined("Needs Soil!", "DermaLarge", 0, -20, Color(200,50,50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
				end
				draw.SimpleTextOutlined("Soil Uses Left: " .. soil, "DermaDefaultBold", 0, 10, Color(139,69,19), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
			end
		end
	cam.End3D2D()
		
		-- draw a fun little plant model
        if IsValid(self.PlantModel) and growth > 0 then
            local plantPos = self.DirtModel:GetPos()
            local plantAng = self.DirtModel:GetAngles()
			
            local scale = Lerp(growth / 100, 0.1, 0.8)

            local mat = Matrix()
            mat:Scale(Vector(scale, scale, scale))
            self.PlantModel:EnableMatrix("RenderMultiply", mat)

            self.PlantModel:SetPos(plantPos)
            self.PlantModel:SetAngles(plantAng)
            self.PlantModel:DrawModel()
        end
		
		-- draw a pot model
        if IsValid(self.PotModel) then
            local potPos = self:GetPos()
            local potAng = self:GetAngles()

            self.PotModel:SetPos(potPos)
            self.PotModel:SetAngles(potAng)
            self.PotModel:DrawModel()
        end
		
		-- draw a dirt model
        if IsValid(self.DirtModel) and soil >= 1 then
			local dirtColorVec = self:GetNWVector("DirtColor", Vector(139/255, 69/255, 19/255))
			local dirtColor = Color(dirtColorVec.x * 255, dirtColorVec.y * 255, dirtColorVec.z * 255)
	
            local dirtPos = self:GetPos() + (self:GetUp() * 25) + (self:GetForward() * 2.5) + (self:GetRight() * 1.1)
            local dirtAng = self:GetAngles()
			
			local scale = 0.29

            local mat = Matrix()
            mat:Scale(Vector(scale, scale, scale))
            self.DirtModel:EnableMatrix("RenderMultiply", mat)

            self.DirtModel:SetPos(dirtPos)
            self.DirtModel:SetAngles(dirtAng)
			render.SetColorModulation(dirtColor.r/255, dirtColor.g/255, dirtColor.b/255)
			self.DirtModel:DrawModel()
			render.SetColorModulation(1, 1, 1)
        end
		
		-- purple grow light effect
        if growing then
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos = self:GetPos() + self:GetUp() * 50
                dlight.r = 180
                dlight.g = 0
                dlight.b = 255
                dlight.brightness = 2
                dlight.Decay = 500
                dlight.Size = 250
                dlight.DieTime = CurTime() + 0.1 -- refresh every frame
            end
        end
	end
end
