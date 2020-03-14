local cnbnpoints = LibStub("AceAddon-3.0"):GetAddon("cnbnpoints")

local function cofunc()
	if not UnitIsGroupLeader("player") then
		return
	end
	local entry = C_LFGList.GetActiveEntryInfo()
	local classid = select(3,UnitClass("player"))
	C_LFGList.CopyActiveEntryInfoToCreationFields()
	local EntryCreation = LFGListFrame.EntryCreation
	cnbnpoints.send_awaits(nil,"SEI",UnitGUID('player'),nil,cnbnpoints.constant2,entry.activityID,0,nil,nil,EntryCreation.Name:GetText().." "..EntryCreation.Description.EditBox:GetText().." "..EntryCreation.VoiceChat.EditBox:GetText(),entry.requiredItemLevel,nil,classid)
end

function cnbnpoints:LFG_LIST_OR_UPDATE()
	coroutine.wrap(cofunc)()
end

cnbnpoints:RegisterMessage("LFG_LIST_OR_UPDATE")
