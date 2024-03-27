local BLACK = { love.math.colorFromBytes(0, 0, 0, 255) }
local WHITE = { love.math.colorFromBytes(255, 255, 255, 255) }
local RED = { love.math.colorFromBytes(255, 0, 0, 255) }
local BLUE = { love.math.colorFromBytes(0, 0, 255, 255) }
local GREEN = { love.math.colorFromBytes(0, 255, 0, 255) }
local YELLOW = { love.math.colorFromBytes(255, 255, 0, 255) }
local GRAY = { love.math.colorFromBytes(200, 200, 200, 255) }

local WIDTH = 1000
local HEIGHT = 1000
local BASEHEIGHT = 250
local BASEY = HEIGHT - BASEHEIGHT
local GUNLENGTH = BASEHEIGHT / 4
local GUNX = WIDTH / 2
local GUNY = BASEY + GUNLENGTH * 2
local MISSILE_SPEED = 500
local MISSILE_RADIUS = 5
local MOUSE_RADIUS = 10
local FONT_SIZE = 45
local FONT_PADDING = 20
local EXPLOSION_TIME = 3
local BASE_EXPLOSION_RADIUS = 35
local ENEMY_SPEED = 50
local ENEMY_WIDTH = 5

local lifes = 6
local score = 0

local mousex, mousey = 0, 0

local function drawEnd()
    local font = love.graphics.getFont()
    love.graphics.setColor(WHITE)

    local text = "You're dead."
    local w = font:getWidth(text)
    local h = font:getHeight(text)
    love.graphics.print(text, (WIDTH - w) / 2, HEIGHT / 2 - h - FONT_PADDING)

    local text = "Final score: " .. score
    local w = font:getWidth(text)
    local h = font:getHeight(text)
    love.graphics.print(text, (WIDTH - w) / 2, HEIGHT / 2 + FONT_PADDING)
end

local function newEnemy(e)
    local x = math.random() * WIDTH
    local targetX = math.random() * (WIDTH - 10)
    e.x = x
    e.y = 0
    e.begx = x
    e.targetX = targetX
    e.alive = true
end

local function deployMissile(m, x, y)
    m.targetX = x
    m.targetY = y
    m.curX = GUNX
    m.curY = GUNY
    m.explosionTime = 0
    m.deployed = true
end

local function undeployMissile(m)
     m.deployed = false
end

local enemies = {{}, {}, {}, {}, {}}
newEnemy(enemies[1])
newEnemy(enemies[2])
newEnemy(enemies[3])
newEnemy(enemies[4])
newEnemy(enemies[5])

local missiles = {{}, {}, {}}
undeployMissile(missiles[1])
undeployMissile(missiles[2])
undeployMissile(missiles[3])

local function updateEnemy(e, dt)
    for i, m in ipairs(missiles) do
        if m.deployed and m.curY < m.targetY then
            if (e.x - m.targetX)^2 + (e.y - m.targetY)^2 < (m.explosionTime * BASE_EXPLOSION_RADIUS)^2 then
                score = score + 1
                newEnemy(e)
                return
            end
        elseif e.y > BASEY then
            lifes = lifes - 1
            if lifes <= 0 then
                love.update = nil
                love.draw = drawEnd
                return
            end
            newEnemy(e)
            return
        end
    end

    local eVec = { e.targetX - e.x, BASEY - e.y }
    if eVec[1] < 0 then
        eVec[1] = e.x - e.targetX
    end

    local hip = math.sqrt(eVec[1]^2 + eVec[2]^2)
    local sin = eVec[2] / hip
    local cos = eVec[1] / hip

    local x = ENEMY_SPEED * dt * cos
    if e.targetX < e.x then
        x = e.x - x
    else
        x = x + e.x
    end
    local y = e.y + ENEMY_SPEED * dt * sin

    e.x = x
    e.y = y
end

local function updateMissile(m, dt)
    if m.curY < m.targetY then
        m.explosionTime = m.explosionTime + dt
        if m.explosionTime > EXPLOSION_TIME then
            undeployMissile(m)
        end
        return
    end

    local mVec = { m.targetX - m.curX, m.targetY - m.curY }
    if mVec[1] < 0 then
        mVec[1] = m.curX - m.targetX
    end
    if mVec[2] < 0 then
        mVec[2] = m.curY - m.targetY
    end

    local hip = math.sqrt(mVec[1]^2 + mVec[2]^2)
    local sin = mVec[2] / hip
    local cos = mVec[1] / hip

    local x = MISSILE_SPEED * dt * cos
    if m.targetX < m.curX then
        x = m.curX - x
    else
        x = x + m.curX
    end
    local y = m.curY - MISSILE_SPEED * dt * sin

    m.curX = x
    m.curY = y
