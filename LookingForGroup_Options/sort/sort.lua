local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function compare(ae,be)
	if ae == nil or be == nil then
		if ae and be == nil then
			return true
		elseif ae == nil and be then
			return false
		end
	else
		local tp = type(ae)
		if tp == "boolean" then
			if ae and be == false then
				return true
			elseif ae == false and be then
				return false
			end
		else
			if ae < be then
				return true
			elseif ae~= be then
				return false
			end
		end
	end
end

function LookingForGroup_Options.SortSearchResults(results_tb)
	local profile = LookingForGroup_Options.db.profile
	if profile.sortby_shuffle then
		local random = random
		for i = #results_tb,2,-1 do
			local r = random(1,i)
			local t = results_tb[r]
			results_tb[r] = results_tb[i]
			results_tb[i] = t
		end
		return
	end
	local sort = profile.sort
	if sort then
		local type = type
		local n = #sort
		if n~= 0 then
			local C_LFGList_GetSearchResultInfo = C_LFGList.GetSearchResultInfo
			for i=1,#results_tb do
				local t = C_LFGList_GetSearchResultInfo(results_tb[i])
				t[1]=t.searchResultID
				t[2]=t.activityID
				t[3]=t.name
				t[4]=t.comment
				t[5]=t.voiceChat
				t[6]=t.requiredItemLevel
				t[7]=t.requiredHonorlevel
				t[8]=t.age
				t[9]=t.numBNetFriends
				t[10]=t.numGuildMates
				t[11]=t.IsDelisted
				t[12]=t.leaderName
				t[13]=t.numMembers
				t[14]=t.autoAccept
				t[15]=t.questID
				results_tb[i] = t
			end
			table.sort(results_tb,function(ta,tb)
				for i=1,n do
					local ele = sort[i]
					if ele < 0 then
						ele = -ele
						local d = compare(ta[ele],tb[ele])
						if d then
							return
						elseif d == false then
							return true
						end
					else
						local d = compare(ta[ele],tb[ele])
						if d then
							return true
						elseif d == false then
							return
						end
					end
				end
			end)
			for i=1,#results_tb do
				results_tb[i] = results_tb[i].searchResultID
			end
		end
	end
end