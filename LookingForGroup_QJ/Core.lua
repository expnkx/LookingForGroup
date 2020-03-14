local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options")
local AceGUI = LibStub("AceGUI-3.0")

local select_sup = {}
local social_tb = {}
local filter_options = {"spam"}

local function social_queue_update()
	local all_groups = C_SocialQueue.GetAllGroups(false)
	local C_SocialQueue_GetGroupQueues = C_SocialQueue.GetGroupQueues
	local filter = LookingForGroup_Options.ExecuteSimpleFilter
	local results = {}
	for i = 1, #all_groups do
		local ai = all_groups[i]
		local queues = C_SocialQueue_GetGroupQueues(ai)
		if queues then
			local q1 = queues[1]
			if q1 then
				local queue_data = q1.queueData
				if queue_data then
					local lfgListID = queue_data.lfgListID
					if lfgListID then
						results[#results+1] = lfgListID
					end
				end
			end
		end
	end
	local bts = {}
	local tb = LookingForGroup_Options.ExecuteFilter(bts,{},results,filter_options)
	wipe(bts)
	for i=1,#tb do
		bts[tb[i]] = true
	end
	wipe(social_tb)
	for i = 1, #all_groups do
		local ai = all_groups[i]
		local queues = C_SocialQueue_GetGroupQueues(ai)
		if queues then
			local q1 = queues[1]
			if q1 then
				local queue_data = q1.queueData
				if queue_data then
					local lfgListID = queue_data.lfgListID
					if lfgListID then
						if bts[lfgListID] then
							social_tb[#social_tb+1]=ai
						end
					else
						social_tb[#social_tb+1]=ai
					end
				end
			end
		end
	end
	LookingForGroup_Options.NotifyChangeIfSelected("quick_join")
end

if LookingForGroup_Options.db.profile.qj then
	LookingForGroup_Options:RegisterEvent("SOCIAL_QUEUE_UPDATE",social_queue_update)
	social_queue_update()
end

local function signup_func(comment_text)
	local C_SocialQueue_GetGroupQueues = C_SocialQueue.GetGroupQueues
	local C_SocialQueue_RequestToJoin = C_SocialQueue.RequestToJoin
	local apply_to_group = LookingForGroup_Options.ApplyToGroup
	local tank,healer,damager = select(2,GetLFGRoles())
	local k,v
	for k,v in pairs(select_sup) do
		if v then
			C_SocialQueue_RequestToJoin(k,tank,healer,damager)
		end
	end
end

LookingForGroup_Options:push("quick_join",{
	name = QUICK_JOIN,
	desc = SOCIAL_QUICK_JOIN_TAB_HELP_TIP,
	type = "group",
	args =
	{
		sign_up =
		{
			order = 1,
			name = SIGN_UP,
			type = "execute",
			func = function()
				if next(select_sup) then
					if LookingForGroup.db.profile.role_check then
						LFGListApplicationDialog_Show(LFGListApplicationDialog,signup_func)
					else
						signup_func(LookingForGroup_Options.db.profile.role_comment_text)
					end
				end
			end
		},
		enable =
		{
			order = 2,
			name = ENABLE,
			type = "toggle",
			get = function(info)
				return LookingForGroup_Options.db.profile.qj
			end,
			set = function(info,val)
				if val then
					LookingForGroup_Options.db.profile.qj = true
					LookingForGroup_Options:RegisterEvent("SOCIAL_QUEUE_UPDATE",social_queue_update)
					social_queue_update()
				else
					LookingForGroup_Options.db.profile.qj = nil
					LookingForGroup_Options:UnregisterEvent("SOCIAL_QUEUE_UPDATE")
					wipe(social_tb)
					wipe(select_sup)
				end
			end
		},
		s =
		{
			name = GROUP,
			order = 3,
			values = social_tb,
			dialogControl = "LookingForGroup_Options_Quick_Join_Multiselect",
			type = "multiselect",
		}
	}
})

AceGUI:RegisterWidgetType("LookingForGroup_Options_Quick_Join_Multiselect", function()
	local control = AceGUI:Create("InlineGroup")
	control.type = "LookingForGroup_Options_Quick_Join_Multiselect"
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
		control.SetMultiselect = function()end
		control.SetItemValue = function(self,key)
			local val = self.values[key]
			local queues = C_SocialQueue.GetGroupQueues(val)
			local queueData = queues[1].queueData
			local check
			local lfgListID = queueData.lfgListID
			if lfgListID then
				check = AceGUI:Create("LookingForGroup_search_result_checkbox")
				check:SetUserData("key", key)
				check:SetUserData("val", lfgListID)
				check:SetUserData("social_val",val)
				LookingForGroup_Options.updatetitle(check)
			else
				check = AceGUI:Create("LookingForGroup_quick_join_checkbox")
				check:SetUserData("key", key)
				check:SetUserData("social_val",val)
				check:updatetitle()
			end
			check:SetValue(select_sup[val])
			check:SetCallback("OnValueChanged",function(self,event,val)
				local user = self:GetUserDataTable()
				local v = user.social_val
				if select_sup[v] then
					select_sup[v] = nil
				else
					select_sup[v] = true
				end
				check:SetValue(select_sup[v])			
			end)
			check.width = "fill"
			self:AddChild(check)
		end
	end
	return AceGUI:RegisterAsContainer(control)
end , 1)
