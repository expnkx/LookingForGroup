local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

LookingForGroup_Options.RegisterSimpleFilterExpensive("cr",function(info,profile,func)
	if func(info.leaderName:lower()) then
		return 1
	end	
end,function(profile)
	local s = profile.a.cr_server
	if s then
		if GetNormalizedRealmName():lower() == s then
			return function(leader)
				return not leader:find(s) and leader:find("-")
			end
		else
			return function(leader)
				return not leader:find(s)
			end
		end
	end
end)
LookingForGroup_Options.RegisterSimpleFilterExpensive("cr",nop,function(profile) return not profile.a.cr_server end)

local cr = LookingForGroup_Options.option_table.args.cr.args
local fd = LookingForGroup_Options.option_table.args.find.args

local party_tb

local function convert_from_std(t)
	local cr_values = {}
	local player_server = GetNormalizedRealmName()
	local smatch = string.match
	local C_LFGList_GetSearchResultInfo = C_LFGList.GetSearchResultInfo
	for i=1,#t do
		local info = C_LFGList_GetSearchResultInfo(t[i])
		local realm = smatch(info.leaderName,"-(.*)$") or player_server
		local t = cr_values[realm]
		if t then
			t[#t+1] = info.searchResultID
		else
			cr_values[realm] = {info.searchResultID,realm=realm}
		end
	end
	wipe(t)
	for k,v in pairs(cr_values) do
		t[#t+1] = v
	end
	table.sort(t,function(a1,a2)
		return a1.realm < a2.realm
	end)
	return t
end

local current_activity

LookingForGroup_Options.RegisterSearchPattern("cr",function(profile,a,category)
	if a.current_map then
		C_LFGList.ClearSearchTextFields()
	elseif current_activity then
		C_LFGList.SetSearchToActivity(current_activity)
	end
end)

cr.search =
{
	name = SEARCH,
	type = "execute",
	order = 5,
	func = function()
		local profile = LookingForGroup_Options.db.profile
		local activities = C_LFGList.GetAvailableActivities()
		local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
		current_activity = nil
		for i=1,#activities do
			if C_LFGList_GetActivityInfoExpensive(activities[i]) then
				current_activity = activities[i]
				break
			end
		end
		local kw
		local category
		local filters = 0
		if profile.a.current_map then
			category = profile.a.category
			if category == nil then
				return
			end
			local recommended = profile.recommended
			if recommended then
				filters = LE_LFG_LIST_FILTER_NOT_RECOMMENDED
			elseif recommended == nil then
				filters = LE_LFG_LIST_FILTER_RECOMMENDED
			end
		else
			if not current_activity then
				LookingForGroup_Options.expected(SPELL_FAILED_INCORRECT_AREA)
				return
			end
			local activityName, shortName, categoryID, groupID, itemLevel, filters = C_LFGList.GetActivityInfo(current_activity)
			kw = current_activity
			filters = ft
			category=categoryID
		end
		coroutine.wrap(function()
			LookingForGroup_Options.Search("LFG_OPT_CRE",
			{"spam","cr"},category,filters,0,nil,{"cr"},convert_from_std,function(cre_tb)
					return cre_tb
			end)
		end)()
	end
}

cr.category = {}
for k,v in pairs(fd.category) do
	cr.category[k] = v
end
cr.category.order = 6


cr.recommanded = {}
for k,v in pairs(fd.recommanded) do
	cr.recommanded[k] = v
end
cr.recommanded.order = 7

cr.signup = {}
for k,v in pairs(fd.f.args.opt.args.signup) do
	cr.signup[k] = v
end
cr.signup.order = 8

cr.server =
{
	order = 9,
	name = FRIENDS_LIST_REALM,
	type = "input",
	set = function(_,val)
		if val:len() == 0 then
			LookingForGroup_Options.db.profile.a.cr_server = nil
		else
			LookingForGroup_Options.db.profile.a.cr_server = val:lower()
		end
	end,
	get = function()
		return LookingForGroup_Options.db.profile.a.cr_server
	end
}

cr.map=
{
	order = 9,
	name = GetRealZoneText,
	type = "toggle",
	set = function(_,val)
		if val then
			LookingForGroup_Options.db.profile.a.current_map = nil
		else
			LookingForGroup_Options.db.profile.a.current_map = true
		end
	end,
	get = function()
		return not LookingForGroup_Options.db.profile.a.current_map
	end
}

local AceGUI = LibStub("AceGUI-3.0")

AceGUI:RegisterWidgetType("LFG_OPT_CRE",function()
	local control = AceGUI:Create("InlineGroup")
	control.type = "LFG_OPT_CRE"
	function control.OnAcquire()
		control:SetLayout("Flow")
		control.width = "fill"
		control.SetList = function(self,values)
			party_tb=values
			self.values = values
		end
		control.SetLabel = function(self,value)
			self:SetTitle(value)
		end
		control.SetDisabled = function(self,disabled)
			self.disabled = disabled
		end
		control.SetMultiselect = nop
		local select_sup = LookingForGroup_Options.select_sup
		local concat_tb = {}
		control.SetItemValue = function(self,key)
			local val = self.values[key]
			if val then
				local check = AceGUI:Create("CheckBox")
				check:SetUserData("key", key)
				check:SetUserData("val", val)
				check:SetValue(select_sup[key])
				check:SetCallback("OnValueChanged",function(self,...)
					local user = self:GetUserDataTable()
					if select_sup[key] then
						select_sup[key] = nil
					else
						select_sup[key] = true
					end
					check:SetValue(select_sup[key])
				end)
				check:SetCallback("OnLeave", function(self,...)
					GameTooltip:Hide()
				end)
				local n = 0
				if current_activity then
					wipe(concat_tb)
					local C_LFGList_GetSearchResultInfo = C_LFGList.GetSearchResultInfo
					for i=1,#val do
						local info = C_LFGList_GetSearchResultInfo(val[i])
						if info.activityID == current_activity then
							if #concat_tb ~= 0 then
								concat_tb[#concat_tb+1]= "\n"
							end
							concat_tb[#concat_tb+1]= "|cff8080cc"
							concat_tb[#concat_tb+1]=info.name
							concat_tb[#concat_tb+1]= "|r  |cc00ff000"
							concat_tb[#concat_tb+1]=info.leaderName
							concat_tb[#concat_tb+1]= "|r"
							if info.autoAccept then
								concat_tb[#concat_tb+1]= "  "
								concat_tb[#concat_tb+1]= LFG_LIST_AUTO_ACCEPT
							end
							n = n + 1
						end
					end
					if #concat_tb~=0 then
						check:SetDescription(table.concat(concat_tb))
					end
				end
				wipe(concat_tb)
				concat_tb[#concat_tb+1]=val.realm
				local lfgscoresbrief = LookingForGroup_Options.lfgscoresbrief
				if lfgscoresbrief then
					local fake_leader_name = "a-"..val.realm
					for i=1,#lfgscoresbrief do
						concat_tb[#concat_tb + 1] = lfgscoresbrief[i](fake_leader_name,0)
					end
				end
				concat_tb[#concat_tb+1]='  '
				concat_tb[#concat_tb+1]="|cff8080cc("
				concat_tb[#concat_tb+1]=#val
				concat_tb[#concat_tb+1]=')|r'
				if n~=0 then
					concat_tb[#concat_tb+1]="|cff00ff00("
					concat_tb[#concat_tb+1]=n
					concat_tb[#concat_tb+1]=')|r'
				end
				check:SetLabel(table.concat(concat_tb))
				check:SetCallback("OnEnter", function(self,...)
					GameTooltip:SetOwner(self.frame,"ANCHOR_TOPRIGHT")
					GameTooltip:ClearLines()
					GameTooltip:AddLine(val.realm)
					local C_LFGList_GetSearchResultInfo = C_LFGList.GetSearchResultInfo
					local C_LFGList_GetActivityInfo = C_LFGList.GetActivityInfo
					for i=1,#val do
						local info = C_LFGList_GetSearchResultInfo(val[i])
						if info and not info.isDelisted then
							local activityName, shortName = C_LFGList_GetActivityInfo(info.activityID)
							wipe(concat_tb)
							concat_tb[1]="|cff00ff00"
							concat_tb[2]=info.numMembers
							concat_tb[3]="|r "
							concat_tb[4]=info.leaderName
							GameTooltip:AddDoubleLine(table.concat(concat_tb),activityName or shortName,0.5,0.5,0.8,true)
						end
					end
					GameTooltip:Show()
				end)
				check.width = "fill"
				self:AddChild(check)
			end
		end
	end
	control.OnRelease = function()
		LookingForGroup_Options:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
	end
	return AceGUI:RegisterAsContainer(control)
end,1)
