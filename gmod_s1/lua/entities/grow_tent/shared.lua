AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Grow Tent"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
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
		self:SetNWVector("DirtColor", Vector(255/255, 255/255, 255/255))
        self:SetNWString("PotType", "")
        self:SetNWInt("MaxGrowth", 100)
		
		-- growing weed stats
		self:SetNWVector("PlantColor", Vector(255/255, 255/255, 255/255))
        self:SetNWString("Product", "")
        self:SetNWString("PlantName", "")
	end
	
	-- called when a player uses it
	function ENT:Use(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		
		-- my vars
		local growth = self:GetNWInt("Growth", 0)
		local shears = self:GetNWInt("ShearCount", 0)
		local soilUses = self:GetNWInt("SoilUsesLeft", 0)
		local isGrowing = self:GetNWBool("Growing", false)
		local seed = self:GetNWBool("PlantName", "")
		local maxGrowth = self:GetNWInt("MaxGrowth", 0)
		
		-- ready for harvest path
		if growth >= maxGrowth then
			local wep = ply:GetActiveWeapon()
			if not IsValid(wep) or (wep:GetClass() ~= "weapon_planttrimmers" and wep:GetClass() ~= "weapon_electrictrimmers") then
				DarkRP.notify(ply, 1, 4, "You need plant trimmers equipped to shear this plant!")
				return
			end
			
			-- check trimmers
			local toShear = 0
			if wep:GetClass() == "weapon_planttrimmers" then
				toShear = 1
			elseif wep:GetClass() == "weapon_electrictrimmers" then
				toShear = 10
			end

			if shears < 10 then
				self:SetNWInt("ShearCount", shears + toShear)

				self:EmitSound("physics/wood/wood_strain2.wav", 75, 100)
				local effect = EffectData()
				local particleOrigin = self:GetPos() + self:GetUp() * 50 + Vector(0, 0, math.Rand(-20, 20))
				effect:SetOrigin(particleOrigin)
				util.Effect("weed_boom", effect, true, true)

				if self:GetNWInt("ShearCount") >= 10 then
					self:ProduceWeed(8)
				end
			end
			return
		end
		
		-- starting growth path
		if not isGrowing and soilUses > 0 and seed ~= "" then
			self:SetNWBool("Growing", true)
		end
	end
	
	-- run every tick
    function ENT:Think()
        if self:GetNWBool("Growing") then
            local growth = self:GetNWInt("Growth")
            local water = self:GetNWInt("Water")
			local potType = self:GetNWString("PotType")
			local plantName = self:GetNWString("PlantName")
            local maxGrowth = self:GetNWInt("MaxGrowth")

			-- if we are allowed to grow
            if water > 0 and growth < maxGrowth and plantName ~= "" then
				-- increment growth regardless
                self:SetNWInt("Growth", math.min(growth + 1, maxGrowth))
				
				-- decrease water based on pot type
				if potType == "pot_water_retaining" then
					self:SetNWInt("Water", math.max(water - 0.5, 0))
				elseif potType == "pot_plastic" then
					self:SetNWInt("Water", math.max(water - 1, 0))
				end
            end
			
			-- stop growing once fully grown
			if self:GetNWInt("Growth") >= maxGrowth then
				self:SetNWBool("Growing", false)
			end
        end

        self:NextThink(CurTime() + 1)
        return true
    end
	
	function ENT:ProduceWeed(amount)
		amount = tonumber(amount) or 1
		local soilUses = self:GetNWInt("SoilUsesLeft", 0)

		-- reset vars
		self:SetNWBool("Growing", false)
		self:SetNWInt("Growth", 0)
		self:SetNWInt("ShearCount", 0)
		self:SetNWInt("SoilUsesLeft", soilUses - 1)
		self:SetNWString("PlantName", "")

		local productClass = self:GetNWString("Product", "")
		local basePos = self:GetPos()
		local ang = self:GetAngles()

		for i = 1, amount do
			local product = ents.Create(productClass)
			if IsValid(product) then
				-- stagger each spawn slightly to avoid overlap
				local offset = (ang:Forward() * 30) + (ang:Up() * (40 + i * 10))
				product:SetPos(basePos + offset)
				product:Spawn()
			end
		end
	end
end

if CLIENT then
	-- materials
	local matWater = Material("vgui/icons/water_icon.png", "smooth")
	local matSoil = Material("vgui/icons/soil_icon.png", "smooth")
	local matPlant = Material("vgui/icons/plant_icon.png", "smooth")

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
		local plantName = self:GetNWString("PlantName", "")
        local maxGrowth = self:GetNWInt("MaxGrowth", 0)
		
		-- complex stats
		local growthPercent = (100 / maxGrowth) * growth
		
		-- plant color
		local plantColorVec = self:GetNWVector("PlantColor", Vector(255/255, 255/255, 255/255))
		local plantColor = Color(plantColorVec.x * 255, plantColorVec.y * 255, plantColorVec.z * 255)
		
		-- get the pot model
		local potType = self:GetNWString("PotType")
		if self.LastPotType ~= potType then
			self:UpdatePotModel()
			self.LastPotType = potType
		end
		
		-- add the text
        cam.Start3D2D(pos, ang, 0.2)
		local headline, headlineColor, headlineY = nil, nil, -20
		if growing then
			if water > 0 then
				headline, headlineColor, headlineY = "Plant Growing...", Color(0,255,0), -40
			else
				headline, headlineColor, headlineY = "Needs Water!", Color(200,50,50), -40
			end

			draw.SimpleTextOutlined(headline, "DermaLarge", 0, headlineY, headlineColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
			draw.SimpleTextOutlined("Plant: " .. plantName, "DermaDefaultBold", 0, -10, plantColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
		else
			if growth >= maxGrowth then
				draw.SimpleTextOutlined("Press E to Shear!", "DermaLarge", 0, -20, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
				draw.SimpleTextOutlined("Shears left: " .. shears .. "/10", "DermaDefaultBold", 0, 0, Color(0, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
			else
				if soil > 0 and potType ~= "" and plantName ~= "" then
					headline, headlineColor = "Press E to Start Growing", Color(255, 255, 255)
				elseif potType == "" then
					headline, headlineColor = "Needs a Pot!", Color(200, 50, 50)
				elseif soil <= 0 then
					headline, headlineColor = "Needs Soil!", Color(200, 50, 50)
				else
					headline, headlineColor = "Needs a Seed!", Color(200, 50, 50)
				end

				draw.SimpleTextOutlined(headline, "DermaLarge", 0, -20, headlineColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
			end
		end
		cam.End3D2D()
		
		-- draw a fun little plant model
        if IsValid(self.PlantModel) and growthPercent > 0 then
            local plantPos = self.DirtModel:GetPos()
            local plantAng = self.DirtModel:GetAngles()
			
            local scale = Lerp(growthPercent / 100, 0.1, 0.8)

            local mat = Matrix()
            mat:Scale(Vector(scale, scale, scale))
            self.PlantModel:EnableMatrix("RenderMultiply", mat)

            self.PlantModel:SetPos(plantPos)
            self.PlantModel:SetAngles(plantAng)
			render.SetColorModulation(plantColor.r/255, plantColor.g/255, plantColor.b/255)
			self.PlantModel:DrawModel()
			render.SetColorModulation(1, 1, 1)
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
			local dirtColorVec = self:GetNWVector("DirtColor", Vector(255/255, 255/255, 255/255))
			local dirtColor = Color(dirtColorVec.x * 255, dirtColorVec.y * 255, dirtColorVec.z * 255)
	
            local dirtPos = self:GetPos() + (self:GetUp() * 25)
            local dirtAng = self:GetAngles()
			
			local scale = 0.3

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
				-- refresh every frame
                dlight.DieTime = CurTime() + 0.1
            end
        end
		
		-- draw a water bar
		local barLength = 70
		local barHeight = 20
		local barOffsetY = 330
		cam.Start3D2D(pos, ang, 0.2)
			-- background
			surface.SetDrawColor(50, 50, 50, 200)
			surface.DrawRect(-barLength/2, barOffsetY - barHeight/2, barLength, barHeight)

			-- fill
			local fillWidth = math.Clamp(water, 0, 100) / 100 * barLength
			surface.SetDrawColor(0, 150, 255, 255)
			surface.DrawRect(-barLength/2, barOffsetY - barHeight/2, fillWidth, barHeight)

			-- outline
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawOutlinedRect(-barLength/2, barOffsetY - barHeight/2, barLength, barHeight)

			-- icon to the left
			surface.SetMaterial(matWater)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(-barLength/2 - 20, barOffsetY - barHeight/2 + 2, 16, 16)

			-- text overlay
			draw.SimpleText(water .. "%", "DermaDefaultBold", 0, barOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
		
		-- draw a soil bar
		barOffsetY = barOffsetY - 25
		cam.Start3D2D(pos, ang, 0.2)
			-- background
			surface.SetDrawColor(50, 50, 50, 200)
			surface.DrawRect(-barLength/2, barOffsetY - barHeight/2, barLength, barHeight)

			-- fill
			local fillWidth = math.Clamp(soil, 0, 3) / 3 * barLength
			surface.SetDrawColor(139, 69, 19, 255)
			surface.DrawRect(-barLength/2, barOffsetY - barHeight/2, fillWidth, barHeight)

			-- outline
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawOutlinedRect(-barLength/2, barOffsetY - barHeight/2, barLength, barHeight)

			-- icon to the left
			surface.SetMaterial(matSoil)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(-barLength/2 - 20, barOffsetY - barHeight/2 + 2, 16, 16)

			-- text overlay
			draw.SimpleText("Uses left: " .. soil, "DermaDefaultBold", 0, barOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
		
		-- draw a growth bar
		barOffsetY = barOffsetY - 25
		cam.Start3D2D(pos, ang, 0.2)
			-- background
			surface.SetDrawColor(50, 50, 50, 200)
			surface.DrawRect(-barLength/2, barOffsetY - barHeight/2, barLength, barHeight)

			-- fill
			local fillWidth = math.Clamp(growth, 0, maxGrowth) / maxGrowth * barLength
			surface.SetDrawColor(plantColor)
			surface.DrawRect(-barLength/2, barOffsetY - barHeight/2, fillWidth, barHeight)

			-- outline
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawOutlinedRect(-barLength/2, barOffsetY - barHeight/2, barLength, barHeight)

			-- icon to the left
			surface.SetMaterial(matPlant)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(-barLength/2 - 20, barOffsetY - barHeight/2 + 2, 16, 16)

			-- text overlay
			draw.SimpleText(math.Round(growthPercent, 2) .. "%", "DermaDefaultBold", 0, barOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
	
	-- helper function to switch models for the pot
	function ENT:UpdatePotModel()
		local potType = self:GetNWString("PotType")

		-- remove old model if type changed or no pot
		if IsValid(self.PotModel) then
			self.PotModel:Remove()
			self.PotModel = nil
		end

		if potType ~= "" then
			if potType == "pot_water_retaining" then
				self.PotModel = ClientsideModel("models/weed_pot_water_retaining/weed_pot_water_retaining.mdl")
			else
				self.PotModel = ClientsideModel("models/weed_pot/weed_pot.mdl")
			end
			-- draw it manually in the draw function
			self.PotModel:SetNoDraw(true)
		end
	end
end
