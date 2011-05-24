--[[
	
	oUF_Nifty

	Author:		Nifty
	Mail:		post@endlessly.de
	URL:		http://www.wowinterface.com/list.php?skinnerid=62149
	
	Credits:	oUF_TsoHG (used as base) / http://www.wowinterface.com/downloads/info8739-oUF_TsoHG.html
				Rothar for buff border (and Neal for the edited version)
				p3lim for party toggle function

--]]

--[[
	
	TODO:
		- Pet health text is uncolored and only shows deficit
		- AltPowerValue for boss frames
	
]]

local backdrop
do
	local ins = -1
	
	backdrop = {
		bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
		insets = {top = ins, left = ins, bottom = ins, right = ins},
	}
end

-- ------------------------------------------------------------------------
-- font, fontsize and textures
-- ------------------------------------------------------------------------
local font = "Interface\\AddOns\\oUF_Nifty\\fonts\\font.ttf"
local upperfont = "Interface\\AddOns\\oUF_Nifty\\fonts\\upperfont.ttf"
local fontsize = 15
local bartex = "Interface\\AddOns\\oUF_Nifty\\textures\\statusbar"
local bufftex = "Interface\\AddOns\\oUF_Nifty\\textures\\border"
local playerClass = select(2, UnitClass("player"))

-- ------------------------------------------------------------------------
-- change some colors :)
-- ------------------------------------------------------------------------

local colors = setmetatable({
	health = { .45, .73, .27 },
		
	power = setmetatable({
		["MANA"] = { 26/255, 139/255, 255/255 },
		["RAGE"] = { 255/255, 26/255, 48/255 },
		["FOCUS"] = { 255/255, 150/255, 26/255 },
		["ENERGY"] = { 255/255, 225/255, 26/255 },
		["HAPPINESS"] = { 0.00, 1.00, 1.00 },
		["RUNES"] = { 0.50, 0.50, 0.50 },
		["RUNIC_POWER"] = { 0.00, 0.82, 1.00 },
		["AMMOSLOT"] = { 0.80, 0.60, 0.00 },
		["FUEL"] = { 0.0, 0.55, 0.5 },
	}, {__index = oUF.colors.power}),
	
	reaction = setmetatable({
		[1] = { 182/255, 34/255, 32/255 },
		[2] = { 182/255, 34/255, 32/255 },
		[3] = { 182/255, 92/255, 32/255 },
		[4] = { 220/225, 180/255, 52/255 },
		[5] = { 143/255, 194/255, 32/255 },
		[6] = { 143/255, 194/255, 32/255 },
		[7] = { 143/255, 194/255, 32/255 },
		[8] = { 143/255, 194/255, 32/255 },
	}, {__index = oUF.colors.reaction})
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

local isUnitActive = function (unit)
	if not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit) then
		return false
	end
	
	return true
end

local shortenValue = function (val)
	if val < 1000 then
		return val
	elseif val > 1000000 then
		return string.format("%.1fm", val / 1000000)
	else
		return string.format("%.1fk", val / 1000)
	end
end

function RGBtoHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end


oUF.Tags['nifty:level'] = function (unit)
	local lvl = UnitLevel(unit)
	local classification = UnitClassification(unit)
	local _, class = UnitClass(unit)
	local color = GetQuestDifficultyColor(lvl)
	local colorTag = "|cff" .. RGBtoHex(color.r, color.g, color.b)
	local tagValue
	
	if lvl <= 0 then
		lvl = "??"
	end

	
	if classification == "worldboss" then
		tagValue = "|cffff0000" .. lvl .. "b|r"
	elseif classification == "rareelite" then
		tagValue = colorTag .. lvl .. "r+"
	elseif classification == "elite" then
		tagValue = colorTag .. lvl .. "+"
	elseif classification == "rare" then
		tagValue = colorTag .. lvl .. "r"
	else
		if not UnitIsPlayer(unit) then
			tagValue = "|cff" .. RGBtoHex(color.r, color.g, color.b)
		elseif oUF.colors.class[ class ] then
			tagValue = "|cff" .. RGBtoHex(unpack(oUF.colors.class[ class ]))
		end

		if UnitIsConnected(unit) == nil then
			tagValue = tagValue .. "??"
		else
			tagValue = tagValue .. lvl
		end
	end
	tagValue = tagValue .. "|r"

	return tagValue
end
oUF.TagEvents['nifty:level'] = oUF.TagEvents.level

-- ------------------------------------------------------------------------
-- serendipity update
-- ------------------------------------------------------------------------

oUF.Tags['nifty:serendipity'] = function(u)
    local _, _, _, count = UnitAura("player", "Serendipity")
	
	return count and "|cff0080ff" .. count .. "|r"
end
oUF.TagEvents['nifty:serendipity'] = "UNIT_AURA"

oUF.Tags['nifty:name'] = function (unit)
	local name = UnitName(unit)
	
	return string.lower(name or "")
end
oUF.TagEvents['nifty:name'] = oUF.TagEvents.name

oUF.Tags['nifty:health'] = function (unit)
	if not isUnitActive(unit) then
		return
	end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local tagValue
	
	if cur == max then
		tagValue = "|cff33EE44" .. shortenValue(cur) .. "|r"
	else 
		tagValue = "|cff33EE44" .. shortenValue(cur) .. "/" .. shortenValue(max) .. "|r"
	end
	
	return tagValue
end

oUF.Tags['nifty:currentHealth'] = function (unit)
	if not isUnitActive(unit) then
		return
	end
	
	local cur, max = UnitHealth(unit), UnitHealthMax(unit)

	if cur == max then
		return ""
	end
	
	return "|cff33EE44" .. shortenValue(cur) .. "|r"
end

oUF.Tags['nifty:deficit'] = function (unit)
	if not isUnitActive(unit) then
		return
	end
	
	if not UnitIsFriend("player", unit) then
		return ""
	end
	
	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	if cur == max then
		return ""
	end
		
	return "|cffff7f74" .. (cur - max) .. "|r"
end

oUF.Tags['nifty:percentHealth'] = function (unit)
	if not isUnitActive(unit) then
		return
	end
	
	if unit == "target" and UnitIsFriend("player", unit) then
		return ""
	end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local percent = floor(cur / max * 100)
	
	return "|cff33EE44 " .. percent .. "%|r"
end

oUF.TagEvents['nifty:health'] = oUF.TagEvents.missinghp
oUF.TagEvents['nifty:currentHealth'] = oUF.TagEvents.missinghp
oUF.TagEvents['nifty:deficit'] = oUF.TagEvents.missinghp
oUF.TagEvents['nifty:percentHealth'] = oUF.TagEvents.missinghp

oUF.Tags['nifty:power'] = function (unit)
	if not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit) then 
		return
	end

	local min, max = UnitPower(unit), UnitPowerMax(unit)
	local _, ptype = UnitPowerType(unit)
	local color = colors.power[ptype]
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
	
	color = color and RGBtoHex(unpack(color)) or ""
		
	return "|cff" .. color .. tagValue .. "|r"
