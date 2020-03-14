local AceAddon = LibStub("AceAddon-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")
local order = 0
local function get_order()
	local temp = order
	order = order +1
	return temp
end

local get_function_negative = LookingForGroup_Options.get_function_negative
local set_function_negative = LookingForGroup_Options.set_function_negative
local options_get_function_negative = LookingForGroup_Options.options_get_function_negative
local options_set_function_negative = LookingForGroup_Options.options_set_function_negative

local select_tb = {}

LookingForGroup_Options:push_settings("sf",{
	name = SPAM_FILTER,
	type = "group",
	args =
	{
		mlength = 
		{
			name = L["Maximum Text Length"],
			desc = L.max_length_desc,
			type = "input",
			order = get_order(),
			set = function(_,val)
				if val == "" then
					LookingForGroup.db.profile.spam_filter_maxlength = false
				else
					LookingForGroup.db.profile.spam_filter_maxlength = tonumber(val)
				end
			end,
			get = function()
				local ml = LookingForGroup.db.profile.spam_filter_maxlength
				if ml and 0 <= ml then
					return tostring(ml)
				end
			end,
			pattern = "^[0-9]*$",
			width = "full",
		},
		digits =
		{
			order = get_order(),
			name = "%d+",
			desc = L.digits_desc,
			type = "input",
			get = function(info)
				local d = LookingForGroup.db.profile.spam_filter_digits
				if d then
					return tostring(d)
				end
			end,
			pattern = "^[0-9]*$",
			set = function(info,val)
				if val == "" then
					if GetCurrentRegion() == 5 then
						LookingForGroup.db.profile.spam_filter_digits = false
					else
						LookingForGroup.db.profile.spam_filter_digits = nil
					end
				else
					LookingForGroup.db.profile.spam_filter_digits = tonumber(val)
				end
			end,
			width = "full"
		},
		hyperlinks =
		{
			order = get_order(),
			name = "|c[^%[]+%[([^%]]+)%]|h|r",
			desc = L.hyperlinks_desc,
			type = "input",
			get = function(info)
				local d = LookingForGroup.db.profile.spam_filter_hyperlinks
				if d then
					return tostring(d)
				end
			end,
			pattern = "^[0-9]*$",
			set = function(info,val)
				if val == "" then
					if GetCurrentRegion() == 5 then
						LookingForGroup.db.profile.spam_filter_hyperlinks = false
					else
						LookingForGroup.db.profile.spam_filter_hyperlinks = nil
					end
				else
					LookingForGroup.db.profile.spam_filter_hyperlinks = tonumber(val)
				end
			end,
			width = "full"
		},
		add =
		{
			name = ADD,
			desc = L.sf_add_desc,
			type = "input",
			order = get_order(),
			set = function(_,val)
				local tb = LookingForGroup.db.profile.spam_filter_keywords
				if tb == nil then
					tb = {}
				end
				local lower = string.lower
				local gsub = string.gsub
				tb[#tb+1] = lower(gsub(val," ",""))
				table.sort(tb)
				LookingForGroup.db.profile.spam_filter_keywords = tb
			end,
			get = nop,
			width = "full"
		},
		auto_whisper =
		{
			name = WHISPER,
			type = "input",
			get = function(info)
				return LookingForGroup.db.profile.sf_whisper
			end,
			set = function(info,v)
				if v:len() == 0 then
					LookingForGroup.db.profile.sf_whisper = nil
				else
					LookingForGroup.db.profile.sf_whisper = v					
				end
			end,
			width = "full"
		},
		rmv =
		{
			name = REMOVE,
			type = "execute",
			order = get_order(),
			func = function()
				local profile = LookingForGroup.db.profile
				local spkt = profile.spam_filter_keywords
				local cp = {}
				if spkt then
					for i = 1,#spkt do
						if select_tb[i]~=true then
							cp[#cp+1] = spkt[i]
						end
					end
				end
				wipe(select_tb)
				profile.spam_filter_keywords = cp
			end
		},
		reset =
		{
			name = RESET,
			type = "execute",
			order = get_order(),
			func = function() wipe(select_tb) end
		},
		filters_s =
		{
			name = function()
				local kws = LookingForGroup.db.profile.spam_filter_keywords
				if kws == nil or #kws == 0 then
					return FILTERS
				else
					return tostring(#kws)
				end
			end,
			type = "multiselect",
			order = get_order(),
			values = function() return LookingForGroup.db.profile.spam_filter_keywords end,
			set = function(_,key,val)
				if val then
					select_tb[key] = true
				else
					select_tb[key] = nil
				end
			end,
			get = function(_,key)
				return select_tb[key]
			end,
			width = "full",
		},
		cpft =
		{
			order = get_order(),
			name = COPY_FILTER,
			type = "execute",
			func = function()
				LookingForGroup_Options.paste(LookingForGroup.db.profile,"spam_filter_keywords",true,"sf")
			end
		},
		language =
		{
			name = LANGUAGE,
			desc = L.language_sf_desc,
			type = "group",
			args =
			{
				enable =
				{
					name = ENABLE,
					desc = format(L.bwlist_desc,LANGUAGE,LANGUAGE,DISABLE),
					type = "toggle",
					order = get_order(),
					set = function(_,val)
						if val then
							LookingForGroup.db.profile.spam_filter_language = true
						elseif val == false then
							LookingForGroup.db.profile.spam_filter_language = nil
						else
							LookingForGroup.db.profile.spam_filter_language = false
						end
					end,
					get = function()
						local lg = LookingForGroup.db.profile.spam_filter_language
						if lg then
							return true
						elseif lg == false then
							return
						else
							return false
						end
					end,
					width = "full",
					tristate = true
				},
				language_english =
				{
					name = LFG_LIST_LANGUAGE_ENUS,
					type = "toggle",
					set = LookingForGroup_Options.set_function,
					get =LookingForGroup_Options.get_function,
				},
				language_chinese =
				{
					name = LFG_LIST_LANGUAGE_ZHCN,
					type = "toggle",
					set = LookingForGroup_Options.set_function,
					get =LookingForGroup_Options.get_function,
				},
				language_korean =
				{
					name = LFG_LIST_LANGUAGE_KOKR,
					type = "toggle",
					set = LookingForGroup_Options.set_function,
					get =LookingForGroup_Options.get_function,
				},
				language_russian =
				{
					name = LFG_LIST_LANGUAGE_RURU,
					type = "toggle",
					set = LookingForGroup_Options.set_function,
					get =LookingForGroup_Options.get_function,
				}
			}
		},
		addons =	IsAddOnLoaded("LookingForGroup_SF") and
		{
			name = ADDONS,
			type = "group",
			args =
			{
				add =
				{
					name = ADD,
					type = "input",
					order = get_order(),
					set = function(_,val)
						if val:len() == 0 then
							return
						end
						local tb = LookingForGroup.db.profile.addon_filters
						if tb == nil then
							tb = {}
						end
						tb[#tb+1] = val
						table.sort(tb)
						LookingForGroup.db.profile.addon_filters = tb
					end,
					get = nop,
					width = "full"
				},
				rmv =
				{
					name = REMOVE,
					type = "execute",
					order = get_order(),
					func = function()
						local profile = LookingForGroup.db.profile
						local spkt = profile.addon_filters
						local cp = {}
						for i = 1,#spkt do
							if select_tb[i]~=true then
								cp[#cp+1] = spkt[i]
							end
						end
						wipe(select_tb)
						if #cp ~= 0 then
							profile.addon_filters = cp
						end
					end
				},
				reset =
				{
					name = RESET,
					type = "execute",
					order = get_order(),
					func = function() wipe(select_tb) end
				},
				defaults =
				{
					name = DEFAULTS,
					type = "execute",
					order = get_order(),
					confirm = true,
					func = function()
						local db = LookingForGroup.db
						local profile = db.profile
						local default = db.defaults.profile.addon_filters
						local tb = {}
						for i=1,#default do
							tb[i] = default[i]
						end
						LookingForGroup.db.profile.addon_filters = tb
					end
				},
				whisper =
				{
					name = WHISPER,
					desc = L.sf_whisper_desc,
					type = "toggle",
					order = get_order(),
					set = function(_,v)
						if v then
							LookingForGroup.db.profile.addon_ft_whisper = v
						else
							LookingForGroup.db.profile.addon_ft_whisper = nil
						end
					end,
					get = function()
						return LookingForGroup.db.profile.addon_ft_whisper
					end
				},
				filters_s =
				{
					name = FILTERS,
					type = "multiselect",
					order = get_order(),
					values = function() return LookingForGroup.db.profile.addon_filters end,
					set = function(_,key,val)
						if val then
							select_tb[key] = true
						else
							select_tb[key] = nil
						end
					end,
					get = function(_,key)
						return select_tb[key]
					end,
					width = "full",
				},
				cpft =
				{
					order = get_order(),
					name = COPY_FILTER,
					type = "execute",
					func = function()
						LookingForGroup_Options.paste(LookingForGroup.db.profile,"addon_filters",false,"sf","addons")
					end
				}
			}
		} or nil,
		channel =
		{
			name = CHANNEL,
			type = "group",
			args =
			{
				spam_filter_disable =
				{
					name = DISABLE,
					type = "toggle",
					order = 1,
					get = LookingForGroup_Options.get_function,
					set = LookingForGroup_Options.set_function,
				},
				spam_filter_slash =
				{
					name = "/",
					type = "toggle",
					set = set_function_negative,
					get = get_function_negative,
				},
				spam_filter_community =
				{
					name = COMMUNITIES_CREATE_DIALOG_NAME_LABEL,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_spaces =
				{
					name = "[Space]",
					type = "toggle",
					get = LookingForGroup_Options.get_function,
					set = LookingForGroup_Options.set_function,
				},
				spam_filter_emote_xp =
				{
					name = EMOTE.." "..XP,
					type = "toggle",
					set = set_function_negative,
					get = get_function_negative
				},
				spam_filter_achievements =
				{
					name = ACHIEVEMENTS,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_quest =
				{
					name = BATTLE_PET_SOURCE_2,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_fast =
				{
					name = L.Fast,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_unknown =
				{
					name = UNKNOWN,
					type = "toggle",
					set = LookingForGroup_Options.set_function,
					get = LookingForGroup_Options.get_function
				},
				spam_filter_instance =
				{
					name = INSTANCE,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				reset =
				{
					name = RESET,
					type = "execute",
					order = -1,
					func = function()
						local db = LookingForGroup.db
						local t = {}
						for k,v in pairs(db.profile) do
							if not k:find("^spam_filter_") then
								t[k] = v
							end
						end
						db.profile = t
					end,
					width = "full"
				}
			}
		},
--[[		levenshtein =
		{
			name = L["Levenshtein Distance"],
			desc = L.levenshtein_desc,
			type = "group",
			args =
			{
				enable =
				{
					name = ENABLE,
					desc = L.enable_levenshtein_desc,
					type = "toggle",
					get = function(info)
						return LookingForGroup_Options.db.profile.spam_filter_levenshtein
					end,
					set = function(info,val)
						if val then
							LookingForGroup_Options.db.profile.spam_filter_levenshtein = true
						else
							LookingForGroup_Options.db.profile.spam_filter_levenshtein = nil
						end
					end
				},
				factor =
				{
					name = "α",
					type = "range",
					get = function(info)
						local factor = LookingForGroup_Options.db.profile.spam_filter_levenshtein_factor
						if factor then
							return factor
						else
							return 0.1
						end
					end,
					set = function(info,val)
						if val == 0.1 then
							LookingForGroup_Options.db.profile.spam_filter_levenshtein_factor = nil
						else
							LookingForGroup_Options.db.profile.spam_filter_levenshtein_factor = val
						end
					end,
					min = 0,
					max = 1,
					isPercent = true,
				},
				groups =
				{
					name = "n",
					desc = GROUPS,
					type = "range",
					get = function(info)
						local factor = LookingForGroup_Options.db.profile.spam_filter_levenshtein_groups
						if factor then
							return factor
						else
							return 2
						end
					end,
					set = function(info,val)
						if val == 2 then
							LookingForGroup_Options.db.profile.spam_filter_levenshtein_groups = nil
						else
							LookingForGroup_Options.db.profile.spam_filter_levenshtein_groups = val
						end
					end,
					min = 0,
					max = 100,
					step = 1,
				}
			}
		},]]
		invite =
		{
			name = INVITE,
			type = "group",
			args =
			{
				sf_invite_relationship =
				{
					name = FRIEND,
					desc = L.sf_invite_relationship_desc,
					get = get_function_negative,
					set = set_function_negative,
					type = "toggle"
				}
			}
		},
		advanced =
		{
			name = ADVANCED_LABEL,
			type = "group",
			order = -1,
			args =
			{
				spam_filter_dk = 
				{
					name = GetClassInfo(6),
					desc = L.sf_dk_desc,
					type = "toggle",
					set = options_set_function_negative,
					get = options_get_function_negative
				},
				spam_filter_solo = 
				{
					name = SOLO,
					desc = L.sf_solo,
					type = "toggle",
					set = options_set_function_negative,
					get = options_get_function_negative
				},
				spam_filter_auto_report =
				{
					name = L.auto_report,
					desc = L.auto_report_desc,
					type = "toggle",
					get = options_get_function_negative,
					set = options_set_function_negative
				},
				spam_filter_ignoreall =
				{
					name = ALL,
					desc = IGNORE,
					type = "toggle",
					get = function(info)
						return LookingForGroup_Options.spam_filter_ignore_all
					end,
					set = function(info,val)
						LookingForGroup_Options.spam_filter_ignore_all = val or nil
						LookingForGroup:SendMessage("LFG_CORE_FINALIZER",0)
					end
				},
				spam_filter_player_name =
				{
					name = CALENDAR_PLAYER_NAME,
					desc = L.sf_player_name_desc,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_ilvl =
				{
					name = ITEM_LEVEL_ABBR,
					desc = L.sf_ilvl,
					type = "toggle",
					get = options_get_function_negative,
					set = options_set_function_negative
				},
				spam_filter_activity =
				{
					name = LFG_LIST_ACTIVITY,
					type = "toggle",
					get = options_get_function_negative,
					set = options_set_function_negative
				},
				spam_filter_equal =
				{
					name = "=",
					type = "toggle",
					get = LookingForGroup_Options.options_get_function,
					set =LookingForGroup_Options.options_set_function
				},
				spam_filter_ages =
				{
					name = ACTION_SPELL_CREATE,
					type = "toggle",
					get = LookingForGroup_Options.options_get_function_negative,
					set =LookingForGroup_Options.options_set_function_negative
				}
			}
		}
	}
})
