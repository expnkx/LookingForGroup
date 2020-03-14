local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")


local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")

local LFGListSearchReporter =
{
	func = function(self, ...)C_LFGList.ReportSearchResult(...)end,
	notCheckable = true,
}
LFGListSearchReporter.__index = LFGListSearchReporter

function LFGListSearchReporter:new(o)
	setmetatable(o,self)
	return o
end

local function backfunc()
	if LookingForGroup_Options.option_table.args.search_result then
		AceConfigDialog:SelectGroup("LookingForGroup","search_result")
	end
end

local function paste(text)
	LookingForGroup_Options.Paste(text,backfunc)
end


local LFG_LIST_SEARCH_ENTRY_MENU

local armory_menu = {}

local function update_armory_menu()
	wipe(armory_menu)
	local k,v
	for k,v in pairs(LookingForGroup_Options.armory) do
		armory_menu[#armory_menu + 1] = LFGListSearchReporter:new(
		{
			text = k,
			func = function(_, id)
				local leaderName = C_LFGList.GetSearchResultInfo(id).leaderName
				if leaderName then
					local armory_link = v(leaderName)
					if armory_link then
						paste(armory_link)
					end
				end
			end,
		})
	end
	table.sort(armory_menu,function(a,b)
		return a.text < b.text
	end)
end
LookingForGroup_Options:RegisterMessage("UpdateArmory",update_armory_menu)

