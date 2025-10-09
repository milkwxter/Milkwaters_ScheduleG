DEFINE_BASECLASS("base_shop_npc")

ENT.PrintName = "NPC Hardware Store"
ENT.Author = "Milkwater"
ENT.Category = "DarkRP (Schedule 1)"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true
ENT.ShopName = "Dan's Hardware"
ENT.ShopModel = "models/Humans/Group02/male_06.mdl"
ENT.MaxItemsPerPurchase = 10

ENT.ShopTheme = {
    Background = Color(255, 255, 255),
    CardBackground = Color(240, 240, 240),
    TabBackground = Color(50, 91, 130),
    TabForeground = Color(79, 140, 197),
    Text = Color(0, 0, 0),
    Price = Color(90, 185, 90),
}

ENT.Categories = {
    {name = "Agriculture", items = {
        {name = "Grow Tent", price = 100, class = "grow_tent"},
        {name = "Soil Bag", price = 10, class = "soil_bag"},
        {name = "Long Life Soil Bag", price = 30, class = "soil_bag_long_life"},
        {name = "Extra Long Life Soil Bag", price = 60, class = "soil_bag_extra_long_life"},
        {name = "Plastic Pot", price = 20, class = "pot_plastic"},
        {name = "Water Retaining Pot", price = 50, class = "pot_water_retaining"},
    }},
    {name = "Tools", items = {
        {name = "Plant Trimmers", price = 10, class = "weapon_planttrimmers"},
        {name = "Watering Can", price = 15, class = "weapon_wateringcan"},
        {name = "Electric Plant Trimmers", price = 1000, class = "weapon_electrictrimmers"},
    }},
    {name = "Packaging", items = {
        {name = "Baggie", price = 1, class = "weed"},
        {name = "Jar", price = 3, class = "weed"},
    }},
}

function ENT:HandlePurchase(ply, class, price, amount)
    for i = 1, amount do
		local ent = ents.Create(class)
		if not IsValid(ent) then
			DarkRP.notify(ply, 1, 4, "Could not create item.")
			return
		end
		
		ent:SetPos(ply:GetPos())
		ent:Spawn()
		ply:addPocketItem(ent)
    end
	
	-- tell player of results
	DarkRP.notify(ply, 0, 4, "Purchased " .. amount .. "x " .. class .. " for $" .. price)
end