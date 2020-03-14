local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function issubstr(s,substr)
	local sbyte = string.byte
	local i = 1
	local slen = s:len()
	local substr_len = substr:len()
	local j = 1
	while i <= slen and j <= substr_len do
		if sbyte(s,i) == sbyte(substr,j) then
			j = j + 1
		else
			j = 1
		end
		i = i + 1
	end
	if substr_len < j then
		return true
	end
end

LookingForGroup_Options.RegisterSearchPattern("find",function(profile,a,category)
	if LFGListFrame.SearchPanel.SearchBox:GetText():len() == 0 and a.activity then
		C_LFGList.SetSearchToActivity(a.activity)
	end
end)


LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,class)
	local class_tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
	if class_tb and class_tb[class] < 2 then
		return 1
	end
end,function(profile)
	if profile.a.class then
		return select(2,UnitClass("player"))
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,armor)
	local class_tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
	local atleast = info.numMembers * 0.4
	if atleast < 2 then
		atleast = 2
	end
	local total = 0
	for k,v in pairs(armor) do
		total = total + class_tb[k]
		if atleast <= total then
			return 0
		end
	end
	return 1
end,function(profile)
	if profile.a.armor then
		local classlocalized,class,id = UnitClass("player")
		local leather = {DEMONHUNTER=true,DRUID=true,MONK=true,ROGUE=true}
		if leather[class] then
			return leather
		end
		local cloth = {MAGE=true,PRIEST=true,WARLOCK=true}
		if cloth[class] then
			return cloth
		end
		local plate = {DEATHKNIGHT=true,PALADIN=true,WARRIOR=true}
		if plate[class] then
			return plate
		end
		local mail = {HUNTER=true,SHAMAN=true}
		if mail[class] then
			return mail
		end
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,ilvl)
	if info.requiredItemLevel < ilvl then
		return 1
	end
end,function(profile)
	return profile.a.ilvl
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info)
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(info.activityID)
	if info.numMembers * 3 < maxPlayers * 2 then
		return 1
	end
end,function(profile)
	return profile.a.complete
end)


LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,last_time)
	if GetTime() < info.age + last_time then
		return 1
	end
end,function(profile,first)
	local a = profile.a
	if first then
		if a.current_time then
			a.last_time = a.current_time
		end
		a.current_time = GetTime()
	end
	if a.newg then
		return a.last_time
	end
end)

LookingForGroup_Options.RegisterSimpleApplicantFilter("s",function(id,pos,profile,func)
	local name = C_LFGList.GetApplicantMemberInfo(id,pos)
	return func(name) and 1
end,function(profile)
	if LookingForGroup.db.profile.mode_rf ~= nil then
		return LookingForGroup.realm_filter
	end
end)

LookingForGroup_Options.RegisterSimpleApplicantFilter("s",function(id,pos,profile,fakeilvl)
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship = C_LFGList.GetApplicantMemberInfo(id,pos)
	if itemLevel < fakeilvl then
		return 1
	end
end,function(profile)
	return profile.s.fake_minimum_item_level
end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	local numMembers = info.numMembers
	if numMembers < 2 then
		local fullName, shortName, categoryID = C_LFGList.GetActivityInfo(info.activityID)
		local age = info.age
		if numMembers == 1 then
			if 300 < age then
				return 2
			else
				if categoryID == 3 or categoryID == 9 then
					if 120 < age then
						return 2
					end
				end
			end
		elseif numMembers == 2 then
			if categoryID == 3 or categoryID == 9 then
				if 300 < age then
					return 2
				end
			end
		end
	end
end,function(profile)
	return not profile.spam_filter_solo
end)

LookingForGroup_Options.RegisterSimpleFilterExpensive("spam",function(info,profile,sf_kw)
	local leaderName = info.leaderName:lower()
	for i=1,#sf_kw do
		if issubstr(leaderName,sf_kw[i]) then
			return 8
		end
	end
end,function()
	local lfg_profile = LookingForGroup.db.profile
	return not lfg_profile.spam_filter_player_name and lfg_profile.spam_filter_keywords
end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info,profile)
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(info.activityID)
	local iLvl = info.requiredItemLevel
	if iLvl~=0 and iLvl < itemLevel then
		return 8
	end
end,function(profile)
	return not profile.spam_filter_ilvl
end)

LookingForGroup_Options.RegisterSimpleFilterExpensive("spam",function()
	return 32
end,
function()
	return LookingForGroup_Options.spam_filter_ignore_all and LFGListFrame.SearchPanel.SearchBox:GetText():len()~=0
end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	local fullName, shortName, categoryID, groupID = C_LFGList.GetActivityInfo(info.activityID)
	if groupID == 136 then
		return 8
	end
end,function(profile)
	return not profile.spam_filter_activity and profile.a.group ~= 136
end)


