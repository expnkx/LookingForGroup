local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")

local order = 0
local function get_order()
	local temp = order
	order = order +1
	return temp
end

local sort_values = {ID,LFG_LIST_ACTIVITY,LFG_LIST_TITLE,LFG_LIST_DETAILS,VOICE_CHAT,LFG_LIST_ITEM_LEVEL_INSTR_SHORT,LFG_LIST_HONOR_LEVEL_INSTR_SHORT,ACTION_SPELL_CREATE,BATTLETAG,CHARACTER,GUILD,UNLIST_MY_GROUP,LEADER,MEMBERS,LFG_LIST_AUTO_ACCEPT,BATTLE_PET_SOURCE_2}

local select_tb = {}

LookingForGroup_Options:push_settings("sort",
{
	name = RAID_FRAME_SORT_LABEL,
	desc = KBASE_SEARCH_RESULTS,
	type = "group",
	args =
	{
		filter =
		{
			order = get_order(),
			name = FILTER,
			type = "select",
			values = sort_values,
			set = function(_,val)
				LookingForGroup_Options.db.profile.sortfilter = val
			end,
			get = function(info) return LookingForGroup_Options.db.profile.sortfilter end,
			width = "full",
		},
		revs = 
		{
			name = "-",
			type = "toggle",
			order = get_order(),
			get = function(info)
				return LookingForGroup_Options.db.profile.sortby_revs
			end,
			set = function(info,val)
				if val then
					LookingForGroup_Options.db.profile.sortby_revs = true
				else
					LookingForGroup_Options.db.profile.sortby_revs = nil
				end
			end
		},
		shuffle = 
		{
			name = "Shuffle",
			desc = L.options_sort_shuffle_desc,
			type = "toggle",
			order = get_order(),
			get = function(info)
				return LookingForGroup_Options.db.profile.sortby_shuffle
			end,
			set = function(info,val)
				if val then
					LookingForGroup_Options.db.profile.sortby_shuffle = true
				else
					LookingForGroup_Options.db.profile.sortby_shuffle = nil
				end
			end
		},
		add =
		{
			name = ADD,
			type = "execute",
			order = get_order(),
			func = function(_,val)
				local profile = LookingForGroup_Options.db.profile
				local sortfilter = profile.sortfilter
				if sortfilter then
					local tb = profile.sort
					if tb == nil then
						tb = {}
					end
					if profile.sortby_revs then
						tb[#tb+1] = -sortfilter
					else
						tb[#tb+1] = sortfilter
					end
					profile.sort = tb
				end
			end,
		},
		rmv =
		{
			name = REMOVE,
			type = "execute",
			order = get_order(),
			func = function()
				local profile = LookingForGroup_Options.db.profile
				local spkt = profile.sort
				if spkt then
					local cp = {}
					local i
					local n = #spkt
					for i = 1,n do
						if select_tb[i]~=true then
							cp[#cp+1] = spkt[i]
						end
					end
					wipe(select_tb)
					if #cp == 0 then
						profile.sort = nil
					else
						profile.sort = cp
					end
				end
			end
		},
		reset =
		{
			name = RESET,
			type = "execute",
			order = get_order(),
			func = function()
				local profile = LookingForGroup_Options.db.profile
				profile.sortby_revs = nil
				profile.sortfilter = nil
				wipe(select_tb)
			end
		},
		filters_s =
		{
			name = FILTERS,
			type = "multiselect",
			order = get_order(),
			values =
			function()
				local sort = LookingForGroup_Options.db.profile.sort
				if sort and #sort ~= 0 then
					local v = {}
					for i=1,#sort do
						local ele = sort[i]
						if ele<0 then
							v[i] = sort_values[-ele].."(-)"
						else
							v[i] = sort_values[ele]
						end
					end
					return v
				end
			end,
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
		resetc =
		{
			order = -1,
			name = RESET,
			type = "execute",
			func = function()
				LookingForGroup_Options.db.profile.sort = nil
				wipe(select_tb)
			end,
			width = "full"
		},
	}
})
