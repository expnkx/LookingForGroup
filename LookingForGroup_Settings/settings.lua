local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")

local settings = LookingForGroup_Options.option_table.args.settings
local opt_not_enabled

if settings == nil then
	opt_not_enabled = true
	settings = LookingForGroup_Options.option_table
end
settings.args =
{
	disable_blizzard =
	{
		name = DISABLE.." BlizzardUI",
		type = "group",
		args =
		{
			disable_gmotd =
			{
				name = GUILD_MOTD_LABEL2,
				type = "toggle",
				get = LookingForGroup_Options.get_function,
				set = LookingForGroup_Options.set_function
			},
			quick_join =
			{
				name = QUICK_JOIN,
				type = "toggle",
				get = function(info)
					return LookingForGroup.db.profile.disable_quick_join
				end,
				confirm = true,
				set = function(info,val)
					if val then
						LookingForGroup.db.profile.disable_quick_join = true
					else
						LookingForGroup.db.profile.disable_quick_join = nil
					end
					ReloadUI()
				end,
				confirm = true,
			},
		}
	},
	window =
	{
		name = L.options_window,
		type = "group",
		args =
		{
			save = 
			{
				name = SAVE,
				order = 1,
				type = "execute",
				func = function()
					local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
					local height, width	= st.height, st.width
					local db = LookingForGroup_Options.db
					local default = db.defaults.profile
					local profile = db.profile
					if height == nil then
						profile.window_height = 500
					elseif height == default.window_height then
						profile.window_height = nil
					else
						profile.window_height = height
					end
					if width == nil then
						profile.window_width = 700
					elseif width == default.window_width then
						profile.window_width = nil
					else
						profile.window_width = width
					end
					profile.window_left,profile.window_top = st.left, st.top
				end,
			},
			reset = 
			{
				name = RESET,
				order = 2,
				type = "execute",
				func = function()
					local v = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
					local db = LookingForGroup_Options.db
					local default = db.defaults.profile
					local profile = db.profile
					v.height = default.window_height
					profile.window_height = nil
					v.width = default.window_width
					profile.window_width = nil
					v.left = nil
					v.top = nil
					profile.window_left = nil
					profile.window_top = nil
				end,
			},
			line =
			{
				name = nop,
				order = 3,
				type = "description",
				width = "full"
			},
			height =
			{
				name = COMPACT_UNIT_FRAME_PROFILE_FRAMEHEIGHT,
				type = "range",
				max = tonumber(GetCVar("gxFullscreenResolution"):match("%d+x(%d+)")),
				step = 0.01,
				get = function()
					local v = (LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")).height
					if v then
						return v
					else
						return 500
					end
				end,
				set = function(info,val)
					local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
					if val == 500 then
						st.height = nil
					else
						st.height = val
					end
				end,
			},
			width =
			{
				name = COMPACT_UNIT_FRAME_PROFILE_FRAMEWIDTH,
				type = "range",
				max = tonumber(GetCVar("gxFullscreenResolution"):match("(%d+)x%d+")),
				step = 0.01,
				get = function(info)
					local v = (LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")).width
					if v then
						return v
					else
						return 700
					end
				end,
				set = function(info,val)
					local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
					if val == 700 then
						st.width = nil
					else
						st.width = val
					end
				end,
			},
			left =
			{
				name = "LEFT",
				type = "range",
				min = -1,
				max = tonumber(GetCVar("gxFullscreenResolution"):match("%d+x(%d+)")),
				step = 0.01,
				get = function()
					local v = (LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")).left
					if v then
						return v
					else
						return -1
					end
				end,
				set = function(info,val)
					local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
					if val < 0 then
						st.left = nil
					else
						st.left = val
					end
				end,
			},
			top =
			{
				name = "TOP",
				type = "range",
				min = -1,
				max = tonumber(GetCVar("gxFullscreenResolution"):match("(%d+)x%d+")),
				step = 0.01,
				get = function(info)
					local v = (LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")).top
					if v then
						return v
					else
						return -1
					end
				end,
				set = function(info,val)
					local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
					if val < 0 then
						st.top = nil
					else
						st.top = val
					end
				end,
			},
		}
	},
	profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(LookingForGroup.db)
}

local special =
{
	role_check =
	{
		name = LFG_LIST_ROLE_CHECK,
		desc = string.format(L.options_advanced_role_check,ROLE),
		type = "toggle",
		get = LookingForGroup_Options.get_function,
		set = LookingForGroup_Options.set_function,
	},
	hardware =
	{
		name = HARDWARE,
		desc = L.options_advanced_hardware,
		type = "toggle",
		get = LookingForGroup_Options.get_function,
		set = function(_,val)
			LookingForGroup.db.profile.hardware=val
		end,
	},
	mute =
	{
		name = MUTE,
		desc = L.options_advanced_mute,
		type = "toggle",
		get = LookingForGroup_Options.get_function,
		set = LookingForGroup_Options.set_function,
	},
	taskbar_flash = 
	{
		name = L["Taskbar Flash"],
		type = "toggle",
		get = LookingForGroup_Options.get_function,
		set = LookingForGroup_Options.set_function,
	},
}

if opt_not_enabled then
	settings.args.settings =
	{
		name = SETTINGS,
		type = "group",
		args = special
	}
else
	local args = settings.args
	for k,v in pairs(special) do
		args[k]=v
	end
end

settings.args.profile.order = -1

function LookingForGroup_Options:push_settings(key,val)
	settings.args[key] = val
end