LookingForGroup_Options.RegisterSimpleFilter("spam",function(info,profile,length)
	local approximate_length= LookingForGroup_Options.approximate_length
	if length < approximate_length(info.name) or length < approximate_length(info.comment) or length < approximate_length(info.voiceChat) then
		return 8
	end
end,function(profile)
	local maxlen =  LookingForGroup.db.profile.spam_filter_maxlength
	if maxlen then
		if GetCurrentRegion()==5 then
			return maxlen/3
		end
		return maxlen
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	local rse = C_LFGList.GetSearchResultEncounterInfo(info.searchResultID)
	local age = info.age
	if rse then
		if 36000 < age then
			return 8
		end
	elseif 1200 < age then
		if 10800 < age then
			return 8
		end
		return 2
	end
end,function(profile) return not profile.spam_filter_ages end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	if info == nil or info.isDelisted then
		return 1
	end
	local _, appStatus = C_LFGList.GetApplicationInfo(info.searchResultID)
	if appStatus ~= "none" then
		return 1
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info,profile,temp)
	local id, numMembers = info.searchResultID,info.numMembers
	local C_LFGList_GetSearchResultMemberInfo = C_LFGList.GetSearchResultMemberInfo
	wipe(temp)
	for i=1,numMembers do
		local role, class, class_localized = C_LFGList_GetSearchResultMemberInfo(id,i)
		if class then
			local t = (temp[class] or 0)+1
			temp[class] = t
		end
	end
	local num_classes = GetNumClasses()
	local prop = numMembers/num_classes
--[[	if prop < 5 then
		prop = 5
	elseif 18000 < info.age then
		return 8
	end]]
	local sum = 0 
	for k,v in pairs(temp) do
		sum = sum + v - prop
	end
	if 10 < sum or (1 < sum and 18000 < info.age) then
		return 8
	end
end,function(profile)
	return not profile.spam_filter_dk and {} or nil
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info)
	if info.numMembers == 4 and 2400 < info.age then
		local fullName, shortName, categoryID = C_LFGList.GetActivityInfo(info.activityID)
		if categoryID == 2 then
			local tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
			if tb.TANK == 1 and tb.HEALER == 1 then
				return 8
			end
		end
	end
end,function(profile)
	return not profile.spam_filter_fast
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile)
	local activityID = info.activityID
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(activityID)
	local fsname = fullName or shortName
	local a = profile.a
	local val = a.activities_blacklist and 1 or 0
	local reverse_val = val == 1 and 0 or 1
	if a.activity then
		if a.activity == activityID then
			return val
		end
	elseif a.group then
		if a.group == groupID then
			return val
		end
	end
	local activities = a.activities
	if activities and next(activities) then
		for i=1,#activities do
			local ctv = activities[i]
			if issubstr(fsname,ctv) then
				return val
			end
		end
	elseif a.activity == nil and a.group == nil then
		return val
	end
	return reverse_val
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,membercounts)
	local this_group = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(info.activityID)
	local GetClassInfo = GetClassInfo
	local numclasses = GetNumClasses()
	if maxPlayers < numclasses then
		for i=1,numclasses do
			local id,class = GetClassInfo(i)
			if 1 < this_group[class] then
				return 1
			end
		end
	end
	for i=1,numclasses do
		local id,class = GetClassInfo(i)
		if this_group[class] == 0 and membercounts[class] ~= 0 then
			return
		end
	end
	return 1
end,function(profile)
	if profile.a.diverse then
		local membercounts = GetGroupMemberCounts()
		if not IsInGroup() then
			local classlocalized,class,id = UnitClass("player")
			membercounts[class] = 1
		end
		return membercounts
	end
end)

local label = UIParent:CreateFontString(nil, "BACKGROUND","GameFontHighlightSmall")
label:Hide()
label:SetFont("Fonts\\FRIZQT__.TTF",1)

function LookingForGroup_Options.approximate_length(encrypt_string)
	if encrypt_string:len() == 0 then
		return 0
	end
	label:SetText("O")
	local o_size = label:GetStringWidth()
	label:SetText(encrypt_string)
	local string_height = label:GetStringHeight()
	if string_height == 0 then
		return math.floor(label:GetStringWidth()/o_size)
	end
	return math.floor(string_height*label:GetStringWidth()/o_size)
end

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	if 10000 < info.age and 0 < info.comment:len() and info.name == info.comment then
		return 8
	end
end,function(profile)
	return profile.spam_filter_equal
end)

LookingForGroup_Options.RegisterFilter("spam",function(infos,bts,first,profile)
	if not profile.spam_filter_equal then
		return
	end
	local hash = {}
	local categoryID
	for i=1,#infos do
		local info = infos[i]
		repeat
		if not info then
			break
		end
		if not categoryID then
			categoryID = select(3,C_LFGList.GetActivityInfo(info.activityID))
			if categoryID == 1 then
				return
			end
		end
		if info.questID then
			break
		end
		local name,comment = info.name,info.comment
		if comment:len() == 0 and LookingForGroup_Options.approximate_length(name) < 5 then
			break
		end
		local v = name..comment
		local t = hash[v]
		if t == nil then
			t = {}
			hash[v] = t
		end
		t[#t+1] = i
		until true
	end
	local limits = 2
	local slen = string.len
	local bor = bit.bor
	for k,v in pairs(hash) do
		local lm = limits
		if slen(k) == 8 then
			lm = lm * 4
		end
		if lm < #v then
			for i=1,#v do
				local e=v[i]
				bts[e] = bor(bts[e],8)
			end
		end
	end
end)



LookingForGroup_Options.RegisterSimpleFilterExpensive("spam",function(info,profile,func)
	return func(info.leaderName) and 1
end,function()
	if LookingForGroup.db.profile.mode_rf ~= nil then
		return LookingForGroup.realm_filter
	end
end)
