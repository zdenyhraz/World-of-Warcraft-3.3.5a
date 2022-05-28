PVPSound_PaybackQueue = { }
PVPSound_RetributionQueue = { }
PVPSound_NextPayUpdate = 90
PVPSound_NextRetUpdate = 90

-- Payback
function PVPSound_AddToPaybackQueue(name)
	-- This function will add a name to the Payback queue
	if (name) then
		AlreadyInQueue = false
		for i = 1, table.getn(PVPSound_PaybackQueue) do
			if (string.upper(PVPSound_PaybackQueue[i].dir) == string.upper(name)) then
				-- The name was already found in the queue
				AlreadyInQueue = true
			end
		end
	end
	if (AlreadyInQueue ~= true) then
		local paytemptable = {dir = name}
		table.insert(PVPSound_PaybackQueue, paytemptable)
	end
end

function PVPSound_ClearPaybackQueue()
	-- This function will clear all possible Payback names from the queue
	local i
	for i = table.getn(PVPSound_PaybackQueue), 1 do
		table.remove(PVPSound_PaybackQueue, i)
	end
end

function PVPSound_DeleteFirstPayback()
	-- This function will delete the first Payback name in the queue and return 90, if its empty its returns 90 too
	if (PVPSound_PaybackInQueue()) then
		table.remove(PVPSound_PaybackQueue,1)
		return 90
	else
		return 90
	end
end

function PVPSound_PaybackInQueue()
	-- This function will return 1 if there is a name in the queue, nil otherwise
	if (table.getn(PVPSound_PaybackQueue) > 0) then
		return 1
	else
		return nil
	end
end

function PVPSound_UpdatePaySound(self, elapsed)
	self.TimeSinceLastPayUpdate = self.TimeSinceLastPayUpdate + elapsed
	while (self.TimeSinceLastPayUpdate > PVPSound_NextPayUpdate) do
		self.TimeSinceLastPayUpdate = self.TimeSinceLastPayUpdate - PVPSound_NextPayUpdate
		PVPSound_NextPayUpdate = PVPSound_DeleteFirstPayback()
	end
end

-- Retribution
function PVPSound_AddToRetributionQueue(name)
	-- This function will add a name to the Retribution queue
	if (name) then
		AlreadyInQueue = false
		for i = 1, table.getn(PVPSound_RetributionQueue) do
			if (string.upper(PVPSound_RetributionQueue[i].dir) == string.upper(name)) then
				-- The name was already found in the queue
				AlreadyInQueue = true
			end
		end
	end
	if (AlreadyInQueue ~= true) then
		local rettemptable = {dir = name}
		table.insert(PVPSound_RetributionQueue, rettemptable)
	end
end

function PVPSound_ClearRetributionQueue()
	-- This function will clear all possible Retribution names from the queue
	local i
	for i = table.getn(PVPSound_RetributionQueue), 1 do
		table.remove(PVPSound_RetributionQueue, i)
	end
end

function PVPSound_DeleteFirstRetribution()
	-- This function will delete the first Retribution name in the queue and return 90, if its empty its returns 90 too
	if (PVPSound_RetributionInQueue()) then
		table.remove(PVPSound_RetributionQueue,1)
		return 90
	else
		return 90
	end
end

function PVPSound_RetributionInQueue()
	-- This function will return 1 if there is a name in the queue, nil otherwise
	if (table.getn(PVPSound_RetributionQueue) > 0) then
		return 1
	else
		return nil
	end
end

function PVPSound_UpdateRetSound(self, elapsed)
	self.TimeSinceLastRetUpdate = self.TimeSinceLastRetUpdate + elapsed
	while (self.TimeSinceLastRetUpdate > PVPSound_NextRetUpdate) do
		self.TimeSinceLastRetUpdate = self.TimeSinceLastRetUpdate - PVPSound_NextRetUpdate
		PVPSound_NextRetUpdate = PVPSound_DeleteFirstRetribution()
	end
end