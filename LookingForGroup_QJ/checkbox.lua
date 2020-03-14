local AceGUI = LibStub("AceGUI-3.0")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local ENTRY_MENU

local function GetSearchEntryMenu(aid)
	if ENTRY_MENU == nil then
		local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")
		ENTRY_MENU =
		{
			{
				text = WHISPER,
				func = function(_, id)
					local name = SocialQueueUtil_GetRelationshipInfo(select(7,C_SocialQueue.GetGroupInfo(id)))
					if name then
						ChatFrame_SendTell(name)
					end
				end,
				notCheckable = true
			},
			{
				text = L.Armory,
				hasArrow = true,
				notCheckable = true,
				menuList = {}
			},
			{
				text = CANCEL,
				notCheckable = true,
			},
		}
	end
	ENTRY_MENU[1].arg1 = aid
	local armory_menu = ENTRY_MENU[2].menuList
	wipe(armory_menu)
	local function backqj()
		LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","quick_join")
	end
	
	for k,v in pairs(LookingForGroup_Options.armory) do
		armory_menu[#armory_menu + 1] = 
		{
			text = k,
			func = function(_, id)
				local name = SocialQueueUtil_GetRelationshipInfo(select(7,C_SocialQueue.GetGroupInfo(id)))
				if name then
					LookingForGroup_Options.Paste(v(name),backqj)
				end
			end,
			arg1 = aid,
			notCheckable = true
		}
	end
	table.sort(armory_menu,function(a,b)
		return a.text < b.text
	end)
	return ENTRY_MENU;
end

local function AlignImage(self)
	local img = self.image:GetTexture()
	self.text:ClearAllPoints()
	if not img then
		self.text:SetPoint("LEFT", self.checkbg, "RIGHT")
		self.text:SetPoint("RIGHT")
	else
		self.text:SetPoint("LEFT", self.image,"RIGHT", 1, 0)
		self.text:SetPoint("RIGHT")
	end
end

local C_SocialQueue_GetGroupQueues = C_SocialQueue.GetGroupQueues
local concat_tb = {}
local table_concat = table.concat

local function updateqjtitle(obj)
	local users = obj:GetUserDataTable()
	local key = users.key
	local val = users.social_val
	obj:SetLabel(SocialQueueUtil_GetHeaderName(users.social_val))
	wipe(concat_tb)
	local queues = C_SocialQueue_GetGroupQueues(val)
	for i=1,#queues do
		local queueData = queues[i].queueData
		if not queueData.lfgListID then
			if #concat_tb ~= 0 then
				concat_tb[#concat_tb + 1] = "\n"
			end
			concat_tb[#concat_tb + 1] = SocialQueueUtil_GetQueueName(queueData)
		end
	end
	obj:SetDescription(table_concat(concat_tb))
end

AceGUI:RegisterWidgetType("LookingForGroup_quick_join_checkbox", function()
	local check = AceGUI:Create("CheckBox")
	check.type = "LookingForGroup_quick_join_checkbox"
	function check.OnAcquire()
		local frame = check.frame
		frame:RegisterForClicks("LeftButtonDown","RightButtonDown")
		frame:SetScript("OnMouseUp",function(self,button)
			local obj = self.obj
			local user = obj:GetUserDataTable()
			if button == "LeftButton" then
				if not obj.disabled then
	--				obj:ToggleChecked()
					if obj.checked then
						PlaySound(856)
					else -- for both nil and false (tristate)
						PlaySound(857)
					end				
					obj:Fire("OnValueChanged", obj.checked)
					AlignImage(obj)
				end
			else
				local val = user.social_val
				EasyMenu(GetSearchEntryMenu(val), LFGListFrameDropDown, "cursor" , 20, 0, "MENU")
			end
		end)
		check.width = "fill"
		check.updatetitle = updateqjtitle
	end
	return AceGUI:RegisterAsWidget(check)
end, 1)
