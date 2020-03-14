local LibStub = LibStub
local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options")
local LookingForGroup_AV = AceAddon:GetAddon("LookingForGroup_AV")
local C_LFGList_ClearSearchResults = C_LFGList.ClearSearchResults
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local string_find = string.find
local string_gsub = string.gsub
local string_lower = string.lower

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

local order = 0
local function get_order()
	local temp = order
	order = order + 1
	return temp
end

LookingForGroup_Options.RegisterSearchPattern("av",function(profile,a,category)
	C_LFGList.ClearSearchTextFields()
	C_LFGList.SetSearchToActivity(44)
end)

local function do_search()
	coroutine.wrap(function()
		local activity_name = C_LFGList.GetActivityInfo(44)
		LookingForGroup_Options.Search(
		"lfg_opt_sr_default_multiselect",
		nil,
		do_search,
		{"spam","av"},
		3,nil,LE_LFG_LIST_FILTER_NOT_RECOMMENDED,0,nil,nil,nil,{"av"})
	end)()
end
local concat_tb = {}
local class_table = LOCALIZED_CLASS_NAMES_FEMALE

local start_av = LookingForGroup_Options.option_table.args.find.args.s

local original_start_func = start_av.args.start.func
start_av.args.start.func = function(tb)
	if tb[1] == "av" then
		local profile = LookingForGroup_Options.db.profile
		LookingForGroup_Options.listing(44,profile.s,{"s"},{"av","s"},LookingForGroup_AV)
	else
		original_start_func(tb)
	end
end

local function av_rl_command(...)				
	local profile = LookingForGroup_AV.db.profile
	if profile.role == 2 then
		local serialize = LookingForGroup_AV:Serialize(2,...)
		local LookingForGroup_AV_SendCommand = LookingForGroup_AV.SendCommand
		local parties = profile.parties
		local k,v
		for k,v in pairs(parties) do
			LookingForGroup_AV_SendCommand(LookingForGroup_AV,serialize,"WHISPER",k)
		end
	end
end

local string_format = string.format
local math_floor = math.floor

local function convert_ms_to_xx_xx_xx_xx(value)
	value = math_floor(value)
	local hour = value / 3600000
	local min_sec_ms = value % 3600000
	local minute = min_sec_ms / 60000
	local sec_ms = min_sec_ms % 60000
	local sec = sec_ms / 1000
	local ms = sec_ms % 1000
	return string_format("%02d:%02d:%02d.%03d",hour,minute,sec,ms)
end


local function convert_name(name)
	return string.upper(string.sub(name,1,1))..string.lower(string.sub(name,2,-1))
end

local select_tb = {}
local party_tb = {}

LookingForGroup_Options:push("av",{
	name = C_Map.GetMapInfo(91).name,
	type = "group",
	args =
	{
		search =
		{
			order = get_order(),
			name = LFG_LIST_FIND_A_GROUP,
			type = "execute",
			func = do_search,
		},
		start_a_g =
		{
			order = get_order(),
			name = START_A_GROUP,
			type = "execute",
			func = function()
				local status,LookingForGroup_AV = pcall(AceAddon.GetAddon,AceAddon,"LookingForGroup_AV")
				if status then
					LookingForGroup_Options.option_table.args.av.args.s = start_av
					AceConfigDialog:SelectGroup("LookingForGroup","av","s")
				end
			end,
		},
		disban =
		{
			order = get_order(),
			name = RESET,
			desc = TEAM_DISBAND,
			type = "execute",
			confirm = true,
			func = function()
				LookingForGroup_AV.rl_disban()
				wipe(select_tb)
			end,
		},
		start =
		{
			order = get_order(),
			name = START,
			type = "execute",
			func = function()
				local LookingForGroup_AV = AceAddon:GetAddon("LookingForGroup_AV")
				LookingForGroup_AV.Start()
			end
		},
		raid_leader =
		{
			order = get_order(),
			type = "input",
			name = RAID_LEADER,
			get = function()
				local LookingForGroup_AV = AceAddon:GetAddon("LookingForGroup_AV")
				local rl = LookingForGroup_AV.db.profile.raid_leader
				if rl then
					return rl
				end
			end,
			set = function(_,val)
				local LookingForGroup_AV = AceAddon:GetAddon("LookingForGroup_AV")
				local profile = LookingForGroup_AV.db.profile
				if profile.role == 0 then
					if val and not string_find(val,'-') then
						val = convert_name(val)
						local name = UnitFullName("player")
						profile.raid_leader = val
						if name == val then
							profile.role = 2
						else
							profile.role = 1
							LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(3,4),"WHISPER",val)
						end
					end
				end
			end
		},
		parties =
		{
			name = PARTY_MEMBERS,
			type = "group",
			args =
			{
				roleconfirm =
				{
					order = get_order(),
					name = ROLE_POLL,
					type = "execute",
					func = function() av_rl_command(3) end,
					width = "full"
				},
				leave_queue =
				{
					order = get_order(),
					name = LEAVE_QUEUE,
					type = "execute",
					confirm = true,
					func = function()
						av_rl_command(6)
					end,
				},
				join_battle =
				{
					order = get_order(),
					name = BATTLEFIELD_JOIN,
					type = "execute",
					confirm = true,
					func = function()
						av_rl_command(7)
					end,
				},
				parties =
				{
					order = get_order(),
					name = " ",
					type = "multiselect",
					order = get_order(),
					values = nop,
					width = "full",
					dialogControl = "LFG_OPT_av_parties_multiselect"
				}
			},
		},
		status =
		{
			name = STATUS,
			type = "group",
			args =
			{
				add =
				{
					order = get_order(),
					type = "input",
					name = ADD,
					get = function()
					end,
					set = function(_,val)
						local profile = LookingForGroup_AV.db.profile
						if profile.role == 2 then
							if val and not string_find(val,'-') then
								val = convert_name(val)
								profile.parties[val] = {}
								profile.status[val] = {}
								LookingForGroup_AV:SendCommand(LookingForGroup_AV:Serialize(2,8),"WHISPER",val)
							end
						end
					end
				},
				rem =
				{
					order = get_order(),
					type = "execute",
					name = REMOVE,
					func = function()
						local LookingForGroup_AV = AceAddon:GetAddon("LookingForGroup_AV")
						local profile = LookingForGroup_AV.db.profile
						for k,v in pairs(select_tb) do
							if v then
								profile.parties[k] = nil
								profile.status[k] = nil
							end
						end
						wipe(select_tb)
					end
				},
				rest =
				{
					order = get_order(),
					type = "execute",
					name = RESET,
					func = function()
						wipe(select_tb)
					end
				},
				prty =
				{
					type = "multiselect",
					order = get_order(),
					name = PARTY,
					width = "full",
					values = function()
						local LookingForGroup_AV = AceAddon:GetAddon("LookingForGroup_AV")
						local profile = LookingForGroup_AV.db.profile
						local parties = profile.parties
						wipe(party_tb)
						for k,v in pairs(parties) do
							party_tb[k] = k
						end
						return party_tb
					end,
					get = function(_,key)
						return select_tb[key]
					end,
					set = function(_,key,val)
						if val then
							select_tb[key] = true
						else
							select_tb[key] = nil
						end
					end
				},
				potentials =
				{
					name = " ",
					type = "multiselect",
					order = get_order(),
					values = function()
						return LookingForGroup_AV.db.profile.potentials
					end,
					width = "full",
					set = nop,
					get = nop,
				}
			}
		}
	}
})

