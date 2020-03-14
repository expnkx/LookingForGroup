local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function keystone_information(detailed)
	local mapid = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	if not mapid then return end
	local maps_to_group_id =
	{
		[244] = 137,  -- Atal'Dazar
		[245] = 142,  -- Freehold
		[249] = 141,  -- Kings' Rest
		[252] = 143,  -- Shrine of the Storm
		[353] = 146,  -- Siege of Boralus
		[250] = 139,  -- Temple of Sethraliss
		[247] = 140,  -- The MOTHERLODE
		[251] = 138,  -- The Underrot
		[246] = 144,  -- Tol Dagor
		[248] = 145  -- Waycrest Manor
	}
	local groupid = maps_to_group_id[mapid]
	if not groupid then return end
	local labelname = LFG_OPT.mythic_keystone_label_name
	local groups = C_LFGList.GetAvailableActivities(nil,groupid)
	local C_LFGList_GetActivityInfo = C_LFGList.GetActivityInfo
	for i=1,#groups do
		local fullName, shortName = C_LFGList_GetActivityInfo(groups[i])
		if shortName == labelname then
			return groups[i],C_MythicPlus.GetOwnedKeystoneLevel()
		end
	end
end

local disable_text = "|cffff0000"..string.gsub(MYTHIC_PLUS_TAB_DISABLE_TEXT, "\n"," ").."|r"

