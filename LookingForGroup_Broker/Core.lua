local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")

local LDB = LibStub("LibDataBroker-1.1"):NewDataObject(LFG_TITLE:gsub(" ",""),{
	type = "data source",
	icon = 134149,
})

function LDB:OnClick(button)
	if button == "RightButton" then
		if IsControlKeyDown() or IsShiftKeyDown()  then
			LookingForGroup:SendMessage("LFG_ICON_RIGHT_CLICK", 0)
		else
			LookingForGroup:SendMessage("LFG_ICON_RIGHT_CLICK")
		end
	elseif button == "LeftButton" then
		LookingForGroup:SendMessage("LFG_ICON_LEFT_CLICK")
	else
		LookingForGroup:SendMessage("LFG_ICON_MIDDLE_CLICK")
	end
end

function LDB:OnEnter()
	GameTooltip:SetOwner(self)
	GameTooltip:ClearLines()
	GameTooltip:AddLine("LookingForGroup")
	local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options",true)
	if LookingForGroup_Options and LookingForGroup_Options.Background_Timer then
		GameTooltip:AddLine("|cff8080cc"..SEARCHING.."|r")
		local bg_rs = LookingForGroup_Options.Background_Result
		if bg_rs then
			GameTooltip:AddLine(table.concat{"|cffff00ff",KBASE_SEARCH_RESULTS,"(",bg_rs,")|r"})
		end
	end
	GameTooltip:Show()
end

function LDB:OnLeave()
	GameTooltip:Hide()
end

LookingForGroup.LDB = LDB
