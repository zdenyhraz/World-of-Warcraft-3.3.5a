function PVPSound_OnLoad()
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	frame:RegisterEvent("PLAYER_DEAD")
	frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
	frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
	frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
	frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	frame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	frame:RegisterEvent("WORLD_MAP_UPDATE")
	frame:RegisterEvent("UPDATE_WORLD_STATES")

	-- Slash Commands
	SlashCmdList["PVPSound"] = PVPSound_Command
	SLASH_PVPSound1 = "/pvpsound"
	SLASH_PVPSound2 = "/ps"
end

	-- Default Settings
	PS_pvpmode = true
	PS_emote = true
	PS_emotemode = true
	PS_deathmsg = true
	PS_killsound = true
	PS_paysound = true
	PS_multikillsound = true
	PS_bgsound = true
	PS_soundengine = true
	PS_channel = "Master"
	PS_soundpack = "UnrealTournament3"
	PS_soundpacklanguage = "Eng"
	PS_soundpackdir = "Interface\\AddOns\\PVPSound\\Sounds\\"..PS_soundpack.."\\"..PS_soundpacklanguage.."\\"

	frame = CreateFrame("Frame", "PVPSound_Frame")

	-- Global Variables
	local PS_timer_reset = false
	local PS_reset_time = 1800
	local PS_kill_time = 60
	local PS_pkill_time = 90
	local PS_mkill_time = 16
	local PS_killcounter = 0
	
	-- Memory Allocation
	local MyFaction = "NotYet"
	local MyGender = "NotYet"
	local BgIsOver = "NotYet"
	local SotaAttacker = "NotYet"
	local SotaRoundOver = "NotYet"
	local IocAllianceGateDown = "NotYet"
	local IocHordeGateDown = "NotYet"
	local TbActive = "NotYet"
	local TbAttacker = "NotYet"
	local WgActive = "NotYet"
	local WgAttacker = "NotYet"

	-- Arathi Basin
	local ABobjectives = {Blacksmith = 0, Farm = 0, GoldMine = 0, LumberMill = 0, Stables = 0}

	local function ABget_objective(id)
		if id >= 126 and id <= 130 then
			return "Blacksmith"
		elseif id >= 231 and id <= 235 then
			return "Farm"
		elseif id >= 316 and id <= 320 then
			return "GoldMine"
		elseif id >= 421 and id <= 425 then
			return "LumberMill"
		elseif id >= 536 and id <= 540 then
			return "Stables"
		else
			return false
		end
	end

	local function ABobj_state(id)
		if id == 128 or id == 233 or id == 318 or id == 423 or id == 538 then
			return 1 -- Alliance Bases
		elseif id == 130 or id == 235 or id == 320 or id == 425 or id == 540 then
			return 2 -- Horde Bases
		elseif id == 127 or id == 232 or id == 317 or id == 422 or id == 537 then
			return 3 -- Alliance trys to capture
		elseif id == 129 or id == 234 or id == 319 or id == 424 or id == 539 then
			return 4 -- Horde trys to capture
		else
			return 0 -- Noone controling
		end
	end
	
	-- Arathi Basin Alliance Bases
	local ABBaseAobjectives = {AllianceBases = 0}

	local function ABBaseAget_objective(id)
		if id then
			return "AllianceBases"
		else
			return false
		end
	end

	local function ABBaseAobj_state(id)
		if id == 4 then
			return 1 -- Alliance Bases: 4
		elseif id == 5 then
			return 2 -- Alliance Bases: 5
		else
			return 0
		end
	end
	
	-- Arathi Basin Horde Bases
	local ABBaseHobjectives = {HordeBases = 0}

	local function ABBaseHget_objective(id)
		if id then
			return "HordeBases"
		else
			return false
		end
	end

	local function ABBaseHobj_state(id)
		if id == 4 then
			return 1 -- Horde Bases: 4
		elseif id == 5 then
			return 2 -- Horde Bases: 5
		else
			return 0
		end
	end

	-- The Battle for Gilneas
	local TBFGobjectives = {Lighthouse = 0, Mines = 0, Waterworks = 0}
	
	local function TBFGget_objective(id)
		if id >= 106 and id <= 112 then
			return "Lighthouse"
		elseif id >= 216 and id <= 220 then
			return "Mines"
		elseif id >= 326 and id <= 330 then
			return "Waterworks"
		else
			return false
		end
	end

	local function TBFGobj_state(id)
		if id == 111 or id == 218 or id == 328 then
			return 1 -- Alliance Bases
		elseif id == 110 or id == 220 or id == 330 then
			return 2 -- Horde Bases
		elseif id == 109 or id == 217 or id == 327 then
			return 3 -- Alliance trys to capture
		elseif id == 112 or id == 219 or id == 329 then
			return 4 -- Horde trys to capture
		else
			return 0 -- Noone controling
		end
	end
	
	-- The Battle for Gilneas Alliance Bases
	local TBFGBaseAobjectives = {AllianceBases = 0}

	local function TBFGBaseAget_objective(id)
		if id then
			return "AllianceBases"
		else
			return false
		end
	end

	local function TBFGBaseAobj_state(id)
		if id == 2 then
			return 1 -- Alliance Bases: 2
		elseif id == 3 then
			return 2 -- Alliance Bases: 3
		else
			return 0
		end
	end
	
	-- The Battle for Gilneas Horde Bases
	local TBFGBaseHobjectives = {HordeBases = 0}

	local function TBFGBaseHget_objective(id)
		if id then
			return "HordeBases"
		else
			return false
		end
	end

	local function TBFGBaseHobj_state(id)
		if id == 2 then
			return 1 -- Horde Bases: 2
		elseif id == 3 then
			return 2 -- Horde Bases: 3
		else
			return 0
		end
	end

	-- Isle of Conquest
	local IOCobjectives = {Quarry = 0, Workshop = 0, Hangar = 0, Docks = 0, Refinerie = 0}

	local function IOCget_objective(id)
		if id >= 16 and id <= 20 then
			return "Quarry"
		elseif id >= 135 and id <= 139 then
			return "Workshop"
		elseif id >= 140 and id <= 144 then
			return "Hangar"
		elseif id >= 145 and id <= 149 then
			return "Docks"
		elseif id >= 150 and id <= 154 then
			return "Refinerie"
		else
			return false
		end
	end

	local function IOCobj_state(id)
		if id == 18 or id == 136 or id == 141 or id == 146 or id == 151 then
			return 1 -- Alliance Bases
		elseif id == 20 or id == 138 or id == 143 or id == 148 or id == 153 then
			return 2 -- Horde Bases
		elseif id == 17 or id == 137 or id == 142 or id == 147 or id == 152 then
			return 3 -- Alliance trys to capture
		elseif id == 19 or id == 139 or id == 144 or id == 149 or id == 154 then
			return 4 -- Horde trys to capture
		else
			return 0 -- Noone controling
		end
	end

	-- Strand of the Ancients
	local SOTAobjectives = {AllianceDefense = 0, HordeDefense = 0, EastGraveyard = 0, WestGraveyard = 0, SouthGraveyard = 0, AllianceChamberofAncientRelics = 0, HordeChamberofAncientRelics = 0, GateoftheRedSun = 0, GateoftheBlueSapphire = 0, GateoftheYellowMoon = 0, GateofthePurpleAmethyst = 0, GateoftheGreenEmerald = 0}

	local function SOTAget_objective(id)
		if id == 46 then
			return "AllianceDefense"
		elseif id == 48 then
			return "HordeDefense"
		elseif id >= 113 and id <= 115 then
			return "EastGraveyard"
		elseif id >= 213 and id <= 215 then
			return "WestGraveyard"
		elseif id >= 313 and id <= 315 then
			return "SouthGraveyard"
		elseif id >= 480 and id <= 482 then
			return "AllianceChamberofAncientRelics"
		elseif id >= 477 and id <= 479 then
			return "HordeChamberofAncientRelics"
		elseif id >= 577 and id <= 579 then
			return "GateoftheRedSun"
		elseif id >= 680 and id <= 682 then
			return "GateoftheBlueSapphire"
		elseif id >= 702 and id <= 704 then
			return "GateoftheYellowMoon"
		elseif id >= 805 and id <= 807 then
			return "GateofthePurpleAmethyst"
		elseif id >= 908 and id <= 910 then
			return "GateoftheGreenEmerald"
		else
			return false
		end
	end

	local function SOTAobj_state(id)
		if id == 115 or id == 215 or id == 315 then
			return 1 -- Alliance Graveyards
		elseif id == 113 or id == 213 or id == 313 then
			return 2 -- Horde Graveyards
		elseif id == 480 then
			return 3 -- Alliance Chamber Gate Undamaged
		elseif id == 481 then
			return 4 -- Alliance Chamber Gate Damaged
		elseif id == 482 then
			return 5 -- Alliance Chamber Gate Destroyed
		elseif id == 477 then
			return 6 -- Horde Chamber Gate Undamaged
		elseif id == 478 then
			return 7 -- Horde Chamber Gate Damaged
		elseif id == 479 then
			return 8 -- Horde Chamber Gate Destroyed
		elseif id == 577 or id == 680 or id == 702 or id == 805 or id == 908 then
			return 9 -- Other Gates Undamaged
		elseif id == 578 or id == 681 or id == 703 or id == 806 or id == 909 then
			return 10 -- Other Gates Damaged
		elseif id == 579 or id == 682 or id == 704 or id == 807 or id == 910 then
			return 11 -- Other Gates Destroyed
		else
			return 0
		end
	end

	-- Eye of the Storm Alliance Bases
	local EOTSBaseAobjectives = {AllianceBases = 0}

	local function EOTSBaseAget_objective(id)
		if id then
			return "AllianceBases"
		else
			return false
		end
	end

	local function EOTSBaseAobj_state(id)
		if id == 0 then
			return 1 -- Alliance Bases: 0
		elseif id == 1 then
			return 2 -- Alliance Bases: 1
		elseif id == 2 then
			return 3 -- Alliance Bases: 2
		elseif id == 3 then
			return 4 -- Alliance Bases: 3
		elseif id == 4 then
			return 5 -- Alliance Bases: 4
		else
			return 0
		end
	end

	-- Eye of the Storm Horde Bases
	local EOTSBaseHobjectives = {HordeBases = 0}

	local function EOTSBaseHget_objective(id)
		if id then
			return "HordeBases"
		else
			return false
		end
	end

	local function EOTSBaseHobj_state(id)
		if id == 0 then
			return 1 -- Horde Bases: 0
		elseif id == 1 then
			return 2 -- Horde Bases: 1
		elseif id == 2 then
			return 3 -- Horde Bases: 2
		elseif id == 3 then
			return 4 -- Horde Bases: 3
		elseif id == 4 then
			return 5 -- Horde Bases: 4
		else
			return 0
		end
	end

	-- Eye of the Storm Victory Points
	local EOTSWINobjectives = {VictoryPoints = 0}

	local function EOTSWINget_objective(id)
		if id then
			return "VictoryPoints"
		else
			return false
		end
	end

	local function EOTSWINobj_state(id)
		if id == 1600 then
			return 1 -- Victory Points: 1600/1600
		else
			return 0 -- Victory Points: 0-1599/1600
		end
	end

	-- Wintergrasp
	local WGobjectives = {FlamewatchTower = 0, ShadowsightTower = 0, WintersEdgeTower = 0}

	local function WGget_objective(id)
		if id >= 110 and id <= 153 then
			return "FlamewatchTower"
		elseif id >= 210 and id <= 253 then
			return "ShadowsightTower"
		elseif id >= 310 and id <= 353 then
			return "WintersEdgeTower"
		else
			return false
		end
	end

	local function WGobj_state(id)
		if id == 111 or id == 211 or id == 311 then
			return 1 -- Alliance Towers Undamaged
		elseif id == 110 or id == 210 or id == 310 then
			return 2 -- Horde Towers Undamaged
		elseif id == 150 or id == 250 or id == 350 then
			return 3 -- Alliance Towers Heavily Damaged
		elseif id == 151 or id == 251 or id == 351 then
			return 4 -- Alliance Towers Destroyed
		elseif id == 152 or id == 252 or id == 352 then
			return 5 -- Horde Towers Heavily Damaged
		elseif id == 153 or id == 253 or id == 353 then
			return 6 -- Horde Towers Destroyed
		else
			return 0
		end
	end

	-- Tol Barad
	local TBobjectives = {TowersDestroyed = 0}

	local function TBget_objective(id)
		if id then
			return "TowersDestroyed"
		else
			return false
		end
	end

	local function TBobj_state(id)
		if id == 0 then
			return 1 -- Towers Destroyed: 0
		elseif id == 1 then
			return 2 -- Towers Destroyed: 1
		elseif id == 2 then
			return 3 -- Towers Destroyed: 2
		elseif id == 3 then
			return 4 -- Towers Destroyed: 3
		else
			return 0
		end
	end

	-- Alterac Valley and Isle of Conquest Reinforcements
	local AVandIOCCDobjectives = {Reinforcements = 0}

	local function AVandIOCCDget_objective(id)
		if id == 11 or id == 10 or id == 6 or id == 5 or id == 2 or id == 1 then
			return "Reinforcements"
		else
			return false
		end
	end

	local function AVandIOCCDobj_state(id)
		if id == 11 then
			return 1 -- Reinforcements: 11
		elseif id == 10 then
			return 2 -- Reinforcements: 10
		elseif id == 6 then
			return 3 -- Reinforcements: 6
		elseif id == 5 then
			return 4 -- Reinforcements: 5
		elseif id == 2 then
			return 5 -- Reinforcements: 2
		elseif id == 1 then
			return 6 -- Reinforcements: 1
		else
			return 0
		end
	end

