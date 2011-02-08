--[[
	
	oUF_Nifty

	Author:		Nifty
	Mail:		post@endlessly.de
	URL:		http://www.wowinterface.com/list.php?skinnerid=62149
	
	Credits:	oUF_TsoHG (used as base) / http://www.wowinterface.com/downloads/info8739-oUF_TsoHG.html
				Rothar for buff border (and Neal for the edited version)
				p3lim for party toggle function

--]]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}
--local texture = [=[Interface\AddOns\oUF_P3lim\minimalist]=]
-- ------------------------------------------------------------------------
-- local horror
-- ------------------------------------------------------------------------
local select = select
local UnitClass = UnitClass
local UnitIsDead = UnitIsDead
local UnitIsPVP = UnitIsPVP
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction
local UnitIsConnected = UnitIsConnected
local UnitCreatureType = UnitCreatureType
local UnitClassification = UnitClassification
local UnitReactionColor = UnitReactionColor
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

-- ------------------------------------------------------------------------
-- font, fontsize and textures
-- ------------------------------------------------------------------------
local font = "Interface\\AddOns\\oUF_Nifty\\fonts\\font.ttf"
local upperfont = "Interface\\AddOns\\oUF_Nifty\\fonts\\upperfont.ttf"
local fontsize = 15
local bartex = "Interface\\AddOns\\oUF_Nifty\\textures\\statusbar"
local bufftex = "Interface\\AddOns\\oUF_Nifty\\textures\\border"
local playerClass = select(2, UnitClass("player"))

-- castbar position
local playerCastBar_x = 0
local playerCastBar_y = -300
local targetCastBar_x = 11
local targetCastBar_y = -200

-- ------------------------------------------------------------------------
-- change some colors :)
-- ------------------------------------------------------------------------

local colors = setmetatable({
	health = {.45, .73, .27},
	power = setmetatable({
		['RAGE'] = {.73, .27, .27}
	}, {__index = oUF.colors.power})
}, {__index = oUF.colors})

-- ------------------------------------------------------------------------
-- right click
-- ------------------------------------------------------------------------
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

-- ------------------------------------------------------------------------
-- reformat everything above 9999, i.e. 10000 -> 10k
-- ------------------------------------------------------------------------
local numberize = function(v)
	if v <= 999 then return v end
	if v >= 1000000 then
		local value = string.format("%.1fm", v/1000000)
		return value
	elseif v >= 1000 then
		local value = string.format("%.1fk", v/1000)
		return value
	end
end

oUF.Tags['nifty:level'] = function (unit)
	local lvl = UnitLevel(unit)
	local class = UnitClassification(unit)
	local color = GetQuestDifficultyColor(lvl)
	local tagValue
	
	if lvl <= 0 then
		lvl = "??"
	end
	
	if class == "worldboss" then
		tagValue = "|cffff0000" .. lvl .. "b|r"
	elseif class == "rareelite" then
		tagValue = lvl .. "r+"
	elseif class == "elite" then
		tagValue = lvl .. "+"
	elseif class == "rare" then
		tagValue = lvl .. "r"
	else
		if UnitIsConnected(unit) == nil then
			tagValue = "??"
		else
			tagValue = lvl
		end
	end
	
	return tagValue
end

-- ------------------------------------------------------------------------
-- serendipity update
-- ------------------------------------------------------------------------

oUF.Tags['nifty:serendipity'] = function(u)
    local _, _, _, count = UnitAura("player", "Serendipity"); return "" and count --'|cff0080ff.|r'
end
oUF.TagEvents['nifty:serendipity'] = "UNIT_AURA"


