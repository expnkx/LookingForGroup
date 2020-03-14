local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

function LookingForGroup_Options.listing(activity,s,filters,back_list,provider,...)
	local quest_id = s.quest_id
	local expected = s.expected or LookingForGroup_Options.expected
	if quest_id then
		if not activity then
			activity = C_LFGList.GetActivityIDForQuestID(quest_id) or 16
		end
	else
		if not activity then
			local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")
			expected(format(L.must_select_xxx,LFG_LIST_ACTIVITY,START_A_GROUP))
			LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","find")
			return
		end
	end
	local listing
	provider = provider or C_LFGList
	if C_LFGList.HasActiveEntryInfo() then
		local actv = C_LFGList.GetActiveEntryInfo().activityID
		activity = actv
		listing = provider.UpdateListing
		if quest_id == nil and LFGListFrame.EntryCreation.Name:GetText()=="" then
			expected(LFG_LIST_MUST_HAVE_NAME)
			return
		end
		LookingForGroup_Options:SendMessage("LFG_LIST_OR_UPDATE")
	else
		listing = provider.CreateListing
		if quest_id == nil and LFGListFrame.EntryCreation.Name:GetText()=="" then
			expected(LFG_LIST_MUST_HAVE_NAME)
			return
		end
	end
	if listing(activity,s.minimum_item_level or 0,s.minimum_honor_level or 0,s.auto_accept or false,s.private or false,quest_id) then
		if not active then
			coroutine.wrap(LookingForGroup_Options.req_main)(s.auto_accept,filters,back_list,provider,...)
		end
		return true
	else
		expected(FAILED)
	end
end
