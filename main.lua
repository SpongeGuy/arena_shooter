local v = require 'lib/vector'

WINDOW_WIDTH = 1920
WINDOW_HEIGHT = 1080

function love.load()
	local success = love.window.setFullscreen(true, "desktop")
	bullets = {}
end

local player = {
	coordinates = {x = 0, y = 0},
	direction = {x = 0, y = 0},
	size = 16,
	speed = 250,
}

function player:control()
	local vector = {x = 0, y = 0}
	if love.keyboard.isDown('w') then
		vector.y = vector.y - player.speed
	end
	if love.keyboard.isDown('a') then
		vector.x = vector.x - player.speed
	end
	if love.keyboard.isDown('s') then
		vector.y = vector.y + player.speed
	end
	if love.keyboard.isDown('d') then
		vector.x = vector.x + player.speed
	end
	return vector
end

function love.update(dt)
	fps = love.timer.getFPS()
	player.direction = player:control()
	player.coordinates.x = player.coordinates.x + player.direction.x * dt
	player.coordinates.y = player.coordinates.y + player.direction.y * dt
	for i = #bullets, 1, -1 do
		local b = bullets[i]
		b:update(dt)
		if b.kill then
			table.remove(bullets, i)
		end
	end
end

function love.draw()
	love.graphics.print(fps, 0, 0)
	love.graphics.rectangle('fill', player.coordinates.x, player.coordinates.y, player.size, player.size)
	for i = #bullets, 1, -1 do
		local b = bullets[i]
		love.graphics.circle('fill', b.coordinates.x, b.coordinates.y, b.size)
	end
end

function love.mousepressed(x, y, button)
	local mouse_coordinates = {x = x, y = y}
	local bullet = {
		coordinates = {
			x = player.coordinates.x + (player.size / 2), 
			y = player.coordinates.y + (player.size / 2)
		},
		direction = v:vec2_add_vec2(v:vec2_mult_scalar(v:vec2_normalize(v:vec2_diff_vec2(v:vec2_add_vec2(player.coordinates, {x = player.size / 2, y = player.size / 2}), mouse_coordinates)), 500), v:vec2_mult_scalar(v:vec2_normalize(player.direction), 250)),
		size = 8,
		kill = false,
	}
	function bullet:update(dt)
		bullet.coordinates.x = bullet.coordinates.x + bullet.direction.x * dt
		bullet.coordinates.y = bullet.coordinates.y + bullet.direction.y * dt
		if bullet.coordinates.x < -100 or bullet.coordinates.x > WINDOW_WIDTH + 100 then
			bullet.kill = true
		end
		if bullet.coordinates.y < -100 or bullet.coordinates.y > WINDOW_HEIGHT + 100 then
			bullet.kill = true
		end
	end
	table.insert(bullets, bullet)
end