-- ------------------------------------------------------------------------
-- name update
-- ------------------------------------------------------------------------
local updateName = function(self, event, unit)
	if(self.unit ~= unit) then return end

	local name = UnitName(unit)
    self.Name:SetText(string.lower(name or ""))
	
	if unit=="targettarget" then
		local totName = UnitName(unit)
		local pName = UnitName("player")
		if totName==pName then
			self.Name:SetTextColor(0.9, 0.5, 0.2)
		else
			self.Name:SetTextColor(1,1,1)
		end
	else
		self.Name:SetTextColor(1,1,1)
	end
	   
    if unit=="target" then -- Show level value on targets only
		updateLevel(self, unit, name)      
    end
end


-- ------------------------------------------------------------------------
-- health update
-- ------------------------------------------------------------------------
local updateHealth = function(self, event, unit, bar, min, max)  
    local cur, maxhp = min, max
	local missing = maxhp-cur
	local isfriend = UnitIsFriend("player", "target")
    local unitLvl = UnitLevel("target")
    
    local d = floor(cur/maxhp*100)
    
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
		bar.value:SetText"dead"
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText"offline"
    elseif(unit == "player") then
		if(min ~= max) then
			bar.value:SetText("|cff33EE44"..numberize(cur) .."|r"--[[.. d.."%"]])
		else
			bar.value:SetText(" ")
		end
	elseif(unit == "targettarget" or unit == "focus") then
		bar.value:SetText(d.."%")
    elseif(unit == "target") then
		if(d < 100 and isfriend) then
			bar.value:SetText("|cffff7f74-"..missing.."|r |cff33EE44"..numberize(cur).."/"..numberize(maxhp).."|r"--[[..d.."%"]])
        elseif(unitLvl == -1) then
            bar.value:SetText("|r |cff33EE44"..numberize(cur).."|r |cff33EE44"..d.."%|r")
		elseif(d < 100) then
			bar.value:SetText("|r |cff33EE44"..numberize(cur).."/"..numberize(maxhp).."|r")
		else
			bar.value:SetText("|cff33EE44"..numberize(maxhp).."|r")
		end

	elseif(min == max) then
        if unit == "pet" then
			bar.value:SetText(" ") -- just here if otherwise wanted
		else
			bar.value:SetText(" ")
		end
    else
        if((max-min) < max) then
			if unit == "pet" then
				bar.value:SetText("-"..maxhp-cur) -- negative values as for party, just here if otherwise wanted
			else
				bar.value:SetText("-"..maxhp-cur) -- this makes negative values (easier as a healer)
			end
	    end
    end

    self:UNIT_NAME_UPDATE(event, unit)
end

oUF.Tags['nifty:health'] = function (unit)	
	if not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit) then 
		return
	end
	
	local curHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
	local deficitHp = curHp - maxHp
	local percentHp = floor(curHp / maxHp * 100)
	local isFriend = UnitIsFriend("player", "target")
	local unitLvl = UnitLevel("target")
	local tagValue
	
	if unit == "player" then
		if curHp ~= maxHp then
			tagValue = "|cff33EE44" .. numberize(curHp) .. "|r"
		else
			return "";
		end
	elseif unit == "targettarget" or unit == "focus" then
		tagValue = deficitHp .. "%"
	elseif unit == "target" then
		if percentHp < 100 and isFriend then
			tagValue = "|cffff7f74" .. deficitHp .. "|r |cff33EE44" .. numberize(cur) .. "/" .. numberize(maxHp) .. "|r"
		elseif unitLvl == -1 then
			tagValue = "|r |cff33EE44" .. numberize(curHp) .. "|r |cff33EE44" .. percentHp .."%|r"
		elseif percentHp < 100 then
			tagValue = "|r |cff33EE44" .. numberize(curHp) .. "/" .. numberize(maxHp) .. "|r"
		else
			tagValue = "|cff33EE44" .. numberize(maxHp) .. "|r"
		end
	elseif curHp == maxHp then
		tagValue = "" -- maybe pet condition here?
	else
		if (maxHp - curHp) < maxHp then
			if unit == "pet" then
				tagValue = "-" .. maxHp - curHp
			else
				tagValue = "-" .. maxHp - curHp
			end
		end
	end
		
	return tagValue
