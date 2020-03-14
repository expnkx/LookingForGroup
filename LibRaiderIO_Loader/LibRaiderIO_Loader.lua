local faction = UnitFactionGroup("player")
local my_faction
if faction == "Alliance" then
	my_faction = 1
elseif faction == "Horde" then
	my_faction = 2
end

local region = GetCurrentRegion()
local my_region
if region == 1 then
	my_region = "us"
elseif region == 2 then
	my_region = "kr"
elseif region == 3 then
	my_region = "eu"
elseif region == 4 then
	my_region = "tw"
elseif region == 5 then
	my_region = "cn"
end

local original_add_provider = RaiderIO.AddProvider
local exposed_providers = {}
RaiderIO.libraiderio_loader_exposed_providers = exposed_providers

function RaiderIO.AddProvider(provider)
	exposed_providers[#exposed_providers+1] = provider
	if my_faction == provider.faction and my_region == provider.region then
		local exposed_current_region_faction_providers = RaiderIO.libraiderio_loader_exposed_current_region_faction_providers
		if exposed_current_region_faction_providers == nil then
			exposed_current_region_faction_providers={}
			RaiderIO.libraiderio_loader_exposed_current_region_faction_providers = exposed_current_region_faction_providers
		end
		exposed_current_region_faction_providers[#exposed_current_region_faction_providers+1] = provider
	end
	local copied_provider = {} -- since raider.io would make changes towards the original table. We will provide the Raider.IO a copy of the table
	for k,v in pairs(provider) do
		copied_provider[k] = v
	end
	original_add_provider(copied_provider)
end