local RIO = LibStub:GetLibrary("LibRaiderIO")
local LFG = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local LFG_RIO = LFG_OPT:GetModule("RaiderIO")

local function unitcangenerate(unit)
	return (UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit,"player")) and unit
end

function LFG_RIO.generate_whose_info()
	local u = unitcangenerate("mouseover") or unitcangenerate("target") or unitcangenerate("focus")
	if u then
		return u,UnitFullName(u)
	else
		local nm = LFG_OPT.raider_io_name
		if nm then
			return nil,strsplit("-",LFG_OPT.raider_io_name)
		else
			return "player",UnitFullName("player")
		end
	end
end

function LFG_RIO.role_concat(concat,raw,i,pool1)
	local roles = RIO.role(raw,i,pool1)
	local rshift = bit.rshift
	local band = bit.band
	for i=1,#roles do
		local ele = roles[i]
		local role = rshift(ele,1)
		if band(ele,1)==1 then
			concat[#concat+1] = "∂"
		end
		if role == 0 then
			concat[#concat+1] = "|T337497:16:16:0:0:64:64:20:39:22:41|t"
		elseif role == 1 then
			concat[#concat+1] = "|T337497:16:16:0:0:64:64:20:39:1:20|t"
		elseif role == 2 then
			concat[#concat+1] = "|T337497:16:16:0:0:64:64:0:19:22:41|t"
		end
	end
	return concat
end
local function co_label(self)
	local current = coroutine.running()
	function self.OnRelease()
		LFG.resume(current)
	end
	local function update(...)
		LFG.resume(current,...)
	end
	LFG_RIO:RegisterEvent("UNIT_TARGET",update)
	LFG_RIO:RegisterEvent("UPDATE_MOUSEOVER_UNIT",update)
	local on_mousedown_origin = self.frame:GetScript("OnMouseDown")
	self.frame:SetScript("OnMouseDown",function()
		LFG.resume(current,1)
	end)
	local pool,pool1,concat = {},{},{}
	local yd = 0
	local GetActivityGroupInfo = C_LFGList.GetActivityGroupInfo
	local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	while yd do
		repeat
			wipe(concat)
			if yd == 1 then
				local unit,name,server =  LFG_RIO.generate_whose_info()
				if name then
					concat[1]=name
					concat[2]=server
					LFG_OPT.Paste(LFG_OPT.armory["Raider.IO"](table.concat(concat,"-")),function()
						LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","rioffline")
					end)
				end
				break
			end
			local unit,name,server = LFG_RIO.generate_whose_info()
			local class = unit and select(2,UnitClass(unit)) or nil
			if class then
				concat[#concat+1] = "|c"
				concat[#concat+1] = CLASS_COLORS[class].colorStr
			end
			concat[#concat+1] = name
			if server then
				concat[#concat+1] = " "
				concat[#concat+1] = server
			end
			if class then
				concat[#concat+1] = "|r"
			end
			concat[#concat+1] = "\n\n"
			local raw = RIO.raw(1,name,server,pool)
			local band = bit.band
			if raw then
				for i=1,RIO.score_types do
					local score = RIO.score(raw,i)
					if score ~= 0 then
						if band(i-1,1) ~= 0 then
							concat[#concat+1] = "< "
						end
						if band(i-1,2) ~= 0 then
							concat[#concat+1] = "M "
						end
						concat[#concat+1] = RIO.score(raw,i)
						concat[#concat+1] = " "
						LFG_RIO.role_concat(concat,raw,i,pool1)
						concat[#concat+1] = "\n"
					end
				end
				concat[#concat+1] = "\n"
				local RIO_keystone = RIO.keystone
				local RIO_keystone_range = RIO.keystone_levels_range
				for i=RIO.keystone_levels,1,-1 do
					local t,range = RIO_keystone(raw,i)
					if t~= 0 then
						concat[#concat+1] = "|cffff00ff["
						concat[#concat+1] = i*5
						concat[#concat+1] = ","
						if i <= RIO_keystone_range then
							concat[#concat+1] = i*5+5
						else
							concat[#concat+1] = "+∞"
						end
						concat[#concat+1] = ")|r "
						if range then
							concat[#concat+1] = "["
							concat[#concat+1] = t
							if range == true then
								concat[#concat+1] = ",+∞)"
							else
								concat[#concat+1] = ","
								concat[#concat+1] = range
								concat[#concat+1] = ")"
							end
						else
							concat[#concat+1] = t
						end
						concat[#concat+1] = "\n"
					end
				end
				concat[#concat+1] = "\n"
				local RIO_dungeons = RIO.dungeons
				local max_dungeon = RIO.max_dungeon(raw)
				concat[#concat+1] = 0
				local done_pos = #concat
				concat[#concat+1] = "/"
				concat[#concat+1] = #RIO_dungeons
				concat[#concat+1] = "\n"
				local RIO_dungeon = RIO.dungeon
				local done = 0
				for i=1,#RIO_dungeons do
					local level,upgrade = RIO_dungeon(raw,i)
					if level ~= 0 then
						done = done + 1
						if i == max_dungeon then
							concat[#concat+1] = "|c0000FF00★|r "
						end
						concat[#concat+1] = "|cff8080cd"
						concat[#concat+1] = GetActivityGroupInfo(RIO_dungeons[i])
						concat[#concat+1] = "|r "
						concat[#concat+1] = level
						if upgrade == 0 then
							concat[#concat+1] = '|c00FF0000-|r\n'
						else
							concat[#concat+1] = '+|c0000ff00'
							concat[#concat+1] = upgrade
							concat[#concat+1] = "|r\n"
						end
					end
				end
				concat[done_pos] = done
				concat[#concat+1] = format("\n|cff0000ff{%.0f",raw[1])
				for i=2,#raw do
					concat[#concat+1] = format(",%.0f",raw[i])
				end
				concat[#concat+1] = "}|r\n"
			end
			local raw = RIO.raw(2,name,server,pool)
			if raw then
				local reserved_group_id
				for i=1,RIO.raid_types do
					local difficulty,count,bosses,has_pool,instance,pool = RIO.raid(raw,i,pool1)
					if difficulty then
						local groupid = instance[1]
						if groupid~=reserved_group_id then
							concat[#concat+1] = "\n|c0000ff00"
							concat[#concat+1] = GetActivityGroupInfo(groupid)
							concat[#concat+1] = "|r\n"
							reserved_group_id = groupid
						end
						if not has_pool and pool then
							concat[#concat+1] = 'M '
						end
						concat[#concat+1] = '|cff8080cd'
						concat[#concat+1] = RIO.decode[4][difficulty]
						concat[#concat+1] = '|r '
						if count == bosses then
							concat[#concat+1] = count
						else
							concat[#concat+1] = "|c00ff0000"
							concat[#concat+1] = count
							concat[#concat+1] = "|r"
						end
						concat[#concat+1] = '/'
						concat[#concat+1] = bosses
						if has_pool then
							concat[#concat+1] = ' '
							for i=1,#pool do
								concat[#concat+1] = pool[i]
							end
						end
						concat[#concat+1] = "\n"
					end
				end
				concat[#concat+1] = format("\n|cff0000ff{%.0f",raw[1])
				for i=2,#raw do
					concat[#concat+1] = format(",%.0f",raw[i])
				end
				concat[#concat+1] = "}|r\n"
			end
			self:SetText(table.concat(concat))
		until true
		yd = coroutine.yield()
	end
	self.frame:SetScript("OnMouseDown",on_mousedown_origin)
	self.OnRelease = nil
	LFG_RIO:UnregisterAllEvents()
end

local AceGUI = LibStub("AceGUI-3.0")
AceGUI:RegisterWidgetType("LFG_RIO_INDICATOR", function()
	local label = AceGUI:Create("Label")
	local on_acquire = label.OnAcquire
	function label.OnAcquire(self)
		on_acquire(self)
		coroutine.wrap(co_label)(label)
	end
	label.SetMultiselect = nop
	label.type = "LFG_RIO_INDICATOR"
	label.SetLabel = nop
	label.SetList = nop
	label.SetDisabled = nop
	return AceGUI:RegisterAsWidget(label)
end,1)