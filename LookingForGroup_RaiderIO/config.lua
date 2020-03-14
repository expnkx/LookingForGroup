local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local LFG_RIO = LFG_OPT:NewModule("RaiderIO","AceEvent-3.0")

LFG_OPT:push("rioffline",{
	name = "IO "..PLAYER_OFFLINE,
	type = "group",
	args =
	{
		search =
		{
			name = SEARCH,
			get = function()
				return LFG_OPT.raider_io_name
			end,
			set = function(_,v)
				if v=="" then
					LFG_OPT.raider_io_name = nil
				else
					LFG_OPT.raider_io_name = v				
				end
			end,
			type = "input",
			order = 1,
			width = 2,
		},
		region =
		{
			name = "Region",
			type = "select",
			values = {"US","KR","EU","TW","CN"},
			get = function()
				return LFG_OPT.db.profile.io_region or GetCurrentRegion()
			end,
			set = function(info,v)
				local profile = LFG_OPT.db.profile
				local io_region = profile.io_region
				if v == GetCurrentRegion() then
					profile.io_region = nil
				else
					profile.io_region = v
				end
				ReloadUI()
			end,
			order = 2,
			confirm = true
		},
		desc = 
		{
			name = nop,
			type = "multiselect",
			values = nop,
			control = "LFG_RIO_INDICATOR",
			width = "full",
		},
	}
})

LFG_OPT.Register("category_callbacks",nil,{function(find_args,f_args,s_args)
	f_args.rio_min_score =
	{
		name = "IO "..MINIMUM,
		type = "input",
		order = 1,
		get = function(info)
			local val = LFG_OPT.db.profile[info[#info]]
			if val then
				return tostring(val)
			end
		end,
		set = function(info,val)
			if val == "" then
				LFG_OPT.db.profile[info[#info]] = nil
			else
				LFG_OPT.db.profile[info[#info]] = tonumber(val)
			end
		end,
		pattern = "^[0-9]*$"
	}
	f_args.rio_max_score =
	{
		name = "IO "..MAXIMUM,
		type = "input",
		order = 2,
		get = f_args.rio_min_score.get,
		set = f_args.rio_min_score.set,
		pattern = "^[0-9]*$"
	}
	s_args.rio_min_score=f_args.rio_min_score
	s_args.rio_max_score=f_args.rio_max_score
	s_args.rio_elitist_level =
	{
		name = "Elitist M+",
		type = "input",
		get = f_args.rio_min_score.get,
		set = f_args.rio_min_score.set,
		pattern = "^[0-9]*$"
	}
end,function(find_args,f_args,s_args)
	f_args.rio_min_score = nil
	f_args.rio_max_score = nil
	s_args.rio_min_score = nil
	s_args.rio_max_score= nil
	s_args.rio_elitist_level = nil
end,2})

LFG_OPT.Register("category_callbacks",nil,{function(find_args,f_args,s_args,category)
	f_args.rio_elite =
	{
		name = "Elite",
		type = "toggle",
		get = LFG_OPT.options_get_function,
		set = LFG_OPT.options_set_function,
	}
	if category == 3 then
		s_args.rio_elite = f_args.rio_elite
	else
		s_args.rio_elite = nil
	end
end,function(find_args,f_args,s_args)
	f_args.rio_elite = nil
	s_args.rio_elite = nil
end,2,3})

LFG_OPT.Register("category_callbacks",nil,{function(find_args,f_args,s_args,category)
	f_args.rio_disable =
	{
		name = DISABLE.." Raider.IO",
		type = "toggle",
		get = LFG_OPT.options_get_function,
		set = LFG_OPT.options_set_function,
	}
	s_args.rio_disable = f_args.rio_disable
end})
