function PVPSound_DataOnLoad()
	dataframe:RegisterEvent("CHAT_MSG_ADDON")
end

dataframe = CreateFrame("Frame", "PVPSound_DataFrame")

-- PVPSound Addon Data Shareing
function PVPSound_DataOnEvent(self, event, prefix, message, channel, sender)
	if (event == "CHAT_MSG_ADDON") then
		-- If the Sent Data is from the registered prefix
		if prefix == "PVPSound" then
			-- If the sender is not nil and its not the player
			if sender ~= nil and sender ~= UnitName("player") then
				-- Kill Data Share
				if PS_emote == true then
				-- If sender is from CrossRealm
					if (string.find(sender,"-")) then
						local PlayerName = tostring(string.match(sender, "(.+)-"))
						if message == "FirstBloodMale" then
							print("|cFFFFA500"..PlayerName.." "..MSG_FirstBloodMale.."|cFFFFFFFF")
						elseif message == "FirstBloodFemale" then
							print("|cFFFFA500"..PlayerName.." "..MSG_FirstBloodFemale.."|cFFFFFFFF")
						elseif message == "KillingSpree" then
							print("|cFFFFA500"..PlayerName.." "..MSG_KillingSpree.."|cFFFFFFFF")
						elseif message == "Rampage" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Rampage.."|cFFFFFFFF")
						elseif message == "Dominating" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Dominating.."|cFFFFFFFF")
						elseif message == "Unstoppable" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Unstopable.."|cFFFFFFFF")
						elseif message == "Godlike" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Godlike.."|cFFFFFFFF")
						elseif message == "MASSACRE" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Massacre.."|cFFFFFFFF")
						end
					-- If the sender is not from CrossRealm and his/her Emote is toggled off or Emote is on but in Emotemode
					else
						local PlayerName = tostring(sender)
						if message == "FirstBloodMaleEmote" then
							print("|cFFFFA500"..PlayerName.." "..MSG_FirstBloodMale.."|cFFFFFFFF")
						elseif message == "FirstBloodFemaleEmote" then
							print("|cFFFFA500"..PlayerName.." "..MSG_FirstBloodFemale.."|cFFFFFFFF")
						elseif message == "KillingSpreeEmote" then
							print("|cFFFFA500"..PlayerName.." "..MSG_KillingSpree.."|cFFFFFFFF")
						elseif message == "RampageEmote" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Rampage.."|cFFFFFFFF")
						elseif message == "DominatingEmote" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Dominating.."|cFFFFFFFF")
						elseif message == "UnstoppableEmote" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Unstopable.."|cFFFFFFFF")
						elseif message == "GodlikeEmote" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Godlike.."|cFFFFFFFF")
						elseif message == "MASSACREEmote" then
							print("|cFFFFA500"..PlayerName.." "..MSG_Massacre.."|cFFFFFFFF")
						end
					end
				end
				-- Death Data Share
				if PS_deathmsg == true then
					if message ~= nil then
						Spree = tostring(string.match(message, "(.+):"))
						KillerNameServer = (string.match(message, ":(.+)"))
					end
					if (string.find(KillerNameServer,"-")) then
						KillerName = tostring(string.match(KillerNameServer, "(.+)-"))
					else
						KillerName = tostring(KillerNameServer)
					end
					if KillerName ~= UnitName("player") then
						if Spree == "First Blood" then
							print("|cFFFF4500"..sender..""..MSG_FirstBlood_Over.." "..KillerName..".|cFFFFFFFF")
						elseif Spree == "Killing Spree" then
							print("|cFFFF4500"..sender..""..MSG_KillingSpree_Over.." "..KillerName..".|cFFFFFFFF")
						elseif Spree == "Rampage" then
							print("|cFFFF4500"..sender..""..MSG_Rampage_Over.." "..KillerName..".|cFFFFFFFF")
						elseif Spree == "Dominating" then
							print("|cFFFF4500"..sender..""..MSG_Dominating_Over.." "..KillerName..".|cFFFFFFFF")
						elseif Spree == "Unstoppable" then
							print("|cFFFF4500"..sender..""..MSG_Unstoppable_Over.." "..KillerName..".|cFFFFFFFF")
						elseif Spree == "Godlike" then
							print("|cFFFF4500"..sender..""..MSG_Godlike_Over.." "..KillerName..".|cFFFFFFFF")
						elseif Spree == "MASSACRE" then
							print("|cFFFF4500"..sender..""..MSG_Massacre_Over.." "..KillerName..".|cFFFFFFFF")
						end
					end
				end
			end
		end
	end
end

dataframe:SetScript("OnEvent", PVPSound_DataOnEvent)