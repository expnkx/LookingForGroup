local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local Auto = LookingForGroup:NewModule("Auto","AceEvent-3.0")

local ms = LibStub("AceAddon-3.0"):GetAddon("MeetingStone", true)
if ms then
	local cp = ms:GetModule("CreatePanel", true)
	if cp then
		cp:UnregisterEvent("LFG_LIST_ENTRY_CREATION_FAILED")
		cp.LFG_LIST_ENTRY_CREATION_FAILED = nil
	end
end

local function is_queueing_lfg()
	for i = 1,6 do
		if GetLFGMode(i) then
			return true
		end
	end
	for i=1,GetMaxBattlefieldID() do
		if GetBattlefieldStatus(i) ~= "none" then
			return true
		end
	end
end

function LookingForGroup.accepted(name,search,create,secure,raid,keyword,ty_pe,create_only,composition)
	if C_LFGList.HasActiveEntryInfo() then
		return
	end
	local profile = LookingForGroup.db.profile
	if (secure <= 0 and profile.disable_auto) or is_queueing_lfg() then
		return true
	end
	local delta = profile.hardware and -1 or 0
	local current = coroutine.running()
	local function resume()
		LookingForGroup.resume(current)
	end
	local function resume_1()
		LookingForGroup.resume(current,1)
	end	
	local asag
	if create == nil then
		asag = false
	else
		asag = profile.auto_start_a_group
		if create_only then
			asag = true
		elseif create_only == false then
			asag = nil
		end
	end
	if secure < 0 or profile.auto_find_a_group then
		secure = -1
	elseif 0 == secure then
		secure = delta
	end
	local show_popup=LookingForGroup.show_popup
	local wql = ty_pe and profile.auto_addons_wql or nil
	local function hwe_api(editbox,text,func,clearfunc,button1,strict)
		if not wql and strict then
			clearfunc()
		end
		if editbox and keyword and (wql and (strict and editbox:GetText()==keyword or not editbox:GetText():find(keyword)) or (not strict and editbox:GetText():len()~=1)) then
			clearfunc()
			if wql then
				text=text.."\n"..keyword
			else
				if keyword then
					text=text.."("..keyword..")"
				else
					text=text
				end
				text = text.."\n|cff8080ccPress enter after entering a single character!|r\n|cffff0000Do not enter the id or the title of the quest.|r"
			end
			show_popup(text,{resume},editbox)
			if coroutine.yield() ~= 1 then
				return true
			end
		elseif secure < 0 then
			if keyword then
				text=text.."("..keyword..")"
			else
				text=text
			end
			show_popup(text,{resume,button1,resume_1})
			if coroutine.yield() ~= 1 then
				return true
			end
		end
		secure = delta
		return nil,func()
	end
	local LFGListFrame = LFGListFrame
	local EntryCreation = LFGListFrame.EntryCreation
	local Name = EntryCreation.Name
	Name:SetEnabled(true)
	local SearchPanel = LFGListFrame.SearchPanel
	local SearchBox = SearchPanel.SearchBox
	SearchBox:SetEnabled(true)
	local searchbox_onenterpressed = SearchBoxTemplate_OnTextChanged
	local name_onenterpressed = InputBoxInstructions_OnTextChanged
	local await_search_result
	if wql then
		searchbox_onenterpressed = function(self)
			if self:GetText()==keyword and LookingForGroup.popup:IsShown() then
				LookingForGroup.popup:Hide()
				resume_1()
			end
		end
		name_onenterpressed = function(self)
			if self:GetText():find(keyword) and LookingForGroup.popup:IsShown() then
					LookingForGroup.popup:Hide()
					resume_1()
			end
		end
	else
		await_search_result=function(resultid,leader)
			if leader then
				return resultid
			end
			for timeout=1,10 do
				local info = C_LFGList.GetSearchResultInfo(resultid)
				if not info or info.isDelisted then
					return
				end
				if info.leaderName then
					return resultid
				end
				local current = coroutine.running()
				Auto:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",function(_,resultID)
					if resultid == resultID then
						LookingForGroup.resume(current,true)
					end
				end)
				coroutine.yield()
				Auto:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
			end
		end
		name_onenterpressed = function(self)
			if self:GetText():len()==1 and LookingForGroup.popup:IsShown() then
				LookingForGroup.popup:Hide()
				resume_1()
			end
		end
	end
	if delta < 0 then
		Name:SetScript("OnTextChanged",InputBoxInstructions_OnTextChanged)
		SearchBox:SetScript("OnTextChanged",SearchBoxTemplate_OnTextChanged)
	else
		if wql then
			Name:SetScript("OnTextChanged",InputBoxInstructions_OnTextChanged)
		else
			if composition then
				Name:SetScript("OnTextChanged",InputBoxInstructions_OnTextChanged)
			else
				Name:SetScript("OnTextChanged",function(...)
					name_onenterpressed(...)
					InputBoxInstructions_OnTextChanged(...)
				end)
			end
		end
		SearchBox:SetScript("OnTextChanged",function(...)
			searchbox_onenterpressed(...)
			SearchBoxTemplate_OnTextChanged(...)
		end)
	end
	Name:SetScript("OnEnterPressed",name_onenterpressed)
	SearchBox:SetScript("OnEnterPressed",searchbox_onenterpressed)
	SearchBox:SetScript("OnArrowPressed",nop)
	SearchBox:SetScript("OnTabPressed",nop)
	SearchBox:SetScript("OnEditFocusGained",SearchBoxTemplate_OnEditFocusGained)
	SearchBox:SetScript("OnEditFocusLost",SearchBoxTemplate_OnEditFocusLost)
	SearchBox.clearButton:SetScript("OnClick",C_LFGList.ClearSearchTextFields)
	if not asag then
	local error_code,count,results,iscache = hwe_api(SearchBox,name,search,C_LFGList.ClearSearchTextFields,SEARCH,true)
	if error_code or is_queueing_lfg() then
		return true
	end
	if iscache then
		secure = secure + 1
	end
	if count==0 then
		if not create then
			return true
		end
	else
		local leader,tank,healer = GetLFGRoles()
		C_LFGList.ClearApplicationTextFields()
		local function event_func(...)
			LookingForGroup.resume(current,...)
		end
		local function resume_2()
			LookingForGroup.resume(current,2)
		end
		local function resume_3()
			LookingForGroup.resume(current,3)		
		end
		local Event = LookingForGroup:GetModule("Event")
		local invited = -1
		local invited_tb = {}
		local concat_tb = {}
		local oked = 0
		if not create then
			for i=1,#results do
				local id = results[i]
				local info = C_LFGList.GetSearchResultInfo(id)
				if info and not info.isDelisted then
					if info.autoAccept then
						invited_tb[i]=id
					else
						local iLvl = info.requiredItemLevel
						if math.floor(iLvl) == iLvl then
							concat_tb[i]=id
						end
					end
				end
			end
			wipe(results)
			for i=1,#concat_tb do
				results[#results+1]=concat_tb[i]
			end
			for i=1,#invited_tb do
				results[#results+1]=invited_tb[i]
			end
			wipe(invited_tb)
			wipe(concat_tb)
		end
		local ok_num = 5
		if keyword then
			ok_num=4
		end
		while #results ~= 0 and oked~=5 do
			local id = results[#results]
			local info = C_LFGList.GetSearchResultInfo(id)
			if info and not info.isDelisted and (not create or create and (raid or info.autoAccept or info.numMembers < ok_num)) and info.comment:len()==0 and info.voiceChat:len()==0 and info.age < 3600 then
				local iLvl = info.requiredItemLevel
				if keyword and not wql then
					if math.floor(iLvl) ~= iLvl then
						invited_tb[#invited_tb+1] = await_search_result(id,info.leaderName)
					end
				else
					if secure < 0 then
						wipe(concat_tb)
						concat_tb[#concat_tb+1] = info.name
						concat_tb[#concat_tb+1] = info.numMembers
						concat_tb[#concat_tb+1] = info.leaderName
						local tb = {resume,SIGN_UP,resume_1}
						if #results == 1 then
							if create then
								tb[#tb+1] = START_A_GROUP
								tb[#tb+1] = resume_2
							end
						else
							tb[#tb+1] = tostring(#results)
							tb[#tb+1] = resume_2
						end
						show_popup(table.concat(concat_tb,"\n"),tb)
						local yd,applicationid = coroutine.yield()
						if yd == 1 then
							C_LFGList.ApplyToGroup(id,tank,healer,true)
							local timer = C_Timer.NewTimer(5,resume_3)
							Event:UnregisterEvent("PARTY_INVITE_REQUEST")
							Auto:RegisterEvent("PARTY_INVITE_REQUEST",event_func)
							Auto:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",function(event,applicationid,invited,applied)
								if invited=="invited" and applied == "applied" and applicationid == id then
									LookingForGroup.resume(current,event,applicationid)
								end
							end)
							local yd,applicationid = coroutine.yield()
							Auto:UnregisterAllEvents()
							Event:RegisterEvent("PARTY_INVITE_REQUEST")
							timer:Cancel()
							if yd == 3 then
								if hwe_api(nil,CANCEL_SIGN_UP,function()
									C_LFGList.CancelApplication(id)
								end,nop,ACCEPT) then
									return true
								end
							elseif yd == "PARTY_INVITE_REQUEST" then
								invited = -2
								break
							elseif yd == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
								invited = applicationid
								break
							else
								return true
							end
						elseif yd == 2 then
							if #results == 1 then
								secure = 0
							else
								secure = delta
							end
						end
					else
						C_LFGList.ApplyToGroup(id,tank,healer,true)
						secure = delta
						oked=oked+1
					end
				end
			end
			results[#results] = nil
		end
		if #results ~= 0 or oked~=0 or #invited_tb ~= 0 then
			local lfgoked = 0
			if #invited_tb ~= 0 then
				if keyword then
					if ty_pe then
						ty_pe = ty_pe..keyword
					else
						ty_pe = keyword
					end
				end
				Auto:SendMessage("LFG_CHAT_MSG_SILENT")
				for i=1,#invited_tb do
					local info = C_LFGList.GetSearchResultInfo(invited_tb[i])
					if info and not info.isDelisted then
						SendChatMessage(ty_pe,"WHISPER",nil,info.leaderName)
						lfgoked = lfgoked + 1
					end
				end
			end
			local yd
			if #results ~=0 or oked ~= 0 or lfgoked~=0 then
				local netdown, netup, netlagHome, netlagWorld = GetNetStats()
				local timeout = math.max(netlagWorld*0.004,1)
				if lfgoked == 0 and (not create or hardware) then
					timeout = math.max(timeout,15)
				end
				local timer = C_Timer.NewTimer(timeout,resume_3)
				Event:UnregisterEvent("PARTY_INVITE_REQUEST")
				Auto:RegisterEvent("PARTY_INVITE_REQUEST",event_func)
				if 0 <= delta then
					Event:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
					Auto:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",function(event,applicationid,invited,applied)
						if invited=="invited" and applied == "applied" then
							C_LFGList.AcceptInvite(applicationid)
						end
					end)
				end
				Auto:RegisterEvent("LFG_LIST_JOINED_GROUP",event_func)
				Auto:RegisterEvent("GROUP_JOINED",event_func)
				if invited == -2 then
					AcceptGroup()
				end
				yd = coroutine.yield()
				if yd == 3 then
					local applications = C_LFGList.GetApplications()
					for i = 1,#applications do
						local groupID, status = C_LFGList.GetApplicationInfo(applications[i])
						if status == "applied" and 0 <= delta then
							C_LFGList.CancelApplication(groupID)
						end
					end
				elseif yd == "PARTY_INVITE_REQUEST" then
					AcceptGroup()
					timer:Cancel()
					yd = coroutine.yield()
				end
				timer:Cancel()
			end
			Auto:UnregisterAllEvents()
			Event:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
			Event:RegisterEvent("PARTY_INVITE_REQUEST")
			Auto:SendMessage("LFG_CHAT_MSG_UNSILENT")
			if yd == "GROUP_JOINED" or yd == "LFG_LIST_JOINED_GROUP" then
				if not IsInGroup() then
					Auto:SendMessage("LFG_CHAT_MSG_SILENT")
					Auto:RegisterEvent("GROUP_ROSTER_UPDATE",resume)
					local ticker = C_Timer.NewTicker(0.01,resume)
					repeat
						coroutine.yield()
					until IsInGroup()
					ticker:Cancel()
					Auto:UnregisterAllEvents()
					Auto:SendMessage("LFG_CHAT_MSG_UNSILENT")
				end
				if IsInRaid() then
					local could_do_in_raid = raid
					if C_LFGList.HasActiveEntryInfo() then
						local entryinfo = C_LFGList.GetActiveEntryInfo()
						if entryinfo.autoAccept then
							could_do_in_raid = true
						end
					end
					if could_do_in_raid then
						local UnitClass = UnitClass
						local UnitLevel = UnitLevel
						local select = select
						local is_spam_group
						local require_pause = true
						local UnitHealthMax = UnitHealthMax
						Auto:SendMessage("LFG_CHAT_MSG_SILENT")
						while require_pause do
							require_pause = nil
							for i=1,GetNumGroupMembers() do
								local unit = "raid"..i
								local level  = UnitLevel(unit)
								if level == 0 then
									require_pause = true
									break
								elseif level == 120 and UnitHealthMax(unit) < 25000 or level < 60 and select(3,UnitClass(unit)) == 6 then
									is_spam_group = true
									break
								end
							end
							if require_pause then
								Auto:RegisterEvent("GROUP_ROSTER_UPDATE",resume)
								local timer = C_Timer.NewTimer(0.01,resume)
								coroutine.yield()
								timer:Cancel()
								Auto:UnregisterEvent("GROUP_ROSTER_UPDATE")
							end
						end
						Auto:SendMessage("LFG_CHAT_MSG_UNSILENT")
						if not is_spam_group then
							return
						end
					end
					C_PartyInfo.LeaveParty()
				else
					return
				end
			end
		end
	end
	end
	if asag~=false then
		if 0 <= delta then
			local pause = {}
			local applications = C_LFGList.GetApplications()
			for i = 1,#applications do
				local groupID, status = C_LFGList.GetApplicationInfo(applications[i])
				if status == "applied" then
					C_LFGList.CancelApplication(groupID)
					pause[groupID] = true
				end
			end
			if next(pause) then
				local timer = C_Timer.NewTimer(3,function()
					LookingForGroup.resume(current)
				end)
				Auto:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",function(event,applicationid,invited,applied)
					if invited~="applied" then
						pause[applicationid] = nil
						if next(pause) == nil then
							LookingForGroup.resume(current)
						end
					end
				end)
				coroutine.yield()
				timer:Cancel()
				Auto:UnregisterAllEvents()
			end
		end
		return hwe_api(Name,name,create,C_LFGList.ClearCreationTextFields,START_A_GROUP)
	end
end

function LookingForGroup.autoloop(name,create,raid,keyword,ty_pe,in_range,composition)
	Auto:SendMessage("LFG_AUTO_MAIN_LOOP",keyword)
	local current = coroutine.running()
	local profile = LookingForGroup.db.profile
	local function event_func(...)
		LookingForGroup.resume(current,...)
	end
	Auto:UnregisterEvent("GROUP_ROSTER_UPDATE")
	Auto:RegisterEvent("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS",event_func)
	local ticker
	local function initialize_kicker()
		if ticker then
			ticker:Cancel()
		end
		if profile.auto_kick then
			ticker = C_Timer.NewTicker(1,function()
				event_func(13)
			end)
		end
	end
	initialize_kicker()
	Auto:RegisterEvent("GROUP_LEFT",event_func)
	local Event = LookingForGroup:GetModule("Event")
	Event:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
	if not LookingForGroup.disable_pve_frame then
		LFGListFrame:UnregisterAllEvents()
		LFGListFrame:Hide()
		GroupFinderFrameGroupButton4:Hide()
	end
	local player_list
	local original_tp = ty_pe
	local invited_tb = {}
	local has_set_friends
	if not profile.auto_addons_wqt and in_range then
		Auto:RegisterEvent("CHAT_MSG_SYSTEM",event_func)
		UIParent:UnregisterEvent("GROUP_INVITE_CONFIRMATION")
		Auto:RegisterEvent("GROUP_INVITE_CONFIRMATION",event_func)
		if not profile.auto_show_nameplate then
			local function callback()
				has_set_friends = not GetCVarBool("nameplateShowFriends")
				SetCVar("nameplateShowFriends",true)
				SetCVar("nameplateMaxDistance",100)
			end
			if InCombatLockdown() then
				Auto:RegisterEvent("PLAYER_REGEN_ENABLED",callback)
			else
				callback()				
			end
		end
		Auto:RegisterEvent("NAME_PLATE_UNIT_ADDED",event_func,18)
		Auto:RegisterEvent("UNIT_HEALTH_FREQUENT",event_func,18)
		Auto:RegisterEvent("UNIT_TARGET",event_func,17)
	end
	if keyword then
		if profile.auto_addons_wql then
			Auto:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED",event_func)
		end
		Auto:RegisterEvent("CHAT_MSG_WHISPER",event_func)
		if ty_pe then
			ty_pe = ty_pe..keyword
		else
			ty_pe = keyword
		end
		player_list = {}
	else
		Auto:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED",event_func)
	end
	QueueStatusMinimapButton_SetGlowLock(QueueStatusMinimapButton, "lfglist-applicant", false)
	local must
	Auto:RegisterMessage("LFG_AUTO_MAIN_LOOP",event_func)
	Auto:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE",event_func)
	local tolist
	if not IsInGroup() and not C_LFGList.HasActiveEntryInfo() then
		tolist = true
	end
	local function full()
		if not C_LFGList.HasActiveEntryInfo() and not LFGListUtil_IsEntryEmpowered() then
			return true
		end
		local q = C_LFGList.CanActiveEntryUseAutoAccept() or raid
		local n = GetNumGroupMembers()
		local tn = n+C_LFGList.GetNumInvitedApplicantMembers()
		if not keyword then
			tn = tn + C_LFGList.GetNumPendingApplicantMembers()
		end
		local maxn = q and 40 or 4
		if q then
			maxn = 40
		elseif keyword then
			maxn = 4
		else
			maxn = 5
		end
		if maxn <= tn then
			return true
		end
		local gtime = GetTime()
		local counter = tn
		local type = type
		for k,v in pairs(invited_tb) do
			if type(v)=="number" then
				if v + 120 < gtime then
					invited_tb[k] = true
				else
					counter = counter + 1
					if maxn <= counter then
						return true
					end
				end
			end
		end	
	end
	local show_popup = LookingForGroup.show_popup
	local not_hide_popup
	while true do
		local k,gpl,arg3,arg4,arg5,arg6 = coroutine.yield()
		if is_queueing_lfg() or (not tolist and not IsInGroup()) or k == "GROUP_LEFT" then
			break
		elseif k == 0 or k == 1 then
			local hardware = profile.hardware
			if not hardware then
				local CancelApplication = C_LFGList.CancelApplication
				local DeclineInvite = C_LFGList.DeclineInvite
				local GetApplicationInfo = C_LFGList.GetApplicationInfo
				local temp = C_LFGList.GetApplications()
				for i=1,#temp do
					local groupID, status = GetApplicationInfo(temp[i])
					if status == "invited" then
						DeclineInvite(groupID)
					else
						CancelApplication(groupID)
					end
				end
			end			
			local nm = GetNumGroupMembers()
			local auto_leave_party = profile.auto_leave_party
			if nm == 0 or (k == 0 and (nm == 1 or (not gpl and auto_leave_party))) then
				C_PartyInfo.LeaveParty()
				break
			elseif k == 0 and gpl and not hardware then
				C_LFGList.RemoveListing()
			else
				local tb = {nop,ACCEPT,C_PartyInfo.LeaveParty}
				if C_LFGList.HasActiveEntryInfo() and UnitIsGroupLeader("player") then
					tb[#tb+1]=UNLIST_MY_GROUP
					tb[#tb+1]=function()
						C_LFGList.RemoveListing()
						event_func("GROUP_LEFT")
					end
				end
				show_popup(PARTY_LEAVE,tb)
				if k == 0 then
					not_hide_popup = true
					break
				end
			end
		elseif k == 3 then
			if LookingForGroup.popup then
				LookingForGroup.popup:Hide()
			end
		elseif k == 11 then
			if not IsInInstance() then
				C_PartyInfo.LeaveParty()
			end
		elseif k == 17 or k == 18 then
			if UnitExists(arg3) and C_LFGList.HasActiveEntryInfo() and LFGListUtil_IsEntryEmpowered() and
				not UnitInAnyGroup(arg3) and UnitIsPlayer(arg3) and UnitIsFriend(arg3,"player") and
				not UnitOnTaxi(arg3) and (UnitAffectingCombat(arg3) or (k==17 and GetUnitSpeed(arg3) == 0)) then
				local q = C_LFGList.CanActiveEntryUseAutoAccept() or raid
				local n = GetNumGroupMembers()
				local tn = n+C_LFGList.GetNumInvitedApplicantMembers() 
				local maxn = q and 40 or 4
				if tn < maxn  then
					local name,server = UnitName(arg3)
					if name and server then
						name = name.."-"..server
					end
					if name and not invited_tb[name] then
						local us = UnitInRaid("player") and "raid" or "party"
						for i = 1, (us=="party" and n-1 or n) do
							local uname,userver = UnitName(us..i)
							if uname and userver then
								uname = uname.."-"..userver
							end
							if uname then
								invited_tb[uname] = true
							end
						end
						if not full() then
							InviteUnit(name)
							invited_tb[name] = GetTime()
						end
					end
				end
			end
		elseif k == 19 or k == 20 then
			local UnitDistanceSquared = UnitDistanceSquared
			local UnitIsUnit = UnitIsUnit
			local UnitExists = UnitExists
			local UnitIsConnected = UnitIsConnected
			local q = C_LFGList.CanActiveEntryUseAutoAccept() or raid
			local m = min((q and 40 or 5),n)
			local n = GetNumGroupMembers()
			local require_kick
			repeat
			local u = UnitInRaid("player") and "raid" or "party"
			for i=1,(u=="party" and m-1 or m) do
				local unit = u .. i
				local distance = UnitDistanceSquared(unit)
				local name,server = UnitName(unit)
				if name and UnitExists(unit) and not UnitIsUnit("player",unit) and (not UnitIsConnected(unit) or (not distance or 1500000 < distance)) then
					if k==20 then
						UninviteUnit(unit)
					else
						require_kick = name.."-"..server
						break
					end
				end
			end
			for i=m+1,n do
				local unit = u .. i
				if k==20 then
					UninviteUnit(unit)
				else
					require_kick = "Full!"
					break
				end
			end
			until true
			if (not q) and IsInRaid() and (k == 20 or not require_kick) then
				C_PartyInfo.ConvertToParty()
			end
			if k==19 and require_kick then
				show_popup("Kick",{nop,require_kick,function() event_func(20) end})
				ticker:Cancel()
			end
			if k==20 then
				initialize_kicker()
			end
		elseif k == "CHAT_MSG_WHISPER" then
			if not full() and gpl == ty_pe and (not player_list[arg3] or player_list[arg3] + 30 < GetTime() ) then
				player_list[arg3] = GetTime()
				InviteUnit(arg3)
			end
		elseif k == "CHAT_MSG_SYSTEM" then
			local uname = string.match(gpl,string.gsub(ERR_DECLINE_GROUP_S,"%%s","(.*)"))
			if uname then
				uname = strsplit("-",uname)
				for k,v in pairs(invited_tb) do
					if uname == strsplit("-",k) then
						invited_tb[k] = true
					end
				end
			end
		elseif k == "GROUP_INVITE_CONFIRMATION" then
			local firstInvite = GetNextPendingInviteConfirmation()
			if firstInvite then
				local confirmationType, name, guid, rolesInvalid, willConvertToRaid = GetInviteConfirmationInfo(firstInvite)
				if not full() and confirmationType == LE_INVITE_CONFIRMATION_REQUEST and invited_tb[name] == true then
					RespondToInviteConfirmation(firstInvite, true)
				else
					RespondToInviteConfirmation(firstInvite, false)
				end
			end
		elseif k == "LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS" then
			Auto:UnregisterEvent("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS")
			Auto:RegisterEvent("GROUP_ROSTER_UPDATE",event_func)
		elseif k == "GROUP_ROSTER_UPDATE" then
			local nm = GetNumGroupMembers()
			if nm ~= 0 and nm ~= 5 and nm ~= 40 and UnitIsGroupLeader("player") then
				Auto:UnregisterEvent("GROUP_ROSTER_UPDATE")
				Auto:RegisterEvent("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS",event_func)
				if profile.hardware then
					show_popup(name,{nop,START_A_GROUP,create})
				else
					create()
				end
			end
		elseif k == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
			tolist = nil
			if C_LFGList.HasActiveEntryInfo() then
				if must then
					local now = C_LFGList.GetActiveEntryInfo()
					if now.autoAccept ~= must.autoAccept or now.activityID ~= must.activityID or now.questID ~= must.questID then
						local isleader = UnitIsGroupLeader("player")
						if isleader and not profile.hardware and must.autoAccept and must.questID then
							C_LFGList.RemoveListing()
						end
						local quitmessage = "<LFG>LookingForGroup插件已经检测到该团为广告团，请所有人立即退团，防止被工作室举报误封!"
						if UnitInRaid() then
							local assist = isleader and UnitIsGroupAssistant("player")
							SendChatMessage(quitmessage,assist and "RAID_WARNING" or "RAID")
						else
							SendChatMessage(quitmessage,"PARTY")
						end
						C_PartyInfo.LeaveParty()
						break
					end
				else
					must = C_LFGList.GetActiveEntryInfo()
					if UnitIsGroupLeader("player") and not profile.auto_convert_to_raid then
						if C_LFGList.CanActiveEntryUseAutoAccept() or raid then
							C_PartyInfo.ConvertToRaid()
						else
							C_PartyInfo.ConvertToParty()
						end
					end
				end
			end
		elseif k == "LFG_LIST_APPLICANT_LIST_UPDATED" then
			if LFGListUtil_IsEntryEmpowered() then
				if ( C_LFGList.CanActiveEntryUseAutoAccept() or raid) and not profile.auto_convert_to_raid then
					C_PartyInfo.ConvertToRaid()
				end
				if not full() then
					local app = C_LFGList.GetApplicants()
					local C_LFGList_GetApplicantInfo = C_LFGList.GetApplicantInfo
					local InviteUnit = InviteUnit
					local C_LFGList_GetApplicantMemberInfo = C_LFGList.GetApplicantMemberInfo
					local InviteApplicant = C_LFGList.InviteApplicant
					local hardware = profile.hardware
					for i=1,#app do
						local info = C_LFGList_GetApplicantInfo(app[i])
						if info.applicationStatus == "applied" and info.isNew then
							if hardware then
								local name = C_LFGList_GetApplicantMemberInfo(info.applicantID,1)
								InviteUnit(name)
							else
								InviteApplicant(info.applicantID)
							end
						end
					end
				end
			end
		else
			break
		end
	end
	if not not_hide_popup and LookingForGroup.popup then
		LookingForGroup.popup:Hide()
	end
	Event:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
	UIParent:RegisterEvent("GROUP_INVITE_CONFIRMATION")
	Auto:UnregisterAllEvents()
	Auto:UnregisterAllMessages()
	if not LookingForGroup.disable_pve_frame then
		LFGListFrame_OnLoad(LFGListFrame)
		LFGListFrame:Show()
		GroupFinderFrameGroupButton4:Show()
	end
	if ticker then ticker:Cancel() end
	if has_set_friends and GetCVarBool("nameplateShowFriends") then
		local function callback()
			SetCVar("nameplateShowFriends",false)
			Auto:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
		if InCombatLockdown() then
			Auto:RegisterEvent("PLAYER_REGEN_ENABLED",callback)
		else
			callback()
		end
	end
end
