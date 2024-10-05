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
	attack_speed = 0.25,
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
	vertices = {20, 20, -20, 20, -20, -40,},
	draw_offset = {1000, 500},
	angle = 0.01,
	center_x = 0,
	center_y = 0,
}

function vector_rotate(x, y, cx, cy, angle)
	local s = math.sin(angle)
	local c = math.cos(angle)

	x = x - cx
	y = y - cy

	local xnew = x * c - y * s
	local ynew = x * s + y * c

	x = xnew + cx
	y = ynew + cy
	return x, y
end

function transform(dt, shape)
	shape.angle = shape.angle
	for i = 1, #shape.vertices, 2 do
		shape.vertices[i], shape.vertices[i+1] = vector_rotate(shape.vertices[i], shape.vertices[i+1], shape.center_x, shape.center_y, shape.angle)
	end
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

	transform(dt, pentagron)
end

function love.draw()
	love.graphics.rectangle('fill', player.coordinates[1], player.coordinates[2], player.size, player.size)
	for i = #bullets, 1, -1 do
		local b = bullets[i]
		love.graphics.circle('fill', b.coordinates[1], b.coordinates[2], b.size)
	end
	love.graphics.polygon('fill', offset(pentagron.vertices, pentagron.draw_offset))
end