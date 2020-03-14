local RIO = LibStub:GetLibrary("LibRaiderIO")
local LFG = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local LFG_RIO = LFG_OPT:GetModule("RaiderIO")

function LFG_RIO.cache_info(info,tag)
	local rios = info.rios
	if rios == nil then
		rios = {}
		info.rios = rios
	end
	if rios.leaderName ~= info.leaderName then
		wipe(rios)
		rios.leaderName = info.leaderName
	end
	local riost = rios[tag]
	if riost then return riost end
	local raw = RIO.raw(tag,strsplit("-",info.leaderName))
	rios[tag] = raw
	return raw
end

local function io_min_score(rio_min_score,raw)
	local score = 0
	if raw then
		score = RIO.score(raw,1)
	end
	if score < rio_min_score then
		return 1
	end
end

local function io_max_score(rio_max_score,raw)
	local score = 0
	if raw then
		score = RIO.score(raw,1)
	end
	if rio_max_score < score then
		return 1
	end
end

local function io_elite_raid(info,raw1,raw2)
	local fullname,shortname,category,group = C_LFGList.GetActivityInfo(info.activityID)
	local difficulty,count,bosses = RIO.raid_group(raw1,group,shortname)
	local done = count==bosses
	local difficulty,count,bosses = RIO.raid_group(raw2,group,shortname)
	if done ~= (count == bosses) then
		return 1
	end
end

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,profile,v)
	return io_min_score(v,LFG_RIO.cache_info(info,1))
end,function(profile)
	return profile.a.category == 2 and not profile.rio_disable and profile.rio_min_score
end)

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,profile,v)
	return io_max_score(v,LFG_RIO.cache_info(info,1))
end,function(profile)
	return profile.a.category == 2 and not profile.rio_disable and profile.rio_max_score
end)

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,profile,player_raw)
	local fullname,shortname,category,group = C_LFGList.GetActivityInfo(info.activityID)
	local rio_dungeon_id = RIO.group_ids[group]
	if not rio_dungeon_id then return end
	local dg = 0
	local raw = LFG_RIO.cache_info(info,1)
	if raw then
		dg = RIO.dungeon(raw,rio_dungeon_id)
	end
	if dg + 2 < RIO.dungeon(player_raw,rio_dungeon_id) then
		return 1
	end
end,function(profile)
	return profile.a.category == 2 and not profile.rio_disable and profile.rio_elite and RIO.raw(1,UnitName("player"))
end)

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,profile,player_raw)
	return io_elite_raid(info,player_raw,LFG_RIO.cache_info(info,2))
end,function(profile)
	return profile.a.category == 3 and not profile.rio_disable and profile.rio_elite
			and RIO.raw(2,UnitFullName("player"))
end)

LFG_OPT.armory["IO "..PLAYER_OFFLINE] = function(playername)
	LFG_OPT.raider_io_name = playername
	LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","rioffline")
end

function LFG_RIO.cache_app_info(name,tag,cache)
	local raw = cache[name]
	if raw == nil then
		raw = RIO.raw(tag,strsplit("-",name))
		if raw == nil then
			raw = false
		end
		cache[name] = raw
	end
	if raw == false then
		return
	end
	return raw
end

local function applicant_trigger(value,category,profile,entryinfo)
	if value and not profile.rio_disable then
		local fullName, shortName, categoryID, groupID = C_LFGList.GetActivityInfo(entryinfo.activityID)
		if categoryID == category then
			return value
		end
	end
end

LFG_OPT.RegisterSimpleApplicantFilter("s",function(applicantID,i,profile,v,entryinfo,info,cache)
	return io_min_score(v,LFG_RIO.cache_app_info(C_LFGList.GetApplicantMemberInfo(applicantID,i),1,cache))
end,function(profile,entryinfo)
	return applicant_trigger(profile.rio_min_score,2,profile,entryinfo)
end)

LFG_OPT.RegisterSimpleApplicantFilter("s",function(applicantID,i,profile,v,entryinfo,info,cache)
	return io_max_score(v,LFG_RIO.cache_app_info(C_LFGList.GetApplicantMemberInfo(applicantID,i),1,cache))
end,function(profile,entryinfo)
	return applicant_trigger(profile.rio_max_score,2,profile,entryinfo)
end)

LFG_OPT.RegisterSimpleApplicantFilter("s",function(applicantID,i,profile,rio_elitist_level,entryinfo,info,cache)
	local fullname,shortname,category,group = C_LFGList.GetActivityInfo(entryinfo.activityID)
	local rio_dungeon_id = RIO.group_ids[group]
	if not rio_dungeon_id then return end
	local raw = LFG_RIO.cache_app_info(C_LFGList.GetApplicantMemberInfo(applicantID,i),1,cache)
	if not raw then
		return 1
	end
	local dg,up = RIO.dungeon(raw,rio_dungeon_id)
	if up == 0 then
		dg = dg - 2
	end
	if dg <= rio_elitist_level then
		return 1
	end
end,function(profile,entryinfo)
	return applicant_trigger(profile.rio_elitist_level,2,profile,entryinfo)
end)

LFG_OPT.RegisterSimpleApplicantFilter("s",function(applicantID,i,profile,player_raw,entryinfo,info,cache)
	return io_elite_raid(entryinfo,player_raw,LFG_RIO.cache_app_info(C_LFGList.GetApplicantMemberInfo(applicantID,i),2,cache))
end,function(profile,entryinfo,info,cache)
	return applicant_trigger(profile.rio_elite,2,profile,entryinfo) and LFG_RIO.cache_app_info(UnitName("player"),2,cache)
end)

LFG_OPT.Register("mplus_callbacks",nil,function(profile,a,s,keystone_level)
	profile.rio_elitist_level = keystone_level
end)