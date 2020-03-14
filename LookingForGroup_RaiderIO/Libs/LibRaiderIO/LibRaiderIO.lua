local RIO = LibStub:NewLibrary("LibRaiderIO",3)
if not RIO then return end
RIO.instances =
{
{258,2,12}, -- Ny'alotha, the Waking City
{254,2,8}, -- The Eternal Palace
}
RIO.dungeons = {140,137,142,144,146,138,145,143,141,139,256,257}

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
--RIO.constants = {3,2}

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
		RIO.characters[data] = provider
		provider.db = provider.db1 or provider.db2
	else
		RIO.lookups[data] = provider
		provider.lookup = provider.lookup1 or provider.lookup2
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
	local server_info = characters_data.db[server]
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
		if bucket then
			local lookup = RIO.lookups[data]
			if data == 1 then	-- dungeon
				return 1 + server_info[1] + (first - 2) * lookup.recordSizeInBytes
			else	
				if pool then
					wipe(pool)
				else
					pool = {}
				end		
				local constant = 2
				local pos = server_info[1]+(first-2) * constant
				local lkp = RIO.lookups[data].lookup
				local size = #lkp[1]
				local b = lkp[math.floor(pos/size)+1]
				local s = pos%size
				for i=1,constant do
					pool[i] = b[s+i]
				end
				return pool
			end
		end
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

function RIO.ReadBitsFromString(str, bitOffset, totalBitsToRead)
	local value = 0
	local readOffset = 0
	local firstByteShift = bitOffset % 8
	local bytesToRead = ceil((totalBitsToRead + firstByteShift) / 8)
	local strbyte = strbyte
	local floor = floor
	local band = bit.band
	local rshift = bit.rshift
	local lshift = bit.lshift
	local min = min
	while readOffset < totalBitsToRead do
		local byte = strbyte(str, 1 + floor((bitOffset + readOffset) / 8))
		local bitsRead = 0
		if readOffset == 0 then
			if bytesToRead == 1 then
				local availableBits = totalBitsToRead - readOffset
				value = band(rshift(byte, firstByteShift), ((lshift(1, availableBits)) - 1))
				bitsRead = totalBitsToRead
			else
				value = rshift(byte, firstByteShift)
				bitsRead = 8 - firstByteShift
			end
		else
			local availableBits = totalBitsToRead - readOffset
			if availableBits < 8 then
				value = value + lshift(band(byte, (lshift(1, availableBits) - 1)), readOffset)
				bitsRead = bitsRead + availableBits;
			else
				value = value + lshift(byte, readOffset)
				bitsRead = bitsRead + min(8, totalBitsToRead)
			end
		end
		readOffset = readOffset + bitsRead
	end

	if readOffset ~= totalBitsToRead then
		error('Read an improper number of bits. Expected ' .. totalBitsToRead .. ' got ' .. readOffset)
	end

	return value, bitOffset + readOffset
end

--[[
1  12   0       CURRENT_SCORE               current season score
2   7  12       CURRENT_ROLES               current season roles
3  14  19       PREVIOUS_SCORE              previous season score
4   7  33       PREVIOUS_ROLES              previous season roles
5  12  40       MAIN_CURRENT_SCORE          main's current season score
6   7  52       MAIN_CURRENT_ROLES          main's current season roles
7  11  59       MAIN_PREVIOUS_SCORE         main's previous season score
8   7  70       MAIN_PREVIOUS_ROLES         main's previous season roles
9  24  77       DUNGEON_RUN_COUNTS          number of runs this season for 5+, 10+, 15+, and 20+
10 84 101       DUNGEON_LEVELS              dungeon levels and stars for each dungeon completed
11  4 185       DUNGEON_BEST_INDEX          best dungeon index
]]
function RIO.score(raw,index)
	local str=RIO.lookups[1].db[1]
	local read_bits_from_str = RIO.ReadBitsFromString
	if index==1 then
		return read_bits_from_str(str,raw,12)
	elseif index == 2 then
		return read_bits_from_str(str,raw+19,12),read_bits_from_str(str,raw+31,2)
	elseif index == 3 then
		return read_bits_from_str(str,raw+40,12)
	else
		return read_bits_from_str(str,raw+59,9)*10,read_bits_from_str(str,raw+68,2)
	end
end

function RIO.dungeon(raw,index)
	local base = 101+index*7 + raw		--101: DUNGEON_LEVELS
	local str=RIO.lookups[1].db[1]
	local read_bits_from_str = RIO.ReadBitsFromString
	return read_bits_from_str(str,base,5),read_bits_from_str(str,base,2)
end

function RIO.DecodeBits6(value)
	if value < 10 then
		return value
	end
	return 10 + (value - 10) * 5
end

function RIO.keystone(raw,leveldiv5)
	local value = RIO.ReadBitsFromString(RIO.lookups[1].db[1],raw+71+leveldiv5*6,6)
	if value < 10 then
		return value
	end
	return 10 + (value - 10) * 5
end

function RIO.max_dungeon(raw)
	return RIO.ReadBitsFromString(RIO.lookups[1].db[1],raw+185,4)+1
end

function RIO.role_process(raw,pool)
	local roles = RIO.ReadBitsFromString(RIO.lookups[1].db[1],raw,7)
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
		return RIO.role_process(raw+12,pool)
	elseif index == 2 then
		return RIO.role_process(raw+33,pool)
	elseif index == 3 then
		return RIO.role_process(raw+52,pool)
	else
		return RIO.role_process(raw+70,pool)
	end
end