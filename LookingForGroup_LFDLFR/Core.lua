local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")
local order = 0
local function get_order()
	local temp = order
	order = order+1
	return temp
end

local selected_dungeon
local dungeons_tb = {}

local selected_spd_tb, selected_rf_tb = {},{}

function LFG_OPT:LFG_UPDATE()
	local k,v = next(selected_rf_tb)
	if v and GetLFGMode(3,k) then
		selected_rf_tb[k] = nil
	end
	k,v = next(selected_spd_tb)
	if v and GetLFGMode(1,k) then
		selected_rf_tb[k] = nil
	end
	self.NotifyChangeIfSelected("lfd")
	self.NotifyChangeIfSelected("lfd\1spd")
	self.NotifyChangeIfSelected("rf")
end

LFG_OPT:RegisterEvent("LFG_UPDATE")

local function factory(widget_name,dungeoninfofunc,callback,style)
	local AceGUI = LibStub("AceGUI-3.0")
	AceGUI:RegisterWidgetType(widget_name,function()
		local control = AceGUI:Create("InlineGroup")
		control.type = widget_name
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
			local t = {}
			control.SetItemValue = function(self,key)
				local kval = self.values[key]
				local check = AceGUI:Create("CheckBox")
				if style then
					check:SetType(style)
				end
				local id, name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, 
					maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers,
					description, isHoliday, bonusRepAmount, minPlayers, isTimewalker , raidname, ilvl = dungeoninfofunc(kval)
				local numCompletions, isWeekly = LFGRewardsFrame_EstimateRemainingCompletions(id)
				if IsLFGDungeonJoinable(id) then
					wipe(t)
					if numCompletions <= 0 then
						t[#t+1] = name
					else
						t[#t+1] = "|cff00ff00"
						t[#t+1] = name
						t[#t+1] = "|r"
					end
					for i = 1,LFG_ROLE_NUM_SHORTAGE_TYPES do
						local eligible, forTank, forHealer, forDamage, itemCount, money, xp = GetLFGRoleShortageRewards(id,i)
						if itemCount ~= 0 or money ~= 0 or xp ~= 0 then
							if forTank then
								t[#t+1] = "|T337497:16:16:0:0:64:64:0:19:22:41|t"
							end
							if forHealer then
								t[#t+1] = "|T337497:16:16:0:0:64:64:20:39:1:20|t"
							end
							if forDamage then
								t[#t+1] = "|T337497:16:16:0:0:64:64:20:39:22:41|t"
							end
						end
					end
					check:SetLabel(table.concat(t))
				else
					wipe(t)
					t[#t+1] = "|cffcccccc"
					t[#t+1] = name
					t[#t+1] = "|r"
					check:SetLabel(table.concat(t))
				end
				if raidname ~= "" then
					wipe(t)
					t[#t+1] = "|cff8080cc"
					if raidname == name then
						t[#t+1] = _G["PLAYER_DIFFICULTY"..subtypeID]
					else
						t[#t+1] = raidname
					end
					t[#t+1] = "|r"
					check:SetDescription(table.concat(t))
				else
					check:SetDescription()
				end
				if textureFilename then
					check.image:SetSize(80,45)
					check:SetImage(textureFilename)
				end
				check:SetCallback("OnValueChanged",callback(check,id,control))
				check:SetCallback("OnLeave", function(self,...)
					GameTooltip:Hide()
				end)
				check:SetCallback("OnEnter", function(self,...)
					GameTooltip:SetOwner(self.frame,"ANCHOR_TOPRIGHT")
					GameTooltip:ClearLines()
					GameTooltip:AddDoubleLine(name,id)
					if raidname ~= "" then
						if raidname == name then
							GameTooltip:AddLine(_G["PLAYER_DIFFICULTY"..subtypeID])
						else
							GameTooltip:AddLine(raidname)
						end
					end
					
					if description ~= "" then
						GameTooltip:AddLine(description, 0.5, 0.5, 0.8, true)
						GameTooltip:AddLine(" ")
					end
					local doneToday, moneyAmount, moneyVar, experienceGained, experienceVar, numRewards, spellID = GetLFGDungeonRewards(id)
					if maxLevel == 255 then
						GameTooltip:AddDoubleLine(LEVEL,minLevel.."+",0.5,0.5,0.8,true)
					elseif minLevel == maxLevel then
						if minLevel ~= GetMaxPlayerLevel() then
							GameTooltip:AddDoubleLine(LEVEL,minLevel,0.5,0.5,0.8,true)
						end
					else
						GameTooltip:AddDoubleLine(LEVEL,minLevel.."-"..maxLevel,0.5,0.5,0.8,true)
					end
					if ilvl then
						GameTooltip:AddDoubleLine(ITEM_LEVEL_ABBR,ilvl, 0.5, 0.5, 0.8, true)
					end
					if numCompletions ~= 0 then
						GameTooltip:AddDoubleLine(isWeekly and WEEKLY or DAILY,numCompletions,0.5,0.5,0.8,true)
					end
					if moneyAmount ~= 0 then
						local g = math.floor(moneyAmount/10000)
						local c = moneyAmount%10000
						GameTooltip:AddDoubleLine(MONEY,table.concat{g,"|T237618:12:12|t",
																	math.floor(c/100),"|T237620:12:12|t",
																	c%100,"|T237617:12:12|t"},0.5,0.5,0.8,true)
					end
					if experienceGained ~= 0 then
						GameTooltip:AddDoubleLine(XP,experienceGained,0.5,0.5,0.8,true)
					end
					if numRewards ~= 0 then
						local GetLFGDungeonRewardInfo = GetLFGDungeonRewardInfo	
						for i=1,numRewards do
							local name,texture,count = GetLFGDungeonRewardInfo(id,i)
							GameTooltip:AddDoubleLine(name,count,0.5,0.5,0.8,true)
						end
					end
					for i = 1,LFG_ROLE_NUM_SHORTAGE_TYPES do
						local eligible, forTank, forHealer, forDamage, itemCount, money, xp = GetLFGRoleShortageRewards(id,i)
						if itemCount ~= 0 or money ~= 0 or xp ~= 0 then
							wipe(t)
							if forTank then
								t[#t+1] = "|T337497:16:16:0:0:64:64:0:19:22:41|t"
							end
							if forHealer then
								t[#t+1] = "|T337497:16:16:0:0:64:64:20:39:1:20|t"
							end
							if forDamage then
								t[#t+1] = "|T337497:16:16:0:0:64:64:20:39:22:41|t"
							end
							if #t ~= 0 then
								GameTooltip:AddDoubleLine(table.concat(t),i,nil,nil,nil,0.5,0.5,0.8,true)
								if money ~= 0 then
									local g = math.floor(money/10000)
									local c = money%10000
									GameTooltip:AddDoubleLine(MONEY,table.concat{g,"|T237618:12:12|t",
																				math.floor(c/100),"|T237620:12:12|t",
																				c%100,"|T237617:12:12|t"},0.5,0.5,0.8,true)
								end
								if xp ~= 0 then
									GameTooltip:AddDoubleLine(XP,xp,0.5,0.5,0.8,true)
								end
								for j=1,itemCount do
									local name,texture,count = GetLFGDungeonShortageRewardInfo(id,i,j)
									GameTooltip:AddDoubleLine(name,count,0.5,0.5,0.8,true)
								end
							end
						end
					end
					if isTimewalker then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(LFD_TIMEWALKER_RANDOM_EXPLANATION,nil,nil,nil,true)
					end
					local numEncounters = GetLFGDungeonNumEncounters(id)
					if numEncounters ~= 0 then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(numEncounters)
						for j = 1, numEncounters do
							local bossName, _, isKilled = GetLFGDungeonEncounterInfo(id, j);
							if isKilled then
								GameTooltip:AddLine(bossName,1,0,0,true)
							else
								GameTooltip:AddLine(bossName)
							end
						end
					end
					if not IsLFGDungeonJoinable(id) then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(LFGConstructDeclinedMessage(id),1,0,0,true)
					end
					GameTooltip:Show()
				end)
				check.width = "fill"
				self:AddChild(check)
			end
		end
		return AceGUI:RegisterAsContainer(control)
	end,1)
end

factory("LFG_OPT_LFD",GetLFGRandomDungeonInfo,function(check,id,control)
	if selected_dungeon == id then
		check:SetValue(true)
	else
		check:SetValue(false)
	end
	return function(self,_,val)
		if IsLFGDungeonJoinable(id) then
			selected_dungeon = id
			local children = control.children
			for i=1,#children do
				children[i]:SetValue(false)
			end
			check:SetValue(true)
		else
			check:SetValue(false)
		end
	end
end,"radio")

local rf_tb = {}
LFG_OPT:push("lfd",
{
	name = LOOKING_FOR_DUNGEON,
	type = "group",
	args =
	{
		lfd =
		{
			name = LFG_TYPE_RANDOM_DUNGEON,
			type = "multiselect",
			order = get_order(),
			values = function()
				wipe(dungeons_tb)
				for i=1,GetNumRandomDungeons() do
					local id, name = GetLFGRandomDungeonInfo(i)
					local isAvailable, isAvailableToPlayer, hideIfUnmet = IsLFGDungeonJoinable(id)
					if LFG_IsRandomDungeonDisplayable(id) then
						dungeons_tb[#dungeons_tb+1] = i
					end
				end
				if selected_dungeon == nil then
					selected_dungeon = GetRandomDungeonBestChoice()
				end
				return dungeons_tb
			end,
			width = "full",
			dialogControl = "LFG_OPT_LFD"
		},
		exec =
		{
			type = "execute",
			name = function()
				if GetLFGQueueStats(1) then
					return LEAVE_QUEUE
				else
					return FIND_A_GROUP
				end
			end,
			order = get_order(),
			func = function()
				if GetLFGQueueStats(1) then
					LeaveLFG(1)
				elseif selected_dungeon then
					ClearAllLFGDungeons(1)
					JoinSingleLFG(1,selected_dungeon)
				end
			end
		},
		backfill =
		{
			type = "execute",
			name = L.Backfill,
			desc = function()
				if CanPartyLFGBackfill() then
					return format(LFG_OFFER_CONTINUE,"|cffff00ff"..GetLFGDungeonInfo(GetPartyLFGID()).."|r")
				end
			end,
			order = get_order(),
			func = PartyLFGStartBackfill
		},
		spd =
		{
			name = SPECIFIC_DUNGEONS,
			type = "group",
			args=
			{
				sd =
				{
					type = "multiselect",
					name = SPECIFIC_DUNGEONS,
					order = get_order(),
					tristate = true,
					values = function()
						wipe(rf_tb)		
						local GetLFGDungeonInfo = GetLFGDungeonInfo
						local GetLFDLockInfo = GetLFDLockInfo
						local IsLFGDungeonJoinable = IsLFGDungeonJoinable
						local i = 1
						local k = 0
						local myLevel = UnitLevel("player")
						while true do
							local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, 
										difficulty, maxPlayers, description, isHoliday, bonusRepAmount, minPlayers, isRandomTimewalker,
										mapName, minGear, isScalingDungeon = GetLFGDungeonInfo(i)
							if name == nil then
								k = k + 1
								if k == 500 then
									break
								end
							else
								k = 0
								if typeID == 1 and (subtypeID == 1 or subtypeID == 2) and (textureFilename == nil or textureFilename > 0) and minLevel <= myLevel and myLevel <= maxLevel and maxLevel ~= 255 and EXPANSION_LEVEL >= expansionLevel and not isHoliday and not isRandomTimewalker then
									local _,lockreason = GetLFDLockInfo(i,1)
									if lockreason ~= 10 then
										rf_tb[#rf_tb + 1] = i
									end
								end
							end
							i = i + 1
						end
						return rf_tb
					end,
					width = "full",
					dialogControl = "LFG_OPT_SPD"
				},
				apply =
				{
					type = "execute",
					name = SIGN_UP,
					order = get_order(),
					func = function()
						for k,v in pairs(selected_spd_tb) do
							if v then
								if GetLFGMode(1,k) then
									LeaveSingleLFG(1,k)
									selected_spd_tb[k] = nil
								end
							end
						end
						local k,v = next(selected_spd_tb)
						if v then
							ClearAllLFGDungeons(1)
							SetLFGDungeon(1,k)
							JoinLFG(1)
						end
					end
				},
				all =
				{
					type = "execute",
					name = ALL,
					order = get_order(),
					func = function()
						if next(selected_spd_tb) then
							wipe(selected_spd_tb)
							return
						end
						local IsLFGDungeonJoinable = IsLFGDungeonJoinable
						for i=1,#rf_tb do
							local id = rf_tb[i]
							if IsLFGDungeonJoinable(id) and not GetLFGMode(1,id) then
								selected_spd_tb[id] = true
							end
						end
					end
				},
				leaveall =
				{
					type = "execute",
					name = LEAVE_ALL_QUEUES,
					order = get_order(),
					func = function()
						for i = 1,#rf_tb do
							local id = rf_tb[i]
							if IsLFGDungeonJoinable(id) then
								LeaveSingleLFG(1,id)
							end
						end
						wipe(selected_spd_tb)
					end
				},
				cancel =
				{
					type = "execute",
					name = CANCEL,
					order = get_order(),
					func = function()
						wipe(selected_spd_tb)			
					end
				},
			}
		}
	}
})

LFG_OPT:push("rf",
{
	name = RAID_FINDER,
	type = "group",
	args=
	{
		rf =
		{
			type = "multiselect",
			name = RAID_FINDER,
			order = get_order(),
			tristate = true,
			values = function()
				wipe(rf_tb)
				local LFG_IsRandomDungeonDisplayable = LFG_IsRandomDungeonDisplayable
				local GetRFDungeonInfo = GetRFDungeonInfo
				local GetLFGDungeonNumEncounters = GetLFGDungeonNumEncounters
				local GetLFGDungeonEncounterInfo = GetLFGDungeonEncounterInfo
				local all_dg = LFG_OPT.db.profile.lfdrf_all_dg			
				for i = 1,GetNumRFDungeons() do
					local id = GetRFDungeonInfo(i)
					local isAvailable, isAvailableToPlayer, hideIfUnmet = IsLFGDungeonJoinable(id)
					if LFG_IsRandomDungeonDisplayable(id) and not hideIfUnmet then
						if all_dg then
							rf_tb[#rf_tb + 1] = i
						else
							local numEncounters = GetLFGDungeonNumEncounters(id)
							local j = 1
							while j <= numEncounters do
								local _, _, isKilled = GetLFGDungeonEncounterInfo(id, j)
								if not isKilled then
									break
								end								
								j = j + 1
							end
							if j <= numEncounters then
								rf_tb[#rf_tb + 1] = i
							end
						end
					end
				end
				return rf_tb
			end,
			width = "full",
			dialogControl = "LFG_OPT_RF"
		},
		apply =
		{
			type = "execute",
			name = SIGN_UP,
			order = get_order(),
			func = function()
				for k,v in pairs(selected_rf_tb) do
					if v then
						if GetLFGMode(3,k) then
							LeaveSingleLFG(3,k)
							selected_rf_tb[k] = nil
						end
					end
				end
				local k,v = next(selected_rf_tb)
				if v then
					ClearAllLFGDungeons(3)
					SetLFGDungeon(3,k)
					JoinLFG(3)
				end
			end
		},
		all =
		{
			type = "execute",
			name = ALL,
			order = get_order(),
			func = function()
				if next(selected_rf_tb) then
					wipe(selected_rf_tb)
					return
				end
				local IsLFGDungeonJoinable = IsLFGDungeonJoinable
				for i=1,#rf_tb do
					local id = GetRFDungeonInfo(rf_tb[i])
					if IsLFGDungeonJoinable(id) and not GetLFGMode(3,id) then
						selected_rf_tb[id] = true
					end
				end
			end
		},
		leaveall =
		{
			type = "execute",
			name = LEAVE_ALL_QUEUES,
			order = get_order(),
			func = function()
				for i = 1,GetNumRFDungeons() do
					local id = GetRFDungeonInfo(i)
					if IsLFGDungeonJoinable(id) then
						LeaveSingleLFG(3,id)
					end
				end
				wipe(selected_rf_tb)
			end
		},
		cancel =
		{
			type = "execute",
			name = CANCEL,
			order = get_order(),
			func = function()
				wipe(selected_rf_tb)			
			end
		},
		sall =
		{
			type = "toggle",
			name = ALL,
			order = -1,
			set = function(_,val)
				LFG_OPT.db.profile.lfdrf_all_dg = val or nil
			end,
			get = function()
				return LFG_OPT.db.profile.lfdrf_all_dg
			end,
		}
	}
})

local function select_generator_factory(lfg_mode,selected_tb)
	return function(check,id)
		check:SetTriState(true)
		local state = selected_tb[id]
		if GetLFGMode(lfg_mode,id) then
			if state then
				check:SetValue(false)
			else
				check:SetValue(nil)
			end
		else
			if state then
				check:SetValue(true)
			elseif state == nil then
				check:SetValue(false)
			end
		end
		return function(self,_,val)
			if GetLFGMode(lfg_mode,id) then
				if val == false then
					selected_tb[id] = true
					self:SetValue(false)
				else
					selected_tb[id] = nil
					self:SetValue(nil)
				end
			else
				if val and IsLFGDungeonJoinable(id) then
					selected_tb[id] = true
					self:SetValue(true)
				else
					selected_tb[id] = nil
					self:SetValue(false)
				end
			end
		end
	end
end

factory("LFG_OPT_SPD",function(id) return id,GetLFGDungeonInfo(id) end,select_generator_factory(1,selected_spd_tb))
factory("LFG_OPT_RF",GetRFDungeonInfo,select_generator_factory(3,selected_rf_tb))

if LibStub("AceAddon-3.0"):GetAddon("LookingForGroup").disable_pve_frame then

function LFG_OPT:AJ_DUNGEON_ACTION(event,id)
	selected_dungeon=id
	self.aj_open_action("lfd")
end

function LFG_OPT:AJ_RAID_ACTION(event,id)
	selected_rf_tb[id]=true
	self.aj_open_action("rf")
end

function LFG_OPT:LFG_OPEN_FROM_GOSSIP(event,id)
	selected_spd_tb[id]=true
	self.aj_open_action("lfd","spd")
end

LFG_OPT:RegisterEvent("AJ_DUNGEON_ACTION")
LFG_OPT:RegisterEvent("AJ_RAID_ACTION")
LFG_OPT:RegisterEvent("LFG_OPEN_FROM_GOSSIP")

end