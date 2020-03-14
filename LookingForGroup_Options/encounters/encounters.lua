local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")
local instance_tb = {}

function LookingForGroup_Options.generate_encounters_table(groupid)
	if groupid and groupid ~= 0 then
		local igp = instance_tb[groupid]
		if igp then
			return igp
		else
			local name = C_LFGList.GetActivityGroupInfo(groupid)
			local num = GetNumSavedInstances()
			local string_find = string.find
			local GetSavedInstanceInfo = GetSavedInstanceInfo
			for i=1,num do
				local instanceName, instanceID, _, instanceDifficulty, locked, _, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses = GetSavedInstanceInfo(i)
				if (string_find(name,instanceName) or string_find(instanceName,name)) then
					local encounters_tb = {}
					for j = 1, maxBosses do
						encounters_tb[j] = GetSavedInstanceEncounterInfo(i,j)
					end
					instance_tb[groupid] = encounters_tb
					return encounters_tb
				end
			end
		end
	end
end

local encounters_tb

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,mbnm)
	local rse = C_LFGList.GetSearchResultEncounterInfo(info.searchResultID)
	local encounters = profile.a.encounters
	local mct = 0
	if rse then
		for i=1,#rse do
			local gt = encounters[rse[i]]
			if gt then
				mct = mct + 1
			elseif gt == false then
				return 1
			end
		end
	end
	if mct < mbnm then
		return 1
	end
end,function(profile)
	local encounters = profile.a.encounters
	if encounters then
		local mbnm = 0
		for k,v in pairs(encounters) do
			if v then
				mbnm = mbnm + 1
			end
		end
		return mbnm
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info) return C_LFGList.GetSearchResultEncounterInfo(info.searchResultID) and 1 or 0 end,function(profile) return profile.a.new end)

LookingForGroup_Options.option_table.args.find.args.f.args.encounters =
{
	name = RAID_BOSSES,
	type = "group",
	args =
	{
		encounters =
		{
			order = 0,
			name = RAID_ENCOUNTERS,
			type = "multiselect",
			width = "full",
			values = function()
				local a = LookingForGroup_Options.db.profile.a
				if not encounters_tb or not a.encounters then
					encounters_tb = LookingForGroup_Options.generate_encounters_table(a.group)
				end
				return encounters_tb
			end,
			tristate = true,
			get = function(info,val)
				local encounters = LookingForGroup_Options.db.profile.a.encounters
				if encounters == nil then
					return false
				end
				local v = encounters[encounters_tb[val]]
				if v then
					return true
				elseif v == false then
					return nil
				end
				return false
			end,
			set = function(info,key,val)
				local k = false
				if val then
					k = true
				elseif val == false then
					k = nil
				end
				local a = LookingForGroup_Options.db.profile.a
				a.new = nil
				if a.encounters == nil then
					a.encounters = {}
				end
				a.encounters[encounters_tb[key]] = k
			end
		},
		clearall = 
		{
			order = 2,
			name = REMOVE_WORLD_MARKERS,
			type = "execute",
			func = function()
				LookingForGroup_Options.db.profile.a.encounters = nil
			end,
		},
		raidinfo = 
		{
			order = 3,
			name = RAID_INFO,
			type = "execute",
			func = function()
				local a = LookingForGroup_Options.db.profile.a
				repeat
				if encounters_tb == nil then
					break
				end
				local activity = a.activity
				local temp_encounters = a.encounters
				a.encounters = nil
				if activity == nil then
					break
				end
				local fullname,shortname = C_LFGList.GetActivityInfo(activity)
				local num = GetNumSavedInstances()
				local GetSavedInstanceInfo = GetSavedInstanceInfo
				local string_find = string.find
				for i=1,num do
					local instanceName, instanceID, _, instanceDifficulty, locked, _, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses = GetSavedInstanceInfo(i)
					if fullname:find(instanceName) and difficultyName == shortname then
						local t = {}
						for j = 1, maxBosses do
							local bossName, fileDataID, isKilled, unknown4 = GetSavedInstanceEncounterInfo(i,j)
							t[encounters_tb[j]] = locked and isKilled
						end
						if temp_encounters then
							local same = true
							for k,v in pairs(t) do
								if temp_encounters[k] ~= v then
									same = nil
									break
								end
							end
							if same then
								for k,v in pairs(temp_encounters) do
									if not v then
										if v == false then
											t[k] = nil
										else
											t[k] = false
										end
									end
								end
							end
						end
						a.encounters = t
						a.new = nil
						return
					end
				end
				until true
				a.new = not a.new
			end,
		},
		new =
		{
			name = NEW,
			type = "toggle",
			get = function()
				return LookingForGroup_Options.db.profile.a.new
			end,
			set = function(_,val)
				if val then
					LookingForGroup_Options.db.profile.a.new = true
					LookingForGroup_Options.db.profile.a.encounters = nil
				else
					LookingForGroup_Options.db.profile.a.new = nil
				end
			end,
			width = "full",
			order = 4,
		},
	}
}