end
oUF.TagEvents['nifty:health'] = oUF.TagEvents.missinghp

oUF.Tags['nifty:power'] = function (unit)
	if not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit) then 
		return
	end

	local min, max = UnitPower(unit), UnitPowerMax(unit)
	local tagValue
	
	if UnitIsPlayer(unit) == nil then
		tagValue = ""
	else
		local _, ptype = UnitPowerType(unit)
		local color = colors.power[ptype]
		
		if min == 0 then
			tagValue = ""
		elseif unit == "player" then
			if (max - min) > 0 then
				tagValue = min
			elseif min == max then
				tagValue = ""
			else
				tagValue = min
			end
		else
			if (max - min) > 0 then
				tagValue = min
			else
				tagValue = min
			end
		end
	end
	
	return tagValue
end
oUF.TagEvents['nifty:power'] = oUF.TagEvents.missingpp

-- ------------------------------------------------------------------------
-- aura reskin
-- ------------------------------------------------------------------------
local auraIcon = function(self, button, icons)
	icons.showDebuffType = true -- show debuff border type color  
	
	button.icon:SetTexCoord(.07, .93, .07, .93)
	button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	
	button.overlay:SetTexture(bufftex)
	button.overlay:SetTexCoord(0,1,0,1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.3, 0.3, 0.3) end
	
	button.cd:SetReverse()
	button.cd:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2) 
	button.cd:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)     
end

-- ------------------------------------------------------------------------
-- the layout starts here
-- ------------------------------------------------------------------------

local UnitSpecific = {
	player = function (self, ...)
		self.Level:Hide()
		
		self.Power.value:Show()
	
        -- Serendipity counter
        self.Serendipity = self:CreateFontString(nil, "OVERLAY")
        self.Serendipity:SetPoint("LEFT", self, "RIGHT", 10, 0)
        self.Serendipity:SetFont(font, 20, "OUTLINE")
        self.Serendipity:SetTextColor(0, 0.81, 1)
        self.Serendipity:SetShadowOffset(1, -1)
        self.Serendipity:SetJustifyH("RIGHT")
		self:Tag(self.Serendipity, '[nifty:serendipity]')
	end,
	
	target = function (self, ...)
	
	end,
	
	focus = function (self, ...)
		self:SetWidth(120)
		self:SetHeight(18)
		
		self.Health:SetHeight(15)
		self.Power:SetHeight(2)
	end,
}

