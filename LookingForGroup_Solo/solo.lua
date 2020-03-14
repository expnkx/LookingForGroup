local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")

LookingForGroup_Options:push("solo",
{
	name = SOLO,
	type = "group",
	args =
	{
		start_a_group =
		{
			name = START_A_GROUP,
			type = "execute",
			func = function()
				if not IsInGroup() then
					if LFGListFrame.EntryCreation.Name:GetText() ~= "" then
						C_LFGList.CreateListing(457,GetAverageItemLevel()-3,0,false,true)
						coroutine.wrap(LookingForGroup_Options.req_main)(1)
					else
						LookingForGroup_Options.expected(format(L.solo_hint,LFG_LIST_TITLE,START_A_GROUP))
					end
					if LookingForGroup_Options.db.profile.solo_convert_to_raid then
						C_Timer.After(1,C_PartyInfo.ConvertToRaid)
					end
				end
			end,
			order = 1
		},
		instance_leave =
		{
			name = INSTANCE_LEAVE,
			type = "execute",
			func = function()
				if C_LFGList.HasActiveEntryInfo() and LFGListUtil_IsEntryEmpowered() then
					local info = C_LFGList.GetActiveEntryInfo()
					if info.activityID==457 and info.privateGroup then
						C_PartyInfo.LeaveParty()
					end
				elseif IsInInstance() and not IsInGroup() then
					if LFGListFrame.EntryCreation.Name:GetText() ~= "" then
						C_LFGList.CreateListing(457,GetAverageItemLevel()-3,0,false,true)
						coroutine.wrap(LookingForGroup_Options.req_main)(1)
						C_Timer.After(1,C_PartyInfo.LeaveParty)
					else
						LookingForGroup_Options.expected(format(L.solo_hint,LFG_LIST_TITLE,INSTANCE_LEAVE))
						LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","find","s","s")
					end
				end
			end,
			order = 2,
		},
		cvtr =
		{
			name = CONVERT_TO_RAID,
			type = "toggle",
			get = function()
				return LookingForGroup_Options.db.profile.solo_convert_to_raid
			end,
			set = function(info,val)
				LookingForGroup_Options.db.profile.solo_convert_to_raid = val or nil
			end,
			order = 4,
		},
		title = 
		{
			order = 3,
			name = format(L.solo_hint,LFG_LIST_TITLE,SPELL_TARGET_TYPE1_DESC),
			type = "input",
			dialogControl = "LFG_SECURE_NAME_EDITBOX_REFERENCE",
			width = "full"
		}
	}
})
