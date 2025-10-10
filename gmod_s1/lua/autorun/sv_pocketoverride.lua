hook.Add("PostGamemodeLoaded", "RemovePocketDrop", function()
	-- remove darkrps hook
    hook.Remove("PlayerDeath", "DropPocketItems")

	-- add mine
    hook.Add("PlayerDeath", "SpawnDeathCache", function(ply)
		-- checks
        if not IsValid(ply) then return end
		if not ply.darkRPPocket or table.IsEmpty(ply.darkRPPocket) then return end
		
		-- create the cache
		local cache = ents.Create("death_cache")
		if not IsValid(cache) then return end
		
		cache:SetPos(ply:GetPos() + Vector(0,0,10))
		cache:Spawn()

		-- store some info
		cache:SetPlayerName(ply:Nick())

		-- transfer pocket items into cache
		local items = ply:getPocketItems()
        if not items or table.IsEmpty(items) then return end
		for _, data in pairs(items) do
            if not cache:IsFull() and isstring(data.class) then
                cache:AddItem(data.class)
            end
        end
		
		-- remove players items
		for ent in pairs(ply.darkRPPocket or {}) do
			ply:removePocketItem(ent)
		end

		DarkRP.notify(ply, 0, 4, "Your items have been stored in a death cache.")
    end)
end)
