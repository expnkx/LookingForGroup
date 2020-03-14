local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local mplus_name,label_name = C_LFGList.GetActivityInfo(459) -- "Eye of Azshara (Mythic Keystone)"

LFG_OPT.mythic_keystone = mplus_name:sub(C_LFGList.GetActivityGroupInfo(112):len()+1)
LFG_OPT.mythic_keystone_label_name = label_name

LFG_OPT.Register("category_callbacks",nil,{function(find_args,f_args,s_args)
	f_args.mplus =
	{
		name = label_name,
		type = "toggle",
		get = LFG_OPT.options_get_function,
		set = LFG_OPT.options_set_function
	}
end,function(find_args,f_args,s_args)
	f_args.mplus=nil
end,2})

LFG_OPT.RegisterSimpleFilter("find",function(info)
	local fullName, shortName = C_LFGList.GetActivityInfo(info.activityID)
	if shortName ~= label_name then
		return 1
	end
end,function(profile)
	local a = profile.a
	return a.category == 2 and profile.mplus
end)