local function fake_achievement_link(id,b)
	local concat_tb = {"\124cffffff00\124Hachievement:",id,":",string.gsub(UnitGUID("player"), '0x', ''),":1:"}	
	local time_tb = date("*t",time()-691200)
	local d,m,y = time_tb.day,time_tb.month,math.fmod(time_tb.year,100)
	if b then
		concat_tb[#concat_tb+1] = math.random(1,28)
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = math.random(1,12)
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = math.random(y-7,y-1)
	else
		concat_tb[#concat_tb+1] = d
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = m
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = y
	end
	concat_tb[#concat_tb+1] = ":4294967295:4294967295:4294967295:4294967295\124h["
	concat_tb[#concat_tb+1] = select(2,GetAchievementInfo(id))
	concat_tb[#concat_tb+1] = "]\124h\124r"
	return table.concat(concat_tb)
end

local function raid_achievement(ce,aotc,from,n)
	if ce and aotc == nil then
		aotc = ce - 1
	end
	local GetAchievementInfo = GetAchievementInfo
	if select(14,GetAchievementInfo(ce)) then	-- Cutting Edge
		return GetAchievementLink(ce)
	end
	local aotc = select(14,GetAchievementInfo(aotc)) and GetAchievementLink(aotc) or fake_achievement_link(aotc)
	if from then
		if select(14,GetAchievementInfo(from+n-1)) then
			return GetAchievementLink(from+n-1)
		end
		for i=from+n-2,from,-1 do
			if select(14,GetAchievementInfo(i)) then
				return table.concat{GetAchievementLink(i),aotc}
			end
		end
	end
	return aotc
end

local function botting_achievement(id,v)
	if select(14,GetAchievementInfo(id)) then
		return GetAchievementLink(id)
	end
	return fake_achievement_link(id,v)
end

local function applysearchresultinfo(id,key,func)
	local searchresultinfo = C_LFGList.GetSearchResultInfo(id)
	if searchresultinfo then
		local val = searchresultinfo[key]
		if val then
			func(val)
		end
	end
end

local function GetSearchEntryMenu(resultID)
	LFGListSearchReporter.arg1 = resultID;
	if LFG_LIST_SEARCH_ENTRY_MENU == nil then
		update_armory_menu()
		LFG_LIST_SEARCH_ENTRY_MENU =
		{
			LFGListSearchReporter:new(
			{
				text = WHISPER_LEADER,
				func = function(_, id)
					applysearchresultinfo(id,"leaderName",ChatFrame_SendTell)
				end,
			}),
			{
				text = CALENDAR_COPY_EVENT,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
--[[					LFGListSearchReporter:new(
					{
						text = LFG_LIST_BAD_NAME,
						func = function(_, id)
							applysearchresultinfo(id,"name",paste)
						end,
					}),
					LFGListSearchReporter:new(
					{
						text = LFG_LIST_BAD_DESCRIPTION,
						func = function(_, id)
							applysearchresultinfo(id,"comment",paste)
						end,
					}),
					LFGListSearchReporter:new(
					{
						text = VOICE_CHAT,
						func = function(_, id)
							applysearchresultinfo(id,"voiceChat",paste)
						end,
					}),]]
					LFGListSearchReporter:new(
					{
						text = LFG_LIST_BAD_LEADER_NAME,
						func = function(_, id)
							applysearchresultinfo(id,"leaderName",paste)
						end,
					})
				}
			},
			{
				text = L.Armory,
				hasArrow = true,
				notCheckable = true,
				menuList = armory_menu
			},
			LFGListSearchReporter:new({
				text = BATTLE_PET_SOURCE_6,
				func = function(_,groupid)
					local info = C_LFGList.GetSearchResultInfo(groupid)
					if not info then
						return
					end
					local leaderName = info.leaderName
					local activityID = info.activityID
					if leaderName then
						if activityID == 494 or activityID == 495 then -- Uldir N/H
							SendChatMessage(raid_achievement(12535,12536),"WHISPER",nil,leaderName)
						end

						if activityID == 496 then
							SendChatMessage(botting_achievement(12535),"WHISPER",nil,leaderName)
						end

						if activityID == 663 or activityID == 664 then -- BoD N/H
							SendChatMessage(raid_achievement(13323),"WHISPER",nil,leaderName)
						end
						
						if activityID == 667 or activityID == 668 then -- Crucible of Storms N/H
							SendChatMessage(raid_achievement(13419),"WHISPER",nil,leaderName)
						end

						if activityID == 671 or activityID == 672 then -- The Eternal Palace N/H
							SendChatMessage(raid_achievement(13785),"WHISPER",nil,leaderName)
						end

						if activityID == 6 then -- 2 Bots vs 2 Bots
							SendChatMessage(botting_achievement(1159,true),"WHISPER",nil,leaderName)
						end
						if activityID == 7 then -- 3 Bots vs 3 Bots
							SendChatMessage(botting_achievement(5267,true),"WHISPER",nil,leaderName)
						end
						if activityID == 19 then -- Rated Bots
							SendChatMessage(botting_achievement(5356,true)..botting_achievement(5267,true),"WHISPER",nil,leaderName)	-- Rated Bots + 3 Bots vs 3 Bots
						end
					end
				end
			}),
			LFGListSearchReporter:new({
				text = IGNORE,
				hasArrow = true,
				notCheckable = true,
				func = function(_,id)
					local info = C_LFGList.GetSearchResultInfo(id)
					if not info then
						return
					end
					local leaderName = info.leaderName
					if leaderName then
						C_LFGList.ReportSearchResult(id,"lfglistspam")
						local tb = LookingForGroup.db.profile.spam_filter_keywords
						if tb == nil then
							tb = {}
						end
						tb[#tb+1] = leaderName:lower()
						LookingForGroup.db.profile.spam_filter_keywords = tb
					end
				end,
				menuList =
				{
					LFGListSearchReporter:new({text = LFG_LIST_BAD_LEADER_NAME,func = function(_, id)
						applysearchresultinfo(id,"leaderName",AddIgnore)
					end}),
					LFGListSearchReporter:new({text = FRIENDS_LIST_REALM:match("^(.*)%:") or FRIENDS_LIST_REALM:match("^(.*)%：") or FRIENDS_LIST_REALM,func = function(_,id)
						local info = C_LFGList.GetSearchResultInfo(id)
						if not info then
							return
						end
						local leaderName = info.leaderName
						if leaderName then
							local _,realm = strsplit("-",leaderName)
							if realm then
								LookingForGroup_Options:add_realm_filter(realm)
							end
						end
					end}),
				}
			}),
			{
				text = LFG_LIST_REPORT_GROUP_FOR,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
					LFGListSearchReporter:new({text = LFG_LIST_SPAM,arg2 = "lfglistspam"}),
					LFGListSearchReporter:new({text = LFG_LIST_BAD_NAME,arg2 = "lfglistname"}),
					LFGListSearchReporter:new({text = LFG_LIST_BAD_DESCRIPTION,arg2 = "lfglistcomment"}),
					LFGListSearchReporter:new({text = LFG_LIST_BAD_VOICE_CHAT_COMMENT,arg2 = "lfglistvoicechat"}),
					LFGListSearchReporter:new({text = LFG_LIST_BAD_LEADER_NAME,arg2 = "badplayername"}),
				},
			},
			{
				text = CANCEL,
				notCheckable = true,
			},
		}
	end
	return LFG_LIST_SEARCH_ENTRY_MENU;
end

LookingForGroup_Options.GetSearchEntryMenu = GetSearchEntryMenu

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

local GameTooltip = GameTooltip
local floor = floor

local function formatted_convert_sec_to_xx_xx_xx(value)
	if value < 60 then
		return "%d",value
	elseif value < 3600 then
		value = floor(value)
		local v = floor(value / 60)
		return "%d:%02d",v,value-v*60
	else
		value = floor(value)
		local hour = value / 3600
		local min_sec = value % 3600
		local minute = min_sec / 60
		local sec = min_sec % 60
		return "%d:%02d:%02d",hour,minute,sec
	end
end

local function convert_sec_to_xx_xx_xx(value)
	return format(formatted_convert_sec_to_xx_xx_xx(value))
end

LookingForGroup_Options.convert_sec_to_xx_xx_xx = convert_sec_to_xx_xx_xx

local tank_tb = {}
local healer_tb = {}
local damager_tb = {}

local classes = {}
do

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local GetClassInfo = GetClassInfo
for i=1,GetNumClasses() do
	local _,class = GetClassInfo(i)
	classes[i]=CLASS_COLORS[class]
	classes[class]=i
end

end

local function add_role(tbl,icon,n)
	if n ~= 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(icon,n,nil,nil,nil,0.5,0.5,0.8)
		local GetClassInfo = GetClassInfo
		for i=1,#tbl do
			local v = tbl[i]
			if v ~= 0 then
				local color=classes[i]
				if v == 1 then
					GameTooltip:AddDoubleLine(GetClassInfo(i),nil,color.r,color.g,color.b)
				else
					GameTooltip:AddDoubleLine(GetClassInfo(i),v,color.r,color.g,color.b,color.r,color.g,color.b)
				end
			end
		end		
	end
end

local function init_roles(id,numMembers)
	local C_LFGList_GetSearchResultMemberInfo = C_LFGList.GetSearchResultMemberInfo
	for i=1,GetNumClasses() do
		tank_tb[i]=0
		healer_tb[i]=0
		damager_tb[i]=0
	end
	local tank,healer,damager = 0,0,0
	for i = 1, numMembers do
		local role, class, class_localized = C_LFGList_GetSearchResultMemberInfo(id,i)
		local class_id = classes[class]
		if role == "TANK" then
			tank_tb[class_id] = tank_tb[class_id] + 1
			tank = tank + 1
		elseif role == "HEALER" then
			healer_tb[class_id] = healer_tb[class_id] + 1
			healer = healer + 1
		else
			damager_tb[class_id] = damager_tb[class_id] + 1
			damager = damager + 1
		end
	end
	return tank,healer,damager,tank_tb,healer_tb,damager_tb,classes
end
LookingForGroup_Options.init_roles = init_roles

local function handle_title_role(concat_tb,number,tb,sign)
	if number ~= 0 then
		for i=1,#tb do
			local v = tb[i]
			if v ~= 0 then
				concat_tb[#concat_tb + 1] = "|c"
				concat_tb[#concat_tb + 1] = classes[i].colorStr
				concat_tb[#concat_tb + 1] = sign
				if v ~= 1 then
					concat_tb[#concat_tb + 1] = v
				end
				concat_tb[#concat_tb + 1] = "|r"
			end
		end
		concat_tb[#concat_tb+1] = " "
	end
end
LookingForGroup_Options.handle_title_role = handle_title_role
local concat_tb = {}

function LookingForGroup_Options.updatetitle(obj)
	local users = obj:GetUserDataTable()
	local info = C_LFGList.GetSearchResultInfo(users.val)
	if info == nil then
		return
	end
	local activityName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = 
		C_LFGList.GetActivityInfo(info.activityID)
	local questID = info.questID
	if questID then
		local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
		if questName then
			obj.text:SetText(questName)
		else
			obj.text:SetText(info.name)
		end
	else
		obj.text:SetText(info.name)
	end
	obj.text:SetTextColor(1,0.82,0)
	wipe(concat_tb)
	concat_tb[#concat_tb + 1] = activityName
	local iLvl = info.requiredItemLevel
	if iLvl ~= 0 then
		concat_tb[#concat_tb + 1] = " |cff8080cc"
		concat_tb[#concat_tb + 1] = iLvl
		concat_tb[#concat_tb + 1] = "|r"
	end
	local leaderName = info.leaderName
	if leaderName then
		local lfgscoresbrief = LookingForGroup_Options.lfgscoresbrief
		if lfgscoresbrief then
			for i=1,#lfgscoresbrief do
				concat_tb[#concat_tb + 1] = lfgscoresbrief[i](leaderName,1,info,categoryID,groupID)
			end
		end
	end
	concat_tb[#concat_tb+1] = "\n|cff8080cc"
	local numMembers = info.numMembers
	concat_tb[#concat_tb+1] = numMembers
	concat_tb[#concat_tb+1] = "("
	local tank,healer,damager = init_roles(users.val,numMembers)
	concat_tb[#concat_tb+1] = tank
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = healer
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = damager
	concat_tb[#concat_tb+1] = ")|r "
	handle_title_role(concat_tb,tank,tank_tb,"T")
	handle_title_role(concat_tb,healer,healer_tb,"H")
	handle_title_role(concat_tb,damager,damager_tb,"D")
	local social_val = users.social_val
	if social_val then
		concat_tb[#concat_tb + 1] = SocialQueueUtil_GetHeaderName(social_val)
	end
	if leaderName then
		concat_tb[#concat_tb + 1] = " |cffff00ff"
		concat_tb[#concat_tb + 1] = leaderName
		concat_tb[#concat_tb + 1] = "|r"
	end
	local voiceChat = info.voiceChat
	if voiceChat:len()~=0 then
		concat_tb[#concat_tb + 1] = "\n|cff00ffff"
		concat_tb[#concat_tb + 1] = voiceChat
		concat_tb[#concat_tb + 1] = "|r"
	end
	local comment = info.comment
	if comment:len()~=0 then
		concat_tb[#concat_tb + 1] = "\n|cff00ff00"
		concat_tb[#concat_tb + 1] = comment
		concat_tb[#concat_tb + 1] = "|r"
	end
	obj:SetDescription(table.concat(concat_tb))
	wipe(concat_tb)
	if info.isDelisted then
		LookingForGroup_Options.delist(obj)
	end
end

function LookingForGroup_Options.delist(obj)
	local r,g,b,a = obj.text:GetTextColor()
	obj.text:SetTextColor(r,g,b,0.55)
	r,g,b,a = obj.desc:GetTextColor()
	obj.desc:SetTextColor(r,g,b,0.55)
	obj.disabled = true
end

function LookingForGroup_Options.disable(obj,disabled)
	obj.disabled = disabled
	if disabled then
		obj.frame:Disable()
		local r,g,b = obj.text:GetTextColor()
		obj.text:SetTextColor(r,g,b,0.55)
		SetDesaturation(obj.check, true)
		if obj.desc then
			r,g,b = obj.desc:GetTextColor()
			obj.desc:SetTextColor(r,g,b,0.55)
		end
	else
		obj.frame:Enable()
		local r,g,b = obj.text:GetTextColor()
		obj.text:SetTextColor(r,g,b,1)
		if obj.tristate and obj.checked == nil then
			SetDesaturation(obj.check, true)
		else
			SetDesaturation(obj.check, false)
		end
		if obj.desc then
			r,g,b = obj.desc:GetTextColor()
			obj.desc:SetTextColor(r,g,b,1)
		end
	end
end

function LookingForGroup_Options.handle_encounters(rse,...)
	if rse then
		if rse[0] == nil then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(#rse)
		end
		for i=1,#rse do
			GameTooltip:AddLine(rse[i],1,0,0,true)
		end
	end
	return ...
end

local function add_application_info_tooltip(resultID)
	local id, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(resultID)
	if appStatus == "none" then
		return
	elseif appStatus == "applied" then
		GameTooltip:AddLine(' ')
		wipe(concat_tb)
		concat_tb[#concat_tb+1] = LFG_LIST_PENDING
		concat_tb[#concat_tb+1] = ' '
		concat_tb[#concat_tb+1] = convert_sec_to_xx_xx_xx(appDuration)
		GameTooltip:AddLine(table.concat(concat_tb),GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
		wipe(concat_tb)
	elseif pendingStatus == "cancelled" or appStatus == "cancelled" or appStatus == "failed" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_CANCELLED,RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	elseif appStatus == "declined" or appStatus == "declined_full" or appStatus == "declined_delisted" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_DECLINED,RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	elseif appStatus == "timeout" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_TIMED_OUT,RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	elseif appStatus == "invited" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_INVITED,GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
	elseif appStatus == "inviteaccepted" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_INVITE_ACCEPTED,GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
	elseif appStatus == "invitedeclined" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_INVITE_DECLINED,RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	end
end

LookingForGroup_Options.add_application_info_tooltip = add_application_info_tooltip

local function on_enter(self)
	GameTooltip:SetOwner(self,"ANCHOR_TOPRIGHT")
	coroutine.wrap(LookingForGroup_Options.search_result_tooltip_coroutine)(self,self.obj:GetUserDataTable().val)
end

function LookingForGroup_Options.search_result_tooltip_coroutine(frame,id,detail)
	local co = coroutine.running()
	local onenter = frame:GetScript("OnEnter")
	local onleave = frame:GetScript("OnLeave")
	local function cofunc(...)
		LookingForGroup.resume(...)
	end
	frame:SetScript("OnEnter",nop)
	local function leave()
		cofunc(co)
	end
	frame:SetScript("OnLeave",leave)
	local ticker=C_Timer.NewTicker(1,function()
		cofunc(co,2)
	end)
	local function update_method(message,result_id,...)
		if id == result_id then
			cofunc(co,1,message,...)
		end
	end
	LookingForGroup:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",update_method)
	LookingForGroup:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",update_method)
	local GameTooltip = GameTooltip
	local GetTime = GetTime
	local yd = 1
	local delta
	local cache
	local timeTextLeftTooltip = detail and GameTooltipTextLeft2 or GameTooltipTextLeft1
	while yd do
		if GameTooltip:GetOwner() ~= frame then
			break
		end
		if yd == 1 then
			local info = C_LFGList.GetSearchResultInfo(id)
			if info == nil then
				break
			end
			local age = info.age
			delta = age-GetTime()
			local activityName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(info.activityID)
			local iLvl = info.requiredItemLevel
			local questID = info.questID
			local addon
			if cache then wipe(cache) end
			GameTooltip:ClearLines()
			if detail then
				GameTooltip:AddLine(info.name,nil,nil,nil,true)
			end
			GameTooltip:AddDoubleLine(convert_sec_to_xx_xx_xx(age),id,nil,nil,nil,0.5, 0.5, 0.8,true)
			if info.requiredHonorLevel ~= 0 then
				GameTooltip:AddDoubleLine(LFG_LIST_HONOR_LEVEL_INSTR_SHORT, info.requiredHonorLevel, nil,nil,nil,  0.5, 0.5, 0.8)
			end
			if info.questID then
				GameTooltip:AddDoubleLine(TRANSMOG_SOURCE_2,info.questID,nil,nil,nil,0.5,0.5,0.8,true)	
			end
			if iLvl ~= 0 then
				if math.floor(iLvl)~=iLvl then
					addon = "LFG"
				elseif iLvl == 240 then
					addon = "WQL"
				end
			elseif questID then
				addon = "Blizzard"
			end
			if addon then
				GameTooltip:AddDoubleLine(ADDONS,addon,nil,nil,nil,0.5,0.5,0.8,true)
			end
			if info.autoAccept then
				GameTooltip:AddLine(LFG_LIST_AUTO_ACCEPT)
			end
			if detail then
				local voiceChat = info.voiceChat
				if voiceChat:len()~=0 then
					GameTooltip:AddLine(voiceChat,0,1,1,true)
				end
				local comment = info.comment
				if comment:len()~=0 then
					GameTooltip:AddLine(comment,0.5,0.5,0.8,true)
				end
			end
			cache=LookingForGroup_Options.handle_encounters(C_LFGList.GetSearchResultEncounterInfo(id),cache,info,groupID,categoryID,shortName)
			local friendlist = LFGListSearchEntryUtil_GetFriendList(id)
			if friendlist:len()~=0 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(friendlist,nil,nil,nil,true)
			end
			if info.isDelisted then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(LFG_LIST_ENTRY_DELISTED,1,0,0,true)
			end
			add_application_info_tooltip(id)
			GameTooltip:Show()
		elseif yd == 2 then
			timeTextLeftTooltip:SetFormattedText(formatted_convert_sec_to_xx_xx_xx((GetTime()+delta)))
		end
		yd = coroutine.yield()
	end
	ticker:Cancel()
	LookingForGroup:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
	LookingForGroup:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
	frame:SetScript("OnLeave",onleave)
	frame:SetScript("OnEnter",onenter)
	GameTooltip:Hide()
	if onleave then
		onleave(frame)
	end
end

AceGUI:RegisterWidgetType("LookingForGroup_search_result_checkbox", function()
	local check = AceGUI:Create("CheckBox")
	local frame = check.frame
	frame:RegisterForClicks("LeftButtonDown","RightButtonDown")
	frame:SetScript("OnMouseUp",function(self,button)
		local obj = self.obj
		local user = obj:GetUserDataTable()
		if button == "LeftButton" then
			if not obj.disabled then
				if obj.checked then
					PlaySound(856)
				else -- for both nil and false (tristate)
					PlaySound(857)
				end
				
				obj:Fire("OnValueChanged", obj.checked)
			end
			AlignImage(obj)
		else
			EasyMenu(GetSearchEntryMenu(user.val), LFGListFrameDropDown, "cursor" , 0, 0, "MENU")
		end
	end)
	check.SetDisabled = LookingForGroup_Options.disable
	frame:SetScript("OnEnter", on_enter)
	function check.OnAcquire(self)
		self:SetTriState(nil)
		self.disabled = false
		self.width = "fill"
	end
	check.type = "LookingForGroup_search_result_checkbox"	
	return AceGUI:RegisterAsWidget(check)
end, 1)
