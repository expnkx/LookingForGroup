local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup_Options = AceAddon:NewAddon("LookingForGroup_Options","AceEvent-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")

LookingForGroup_Options.option_table =
{
	type = "group",
	name = LFG_TITLE:gsub(" ","").." |cff8080cc"..GetAddOnMetadata("LookingForGroup","Version").."|r",
	args = {}
}

function LookingForGroup_Options:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LookingForGroup_OptionsDB",{profile ={a={},s={},window_height=600,window_width=840}},true)
end

local order = 0

function LookingForGroup_Options:push(key,val)
	if val.order == nil then
		val.order = order
		order = order + 1
	end
	self.option_table.args[key] = val
end

function LookingForGroup_Options.lfg_frame_is_open()
	return LibStub("AceConfigDialog-3.0").OpenFrames.LookingForGroup
end

function LookingForGroup_Options.expected(message)
	LookingForGroup_Options.lfg_frame_is_open():SetStatusText(message)
	PlaySound(882)
end

local function get_get_set_tb(tb,parameters)
	local t = tb
	for i = 1,#parameters do
		t=t[parameters[i]]
	end
	return t
end

local function generate_get_set(tb,parameters)
	if parameters == nil then
		parameters = {"db","profile"}
	end
	local function get(info)
		return get_get_set_tb(tb,parameters)[info[#info]]
	end
	local function set(info,val)
		if val then
			get_get_set_tb(tb,parameters)[info[#info]]=true
		else
			get_get_set_tb(tb,parameters)[info[#info]]=nil
		end
	end
	return get,set,function(info) return not get(info) end,function(info,val) set(info,not val) end
end

LookingForGroup_Options.get_function,LookingForGroup_Options.set_function,LookingForGroup_Options.get_function_negative,LookingForGroup_Options.set_function_negative=generate_get_set(LookingForGroup)

LookingForGroup_Options.options_get_function,LookingForGroup_Options.options_set_function,LookingForGroup_Options.options_get_function_negative,LookingForGroup_Options.options_set_function_negative=generate_get_set(LookingForGroup_Options)

LookingForGroup_Options.options_get_a_function,LookingForGroup_Options.options_set_a_function,LookingForGroup_Options.options_get_a_function_negative,LookingForGroup_Options.options_set_a_function_negative=generate_get_set(LookingForGroup_Options,{"db","profile","a"})

LookingForGroup_Options.options_get_s_function,LookingForGroup_Options.options_set_s_function,LookingForGroup_Options.options_get_s_function_negative,LookingForGroup_Options.options_set_s_function_negative=generate_get_set(LookingForGroup_Options,{"db","profile","s"})

function LookingForGroup_Options.IsSelected(groupname)
	local status_table = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
	if status_table.groups and status_table.groups.selected == groupname then
		return true
	end
end

function LookingForGroup_Options.NotifyChangeIfSelected(groupname)
	if LookingForGroup_Options.IsSelected(groupname) then
		LibStub("AceConfigRegistry-3.0"):NotifyChange("LookingForGroup")
		return true
	end
end

function LookingForGroup_Options.Register(table_name,filtername,func)
	local tbl = LookingForGroup_Options[table_name]
	if tbl == nil then
		tbl = {}
	end
	if filtername then
		local tblf = tbl[filtername]
		if tblf == nil then
			tbl[filtername] = {func}
		else
			tblf[#tblf+1] = func
		end
	else
		tbl[#tbl+1] = func
	end
	LookingForGroup_Options[table_name] = tbl
end

LookingForGroup_Options.Register("category_callbacks",nil,function()
	local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
	local db = LookingForGroup_Options.db
	local profile = db.profile
	local default = db.defaults.profile
	st.height,st.width = profile.window_height or default.window_height,profile.window_width or default.window_width
	st.left,st.top = profile.window_left,profile.window_top
end)

function LookingForGroup_Options:OnEnable()
	local options = LookingForGroup_Options.option_table
	LibStub("AceConfig-3.0"):RegisterOptionsTable("LookingForGroup", options)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	self:RegisterMessage("LFG_ICON_LEFT_CLICK")
	self:RegisterMessage("LFG_ChatCommand")
	if self.options_onenable then
		self:options_onenable()
	end
	self:OnProfileChanged()
	self.option_table.args.settings=
	{
		name = SETTINGS,
		type = "group",
		args =
		{
			enable =
			{
				name = ENABLE,
				type = "execute",
				func = function()
					LoadAddOn("LookingForGroup_Settings")
					collectgarbage("collect")
					LookingForGroup_Options:SendMessage("LFG_SETTINGS_ENABLED")
				end
			}
		}
	}
	self.OnEnable = nil
	self.OnInitialize = nil
end

function LookingForGroup_Options.OnProfileChanged(update_db)
	local type = type
	local category=LookingForGroup_Options.db.profile.a.category
	local category_callbacks = LookingForGroup_Options.category_callbacks
	local fd = LookingForGroup_Options.option_table.args.find
	local find_args
	local f_args,s_args
	if fd then
		find_args = fd.args
		f_args,s_args = find_args.f.args.opt.args,find_args.s.args.opt.args
	end
	for i=1,#category_callbacks do
		local ci = category_callbacks[i]
		if type(ci) == "table" then
			local ok = #ci < 3
			if not ok then
				for j=3,#ci do
					if ci[j] == category then
						ok = true
					end
				end
			end
			if ok then
				ci[1](find_args,f_args,s_args,category)
			else
				ci[2](find_args,f_args,s_args,category)
			end
		elseif update_db then
			ci()
		end
	end
end

function LookingForGroup_Options:LFG_ChatCommand(message,input)
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):Open("LookingForGroup")
	else
		LibStub("AceConfigCmd-3.0"):HandleCommand("LookingForGroup", "LookingForGroup",input)
	end
end

function LookingForGroup_Options:LFG_ICON_LEFT_CLICK(message,para,...)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	if AceConfigDialog.OpenFrames.LookingForGroup then
		AceConfigDialog:Close("LookingForGroup")
	else
		if para then
			AceConfigDialog:SelectGroup(para,...)
		end
		AceConfigDialog:Open("LookingForGroup")
	end
end