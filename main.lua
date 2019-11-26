local screenWidth, screenHeight

-- constants
local NUMBER_ENEMI = 10
local ENEMI_SPEED = 100
local SHIP_SPEED = 600
local SPRITES_SIZE = 20
local SHOOT_COOLDOWN = 0.2
local MAX_PARTICLES = 30
local PARTICLES_GRAVITY = 300
local PARTICLES_SPEED = 300
local FADE_SPEED = 0.7
local MAX_STARS = 1000
local STARS_MAX_RADIUS = 1
local STARS_MAX_SPEED = 15

local ship
local enemiList
local laserSound
local explosionSound
local bumpSound
local score
local currentScreen
local hiScore
local particles
local stars


function love.load()
  loadResources()
  initGame()
end


function love.update(dt)
  if currentScreen == 'title' then
    updateTitle(dt)
  elseif currentScreen == 'game' then
    updateGame(dt)
  else -- currentScreen == 'gameover'
    updateGameOver(dt)
  end
end


function love.draw()
  if currentScreen == 'title' then
    drawTitle()
  elseif currentScreen == 'game' then
    drawGame()
  else -- currentScreen == 'gameover'
    drawGameOver()
  end
end


function love.keypressed(key)
  if key == 'escape' then
      love.event.quit()
  end
end


function loadResources()
  screenWidth, screenHeight = love.graphics.getDimensions()
  
  currentScreen = 'title'
  
  laserSound = love.audio.newSource('laser.wav', 'static')
  explosionSound = love.audio.newSource('explosion.wav', 'static')
  bumpSound = love.audio.newSource('bump.wav', 'static')
  
  standardFont = love.graphics.newFont('FreePixel.ttf', 50, 'mono')
  titleFont = love.graphics.newFont('FreePixel.ttf', 100, 'mono')
  bigFont = love.graphics.newFont('FreePixel.ttf', 50, 'mono')
  
  particles = {}
  for i = 1, NUMBER_ENEMI do
    particles[i] = {}
  end
  
  stars = {}
  for i = 1, MAX_STARS do
    stars[i] = {
      x = love.math.random(screenWidth),
      y = love.math.random(screenHeight),
      radius = love.math.random() * STARS_MAX_RADIUS,
      dy = love.math.random() * STARS_MAX_SPEED
      }
  end
  
  hiScore = 0
end


function initGame()
  ship = {
    x = love.mouse.getX(),
    y = love.mouse.getY(),
    shoot = false,
    canShoot = true,
    shootTimer = SHOOT_COOLDOWN
    }
  
  enemiList = {}
  for i = 1, NUMBER_ENEMI do
    addEnemi(enemiList, randomEnemi())
  end
  
  resetScore()
end


function updateTitle(dt)
  if love.mouse.isDown(1) then
    currentScreen = 'game'
  end
end


function updateGame(dt)
  updateShip(dt)
  updateEnemies(dt)
  for i = 1, NUMBER_ENEMI do
    checkCollision(enemiList[i], i)
  end
  updateParticles(dt)
  updateStars(dt)
end


function updateGameOver(dt)
  if love.mouse.isDown(1) then
    currentScreen = 'game'
    initGame()
  end
end


function drawTitle()
  love.graphics.setFont(titleFont)
  love.graphics.printf('ShootEm', 0, screenHeight / 3, screenWidth, 'center')
  love.graphics.setFont(bigFont)
  love.graphics.printf('click to play', 0, 2 * screenHeight / 3, screenWidth, 'center')
end


function drawGame()
  drawShip()
  drawLaser()
  drawEnemies()
  drawScore()
  drawParticles()
  drawStars()
end


function drawGameOver()
  love.graphics.setFont(titleFont)
  love.graphics.printf('GAME OVER', 0, screenHeight / 3, screenWidth, 'center')
  love.graphics.setFont(bigFont)
  love.graphics.printf('Hi-score: '..hiScore, 0, screenHeight / 2, screenWidth, 'center')
  love.graphics.printf('click to play again', 0, 2 * screenHeight / 3, screenWidth, 'center')
end


function drawShip()
  love.graphics.circle('line', ship.x, ship.y, SPRITES_SIZE / 2)
end


function updateStars(dt)
  for i = 1, MAX_STARS do
    stars[i].y = stars[i].y + stars[i].dy * dt
    if stars[i].y > screenHeight + STARS_MAX_RADIUS / 2 then
      stars[i].y = -STARS_MAX_RADIUS / 2
    end
  end
end


function drawStars()
  for i = 1, MAX_STARS do
    love.graphics.push('all')
    love.graphics.setColor(1, 1, 1, love.math.random())
    love.graphics.circle('fill', stars[i].x, stars[i].y, stars[i].radius)
    love.graphics.pop()
  end
end


function drawLaser()
  if ship.shoot then
    love.graphics.line(ship.x, ship.y, ship.x, 0)
  end
end