LFG_OPT:push("m+",{
	name = LFG_OPT.mythic_keystone_label_name,
	type = "group",
	args =
	{
		title = 
		{
			order = 1,
			name = function()
				local t = C_MythicPlus.GetOwnedKeystoneLevel()
				if t then
					return t
				end
				return disable_text
			end,
			type = "input",
			dialogControl = "LFG_SECURE_NAME_EDITBOX_REFERENCE",
			width = "full"
		},
		create =
		{
			name = function()
				if C_LFGList.HasActiveEntryInfo() then
					return UNLIST_MY_GROUP
				else
					return LIST_GROUP
				end
			end,
			type = "execute",
			order = 2,
			func = function()
				if C_LFGList.HasActiveEntryInfo() then
					C_LFGList.RemoveListing()
					return
				end
				local activityID,key_level_number = keystone_information(true)
				if not activityID then
					LFG_OPT.expected(disable_text)
					return
				end
				if string.match(LFGListFrame.EntryCreation.Name:GetText(),"(%d+)") ~= tostring(key_level_number) then
					LFG_OPT.expected("|cffff0000Title does not contain the keyword|r "..key_level_number)
					return
				end
				local _,_,categoryID,groupID = C_LFGList.GetActivityInfo(activityID)
				local profile = LFG_OPT.db.profile
				local a = profile.a
				local category = a.category
				wipe(a)
				a.category = categoryID
				a.group = groupID
				a.activity = activityID
				if category ~= a.category then
						LFG_OPT.OnProfileChanged()
				end
				local s = profile.s
				local auto_accept = s.auto_accept
				wipe(s)
				s.auto_accept = auto_accept
				local mplus_callbacks = LFG_OPT.mplus_callbacks
				for i=1,#mplus_callbacks do
					mplus_callbacks[i](profile,a,s,key_level_number)
				end
				LFG_OPT.listing(a.activity,s,nil,{"m+"})
			end
		},
		reset =
		{
			name = RESET,
			type = "execute",
			order = 3,
			func = C_LFGList.ClearCreationTextFields
		},
		auto_accept =
		{
			order = 4,
			name = LFG_LIST_AUTO_ACCEPT,
			type = "toggle",
			get = LFG_OPT.options_get_s_function,
			set = LFG_OPT.options_set_s_function
		},
		desc = 
		{
			order = 5,
			name = function()
				C_MythicPlus.RequestCurrentAffixes()
				C_MythicPlus.RequestMapInfo()
				C_MythicPlus.RequestRewards()
				local t = {}
				local C_MythicPlus = C_MythicPlus
				if C_MythicPlus.IsWeeklyRewardAvailable() then
					t[#t+1] = "|cff00ff00"
					t[#t+1] = CLAIM_REWARD
					t[#t+1] = "|r\n"
				end
				local best_kl = 10
				local best_rw = C_MythicPlus.GetRewardLevelForDifficultyLevel(best_kl)
				while best_kl < 31 do
					local gg = C_MythicPlus.GetRewardLevelForDifficultyLevel(best_kl+3)
					if gg == best_rw then
						break
					end
					best_rw = gg
					best_kl = best_kl + 5
				end
				local owned_keystone_level = C_MythicPlus.GetOwnedKeystoneLevel()
				local rewarded_owned 
				if owned_keystone_level then
					rewarded_owned = C_MythicPlus.GetRewardLevelForDifficultyLevel(owned_keystone_level)
					t[#t+1] = format(MYTHIC_PLUS_MISSING_WEEKLY_CHEST_REWARD,owned_keystone_level,
										rewarded_owned)
				end
				if rewarded_owned ~= best_rw then
					if owned_keystone_level then
						t[#t+1] = "\n"
					end
					t[#t+1] = "|cffff0000"
					t[#t+1] = format(MYTHIC_PLUS_MISSING_WEEKLY_CHEST_REWARD,best_kl,best_rw)
					t[#t+1] = "|r"
				end
				local affixes = C_MythicPlus.GetCurrentAffixes()
				if affixes then
					t[#t+1] = "\n\n|cff8080cc"
					t[#t+1] = #affixes
					t[#t+1] = "|r"
					for i=1,#affixes do
						local name,description,filedataid = C_ChallengeMode.GetAffixInfo(affixes[i].id)
						t[#t+1] = "\n\n|T"
						t[#t+1] = filedataid
						t[#t+1] = ":0:0:0:0:10:10:1:9:1:9|t|cff8080cc"
						t[#t+1] = name
						t[#t+1] = "|r\n"
						t[#t+1] = description
					end
				end
				local currentWeekBestLevel,weeklyRewardLevel,nextDifficultyWeeklyRewardLevel,nextBestLevel=C_MythicPlus.GetWeeklyChestRewardLevel()
				if currentWeekBestLevel~=0 then
					t[#t+1] = "\n\n|cff8080cc"
					t[#t+1] = currentWeekBestLevel
					t[#t+1] = "|r |cff00ff00"
					t[#t+1] = format(string.gsub(MYTHIC_PLUS_CHEST_ITEM_LEVEL_REWARD, "\n",""),weeklyRewardLevel)
					t[#t+1] = "|r"
				end
				t[#t+1] = "\n\n"
				t[#t+1] = HONORABLE_KILLS
				t[#t+1] = ": |cff8080cc"
				t[#t+1] = GetPVPLifetimeStats()
				t[#t+1] = "|r\n"
				t[#t+1] = LFG_LIST_HONOR_LEVEL_INSTR_SHORT
				local currentHonor = UnitHonor("player")
				local maxHonor = UnitHonorMax("player")
				local honorlevel =UnitHonorLevel("player")
				t[#t+1] = ": |cff8080cc"
				t[#t+1] = honorlevel
				t[#t+1] = "|r |cffff00ff("
				t[#t+1] = format(PVP_PRESTIGE_RANK_UP_NEXT_MAX_LEVEL_REWARD,C_PvP.GetNextHonorLevelForReward(honorlevel))
				t[#t+1] = ")|r\n"
				t[#t+1] = HONOR
				t[#t+1] = ": |cff8080cc"
				t[#t+1] = currentHonor
				t[#t+1] = "/"
				t[#t+1] = maxHonor
				t[#t+1] = format("|r |cffff00ff(%.2f%%)|r\n",currentHonor/maxHonor*100)
				local rewardAchieved, lastWeekRewardAchieved, lastWeekRewardClaimed, pvpTierMaxFromWins = C_PvP.GetWeeklyChestInfo()
				if lastWeekRewardAchieved and not lastWeekRewardClaimed then
					t[#t+1] = "\n|cff00ff00"
					t[#t+1] = RATED_PVP_WEEKLY_CHEST_TOOLTIP_COLLECT
					t[#t+1] = "|r"
					if pvpTierMaxFromWins ~= -1 then
						local activityItemLevel, weeklyItemLevel = C_PvP.GetRewardItemLevelsByTierEnum(pvpTierMaxFromWins)
						t[#t+1] = "\n"
						t[#t+1] = weeklyItemLevel
					end
				end
				if rewardAchieved then
					t[#t+1] = "\n|cff00ff00"
					t[#t+1] = RATED_PVP_WEEKLY_CHEST_EARNED
					t[#t+1] = "|r"
				end
				return table.concat(t)
			end,
			fontSize = "large",
			type = "description"
		},
	}
})

LFG_OPT.Register("mplus_callbacks",nil,function(profile,a,s)
	s.minimum_item_level = GetAverageItemLevel()-2
	s.role = true
	s.diverse = true
end)

if GetCurrentRegion() == 5 then	-- add +8 ilvl for Chinese Region since they do not have Raider.IO
	LFG_OPT.Register("mplus_callbacks",nil,function(profile,a,s)
		s.fake_minimum_item_level = GetAverageItemLevel()+8
	end)
end