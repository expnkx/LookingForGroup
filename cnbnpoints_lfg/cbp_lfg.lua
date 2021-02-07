local cnbnpoints = LibStub("AceAddon-3.0"):GetAddon("cnbnpoints")

local function cofunc(activityID,info)
	if IsInGroup("player") and not UnitIsGroupLeader("player") then
		return
	end
	if info.private then
		return
	end
	local classid = select(3,UnitClass("player"))
	local EntryCreation = LFGListFrame.EntryCreation
	cnbnpoints.send_awaits(nil,"SEI",UnitGUID('player'),nil,cnbnpoints.constant2,activityID,0,nil,nil,
		EntryCreation.Name:GetText().." "..EntryCreation.Description.EditBox:GetText().." "..EntryCreation.VoiceChat.EditBox:GetText(),
		info.minimum_item_level or 0,nil,classid)
end

function cnbnpoints:LFG_LIST_OR_UPDATE(_,activityID,info)
	coroutine.wrap(cofunc)(activityID,info)
end

cnbnpoints:RegisterMessage("LFG_LIST_OR_UPDATE")
