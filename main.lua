local v = require 'lib/vector'
require 'lib/errorexplorer'

WINDOW_WIDTH = 1920
WINDOW_HEIGHT = 1080

function love.load()
	local success = love.window.setFullscreen(true, "desktop")
	bullets = {}
	terrain = {}
end

local player = {
	coordinates = {0, 0},
	direction = {0, 0},
	size = 24,
	move_speed = 250,
	
	shot_timer = love.timer.getTime(),
	attack_speed = 0.1,
	shot_size = 8,
}

function player:control()
	local vector = {0, 0}
	if love.keyboard.isDown('w') then
		vector[2] = vector[2] - player.move_speed
	end
	if love.keyboard.isDown('a') then
		vector[1] = vector[1] - player.move_speed
	end
	if love.keyboard.isDown('s') then
		vector[2] = vector[2] + player.move_speed
	end
	if love.keyboard.isDown('d') then
		vector[1] = vector[1] + player.move_speed
	end
	return vector
end

function player:shoot()
	local mouse_coordinates = {love.mouse.getX(), love.mouse.getY()}
	local bullet = {
		coordinates = {
			player.coordinates[1] + (player.size / 2), 
			player.coordinates[2] + (player.size / 2)
		},
		-- direction is (player pos - mouse pos) * 500 + (player direction)
		direction = v:vec2_add_vec2(v:vec2_mult_scalar(v:vec2_normalize(v:vec2_diff_vec2(v:vec2_add_vec2(player.coordinates, {player.size / 2, player.size / 2}), mouse_coordinates)), 500), v:vec2_mult_scalar(v:vec2_normalize(player.direction), 250)),
		
		size = player.shot_size,
		kill = false,
	}
	function bullet:update(dt)
		bullet.coordinates[1] = bullet.coordinates[1] + bullet.direction[1] * dt
		bullet.coordinates[2] = bullet.coordinates[2] + bullet.direction[2] * dt
		if bullet.coordinates[1] < -100 or bullet.coordinates[1] > WINDOW_WIDTH + 100 then
			bullet.kill = true
		end
		if bullet.coordinates[2] < -100 or bullet.coordinates[2] > WINDOW_HEIGHT + 100 then
			bullet.kill = true
		end
	end
	table.insert(bullets, bullet)
end

local pentagron = {
	vertices = {520, 520, 480, 520, 480, 460, 800, 600},
	rotation_speed = 0.25, -- rotation at radians per frame
	center_x = 551,
	center_y = 510,
}

function polygon_rotate(dt, polygon)
	local angle = polygon.rotation_speed * dt
	local s = math.sin(angle)
	local c = math.cos(angle)

	-- this is pain
	for i = 1, #polygon.vertices, 2 do
		local x = polygon.vertices[i] - polygon.center_x
		local y = polygon.vertices[i+1] - polygon.center_y

		local xnew = x * c - y * s
		local ynew = x * s + y * c

		x = xnew + polygon.center_x
		y = ynew + polygon.center_y
		polygon.vertices[i], polygon.vertices[i+1] = x, y
	end
end

function polygon_translate(dt, polygon, vector)
	local dx = vector[1] * dt
	local dy = vector[2] * dt
	for i = 1, #polygon.vertices, 2 do
		
		local x = polygon.vertices[i]
		local y = polygon.vertices[i+1]

		x = x + dx
		y = y + dy

		polygon.vertices[i], polygon.vertices[i+1] = x, y
	end
	polygon.center_x = polygon.center_x + dx
	polygon.center_y = polygon.center_y + dy
end

function offset(vector, offset)
	local v = {}
	for _, value in ipairs(vector) do
		table.insert(v, value)
	end
	for i = 1, #v, 2 do
		v[i] = v[i] + offset[1]
		v[i + 1] = v[i + 1] + offset[2]
	end
	return v
end

function love.update(dt)
	fps = love.timer.getFPS()
	player.direction = player:control()
	player.coordinates[1] = player.coordinates[1] + player.direction[1] * dt
	player.coordinates[2] = player.coordinates[2] + player.direction[2] * dt
	for i = #bullets, 1, -1 do
		local b = bullets[i]
		b:update(dt)
		if b.kill then
			table.remove(bullets, i)
		end
	end
	if love.mouse.isDown(1) and love.timer.getTime() - player.shot_timer > player.attack_speed then
		player:shoot()
		player.shot_timer = love.timer.getTime()
	end

	polygon_translate(dt, pentagron, {100, -70})
	polygon_rotate(dt, pentagron)

end

function love.draw()
	love.graphics.rectangle('fill', player.coordinates[1], player.coordinates[2], player.size, player.size)
	for i = #bullets, 1, -1 do
		local b = bullets[i]
		love.graphics.circle('fill', b.coordinates[1], b.coordinates[2], b.size)
	end
	love.graphics.polygon('fill', pentagron.vertices)
	love.graphics.print(love.mouse.getX(), love.mouse.getX() + 30, love.mouse.getY() + 30)
	love.graphics.print(love.mouse.getY(), love.mouse.getX() + 60, love.mouse.getY() + 30)
end