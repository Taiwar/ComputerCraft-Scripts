rside = "right" -- Side of Draconic Evolution Sun Dial

while true do
	time = os.time()
	-- if none of the while loops are true aka it is day and the sun is shining, nothing will happen
	-- otherwise the loops will activate the sun dial until the night is over
	while time < 6 do -- between 18 and 6 is night so activate sun dial
		print("Time: "..time.." is less than 6, fast forwarding...")
		redstone.setOutput(rside, true)
		sleep(0.5)
		redstone.setOutput(rside, false)
		time = os.time()
	end
	while time > 18 do -- 18 is sunset so activate sun dial
		print("Time: "..time.." is more than 18, fast forwarding...")
		redstone.setOutput(rside, true)
		sleep(0.5)
		redstone.setOutput(rside, false)
		time = os.time()		
	end
	sleep(0.5)
end			
