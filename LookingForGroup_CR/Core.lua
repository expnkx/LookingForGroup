local AceAddon=LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_CR = AceAddon:NewAddon("LookingForGroup_CR","AceEvent-3.0")

local function print_result(tb,state)
	local tb2 = {}
	local num = 0
	for k,v in pairs(tb) do
		tb2[#tb2+1]={k,v}
		num = num + v
	end
	table.sort(tb2,function(a,b) return b[2] < a[2]; end)
	if num == 0 then
		LookingForGroup:Print(UNKNOWN)
	else
		local n = #tb2
		if n == 1 then
			LookingForGroup:Print(tb2[1][1])
			return
		end
		if 3 < n then
			LookingForGroup:Print("CRZ",n)
			if not state then
				n = 2
			end
		end
		local string_format = string.format
		for i = 1, n do
			local ti = tb2[i]
			LookingForGroup:Print(i,ti[1],string_format("%.0f%%",100 * ti[2]/num))
			if i < n and tb2[i+1][2]*2 < ti[2] then
				break
			end
		end
	end
end

local function scan(state)
	local current = coroutine.running()
	local function event_callback(...)
		LookingForGroup.resume(current,...)
	end
	LookingForGroup_CR:SendMessage("LFG_CR_SCAN_START")
	FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
	C_FriendList.SetWhoToUi(0)
	local string_match = string.match
	local player_realm = GetRealmName()
	local log_tb = {}
	local function add_to_log_tb(uid,name)
		if not string.find(uid,"Player") or UnitGUID("player") == uid then
			return
		end
		local realm = string_match(name,"-(.*)$")
		if realm == nil then
			realm = player_realm
		end
		if log_tb[realm] == nil then
			log_tb[realm] = 1
		else
			log_tb[realm] = log_tb[realm] + 1
		end
	end
	LookingForGroup_CR:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",function()
		local timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName = CombatLogGetCurrentEventInfo()
		add_to_log_tb(sourceGUID,sourceName)
		add_to_log_tb(destGUID,destName)
		LookingForGroup.resume(current,2)
	end)
	SendWho(table.concat{"z-\"",GetRealZoneText(),"\""})
	LookingForGroup_CR:RegisterEvent("WHO_LIST_UPDATE",function()
		LookingForGroup.resume(current,1)
	end)
	local timer = C_Timer.NewTimer(20,function()
		LookingForGroup.resume(current,0)
	end)

	local i = 1
	while i<31 do
		local yd = coroutine.yield()
		if yd == 1 then
			LookingForGroup_CR:UnregisterEvent("WHO_LIST_UPDATE")
			local tb = {}
			local all_player_realm = true
			for i = 1,GetNumWhoResults() do
				local name = GetWhoInfo(i)
				local realm = string_match(name,"-(.*)$")
				if realm == nil then
					realm = player_realm
				else
					all_player_realm = false
				end
				local tbs = tb[realm]
				if tbs == nil then
					tb[realm] = 1
				else
					tb[realm] = tbs + 1
				end
			end
			if not all_player_realm then
				print_result(tb,state)
				break
			end
		elseif yd == 2 then
			i=i+1
		elseif yd == 0 then
			i=31
		else
			break
		end
	end
	if 30 < i then
		print_result(log_tb,state)
	end
	LookingForGroup_CR:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	timer:Cancel()
	LookingForGroup_CR:UnregisterEvent("WHO_LIST_UPDATE")
	LookingForGroup_CR:RegisterMessage("LFG_CR_SCAN_START",event_callback)
	local timer = C_Timer.NewTimer(5,event_callback)
	local yd = coroutine.yield()
	timer:Cancel()
	LookingForGroup_CR:UnregisterMessage("LFG_CR_SCAN_START")
	if yd == "LFG_CR_SCAN_START" then
		return
	end
	FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
	LookingForGroup_CR:RegisterMessage("LFG_ICON_RIGHT_CLICK")
end

local results_cache

local function hop()
	local activities = C_LFGList.GetAvailableActivities()
	local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
	local activity_id
	for i=1,#activities do
		if C_LFGList_GetActivityInfoExpensive(activities[i]) then
			activity_id = activities[i]
			break
		end
	end
	if activity_id == nil then
		return
	end
	local activityName, activityShortName, categoryID, groupID, iLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activity_id)
	local function search()
		if results_cache and results_cache.activity_id == activity_id then
			local GetSearchResultInfo = C_LFGList.GetSearchResultInfo
			while #results_cache ~= 0 do
				local info = GetSearchResultInfo(results_cache[#results_cache])
				if info and not isDelisted and (info.questID or info.numMembers ~= 5) then
					break
				else
					results_cache[#results_cache]=nil
				end
			end
			if results_cache and #results_cache ~= 0 then
				results_cache.activity_id = activity_id
				return #results_cache,results_cache,true
			end
		end
		C_LFGList.SetSearchToActivity(activity_id)
		local count,results = LookingForGroup.Search(categoryID,filters,0)
		if rare == 1 then
			if results then
				rare_filter(results)
			end
		end
		results_cache = results
		if results_cache then
			results_cache.activity_id = activity_id		
		end
		return count,results_cache
	end
	local current = coroutine.running()
	local function resume()
		LookingForGroup.resume(current,4)
	end
	local activityName,activityShortName = C_LFGList.GetActivityInfo(activity_id)
	local zone_text = activityName or activityShortName
	if LookingForGroup.accepted(zone_text,search,nil,1) then
		LookingForGroup:Print(LFG_LIST_NO_RESULTS_FOUND)
		return
	end
	local show_popup = LookingForGroup.show_popup
	while true do
		if rare~=1 then
			coroutine.wrap(scan)()
		end
		local timer = C_Timer.NewTimer(5,resume)
		LookingForGroup_CR:RegisterEvent("GROUP_LEFT",resume)
		local yd = coroutine.yield()
		LookingForGroup_CR:UnregisterEvent("GROUP_LEFT")
		timer:Cancel()
		if IsInInstance() then return end
		if yd == 4 then
			local tb = {nop}
			if IsInGroup() then
				tb[#tb+1] = PARTY_LEAVE
				tb[#tb+1] = function()
					C_PartyInfo.LeaveParty()
					LookingForGroup.resume(current,5)
				end
			end
			tb[#tb+1]=NEXT
			tb[#tb+1]=function() LookingForGroup.resume(current,6) end
			show_popup(zone_text,tb)
			if coroutine.yield()==6 then
				if IsInInstance() then return end
				if IsInGroup() then
					C_PartyInfo.LeaveParty()
					results_cache = nil
				end
				if LookingForGroup.accepted(zone_text,search,nil,1) then
					LookingForGroup:Print(LFG_LIST_NO_RESULTS_FOUND)
					return
				end
			else
				break
			end
		else
			break
		end
	end
	LookingForGroup.popup:Hide()
end

function LookingForGroup_CR:LFG_ICON_RIGHT_CLICK(message,r)
	if r then
		self:SendMessage("LFG_SECURE_QUEST_ACCEPTED")
		coroutine.wrap(hop)(r)
	else
		local name, t = GetInstanceInfo()
		if t == "none" then
			coroutine.wrap(scan)(true)
		else
			LookingForGroup:Print(INSTANCE)
		end
	end
end

function LookingForGroup_CR:OnInitialize()
	self:RegisterMessage("LFG_ICON_RIGHT_CLICK")
	self.OnInitialize = nil
end