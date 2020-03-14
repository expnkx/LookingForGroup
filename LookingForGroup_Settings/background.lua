local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")

LookingForGroup_Options:push_settings("background",
{
	name = L.background_search,
	type = "group",
	args =
	{
		counts =
		{
			name = GROUPS,
			order = 1,
			type = "range",
			step = 1,
			min = 1,
			max = 100,
			get = function()
				return LookingForGroup_Options.db.profile.background_counts or 1
			end,
			set = function(info,val)
				if val== 1 then
					LookingForGroup_Options.db.profile.background_counts = nil
				else
					LookingForGroup_Options.db.profile.background_counts = val
				end
			end,
			width = "full"
		},
		period = 
		{
			name = "["..HARDWARE.."]Period",
			desc = "Unit: (sec)",
			order = 6,
			type = "input",
			get = function()
				local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
				if LookingForGroup.db.profile.hardware then
					local v = LookingForGroup_Options.db.profile.background_period
					if v then
						return tostring(v)
					else
						return "300"
					end
				end
			end,
			set = function(info,val)
				local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
				if LookingForGroup.db.profile.hardware then
					local v = tonumber(val)
					if v < 10 then
						v = 10
					end
					if v == 300 then
						LookingForGroup_Options.db.profile.background_period = nil
					else
						LookingForGroup_Options.db.profile.background_period = v
					end
				end
			end,
		},
		background_popup =
		{
			name = "Pop up",
			order = 7,
			type = "toggle",
			get = LookingForGroup_Options.options_get_function,
			set = LookingForGroup_Options.options_set_function
		},
		reset = 
		{
			name = RESET,
			order = 5,
			type = "execute",
			func = function()
				LookingForGroup_Options.db.profile.background_counts=nil
				LookingForGroup_Options.db.profile.background_period=nil
				LookingForGroup_Options.db.profile.background_popup=nil
			end
		}
	}
})
