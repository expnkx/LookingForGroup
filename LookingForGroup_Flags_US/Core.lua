local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local realms =
{
["Frostmourne"] = "oceanic",
["Nagrand"] = "oceanic",
["Caelestrasz"] = "oceanic",
["Dreadmaul"] = "oceanic",
["Saurfang"] = "oceanic",
["Dath'Remar"] = "oceanic",
["Thaurissan"] = "oceanic",
["Khaz'goroth"] = "oceanic",
["Barthilas"] = "oceanic",
["Gundrak"] = "oceanic",
["Aman'Thul"] = "oceanic",
["Jubei'Thos"] = "oceanic",

["TolBarad"] = "brazilian",
["Nemesis"] = "brazilian",
["Goldrinn"] = "brazilian",
["Gallywix"] = "brazilian",
["Azralon"] = "brazilian",

["Ragnaros"] = "mexican",
["Quel'Thalas"] = "mexican",
["Drakkari"] = "mexican",
}

LookingForGroup_Options.Register("lfgscoresbrief",nil,function(name)
	local realm = name:match("-(.*)$")
	if realm == nil then
		realm = GetNormalizedRealmName()
	end
	local language = realms[realm]
	if language then
		return " |TInterface\\AddOns\\LookingForGroup_Flags_US\\textures\\"..language..":0|t"
	end
end)
