local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")

LookingForGroup:NewModule("Icon").OnEnable = function()
	LibStub("LibDBIcon-1.0"):Register(LFG_TITLE:gsub(" ",""),LookingForGroup.LDB,(LibStub("AceDB-3.0"):New("LookingForGroup_IconCharacterDB", {profile = {}})).profile)
end