function PVPSound_OnEvent(self, event, ...)
	if (select(4, GetBuildInfo())) >= 40200 then
		arg1, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, swingOverkill, _, _, spellOverkill = select(1, ...)
	elseif (select(4, GetBuildInfo())) >= 40100 then
		arg1, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, swingOverkill, _, _, spellOverkill = select(1, ...)
	elseif (select(4, GetBuildInfo())) >= 40000 then
		arg1, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, swingOverkill, _, _, spellOverkill = select(1, ...)
	end
	local PS_COMBATLOG_FILTER_ENEMY_PLAYERS = bit.bor (COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PLAYER)
	local PS_COMBATLOG_FILTER_ENEMY_NPC = bit.bor (COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_CONTROL_NPC, COMBATLOG_OBJECT_TYPE_NPC)
	local player = UnitGUID("player")
	local PS_msg = ""

	if (event == "PLAYER_ENTERING_WORLD") then
		CurrentZoneId = GetCurrentMapAreaID()
		InstanceType = select(2, IsInInstance())
		BgIsOver = "No"
		IocAllianceGateDown = "No"
		IocHordeGateDown = "No"
		SOTAobjectives = {EastGraveyard = 0, WestGraveyard = 0, SouthGraveyard = 0}
		PS_timer_reset = true
		-- Battlegrounds
		if CurrentZoneId == 443 and InstanceType == "pvp" then
			MyZone = "Zone_WarsongGulch"
		elseif CurrentZoneId == 461 and InstanceType == "pvp" then
			MyZone = "Zone_ArathiBasin"
		elseif CurrentZoneId == 401 and InstanceType == "pvp" then
			MyZone = "Zone_AlteracValley"
		elseif CurrentZoneId == 482 and InstanceType == "pvp" then
			MyZone = "Zone_EyeoftheStorm"
		elseif CurrentZoneId == 540 and InstanceType == "pvp" then
			MyZone = "Zone_IsleofConquest"
		elseif CurrentZoneId == 512 and InstanceType == "pvp" then
			MyZone = "Zone_StrandoftheAncients"
		elseif CurrentZoneId == 626 and InstanceType == "pvp" then
			MyZone = "Zone_TwinPeaks"
		elseif CurrentZoneId == 736 and InstanceType == "pvp" then
			MyZone = "Zone_TheBattleforGilneas"
		 -- Battlefields
		elseif CurrentZoneId == 501 then
			MyZone = "Zone_Wintergrasp"
		elseif CurrentZoneId == 708 then
			MyZone = "Zone_TolBarad"
		 -- Arenas
		elseif InstanceType == "arena" then
			MyZone = "Zone_Arenas"
		else
			MyZone = ""
		end
		MyFaction = UnitFactionGroup("player")
		if (UnitSex("player") == 1) then
			MyGender = "Unknown"
		elseif (UnitSex("player") == 2) then
			MyGender = "Male"
		elseif (UnitSex("player") == 3) then
			MyGender = "Female"
		end
	end

	if (event == "PLAYER_DEAD") then
		-- Death Data Share
		RegisterAddonMessagePrefix("PVPSound")
		if KilledMe ~= nil then
			if PS_file == "FirstBlood.mp3" then
				if InstanceType == "pvp" then
					SendAddonMessage("PVPSound", "First Blood:"..KilledMe, "BATTLEGROUND")
				else
					SendAddonMessage("PVPSound", "First Blood:"..KilledMe, "RAID")
				end
			elseif PS_file == "KillingSpree.mp3" then
				if InstanceType == "pvp" then
					SendAddonMessage("PVPSound", "Killing Spree:"..KilledMe, "BATTLEGROUND")
				else
					SendAddonMessage("PVPSound", "Killing Spree:"..KilledMe, "RAID")
				end
			elseif PS_file == "Rampage.mp3" then
				if InstanceType == "pvp" then
					SendAddonMessage("PVPSound", "Rampage:"..KilledMe, "BATTLEGROUND")
				else
					SendAddonMessage("PVPSound", "Rampage:"..KilledMe, "RAID")
				end
			elseif PS_file == "Dominating.mp3" then
				if InstanceType == "pvp" then
					SendAddonMessage("PVPSound", "Dominating:"..KilledMe, "BATTLEGROUND")
				else
					SendAddonMessage("PVPSound", "Dominating:"..KilledMe, "RAID")
				end
			elseif PS_file == "Unstoppable.mp3" then
				if InstanceType == "pvp" then
					SendAddonMessage("PVPSound", "Unstoppable:"..KilledMe, "BATTLEGROUND")
				else
					SendAddonMessage("PVPSound", "Unstoppable:"..KilledMe, "RAID")
				end
			elseif PS_file == "Godlike.mp3" then
				if InstanceType == "pvp" then
					SendAddonMessage("PVPSound", "Godlike:"..KilledMe, "BATTLEGROUND")
				else
					SendAddonMessage("PVPSound", "Godlike:"..KilledMe, "RAID")
				end
			elseif PS_file == "Massacre.mp3" then
				if InstanceType == "pvp" then
					SendAddonMessage("PVPSound", "MASSACRE:"..KilledMe, "BATTLEGROUND")
				else
					SendAddonMessage("PVPSound", "MASSACRE:"..KilledMe, "RAID")
				end
			end
			-- Death messages
			if PS_deathmsg == true then
				if (string.find(KilledMe,"-")) then
					KillerName = tostring(string.match(KilledMe, "(.+)-"))
				else
					KillerName = tostring(KilledMe)
				end
				print("|cFFFF4500"..MSG_YouGotKilledBy.." "..KillerName.."!|cFFFFFFFF")
			end
		end
		KilledMe = nil
		PS_timer_reset = true
	end

	if PS_bgsound == true then
		if (event == "ZONE_CHANGED_NEW_AREA") then
			CurrentZoneId = GetCurrentMapAreaID()
			InstanceType = select(2, IsInInstance())
			BgIsOver = "No"
			IocAllianceGateDown = "No"
			IocHordeGateDown = "No"
			SOTAobjectives = {EastGraveyard = 0, WestGraveyard = 0, SouthGraveyard = 0}
			PS_timer_reset = true
			-- Battlegrounds
			if CurrentZoneId == 443 and InstanceType == "pvp" then
				MyZone = "Zone_WarsongGulch"
			elseif CurrentZoneId == 461 and InstanceType == "pvp" then
				MyZone = "Zone_ArathiBasin"
			elseif CurrentZoneId == 401 and InstanceType == "pvp" then
				MyZone = "Zone_AlteracValley"
			elseif CurrentZoneId == 482 and InstanceType == "pvp" then
				MyZone = "Zone_EyeoftheStorm"
			elseif CurrentZoneId == 540 and InstanceType == "pvp" then
				MyZone = "Zone_IsleofConquest"
			elseif CurrentZoneId == 512 and InstanceType == "pvp" then
				MyZone = "Zone_StrandoftheAncients"
			elseif CurrentZoneId == 626 and InstanceType == "pvp" then
				MyZone = "Zone_TwinPeaks"
			elseif CurrentZoneId == 736 and InstanceType == "pvp" then
				MyZone = "Zone_TheBattleforGilneas"
			 -- Battlefields
			elseif CurrentZoneId == 501 then
				MyZone = "Zone_Wintergrasp"
			elseif CurrentZoneId == 708 then
				MyZone = "Zone_TolBarad"
			 -- Arenas
			elseif InstanceType == "arena" then
				MyZone = "Zone_Arenas"
			else
				MyZone = ""
			end
			-- Battleground PlaySounds
			if (MyZone == "Zone_WarsongGulch" or MyZone == "Zone_EyeoftheStorm" or MyZone == "Zone_ArathiBasin" or MyZone == "Zone_AlteracValley" or MyZone == "Zone_IsleofConquest" or MyZone == "Zone_StrandoftheAncients" or MyZone == "Zone_TwinPeaks" or MyZone == "Zone_TheBattleforGilneas") then
				PS_killcounter = 0
				if (MyFaction == "Alliance") and AlreadyPlaySound ~= "Yes" then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\PlayYouAreOnBlue.mp3")
					AlreadyPlaySound = "Yes"
				elseif (MyFaction == "Horde") and AlreadyPlaySound ~= "Yes" then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\PlayYouAreOnRed.mp3")
					AlreadyPlaySound = "Yes"
				end
			 -- Arena PlaySouns
			elseif (MyZone == "Zone_Arenas") then
				PS_killcounter = 0
				PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\PrepareForBattle.mp3")
			 -- Wintergrasp PlaySounds
			elseif (MyZone == "Zone_Wintergrasp") then
				PS_killcounter = 0
				local isActive = (select(3, GetWorldPVPAreaInfo(1)))
				if isActive == true then
					WgActive = "Active"
				elseif isActive == false then
					WgActive = "NotActive"
				end
				if (WgActive == "Active") then
					for i=7, 7, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							if (textureIndex == 68) then
								WgAttacker = "Alliance"
							elseif (textureIndex == 71) then
								WgAttacker = "Horde"
							end
						end
					end
					if ((WgAttacker == "Alliance") and (MyFaction == "Alliance")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\PlayYouAreOnBlueAttackTheEnemyCore.mp3")
					elseif ((WgAttacker == "Alliance") and (MyFaction == "Horde")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\PlayYouAreOnRedDefendYourCore.mp3")
					elseif ((WgAttacker == "Horde") and (MyFaction == "Alliance")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\PlayYouAreOnBlueDefendYourCore.mp3")
					elseif ((WgAttacker == "Horde") and (MyFaction == "Horde")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\PlayYouAreOnRedAttackTheEnemyCore.mp3")
					end
				end
			 -- Tol Barad PlaySounds
			elseif (MyZone == "Zone_TolBarad") then
				PS_killcounter = 0
				local isActive = (select(3, GetWorldPVPAreaInfo(2)))
				if isActive == true then
					TbActive = "Active"
				elseif isActive == false then
					TbActive = "NotActive"
				end
				if (TbActive == "Active") then
					for i=1, 1, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							if (textureIndex == 48) then
								TbAttacker = "Alliance"
							elseif (textureIndex == 46) then
								TbAttacker = "Horde"
							end
						end
					end
					if ((TbAttacker == "Alliance") and (MyFaction == "Alliance")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\PlayYouAreOnBlueAttackTheEnemyCore.mp3")
					elseif ((TbAttacker == "Alliance") and (MyFaction == "Horde")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\PlayYouAreOnRedDefendYourCore.mp3")
					elseif ((TbAttacker == "Horde") and (MyFaction == "Alliance")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\PlayYouAreOnBlueDefendYourCore.mp3")
					elseif ((TbAttacker == "Horde") and (MyFaction == "Horde")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\PlayYouAreOnRedAttackTheEnemyCore.mp3")
					end
				end
			end
			AlreadyPlaySound = "No"
		end
		-- WinSounds
		if (event == "CHAT_MSG_BG_SYSTEM_NEUTRAL") or (event == "CHAT_MSG_BG_SYSTEM_ALLIANCE") or (event == "CHAT_MSG_BG_SYSTEM_HORDE") or (event == "CHAT_MSG_MONSTER_YELL") then
			if (string.find(arg1,BG_ALLIANCE_WINS)) and (BgIsOver ~= "Yes") then
				PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\AllianceWins.mp3")
				BgIsOver = "Yes"
				PVPSound_ClearPaybackQueue()
				PVPSound_ClearRetributionQueue()
			elseif (string.find(arg1,BG_HORDE_WINS)) and (BgIsOver ~= "Yes") then
				PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\HordeWins.mp3")
				BgIsOver = "Yes"
				PVPSound_ClearPaybackQueue()
				PVPSound_ClearRetributionQueue()
			end
		end

		if (event == "CHAT_MSG_BG_SYSTEM_NEUTRAL") then
			-- Waronsg Gulch and Twin Peaks Vulnerable
			if ((MyZone == "Zone_WarsongGulch") or (MyZone == "Zone_TwinPeaks")) then
				if (string.find(arg1,BG_VULNERABLE)) then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\Overtime.mp3")
				end
			 -- Strand of the Ancients Attack/Defend Sounds
			elseif (MyZone == "Zone_StrandoftheAncients") then
				if (string.find(arg1,BG_SOTA_ROUND_ONE)) or (string.find(arg1,BG_SOTA_ROUND_TWO)) then
					for i=1, 1, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							if (textureIndex == 46) then
								SotaAttacker = "Horde"
							end
						end
					end
					for i=8, 8, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							if (textureIndex == 48) then
								SotaAttacker = "Alliance"
							end
						end
					end
					if ((SotaAttacker == "Alliance") and (MyFaction == "Alliance")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\AttackTheEnemyCore.mp3")
					elseif ((SotaAttacker == "Alliance") and (MyFaction == "Horde")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\DefendYourCore.mp3")
					elseif ((SotaAttacker == "Horde") and (MyFaction == "Alliance")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\DefendYourCore.mp3")
					elseif ((SotaAttacker == "Horde") and (MyFaction == "Horde")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\AttackTheEnemyCore.mp3")
					end
				elseif (string.find(arg1,BG_SOTA_ROUND_TWO_TWO)) then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\FinalRound.mp3")
				end
			end

		elseif (event == "CHAT_MSG_BG_SYSTEM_ALLIANCE") or (event == "CHAT_MSG_BG_SYSTEM_HORDE") then
			-- Waronsg Gulch and Twin Peaks
			if ((MyZone == "Zone_WarsongGulch") or (MyZone == "Zone_TwinPeaks")) then
				-- Alliance
				if (event == "CHAT_MSG_BG_SYSTEM_ALLIANCE") then
					if (string.find(arg1,BG_PICKED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Flag_Taken.mp3")
					elseif (string.find(arg1,BG_DROPPED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Flag_Dropped.mp3")
					elseif (string.find(arg1,BG_RETURNED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Flag_Returned.mp3")
					elseif (string.find(arg1,BG_CAPTURED)) then
						local x = 2
						local y = 3
						if ((select(4, GetWorldStateUIInfo(x))) ~= nil) and ((select(4, GetWorldStateUIInfo(y))) ~= nil) then
							-- Alliance Score
							local AllianceScore = tonumber(string.match(select(4, GetWorldStateUIInfo(x)), "%d/"))
							-- Horde Score
							local HordeScore = tonumber(string.match(select(4, GetWorldStateUIInfo(y)), "%d/"))
							-- Scores
							if (AllianceScore == 1) and (HordeScore == 0) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Takes_Lead.mp3")
							elseif (AllianceScore == 2) and (HordeScore == 1) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Scores.mp3")
							elseif (AllianceScore == 1) and (HordeScore == 2) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Scores.mp3")
							elseif (AllianceScore == 1) and (HordeScore == 1) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Scores.mp3")
							elseif (AllianceScore == 2) and (HordeScore == 2) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Scores.mp3")
							elseif (AllianceScore == 2) and (HordeScore == 0) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Inc_Lead.mp3")
							end
							if PS_soundengine == true then
								-- 3/3 Scores
								if (AllianceScore == 3) and (HordeScore == 0) then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Scores.mp3")
								elseif (AllianceScore == 3) and (HordeScore == 1) then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Scores.mp3")
								elseif (AllianceScore == 3) and (HordeScore == 2) then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Scores.mp3")
								end
							end
						end
					end
				 -- Horde
				elseif (event == "CHAT_MSG_BG_SYSTEM_HORDE") then
					if (string.find(arg1,BG_PICKED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Flag_Taken.mp3")
					elseif (string.find(arg1,BG_DROPPED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Flag_Dropped.mp3")
					elseif (string.find(arg1,BG_RETURNED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Flag_Returned.mp3")
					elseif (string.find(arg1,BG_CAPTURED)) then
						local x = 2
						local y = 3
						if ((select(4, GetWorldStateUIInfo(x))) ~= nil) and ((select(4, GetWorldStateUIInfo(y))) ~= nil) then
							-- Alliance Score
							local AllianceScore = tonumber(string.match(select(4, GetWorldStateUIInfo(x)), "%d/"))
							-- Horde Score
							local HordeScore = tonumber(string.match(select(4, GetWorldStateUIInfo(y)), "%d/"))
							-- Scores
							if (AllianceScore == 0) and (HordeScore == 1) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Takes_Lead.mp3")
							elseif (AllianceScore == 2) and (HordeScore == 1) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Scores.mp3")
							elseif (AllianceScore == 1) and (HordeScore == 2) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Scores.mp3")
							elseif (AllianceScore == 1) and (HordeScore == 1) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Scores.mp3")
							elseif (AllianceScore == 2) and (HordeScore == 2) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Scores.mp3")
							elseif (AllianceScore == 0) and (HordeScore == 2) then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Inc_Lead.mp3")
							end
							if PS_soundengine == true then
								-- 3/3 Scores
								if (AllianceScore == 0) and (HordeScore == 3) then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Scores.mp3")
								elseif (AllianceScore == 1) and (HordeScore == 3) then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Scores.mp3")
								elseif (AllianceScore == 2) and (HordeScore == 3) then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Scores.mp3")
								end
							end
						end
					end
				end
			 -- Eye of the Storm Score Sounds
			elseif (MyZone == "Zone_EyeoftheStorm") then
				if (string.find(arg1,BG_CAPTURED)) then
					if (event == "CHAT_MSG_BG_SYSTEM_ALLIANCE") then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Scores.mp3")
					elseif (event == "CHAT_MSG_BG_SYSTEM_HORDE") then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Scores.mp3")
					end
				end
			 -- Isle of Conquest Gate Destroyed
			elseif (MyZone == "Zone_IsleofConquest") then
				if (string.find(arg1,BG_IOC_GATE_DOWN)) then
					if (event == "CHAT_MSG_BG_SYSTEM_ALLIANCE") then
						if (IocHordeGateDown ~= "Yes") then
							PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyedRedCoreIsVulnerable.mp3")
							IocHordeGateDown = "Yes"
						else
							PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyed.mp3")
						end
					elseif (event == "CHAT_MSG_BG_SYSTEM_HORDE") then
						if (IocAllianceGateDown ~= "Yes") then
							PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyedBlueCoreIsVulnerable.mp3")
							IocAllianceGateDown = "Yes"
						else
							PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyed.mp3")
						end
					end
				end
			end

		elseif (event == "CHAT_MSG_MONSTER_YELL") then
			-- Alterac Valley
			if (MyZone == "Zone_AlteracValley") then
				if (string.find(arg1,BG_AV_BUNKER_UNDER_ATTACK) or string.find(arg1,BG_AV_TOWER_UNDER_ATTACK) or string.find(arg1,BG_AV_TOWER_POINT_UNDER_ATTACK)) then
					if (string.find(arg1,FACTION_ALLIANCE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Offense.mp3")
					elseif (string.find(arg1,FACTION_HORDE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Offense.mp3")
					end
				elseif (string.find(arg1,BG_AV_GRAVEYARD_UNDER_ATTACK) or string.find(arg1,BG_AV_DUN_BALDAR_UNDER_ATTACK) or string.find(arg1,BG_AV_FROSTWOLF_RELIEF_HUT_UNDER_ATTACK)) then
					if (string.find(arg1,FACTION_ALLIANCE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Node_Offense.mp3")
					elseif (string.find(arg1,FACTION_HORDE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Node_Offense.mp3")
					end
				elseif (string.find(arg1,BG_AV_BUNKER_TAKEN) or string.find(arg1,BG_AV_TOWER_TAKEN) or string.find(arg1,BG_AV_TOWER_POINT_TAKEN)) then
					if (string.find(arg1,FACTION_ALLIANCE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Defense.mp3")
					elseif (string.find(arg1,FACTION_HORDE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Defense.mp3")
					end
				elseif (string.find(arg1,BG_AV_GRAVEYARD_TAKEN) or string.find(arg1,BG_AV_DUN_BALDAR_TAKEN) or string.find(arg1,BG_AV_FROSTWOLF_RELIEF_HUT_TAKEN)) then
					if (string.find(arg1,FACTION_ALLIANCE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Node_Defense.mp3")
					elseif (string.find(arg1,FACTION_HORDE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Node_Defense.mp3")
					end
				elseif (string.find(arg1,BG_AV_BUNKER_DESTROYED) or string.find(arg1,BG_AV_TOWER_DESTROYED) or string.find(arg1,BG_AV_TOWER_POINT_DESTROYED)) then
					if (string.find(arg1,FACTION_ALLIANCE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Destroyed.mp3")
					elseif (string.find(arg1,FACTION_HORDE)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Destroyed.mp3")
					end
				end
			end

		elseif (event == "CHAT_MSG_RAID_BOSS_EMOTE") then
			-- Wintergrasp
			if (MyZone == "Zone_Wintergrasp") then
				local isActive = (select(3, GetWorldPVPAreaInfo(1)))
				if isActive == true then
					WgActive = "Active"
				elseif isActive == false then
					WgActive = "NotActive"
				end
				-- WinSounds
				if ((string.find(arg1,BF_WG_ALLIANCE_WIN_DEFENDED)) or (string.find(arg1,BF_WG_ALLIANCE_WIN_CAPTURED))) then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\AllianceWins.mp3")
				elseif ((string.find(arg1,BF_WG_HORDE_WIN_DEFENDED)) or (string.find(arg1,BF_WG_HORDE_WIN_CAPTURED))) then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\HordeWins.mp3")
				end
				if (WgActive == "Active") then
					-- Workshops
					if (string.find(arg1,BF_WG_ALLIANCE_ATTACKED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
					elseif (string.find(arg1,BF_WG_ALLIANCE_CAPTURED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
					elseif (string.find(arg1,BF_WG_HORDE_ATTACKED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
					elseif (string.find(arg1,BF_WG_HORDE_CAPTURED)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
					end
				end
			 -- Tol Barad
			elseif (MyZone == "Zone_TolBarad") then
				local isActive = (select(3, GetWorldPVPAreaInfo(2)))
				if isActive == true then
					TbActive = "Active"
				elseif isActive == false then
					TbActive = "NotActive"
				end
				-- WinSounds
				if ((string.find(arg1,BF_TB_ALLIANCE_SUCCESSFULLY_DEFENDED)) or (string.find(arg1,BF_TB_ALLIANCE_SUCCESSFULLY_TAKEN))) then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\AllianceWins.mp3")
				elseif ((string.find(arg1,BF_TB_HORDE_SUCCESSFULLY_DEFENDED)) or (string.find(arg1,BF_TB_HORDE_SUCCESSFULLY_TAKEN))) then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\HordeWins.mp3")
				end
				if (TbActive == "Active") then
					for i=1, 1, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							if (textureIndex == 48) then
								TbAttacker = "Alliance"
							elseif (textureIndex == 46) then
								TbAttacker = "Horde"
							end
						end
					end
					-- Bases
					if (string.find(arg1,BF_TB_ALLIANCE_LOST_CONTROL)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
					elseif (string.find(arg1,BF_TB_HORDE_LOST_CONTROL)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
					elseif (string.find(arg1,BF_TB_ALLIANCE_TAKEN)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
					elseif (string.find(arg1,BF_TB_HORDE_TAKEN)) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
					end
					-- Towers
					if ((string.find(arg1,BF_TB_DAMAGED)) and (TbAttacker == "Horde")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_HeavilyDamaged.mp3")
					elseif ((string.find(arg1,BF_TB_DAMAGED)) and (TbAttacker == "Alliance")) then
						PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_HeavilyDamaged.mp3")
					end
				end
			 -- Strand of the Ancients Round One Finished
			elseif (MyZone == "Zone_StrandoftheAncients") then
				if (string.find(arg1,BG_SOTA_ROUND_ONE_FINISHED)) then
					SotaRoundOver = "Yes"
					SOTAobjectives = {EastGraveyard = 0, WestGraveyard = 0, SouthGraveyard = 0}
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\EndOfRound.mp3")
				elseif (string.find(arg1,BG_SOTA_LET_THE_BATTLE)) then
					SotaRoundOver = "No"
				end
			 -- Eye of the Storm RBG Score Sounds
			elseif (MyZone == "Zone_EyeoftheStorm") then
				if (string.find(arg1,BG_EOTSRBG_ALLIANCE_CAPTURED)) then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\CHAT_MSG_BG_SYSTEM_ALLIANCE_Scores.mp3")
				elseif (string.find(arg1,BG_EOTSRBG_HORDE_CAPTURED)) then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\CHAT_MSG_BG_SYSTEM_HORDE_Scores.mp3")
				end
			end

		elseif (event == "WORLD_MAP_UPDATE") then
			-- Strand of the Ancients
			if (MyZone == "Zone_StrandoftheAncients") then
				-- If the Round is not over yet
				if (SotaRoundOver ~= "Yes") then
					-- East Graveyard
					for i=2, 3, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							local faketextureIndex = textureIndex+100
							local type = SOTAget_objective(faketextureIndex)
							if type then
								if SOTAobj_state(SOTAobjectives[type]) == 2 and SOTAobj_state(faketextureIndex) == 1 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Node_Defense.mp3")
								elseif SOTAobj_state(SOTAobjectives[type]) == 1 and SOTAobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Node_Defense.mp3")
								end
								SOTAobjectives[type] = faketextureIndex
							end
						end
					end
					-- South Graveyard
					for i=9, 9, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							local faketextureIndex = textureIndex+300
							local type = SOTAget_objective(faketextureIndex)
							if type then
								if SOTAobj_state(SOTAobjectives[type]) == 2 and SOTAobj_state(faketextureIndex) == 1 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Node_Defense.mp3")
								elseif SOTAobj_state(SOTAobjectives[type]) == 1 and SOTAobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Node_Defense.mp3")
								end
								SOTAobjectives[type] = faketextureIndex
							end
						end
					end
					-- West Graveyard
					for i=12, 12, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							local faketextureIndex = textureIndex+200
							local type = SOTAget_objective(faketextureIndex)
							if type then
								if SOTAobj_state(SOTAobjectives[type]) == 2 and SOTAobj_state(faketextureIndex) == 1 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Node_Defense.mp3")
								elseif SOTAobj_state(SOTAobjectives[type]) == 1 and SOTAobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Node_Defense.mp3")
								end
								SOTAobjectives[type] = faketextureIndex
							end
						end
					end
				end
				-- Alliance Chamber of Ancient Relics
				for i=1, 2, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+400
						local type = SOTAget_objective(faketextureIndex)
						if type then
							if SOTAobj_state(SOTAobjectives[type]) == 4 and SOTAobj_state(faketextureIndex) == 5 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyedBlueCoreIsVulnerable.mp3")
							end
							SOTAobjectives[type] = faketextureIndex
						end
					end
				end
				-- Horde Chamber of Ancient Relics
				for i=1, 2, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+400
						local type = SOTAget_objective(faketextureIndex)
						if type then
							if SOTAobj_state(SOTAobjectives[type]) == 7 and SOTAobj_state(faketextureIndex) == 8 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyedRedCoreIsVulnerable.mp3")
							end
							SOTAobjectives[type] = faketextureIndex
						end
					end
				end
				-- Gate of the Blue Sapphire
				for i=3, 4, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+600
						local type = SOTAget_objective(faketextureIndex)
						if type then
							if SOTAobj_state(SOTAobjectives[type]) == 10 and SOTAobj_state(faketextureIndex) == 11 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyed.mp3")
							end
							SOTAobjectives[type] = faketextureIndex
						end
					end
				end
				-- Gate of the Green Emerald
				for i=4, 5, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+800
						local type = SOTAget_objective(faketextureIndex)
						if type then
							if SOTAobj_state(SOTAobjectives[type]) == 10 and SOTAobj_state(faketextureIndex) == 11 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyed.mp3")
							end
							SOTAobjectives[type] = faketextureIndex
						end
					end
				end
				-- Gate of the Purple Amethyst
				for i=5, 6, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+700
						local type = SOTAget_objective(faketextureIndex)
						if type then
							if SOTAobj_state(SOTAobjectives[type]) == 10 and SOTAobj_state(faketextureIndex) == 11 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyed.mp3")
							end
							SOTAobjectives[type] = faketextureIndex
						end
					end
				end
				-- Gate of the Red Sun
				for i=6, 7, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+500
						local type = SOTAget_objective(faketextureIndex)
						if type then
							if SOTAobj_state(SOTAobjectives[type]) == 10 and SOTAobj_state(faketextureIndex) == 11 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyed.mp3")
							end
							SOTAobjectives[type] = faketextureIndex
						end
					end
				end
				-- Gate of the Yellow Moon
				for i=7, 8, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+600
						local type = SOTAget_objective(faketextureIndex)
						if type then
							if SOTAobj_state(SOTAobjectives[type]) == 10 and SOTAobj_state(faketextureIndex) == 11 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\BarricadeDestroyed.mp3")
							end
							SOTAobjectives[type] = faketextureIndex
						end
					end
				end
			 -- Isle of Conquest
			elseif (MyZone == "Zone_IsleofConquest") then
				-- Bases
				for i=1, GetNumMapLandmarks(), 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local type = IOCget_objective(textureIndex)
						if type then
							if IOCobj_state(IOCobjectives[type]) == 3 and IOCobj_state(textureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif IOCobj_state(IOCobjectives[type]) == 4 and IOCobj_state(textureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif IOCobj_state(IOCobjectives[type]) == 1 and IOCobj_state(textureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif IOCobj_state(IOCobjectives[type]) == 2 and IOCobj_state(textureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif IOCobj_state(IOCobjectives[type]) == 3 and IOCobj_state(textureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif IOCobj_state(IOCobjectives[type]) == 4 and IOCobj_state(textureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							IOCobjectives[type] = textureIndex
						end
					end
				end
			 -- Wintergrasp
			elseif (MyZone == "Zone_Wintergrasp") then
				local _, localizedName, isActive = GetWorldPVPAreaInfo(1)
				if isActive == true then
					WgActive = "Active"
				elseif isActive == false then
					WgActive = "NotActive"
				end
				if (WgActive == "Active") then
					-- Flamewatch Tower
					for i=5, 5, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							local faketextureIndex = textureIndex+100
							local type = WGget_objective(faketextureIndex)
							if type then
								if WGobj_state(WGobjectives[type]) == 1 and WGobj_state(faketextureIndex) == 3 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_HeavilyDamaged.mp3")
								elseif WGobj_state(WGobjectives[type]) == 3 and WGobj_state(faketextureIndex) == 4 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Destroyed.mp3")
								elseif WGobj_state(WGobjectives[type]) == 2 and WGobj_state(faketextureIndex) == 5 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_HeavilyDamaged.mp3")
								elseif WGobj_state(WGobjectives[type]) == 5 and WGobj_state(faketextureIndex) == 6 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Destroyed.mp3")
								end
								WGobjectives[type] = faketextureIndex
							end
						end
					end
					-- Shadowsight Tower
					for i=9, 9, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							local faketextureIndex = textureIndex+200
							local type = WGget_objective(faketextureIndex)
							if type then
								if WGobj_state(WGobjectives[type]) == 1 and WGobj_state(faketextureIndex) == 3 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_HeavilyDamaged.mp3")
								elseif WGobj_state(WGobjectives[type]) == 3 and WGobj_state(faketextureIndex) == 4 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Destroyed.mp3")
								elseif WGobj_state(WGobjectives[type]) == 2 and WGobj_state(faketextureIndex) == 5 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_HeavilyDamaged.mp3")
								elseif WGobj_state(WGobjectives[type]) == 5 and WGobj_state(faketextureIndex) == 6 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Destroyed.mp3")
								end
								WGobjectives[type] = faketextureIndex
							end
						end
					end
					-- Winter's Edge Tower
					for i=15, 15, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							local faketextureIndex = textureIndex+300
							local type = WGget_objective(faketextureIndex)
							if type then
								if WGobj_state(WGobjectives[type]) == 1 and WGobj_state(faketextureIndex) == 3 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_HeavilyDamaged.mp3")
								elseif WGobj_state(WGobjectives[type]) == 3 and WGobj_state(faketextureIndex) == 4 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Destroyed.mp3")
								elseif WGobj_state(WGobjectives[type]) == 2 and WGobj_state(faketextureIndex) == 5 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_HeavilyDamaged.mp3")
								elseif WGobj_state(WGobjectives[type]) == 5 and WGobj_state(faketextureIndex) == 6 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Destroyed.mp3")
								end
								WGobjectives[type] = faketextureIndex
							end
						end
					end
				end
			end

		elseif (event == "UPDATE_WORLD_STATES") then
			-- Arathi Basin
			if (MyZone == "Zone_ArathiBasin") then
				-- Blacksmith
				for i=1, 1, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+100
						local type = ABget_objective(faketextureIndex)
						if type then
							if ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 1 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 2 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							ABobjectives[type] = faketextureIndex
						end
					end
				end
				-- Farm
				for i=2, 2, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+200
						local type = ABget_objective(faketextureIndex)
						if type then
							if ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 1 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 2 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							ABobjectives[type] = faketextureIndex
						end
					end
				end
				-- Gold Mine
				for i=3, 3, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+300
						local type = ABget_objective(faketextureIndex)
						if type then
							if ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 1 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 2 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							ABobjectives[type] = faketextureIndex
						end
					end
				end
				-- Lumber Mill
				for i=4, 4, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+400
						local type = ABget_objective(faketextureIndex)
						if type then
							if ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 1 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 2 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							ABobjectives[type] = faketextureIndex
						end
					end
				end
				-- Stables
				for i=5, 5, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+500
						local type = ABget_objective(faketextureIndex)
						if type then
							if ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 1 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 2 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 3 and ABobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif ABobj_state(ABobjectives[type]) == 4 and ABobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							ABobjectives[type] = faketextureIndex
						end
					end
				end
				-- Alliance Dominating
				for i=1, 1, 1 do
					if ((select(4, GetWorldStateUIInfo(i))) ~= nil) then
						local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "%d%s"))
						if faketextureIndex then
							local type = ABBaseAget_objective(faketextureIndex)
							if type then
								if ABBaseAobj_state(ABBaseAobjectives[type]) == 1 and ABBaseAobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\AllianceDominating.mp3")
								end
								ABBaseAobjectives[type] = faketextureIndex
							end
						end
					end
				end
				-- Horde Dominating
				for i=2, 2, 1 do
					if ((select(4, GetWorldStateUIInfo(i))) ~= nil) then
						local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "%d%s"))
						if faketextureIndex then
							local type = ABBaseHget_objective(faketextureIndex)
							if type then
								if ABBaseHobj_state(ABBaseHobjectives[type]) == 1 and ABBaseHobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\HordeDominating.mp3")
								end
								ABBaseHobjectives[type] = faketextureIndex
							end
						end
					end
				end
			 -- The Battle for Gilneas
			elseif (MyZone == "Zone_TheBattleforGilneas") then
				-- Lighthouse
				for i=1, 1, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+100
						local type = TBFGget_objective(faketextureIndex)
						if type then
							if TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 1 and TBFGobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 2 and TBFGobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							TBFGobjectives[type] = faketextureIndex
						end
					end
				end
				-- Mines
				for i=2, 2, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+200
						local type = TBFGget_objective(faketextureIndex)
						if type then
							if TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 1 and TBFGobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 2 and TBFGobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							TBFGobjectives[type] = faketextureIndex
						end
					end
				end
				-- Waterworks
				for i=3, 3, 1 do
					local name, _, textureIndex = GetMapLandmarkInfo(i)
					if name and textureIndex then
						local faketextureIndex = textureIndex+300
						local type = TBFGget_objective(faketextureIndex)
						if type then
							if TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 1 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 2 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 1 and TBFGobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 2 and TBFGobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 3 and TBFGobj_state(faketextureIndex) == 4 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
							elseif TBFGobj_state(TBFGobjectives[type]) == 4 and TBFGobj_state(faketextureIndex) == 3 then
								PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
							end
							TBFGobjectives[type] = faketextureIndex
						end
					end
				end
				-- Alliance Dominating
				for i=1, 1, 1 do
					if ((select(4, GetWorldStateUIInfo(i))) ~= nil) then
						local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "%d%s"))
						if faketextureIndex then
							local type = TBFGBaseAget_objective(faketextureIndex)
							if type then
								if TBFGBaseAobj_state(TBFGBaseAobjectives[type]) == 1 and TBFGBaseAobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\AllianceDominating.mp3")
								end
								TBFGBaseAobjectives[type] = faketextureIndex
							end
						end
					end
				end
				-- Horde Dominating
				for i=2, 2, 1 do
					if ((select(4, GetWorldStateUIInfo(i))) ~= nil) then
						local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "%d%s"))
						if faketextureIndex then
							local type = TBFGBaseHget_objective(faketextureIndex)
							if type then
								if TBFGBaseHobj_state(TBFGBaseHobjectives[type]) == 1 and TBFGBaseHobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\HordeDominating.mp3")
								end
								TBFGBaseHobjectives[type] = faketextureIndex
							end
						end
					end
				end
			 -- Eye of the Storm
			elseif (MyZone == "Zone_EyeoftheStorm") then
				if (BgIsOver ~= "Yes") then
					if ((select(4, GetWorldStateUIInfo(2))) ~= nil) then
						-- Alliance Bases
						for i=2, 2, 1 do
							local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "%d%s"))
							if faketextureIndex then
								local type = EOTSBaseAget_objective(faketextureIndex)
								if type then
									if EOTSBaseAobj_state(EOTSBaseAobjectives[type]) == 1 and EOTSBaseAobj_state(faketextureIndex) == 2 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
									elseif EOTSBaseAobj_state(EOTSBaseAobjectives[type]) == 2 and EOTSBaseAobj_state(faketextureIndex) == 3 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
									elseif EOTSBaseAobj_state(EOTSBaseAobjectives[type]) == 3 and EOTSBaseAobj_state(faketextureIndex) == 4 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
									elseif EOTSBaseAobj_state(EOTSBaseAobjectives[type]) == 4 and EOTSBaseAobj_state(faketextureIndex) == 5 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Defense.mp3")
										-- Alliance Dominating
										if PS_soundengine == true then
											PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\AllianceDominating.mp3")
										end
									elseif EOTSBaseAobj_state(EOTSBaseAobjectives[type]) == 5 and EOTSBaseAobj_state(faketextureIndex) == 4 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
									elseif EOTSBaseAobj_state(EOTSBaseAobjectives[type]) == 4 and EOTSBaseAobj_state(faketextureIndex) == 3 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
									elseif EOTSBaseAobj_state(EOTSBaseAobjectives[type]) == 3 and EOTSBaseAobj_state(faketextureIndex) == 2 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
									elseif EOTSBaseAobj_state(EOTSBaseAobjectives[type]) == 2 and EOTSBaseAobj_state(faketextureIndex) == 1 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Offense.mp3")
									end
									EOTSBaseAobjectives[type] = faketextureIndex
								end
							end
						end
						-- Alliance Victory Points
						for i=2, 2, 1 do
							local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "(%d+)/"))
							if faketextureIndex then
								local type = EOTSWINget_objective(faketextureIndex)
								if type then
									if EOTSWINobj_state(EOTSWINobjectives[type]) == 0 and EOTSWINobj_state(faketextureIndex) == 1 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\AllianceWins.mp3")
										BgIsOver = "Yes"
									end
									EOTSWINobjectives[type] = faketextureIndex
								end
							end
						end
					end
					if ((select(4, GetWorldStateUIInfo(3))) ~= nil) then
						-- Horde Bases
						for i=3, 3, 1 do
							local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "%d%s"))
							if faketextureIndex then
								local type = EOTSBaseHget_objective(faketextureIndex)
								if type then
									if EOTSBaseHobj_state(EOTSBaseHobjectives[type]) == 1 and EOTSBaseHobj_state(faketextureIndex) == 2 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
									elseif EOTSBaseHobj_state(EOTSBaseHobjectives[type]) == 2 and EOTSBaseHobj_state(faketextureIndex) == 3 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
									elseif EOTSBaseHobj_state(EOTSBaseHobjectives[type]) == 3 and EOTSBaseHobj_state(faketextureIndex) == 4 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
									elseif EOTSBaseHobj_state(EOTSBaseHobjectives[type]) == 4 and EOTSBaseHobj_state(faketextureIndex) == 5 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_Base_Defense.mp3")
										-- Horde Dominating
										if PS_soundengine == true then
											PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\HordeDominating.mp3")
										end
									elseif EOTSBaseHobj_state(EOTSBaseHobjectives[type]) == 5 and EOTSBaseHobj_state(faketextureIndex) == 4 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
									elseif EOTSBaseHobj_state(EOTSBaseHobjectives[type]) == 4 and EOTSBaseHobj_state(faketextureIndex) == 3 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
									elseif EOTSBaseHobj_state(EOTSBaseHobjectives[type]) == 3 and EOTSBaseHobj_state(faketextureIndex) == 2 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
									elseif EOTSBaseHobj_state(EOTSBaseHobjectives[type]) == 2 and EOTSBaseHobj_state(faketextureIndex) == 1 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_Base_Offense.mp3")
									end
									EOTSBaseHobjectives[type] = faketextureIndex
								end
							end
						end
						-- Horde Victory Points
						for i=3, 3, 1 do
							local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "(%d+)/"))
							if faketextureIndex then
								local type = EOTSWINget_objective(faketextureIndex)
								if type then
									if EOTSWINobj_state(EOTSWINobjectives[type]) == 0 and EOTSWINobj_state(faketextureIndex) == 1 then
										PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\HordeWins.mp3")
										BgIsOver = "Yes"
									end
									EOTSWINobjectives[type] = faketextureIndex
								end
							end
						end
					end
				end
			 -- Tol Barad Towers Destroyed
			elseif (MyZone == "Zone_TolBarad") then
				local isActive = (select(3, GetWorldPVPAreaInfo(2)))
				if isActive == true then
					TbActive = "Active"
				elseif isActive == false then
					TbActive = "NotActive"
				end
				if (TbActive == "Active") then
					for i=1, 1, 1 do
						local name, _, textureIndex = GetMapLandmarkInfo(i)
						if name and textureIndex then
							if (textureIndex == 48) then
								TbAttacker = "Alliance"
							elseif (textureIndex == 46) then
								TbAttacker = "Horde"
							end
						end
					end
					if TbAttacker == "Alliance" then
						-- Towers Destroyed
						for i=7, 7, 1 do
							if ((select(4, GetWorldStateUIInfo(i))) ~= nil) then
								local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "%d%s"))
								if faketextureIndex then
									local type = TBget_objective(faketextureIndex)
									if type then
										if TBobj_state(TBobjectives[type]) == 1 and TBobj_state(faketextureIndex) == 2 then
											PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Destroyed.mp3")
										elseif TBobj_state(TBobjectives[type]) == 2 and TBobj_state(faketextureIndex) == 3 then
											PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Destroyed.mp3")
										elseif TBobj_state(TBobjectives[type]) == 3 and TBobj_state(faketextureIndex) == 4 then
											PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\HORDE_TowerNode_Destroyed.mp3")
										end
										TBobjectives[type] = faketextureIndex
									end
								end
							end
						end
					elseif TbAttacker == "Horde" then
						-- Towers Destroyed
						for i=7, 7, 1 do
							if ((select(4, GetWorldStateUIInfo(i))) ~= nil) then
								local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), "%d%s"))
								if faketextureIndex then
									local type = TBget_objective(faketextureIndex)
									if type then
										if TBobj_state(TBobjectives[type]) == 1 and TBobj_state(faketextureIndex) == 2 then
											PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Destroyed.mp3")
										elseif TBobj_state(TBobjectives[type]) == 2 and TBobj_state(faketextureIndex) == 3 then
											PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Destroyed.mp3")
										elseif TBobj_state(TBobjectives[type]) == 3 and TBobj_state(faketextureIndex) == 4 then
											PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\"..MyZone.."\\ALLIANCE_TowerNode_Destroyed.mp3")
										end
										TBobjectives[type] = faketextureIndex
									end
								end
							end
						end
					end
				end
			 -- Alterac Valley and Isle of Conquest Countdown
			elseif (MyZone == "Zone_AlteracValley") or (MyZone == "Zone_IsleofConquest") then
				-- Alliance Reinforcements
				for i=1, 1, 1 do
					if ((select(4, GetWorldStateUIInfo(i))) ~= nil) then
						local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), ": (%d+)"))
						if faketextureIndex then
							local type = AVandIOCCDget_objective(faketextureIndex)
							if type then
								if AVandIOCCDobj_state(AVandIOCCDobjectives[type]) == 1 and AVandIOCCDobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\CountDown\\TenKillsRemain.mp3")
								elseif AVandIOCCDobj_state(AVandIOCCDobjectives[type]) == 3 and AVandIOCCDobj_state(faketextureIndex) == 4 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\CountDown\\FiveKillsRemain.mp3")
								elseif AVandIOCCDobj_state(AVandIOCCDobjectives[type]) == 5 and AVandIOCCDobj_state(faketextureIndex) == 6 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\CountDown\\OneKillRemains.mp3")
								end
								AVandIOCCDobjectives[type] = faketextureIndex
							end
						end
					end
				end
				-- Horde Reinforcements
				for i=2, 2, 1 do
					if ((select(4, GetWorldStateUIInfo(i))) ~= nil) then
						local faketextureIndex = tonumber(string.match(select(4, GetWorldStateUIInfo(i)), ": (%d+)"))
						if faketextureIndex then
							local type = AVandIOCCDget_objective(faketextureIndex)
							if type then
								if AVandIOCCDobj_state(AVandIOCCDobjectives[type]) == 1 and AVandIOCCDobj_state(faketextureIndex) == 2 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\CountDown\\TenKillsRemain.mp3")
								elseif AVandIOCCDobj_state(AVandIOCCDobjectives[type]) == 3 and AVandIOCCDobj_state(faketextureIndex) == 4 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\CountDown\\FiveKillsRemain.mp3")
								elseif AVandIOCCDobj_state(AVandIOCCDobjectives[type]) == 5 and AVandIOCCDobj_state(faketextureIndex) == 6 then
									PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\CountDown\\OneKillRemains.mp3")
								end
								AVandIOCCDobjectives[type] = faketextureIndex
							end
						end
					end
				end
			end
		end
	end -- PS_bgsounds == true

	if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		local toEnemy
		local fromEnemy
		local toEnemyPlayer
		local toEnemyNPC
		local fromEnemyPlayer
		local fromEnemyNPC
		-- To an Enemy
		if (destName and not CombatLog_Object_IsA(destFlags, COMBATLOG_OBJECT_NONE)) then
			toEnemyPlayer = CombatLog_Object_IsA(destFlags, PS_COMBATLOG_FILTER_ENEMY_PLAYERS)
			toEnemyNPC = CombatLog_Object_IsA(destFlags, PS_COMBATLOG_FILTER_ENEMY_NPC)
		end
		-- From an Enemy
		if (sourceName and not CombatLog_Object_IsA(sourceFlags, COMBATLOG_OBJECT_NONE)) then
			fromEnemyPlayer = CombatLog_Object_IsA(sourceFlags, PS_COMBATLOG_FILTER_ENEMY_PLAYERS)
			fromEnemyNPC = CombatLog_Object_IsA(sourceFlags, PS_COMBATLOG_FILTER_ENEMY_NPC)
		end

		if PS_pvpmode == true then
			toEnemy = toEnemyPlayer
			fromEnemy = fromEnemyPlayer
		else
			toEnemy = toEnemyNPC
			fromEnemy = fromEnemyNPC
		end

		if PS_killsound == true then
			if (eventType == "PARTY_KILL" and sourceGUID == player and toEnemy) then
				RegisterAddonMessagePrefix("PVPSound")
				KilledWho = destName
				PVPSound_AddToPaybackQueue(KilledWho)
				-- First Killing
				if (not PS_lastkill or (GetTime() - PS_lastkill > PS_reset_time) or PS_timer_reset) then
					PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\FirstBlood.mp3")
					PS_file = "FirstBlood.mp3"
					if (MyGender == "Male") then
						PS_msg = MSG_FirstBloodMale
						if InstanceType == "pvp" then
							SendAddonMessage("PVPSound", "FirstBloodMale", "BATTLEGROUND")
						end
						if ((PS_emote ~= true) or (PS_emote == true and PS_emotemode == false)) then
							if InstanceType == "pvp" then
								SendAddonMessage("PVPSound", "FirstBloodMaleEmote", "BATTLEGROUND")
							else
								SendAddonMessage("PVPSound", "FirstBloodMaleEmote", "RAID")
							end
						end
					elseif (MyGender == "Female") then
						PS_msg = MSG_FirstBloodFemale
						if InstanceType == "pvp" then
							SendAddonMessage("PVPSound", "FirstBloodFemale", "BATTLEGROUND")
						end
						if ((PS_emote ~= true) or (PS_emote == true and PS_emotemode == false)) then
							if InstanceType == "pvp" then
								SendAddonMessage("PVPSound", "FirstBloodFemaleEmote", "BATTLEGROUND")
							else
								SendAddonMessage("PVPSound", "FirstBloodFemaleEmote", "RAID")
							end
						end
					end
					-- RetributionKilling (First Blood)
					if PS_paysound == true then
						RetributionKill = false
						for i = 1, table.getn(PVPSound_RetributionQueue) do
							if (string.upper(PVPSound_RetributionQueue[i].dir) == string.upper(KilledWho)) then
								RetributionKill = true
							end
						end
						if RetributionKill == true then
							PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Retribution.mp3")
						end
					end
					PS_killcounter = 1
					PS_kills = 1
					if (not PS_lastkill or (GetTime() - PS_lastkill > PS_mkill_time) or PS_timer_reset) then
						PS_mkills = 1
					end
					PS_timer_reset = false
				 -- Killing
				elseif (GetTime() - PS_lastkill <= PS_reset_time) then
					PS_killcounter = PS_killcounter + 1
					if (GetTime() - PS_lastkill <= PS_kill_time) then
						PS_firstmkill = PS_lastkill
						if (GetTime() - PS_firstmkill <= PS_kill_time) then
							PS_kills = PS_kills + 1
							if (PS_kills == 2) then
								PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\KillingSpree.mp3")
								PS_file = "KillingSpree.mp3"
								PS_msg = MSG_KillingSpree
								if InstanceType == "pvp" then
									SendAddonMessage("PVPSound", "KillingSpree", "BATTLEGROUND")
								end
								if ((PS_emote ~= true) or (PS_emote == true and PS_emotemode == false)) then
									if InstanceType == "pvp" then
										SendAddonMessage("PVPSound", "KillingSpreeEmote", "BATTLEGROUND")
									else
										SendAddonMessage("PVPSound", "KillingSpreeEmote", "RAID")
									end
								end
							elseif (PS_kills == 3) then
								PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Rampage.mp3")
								PS_file = "Rampage.mp3"
								PS_msg = MSG_Rampage
								if InstanceType == "pvp" then
									SendAddonMessage("PVPSound", "Rampage", "BATTLEGROUND")
								end
								if ((PS_emote ~= true) or (PS_emote == true and PS_emotemode == false)) then
									if InstanceType == "pvp" then
										SendAddonMessage("PVPSound", "RampageEmote", "BATTLEGROUND")
									else
										SendAddonMessage("PVPSound", "RampageEmote", "RAID")
									end
								end
							elseif (PS_kills == 4) then
								PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Dominating.mp3")
								PS_file = "Dominating.mp3"
								PS_msg = MSG_Dominating
								if InstanceType == "pvp" then
									SendAddonMessage("PVPSound", "Dominating", "BATTLEGROUND")
								end
								if ((PS_emote ~= true) or (PS_emote == true and PS_emotemode == false)) then
									if InstanceType == "pvp" then
										SendAddonMessage("PVPSound", "DominatingEmote", "BATTLEGROUND")
									else
										SendAddonMessage("PVPSound", "DominatingEmote", "RAID")
									end
								end
							elseif (PS_kills == 5) then
								PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Unstoppable.mp3")
								PS_file = "Unstoppable.mp3"
								PS_msg = MSG_Unstoppable
								if InstanceType == "pvp" then
									SendAddonMessage("PVPSound", "Unstoppable", "BATTLEGROUND")
								end
								if ((PS_emote ~= true) or (PS_emote == true and PS_emotemode == false)) then
									if InstanceType == "pvp" then
										SendAddonMessage("PVPSound", "UnstoppableEmote", "BATTLEGROUND")
									else
										SendAddonMessage("PVPSound", "UnstoppableEmote", "RAID")
									end
								end
							elseif (PS_kills == 6) then
								PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Godlike.mp3")
								PS_file = "Godlike.mp3"
								PS_msg = MSG_Godlike
								if InstanceType == "pvp" then
									SendAddonMessage("PVPSound", "Godlike", "BATTLEGROUND")
								end
								if ((PS_emote ~= true) or (PS_emote == true and PS_emotemode == false)) then
									if InstanceType == "pvp" then
										SendAddonMessage("PVPSound", "GodlikeEmote", "BATTLEGROUND")
									else
										SendAddonMessage("PVPSound", "GodlikeEmote", "RAID")
									end
								end
							elseif (PS_kills > 6) then
								PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Massacre.mp3")
								PS_file = "Massacre.mp3"
								PS_msg = MSG_Massacre
								if InstanceType == "pvp" then
									SendAddonMessage("PVPSound", "MASSACRE", "BATTLEGROUND")
								end
								if ((PS_emote ~= true) or (PS_emote == true and PS_emotemode == false)) then
									if InstanceType == "pvp" then
										SendAddonMessage("PVPSound", "MASSACREEmote", "BATTLEGROUND")
									else
										SendAddonMessage("PVPSound", "MASSACREEmote", "RAID")
									end
								end
							end
							-- RetributionKilling (0-60sec)
							if PS_paysound == true then
								RetributionKill = false
								for i = 1, table.getn(PVPSound_RetributionQueue) do
									if (string.upper(PVPSound_RetributionQueue[i].dir) == string.upper(KilledWho)) then
										RetributionKill = true
									end
								end
								if RetributionKill == true then
									PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Retribution.mp3")
								end
							end
							-- MultiKilling
							if PS_multikillsound == true then
								if (GetTime() - PS_lastkill <= PS_mkill_time) then
									PS_firstdkill = PS_lastkill
									if (GetTime() - PS_firstdkill > PS_mkill_time) then
										PS_mkills = 1
									elseif (GetTime() - PS_firstdkill <= PS_mkill_time) then
										PS_mkills = PS_mkills + 1
										if (PS_mkills == 2) then
											PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\DoubleKill.mp3")
										elseif (PS_mkills == 3) then
											PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\MultiKill.mp3")
										elseif (PS_mkills == 4) then
											PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\MegaKill.mp3")
										elseif (PS_mkills == 5) then
											PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\UltraKill.mp3")
										elseif (PS_mkills > 5) then
											PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\MonsterKill.mp3")
										end
									end
								end
							end
						end
					elseif (GetTime() - PS_lastkill > PS_kill_time) then
						-- If triggers a kill after the Killing Time (60sec) than replay the last KillSound without emote
						PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\"..PS_file)
						-- RetributionKilling (60-90sec)
						if (GetTime() - PS_lastkill < PS_pkill_time) then
							if PS_paysound == true then
								RetributionKill = false
								for i = 1, table.getn(PVPSound_RetributionQueue) do
									if (string.upper(PVPSound_RetributionQueue[i].dir) == string.upper(KilledWho)) then
										RetributionKill = true
									end
								end
								if RetributionKill == true then
									PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Retribution.mp3")
								end
							end
						end
					end
				end
				-- Reseting MultiKilling
				if (not PS_lastkill or (GetTime() - PS_lastkill > PS_mkill_time)) then
					PS_mkills = 1
				end
				PS_lastkill = GetTime()
			elseif (eventType == "SPELL_AURA_APPLIED") then
				-- Alliance RBG buff
				if spellId == 81748 and destGUID == player and AlreadyPlaySound ~= "Yes" then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\PlayYouAreOnBlue.mp3")
					AlreadyPlaySound = "Yes"
				end
				-- Horde RBG buff
				if spellId == 81744 and destGUID == player and AlreadyPlaySound ~= "Yes" then
					PVPSound_AddToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\GameStatus\\PlayYouAreOnRed.mp3")
					AlreadyPlaySound = "Yes"
				end
			 -- PaybackKilling
			elseif (eventType == "SWING_DAMAGE" and fromEnemy and destGUID == player and tonumber(swingOverkill) ~= nil and tonumber(swingOverkill) ~= -1) then
				-- If the killer is not nil
				if sourceName ~= nil then
					-- If the killer is not the player
					if sourceName ~= UnitName("player") then
						KilledMe = sourceName
						if PS_paysound == true then
							PVPSound_AddToRetributionQueue(KilledMe)
							PaybackKill = false
							for i = 1, table.getn(PVPSound_PaybackQueue) do
								if (string.upper(PVPSound_PaybackQueue[i].dir) == string.upper(KilledMe)) then
									PaybackKill = true
								end
							end
							if PaybackKill == true then
								PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Payback.mp3")
							end
						end
					end
				end
			elseif ((eventType == "RANGE_DAMAGE" or eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE") and fromEnemy and destGUID == player and tonumber(spellOverkill) ~= nil and tonumber(spellOverkill) ~= -1) then
				-- If the killer is not nil
				if sourceName ~= nil then
					-- If the killer is not the player
					if sourceName ~= UnitName("player") then
						KilledMe = sourceName
						if PS_paysound == true then
							PVPSound_AddToRetributionQueue(KilledMe)
							PaybackKill = false
							for i = 1, table.getn(PVPSound_PaybackQueue) do
								if (string.upper(PVPSound_PaybackQueue[i].dir) == string.upper(KilledMe)) then
									PaybackKill = true
								end
							end
							if PaybackKill == true then
								PVPSound_AddKillToQueue("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Spree\\Payback.mp3")
							end
						end
					end
				end
			end
		end -- PS_killsound == true
		if PS_emote == true then
			if (eventType == "PARTY_KILL" and sourceGUID == player and toEnemy) then
				if PS_emotemode == true then
					SendChatMessage(PS_msg, "EMOTE")
				elseif PS_emotemode == false then
					print("|cFFFFFF00"..sourceName.." "..PS_msg.."|cFFFFFFFF")
				end
			end
		end
	end
end

frame:SetScript("OnEvent", PVPSound_OnEvent)

function PVPSound_Command(arg1)
	arg1 = strlower(arg1)
	if arg1 == "pvp" then
		PS_pvpmode = not PS_pvpmode
		if PS_pvpmode == true then
			print("|cFF50C0FF"..Opt_Mode..": |cFFADFF2F"..Opt_PVP.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_Mode..": |cFFFF4500"..Opt_PVE.."|cFFFFFFFF")
		end
	elseif arg1 == "emote" then
		PS_emote = not PS_emote
		if PS_emote == true then
			print("|cFF50C0FF"..Opt_Emotes..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_Emotes..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
	elseif arg1 == "emotemode" then
		PS_emotemode = not PS_emotemode
		if PS_emotemode == true then
			print("|cFF50C0FF"..Opt_EmoteMode..": |cFFADFF2F"..Opt_Emote.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_EmoteMode..": |cFFFF4500"..Opt_ChatMessage.."|cFFFFFFFF")
		end
	elseif arg1 == "deathmessage" then
		PS_deathmsg = not PS_deathmsg
		if PS_deathmsg == true then
			print("|cFF50C0FF"..Otp_DeathMsg..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Otp_DeathMsg..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
	elseif arg1 == "killsound" then
		PS_killsound = not PS_killsound
		if PS_killsound == true then
			print("|cFF50C0FF"..Opt_KillSound..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_KillSound..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
	elseif arg1 == "paysound" then
		PS_paysound = not PS_paysound
		if PS_paysound == true then
			print("|cFF50C0FF"..Opt_PaySound..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_PaySound..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
	elseif arg1 == "multikillsound" then
		PS_multikillsound = not PS_multikillsound
		if PS_multikillsound == true then
			print("|cFF50C0FF"..Opt_MultiKillSound..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_MultiKillSound..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
	elseif arg1 == "bgsound" then
		PS_bgsound = not PS_bgsound
		if PS_bgsound == true then
			print("|cFF50C0FF"..Opt_BgSound..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_BgSound..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
	elseif arg1 == "soundengine" then
		PS_soundengine = not PS_soundengine
		if PS_soundengine == true then
			print("|cFF50C0FF"..Opt_SoundEngine..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_SoundEngine..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
	elseif arg1 == "channelmaster" then
		PS_channel = "Master"
		if PS_channel == "Master" then
			print("|cFF50C0FF"..Opt_Channel..": |cFFADFF2F"..Opt_Master.."|cFFFFFFFF")
		end
	elseif arg1 == "channelsound" then
		PS_channel = "Sound"
		if PS_channel == "Sound" then
			print("|cFF50C0FF"..Opt_Channel..": |cFFFF4500"..Opt_Sound.."|cFFFFFFFF")
		end
	elseif arg1 == "channelmusic" then
		PS_channel = "Music"
		if PS_channel == "Music" then
			print("|cFF50C0FF"..Opt_Channel..": |cFFFF4500"..Opt_Music.."|cFFFFFFFF")
		end
	elseif arg1 == "channelambience" then
		PS_channel = "Ambience"
		if PS_channel == "Ambience" then
			print("|cFF50C0FF"..Opt_Channel..": |cFFFF4500"..Opt_Ambience.."|cFFFFFFFF")
		end
	elseif arg1 == "test" then
		print("|cFF50C0FF"..Opt_Test.."...")
		PlaySoundFile("Interface\\AddOns\\PVPSound\\Sounds\\UnrealTournament3\\Test\\Pancake.mp3", ""..PS_channel.."")
	elseif arg1 == "reset" then
		PVPSound_ClearSoundQueue()
		PVPSound_ClearKillSoundQueue()
		PVPSound_ClearPaybackQueue()
		PVPSound_ClearRetributionQueue()
		PS_timer_reset = true
		PS_killcounter = 0
		print("|cFF50C0FF"..Opt_Reset..".")
	elseif arg1 == "help" then
		print("|cFFFFA500PVPSound "..GetAddOnMetadata("PVPSound", "Version").." "..Opt_cmdlist.."|cFFFFFFFF")
		print("|cFF50C0FF/ps - |cFFFFFFA0"..Opt_helpstatus.."|cFFFFFFFF")
		print("|cFF50C0FF/ps pvp - |cFFFFFFA0"..Opt_helpmode.."|cFFFFFFFF")
		print("|cFF50C0FF/ps emote - |cFFFFFFA0"..Opt_helpemote.."|cFFFFFFFF")
		print("|cFF50C0FF/ps emotemode - |cFFFFFFA0"..Opt_helpemotemode.."|cFFFFFFFF")
		print("|cFF50C0FF/ps deathmessage - |cFFFFFFA0"..Opt_helpdeathmsg.."|cFFFFFFFF")
		print("|cFF50C0FF/ps killsound - |cFFFFFFA0"..Opt_helpkillsound.."|cFFFFFFFF")
		print("|cFF50C0FF/ps paysound - |cFFFFFFA0"..Opt_helppaysound.."|cFFFFFFFF")
		print("|cFF50C0FF/ps multikillsound - |cFFFFFFA0"..Opt_helpmultikillsound.."|cFFFFFFFF")
		print("|cFF50C0FF/ps bgsound - |cFFFFFFA0"..Opt_helpbgsound.."|cFFFFFFFF")
		print("|cFF50C0FF/ps soundengine - |cFFFFFFA0"..Opt_helpsoundengine.."|cFFFFFFFF")
		print("|cFF50C0FF/ps channel'channelname' - |cFFFFFFA0"..Opt_helpchannel.."|cFFFFFFFF")
		print("|cFF50C0FF/ps test - |cFFFFFFA0"..Opt_helptest.."|cFFFFFFFF")
		print("|cFF50C0FF/ps reset - |cFFFFFFA0"..Opt_helpreset.."|cFFFFFFFF")
		print("|cFF50C0FF/ps help - |cFFFFFFA0"..Opt_helpcmdlist.."|cFFFFFFFF")
	else
		print("|cFFFFA500PVPSound "..GetAddOnMetadata("PVPSound", "Version").." "..Opt_helpinput.."|cFFFFFFFF")
		print("|cFF50C0FF"..Opt_kills..": |cFFADFF2F"..PS_killcounter.."|cFFFFFFFF")
		if PS_pvpmode == true then
			print("|cFF50C0FF"..Opt_Mode..": |cFFADFF2F"..Opt_PVP.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_Mode..": |cFFFF4500"..Opt_PVE.."|cFFFFFFFF")
		end
		if PS_emote == true then
			print("|cFF50C0FF"..Opt_Emotes..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_Emotes..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
		if PS_emotemode == true then
			print("|cFF50C0FF"..Opt_EmoteMode..": |cFFADFF2F"..Opt_Emote.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_EmoteMode..": |cFFFF4500"..Opt_ChatMessage.."|cFFFFFFFF")
		end
		if PS_deathmsg == true then
			print("|cFF50C0FF"..Otp_DeathMsg..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Otp_DeathMsg..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
		if PS_killsound == true then
			print("|cFF50C0FF"..Opt_KillSound..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_KillSound..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
		if PS_paysound == true then
			print("|cFF50C0FF"..Opt_PaySound..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_PaySound..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
		if PS_multikillsound == true then
			print("|cFF50C0FF"..Opt_MultiKillSound..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_MultiKillSound..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
		if PS_bgsound == true then
			print("|cFF50C0FF"..Opt_BgSound..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_BgSound..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
		if PS_soundengine == true then
			print("|cFF50C0FF"..Opt_SoundEngine..": |cFFADFF2F"..Opt_Enable.."|cFFFFFFFF")
		else
			print("|cFF50C0FF"..Opt_SoundEngine..": |cFFFF4500"..Opt_Disable.."|cFFFFFFFF")
		end
		if PS_channel == "Master" then
			print("|cFF50C0FF"..Opt_Channel..": |cFFADFF2F"..Opt_Master.."|cFFFFFFFF")
		elseif PS_channel == "Sound" then
			print("|cFF50C0FF"..Opt_Channel..": |cFFFF4500"..Opt_Sound.."|cFFFFFFFF")
		elseif PS_channel == "Music" then
			print("|cFF50C0FF"..Opt_Channel..": |cFFFF4500"..Opt_Music.."|cFFFFFFFF")
		elseif PS_channel == "Ambience" then
			print("|cFF50C0FF"..Opt_Channel..": |cFFFF4500"..Opt_Ambience.."|cFFFFFFFF")
		end
	end
end