function drawEnemies()
  for i = 1, NUMBER_ENEMI do
    --love.graphics.rectangle('line', enemiList[i].x - SPRITES_SIZE / 2, enemiList[i].y - SPRITES_SIZE / 2, SPRITES_SIZE, SPRITES_SIZE)
    love.graphics.polygon('line',
      enemiList[i].x + math.cos(enemiList[i].angle) * length(SPRITES_SIZE, SPRITES_SIZE) / 2, 
      enemiList[i].y + math.sin(enemiList[i].angle) * length(SPRITES_SIZE, SPRITES_SIZE) / 2,
      enemiList[i].x + math.cos(enemiList[i].angle + math.pi / 2) * length(SPRITES_SIZE, SPRITES_SIZE) / 2, 
      enemiList[i].y + math.sin(enemiList[i].angle + math.pi / 2) * length(SPRITES_SIZE, SPRITES_SIZE) / 2,
      enemiList[i].x + math.cos(enemiList[i].angle + math.pi) * length(SPRITES_SIZE, SPRITES_SIZE) / 2, 
      enemiList[i].y + math.sin(enemiList[i].angle + math.pi) * length(SPRITES_SIZE, SPRITES_SIZE) / 2,
      enemiList[i].x + math.cos(enemiList[i].angle + 3 * math.pi / 2) * length(SPRITES_SIZE, SPRITES_SIZE) / 2, 
      enemiList[i].y + math.sin(enemiList[i].angle + 3 * math.pi / 2) * length(SPRITES_SIZE, SPRITES_SIZE) / 2)
  end
end


function drawScore()
  love.graphics.print('Score :'..tostring(score), 50, 50)
end


function drawParticles()
  for i = 1, NUMBER_ENEMI do
    for j = 1, MAX_PARTICLES do
      if particles[i][j] ~= nil then
        love.graphics.push('all')
        love.graphics.setColor(1, 1, 1, particles[i][j].alpha)
        love.graphics.points(particles[i][j].x, particles[i][j].y)
        love.graphics.pop()
      end
    end
  end
end


function normalize(x, y)
  local length = length(x, y)
  local tempX = x / length
  local tempY = y / length
  return tempX, tempY
end


function length(x, y)
  return math.sqrt(x * x + y * y)
end


function addEnemi(enemiList, enemi)
  table.insert(enemiList, enemi)
end


function randomEnemi()
  local tempX = love.math.random(screenWidth - SPRITES_SIZE) + SPRITES_SIZE / 2
  return {
    x = tempX,
    y = -SPRITES_SIZE / 2,
    angle = love.math.random() * 2 * math.pi,
    angularSpeed = (love.math.random() - 0.5) * 4 * math.pi
    }
end


function updateShip(dt)
  if ship.shoot then
    ship.shoot = false
  end
  
  local shipToMouseX = love.mouse.getX() - ship.x
  local shipToMouseY = love.mouse.getY() - ship.y
  local shipToMouseXNormalized, shipToMouseYNormalized = normalize(shipToMouseX, shipToMouseY)
  if length(shipToMouseX, shipToMouseY) <= SPRITES_SIZE then
    ship.x = love.mouse.getX()
    ship.y = love.mouse.getY()
  else
    ship.x = ship.x + shipToMouseXNormalized * SHIP_SPEED * dt
    ship.y = ship.y + shipToMouseYNormalized * SHIP_SPEED * dt
  end
  
  ship.shootTimer = ship.shootTimer + dt
  if ship.shootTimer >= SHOOT_COOLDOWN and love.mouse.isDown(1) then
    ship.shoot = true
    ship.shootTimer = 0
    laserSound:stop()
    laserSound:play()
  end
end


function updateEnemies(dt)
  for i = 1, NUMBER_ENEMI do
    updateEnemi(enemiList[i], dt)
  end
end


function updateEnemi(enemi, dt)
  enemi.y = enemi.y + ENEMI_SPEED * dt
  enemi.angle = enemi.angle + enemi.angularSpeed * dt
end


function checkCollision(enemi, index)
  if enemi.y >= screenHeight + SPRITES_SIZE / 2 then
    score = score - 50
    enemiList[index] = randomEnemi()
    bumpSound:stop()
    bumpSound:play()
  end
  if ship.shoot and enemi.y >= 0 and math.abs(enemi.x - ship.x) <= SPRITES_SIZE / 2 then
    score = score + 100
    setParticles(index, enemiList[index].x, enemiList[index].y)
    enemiList[index] = randomEnemi()
    explosionSound:stop()
    explosionSound:play()
  end
  if enemiIsCollindingWithShip(enemi) then
    explosionSound:stop()
    explosionSound:play()
    if hiScore <= score then
      hiScore = score
    end
    currentScreen = 'gameover'
  end
end


function updateParticles(dt)
  for i = 1, NUMBER_ENEMI do
    for j = 1, MAX_PARTICLES do
      if particles[i][j] ~= nil then
        particles[i][j].alpha = particles[i][j].alpha - FADE_SPEED * dt
        if particles[i][j].alpha < 0 then
          particles[i][j] = nil
        else
          particles[i][j].x = particles[i][j].x + particles[i][j].dx * dt
          particles[i][j].y = particles[i][j].y + particles[i][j].dy * dt
          particles[i][j].dy = particles[i][j].dy + PARTICLES_GRAVITY * dt
        end
      end
    end
  end
end


function resetScore()
  score = 0
end


function setParticles(index, x, y)
  particles[index] = {}
  for i = 1, MAX_PARTICLES do
    particles[index][i] = {
      x = x,
      y = y,
      dx = math.cos((i - 1) * 2 * math.pi / MAX_PARTICLES) * math.random() * PARTICLES_SPEED,
      dy = math.sin((i - 1) * 2 * math.pi / MAX_PARTICLES) * math.random() * PARTICLES_SPEED,
      alpha = 1
      }
  end
end


function enemiIsCollindingWithShip(enemi)
  return length(ship.x - enemi.x, ship.y - enemi.y) <= SPRITES_SIZE
end