local Shared = function (self, unit, isSingle)
	self.menu = menu -- Enable the menus
	
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
    
	self:RegisterForClicks("anyup")
	self:SetAttribute("*type2", "menu")
	
	self:SetWidth(250)
  	self:SetHeight(20)

	self.colors = colors

	-- background
	--
	do
		local ins = 2
		self:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
			insets = { left = -ins, right = -ins, top = -ins, bottom = -ins },
		})
	end
	self:SetBackdropColor(0,0,0,1) -- and color the backgrounds
    
	-- Healthbar
	self.Health = CreateFrame "StatusBar"
	self.Health:SetHeight(16)
	self.Health:SetStatusBarTexture(bartex)
    self.Health:SetParent(self)
	self.Health:SetPoint "TOP"
	self.Health:SetPoint "LEFT"
	self.Health:SetPoint "RIGHT"
	
	-- Healhtbar background
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(bartex)
	self.Health.bg:SetAlpha(0.30)  
	
	-- Healthbar text
	local healthValue = self.Health:CreateFontString(nil, "OVERLAY")
	healthValue:SetPoint("RIGHT", self.Health, 0, 9)
	healthValue:SetFont(font, fontsize, "OUTLINE")
	healthValue:SetTextColor(1,1,1)
	healthValue:SetShadowOffset(1, -1)
	self:Tag(healthValue, '[nifty:health]')
	
	self.Health.value = healthValue
	

	-- Healthbar functions
	self.Health.frequentUpdates = true
	self.Health.colorClass = true 
	self.Health.colorReaction = true 
	self.Health.colorDisconnected = true 
	self.Health.colorTapping = true  
	self.PostUpdateHealth = updateHealth -- let the colors be  

	--
	-- powerbar
	--
	self.Power = CreateFrame "StatusBar"
	self.Power:SetHeight(3)
	self.Power:SetStatusBarTexture(bartex)
	self.Power:SetParent(self)
	self.Power:SetPoint"LEFT"
	self.Power:SetPoint"RIGHT"
	self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -1) -- Little offset to make it pretty

	--
	-- powerbar background
	--
	self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture(bartex)
	self.Power.bg:SetAlpha(0.30)  

	-- powerbar text
	local powerValue = self.Power:CreateFontString(nil, "OVERLAY")
    powerValue:SetPoint("LEFT", self.Health, 0, 9) -- powerbar text in health box
	powerValue:SetFont(font, fontsize, "OUTLINE")
	powerValue:SetTextColor(1,1,1)
	powerValue:SetShadowOffset(1, -1)
    powerValue:Hide()
	self:Tag(powerValue, '[nifty:power]')

	self.Power.value = powerValue
    
    --
	-- powerbar functions
	--
	self.Power.frequentUpdates = true
	self.Power.colorTapping = true 
	self.Power.colorDisconnected = true 
	self.Power.colorClass = true 
	self.Power.colorPower = true 
	self.Power.colorHappiness = false  

	--
	-- names
	--
	self.Name = self.Health:CreateFontString(nil, "OVERLAY")
    self.Name:SetPoint("LEFT", self, 0, 9)
    self.Name:SetJustifyH"LEFT"
	self.Name:SetFont(font, fontsize, "OUTLINE")
	self.Name:SetShadowOffset(1, -1)
    self.UNIT_NAME_UPDATE = updateName

	-- level
	local level = self.Health:CreateFontString(nil, "OVERLAY")
	level = self.Health:CreateFontString(nil, "OVERLAY")
	level:SetPoint("LEFT", self.Health, 0, 9)
	level:SetJustifyH("LEFT")
	level:SetFont(font, fontsize, "OUTLINE")
    level:SetTextColor(1,1,1)
	level:SetShadowOffset(1, -1)
	--self.UNIT_LEVEL = updateLevel
	self:Tag(level, '[nifty:level]')
	
	self.Level = level
	
	
	if UnitSpecific[unit] then
		UnitSpecific[unit](self, unit)
	end
	
	self.PostCreateAuraIcon = auraIcon
	self.SetAuraPosition = auraOffset
	
	return self
end


local layout = function(self, unit)

	
	-- ------------------------------------
	-- player
	-- ------------------------------------
    if unit=="player" then
        self:SetWidth(250)
      	self:SetHeight(20)
		self.Health:SetHeight(16)
		self.Name:Hide()
		self.Health.value:SetPoint("RIGHT", 0, 9)
	    self.Power:SetHeight(3)
        self.Power.value:Show()
		self.Power.value:SetPoint("LEFT", self.Health, 0, 9)
		self.Power.value:SetJustifyH"LEFT"
		self.Level:Hide()
		
		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOP', self, 'TOP', 0, 20)
			self.Experience:SetStatusBarTexture(bartex)
			self.Experience:SetHeight(3)
			self.Experience:SetWidth(250)
			self.Experience:SetBackdrop(backdrop)
			self.Experience:SetBackdropColor(0, 0, 0, 1)

			self.Experience.Tooltip = true

			--self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
			--self.Experience.Text:SetPoint('CENTER', self.Experience)

			self.Experience.bg = self.Experience:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(0.2, 0.2, 0.2)
			--self.Experience.bg:SetBackdropColor(0,0,0,1)
			--self.Experience.bg:SetTexture(bartex)
			--self.Experience.bg:SetAlpha(0.30)  
		end
		        
        --
        -- Serendipity counter
        --
        self.Serendipity = self:CreateFontString(nil, "OVERLAY")
        self.Serendipity:SetPoint("LEFT", self, "RIGHT", 10, 0)
        self.Serendipity:SetFont(font, 20, "OUTLINE")
        self.Serendipity:SetTextColor(0, 0.81, 1)
        self.Serendipity:SetShadowOffset(1, -1)
        self.Serendipity:SetJustifyH("RIGHT")
