local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local AceGUI = LibStub("AceGUI-3.0")

local function factory(Type,framename,func,challenges)
	AceGUI:RegisterWidgetType(Type,function()
		if _G[framename] == nil then
			LoadAddOn(challenges and "Blizzard_ChallengesUI" or "Blizzard_PVPUI")
		end
		local frame = _G[framename]
		if challenges then
			hooksecurefunc("ChallengesFrame_Update",function(...)
				LFG_OPT:SendMessage("LFG_HOOK_CHALLENGESFRAME_UPDATE",...)
			end)
		else
			frame:SetScript("OnHide",function()
				local HonorInset = PVPQueueFrame.HonorInset
				HonorInset:SetParent(frame)
				HonorInset:Hide()
			end)
			frame:HookScript("OnShow",function(self)
				local HonorInset = PVPQueueFrame.HonorInset

				HonorInset:SetParent(UIParent)
				HonorInset:ClearAllPoints()
				local value = 185
				HonorInset:SetPoint("TOPRIGHT",self,"TOPRIGHT",value,-25)
				HonorInset:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",value,-25)
				PVPQueueFrame.selection = self
				if self==ConquestFrame then
					HonorInset:DisplayRatedPanel()
				else
					HonorInset:DisplayCasualPanel()
				end
				HonorInset:Show()
			end)			
			local ConquestBar = frame.ConquestBar
			ConquestBar:SetPoint("TOPRIGHT",-32,-19)
			ConquestBar.Border:SetPoint("RIGHT",9,-2)
		end
		local widget = {
			alignoffset = frame:GetHeight(),
			frame       = frame,
			type        = Type,
			OnAcquire = func(frame) or nop,
			SetLabel = nop,
			SetList = nop,
			SetValue = nop,
		}
		return AceGUI:RegisterAsWidget(widget)
	end,1)
end

local function set_relative(frame,tb)
	for i=1,#tb do
		local t = frame[tb[i]]
		local point, relativeTo, relativePoint, xOfs, yOfs = t:GetPoint(1)
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT",relativeTo,relativePoint.."LEFT",xOfs,yOfs)
		t:SetPoint("TOPRIGHT",relativeTo,relativePoint.."RIGHT",xOfs,yOfs)
		t.Reward:SetPoint("RIGHT",-16,-2)
	end
end

factory("LFG_OPT_HONOR","HonorFrame",function(frame)
	local QueueButton = frame.QueueButton
	QueueButton:ClearAllPoints()
	QueueButton:SetPoint("BOTTOMLEFT",0,0)
	QueueButton:SetPoint("BOTTOMRIGHT",0,0)
	set_relative(frame.BonusFrame,{"RandomBGButton","RandomEpicBGButton","Arena1Button","BrawlButton"})
	frame.BonusFrame.WorldBattlesTexture:SetAllPoints()
	local SpecificFrame = frame.SpecificFrame
	local buttons = SpecificFrame.buttons
	buttons[1]:SetPoint("TOPRIGHT",SpecificFrame.scrollBar,"TOPLEFT",0,0)
	for i=2,#buttons do
		local b = buttons[i]
		local point, relativeTo, relativePoint, xOfs, yOfs = b:GetPoint(1)
		b:SetPoint("TOPRIGHT", relativeTo, "BOTTOMRIGHT", xOfs, yOfs)
	end
end)

factory("LFG_OPT_CONQUEST","ConquestFrame",function(frame)
	local RatedBGTexture = frame.RatedBGTexture
	RatedBGTexture:SetPoint("LEFT")
	RatedBGTexture:SetPoint("RIGHT")
	local JoinButton = frame.JoinButton
	JoinButton:ClearAllPoints()
	JoinButton:SetPoint("BOTTOMLEFT",0,0)
	JoinButton:SetPoint("BOTTOMRIGHT",0,0)
	set_relative(frame,{"Arena2v2","Arena3v3","RatedBG"})
end)

factory("LFG_OPT_CHALLENGES","ChallengesFrame",function(frame)
	ChallengesFrameInset:Hide()
	frame.Background:Hide()
	local seasonbest = frame.WeeklyInfo.Child.SeasonBest
	seasonbest:SetAlpha(0)
end,true)

LFG_OPT:push("honor",{
	name = PVP_TAB_HONOR,
	type = "group",
	args =
	{
		honor =
		{
			name = nop,
			type = "select",
			dialogControl="LFG_OPT_HONOR",
			values = {},
			width="full"
		},
	}
})

LFG_OPT:push("conquest",{
	name = PVP_TAB_CONQUEST,
	type = "group",
	args =
	{
		conquest =
		{
			name = nop,
			type = "select",
			dialogControl="LFG_OPT_CONQUEST",
			values = {},
			width="full"
		}
	}
})

LFG_OPT:push("challenge",{
	name = PLAYER_DIFFICULTY5,
	desc = CHALLENGES,
	type = "group",
	args =
	{
		challenge =
		{
			name = nop,
			type = "select",
			dialogControl="LFG_OPT_CHALLENGES",
			values = {},
			width="full"
		}
	}
})

function LFG_OPT:AJ_PVP_ACTION()
	self.aj_open_action("honor")
end

LFG_OPT.AJ_PVP_SKIRMISH_ACTION = LFG_OPT.AJ_PVP_ACTION
LFG_OPT.AJ_PVP_RBG_ACTION = LFG_OPT.AJ_PVP_ACTION

LFG_OPT:RegisterEvent("AJ_PVP_ACTION")
LFG_OPT:RegisterEvent("AJ_PVP_SKIRMISH_ACTION")
LFG_OPT:RegisterEvent("AJ_PVP_RBG_ACTION")

function LFG_OPT:LFG_HOOK_CHALLENGESFRAME_UPDATE(event,frame,...)
	local icon = frame.DungeonIcons[1]
	icon:ClearAllPoints()
	icon:SetPoint("TOPLEFT",frame,"BOTTOMLEFT",0,-400)
	icon:SetParent(frame)
end

LFG_OPT:RegisterMessage("LFG_HOOK_CHALLENGESFRAME_UPDATE")