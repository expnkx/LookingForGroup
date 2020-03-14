local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

LookingForGroup_Options.option_table.args.find.args.f.args.pgf =
{
	name = "PGF",
	type = "group",
	args =
	{
		code =
		{
			name = "Premade Groups Filter",
			type = "input",
			multiline = true,
			width = "full",
			set = function(info,val)
				if val == "" then
					LookingForGroup_Options.db.profile.pgf_code = nil
				else
					LookingForGroup_Options.db.profile.pgf_code = val
				end
			end,
			get = function(info)
				return LookingForGroup_Options.db.profile.pgf_code
			end,
		}
	}
}

local numbers = {}

local env = {}
setmetatable(env, {__index = _G})

local effective_keywords = {"if","local","function","for","while","do","return","repeat"}

LookingForGroup_Options.RegisterSimpleFilterExpensive("find",function(info,profile,pgffunc)
	local activityID = info.activityID
	local activityName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = 
		C_LFGList.GetActivityInfo(activityID)
	wipe(env)
	for k,v in pairs(info) do
		env[k] = v
	end
	env.lfg = LookingForGroup
	env.lfg_opt = LookingForGroup_Options
	env.lfg_opt_profile = profile
	env.activity = activityID
	env.activityname = activityName:lower()
	env.autoinv = env.autoAccept
	env.questid = env.questID

	env.leader = env.leaderName:lower()
	env.age_minutes = env.age/60
	env.voice = env.voiceChat:len()~=0
	env.voicechat = env.voice
	env.ilvl = env.requiredItemLevel
	env.hlvl = env.requiredHonorLevel
	env.friends = env.numBNetFriends + env.numCharFriends + env.numGuildMates
	env.members = env.numMembers

--	to support IsDeclinedGroup???

--	env.bossesmatching = matching            fuck that we don't support shit like this. just use boss filter in LFG instead
	env.maxplayers = maxPlayers
	env.suggestedilvl = itemLevel
	env.minlvl = minLevel
	env.categoryid = categoryID
	env.groupid = groupID
	env.filters = filters
	local tank,healer,damager,tank_tb,healer_tb,damager_tb,classes =  LookingForGroup_Options.init_roles(env.searchResultID,env.numMembers)

	local GetClassInfo = GetClassInfo

	env.tanks = tank
	env.heals = healer
	env.healers = healer
	env.dps = damager

	for i=1,#tank_tb do
		local classlocale,class = GetClassInfo(i)
		class = class:lower()
		local t,h,d = tank_tb[i],healer_tb[i],damager_tb[i]
		local nm = t+h+d
		env[class] = nm
		env[class.."s"] = nm ~= 0 and nm or nil
		env[class.."_dps"]   = d
		env["dps_"..class]   = d 
		env["dps_"..class.."s"]  = d ~= 0 and d or nil
		env[class.."_heal"] = h
		env[class.."_heals"] = h ~= 0 and h or nil
		env["heal_"..class]  = h
		env["heal_"..class.."s"] = env[class.."_heals"]
		env[class.."_tank"] = t
		env[class.."_tanks"] = t ~= 0 and t or nil
		env["tank_"..class]  = t
		env["tank_"..class.."s"] = env[class.."_tanks"]
	end

	env.arena2v2 = activityID == 6 or activityID == 491
	env.arena3v3 = activityID == 7 or activityID == 490

	-- raids
	env.hm   = groupID == 14  -- Highmaul
	env.brf  = groupID == 15  -- Blackrock Foundry
	env.hfc  = groupID == 110  -- Hellfire Citadel
	env.en   = groupID == 122  -- The Emerald Nightmare
	env.nh   = groupID == 123  -- The Nighthold
	env.tov  = groupID == 126  -- Trial of Valor
	env.tos  = groupID == 131  -- Tomb of Sargeras
	env.atbt = groupID == 132  -- Antorus, the Burning Throne
	env.uldir= groupID == 135  -- Uldir
	env.bod = groupID == 251
	env.cs = groupID == 252
	env.tep = groupID == 254
	env.tep = env.ete
	env.nya = groupID == 258		-- Ny’alotha, the Waking City
	env.ny   = env.nya

	-- dungeons
	env.eoa  = groupID == 112  -- Eye of Azshara
	env.dht  = groupID == 113  -- Darkheart Thicket
	env.hov  = groupID == 114  -- Halls of Valor
	env.nl   = groupID == 115  -- Neltharion's Lair
	env.vh   = groupID == 116  -- Violet Hold
	env.votw = groupID == 117  -- Vault of the Wardens
	env.brh  = groupID == 118  -- Black Rook Hold
	env.mos  = groupID == 119  -- Maw of Souls
	env.cos  = groupID == 120 or groupID == 252  -- Court of Stars/Crucible of Storms
	env.aw   = groupID == 121  -- The Arcway
	env.lkara= groupID == 127 -- Lower Karazahn
	env.ukara= groupID == 128 -- Upper Karazhan
	env.kara = groupID == 125 or env.lkara or env.ukara  -- Karazhan
	env.coen = groupID == 129  -- Cathedral of Eternal Night
	env.sott = groupID == 133  -- Seat of the Triumvirate

	env.ad   = groupID == 137  -- Atal'Dazar
	env.tur  = groupID == 138  -- The Underrot
	env.tosl = groupID == 139  -- Temple of Sethraliss
	env.tml  = groupID == 140 -- The MOTHERLODE
	env.kr   = groupID == 141  -- Kings' Rest
	env.fh   = groupID == 142  -- Freehold
	env.sots = groupID == 143  -- Shrine of the Storm
	env.td   = groupID == 144  -- Tol Dagor
	env.wm   = groupID == 145  -- Waycrest Manor
	env.sob  = groupID == 146  -- Siege of Boralus
	env.opmj = groupID == 256  -- Operation: Mechagon - Junkyard
	env.opmw = groupID == 257  -- Operation: Mechagon - Workshop
	env.opm  = groupID == 253 or groupID == 256 or groupID == 257  -- Operation: Mechagon

	env.ml = env.tml
	env.undr = env.tur
	env.siege = env.sob

	env.hasrio       = false
	env.norio        = true
	env.rio          = 0
	env.riodps       = 0
	env.rioheal      = 0
	env.riotank      = 0
	env.riomain      = 0
	env.riokey5plus  = 0
	env.riokey10plus = 0
	env.riokey15plus = 0
	env.riokeymax    = 0
	local leaderName = info.leaderName
	if RaiderIO and RaiderIO.HasPlayerProfile(leaderName) then
		local result = RaiderIO.GetPlayerProfile(RaiderIO.ProfileOutput.MYTHICPLUS, leaderName)
		if result and result.profile then
			env.hasrio       = true
			env.norio        = false
			env.rio          = result.profile.mplusCurrent.score
			env.rioprev      = result.profile.mplusPrevious.score
			env.riomain      = result.profile.mplusMainCurrent.score
			env.riomainprev  = result.profile.mplusMainPrevious.score
			env.riokey5plus  = result.profile.keystoneFivePlus
			env.riokey10plus = result.profile.keystoneTenPlus
			env.riokey15plus = result.profile.keystoneFifteenPlus
			env.riokey20plus = result.profile.keystoneTwentyPlus
			env.riokeymax    = result.profile.maxDungeonLevel
		end
	end
	if not setfenv(pgffunc,env)() then
		return 1
	end
end,function(profile)
	local pgf_code = profile.pgf_code
	if pgf_code then
		local first_word = pgf_code:match("(%a+)")
		if first_word then
			for i=1,#effective_keywords do
				if first_word == effective_keywords[i] then
					return loadstring(pgf_code)
				end
			end
			wipe(numbers)
			numbers[1] = "return "
			numbers[2] = pgf_code
			return loadstring(table.concat(numbers))
		end
	end
end)
