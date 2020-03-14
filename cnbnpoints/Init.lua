if GetCurrentRegion()~=5 then
	return
end

local cnbnpoints = LibStub("AceAddon-3.0"):NewAddon("cnbnpoints","AceConsole-3.0","AceSerializer-3.0","AceEvent-3.0","AceComm-3.0")

cnbnpoints.constant = "8203"
cnbnpoints.constant2 = cnbnpoints.constant:gsub('(%d)(%d)(%d%d)', '%10%200.%3')
--------------------------------------------------------------------------------------

function cnbnpoints:OnInitialize()
	self:RegisterChatCommand("cnbnpoints", "ChatCommand")
	self:RegisterChatCommand("cbp", "ChatCommand")
	self:RegisterComm("NERB")
	local event_zero
	for i = 1, GetNumAddOns() do
		local messages = GetAddOnMetadata(i,"X-CBP-MESSAGE")
		if messages then
			for message in gmatch(messages, "([^,]+)") do
				self:RegisterMessage(message,"loadevent",i)
			end
		end
	end
	self.OnInitialize=nil
end

function cnbnpoints:ChatCommand(input)
	if IsAddOnLoaded("cnbnpoints_options") == false then
		local loaded , reason = LoadAddOn("cnbnpoints_options")
		if not loaded then
			cnbnpoints:Print(reason)
		end
	end
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):Open("cnbnpoints")
	else
		LibStub("AceConfigCmd-3.0"):HandleCommand("cnbnpoints", "cnbnpoints",input)
	end
end

function cnbnpoints:loadevent(p,event,...)
	cnbnpoints:UnregisterMessage(event)
	if IsAddOnLoaded(p) then
		self:SendMessage(event,...)
		return true
	end
	LoadAddOn(p)
	if IsAddOnLoaded(p) then
		local addon = GetAddOnMetadata(p,"X-CBP-EM-HOSTER") or GetAddOnInfo(p)
		local a = LibStub("AceAddon-3.0"):GetAddon(addon)
		a[event](a,event,...)
		collectgarbage("collect")
		return true
	end
end

function cnbnpoints.resume(current,...)
	local current_status = coroutine.status(current)
	if current_status =="suspended" then
		local status, msg = coroutine.resume(current,...)
		if not status then
			cnbnpoints:Print(msg)
		end
	end
end
-- must ensure exception safety
function cnbnpoints.awaits(expected_cbp)
	local running = coroutine.running()
	local temp = {}
	if type(expected_cbp) == "table" then
		cnbnpoints.RegisterMessage(temp,"CBP_COMM_RECEIVED",function(msg,unit,...)
			local select = select
			for i=1,#expected_cbp do
				if expected_cbp[i] ~= select(i,...) then
					return
				end
			end
			cnbnpoints.resume(running,unit,select(#expected_cbp+1,...))
		end)
	else
		cnbnpoints.RegisterMessage(temp,"CBP_COMM_RECEIVED",function(msg,unit,bp,...)
			if expected_cbp == bp then
				cnbnpoints.resume(running,unit,...)
			end
		end)
	end
	local unit,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10 = coroutine.yield()
	cnbnpoints.UnregisterAllEvents(temp)
	return unit,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10
end

local pendings = {}

local connected_unit
-- must ensure exception safety
function cnbnpoints.send_awaits(expected_cbp,...)
	if connected_unit == nil then
		local key = tostring(random(0x100000,0xFFFFFF))
		cnbnpoints:SendCommMessage("NERB",cnbnpoints:Serialize("NETEASE_CONNECT",key), "WHISPER","S1"..UnitFactionGroup("player"))
		connected_unit = false
		local unit,returned_key,source = cnbnpoints.awaits("NETEASE_CONNECT_SUCCESS")
		connected_unit = unit
		local optresume = cnbnpoints.resume
		for i=1,#pendings do
			optresume(pendings[i])
		end
		pendings = nil
	elseif connected_unit == false then
		pendings[#pendings+1] = coroutine.running()
		coroutine.yield()
	end
	if select("#",...) ~= 0 then
		cnbnpoints:SendCommMessage("NERB",cnbnpoints:Serialize(...), "WHISPER",connected_unit)
	end
	if expected_cbp then
		return select(2,cnbnpoints.awaits(expected_cbp))
	end
end

function cnbnpoints:OnCommReceived(prefix, text, distribution, unit)
	if distribution == "WHISPER" then
		local ok,cbp,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10 = self:Deserialize(text)
		if cbp then
			self:SendMessage("CBP_COMM_RECEIVED",unit,cbp,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
		end
	end
end