local function geticon(icon)
	if role == "DAMAGER" then
		return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t"
	elseif role == "HEALER" then
		return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t"
	elseif role == "TANK" then
		return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t"
	end
end

local AceGUI = LibStub("AceGUI-3.0")
AceGUI:RegisterWidgetType("LFG_OPT_av_parties_multiselect", function()
	local control = AceGUI:Create("InlineGroup")
	control.type = "LFG_OPT_av_parties_multiselect"
	function control.OnAcquire()
		control:SetLayout("Flow")
		control.width = "fill"
		control.SetList = nop
		control.SetLabel = nop
		control.SetDisabled = nop
		control.SetMultiselect = nop
		control.SetItemValue = nop
		local ticker
		ticker = C_Timer.NewTicker(0,function()
			control:ReleaseChildren()
			if not LookingForGroup_Options.IsSelected("av\1parties") then
				ticker:Cancel()
				return
			end
			local profile = AceAddon:GetAddon("LookingForGroup_AV").db.profile
			local status = profile.status
			local gtime = GetTime()
			local refresh
			for k,v in pairs(profile.parties) do
				local interactivelabel = AceGUI:Create("InteractiveLabel")
				wipe(concat_tb)
				concat_tb[#concat_tb+1] = k
				concat_tb[#concat_tb+1] = '\n'
				local status_k = status[k]
				if status_k then
					local st = status_k[1]
					if st == 0 then
						concat_tb[#concat_tb+1] = AVERAGE_WAIT_TIME
						local average_wt = status_k[3]
						local wait_time = status_k[4]+(gtime-status_k[2])*1000
						if average_wt then
							concat_tb[#concat_tb+1] = convert_ms_to_xx_xx_xx_xx(average_wt)
							concat_tb[#concat_tb+1] = '\n'
							if wait_time < average_wt then
								concat_tb[#concat_tb+1] = TIME_REMAINING
								concat_tb[#concat_tb+1] = convert_ms_to_xx_xx_xx_xx(average_wt-wait_time)
								concat_tb[#concat_tb+1] = '\n'
							end
						end
						concat_tb[#concat_tb+1] = format(TIME_IN_QUEUE,convert_ms_to_xx_xx_xx_xx(wait_time))
						concat_tb[#concat_tb+1] = '\n'
					elseif st == 1 then
						concat_tb[#concat_tb+1] = TIME_REMAINING
						concat_tb[#concat_tb+1] = convert_ms_to_xx_xx_xx_xx(status_k[3]-(gtime-status_k[2])*1000)
						concat_tb[#concat_tb+1] = '\n'
					end
					refresh = true
				end
				for i=1,#v do
					local vi = v[i]
					local class = vi[3]
					concat_tb[#concat_tb+1] = "|c"
					concat_tb[#concat_tb+1] = CLASS_COLORS[class].colorStr
					concat_tb[#concat_tb+1] = vi[1]
					concat_tb[#concat_tb+1] = ' '
					concat_tb[#concat_tb+1] = class_table[class]
					concat_tb[#concat_tb+1] = '|r '
					concat_tb[#concat_tb+1] = geticon(vi[2])
					concat_tb[#concat_tb+1] = '\n'
				end
				interactivelabel:SetText(table.concat(concat_tb))
				control:AddChild(interactivelabel)
			end
		end)
		end
	return AceGUI:RegisterAsContainer(control)
end , 1)
