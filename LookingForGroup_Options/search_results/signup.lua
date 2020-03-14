local LFG = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function still_valid(lfgid)
	local info = C_LFGList.GetSearchResultInfo(lfgid)
	return info and not info.isDelisted and select(2,C_LFGList.GetApplicationInfo(lfgid)) == "none"
end

local function maincofunc(select_sup,auto,convert_from_custom,notpressbutton,applyfunc)
	local numApplications, numActiveApplications = C_LFGList.GetNumApplications()
	local mapps = {}
	if select_sup == nil then
		for i=1,#auto do
			if 4 < #mapps + numActiveApplications then
				break
			end
			if convert_from_custom then
				local t = convert_from_custom(auto[i])
				for i=1,#t do
					if still_valid(t[i]) then
						mapps[#mapps+1] = t[i]
					end
				end
			elseif still_valid(auto[i]) then
				mapps[#mapps+1] = auto[i]
			end
		end
	else
		for k,v in pairs(select_sup) do
			if 4 < #mapps + numActiveApplications then
				break
			end
			if v then
				if convert_from_custom then
					local t = convert_from_custom(auto[k])
					for i=1,#t do
						if still_valid(t[i]) then
							mapps[#mapps+1] = t[i]
						end
					end
					if #mapps + numActiveApplications <= 5 then
						select_sup[k] = nil
					end
				elseif still_valid(k) then
					select_sup[k] = nil
					mapps[#mapps+1] = k
				end
			end
		end
	end
	while #mapps~=0 and 5 < #mapps + numActiveApplications do
		mapps[#mapps] = nil
	end
	if #mapps == 0 then
		return
	end
	
	local lfg_profile = LFG.db.profile
	local hardware = lfg_profile.hardware
	local role_check = lfg_profile.role_check
	if not role_check then
		local leader,tank,healer,dps = GetLFGRoles()
		if not tank and not healer and not dps then
			role_check = true
		end
	end
	local LFGListApplicationDialog = LFGListApplicationDialog
	local SignUpButton = LFGListApplicationDialog.SignUpButton
	local original_onclick = SignUpButton:GetScript("OnClick")
	local original_onhide = SignUpButton:GetScript("OnHide")
	local current = coroutine.running()
	applyfunc = applyfunc or C_LFGList.ApplyToGroup
	local function event_func(...)
		LFG.resume(current,...)
	end
	if hardware then
		local gain = not notpressbutton and not role_check
		while #mapps~=0 do
			local m = mapps[#mapps]
			if still_valid(m) then
				if not gain then
					SignUpButton:SetScript("OnClick",function()
						LFG.resume(current,"SignUpButton_OnClick")
					end)
					SignUpButton:SetScript("OnHide",function()
						LFG.resume(current,"SignUpButton_OnHide")
					end)
					LFGListApplicationDialog_UpdateRoles(LFGListApplicationDialog)
					StaticPopupSpecial_Show(LFGListApplicationDialog)
					local y,isrunning = coroutine.yield()
					SignUpButton:SetScript("OnHide",original_onhide)
					SignUpButton:SetScript("OnClick",original_onclick)
					if y ~= "SignUpButton_OnHide" then
						StaticPopupSpecial_Hide(LFGListApplicationDialog)
					end
					if y ~= "SignUpButton_OnClick" then
						return
					end
				end
				local leader,tank,healer,dps = GetLFGRoles()
				applyfunc(m,tank,healer,dps)
				gain = false
			end
			mapps[#mapps] = nil
		end
	else
		if role_check then
			SignUpButton:SetScript("OnClick",function()
				LFG.resume(current,"SignUpButton_OnClick")
			end)
			SignUpButton:SetScript("OnHide",function()
				LFG.resume(current,"SignUpButton_OnHide")
			end)
			LFGListApplicationDialog_UpdateRoles(LFGListApplicationDialog)
			StaticPopupSpecial_Show(LFGListApplicationDialog)
			local y,isrunning = coroutine.yield()
			SignUpButton:SetScript("OnHide",original_onhide)
			SignUpButton:SetScript("OnClick",original_onclick)
			if y ~= "SignUpButton_OnHide" then
				StaticPopupSpecial_Hide(LFGListApplicationDialog)
			end
			if y == "LFG_SIGN_UP" then
				isrunning.isrunning =true
			end
			if y ~= "SignUpButton_OnClick" then
				return
			end
		end
		local leader,tank,healer,dps = GetLFGRoles()
		for i=1,#mapps do
			applyfunc(mapps[i],tank,healer,dps)
		end
	end
end

function LFG_OPT.signup_cofunc(...)
	local co = coroutine.create(maincofunc)
	coroutine.resume(co,...)
	return co
end

local function coempty()
	local LFGListApplicationDialog = LFGListApplicationDialog
	local SignUpButton = LFGListApplicationDialog.SignUpButton
	local original_onclick = SignUpButton:GetScript("OnClick")
	local original_onhide = SignUpButton:GetScript("OnHide")
	local current = coroutine.running()
	SignUpButton:SetScript("OnClick",function()
		LFG.resume(current,"SignUpButton_OnClick")
	end)
	SignUpButton:SetScript("OnHide",function()
		LFG.resume(current,"SignUpButton_OnHide")
	end)
	LFGListApplicationDialog_UpdateRoles(LFGListApplicationDialog)
	StaticPopupSpecial_Show(LFGListApplicationDialog)
	local y,isrunning = coroutine.yield()
	SignUpButton:SetScript("OnHide",original_onhide)
	SignUpButton:SetScript("OnClick",original_onclick)
	if y ~= "SignUpButton_OnHide" then
		StaticPopupSpecial_Hide(LFGListApplicationDialog)
	end
end

function LFG_OPT.signup_empty()
	if not LFGListApplicationDialog:IsShown() then
		coroutine.wrap(coempty)()
	end
end
