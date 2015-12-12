function forward()
  turtle.dig()
  turtle.forward()
end

function column()  
  while turtle.detectUp() do
    turtle.digUp()
    turtle.up()
  end
  while not turtle.detectDown() do
    turtle.down()
  end
end 
   
function turnRight()
  turtle.turnRight()
  forward()
  turtle.turnRight()
end

function turnLeft()
  turtle.turnLeft()
  forward()
  turtle.turnLeft()
end

function line()
  for i = 1,Laenge - 1 do
    column()
    forward()
  end
  column()
end

function pack()
  line()
  turnRight()
  line()
  turnLeft()
end

print("Laenge?")
Laenge = read()
print("Breite? Nur gerade Zahlen!")
Breite = read() / 2
forward()
for i = 1,Breite do
  pack()
end  
