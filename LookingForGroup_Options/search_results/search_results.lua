local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local select_sup = {}

LookingForGroup_Options.select_sup = select_sup

local function unregister_lfg_list_search_result_updated()
	LookingForGroup_Options:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
	LookingForGroup_Options:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
end

function LookingForGroup_Options.register_lfg_list_search_result_updated(control,update)
	control.OnRelease = unregister_lfg_list_search_result_updated
	LookingForGroup_Options:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",function(_,resultID)
		local children = control.children
		for i = 1,#children do
			local child = children[i]
			local udt = child:GetUserDataTable()
			if udt.val == resultID then
				update(child)
				return
			end
		end
		LookingForGroup_Options:SendMessage("LFG_SR_UPDATED",resultID)
	end)
	LookingForGroup_Options:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",function(_,resultID, newStatus, oldStatus)
		local children = control.children
		for i = 1,#children do
			local child = children[i]
			local udt = child:GetUserDataTable()
			if udt.val == resultID then
				if newStatus == "applied" then
					child:SetTriState(true)
					child:SetValue(nil)
					child:SetCallback("OnValueChanged",nop)
				elseif newStatus ~= "none" then
					update(child)
				end
				return
			end
		end
		LookingForGroup_Options:SendMessage("LFG_SR_UPDATED",resultID,newStatus,oldStatus)
	end)
end

local function GetApplications()
	local applications = C_LFGList.GetApplications()
	local n = #applications
	local GetApplicationInfo = C_LFGList.GetApplicationInfo
	local j = 1
	for i=1,n do
		local id, appStatus = GetApplicationInfo(applications[i])
		if appStatus == "applied" or appStatus == "invited" then
			applications[j] = id
			j = j + 1
		end
	end
	for i=n,j,-1 do
		applications[i] = nil
	end
	LookingForGroup_Options.applications_count = #applications
	return applications
end

