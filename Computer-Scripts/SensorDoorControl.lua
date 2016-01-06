
iside = "top"
rside = "bottom"
p = peripheral.wrap("openperipheral_sensor_0")
pir = 0

function scanPlayers ()
	players = p.getPlayers()
	for key,value in pairs(players) do
		pir = pir + 1
	end
	for i = 1, pir do
		if players[i]["name"] == "Cooldrago" or players[i]["name"] == "sasnisauter" then
			redstone.setOutput(rside, false)
		else
			redstone.setOutput(rside, true)
		end	
	end
	if pir == 0 then
		redstone.setOutput(rside, true)
	end		
end

while true do	
	if 	redstone.getInput(iside) then
		redstone.setOutput(rside, true)
	else	
		scanPlayers()
		pir = 0
	end
	sleep(0.5)
end	

