function EFFECT:Init(data)
    self.offset = data:GetOrigin() + Vector(0, 0, 0.2)
    self.particles = 32

    local emitter = ParticleEmitter(self.offset, false)
    for i = 1, self.particles do
        local particle = emitter:Add("particles/steam", self.offset)
        if particle then
            local dir = VectorRand()
            dir.z = math.Rand(0.5, 1)
            dir:Normalize()

            particle:SetVelocity(dir * math.Rand(50, 150))

            particle:SetLifeTime(0)
            particle:SetDieTime(math.Rand(2.5, 4))

            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)

            particle:SetStartSize(math.Rand(5, 10))
            particle:SetEndSize(math.Rand(40, 60))

            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(math.Rand(-0.5, 0.5))

            particle:SetAirResistance(100)
            particle:SetGravity(Vector(0, 0, math.Rand(20, 40)))
            particle:SetCollide(false)
        end
    end
    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
