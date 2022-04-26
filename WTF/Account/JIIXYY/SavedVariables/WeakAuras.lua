
WeakAurasSaved = {
	["dynamicIconCache"] = {
	},
	["editor_tab_spaces"] = 4,
	["displays"] = {
		["UI - PartyCooldownTracker"] = {
			["iconSource"] = -1,
			["xOffset"] = -2000,
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["url"] = "https://wago.io/vQqMPBg2Y/1",
			["actions"] = {
				["start"] = {
					["custom"] = "aura_env:scheduleUpdateEvent(\"INVISUS_COOLDOWNS\", 0.5, \"FRAME_UPDATE\")\n\n\n",
					["do_custom"] = true,
					["do_message"] = false,
				},
				["init"] = {
					["custom"] = "local WeakAuras, PartyCooldownTracker, db, DEFAULT_CHAT_FRAME = WeakAuras, aura_env, WeakAurasSaved, DEFAULT_CHAT_FRAME;\nlocal WA_GetUnitDebuff, UnitDebuff = WA_GetUnitDebuff, UnitDebuff;\nlocal _G, pairs, tonumber, select = _G, pairs, tonumber, select;\nlocal GetSpellInfo, GetCurrentMapAreaID, GetItemInfo, GetItemIcon= GetSpellInfo, GetCurrentMapAreaID, GetItemInfo, GetItemIcon;\nlocal UnitExists, UnitFactionGroup, GetNumPartyMembers = UnitExists, UnitFactionGroup, GetNumPartyMembers;\nlocal UnitInParty, UnitCreatureFamily = UnitInParty, UnitCreatureFamily;\nlocal GetInventoryItemLink = GetInventoryItemLink;\nlocal UnitName, UnitGUID, UnitRace, UnitClass = UnitName, UnitGUID, UnitRace, UnitClass;\nlocal config = PartyCooldownTracker.config;\nlocal LoadAddOn, LibStub = LoadAddOn, LibStub;\nlocal GetLocale, GetTime = GetLocale, GetTime;\n\nPartyCooldownTracker.libGT = LibStub:GetLibrary(\"LibGroupTalents-1.0\", true);\n\nif ( not PartyCooldownTracker.libGT ) then\n    local loaded, reason = LoadAddOn(\"LibGroupTalents-1.0\");\n    PartyCooldownTracker.libGT = LibStub:GetLibrary(\"LibGroupTalents-1.0\", true);\nend\n\nif ( PartyCooldownTracker.libGT ) then\n    function PartyCooldownTracker:LibGroupTalents_Update(e, guid, unit, newSpec, n1, n2, n3)\n        local unitName = UnitName(unit);\n        WeakAuras.timer:ScheduleTimer(\n        WeakAuras.ScanEvents, 1.0, \"INVISUS_COOLDOWNS\", \"LibGroupTalents_Update\", unit, unitName)\n    end\n    PartyCooldownTracker.libGT.RegisterCallback(PartyCooldownTracker, \"LibGroupTalents_Update\");\nelseif ( not config.lib_error ) then\n    DEFAULT_CHAT_FRAME:AddMessage(\"|cff69ccf0PartyCooldownTracker- WA|r couldn't find LibGroupTalents-1.0. Download the lib to display talent required cooldowns. (You can copy the name of lib in the |cffffd100Information|r tab).\");\nend\n\n-------------------------------------------------------------------------------------------------------\nPartyCooldownTracker.roster = PartyCooldownTracker.roster or {};\nPartyCooldownTracker.pet_roster = PartyCooldownTracker.pet_roster or {} ;\n\nfunction PartyCooldownTracker:GetNumPartyMembers()\n    if ( GetNumPartyMembers() == 0 ) then\n        return 0;\n    end\n    return config.countUnits <= GetNumPartyMembers() and config.countUnits or GetNumPartyMembers();\nend\n--------------------------------------------------------------------------------------------------------------------\nfunction PartyCooldownTracker:SaveCurrentSession()\n    db.displays[self.id][WeakAuras.me] = {};\n    local data = db.displays[self.id][WeakAuras.me];\n    data.roster = self.roster;\nend\n\nfunction PartyCooldownTracker:GroupRosterGeneration(object)\n    for i = 1, self:GetNumPartyMembers() do\n        local unit = \"party\"..i;\n        if ( UnitExists(unit) ) then \n            object[UnitGUID(unit)] = unit; \n        end\n    end\n    return object;\nend\n\nfunction PartyCooldownTracker:LoadLastSession()\n    local data = db.displays[self.id][WeakAuras.me];\n    local members = self:GroupRosterGeneration({});\n    \n    if ( ( not data ) or ( data and not data.roster ) ) then\n        return;\n    end\n    \n    for guid, unitDATA in pairs(data.roster) do\n        if ( members[guid] and self.roster[guid] ) then\n            local class = unitDATA.class;\n            local unitID = members[guid];\n            local member = self.roster[guid];\n            for spellID, info in pairs(unitDATA.spells) do\n                if ( self.cds[class][spellID] and self.cds[class][spellID].display )\n                or ( self.anyCDs[spellID] and self.anyCDs[spellID].display ) then\n                    \n                    member.spells = member.spells or {};\n                    member.spells[spellID] = member.spells[spellID] or {};\n                    member.spells[spellID].cd = info.cd;\n                    if ( info.exp and math.abs(info.exp - GetTime()) < info.cd ) then\n                        member.spells[spellID].dst = info.dst;\n                        member.spells[spellID].exp = info.exp;\n                        member.spells[spellID].cd = info.cd;\n                    end\n                end\n            end\n            \n            for invSlot, itemData in pairs(unitDATA.trinkets) do\n                if ( self.anyCDs[itemData.spellID] and self.anyCDs[itemData.spellID].display ) then\n                    self:AddTrinketInfo(guid, invSlot, itemData.itemName, itemData.itemID, itemData.spellID)\n                end\n            end\n            for petGUID, petData in pairs(unitDATA.pet) do\n                self.pet_roster[petGUID] = petData;\n                for spellID, info in pairs(petData.spells) do\n                    self:AddCooldownInfo(guid, spellID, info.cd)\n                end\n            end\n            \n            self.roster[guid] = member;\n        end\n    end\n    \nend\n---------------------------------------------------------------------------------------------------------------------\nlocal function GetSpellIcon(spellID, guid)\n    local icon = select(3, GetSpellInfo(spellID));\n    local data = PartyCooldownTracker.roster[guid];\n    \n    if ( data and data.trinkets ) then\n        for slotID, slotINFO in pairs(data.trinkets) do\n            if ( slotINFO.spellID == spellID ) then\n                icon = GetItemIcon(slotINFO.itemID) or icon;\n                break;\n            end\n        end\n    end\n    return icon;\nend \n\nfunction PartyCooldownTracker.GetPetGUID(unitID)\n    if ( unitID and unitID:match(\"party\") ) then\n        local i = (unitID):match(\"%d\");\n        local petID = \"partypet\"..i;\n        if ( UnitExists(petID) ) then\n            local petGUID = UnitGUID(petID);\n            return petGUID;\n        end\n    end            \nend\n\nlocal function GetPetID(unitID)\n    local i = (unitID):match(\"%d\");\n    if ( i and UnitExists(\"partypet\"..i) ) then\n        return \"partypet\"..i;\n    end\nend\n\nfunction PartyCooldownTracker:AdditionalVerification(allstates, subEvent, guid, spellID, destGUID)\n    if not ( subEvent == \"SPELL_CAST_SUCCESS\" ) then \n        return;\n    end\n    \n    local class = self.roster[guid] and self.roster[guid].class;\n    if ( self.relationship[class] and self.relationship[class][spellID] ) then\n        if ( not self.roster[guid].spells[spellID] ) then \n            return true, self:Relationship(allstates, guid, spellID, destGUID);\n        end\n    end\nend\n\nfunction PartyCooldownTracker:SpellIsDisplay(guid, spellID, spellName)\n    if ( self.roster[guid] and self.roster[guid].spells[spellID] ) then\n        return guid;\n    elseif ( self.pet_roster[guid] ) then\n        guid = self.pet_roster[guid].unitGUID;\n        if ( self.roster[guid] and self.roster[guid].spells[spellID] ) then\n            return guid;\n        end\n    elseif ( self.roster[guid] and self.USS[spellName] and self.USS[spellName].display ) then\n        return guid;\n    else\n        return false;\n    end\nend\n\nfunction PartyCooldownTracker:AddInfo(guid, spellID, exp, dst)\n    if not ( self.roster[guid] and self.roster[guid].spells[spellID] ) then \n        return;\n    end\n    \n    self.roster[guid].spells[spellID].exp = exp;\n    self.roster[guid].spells[spellID].dst = dst;\nend\n\nlocal C_PVP = {};\nC_PVP[0] = true;\n\nC_PVP.IsPVPMap = function() \n    return C_PVP[GetCurrentMapAreaID()];\nend\n\nfunction PartyCooldownTracker:Update(allstates)\n    if ( not C_PVP.IsPVPMap() ) then \n        return\n    end\n    \n    for _, state in pairs(allstates) do\n        if ( state and state.show ) then\n            state.changed=  true;\n            state.expirationTime = GetTime();\n            state.dst = false;\n            state.isBuff = false;\n            state.isCD = false;\n            \n            self:AddInfo(state.guid, state.spellID, state.expirationTime, state.dst);\n        end\n    end\n    return true;\nend\n-- Checking spells that have one CD\nfunction PartyCooldownTracker:Relationship(allstates, guid, spellID, destGUID) \n    local class = self.roster[guid].class;\n    if ( self.relationship[class] and self.relationship[class][spellID] ) then\n        \n        if ( spellID == 10278 and guid ~= destGUID ) then \n            return\n        end\n        \n        for id, cd in pairs(self.relationship[class][spellID]) do\n            local state = allstates[guid..id];\n            if ( state and (not state.isCD or state.expirationTime < cd + GetTime()) ) then\n                \n                state.show = true;\n                state.changed = true;\n                state.progressType = \"timed\";\n                state.duration = cd;\n                state.expirationTime = cd + GetTime();\n                state.isCD = true;\n                state.dst = config.des;\n                \n                allstates[guid..id] = state;\n                self:AddInfo(guid, id, state.expirationTime, state.dst);\n            end\n        end\n    end    \nend      \n\nfunction PartyCooldownTracker:GetHypothermia(allstates, guid, id)\n    local state = allstates[guid..id];\n    if ( not state ) then\n        return;\n    end\n    \n    local hypothermia = GetSpellInfo(41425);\n    state.changed = true;\n    \n    if ( WA_GetUnitDebuff(state.unit, hypothermia) ) then\n        state.expirationTime = select(7, UnitDebuff(state.unit, hypothermia));\n        allstates[guid..id] = state;\n        self:AddInfo(guid, id, state.expirationTime, state.dst);\n    else\n        state.dst = false;\n        state.isCD = false;\n        state.isBuff = false;\n        state.expirationTime = GetTime();\n        allstates[guid..id] = state;\n        self:AddInfo(guid, id, state.expirationTime, state.dst);\n    end \nend\n\nfunction PartyCooldownTracker:RefreshState(allstates, guid, spellID) \n    for _, id in pairs(self.refresh[spellID]) do\n        if ( id == 45438 ) then\n            return self:GetHypothermia(allstates, guid, id);\n        end\n        \n        if ( allstates[guid..id] ) then\n            local state = allstates[guid..id];\n            state.changed = true;\n            state.expirationTime = GetTime();\n            state.dst = false;\n            state.isCD = false;\n            state.isBuff = false;\n            \n            allstates[guid..id] = state;\n            self:AddInfo(guid, id, state.expirationTime, state.dst);\n        end\n    end\nend\n\nfunction PartyCooldownTracker:SetDesaturated(allstates, guid, spellID)\n    local state = allstates[guid..spellID];\n    if ( not state ) then\n        return;\n    end\n    \n    if ( self.blacklist[spellID] ) then\n        state.expirationTime = GetTime() + state.duration;\n        state.dst = config.des;\n        state.isCD = true;\n        state.isBuff = false;\n        \n        self:AddInfo(guid, spellID, state.expirationTime, state.dst);\n        \n    elseif ( state.isCD and state.isBuff ) then\n        state.expirationTime = state.expirationTime;\n        state.isBuff = false;\n        state.dst = config.des;\n        \n        self:AddInfo(guid, spellID, state.expirationTime, state.dst);\n    end\n    return true;\nend\n\nfunction PartyCooldownTracker:SetGlow(allstates, guid, spellID, duration)\n    local state = allstates[guid..spellID];\n    if ( not state ) then\n        return;\n    end\n    \n    state.isBuff = config.glow;\n    state.dst = false;\n    if ( not self.blacklist[spellID] and duration ) then\n        if ( spellID == 43039 ) then duration = 60; end\n        WeakAuras.timer:ScheduleTimer(WeakAuras.ScanEvents, duration,\n            \"COMBAT_LOG_EVENT_UNFILTERED\", GetTime(), \"SPELL_AURA_REMOVED\", guid, nil, nil, nil, nil, nil, spellID);\n    end\n    return true\nend\n----------------------        CREATE FRAME      -------------------------------------------------------\n-- created when the event is fired\nfunction PartyCooldownTracker:EditState(allstates, guid, spellID, subEvent, destGUID) \n    allstates[guid..spellID] = allstates[guid..spellID] or {};\n    local state = allstates[guid..spellID];\n    local data = self.roster[guid];\n    local unit = data.unitID;\n    local class = data.class;\n    \n    if ( not data or not (data.spells and data.spells[spellID]) ) then \n        return;\n    end\n    \n    state.show = true;\n    state.changed = true;\n    state.progressType = state.progressType or \"timed\";\n    state.icon = state.icon or GetSpellIcon(spellID, guid);\n    state.duration = data.spells[spellID].cd;\n    state.expirationTime = GetTime() + state.duration;\n    -- custom\n    state.autoHide = config.show;\n    state.isCD = true;\n    state.dst = config.des;\n    state.isBuff = false;\n    state.unit = data.unitID;\n    state.unitName = data.unitName;\n    state.guid = guid;\n    state.spellID = spellID;\n    \n    allstates[guid..spellID] = state;\n    self:AddInfo(guid, spellID, state.expirationTime, state.dst);\n    \n    if ( self.refresh[spellID] and subEvent ~= \"UNIT_DIED\" ) then\n        self:RefreshState(allstates, guid, spellID);\n    elseif ( self.relationship[class] and self.relationship[class][spellID] ) then\n        self:Relationship(allstates, guid, spellID, destGUID);\n    end\n    return true;\nend\n-- main create\nfunction PartyCooldownTracker:CreateCDFrame(allstates, guid, spellID)\n    local unitDATA = self.roster[guid];\n    local spellDATA = unitDATA.spells[spellID];\n    \n    allstates[guid..spellID] = {\n        show = true,\n        changed = true,\n        autoHide = config.show,\n        icon = GetSpellIcon(spellID, guid), \n        progressType = \"timed\",\n        duration = spellDATA.cd,\n        expirationTime = spellDATA.exp or GetTime(),\n        -- custom\n        unit = unitDATA.unitID,\n        isCD = ( spellDATA.exp and spellDATA.exp > GetTime() ) and true or false,\n        unitName = unitDATA.unitName,\n        dst = spellDATA.dst or false,\n        isBuff = false,\n        guid = guid,\n        spellID = spellID,\n    };\nend\n\nfunction PartyCooldownTracker:CreateFrame(allstates, guid)\n    local unitDATA = self.roster[guid];\n    for spellID in pairs(unitDATA.spells) do\n        self:CreateCDFrame(allstates, guid, spellID);\n    end\nend\n\nfunction PartyCooldownTracker:CreateFrames(allstates)\n    for guid in pairs(self.roster) do\n        self:CreateFrame(allstates, guid);\n    end\nend\n--------------------------------------------------------------------------\nfunction PartyCooldownTracker:AddCooldownInfo(guid, id, cd)\n    self.roster[guid].spells[id] = self.roster[guid].spells[id] or {};\n    self.roster[guid].spells[id].cd = cd;\nend\n\nfunction PartyCooldownTracker:AddTrinketInfo(guid, invSlot, itemName, itemID, spellID)\n    self.roster[guid].trinkets[invSlot] = self.roster[guid].trinkets[invSlot] or {};\n    self.roster[guid].trinkets[invSlot].itemName = itemName;\n    self.roster[guid].trinkets[invSlot].spellID = spellID;\n    self.roster[guid].trinkets[invSlot].itemID = itemID;\nend\n\nfunction PartyCooldownTracker:AddPetsInfo(unitGUID, petGUID, id, cd)\n    self.roster[unitGUID].pet[petGUID].spells[id] = self.roster[unitGUID].pet[petGUID].spells[id] or {};\n    self.roster[unitGUID].pet[petGUID].spells[id].cd = cd;\nend\n--------------------------------------------------------------------------\nfunction PartyCooldownTracker:RemoveCooldownInfo(allstates, guid, spellID)\n    self.roster[guid].spells[spellID] = nil;\n    local state = allstates[guid..spellID];\n    \n    if ( not state ) then\n        return;\n    end\n    \n    state.show = false;\n    state.changed = true;\n    allstates[guid..spellID] = state;\n    return true;\nend\n\nfunction PartyCooldownTracker:PetCooldownRemove(allstates, guid)\n    local update = falsel\n    for petGUID, data in pairs(self.pet_roster) do\n        if ( data.unitGUID == guid ) then\n            for spellID in pairs(data.spells) do\n                self:RemoveCooldownInfo(allstates, guid, spellID);\n            end\n            self.pet_roster[petGUID] = nil;\n            self.roster[guid].pet[petGUID] = nil;\n            update = true;\n        end\n    end\n    return update;\nend\n\nfunction PartyCooldownTracker:PetCooldownInit(allstates, unitGUID, petGUID, petType)\n    local createFrames = false;\n    for spellID, data in pairs(self.pets[petType]) do\n        if ( data.display ) then\n            self.pet_roster[petGUID].spells[spellID] = true;\n            self:AddPetsInfo(unitGUID, petGUID, spellID, data.cd);\n            self:AddCooldownInfo(unitGUID, spellID, data.cd);\n            self:CreateCDFrame(allstates, unitGUID, spellID);\n            createFrames = true;\n        end\n    end\n    return createFrames;\nend\n\nlocal function CreatePetRoster(unitGUID, petType)\n    return { unitGUID = unitGUID, type = petType, spells = {} };\nend\n\nfunction PartyCooldownTracker:UnitPetCDInit(allstates, unit)\n    local createFrame = false;\n    local unitGUID = UnitGUID(unit);\n    local petID = GetPetID(unit);\n    \n    if ( ( not petID ) or ( not self.roster[unitGUID] ) ) then\n        return;\n    end\n    \n    local petType = UnitCreatureFamily(petID);\n    local petGUID = UnitGUID(petID);\n    if ( self.pets[petType] and not self.pet_roster[petGUID] ) then\n        self.pet_roster[petGUID] = CreatePetRoster(unitGUID, petType);\n        self.roster[unitGUID].pet[petGUID] = CreatePetRoster(unitGUID, petType);\n        if ( self:PetCooldownInit(allstates, unitGUID, petGUID, petType) ) then\n            createFrame = true;\n        end\n    end\n    \n    return createFrame;\nend\n\nlocal function GetTableSize(object)\n    local t = {};\n    for _, v in pairs(object) do\n        tinsert(t, v);\n    end\n    return #t;\nend\n\nlocal function ScheduleTimer(duration, unit, guid, nilchek)\n    WeakAuras.timer:ScheduleTimer(WeakAuras.ScanEvents, duration, \"WA_INSPECT_READY\", unit, guid, nilchek);\nend\n\nPartyCooldownTracker.detected = {};\nfunction PartyCooldownTracker:UnitIsDetected(unit, guid, isDetected)\n    if ( self.detected[guid] ) then\n        self.detected[guid] = WeakAuras.timer:CancelTimer(self.detected[guid]);\n    end\n    if ( isDetected ) then\n        self.detected[guid] = ScheduleTimer(0.5, unit, guid, true);\n    else\n        local duration = GetTableSize(self.detected) + 1;\n        self.detected[guid] = ScheduleTimer(duration, unit, guid, false);\n    end\nend\n\nlocal function CreateTrinketFrame(allstates, guid, invSlot, itemName, itemID, spellID, cooldown)\n    PartyCooldownTracker:AddCooldownInfo(guid, spellID, cooldown);\n    PartyCooldownTracker:AddTrinketInfo(guid, invSlot, itemName, itemID, spellID);\n    PartyCooldownTracker:CreateCDFrame(allstates, guid, spellID);\n    return true;\nend\n\nfunction PartyCooldownTracker:UnitItemInit(allstates, unit, guid)\n    if ( not self.roster[guid] ) then\n        return;\n    end\n    local createFrames = false;\n    local invTrinkets = {};\n    local check = false;\n    local data = self.roster[guid];\n    \n    for invSlot = 13, 14 do\n        local itemLink = GetInventoryItemLink(unit, invSlot) or \"\";\n        local itemID = (itemLink):match(\"item:(%d+):\") or \"\";\n        local itemName = GetItemInfo(itemLink);\n        \n        if ( data.trinkets and data.trinkets[invSlot] ) then\n            if ( itemName and itemName ~= data.trinkets[invSlot].itemName ) then\n                local spellID = data.trinkets[invSlot].spellID;\n                createFrames = self:RemoveCooldownInfo(allstates, guid, spellID);\n                data.trinkets[invSlot] = nil;\n            end\n        end\n        \n        if itemName then \n            invTrinkets[itemName] = invSlot;\n            check = true;\n        end\n    end\n    \n    if ( not check ) then\n        return;\n    end\n    \n    for spellID, info in pairs(self.anyCDs) do\n        if ( info.display and info.trinket ) then\n            if ( type(info.trinket) == \"table\" ) then\n                for _, itemID in pairs(info.trinket) do\n                    if ( invTrinkets[GetItemInfo(itemID)] ) then\n                        local itemName = GetItemInfo(itemID);\n                        local invSlot = invTrinkets[itemName];\n                        local cooldown = info.cd;\n                        createFrames = CreateTrinketFrame(allstates, guid, invSlot, itemName, itemID, spellID, cooldown)\n                    end\n                end\n            else\n                local itemName = GetItemInfo(info.trinket);\n                if ( invTrinkets[itemName] ) then\n                    local invSlot = invTrinkets[itemName];\n                    local cooldown = info.cd;\n                    local itemID = info.trinket;\n                    createFrames = CreateTrinketFrame(allstates, guid, invSlot, itemName, itemID, spellID, cooldown);\n                end\n            end\n        end\n    end\n    \n    return createFrames;\nend\n\nfunction PartyCooldownTracker:GlyphsRosterGeneration(object, unit)\n    local active = self.libGT:GetActiveTalentGroup(unit);\n    for i = 1, 6 do \n        local glyph = select(i, self.libGT:GetUnitGlyphs(unit, active));\n        if ( glyph ) then   \n            object[glyph] = true;\n        end\n    end\n    return object;\nend\n\nfunction PartyCooldownTracker:CheckTalents(allstates, unit, guid, createFrames)\n    local update = createFrames;\n    local class = self.roster[guid].class;\n    local glyphs = self:GlyphsRosterGeneration({}, unit);\n    \n    for spellID, data in pairs(self.cds[class]) do\n        if ( data.display and (data.tReq or data.minus or data.glyph) ) then   \n            if ( not data.tReq\n                or select(5, self.libGT:GetTalentInfo(unit, data.tabIndex, data.talentIndex)) ~= 0 ) then\n                local cooldown = data.cd;\n                local glyphSlot = data.glyph;\n                \n                if ( glyphSlot and glyphs[glyphSlot.glyphID] ) then\n                    cooldown = cooldown - glyphSlot.minus;\n                end\n                \n                if ( data.minus ) then\n                    if ( type(data.minusTabIndex) == \"table\" ) then\n                        for i = 1, #data.minusTabIndex do\n                            local curRank = select(5, self.libGT:GetTalentInfo(unit, data.minusTabIndex[i], data.minusTalentIndex[i])) or 0;\n                            cooldown = cooldown - curRank * data.minusPerPoint[i];\n                        end\n                    else\n                        local curRank = select(5, self.libGT:GetTalentInfo(unit, data.minusTabIndex, data.minusTalentIndex)) or 0;\n                        cooldown = cooldown - curRank * data.minusPerPoint;\n                    end\n                end\n                \n                if ( class == \"HUNTER\" ) then\n                    for spell, spellData in pairs(self.relationship[class]) do\n                        for spellId in pairs(spellData) do\n                            if ( spellId == spellID ) then\n                                self.relationship[class][spell][spellId] = cooldown;\n                            end\n                        end \n                    end\n                end\n                \n                self:AddCooldownInfo(guid, spellID, cooldown);\n                update = true;\n            elseif ( self.roster[guid].spells[spellID] ) then\n                update = self:RemoveCooldownInfo(allstates, guid, spellID);\n            end\n        end\n    end\n    \n    if ( update ) then\n        self:CreateFrame(allstates, guid);\n    end\n    WeakAuras.ScanEvents(\"UNIT_IS_VISIBLE\", unit, guid);\n    return update;\nend\n\nfunction PartyCooldownTracker:UnitCooldownsInit(allstates, unit, guid)\n    local class = self.roster[guid].class;\n    local race = self.roster[guid].race;\n    local check = false;\n    local createFrames = false;\n    \n    for spellID, data in pairs(self.cds[class]) do\n        if ( data.display ) then\n            if ( not data.tReq ) then\n                self:AddCooldownInfo(guid, spellID, data.cd);\n                createFrames = true;\n            end\n            \n            if ( not check and (data.tReq or data.minus) ) then\n                check = true;\n            end\n        end\n    end  \n    \n    for spellID, data in pairs(self.anyCDs) do\n        if ( data.display ) then\n            if data.race == race then\n                self:AddCooldownInfo(guid, spellID, data.cd);\n                createFrames = true;\n            end\n        end\n    end\n    \n    if ( check and self.libGT and self.libGT:GetUnitTalents(unit) ) then\n        return self:CheckTalents(allstates, unit, guid, createFrames);\n    elseif ( createFrames ) then\n        self:CreateFrame(allstates, guid);\n    end\n    return createFrames;\nend\n\nfunction PartyCooldownTracker:RosterGeneration(unit, guid, unitClass, faction, race, unitName)\n    return { \n        spells = {}, \n        trinkets = {}, \n        pet = {},\n        unitID = unit, \n        class = unitClass, \n        faction = faction, \n        race = race, \n        unitName = unitName,\n    };\nend\n\nfunction PartyCooldownTracker:InitNewMembers(allstates)\n    local updateFrames = false;\n    for guid, unitData in pairs(self.roster) do\n        if ( not UnitInParty(unitData.unitName) ) then\n            if ( unitData.spells ) then\n                for id in pairs(unitData.spells) do\n                    self:RemoveCooldownInfo(allstates, guid, id);\n                    self:PetCooldownRemove(allstates, guid);\n                end \n            end\n            self.roster[guid] = nil;\n            updateFrames = true;\n        end\n    end\n    \n    for i = 1, self:GetNumPartyMembers() do\n        local unit = \"party\"..i;\n        local unitName = UnitName(unit);\n        local faction = UnitFactionGroup(unit) ; \n        local _, race = UnitRace(unit);\n        local guid = UnitGUID(unit);\n        local _, unitClass = UnitClass(unit);\n        \n        if ( unitName ~= _G.UNKNOWNOBJECT and not self.roster[guid] ) then\n            if ( self.cds[unitClass] ) then\n                self.roster[guid] = self:RosterGeneration(unit, guid, unitClass, faction, race, unitName);\n                \n                if ( self:UnitPetCDInit(allstates, unit) ) then\n                    updateFrames = true;\n                end\n                if ( self:UnitCooldownsInit(allstates, unit, guid) ) then\n                    updateFrames = true;\n                end\n            end\n        end\n    end\n    return updateFrames;\nend\n-------------- >> ANCHOR TO FRMAE << ----------------\nlocal defaultFramePriorities = {\n    -- raid frames\n    [0] = nil,\n    [1] = \"^Vd1\", -- vuhdo\n    [2] = \"^Vd2\", -- vuhdo\n    [3] = \"^Vd3\", -- vuhdo\n    [4] = \"^Vd4\", -- vuhdo\n    [5] = \"^Vd5\", -- vuhdo\n    [6] = \"^Vd\", -- vuhdo\n    [7] = \"^HealBot\", -- healbot\n    [8] = \"^GridLayout\", -- grid\n    [9] = \"^Grid2Layout\", -- grid2\n    [10] = \"^PlexusLayout\", -- plexus\n    [11] = \"^ElvUF_RaidGroup\", -- elv\n    [12] = \"^oUF_bdGrid\", -- bdgrid\n    [13] = \"^oUF_.-Raid\", -- generic oUF\n    [14] = \"^LimeGroup\", -- lime\n    [15] = \"^SUFHeaderraid\", -- suf\n    -- party frames\n    [16] = \"^AleaUI_GroupHeader\", -- Alea\n    [17] = \"^SUFHeaderparty\", --suf\n    [18] = \"^ElvUF_PartyGroup\", -- elv\n    [19] = \"^oUF_.-Party\", -- generic oUF\n    [20] = \"^PitBull4_Groups_Party\", -- pitbull4\n    [21] = \"^XPerl_party\", -- xperl\n    [22] = \"^PartyMemberFrame\", -- blizz\n    [23] = \"^CompactRaid\", -- blizz\n};\n\nlocal defaultPartyTargetFrames = {\n    \"SUFChildpartytarget%d\",\n};\n\nlocal attachIndex = ( config.frame - 1 );\nlocal getFrameOptions = {\n    framePriorities = {\n        [1] = defaultFramePriorities[attachIndex],\n    },\n    ignorePartyTargetFrame = true,\n    partyTargetFrames = defaultPartyTargetFrames,\n};\nif ( config.blizzFrame ) then\n    getFrameOptions.ignoreFrames = {\n        \"PitBull4_Frames_Target's target's target\",\n        \"ElvUF_PartyGroup%dUnitButton%dTarget\",\n        \"ElvUF_FocusTarget\",\n        \"PartyMemberFrame\",\n        \"RavenButton\",\n    };\nend\n\nlocal growDirections = {\n    [1] = \"BOTTOM\",\n    [2] = \"BOTTOMLEFT\",\n    [3] = \"BOTTOMRIGHT\",    \n    [4] = \"CENTER\",\n    [5] = \"LEFT\",\n    [6] = \"RIGHT\",\n    [7] = \"TOP\",\n    [8] = \"TOPLEFT\",\n    [9] = \"TOPRIGHT\",\n};\n\nPartyCooldownTracker.positionFrom = growDirections[config.anchor];\nPartyCooldownTracker.positionTo = growDirections[config.anchorTo];\nPartyCooldownTracker.spacing = config.spacing;\nPartyCooldownTracker.xOffset = config.xOffset;\nPartyCooldownTracker.yOffset = config.yOffset;\nPartyCooldownTracker.column = config.column;\nPartyCooldownTracker.auraCount = {};\n\nlocal function setIconPosition(self, state, rowIdx)\n    local unitToken;\n    for i = 1, self:GetNumPartyMembers() do\n        local unit = \"party\"..i;\n        if ( UnitName(unit) == state.unitName ) then unitToken = unit; end\n    end\n    if ( not unitToken ) then\n        state.show = false\n        state.changed = true\n    else\n        state.unitID = unitToken;\n        local region = WeakAuras.GetRegion(self.id, state.guid..state.spellID);\n        local f = WeakAuras.GetUnitFrame(state.unitID, getFrameOptions);\n        if ( f and region ) then\n            self.auraCount[state.unitID] = self.auraCount[state.unitID] or {};\n            self.auraCount[state.unitID].rowIdx = self.auraCount[state.unitID].rowIdx or 0;\n            self.auraCount[state.unitID].column = self.auraCount[state.unitID].column or 0;\n            self.auraCount[state.unitID].delta = self.auraCount[state.unitID].delta or 1;\n            \n            if ( self.auraCount[state.unitID].rowIdx == self.column ) then\n                self.auraCount[state.unitID].column = self.auraCount[state.unitID].column + 1;\n                self.auraCount[state.unitID].rowIdx = 0;\n                self.auraCount[state.unitID].delta = rowIdx;\n            end\n            \n            local order = self.auraCount[state.unitID].column;\n            local xoffset, yoffset = 0, 0;\n            local height, width = region:GetHeight() + self.spacing, region:GetWidth() + self.spacing;\n            local delta = self.auraCount[state.unitID].delta;\n            \n            if ( config.direction == 1 ) then -- Влево, затем вниз\n                yoffset = yoffset - (order * height);\n                xoffset = xoffset - (rowIdx - delta) * width;\n            elseif ( config.direction == 2 ) then -- Вправо, затем вниз\n                yoffset = yoffset - (order * height);\n                xoffset = xoffset + (rowIdx - delta) * width;\n            elseif ( config.direction == 3 ) then -- Влево, затем вверх\n                yoffset = yoffset + (order * height);\n                xoffset = xoffset - (rowIdx - delta) * width;\n            elseif ( config.direction == 4 ) then  -- Вправо, затем вверх\n                yoffset = yoffset + (order * height);\n                xoffset = xoffset + (rowIdx - delta) * width;\n            end\n            \n            region:SetAnchor(self.positionFrom, f, self.positionTo);\n            region:SetOffset(xoffset + self.xOffset, yoffset + self.yOffset);\n            self.auraCount[state.unitID].rowIdx = self.auraCount[state.unitID].rowIdx + 1;\n        else\n            region:SetAnchor(self.positionFrom, _G.UIParent, self.positionTo);\n            region:SetOffset(-3000, 0);\n            if ( not config.lib_error ) then\n                DEFAULT_CHAT_FRAME:AddMessage(\"|cff69ccf0PartyCooldownTracker|r: 404 frame not found. Calling the function again.\")\n            end\n            self:scheduleUpdateEvent(\"INVISUS_COOLDOWNS\", 0.5, \"FRAME_UPDATE\");\n        end\n    end\nend\n\nfunction PartyCooldownTracker:sort(allstates)\n    local t = {};\n    for _, state in pairs(allstates) do\n        if ( state.spellID ) then\n            t[#t+1] = state;\n        end\n    end\n    table.sort(t, function (a,b)     \n            return ( a.spellID > b.spellID ) \n    end)\n    \n    return t;\nend\n\nPartyCooldownTracker.updateFrames = function(self, allstates)\n    table.wipe(self.auraCount);\n    local sortTable = self:sort(allstates);\n    for guid in pairs(self.roster) do  \n        local rowIdx = 0;\n        for _, state in pairs(sortTable) do\n            if ( state.show and state.guid == guid ) then\n                rowIdx = rowIdx + 1;\n                setIconPosition(self, state, rowIdx);\n            end                \n        end            \n    end\nend\n\nlocal timer;\nfunction PartyCooldownTracker:scheduleUpdateFrames(allstates, duration)\n    if ( timer ) then WeakAuras.timer:CancelTimer(timer); end\n    timer = WeakAuras.timer:ScheduleTimer(function()\n            self:updateFrames(allstates) end, \n        duration\n    );\nend\n\nPartyCooldownTracker.Events = {};\nfunction PartyCooldownTracker:scheduleUpdateEvent(event, duration, ...)\n    if ( ( not event ) or (not duration ) ) then\n        return\n    end\n    if ( self.Events[event] ) then self.Events[event] = WeakAuras.timer:CancelTimer(self.Events[event]); end\n    self.Events[event] = WeakAuras.timer:ScheduleTimer(WeakAuras.ScanEvents, \n    duration, event, ...);\nend \n\nPartyCooldownTracker.cds = {\n    [\"DEATHKNIGHT\"] = {\n        [48707] = {\n            [\"cd\"] = 45,\n        },\n        [51052] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 22,\n            [\"cd\"] = 120,\n        },\n        [49016] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 19,\n            [\"cd\"] = 180,\n        },\n        [48792] = {\n            [\"cd\"] = 120,\n        },\n        [49005] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 15,\n            [\"cd\"] = 180,\n        },\n        [48982] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 7,\n            [\"cd\"] = 60,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 10,\n            [\"minusPerPoint\"] = 10,\n        },\n        [55233] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 23,\n            [\"cd\"] = 60,\n        },\n        [49576] = {\n            [\"cd\"] = 35,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 6,\n            [\"minusPerPoint\"] = 5,\n        }, \n        [46584] = {\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = {3, 3},\n            [\"minusTalentIndex\"] = {13, 20},\n            [\"minusPerPoint\"] = {45, 60},\n        },  \n        [42650] = {\n            [\"cd\"] = 600,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 13,\n            [\"minusPerPoint\"] = 120,\n        },\n        [47528] = {\n            [\"cd\"] = 10,\n        }, \n        [48743] = {\n            [\"cd\"] = 120,\n        }, \n        [47476] = {\n            [\"cd\"] = 120,\n            [\"glyph\"] = {[\"glyphID\"] = 58618, [\"minus\"]= 20},\n        }, \n        [49206] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 31,\n            [\"cd\"] = 180,\n        }, \n        [49203] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 20,\n            [\"cd\"] = 180,\n        }, \n        [49039] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 8,\n            [\"cd\"] = 120\n        },\n        [51271] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 24,\n            [\"cd\"] = 60,\n        },\n        [49937] = {\n            [\"cd\"] = 30, \n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 5,\n            [\"minusPerPoint\"] = 5,\n        }, \n    },\n    [\"DRUID\"] = {\n        [29166] = {\n            [\"cd\"] = 180,\n        },\n        [48477] = {\n            [\"cd\"] = 600,\n        },\n        [48447] = {\n            [\"cd\"] = 480,\n        },\n        [22812] = {\n            [\"cd\"] = 60,\n        },\n        [61336] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 7,\n            [\"cd\"] = 180,\n        },\n        [22842] = {\n            [\"cd\"] = 180,\n        },\n        [8983] = {\n            [\"cd\"] = 60,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 13,\n            [\"minusPerPoint\"] = 15,\n        },\n        [53201] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 28,\n            [\"cd\"] = 90,\n            [\"glyph\"] = {[\"glyphID\"] = 54828, [\"minus\"] = 30},\n        }, \n        [61384] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 24,\n            [\"cd\"] = 20,\n            [\"glyph\"] = {[\"glyphID\"] = 63056, [\"minus\"] = 3},\n        },\n        [33357] = {\n            [\"cd\"] = 180,\n            [\"glyph\"] = {[\"glyphID\"] = 59219, [\"minus\"] = 36},\n        }, \n        [49376] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 14,\n            [\"cd\"] = 30,\n        }, \n        [16979] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 14,\n            [\"cd\"] = 15,\n        }, \n        [50334] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 30,\n            [\"cd\"] = 180,\n        }, \n        [17116] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 12,\n            [\"cd\"] = 180,\n        },\n        [18562] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 18,\n            [\"cd\"] = 15,\n        }, \n        [48438] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 27,\n            [\"cd\"] = 6,\n        }, \n        [33831] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 25,\n            [\"cd\"] = 180,\n        }, \n    },\n    [\"HUNTER\"] = {\n        [19263] = {\n            [\"cd\"] = 60,\n            [\"glyph\"] = {[\"glyphID\"] = 56850, [\"minus\"] = 10},\n        },\n        [34477] = {\n            [\"cd\"] = 30,\n        },\n        [53271] = {\n            [\"cd\"] = 60,\n        },\n        [3045] = {\n            [\"cd\"] = 300,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 10,\n            [\"minusPerPoint\"] = 60,\n        },\n        [5384] = {\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 11,\n            [\"minusPerPoint\"] = 2,\n            [\"glyph\"] = {[\"glyphID\"] = 57903, [\"minus\"] = 5},\n        },\n        [781] = {\n            [\"cd\"] = 25,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 11,\n            [\"minusPerPoint\"] = 2,\n            [\"glyph\"] = {[\"glyphID\"] = 56844, [\"minus\"] = 5},\n        },\n        [63672] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 25,\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 2,\n        },\n        [49067] = {\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 2,\n        },\n        [14311] = {\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 2,\n        },\n        [60192] = {\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 2,\n        },\n        [34600] = {\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 2,     \n        },\n        [13809] = {\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 2,     \n        },\n        [49056] = {\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 2,      \n        },\n        [23989]  = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 14,\n            [\"cd\"] = 180,\n        }, \n        [19503]  = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 9,\n            [\"cd\"] = 30,\n        },\n        [34490]  = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 24,\n            [\"cd\"] = 20,\n        },\n        [1543]   = {\n            [\"cd\"] = 20,\n        },  \n        [49012]  = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 20,\n            [\"cd\"] = 60,\n            [\"glyph\"] = {[\"glyphID\"] = 56848, [\"minus\"] = 6},\n        }, \n        [49048]  = {\n            [\"cd\"] = 10,\n            [\"glyph\"] = {[\"glyphID\"] = 56836, [\"minus\"] = 1},\n        }, \n        [19577]  = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 13,\n            [\"cd\"] = 60,\n        }, \n        [19574]  = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 18,\n            [\"cd\"] = 100,\n            [\"glyph\"] = {[\"glyphID\"] = 56830, [\"minus\"] = 20},\n        }, \n        [49050]  = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 9,\n            [\"cd\"] = 8,\n            [\"glyph\"] = {[\"glyphID\"] = 56824, [\"minus\"] = 2},\n        }, \n        [53209]  = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 27,\n            [\"cd\"] = 10,\n            [\"glyph\"] = {[\"glyphID\"] = 63065, [\"minus\"] = 1},\n        }, \n        [61006]  = {\n            [\"cd\"] = 15,\n            [\"glyph\"] = {[\"glyphID\"] = 63067, [\"minus\"] = 6}, \n        }, \n    },\n    [\"MAGE\"] = {\n        [45438] = {\n            [\"cd\"] = 300,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 3,\n            [\"minusPerPoint\"] = 20,\n        },\n        [66] = {\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 24,\n            [\"minusPerPoint\"] = 27,\n        },\n        [12472] = {\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 3,\n            [\"minusPerPoint\"] = 12,\n        },\n        [42917] = {\n            [\"cd\"] = 25,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 3,\n            [\"minusPerPoint\"] = 1.666667,\n        },        \n        [42931] = {\n            [\"cd\"] = 10,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 3,\n            [\"minusPerPoint\"] = 0.7,    \n        },   \n        [2139]  = {\n            [\"cd\"] = 24,\n        }, \n        [55342] = {\n            [\"cd\"] = 180,\n        }, \n        [1953]  = {\n            [\"cd\"] = 15,\n        },\n        [12051] = {\n            [\"cd\"] = 240,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 24,\n            [\"minusPerPoint\"] = 60,\n        },\n        [12043] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 16,\n            [\"cd\"] = 120,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 24,\n            [\"minusPerPoint\"] = 18,\n        },\n        [12042] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 22,\n            [\"cd\"] = 120,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 24,\n            [\"minusPerPoint\"] = 18,\n        }, \n        [42945] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 16,\n            [\"cd\"] = 30,\n        },  \n        [42950] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 25,\n            [\"cd\"] = 20,\n        }, \n        [11958] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 14,\n            [\"cd\"] = 480,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 17,\n            [\"minusPerPoint\"] = 48,\n        },\n        [43039] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 20,\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 17,\n            [\"minusPerPoint\"] = 3,\n        }, \n        [31687] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 25,\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 17,\n            [\"minusPerPoint\"] = 15,\n            [\"glyph\"] = {[\"glyphID\"] = 56373, [\"minus\"] = 30},\n        },\n        [44572] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 28,\n            [\"cd\"] = 30,\n        },  \n    },\n    [\"PALADIN\"] = {\n        [31821] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 6,\n            [\"cd\"] = 120,\n        },\n        [498] = {\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 14,\n            [\"minusPerPoint\"] = 30,\n        },\n        [64205] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 6,\n            [\"cd\"] = 120,\n        },\n        [642] = {\n            [\"cd\"] = 300,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 14,\n            [\"minusPerPoint\"] = 30,\n        },\n        [48788] = {\n            [\"cd\"] = 1200,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 8,\n            [\"minusPerPoint\"] = 120,\n            [\"glyph\"] = {[\"glyphID\"] = 57955, [\"minus\"] = 300},\n        },\n        [1044] = {\n            [\"cd\"] = 25,\n        },\n        [54428] = {\n            [\"cd\"] = 60,\n        },\n        [10278] = {\n            [\"cd\"] = 300,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 4,\n            [\"minusPerPoint\"] = 60,\n        },\n        [6940] = {\n            [\"cd\"] = 120,\n        },\n        [1038] = {\n            [\"cd\"] = 120,\n        },\n        [10308] = {\n            [\"cd\"] = 60,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = {2, 2},\n            [\"minusTalentIndex\"] = {10, 25},\n            [\"minusPerPoint\"] = {10, 5},\n        },  \n        [31884] = {\n            [\"cd\"] = 180,\n        }, \n        [48806] = {\n            [\"cd\"] = 6,\n        }, \n        [19752] = {\n            [\"cd\"] = 600,\n        }, \n        [31935] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 22,\n            [\"cd\"] = 30,\n        }, \n        [20066] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 18,\n            [\"cd\"] = 60,\n        },\n        [48825] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 19,\n            [\"cd\"] = 6,\n            [\"glyph\"] = {[\"glyphID\"] = 63224, [\"minus\"] = 1},\n        }, \n        [20216] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 13,\n            [\"cd\"] = 120,\n        }, \n        [10326] = {\n            [\"cd\"] = 1,\n            [\"glyph\"] = {[\"glyphID\"] = 54931, [\"minus\"] = -7},\n        },\n        [48817] = {\n            [\"cd\"] = 30,\n            [\"glyph\"] = {[\"glyphID\"] = 56420, [\"minus\"]= 15},\n        }, \n    },\n    [\"PRIEST\"] = {\n        [64843] = {\n            [\"cd\"] = 480,\n        },\n        [48158] = {\n            [\"cd\"] = 12,\n        },\n        [6346] = {\n            [\"cd\"] = 180,\n            [\"glyph\"] = {[\"glyphID\"] = 55678, [\"minus\"] = 60},\n        },\n        [47788] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 27,\n            [\"cd\"] = 180,\n        },\n        [64901] = {\n            [\"cd\"] = 360,\n        },\n        [10060] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 19,\n            [\"cd\"] = 120,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 23,\n            [\"minusPerPoint\"] = 12,\n        },\n        [10890] = {\n            [\"cd\"] = 27,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 7,\n            [\"minusPerPoint\"] = 2,\n            [\"glyph\"] = {[\"glyphID\"] = 55676, [\"minus\"] = -8},\n        },\n        [34433] = {\n            [\"cd\"] = 300,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 10,\n            [\"minusPerPoint\"] = 60,\n        },\n        [33206] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 25,\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 23,\n            [\"minusPerPoint\"] = 18,\n        },\n        [48173] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 6,\n            [\"cd\"] = 120,\n        },   \n        [53007] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 25,\n            [\"cd\"] = 10,\n            [\"glyph\"] = {[\"glyphID\"] = 63235, [\"minus\"] = 2},\n        },  \n        [14751] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 8,\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 23,\n            [\"minusPerPoint\"] = 18,\n        },\n        [64044] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 23,\n            [\"cd\"] = 120,\n        }, \n        [47585] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 27,\n            [\"cd\"] = 120,\n            [\"glyph\"] = {[\"glyphID\"] = 63229, [\"minus\"]= 45},\n        }, \n        [15487] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 13,\n            [\"cd\"] = 45,\n        }, \n    },\n    [\"ROGUE\"]  = {\n        [31224] = {\n            [\"cd\"] = 90,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 7,\n            [\"minusPerPoint\"] = 15,\n        },\n        [26669] = {\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 7,\n            [\"minusPerPoint\"] = 30,\n        },\n        [57934] = {\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 26,\n            [\"minusPerPoint\"] = 5,\n        }, \n        [26889] = {\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 7,\n            [\"minusPerPoint\"] = 30,\n        },\n        [2094] = {\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 7,\n            [\"minusPerPoint\"] = 30,\n        },\n        [14185] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 14,\n            [\"cd\"] = 480,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 26,\n            [\"minusPerPoint\"] = 90, \n        },\n        [36554] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 25,\n            [\"cd\"] = 30,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 26,\n            [\"minusPerPoint\"] = 5,\n            \n        },\n        [11305] = {\n            [\"cd\"] = 180,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 7,\n            [\"minusPerPoint\"] = 30,\n        },\n        [51722] = {\n            [\"cd\"] = 60,\n        },  \n        [1766]  = {\n            [\"cd\"] = 10,\n        }, \n        [1776]  = {\n            [\"cd\"] = 10,\n        },  \n        [8643]  = {\n            [\"cd\"] = 20,\n        },\n        [51713] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 28,\n            [\"cd\"] = 60,\n        },  \n        [51690] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 28,\n            [\"cd\"] = 120,\n            [\"glyph\"] = {[\"glyphID\"] = 63252, [\"minus\"]= 45},\n        },\n        [14177] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 13,\n            [\"cd\"] = 180,\n        },  \n    },\n    [\"SHAMAN\"] = {\n        [32182] = {\n            [\"cd\"] = 300,\n        },\n        [2825] = {\n            [\"cd\"] = 300,\n        },\n        [16190] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 17,\n            [\"cd\"] = 300,\n        },\n        [20608] = {\n            [\"cd\"] = 1800,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 3,\n            [\"minusPerPoint\"] = 420,\n        },\n        [30823] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 26,\n            [\"cd\"] = 60,\n        },\n        [57994] = {\n            [\"cd\"] = 6,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 6,\n            [\"minusPerPoint\"] = 0.2,\n        }, \n        [8177]  = {\n            [\"cd\"] = 15,\n        },  \n        [51514] = {\n            [\"cd\"] = 45,\n        }, \n        [59159] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 25,\n            [\"cd\"] = 45,\n            [\"glyph\"] = {[\"glyphID\"] = 63270, [\"minus\"] = 10},\n        }, \n        [51533] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 29,\n            [\"cd\"] = 180,\n        },  \n        [2894]  = {\n            [\"cd\"] = 600,\n            [\"glyph\"] = {[\"glyphID\"] = 55455, [\"minus\"] = 300},\n            \n        },  \n        [2484]  = {\n            [\"cd\"] = 15,\n        }, \n        [16166] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 16,\n            [\"cd\"] = 180,\n            [\"glyph\"] = {[\"glyphID\"] = 55452, [\"minus\"] = 30},\n        }, \n    }, \n    [\"WARLOCK\"] = {\n        [47877] = {\n            [\"cd\"] = 120,\n        },\n        [48020] = {\n            [\"cd\"] = 30,\n            [\"glyph\"] = {[\"glyphID\"] = 63309, [\"minus\"] = 4}, \n        }, \n        [1122]  = {\n            [\"cd\"] = 600,\n        },\n        [61290] = {\n            [\"cd\"] = 15,\n        },\n        [47827] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 7,\n            [\"cd\"] = 15,\n        },\n        [59671] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 27,\n            [\"cd\"] = 15,\n        },\n        [54785] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 27,\n            [\"cd\"] = 45,\n        },  \n        [47860] = {\n            [\"cd\"] = 120,\n        }, \n        [17928] = {\n            [\"cd\"] = 40,\n            [\"glyph\"] = {[\"glyphID\"] = 56217, [\"minus\"] = 8},\n        },\n        [50796] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 26,\n            [\"cd\"] = 12,   \n            [\"glyph\"] = {[\"glyphID\"] = 63304, [\"minus\"] = 2},    \n        },  \n        [47847] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 23,\n            [\"cd\"] = 20,\n        }, \n        [18708] = {\n            [\"cd\"] = 180,\n        },\n        [47139] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 19,\n            [\"cd\"] = 60,  \n        },\n    },\n    [\"WARRIOR\"] = {\n        [55694] = {\n            [\"cd\"] = 180,\n        },\n        [12975] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 6,\n            [\"cd\"] = 180,\n            [\"glyph\"] = {[\"glyphID\"] = 58376, [\"minus\"] = 60},\n        },\n        [2565] = {\n            [\"cd\"] = 60,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 8,\n            [\"minusPerPoint\"] = 10,\n        },\n        [871] = {\n            [\"cd\"] = 300,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 13,\n            [\"minusPerPoint\"] = 30,\n            [\"glyph\"] = {[\"glyphID\"] = 63329, [\"minus\"] = 120},\n        },\n        [11578] = {\n            [\"cd\"] = 15,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 1,\n            [\"minusTalentIndex\"] = 24,\n            [\"minusPerPoint\"] = -5,\n        },  \n        [676] = {\n            [\"cd\"] = 60,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 3,\n            [\"minusTalentIndex\"] = 11,\n            [\"minusPerPoint\"] = 10,\n        },\n        [1719] = {\n            [\"cd\"] = 300,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 33.333,\n        },\n        [20230] = {\n            [\"cd\"] = 300,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 18,\n            [\"minusPerPoint\"] = 33.333,\n        },\n        [20252] =  {\n            [\"cd\"] = 25,\n            [\"minus\"] = true,\n            [\"minusTabIndex\"] = 2,\n            [\"minusTalentIndex\"] = 15,\n            [\"minusPerPoint\"] = 5,\n        },\n        [23920] = {\n            [\"cd\"] = 10,\n            [\"glyph\"] = {[\"glyphID\"] = 63328, [\"minus\"] = 1},\n        },\n        [3411]  = {\n            [\"cd\"] = 30,\n        }, \n        [72]    = {\n            [\"cd\"] = 12,\n        }, \n        [6552]  = {\n            [\"cd\"] = 10,            \n        }, \n        [5246]  = {\n            [\"cd\"] = 120,\n        },\n        [46924] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 1,\n            [\"talentIndex\"] = 31,\n            [\"cd\"] = 90,\n            [\"glyph\"] = {[\"glyphID\"] = 63324, [\"minus\"] = 15},\n        }, \n        [60970] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 23,\n            [\"cd\"] = 45,\n        },  \n        [12809] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 14,\n            [\"cd\"] = 30,\n        }, \n        [46968] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 3,\n            [\"talentIndex\"] = 27,\n            [\"cd\"] = 20,\n            [\"glyph\"] = {[\"glyphID\"] = 63325, [\"minus\"] = 3},\n        },\n        [12292] = {\n            [\"tReq\"] = true,\n            [\"tabIndex\"] = 2,\n            [\"talentIndex\"] = 14,\n            [\"cd\"] = 180,\n        },\n    },    \n};\n\nif ( config.cds ) then\n    for class, classData in pairs(config.cds) do\n        if ( PartyCooldownTracker.cds[class] ) then\n            for spellID, enable in pairs(classData) do\n                spellID = tonumber(spellID);\n                local spellDATA = PartyCooldownTracker.cds[class][spellID];\n                if ( spellDATA ) then\n                    spellDATA.display = enable;\n                end\n            end\n        end\n    end\nend\n\n-- Heroism / Bloodlust\nif ( UnitFactionGroup(\"player\") == \"Horde\" ) then\n    PartyCooldownTracker.cds[\"SHAMAN\"][32182] = nil;\nelse\n    PartyCooldownTracker.cds[\"SHAMAN\"][2825] = nil;\nend\n-- preparation spells\nPartyCooldownTracker.refresh = {\n    [14185] = {26669, 11305, 26889, 14177, 36554, 13877, 51722, 1766}, -- ROGUE\n    [23989] = {\n        19263, 5384, 781, 19503, 34490, 1543, 34600, 3045, \n        49067, 49056, 14311, 60192, 13809, 63672, 49012,  \n        49048, 19577, 49050,53209, 61006, 34477, 53721\n    }, -- HUNTER\n    [11958] = {42917, 45438, 43039, 31687, 44572, 12472}, -- MAGE\n    [46584] = {47481}, -- DK\n};\n\nPartyCooldownTracker.anyCDs = {\n    -- spellID                itemID/race                          \n    [42292] = {[\"cd\"] = 120, [\"trinket\"] = {51377, 51378, 46082}}, -- Медальон Альянса\\Орды\n    [71607] = {[\"cd\"] = 120, [\"trinket\"] = {50726, 50354}}, -- Подвеска истинной крови\n    [71586] = {[\"cd\"] = 120, [\"trinket\"] = 50356}, -- Проржавевший костяной ключ\n    [71638] = {[\"cd\"] = 60,  [\"trinket\"] = 50364}, -- Безупречный клык Синдрагосы\n    [75490] = {[\"cd\"] = 120, [\"trinket\"] = 54573}, -- Светящаяся сумеречная чешуя\n    [67596] = {[\"cd\"] = 120, [\"trinket\"] = {42137, 42136, 42135, 42134, 42133}}, -- Ярость/Точность/Бодрость/Неистовство/Опустошение военачальника\n    \n    [59752] = {[\"cd\"] = 120, [\"race\"] = \"Human\"}, -- Каждый за себя\n    [58984] = {[\"cd\"] = 120, [\"race\"] = \"NightElf\"}, -- Слиться с тенью\n    [59547] = {[\"cd\"] = 180, [\"race\"] = \"Draenei\"}, -- Дар наару\n    [20594] = {[\"cd\"] = 120, [\"race\"] = \"Dwarf\"}, -- Каменная форма\n    [20589] = {[\"cd\"] = 95,  [\"race\"] = \"Gnome\"}, -- Мастер побега\n    [20572] = {[\"cd\"] = 120, [\"race\"] = \"Orc\"}, -- Кровавое неистовство\n    [7744]  = {[\"cd\"] = 120, [\"race\"] = \"Scourge\"}, -- Воля Отрекшихся\n    [20549] = {[\"cd\"] = 120, [\"race\"] = \"Tauren\"}, -- Громовая поступь\n    [26297] = {[\"cd\"] = 180, [\"race\"] = \"Troll\"}, -- Берсерк\n    [28730] = {[\"cd\"] = 120, [\"race\"] = \"BloodElf\"}  -- Волшебный поток\n};\n\nif ( config.ANY ) then\n    for spellID, enable in pairs(config.ANY) do\n        spellID = tonumber(spellID);\n        if ( PartyCooldownTracker.anyCDs[spellID] ) then\n            PartyCooldownTracker.anyCDs[spellID].display = enable;\n        end\n    end\nend\n-- casting spells that can\"t be read from CLEU\nPartyCooldownTracker.USS = {\n    [GetSpellInfo(48477)] = {\n        display = PartyCooldownTracker.cds.DRUID[48477].display,\n        id = 48477,\n    },\n    [GetSpellInfo(51514)] = {\n        display = PartyCooldownTracker.cds.SHAMAN[51514].display,\n        id = 51514,\n    },\n    [GetSpellInfo(61384)] = {\n        display = PartyCooldownTracker.cds.DRUID[61384].display,\n        id = 61384,\n    },\n    [GetSpellInfo(17928)] = {\n        display = PartyCooldownTracker.cds.WARLOCK[17928].display,\n        id = 17928,\n    },\n    [GetSpellInfo(50796)] = {\n        display = PartyCooldownTracker.cds.WARLOCK[50796].display,\n        id = 50796,\n    }, \n    [GetSpellInfo(47877)] = {\n        display = PartyCooldownTracker.cds.WARLOCK[47877].display,\n        id = 47877,\n    },\n    [GetSpellInfo(53007)] = {\n        display = PartyCooldownTracker.cds.PRIEST[53007].display,\n        id = 53007\n    }\n};\n-- spells that have one CD\"s\nPartyCooldownTracker.relationship = {\n    [\"PALADIN\"] = {\n        [498]   = {[31884] = 30, [642] = 120},\n        [642]   = {[31884] = 30, [498] = 120},\n        [31884] = {[642]   = 30, [498] = 30},\n        [10278] = {[31884] = 30, [642] = 120, [498] = 120},\n    },\n    [\"WARRIOR\"] = {\n        [72]    = {[6552] = 10},\n        [6552]  = {[72] = 12}\n    },\n    [\"HUNTER\"]  = {\n        [14311] = {[60192] = 30, [13809] = 30}, \n        [60192] = {[14311] = 30, [13809] = 30},\n        [13809] = {[14311] = 30, [60192] = 30},\n        [49056] = {[49067] = 30},\n        [49067] = {[49056] = 30}\n    },\n    [\"DRUID\"]   = {\n        [49376] = {[16979] = 15},\n        [16979] = {[49376] = 15}\n    }\n};\n\nlocal L = {};\nif GetLocale() == \"ruRU\" then\n    L[\"Felhunter\"] = \"Охотник Скверны\"\n    L[\"Voidwalker\"] = \"Демон Бездны\"\n    L[\"Ghoul\"] = \"Вурдалак\"\n    L[\"Spider\"] = \"Паук\"\n    L[\"Crab\"] = \"Краб\"\n    L[\"Wolf\"] = \"Волк\"\n    L[\"Worm\"] = \"Червь\"   \n    L[\"Chimaera\"] = \"Химера\"\n    L[\"Gorilla\"] = \"Горилла\"\n    L[\"Turtle\"] = \"Черепаха\"\n    L[\"Spirit Beast\"] = \"Дух зверя\"\n    L[\"Core Hound\"] = \"Гончая Недр\"\n    L[\"Bat\"] = \"Летучая мышь\"\n    L[\"Ravager\"] = \"Опустошитель\"\nelse\n    L[\"Felhunter\"] = \"Felhunter\"\n    L[\"Voidwalker\"] = \"Voidwalker\"\n    L[\"Ghoul\"] = \"Ghoul\"\n    L[\"Spider\"] = \"Spider\"\n    L[\"Crab\"] = \"Crab\"\n    L[\"Wolf\"] = \"Wolf\"\n    L[\"Worm\"] = \"Worm\"   \n    L[\"Chimaera\"] = \"Chimaera\"\n    L[\"Gorilla\"] = \"Gorilla\"\n    L[\"Turtle\"] = \"Turtle\"\n    L[\"Spirit Beast\"] = \"Spirit Beast\"\n    L[\"Core Hound\"] = \"Core Hound\"\n    L[\"Bat\"] = \"Bat\"\n    L[\"Ravager\"] = \"Ravager\"\nend\n-- pet ability table (API return only localization)\nPartyCooldownTracker.pets = {\n    [L[\"Felhunter\"]] = {\n        [19647] = {[\"cd\"] = 24},\n        [48011] = {[\"cd\"] = 8},\n        [54053] = {[\"cd\"] = 6},\n    },\n    [L[\"Voidwalker\"]] = {\n        [47986] = {[\"cd\"] = 60},\n        [47990] = {[\"cd\"] = 120},\n    },\n    [L[\"Ghoul\"]] = {\n        [47482] = {[\"cd\"] = 20},\n        [47481] = {[\"cd\"] = 60},\n        [47484] = {[\"cd\"] = 45},\n    },\n    [L[\"Spider\"]] =  {\n        [4167] = {[\"cd\"] = 40},\n    },\n    [L[\"Crab\"]] = { \n        [53548] = {[\"cd\"] = 40},\n        [53480] = {[\"cd\"] = 60},\n    },\n    [L[\"Gorilla\"]] = { \n        [26090] = {[\"cd\"] = 30},\n        [53480] = {[\"cd\"] = 60},\n    },\n    [L[\"Turtle\"]] = {\n        [26064] = {[\"cd\"] = 60},\n        [53480] = {[\"cd\"] = 60},\n    },\n    [L[\"Turtle\"]] = {\n        [55754] = {[\"cd\"] = 10}, \n        [53480] = {[\"cd\"] = 60},\n    },\n    [L[\"Wolf\"]] = {\n        [64495] = {[\"cd\"] = 40}\n    },\n    [L[\"Chimaera\"]] = {\n        [55492] = {[\"cd\"] = 10},\n    },\n    [L[\"Spirit Beast\"]] = {\n        [61198] = {[\"cd\"] = 10},\n    },\n    [L[\"Core Hound\"]] = {\n        [58611] = {[\"cd\"] = 10},\n    },\n    [L[\"Bat\"]] = {\n        [53568] = {[\"cd\"] = 60}, \n    },\n    [L[\"Ravager\"]] = {\n        [53561] = {[\"cd\"] = 40},\n        [53480] = {[\"cd\"] = 60},\n    },\n};\n\nfor _, classData in pairs(config.cds) do\n    if ( classData.pet ) then\n        for spellID, enable in pairs(classData.pet) do\n            spellID = tonumber(spellID);\n            for type, data in pairs(PartyCooldownTracker.pets) do\n                for spellId in pairs(data) do\n                    if ( spellId == spellID ) then\n                        PartyCooldownTracker.pets[type][spellID].display = enable;\n                    end\n                end\n            end\n        end\n    end\nend\n--------------------------------------------------------------------------------------------------------\n-- blacklist for CLUE:SPELL_CAST_SUCCESS\nPartyCooldownTracker.blacklist = {\n    [57934] = true, -- Маленькие хитрости\n    [34477] = true, -- Перенаправление\n    [14751] = true, -- Внутреннее сосредоточение\n    [46584] = true, -- Воскрешение мертвых\n    [20216] = true, -- Божественное одобрение\n};",
					["do_custom"] = true,
				},
				["finish"] = {
					["do_glow"] = false,
					["hide_all_glows"] = false,
					["custom"] = "aura_env:scheduleUpdateEvent(\"INVISUS_COOLDOWNS\", 0.5, \"FRAME_UPDATE\")",
					["do_message"] = false,
					["do_custom"] = true,
				},
			},
			["useTooltip"] = false,
			["keepAspectRatio"] = false,
			["selfPoint"] = "CENTER",
			["Jixxy"] = {
				["roster"] = {
					["0x0A000000007FBAB6"] = {
						["trinkets"] = {
							[14] = {
								["itemName"] = "Bauble of True Blood",
								["itemID"] = 50354,
								["spellID"] = 71607,
							},
						},
						["race"] = "Human",
						["spells"] = {
							[33206] = {
								["dst"] = false,
								["cd"] = 144,
								["exp"] = 65579.63000000001,
							},
							[10890] = {
								["dst"] = false,
								["cd"] = 27,
								["exp"] = 65579.63100000001,
							},
							[34433] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 65851.33500000001,
							},
							[59752] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 65693.342,
							},
							[71607] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 65579.63100000001,
							},
							[6346] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 65689.32700000001,
							},
							[48173] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 65579.63100000001,
							},
							[10060] = {
								["dst"] = false,
								["cd"] = 96,
								["exp"] = 65633.046,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Tahikupirest",
						["class"] = "PRIEST",
						["pet"] = {
						},
						["unitID"] = "party1",
					},
				},
			},
			["desc"] = "Author: RomanSpector\nDiscord: https://discord.com/invite/Fm9kgfk\n\nLibGroupTalents-1.0, LibTalentQuery-1.0",
			["Specterx"] = {
				["roster"] = {
					["0x00000000018B9142"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["49576"] = {
								["dst"] = false,
								["cd"] = 35,
								["exp"] = 305593.703,
							},
							["47476"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 305593.718,
							},
							["48792"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 305593.671,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 305593.671,
							},
							["47528"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 305593.734,
							},
							["48707"] = {
								["dst"] = false,
								["cd"] = 45,
								["exp"] = 305593.625,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Jkhfgd",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "DEATHKNIGHT",
					},
				},
			},
			["Spectrolinex"] = {
				["roster"] = {
					["0x0000000001A5351F"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["6552"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 216768.312,
							},
							["5246"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 216768.312,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 216768.312,
							},
							["871"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 216768.312,
							},
							["46924"] = {
								["dst"] = false,
								["cd"] = 90,
								["exp"] = 216768.312,
							},
							["2565"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 216768.312,
							},
							["71607"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 216768.312,
							},
							["42292"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 216768.312,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Specterx",
						["trinkets"] = {
							[14] = {
								["itemName"] = "Подвеска истинной крови",
								["itemID"] = 50354,
								["spellID"] = 71607,
							},
							[13] = {
								["itemName"] = "Медальон Альянса",
								["itemID"] = 51377,
								["spellID"] = 42292,
							},
						},
						["pet"] = {
						},
						["class"] = "WARRIOR",
					},
				},
			},
			["load"] = {
				["use_size"] = false,
				["zoneId"] = "",
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["difficulty"] = {
				},
				["use_ingroup"] = false,
				["ingroup"] = {
					["multi"] = {
						["group"] = true,
						["raid"] = true,
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["use_never"] = false,
				["use_zoneId"] = false,
				["size"] = {
					["single"] = "arena",
					["multi"] = {
						["none"] = true,
						["arena"] = true,
					},
				},
			},
			["Kitaev"] = {
				["roster"] = {
					["0x0A00000000A76946"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["47860"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 91662.262,
							},
							["61290"] = {
								["dst"] = false,
								["cd"] = 15,
								["exp"] = 91662.264,
							},
							["48020"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 91662.262,
							},
							["18708"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 91662.26300000001,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 91662.262,
							},
							["54785"] = {
								["dst"] = false,
								["cd"] = 45,
								["exp"] = 91662.26300000001,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Nyvez",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "WARLOCK",
					},
				},
			},
			["Zves"] = {
				["roster"] = {
					["0x0A000000008E1376"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["11958"] = {
								["dst"] = false,
								["cd"] = 384,
								["exp"] = 5344.02,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 5064.419,
							},
							["43039"] = {
								["dst"] = false,
								["cd"] = 24,
								["exp"] = 4853.557,
							},
							["2139"] = {
								["dst"] = false,
								["cd"] = 24,
								["exp"] = 5032.881,
							},
							["45438"] = {
								["dst"] = false,
								["cd"] = 240,
								["exp"] = 5245.446,
							},
							["44572"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 4958.371,
							},
							["1953"] = {
								["dst"] = false,
								["cd"] = 15,
								["exp"] = 5008.435,
							},
							["12051"] = {
								["dst"] = false,
								["cd"] = 240,
								["exp"] = 5207.416,
							},
							["12472"] = {
								["dst"] = false,
								["cd"] = 144,
								["exp"] = 5146.982,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Sakaris",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "MAGE",
					},
				},
			},
			["regionType"] = "icon",
			["Zvh"] = {
				["roster"] = {
				},
			},
			["zoom"] = 0,
			["auto"] = true,
			["tocversion"] = 30300,
			["alpha"] = 1,
			["Spectorqx"] = {
				["roster"] = {
					["0x000000000031D9B1"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["6940"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 82585.359,
							},
							["642"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 82585.359,
							},
							["1044"] = {
								["dst"] = false,
								["cd"] = 25,
								["exp"] = 82585.359,
							},
							["10308"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 82585.359,
							},
							["54428"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 82585.359,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 82585.359,
							},
							["10278"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 82585.359,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Romansacra",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "PALADIN",
					},
				},
			},
			["displayIcon"] = "Interface\\Icons\\Spell_Shadow_Dispersion",
			["Smiwolfa"] = {
				["roster"] = {
					["0x07000000003351C5"] = {
						["unitID"] = "party2",
						["race"] = "Human",
						["spells"] = {
							["5246"] = {
								["dst"] = true,
								["cd"] = 120,
								["exp"] = 405747.836,
							},
							["23920"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 405561.221,
							},
							["46924"] = {
								["dst"] = true,
								["cd"] = 90,
								["exp"] = 405737.785,
							},
							["2565"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 405561.221,
							},
							["55694"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 405561.221,
							},
							["676"] = {
								["dst"] = true,
								["cd"] = 60,
								["exp"] = 405754.356,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 405561.22,
							},
							["72"] = {
								["dst"] = false,
								["cd"] = 12,
								["exp"] = 405561.22,
							},
							["1719"] = {
								["dst"] = true,
								["cd"] = 300,
								["exp"] = 405939.435,
							},
							["20230"] = {
								["dst"] = true,
								["cd"] = 300,
								["exp"] = 406000.617,
							},
							["871"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 405561.224,
							},
							["6552"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 405561.22,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Rexxyklex",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "WARRIOR",
					},
				},
			},
			["Zvs"] = {
				["roster"] = {
					["0x0A00000000AC15AD"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["46968"] = {
								["dst"] = false,
								["cd"] = 20,
								["exp"] = 13566.254,
							},
							["5246"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 13560.717,
							},
							["23920"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 13560.718,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 13560.717,
							},
							["2565"] = {
								["dst"] = false,
								["cd"] = 40,
								["exp"] = 13575.652,
							},
							["3411"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 13560.719,
							},
							["676"] = {
								["dst"] = false,
								["cd"] = 40,
								["exp"] = 13560.715,
							},
							["1719"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 13560.718,
							},
							["20230"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 13560.716,
							},
							["871"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 13560.717,
							},
							["12809"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 13564.621,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Suvadzhan",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "WARRIOR",
					},
				},
			},
			["wagoID"] = "vQqMPBg2Y",
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["Data"] = {
				["roster"] = {
					["0x000000000038D011"] = {
						["unitName"] = "Tessttz",
						["race"] = "Human",
						["spells"] = {
							["47860"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 533567.031,
							},
							["48020"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 533567.031,
							},
							["18708"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 533567.031,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 533567.031,
							},
							["17928"] = {
								["dst"] = false,
								["cd"] = 40,
								["exp"] = 533567.031,
							},
							["19647"] = {
								["dst"] = false,
								["cd"] = 24,
								["exp"] = 533567.031,
							},
						},
						["faction"] = "Alliance",
						["unitID"] = "party1",
						["trinkets"] = {
						},
						["frame"] = "PartyMemberFrame1",
						["class"] = "WARLOCK",
					},
				},
			},
			["cooldownEdge"] = true,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "custom",
						["subeventSuffix"] = "_CAST_START",
						["customVariables"] = "{\n    expirationTime = true,\n    duration = true,\n    isBuff = {\n        display = \"buff\",\n        type = \"bool\",\n    },\n    isCD = {\n        display = \"cd\",    \n        type = \"bool\"    \n    }\n}",
						["event"] = "Health",
						["unit"] = "player",
						["subeventPrefix"] = "SPELL",
						["spellIds"] = {
						},
						["events"] = "INVISUS_COOLDOWNS RAID_ROSTER_UPDATE PARTY_MEMBERS_CHANGED WA_PARTY_MEMBERS_UPDATE CLEU:SPELL_CAST_SUCCESS:SPELL_AURA_REMOVED:SPELL_AURA_APPLIED:SPELL_RESURRECT:UNIT_DIED UNIT_SPELLCAST_SUCCEEDED UNIT_PET ZONE_CHANGED_NEW_AREA UNIT_IS_VISIBLE WA_INSPECT_READY UNIT_INVENTORY_CHANGED UNIT_FACTION UNIT_NAME_UPDATE PLAYER_LOGOUT WA_INIT ",
						["names"] = {
						},
						["check"] = "event",
						["custom"] = "function(allstates, event, ...)\n    \n    local self, WeakAuras = aura_env, WeakAuras;\n    \n    if ( event == \"OPTIONS\" ) then\n        \n        if ( WeakAuras.IsOptionsOpen() and self.loadedSession ) then\n            self.loadedSession = false;\n            self:SaveCurrentSession();\n        end\n        \n        self:InitNewMembers(allstates);\n        self:LoadLastSession();\n        self:CreateFrames(allstates);\n        self:scheduleUpdateFrames(allstates, 0.5);\n        \n    elseif ( event == \"WA_INIT\" ) then\n        self.loadedSession = true;\n        WeakAuras.ScanEvents(\"INVISUS_COOLDOWNS\", \"CD_UPDATE\");\n    elseif ( self.loadedSession ) then\n        if ( event == \"RAID_ROSTER_UPDATE\" or event == \"PARTY_MEMBERS_CHANGED\" ) then\n            if ( UnitInRaid(\"player\") and event == \"PARTY_MEMBERS_CHANGED\" ) then \n                return;\n            end\n            \n            WeakAuras.timer:ScheduleTimer(WeakAuras.ScanEvents, 1, \"WA_PARTY_MEMBERS_UPDATE\");\n        elseif ( event == \"WA_PARTY_MEMBERS_UPDATE\" ) then\n            return self:InitNewMembers(allstates);\n            \n        elseif ( event == \"INVISUS_COOLDOWNS\" ) then\n            local subEvent = ...;\n            \n            if ( subEvent == \"CD_UPDATE\" ) then\n                self:InitNewMembers(allstates);\n                self:LoadLastSession();\n                self:CreateFrames(allstates);\n                return true;\n            elseif ( subEvent == \"LibGroupTalents_Update\" ) then\n                local unit, unitName = select(2, ...)\n                local guid = UnitGUID(unit)\n                if ( unit and unitName and self.roster[guid] ) then\n                    self:UnitIsDetected(unit, guid);\n                    return self:CheckTalents(allstates, unit, guid);\n                end\n            elseif ( subEvent == \"FRAME_UPDATE\" ) then\n                self:scheduleUpdateFrames(allstates, 0.5);\n            end\n            \n        elseif ( event == \"WA_INSPECT_READY\" and ... ) then\n            local unit, guid, nilcheck = ...;\n            \n            if ( not nilcheck and CanInspect(unit, true) ) then\n                return NotifyInspect(unit), self:UnitIsDetected(unit, guid, true);\n            elseif ( nilcheck ) then\n                return self:UnitItemInit(allstates, unit, guid);\n            else\n                self:UnitIsDetected(unit, guid);\n            end\n            \n        elseif ( event == \"UNIT_INVENTORY_CHANGED\" and ... ) then\n            local unit = ...;\n            local guid = UnitGUID(unit);\n            return self.roster[guid] and self:UnitIsDetected(unit, guid);\n            \n        elseif ( event == \"UNIT_IS_VISIBLE\" and ... ) then\n            return self.UnitPetCDInit(allstates, ...)\n            \n        elseif ( event == \"ZONE_CHANGED_NEW_AREA\" ) then\n            return self:Update(allstates)\n            \n        elseif event == \"UNIT_PET\" and ... then\n            local unit = ...;\n            local guid = UnitGUID(unit);\n            local petGUID = self.GetPetGUID(unit);\n            \n            if ( not petGUID and unit ~= \"target\" and not (unit):match(\"raid\") ) then\n                return self:PetCooldownRemove(allstates, guid);\n            else\n                return self:UnitPetCDInit(allstates, unit);\n            end\n            \n        elseif ( event == \"UNIT_FACTION\" or event == \"UNIT_NAME_UPDATE\" ) and ... then\n            local unit = ...;\n            local guid = UnitGUID(unit);\n            if ( unit and (unit):match(\"partypet\") ) then\n                return self:PetCooldownRemove(allstates, guid);\n            end\n            \n        elseif ( event == \"COMBAT_LOG_EVENT_UNFILTERED\" and ... ) then\n            local _, subEvent, sourceGUID, _, _, destGUID, _, _, spellID, spellName, _, type = ...;\n            if ( self:SpellIsDisplay(sourceGUID, spellID) ) then\n                local GUID =self:SpellIsDisplay(sourceGUID, spellID);\n                if ( subEvent == \"SPELL_RESURRECT\" or subEvent == \"SPELL_CAST_SUCCESS\" ) \n                and not self.blacklist[spellID] then\n                    return self:EditState( allstates, GUID, spellID, subEvent, destGUID);\n                elseif ( subEvent == \"SPELL_AURA_REMOVED\" ) then\n                    return self:SetDesaturated(allstates, GUID, spellID);\n                elseif ( subEvent == \"SPELL_AURA_APPLIED\" and type == \"BUFF\" ) then \n                    local duration = select(6, UnitAura(self.roster[GUID].unitID, spellName));\n                    return self:SetGlow(allstates, GUID, spellID, duration);\n                end\n                \n            elseif ( subEvent == \"UNIT_DIED\" and self.pet_roster[destGUID] ) then \n                if ( self.pet_roster[destGUID].type == \"Вурдалак\" \n                    or self.pet_roster[destGUID].type == \"Ghoul\" ) then\n                    return self:EditState(allstates, self.pet_roster[destGUID].unitGUID, 46584, subEvent);\n                end\n                \n            elseif ( self.roster[sourceGUID] ) then\n                return self:AdditionalVerification(allstates, subEvent, sourceGUID, spellID, destGUID);\n            end\n            \n        elseif ( event == \"UNIT_SPELLCAST_SUCCEEDED\" and ... ) then\n            local srcUnit, spellName = ...;\n            local guid = UnitGUID(srcUnit);\n            \n            if ( self:SpellIsDisplay(guid, nil, spellName) ) then \n                local spellID = self.USS[spellName].id;\n                if ( self.roster[guid].spells[spellID] ) then\n                    return self:EditState(allstates, guid, spellID, event);\n                end\n            end\n            \n        elseif ( event == \"PLAYER_LOGOUT\" ) then\n            self:SaveCurrentSession();\n            self:scheduleUpdateFrames(allstates, 0.5);\n        end\n    end\nend",
						["custom_type"] = "stateupdate",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				["disjunctive"] = "any",
				["customTriggerLogic"] = "function(trigger)\n    return trigger[1]\nend",
				["activeTriggerMode"] = 1,
			},
			["Apocalypsez"] = {
				["roster"] = {
					["0x00000000003AEFC6"] = {
						["unitID"] = "party2",
						["race"] = "Human",
						["spells"] = {
							["10890"] = {
								["dst"] = false,
								["cd"] = 27,
								["exp"] = 221933.203,
							},
							["6346"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 221839.078,
							},
							["48173"] = {
								["dst"] = true,
								["cd"] = 120,
								["exp"] = 222031.609,
							},
							["34433"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 221839.078,
							},
							["59752"] = {
								["dst"] = true,
								["cd"] = 120,
								["exp"] = 222030.89,
							},
							["64843"] = {
								["dst"] = false,
								["cd"] = 480,
								["exp"] = 221839.078,
							},
							["33206"] = {
								["dst"] = true,
								["cd"] = 144,
								["exp"] = 222053.093,
							},
							["10060"] = {
								["dst"] = false,
								["cd"] = 96,
								["exp"] = 221839.625,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Gardeqt",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "PRIEST",
					},
				},
			},
			["internalVersion"] = 44,
			["Zvk"] = {
				["roster"] = {
				},
			},
			["animation"] = {
				["start"] = {
					["colorR"] = 1,
					["scalex"] = 1,
					["alphaType"] = "straight",
					["colorA"] = 1,
					["colorG"] = 1,
					["alphaFunc"] = "    function(progress, start, delta)\n      return start + (progress * delta)\n    end\n  ",
					["use_translate"] = true,
					["use_alpha"] = false,
					["type"] = "none",
					["easeType"] = "none",
					["translateFunc"] = "    function(progress, startX, startY, deltaX, deltaY)\n      return startX + (progress * deltaX), startY + (progress * deltaY)\n    end\n  ",
					["scaley"] = 1,
					["alpha"] = 0,
					["y"] = 0,
					["x"] = 45,
					["colorB"] = 1,
					["duration"] = "0.3",
					["easeStrength"] = 3,
					["rotate"] = 0,
					["translateType"] = "straightTranslate",
					["duration_type"] = "seconds",
				},
				["main"] = {
					["colorR"] = 1,
					["duration"] = "",
					["alphaType"] = "custom",
					["colorB"] = 1,
					["colorG"] = 1,
					["alphaFunc"] = "function(progress, start, delta)\n    \n    return start + (progress * delta)\nend",
					["use_translate"] = false,
					["use_alpha"] = false,
					["colorA"] = 1,
					["type"] = "custom",
					["scalex"] = 1,
					["easeType"] = "none",
					["translateFunc"] = "function(progress, startX, startY, deltaX, deltaY)\n    return startX + (progress * deltaX), startY + (progress * deltaY)\nend",
					["scaley"] = 1,
					["alpha"] = 0,
					["easeStrength"] = 3,
					["y"] = 0,
					["x"] = 0,
					["translateType"] = "custom",
					["colorType"] = "custom",
					["colorFunc"] = "function(progress, r1, g1, b1, a1, r2, g2, b2, a2)\n    local state = aura_env.region.state\n    if ( aura_env.config.des and state ) then\n        aura_env.region.icon:SetDesaturated(state.dst) \n    end\n    return r1, g1, b1, a1\nend",
					["rotate"] = 0,
					["use_color"] = false,
					["duration_type"] = "seconds",
				},
				["finish"] = {
					["colorR"] = 1,
					["scalex"] = 1,
					["alphaType"] = "straight",
					["colorA"] = 1,
					["colorG"] = 1,
					["alphaFunc"] = "    function(progress, start, delta)\n      return start + (progress * delta)\n    end\n  ",
					["use_translate"] = true,
					["use_alpha"] = true,
					["type"] = "none",
					["easeType"] = "none",
					["translateFunc"] = "    function(progress, startX, startY, deltaX, deltaY)\n      return startX + (progress * deltaX), startY + (progress * deltaY)\n    end\n  ",
					["scaley"] = 1,
					["alpha"] = 0,
					["colorB"] = 1,
					["y"] = 0,
					["x"] = -45,
					["preset"] = "slideleft",
					["easeStrength"] = 3,
					["translateType"] = "straightTranslate",
					["rotate"] = 0,
					["duration_type"] = "seconds",
					["duration"] = "0.3",
				},
			},
			["Nuax"] = {
				["roster"] = {
				},
			},
			["Uyild"] = {
				["roster"] = {
					["0x00000000018B57FC"] = {
						["unitID"] = "party1",
						["race"] = "Scourge",
						["spells"] = {
							["45438"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 305803.109,
							},
							["12051"] = {
								["dst"] = false,
								["cd"] = 240,
								["exp"] = 305803.109,
							},
							["1953"] = {
								["dst"] = false,
								["cd"] = 15,
								["exp"] = 305803.125,
							},
							["2139"] = {
								["dst"] = false,
								["cd"] = 24,
								["exp"] = 305803.093,
							},
						},
						["faction"] = "Horde",
						["unitName"] = "Poopey",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "MAGE",
					},
				},
			},
			["version"] = 1,
			["subRegions"] = {
				{
					["glowFrequency"] = 0.25,
					["type"] = "subglow",
					["useGlowColor"] = true,
					["glowType"] = "ACShine",
					["glowLength"] = 10,
					["glowYOffset"] = 0,
					["glowColor"] = {
						1, -- [1]
						0.96470588235294, -- [2]
						0.5843137254902, -- [3]
						1, -- [4]
					},
					["glowXOffset"] = 0,
					["glowScale"] = 1.6,
					["glow"] = false,
					["glowThickness"] = 1,
					["glowLines"] = 5,
					["glowBorder"] = false,
				}, -- [1]
			},
			["height"] = 33,
			["Nvd"] = {
				["roster"] = {
					["0x0A00000000A76946"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["47860"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 99088.98,
							},
							["61290"] = {
								["dst"] = false,
								["cd"] = 15,
								["exp"] = 99088.981,
							},
							["48020"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 99088.978,
							},
							["18708"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 99088.98,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 99088.97900000001,
							},
							["54785"] = {
								["dst"] = false,
								["cd"] = 45,
								["exp"] = 99088.98,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Nyvez",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "WARLOCK",
					},
					["0x0A00000000AC2C0E"] = {
						["unitID"] = "party2",
						["race"] = "Human",
						["spells"] = {
							["49039"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 99088.97900000001,
							},
							["47476"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 99088.98,
							},
							["48792"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 99088.978,
							},
							["51052"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 99088.97900000001,
							},
							["48707"] = {
								["dst"] = false,
								["cd"] = 45,
								["exp"] = 99088.978,
							},
							["48743"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 99088.978,
							},
							["47481"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 99088.97900000001,
							},
							["49576"] = {
								["dst"] = false,
								["cd"] = 25,
								["exp"] = 99088.97900000001,
							},
							["49206"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 99088.98,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 99088.97900000001,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Zvdk",
						["trinkets"] = {
						},
						["pet"] = {
							["0xF14046459B00248A"] = {
								["type"] = "Ghoul",
								["spells"] = {
									["47481"] = {
										["cd"] = 60,
									},
								},
								["unitGUID"] = "0x0A00000000AC2C0E",
							},
						},
						["class"] = "DEATHKNIGHT",
					},
				},
			},
			["Zvm"] = {
				["roster"] = {
					["0x0700000000688DD4"] = {
						["unitID"] = "party1",
						["race"] = "NightElf",
						["spells"] = {
							["8983"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 39948.448,
							},
							["61384"] = {
								["dst"] = false,
								["cd"] = 20,
								["exp"] = 39954.49,
							},
							["42292"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 39955.534,
							},
							["22812"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 39948.447,
							},
							["53201"] = {
								["dst"] = false,
								["cd"] = 90,
								["exp"] = 39954.49,
							},
							["33831"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 39954.49,
							},
							["29166"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 39948.447,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Mesivo",
						["trinkets"] = {
							[14] = {
								["itemName"] = "Medallion of the Alliance",
								["itemID"] = 51377,
								["spellID"] = 42292,
							},
						},
						["pet"] = {
						},
						["class"] = "DRUID",
					},
				},
			},
			["Juxxy"] = {
				["roster"] = {
					["0x0D00000000017CC5"] = {
						["spells"] = {
							[31884] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 285270.136,
							},
							[6940] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 285270.137,
							},
							[1044] = {
								["dst"] = false,
								["cd"] = 25,
								["exp"] = 285270.136,
							},
							[642] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 285270.136,
							},
							[10308] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 285270.135,
							},
							[10278] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 285270.137,
							},
						},
						["race"] = "BloodElf",
						["trinkets"] = {
						},
						["faction"] = "Horde",
						["unitID"] = "party1",
						["class"] = "PALADIN",
						["pet"] = {
						},
						["unitName"] = "Sebalin",
					},
					["0x0D0000000002B4E8"] = {
						["spells"] = {
							[34433] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 285270.137,
							},
							[6346] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 285270.137,
							},
							[10890] = {
								["dst"] = false,
								["cd"] = 27,
								["exp"] = 285270.137,
							},
							[7744] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 285270.136,
							},
						},
						["race"] = "Scourge",
						["trinkets"] = {
						},
						["faction"] = "Horde",
						["unitID"] = "party2",
						["class"] = "PRIEST",
						["pet"] = {
						},
						["unitName"] = "Lkt",
					},
					["0x0D0000000002BC67"] = {
						["spells"] = {
							[19263] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 285270.136,
							},
							[13809] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 285270.135,
							},
							[3045] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 285270.136,
							},
							[14311] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 285270.137,
							},
							[53271] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 285270.136,
							},
						},
						["race"] = "Orc",
						["trinkets"] = {
						},
						["faction"] = "Horde",
						["unitID"] = "party4",
						["class"] = "HUNTER",
						["pet"] = {
						},
						["unitName"] = "Lovemypet",
					},
					["0x0D0000000001AF72"] = {
						["spells"] = {
							[31884] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 285270.135,
							},
							[6940] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 285270.136,
							},
							[1044] = {
								["dst"] = false,
								["cd"] = 25,
								["exp"] = 285270.136,
							},
							[642] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 285270.135,
							},
							[10278] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 285270.137,
							},
							[10308] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 285270.135,
							},
							[59752] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 285270.137,
							},
						},
						["race"] = "Human",
						["trinkets"] = {
						},
						["faction"] = "Alliance",
						["unitID"] = "party3",
						["class"] = "PALADIN",
						["pet"] = {
						},
						["unitName"] = "Passifikator",
					},
				},
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["anchorFrameFrame"] = "WeakAuras:PartyMember1Frame",
			["Zevlovex"] = {
				["roster"] = {
					["0x0A0000000061CDF3"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["45438"] = {
								["dst"] = false,
								["cd"] = 240,
								["exp"] = 46680.077,
							},
							["12051"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 46680.079,
							},
							["1953"] = {
								["dst"] = false,
								["cd"] = 15,
								["exp"] = 46680.076,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 46680.077,
							},
							["12472"] = {
								["dst"] = false,
								["cd"] = 144,
								["exp"] = 46680.076,
							},
							["12042"] = {
								["dst"] = false,
								["cd"] = 84,
								["exp"] = 46974.549,
							},
							["2139"] = {
								["dst"] = false,
								["cd"] = 24,
								["exp"] = 46680.078,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Zevlove",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "MAGE",
					},
				},
			},
			["conditions"] = {
				{
					["check"] = {
						["trigger"] = -2,
						["op"] = "",
						["variable"] = "AND",
						["checks"] = {
							{
								["trigger"] = 1,
								["variable"] = "isCD",
								["value"] = 1,
							}, -- [1]
							{
								["trigger"] = 1,
								["variable"] = "isBuff",
								["value"] = 0,
							}, -- [2]
						},
					},
					["changes"] = {
						{
							["value"] = 0.5,
							["property"] = "alpha",
						}, -- [1]
					},
				}, -- [1]
				{
					["check"] = {
						["trigger"] = 1,
						["variable"] = "isBuff",
						["value"] = 1,
					},
					["linked"] = false,
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.1.glow",
						}, -- [1]
					},
				}, -- [2]
				{
					["check"] = {
						["trigger"] = 1,
						["op"] = "<=",
						["variable"] = "expirationTime",
						["value"] = "0",
					},
					["linked"] = false,
					["changes"] = {
						{
							["value"] = {
								["custom"] = "aura_env.region.state.isCD = false\naura_env.region.state.dst = false\naura_env.region.state.isBuff = false\n\nlocal guid = aura_env.region.state.guid\nlocal spellID = aura_env.region.state.spellID\nlocal dst = aura_env.region.state.dst\nlocal exp = GetTime()\n\nif guid and spellID then\n    aura_env:AddInfo(guid, spellID, exp, dst)\nend\n\n\n",
							},
							["property"] = "customcode",
						}, -- [1]
						{
							["value"] = 1,
							["property"] = "alpha",
						}, -- [2]
					},
				}, -- [3]
			},
			["Zvd"] = {
				["roster"] = {
					["0x0A00000000AB5A24"] = {
						["unitID"] = "party2",
						["race"] = "Human",
						["spells"] = {
							["5246"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 30143.39,
							},
							["871"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 30143.39,
							},
							["46924"] = {
								["dst"] = false,
								["cd"] = 90,
								["exp"] = 30313.193,
							},
							["2565"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 30143.39,
							},
							["3411"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 30143.39,
							},
							["676"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 30143.39,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 30342.639,
							},
							["23920"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 30143.39,
							},
							["20230"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 30143.39,
							},
							["1719"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 30143.39,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Luko",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "WARRIOR",
					},
				},
			},
			["uid"] = "9)m2dZi1)ca",
			["Zvw"] = {
				["roster"] = {
					["0x0700000000620436"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["6940"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 129014.929,
							},
							["642"] = {
								["dst"] = false,
								["cd"] = 240,
								["exp"] = 128826.804,
							},
							["64205"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 128826.804,
							},
							["10308"] = {
								["dst"] = false,
								["cd"] = 40,
								["exp"] = 128941.499,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 129018.022,
							},
							["1044"] = {
								["dst"] = false,
								["cd"] = 25,
								["exp"] = 128826.804,
							},
							["31884"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 128826.806,
							},
							["10278"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 128826.803,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Sickstrilla",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "PALADIN",
					},
				},
			},
			["Fraken"] = {
				["roster"] = {
				},
			},
			["anchorFrameParent"] = true,
			["Poopey"] = {
				["roster"] = {
					["0x0000000000330110"] = {
						["unitID"] = "party1",
						["race"] = "Orc",
						["spells"] = {
							["53548"] = {
								["dst"] = false,
								["cd"] = 40,
								["exp"] = 307764.75,
							},
							["19503"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 307764.75,
							},
							["49012"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 307764.75,
							},
							["53480"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 307764.75,
							},
							["63672"] = {
								["dst"] = false,
								["cd"] = 24,
								["exp"] = 307764.75,
							},
							["14311"] = {
								["dst"] = false,
								["cd"] = 24,
								["exp"] = 307764.75,
							},
							["19263"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 307764.75,
							},
							["53271"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 307764.75,
							},
						},
						["faction"] = "Horde",
						["unitName"] = "Uyild",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "HUNTER",
					},
				},
			},
			["width"] = 33,
			["icon"] = true,
			["semver"] = "1.0.0",
			["Smiwolf"] = {
				["roster"] = {
					["0x0A000000007E2F3F"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["5246"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 6988.061,
							},
							["23920"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 6988.061,
							},
							["46924"] = {
								["dst"] = false,
								["cd"] = 90,
								["exp"] = 6989.424,
							},
							["2565"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 6988.061,
							},
							["55694"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 6988.061,
							},
							["676"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 6988.061,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 6988.061,
							},
							["72"] = {
								["dst"] = false,
								["cd"] = 12,
								["exp"] = 6988.061,
							},
							["1719"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 6988.061,
							},
							["20230"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 6988.061,
							},
							["871"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 6988.061,
							},
							["6552"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 6988.061,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Malvin",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "WARRIOR",
					},
					["0x0A000000009640A9"] = {
						["unitID"] = "party2",
						["race"] = "Human",
						["spells"] = {
							["64901"] = {
								["dst"] = false,
								["cd"] = 360,
								["exp"] = 7005.983,
							},
							["6346"] = {
								["dst"] = true,
								["cd"] = 180,
								["exp"] = 7228.808,
							},
							["10890"] = {
								["dst"] = true,
								["cd"] = 27,
								["exp"] = 7081.728,
							},
							["48158"] = {
								["dst"] = false,
								["cd"] = 12,
								["exp"] = 7005.989,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 7005.984,
							},
							["33206"] = {
								["dst"] = false,
								["cd"] = 144,
								["exp"] = 7005.987,
							},
							["10060"] = {
								["dst"] = false,
								["cd"] = 96,
								["exp"] = 7005.988,
							},
							["34433"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 7005.983,
							},
							["71607"] = {
								["dst"] = true,
								["cd"] = 120,
								["exp"] = 7176.595,
							},
							["64843"] = {
								["dst"] = false,
								["cd"] = 480,
								["exp"] = 7005.987,
							},
							["48173"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 7005.989,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Yumigidqx",
						["trinkets"] = {
							[14] = {
								["itemName"] = "Bauble of True Blood",
								["itemID"] = 50354,
								["spellID"] = 71607,
							},
						},
						["pet"] = {
						},
						["class"] = "PRIEST",
					},
				},
			},
			["id"] = "UI - PartyCooldownTracker",
			["desaturate"] = false,
			["frameStrata"] = 2,
			["anchorFrameType"] = "SCREEN",
			["Zevyn"] = {
				["roster"] = {
					["0x0A00000000AC2C0E"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["49039"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 40677.577,
							},
							["47476"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 40467.484,
							},
							["48792"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 40703.026,
							},
							["51052"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 40597.682,
							},
							["48707"] = {
								["dst"] = false,
								["cd"] = 45,
								["exp"] = 41101.372,
							},
							["48743"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 40467.482,
							},
							["49206"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 40467.483,
							},
							["49576"] = {
								["dst"] = false,
								["cd"] = 25,
								["exp"] = 40467.483,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 40593.454,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Zvdk",
						["trinkets"] = {
						},
						["pet"] = {
						},
						["class"] = "DEATHKNIGHT",
					},
				},
			},
			["authorOptions"] = {
				{
					["type"] = "description",
					["text"] = "|cff69ccf0Libraries are required for correct operation: \nLibGroupTalents-1.0, LibTalentQuery-1.0|r\n\nJoin in my Discord group|r https://discord.com/invite/Fm9kgfk",
					["fontSize"] = "large",
					["width"] = 2,
				}, -- [1]
				{
					["type"] = "space",
					["variableWidth"] = false,
					["height"] = 2,
					["width"] = 1,
					["useHeight"] = true,
				}, -- [2]
				{
					["type"] = "select",
					["values"] = {
						"BOTTOM", -- [1]
						"BOTTOMLEFT", -- [2]
						"BOTTOMRIGHT", -- [3]
						"CENTER", -- [4]
						"LEFT", -- [5]
						"RIGHT", -- [6]
						"TOP", -- [7]
						"TOPLEFT", -- [8]
						"TOPRIGHT", -- [9]
					},
					["default"] = 1,
					["key"] = "anchor",
					["useDesc"] = false,
					["name"] = "Anchor",
					["width"] = 1,
				}, -- [3]
				{
					["type"] = "select",
					["values"] = {
						"BOTTOM", -- [1]
						"BOTTOMELFT", -- [2]
						"BOTTOMRIGHT", -- [3]
						"CENTER", -- [4]
						"LEFT", -- [5]
						"RIGHT", -- [6]
						"TOP", -- [7]
						"TOPLEFT", -- [8]
						"TOPRIGHT", -- [9]
					},
					["default"] = 1,
					["key"] = "anchorTo",
					["useDesc"] = false,
					["name"] = "Anchored to",
					["width"] = 1,
				}, -- [4]
				{
					["type"] = "select",
					["values"] = {
						"Default", -- [1]
						"Vuhdo 1", -- [2]
						"Vuhdo 2", -- [3]
						"Vuhdo 3", -- [4]
						"Vuhdo 4", -- [5]
						"Vuhdo 5", -- [6]
						"Vuhdo", -- [7]
						"Heal Bot", -- [8]
						"Grid", -- [9]
						"Grid2", -- [10]
						"Plexus", -- [11]
						"ElvUI Raid", -- [12]
						"BDGrid", -- [13]
						"Generic oUF", -- [14]
						"Lime", -- [15]
						"SUF", -- [16]
						"Alea Party", -- [17]
						"SUF Party", -- [18]
						"ElvUI Party", -- [19]
						"Generic oUF Party", -- [20]
						"PitBull4 Party", -- [21]
						"XPerl Party", -- [22]
						"Blizzard Party", -- [23]
						"Compact Raid", -- [24]
					},
					["default"] = 1,
					["key"] = "frame",
					["useDesc"] = false,
					["name"] = "Frames",
					["width"] = 1,
				}, -- [5]
				{
					["type"] = "select",
					["values"] = {
						"Left, then down", -- [1]
						"Right, then down", -- [2]
						"Left, then up", -- [3]
						"Right, then up", -- [4]
					},
					["default"] = 1,
					["key"] = "direction",
					["useDesc"] = false,
					["name"] = "Direction",
					["width"] = 1,
				}, -- [6]
				{
					["type"] = "range",
					["useDesc"] = false,
					["max"] = 30,
					["step"] = 1,
					["width"] = 1,
					["min"] = 0,
					["key"] = "column",
					["name"] = "Number of columns",
					["default"] = 4,
				}, -- [7]
				{
					["type"] = "range",
					["useDesc"] = false,
					["max"] = 10,
					["step"] = 1,
					["width"] = 1,
					["min"] = 0,
					["key"] = "spacing",
					["name"] = "Spacing",
					["default"] = 3,
				}, -- [8]
				{
					["type"] = "range",
					["useDesc"] = false,
					["max"] = 100,
					["step"] = 1,
					["width"] = 1,
					["min"] = -100,
					["key"] = "xOffset",
					["name"] = "xOffset",
					["default"] = 0,
				}, -- [9]
				{
					["type"] = "range",
					["useDesc"] = false,
					["max"] = 100,
					["step"] = 1,
					["width"] = 1,
					["min"] = -100,
					["key"] = "yOffset",
					["name"] = "yOffset",
					["default"] = 0,
				}, -- [10]
				{
					["type"] = "header",
					["useName"] = false,
					["text"] = "",
					["noMerge"] = false,
					["width"] = 1,
				}, -- [11]
				{
					["type"] = "select",
					["values"] = {
						"party1", -- [1]
						"party1 - party2", -- [2]
						"party1 - party3", -- [3]
						"party1 - party4", -- [4]
					},
					["default"] = 4,
					["key"] = "countUnits",
					["useDesc"] = false,
					["name"] = "Number of tracked units",
					["width"] = 1,
				}, -- [12]
				{
					["type"] = "toggle",
					["key"] = "show",
					["desc"] = "Hide cooldown if not used",
					["default"] = false,
					["useDesc"] = true,
					["name"] = "Show only when is cooldown",
					["width"] = 1,
				}, -- [13]
				{
					["type"] = "toggle",
					["key"] = "glow",
					["default"] = true,
					["useDesc"] = false,
					["name"] = "Glow when buff is active",
					["width"] = 1,
				}, -- [14]
				{
					["type"] = "toggle",
					["key"] = "des",
					["default"] = true,
					["useDesc"] = false,
					["name"] = "Desaturated when is cooldown",
					["width"] = 1,
				}, -- [15]
				{
					["type"] = "header",
					["useName"] = false,
					["text"] = "Способности класса",
					["noMerge"] = true,
					["width"] = 1,
				}, -- [16]
				{
					["subOptions"] = {
						{
							["subOptions"] = {
								{
									["type"] = "toggle",
									["key"] = "33206",
									["desc"] = "Instantly reduces a friendly target's threat by 5%, reduces all damage taken by 40% and increases resistance to Dispel mechanics by 65% for 8 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_painsupression:20:20:0:0|t Pain Suppression",
									["width"] = 0.65,
								}, -- [1]
								{
									["type"] = "toggle",
									["key"] = "6346",
									["desc"] = "Wards the friendly target against Fear. The next Fear effect used against the target will fail, using up the ward. Lasts 3 min.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_excorcism:20:20:0:0|t Fear Ward",
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "10060",
									["desc"] = "Infuses the target with power, increasing spell casting speed by 20% and reducing the mana cost of all spells by 20%. Lasts 15 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_powerinfusion:20:20:0:0|t Power Infusion",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "64044",
									["desc"] = "You terrify the target, causing them to tremble in horror for 3 sec and drop their main hand and ranged weapons for 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_psychichorrors:20:20:0:0|t Psychic Horror",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "47585",
									["desc"] = "You disperse into pure Shadow energy, reducing all damage taken by 90%. You are unable to attack or cast spells, but you regenerate 6% mana every 1 sec for 6 sec. Dispersion can be cast while stunned, feared or silenced and clears all snare and movement impairing effects when cast, and makes you immune to them while dispersed.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_dispersion:20:20:0:0|t Dispersion",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "64901",
									["desc"] = "Restores 3% mana to 3 nearby low mana friendly party or raid targets every 2 sec for 8 sec, and increases their total maximum mana by 20% for 8 sec. Maximum of 12 mana restores. The Priest must channel to maintain the spell.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_symbolofhope:20:20:0:0|t Hymn of Hope",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "64843",
									["desc"] = "Heals 3 nearby lowest health friendly party or raid targets within 40 yards for 3024 to 3342 every 2 sec for 8 sec, and increases healing done to them by 10% for 8 sec. Maximum of 12 heals. The Priest must channel to maintain the spell.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_divinehymn:20:20:0:0|t Divine Hymn",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "10890",
									["desc"] = "The caster lets out a psychic scream, causing 5 enemies within 8 yards to flee for 8 sec. Damage caused may interrupt the effect.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_psychicscream:20:20:0:0|t Psychic Scream",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "15487",
									["desc"] = "Silences the target, preventing them from casting spells for 5 sec. Non-player victim spellcasting is also interrupted for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_impphaseshift:20:20:0:0|t Silence",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "34433",
									["desc"] = "Creates a shadowy fiend to attack the target. Caster receives 5% mana when the Shadowfiend attacks. Damage taken by area of effect attacks is reduced. Lasts 15 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_shadowfiend:20:20:0:0|t Shadowfiend",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "48173",
									["desc"] = "Instantly heals the caster for 3716 to 4384.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_restoration:20:20:0:0|t Desperate Prayer",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "14751",
									["desc"] = "When activated, reduces the mana cost of your next spell by 100% and increases its critical effect chance by 25% if it is capable of a critical effect.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_windwalkon:20:20:0:0|t Inner Focus",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "48158",
									["desc"] = "A word of dark binding that inflicts 750 to 870 Shadow damage to the target. If the target is not killed by Shadow Word: Death, the caster takes damage equal to the damage inflicted upon the target.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Shadow_DemonicFortitude:20:20:0:0|t Shadow Word: Death",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "53007",
									["desc"] = "Launches a volley of holy light at the target, causing 375 Holy damage to an enemy, or 1484 to 1676 healing to an ally instantly and every 1 sec for 2 sec.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Holy_Penance:20:20:0:0|t Penance",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "47788",
									["desc"] = "Calls upon a guardian spirit to watch over the friendly target. The spirit increases the healing received by the target by 40%, and also prevents the target from dying by sacrificing itself. This sacrifice terminates the effect but heals the target of 50% of their maximum health. Lasts 10 sec.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Holy_GuardianSpirit:20:20:0:0|t Guardian Spirit",
									["width"] = 0.65,
								}, -- [15]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:128:192:64:128|t |cfff0ebe0Priest",
							["key"] = "PRIEST",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [1]
						{
							["subOptions"] = {
								{
									["type"] = "toggle",
									["key"] = "2094",
									["desc"] = "Blinds the target, causing it to wander disoriented for up to 10 sec. Any damage caused will remove the effect.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_mindsteal:20:20:0:0|t Blind",
									["width"] = 0.65,
								}, -- [1]
								{
									["type"] = "toggle",
									["key"] = "26889",
									["desc"] = "Allows the rogue to vanish from sight, entering an improved stealth mode for 10 sec. Also breaks movement impairing effects. More effective than Vanish (Rank 2).",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_vanish:20:20:0:0|t Vanish",
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "31224",
									["desc"] = "Instantly removes all existing harmful spell effects and increases your chance to resist all spells by 90% for 5 sec. Does not remove effects that prevent you from using Cloak of Shadows.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_nethercloak:20:20:0:0|t Cloak of Shadows",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "51722",
									["desc"] = "Disarm the enemy, removing all weapons, shield or other equipment carried for 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_dismantle:20:20:0:0|t Dismantle",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "11305",
									["desc"] = "Increases the rogue's movement speed by 70% for 15 sec. Does not break stealth.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_sprint:20:20:0:0|t Sprint",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "1766",
									["desc"] = "A quick kick that interrupts spellcasting and prevents any spell in that school from being cast for 5 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_kick:20:20:0:0|t Kick",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "1776",
									["desc"] = "Causes 1+0.21*AP damage, incapacitating the opponent for 4 sec, and turns off your attack. Target must be facing you. Any damage caused will revive the target. Awards 1 combo point.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_gouge:20:20:0:0|t Gouge",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "8643",
									["desc"] = "Finishing move that stuns the target. Lasts longer per combo point:1 point : 2 seconds2 points: 3 seconds3 points: 4 seconds4 points: 5 seconds5 points: 6 seconds",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_kidneyshot:20:20:0:0|t Kidney Shot",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "57934",
									["desc"] = "The current party or raid member becomes the target of your Tricks of the Trade. The threat caused by your next damaging attack and all actions taken for 6 sec afterwards will be transferred to the target. In addition, all damage caused by the target is increased by 15% during this time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_tricksofthetrade:20:20:0:0|t Tricks of the Trade",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "26669",
									["desc"] = "Increases the rogue's dodge chance by 50% and reduces the chance ranged attacks hit the rogue by 25%. Lasts 15 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_shadowward:20:20:0:0|t Evasion",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "14185",
									["desc"] = "When activated, this ability immediately finishes the cooldown on your Evasion, Sprint, Vanish, Cold Blood and Shadowstep abilities.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_antishadow:20:20:0:0|t Preparation",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "36554",
									["desc"] = "Attempts to step through the shadows and reappear behind your enemy and increases movement speed by 70% for 3 sec. The damage of your next ability is increased by 20% and the threat caused is reduced by 50%. Lasts 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_shadowstep:20:20:0:0|t Shadowstep",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "51713",
									["desc"] = "Enter the Shadow Dance for 6 sec, allowing the use of Sap, Garrote, Ambush, Cheap Shot, Premeditation, Pickpocket and Disarm Trap regardless of being stealthed.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_shadowdance:20:20:0:0|t Shadow Dance",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "51690",
									["desc"] = "Step through the shadows from enemy to enemy within 10 yards, attacking an enemy every .5 secs with both weapons until 5 assaults are made, and increasing all damage done by 20% for the duration. Can hit the same target multiple times. Cannot hit invisible or stealthed targets.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_murderspree:20:20:0:0|t Killing Spree",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "14177",
									["desc"] = "When activated, increases the critical strike chance of your next offensive ability by 100%.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_ice_lament:20:20:0:0|t Cold Blood",
									["width"] = 0.65,
								}, -- [15]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:128:196:0:64|t |cfffff468Rogue",
							["key"] = "ROGUE",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [2]
						{
							["subOptions"] = {
								{
									["type"] = "toggle",
									["key"] = "22812",
									["desc"] = "The druid's skin becomes as tough as bark. All damage taken is reduced by 20%. While protected, damaging attacks will not cause spellcasting delays. This spell is usable while stunned, frozen, incapacitated, feared or asleep. Usable in all forms. Lasts 12 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_stoneclawtotem:20:20:0:0|t Barkskin",
									["width"] = 0.65,
								}, -- [1]
								{
									["type"] = "toggle",
									["key"] = "53201",
									["desc"] = "You summon a flurry of stars from the sky on all targets within 30 yards of the caster, each dealing 563 to 653 Arcane damage. Also causes 101 Arcane damage to all other enemies within 5 yards of the enemy target. Maximum 20 stars. Lasts 10 sec. Shapeshifting into an animal form or mounting cancels the effect. Any effect which causes you to lose control of your character will suppress the starfall effect.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_druid_starfall:20:20:0:0|t Starfall",
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "29166",
									["desc"] = "Causes the target to regenerate mana equal to 225% of the casting Druid's base mana pool over 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_lightning:20:20:0:0|t Innervate",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "61384",
									["desc"] = "You summon a violent Typhoon that does 1190 Nature damage when in contact with hostile targets, knocking them back and dazing them for 6 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_druid_typhoon:20:20:0:0|t Typhoon",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "48477",
									["desc"] = "Returns the spirit to the body, restoring a dead target to life with 6400 health and 4700 mana.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_reincarnation:20:20:0:0|t Rebirth",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "33357",
									["desc"] = "Increases movement speed by 70% while in Cat Form for 15 sec. Does not break prowling.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_druid_dash:20:20:0:0|t Dash",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "8983",
									["desc"] = "Stuns the target for 4 sec and interrupts non-player spellcasting for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_druid_bash:20:20:0:0|t Bash",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "49377",
									["desc"] = "Teaches Feral Charge (Bear) and Feral Charge (Cat).Feral Charge (Bear) - Causes you to charge an enemy, immobilizing and interrupting any spell being cast for 4 sec. This ability can be used in Bear Form and Dire Bear Form. 15 second cooldown.Feral Charge (Cat) - Causes you to leap behind an enemy, dazing them for 3 sec. 30 second cooldown.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_pet_bear:20:20:0:0|t Feral Charge - Bear",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "50334",
									["desc"] = "When activated, this ability causes your Mangle (Bear) ability to hit up to 3 targets and have no cooldown, and reduces the energy cost of all your Cat Form abilities by 50%. Lasts 15 sec. You cannot use Tiger's Fury while Berserk is active.Clears the effect of Fear and makes you immune to Fear for the duration.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_druid_berserk:20:20:0:0|t Berserk",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "17116",
									["desc"] = "When activated, your next Nature spell with a base casting time less than 10 sec. becomes an instant cast spell.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_ravenform:20:20:0:0|t Nature's Swiftness",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "18562",
									["desc"] = "Consumes a Rejuvenation or Regrowth effect on a friendly target to instantly heal them an amount equal to 12 sec. of Rejuvenation or 18 sec. of Regrowth.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\inv_relics_idolofrejuvenation:20:20:0:0|t Swiftmend",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "48438",
									["desc"] = "Heals up to 5 friendly party or raid members within 15 yards of the target for 686 over 7 sec. The amount healed is applied quickly at first, and slows down as the Wild Growth reaches its full duration.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_druid_flourish:20:20:0:0|t Wild Growth",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "33831",
									["desc"] = "Summons 3 treants to attack enemy targets for 30 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_druid_forceofnature:20:20:0:0|t Force of Nature",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "61336",
									["desc"] = "When activated, this ability temporarily grants you 30% of your maximum health for 20 sec while in Bear Form, Cat Form, or Dire Bear Form. After the effect expires, the health is lost.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Ability_Druid_TigersRoar:20:20:0:0|t Survival Instincts",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "22842",
									["desc"] = "Converts up to 10 rage per second into health for 10 sec. Each point of rage is converted into 0.3% of max health.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Ability_BullRush:20:20:0:0|t Frenzied Regeneration",
									["width"] = 0.65,
								}, -- [15]
								{
									["type"] = "toggle",
									["key"] = "48447",
									["desc"] = "Heals all nearby group members for 3035 every 2 seconds for 8 sec. Druid must channel to maintain the spell.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Nature_Tranquility:20:20:0:0|t Tranquility",
									["width"] = 0.65,
								}, -- [16]
								{
									["type"] = "toggle",
									["key"] = "49376",
									["desc"] = "Causes you to leap behind an enemy, dazing them for 3 sec.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_druid_feralchargecat:20:20:0:0|t Feral Charge - Cat",
									["width"] = 0.65,
								}, -- [17]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:196:256:0:64|t |cffff7c0aDruid",
							["key"] = "DRUID",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [3]
						{
							["subOptions"] = {
								{
									["subOptions"] = {
										{
											["type"] = "toggle",
											["key"] = "4167",
											["desc"] = "Encases the target in sticky webs, preventing movement for 4 sec.",
											["default"] = true,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Nature_Web:20:20:0:0|t Web",
											["width"] = 1,
										}, -- [1]
										{
											["type"] = "toggle",
											["key"] = "53548",
											["desc"] = "Pins the target in place, and squeezes for 112 to 144 damage over 4 sec.",
											["default"] = true,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\INV_Jewelcrafting_TruesilverCrab:20:20:0:0|t Pin",
											["width"] = 1,
										}, -- [2]
										{
											["type"] = "toggle",
											["key"] = "53561",
											["desc"] = "Violently attacks an enemy for 50 to 70, stunning it for 2 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Ability_Druid_PrimalTenacity:20:20:0:0|t Ravage",
											["width"] = 1,
										}, -- [3]
										{
											["type"] = "toggle",
											["key"] = "53568",
											["desc"] = "Emits a piercing shriek, inflicting 62 to 88 Nature damage and stunning the target for 2 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Ability_Hunter_Pet_Bat:20:20:0:0|t Sonic Blast",
											["width"] = 1,
										}, -- [4]
										{
											["type"] = "toggle",
											["key"] = "58611",
											["desc"] = "Your pet breathes a double gout of molten lava at the target for 128 to 172 Fire damage and reduces the target's casting speed by 25% for 10 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Fire_WindsofWoe:20:20:0:0|t Lava Breath",
											["width"] = 1,
										}, -- [5]
										{
											["type"] = "toggle",
											["key"] = "61198",
											["desc"] = "Burns the enemy for 49 to 65 Arcane damage and then an additional 49 to 65 after 6 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Nature_StarFall:20:20:0:0|t Spirit Strike",
											["width"] = 1,
										}, -- [6]
										{
											["type"] = "toggle",
											["key"] = "26064",
											["desc"] = "The turtle partially withdraws into its shell, reducing damage taken by 50% for 12 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Ability_Hunter_Pet_Turtle:20:20:0:0|t Shell Shield",
											["width"] = 1,
										}, -- [7]
										{
											["type"] = "toggle",
											["key"] = "26090",
											["desc"] = "Pummel the target, interrupting spellcasting and preventing any spell in that school from being cast for 2 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Ability_Hunter_Pet_Gorilla:20:20:0:0|t Pummel",
											["width"] = 1,
										}, -- [8]
										{
											["type"] = "toggle",
											["key"] = "55492",
											["desc"] = "Your pet simultaneously breathes frost and lightning at an enemy target, inflicting 128 to 172 Frost and Nature damage and slowing the target for 5 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Nature_Lightning:20:20:0:0|t Froststorm Breath",
											["width"] = 1,
										}, -- [9]
										{
											["type"] = "toggle",
											["key"] = "55754",
											["desc"] = "Your worm spits acid at an enemy, causing 124 to 176 Nature damage and reducing its armor by 10% per Acid Spit for 30 sec. Can be applied up to 2 times.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Nature_Acid_01:20:20:0:0|t Acid Spit",
											["width"] = 1,
										}, -- [10]
										{
											["type"] = "toggle",
											["key"] = "64495",
											["desc"] = "Increases melee and ranged attack power by 320 for the wolf and its master for 20 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Ability_Hunter_Pet_Wolf:20:20:0:0|t Furious Howl",
											["width"] = 1,
										}, -- [11]
										{
											["type"] = "toggle",
											["key"] = "53480",
											["desc"] = "Protects a friendly target from critical strikes, making attacks against that target unable to be critical strikes, but 20% of all damage taken by that target is also taken by the pet. Lasts 12 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Ability_Druid_DemoralizingRoar:20:20:0:0|t Roar of Sacrifice",
											["width"] = 1,
										}, -- [12]
									},
									["hideReorder"] = true,
									["useDesc"] = false,
									["nameSource"] = 0,
									["width"] = 1,
									["useCollapse"] = true,
									["collapse"] = false,
									["name"] = "Pet abilities",
									["key"] = "pet",
									["limitType"] = "none",
									["groupType"] = "simple",
									["type"] = "group",
									["size"] = 10,
								}, -- [1]
								{
									["type"] = "header",
									["useName"] = false,
									["text"] = "",
									["noMerge"] = false,
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "3045",
									["desc"] = "Increases ranged attack speed by 40% for 15 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_runningshot:20:20:0:0|t Rapid Fire",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "19263",
									["desc"] = "When activated, increases parry chance by 100%, reduces the chance ranged attacks will hit you by 100% and grants a 100% chance to deflect spells. While Deterrence is active, you cannot attack. Lasts 5 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_whirlwind:20:20:0:0|t Deterrence",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "23989",
									["desc"] = "When activated, this ability immediately finishes the cooldown on your other Hunter abilities except Bestial Wrath.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_readiness:20:20:0:0|t Readiness",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "5384",
									["desc"] = "Feign death which may trick enemies into ignoring you. Lasts up to 6 min.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_feigndeath:20:20:0:0|t Feign Death",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "781",
									["desc"] = "You attempt to disengage from combat, leaping backwards. Can only be used while in combat.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_feint:20:20:0:0|t Disengage",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "19503",
									["desc"] = "A short-range shot that deals 50% weapon damage and disorients the target for 4 sec. Any damage caused will remove the effect. Turns off your attack when used.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_golemstormbolt:20:20:0:0|t Scatter Shot",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "34490",
									["desc"] = "A shot that deals 50% weapon damage and Silences the target for 3 sec. Non-player victim spellcasting is also interrupted for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_theblackarrow:20:20:0:0|t Silencing Shot",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "1543",
									["desc"] = "Exposes all hidden and invisible enemies within 10 yards of the targeted area for 20 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_fire_flare:20:20:0:0|t Flare",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "34600",
									["desc"] = "Place a trap that will release several venomous snakes to attack the first enemy to approach. The snakes will die after 15 sec. Trap will exist for 30 sec. Only one trap can be active at a time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_snaketrap:20:20:0:0|t Snake Trap",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "49067",
									["desc"] = "Place a fire trap that explodes when an enemy approaches, causing RAP*0.1+523 to RAP*0.1+671 Fire damage and burning all enemies for 90*10+RAP additional Fire damage over 20 sec to all within 10 yards. Trap will exist for 30 sec. Only one trap can be active at a time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_fire_selfdestruct:20:20:0:0|t Explosive Trap",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "49056",
									["desc"] = "Place a fire trap that will burn the first enemy to approach for (RAP*(2/100)+377)*5 Fire damage over 15 sec. Trap will exist for 30 sec. Only one trap can be active at a time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_fire_flameshock:20:20:0:0|t Immolation Trap",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "14311",
									["desc"] = "Place a frost trap that freezes the first enemy that approaches, preventing all action for up to 20 sec. Any damage caused will break the ice. Trap will exist for 30 sec. Only one trap can be active at a time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_chainsofice:20:20:0:0|t Freezing Trap",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "60192",
									["desc"] = "Fire a freezing arrow that places a Freezing Trap at the target location, freezing the first enemy that approaches, preventing all action for up to 20 sec. Any damage caused will break the ice. Trap will exist for 30 sec. Only one trap can be active at a time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_chillingbolt:20:20:0:0|t Freezing Arrow",
									["width"] = 0.65,
								}, -- [15]
								{
									["type"] = "toggle",
									["key"] = "13809",
									["desc"] = "Place a frost trap that creates an ice slick around itself for 30 sec when the first enemy approaches it. All enemies within 10 yards will be slowed by 50% while in the area of effect. Trap will exist for 30 sec. Only one trap can be active at a time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_freezingbreath:20:20:0:0|t Frost Trap",
									["width"] = 0.65,
								}, -- [16]
								{
									["type"] = "toggle",
									["key"] = "63672",
									["desc"] = "Fires a Black Arrow at the target, increasing all damage done by you to the target by 6% and dealing RAP*0.1+553*5 Shadow damage over 15 sec. Black Arrow shares a cooldown with Trap spells.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_painspike:20:20:0:0|t Black Arrow",
									["width"] = 0.65,
								}, -- [17]
								{
									["type"] = "toggle",
									["key"] = "49012",
									["desc"] = "A stinging shot that puts the target to sleep for 30 sec. Any damage will cancel the effect. When the target wakes up, the Sting causes 2460 Nature damage over 6 sec. Only one Sting per Hunter can be active on the target at a time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\inv_spear_02:20:20:0:0|t Wyvern Sting",
									["width"] = 0.65,
								}, -- [18]
								{
									["type"] = "toggle",
									["key"] = "53271",
									["desc"] = "Your pet attempts to remove all root and movement impairing effects from itself and its target, and causes your pet and its target to be immune to all such effects for 4 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_masterscall:20:20:0:0|t Master's Call",
									["width"] = 0.65,
								}, -- [19]
								{
									["type"] = "toggle",
									["key"] = "34477",
									["desc"] = "The current party or raid member targeted will receive the threat caused by your next damaging attack and all actions taken for 4 sec afterwards.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_misdirection:20:20:0:0|t Misdirection",
									["width"] = 0.65,
								}, -- [20]
								{
									["type"] = "toggle",
									["key"] = "49048",
									["desc"] = "Fires several missiles, hitting 3 targets for an additional 408 damage.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_upgrademoonglaive:20:20:0:0|t Multi-Shot",
									["width"] = 0.65,
								}, -- [21]
								{
									["type"] = "toggle",
									["key"] = "19577",
									["desc"] = "Command your pet to intimidate the target, causing a high amount of threat and stunning the target for 3 sec. Lasts 15 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_devour:20:20:0:0|t Intimidation",
									["width"] = 0.65,
								}, -- [22]
								{
									["type"] = "toggle",
									["key"] = "19574",
									["desc"] = "Send your pet into a rage causing 50% additional damage for 10 sec. While enraged, the beast does not feel pity or remorse or fear and it cannot be stopped unless killed.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_druid_ferociousbite:20:20:0:0|t Bestial Wrath",
									["width"] = 0.65,
								}, -- [23]
								{
									["type"] = "toggle",
									["key"] = "49050",
									["desc"] = "An aimed shot that increases ranged damage by 408 and reduces healing done to that target by 50%. Lasts 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\inv_spear_07:20:20:0:0|t Aimed Shot",
									["width"] = 0.65,
								}, -- [24]
								{
									["type"] = "toggle",
									["key"] = "53209",
									["desc"] = "You deal 125% weapon damage, refreshing the current Sting on your target and triggering an effect:Serpent Sting - Instantly deals 40% of the damage done by your Serpent Sting.Viper Sting - Instantly restores mana to you equal to 60% of the total amount drained by your Viper Sting.Scorpid Sting - Attempts to Disarm the target for 10 sec. This effect cannot occur more than once per 1 minute.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_chimerashot2:20:20:0:0|t Chimera Shot",
									["width"] = 0.65,
								}, -- [25]
								{
									["type"] = "toggle",
									["key"] = "61006",
									["desc"] = "You attempt to finish the wounded target off, firing a long range attack dealing 200% weapon damage plus RAP*0.40+325*2. Kill Shot can only be used on enemies that have 20% or less health.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_assassinate2:20:20:0:0|t Kill Shot",
									["width"] = 0.65,
								}, -- [26]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:0:64:64:128|t |cffaad372Hunter",
							["key"] = "HUNTER",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [4]
						{
							["subOptions"] = {
								{
									["type"] = "toggle",
									["key"] = "42917",
									["desc"] = "Blasts enemies near the caster for 365 to 415 Frost damage and freezes them in place for up to 8 sec. Damage caused may interrupt the effect.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_frostnova:20:20:0:0|t Frost Nova",
									["width"] = 0.65,
								}, -- [1]
								{
									["type"] = "toggle",
									["key"] = "45438",
									["desc"] = "You become encased in a block of ice, protecting you from all physical attacks and spells for 10 sec, but during that time you cannot attack, move or cast spells. Also causes Hypothermia, preventing you from recasting Ice Block for 30 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_frost:20:20:0:0|t Ice Block",
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "2139",
									["desc"] = "Counters the enemy's spellcast, preventing any spell from that school of magic from being cast for 8 sec. Generates a high amount of threat.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_iceshock:20:20:0:0|t Counterspell",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "55342",
									["desc"] = "Creates 3 copies of the caster nearby, which cast spells and attack the mage's enemies. Lasts 30 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_magic_lesserinvisibilty:20:20:0:0|t Mirror Image",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "66",
									["desc"] = "Fades the caster to invisibility over 3 sec, reducing threat each second. The effect is cancelled if you perform any actions. While invisible, you can only see other invisible targets and those who can see invisible. Lasts 20 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_mage_invisibility:20:20:0:0|t InvisibilityInvisibility",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "1953",
									["desc"] = "Teleports the caster 20 yards forward, unless something is in the way. Also frees the caster from stuns and bonds.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_arcane_blink:20:20:0:0|t Blink",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "12051",
									["desc"] = "While channeling this spell, you gain 60% of your total mana over 8 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_purge:20:20:0:0|t Evocation",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "12042",
									["desc"] = "When activated, your spells deal 20% more damage while costing 20% more mana to cast. This effect lasts 15 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_lightning:20:20:0:0|t Arcane Power",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "42945",
									["desc"] = "От заклинателя расходится волна пламени, нанося всем противникам в зоне действия 154 - 186 ед. урона от огня, сбивая их с ног и вызывая у них головокружение на 6 сек..",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_excorcism_02:20:20:0:0|t Blast Wave",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "42950",
									["desc"] = "Targets in a cone in front of the caster take 1101 to 1279 Fire damage and are Disoriented for 5 sec. Any direct damaging attack will revive targets. Turns off your attack when used.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\inv_misc_head_dragon_01:20:20:0:0|t Dragon's Breath",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "11958",
									["desc"] = "When activated, this spell finishes the cooldown on all Frost spells you recently cast.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_wizardmark:20:20:0:0|t Cold Snap",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "43039",
									["desc"] = "Instantly shields you, absorbing 3300 damage. Lasts 1 min. While the shield holds, spellcasting will not be delayed by damage.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_ice_lament:20:20:0:0|t Ice Barrier",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "31687",
									["desc"] = "Summon a Water Elemental to fight for the caster for 45 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_summonwaterelemental_2:20:20:0:0|t Summon Water Elemental",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "44572",
									["desc"] = "Stuns the target for 5 sec. Only usable on Frozen targets. Deals 1469 to 1741 damage to targets permanently immune to stuns.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_mage_deepfreeze:20:20:0:0|t Deep Freeze",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "12472",
									["desc"] = "Hastens your spellcasting, increasing spell casting speed by 20% and reduces the pushback suffered from damaging attacks while casting by 100%. Lasts 20 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_coldhearted:20:20:0:0|t Icy Veins",
									["width"] = 0.65,
								}, -- [15]
								{
									["type"] = "toggle",
									["key"] = "42931",
									["desc"] = "Targets in a cone in front of the caster take 707 to 773 Frost damage and are slowed by 50% for 8 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_glacier:20:20:0:0|t Cone of Cold",
									["width"] = 0.65,
								}, -- [16]
								{
									["type"] = "toggle",
									["key"] = "12043",
									["desc"] = "When activated, your next Mage spell with a casting time less than 10 sec becomes an instant cast spell.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_enchantarmor:20:20:0:0|t Presence of Mind",
									["width"] = 0.65,
								}, -- [17]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:64:128:0:64|t |cff68ccefMage",
							["key"] = "MAGE",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [5]
						{
							["subOptions"] = {
								{
									["type"] = "toggle",
									["key"] = "48788",
									["desc"] = "Heals a friendly target for an amount equal to the Paladin's maximum health and restores 1950 of their mana. If used on self, the Paladin cannot be targeted by Divine Shield, Divine Protection, Hand of Protection, or self-targeted Lay on Hands again for 2 min. Also cannot be used on self within 30 sec of using Avenging Wrath.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_layonhands:20:20:0:0|t Lay on Hands",
									["width"] = 0.65,
								}, -- [1]
								{
									["type"] = "toggle",
									["key"] = "31884",
									["desc"] = "Increases all damage and healing caused by 20% for 20 sec. Cannot be used within 30 sec of being the target of Divine Shield, Divine Protection, or Hand of Protection, or of using Lay on Hands on oneself.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_avenginewrath:20:20:0:0|t Avenging Wrath",
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "48806",
									["desc"] = "Hurls a hammer that strikes an enemy for 1139+0.15*HolP+0.15*AP to 1257+0.15*HolP+0.15*AP Holy damage. Only usable on enemies that have 20% or less health.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_thunderclap:20:20:0:0|t Hammer of Wrath",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "642",
									["desc"] = "Protects the paladin from all damage and spells for 12 sec, but reduces all damage you deal by 50%. Once protected, the target cannot be targeted by Divine Shield, Divine Protection, or Hand of Protection again for 2 min. Cannot be used within 30 sec. of using Avenging Wrath.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_divineintervention:20:20:0:0|t Divine Shield",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "498",
									["desc"] = "Reduces all damage taken by 50% for 12 sec. Once protected, the target cannot be targeted by Divine Shield, Divine Protection, or Hand of Protection again for 2 min. Cannot be used within 30 sec of using Avenging Wrath.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_restoration:20:20:0:0|t Divine Protection",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "10278",
									["desc"] = "A targeted party or raid member is protected from all physical attacks for 10 sec, but during that time they cannot attack or use physical abilities. Players may only have one Hand on them per Paladin at any one time. Once protected, the target cannot be targeted by Divine Shield, Divine Protection, or Hand of Protection again for 2 min. Cannot be targeted on players who have used Avenging Wrath within the last 30 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_sealofprotection:20:20:0:0|t Hand of Protection",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "6940",
									["desc"] = "Places a Hand on the party or raid member, transfering 30% damage taken to the caster. Lasts 12 sec or until the caster has transfered 100% of their maximum health. Players may only have one Hand on them per Paladin at any one time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_sealofsacrifice:20:20:0:0|t Hand of Sacrifice",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "1044",
									["desc"] = "Places a Hand on the friendly target, granting immunity to movement impairing effects for 6 sec. Players may only have one Hand on them per Paladin at any one time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_sealofvalor:20:20:0:0|t Hand of Freedom",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "10308",
									["desc"] = "Stuns the target for 6 sec and interrupts non-player spellcasting for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_sealofmight:20:20:0:0|t Hammer of Justice",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "19752",
									["desc"] = "The paladin sacrifices <himself/herself> to remove the targeted party member from harm's way. Enemies will stop attacking the protected party member, who will be immune to all harmful attacks but will not be able to take any action for 3 min.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_timestop:20:20:0:0|t Divine Intervention",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "31821",
									["desc"] = "Causes your Concentration Aura to make all affected targets immune to Silence and Interrupt effects and improve the effect of all other auras by 100%. Lasts 6 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_auramastery:20:20:0:0|t Aura Mastery",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "31935",
									["desc"] = "Hurls a holy shield at the enemy, dealing 440+0.07*HolP+0.07*AP to 536+0.07*HolP+0.07*AP Holy damage, Dazing them and then jumping to additional nearby enemies. Affects 3 total targets. Lasts 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_avengersshield:20:20:0:0|t Avenger's Shield",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "20066",
									["desc"] = "Puts the enemy target in a state of meditation, incapacitating them for up to 1 min, and removing the effect of Righteous Vengeance. Any damage caused will awaken the target. Usable against Demons, Dragonkin, Giants, Humanoids and Undead.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_prayerofhealing:20:20:0:0|t Repentance",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "48825",
									["desc"] = "Blasts the target with Holy energy, causing 1296 to 1402 Holy damage to an enemy, or 2401 to 2599 healing to an ally.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_searinglight:20:20:0:0|t Holy Shock",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "20216",
									["desc"] = "When activated, gives your next Flash of Light, Holy Light, or Holy Shock spell a 100% critical effect chance.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_heal:20:20:0:0|t Divine Favor",
									["width"] = 0.65,
								}, -- [15]
								{
									["type"] = "toggle",
									["key"] = "64205",
									["desc"] = "30% of all damage taken by party members within 30 yards is redirected to the Paladin (up to a maximum of 40% of the Paladin's health times the number of party members). Damage which reduces the Paladin below 20% health will break the effect. Lasts 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_powerwordbarrier:20:20:0:0|t  Divine Sacrifice",
									["width"] = 0.65,
								}, -- [16]
								{
									["type"] = "toggle",
									["key"] = "10326",
									["desc"] = "The targeted undead or demon enemy will be compelled to flee for up to 20 sec. Damage caused may interrupt the effect. Only one target can be turned at a time.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Holy_TurnUndead:20:20:0:0|t Turn Evil",
									["width"] = 0.65,
								}, -- [17]
								{
									["type"] = "toggle",
									["key"] = "48817",
									["desc"] = "Sends bolts of holy power in all directions, causing 1050+0.07*HolP+0.07*AP to 1234+0.07*HolP+0.07*AP Holy damage and stunning all Undead and Demon targets within 10 yds for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_holy_excorcism:20:20:0:0|t Holy Wrath",
									["width"] = 0.65,
								}, -- [18]
								{
									["type"] = "toggle",
									["key"] = "54428",
									["desc"] = "You gain 25% of your total mana over 15 sec, but the amount healed by your Flash of Light, Holy Light, and Holy Shock spells is reduced by 50%.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Holy_Aspiration:20:20:0:0|t Divine Plea",
									["width"] = 1,
								}, -- [19]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:0:64:128:196|t |cfff48cbaPaladin",
							["key"] = "PALADIN",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [6]
						{
							["subOptions"] = {
								{
									["type"] = "toggle",
									["key"] = "8177",
									["desc"] = "Summons a Grounding Totem with 5 health at the feet of the caster that will redirect one harmful spell cast on a nearby party member to itself, destroying the totem. Will not redirect area of effect spells. Lasts 45 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_groundingtotem:20:20:0:0|t Grounding Totem",
									["width"] = 0.65,
								}, -- [1]
								{
									["type"] = "toggle",
									["key"] = "57994",
									["desc"] = "Instantly blasts the target with a gust of wind, causing no damage but interrupting spellcasting and preventing any spell in that school from being cast for 2 sec. Also lowers your threat, making the enemy less likely to attack you.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_cyclone:20:20:0:0|t Wind Shear",
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "51514",
									["desc"] = "Transforms the enemy into a frog. While hexed, the target cannot attack or cast spells. Damage caused may interrupt the effect. Lasts 30 sec. Only one target can be hexed at a time. Only works on Humanoids and Beasts.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shaman_hex:20:20:0:0|t Hex",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "59159",
									["desc"] = "You call down a bolt of lightning, energizing you and damaging nearby enemies within 10 yards. Restores 8% mana to you and deals 1450 to 1656 Nature damage to all nearby enemies, knocking them back 20 yards. This spell is usable while stunned.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shaman_thunderstorm:20:20:0:0|t Thunderstorm",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "51533",
									["desc"] = "Summons two Spirit Wolves under the command of the Shaman, lasting 45 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shaman_feralspirit:20:20:0:0|t Feral Spirit",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "32182",
									["desc"] = "Melee, ranged, and spell casting speed increased by 30%.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_shaman_heroism:20:20:0:0|t Heroism",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "2825",
									["desc"] = "Melee, ranged, and spell casting speed increased by 30%.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Nature_BloodLust:18:18:0:0:64:64:4:60:4:60|t Bloodlust",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "2894",
									["desc"] = "Summons an elemental totem that calls forth a greater fire elemental to rain destruction on the caster's enemies. Lasts 2 min.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_fire_elemental_totem:20:20:0:0|t Fire Elemental Totem",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "2484",
									["desc"] = "Summons an Earthbind Totem with 5 health at the feet of the caster for 45 sec that slows the movement speed of enemies within 10 yards.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_strengthofearthtotem02:20:20:0:0|t Earthbind Totem",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "16166",
									["desc"] = "When activated, your next Lightning Bolt, Chain Lightning or Lava Burst spell becomes an instant cast spell. In addition, you gain 15% spell haste for 15 sec. Elemental Mastery shares a cooldown with Nature's Swiftness.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_wispheal:20:20:0:0|t Elemental Mastery",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "16190",
									["desc"] = "Summons a Mana Tide Totem with 10% of the caster's health at the feet of the caster for 12 sec that restores 6% of total mana every 3 seconds to group members within 30 yards.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_frost_summonwaterelemental:20:20:0:0|t Mana Tide Totem",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "30823",
									["desc"] = "Reduces all damage taken by 30% and gives your successful melee attacks a chance to regenerate mana equal to 15% of your attack power. This spell is usable while stunned. Lasts 15 sec.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_shamanrage:20:20:0:0|t Shamanistic Rage",
									["width"] = 0.65,
								}, -- [12]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:64:128:64:128|t |cff2359ffShaman",
							["key"] = "SHAMAN",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [7]
						{
							["subOptions"] = {
								{
									["subOptions"] = {
										{
											["type"] = "toggle",
											["key"] = "19647",
											["desc"] = "Silences the enemy for 3 sec. If used on a casting target, it will counter the enemy's spellcast, preventing any spell from that school of magic from being cast for 6 sec.",
											["default"] = true,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Shadow_MindRot:20:20:0:0|t Spell Lock",
											["width"] = 1,
										}, -- [1]
										{
											["type"] = "toggle",
											["key"] = "48011",
											["desc"] = "Purges 1 harmful magic effect from a friend or 1 beneficial magic effect from an enemy. If an effect is devoured, the Felhunter will be healed for 1150.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Nature_Purge:20:20:0:0|t Devour Magic",
											["width"] = 1,
										}, -- [2]
										{
											["type"] = "toggle",
											["key"] = "54053",
											["desc"] = "Bite the enemy, causing 98 to 138 Shadow damage plus an additional 15% damage for each of your damage over time effects on the target.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Shadow_SoulLeech_3:20:20:0:0|t Shadow Bite",
											["width"] = 1,
										}, -- [3]
										{
											["type"] = "toggle",
											["key"] = "47986",
											["desc"] = "Sacrifices a portion of the Voidwalker's health, giving its master a shield that will absorb 8350 damage for 30 sec. While the shield holds, spellcasting will not be interrupted by damage.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Shadow_SacrificialShield:20:20:0:0|t Sacrifice",
											["width"] = 1,
										}, -- [4]
										{
											["type"] = "toggle",
											["key"] = "47990",
											["desc"] = "Taunts all enemies within 10 yards, increasing the chance that they will attack the Voidwalker and reducing chance to hit by 10% for 15 sec. More effective than Suffering (Rank 7).",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Shadow_BlackPlague:20:20:0:0|t Suffering",
											["width"] = 1,
										}, -- [5]
									},
									["hideReorder"] = true,
									["nameSource"] = 0,
									["width"] = 0.65,
									["useCollapse"] = true,
									["key"] = "pet",
									["name"] = "Pet abilities",
									["collapse"] = false,
									["limitType"] = "none",
									["groupType"] = "simple",
									["type"] = "group",
									["size"] = 10,
								}, -- [1]
								{
									["type"] = "header",
									["useName"] = false,
									["text"] = "",
									["noMerge"] = false,
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "48020",
									["desc"] = "Teleports you to your Demonic Circle and removes all snare effects.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_demoniccircleteleport:20:20:0:0|t Demonic Circle: Teleport",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "47877",
									["desc"] = "Instantly restores 5136 life.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\INV_Stone_04:20:20:0:0|t Master Healthstone",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "1122",
									["desc"] = "Summons a meteor from the Twisting Nether, causing 200 Fire damage and stunning all enemy targets in the area for 2 sec. An Infernal rises from the crater, under the command of the caster for 1 min.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_summoninfernal:20:20:0:0|t Inferno",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "54785",
									["desc"] = "Charge an enemy, stunning it for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warstomp:20:20:0:0|t Demon Charge",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "47860",
									["desc"] = "Causes the enemy target to run in horror for 3 sec and causes 790 Shadow damage. The caster gains 300% of the damage caused in health.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_deathcoil:20:20:0:0|t Death Coil",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "17928",
									["desc"] = "Howl, causing 5 enemies within 10 yds to flee in terror for 8 sec. Damage caused may interrupt the effect.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_deathscream:20:20:0:0|t Howl of Terror",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "50796",
									["desc"] = "Sends a bolt of chaotic fire at the enemy, dealing 837 to 1061 Fire damage. Chaos Bolt cannot be resisted, and pierces through all absorption effects.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warlock_chaosbolt:20:20:0:0|t Chaos Bolt",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "47847",
									["desc"] = "Shadowfury is unleashed, causing 968 to 1152 Shadow damage and stunning all enemies within 8 yds for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_shadowfury:20:20:0:0|t Shadowfury",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "18708",
									["desc"] = "Your next Imp, Voidwalker, Succubus, Felhunter or Felguard Summon spell has its casting time reduced by 5.5 sec and its Mana cost reduced by 50%.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_nature_removecurse:20:20:0:0|t Fel Domination",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "47193",
									["desc"] = "Grants the Warlock's summoned demon Empowerment.Imp - Increases the Imp's spell critical strike chance by 20% for 30 sec.Voidwalker - Increases the Voidwalker's health by 20%, and its threat generated from spells and attacks by 20% for 20 sec.Succubus - Instantly vanishes, causing the Succubus to go into an improved Invisibility state. The vanish effect removes all stuns, snares and movement impairing effects from the Succubus.Felhunter - Dispels all magical effects from the Felhunter.Felguard - Increases the Felguard's attack speed by 20% and breaks all stun, snare and movement impairing effects and makes your Felguard immune to them for 15 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Ability_Warlock_DemonicEmpowerment:20:20:0:0|t Demonic Empowerment",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "61290",
									["desc"] = "Targets in a cone in front of the caster take 615 to 671 Shadow damage and an additional 644 Fire damage over 8 sec.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Ability_Warlock_ShadowFlame:20:20:0:0|t Shadowflame",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "47827",
									["desc"] = "Instantly blasts the target for 775 to 865 Shadow damage. If the target dies within 5 sec of Shadowburn, and yields experience or honor, the caster gains a Soul Shard.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Shadow_ScourgeBuild:20:20:0:0|t Shadowburn",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "59671",
									["desc"] = "Taunts all enemies within 10 yards for 6 sec.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Nature_ShamanRage:20:20:0:0|t Challenging Howl",
									["width"] = 0.65,
								}, -- [15]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:196:256:64:128|t |cff9382c9Warlock",
							["key"] = "WARLOCK",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [8]
						{
							["subOptions"] = {
								{
									["type"] = "toggle",
									["key"] = "871",
									["desc"] = "Reduces all damage taken by 60% for 12 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_shieldwall:20:20:0:0|t Shield Wall",
									["width"] = 0.65,
								}, -- [1]
								{
									["type"] = "toggle",
									["key"] = "23920",
									["desc"] = "Raise your shield, reflecting the next spell cast on you. Lasts 5 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_shieldreflection:20:20:0:0|t Spell Reflection",
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "676",
									["desc"] = "Disarm the enemy's main hand and ranged weapons for 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_disarm:20:20:0:0|t Disarm",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "3411",
									["desc"] = "Run at high speed towards a party member, intercepting the next melee or ranged attack made against them as well as reducing their total threat by 10%.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_victoryrush:20:20:0:0|t Intervene",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "72",
									["desc"] = "Bash the target with your shield dazing them and interrupting spellcasting, which prevents any spell in that school from being cast for 6 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_shieldbash:20:20:0:0|t Shield Bash",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "55694",
									["desc"] = "You regenerate 30% of your total health over 10 sec. This ability requires an Enrage effect, consumes all Enrage effects and prevents any from affecting you for the full duration.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_focusedrage:20:20:0:0|t Enraged Regeneration",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "6552",
									["desc"] = "Pummel the target, interrupting spellcasting and preventing any spell in that school from being cast for 4 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\inv_gauntlets_04:20:20:0:0|t Pummel",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "20252",
									["desc"] = "Charge an enemy, causing AP*0.12 damage (based on attack power) and stunning it for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_rogue_sprint:20:20:0:0|t Intercept",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "5246",
									["desc"] = "The warrior shouts, causing up to 5 enemies within 8 yards to cower in fear. The targeted enemy will be unable to move while cowering. Lasts 8 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_golemthunderclap:20:20:0:0|t Intimidating Shout",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "11578",
									["desc"] = "Charge an enemy, generate 15 rage, and stun it for 1.5 sec. Cannot be used in combat.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_charge:20:20:0:0|t Charge",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "46924",
									["desc"] = "Instantly Whirlwind up to 4 nearby targets and for the next 6 sec you will perform a whirlwind attack every 1 sec. While under the effects of Bladestorm, you can move but cannot perform any other abilities but you do not feel pity or remorse or fear and you cannot be stopped unless killed.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_bladestorm:20:20:0:0|t Bladestorm",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "60970",
									["desc"] = "Removes any Immobilization effects and refreshes the cooldown of your Intercept ability.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_heroicleap:20:20:0:0|t Heroic Fury",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "12809",
									["desc"] = "Stuns the opponent for 5 sec and deals 38/100*AP damage (based on attack power).",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_thunderbolt:20:20:0:0|t Concussion Blow",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "46968",
									["desc"] = "Sends a wave of force in front of the warrior, causing 75/100*AP damage (based on attack power) and stunning all enemy targets within 10 yards in a frontal cone for 4 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_shockwave:20:20:0:0|t Shockwave",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "2565",
									["desc"] = "Increases your chance to block and block value by 100% for 10 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_defend:20:20:0:0|t Shield Block",
									["width"] = 0.65,
								}, -- [15]
								{
									["type"] = "toggle",
									["key"] = "20230",
									["desc"] = "Instantly counterattack any enemy that strikes you in melee for 12 sec. Melee attacks made from behind cannot be counterattacked. A maximum of 20 attacks will cause retaliation.",
									["default"] = false,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_warrior_challange:20:20:0:0|t Retaliation",
									["width"] = 0.65,
								}, -- [16]
								{
									["type"] = "toggle",
									["key"] = "1719",
									["desc"] = "Your next 3 special ability attacks have an additional 100% to critically hit but all damage taken is increased by 20%. Lasts 12 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_criticalstrike:20:20:0:0|t Recklessness",
									["width"] = 0.65,
								}, -- [17]
								{
									["type"] = "toggle",
									["key"] = "12292",
									["desc"] = "When activated you become enraged, increasing your physical damage by 20% but increasing all damage taken by 5%. Lasts 30 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_deathpact:20:20:0:0|t Death Wish",
									["width"] = 0.65,
								}, -- [18]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:0:64:0:64|t |cffc69b6dWarrior",
							["key"] = "WARRIOR",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [9]
						{
							["subOptions"] = {
								{
									["subOptions"] = {
										{
											["type"] = "toggle",
											["key"] = "47481",
											["desc"] = "Chew a limb off the target, stunning for 3 sec and dealing damage.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_DeathKnight_Gnaw_Ghoul:20:20:0:0|t Gnaw",
											["width"] = 1,
										}, -- [1]
										{
											["type"] = "toggle",
											["key"] = "47482",
											["desc"] = "Leap behind the targeted friend or enemy.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Shadow_Skull:20:20:0:0|t Leap",
											["width"] = 1,
										}, -- [2]
										{
											["type"] = "toggle",
											["key"] = "47484",
											["desc"] = "Go into a defensive crouch, reducing the damage taken from melee attacks, ranged attacks and spells by 50% for 10 sec.",
											["default"] = false,
											["useDesc"] = true,
											["name"] = "|TInterface\\Icons\\Spell_Shadow_RaiseDead:20:20:0:0|t Huddle",
											["width"] = 1,
										}, -- [3]
									},
									["hideReorder"] = true,
									["nameSource"] = 0,
									["width"] = 0.65,
									["useCollapse"] = true,
									["key"] = "pet",
									["name"] = "Pet abilities",
									["collapse"] = false,
									["limitType"] = "none",
									["groupType"] = "simple",
									["type"] = "group",
									["size"] = 10,
								}, -- [1]
								{
									["type"] = "header",
									["useName"] = false,
									["text"] = "",
									["noMerge"] = false,
									["width"] = 0.65,
								}, -- [2]
								{
									["type"] = "toggle",
									["key"] = "51052",
									["desc"] = "Places a large, stationary Anti-Magic Zone that reduces spell damage done to party or raid members inside it by 75%. The Anti-Magic Zone lasts for 10 sec or until it absorbs 10000+2*AP spell damage.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_deathknight_antimagiczone:20:20:0:0|t Anti-Magic Zone",
									["width"] = 0.65,
								}, -- [3]
								{
									["type"] = "toggle",
									["key"] = "48707",
									["desc"] = "Surrounds the Death Knight in an Anti-Magic Shell, absorbing 75% of the damage dealt by harmful spells (up to a maximum of 50% of the Death Knight's health) and preventing application of harmful magical effects. Damage absorbed by Anti-Magic Shell energizes the Death Knight with additional runic power. Lasts 5 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_antimagicshell:20:20:0:0|t Anti-Magic Shell",
									["width"] = 0.65,
								}, -- [4]
								{
									["type"] = "toggle",
									["key"] = "49576",
									["desc"] = "Harness the unholy energy that surrounds and binds all matter, drawing the target toward the death knight and forcing the enemy to attack the death knight for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_deathknight_strangulate:20:20:0:0|t Death Grip",
									["width"] = 0.65,
								}, -- [5]
								{
									["type"] = "toggle",
									["key"] = "46584",
									["desc"] = "Raises a Ghoul to fight by your side. If no humanoid corpse that yields experience or honor is available, you must supply Corpse Dust to complete the spell. You can have a maximum of one Ghoul at a time. Lasts 1 min.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\Spell_Shadow_AnimateDead:20:20:0:0|t Raise Dead",
									["width"] = 0.65,
								}, -- [6]
								{
									["type"] = "toggle",
									["key"] = "42650",
									["desc"] = "Summons an entire legion of Ghouls to fight for the Death Knight. The Ghouls will swarm the area, taunting and fighting anything they can. While channelling Army of the Dead, the Death Knight takes less damage equal to <his/her> Dodge plus Parry chance.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_deathknight_armyofthedead:20:20:0:0|t Army of the Dead",
									["width"] = 0.65,
								}, -- [7]
								{
									["type"] = "toggle",
									["key"] = "47528",
									["desc"] = "Smash the target's mind with cold, interrupting spellcasting and preventing any spell in that school from being cast for 4 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_deathknight_mindfreeze:20:20:0:0|t Mind Freeze",
									["width"] = 0.65,
								}, -- [8]
								{
									["type"] = "toggle",
									["key"] = "48792",
									["desc"] = "The Death Knight freezes <his/her> blood to become immune to Stun effects and reduce all damage taken by 30% plus additional damage reduction based on Defense for 12 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_deathknight_iceboundfortitude:20:20:0:0|t Icebound Fortitude",
									["width"] = 0.65,
								}, -- [9]
								{
									["type"] = "toggle",
									["key"] = "48743",
									["desc"] = "Sacrifices an undead minion, healing the Death Knight for 40% of <his/her> maximum health. This heal cannot be a critical.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_deathpact:20:20:0:0|t Death Pact",
									["width"] = 0.65,
								}, -- [10]
								{
									["type"] = "toggle",
									["key"] = "47476",
									["desc"] = "Strangulates an enemy, silencing them for 5 sec. Non-player victim spellcasting is also interrupted for 3 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_soulleech_3:20:20:0:0|t Strangulate",
									["width"] = 0.65,
								}, -- [11]
								{
									["type"] = "toggle",
									["key"] = "49206",
									["desc"] = "A Gargoyle flies into the area and bombards the target with Nature damage modified by the Death Knight's attack power. Persists for 30 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_pet_bat:20:20:0:0|t Summon Gargoyle",
									["width"] = 0.65,
								}, -- [12]
								{
									["type"] = "toggle",
									["key"] = "49039",
									["desc"] = "Draw upon unholy energy to become undead for 10 sec. While undead, you are immune to Charm, Fear and Sleep effects.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_raisedead:20:20:0:0|t Lichborne",
									["width"] = 0.65,
								}, -- [13]
								{
									["type"] = "toggle",
									["key"] = "49203",
									["desc"] = "Purges the earth around the Death Knight of all heat. Enemies within 10 yards are trapped in ice, preventing them from performing any action for 10 sec and infecting them with Frost Fever. Enemies are considered Frozen, but any damage other than diseases will break the ice.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\inv_staff_15:20:20:0:0|t Hungering Cold",
									["width"] = 0.65,
								}, -- [14]
								{
									["type"] = "toggle",
									["key"] = "51271",
									["desc"] = "Reinforces your armor with a thick coat of ice, increasing your armor by 25% and increasing your Strength by 20% for 20 sec.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\inv_armor_helm_plate_naxxramas_raidwarrior_c_01:20:20:0:0|t Unbreakable Armor",
									["width"] = 0.65,
								}, -- [15]
								{
									["type"] = "toggle",
									["key"] = "48982",
									["desc"] = "Converts 1 Blood Rune into 10% of your maximum health.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_deathknight_runetap:20:20:0:0|t Rune Tap",
									["width"] = 0.65,
								}, -- [16]
								{
									["type"] = "toggle",
									["key"] = "49005",
									["desc"] = "Place a Mark of Blood on an enemy. Whenever the marked enemy deals damage to a target, that target is healed for 4% of its maximum health. Lasts for 20 sec or up to 20 hits.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\ability_hunter_rapidkilling:20:20:0:0|t Mark of Blood",
									["width"] = 0.65,
								}, -- [17]
								{
									["type"] = "toggle",
									["key"] = "49016",
									["desc"] = "Induces a friendly unit into a killing frenzy for 30 sec. The target is Enraged, which increases their physical damage by 20%, but causes them to lose health equal to 1% of their maximum health every second.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_deathknight_bladedarmor:20:20:0:0|t Hysteria",
									["width"] = 0.65,
								}, -- [18]
								{
									["type"] = "toggle",
									["key"] = "49937",
									["desc"] = "Corrupts the ground targeted by the Death Knight, causing 49 Shadow damage every sec that targets remain in the area for 10 sec. This ability produces a high amount of threat.",
									["default"] = true,
									["useDesc"] = true,
									["name"] = "|TInterface\\Icons\\spell_shadow_deathanddecay:20:20:0:0|t Death and Decay",
									["width"] = 0.65,
								}, -- [19]
							},
							["hideReorder"] = true,
							["useDesc"] = false,
							["nameSource"] = 0,
							["width"] = 1,
							["useCollapse"] = true,
							["collapse"] = true,
							["name"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:26:26:0:0:256:256:64:128:128:196|t |cffc41e3bDeath Knight",
							["key"] = "DEATHKNIGHT",
							["limitType"] = "none",
							["groupType"] = "simple",
							["type"] = "group",
							["size"] = 10,
						}, -- [10]
					},
					["hideReorder"] = true,
					["useDesc"] = false,
					["nameSource"] = 0,
					["width"] = 1,
					["useCollapse"] = true,
					["collapse"] = true,
					["name"] = "List of class spells",
					["key"] = "cds",
					["limitType"] = "none",
					["groupType"] = "simple",
					["type"] = "group",
					["size"] = 10,
				}, -- [17]
				{
					["type"] = "header",
					["useName"] = false,
					["text"] = "Расовые споспобности и тринкеты",
					["noMerge"] = false,
					["width"] = 1,
				}, -- [18]
				{
					["subOptions"] = {
						{
							["type"] = "toggle",
							["key"] = "42292",
							["desc"] = "Removes all movement impairing effects and all effects which cause loss of control of your character.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\spell_holy_dispelmagic:20:20:0:0|t PvP Trinket",
							["width"] = 1,
						}, -- [1]
						{
							["type"] = "toggle",
							["key"] = "59752",
							["desc"] = "Removes all movement impairing effects and all effects which cause loss of control of your character. This effect shares a cooldown with other similar effects.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\spell_shadow_charm:20:20:0:0|t Every Man for Himself",
							["width"] = 1,
						}, -- [2]
						{
							["type"] = "toggle",
							["key"] = "71607",
							["desc"] = "Instantly heal a friendly target for 7400 to 8600.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\INV_Jewelcrafting_Gem_28:20:20:0:0|t Bauble of True Blood",
							["width"] = 1,
						}, -- [3]
						{
							["type"] = "toggle",
							["key"] = "71586",
							["desc"] = "Absorbs 6400 damage.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\inv_misc_key_15:20:20:0:0|t Corroded Skeleton Key",
							["width"] = 1,
						}, -- [4]
						{
							["type"] = "toggle",
							["key"] = "71638",
							["desc"] = "Arane, Fire, Frost, Nature, and Shadow resistance increased by 268.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\inv_jewelry_trinket_06:20:20:0:0|t Sindragosa's Flawless Fang",
							["width"] = 1,
						}, -- [5]
						{
							["type"] = "toggle",
							["key"] = "75490",
							["desc"] = "For the next 15 sec, each time your direct healing spells heal a target you cause the target of your heal to heal themselves and friends within 10 yards for 356 each sec for 6 sec.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\inv_misc_rubysanctum1:20:20:0:0|t Glowing Twilight Scale",
							["width"] = 1,
						}, -- [6]
						{
							["type"] = "toggle",
							["key"] = "67596",
							["desc"] = "Increases maximum health by 4608 for 15 sec. Shares cooldown with other Battlemaster's trinkets.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\ability_warrior_endlessrage:20:20:0:0|t Battlemaster's",
							["width"] = 1,
						}, -- [7]
						{
							["type"] = "toggle",
							["key"] = "58984",
							["desc"] = "Activate to slip into the shadows, reducing the chance for enemies to detect your presence. Lasts until cancelled or upon moving. Any threat is restored versus enemies still in combat upon cancellation of this effect.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\ability_ambush:20:20:0:0|t Shadowmeld",
							["width"] = 1,
						}, -- [8]
						{
							["type"] = "toggle",
							["key"] = "59547",
							["desc"] = "Heals the target for 50 over 15 sec. The amount healed is increased by your spell power or attack power, whichever is higher.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\spell_holy_holyprotection:20:20:0:0|t Gift of the Naaru",
							["width"] = 1,
						}, -- [9]
						{
							["type"] = "toggle",
							["key"] = "20594",
							["desc"] = "Removes all poison, disease and bleed effects and increases your armor by 10% for 8 sec",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\spell_shadow_unholystrength:20:20:0:0|t Stoneform",
							["width"] = 1,
						}, -- [10]
						{
							["type"] = "toggle",
							["key"] = "20589",
							["desc"] = "Escape the effects of any immobilization or movement speed reduction effect.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\ability_rogue_trip:20:20:0:0|t Escape Artist",
							["width"] = 1,
						}, -- [11]
						{
							["type"] = "toggle",
							["key"] = "20572",
							["desc"] = "Increases attack power by 6. Lasts 15 sec.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\racial_orc_berserkerstrength:20:20:0:0|t Blood Fury",
							["width"] = 1,
						}, -- [12]
						{
							["type"] = "toggle",
							["key"] = "7744",
							["desc"] = "Removes any Charm, Fear and Sleep effect. This effect shares a 45 sec cooldown with other similar effects.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\spell_shadow_raisedead:20:20:0:0|t Will of the Forsaken",
							["width"] = 1,
						}, -- [13]
						{
							["type"] = "toggle",
							["key"] = "20549",
							["desc"] = "Stuns up to 5 enemies within 8 yds for 2 sec.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\ability_warstomp:20:20:0:0|t War Stomp",
							["width"] = 1,
						}, -- [14]
						{
							["type"] = "toggle",
							["key"] = "26297",
							["desc"] = "Increases your attack and casting speed by 20% for 10 sec.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\racial_troll_berserk:20:20:0:0|t Berserking",
							["width"] = 1,
						}, -- [15]
						{
							["type"] = "toggle",
							["key"] = "28730",
							["desc"] = "Silence all enemies within 8 yards for 2 sec and restores 6% of your Mana. Non-player victim spellcasting is also interrupted for 3 sec.",
							["default"] = true,
							["useDesc"] = true,
							["name"] = "|TInterface\\Icons\\spell_shadow_teleport:20:20:0:0|t Arcane Torrent",
							["width"] = 1,
						}, -- [16]
					},
					["hideReorder"] = true,
					["useDesc"] = false,
					["nameSource"] = 0,
					["width"] = 1,
					["useCollapse"] = true,
					["collapse"] = true,
					["name"] = "Racial spells and Trinkets",
					["key"] = "ANY",
					["limitType"] = "none",
					["groupType"] = "simple",
					["type"] = "group",
					["size"] = 10,
				}, -- [19]
				{
					["type"] = "header",
					["useName"] = false,
					["text"] = "",
					["noMerge"] = false,
					["width"] = 1,
				}, -- [20]
				{
					["type"] = "toggle",
					["key"] = "lib_error",
					["desc"] = "",
					["default"] = false,
					["useDesc"] = false,
					["name"] = "hide lib error text",
					["width"] = 1,
				}, -- [21]
				{
					["type"] = "toggle",
					["key"] = "blizzFrame",
					["default"] = false,
					["useDesc"] = false,
					["name"] = "Ignore blizz party frame",
					["width"] = 1,
				}, -- [22]
			},
			["inverse"] = true,
			["Самапнулшм"] = {
				["roster"] = {
					["0x00000000002429B3"] = {
						["unitID"] = "party1",
						["race"] = "Human",
						["spells"] = {
							["64901"] = {
								["dst"] = false,
								["cd"] = 360,
								["exp"] = 3692.015,
							},
							["59752"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 3692.015,
							},
							["10890"] = {
								["dst"] = false,
								["cd"] = 27,
								["exp"] = 3692.015,
							},
							["71607"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 3692.015,
							},
							["34433"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 3692.015,
							},
							["64843"] = {
								["dst"] = false,
								["cd"] = 480,
								["exp"] = 3692.015,
							},
							["33206"] = {
								["dst"] = false,
								["cd"] = 144,
								["exp"] = 3692.015,
							},
							["48173"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 3692.015,
							},
						},
						["faction"] = "Alliance",
						["unitName"] = "Dpheroqt",
						["trinkets"] = {
							[14] = {
								["itemName"] = "Подвеска истинной крови",
								["itemID"] = 50354,
								["spellID"] = 71607,
							},
						},
						["pet"] = {
						},
						["class"] = "PRIEST",
					},
				},
			},
			["Leal"] = {
				["roster"] = {
					["0x000000000019D699"] = {
						["unitName"] = "Zzuz",
						["race"] = "NightElf",
						["spells"] = {
							["51722"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 12754.187,
							},
							["8643"] = {
								["dst"] = false,
								["cd"] = 20,
								["exp"] = 12754.187,
							},
							["26889"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 12754.187,
							},
							["2094"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 12754.187,
							},
							["11305"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 12754.187,
							},
							["31224"] = {
								["dst"] = false,
								["cd"] = 90,
								["exp"] = 12754.187,
							},
							["26669"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 12754.187,
							},
							["57934"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 12754.187,
							},
						},
						["faction"] = "Alliance",
						["unitID"] = "party1",
						["trinkets"] = {
						},
						["frame"] = {
							["framePriorities"] = {
								"^PartyMemberFrame", -- [1]
							},
						},
						["class"] = "ROGUE",
					},
					["0x000000000035017E"] = {
						["unitName"] = "Spectorqx",
						["race"] = "Human",
						["spells"] = {
							["5246"] = {
								["dst"] = false,
								["cd"] = 120,
								["exp"] = 12754.187,
							},
							["23920"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 12754.187,
							},
							["46924"] = {
								["dst"] = false,
								["cd"] = 90,
								["exp"] = 12754.187,
							},
							["2565"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 12754.187,
							},
							["3411"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 12754.187,
							},
							["11578"] = {
								["dst"] = false,
								["cd"] = 20,
								["exp"] = 12754.187,
							},
							["6552"] = {
								["dst"] = false,
								["cd"] = 10,
								["exp"] = 12754.187,
							},
							["676"] = {
								["dst"] = false,
								["cd"] = 60,
								["exp"] = 12754.187,
							},
							["20252"] = {
								["dst"] = false,
								["cd"] = 30,
								["exp"] = 12754.187,
							},
							["871"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 12754.187,
							},
							["72"] = {
								["dst"] = false,
								["cd"] = 12,
								["exp"] = 12754.187,
							},
							["20230"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 12754.187,
							},
							["1719"] = {
								["dst"] = false,
								["cd"] = 300,
								["exp"] = 12754.187,
							},
							["55694"] = {
								["dst"] = false,
								["cd"] = 180,
								["exp"] = 12754.187,
							},
						},
						["faction"] = "Alliance",
						["unitID"] = "party2",
						["trinkets"] = {
						},
						["frame"] = {
							["framePriorities"] = {
								"^PartyMemberFrame", -- [1]
							},
						},
						["class"] = "WARRIOR",
					},
				},
			},
			["cooldown"] = true,
			["config"] = {
				["des"] = false,
				["direction"] = 1,
				["ANY"] = {
					["67596"] = false,
					["28730"] = false,
					["59547"] = false,
					["42292"] = true,
					["59752"] = true,
					["71638"] = false,
					["71586"] = true,
					["26297"] = false,
					["20549"] = false,
					["7744"] = true,
					["58984"] = false,
					["20572"] = false,
					["20594"] = true,
					["71607"] = true,
					["75490"] = false,
					["20589"] = false,
				},
				["anchorTo"] = 8,
				["xOffset"] = 0,
				["cds"] = {
					["HUNTER"] = {
						["34600"] = false,
						["19263"] = true,
						["1543"] = false,
						["61006"] = false,
						["49067"] = false,
						["13809"] = true,
						["19577"] = true,
						["14311"] = true,
						["3045"] = true,
						["53271"] = true,
						["19503"] = true,
						["49012"] = true,
						["49048"] = false,
						["63672"] = false,
						["781"] = false,
						["pet"] = {
							["64495"] = true,
							["53548"] = true,
							["53561"] = true,
							["55754"] = true,
							["58611"] = true,
							["53568"] = true,
							["53480"] = true,
							["26064"] = true,
							["4167"] = true,
							["55492"] = true,
							["61198"] = true,
							["26090"] = true,
						},
						["49050"] = false,
						["60192"] = false,
						["49056"] = false,
						["34477"] = false,
						["19574"] = true,
						["5384"] = false,
						["34490"] = true,
						["53209"] = false,
						["23989"] = true,
					},
					["WARRIOR"] = {
						["12292"] = true,
						["60970"] = false,
						["20252"] = false,
						["20230"] = true,
						["55694"] = false,
						["12809"] = true,
						["46968"] = true,
						["1719"] = true,
						["23920"] = true,
						["2565"] = true,
						["11578"] = false,
						["6552"] = false,
						["676"] = true,
						["871"] = true,
						["3411"] = true,
						["72"] = false,
						["5246"] = true,
						["46924"] = true,
					},
					["ROGUE"] = {
						["51713"] = true,
						["26889"] = true,
						["1766"] = false,
						["11305"] = false,
						["31224"] = true,
						["14177"] = true,
						["57934"] = true,
						["51722"] = true,
						["36554"] = false,
						["51690"] = true,
						["1776"] = false,
						["8643"] = true,
						["2094"] = true,
						["26669"] = true,
						["14185"] = true,
					},
					["MAGE"] = {
						["12051"] = true,
						["12472"] = true,
						["43039"] = true,
						["12042"] = true,
						["31687"] = false,
						["55342"] = false,
						["42917"] = false,
						["1953"] = true,
						["42945"] = true,
						["42950"] = true,
						["45438"] = true,
						["66"] = false,
						["42931"] = false,
						["44572"] = true,
						["11958"] = true,
						["12043"] = false,
						["2139"] = true,
					},
					["PRIEST"] = {
						["64901"] = false,
						["47788"] = true,
						["48173"] = true,
						["48158"] = false,
						["64843"] = false,
						["6346"] = true,
						["10060"] = true,
						["10890"] = true,
						["47585"] = true,
						["33206"] = true,
						["64044"] = true,
						["34433"] = true,
						["15487"] = true,
						["53007"] = false,
						["14751"] = false,
					},
					["WARLOCK"] = {
						["47860"] = true,
						["47847"] = true,
						["61290"] = true,
						["17928"] = false,
						["18708"] = true,
						["47877"] = false,
						["pet"] = {
							["48011"] = true,
							["54053"] = false,
							["19647"] = true,
							["47990"] = false,
							["47986"] = true,
						},
						["47827"] = true,
						["59671"] = false,
						["48020"] = true,
						["1122"] = false,
						["54785"] = true,
						["47193"] = true,
						["50796"] = true,
					},
					["PALADIN"] = {
						["1044"] = true,
						["48806"] = false,
						["10308"] = true,
						["54428"] = false,
						["31884"] = true,
						["20066"] = true,
						["6940"] = true,
						["20216"] = false,
						["19752"] = false,
						["31821"] = false,
						["10326"] = false,
						["48817"] = false,
						["498"] = false,
						["31935"] = false,
						["48788"] = false,
						["48825"] = false,
						["64205"] = true,
						["642"] = true,
						["10278"] = true,
					},
					["DRUID"] = {
						["48477"] = false,
						["50334"] = true,
						["17116"] = true,
						["33357"] = false,
						["61384"] = true,
						["33831"] = true,
						["49376"] = false,
						["61336"] = true,
						["29166"] = true,
						["48447"] = false,
						["22842"] = false,
						["18562"] = true,
						["22812"] = true,
						["8983"] = true,
						["53201"] = true,
						["48438"] = false,
						["49377"] = false,
					},
					["SHAMAN"] = {
						["8177"] = true,
						["2484"] = false,
						["51533"] = true,
						["16190"] = true,
						["57994"] = false,
						["51514"] = true,
						["32182"] = true,
						["16166"] = true,
						["30823"] = true,
						["2825"] = true,
						["59159"] = true,
						["2894"] = false,
					},
					["DEATHKNIGHT"] = {
						["49039"] = true,
						["47476"] = true,
						["51271"] = true,
						["49203"] = true,
						["48743"] = true,
						["49937"] = false,
						["48982"] = false,
						["49005"] = false,
						["48792"] = true,
						["49016"] = true,
						["47528"] = false,
						["pet"] = {
							["47484"] = false,
							["47481"] = true,
							["47482"] = false,
						},
						["49576"] = true,
						["42650"] = false,
						["48707"] = true,
						["46584"] = false,
						["51052"] = true,
						["49206"] = true,
					},
				},
				["lib_error"] = true,
				["yOffset"] = 0,
				["show"] = false,
				["column"] = 4,
				["blizzFrame"] = true,
				["spacing"] = 0,
				["anchor"] = 9,
				["frame"] = 24,
				["glow"] = true,
				["countUnits"] = 4,
			},
		},
		["Windfury Totem Pulse"] = {
			["sparkWidth"] = 10,
			["sparkOffsetX"] = 0,
			["xOffset"] = -20,
			["adjustedMax"] = "10",
			["adjustedMin"] = "0",
			["yOffset"] = 18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["url"] = "https://wago.io/otyGuo9sL/3",
			["actions"] = {
				["start"] = {
					["do_custom"] = false,
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["dynamicDuration"] = false,
						["custom_type"] = "event",
						["spellIds"] = {
						},
						["duration"] = "10",
						["event"] = "Health",
						["unit"] = "player",
						["customDuration"] = "function()\n    \n \n        duration = 5\n        return true\n  \n    end",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED:player WF_REFIRE_EVENT PLAYER_TOTEM_UPDATE",
						["custom"] = "function(event, unit, _, spell_ID)\n    \n    if (spell_ID == 8512 or spell_ID == 10613 or spell_ID == 10614) and unit == \"player\" and event ~= \"WF_REFIRE_EVENT\" then\n        \n        if aura_env.timer then \n            \n            aura_env.timer:Cancel() \n            aura_env.timer = 0\n        end\n        \n        aura_env.timer = C_Timer.NewTicker(5, function() WeakAuras.ScanEvents(\"WF_REFIRE_EVENT\") end,23)\n        \n        return true\n        \n    elseif  event == \"WF_REFIRE_EVENT\"  then\n        \n        return true\n        \n    elseif (spell_ID == 8835\n        or spell_ID == 10627\n        or spell_ID == 25359\n        or spell_ID == 8177\n        or spell_ID == 10595\n        or spell_ID == 10600\n        or spell_ID == 10601\n        or spell_ID == 6495\n        or spell_ID == 25908\n        or spell_ID == 15107\n        or spell_ID == 15111\n        or spell_ID == 15112\n        \n    ) and unit == \"player\" and event ~= \"WF_REFIRE_EVENT\" then\n        \n        if aura_env.timer then \n            \n            aura_env.timer:Cancel() \n        end   \n        \n    end\nend",
						["subeventSuffix"] = "_CAST_START",
						["check"] = "event",
						["subeventPrefix"] = "SPELL",
						["names"] = {
						},
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["type"] = "spell",
						["subeventSuffix"] = "_CAST_START",
						["totemNamePattern_operator"] = "find('%s')",
						["totemNamePattern"] = "Windfury",
						["subeventPrefix"] = "SPELL",
						["unit"] = "player",
						["use_unit"] = true,
						["totemName"] = "Disease Cleansing Totem",
						["use_totemNamePattern"] = true,
						["duration"] = "1",
						["event"] = "Totem",
						["unevent"] = "auto",
						["use_totemName"] = false,
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [3]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and trigger[2] and not trigger[3] then return true end\n    return false\nend\n\n",
				["activeTriggerMode"] = 1,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["zoom"] = 0,
			["barColor"] = {
				0.6980392156862745, -- [1]
				0.9450980392156863, -- [2]
				0.9058823529411765, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["preferToUpdate"] = false,
			["version"] = 3,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["type"] = "subborder",
					["border_anchor"] = "bar",
					["border_offset"] = 0,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_size"] = 1,
				}, -- [2]
			},
			["height"] = 6,
			["parent"] = "Shaman Totems",
			["load"] = {
				["ingroup"] = {
					["single"] = "group",
					["multi"] = {
						["group"] = true,
						["raid"] = true,
					},
				},
				["use_never"] = true,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
						["SHAMAN"] = true,
					},
				},
				["use_class"] = true,
				["size"] = {
					["multi"] = {
					},
				},
				["use_alive"] = true,
				["spec"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5080125033855438, -- [4]
			},
			["icon"] = false,
			["iconSource"] = 0,
			["authorOptions"] = {
			},
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["smoothProgress"] = false,
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["config"] = {
			},
			["width"] = 40,
			["icon_side"] = "RIGHT",
			["alpha"] = 1,
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["sparkHidden"] = "NEVER",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["spark"] = false,
			["tocversion"] = 20501,
			["id"] = "Windfury Totem Pulse",
			["auto"] = false,
			["frameStrata"] = 1,
			["anchorFrameType"] = "SCREEN",
			["semver"] = "1.0.2",
			["uid"] = "W2(nYlGpM4n",
			["inverse"] = true,
			["sparkOffsetY"] = 0,
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["selfPoint"] = "CENTER",
		},
		["Earth Totems"] = {
			["iconSource"] = -1,
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["cooldownSwipe"] = true,
			["url"] = "https://wago.io/qIeKQ6u0D/7",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["duration"] = "1",
						["subeventPrefix"] = "SPELL",
						["remaining"] = "0",
						["use_totemType"] = true,
						["debuffType"] = "HELPFUL",
						["use_remaining"] = true,
						["subeventSuffix"] = "_CAST_START",
						["use_unit"] = true,
						["event"] = "Totem",
						["totemType"] = 2,
						["unit"] = "player",
						["use_totemName"] = false,
						["spellIds"] = {
						},
						["type"] = "spell",
						["unevent"] = "auto",
						["remaining_operator"] = ">",
						["names"] = {
						},
						["totemName"] = "Grounding Totem",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["useName"] = true,
						["useGroup_count"] = true,
						["matchesShowOn"] = "showOnMissing",
						["unit"] = "group",
						["group_countOperator"] = ">",
						["auranames"] = {
							"Strength of Earth", -- [1]
							"Stoneskin", -- [2]
						},
						["group_count"] = "1",
						["type"] = "aura2",
						["ownOnly"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [3]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Strength of Earth", -- [1]
						},
						["debuffType"] = "HELPFUL",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [4]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Stoneskin", -- [1]
						},
						["unit"] = "player",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [5]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and not trigger[2] then return true end\n    return false\nend",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 45,
			["keepAspectRatio"] = true,
			["selfPoint"] = "CENTER",
			["desaturate"] = false,
			["version"] = 7,
			["subRegions"] = {
				{
					["border_size"] = 1,
					["border_offset"] = 0,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["type"] = "subborder",
				}, -- [1]
				{
					["text_shadowXOffset"] = 0,
					["text_text"] = "%3.unitCount",
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_selfPoint"] = "AUTO",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["text_text_format_6.unitCount_format"] = "none",
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["rotateText"] = "NONE",
					["text_text_format_p_time_dynamic_threshold"] = 0,
					["text_text_format_3.unitCount_format"] = "none",
					["text_text_format_5.unitCount_format"] = "none",
					["type"] = "subtext",
					["text_text_format_2.unitCount_format"] = "none",
					["text_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["text_font"] = "Naowh",
					["text_anchorYOffset"] = -8,
					["text_shadowYOffset"] = 0,
					["text_visible"] = false,
					["text_wordWrap"] = "WordWrap",
					["text_fontType"] = "OUTLINE",
					["text_anchorPoint"] = "OUTER_TOP",
					["text_text_format_p_time_format"] = 0,
					["text_text_format_p_format"] = "timed",
					["text_fontSize"] = 12,
					["anchorXOffset"] = 0,
					["text_text_format_p_time_precision"] = 1,
				}, -- [2]
				{
					["glowFrequency"] = 0.25,
					["glow"] = false,
					["useGlowColor"] = false,
					["glowType"] = "buttonOverlay",
					["glowLength"] = 10,
					["glowYOffset"] = 0,
					["glowColor"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["type"] = "subglow",
					["glowXOffset"] = 0,
					["glowThickness"] = 1,
					["glowScale"] = 1,
					["glowLines"] = 8,
					["glowBorder"] = false,
				}, -- [3]
			},
			["height"] = 32,
			["load"] = {
				["use_class"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["uid"] = "n2RFmBDzm6N",
			["icon"] = true,
			["animation"] = {
				["start"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["regionType"] = "icon",
			["parent"] = "Shaman Totems",
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["conditions"] = {
				{
					["check"] = {
						["trigger"] = -2,
						["variable"] = "OR",
						["checks"] = {
							{
								["trigger"] = -2,
								["op"] = "find('%s')",
								["variable"] = "AND",
								["checks"] = {
									{
										["value"] = "Strength of Earth Totem",
										["variable"] = "totemName",
										["op"] = "find('%s')",
										["trigger"] = 1,
									}, -- [1]
									{
										["trigger"] = 4,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [1]
							{
								["trigger"] = -2,
								["variable"] = "AND",
								["checks"] = {
									{
										["trigger"] = 1,
										["op"] = "find('%s')",
										["value"] = "Stoneskin Totem",
										["variable"] = "totemName",
									}, -- [1]
									{
										["trigger"] = 5,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [2]
						},
					},
					["changes"] = {
						{
							["value"] = {
								0.1803921568627451, -- [1]
								0.1803921568627451, -- [2]
								0.1803921568627451, -- [3]
								1, -- [4]
							},
							["property"] = "color",
						}, -- [1]
						{
							["value"] = false,
							["property"] = "sub.3.glow",
						}, -- [2]
					},
				}, -- [1]
				{
					["check"] = {
						["trigger"] = 3,
						["variable"] = "show",
						["value"] = 1,
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.2.text_visible",
						}, -- [1]
					},
				}, -- [2]
				{
					["check"] = {
						["trigger"] = -2,
						["variable"] = "AND",
						["op"] = "<",
						["checks"] = {
							{
								["trigger"] = 1,
								["variable"] = "expirationTime",
								["value"] = "5",
								["op"] = "<=",
							}, -- [1]
							{
								["trigger"] = 1,
								["variable"] = "duration",
								["value"] = "60",
								["op"] = ">=",
							}, -- [2]
						},
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.3.glow",
						}, -- [1]
					},
				}, -- [3]
			},
			["xOffset"] = 60,
			["auto"] = true,
			["anchorFrameType"] = "SCREEN",
			["zoom"] = 0.3,
			["semver"] = "1.0.6",
			["tocversion"] = 20501,
			["id"] = "Earth Totems",
			["frameStrata"] = 1,
			["alpha"] = 1,
			["width"] = 40,
			["cooldownTextDisabled"] = false,
			["config"] = {
			},
			["inverse"] = false,
			["cooldownEdge"] = false,
			["displayIcon"] = "136098",
			["cooldown"] = false,
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
		},
		["Fire Totems Bar"] = {
			["sparkWidth"] = 10,
			["sparkOffsetX"] = 0,
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = -18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5, -- [4]
			},
			["triggers"] = {
				{
					["trigger"] = {
						["remaining_operator"] = ">",
						["genericShowOn"] = "showOnCooldown",
						["names"] = {
						},
						["remaining"] = "0",
						["use_totemType"] = true,
						["debuffType"] = "HELPFUL",
						["use_remaining"] = true,
						["subeventSuffix"] = "_CAST_START",
						["spellName"] = 0,
						["event"] = "Totem",
						["totemType"] = 1,
						["realSpellName"] = 0,
						["use_spellName"] = true,
						["spellIds"] = {
						},
						["subeventPrefix"] = "SPELL",
						["unit"] = "player",
						["type"] = "spell",
						["use_track"] = true,
						["use_genericShowOn"] = true,
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [2]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and not trigger[2] then return true end\n    return false\nend",
				["activeTriggerMode"] = -10,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["selfPoint"] = "CENTER",
			["barColor"] = {
				0.03137254901960784, -- [1]
				1, -- [2]
				0.4901960784313725, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["sparkOffsetY"] = 0,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["type"] = "subborder",
					["border_anchor"] = "bar",
					["border_size"] = 1,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_offset"] = 0,
				}, -- [2]
			},
			["height"] = 6,
			["load"] = {
				["use_class"] = true,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["config"] = {
			},
			["parent"] = "Shaman Totems",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["icon"] = false,
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["iconSource"] = -1,
			["xOffset"] = 20,
			["icon_side"] = "RIGHT",
			["zoom"] = 0,
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["sparkHidden"] = "NEVER",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["spark"] = false,
			["tocversion"] = 20501,
			["id"] = "Fire Totems Bar",
			["width"] = 40,
			["alpha"] = 1,
			["anchorFrameType"] = "SCREEN",
			["frameStrata"] = 1,
			["uid"] = "YR1W8bPBbR5",
			["inverse"] = false,
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
			},
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
		},
		["Tremor Totem Pulse"] = {
			["sparkWidth"] = 10,
			["iconSource"] = 0,
			["xOffset"] = 60,
			["adjustedMax"] = "10",
			["adjustedMin"] = "0",
			["yOffset"] = 18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["url"] = "https://wago.io/otyGuo9sL/3",
			["actions"] = {
				["start"] = {
					["do_custom"] = false,
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["debuffType"] = "HELPFUL",
						["type"] = "custom",
						["dynamicDuration"] = false,
						["custom_type"] = "event",
						["unit"] = "player",
						["duration"] = "4",
						["event"] = "Health",
						["subeventPrefix"] = "SPELL",
						["customDuration"] = "function()\n    \n \n        duration = 5\n        return true\n  \n    end",
						["custom"] = "function(event, unit, _, spell_ID)\n    \n    if spell_ID == 8143 and unit == \"player\" and event ~= \"TREMOR_REFIRE_EVENT\" then\n        \n        if aura_env.timer then \n            \n            aura_env.timer:Cancel() \n            aura_env.timer = 0\n        end\n        \n        aura_env.timer = C_Timer.NewTicker(4, function() WeakAuras.ScanEvents(\"TREMOR_REFIRE_EVENT\") end,23)\n        \n        return true\n        \n    elseif  event == \"TREMOR_REFIRE_EVENT\" then\n        \n        return true\n        \n        \n        \n        \n    end\nend",
						["spellIds"] = {
						},
						["subeventSuffix"] = "_CAST_START",
						["check"] = "event",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED:player TREMOR_REFIRE_EVENT",
						["names"] = {
						},
						["custom_hide"] = "timed",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["type"] = "spell",
						["subeventSuffix"] = "_CAST_START",
						["duration"] = "1",
						["event"] = "Totem",
						["totemName"] = "Tremor Totem",
						["use_unit"] = true,
						["unevent"] = "auto",
						["use_totemName"] = true,
						["unit"] = "player",
						["subeventPrefix"] = "SPELL",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["unit"] = "player",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["debuffType"] = "HELPFUL",
						["duration"] = "1.5",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["custom_hide"] = "timed",
					},
					["untrigger"] = {
					},
				}, -- [3]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and trigger[2] and not trigger[3] then return true end\n    return false\nend\n\n",
				["activeTriggerMode"] = 1,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["animation"] = {
				["start"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["zoom"] = 0,
			["barColor"] = {
				0.9372549019607843, -- [1]
				0.8941176470588235, -- [2]
				0.3215686274509804, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["preferToUpdate"] = false,
			["version"] = 3,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["type"] = "subborder",
					["border_anchor"] = "bar",
					["border_offset"] = 0,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_size"] = 1,
				}, -- [2]
			},
			["height"] = 6,
			["parent"] = "Shaman Totems",
			["load"] = {
				["use_class"] = true,
				["ingroup"] = {
					["single"] = "group",
					["multi"] = {
						["group"] = true,
						["raid"] = true,
					},
				},
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
						["SHAMAN"] = true,
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["icon"] = false,
			["selfPoint"] = "CENTER",
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5080125033855438, -- [4]
			},
			["sparkOffsetX"] = 0,
			["config"] = {
			},
			["smoothProgress"] = false,
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["width"] = 40,
			["icon_side"] = "RIGHT",
			["alpha"] = 1,
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["id"] = "Tremor Totem Pulse",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["spark"] = false,
			["tocversion"] = 20501,
			["sparkHidden"] = "NEVER",
			["semver"] = "1.0.2",
			["frameStrata"] = 1,
			["anchorFrameType"] = "SCREEN",
			["auto"] = false,
			["uid"] = "AVjSaXzTG)n",
			["inverse"] = true,
			["authorOptions"] = {
			},
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["sparkOffsetY"] = 0,
		},
		["Duel Timer 1 seconds"] = {
			["wagoID"] = "33gbLewvG",
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["url"] = "https://wago.io/33gbLewvG/1",
			["actions"] = {
				["start"] = {
					["do_glow"] = false,
					["sound"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\swordecho.ogg",
					["do_sound"] = true,
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["use_sourceName"] = false,
						["subeventSuffix"] = "_CAST_START",
						["messageType"] = "CHAT_MSG_SYSTEM",
						["unit"] = "player",
						["message_operator"] = "==",
						["names"] = {
						},
						["message"] = "Duel starting: 1",
						["type"] = "event",
						["spellIds"] = {
						},
						["event"] = "Chat Message",
						["use_message"] = true,
						["subeventPrefix"] = "SPELL",
						["use_messageType"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["animation"] = {
				["start"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["preset"] = "shrink",
					["duration_type"] = "seconds",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["preset"] = "fade",
					["duration_type"] = "seconds",
				},
			},
			["desaturate"] = false,
			["rotation"] = 0,
			["version"] = 1,
			["subRegions"] = {
			},
			["height"] = 100,
			["rotate"] = false,
			["load"] = {
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["mirror"] = false,
			["regionType"] = "texture",
			["blendMode"] = "BLEND",
			["anchorFrameType"] = "SCREEN",
			["texture"] = "Interface\\AddOns\\ArenaCountDown\\Artwork\\1.blp",
			["xOffset"] = 0,
			["discrete_rotation"] = 0,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "Duel Timer 1 seconds",
			["selfPoint"] = "CENTER",
			["frameStrata"] = 2,
			["width"] = 200,
			["alpha"] = 1,
			["config"] = {
			},
			["authorOptions"] = {
			},
			["uid"] = "xmXl8iiWRcE",
			["conditions"] = {
			},
			["information"] = {
			},
			["parent"] = "UI - Duel Count Down",
		},
		["HordeProgressBar"] = {
			["user_y"] = 0,
			["iconSource"] = 0,
			["user_x"] = 0,
			["xOffset"] = 60,
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sameTexture"] = true,
			["url"] = "https://wago.io/NEvswKSI5/39",
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.80000001192093, -- [4]
			},
			["fontFlags"] = "OUTLINE",
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["selfPoint"] = "CENTER",
			["barColor"] = {
				0.54901960784314, -- [1]
				0.086274509803922, -- [2]
				0.086274509803922, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["rotation"] = 0,
			["sparkOffsetY"] = 0,
			["load"] = {
				["use_size"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["difficulty"] = {
					["multi"] = {
					},
				},
				["role"] = {
					["multi"] = {
					},
				},
				["talent3"] = {
					["multi"] = {
					},
				},
				["faction"] = {
					["multi"] = {
					},
				},
				["talent2"] = {
					["multi"] = {
					},
				},
				["ingroup"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["single"] = "pvp",
					["multi"] = {
					},
				},
			},
			["foregroundTexture"] = "Interface\\AddOns\\WeakAuras\\Media\\SpellActivationOverlays\\Eclipse_Sun",
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["blendMode"] = "BLEND",
			["texture"] = "Smooth",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["auto"] = false,
			["tocversion"] = 30300,
			["alpha"] = 1,
			["sparkColor"] = {
				1, -- [1]
				0, -- [2]
				0.68627450980392, -- [3]
				1, -- [4]
			},
			["backgroundOffset"] = 2,
			["borderBackdrop"] = "None",
			["parent"] = "Battleground Widget",
			["customText"] = "function(total, value)    \n    \n    if ( ( aura_env.zone == \"IsleofConquest\" ) \n        or ( aura_env.zone == \"AlteracValley\" ) ) then\n        return value\n    end\n    \n    return (\"%.f / %.f\"):format(value, total)\nend",
			["desaturateBackground"] = false,
			["sparkRotationMode"] = "AUTO",
			["desaturateForeground"] = false,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "custom",
						["debuffType"] = "HELPFUL",
						["subeventSuffix"] = "_CAST_START",
						["event"] = "Health",
						["names"] = {
						},
						["genericShowOn"] = "showOnActive",
						["unit"] = "player",
						["customDuration"] = "function()\n    return aura_env.value, aura_env.total, true      \nend",
						["custom"] = "function(event, ...)\n    return aura_env:OnEvent(event, ...)\nend",
						["spellIds"] = {
						},
						["events"] = "UPDATE_WORLD_STATES CHAT_MSG_BATTLEGROUND CHAT_MSG_BATTLEGROUND_LEADER CHAT_MSG_BG_SYSTEM_NEUTRAL CHAT_MSG_BG_SYSTEM_ALLIANCE CHAT_MSG_BG_SYSTEM_HORDE UPDATE_BATTLEFIELD_SCORE",
						["check"] = "event",
						["subeventPrefix"] = "SPELL",
						["custom_type"] = "status",
						["custom_hide"] = "timed",
					},
					["untrigger"] = {
						["custom"] = "function()\n    return true\nend\n\n\n\n\n\n",
					},
				}, -- [1]
				["activeTriggerMode"] = 1,
			},
			["internalVersion"] = 44,
			["useAdjustedMin"] = false,
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["colorR"] = 1,
					["duration"] = "1",
					["alphaType"] = "straight",
					["colorA"] = 1,
					["colorG"] = 1,
					["alphaFunc"] = "function(progress, start, delta)\n  return start + (progress * delta)\nend",
					["use_translate"] = false,
					["use_alpha"] = false,
					["duration_type"] = "seconds",
					["type"] = "none",
					["scaleType"] = "straightScale",
					["easeType"] = "none",
					["translateFunc"] = "",
					["scaley"] = 1,
					["alpha"] = 0,
					["rotate"] = 0,
					["y"] = 0,
					["x"] = 0,
					["translateType"] = "custom",
					["scaleFunc"] = "    function(progress, startX, startY, scaleX, scaleY)\n      return startX + (progress * (scaleX - startX)), startY + (progress * (scaleY - startY))\n    end\n  ",
					["use_scale"] = false,
					["easeStrength"] = 3,
					["scalex"] = 1,
					["colorB"] = 1,
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["backdropInFront"] = true,
			["version"] = 39,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["text_shadowXOffset"] = 1,
					["text_text"] = "%c",
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_selfPoint"] = "AUTO",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["rotateText"] = "NONE",
					["type"] = "subtext",
					["text_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["text_font"] = "PT Sans Narrow",
					["text_shadowYOffset"] = -1,
					["text_wordWrap"] = "WordWrap",
					["text_fontType"] = "None",
					["text_anchorPoint"] = "INNER_CENTER",
					["text_fontSize"] = 12,
					["anchorXOffset"] = 0,
					["text_visible"] = true,
				}, -- [2]
				{
					["border_size"] = 20,
					["type"] = "subborder",
					["border_anchor"] = "bg",
					["text_color"] = {
					},
					["border_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Blizzard Tooltip",
					["border_offset"] = 5,
				}, -- [3]
			},
			["height"] = 25,
			["crop_y"] = 0.41,
			["sparkBlendMode"] = "ADD",
			["backdropColor"] = {
				[4] = 0,
			},
			["backgroundTexture"] = "Interface\\AddOns\\WeakAuras\\Media\\SpellActivationOverlays\\Eclipse_Sun",
			["desc"] = "Author: RomanSpector\nDiscord: https://discord.com/invite/Fm9kgfk\n",
			["crop_x"] = 0.41,
			["authorOptions"] = {
			},
			["useAdjustedMax"] = false,
			["mirror"] = false,
			["sparkWidth"] = 15,
			["sparkOffsetX"] = 0,
			["borderInFront"] = true,
			["customTextUpdate"] = "event",
			["icon_side"] = "LEFT",
			["actions"] = {
				["start"] = {
					["do_custom"] = false,
					["custom"] = "",
					["sound"] = "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\567474.ogg",
					["do_sound"] = false,
				},
				["finish"] = {
					["custom"] = "",
					["do_custom"] = false,
				},
				["init"] = {
					["custom"] = "local aura_env = aura_env;\nlocal region = aura_env.region;\n\nlocal C_Map = {};\nlocal C_PvP = {};\n\nC_Map[\"ArathiBasin\"] = {\n    progress = 3,\n    index = 2,\n    curr = 4,\n    find = \"(%d+)[^%d]+(%d+)[^%d]+(%d+)\",\n    total = 1600\n};\n\nC_Map[\"AlteracValley\"] = {\n    progress = 3,\n    index = 2,\n    curr = 3,\n    find = \"(%d+)\",\n    total = 600\n};\n\nC_Map[\"IsleofConquest\"] = {\n    progress = 3,\n    index = 2,\n    curr = 3,\n    find = \"(%d+)\",\n    total = 300\n};\n\nC_Map[\"NetherstormArena\"] = {\n    progress = 3,\n    index = 3,\n    curr = 4,\n    find = \"(%d+)[^%d]+(%d+)[^%d]+(%d+)\",\n    total = 1600\n};\n\nC_Map[\"WarsongGulch\"] = {\n    progress = 3,\n    index = 3,\n    curr = 3,\n    find = \"(%d+)[^%d]+(%d+)\",\n    total = 3\n};\n\nfunction C_PvP.IsPvPMap()\n    local inInstance, instanceType = IsInInstance()\n    if ( not inInstance ) then\n        return;\n    end\n    \n    return instanceType == \"pvp\" or instanceType == \"arena\";\nend\n\nfunction aura_env:OnEvent(event, ...)\n    \n    if not C_PvP.IsPvPMap() then\n        return false;\n    end\n    \n    local mapFileName = GetMapInfo();\n    \n    if ( C_Map[mapFileName] ) then\n        RequestBattlefieldScoreData()\n        \n        local number = C_Map[mapFileName]\n        local progress = select(number.progress,GetWorldStateUIInfo(number.index))\n        local curr  = select(number.curr, progress:find(number.find)) \n        \n        aura_env.zone  = mapFileName\n        aura_env.value = tonumber(curr)\n        aura_env.total = number.total\n        \n        return true\n    end\n    \nend\n-----------------------------------------------------------------------------------------------------\n\nlocal frame = WeakAuras.regions[aura_env.id].region;\n\nif ( not frame.texture ) then\n    local texture = CreateFrame(\"Frame\", nil, frame);\n    texture:SetFrameStrata(\"MEDIUM\") ;\n    frame.texture = texture;\n    frame.texture = frame.texture:CreateTexture(nil, \"Texture\");\n    frame.texture:SetTexture([[Interface\\Timer\\Horde-Logo]]);\nend \n\nframe.texture:SetPoint(\"LEFT\", frame, \"RIGHT\", - region:GetHeight() / 1.6, 0);\nframe.texture:SetSize(region:GetHeight() * 2.3, region:GetHeight() * 2.3);\n\n-----------------------------------------------------------------------------------------------------\n\naura_env.value, aura_env.total = math.random(400, 1400), 1600;\n\n\n",
					["do_custom"] = true,
				},
			},
			["anchorFrameType"] = "SCREEN",
			["sparkHeight"] = 60,
			["zoom"] = 0,
			["icon"] = false,
			["id"] = "HordeProgressBar",
			["semver"] = "2.0.0",
			["spark"] = true,
			["sparkHidden"] = "NEVER",
			["useAdjustededMax"] = false,
			["frameStrata"] = 2,
			["width"] = 100,
			["foregroundColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["compress"] = false,
			["inverse"] = false,
			["config"] = {
			},
			["orientation"] = "HORIZONTAL_INVERSE",
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["uid"] = "l1TEBj1iqeR",
		},
		["armor"] = {
			["iconSource"] = -1,
			["xOffset"] = 150,
			["yOffset"] = -39.7222848915286,
			["anchorPoint"] = "CENTER",
			["cooldownEdge"] = false,
			["actions"] = {
				["start"] = {
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "aura2",
						["subeventSuffix"] = "_CAST_START",
						["event"] = "Health",
						["subeventPrefix"] = "SPELL",
						["auranames"] = {
							"Demon Armor", -- [1]
							"Demon Skin", -- [2]
						},
						["spellIds"] = {
						},
						["useName"] = true,
						["useExactSpellId"] = false,
						["names"] = {
						},
						["unit"] = "player",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["use_class"] = true,
						["type"] = "unit",
						["unit"] = "player",
						["use_unit"] = true,
						["class"] = "WARLOCK",
						["event"] = "Health",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [2]
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["keepAspectRatio"] = false,
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["duration_type"] = "seconds",
					["preset"] = "pulse",
					["easeStrength"] = 3,
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["desaturate"] = false,
			["discrete_rotation"] = 0,
			["subRegions"] = {
			},
			["height"] = 80,
			["rotate"] = true,
			["load"] = {
				["size"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["talent"] = {
					["multi"] = {
					},
				},
			},
			["mirror"] = false,
			["regionType"] = "texture",
			["blendMode"] = "BLEND",
			["rotation"] = 0,
			["color"] = {
				0, -- [1]
				1, -- [2]
				0.2901960784313725, -- [3]
				1, -- [4]
			},
			["texture"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura25",
			["cooldown"] = false,
			["zoom"] = 0,
			["icon"] = true,
			["authorOptions"] = {
			},
			["id"] = "armor",
			["width"] = 80,
			["alpha"] = 1,
			["anchorFrameType"] = "SCREEN",
			["config"] = {
			},
			["uid"] = "Q8nYsx3rPxq",
			["inverse"] = false,
			["frameStrata"] = 1,
			["conditions"] = {
			},
			["information"] = {
			},
			["selfPoint"] = "CENTER",
		},
		["bolt"] = {
			["config"] = {
			},
			["desaturate"] = false,
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["load"] = {
				["size"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["talent"] = {
					["multi"] = {
					},
				},
			},
			["mirror"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["xOffset"] = 0,
			["blendMode"] = "BLEND",
			["rotate"] = true,
			["regionType"] = "texture",
			["authorOptions"] = {
			},
			["actions"] = {
				["start"] = {
					["sound"] = "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Blast.ogg",
					["do_sound"] = false,
				},
				["init"] = {
				},
				["finish"] = {
					["sound"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\throwknife.ogg",
					["do_message"] = false,
					["do_sound"] = true,
				},
			},
			["texture"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura3",
			["width"] = 200,
			["internalVersion"] = 44,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "aura2",
						["subeventSuffix"] = "_CAST_START",
						["event"] = "Health",
						["subeventPrefix"] = "SPELL",
						["spellIds"] = {
						},
						["auranames"] = {
							"Shadow Trance", -- [1]
						},
						["useName"] = true,
						["names"] = {
						},
						["unit"] = "player",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["use_class"] = true,
						["type"] = "unit",
						["unit"] = "player",
						["use_unit"] = true,
						["class"] = "WARLOCK",
						["event"] = "Health",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [2]
				["activeTriggerMode"] = -10,
			},
			["selfPoint"] = "CENTER",
			["id"] = "bolt",
			["rotation"] = 0,
			["alpha"] = 0,
			["anchorFrameType"] = "SCREEN",
			["discrete_rotation"] = 0,
			["uid"] = "O3g5Ml1ERAK",
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["subRegions"] = {
			},
			["height"] = 200,
			["conditions"] = {
			},
			["information"] = {
			},
			["frameStrata"] = 1,
		},
		["Water Totems"] = {
			["iconSource"] = -1,
			["xOffset"] = -60,
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["cooldownSwipe"] = true,
			["url"] = "https://wago.io/qIeKQ6u0D/7",
			["icon"] = true,
			["triggers"] = {
				{
					["trigger"] = {
						["remaining_operator"] = ">",
						["unit"] = "player",
						["remaining"] = "0",
						["use_totemType"] = true,
						["debuffType"] = "HELPFUL",
						["use_remaining"] = true,
						["subeventSuffix"] = "_CAST_START",
						["subeventPrefix"] = "SPELL",
						["event"] = "Totem",
						["totemType"] = 3,
						["names"] = {
						},
						["duration"] = "1",
						["spellIds"] = {
						},
						["type"] = "spell",
						["unevent"] = "auto",
						["use_totemName"] = false,
						["use_unit"] = true,
						["totemName"] = "Grounding Totem",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["useName"] = true,
						["useGroup_count"] = true,
						["matchesShowOn"] = "showOnMissing",
						["unit"] = "group",
						["group_countOperator"] = ">",
						["auranames"] = {
							"Mana Spring", -- [1]
							"Healing Stream", -- [2]
							"Fire Resistance", -- [3]
						},
						["group_count"] = "1",
						["type"] = "aura2",
						["ownOnly"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [3]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Mana Spring", -- [1]
						},
						["debuffType"] = "HELPFUL",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [4]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Healing Stream", -- [1]
						},
						["unit"] = "player",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [5]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Fire Resistance", -- [1]
						},
						["debuffType"] = "HELPFUL",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [6]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and not trigger[2] then return true end\n    return false\nend",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 45,
			["keepAspectRatio"] = true,
			["animation"] = {
				["start"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["desaturate"] = false,
			["version"] = 7,
			["subRegions"] = {
				{
					["border_offset"] = 0,
					["type"] = "subborder",
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_size"] = 1,
				}, -- [1]
				{
					["text_text_format_p_time_precision"] = 1,
					["text_text"] = "%3.unitCount",
					["text_text_format_2.unitCount_format"] = "none",
					["text_selfPoint"] = "AUTO",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["text_text_format_5.unitCount_format"] = "none",
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["rotateText"] = "NONE",
					["text_text_format_p_time_dynamic_threshold"] = 0,
					["text_text_format_3.unitCount_format"] = "none",
					["text_text_format_6.unitCount_format"] = "none",
					["type"] = "subtext",
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["text_font"] = "Naowh",
					["text_anchorYOffset"] = -8,
					["text_shadowYOffset"] = 0,
					["text_visible"] = false,
					["text_wordWrap"] = "WordWrap",
					["text_fontType"] = "OUTLINE",
					["text_anchorPoint"] = "OUTER_TOP",
					["text_text_format_p_time_format"] = 0,
					["text_text_format_p_format"] = "timed",
					["text_fontSize"] = 12,
					["anchorXOffset"] = 0,
					["text_shadowXOffset"] = 0,
				}, -- [2]
				{
					["glowFrequency"] = 0.25,
					["glow"] = false,
					["useGlowColor"] = false,
					["glowType"] = "buttonOverlay",
					["glowLength"] = 10,
					["glowYOffset"] = 0,
					["glowColor"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["type"] = "subglow",
					["glowXOffset"] = 0,
					["glowThickness"] = 1,
					["glowScale"] = 1,
					["glowLines"] = 8,
					["glowBorder"] = false,
				}, -- [3]
			},
			["height"] = 32,
			["load"] = {
				["use_class"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["uid"] = "XOFf82wj)ej",
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["regionType"] = "icon",
			["parent"] = "Shaman Totems",
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["conditions"] = {
				{
					["check"] = {
						["trigger"] = -2,
						["variable"] = "OR",
						["checks"] = {
							{
								["trigger"] = -2,
								["op"] = "find('%s')",
								["variable"] = "AND",
								["checks"] = {
									{
										["value"] = "Mana Spring Totem",
										["variable"] = "totemName",
										["op"] = "find('%s')",
										["trigger"] = 1,
									}, -- [1]
									{
										["trigger"] = 4,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [1]
							{
								["trigger"] = -2,
								["variable"] = "AND",
								["checks"] = {
									{
										["trigger"] = 1,
										["op"] = "find('%s')",
										["value"] = "Healing Stream Totem",
										["variable"] = "totemName",
									}, -- [1]
									{
										["trigger"] = 5,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [2]
							{
								["trigger"] = -2,
								["variable"] = "AND",
								["checks"] = {
									{
										["trigger"] = 1,
										["op"] = "find('%s')",
										["variable"] = "totemName",
										["value"] = "Fire Resistance Totem",
									}, -- [1]
									{
										["trigger"] = 6,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [3]
						},
					},
					["changes"] = {
						{
							["value"] = {
								0.1803921568627451, -- [1]
								0.1803921568627451, -- [2]
								0.1803921568627451, -- [3]
								1, -- [4]
							},
							["property"] = "color",
						}, -- [1]
						{
							["value"] = false,
							["property"] = "sub.3.glow",
						}, -- [2]
					},
				}, -- [1]
				{
					["check"] = {
						["trigger"] = 3,
						["variable"] = "show",
						["value"] = 1,
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.2.text_visible",
						}, -- [1]
					},
				}, -- [2]
				{
					["check"] = {
						["trigger"] = -2,
						["variable"] = "AND",
						["checks"] = {
							{
								["trigger"] = 1,
								["op"] = "<=",
								["variable"] = "expirationTime",
								["value"] = "5",
							}, -- [1]
							{
								["trigger"] = 1,
								["variable"] = "duration",
								["value"] = "60",
								["op"] = ">=",
							}, -- [2]
						},
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.3.glow",
						}, -- [1]
					},
				}, -- [3]
			},
			["cooldownEdge"] = false,
			["auto"] = true,
			["width"] = 40,
			["cooldownTextDisabled"] = false,
			["semver"] = "1.0.6",
			["tocversion"] = 20501,
			["id"] = "Water Totems",
			["alpha"] = 1,
			["frameStrata"] = 1,
			["anchorFrameType"] = "SCREEN",
			["zoom"] = 0.3,
			["config"] = {
			},
			["inverse"] = false,
			["selfPoint"] = "CENTER",
			["displayIcon"] = "135127",
			["cooldown"] = false,
			["authorOptions"] = {
			},
		},
		["Shaman Totems"] = {
			["controlledChildren"] = {
				"Totem Range Check", -- [1]
				"Tremor Totem Pulse", -- [2]
				"Magma Totem Pulse", -- [3]
				"Poison Totem Pulse", -- [4]
				"Disease Totem Pulse", -- [5]
				"Windfury Totem Pulse", -- [6]
				"Water Totems Bar", -- [7]
				"Water Totems", -- [8]
				"Air Totems Bar", -- [9]
				"Air Totems", -- [10]
				"Fire Totems Bar", -- [11]
				"Fire Totems", -- [12]
				"Earth Totems Bar", -- [13]
				"Earth Totems", -- [14]
			},
			["borderBackdrop"] = "Blizzard Tooltip",
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["groupIcon"] = 136098,
			["anchorPoint"] = "CENTER",
			["borderColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				1, -- [4]
			},
			["url"] = "https://wago.io/qIeKQ6u0D/7",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["names"] = {
						},
						["type"] = "aura2",
						["spellIds"] = {
						},
						["subeventSuffix"] = "_CAST_START",
						["subeventPrefix"] = "SPELL",
						["unit"] = "player",
						["event"] = "Health",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
			},
			["internalVersion"] = 45,
			["selfPoint"] = "BOTTOMLEFT",
			["version"] = 7,
			["subRegions"] = {
			},
			["load"] = {
				["use_class"] = "true",
				["talent"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["backdropColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				0.5, -- [4]
			},
			["scale"] = 1,
			["border"] = false,
			["borderEdge"] = "1 Pixel",
			["regionType"] = "group",
			["borderSize"] = 2,
			["borderOffset"] = 4,
			["semver"] = "1.0.6",
			["tocversion"] = 20501,
			["id"] = "Shaman Totems",
			["config"] = {
			},
			["frameStrata"] = 1,
			["anchorFrameType"] = "SCREEN",
			["xOffset"] = 0,
			["borderInset"] = 1,
			["uid"] = "BVpLc7V53sK",
			["yOffset"] = -322.7232039476397,
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
				["groupOffset"] = true,
			},
			["animation"] = {
				["start"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
		},
		["Disease Totem Pulse"] = {
			["sparkWidth"] = 10,
			["sparkOffsetX"] = 0,
			["xOffset"] = -60,
			["adjustedMax"] = "10",
			["adjustedMin"] = "0",
			["yOffset"] = 18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["url"] = "https://wago.io/otyGuo9sL/3",
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5080125033855438, -- [4]
			},
			["triggers"] = {
				{
					["trigger"] = {
						["debuffType"] = "HELPFUL",
						["type"] = "custom",
						["dynamicDuration"] = false,
						["custom_type"] = "event",
						["names"] = {
						},
						["duration"] = "5",
						["event"] = "Health",
						["unit"] = "player",
						["customDuration"] = "function()\n    \n \n        duration = 5\n        return true\n  \n    end",
						["custom"] = "function(event, unit, _, spell_ID)\n    \n    if spell_ID == 8170  and unit == \"player\" and event ~= \"DISEASE_REFIRE_EVENT\" then\n        \n        if aura_env.timer then \n            \n            aura_env.timer:Cancel() \n            aura_env.timer = 0\n        end\n        \n        aura_env.timer = C_Timer.NewTicker(5, function() WeakAuras.ScanEvents(\"DISEASE_REFIRE_EVENT\") end,23)\n        \n        return true\n        \n    elseif  event == \"DISEASE_REFIRE_EVENT\" then\n        \n        return true\n        \n        \n    end\nend",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED:player DISEASE_REFIRE_EVENT",
						["subeventSuffix"] = "_CAST_START",
						["check"] = "event",
						["spellIds"] = {
						},
						["subeventPrefix"] = "SPELL",
						["custom_hide"] = "timed",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["type"] = "spell",
						["subeventSuffix"] = "_CAST_START",
						["duration"] = "1",
						["event"] = "Totem",
						["totemName"] = "Disease Cleansing Totem",
						["use_unit"] = true,
						["unevent"] = "auto",
						["use_totemName"] = true,
						["unit"] = "player",
						["subeventPrefix"] = "SPELL",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["unit"] = "player",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["debuffType"] = "HELPFUL",
						["duration"] = "1.5",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["custom_hide"] = "timed",
					},
					["untrigger"] = {
					},
				}, -- [3]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and trigger[2] and not trigger[3] then return true end\n    return false\nend\n\n",
				["activeTriggerMode"] = 1,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["selfPoint"] = "CENTER",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["barColor"] = {
				0.4627450980392157, -- [1]
				0.9450980392156863, -- [2]
				0.04705882352941176, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["preferToUpdate"] = false,
			["sparkOffsetY"] = 0,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["border_offset"] = 0,
					["border_anchor"] = "bar",
					["border_size"] = 1,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["type"] = "subborder",
				}, -- [2]
			},
			["height"] = 6,
			["parent"] = "Shaman Totems",
			["load"] = {
				["use_class"] = true,
				["ingroup"] = {
					["single"] = "group",
					["multi"] = {
						["group"] = true,
						["raid"] = true,
					},
				},
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
						["SHAMAN"] = true,
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["version"] = 3,
			["actions"] = {
				["start"] = {
					["do_custom"] = false,
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["iconSource"] = 0,
			["authorOptions"] = {
			},
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["smoothProgress"] = false,
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["config"] = {
			},
			["width"] = 40,
			["icon_side"] = "RIGHT",
			["frameStrata"] = 1,
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["id"] = "Disease Totem Pulse",
			["zoom"] = 0,
			["spark"] = false,
			["tocversion"] = 20501,
			["sparkHidden"] = "NEVER",
			["semver"] = "1.0.2",
			["alpha"] = 1,
			["anchorFrameType"] = "SCREEN",
			["auto"] = false,
			["uid"] = "0eXj51wQTi2",
			["inverse"] = true,
			["icon"] = false,
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["animation"] = {
				["start"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
		},
		["Earth Totems Bar"] = {
			["sparkWidth"] = 10,
			["sparkOffsetX"] = 0,
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = -18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5, -- [4]
			},
			["triggers"] = {
				{
					["trigger"] = {
						["use_genericShowOn"] = true,
						["genericShowOn"] = "showOnCooldown",
						["names"] = {
						},
						["remaining"] = "0",
						["use_totemType"] = true,
						["debuffType"] = "HELPFUL",
						["type"] = "spell",
						["subeventSuffix"] = "_CAST_START",
						["remaining_operator"] = ">",
						["event"] = "Totem",
						["totemType"] = 2,
						["realSpellName"] = 0,
						["use_spellName"] = true,
						["spellIds"] = {
						},
						["use_remaining"] = true,
						["subeventPrefix"] = "SPELL",
						["unit"] = "player",
						["use_track"] = true,
						["spellName"] = 0,
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend\n",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [2]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and not trigger[2] then return true end\n    return false\nend",
				["activeTriggerMode"] = -10,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["selfPoint"] = "CENTER",
			["barColor"] = {
				0.03137254901960784, -- [1]
				1, -- [2]
				0.4901960784313725, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["sparkOffsetY"] = 0,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["border_offset"] = 0,
					["border_anchor"] = "bar",
					["type"] = "subborder",
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_size"] = 1,
				}, -- [2]
			},
			["height"] = 6,
			["load"] = {
				["use_class"] = true,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["uid"] = "5jlvHM1MTcR",
			["parent"] = "Shaman Totems",
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["icon"] = false,
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["xOffset"] = 60,
			["iconSource"] = -1,
			["icon_side"] = "RIGHT",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["id"] = "Earth Totems Bar",
			["zoom"] = 0,
			["spark"] = false,
			["tocversion"] = 20501,
			["sparkHidden"] = "NEVER",
			["anchorFrameType"] = "SCREEN",
			["frameStrata"] = 1,
			["width"] = 40,
			["alpha"] = 1,
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["inverse"] = false,
			["config"] = {
			},
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
			},
			["actions"] = {
				["start"] = {
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
		},
		["AllianceProgressBar"] = {
			["user_y"] = 0,
			["iconSource"] = 0,
			["user_x"] = 0,
			["xOffset"] = -60,
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["foregroundColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["sparkRotation"] = 0,
			["sameTexture"] = true,
			["url"] = "https://wago.io/NEvswKSI5/39",
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.80000001192093, -- [4]
			},
			["fontFlags"] = "OUTLINE",
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["selfPoint"] = "CENTER",
			["barColor"] = {
				0.086274509803922, -- [1]
				0.17254901960784, -- [2]
				0.34117647058824, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["rotation"] = 0,
			["sparkOffsetY"] = 0,
			["crop_y"] = 0.41,
			["foregroundTexture"] = "Interface\\AddOns\\WeakAuras\\Media\\SpellActivationOverlays\\Eclipse_Sun",
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["blendMode"] = "BLEND",
			["sparkDesaturate"] = false,
			["texture"] = "Smooth",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["auto"] = false,
			["tocversion"] = 30300,
			["alpha"] = 1,
			["sparkColor"] = {
				0, -- [1]
				0.74509803921569, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["backgroundOffset"] = 2,
			["borderBackdrop"] = "None",
			["parent"] = "Battleground Widget",
			["customText"] = "function(total, value)    \n    \n    if ( ( aura_env.zone == \"IsleofConquest\" ) \n        or ( aura_env.zone == \"AlteracValley\" ) ) then\n        return value\n    end\n    \n    return (\"%.f / %.f\"):format(value, total)\nend",
			["desaturateBackground"] = false,
			["sparkRotationMode"] = "AUTO",
			["desaturateForeground"] = false,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "custom",
						["debuffType"] = "HELPFUL",
						["subeventSuffix"] = "_CAST_START",
						["event"] = "Health",
						["names"] = {
						},
						["genericShowOn"] = "showOnActive",
						["unit"] = "player",
						["customDuration"] = "function()    \n    return aura_env.value, aura_env.total, true      \nend",
						["custom"] = "function(event, ...)\n    return aura_env:OnEvent(event, ...)\nend",
						["spellIds"] = {
						},
						["events"] = "UPDATE_WORLD_STATES CHAT_MSG_BATTLEGROUND CHAT_MSG_BATTLEGROUND_LEADER CHAT_MSG_BG_SYSTEM_NEUTRAL CHAT_MSG_BG_SYSTEM_ALLIANCE CHAT_MSG_BG_SYSTEM_HORDE UPDATE_BATTLEFIELD_SCORE",
						["check"] = "event",
						["subeventPrefix"] = "SPELL",
						["custom_type"] = "status",
						["custom_hide"] = "timed",
					},
					["untrigger"] = {
						["custom"] = "function()\n    return true\nend\n\n\n\n\n\n",
					},
				}, -- [1]
				["activeTriggerMode"] = 1,
			},
			["internalVersion"] = 44,
			["useAdjustedMin"] = false,
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["colorR"] = 1,
					["duration"] = "1",
					["alphaType"] = "straight",
					["colorA"] = 1,
					["colorG"] = 1,
					["alphaFunc"] = "function(progress, start, delta)\n  return start + (progress * delta)\nend",
					["use_translate"] = false,
					["use_alpha"] = false,
					["duration_type"] = "seconds",
					["type"] = "none",
					["scaleType"] = "straightScale",
					["easeType"] = "none",
					["translateFunc"] = "",
					["scaley"] = 1,
					["alpha"] = 0,
					["rotate"] = 0,
					["y"] = 0,
					["x"] = 0,
					["translateType"] = "custom",
					["scaleFunc"] = "    function(progress, startX, startY, scaleX, scaleY)\n      return startX + (progress * (scaleX - startX)), startY + (progress * (scaleY - startY))\n    end\n  ",
					["use_scale"] = false,
					["easeStrength"] = 3,
					["scalex"] = 1,
					["colorB"] = 1,
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["backdropInFront"] = true,
			["version"] = 39,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["text_shadowXOffset"] = 1,
					["text_text"] = "%c",
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_selfPoint"] = "AUTO",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["rotateText"] = "NONE",
					["type"] = "subtext",
					["text_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["text_font"] = "PT Sans Narrow",
					["text_shadowYOffset"] = -1,
					["text_wordWrap"] = "WordWrap",
					["text_fontType"] = "None",
					["text_anchorPoint"] = "INNER_CENTER",
					["text_fontSize"] = 12,
					["anchorXOffset"] = 0,
					["text_visible"] = true,
				}, -- [2]
				{
					["border_size"] = 20,
					["type"] = "subborder",
					["border_anchor"] = "bg",
					["text_color"] = {
					},
					["border_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Blizzard Tooltip",
					["border_offset"] = 5,
				}, -- [3]
			},
			["height"] = 25,
			["desc"] = "Author: RomanSpector\nDiscord: https://discord.com/invite/Fm9kgfk\n",
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["backgroundTexture"] = "Interface\\AddOns\\WeakAuras\\Media\\SpellActivationOverlays\\Eclipse_Sun",
			["sparkWidth"] = 15,
			["conditions"] = {
			},
			["customTextUpdate"] = "event",
			["useAdjustedMax"] = false,
			["mirror"] = false,
			["config"] = {
			},
			["actions"] = {
				["start"] = {
					["custom"] = "WorldStateAlwaysUpFrame:Hide()",
					["do_custom"] = true,
				},
				["finish"] = {
					["custom"] = "WorldStateAlwaysUpFrame:Show()",
					["do_custom"] = true,
				},
				["init"] = {
					["custom"] = "local aura_env = aura_env;\nlocal region = aura_env.region;\n\nlocal C_Map = {};\nlocal C_PvP = {};\n\nC_Map[\"ArathiBasin\"] = {\n    progress = 3,\n    index = 1, \n    curr = 4,\n    find = \"(%d+)[^%d]+(%d+)[^%d]+(%d+)\",\n    total = 1600\n};\n\nC_Map[\"AlteracValley\"] = {\n    progress = 3,\n    index = 1,\n    curr = 3,\n    find = \"(%d+)\",\n    total = 600\n};\n\nC_Map[\"IsleofConquest\"] = {\n    progress = 3,\n    index = 1,\n    curr = 3,\n    find = \"(%d+)\",\n    total = 300\n};\n\nC_Map[\"NetherstormArena\"] = {\n    progress = 3,\n    index = 2,\n    curr = 4,\n    find = \"(%d+)[^%d]+(%d+)[^%d]+(%d+)\",\n    total = 1600\n};\n\nC_Map[\"WarsongGulch\"] = {\n    progress = 3,\n    index = 2,\n    curr = 3,\n    find = \"(%d+)[^%d]+(%d+)\",\n    total = 3\n};\n\nfunction C_PvP.IsPvPMap()\n    local inInstance, instanceType = IsInInstance()\n    if ( not inInstance ) then\n        return;\n    end\n    \n    return instanceType == \"pvp\" or instanceType == \"arena\";\nend\n\nfunction aura_env:OnEvent(event, ...)\n    \n    if ( not C_PvP.IsPvPMap() ) then\n        return false;\n    end\n    \n    local mapFileName = GetMapInfo();\n    \n    if ( C_Map[mapFileName] ) then\n        RequestBattlefieldScoreData()\n        \n        local number = C_Map[mapFileName]\n        local progress = select(number.progress,GetWorldStateUIInfo(number.index))\n        local curr  = select(number.curr, progress:find(number.find)) \n        \n        aura_env.zone  = mapFileName\n        aura_env.value = tonumber(curr)\n        aura_env.total = number.total\n        \n        return true\n    end\n    \nend\n-----------------------------------------------------------------------------------------------------\n\nlocal frame = WeakAuras.regions[aura_env.id].region;\n\nif ( not frame.texture ) then\n    local texture = CreateFrame(\"Frame\", nil, frame);\n    texture:SetFrameStrata(\"MEDIUM\") ;\n    frame.texture = texture;\n    frame.texture = frame.texture:CreateTexture(nil, \"Texture\");\n    frame.texture:SetTexture([[Interface\\Timer\\Alliance-Logo]]);\nend \n\nframe.texture:SetPoint(\"RIGHT\", frame, \"LEFT\", region:GetHeight() / 1.6, 0);\nframe.texture:SetSize(region:GetHeight() * 2.3, region:GetHeight() * 2.3);\n\n-----------------------------------------------------------------------------------------------------\n\naura_env.value, aura_env.total = math.random(400, 1400), 1600;",
					["do_custom"] = true,
				},
			},
			["borderInFront"] = true,
			["sparkOffsetX"] = 0,
			["icon_side"] = "RIGHT",
			["anchorPoint"] = "CENTER",
			["width"] = 100,
			["sparkHeight"] = 60,
			["zoom"] = 0,
			["icon"] = false,
			["id"] = "AllianceProgressBar",
			["semver"] = "2.0.0",
			["backdropColor"] = {
				[4] = 0,
			},
			["sparkHidden"] = "NEVER",
			["compress"] = false,
			["frameStrata"] = 2,
			["anchorFrameType"] = "SCREEN",
			["load"] = {
				["use_size"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["difficulty"] = {
					["multi"] = {
					},
				},
				["role"] = {
					["multi"] = {
					},
				},
				["talent3"] = {
					["multi"] = {
					},
				},
				["faction"] = {
					["multi"] = {
					},
				},
				["talent2"] = {
					["multi"] = {
					},
				},
				["ingroup"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["single"] = "pvp",
					["multi"] = {
					},
				},
			},
			["uid"] = "BzfZ6IjnWwh",
			["inverse"] = false,
			["spark"] = true,
			["orientation"] = "HORIZONTAL",
			["crop_x"] = 0.41,
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["authorOptions"] = {
			},
		},
		["PointIsCaptured"] = {
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["url"] = "https://wago.io/NEvswKSI5/39",
			["actions"] = {
				["start"] = {
					["custom"] = "aura_env.region.texture:SetTexCoord(unpack(aura_env.state.coord))",
					["do_custom"] = false,
				},
				["finish"] = {
				},
				["init"] = {
					["custom"] = "local WorldMap_GetPOITextureCoords = WorldMap_GetPOITextureCoords;\nlocal GetNumMapLandmarks, GetMapLandmarkInfo = GetNumMapLandmarks, GetMapLandmarkInfo;\nlocal GetLocale, GetMapInfo = GetLocale, GetMapInfo;\nlocal PointIsCaptured, WeakAuras = aura_env, WeakAuras;\n\nlocal L = {};\n\nif ( GetLocale() == \"ruRU\" ) then\n    L[\"captures\"] = \"захватывает\";\n    L[\"returned\"] = \"возвращен\";\n    L[\"dropped\"]  = \"уронили\";\nelse\n    L[\"captures\"] = \"captures\";\n    L[\"returned\"] = \"returned\";\n    L[\"dropped\"]  = \"dropped\";\nend\n\nlocal C_Map = {};\nC_Map[\"NetherstormArena\"] = {};\nC_Map[\"ArathiBasin\"] = {};\nC_Map.IsBattleground = function()\n    return C_Map[GetMapInfo()];\nend\n\nC_Map[\"NetherstormArena\"].Object = {\n    [10] = {\"horde\", \"captured\"}, \n    [11] = {\"alliance\", \"captured\"},\n};\n\nC_Map[\"ArathiBasin\"].Object = {\n    [17] = {\"alliance\", \"attack\"},   [19] = {\"horde\", \"attack\"},\n    [22] = {\"alliance\", \"attack\"},   [24] = {\"horde\", \"attack\"}, \n    [27] = {\"alliance\", \"attack\"},   [29] = {\"horde\", \"attack\"},\n    [32] = {\"alliance\", \"attack\"},   [34] = {\"horde\", \"attack\"}, \n    [37] = {\"alliance\", \"attack\"},   [39] = {\"horde\", \"attack\"},\n    \n    [18] = {\"alliance\", \"captured\"},  [20] = {\"horde\", \"captured\"},\n    [23] = {\"alliance\", \"captured\"},  [25] = {\"horde\", \"captured\"}, \n    [28] = {\"alliance\", \"captured\"},  [30] = {\"horde\", \"captured\"}, \n    [33] = {\"alliance\", \"captured\"},  [35] = {\"horde\", \"captured\"}, \n    [38] = {\"alliance\", \"captured\"},  [40] = {\"horde\", \"captured\"},\n};\n\nC_Map.GetObject = function(index)\n    if ( C_Map[GetMapInfo()] )  then\n        local index = C_Map[GetMapInfo()].Object[index];\n        return index and index[1], index and index[2];\n    end\nend\n\nPointIsCaptured.roster = PointIsCaptured.roster or {};\n\nfunction PointIsCaptured:GetFactionStatusBar(faction)\n    if ( faction == \"alliance\" ) then\n        return \"AllianceProgressBar\";\n    else\n        return \"HordeProgressBar\";\n    end\nend\n\nfunction PointIsCaptured:CreateTexture(allstates, index)\n    local data = self.roster[index]\n    if ( not data ) then \n        return;\n    end\n    \n    allstates[index] = {\n        show = true,\n        changed = true,\n        autoHide = false,\n        progressType = \"static\",\n        --custom\n        texture = \"Interface\\\\Minimap\\\\POIIcons\",\n        status = data.status,\n        name = data.name,\n        index = index,\n        coord = data.coord,\n        frameID = data.frameID\n    };\nend\n\nfunction PointIsCaptured:CreateFrame(allstates)\n    for index, data in pairs(self.roster) do\n        self:CreateTexture(allstates, index);\n    end\nend\n\nfunction PointIsCaptured:RemoveDB(allstates, index)\n    local state = allstates[index];\n    if ( not state ) then\n        return;\n    end\n    \n    state.show = false;\n    state.changed = true;\nend\n\nfunction PointIsCaptured:CheckFlagStatus(allstates, event, ...)\n    local msg = ...  or \"\";\n    local update = false;\n    if ( ( event == \"CHAT_MSG_BG_SYSTEM_ALLIANCE\" or event == \"CHAT_MSG_BG_SYSTEM_HORDE\" ) \n        and (msg):match(L[\"captures\"]) ) then \n        local index, textureIndex = 6, 45;\n        local name = \"Flag\";\n        local a, b, c, d = WorldMap_GetPOITextureCoords(textureIndex);\n        local faction = event == \"CHAT_MSG_BG_SYSTEM_ALLIANCE\" and \"alliance\" or \"horde\";\n        self.roster[index] = {\n            textureIndex = textureIndex, \n            index = index,\n            coord = {a,b,c,d},\n            name = name,\n            status = \"neutral\",   \n            frameID = self:GetFactionStatusBar(faction),\n        };\n        self:CreateTexture(allstates, index);\n        self:scheduleUpdateFrames(allstates, 0.02);\n        update = true;\n    elseif ( (msg):match(L[\"returned\"]) or (msg):match(L[\"dropped\"]) ) then\n        local state = allstates[6];\n        if ( state ) then\n            state.show = false;\n            state.changed = true;\n            self.roster[6] = nil;\n            self:scheduleUpdateFrames(allstates, 0.02);\n            update = true;\n        end\n    end\n    return update;\nend\n\nfunction PointIsCaptured:InitNeweBase(allstates, ...)\n    local update = false;\n    if ( GetMapInfo() == \"NetherstormArena\" ) then\n        update = self:CheckFlagStatus(allstates, ...);\n    end\n    \n    for index, data in pairs(self.roster) do\n        if ( index ~= 6 ) then \n            if ( data.textureIndex ~= select(3, GetMapLandmarkInfo(index)) ) then\n                self:RemoveDB(allstates, index);\n                self.roster[index] = nil;\n                update = true;\n                self:scheduleUpdateFrames(allstates, 0.02);\n            end\n        end\n    end\n    \n    for index = 1, GetNumMapLandmarks() do\n        local name, _, textureIndex = GetMapLandmarkInfo(index);\n        local textureIndex = select(3, GetMapLandmarkInfo(index));\n        if ( name and textureIndex ) then \n            local faction, status = C_Map.GetObject(textureIndex);\n            local a,b,c,d = WorldMap_GetPOITextureCoords(textureIndex);\n            if ( status and not self.roster[index] ) then\n                self.roster[index] = {\n                    textureIndex = textureIndex, \n                    index = index,\n                    coord = {a,b,c,d},\n                    name = name,\n                    status = status,\n                    frameID = self:GetFactionStatusBar(faction)\n                };\n                \n                self:CreateTexture(allstates, index);\n                update = true;\n                self:scheduleUpdateFrames(allstates, 0.02);\n            end\n        end \n    end\n    return update;\nend\n\nfunction PointIsCaptured:ClearAllStates(allstates) \n    for _, state in pairs(allstates) do\n        state.show = false;\n        state.changed = true;\n    end\n    self.roster = {};\nend\n\nPointIsCaptured.TestObject = {\n    [17] = {\"alliance\", \"attack\"},   \n    [22] = {\"alliance\", \"captured\"}, \n    [28] = {\"alliance\", \"captured\"},  \n    \n    [35] = {\"horde\", \"attack\"},\n    [40] = {\"horde\", \"captured\"},\n};\n\nfunction PointIsCaptured:CreateTestFrames(allstates)\n    for textureIndex in pairs(self.TestObject) do\n        local faction = self.TestObject[textureIndex][1];\n        local a,b,c,d = WorldMap_GetPOITextureCoords(textureIndex);\n        self.roster[textureIndex] = {\n            textureIndex = textureIndex, \n            coord = {a,b,c,d},\n            faction = faction,\n            frameID = self:GetFactionStatusBar(faction)\n        };\n        self:CreateTexture(allstates, textureIndex);\n    end\nend\n\nfunction PointIsCaptured:OnEvent(allstates, event, ...) \n    if ( event == \"OPTIONS\" ) then\n        self:CreateTestFrames(allstates);\n        self:scheduleUpdateFrames(allstates, 0.02);\n    end\n    \n    if ( not C_Map.IsBattleground() ) then \n        return;\n    end\n    \n    if ( event == \"ZONE_CHANGED_NEW_AREA\" ) then\n        self:ClearAllStates(allstates);\n        self:InitNeweBase(allstates, event, ...);\n        self:CreateFrame(allstates);\n        return true;\n        \n    elseif ( event == \"PLAYER_ENTERING_WORLD\" ) then \n        self:InitNeweBase(allstates, event, ...);\n        self:CreateFrame(allstates);\n        return true;\n        \n    else\n        return self:InitNeweBase(allstates, event, ...);\n    end\nend\n\nPointIsCaptured.auraCount = {};\nPointIsCaptured.xOffset = 0;\nPointIsCaptured.yOffset = -10;\n\nlocal function setIconPosition(self, state, rowIdx)\n    local region = WeakAuras.GetRegion(self.id, state.index);\n    local f = WeakAuras.GetRegion(state.frameID);\n    local positionFrom, positionTo;\n    if ( f and region ) then\n        self.auraCount[state.index] = self.auraCount[state.index] or {};\n        self.auraCount[state.index].rowIdx = self.auraCount[state.index].rowIdx or 0;\n        \n        local xoffset, yoffset = 0, 0;\n        local height, width = region:GetHeight() + 2, region:GetWidth() + 2;\n        \n        if ( state.frameID == \"AllianceProgressBar\" ) then\n            xoffset = xoffset - (rowIdx - 1) * height;\n            positionFrom, positionTo = \"TOPRIGHT\", \"BOTTOMRIGHT\";\n        elseif ( state.frameID == \"HordeProgressBar\" ) then\n            xoffset = xoffset + (rowIdx - 1) * height;\n            positionFrom, positionTo = \"TOPLEFT\", \"BOTTOMLEFT\";\n        end\n        \n        region:SetAnchor(positionFrom, f, positionTo);\n        region:SetOffset(xoffset + self.xOffset, yoffset + self.yOffset);\n        region.texture:SetTexCoord(unpack(state.coord)) ;\n        self.auraCount[state.index].rowIdx = self.auraCount[state.index].rowIdx + 1;\n    end\nend\n\nfunction PointIsCaptured:updateFrames(allstates)\n    table.wipe(self.auraCount)\n    for index, indexData in pairs(self.roster) do  \n        local rowIdxA = 0    \n        local rowIdxH = 0    \n        for _, state in pairs(allstates) do\n            if state.show and state.frameID == \"AllianceProgressBar\" then\n                rowIdxA = rowIdxA + 1\n                setIconPosition(self, state, rowIdxA)\n            elseif state.show and state.frameID == \"HordeProgressBar\" then\n                rowIdxH = rowIdxH+ 1\n                setIconPosition(self, state, rowIdxH)\n            end                           \n        end            \n    end\nend\n\nlocal timer;\nfunction PointIsCaptured:scheduleUpdateFrames(allstates, duration)\n    if timer then WeakAuras.timer:CancelTimer(timer) end\n    timer = WeakAuras.timer:ScheduleTimer(function()\n            self:updateFrames(allstates) end, \n        duration\n    )\nend",
					["do_custom"] = true,
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "custom",
						["subeventSuffix"] = "_CAST_START",
						["debuffType"] = "HELPFUL",
						["event"] = "Health",
						["unit"] = "player",
						["custom_type"] = "stateupdate",
						["events"] = "ZONE_CHANGED_NEW_AREA PLAYER_ENTERING_WORLD CHAT_MSG_BATTLEGROUND CHAT_MSG_BATTLEGROUND_LEADER CHAT_MSG_BG_SYSTEM_NEUTRAL CHAT_MSG_BG_SYSTEM_ALLIANCE CHAT_MSG_BG_SYSTEM_HORDE UPDATE_BATTLEFIELD_SCORE",
						["custom"] = "function(...)\n    return aura_env:OnEvent(...)\nend",
						["names"] = {
						},
						["check"] = "event",
						["spellIds"] = {
						},
						["subeventPrefix"] = "SPELL",
						["customVariables"] = "{\n    texIndx = 'number',\n    status = {\n        display = \"Status\",\n        type = \"select\",\n        values = {\n            [\"attack\"] = \"Attacked\", \n            [\"captured\"] = \"Captured\", \n        }\n    }\n}",
					},
					["untrigger"] = {
					},
				}, -- [1]
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["colorR"] = 1,
					["use_scale"] = false,
					["colorB"] = 1,
					["colorG"] = 1,
					["scalex"] = 1,
					["use_translate"] = false,
					["translateType"] = "straightTranslate",
					["rotate"] = 0,
					["type"] = "none",
					["use_color"] = false,
					["easeType"] = "none",
					["translateFunc"] = "function(progress, startX, startY, deltaX, deltaY)\n    return startX + (progress * deltaX), startY + (progress * deltaY)\nend\n",
					["scaley"] = 1,
					["alpha"] = 0,
					["scaleType"] = "straightScale",
					["y"] = 0,
					["x"] = 0,
					["scaleFunc"] = "function(progress, startX, startY, scaleX, scaleY)\n    return startX + (progress * (scaleX - startX)), startY + (progress * (scaleY - startY))\nend\n",
					["colorType"] = "straightColor",
					["colorFunc"] = "function(progress, r1, g1, b1, a1, r2, g2, b2, a2)\n    return r1 + (progress * (r2 - r1)), g1 + (progress * (g2 - g1)), b1 + (progress * (b2 - b1)), a1 + (progress * (a2 - a1))\nend\n",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["colorA"] = 1,
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["desaturate"] = false,
			["rotation"] = 0,
			["version"] = 39,
			["subRegions"] = {
			},
			["height"] = 18,
			["rotate"] = true,
			["load"] = {
				["use_size"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["single"] = "pvp",
					["multi"] = {
					},
				},
			},
			["mirror"] = false,
			["regionType"] = "texture",
			["blendMode"] = "BLEND",
			["parent"] = "Battleground Widget",
			["desc"] = "Author: RomanSpector\nDiscord: https://discord.com/invite/Fm9kgfk\n\n",
			["texture"] = "Interface\\ICONS\\Achievement_BG_DefendXtowers_AV",
			["selfPoint"] = "CENTER",
			["xOffset"] = 0,
			["semver"] = "2.0.0",
			["tocversion"] = 30300,
			["id"] = "PointIsCaptured",
			["authorOptions"] = {
			},
			["frameStrata"] = 1,
			["width"] = 18,
			["uid"] = "pzKfttOqwyz",
			["config"] = {
			},
			["alpha"] = 1,
			["anchorFrameType"] = "SCREEN",
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["discrete_rotation"] = 0,
		},
		["Duel Timer 3 seconds"] = {
			["wagoID"] = "33gbLewvG",
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["url"] = "https://wago.io/33gbLewvG/1",
			["actions"] = {
				["start"] = {
					["do_glow"] = false,
					["sound"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\swordecho.ogg",
					["do_sound"] = true,
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["use_sourceName"] = false,
						["subeventSuffix"] = "_CAST_START",
						["messageType"] = "CHAT_MSG_SYSTEM",
						["unit"] = "player",
						["message_operator"] = "==",
						["names"] = {
						},
						["message"] = "Duel starting: 3",
						["type"] = "event",
						["spellIds"] = {
						},
						["event"] = "Chat Message",
						["use_message"] = true,
						["subeventPrefix"] = "SPELL",
						["use_messageType"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["animation"] = {
				["start"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["preset"] = "shrink",
					["duration_type"] = "seconds",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["preset"] = "fade",
					["duration_type"] = "seconds",
				},
			},
			["desaturate"] = false,
			["rotation"] = 0,
			["version"] = 1,
			["subRegions"] = {
			},
			["height"] = 100,
			["rotate"] = false,
			["load"] = {
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["mirror"] = false,
			["regionType"] = "texture",
			["blendMode"] = "BLEND",
			["anchorFrameType"] = "SCREEN",
			["texture"] = "Interface\\AddOns\\ArenaCountDown\\Artwork\\3.blp",
			["xOffset"] = 0,
			["discrete_rotation"] = 0,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "Duel Timer 3 seconds",
			["selfPoint"] = "CENTER",
			["frameStrata"] = 2,
			["width"] = 200,
			["alpha"] = 1,
			["config"] = {
			},
			["authorOptions"] = {
			},
			["uid"] = "8HawinKM9Zb",
			["conditions"] = {
			},
			["information"] = {
			},
			["parent"] = "UI - Duel Count Down",
		},
		["Duel Timer 2 seconds"] = {
			["wagoID"] = "33gbLewvG",
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["url"] = "https://wago.io/33gbLewvG/1",
			["actions"] = {
				["start"] = {
					["do_glow"] = false,
					["sound"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\swordecho.ogg",
					["do_sound"] = true,
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["use_sourceName"] = false,
						["subeventSuffix"] = "_CAST_START",
						["messageType"] = "CHAT_MSG_SYSTEM",
						["unit"] = "player",
						["message_operator"] = "==",
						["names"] = {
						},
						["message"] = "Duel starting: 2",
						["type"] = "event",
						["spellIds"] = {
						},
						["event"] = "Chat Message",
						["use_message"] = true,
						["subeventPrefix"] = "SPELL",
						["use_messageType"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["animation"] = {
				["start"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["preset"] = "shrink",
					["duration_type"] = "seconds",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["preset"] = "fade",
					["duration_type"] = "seconds",
				},
			},
			["desaturate"] = false,
			["rotation"] = 0,
			["version"] = 1,
			["subRegions"] = {
			},
			["height"] = 100,
			["rotate"] = false,
			["load"] = {
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["mirror"] = false,
			["regionType"] = "texture",
			["blendMode"] = "BLEND",
			["anchorFrameType"] = "SCREEN",
			["texture"] = "Interface\\AddOns\\ArenaCountDown\\Artwork\\2.blp",
			["xOffset"] = 0,
			["discrete_rotation"] = 0,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "Duel Timer 2 seconds",
			["selfPoint"] = "CENTER",
			["frameStrata"] = 2,
			["width"] = 200,
			["alpha"] = 1,
			["config"] = {
			},
			["authorOptions"] = {
			},
			["uid"] = "S3XnVnjlDvQ",
			["conditions"] = {
			},
			["information"] = {
			},
			["parent"] = "UI - Duel Count Down",
		},
		["Fire Totems"] = {
			["iconSource"] = -1,
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["cooldownSwipe"] = true,
			["url"] = "https://wago.io/qIeKQ6u0D/7",
			["icon"] = true,
			["triggers"] = {
				{
					["trigger"] = {
						["duration"] = "1",
						["unit"] = "player",
						["remaining"] = "0",
						["use_totemType"] = true,
						["debuffType"] = "HELPFUL",
						["use_remaining"] = true,
						["subeventSuffix"] = "_CAST_START",
						["totemType"] = 1,
						["event"] = "Totem",
						["totemName"] = "Grounding Totem",
						["subeventPrefix"] = "SPELL",
						["use_totemName"] = false,
						["spellIds"] = {
						},
						["type"] = "spell",
						["unevent"] = "auto",
						["remaining_operator"] = ">",
						["names"] = {
						},
						["use_unit"] = true,
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["custom_type"] = "event",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["useName"] = true,
						["useGroup_count"] = true,
						["matchesShowOn"] = "showOnMissing",
						["unit"] = "group",
						["group_countOperator"] = ">",
						["auranames"] = {
							"Totem of Wrath", -- [1]
							"Frost Resistance", -- [2]
						},
						["group_count"] = "1",
						["type"] = "aura2",
						["ownOnly"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [3]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Totem of Wrath", -- [1]
						},
						["unit"] = "player",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [4]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Frost Resistance", -- [1]
						},
						["debuffType"] = "HELPFUL",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [5]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and not trigger[2] then return true end\n    return false\nend",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 45,
			["keepAspectRatio"] = true,
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["desaturate"] = false,
			["version"] = 7,
			["subRegions"] = {
				{
					["type"] = "subborder",
					["border_size"] = 1,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_offset"] = 0,
				}, -- [1]
				{
					["text_text_format_p_time_format"] = 0,
					["text_text"] = "%3.unitCount",
					["text_text_format_6.unitCount_format"] = "none",
					["text_selfPoint"] = "AUTO",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["text_text_format_5.unitCount_format"] = "none",
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["rotateText"] = "NONE",
					["anchorXOffset"] = 0,
					["text_text_format_2.unitCount_format"] = "none",
					["text_shadowXOffset"] = 0,
					["type"] = "subtext",
					["text_text_format_p_time_precision"] = 1,
					["text_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["text_font"] = "Naowh",
					["text_anchorYOffset"] = -8,
					["text_shadowYOffset"] = 0,
					["text_fontType"] = "OUTLINE",
					["text_wordWrap"] = "WordWrap",
					["text_visible"] = false,
					["text_anchorPoint"] = "OUTER_TOP",
					["text_text_format_p_format"] = "timed",
					["text_text_format_3.unitCount_format"] = "none",
					["text_fontSize"] = 12,
					["text_text_format_p_time_dynamic_threshold"] = 0,
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
				}, -- [2]
				{
					["glowFrequency"] = 0.25,
					["type"] = "subglow",
					["useGlowColor"] = false,
					["glowType"] = "buttonOverlay",
					["glowLength"] = 10,
					["glowYOffset"] = 0,
					["glowColor"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["glow"] = false,
					["glowXOffset"] = 0,
					["glowScale"] = 1,
					["glowThickness"] = 1,
					["glowLines"] = 8,
					["glowBorder"] = false,
				}, -- [3]
			},
			["height"] = 32,
			["load"] = {
				["use_class"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
			},
			["config"] = {
			},
			["cooldownEdge"] = false,
			["selfPoint"] = "CENTER",
			["regionType"] = "icon",
			["parent"] = "Shaman Totems",
			["cooldown"] = false,
			["displayIcon"] = "135825",
			["xOffset"] = 20,
			["auto"] = true,
			["anchorFrameType"] = "SCREEN",
			["cooldownTextDisabled"] = false,
			["semver"] = "1.0.6",
			["tocversion"] = 20501,
			["id"] = "Fire Totems",
			["frameStrata"] = 1,
			["alpha"] = 1,
			["width"] = 40,
			["zoom"] = 0.3,
			["uid"] = "P0ayQvk0KKG",
			["inverse"] = false,
			["actions"] = {
				["start"] = {
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["conditions"] = {
				{
					["check"] = {
						["trigger"] = -2,
						["variable"] = "OR",
						["checks"] = {
							{
								["trigger"] = -2,
								["op"] = "find('%s')",
								["variable"] = "AND",
								["checks"] = {
									{
										["value"] = "Totem of Wrath",
										["variable"] = "totemName",
										["trigger"] = 1,
										["op"] = "find('%s')",
									}, -- [1]
									{
										["trigger"] = 4,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [1]
							{
								["trigger"] = -2,
								["variable"] = "AND",
								["checks"] = {
									{
										["trigger"] = 1,
										["op"] = "find('%s')",
										["variable"] = "totemName",
										["value"] = "Frost Resistance Totem",
									}, -- [1]
									{
										["trigger"] = 5,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [2]
						},
					},
					["changes"] = {
						{
							["value"] = {
								0.1803921568627451, -- [1]
								0.1803921568627451, -- [2]
								0.1803921568627451, -- [3]
								1, -- [4]
							},
							["property"] = "color",
						}, -- [1]
						{
							["value"] = false,
							["property"] = "sub.3.glow",
						}, -- [2]
					},
				}, -- [1]
				{
					["check"] = {
						["trigger"] = 3,
						["variable"] = "show",
						["value"] = 1,
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.2.text_visible",
						}, -- [1]
					},
				}, -- [2]
				{
					["check"] = {
						["trigger"] = -2,
						["variable"] = "AND",
						["checks"] = {
							{
								["trigger"] = 1,
								["variable"] = "expirationTime",
								["value"] = "5",
								["op"] = "<=",
							}, -- [1]
							{
								["trigger"] = 1,
								["variable"] = "duration",
								["value"] = "60",
								["op"] = ">=",
							}, -- [2]
						},
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.3.glow",
						}, -- [1]
					},
				}, -- [3]
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
		},
		["stone"] = {
			["config"] = {
			},
			["selfPoint"] = "CENTER",
			["xOffset"] = 0,
			["load"] = {
				["size"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["talent"] = {
					["multi"] = {
					},
				},
			},
			["mirror"] = false,
			["yOffset"] = -182,
			["regionType"] = "texture",
			["color"] = {
				0, -- [1]
				0.5882352941176471, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["blendMode"] = "BLEND",
			["rotate"] = true,
			["anchorPoint"] = "CENTER",
			["authorOptions"] = {
			},
			["actions"] = {
				["start"] = {
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["enchant"] = "Grand Spellstone",
						["itemName"] = 0,
						["use_genericShowOn"] = true,
						["genericShowOn"] = "showOnCooldown",
						["unit"] = "player",
						["use_weapon"] = true,
						["debuffType"] = "HELPFUL",
						["type"] = "item",
						["subeventSuffix"] = "_CAST_START",
						["use_showOn"] = true,
						["use_itemName"] = true,
						["use_enchant"] = true,
						["spellIds"] = {
						},
						["names"] = {
						},
						["showOn"] = "showOnMissing",
						["event"] = "Weapon Enchant",
						["subeventPrefix"] = "SPELL",
						["weapon"] = "main",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["use_class"] = true,
						["type"] = "unit",
						["unit"] = "player",
						["use_unit"] = true,
						["class"] = "WARLOCK",
						["event"] = "Health",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [2]
				["disjunctive"] = "all",
				["activeTriggerMode"] = -10,
			},
			["anchorFrameType"] = "SCREEN",
			["internalVersion"] = 44,
			["texture"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura51",
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["id"] = "stone",
			["discrete_rotation"] = 0,
			["frameStrata"] = 1,
			["width"] = 100,
			["rotation"] = 36,
			["uid"] = "UiSFBQEiJUB",
			["desaturate"] = false,
			["subRegions"] = {
			},
			["height"] = 100,
			["conditions"] = {
			},
			["information"] = {
			},
			["alpha"] = 1,
		},
		["AllianceFlag"] = {
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "BOTTOM",
			["url"] = "https://wago.io/NEvswKSI5/39",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
					["custom"] = "local aura_env = aura_env;\nlocal region = aura_env.region;\n\nif ( not region.background ) then\n    region.background = region:CreateTexture(nil, \"BACKGROUND\");\nend\nregion.background:SetTexture([[Interface\\WorldStateFrame\\HordeFlagFlash]]);\nregion.background:SetBlendMode(\"ADD\");\nregion.background:ClearAllPoints();\nregion.background:SetPoint(\"CENTER\", region, \"CENTER\");\nregion.background:SetSize(region:GetWidth()*0.75 , region:GetHeight()*0.75);\n\naura_env.BGcolor = {};\n\nfor key, value in pairs(aura_env.config[\"color\"]) do\n    aura_env.BGcolor[key] = value;\nend",
					["do_custom"] = true,
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "custom",
						["subeventSuffix"] = "_CAST_START",
						["names"] = {
						},
						["event"] = "Health",
						["unit"] = "player",
						["subeventPrefix"] = "SPELL",
						["custom_type"] = "status",
						["spellIds"] = {
						},
						["customTexture"] = "function()   \n    return [[Interface\\WorldStateFrame\\AllianceFlag]] \nend",
						["check"] = "event",
						["events"] = "UPDATE_WORLD_STATES CHAT_MSG_BATTLEGROUND CHAT_MSG_BATTLEGROUND_LEADER CHAT_MSG_BG_SYSTEM_NEUTRAL CHAT_MSG_BG_SYSTEM_ALLIANCE CHAT_MSG_BG_SYSTEM_HORDE UPDATE_BATTLEFIELD_SCOREUPDATE_WORLD_STATES CHAT_MSG_BATTLEGROUND CHAT_MSG_BATTLEGROUND_LEADER CHAT_MSG_BG_SYSTEM_NEUTRAL CHAT_MSG_BG_SYSTEM_ALLIANCE CHAT_MSG_BG_SYSTEM_HORDE UPDATE_BATTLEFIELD_SCORE",
						["custom"] = "function(event, ...)\n    if not ( GetMapInfo() == \"WarsongGulch\" ) then return end\n    return select(2, GetWorldStateUIInfo(3)) == 2 \nend",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
						["custom"] = "function()\n    return true\nend",
					},
				}, -- [1]
				["disjunctive"] = "any",
				["customTriggerLogic"] = "function(trigger)\n    return trigger[1] \nend",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["colorR"] = 1,
					["duration"] = "1",
					["alphaType"] = "custom",
					["colorB"] = 1,
					["colorG"] = 1,
					["alphaFunc"] = "function(progress, start, delta)\n    local angle = (progress * 2 * math.pi) - (math.pi / 2);\n    local alpha = start + (((math.sin(angle) + 1)/2) * delta);\n    aura_env.region.background:SetVertexColor(aura_env.BGcolor[1], aura_env.BGcolor[2], aura_env.BGcolor[3], alpha);\n    return start;\nend",
					["use_alpha"] = true,
					["type"] = "custom",
					["duration_type"] = "seconds",
					["easeType"] = "none",
					["scaley"] = 1,
					["use_color"] = false,
					["alpha"] = 0,
					["rotate"] = 0,
					["y"] = 0,
					["x"] = 0,
					["preset"] = "pulse",
					["colorA"] = 1,
					["colorFunc"] = "function(progress, r1, g1, b1, a1, r2, g2, b2, a2)\n    local angle = (progress * 2 * math.pi) - (math.pi / 2)\n    local alpha = 1 + (((math.sin(angle) + 1)/2) * 0.5)\n    WeakAuras.regions[aura_env.id].region.background:SetVertexColor(1, 1, 1, alpha)\n    return r1, g1, b1, a1\nend\n\n\n\n",
					["easeStrength"] = 3,
					["colorType"] = "custom",
					["scalex"] = 1,
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["desaturate"] = false,
			["discrete_rotation"] = 0,
			["version"] = 39,
			["subRegions"] = {
			},
			["height"] = 50,
			["rotate"] = true,
			["load"] = {
				["use_size"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["single"] = "pvp",
					["multi"] = {
						["pvp"] = true,
					},
				},
			},
			["mirror"] = false,
			["anchorFrameFrame"] = "WeakAuras:HordeProgressBar",
			["regionType"] = "texture",
			["blendMode"] = "BLEND",
			["parent"] = "Battleground Widget",
			["rotation"] = 0,
			["anchorFrameParent"] = false,
			["texture"] = "Interface\\WorldStateFrame\\AllianceFlag",
			["selfPoint"] = "TOP",
			["xOffset"] = 0,
			["semver"] = "2.0.0",
			["tocversion"] = 30300,
			["id"] = "AllianceFlag",
			["anchorFrameType"] = "SELECTFRAME",
			["frameStrata"] = 4,
			["width"] = 50,
			["desc"] = "Author: RomanSpector\nDiscord: https://discord.com/invite/Fm9kgfk\n",
			["config"] = {
				["color"] = {
					0.21176470588235, -- [1]
					0.78039215686275, -- [2]
					1, -- [3]
					1, -- [4]
				},
			},
			["uid"] = "0pfDqSK9IuM",
			["alpha"] = 1,
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["authorOptions"] = {
				{
					["type"] = "color",
					["key"] = "color",
					["default"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["name"] = "Цвет фона флага",
					["useDesc"] = false,
					["width"] = 1,
				}, -- [1]
			},
		},
		["HordeFlag"] = {
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "BOTTOM",
			["url"] = "https://wago.io/NEvswKSI5/39",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
					["custom"] = "local aura_env = aura_env;\nlocal region = aura_env.region;\n\nif ( not region.background ) then\n    region.background = region:CreateTexture(nil, \"BACKGROUND\");\nend\nregion.background:SetTexture([[Interface\\WorldStateFrame\\HordeFlagFlash]]);\nregion.background:SetBlendMode(\"ADD\");\nregion.background:ClearAllPoints();\nregion.background:SetPoint(\"CENTER\", region, \"CENTER\");\nregion.background:SetSize(region:GetWidth()*0.75 , region:GetHeight()*0.75);\n\naura_env.BGcolor = {};\n\nfor key, value in pairs(aura_env.config[\"color\"]) do\n    aura_env.BGcolor[key] = value;\nend",
					["do_custom"] = true,
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "custom",
						["subeventSuffix"] = "_CAST_START",
						["names"] = {
						},
						["event"] = "Health",
						["unit"] = "player",
						["subeventPrefix"] = "SPELL",
						["custom_type"] = "status",
						["spellIds"] = {
						},
						["customTexture"] = "function()   \n    return [[Interface\\WorldStateFrame\\HordeFlag]] \nend",
						["check"] = "event",
						["events"] = "UPDATE_WORLD_STATES CHAT_MSG_BATTLEGROUND CHAT_MSG_BATTLEGROUND_LEADER CHAT_MSG_BG_SYSTEM_NEUTRAL CHAT_MSG_BG_SYSTEM_ALLIANCE CHAT_MSG_BG_SYSTEM_HORDE UPDATE_BATTLEFIELD_SCORE",
						["custom"] = "function(event, ...)\n    if not ( GetMapInfo() == \"WarsongGulch\" ) then return end\n    return select(2, GetWorldStateUIInfo(2)) == 2 \nend",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
						["custom"] = "function()\n    return true\nend",
					},
				}, -- [1]
				["disjunctive"] = "any",
				["customTriggerLogic"] = "function(trigger)\n    return trigger[1] \nend",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["colorR"] = 1,
					["duration"] = "1",
					["alphaType"] = "custom",
					["colorB"] = 1,
					["colorG"] = 1,
					["alphaFunc"] = "function(progress, start, delta)\n    local angle = (progress * 2 * math.pi) - (math.pi / 2);\n    local alpha = start + (((math.sin(angle) + 1)/2) * delta);\n    aura_env.region.background:SetVertexColor(aura_env.BGcolor[1], aura_env.BGcolor[2], aura_env.BGcolor[3], alpha);\n    return start;\nend",
					["use_alpha"] = true,
					["type"] = "custom",
					["duration_type"] = "seconds",
					["easeType"] = "none",
					["scaley"] = 1,
					["use_color"] = false,
					["alpha"] = 0,
					["rotate"] = 0,
					["y"] = 0,
					["x"] = 0,
					["preset"] = "pulse",
					["colorA"] = 1,
					["colorFunc"] = "function(progress, r1, g1, b1, a1, r2, g2, b2, a2)\n    local angle = (progress * 2 * math.pi) - (math.pi / 2)\n    local alpha = 1 + (((math.sin(angle) + 1)/2) * 0.5)\n    WeakAuras.regions[aura_env.id].region.background:SetVertexColor(1, 1, 1, alpha)\n    return r1, g1, b1, a1\nend\n\n\n\n",
					["easeStrength"] = 3,
					["colorType"] = "custom",
					["scalex"] = 1,
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["desaturate"] = false,
			["discrete_rotation"] = 0,
			["version"] = 39,
			["subRegions"] = {
			},
			["height"] = 50,
			["rotate"] = true,
			["load"] = {
				["use_size"] = true,
				["talent"] = {
					["multi"] = {
					},
				},
				["use_zone"] = false,
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["single"] = "pvp",
					["multi"] = {
						["pvp"] = true,
					},
				},
			},
			["mirror"] = false,
			["anchorFrameFrame"] = "WeakAuras:AllianceProgressBar",
			["regionType"] = "texture",
			["blendMode"] = "BLEND",
			["parent"] = "Battleground Widget",
			["rotation"] = 0,
			["anchorFrameParent"] = false,
			["texture"] = "Interface\\WorldStateFrame\\HordeFlag",
			["selfPoint"] = "TOP",
			["xOffset"] = 0,
			["semver"] = "2.0.0",
			["tocversion"] = 30300,
			["id"] = "HordeFlag",
			["anchorFrameType"] = "SELECTFRAME",
			["frameStrata"] = 4,
			["width"] = 50,
			["desc"] = "Author: RomanSpector\nDiscord: https://discord.com/invite/Fm9kgfk\n",
			["config"] = {
				["color"] = {
					1, -- [1]
					0.5529411764705901, -- [2]
					0, -- [3]
					1, -- [4]
				},
			},
			["uid"] = "8x5(4W69qAm",
			["alpha"] = 1,
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["authorOptions"] = {
				{
					["type"] = "color",
					["key"] = "color",
					["default"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["name"] = "Цвет фона флага",
					["useDesc"] = false,
					["width"] = 1,
				}, -- [1]
			},
		},
		["Tremor Totem Killed"] = {
			["outline"] = "OUTLINE",
			["iconSource"] = 0,
			["wagoID"] = "c8f3zaNzo",
			["xOffset"] = 2.221923828125,
			["displayText"] = "Tremor Down",
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["displayText_format_1.spellName_format"] = "none",
			["cooldownSwipe"] = true,
			["customTextUpdate"] = "update",
			["cooldownEdge"] = false,
			["actions"] = {
				["start"] = {
					["sound"] = "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Shotgun.ogg",
					["do_sound"] = false,
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["use_amount"] = true,
						["duration"] = "2",
						["names"] = {
						},
						["amount"] = "5",
						["use_destName"] = true,
						["use_cloneId"] = true,
						["debuffType"] = "HELPFUL",
						["type"] = "combatlog",
						["destFlags"] = "Mine",
						["subeventSuffix"] = "_DAMAGE",
						["event"] = "Combat Log",
						["amount_operator"] = ">=",
						["spellIds"] = {
						},
						["destName"] = "Tremor Totem",
						["subeventPrefix"] = "SPELL",
						["unevent"] = "timed",
						["unit"] = "player",
						["use_destFlags"] = true,
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["use_amount"] = true,
						["duration"] = "2",
						["names"] = {
						},
						["amount"] = "5",
						["use_destName"] = true,
						["use_cloneId"] = true,
						["debuffType"] = "HELPFUL",
						["type"] = "combatlog",
						["destFlags"] = "Mine",
						["subeventSuffix"] = "_DAMAGE",
						["event"] = "Combat Log",
						["amount_operator"] = ">=",
						["spellIds"] = {
						},
						["destName"] = "Tremor Totem",
						["subeventPrefix"] = "RANGE",
						["unevent"] = "timed",
						["unit"] = "player",
						["use_destFlags"] = true,
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["use_amount"] = true,
						["duration"] = "2",
						["names"] = {
						},
						["amount"] = "5",
						["use_destName"] = true,
						["use_cloneId"] = true,
						["debuffType"] = "HELPFUL",
						["type"] = "combatlog",
						["destFlags"] = "Mine",
						["subeventSuffix"] = "_DAMAGE",
						["event"] = "Combat Log",
						["amount_operator"] = ">=",
						["spellIds"] = {
						},
						["destName"] = "Tremor Totem",
						["subeventPrefix"] = "SWING",
						["unevent"] = "timed",
						["unit"] = "player",
						["use_destFlags"] = true,
					},
					["untrigger"] = {
					},
				}, -- [3]
				["disjunctive"] = "any",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 45,
			["keepAspectRatio"] = false,
			["selfPoint"] = "BOTTOM",
			["desaturate"] = false,
			["icon"] = true,
			["font"] = "Naowh",
			["version"] = 1,
			["subRegions"] = {
			},
			["height"] = 64,
			["shadowYOffset"] = -1,
			["load"] = {
				["talent"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
						["SHAMAN"] = true,
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
			},
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["fontSize"] = 15,
			["cooldown"] = false,
			["conditions"] = {
			},
			["shadowXOffset"] = 1,
			["preferToUpdate"] = false,
			["url"] = "",
			["authorOptions"] = {
			},
			["regionType"] = "text",
			["uid"] = "uFEsyN4nGIc",
			["wordWrap"] = "WordWrap",
			["anchorFrameType"] = "SCREEN",
			["alpha"] = 1,
			["zoom"] = 0.2,
			["justify"] = "LEFT",
			["cooldownTextDisabled"] = false,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "Tremor Totem Killed",
			["animation"] = {
				["start"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["preset"] = "fade",
				},
				["main"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["preset"] = "fade",
				},
			},
			["frameStrata"] = 1,
			["width"] = 64,
			["parent"] = "UI - Shaman Notifications",
			["config"] = {
			},
			["inverse"] = false,
			["fixedWidth"] = 200,
			["shadowColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				1, -- [4]
			},
			["displayIcon"] = 136039,
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["automaticWidth"] = "Auto",
		},
		["armor missing"] = {
			["config"] = {
			},
			["selfPoint"] = "CENTER",
			["authorOptions"] = {
			},
			["information"] = {
			},
			["mirror"] = false,
			["yOffset"] = -180,
			["anchorPoint"] = "CENTER",
			["xOffset"] = 0,
			["blendMode"] = "BLEND",
			["rotate"] = true,
			["regionType"] = "texture",
			["color"] = {
				0, -- [1]
				1, -- [2]
				0.3294117647058824, -- [3]
				1, -- [4]
			},
			["actions"] = {
				["start"] = {
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["texture"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura21",
			["anchorFrameType"] = "SCREEN",
			["internalVersion"] = 44,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "aura2",
						["subeventSuffix"] = "_CAST_START",
						["matchesShowOn"] = "showOnMissing",
						["event"] = "Health",
						["subeventPrefix"] = "SPELL",
						["spellIds"] = {
						},
						["auranames"] = {
							"Fel Armor", -- [1]
							"Demon Armor", -- [2]
							"Demon Skin", -- [3]
						},
						["useName"] = true,
						["names"] = {
						},
						["unit"] = "player",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["use_class"] = true,
						["type"] = "unit",
						["unit"] = "player",
						["use_unit"] = true,
						["class"] = "WARLOCK",
						["event"] = "Health",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["debuffType"] = "HELPFUL",
						["type"] = "unit",
						["percenthealth_operator"] = ">",
						["percenthealth"] = "0",
						["use_unit"] = true,
						["use_percenthealth"] = true,
						["event"] = "Health",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [3]
				["activeTriggerMode"] = -10,
			},
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["id"] = "armor missing",
			["rotation"] = 0,
			["frameStrata"] = 1,
			["width"] = 200,
			["discrete_rotation"] = 0,
			["uid"] = "BMqNNHhX6yA",
			["desaturate"] = false,
			["subRegions"] = {
			},
			["height"] = 200,
			["conditions"] = {
			},
			["load"] = {
				["size"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["talent"] = {
					["multi"] = {
					},
				},
			},
			["alpha"] = 1,
		},
		["Water Totems Bar"] = {
			["sparkWidth"] = 10,
			["sparkOffsetX"] = 0,
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = -18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5, -- [4]
			},
			["triggers"] = {
				{
					["trigger"] = {
						["remaining_operator"] = ">",
						["genericShowOn"] = "showOnCooldown",
						["names"] = {
						},
						["remaining"] = "0",
						["use_totemType"] = true,
						["debuffType"] = "HELPFUL",
						["use_remaining"] = true,
						["subeventSuffix"] = "_CAST_START",
						["use_genericShowOn"] = true,
						["event"] = "Totem",
						["totemType"] = 3,
						["realSpellName"] = 0,
						["use_spellName"] = true,
						["spellIds"] = {
						},
						["subeventPrefix"] = "SPELL",
						["type"] = "spell",
						["unit"] = "player",
						["use_track"] = true,
						["spellName"] = 0,
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [2]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and not trigger[2] then return true end\n    return false\nend",
				["activeTriggerMode"] = -10,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["barColor"] = {
				0.03137254901960784, -- [1]
				1, -- [2]
				0.4901960784313725, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["sparkOffsetY"] = 0,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["border_size"] = 1,
					["border_anchor"] = "bar",
					["border_offset"] = 0,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["type"] = "subborder",
				}, -- [2]
			},
			["height"] = 6,
			["load"] = {
				["use_class"] = true,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["config"] = {
			},
			["parent"] = "Shaman Totems",
			["selfPoint"] = "CENTER",
			["actions"] = {
				["start"] = {
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["xOffset"] = -60,
			["iconSource"] = -1,
			["icon_side"] = "RIGHT",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["sparkHidden"] = "NEVER",
			["zoom"] = 0,
			["spark"] = false,
			["tocversion"] = 20501,
			["id"] = "Water Totems Bar",
			["anchorFrameType"] = "SCREEN",
			["alpha"] = 1,
			["width"] = 40,
			["frameStrata"] = 1,
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["inverse"] = false,
			["uid"] = "vxCJkxNKZm4",
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
			},
			["icon"] = false,
		},
		["UI - Shaman Notifications"] = {
			["grow"] = "DOWN",
			["controlledChildren"] = {
				"Grounding Totem 2", -- [1]
				"Tremor Totem Killed", -- [2]
				"Poison Totem Killed", -- [3]
			},
			["borderBackdrop"] = "Blizzard Tooltip",
			["wagoID"] = "c8f3zaNzo",
			["xOffset"] = 0,
			["preferToUpdate"] = false,
			["yOffset"] = 300,
			["anchorPoint"] = "CENTER",
			["borderColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				1, -- [4]
			},
			["space"] = 2,
			["url"] = "",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["debuffType"] = "HELPFUL",
						["type"] = "aura2",
						["spellIds"] = {
						},
						["subeventSuffix"] = "_CAST_START",
						["subeventPrefix"] = "SPELL",
						["unit"] = "player",
						["event"] = "Health",
						["names"] = {
						},
					},
					["untrigger"] = {
					},
				}, -- [1]
			},
			["columnSpace"] = 1,
			["radius"] = 200,
			["useLimit"] = false,
			["align"] = "CENTER",
			["stagger"] = 0,
			["version"] = 1,
			["subRegions"] = {
			},
			["arcLength"] = 360,
			["uid"] = "HyI9Y89tVSs",
			["load"] = {
				["use_class"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
			},
			["groupIcon"] = 136039,
			["backdropColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				0.5, -- [4]
			},
			["borderInset"] = 1,
			["animate"] = false,
			["rotation"] = 0,
			["scale"] = 1,
			["fullCircle"] = true,
			["border"] = false,
			["borderEdge"] = "Square Full White",
			["regionType"] = "dynamicgroup",
			["borderSize"] = 2,
			["sort"] = "none",
			["authorOptions"] = {
			},
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["constantFactor"] = "RADIUS",
			["internalVersion"] = 45,
			["borderOffset"] = 4,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "UI - Shaman Notifications",
			["gridWidth"] = 5,
			["frameStrata"] = 1,
			["anchorFrameType"] = "SCREEN",
			["gridType"] = "RD",
			["config"] = {
			},
			["selfPoint"] = "TOP",
			["limit"] = 5,
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["rowSpace"] = 1,
		},
		["Poison Totem Killed"] = {
			["outline"] = "OUTLINE",
			["iconSource"] = 0,
			["wagoID"] = "c8f3zaNzo",
			["xOffset"] = 2.221923828125,
			["displayText"] = "Cleansing Down\n",
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["displayText_format_1.spellName_format"] = "none",
			["cooldownSwipe"] = true,
			["customTextUpdate"] = "update",
			["cooldownEdge"] = false,
			["actions"] = {
				["start"] = {
					["sound"] = "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Shotgun.ogg",
					["do_sound"] = false,
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["use_amount"] = true,
						["duration"] = "2",
						["names"] = {
						},
						["amount"] = "5",
						["use_destName"] = true,
						["use_cloneId"] = true,
						["debuffType"] = "HELPFUL",
						["type"] = "combatlog",
						["destFlags"] = "Mine",
						["subeventSuffix"] = "_DAMAGE",
						["event"] = "Combat Log",
						["amount_operator"] = ">=",
						["spellIds"] = {
						},
						["destName"] = "Poison Cleansing Totem",
						["subeventPrefix"] = "SPELL",
						["unevent"] = "timed",
						["unit"] = "player",
						["use_destFlags"] = true,
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["use_amount"] = true,
						["duration"] = "2",
						["names"] = {
						},
						["amount"] = "5",
						["use_destName"] = true,
						["use_cloneId"] = true,
						["debuffType"] = "HELPFUL",
						["type"] = "combatlog",
						["destFlags"] = "Mine",
						["subeventSuffix"] = "_DAMAGE",
						["event"] = "Combat Log",
						["amount_operator"] = ">=",
						["spellIds"] = {
						},
						["destName"] = "Poison Cleansing Totem",
						["subeventPrefix"] = "RANGE",
						["unevent"] = "timed",
						["unit"] = "player",
						["use_destFlags"] = true,
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["use_amount"] = true,
						["duration"] = "2",
						["names"] = {
						},
						["amount"] = "5",
						["use_destName"] = true,
						["use_cloneId"] = true,
						["debuffType"] = "HELPFUL",
						["type"] = "combatlog",
						["destFlags"] = "Mine",
						["subeventSuffix"] = "_DAMAGE",
						["event"] = "Combat Log",
						["amount_operator"] = ">=",
						["spellIds"] = {
						},
						["destName"] = "Poison Cleansing Totem",
						["subeventPrefix"] = "SWING",
						["unevent"] = "timed",
						["unit"] = "player",
						["use_destFlags"] = true,
					},
					["untrigger"] = {
					},
				}, -- [3]
				["disjunctive"] = "any",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 45,
			["keepAspectRatio"] = false,
			["selfPoint"] = "BOTTOM",
			["desaturate"] = false,
			["icon"] = true,
			["font"] = "Naowh",
			["version"] = 1,
			["subRegions"] = {
			},
			["height"] = 64,
			["shadowYOffset"] = -1,
			["load"] = {
				["talent"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
						["SHAMAN"] = true,
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
			},
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["fontSize"] = 15,
			["cooldown"] = false,
			["conditions"] = {
			},
			["shadowXOffset"] = 1,
			["preferToUpdate"] = false,
			["url"] = "",
			["authorOptions"] = {
			},
			["regionType"] = "text",
			["uid"] = "bnPBmPMpb28",
			["wordWrap"] = "WordWrap",
			["anchorFrameType"] = "SCREEN",
			["alpha"] = 1,
			["zoom"] = 0.2,
			["justify"] = "LEFT",
			["cooldownTextDisabled"] = false,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "Poison Totem Killed",
			["animation"] = {
				["start"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["preset"] = "fade",
				},
				["main"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["preset"] = "fade",
				},
			},
			["frameStrata"] = 1,
			["width"] = 64,
			["parent"] = "UI - Shaman Notifications",
			["config"] = {
			},
			["inverse"] = false,
			["fixedWidth"] = 200,
			["shadowColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				1, -- [4]
			},
			["displayIcon"] = 136039,
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["automaticWidth"] = "Auto",
		},
		["fin"] = {
			["outline"] = "OUTLINE",
			["iconSource"] = 0,
			["xOffset"] = 150,
			["displayText_format_p_time_dynamic_threshold"] = 60,
			["shadowYOffset"] = -1,
			["anchorPoint"] = "CENTER",
			["displayText_format_p_time_format"] = 0,
			["customTextUpdate"] = "event",
			["automaticWidth"] = "Auto",
			["icon"] = true,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "unit",
						["use_health"] = false,
						["subeventSuffix"] = "_CAST_START",
						["names"] = {
						},
						["percenthealth"] = "25",
						["event"] = "Health",
						["unit"] = "target",
						["use_class"] = false,
						["subeventPrefix"] = "SPELL",
						["spellIds"] = {
						},
						["health_operator"] = "<=",
						["use_unit"] = true,
						["use_percenthealth"] = true,
						["percenthealth_operator"] = "<=",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["use_class"] = true,
						["type"] = "unit",
						["unit"] = "player",
						["use_unit"] = true,
						["class"] = "WARLOCK",
						["event"] = "Health",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [2]
				["activeTriggerMode"] = -10,
			},
			["displayText_format_p_format"] = "timed",
			["internalVersion"] = 44,
			["keepAspectRatio"] = false,
			["selfPoint"] = "CENTER",
			["desaturate"] = false,
			["discrete_rotation"] = 0,
			["font"] = "Friz Quadrata TT",
			["anchorFrameType"] = "SCREEN",
			["subRegions"] = {
				{
					["text_shadowXOffset"] = 1,
					["text_text"] = "%1.percenthealth%%",
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_selfPoint"] = "AUTO",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["text_text_format_1.percenthealth_abbreviate_max"] = 8,
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["text_text_format_n_format"] = "none",
					["text_text_format_1.percenthealth_format"] = "Number",
					["text_text_format_1.percenthealth_abbreviate"] = false,
					["text_text_format_1.percenthealth_color"] = true,
					["type"] = "subtext",
					["text_anchorXOffset"] = 4,
					["text_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_font"] = "Designosaur Italic (GladiusEx)",
					["text_shadowYOffset"] = -1,
					["text_anchorYOffset"] = -2,
					["text_fontType"] = "None",
					["text_wordWrap"] = "WordWrap",
					["text_visible"] = true,
					["text_anchorPoint"] = "CENTER",
					["text_text_format_1.percenthealth_realm_name"] = "never",
					["text_text_format_1.percenthealth_decimal_precision"] = 0,
					["text_fontSize"] = 25,
					["anchorXOffset"] = 0,
					["text_text_format_1.percenthealth_round_type"] = "floor",
				}, -- [1]
			},
			["height"] = 128,
			["rotate"] = true,
			["load"] = {
				["size"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["talent"] = {
					["multi"] = {
					},
				},
			},
			["animation"] = {
				["start"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["duration_type"] = "seconds",
					["preset"] = "grow",
					["easeStrength"] = 3,
				},
				["main"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["duration_type"] = "seconds",
					["preset"] = "pulse",
					["easeStrength"] = 3,
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["fontSize"] = 45,
			["cooldown"] = false,
			["fixedWidth"] = 200,
			["shadowXOffset"] = 1,
			["yOffset"] = 15.55571819560817,
			["mirror"] = false,
			["cooldownEdge"] = false,
			["regionType"] = "texture",
			["authorOptions"] = {
			},
			["blendMode"] = "BLEND",
			["uid"] = "hJ8NZcljYq9",
			["rotation"] = 0,
			["displayText_format_p_time_precision"] = 1,
			["texture"] = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura143",
			["alpha"] = 1,
			["zoom"] = 0,
			["justify"] = "LEFT",
			["displayText"] = "FIN",
			["id"] = "fin",
			["wordWrap"] = "WordWrap",
			["frameStrata"] = 1,
			["width"] = 128,
			["color"] = {
				0.8431372549019608, -- [1]
				0, -- [2]
				0.007843137254901961, -- [3]
				1, -- [4]
			},
			["config"] = {
			},
			["inverse"] = false,
			["actions"] = {
				["start"] = {
					["sound"] = "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RobotBlip.ogg",
					["do_sound"] = true,
				},
				["init"] = {
					["do_custom"] = false,
				},
				["finish"] = {
				},
			},
			["shadowColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				1, -- [4]
			},
			["conditions"] = {
			},
			["information"] = {
			},
			["displayIcon"] = "Interface\\Icons\\Spell_Shadow_Haunting",
		},
		["UI - Enemy Tremor Totem pulse timer"] = {
			["iconSource"] = 0,
			["wagoID"] = "-XoCJZCzy",
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["preferToUpdate"] = false,
			["yOffset"] = -8.812810790083859,
			["anchorPoint"] = "CENTER",
			["cooldownEdge"] = false,
			["icon"] = true,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "custom",
						["subeventSuffix"] = "_CAST_START",
						["debuffType"] = "HELPFUL",
						["event"] = "Health",
						["unit"] = "player",
						["customDuration"] = "function()\n    local duration = 3\n    local expiration = duration + GetTime()\n    return duration, expiration\nend",
						["subeventPrefix"] = "SPELL",
						["spellIds"] = {
						},
						["custom"] = "function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName)\n    if event == \"COMBAT_LOG_EVENT_UNFILTERED\" \n    and subEvent == \"SPELL_SUMMON\" \n    and destName == \"Tremor Totem\" \n    and aura_env.isArenaTarget(sourceName) then\n        aura_env.totem = arg6\n        aura_env.totemActive = true\n        aura_env.timer(3)\n        return true\n    elseif event == \"TOTEM_STATE\" and arg1\n    and aura_env.totemActive then\n        aura_env.frame:Hide()\n        aura_env.timer(3)\n        return true\n    end\nend",
						["names"] = {
						},
						["custom_type"] = "event",
						["events"] = "COMBAT_LOG_EVENT_UNFILTERED, TOTEM_STATE",
						["custom_hide"] = "custom",
					},
					["untrigger"] = {
						["custom"] = "function(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName)\n    if event == \"COMBAT_LOG_EVENT_UNFILTERED\" \n    and subEvent == \"UNIT_DIED\" \n    and destGUID == aura_env.totem then\n        aura_env.totemActive = false\n        aura_env.frame:Hide()\n        return true\n    end\nend",
					},
				}, -- [1]
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["keepAspectRatio"] = false,
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["desaturate"] = false,
			["version"] = 1,
			["subRegions"] = {
				{
					["type"] = "subborder",
					["border_offset"] = 0,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = false,
					["border_edge"] = "Square Full White",
					["border_size"] = 1,
				}, -- [1]
				{
					["text_text_format_p_time_format"] = 0,
					["text_text_format_s_format"] = "none",
					["text_text"] = "%p",
					["text_text_format_p_format"] = "timed",
					["text_selfPoint"] = "CENTER",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["rotateText"] = "NONE",
					["type"] = "subtext",
					["text_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["text_font"] = "ArchivoNarrow-Bold",
					["text_visible"] = false,
					["text_shadowYOffset"] = 0,
					["anchorXOffset"] = 0,
					["text_wordWrap"] = "WordWrap",
					["text_fontType"] = "OUTLINE",
					["text_anchorPoint"] = "CENTER",
					["text_shadowXOffset"] = 0,
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_fontSize"] = 14,
					["text_text_format_p_time_dynamic_threshold"] = 60,
					["text_text_format_p_time_precision"] = 1,
				}, -- [2]
			},
			["height"] = 32,
			["load"] = {
				["use_size"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["single"] = "arena",
					["multi"] = {
						["arena"] = true,
					},
				},
			},
			["xOffset"] = 195.1793960736561,
			["actions"] = {
				["start"] = {
				},
				["init"] = {
					["custom"] = "aura_env.frame = aura_env.frame or CreateFrame(\"Frame\")\nlocal f = aura_env.frame\n\nlocal function Tremor_OnUpdate(self, elapsed)\n    self.elapsed = self.elapsed - elapsed\n    if self.elapsed <= 0 then\n        self:Hide()\n    end\nend\n\nlocal function Tremor_OnHide(self, elapsed)\n    WeakAuras.ScanEvents(\"TOTEM_STATE\", true)\nend\n\naura_env.timer = function(time)\n    f.elapsed = time\n    f:SetScript(\"OnUpdate\", Tremor_OnUpdate)\n    f:SetScript(\"OnHide\", Tremor_OnHide)\n    f:Show()\nend\n\naura_env.isArenaTarget = function(name)\n    for i=1, 5 do\n        local unitID = \"arena\"..i\n        if UnitExists(unitID) and UnitName(unitID) == name then\n            return true\n        end\n    end\nend",
					["do_custom"] = true,
				},
				["finish"] = {
				},
			},
			["regionType"] = "icon",
			["selfPoint"] = "CENTER",
			["authorOptions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["displayIcon"] = "Interface\\Icons\\Spell_Nature_TremorTotem",
			["uid"] = "CtSmOBuhLxZ",
			["auto"] = false,
			["zoom"] = 0,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "UI - Enemy Tremor Totem pulse timer",
			["anchorFrameType"] = "SCREEN",
			["alpha"] = 1,
			["width"] = 32,
			["frameStrata"] = 1,
			["config"] = {
			},
			["inverse"] = false,
			["desc"] = "",
			["conditions"] = {
			},
			["cooldown"] = true,
			["url"] = "https://wago.io/-XoCJZCzy/1",
		},
		["Totem Range Check"] = {
			["iconSource"] = -1,
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = 40,
			["anchorPoint"] = "CENTER",
			["cooldownSwipe"] = true,
			["url"] = "https://wago.io/bTKHklByV/4",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["duration"] = "1",
						["unit"] = "party1",
						["custom_hide"] = "timed",
						["debuffType"] = "HELPFUL",
						["use_specific_unit"] = true,
						["type"] = "custom",
						["use_health"] = false,
						["unevent"] = "auto",
						["subeventSuffix"] = "_CAST_START",
						["subeventPrefix"] = "SPELL",
						["event"] = "Health",
						["customStacks"] = "function() return aura_env.count end\n",
						["custom_type"] = "status",
						["health"] = "0",
						["spellIds"] = {
						},
						["custom"] = "function()\n    \n    local count = 0\n    \n    for unit in WA_IterateGroupMembers(reversed, 1) do\n        if not UnitIsDeadOrGhost(unit)\n        --and not UnitIsUnit(unit, \"player\") \n        and WeakAuras.CheckRange(unit, 30, \"<=\")  \n        then\n            count = count + 1\n        end\n    end\n    aura_env.count = count\n    \n    return aura_env.count >= 1\nend\n\n\n\n",
						["check"] = "update",
						["health_operator"] = ">",
						["use_unit"] = true,
						["names"] = {
						},
					},
					["untrigger"] = {
						["use_specific_unit"] = true,
						["unit"] = "party1",
					},
				}, -- [1]
				["disjunctive"] = "any",
				["customTriggerLogic"] = "\n\n",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 45,
			["keepAspectRatio"] = false,
			["selfPoint"] = "CENTER",
			["desaturate"] = false,
			["version"] = 4,
			["subRegions"] = {
				{
					["text_shadowXOffset"] = 0,
					["text_text"] = "%1.s",
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_selfPoint"] = "CENTER",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["rotateText"] = "NONE",
					["type"] = "subtext",
					["text_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["text_font"] = "Naowh",
					["text_shadowYOffset"] = 0,
					["text_wordWrap"] = "WordWrap",
					["text_visible"] = true,
					["text_anchorPoint"] = "CENTER",
					["text_fontType"] = "OUTLINE",
					["text_fontSize"] = 18,
					["anchorXOffset"] = 0,
					["text_text_format_1.s_format"] = "none",
				}, -- [1]
				{
					["border_size"] = 1,
					["border_offset"] = 0,
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["type"] = "subborder",
				}, -- [2]
			},
			["height"] = 26,
			["load"] = {
				["ingroup"] = {
					["multi"] = {
						["group"] = true,
						["raid"] = true,
					},
				},
				["use_never"] = true,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["use_class"] = true,
				["use_ingroup"] = false,
				["faction"] = {
				},
				["zoneIds"] = "",
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["config"] = {
			},
			["xOffset"] = 0,
			["animation"] = {
				["start"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["regionType"] = "icon",
			["parent"] = "Shaman Totems",
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["conditions"] = {
			},
			["icon"] = true,
			["auto"] = true,
			["anchorFrameType"] = "SCREEN",
			["cooldownTextDisabled"] = false,
			["semver"] = "1.0.3",
			["tocversion"] = 20501,
			["id"] = "Totem Range Check",
			["frameStrata"] = 1,
			["alpha"] = 1,
			["width"] = 26,
			["zoom"] = 0.3,
			["uid"] = "OI7ATBDv)6m",
			["inverse"] = false,
			["cooldownEdge"] = false,
			["displayIcon"] = 136069,
			["cooldown"] = false,
			["color"] = {
				0.63137254901961, -- [1]
				0.8156862745098, -- [2]
				1, -- [3]
				1, -- [4]
			},
		},
		["UI - Duel Count Down"] = {
			["controlledChildren"] = {
				"Duel Timer 3 seconds", -- [1]
				"Duel Timer 2 seconds", -- [2]
				"Duel Timer 1 seconds", -- [3]
			},
			["borderBackdrop"] = "Blizzard Tooltip",
			["wagoID"] = "33gbLewvG",
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = 80,
			["anchorPoint"] = "CENTER",
			["borderColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				1, -- [4]
			},
			["url"] = "https://wago.io/33gbLewvG/1",
			["actions"] = {
				["start"] = {
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["unit"] = "player",
						["type"] = "aura2",
						["spellIds"] = {
						},
						["subeventSuffix"] = "_CAST_START",
						["subeventPrefix"] = "SPELL",
						["debuffType"] = "HELPFUL",
						["event"] = "Health",
						["names"] = {
						},
					},
					["untrigger"] = {
					},
				}, -- [1]
			},
			["internalVersion"] = 44,
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["version"] = 1,
			["subRegions"] = {
			},
			["load"] = {
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["backdropColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				0.5, -- [4]
			},
			["scale"] = 1.5,
			["border"] = false,
			["borderEdge"] = "Square Full White",
			["regionType"] = "group",
			["borderSize"] = 2,
			["borderOffset"] = 4,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "UI - Duel Count Down",
			["frameStrata"] = 1,
			["anchorFrameType"] = "SCREEN",
			["xOffset"] = 0,
			["borderInset"] = 1,
			["config"] = {
			},
			["selfPoint"] = "CENTER",
			["conditions"] = {
			},
			["information"] = {
			},
			["uid"] = "jIP9mf6Nzwp",
		},
		["Magma Totem Pulse"] = {
			["sparkWidth"] = 10,
			["iconSource"] = 0,
			["authorOptions"] = {
			},
			["adjustedMax"] = "10",
			["adjustedMin"] = "0",
			["yOffset"] = 18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["url"] = "https://wago.io/otyGuo9sL/3",
			["icon"] = false,
			["triggers"] = {
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["dynamicDuration"] = false,
						["custom_type"] = "event",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED:player MAGMA_REFIRE_EVENT",
						["duration"] = "2",
						["event"] = "Health",
						["subeventPrefix"] = "SPELL",
						["customDuration"] = "function()\n    \n \n        duration = 5\n        return true\n  \n    end",
						["spellIds"] = {
						},
						["custom"] = "function(event, unit, _, spell_ID)\n    \n    if spell_ID == 10587 and unit == \"player\" and event ~= \"MAGMA_REFIRE_EVENT\" then\n        \n        if aura_env.timer then \n            \n            aura_env.timer:Cancel() \n            aura_env.timer = 0\n        end\n        \n        aura_env.timer = C_Timer.NewTicker(2, function() WeakAuras.ScanEvents(\"MAGMA_REFIRE_EVENT\") end,23)\n        \n        return true\n        \n    elseif  event == \"MAGMA_REFIRE_EVENT\" then\n        \n        return true\n        \n        \n        \n        \n    end\nend",
						["subeventSuffix"] = "_CAST_START",
						["check"] = "event",
						["names"] = {
						},
						["unit"] = "player",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["type"] = "spell",
						["unevent"] = "auto",
						["totemNamePattern_operator"] = "find('%s')",
						["duration"] = "1",
						["totemNamePattern"] = "Magma",
						["unit"] = "player",
						["use_totemNamePattern"] = true,
						["subeventSuffix"] = "_CAST_START",
						["event"] = "Totem",
						["use_totemName"] = false,
						["subeventPrefix"] = "SPELL",
						["totemName"] = "Magma Totem",
						["use_totemType"] = false,
						["use_unit"] = true,
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [3]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and trigger[2] and not trigger[3] then return true end\n    return false\nend\n\n",
				["activeTriggerMode"] = 1,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["selfPoint"] = "CENTER",
			["semver"] = "1.0.2",
			["barColor"] = {
				1, -- [1]
				0.6509803921568628, -- [2]
				0.2901960784313725, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["preferToUpdate"] = false,
			["sparkOffsetY"] = 0,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["border_size"] = 1,
					["border_anchor"] = "bar",
					["type"] = "subborder",
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_offset"] = 0,
				}, -- [2]
			},
			["height"] = 6,
			["parent"] = "Shaman Totems",
			["load"] = {
				["use_class"] = true,
				["ingroup"] = {
					["single"] = "group",
					["multi"] = {
						["group"] = true,
						["raid"] = true,
					},
				},
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
						["SHAMAN"] = true,
					},
				},
				["zoneIds"] = "",
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["version"] = 3,
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5080125033855438, -- [4]
			},
			["xOffset"] = 20,
			["config"] = {
			},
			["smoothProgress"] = false,
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["anchorFrameType"] = "SCREEN",
			["icon_side"] = "RIGHT",
			["frameStrata"] = 1,
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["id"] = "Magma Totem Pulse",
			["zoom"] = 0,
			["auto"] = false,
			["tocversion"] = 20501,
			["sparkHidden"] = "NEVER",
			["spark"] = false,
			["alpha"] = 1,
			["width"] = 40,
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["uid"] = "UAXMRrfwX1k",
			["inverse"] = true,
			["sparkOffsetX"] = 0,
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["actions"] = {
				["start"] = {
					["do_custom"] = false,
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
		},
		["Taste for Blood"] = {
			["iconSource"] = 0,
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["preferToUpdate"] = false,
			["yOffset"] = -557.4448328003801,
			["anchorPoint"] = "CENTER",
			["cooldownEdge"] = true,
			["icon"] = true,
			["triggers"] = {
				{
					["trigger"] = {
						["debuffType"] = "HELPFUL",
						["type"] = "custom",
						["event"] = "Health",
						["custom_type"] = "event",
						["names"] = {
						},
						["duration"] = "6",
						["genericShowOn"] = "showOnActive",
						["unit"] = "player",
						["custom"] = "function(event, name) \n    return aura_env.id == name;\nend",
						["customName"] = "\n\n",
						["spellIds"] = {
						},
						["events"] = "WEAKAURAS_CUSTOM_EVENT",
						["check"] = "event",
						["subeventPrefix"] = "SPELL",
						["subeventSuffix"] = "_CAST_START",
						["custom_hide"] = "timed",
					},
					["untrigger"] = {
						["custom"] = "\n\n",
					},
				}, -- [1]
				{
					["trigger"] = {
						["type"] = "custom",
						["subeventSuffix"] = "_CAST_START",
						["event"] = "Health",
						["subeventPrefix"] = "SPELL",
						["events"] = "CLEU:SPELL_AURA_REMOVED:SPELL_AURA_APPLIED:SPELL_AURA_REFRESH PLAYER_ENTERING_WORLD PLAYER_DEAD",
						["custom_type"] = "event",
						["genericShowOn"] = "showOnActive",
						["custom"] = "function(event,  ...)\n    if ( event == \"COMBAT_LOG_EVENT_UNFILTERED\" and ... ) then\n        local _, subEvent, sourceGUID, _, srcFlags, _, _, _, spellID = ...;\n        if ( subEvent == \"SPELL_AURA_APPLIED\" and spellID == 60503 ) then\n            if ( srcFlags and bit.band(srcFlags,COMBATLOG_OBJECT_REACTION_HOSTILE)~=0 ) then\n                aura_env.sourceGUID = sourceGUID;\n                WeakAuras.ScanEvents(\"WEAKAURAS_CUSTOM_EVENT\", aura_env.id);\n                return true\n            end\n        end\n    end\nend",
						["custom_hide"] = "custom",
					},
					["untrigger"] = {
						["custom"] = "function(event, ...)\n    if ( event==\"PLAYER_ENTERING_WORLD\" ) then\n        return true;\n    elseif ( event==\"COMBAT_LOG_EVENT_UNFILTERED\" and ...  ) then\n        local _, subEvent, sourceGUID, _, _, _, _, _, spellID = ...;\n        if ( subEvent == \"SPELL_AURA_REMOVED\" and spellID == 60503 ) then\n            return aura_env.sourceGUID == sourceGUID;\n        end\n    end\nend",
					},
				}, -- [2]
				["disjunctive"] = "any",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 44,
			["keepAspectRatio"] = false,
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["colorR"] = 1,
					["scalex"] = 1,
					["colorA"] = 1,
					["colorG"] = 1,
					["type"] = "none",
					["easeType"] = "none",
					["use_color"] = true,
					["scaley"] = 1,
					["alpha"] = 0,
					["duration_type"] = "seconds",
					["y"] = 0,
					["colorType"] = "pulseHSV",
					["rotate"] = 0,
					["duration"] = "0",
					["colorFunc"] = "function(progress, r1, g1, b1, a1, r2, g2, b2, a2)\n    local angle = (progress * 2 * math.pi) - (math.pi / 2)\n    local newProgress = ((math.sin(angle) + 1)/2);\n    return WeakAuras.GetHSVTransition(newProgress, r1, g1, b1, a1, r2, g2, b2, a2)\nend\n",
					["easeStrength"] = 3,
					["x"] = 0,
					["colorB"] = 1,
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["desaturate"] = false,
			["version"] = 4,
			["subRegions"] = {
				{
					["type"] = "subborder",
					["border_size"] = 2,
					["border_color"] = {
						0.9843137254902, -- [1]
						1, -- [2]
						0.34117647058824, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_offset"] = 0,
				}, -- [1]
			},
			["height"] = 42,
			["load"] = {
				["use_size"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["difficulty"] = {
					["multi"] = {
					},
				},
				["role"] = {
					["multi"] = {
					},
				},
				["talent3"] = {
					["multi"] = {
					},
				},
				["faction"] = {
					["multi"] = {
					},
				},
				["talent2"] = {
					["multi"] = {
					},
				},
				["ingroup"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["single"] = "arena",
					["multi"] = {
						["arena"] = true,
					},
				},
			},
			["config"] = {
			},
			["url"] = "https://wago.io/loPMXItkV/4",
			["authorOptions"] = {
			},
			["regionType"] = "icon",
			["xOffset"] = -371.111029623916,
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["conditions"] = {
				{
					["check"] = {
						["trigger"] = 2,
						["variable"] = "show",
						["value"] = 0,
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "desaturate",
						}, -- [1]
						{
							["value"] = {
								1, -- [1]
								0, -- [2]
								0.023529411764706, -- [3]
								1, -- [4]
							},
							["property"] = "sub.1.border_color",
						}, -- [2]
					},
				}, -- [1]
			},
			["selfPoint"] = "CENTER",
			["cooldownTextEnabled"] = true,
			["anchorFrameType"] = "SCREEN",
			["zoom"] = 0,
			["auto"] = false,
			["tocversion"] = 30300,
			["id"] = "Taste for Blood",
			["frameStrata"] = 1,
			["alpha"] = 1,
			["width"] = 42,
			["semver"] = "1.0.3",
			["uid"] = "Zx8jhXYCdZk",
			["inverse"] = true,
			["actions"] = {
				["start"] = {
					["glow_frame_type"] = "FRAMESELECTOR",
					["do_glow"] = false,
					["glow_frame"] = "WeakAuras:Over Timer",
					["glow_action"] = "show",
					["use_glow_color"] = true,
					["glow_type"] = "buttonOverlay",
					["do_custom"] = false,
					["do_sound"] = false,
				},
				["finish"] = {
				},
				["init"] = {
					["custom"] = "\n\n",
					["do_custom"] = false,
				},
			},
			["displayIcon"] = "Interface\\Icons\\Ability_Rogue_HungerforBlood",
			["cooldown"] = true,
			["iconInset"] = 0,
		},
		["Air Totems"] = {
			["iconSource"] = -1,
			["xOffset"] = -20,
			["preferToUpdate"] = false,
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["cooldownSwipe"] = true,
			["url"] = "https://wago.io/qIeKQ6u0D/7",
			["icon"] = true,
			["triggers"] = {
				{
					["trigger"] = {
						["remaining_operator"] = ">",
						["unit"] = "player",
						["remaining"] = "0",
						["use_totemType"] = true,
						["debuffType"] = "HELPFUL",
						["use_remaining"] = true,
						["unevent"] = "auto",
						["use_unit"] = true,
						["event"] = "Totem",
						["totemName"] = "Grounding Totem",
						["duration"] = "1",
						["names"] = {
						},
						["spellIds"] = {
						},
						["type"] = "spell",
						["subeventSuffix"] = "_CAST_START",
						["use_totemName"] = false,
						["subeventPrefix"] = "SPELL",
						["totemType"] = 4,
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["useName"] = true,
						["useGroup_count"] = true,
						["matchesShowOn"] = "showOnMissing",
						["unit"] = "group",
						["group_countOperator"] = ">",
						["auranames"] = {
							"Wrath of Air Totem", -- [1]
							"Grace of Air", -- [2]
							"Grounding Totem Effect", -- [3]
							"Nature Resistance", -- [4]
							"Tranquil Air", -- [5]
						},
						["group_count"] = "1",
						["type"] = "aura2",
						["ownOnly"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [3]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Wrath of Air Totem", -- [1]
						},
						["debuffType"] = "HELPFUL",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [4]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Grace of Air", -- [1]
						},
						["unit"] = "player",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [5]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Grounding Totem Effect", -- [1]
						},
						["debuffType"] = "HELPFUL",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [6]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Nature Resistance", -- [1]
						},
						["unit"] = "player",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [7]
				{
					["trigger"] = {
						["useName"] = true,
						["auranames"] = {
							"Tranquil Air", -- [1]
						},
						["debuffType"] = "HELPFUL",
						["matchesShowOn"] = "showOnMissing",
						["type"] = "aura2",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [8]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and not trigger[2] then return true end\n    return false\nend",
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 45,
			["keepAspectRatio"] = true,
			["selfPoint"] = "CENTER",
			["desaturate"] = false,
			["version"] = 7,
			["subRegions"] = {
				{
					["border_offset"] = 0,
					["type"] = "subborder",
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_size"] = 1,
				}, -- [1]
				{
					["text_text_format_p_time_format"] = 0,
					["text_text"] = "%3.unitCount",
					["text_shadowColor"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["text_selfPoint"] = "AUTO",
					["text_automaticWidth"] = "Auto",
					["text_fixedWidth"] = 64,
					["text_text_format_6.unitCount_format"] = "none",
					["anchorYOffset"] = 0,
					["text_justify"] = "CENTER",
					["rotateText"] = "NONE",
					["text_text_format_p_time_dynamic_threshold"] = 0,
					["text_text_format_3.unitCount_format"] = "none",
					["text_text_format_2.unitCount_format"] = "none",
					["type"] = "subtext",
					["text_shadowXOffset"] = 0,
					["text_color"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["text_font"] = "Naowh",
					["text_shadowYOffset"] = 0,
					["text_anchorYOffset"] = -8,
					["text_visible"] = false,
					["text_wordWrap"] = "WordWrap",
					["text_fontType"] = "OUTLINE",
					["text_anchorPoint"] = "OUTER_TOP",
					["text_text_format_p_time_precision"] = 1,
					["text_text_format_p_format"] = "timed",
					["text_fontSize"] = 12,
					["anchorXOffset"] = 0,
					["text_text_format_5.unitCount_format"] = "none",
				}, -- [2]
				{
					["glowFrequency"] = 0.25,
					["glow"] = false,
					["useGlowColor"] = false,
					["glowType"] = "buttonOverlay",
					["glowLength"] = 10,
					["glowYOffset"] = 0,
					["glowColor"] = {
						1, -- [1]
						1, -- [2]
						1, -- [3]
						1, -- [4]
					},
					["type"] = "subglow",
					["glowXOffset"] = 0,
					["glowThickness"] = 1,
					["glowScale"] = 1,
					["glowLines"] = 8,
					["glowBorder"] = false,
				}, -- [3]
			},
			["height"] = 32,
			["load"] = {
				["use_class"] = true,
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["uid"] = "Jj4s6dMGIsU",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["cooldownEdge"] = false,
			["regionType"] = "icon",
			["parent"] = "Shaman Totems",
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["conditions"] = {
				{
					["check"] = {
						["trigger"] = -2,
						["variable"] = "OR",
						["checks"] = {
							{
								["trigger"] = -2,
								["op"] = "find('%s')",
								["variable"] = "AND",
								["checks"] = {
									{
										["value"] = "Wrath of Air Totem",
										["variable"] = "totemName",
										["op"] = "find('%s')",
										["trigger"] = 1,
									}, -- [1]
									{
										["trigger"] = 4,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [1]
							{
								["trigger"] = -2,
								["variable"] = "AND",
								["checks"] = {
									{
										["trigger"] = 1,
										["op"] = "find('%s')",
										["value"] = "Grace of Air Totem",
										["variable"] = "totemName",
									}, -- [1]
									{
										["trigger"] = 5,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [2]
							{
								["trigger"] = -2,
								["variable"] = "AND",
								["checks"] = {
									{
										["trigger"] = 1,
										["variable"] = "totemName",
										["op"] = "find('%s')",
										["value"] = "Grounding Totem",
									}, -- [1]
									{
										["trigger"] = 6,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [3]
							{
								["trigger"] = -2,
								["variable"] = "AND",
								["checks"] = {
									{
										["trigger"] = 1,
										["op"] = "find('%s')",
										["variable"] = "totemName",
										["value"] = "Nature Resistance Totem",
									}, -- [1]
									{
										["trigger"] = 7,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [4]
							{
								["trigger"] = -2,
								["variable"] = "AND",
								["checks"] = {
									{
										["trigger"] = 1,
										["op"] = "find('%s')",
										["value"] = "Tranquil Air Totem",
										["variable"] = "totemName",
									}, -- [1]
									{
										["trigger"] = 8,
										["variable"] = "show",
										["value"] = 1,
									}, -- [2]
								},
							}, -- [5]
						},
					},
					["changes"] = {
						{
							["value"] = {
								0.1803921568627451, -- [1]
								0.1803921568627451, -- [2]
								0.1803921568627451, -- [3]
								1, -- [4]
							},
							["property"] = "color",
						}, -- [1]
						{
							["value"] = false,
							["property"] = "sub.3.glow",
						}, -- [2]
					},
				}, -- [1]
				{
					["check"] = {
						["trigger"] = 3,
						["variable"] = "show",
						["value"] = 1,
						["checks"] = {
							{
								["trigger"] = 3,
								["variable"] = "show",
								["value"] = 1,
							}, -- [1]
						},
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.2.text_visible",
						}, -- [1]
					},
				}, -- [2]
				{
					["check"] = {
						["trigger"] = -2,
						["variable"] = "AND",
						["checks"] = {
							{
								["trigger"] = 1,
								["op"] = "<=",
								["variable"] = "expirationTime",
								["value"] = "5",
							}, -- [1]
							{
								["trigger"] = 1,
								["variable"] = "duration",
								["value"] = "60",
								["op"] = ">=",
							}, -- [2]
						},
					},
					["changes"] = {
						{
							["value"] = true,
							["property"] = "sub.3.glow",
						}, -- [1]
					},
				}, -- [3]
			},
			["authorOptions"] = {
			},
			["semver"] = "1.0.6",
			["width"] = 40,
			["zoom"] = 0.3,
			["auto"] = true,
			["tocversion"] = 20501,
			["id"] = "Air Totems",
			["alpha"] = 1,
			["frameStrata"] = 1,
			["anchorFrameType"] = "SCREEN",
			["cooldownTextDisabled"] = false,
			["config"] = {
			},
			["inverse"] = false,
			["animation"] = {
				["start"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["duration_type"] = "seconds",
					["type"] = "none",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["displayIcon"] = 136039,
			["cooldown"] = false,
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
		},
		["Air Totems Bar"] = {
			["sparkWidth"] = 10,
			["sparkOffsetX"] = 0,
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = -18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5, -- [4]
			},
			["triggers"] = {
				{
					["trigger"] = {
						["use_genericShowOn"] = true,
						["genericShowOn"] = "showOnCooldown",
						["names"] = {
						},
						["remaining"] = "0",
						["use_totemType"] = true,
						["debuffType"] = "HELPFUL",
						["use_remaining"] = true,
						["subeventSuffix"] = "_CAST_START",
						["spellName"] = 0,
						["event"] = "Totem",
						["totemType"] = 4,
						["realSpellName"] = 0,
						["use_spellName"] = true,
						["spellIds"] = {
						},
						["subeventPrefix"] = "SPELL",
						["unit"] = "player",
						["type"] = "spell",
						["use_track"] = true,
						["remaining_operator"] = ">",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [2]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and not trigger[2] then return true end\n    return false\nend",
				["activeTriggerMode"] = -10,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["selfPoint"] = "CENTER",
			["barColor"] = {
				0.03137254901960784, -- [1]
				1, -- [2]
				0.4901960784313725, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["sparkOffsetY"] = 0,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["border_offset"] = 0,
					["border_anchor"] = "bar",
					["type"] = "subborder",
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_size"] = 1,
				}, -- [2]
			},
			["height"] = 6,
			["load"] = {
				["use_class"] = true,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["uid"] = "Tef1QIcBnu2",
			["parent"] = "Shaman Totems",
			["icon"] = false,
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["iconSource"] = -1,
			["xOffset"] = -20,
			["icon_side"] = "RIGHT",
			["zoom"] = 0,
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["id"] = "Air Totems Bar",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["spark"] = false,
			["tocversion"] = 20501,
			["sparkHidden"] = "NEVER",
			["width"] = 40,
			["frameStrata"] = 1,
			["anchorFrameType"] = "SCREEN",
			["alpha"] = 1,
			["config"] = {
			},
			["inverse"] = false,
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
			},
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["easeType"] = "none",
					["duration_type"] = "seconds",
					["preset"] = "starShakeDecay",
					["easeStrength"] = 3,
				},
				["main"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
		},
		["TremorProgressTimer"] = {
			["user_y"] = 0,
			["user_x"] = 0,
			["xOffset"] = -312.7779617470504,
			["preferToUpdate"] = false,
			["yOffset"] = -558.3336568277717,
			["foregroundColor"] = {
				0.086274509803922, -- [1]
				0.2156862745098, -- [2]
				0.043137254901961, -- [3]
				1, -- [4]
			},
			["sparkRotation"] = 90,
			["sameTexture"] = false,
			["url"] = "https://wago.io/qiGsvU1Ao/7",
			["actions"] = {
				["start"] = {
					["custom"] = "\n\n",
					["do_custom"] = false,
				},
				["finish"] = {
				},
				["init"] = {
					["custom"] = "aura_env.summonTime = GetTime()",
					["do_custom"] = true,
				},
			},
			["fontFlags"] = "OUTLINE",
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["selfPoint"] = "CENTER",
			["barColor"] = {
				0, -- [1]
				0.13333333333333, -- [2]
				0.12549019607843, -- [3]
				0.90000000596046, -- [4]
			},
			["desaturate"] = false,
			["rotation"] = 0,
			["font"] = "Friz Quadrata TT",
			["sparkOffsetY"] = 0,
			["load"] = {
				["ingroup"] = {
					["multi"] = {
					},
				},
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["difficulty"] = {
					["multi"] = {
					},
				},
				["role"] = {
					["multi"] = {
					},
				},
				["talent3"] = {
					["multi"] = {
					},
				},
				["faction"] = {
					["multi"] = {
					},
				},
				["talent2"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["single"] = "arena",
					["multi"] = {
						["arena"] = true,
					},
				},
			},
			["foregroundTexture"] = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_FullWhite",
			["useAdjustededMin"] = false,
			["crop"] = 0.41,
			["blendMode"] = "BLEND",
			["texture"] = "Smooth",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["auto"] = true,
			["tocversion"] = 30300,
			["alpha"] = 1,
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["backgroundOffset"] = 0,
			["sparkOffsetX"] = 0,
			["color"] = {
			},
			["customText"] = "\n\n",
			["desaturateBackground"] = false,
			["sparkRotationMode"] = "MANUAL",
			["desaturateForeground"] = false,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "custom",
						["debuffType"] = "HELPFUL",
						["subeventSuffix"] = "_CAST_START",
						["custom_type"] = "event",
						["names"] = {
						},
						["genericShowOn"] = "showOnActive",
						["unit"] = "player",
						["customDuration"] = "function()\n    local value, total =  (GetTime() - aura_env.summonTime)%3, 3\n    return value, total, true \nend",
						["event"] = "Health",
						["spellIds"] = {
						},
						["customTexture"] = "function()\n    return [[Interface\\Icons\\Spell_Nature_TremorTotem]]\nend",
						["events"] = "CLEU:SPELL_SUMMON CLEU:UNIT_DIED PLAYER_ENTERING_WORLD FRAME_UPDATE",
						["custom"] = "function(event, timestamp, subEvent, ...)\n    \n    if event == \"COMBAT_LOG_EVENT_UNFILTERED\" and subEvent == \"SPELL_SUMMON\" then \n        local _, sourceName, srcFlags, objGUID, _, _, spellID = ...  \n        \n        if bit.band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 and spellID == 8143 then\n            aura_env.summonTime, aura_env.totemGUID = GetTime(), objGUID\n            aura_env.triggerState = true\n            return aura_env.triggerState\n        end\n        \n    elseif event == \"FRAME_UPDATE\" then \n        return aura_env.triggerState\n        \n    elseif event == \"OPTIONS\" then\n        aura_env.triggerState = false\n    end\n    \nend",
						["subeventPrefix"] = "SPELL",
						["custom_hide"] = "custom",
					},
					["untrigger"] = {
						["custom"] = "function(event, timestamp, subEvent, ...)  \n    if event == \"PLAYER_ENTERING_WORLD\" then \n        aura_env.triggerState = false\n        return true   \n    elseif event == \"COMBAT_LOG_EVENT_UNFILTERED\" and subEvent == \"UNIT_DIED\" then\n        local _, _, _, objGUID = ...\n        if objGUID == aura_env.totemGUID then\n            aura_env.triggerState = false\n            return true \n        end\n    end\nend",
					},
				}, -- [1]
				["disjunctive"] = "any",
				["activeTriggerMode"] = 1,
			},
			["endAngle"] = 360,
			["internalVersion"] = 44,
			["useAdjustedMin"] = false,
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["stickyDuration"] = false,
			["version"] = 7,
			["subRegions"] = {
				{
					["type"] = "subborder",
					["border_anchor"] = "bar",
					["border_size"] = 8,
					["border_color"] = {
						1, -- [1]
						1, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "ElvUI GlowBorder",
					["border_offset"] = 5,
				}, -- [1]
			},
			["height"] = 48,
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["fontSize"] = 12,
			["crop_y"] = 0.42999997735023,
			["sparkWidth"] = 100,
			["useAdjustedMax"] = false,
			["mirror"] = false,
			["crop_x"] = 0.42999997735023,
			["authorOptions"] = {
			},
			["anchorPoint"] = "CENTER",
			["backgroundTexture"] = "Interface\\Icons\\Spell_Nature_TremorTotem",
			["icon_side"] = "RIGHT",
			["regionType"] = "progresstexture",
			["compress"] = false,
			["sparkHeight"] = 25,
			["width"] = 48,
			["icon"] = false,
			["zoom"] = 0,
			["semver"] = "1.0.6",
			["id"] = "TremorProgressTimer",
			["sparkHidden"] = "NEVER",
			["startAngle"] = 0,
			["frameStrata"] = 2,
			["anchorFrameType"] = "SCREEN",
			["backgroundColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["spark"] = false,
			["inverse"] = false,
			["config"] = {
			},
			["orientation"] = "VERTICAL",
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = false,
			},
			["uid"] = "YDnGbZjzBRn",
		},
		["soul link"] = {
			["uid"] = "8WddNkNd0Gj",
			["alpha"] = 1,
			["authorOptions"] = {
			},
			["load"] = {
				["talent"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
			},
			["mirror"] = false,
			["yOffset"] = -92.11090324429745,
			["anchorPoint"] = "CENTER",
			["color"] = {
				0.996078431372549, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["blendMode"] = "BLEND",
			["conditions"] = {
			},
			["regionType"] = "texture",
			["xOffset"] = 149.9997875892343,
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["texture"] = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\cancel-icon.tga",
			["desaturate"] = false,
			["internalVersion"] = 44,
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "aura2",
						["subeventSuffix"] = "_CAST_START",
						["matchesShowOn"] = "showOnMissing",
						["event"] = "Health",
						["subeventPrefix"] = "SPELL",
						["spellIds"] = {
						},
						["auranames"] = {
							"Soul Link", -- [1]
						},
						["unit"] = "player",
						["names"] = {
						},
						["useName"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["use_class"] = true,
						["type"] = "unit",
						["unit"] = "player",
						["use_unit"] = true,
						["class"] = "WARLOCK",
						["event"] = "Health",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["unit"] = "player",
						["type"] = "unit",
						["use_unit"] = true,
						["use_mounted"] = false,
						["use_pvpflagged"] = true,
						["use_alive"] = true,
						["event"] = "Conditions",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [3]
				["disjunctive"] = "all",
				["activeTriggerMode"] = -10,
			},
			["selfPoint"] = "CENTER",
			["id"] = "soul link",
			["discrete_rotation"] = 0,
			["frameStrata"] = 1,
			["width"] = 80,
			["rotation"] = 0,
			["config"] = {
			},
			["anchorFrameType"] = "SCREEN",
			["subRegions"] = {
			},
			["height"] = 80,
			["rotate"] = true,
			["information"] = {
			},
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["preset"] = "pulse",
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
		},
		["Poison Totem Pulse"] = {
			["sparkWidth"] = 10,
			["sparkOffsetX"] = 0,
			["xOffset"] = -60,
			["adjustedMax"] = "10",
			["adjustedMin"] = "0",
			["yOffset"] = 18,
			["anchorPoint"] = "CENTER",
			["sparkRotation"] = 0,
			["sparkRotationMode"] = "AUTO",
			["url"] = "https://wago.io/otyGuo9sL/3",
			["actions"] = {
				["start"] = {
					["do_custom"] = false,
				},
				["init"] = {
				},
				["finish"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["dynamicDuration"] = false,
						["custom_type"] = "event",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED:player POISON_REFIRE_EVENT",
						["duration"] = "5",
						["event"] = "Health",
						["subeventPrefix"] = "SPELL",
						["customDuration"] = "function()\n    \n \n        duration = 5\n        return true\n  \n    end",
						["spellIds"] = {
						},
						["custom"] = "function(event, unit, _, spell_ID)\n    \n    if spell_ID == 8166  and unit == \"player\" and event ~= \"POISON_REFIRE_EVENT\" then\n        \n        if aura_env.timer then \n            \n            aura_env.timer:Cancel() \n            aura_env.timer = 0\n        end\n        \n        aura_env.timer = C_Timer.NewTicker(5, function() WeakAuras.ScanEvents(\"POISON_REFIRE_EVENT\") end,23)\n        \n        return true\n        \n    elseif  event == \"POISON_REFIRE_EVENT\" then\n        \n        return true\n        \n        \n    end\nend",
						["subeventSuffix"] = "_CAST_START",
						["check"] = "event",
						["names"] = {
						},
						["unit"] = "player",
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				{
					["trigger"] = {
						["type"] = "spell",
						["subeventSuffix"] = "_CAST_START",
						["duration"] = "1",
						["event"] = "Totem",
						["subeventPrefix"] = "SPELL",
						["use_unit"] = true,
						["unit"] = "player",
						["use_totemName"] = true,
						["unevent"] = "auto",
						["totemName"] = "Poison Cleansing Totem",
					},
					["untrigger"] = {
					},
				}, -- [2]
				{
					["trigger"] = {
						["custom_hide"] = "timed",
						["type"] = "custom",
						["events"] = "UNIT_SPELLCAST_SUCCEEDED",
						["custom_type"] = "event",
						["custom"] = "function(event, unit, spell, spellID)\n    if unit == \"player\" and spellID == 36936 then\n        return true\n    end\n    return false\nend",
						["duration"] = "1.5",
						["debuffType"] = "HELPFUL",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [3]
				["disjunctive"] = "custom",
				["customTriggerLogic"] = "function(trigger)\n    if trigger[1] and trigger[2] and not trigger[3] then return true end\n    return false\nend\n\n",
				["activeTriggerMode"] = 1,
			},
			["icon_color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["internalVersion"] = 45,
			["animation"] = {
				["start"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["main"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeStrength"] = 3,
					["easeType"] = "none",
				},
			},
			["zoom"] = 0,
			["barColor"] = {
				0.3607843137254902, -- [1]
				0.9058823529411765, -- [2]
				0.1215686274509804, -- [3]
				1, -- [4]
			},
			["desaturate"] = false,
			["preferToUpdate"] = false,
			["version"] = 3,
			["subRegions"] = {
				{
					["type"] = "aurabar_bar",
				}, -- [1]
				{
					["border_size"] = 1,
					["border_anchor"] = "bar",
					["type"] = "subborder",
					["border_color"] = {
						0, -- [1]
						0, -- [2]
						0, -- [3]
						1, -- [4]
					},
					["border_visible"] = true,
					["border_edge"] = "Square Full White",
					["border_offset"] = 0,
				}, -- [2]
			},
			["height"] = 6,
			["parent"] = "Shaman Totems",
			["load"] = {
				["use_class"] = true,
				["ingroup"] = {
					["single"] = "group",
					["multi"] = {
						["group"] = true,
						["raid"] = true,
					},
				},
				["use_never"] = false,
				["talent"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
						["SHAMAN"] = true,
					},
				},
				["zoneIds"] = "",
			},
			["sparkBlendMode"] = "ADD",
			["useAdjustededMax"] = false,
			["sparkOffsetY"] = 0,
			["icon"] = false,
			["iconSource"] = 0,
			["authorOptions"] = {
			},
			["sparkColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["smoothProgress"] = false,
			["useAdjustededMin"] = false,
			["regionType"] = "aurabar",
			["uid"] = "piFxyCGP7vb",
			["anchorFrameType"] = "SCREEN",
			["icon_side"] = "RIGHT",
			["alpha"] = 1,
			["sparkHeight"] = 30,
			["texture"] = "Blizzard Raid Bar",
			["id"] = "Poison Totem Pulse",
			["sparkTexture"] = "Interface\\CastingBar\\UI-CastingBar-Spark",
			["auto"] = false,
			["tocversion"] = 20501,
			["sparkHidden"] = "NEVER",
			["semver"] = "1.0.2",
			["frameStrata"] = 1,
			["width"] = 40,
			["spark"] = false,
			["config"] = {
			},
			["inverse"] = true,
			["backgroundColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				0.5080125033855438, -- [4]
			},
			["orientation"] = "HORIZONTAL",
			["conditions"] = {
			},
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["selfPoint"] = "CENTER",
		},
		["Battleground Widget"] = {
			["controlledChildren"] = {
				"AllianceProgressBar", -- [1]
				"HordeProgressBar", -- [2]
				"PointIsCaptured", -- [3]
				"HordeFlag", -- [4]
				"AllianceFlag", -- [5]
			},
			["borderBackdrop"] = "Blizzard Tooltip",
			["authorOptions"] = {
			},
			["preferToUpdate"] = false,
			["yOffset"] = -50,
			["anchorPoint"] = "TOP",
			["borderColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				1, -- [4]
			},
			["url"] = "https://wago.io/NEvswKSI5/39",
			["actions"] = {
				["start"] = {
				},
				["finish"] = {
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["names"] = {
						},
						["type"] = "aura2",
						["spellIds"] = {
						},
						["subeventSuffix"] = "_CAST_START",
						["subeventPrefix"] = "SPELL",
						["debuffType"] = "HELPFUL",
						["event"] = "Health",
						["unit"] = "player",
					},
					["untrigger"] = {
					},
				}, -- [1]
			},
			["internalVersion"] = 44,
			["animation"] = {
				["start"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["main"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
			},
			["desc"] = "Author: RomanSpector\nDiscord: https://discord.com/invite/Fm9kgfk\n",
			["version"] = 39,
			["subRegions"] = {
			},
			["load"] = {
				["size"] = {
					["multi"] = {
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["multi"] = {
					},
				},
				["talent"] = {
					["multi"] = {
					},
				},
			},
			["backdropColor"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				0.5, -- [4]
			},
			["scale"] = 1,
			["border"] = false,
			["anchorFrameFrame"] = "UIParent",
			["regionType"] = "group",
			["borderSize"] = 2,
			["config"] = {
			},
			["borderOffset"] = 4,
			["semver"] = "2.0.0",
			["tocversion"] = 30300,
			["id"] = "Battleground Widget",
			["selfPoint"] = "BOTTOMLEFT",
			["frameStrata"] = 4,
			["anchorFrameType"] = "SCREEN",
			["groupIcon"] = "Interface\\Icons\\FactionChange",
			["uid"] = "ZQBPukwoW1X",
			["borderInset"] = 1,
			["borderEdge"] = "Square Full White",
			["conditions"] = {
			},
			["information"] = {
				["groupOffset"] = true,
				["ignoreOptionsEventErrors"] = true,
			},
			["xOffset"] = 0,
		},
		["Grounding Totem 2"] = {
			["outline"] = "OUTLINE",
			["iconSource"] = -1,
			["wagoID"] = "c8f3zaNzo",
			["xOffset"] = 2.221923828125,
			["displayText"] = "Grounded %1.spellName",
			["yOffset"] = 0,
			["anchorPoint"] = "CENTER",
			["displayText_format_1.spellName_format"] = "none",
			["cooldownSwipe"] = true,
			["customTextUpdate"] = "update",
			["cooldownEdge"] = false,
			["actions"] = {
				["start"] = {
					["sound"] = "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Shotgun.ogg",
					["do_sound"] = false,
				},
				["finish"] = {
					["do_custom"] = false,
				},
				["init"] = {
				},
			},
			["triggers"] = {
				{
					["trigger"] = {
						["type"] = "combatlog",
						["destFlags"] = "Mine",
						["subeventSuffix"] = "_CAST_SUCCESS",
						["unevent"] = "timed",
						["duration"] = "2",
						["event"] = "Combat Log",
						["subeventPrefix"] = "SPELL",
						["unit"] = "player",
						["use_destName"] = true,
						["spellIds"] = {
						},
						["destName"] = "Grounding Totem",
						["names"] = {
						},
						["use_destFlags"] = true,
						["use_cloneId"] = true,
						["debuffType"] = "HELPFUL",
					},
					["untrigger"] = {
					},
				}, -- [1]
				["activeTriggerMode"] = -10,
			},
			["internalVersion"] = 45,
			["keepAspectRatio"] = false,
			["selfPoint"] = "BOTTOM",
			["desaturate"] = false,
			["icon"] = true,
			["font"] = "Naowh",
			["version"] = 1,
			["subRegions"] = {
			},
			["height"] = 1,
			["shadowYOffset"] = -1,
			["load"] = {
				["talent"] = {
					["multi"] = {
					},
				},
				["size"] = {
					["multi"] = {
					},
				},
				["class"] = {
					["single"] = "SHAMAN",
					["multi"] = {
						["SHAMAN"] = true,
					},
				},
				["spec"] = {
					["multi"] = {
					},
				},
				["zoneIds"] = "",
			},
			["color"] = {
				1, -- [1]
				1, -- [2]
				1, -- [3]
				1, -- [4]
			},
			["fontSize"] = 15,
			["cooldown"] = false,
			["conditions"] = {
			},
			["shadowXOffset"] = 1,
			["preferToUpdate"] = false,
			["url"] = "",
			["authorOptions"] = {
			},
			["regionType"] = "text",
			["uid"] = "CcJjpO(hCcr",
			["wordWrap"] = "WordWrap",
			["anchorFrameType"] = "SCREEN",
			["alpha"] = 1,
			["zoom"] = 0.2,
			["justify"] = "LEFT",
			["cooldownTextDisabled"] = false,
			["semver"] = "1.0.0",
			["tocversion"] = 30300,
			["id"] = "Grounding Totem 2",
			["animation"] = {
				["start"] = {
					["translateType"] = "straightTranslate",
					["duration"] = "0.2",
					["colorA"] = 1,
					["colorG"] = 1,
					["use_translate"] = false,
					["duration_type"] = "seconds",
					["scalex"] = 3,
					["type"] = "custom",
					["rotate"] = 0,
					["easeType"] = "none",
					["translateFunc"] = "function(progress, startX, startY, deltaX, deltaY)\n    return startX + (progress * deltaX), startY + (progress * deltaY)\nend\n",
					["preset"] = "fade",
					["alpha"] = 0,
					["scaley"] = 3,
					["y"] = 3,
					["x"] = 3,
					["scaleType"] = "straightScale",
					["scaleFunc"] = "function(progress, startX, startY, scaleX, scaleY)\n    return startX + (progress * (scaleX - startX)), startY + (progress * (scaleY - startY))\nend\n",
					["colorR"] = 1,
					["easeStrength"] = 2,
					["use_scale"] = true,
					["colorB"] = 1,
				},
				["main"] = {
					["easeStrength"] = 3,
					["type"] = "none",
					["duration_type"] = "seconds",
					["easeType"] = "none",
				},
				["finish"] = {
					["type"] = "preset",
					["easeType"] = "none",
					["easeStrength"] = 3,
					["duration_type"] = "seconds",
					["preset"] = "fade",
				},
			},
			["frameStrata"] = 1,
			["width"] = 1,
			["parent"] = "UI - Shaman Notifications",
			["config"] = {
			},
			["inverse"] = false,
			["fixedWidth"] = 200,
			["shadowColor"] = {
				0, -- [1]
				0, -- [2]
				0, -- [3]
				1, -- [4]
			},
			["displayIcon"] = 136039,
			["information"] = {
				["ignoreOptionsEventErrors"] = true,
			},
			["automaticWidth"] = "Auto",
		},
	},
	["lastArchiveClear"] = 1650134472,
	["minimap"] = {
		["minimapPos"] = 237.7668486464733,
		["hide"] = false,
	},
	["lastUpgrade"] = 1650134473,
	["dbVersion"] = 44,
	["login_squelch_time"] = 10,
	["registered"] = {
	},
	["frame"] = {
		["xOffset"] = -785.5543150262288,
		["width"] = 829.9999544540985,
		["height"] = 665.000125080261,
		["yOffset"] = -238.0560462150022,
	},
	["editor_theme"] = "Monokai",
}
