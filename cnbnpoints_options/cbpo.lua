local cnbnpoints = LibStub("AceAddon-3.0"):GetAddon("cnbnpoints")
local options = cnbnpoints:NewModule("options","AceEvent-3.0")


local mapIDs =
{
375,	-- Mists of Tirna Scithe
376,	-- The Necrotic Wake
377,	-- De Other Side
378,	-- Halls of Atonement
379,	-- Plaguefall
380,	-- Sanguine Depths
381,	-- Spires of Ascension
382,	-- Theater of Pain
}

local generated_mp

local function mp_generation()
	local t = 
	{
	dungeons = random(1,#mapIDs),
	dead = random(0,3),
	upgrade = random(1,3),
	mythiclevel = random(10,15),
	item_level = floor(GetAverageItemLevel())
	}
	if generated_mp then
		wipe(generated_mp)
		for k,v in pairs(t) do
			generated_mp[k] = v
		end
	else
		generated_mp = t
	end
	return generated_mp
end

options.db = LibStub("AceDB-3.0"):New("cnbnpoints_db",{profile = {
mp = mp_generation()
}},true)

function options.IsSelected(groupname)
	local status_table = LibStub("AceConfigDialog-3.0"):GetStatusTable("cnbnpoints")
	if status_table.groups and status_table.groups.selected == groupname then
		return true
	end
end

function options.NotifyChangeIfSelected(groupname)
	if options.IsSelected(groupname) then
		LibStub("AceConfigRegistry-3.0"):NotifyChange("cnbnpoints")
		return true
	end
end

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local whats_new_desc =
{
	type = "description",
	order = 1,
	name = nop,
}

local ann_new_desc =
{
	type = "description",
	order = 2,
	name = nop,
}


local function shuffle(tb)
	local random = random
	for i = #tb,2,-1 do
		local r = random(1,i)
		local t = tb[r]
		tb[r] = tb[i]
		tb[i] = t
	end
	return tb
end


local class_color = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local classes = {}
for i=1,GetNumClasses() do
	local localized_class,english_class,id = GetClassInfo(i)
	classes[i] = "|c"..class_color[english_class].colorStr..localized_class.."|r"
end
local tank_classes = {[1]=true,[2]=true,[6]=true,[10]=true,[11]=true,[12]=true}
local healer_classes = {[2]=true,[5]=true,[7]=true,[10]=true,[11]=true}

local function fake_mpls()
	local maxlevel = GetMaxPlayerLevel()
	local UnitClass = UnitClass
	local leader,tank,healer,damager = GetLFGRoles()
	local my_role
	if tank then
		my_role = 1
	elseif healer then
		my_role = 2
	else
		my_role = 3
	end
	local lack_of_tank = my_role~=1
	local lack_of_healer = my_role~=2
	local chosen_units = {}
	local chosen_dps = {}
--	local myrealm = select(2,UnitFullName("player"))
	for i=1,255 do
		local u = "nameplate"..i
		if UnitExists(u) and UnitIsPlayer(u) and UnitIsFriend(u,"player")  then
			local fullname,fullserver = UnitFullName(u)
			local guid = UnitGUID(u)
			local _,_,class = UnitClass(u)
			if fullname and guid and class then
				if lack_of_tank and tank_classes[class] then
					lack_of_tank = false
					chosen_units[#chosen_units+1] = format('%s.%d.%d.%s', fullname, class, 1, guid)
				elseif lack_of_healer and healer_classes[class] then
					lack_of_healer = false
					chosen_units[#chosen_units+1] = format('%s.%d.%d.%s', fullname, class, 2, guid)
				else
					chosen_dps[#chosen_dps+1] = u
				end
			end
		end
	end
	if #chosen_dps < 3 then
		for i=1,#chosen_dps do
			local ci = chosen_dps[i]
			local name,server = UnitFullName(ci)
			chosen_units[i] = format('%s.%d.%d.%s', name, select(3,UnitClass(ci)), 3, UnitGUID(ci))
		end
	end
	local mp = options.db.profile.mp
	local mapname, unknown, timeLimit = C_ChallengeMode.GetMapUIInfo(mapIDs[mp.dungeons])
	local upgrade = mp.upgrade
	local time
	if upgrade == 1 then
		time = random(timeLimit*0.8,timeLimit)
	elseif upgrade == 2 then
		time = random(timeLimit*0.6,timeLimit*0.8)
	elseif upgrade == 3 then
		time = random(timeLimit*0.35,timeLimit*0.6)
	else
		time = random(timeLimit,7200)
	end
	local total_weight = random(15000,25000)
	local dps,hps,dtps
	if my_role == 1 then
		dps = random(15000,total_weight)
		hps = random(15000,total_weight)
		dtps = random(15000,total_weight)*1.4
	elseif my_role == 2 then
		dps = random(15000,total_weight)/20
		hps = random(15000,total_weight)*1.4
		dtps = random(15000,total_weight)/10
	else
		dps = random(15000,total_weight)*2.2
		hps = random(15000,total_weight)/20
		dtps = random(15000,total_weight)/10
	end
	cnbnpoints.send_awaits(nil,"APP_CHALLENGE2",UnitGUID("player"),mapIDs[mp.dungeons],mp.mythiclevel,time*1000,select(3,UnitClass("player")),mp.item_level,my_role,shuffle(chosen_units),
	{
		dd = floor(dps * time),
		dt = floor(dtps * time),
		hd = floor(hps * time),
		dps = floor(dps),
		hps = floor(hps),
		dead = mp.dead,
	})
end

local function mp_get_function(info)
	return options.db.profile.mp[info[#info]]
end

local function mp_set_function(info,val)
	options.db.profile.mp[info[#info]] = val
end

local mapNames = {}
for i=1,#mapIDs do
	mapNames[i] = C_ChallengeMode.GetMapUIInfo(mapIDs[i])
end

local mp_args=
{
	dungeons =
	{
		name = DUNGEONS,
		order = 1,
		type = "select",
		values = mapNames,
		get = mp_get_function,
		set = mp_set_function,
		width = "full"
	},
	mythiclevel =
	{
		name = CHALLENGE_MODE_ITEM_POWER_LEVEL:gsub(" %%d", ""),
		order = 2,
		type = "range",
		min = 2,
		max = 25,
		step = 1,
		get = mp_get_function,
		set = mp_set_function,

	},
	upgrade =
	{
		name = "+",
		min = 0,
		max = 3,
		step = 1,
		order = 3,
		type = "range",
		get = mp_get_function,
		set = mp_set_function,

	},
	dead =
	{
		name = DEAD,
		order = 4,
		min = 0,
		max = 10,
		step = 1,
		type = "range",
		get = mp_get_function,
		set = mp_set_function,

	},
	item_level =
	{
		name = LFG_LIST_ITEM_LEVEL_INSTR_SHORT,
		order = 5,
		min = 0,
		max = 550,
		type = "range",
		get = mp_get_function,
		set = mp_set_function,
		step = 1,
	}
}

local options_table =
{
	whatsnew =
	{
		order = 3,
		name = SPLASH_BASE_HEADER,
		type = "group",
		args =
		{
			whats_new_desc = whats_new_desc,
			ann_new_desc = ann_new_desc
		}
	},
	store =
	{
		order = 2,
		name = BLIZZARD_STORE,
		type = "group",
		args =
		{
		}
	},
	mp =
	{
		order = 1,
		name = CHALLENGES,
		type = "group",
		args =
		{
			submit =
			{
				name = SUBMIT,
				order = 6,
				type = "execute",
				func = function()
					local cvar = GetCVar("nameplateShowFriends")
					if not cvar and not InCombatLockdown() then
						SetCVar("nameplateShowFriends",true)
					end
					if not InCombatLockdown() then
						SetCVar("nameplateMaxDistance",100)
					end
					coroutine.wrap(fake_mpls)()
				end,
			},
			reset = 
			{
				name = RESET,
				order = 7,
				type = "execute",
				func = function()
					wipe(options.db.profile.mp)
					local mp = options.db.profile.mp
					for k,v in pairs(mp_generation()) do
						mp[k]=v
					end
				end
			},
		}
	}
}

for k,v in pairs(mp_args) do
	options_table.mp.args[k] = v
end

local function fillpoint()
	coroutine.wrap(function()
		if options_table.store.args.point then
			options_table.store.args.point = nil
			options.NotifyChangeIfSelected("store")
		end
		options_table.store.args.point =
		{
			name = cnbnpoints.send_awaits("MALLQUERY_RESULT","MALLQUERY",UnitGUID("player"),cnbnpoints.constant),
			type = "execute",
			func = fillpoint
		}
		options.NotifyChangeIfSelected("store")
	end)()
end

fillpoint()
--options.args.profile = AceDBOptions:GetOptionsTable(cnbnpoints.db)
--options.args.profile.order = -1
LibStub("AceConfig-3.0"):RegisterOptionsTable("cnbnpoints",
{
	type = "group",
	name = "cnbnpoints",
	args = options_table
})


coroutine.wrap(function()
	local str = cnbnpoints.send_awaits({"SDV","ActivitiesData"},"SLOGIN",cnbnpoints.constant2,UnitGUID("player"),0,nil,nil,true)
	local tb ={cnbnpoints:Deserialize(str:gsub('%$', '^'):gsub('%*', '~'))}
	local concat = {"|cff00ff00"}
	if tb[1] then
		local type = type
		for i=1,#tb do
			local tbi = tb[i]
			if type(tbi) == "string" then
				local enable, tabs, gift, mallList, mallData, lotteryItem, lottery = strsplit('`',tbi)
				if mallList then
					concat[#concat+1] = mallList
					concat[#concat+1] = "\n\n"
				end
			end
		end
		concat[#concat+1] = "|r"
		whats_new_desc.name = table.concat(concat)
	else
		whats_new_desc.name = str
	end
end)()

coroutine.wrap(function()
	local str = cnbnpoints.send_awaits({"SDV","AnnData"})
	local ok,tag,tb = cnbnpoints:Deserialize(str)
	local done,formatted = pcall(format,"|cffff0000%s|r\n%s",tb.title,tb.content)
	if done then
		ann_new_desc.name = formatted
	else
		ann_new_desc.name = str
	end
	options.NotifyChangeIfSelected("whatsnew")
end)()
