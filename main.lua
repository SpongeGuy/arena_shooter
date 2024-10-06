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



function create_player(vertices)
	local player = {}
	player.vertices = vertices
	player.rotation_speed = 1
	player.center = polygon:get_centroid(player)
	player.bounding_box = polygon:get_bounding_box(player)
	
	player.direction = {0, 0}
	--player.size = 24
	player.move_speed = 250
	
	player.shot_timer = love.timer.getTime()
	player.attack_speed = 0.1
	player.shot_size = 8

	return player
end


local p_vert = {600, 520, 550, 550, 400, 520, 370, 350, 480, 300, 600, 350, 625, 450}
local pentagron = polygon:create(p_vert, 0.1)

local p_square = {200, 250, 150, 200, 200, 150, 250, 200, 250, 250}
local cuber = polygon:create(p_square, 0)

local p_player = {20, 36, 20, 20, 36, 20, 36, 36}
local player = create_player(p_player)
polygon:scale(player, 2)

print(player.center[1], player.center[2])

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
		coordinates = {player.center[1], player.center[2]},
		-- REMEMBER TO NOT INITIALIZE REFERENCES TO TABLES
		-- direction is (player pos - mouse pos) * 500 + (player direction)
		direction = vec2:add_vec2(vec2:mult_scalar(vec2:normalize(vec2:diff_vec2(player.center, mouse_coordinates)), 500), vec2:mult_scalar(vec2:normalize(player.direction), 250)),
		
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




function love.update(dt)
	fps = love.timer.getFPS()
	
	player.direction = player:control()
	polygon:translate(dt, player, player.direction)
	polygon:rotate(dt, player, player.rotation_speed)
	player.bounding_box = polygon:get_bounding_box(player)
	
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

	--polygon:translate(dt, pentagron, {25, -40})
	polygon:rotate(dt, pentagron, pentagron.rotation_speed)
	pentagron.bounding_box = polygon:get_bounding_box(pentagron)

end

function love.draw()
	love.graphics.setColor(1, 1, 1)

	love.graphics.polygon('fill', player.vertices)
	--polygon:debug_render_bounding_box(player)
	
	for i = #bullets, 1, -1 do
		local b = bullets[i]
		love.graphics.circle('fill', b.coordinates[1], b.coordinates[2], b.size)
	end

	love.graphics.polygon('fill', pentagron.vertices)
	if polygon:AABB_collision(player, pentagron) then
		love.graphics.setColor(1, 0, 0)
	end
	polygon:debug_render_bounding_box(pentagron)
	polygon:debug_render_coordinates(pentagron.vertices)
	love.graphics.setColor(1, 1, 1)

	love.graphics.polygon('fill', cuber.vertices)
	
	local v1 = {player.vertices[1], player.vertices[2]}
	local v2 = {player.vertices[3], player.vertices[4]}
	love.graphics.print(tostring(vec2:get_slope(v1, v2)), 0, 60)
	local m = vec2:diff_vec2(v2, v1)
	love.graphics.print(tostring(m[2] / m[1]), 0, 80)


	love.graphics.setColor(0, 1, 0)
	love.graphics.circle('fill', v1[1], v1[2], 3)
	love.graphics.circle('fill', v2[1], v2[2], 3)
	love.graphics.print(love.mouse.getX(), love.mouse.getX() + 30, love.mouse.getY() + 30)
	love.graphics.print(love.mouse.getY(), love.mouse.getX() + 60, love.mouse.getY() + 30)
end