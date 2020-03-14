local RIO = LibStub:GetLibrary("LibRaiderIO")
local LFG = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local LFG_RIO = LFG_OPT:GetModule("RaiderIO")
RIO.region=LFG_OPT.db.profile.io_region

LFG_OPT.Register("lfgscoresbrief",nil,function(name,tag)
	if tag == 0 then return end
	local pool = RIO.raw(1,strsplit("-",name))
	return pool and table.concat(LFG_RIO.role_concat({" ",RIO.score(pool,1)},pool,1,pool))
end)

local function encounters(rse,cache,groupID,categoryID,shortName,target_name)
	local name,server = strsplit("-",target_name)
	if categoryID == 2 then
		if cache == nil or #cache ~= 2 then
			cache = RIO.raw(1,name,server)
			if not cache then return end
		end
		local maxdungeon = RIO.max_dungeon(cache)
		local group_dungeon = RIO.group_ids[groupID]
		local dungeon,upgrade = RIO.dungeon(cache,group_dungeon)
		if maxdungeon==group_dungeon then
			if upgrade == 0 then
				GameTooltip:AddLine("★"..dungeon.."-",1,0,0)
			else
				GameTooltip:AddLine("★"..dungeon.."+"..upgrade,0,1,0)
			end
			return
		end
		if upgrade == 0 then
			GameTooltip:AddLine(dungeon.."-",1,0,0)
		else
			GameTooltip:AddLine(dungeon.."+"..upgrade,0,1,0)
		end
		local dungeon,upgrade = RIO.dungeon(cache,maxdungeon)
		local best_dungeon_name = C_LFGList.GetActivityGroupInfo(RIO.dungeons[maxdungeon])
		if upgrade == 0 then
			GameTooltip:AddLine("★"..best_dungeon_name,1,0,0)
			GameTooltip:AddLine(dungeon.."-",1,0,0)
		else
			GameTooltip:AddLine("★"..best_dungeon_name,0,1,0)
			GameTooltip:AddLine(dungeon.."+"..upgrade,0,1,0)
		end
		return
	end
	if categoryID ~= 3 then
		return
	end
	if cache == nil or #cache ~= 3 then
		cache = RIO.raw(2,name,server)
	end
	local ib = LFG_OPT.generate_encounters_table(groupID)
	if not ib then
		return
	end
	local difficulty,count,bosses,has_pool,instance,temp = RIO.raid_group(cache,groupID,shortName,{})
	if bosses == -1 then
		return
	end
	GameTooltip:AddLine(" ")
	if count == bosses then
		GameTooltip:AddDoubleLine(rse and #rse or 0,count.."/"..bosses,nil,nil,nil,0, 1, 0)
	else
		GameTooltip:AddDoubleLine(rse and #rse or 0,count.."/"..bosses,nil,nil,nil,1, 0, 0)
	end
	if not temp then
		if rse then rse[0] = true end
		return
	end
	if rse then
		local j = 1
		for i=1,#temp do
			local tempi = temp[i]
			if ib[i] == rse[j] then
				if tempi == 0 then
					GameTooltip:AddDoubleLine(ib[i],0,1,0,0,1,0,0)
				else
					GameTooltip:AddDoubleLine(ib[i],tempi,1,0,0,0,1,0)
				end
				j = j + 1
			else
				if tempi == 0 then
					GameTooltip:AddDoubleLine(ib[i],0,0,1,0,1,0,0)
				else
					GameTooltip:AddDoubleLine(ib[i],tempi,0,1,0,0,1,0)
				end
			end
		end
	else
		for i=1,#temp do
			local tempi = temp[i]
			if tempi == 0 then
				GameTooltip:AddDoubleLine(ib[i],0,0,1,0,1,0,0)
			else
				GameTooltip:AddDoubleLine(ib[i],temp[i],0,1,0,0,1,0)
			end
		end
	end
	return cache
end

local orig_handle_encounters = LFG_OPT.handle_encounters

function LFG_OPT.handle_encounters(rse,cache,info,groupID,categoryID,shortName)
	local leaderName = info.leaderName
	if leaderName then
		local c = encounters(rse,cache,groupID,categoryID,shortName,leaderName)
		if c then
			return c
		end
	end
	return orig_handle_encounters(rse,cache,info,groupID,categoryID,shortName)
end

LFG_OPT.Register("applicant_tooltips",nil,function(val,entry,profile)
	if profile.rio_disable then
		return
	end
	local fullName, shortName, categoryID, groupID = C_LFGList.GetActivityInfo(entry.activityID)
	if categoryID ~= 2 and categoryID ~= 3 then
		return
	end
	local cache = {}
	return function(val,entry,profile)
		local info = C_LFGList.GetApplicantInfo(val)
		for i=1,info.numMembers do
			if i ~= 1 then
				GameTooltip:AddLine(" ")
			end
			local name = C_LFGList.GetApplicantMemberInfo(val,i)
			GameTooltip:AddLine(name)
			encounters(nil,cache,groupID,categoryID,shortName,name)
		end
	end
end)
