local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Q = LibStub("AceAddon-3.0"):NewAddon("LookingForGroup_Q","AceEvent-3.0")

function LookingForGroup_Q:OnInitialize()
	local db = LookingForGroup.db
	local defaults = LookingForGroup.db.defaults
	defaults.profile.q = {[42170]=true,[42233]=true,[42234]=true,[42420]=true,[42421]=true,[42422]=true,[43179]=true,[43943]=true,[45379]=true,[48338]=true,[48358]=true,[48360]=true,[48374]=true,[48592]=true,[48639]=true,[48641]=true,[48642]=true,[50562]=true,
	[54978] = true, -- Against Overwhelming Odds
	[51017] = true, -- Supplies Needed: Monelite Ore
	[54618] = true, -- Paragon of the 7th Legion
	[48973] = true, -- Paragon of Argussian Reach
	[48974] = true, -- Paragon of the Army of the Light
	[54453] = true, -- Paragon Order of Embers
	[54456] = true, -- Paragon Order of Embers
-- bfa assaults
    [51982] = true, -- Storm's Rage
    [53701] = true, -- A Drust Cause
    [53711] = true, -- A Sound Defense
    [53883] = true, -- Shores of Zuldazar
    [53885] = true, -- Isolated Victory
    [53939] = true, -- Breaching Boralus
    [54132] = true, -- Horde of Heroes
	[53414] = true,
	[53416] = true, -- Warfront: The Battle for Stromgarde
	[53992] = true, 
	[53995] = true, -- Warfront: The Battle for Darkshore
	[56119] = true, -- The Waveblade Ankoan
	[56120] = true, -- The Unshackled
	[56129] = true, -- Heroic: The Battle for Stromgarde
	[56206] = true, -- Heroic: The Battle for Stromgarde
	[56136] = true, -- Heroic Warfront: The Battle for Stromgarde
	[56137] = true, -- Heroic Warfront: The Battle for Stromgarde
	[56128] = true, -- Drowning the Horde
	[56129] = true, -- Heroic: The Battle for Stromgarde
	[56433] = true, -- Drowning the Alliance
	[56003] = true, -- Runelocked Chest
	}
	db:RegisterDefaults(defaults)
end

function LookingForGroup_Q:OnEnable()
	LookingForGroup_Q:RegisterEvent("QUEST_ACCEPTED")
	LookingForGroup_Q:RegisterMessage("LFG_SECURE_QUEST_ACCEPTED")
end

local function cofunc(quest_id,secure,gp)
	local questName = C_TaskQuest.GetQuestInfoByQuestID(quest_id)
	if questName == nil then
		if secure <= 0 and LookingForGroup.db.profile.auto_no_info_quest then
			return
		end
		local GetQuestLogTitle = GetQuestLogTitle
		for i=1,GetNumQuestLogEntries() do
			local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(i)
			if questID == quest_id then
				if secure <= 0 and frequency == LE_QUEST_FREQUENCY_WEEKLY then
					return
				end
				questName = title
				break
			end
		end
	end
	if questName == nil then return end
	local activityID = C_LFGList.GetActivityIDForQuestID(quest_id)
	if activityID  == nil then
		local activities = C_LFGList.GetAvailableActivities()
		local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
		for i=1,#activities do
			if C_LFGList_GetActivityInfoExpensive(activities[i]) then
				activityID = activities[i]
				break
			end
		end
		if activityID == nil then
			activityID = 280 --use wandering isle activity since no one will use it unless you are a level capped neutral pandaren like me
		end
	end
	local fullName, shortName, categoryID, groupID, iLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activityID)
	local confirm_keyword = not C_LFGList.CanCreateQuestGroup(quest_id) and tostring(quest_id) or nil
	local function create()
		local ilvl = GetAverageItemLevel() - 100
		if ilvl < iLevel then
			ilvl = iLevel
		end
		if confirm_keyword then
			if math.floor(ilvl) == ilvl then
				ilvl = ilvl + 0.125
			end
			C_LFGList.CreateListing(activityID,ilvl,0,true,false)
		else
			C_LFGList.ClearCreationTextFields()
			C_LFGList.CreateListing(activityID,ilvl,0,true,false,quest_id)
		end
	end
	local function search()
		if not confirm_keyword then
			C_LFGList.SetSearchToQuestID(quest_id)
		end
		return LookingForGroup.Search(categoryID,filters,0)
	end
	LookingForGroup_Q:RegisterEvent("QUEST_REMOVED",function(info,id)
		if quest_id == id and LookingForGroup.popup and LookingForGroup.popup:IsShown() then
			LookingForGroup.popup:Hide()
		end
	end)
	local raid = select(4,GetQuestTagInfo(quest_id)) == 3
	if not gp and IsInGroup() then
		if 0 < secure and UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME) then
			gp = true
		else
			return
		end
	end
	local current = coroutine.running()
	if LookingForGroup.accepted(questName,search,create,secure,raid,confirm_keyword,"<LFG>Q",gp) then
		return
	end
	LookingForGroup_Q:RegisterEvent("QUEST_ACCEPTED",function(event,index,id)
		if IsInGroup() then
			if quest_id == id then
				LookingForGroup.resume(current,3)
			end
		else
			LookingForGroup.resume(current)
			LookingForGroup_Q:RegisterEvent("QUEST_ACCEPTED")
		end
	end)
	LookingForGroup_Q:RegisterEvent("QUEST_TURNED_IN",function(info,id)
		if quest_id == id then
			LookingForGroup.resume(current,0,gp)
		end
	end)
	LookingForGroup_Q:RegisterEvent("QUEST_REMOVED",function(info,id)
		if quest_id == id then
			LookingForGroup.resume(current,1,gp)
		end
	end)
	LookingForGroup.autoloop(questName,create,raid,confirm_keyword,"<LFG>Q",function()
		local distance = C_TaskQuest.GetDistanceSqToQuest(quest_id)
		return not distance or distance < 40000
	end)
	LookingForGroup_Q:UnregisterEvent("QUEST_TURNED_IN")
	LookingForGroup_Q:UnregisterEvent("QUEST_REMOVED")
	LookingForGroup_Q:RegisterEvent("QUEST_ACCEPTED")
