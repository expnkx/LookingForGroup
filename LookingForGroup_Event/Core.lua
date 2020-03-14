local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local Event = LookingForGroup:NewModule("Event","AceEvent-3.0")

function Event:OnEnable()
	self:RegisterEvent("ADDON_ACTION_BLOCKED")
	LFGListInviteDialog:UnregisterAllEvents()
	self:RegisterEvent("PARTY_INVITE_REQUEST")
	UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
	local profile = LookingForGroup.db.profile
	if not profile.spam_filter_community then
		local frames = {GetFramesRegisteredForEvent("CLUB_INVITATION_ADDED_FOR_SELF")}
		for i=1,#frames do
			frames[i]:UnregisterEvent("CLUB_INVITATION_ADDED_FOR_SELF")
		end
	end
	if profile.disable_quick_join then
		local frames = {GetFramesRegisteredForEvent("SOCIAL_QUEUE_UPDATE")}
		for i=1,#frames do
			frames[i]:UnregisterEvent("SOCIAL_QUEUE_UPDATE")
		end
		FriendsFrameTab4:Hide()
		QuickJoinFrame:Hide()
		QuickJoinToastButton:Hide()
		QuickJoinFrame:UnregisterAllEvents()
		QuickJoinToastButton:UnregisterAllEvents()
	end
	local elvui = LibStub("AceAddon-3.0"):GetAddon("ElvUI",true)
	if elvui then
		local S = elvui:GetModule("Skins")
		S:RegisterMessage("LFG_QUEST_BUTTON",function(event,button,questID,block)
			if not button.elvui then
				S:HandleButton(button)
				button:Size(20)
				button.elvui = true
			end
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", block, "TOPRIGHT",4,0)
		end)
	end
	self.OnEnable = nil
	local numApplications, numActiveApplications = C_LFGList.GetNumApplications()
	if numActiveApplications ~= 0 then
		local applications = C_LFGList.GetApplications()
		local GetApplicationInfo = C_LFGList.GetApplicationInfo
		for i =1, #applications do
			local id, appStatus,pendingStatus = GetApplicationInfo(applications[i])
			if appStatus == "invited" then
				self:LFG_LIST_APPLICATION_STATUS_UPDATED(nil,id, appStatus,pendingStatus,arg3,arg4,arg5)
				return
			end
		end
	end
	if LookingForGroup.disable_pve_frame then
		LFGEventFrame:UnregisterEvent("LFG_UPDATE")
		LFGEventFrame:UnregisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE");
		LFGEventFrame:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");
		PVEFrame:UnregisterAllEvents()
		LFDParentFrame:UnregisterEvent("AJ_DUNGEON_ACTION")
		LFDParentFrame:UnregisterEvent("LFG_OPEN_FROM_GOSSIP")
		RaidFinderFrame:UnregisterAllEvents()
		LFGListFrame:UnregisterAllEvents()
		LFGListFrame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
	else
		LFGListFrame:UnregisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
		LFGListFrame:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
	end
	self:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
	self:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
	self:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
end

function Event:LFG_LIST_APPLICANT_UPDATED()
	if InCombatLockdown() or ( select(2,C_LFGList.GetNumApplicants()) == 0 ) then
		QueueStatusMinimapButton_SetGlowLock(QueueStatusMinimapButton, "lfglist-applicant", false)
	end
end

function Event:ADDON_ACTION_BLOCKED(info,addon,method)
	if addon:find("LookingForGroup") and (method == "Search()" or method == "resume()" or method == "UNKNOWN()") then
		local profile = LookingForGroup.db.profile
		if not profile.hardware then
			profile.hardware = true
			LookingForGroup:Print(MODE,HARDWARE)
		end
	end
end

function Event:LFG_LIST_ACTIVE_ENTRY_UPDATE(event,creatednew)
	if creatednew and not LookingForGroup.db.profile.mute then
		PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
	end
end

function Event:PARTY_INVITE_REQUEST(event, name, tank, healer, damage, isXRealm, allowMultipleRoles, inviterGuid)
	-- Color the name by our relationship
	local modifiedName, color, selfRelationship = SocialQueueUtil_GetRelationshipInfo(inviterGuid);
	if ( selfRelationship ) then
		name = color..name..FONT_COLOR_CODE_CLOSE;
	elseif not LookingForGroup.db.profile.sf_invite_relationship then
		Event:SendMessage("LFG_CHAT_MSG_SILENT",0)
		DeclineGroup()
		return
	end
	-- if there's a role, it's an LFG invite
	if ( tank or healer or damage ) then
		StaticPopupSpecial_Show(LFGInvitePopup);
		LFGInvitePopup_Update(name, tank, healer, damage, allowMultipleRoles);
	else
		local text = isXRealm and INVITATION_XREALM or INVITATION;
		text = string.format(text, name);

		if ( WillAcceptInviteRemoveQueues() ) then
			text = text.."\n\n"..ACCEPTING_INVITE_WILL_REMOVE_QUEUE;
		end
		StaticPopup_Show("PARTY_INVITE", text);
	end
end

