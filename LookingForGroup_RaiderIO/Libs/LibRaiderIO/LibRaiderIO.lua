local RIO = LibStub:NewLibrary("LibRaiderIO",3)
if not RIO then return end
RIO.instances =
{
{254,2,8}, -- The Eternal Palace
{251,2,9}, -- Battle of Dazar'alor
}
RIO.dungeons = {140,137,142,144,146,138,145,143,141,139}

RIO.raid_types = 7
RIO.score_types = 4
RIO.keystone_levels = 4
RIO.keystone_levels_range = 2
RIO.group_ids = {}
for i=1,#RIO.instances do
	local e = RIO.instances[i]
	RIO.group_ids[e[1]] = e
end

for i=1,#RIO.dungeons do
	RIO.group_ids[RIO.dungeons[i]] = i
end

RIO.characters = {}
RIO.lookups = {}
RIO.constants = {3,2}

RIO.decode =
{
{0,1,2,5},
{0,1,2,3,4,5,10,20},
{0,1,2,3,4,5,6,7,8,9,10,15,20,25,50,100},
{PLAYER_DIFFICULTY1,PLAYER_DIFFICULTY2,PLAYER_DIFFICULTY6},
{392260842160640,463455831238226,4406570008493662,4829607409813010,5595827431087636,6440549256539808,1020647353890488,1175956550689488,192446621930216,9271499395563044,9694536765937190,10945404392723974,11367755910503224,324}
}

