local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup_AV = AceAddon:GetAddon("LookingForGroup_AV")
local LookingForGroup_AV_SendCommand = LookingForGroup_AV.SendCommand

local C_LFGList_GetApplicantMemberInfo = C_LFGList.GetApplicantMemberInfo

local function name_is_same_realm(name)
	if string.find(name,'-') == nil then
		return true
	end
end

local function isr()
	return LookingForGroup_AV.GetRole() == 2
end

local function potential(potentials,name)
	if name_is_same_realm(name) then
		potentials[#potentials + 1] = name
	end
	return name
end

local function too_many_healers(v)
	local num = 0
	for i=1,#v do
		if v[i][2] == "HEALER" then
			num = num + 1
			if 1 < num then
				return true
			end
		end
	end
end

local function party_assign(parties,potentials,name,ishealer)
	local d = name_is_same_realm(name)
	local i
	local k,v
	for k,v in pairs(parties) do
		if #v < 5 and not (ishealer and too_many_healers(v)) then
			if d then
				potentials[name] = name
			end
			LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(2,1,name),"WHISPER",k)
			return
		end
	end
	if d then
		potentials[name] = name
		LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(1,1),"WHISPER",name)
	else
		local top = next(potentials)
		if top then
			parties[name] = {}
			LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(2,2,name),"WHISPER",top)
			potentials[top] = nil
			local ok,LookingForGroup_Options = pcall(AceAddon.GetAddon,AceAddon,"LookingForGroup_Options")
			if ok then
				LookingForGroup_Options.NotifyChangeIfSelected("av\1status")
			end
		end
	end
end

function LookingForGroup_AV.Start()
	local profile = LookingForGroup_AV.db.profile
	if profile.raid_leader == nil then
		local parties = profile.parties
		LookingForGroup_AV.SetRole(2)
		local name = UnitName("player")
		parties[name]={}
		profile.raid_leader = name
	end
end

function LookingForGroup_AV.CreateListing(id,itemLevel, honorLevel, voiceChat, autoAccept, privateGroup, questID)
	LookingForGroup_AV.Start()
	if isr() then
		C_LFGList.CreateListing(id,itemLevel, honorLevel, voiceChat, false, privateGroup)
	end
end

function LookingForGroup_AV.UpdateListing(id,itemLevel, honorLevel, voiceChat, autoAccept, privateGroup, questID)
	if isr() then
		C_LFGList.UpdateListing(id,itemLevel, honorLevel, voiceChat, false, privateGroup)
	end
end

function LookingForGroup_AV.RemoveListing(...)
	if isr() then
		C_LFGList.RemoveListing(...)
	end
end

function LookingForGroup_AV.rl_disban()
	local profile = LookingForGroup_AV.db.profile
	profile.role = 0
	wipe(profile.parties)
	wipe(profile.potentials)
	wipe(profile.status)
	profile.raid_leader = nil
end

local raid_leader = {}

raid_leader[1] = function(leader,members) --raid_leader.group_roster_update(leader,members)
	if isr() then
		local parties = LookingForGroup_AV.db.profile.parties
		if parties[leader] then
			parties[leader] = members
			local ok,LookingForGroup_Options = pcall(AceAddon.GetAddon,AceAddon,"LookingForGroup_Options")
			if ok then
				LookingForGroup_Options.NotifyChangeIfSelected("av\1parties")
			end
		end
	end
end

raid_leader[2] = function(source,...) -- raid_leader.broadcast_chat_message(source,...)
	if isr() then
		local parties = LookingForGroup_AV.db.profile.parties
		if parties[source] then
			local serialize = LookingForGroup_AV:Serialize(2,5,...)
			local k,v
			for k,v in pairs(parties) do
				LookingForGroup_AV_SendCommand(LookingForGroup_AV,serialize,"WHISPER",k)
			end
		end
	end
end

raid_leader[3] = function(source,status,...) -- raid_leader.update_status(source,...)
	if isr() then
		local profile = LookingForGroup_AV.db.profile
		local parties = profile.parties
		if parties[source] then
			if status == nil then
				profile.status[source] = nil
			elseif status == 0 then
				profile.status[source] = {0,GetTime(),...}
			elseif status == 1 then
				profile.status[source] = {1,GetTime(),...}
			end
			local ok,LookingForGroup_Options = pcall(AceAddon.GetAddon,AceAddon,"LookingForGroup_Options")
			if ok then
				LookingForGroup_Options.NotifyChangeIfSelected("av\1parties")
			end
		end
	end
end

raid_leader[4] = function(source)
	local profile = LookingForGroup_AV.db.profile
	if profile.role == 2 and profile.parties[source] == nil then
		local dialog = StaticPopupDialogs.LookingForGroup_AV_Dialog
		dialog.text = "LookingForGroup\n"..format(INVITE_CONFIRMATION_REQUEST,source)
		dialog.OnAccept = function()
			profile.parties[source] = {}
			profile.status[source] = {}
		end
		StaticPopup_Show("LookingForGroup_AV_Dialog")
	end
end

LookingForGroup_AV.member[3] = raid_leader
