local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_AV = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_AV")
local InviteUnit = InviteUnit
local LookingForGroup_AV_SendCommand = LookingForGroup_AV.SendCommand
local GetNumGroupMembers = GetNumGroupMembers
local UnitName = UnitName
local table_insert = table.insert

local party_leader = {}

local function isp()
	return 0 < LookingForGroup_AV.db.profile.role and (not UnitInParty("player") or UnitIsGroupLeader("player"))
end

local function isrl(rl)
	return LookingForGroup_AV.db.profile.raid_leader == rl
end

party_leader[1] = function(rl,name) -- party_leader.invite(rl,name)
	if isp() and isrl(rl) then
		InviteUnit(name)
	end
end

party_leader[2] = function(rl,...) -- party_leader.create_invite(rl,...)
	if isrl(rl) then
		local invite_temp = {...}
		C_PartyInfo.LeaveParty()
		LookingForGroup_AV:ScheduleTimer(function()
			LookingForGroup_AV.SetRole(1)
			local i
			for i = 1,#invite_temp do
				InviteUnit(invite_temp[i])
			end
		end,1)
	end
end

party_leader[3] = function(rl) -- party_leader.roleconfirm(rl)
	if isrl(rl) then
		LookingForGroup_AV_SendCommand(LookingForGroup_AV,LookingForGroup_AV:Serialize(1,4),"PARTY")
	end
end

party_leader[4] = function(pm,...) -- party_leader.send_chat_message(pm,...)
	if isp() and UnitInParty(pm) then
		LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(3,2,pm,...),"WHISPER",LookingForGroup_AV.db.profile.raid_leader)
	end
end

party_leader[5] = function(rl,...) -- party_leader.broadcast_chat_message(rl,...)
	if isrl(rl) then
		LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(1,3,...),"PARTY")
	end
end

party_leader[6] = function(rl)
	if isrl(rl) then
		local GetBattlefieldStatus = GetBattlefieldStatus
		for i=1,GetMaxBattlefieldID() do
			local status, bg = GetBattlefieldStatus(i)
			if status ~= "none" then
				LookingForGroup:Print(LEAVE_QUEUE,bg)
				return
			end
		end
	end
end

party_leader[7] = function(rl)
	if isrl(rl) then
		local GetBattlefieldStatus = GetBattlefieldStatus
		for i=1,GetMaxBattlefieldID() do
			local status, bg = GetBattlefieldStatus(i)
			if status == "none" then
				LookingForGroup:Print(BATTLEFIELD_JOIN)
				return
			end
		end
	end
end

party_leader[8] = function(rl)
	local profile = LookingForGroup_AV.db.profile
	if profile.raid_leader == nil then
		local dialog = StaticPopupDialogs.LookingForGroup_AV_Dialog
		dialog.text = "LookingForGroup\n"..format(INVITATION,rl)
		dialog.OnAccept = function()
			profile.raid_leader = rl
		end
		StaticPopup_Show("LookingForGroup_AV_Dialog")
	end
end

function LookingForGroup_AV:GROUP_ROSTER_UPDATE()
	if isp() then
		local profile = LookingForGroup_AV.db.profile
		local raid_leader = profile.raid_leader
		local numgm = GetNumGroupMembers()
		local members = {}
		local i
		for i = 1,numgm do
			local unit = "player"
			if 1 < i then
				unit = "party"..i-1
			end
			local name,server = UnitFullName(unit)
			if name and server then
				table_insert(members,{name..'-'..server,UnitGroupRolesAssigned(unit),select(2,UnitClass(unit))})
			end
		end
		LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(3,1,members),"WHISPER",raid_leader)
	end
end

function LookingForGroup_AV:UPDATE_BATTLEFIELD_STATUS(event,index,...)
	if isp() then
		local raid_leader = LookingForGroup_AV.db.profile.raid_leader
		local status = GetBattlefieldStatus(index)
		if status == "none" then
			LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(3,3),"WHISPER",raid_leader)
		elseif status == "queued" then
			LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(3,3,0,GetBattlefieldEstimatedWaitTime(index),GetBattlefieldTimeWaited(index)),"WHISPER",raid_leader)
		elseif status == "confirm" then
			LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(3,3,1,GetBattlefieldPortExpiration(index)),"WHISPER",raid_leader)
		end
	end
end

LookingForGroup_AV.member[2] = party_leader