function RIO.AddProvider(provider)
	local providers = RIO.providers
	providers[#providers+1] = provider
	local data = provider.data
	local db = provider.db1 or provider.db2
	if db then
		RIO.characters[data] = db
	else
		local lookup = provider.lookup1 or provider.lookup2
		RIO.lookups[data] = lookup
	end
end

function RIO.raw(data,player,server,pool)
	if RIO.providers == nil then
		RIO.providers = {}
		if RaiderIO and RaiderIO.libraiderio_loader_exposed_current_region_faction_providers then
			local exposed_current_region_faction_providers = RaiderIO.libraiderio_loader_exposed_current_region_faction_providers
			local AddProvider = RIO.AddProvider
			for i=1,#exposed_current_region_faction_providers do
				AddProvider(exposed_current_region_faction_providers[i])
			end
			RIO.providers = exposed_current_region_faction_providers
		else
			local faction = UnitFactionGroup("player")
			local region = RIO.region or GetCurrentRegion()
			local GetAddOnMetadata = GetAddOnMetadata
			local GetAddOnInfo = GetAddOnInfo
			local IsAddOnLoaded = IsAddOnLoaded
			for i = 1, GetNumAddOns() do
				if not IsAddOnLoaded(i) then
					local metadata = GetAddOnMetadata(i, "X-RAIDER-IO-LOD")
					if metadata and region == tonumber(metadata) and GetAddOnMetadata(i, "X-RAIDER-IO-LOD-FACTION") == faction then
						local original_RaiderIO = RaiderIO
						RaiderIO = RIO
						LoadAddOn(i)
						RaiderIO = original_RaiderIO
					end
				end
			end
		end
		RIO.AddProvider = nil
	end
	if server == nil then
		server = GetNormalizedRealmName()
	end
	local characters_data = RIO.characters[data]
	if characters_data == nil then return end
	local server_info = characters_data[server]
	if server_info == nil then return end
--lower bound : https://en.cppreference.com/w/cpp/algorithm/lower_bound
	local first,last = 2,#server_info+1
	local count = last - first
	local rshift = bit.rshift
	while 0 < count do
		local step = rshift(count,1)
		local it = first + step
		if server_info[it] < player then
			first = it + 1
			count = count - 1 - step
		else
			count = step
		end
	end
--binary search : https://en.cppreference.com/w/cpp/algorithm/binary_search
	if first~=last and server_info[first] <= player then
		if pool then
			wipe(pool)
		else
			pool = {}
		end
		local constant = RIO.constants[data] or 1
		local pos = server_info[1]+(first-2) * constant
		local lkp = RIO.lookups[data]
		local size = #lkp[1]
		local b = lkp[math.floor(pos/size)+1]
		local s = pos%size
		for i=1,constant do
			pool[i] = b[s+i]
		end
		return pool
	end
end

function RIO.ReadBits(lo, hi, offset, bits)
	local bit = bit
	if offset < 32 and (offset + bits) > 32 then
		-- reading across boundary
		local mask = bit.lshift(1, (offset + bits) - 32) - 1
		local p1 = bit.rshift(lo, offset)
		local p2 = bit.lshift(bit.band(hi, mask), 32 - offset)
		return p1 + p2
	else
		local mask = bit.lshift(1, bits) - 1
		if offset < 32 then
			-- standard read from loword
			return bit.band(bit.rshift(lo, offset), mask)
		else
			-- standard read from hiword
			return bit.band(bit.rshift(hi, offset - 32), mask)
		end
	end
end

function RIO.Split64BitNumber(d)
	local lo = bit.band(d, 0xfffffffff)
	return lo, (d - lo) / 0x100000000
end

function RIO.raid_process(raw,pos,instance,pool)
	local lo, hi = RIO.Split64BitNumber(raw)
	local read_bits = RIO.ReadBits
	local difficulty = read_bits(lo,hi,pos,2)
	local bosses = instance[3]
	if difficulty == 0 then
		return
	end
	local count = 0
	if pool == nil then
		for i=1, bosses do
			if 0 ~= read_bits(lo,hi,pos+i*2,2) then
				count = count + 1
			end
		end
	elseif type(pool) == "table" then
		wipe(pool)
		local dc = RIO.decode[1]
		for i=1, bosses do
			local c = dc[read_bits(lo,hi,pos+i*2,2)+1]
			pool[i] = c
			if 0 ~= c then
				count = count + 1
			end
		end
	else
		return difficulty,read_bits(lo,hi,pos+2,4),bosses,false,instance,pool
	end
	return difficulty,count,bosses,true,instance,pool
end

function RIO.raid(raw,index,pool)
	if type(pool)~="table" then
		pool = nil
	end
	local current = RIO.instances[1]
	local current_bosses = current[3]
	if index == 1 then	
		return RIO.raid_process(raw[1],0,current,pool)
	elseif index == 2 then
		return RIO.raid_process(raw[1],2*current_bosses+2,current,pool)
	elseif index == 3 then
		return RIO.raid_process(raw[2],0,current,pool)
	else
		if index < 6 then
			current = RIO.instances[2]
		end
		return RIO.raid_process(raw[2],2*current_bosses+6*index-22,current,5 < index)
	end
end

function RIO.raid_group(raw,groupID,shortName,pool)
	if raw then
		local decode = RIO.decode[4]
		local RIO_raid = RIO.raid
		for i=1,5 do
			local difficulty,count,bosses,has_pool,instance,temp = RIO_raid(raw,i,pool)
			if difficulty and instance[1] == groupID and (shortName == nil or decode[difficulty] == shortName) then
				return difficulty,count,bosses,has_pool,instance,temp
			end
		end
	end
	local e = RIO.group_ids[groupID]
	if type(e)=="table" then return false,0,e[3] end
	return false,0,-1
end

function RIO.score_process(raw,pos,bits,approximate)
	local lo, hi = RIO.Split64BitNumber(raw)
	local score = RIO.ReadBits(lo,hi,pos,bits)
	if approximate then
		return score * approximate,approximate
	end
	return score
end

function RIO.score(raw,index)
	if index == 1 then
		return RIO.score_process(raw[1],0,12)
	elseif index == 2 then
		return RIO.score_process(raw[3],#RIO.dungeons*7 - 42,9,10)
	elseif index == 3 then
		return RIO.score_process(raw[1],34,12)
	else
		return RIO.score_process(raw[3],#RIO.dungeons*7 - 26,9,10)
	end
end

function RIO.role_process(raw,pos,pool)
	local lo, hi = RIO.Split64BitNumber(raw)
	local roles = RIO.ReadBits(lo,hi,pos,7)
	local lw, hw = RIO.Split64BitNumber(RIO.decode[5][floor(roles/6)+1])
	local rl = RIO.ReadBits(lw,hw,(roles%6)*9,9)
	if pool then
		wipe(pool)
	else
		pool = {}
	end
	while rl ~= 0 do
		pool[#pool+1] = rl%7 - 1
		rl=floor(rl/7)
	end
	return pool
end

function RIO.role(raw,index,pool)
	if index == 1 then
		return RIO.role_process(raw[1],12,pool)
	elseif index == 2 then
		return RIO.role_process(raw[1],27,pool)
	elseif index == 3 then
		return RIO.role_process(raw[1],46,pool)
	else
		return RIO.role_process(raw[3],#RIO.dungeons*7-33,pool)
	end
end

function RIO.dungeon(raw,index)
	if index < 8 then
		raw = raw[2]
		index = 7 * index - 3
	else
		raw = raw[3]
		index = 7 * index - 56
	end
	local lo, hi = RIO.Split64BitNumber(raw)
	local read_bits = RIO.ReadBits
	return read_bits(lo,hi,index,5),read_bits(lo,hi,index+5,2)
end

function RIO.keystone(raw,leveldiv5)
	local b = leveldiv5 == 4 and 3 or 4
	local bs
	if leveldiv5 < 3 then
		raw = raw[1]
		bs = 15
	else
		raw = raw[3]
		bs = 9
	end
	local lo, hi = RIO.Split64BitNumber(raw)
	local dec = RIO.decode[b-1]
	local pos = RIO.ReadBits(lo,hi,bs+leveldiv5*4,b)+1
	if pos == #dec then
		return dec[pos],true
	end
	local nx = dec[pos+1]
	if nx == pos then
		return dec[pos]
	end
	return dec[pos],nx
end

function RIO.max_dungeon(raw)
	local lo, hi = RIO.Split64BitNumber(raw[2])
	return 1+RIO.ReadBits(lo, hi, 0, 4)
end