function LookingForGroup_Options.Search(dialog_control,filter_options,
	category,filters,preferredfilters,asup_toggle,back_list,convert_to_custom,convert_from_custom,sign_up_func)
	local lfg_profile = LookingForGroup.db.profile
	local profile = LookingForGroup_Options.db.profile
	if asup_toggle == nil then
		asup_toggle = profile.a.signup
	end
	local hardware = lfg_profile.hardware
	local option_table_args = LookingForGroup_Options.option_table.args
	local current = coroutine.running()
	local function resume()
		LookingForGroup.resume(current)
	end
	local unsecure_state
	local yd,arg1,arg2,arg3,arg4,arg5 = 0
	local sign_up_coroutine

	local auto_sign_up =
	{
		order = 4,
		name = (LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")).Auto,
		desc = SIGN_UP,
		type = "toggle",
		width = 0.667
	}
	if hardware then
		function auto_sign_up.get() return asup_toggle end
		function auto_sign_up.set(t,val)
			asup_toggle = val
			if not asup_toggle then
				if sign_up_coroutine then
					LookingForGroup.resume(sign_up_coroutine)
				end
			end
			LookingForGroup.resume(current,0)
		end
	else
		auto_sign_up.tristate = true
		function auto_sign_up.get()
			if asup_toggle then
				return true
			elseif asup_toggle == false then
				return
			else
				return false
			end
		end
		local function event_register()
			local Event = LookingForGroup:GetModule("Event",true)
			if Event and asup_toggle then
				Event:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
			else
				Event:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
			end		
		end
		function auto_sign_up.set(t,val)
			if val then
				asup_toggle = true
			elseif val == false then
				asup_toggle = nil
			else
				asup_toggle = false
			end
			if not asup_toggle then
				if sign_up_coroutine then
					LookingForGroup.resume(sign_up_coroutine)
				end
			end
			event_register()
			LookingForGroup.resume(current,0)
		end
		event_register()
	end
	local args =
	{
		back = 
		{
			order = 1,
			name = BACK,
			type = "execute",
			func = resume,
			width = 0.667
		},
		search_again = 
		{
			order = 2,
			name = LFG_LIST_SEARCH_AGAIN,
			type = "execute",
			func = function()
				LookingForGroup.resume(current,0)
			end,
		},
		auto_sign_up = auto_sign_up
	}
	local ftrs
	local sign_up = 
	{
		order = 3,
		name = SIGN_UP,
		type = "execute",
		func = function()
			if ftrs then
				if sign_up_coroutine then
					if coroutine.status(sign_up_coroutine) ~= "dead" then
						return
					end
				end
				sign_up_coroutine = LookingForGroup_Options.signup_cofunc(select_sup,ftrs,convert_from_custom,false,sign_up_func)
			end
		end,
		width = 0.667
	}
	local search_config_tb =
	{
		name = KBASE_SEARCH_RESULTS,
		type = "group",
		childGroups = "tab",
		args = args
	}
	local results_t =
	{
		type = "multiselect",
		dialogControl = dialog_control,
		get = function(info,val)	return select_sup[val] end,
		width = "full"
	}
	local search_info =
	{
		type = "group",
		childGroups = "tab",
		order = 5,
		args ={results_t}
	}
	local function resume_1()
		LookingForGroup.resume(current,1)
	end
	LookingForGroup_Options:RegisterMessage("LFG_CORE_FINALIZER",resume)
	LookingForGroup_Options:RegisterMessage("LFG_ICON_MIDDLE_CLICK",resume)
	local count, results
	local timer
	local pending
	local none_format_concat = {}
	local C_LFGList = C_LFGList
	local bts,tb = {},{}
	local last_search_time = GetTime()
	local eventer = {}
	local function event_resume(...)
		LookingForGroup.resume(current,...)	
	end
	LookingForGroup_Options.RegisterEvent(eventer,"LFG_LIST_APPLICATION_STATUS_UPDATED",event_resume)
	LookingForGroup_Options.RegisterEvent(eventer,"LFG_LIST_JOINED_GROUP",event_resume)
	while true do
		if type(yd)~="number" then
			if yd ~= "LFG_LIST_APPLICATION_STATUS_UPDATED" then
				break
			end
			--event,applicationid,invited,applied
			if arg2 == "invited" then
				if sign_up_coroutine then
					LookingForGroup.resume(sign_up_coroutine)
				end
				if asup_toggle and not hardware then
					C_LFGList.AcceptInvite(arg1)
				end
			end
			yd = 10
		end
		local skip_yield
		repeat
		if yd < 2 then
			if sign_up_coroutine and coroutine.status(sign_up_coroutine) ~= "dead" then
				break
			end
			if yd == 1 and next(select_sup) then
				break
			end
			ftrs = nil
			if unsecure_state and last_search_time+(profile.background_period or 300)  < GetTime() then
				if LookingForGroup_Options.Background_Timer then
					LookingForGroup_Options.Background_Timer:Cancel()
					LookingForGroup_Options.Background_Timer = nil
				end
				if InCombatLockdown() then
					LookingForGroup_Options:RegisterEvent("PLAYER_REGEN_ENABLED",function(...)
						LookingForGroup.resume(current,...)
					end)
					yd,arg1,arg2,arg3,arg4,arg5=coroutine.yield()
					LookingForGroup_Options:UnregisterEvent("PLAYER_REGEN_ENABLED")
					if yd~="PLAYER_REGEN_ENABLED" then
						skip_yield = true
						break
					end
				end
				LookingForGroup.show_popup(LFG_LIST_SEARCH_AGAIN,{[0]=BACK,resume,OKAY,function() LookingForGroup.resume(current,0) end})
				yd,arg1,arg2,arg3,arg4,arg5=coroutine.yield()
				LookingForGroup.popup:Hide()
				if yd~=0 then
					skip_yield = true
					break
				end
				unsecure_state = nil
			end
			local elapse_time_start = GetTime()
			local error_msg
			if yd == 0 or not unsecure_state then
				if yd == 0 or option_table_args.search_result then
					args.results =
					{
						order = 4,
						name = SEARCHING,
						type = "description",
						width = "full"
					}
					args.sign_up = nil
					option_table_args.search_result = search_config_tb
					if yd == 0 and AceConfigDialog.OpenFrames.LookingForGroup then
						AceConfigDialog:SelectGroup("LookingForGroup","search_result")
					else
						LookingForGroup_Options.NotifyChangeIfSelected("search_result")
					end
				end
				LookingForGroup_Options.ExecuteSearchPattern(filter_options)
				count, results = LookingForGroup.Search(category,filters,preferredfilters)
				last_search_time = GetTime()
				wipe(select_sup)
				if count == 0 then
					error_msg = results and LFG_LIST_NO_RESULTS_FOUND or LFG_LIST_SEARCH_FAILED
					args.results =
					{
						order = 4,
						name = error_msg,
						type = "description",
						width = "full"
					}
					args.sign_up = nil
					results=nil
					option_table_args.search_result = search_config_tb
				end
				unsecure_state=hardware
			end
			if results then
				ftrs = LookingForGroup_Options.ExecuteFilter(bts,tb,results,filter_options,yd == 0)
				if LookingForGroup_Options.Background_Timer then
					LookingForGroup_Options.Background_Timer:Cancel()
					LookingForGroup_Options.Background_Timer = nil
				end
				LookingForGroup_Options.Background_Timer = C_Timer.NewTicker(#ftrs+10,resume_1)
				wipe(none_format_concat)
				if convert_to_custom then
					local cvt = convert_to_custom(ftrs)
					none_format_concat[#none_format_concat+1] = #cvt
					results_t.values = cvt
				else
					local applications = GetApplications()
					if #applications ~= 0 then
						none_format_concat[#none_format_concat+1] = #applications
					end
					none_format_concat[#none_format_concat+1] = #ftrs
					for i=1,#ftrs do
						applications[#applications+1]=ftrs[i]
					end
					results_t.values = applications
				end
				none_format_concat[#none_format_concat+1] = #results
				none_format_concat[#none_format_concat+1] = (#results ~= count and count) or nil
				none_format_concat[#none_format_concat+1] = string.format("%gs",GetTime()-elapse_time_start)
				search_info.name=table.concat(none_format_concat,"/")
				args.results = search_info
				option_table_args.search_result = search_config_tb
				if asup_toggle ~= nil then
					args.sign_up = nil
				else
					args.sign_up = sign_up
				end
			else
				if LookingForGroup_Options.Background_Timer then
					LookingForGroup_Options.Background_Timer:Cancel()
					LookingForGroup_Options.Background_Timer = nil
				end
				LookingForGroup_Options.Background_Timer = C_Timer.NewTicker(10,resume_1)
			end
			local isopen = AceConfigDialog.OpenFrames.LookingForGroup
			if yd == 0 and isopen then
				LookingForGroup_Options.NotifyChangeIfSelected("search_result")
				if (ftrs and #ftrs or 0) < (profile.background_counts or 1) then
					pending = true
				end
			else
				if isopen and LookingForGroup_Options.NotifyChangeIfSelected("search_result") then
					pending = nil
				elseif pending and ((profile.background_counts or 1)<= (ftrs and #ftrs or 0)) then
					if not lfg_profile.mute then
						PlaySound(SOUNDKIT.UI_GROUP_FINDER_RECEIVE_APPLICATION)
					end
					if lfg_profile.taskbar_flash then
						FlashClientIcon()
					end
					if not isopen and profile.background_popup then
						AceConfigDialog:SelectGroup("LookingForGroup","search_result")
						AceConfigDialog:Open("LookingForGroup")
					end
					LookingForGroup_Options.Background_Result = #ftrs
				end
			end
			if asup_toggle ~= nil and (ftrs and #ftrs ~= 0) and (not sign_up_coroutine or coroutine.status(sign_up_coroutine) == "dead") then
				sign_up_coroutine = LookingForGroup_Options.signup_cofunc(nil,ftrs,convert_from_custom,true,sign_up_func)
			end
		end
		until true
		if not skip_yield then
			yd,arg1,arg2,arg3,arg4,arg5=coroutine.yield()
		end
	end
	option_table_args.search_result = nil
	LookingForGroup_Options.Background_Result = nil
	C_LFGList.ClearSearchResults()
	if LookingForGroup_Options.Background_Timer then
		LookingForGroup_Options.Background_Timer:Cancel()
		LookingForGroup_Options.Background_Timer=nil
	end
	LookingForGroup_Options.UnregisterEvent(eventer,"LFG_LIST_APPLICATION_STATUS_UPDATED")
	LookingForGroup_Options.UnregisterEvent(eventer,"LFG_LIST_JOINED_GROUP")
	LookingForGroup_Options:UnregisterMessage("LFG_CORE_FINALIZER")
	local Event = LookingForGroup:GetModule("Event",true)
	if Event then
		Event:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
	end
	if sign_up_coroutine then
		LookingForGroup.resume(sign_up_coroutine)
	end
	if LookingForGroup_Options.IsSelected("search_result") then
		if back_list then
			AceConfigDialog:SelectGroup("LookingForGroup",unpack(back_list))
		else
			AceConfigDialog:SelectGroup("LookingForGroup","find","f")
		end
	else
		LibStub("AceConfigRegistry-3.0"):NotifyChange("LookingForGroup")
	end
end

local AceGUI = LibStub("AceGUI-3.0")
AceGUI:RegisterWidgetType("lfg_opt_sr_default_multiselect", function()
	local control = AceGUI:Create("InlineGroup")
	control.type = "lfg_opt_sr_default_multiselect"
	function control.OnAcquire()
		control:SetLayout("Flow")
		control.width = "fill"
		control.SetList = function(self,values)
			self.values = values
		end
		control.SetLabel = function(self,value)
			self:SetTitle(value)
		end
		control.SetDisabled = function(self,disabled)
			self.disabled = disabled
		end
		control.SetMultiselect = nop
		local applications_count = LookingForGroup_Options.applications_count
		control.SetItemValue = function(self,key)
			local val = self.values[key]
			local check = AceGUI:Create("LookingForGroup_search_result_checkbox")
			check:SetUserData("key", key)
			check:SetUserData("val", val)
			if applications_count and key <= applications_count then
				check:SetTriState(true)
				check:SetValue(nil)
				check:SetCallback("OnValueChanged",nop)
			else
				check:SetValue(select_sup[val])
				check:SetCallback("OnValueChanged",function(self,...)
					local user = self:GetUserDataTable()
					local v = user.val
					if select_sup[v] then
						select_sup[v] = nil
					else
						select_sup[v] = true
					end
					check:SetValue(select_sup[v])
				end)
			end
			LookingForGroup_Options.updatetitle(check)
			self:AddChild(check)
		end
		LookingForGroup_Options.register_lfg_list_search_result_updated(control,LookingForGroup_Options.updatetitle)
	end
	return AceGUI:RegisterAsContainer(control)
end , 1)
