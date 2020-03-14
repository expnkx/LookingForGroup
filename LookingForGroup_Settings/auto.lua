local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")

local select_tb = {}

LookingForGroup_Options:push_settings("auto",
{
	name = L.Auto,
	type = "group",
	args =
	{
		disable_auto =
		{
			name = DISABLE,
			desc = L.auto_disable_desc,
			type = "toggle",
			get = LookingForGroup_Options.get_function,
			set = LookingForGroup_Options.set_function
		},
		leave_party =
		{
			name = PARTY_LEAVE,
			desc = L.auto_leave_party_desc,
			type = "toggle",
			get = function(info)
				local val = LookingForGroup.db.profile.auto_leave_party
				if val then
					return true
				elseif val == nil then
					return false
				end
			end,
			set = function(info,val)
				if val then
					LookingForGroup.db.profile.auto_leave_party = true
				elseif val == false then
					LookingForGroup.db.profile.auto_leave_party = nil
				else
					LookingForGroup.db.profile.auto_leave_party = false
				end
			end,
			tristate = true
		},
		auto_find_a_group =
		{
			name = FIND_A_GROUP,
			desc = L.options_auto_fnd_desc,
			type = "toggle",
			get = function(info)
				return LookingForGroup.db.profile.auto_find_a_group
			end,
			set = function(info,val)
				local profile = LookingForGroup.db.profile
				if not profile.hardware then
					if val then
						LookingForGroup.db.profile.auto_find_a_group = true
					else
						LookingForGroup.db.profile.auto_find_a_group = nil
					end
				end
			end,
		},
		auto_start_a_group =
		{
			name = START_A_GROUP,
			desc = L.options_auto_start_desc,
			type = "toggle",
			tristate = true,
			get = function(info)
				local val = LookingForGroup.db.profile.auto_start_a_group
				if val then
					return true
				elseif val == nil then
					return false
				end
			end,
			set = function(info,val)
				if val then
					LookingForGroup.db.profile.auto_start_a_group = true
				elseif val == false then
					LookingForGroup.db.profile.auto_start_a_group = nil
				else
					LookingForGroup.db.profile.auto_start_a_group = false
				end
			end,
		},
		auto_show_nameplate =
		{
			name = OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_FRIENDS,
			type = "toggle",
			get = LookingForGroup_Options.get_function_negative,
			set = LookingForGroup_Options.set_function_negative
		},
		auto_convert_to_raid =
		{
			name = CONVERT_TO_RAID,
			type = "toggle",
			get = LookingForGroup_Options.get_function_negative,
			set = LookingForGroup_Options.set_function_negative
		},
--[[		ilvl =
		{
			name = ITEM_LEVEL_ABBR,
			desc = LFG_LIST_ITEM_LEVEL_REQ,
			type = "input",
			get = function()
				local ilv = LookingForGroup.db.profile.auto_ilvl
				if ilv then
					return tostring(ilv)
				end
			end,
			set = function(_,val)
				if val == "" then
					LookingForGroup.db.profile.auto_ilvl = nil
				else
					local num = tonumber(val)
					local average = GetAverageItemLevel() - 2
					if num <= average then
						LookingForGroup.db.profile.auto_ilvl = num
					else
						LookingForGroup.db.profile.auto_ilvl = math_floor(average)
					end
				end
			end,
			pattern = "^[0-9]*$"
		},]]
		auto_kick =
		{
			name = "Kick",
			type = "toggle",
			get = LookingForGroup_Options.get_function_negative,
			set = LookingForGroup_Options.set_function_negative
		},
		
--[[		auto_use_name =
		{
			name = L.auto_use_name,
			desc = L.auto_use_name_desc,
			get = function()
				return LookingForGroup.db.profile.auto_use_name
			end,
			set = function(info,val)
				if val then
					LookingForGroup.db.profile.auto_use_name = true
				else
					LookingForGroup.db.profile.auto_use_name = nil
				end			
			end,
			type = "toggle"
		},]]
		auto_no_info_quest =
		{
			name = L.auto_no_info_quest,
			desc = L.auto_no_info_quest_desc,
			type = "toggle",
			get = LookingForGroup_Options.get_function,
			set = LookingForGroup_Options.set_function
		},
		auto_wq_only =
		{
			name = format(L.auto_wq_only_desc,TRACKER_HEADER_WORLD_QUESTS),
			type = "toggle",
			get = LookingForGroup_Options.get_function,
			set = LookingForGroup_Options.set_function
		},
		auto_ccqg =
		{
			name = "CanCreateQuestGroup",
			type = "toggle",
			get = LookingForGroup_Options.get_function,
			set = LookingForGroup_Options.set_function
		},
		mtq = 
		{
			name = ID,
			desc = TRANSMOG_SOURCE_2,
			set = function(_,val)
				LookingForGroup:loadevent("LookingForGroup_Q","LFG_SECURE_QUEST_ACCEPTED",tonumber(val))
			end,
			pattern = "^[0-9]+$",
			order = -1,
			type = "input"
		},
		addons =
		{
			name = ADDONS,
			type = "group",
			args =
			{
				auto_addons_wql =
				{
					name = "World Quests List",
					type = "toggle",
					get = LookingForGroup_Options.get_function,
					set = LookingForGroup_Options.set_function
				},
				auto_addons_wqt =
				{
					name = "Invite Nearby",
					type = "toggle",
					get = LookingForGroup_Options.get_function_negative,
					set = LookingForGroup_Options.set_function_negative
				},
--[[				WQP =
				{
					name = "World Quest Party",
				}]]
			}
		},
		quests =
		{
			name = BATTLE_PET_SOURCE_2,
			type = "group",
			args =
			{
				add =
				{
					name = ADD,
					type = "input",
					order = 1,
					set = function(_,val)
						local k = tonumber(val)
						if k then
							local profile = LookingForGroup.db.profile
							local q = profile.q
							if q then
								q[k] = true
							else
								profile.q = {[k] = true}
							end
						end
					end,
					get = nop,
					width = "full",
					pattern = "^[0-9]*$",
				},
				rmv =
				{
					name = REMOVE,
					type = "execute",
					order = 2,
					func = function()
						local db = LookingForGroup.db
						local profile = db.profile
						local q = profile.q
						if q then
							local default = db.defaults.profile.q
							if default then
								for k,v in pairs(select_tb) do
									if default[k] then
										q[k] = false
									else
										q[k] = nil
									end
								end
							else
								for k,v in pairs(select_tb) do
									q[k] = nil
								end
								if next(q) == nil then
									profile.q = nil
								end
							end
						end
						wipe(select_tb)
					end
				},
				reset =
				{
					name = RESET,
					type = "execute",
					order = 3,
					func = function() wipe(select_tb) end
				},
				defaults =
				{
					name = DEFAULTS,
					type = "execute",
					order = 4,
					confirm = true,
					func = function()
						local db = LookingForGroup.db
						local profile = db.profile
						local tb = {}
						local default = db.defaults.profile.q
						if default then
							for k,v in pairs(default) do
								tb[k] = true
							end
						end
						LookingForGroup.db.profile.q = tb
					end
				},
				filters_s =
				{
					name = FILTERS,
					type = "multiselect",
					order = 5,
					values = function()
						local q = LookingForGroup.db.profile.q
						if q then
							local quests_names = {}
							local GetQuestInfoByQuestID = C_TaskQuest.GetQuestInfoByQuestID
							for k,v in pairs(q) do
								if v then
									local questName = GetQuestInfoByQuestID(k)
									if questName == nil then
										local GetQuestLogTitle = GetQuestLogTitle
										for i=1,GetNumQuestLogEntries() do
											local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(i)
											if questID == k then
												questName = title
												break
											end
										end
									end
									quests_names[k] = questName and table.concat{"[",k,"] ",questName} or k
								end
							end
							return quests_names
						end
					end,
					set = function(_,key,val)
						select_tb[key] = val or nil
					end,
					get = function(_,key)
						return select_tb[key]
					end,
					width = "full",
				},
			}
		},
	}
})
