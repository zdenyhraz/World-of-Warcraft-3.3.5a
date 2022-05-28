PVPSound_SoundQueue = { }
PVPSound_KillSoundQueue = { }
PVPSound_NextUpdate = 0.3
PVPSound_NextKillUpdate = 0.3

-- SoundQueue
function PVPSound_AddToQueue(file, unique)
	-- This function will add file to the sound queue to be played
	-- If the sound could not be found in the sound lengths table then just play it
	-- If a unique sound is already in the queue then don't add it (if the sound is already playing then the sound is still added to the queue)
	local i
	local filefoundlength
	-- This is a table of soundlengths according to the selected SoundPack. UnrealTournament3 = PVPSound_UnrealTournament3Durations
	if (PS_soundpack == "UnrealTournament3") and (PS_soundengine == true) then
		local soundlengthtable = getglobal("PVPSound_"..PS_soundpack.."Durations")
		-- Is .mp3 at the end?
		if ((not string.find(file,".mp3",string.len(file) - 3)) and (not string.find(file,".MP3",string.len(file) - 3)) and (not string.find(file,".mP3",string.len(file) - 3)) and (not string.find(file,".Mp3",string.len(file) - 3))) then
			-- Nope so add it
			file = file..".mp3"
		end
		--[[if (unique) then
			for i = 1, table.getn(PVPSound_SoundQueue) do
				if (string.upper(PVPSound_SoundQueue[i].dir) == string.upper(file)) then
					-- The unique sound was already found in the queue
					return
				end
			end
		end]]--
		for i = 1, table.getn(soundlengthtable) do
			if (string.upper(soundlengthtable[i].dir) == string.upper(file)) then
				filefoundlength = soundlengthtable[i].duration
			end
		end
		if (filefoundlength) then
			local temptable = {dir = file, length = filefoundlength}
			-- Insert the sound into the queue
			table.insert(PVPSound_SoundQueue, temptable)
		else
			-- Not in the sound table so just play it
			PlaySoundFile(file, ""..PS_channel.."")
		end
	else
		-- We've got lengths for UnrealTournament3 SoundPack only. If that's not selected or soundengine is disabled then just play it
		PlaySoundFile(file, ""..PS_channel.."")
	end
end

function PVPSound_ClearSoundQueue()
	-- This function will clear all the sound queue
	-- This is used for example in the end of a battle where you no longer need to hear any more announcements
	local i
	for i = table.getn(PVPSound_SoundQueue), 1 do
		table.remove(PVPSound_SoundQueue, i)
	end
end

function PVPSound_PlayNextSound()
	-- This function will play the next sound in the queue and return how long that sound will play
	-- If there is no sound in the queue it will just return 0.3
	if (PVPSound_SoundInQueue()) then
		local x
		PlaySoundFile(PVPSound_SoundQueue[1].dir, ""..PS_channel.."")
		x = PVPSound_SoundQueue[1].length
		table.remove(PVPSound_SoundQueue,1)
		return x
	else
		return 0.3
	end
end

function PVPSound_SoundInQueue()
	-- This function will return 1 if there is a sound in the queue, nil otherwise
	if (table.getn(PVPSound_SoundQueue) > 0) then
		return 1
	else
		return nil
	end
end

function PVPSound_UpdateSoundEngine(self, elapsed)
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
	while (self.TimeSinceLastUpdate > PVPSound_NextUpdate) do
		self.TimeSinceLastUpdate = self.TimeSinceLastUpdate - PVPSound_NextUpdate
		PVPSound_NextUpdate = PVPSound_PlayNextSound()
	end
end

-- KillSoundQueue
function PVPSound_AddKillToQueue(file, unique)
	-- This function will add file to the sound queue to be played
	-- If the sound could not be found in the sound lengths table then just play it
	-- If a unique sound is already in the queue then don't add it (if the sound is already playing then the sound is still added to the queue)
	local i
	local filekillfoundlength
	-- This is a table of soundlengths according to the selected SoundPack. UnrealTournament3 = PVPSound_UnrealTournament3Durations
	if (PS_soundpack == "UnrealTournament3") and (PS_soundengine == true) then
		local killsoundlengthtable = getglobal("PVPSound_"..PS_soundpack.."Durations")
		-- Is .mp3 at the end?
		if ((not string.find(file,".mp3",string.len(file) - 3)) and (not string.find(file,".MP3",string.len(file) - 3)) and (not string.find(file,".mP3",string.len(file) - 3)) and (not string.find(file,".Mp3",string.len(file) - 3))) then
			-- Nope so add it
			file = file..".mp3"
		end
		--[[if (unique) then
			for i = 1, table.getn(PVPSound_KillSoundQueue) do
				if (string.upper(PVPSound_KillSoundQueue[i].dir) == string.upper(file)) then
					-- The unique sound was already found in the queue
					return
				end
			end
		end]]--
		for i = 1, table.getn(killsoundlengthtable) do
			if (string.upper(killsoundlengthtable[i].dir) == string.upper(file)) then
				filekillfoundlength = killsoundlengthtable[i].duration
			end
		end
		if (filekillfoundlength) then
			local killtemptable = {dir = file, length = filekillfoundlength}
			-- Insert the sound into the queue
			table.insert(PVPSound_KillSoundQueue, killtemptable)
		else
			-- Not in the sound table so just play it
			PlaySoundFile(file, ""..PS_channel.."")
		end
	else
		-- We've got lengths for UnrealTournament3 SoundPack only. If that's not selected or soundengine is disabled then just play it
		PlaySoundFile(file, ""..PS_channel.."")
	end
end

function PVPSound_ClearKillSoundQueue()
	-- This function will clear all the sound queue
	-- This is used for example in the end of a battle where you no longer need to hear any more announcements
	local i
	for i = table.getn(PVPSound_KillSoundQueue), 1 do
		table.remove(PVPSound_KillSoundQueue, i)
	end
end

function PVPSound_PlayNextKillSound()
	-- This function will play the next sound in the queue and return how long that sound will play
	-- If there is no sound in the queue it will just return 0.3
	if (PVPSound_KillSoundInQueue()) then
		local x
		PlaySoundFile(PVPSound_KillSoundQueue[1].dir, ""..PS_channel.."")
		x = PVPSound_KillSoundQueue[1].length
		table.remove(PVPSound_KillSoundQueue,1)
		return x
	else
		return 0.3
	end
end

function PVPSound_KillSoundInQueue()
	-- This function will return 1 if there is a sound in the queue, nil otherwise
	if (table.getn(PVPSound_KillSoundQueue) > 0) then
		return 1
	else
		return nil
	end
end

function PVPSound_UpdateKillSoundEngine(self, elapsed)
	self.TimeSinceLastKillUpdate = self.TimeSinceLastKillUpdate + elapsed
	while (self.TimeSinceLastKillUpdate > PVPSound_NextKillUpdate) do
		self.TimeSinceLastKillUpdate = self.TimeSinceLastKillUpdate - PVPSound_NextKillUpdate
		PVPSound_NextKillUpdate = PVPSound_PlayNextKillSound()
	end
end