end
oUF.TagEvents['nifty:power'] = oUF.TagEvents.missingpp

-- ------------------------------------------------------------------------
-- aura reskin
-- ------------------------------------------------------------------------
local PostCreateIcon = function(element, button)
	element.showDebuffType = true

	button.icon:SetTexCoord(.07, .93, .07, .93)
	button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

	button.overlay:SetTexture( bufftex )
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay.Hide = function (self)
		self:SetVertexColor(0.3, 0.3, 0.3)
	end

	button.cd:SetReverse()
	button.cd:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2) 
	button.cd:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)   
end

-- ------------------------------------------------------------------------
-- the layout starts here
-- ------------------------------------------------------------------------

local createCastbar = function(self)
	local castbar = CreateFrame("StatusBar", nil, self)
	
	castbar:SetWidth(260)
	castbar:SetHeight(24)
			
	castbar:SetStatusBarTexture(bartex)
	castbar:SetStatusBarColor(1, .5, 0)
	
	castbar:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
		tile = true,
		tileSize = 16,
		insets = {
			left = -1,
			right = -1,
			top = -1,
			bottom = -1
		}
	})
	castbar:SetBackdropColor(0, 0, 0, .7)
	
	-- Background
	castbar.bg = castbar:CreateTexture(nil, 'BORDER')
	castbar.bg:SetAllPoints( castbar )
	castbar.bg:SetTexture(0, 0, 0, 0.6)
	
	-- Text
	castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
	castbar.Text:SetPoint("LEFT", castbar, 2, -1)
	castbar.Text:SetFont(upperfont, 11)
	castbar.Text:SetShadowOffset(1, -1)
	castbar.Text:SetTextColor(1, 1, 1)
	castbar.Text:SetJustifyH("LEFT")
	
	-- Time
	castbar.Time = castbar:CreateFontString(nil, "OVERLAY")
	castbar.Time:SetPoint("RIGHT", castbar, -2, 0)
	castbar.Time:SetFont(upperfont, 11)
	castbar.Time:SetShadowOffset(1, -1)
	castbar.Time:SetTextColor(1, 1, 1)
	castbar.Time:SetJustifyH("RIGHT")
	
	castbar.CustomTimeText = function (self, duration)
		if self.casting then
			self.Time:SetFormattedText("%.1f", self.max - duration)
		elseif self.channeling then
			self.Time:SetFormattedText("%.1f", duration)
		end
	end
	
	return castbar