end

local function drawMouse()
    love.graphics.setColor(GREEN)
    love.graphics.circle("line", mousex, mousey, MOUSE_RADIUS)
    love.graphics.line(mousex, mousey - MOUSE_RADIUS, mousex, mousey + MOUSE_RADIUS)
    love.graphics.line(mousex - MOUSE_RADIUS, mousey, mousex + MOUSE_RADIUS, mousey)
end

local function drawGun()
    love.graphics.setColor(BLUE)

    local restore = love.graphics.getLineWidth()
    love.graphics.setLineWidth(MOUSE_RADIUS * 2)

    local gunVec = { mousex - GUNX, mousey - GUNY }
    if gunVec[1] < 0 then
        gunVec[1] = GUNX - mousex
    end
    if gunVec[2] < 0 then
        gunVec[2] = GUNY - mousey
    end

    local hip = math.sqrt(gunVec[1]^2 + gunVec[2]^2)
    local sin = gunVec[2] / hip
    local cos = gunVec[1] / hip

    local x = GUNLENGTH * cos
    if mousex < GUNX then
        x = GUNX - x
    else
        x = x + GUNX
    end
    local y = GUNY - GUNLENGTH * sin

    love.graphics.line(GUNX, GUNY, x, y)

    love.graphics.setLineWidth(restore)

    love.graphics.setColor(BLACK)
    love.graphics.circle("fill", GUNX, GUNY, MOUSE_RADIUS * 2)
end

local function drawBase()
    love.graphics.setColor(GRAY)
    love.graphics.rectangle("fill", 0, BASEY, WIDTH, HEIGHT)
end

local function drawLifes()
    love.graphics.setColor(BLACK)
    love.graphics.print("Lifes: " .. lifes, FONT_PADDING, HEIGHT - (FONT_SIZE + FONT_PADDING) * 2)
end

local function drawScore()
    love.graphics.setColor(BLACK)
    love.graphics.print("Score: " .. score, FONT_PADDING, HEIGHT - FONT_SIZE - FONT_PADDING)
end

local function drawMissiles()
    for i, m in ipairs(missiles) do
        if m.deployed then
            if m.explosionTime == 0 then
                love.graphics.setColor(RED)
                love.graphics.circle("fill", m.curX, m.curY, MISSILE_RADIUS)
            else
                love.graphics.setColor(YELLOW)
                love.graphics.circle("fill", m.targetX, m.targetY, m.explosionTime * BASE_EXPLOSION_RADIUS)
            end
        end
    end
end

local function drawEnemies()
    love.graphics.setColor(RED)
    local restore = love.graphics.getLineWidth()
    love.graphics.setLineWidth(ENEMY_WIDTH)
    for i, e in ipairs(enemies) do
        love.graphics.line(e.begx, 0, e.x, e.y)
    end
    love.graphics.setLineWidth(restore)
end

function love.load()
    love.window.updateMode(WIDTH, HEIGHT, {resizable = false})
    love.graphics.setNewFont("Monocraft.ttf", FONT_SIZE)
    love.graphics.setBackgroundColor(BLACK)
    love.graphics.setColor(WHITE)
    mousex, mousey = love.mouse.getPosition()
    love.mouse.setVisible(false)
    love.window.setTitle("Lunar Command")
end

function love.mousemoved(x, y, dx, dy, istouch)
    mousex = x
    mousey = y
    if mousey > BASEY then
        mousey = BASEY
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    for i, m in ipairs(missiles) do
        if not m.deployed then
            deployMissile(missiles[i], x, y)
            return
        end
    end
end

function love.update(dt)
    for i, m in ipairs(missiles) do
        if m.deployed then
            updateMissile(m, dt)
        end
    end
    for i, e in ipairs(enemies) do
        updateEnemy(e, dt)
    end
end

function love.draw()
    drawBase()
    drawGun()
    drawLifes()
    drawScore()
    drawMissiles()
    drawEnemies()
    drawMouse()
end