--        self:Tag(self.Serendipity, '[Serendipity]')
        
        
		--
		-- leader icon
		--
		self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
		self.Leader:SetHeight(12)
		self.Leader:SetWidth(12)
		self.Leader:SetPoint("BOTTOMRIGHT", self, -2, 4)
		self.Leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
		
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("TOP", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
        
		--
		-- oUF_PowerSpark support
		--
        self.Spark = self.Power:CreateTexture(nil, "OVERLAY")
		self.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		self.Spark:SetVertexColor(1, 1, 1, 1)
		self.Spark:SetBlendMode("ADD")
		self.Spark:SetHeight(self.Power:GetHeight()*2.5)
		self.Spark:SetWidth(self.Power:GetHeight()*2)
        -- self.Spark.rtl = true -- Make the spark go from Right To Left instead
		-- self.Spark.manatick = true -- Show mana regen ticks outside FSR (like the energy ticker)
		-- self.Spark.highAlpha = 1 	-- What alpha setting to use for the FSR and energy spark
		-- self.Spark.lowAlpha = 0.25 -- What alpha setting to use for the mana regen ticker
		
		--
		-- oUF_BarFader
		--
		self.BarFade = true
		self.BarFadeAlpha = 0.2
	end

	-- ------------------------------------
	-- pet
	-- ------------------------------------
	if unit=="pet" then
		self:SetWidth(120)
		self:SetHeight(18)
		self.Health:SetHeight(18)
		self.Power:Hide()
		self.Health.value:Hide()
		self.Level:Hide()
		self.Name:Hide()
		
		if playerClass=="HUNTER" then
			self.Health.colorReaction = false
			self.Health.colorClass = false
			self.Health.colorHappiness = true  
		end
		
		--
		-- oUF_BarFader
		--
		self.BarFade = true
		self.BarFadeAlpha = 0.2
	end
	
	-- ------------------------------------
	-- target
	-- ------------------------------------
    if unit=="target" then
		self:SetWidth(250)
		self:SetHeight(20)
		self.Health:SetHeight(16)
		self.Power:SetHeight(3)
		self.Power.value:Hide()
		self.Health.value:SetPoint("RIGHT", 0, 9)
		self.Name:SetPoint("LEFT", self.Level, "RIGHT", 0, 0)
		self.Name:SetHeight(20)
		self.Name:SetWidth(120)
			
		self.Health.colorClass = true
		
		--
		-- combo points
		--
		if(playerClass=="ROGUE" or playerClass=="DRUID") then
			self.CPoints = self:CreateFontString(nil, "OVERLAY")
			self.CPoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
			self.CPoints:SetFont(font, 20, "OUTLINE")
			self.CPoints:SetTextColor(0, 0.81, 1)
			self.CPoints:SetShadowOffset(1, -1)
			self.CPoints:SetJustifyH"RIGHT" 
		end
    
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("RIGHT", self, 30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
		
		--
		-- buffs
		--
		self.Buffs = CreateFrame("Frame", nil, self) -- buffs
		self.Buffs.size = 22
		self.Buffs:SetHeight(self.Buffs.size)
		self.Buffs:SetWidth(self.Buffs.size * 5)
		self.Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 15)
		self.Buffs.initialAnchor = "BOTTOMLEFT"
		self.Buffs["growth-y"] = "TOP"
		self.Buffs.num = 20
		self.Buffs.spacing = 2
		
		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 30
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 9)
		self.Debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -2, -6)
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-y"] = "DOWN"
		self.Debuffs.filter = false
		self.Debuffs.num = 40
		self.Debuffs.spacing = 2
	end
	
	-- ------------------------------------
	-- target of target and focus
	-- ------------------------------------
	if unit=="targettarget" or unit=="focus" or unit=="focusTarget" then
		self:SetWidth(120)
		self:SetHeight(18)
		self.Health:SetHeight(18)
		self.Power:Hide()
		self.Power.value:Hide()
		self.Health.value:SetPoint("RIGHT", 0, 9)
		--self.Health.value:Hide()
		self.Name:SetWidth(80)
		self.Name:SetHeight(18)
		
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("RIGHT", self, 22, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
		
		--
		-- oUF_BarFader
		--
		if unit=="focus" then
			self.BarFade = true
			self.BarFadeAlpha = 0.2
		end
	end

	-- ------------------------------------
	-- player and target castbar
	-- ------------------------------------	
	
	if(unit == 'player' or unit == 'target' or unit == 'focus') then
	    self.Castbar = CreateFrame('StatusBar', nil, self)
	    self.Castbar:SetStatusBarTexture(bartex)
	    		
		if(unit == "player") then
			self.Castbar:SetStatusBarColor(1, 0.50, 0)
			self.Castbar:SetHeight(24)
			self.Castbar:SetWidth(260)
		
			self.Castbar.CustomTimeText = function(self, duration)
				if self.casting then
					self.Time:SetFormattedText("%.1f", self.max - duration)
				elseif self.channeling then
					self.Time:SetFormattedText("%.1f", duration)
				end
			end
			self.Castbar:SetBackdropColor(0,0,0,1)
			
			self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', playerCastBar_x, -280)
			
		elseif(unit == "focus") then
			self.Castbar:SetStatusBarColor(1, 0.50, 0)
			self.Castbar:SetHeight(18)
			self.Castbar:SetWidth(120)
			
			self.Castbar:SetPoint('TOPLEFT', oUF_Focus, 'BOTTOMLEFT', 0, -10)
			
		else
			self.Castbar:SetStatusBarColor(0.80, 0.01, 0)
			self.Castbar:SetHeight(24)
			self.Castbar:SetWidth(260)

			self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', 0, 380)
		end
		
		self.Castbar:SetBackdrop{
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
			tile = true,
			tileSize = 16,
			insets = {
				left = -2,
				right = -2,
				top = -2,
				bottom = -2
			},
		}
		self.Castbar:SetBackdropColor(0, 0, 0, 0.5)

	    self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
	    self.Castbar.bg:SetAllPoints(self.Castbar)
	    self.Castbar.bg:SetTexture(0, 0, 0, 0.6)
		
		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY')
	    self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, -1)
	    self.Castbar.Text:SetFont(upperfont, 11)
		self.Castbar.Text:SetShadowOffset(1, -1)
	    self.Castbar.Text:SetTextColor(1, 1, 1)
	    self.Castbar.Text:SetJustifyH('LEFT')
		
		
	    self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY')

	    self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, 0)
	    self.Castbar.Time:SetFont(upperfont, 12)
	    self.Castbar.Time:SetTextColor(1, 1, 1)
	    self.Castbar.Time:SetJustifyH('RIGHT')
	end
	

	--[[
	
	-- ------------------------------------
	-- party 
	-- ------------------------------------
	if(self:GetParent():GetName():match"oUF_Party") then
		self:SetWidth(160)
		self:SetHeight(20)
		self.Health:SetHeight(15)
		self.Power:SetHeight(3)
		self.Power.value:Hide()
		self.Health.value:SetPoint("RIGHT", 0 , 9)
		self.Name:SetPoint("LEFT", 0, 9)

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 20 * 1.3
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 5)
		self.Debuffs:SetPoint("LEFT", self, "RIGHT", 5, 0)
		self.Debuffs.initialAnchor = "TOPLEFT"
	    self.Debuffs.filter = false
		self.Debuffs.showDebuffType = true
		self.Debuffs.spacing = 2
		self.Debuffs.num = 2 -- max debuffs
		
		--
		-- leader icon
		--
		self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
		self.Leader:SetHeight(12)
		self.Leader:SetWidth(12)
		self.Leader:SetPoint("BOTTOMRIGHT", self, -2, 4)
		self.Leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
		
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("LEFT", self, -30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end

	-- ------------------------------------
	-- raid 
	-- ------------------------------------
    if(self:GetParent():GetName():match"oUF_Raid") then
		self:SetWidth(85) 
		self:SetHeight(15)
		self.Health:SetHeight(15)
		self.Power:Hide()
		self.Health:SetFrameLevel(2) 
		self.Power:SetFrameLevel(2)
		self.Health.value:Hide()
		self.Power.value:Hide()
		self.Name:SetFont(font, 12)
		self.Name:SetWidth(85)
		self.Name:SetHeight(15)
		
		--
		-- oUF_DebuffHighlight support
		--
		self.DebuffHighlight = self.Health:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlight:SetAllPoints(self.Health)
		self.DebuffHighlight:SetTexture("Interface\\AddOns\\oUF_Nifty\\textures\\highlight.tga")
		self.DebuffHighlight:SetBlendMode("ADD")
		self.DebuffHighlight:SetVertexColor(0, 0, 0, 0)
		self.DebuffHighlightAlpha = 0.8
		self.DebuffHighlightFilter = true
    end
    
	--
	-- fading for party and raid
	--
	if(not unit) then -- fadeout if units are out of range
		self.Range = false -- put true to make party/raid frames fade out if not in your range
		self.inRangeAlpha = 1.0 -- what alpha if IN range
		self.outsideRangeAlpha = 0.5 -- the alpha it will fade out to if not in range
    end
--]]
	
	--
	-- custom aura textures
	--
	self.PostCreateAuraIcon = auraIcon
	self.SetAuraPosition = auraOffset
	
	if(self:GetParent():GetName():match"oUF_Party") then
		self:SetAttribute('initial-height', 20) 
		self:SetAttribute('initial-width', 160)
	else 
		self:SetAttribute('initial-height', height) 
		self:SetAttribute('initial-width', width) 
	end  
	
	return self   