end

local function is_group_q(id,ignore)
	if id == nil or IsRestrictedAccount() then
		return
	end
	local profile = LookingForGroup.db.profile
	if 45068 <= id and id < 45073 then	-- Barrels o' Fun
		LookingForGroup_Q:SendMessage("LFG_Barrels_o_Fun",id)
		return
	end
	if ignore then
		return true
	end
	if GetQuestLogRewardMoney(id) == 23400 then
		return
	end
	if (46794 <= id and id <= 46802) -- legion paragon quests
		or (50598<=id and id <= 50606) -- bfa bounty quests
		or (51021<=id and id <= 51051) or (52375<=id and id <= 52388) -- bfa supplies needed
		or (54134<=id and id <= 54138) --bfa assaults
		or (54626<=id and id <= 54632) -- bfa paragon quests
		or (56006<=id and id <= 56022 and id~= 56012 and id~=56017) -- 8.2 Runelocked Chest
		or (56023<=id and id <=56025) -- 8.2 Laylocked Chest
		then return
	end
	if profile.q[id] then
		return
	end
	local tagID, tagName, wq_type, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(id)
	if tagID == 62 or tagID == 81 or tagID == 83 or tagID == 117 or tagID == 124 or tagID == 125 then
		return
	end
	if profile.auto_wq_only and wq_type == nil then
		return
	end
	if profile.auto_ccqg and not C_LFGList.CanCreateQuestGroup(id) then
		return
	end
	if wq_type == LE_QUEST_TAG_TYPE_PET_BATTLE or wq_type == LE_QUEST_TAG_TYPE_PROFESSION or wq_type == LE_QUEST_TAG_TYPE_DUNGEON or wq_type == LE_QUEST_TAG_TYPE_RAID then
		return
	end
	if math.floor(id/100) == 413 then
		return
	end
	local quest_faction = select(2,C_TaskQuest.GetQuestInfoByQuestID(id))
	if quest_faction == 1090 or quest_faction == 2163 then
		return
	end
	local num_wq_watches = GetNumWorldQuestWatches()
	if num_wq_watches ~= 0 then
		local i = 1
		local GetWorldQuestWatchInfo = GetWorldQuestWatchInfo
		while i<=num_wq_watches do
			if GetWorldQuestWatchInfo(i) == id then
				break
			end
			i = i + 1
		end
		if num_wq_watches < i then
			return
		end
	end
	return true
end

function LookingForGroup_Q:QUEST_ACCEPTED(_,index,quest_id)
	local load_time = LookingForGroup.load_time
	if load_time == nil or GetTime() < load_time + 5 then
		return
	end
	if is_group_q(quest_id) then
		coroutine.wrap(cofunc)(quest_id,0)
	end
end

function LookingForGroup_Q:LFG_SECURE_QUEST_ACCEPTED(_,quest_id,group)
	if is_group_q(quest_id,true) then
		coroutine.wrap(cofunc)(quest_id,1,group)
	end
end