end

local createBuffs = function (self)
	local buffs = CreateFrame("Frame", nil, self) 
	buffs.size = 23
	
	buffs:SetHeight( buffs.size )
	buffs:SetWidth( buffs.size * 5 + (5 * 3) )
	
	buffs.initialAnchor = "BOTTOMLEFT"
	buffs["growth-y"] = "TOP"
	buffs.num = 20
	buffs.spacing = 3
	
	self.Buffs = buffs
	self.Buffs.PostCreateIcon = PostCreateIcon
	
	return buffs
end

local createDebuffs = function (self)
	local debuffs = CreateFrame("Frame", nil, self)
	debuffs.size = 30
	
	debuffs:SetHeight( debuffs.size )
	debuffs:SetWidth( debuffs.size * 8 + (9 * 2) )
	
	debuffs.initialAnchor = "TOPLEFT"
	debuffs["growth-y"] = "DOWN"
	debuffs.filter = false
	debuffs.num = 20
	debuffs.spacing = 2
	
	self.Debuffs = debuffs
	self.Debuffs.PostCreateIcon = PostCreateIcon
	
	return debuffs
end

local SmallUnit = function (self, ...)
	self.Name:SetWidth(80)
	self.Name:SetHeight(18)
	
	self:Tag(self.Health.value, '[nifty:currentHealth]')
end

local UnitSpecific = {
	player = function (self, ...)
		self:Tag(self.Health.value, '[nifty:currentHealth]')
	
		self.Power.value:Show()
	
        -- Serendipity counter
        self.Serendipity = self:CreateFontString(nil, "OVERLAY")
        self.Serendipity:SetPoint("LEFT", self, "RIGHT", 10, 0)
        self.Serendipity:SetFont(font, 20, "OUTLINE")
        self.Serendipity:SetTextColor(0, 0.81, 1)
        self.Serendipity:SetShadowOffset(1, -1)
        self.Serendipity:SetJustifyH("RIGHT")
		self:Tag(self.Serendipity, '[nifty:serendipity]')
		
		-- Castbar
		local castbar = createCastbar(self)
		castbar:SetPoint("CENTER", UIParent, "CENTER", 0, -280)
		
		self.Castbar = castbar
		
		
		local leader = self.Health:CreateTexture(nil, "OVERLAY")
		leader:SetHeight(12)
		leader:SetWidth(12)
		leader:SetPoint("BOTTOMRIGHT", self, -2, 4)
		leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
		
		self.Leader = leader
		
		
		local raidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		raidIcon:SetHeight(16)
		raidIcon:SetWidth(16)
		raidIcon:SetPoint("TOP", self, 0, 9)
		raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		
		self.RaidIcon = raidIcon
	end,
	
	target = function (self, ...)
		self:Tag(self.Name, '[nifty:level] [nifty:name]')
		self:Tag(self.Health.value, '[nifty:deficit] [nifty:health][nifty:percentHealth]')
		
		self.Name:SetWidth(120)
		self.Name:SetHeight(20)
		
		--[[ Buffs ]]--
		local buffs = createBuffs(self) 
		buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -1, 15)
		
		--[[ Debuffs ]]--
		local debuffs = createDebuffs(self)
		debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -1, -6)
		
		-- Castbar
		local castbar = createCastbar(self)
		castbar:SetPoint('CENTER', UIParent, 'CENTER', 0, 380)
		
		castbar:SetStatusBarColor(0.80, 0.01, 0)
		castbar:SetHeight(24)
		castbar:SetWidth(260)
		
		self.Castbar = castbar
		
		
		local raidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		raidIcon:SetHeight(16)
		raidIcon:SetWidth(16)
		raidIcon:SetPoint("TOP", self, 0, 9)
		raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		
		self.RaidIcon = raidIcon
		
		if playerClass == "ROGUE" or playerClass == "DRUID" then
			local cpoints = self:CreateFontString(nil, "OVERLAY")
			cpoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
				
			cpoints:SetFont(font, 20, "OUTLINE")
			cpoints:SetTextColor(0, 0.81, 1)
			cpoints:SetShadowOffset(1, -1)
			cpoints:SetJustifyH("RIGHT")

			self:Tag(cpoints, "[cpoints]")
		end
	end,
	
	focus = function (self, ...)
		SmallUnit(self, ...)
		
		self:Tag(self.Name, '[nifty:name]')
		
		self:SetWidth(120)
		self:SetHeight(18)
		
		self.Health:SetHeight(15)
		self.Power:SetHeight(2)
		
		-- Castbar
		local castbar = createCastbar(self)
		castbar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -10)
		
		castbar:SetStatusBarColor(1, 0.50, 0)
		castbar:SetHeight(18)
		castbar:SetWidth(120)
		
		self.Castbar = castbar
	end,
	
	pet = function (self, ...)
		SmallUnit(self, ...)
		
		self.Name:Hide()
		
		self:SetWidth(120)
		self:SetHeight(18)
		
		self.Health:SetHeight(15)
		self.Power:SetHeight(2)
		
		if playerClass == "HUNTER" then
			self.Health.colorReaction = true
			self.Health.colorClass = true
		end
	end,
	
	targettarget = function (self, ...)
		SmallUnit(self, ...)
		
		self:Tag(self.Name, '[nifty:name]')
	
		self:SetWidth(120)
		self:SetHeight(18)
		
		self.Health:SetHeight(15)
		self.Power:SetHeight(2)
	end,
	
	boss = function (self, ...)
		self:Tag(self.Name, '[nifty:name]')
		self:Tag(self.Health.value, '[nifty:currentHealth] [nifty:percentHealth]')
		
		self:SetWidth(175)
		
		local castbar = createCastbar(self)
		castbar:SetPoint('TOP', self, 'BOTTOM', 0, -6)
		
		castbar:SetStatusBarColor(0.80, 0.01, 0)
		castbar:SetHeight(16)
		castbar:SetWidth(175)
		
		castbar.Text:SetWidth(140)
		castbar.Text:SetHeight(16)
		
		self.Castbar = castbar
		
		local buffs = createBuffs(self)
		buffs:SetPoint("RIGHT", self, "LEFT", -7, 0)

		buffs.initialAnchor = "RIGHT"
		buffs["growth-x"] = "LEFT"
		buffs.num = 5
		
		local raidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		raidIcon:SetHeight(16)
		raidIcon:SetWidth(16)
		raidIcon:SetPoint("TOP", self, 0, 9)
		raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		
		self.RaidIcon = raidIcon
	end,
}

