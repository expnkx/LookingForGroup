local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_AV = LibStub("AceAddon-3.0"):NewAddon("LookingForGroup_AV","AceEvent-3.0","AceTimer-3.0","AceComm-3.0","AceSerializer-3.0","AceConsole-3.0")

function LookingForGroup_AV:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LookingForGroup_AVCharacterDB",
	{
		profile =
		{
			role = 0,
			parties =
			{},
			potentials =
			{},
			status =
			{}
--			raid_leader = nil
		}
	},true)
	self:RegisterComm("LFG_AV")
end

function LookingForGroup_AV:OnEnable()
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	self:RegisterChatCommand("v","ChatCommand")
	local tb = {button1=ACCEPT,button2=CANCEL,timeOut = 60}
	StaticPopupDialogs.LookingForGroup_AV_Dialog = tb
end

function LookingForGroup_AV.SetRole(role)
	LookingForGroup_AV.db.profile.role = role
end

function LookingForGroup_AV.GetRole()
	return LookingForGroup_AV.db.profile.role
end
LookingForGroup_AV.member = {}
local member = LookingForGroup_AV.member

local function transfer_info(unit,...)
	local suc, obj,method = ...
	if suc then
		member[obj][method](unit,select(4,...))
	end
end

function LookingForGroup_AV:OnCommReceived(prefix, text, distribution, unit)
	transfer_info(unit,self:Deserialize(text))
end

function LookingForGroup_AV:SendCommand(...)
	LookingForGroup_AV:SendCommMessage("LFG_AV",...)
end
