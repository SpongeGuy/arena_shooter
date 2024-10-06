local vec2 = require 'lib/vector'
local polygon = require 'lib/polygon'
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
		direction = vec2:add_vec2(vec2:mult_scalar(vec2:normalize(vec2:diff_vec2(vec2:add_vec2(player.coordinates, {player.size / 2, player.size / 2}), mouse_coordinates)), 500), vec2:mult_scalar(vec2:normalize(player.direction), 250)),
		
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

local p_vert = {600, 520, 400, 520, 370, 350,  480, 300, 600, 350}
local pentagron = polygon:create(p_vert, 0.1)


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

	polygon:translate(dt, pentagron, {25, -40})
	polygon:rotate(dt, pentagron)
	pentagron.bounding_box = polygon:get_bounding_box(pentagron)

end

function love.draw()
	love.graphics.rectangle('fill', player.coordinates[1], player.coordinates[2], player.size, player.size)
	for i = #bullets, 1, -1 do
		local b = bullets[i]
		love.graphics.circle('fill', b.coordinates[1], b.coordinates[2], b.size)
	end
	love.graphics.polygon('fill', pentagron.vertices)
	love.graphics.rectangle('line', pentagron.bounding_box[1], pentagron.bounding_box[2], pentagron.bounding_box[3] - pentagron.bounding_box[1], pentagron.bounding_box[4] - pentagron.bounding_box[2])
	love.graphics.print(love.mouse.getX(), love.mouse.getX() + 30, love.mouse.getY() + 30)
	love.graphics.print(love.mouse.getY(), love.mouse.getX() + 60, love.mouse.getY() + 30)
end