local Shared = function (self, unit, isSingle)
	unit = unit:find("boss%d") and "boss" or unit

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

	--
	-- powerbar
	--
	self.Power = CreateFrame "StatusBar"
	self.Power:SetHeight(3)
	self.Power:SetStatusBarTexture(bartex)
	self.Power:SetParent(self)
	self.Power:SetPoint "LEFT"
	self.Power:SetPoint "RIGHT"
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
	powerValue:SetTextColor(1, 1, 1)
	powerValue:SetShadowOffset(1, -1)
    powerValue:Hide()
	self:Tag(powerValue, '[nifty:power]')

	self.Power.value = powerValue
    
	-- powerbar functions
	self.Power.frequentUpdates = true
	self.Power.colorTapping = true 
	self.Power.colorDisconnected = true 
	self.Power.colorClass = true 
	self.Power.colorPower = true 
	self.Power.colorHappiness = false  

	-- names
	local name = self.Health:CreateFontString(nil, "OVERLAY")
	name = self.Health:CreateFontString(nil, "OVERLAY")
    name:SetPoint("LEFT", self, 0, 9)
    name:SetJustifyH("LEFT")
	name:SetFont(font, fontsize, "OUTLINE")
	name:SetShadowOffset(1, -1)
	self.Name = name
	
	
	if UnitSpecific[unit] then
		UnitSpecific[unit](self, unit)
	end
			
	return self
end


oUF:RegisterStyle('Nifty', Shared)


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
	spawn(self, "targettarget", "TOPRIGHT", target, 0, 35)
	
	self:SetActiveStyle('Nifty')
	local prev
	for i = 1, MAX_BOSS_FRAMES do
		local boss = self:Spawn("boss" .. i)
		
		if prev then
			boss:SetPoint("TOP", prev, "BOTTOM", 0, -35)
		else
			boss:SetPoint("RIGHT", -40, 0)
		end
		
		prev = boss
	end
end)

