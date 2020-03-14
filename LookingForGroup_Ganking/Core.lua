local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Ganking = AceAddon:NewAddon("LookingForGroup_Ganking","AceEvent-3.0")

function LookingForGroup_Ganking:OnInitialize()
	self:RegisterEvent("ZONE_CHANGED","OnEnable")
	self:RegisterMessage("LFG_ICON_MIDDLE_CLICK","OnEnable")
end

local function cofunc(map,event,player_is_leader)
	local activityID = 17
--[[	local activities = C_LFGList.GetAvailableActivities()
	local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
	for i=1,#activities do
		if C_LFGList_GetActivityInfoExpensive(activities[i]) then
			activityID = activities[i]
			break
		end
	end
	if activityID == nil then
		activityID = 280
	end]]
	local fullName, shortName, categoryID, groupID, iLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activityID)
	local function create()
		local ilvl = GetAverageItemLevel() - 150
		if ilvl < iLevel then
			ilvl = iLevel
		end
		if math.floor(ilvl) == ilvl then
			ilvl = ilvl + 0.1
		end
		C_LFGList.CreateListing(activityID,ilvl,0,true,false)
	end
	local confirm_keyword = "<LFG>Ganking"
	local function search()
		C_LFGList.SetSearchToActivity(activityID)
		return LookingForGroup.Search(categoryID,filters,0)
	end
	local current = coroutine.running()
	local function resume()
		if C_Map.GetBestMapForUnit("player")~= map then
			LookingForGroup.resume(current,0)
		end
	end
	if LookingForGroup.accepted("Ganking",search,create,event == "LFG_ICON_MIDDLE_CLICK" and 1 or 0,true,confirm_keyword,player_is_leader,nil,true) then
		return
	end
	LookingForGroup_Ganking:RegisterEvent("ZONE_CHANGED",resume)
	LookingForGroup.autoloop(name,create,true,confirm_keyword,nil,function()
		return true
	end,true)
	LookingForGroup_Ganking:RegisterEvent("ZONE_CHANGED","OnEnable")
end

function LookingForGroup_Ganking:OnEnable(event)
	if UnitLevel("player") < GetMaxPlayerLevel() then
		return
	end
	local x,y = UnitPosition("player")
	if not x or not y then
		return
	end
	local player_is_leader = LFGListUtil_IsEntryEmpowered() and C_LFGList.HasActiveEntryInfo()
	if IsInGroup() and not player_is_leader then return end
	local map = C_Map.GetBestMapForUnit("player")
	if not map then
		return
	end
	if (C_PvP.IsWarModeDesired() and (event == "LFG_ICON_MIDDLE_CLICK" or 15 < GetNumGroupMembers()) and not IsInInstance()) or
	(map == 47 and UnitFactionGroup("player") == "Horde" and (-10640 < x  and x <-10460) and (-1400 < y  and y <-1050)) or
		(map == 10 and UnitFactionGroup("player") == "Alliance" and (-580 < x  and x <-330) and (-2825 < y  and y <-2460)) then
		coroutine.wrap(cofunc)(map,event,player_is_leader)
	end
end
