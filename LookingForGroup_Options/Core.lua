local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options")

function LookingForGroup_Options.aj_open_action(...)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfigDialog:SelectGroup("LookingForGroup",...)
	AceConfigDialog:Open("LookingForGroup")
end

function LookingForGroup_Options:LFG_UPDATE_EDITING()
	self.update_editing()
	self.aj_open_action("find","s")
end

function LookingForGroup_Options:AJ_PVE_LFG_ACTION()
	self.aj_open_action("find")
end

LookingForGroup_Options.AJ_PVP_LFG_ACTION = LookingForGroup_Options.AJ_PVE_LFG_ACTION

function LookingForGroup_Options:options_onenable()
	self.option_table.args.find.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local GetAddOnMetadata = GetAddOnMetadata
	local GetAddOnInfo = GetAddOnInfo
	local region = GetCurrentRegion()
	for i = 1, GetNumAddOns() do
		local metadata = GetAddOnMetadata(i, "X-LFG-OPT")
		if metadata and (metadata == "0" or region == tonumber(metadata)) then
			LoadAddOn(i)
		end
	end
	self:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
	self:RegisterMessage("LFG_UPDATE_EDITING")
	self:RegisterMessage("LFG_AUTO_MAIN_LOOP")
	self:RegisterEvent("AJ_PVE_LFG_ACTION")
	self:RegisterEvent("AJ_PVP_LFG_ACTION")
	if C_LFGList.HasActiveEntryInfo() then
		coroutine.wrap(self.req_main)()
	end
	self.options_onenable = nil
end