function Event.show_invite_dialog(resultID)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	local activityName = C_LFGList.GetActivityInfo(searchResultInfo.activityID);
	
	local concat_tb = {}
	local member_counts = C_LFGList.GetSearchResultMemberCounts(resultID)
	concat_tb[#concat_tb+1] = activityName
	concat_tb[#concat_tb+1] = '\n|cff00ffff'
	concat_tb[#concat_tb+1] = searchResultInfo.numMembers
	concat_tb[#concat_tb+1] = "("
	concat_tb[#concat_tb+1] = member_counts.TANK
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.HEALER
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.DAMAGER + member_counts.NOROLE
	concat_tb[#concat_tb+1] = ")|r"
	if searchResultInfo.leaderName then
		concat_tb[#concat_tb+1] = "\n|cffff00ff"
		concat_tb[#concat_tb+1] = searchResultInfo.leaderName
		concat_tb[#concat_tb + 1] = "|r"
	end
	local LFGListInviteDialog = LFGListInviteDialog
	LFGListInviteDialog.GroupName:SetText(searchResultInfo.name);
	LFGListInviteDialog.ActivityName:SetText(table.concat(concat_tb));
	wipe(concat_tb)
	local applicationid, status, pending, appduration, role = C_LFGList.GetApplicationInfo(resultID);
	LFGListInviteDialog.Role:SetText(_G[role]);
	LFGListInviteDialog.RoleIcon:SetTexCoord(GetTexCoordsForRole(role));
	LFGListInviteDialog.Label:SetText(LFG_LIST_INVITED_TO_GROUP);
	LFGListInviteDialog.AcceptButton:SetShown(true);
	LFGListInviteDialog.DeclineButton:SetShown(true);
	LFGListInviteDialog.AcknowledgeButton:SetShown(false);

	LFGListInviteDialog:SetHeight(210);
	LFGListInviteDialog.OfflineNotice:Hide();

	StaticPopupSpecial_Show(LFGListInviteDialog);

	local profile = LookingForGroup.db.profile
	if not profile.mute then
		PlaySound(SOUNDKIT.READY_CHECK);
	end
	if profile.taskbar_flash then
		FlashClientIcon();
	end
end

local function invited_cofunc(applicationid,invited,applied)
	local current = coroutine.running()
	local function event_callback(...)
		LookingForGroup.resume(current,...)
	end
	Event:RegisterEvent("LFG_LIST_JOINED_GROUP",event_callback)
	Event:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",event_callback) 
	Event:RegisterEvent("PARTY_LEADER_CHANGED",event_callback)
	local LFGListInviteDialog = LFGListInviteDialog
	local AcceptButton = LFGListInviteDialog.AcceptButton
	local DeclineButton = LFGListInviteDialog.DeclineButton
	local original_accept_onclick = AcceptButton:GetScript("OnClick")
	local original_decline_onclick = DeclineButton:GetScript("OnClick")
	AcceptButton:SetScript("OnClick",function()
		LookingForGroup.resume(current,0,true)
	end)
	DeclineButton:SetScript("OnClick",function()
		LookingForGroup.resume(current,0,false)
	end)
	if LFGListUtil_IsAppEmpowered() then
		if not LFGListInviteDialog:IsShown() then
			Event.show_invite_dialog(applicationid)
		end
	end
	while true do
		local event,arg1,arg2,arg3,arg4,arg5 = coroutine.yield()
		if event == "LFG_LIST_JOINED_GROUP" then
			StaticPopupSpecial_Hide(LFGListInviteDialog)
			break
		elseif event == "PARTY_LEADER_CHANGED" then
			if LFGListUtil_IsAppEmpowered() then
				if not LFGListInviteDialog:IsShown() then
					Event.show_invite_dialog(applicationid)
				end
			else
				StaticPopupSpecial_Hide(LFGListInviteDialog)
			end
		else
			if event == 0 then
				if arg1 then
					C_LFGList.AcceptInvite(applicationid)
				else
					C_LFGList.DeclineInvite(applicationid)
				end
				StaticPopupSpecial_Hide(LFGListInviteDialog)
				local numApplications, numActiveApplications = C_LFGList.GetNumApplications()
				if numActiveApplications == 0 then
					break
				end
			elseif event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
				if arg1 == applicationid and arg2 ~= "invited" then
					StaticPopupSpecial_Hide(LFGListInviteDialog)
				end
			end
			local applications = C_LFGList.GetApplications()
			local GetApplicationInfo = C_LFGList.GetApplicationInfo
			local i = 1
			while i <= #applications do
				local id, appStatus,pending = GetApplicationInfo(applications[i])
				if appStatus == "invited" and pending ~= "invitedeclined" then
					applicationid = id
					Event.show_invite_dialog(id)
					break
				end
				i = i + 1
			end
			if #applications < i then
				break
			end
		end
	end
	AcceptButton:SetScript("OnClick",original_accept_onclick)
	DeclineButton:SetScript("OnClick",original_decline_onclick)
	Event:UnregisterEvent("LFG_LIST_JOINED_GROUP")
	Event:UnregisterEvent("PARTY_LEADER_CHANGED")
	Event:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
end

function Event:LFG_LIST_APPLICATION_STATUS_UPDATED(event,applicationid,invited,pendingStatus)
	if invited == "invited" then
		coroutine.wrap(invited_cofunc)(applicationid,invited,applied)
	end
end