end

-- ------------------------------------------------------------------------
-- spawning the frames
-- ------------------------------------------------------------------------

--
-- normal frames
--
-- oUF:RegisterStyle("Nifty", func)
-- 
-- oUF:SetActiveStyle("Nifty")
-- local player = oUF:Spawn("player", "oUF_Player")
-- player:SetPoint("CENTER", -335, -106)
-- local target = oUF:Spawn("target", "oUF_Target")
-- target:SetPoint("CENTER", 335, -106) 
-- local pet = oUF:Spawn("pet", "oUF_Pet")
-- pet:SetPoint("BOTTOMLEFT", player, 0, -30)
-- local tot = oUF:Spawn("targettarget", "oUF_TargetTarget")
-- tot:SetPoint("TOPRIGHT", target, 0, 35)
-- local focus	= oUF:Spawn("focus", "oUF_Focus")
-- focus:SetPoint("BOTTOMRIGHT", player, 0, -30) 


oUF:RegisterStyle('Nifty', Shared)
-- for unit, layout in next, UnitSpecific do 
-- 	oUF:RegisterStyle('Nifty - ' .. unit:gsub("^%l", string.upper), layout)
-- end

local function spawn(self, unit, ...)
	self:SetActiveStyle('Nifty')
	local obj = self:Spawn(unit)
	obj:SetPoint(...)

	return obj
end

oUF:Factory( function (self) 
	local player = spawn(self, 'player', 'CENTER', -335, -106)
	local target = spawn(self, 'target', 'CENTER', 335, -106)
	spawn(self, 'focus', 'RIGHT', player, 0, -30)
	spawn(self, 'pet', 'LEFT', player, 0, -30)
end)

