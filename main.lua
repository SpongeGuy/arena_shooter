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
	player.rotation_speed = 0
	player.center = polygon:get_centroid(player)
	player.bounding_box = polygon:get_bounding_box(player)

	player.direction = {0, 0}
	--player.size = 24
	player.move_speed = 25

	player.shot_timer = love.timer.getTime()
	player.attack_speed = 0.1
	player.shot_size = 8

	return player
end

local p_vert = {400, 520, 600, 400, 550, 600}
local p_side = {500, 1000, 500, 250, 1000, 250}
local p_side_alt = {495, 900, 500, 250, 1500, 255}
local pentagron = polygon:create(p_vert, 0)

local p_square = {200, 250, 150, 200, 200, 150, 250, 200, 250, 250}
local cuber = polygon:create(p_square, 0)

local p_player = {603, 504, 603, 479, 628, 479, 628, 504}
local player = create_player(p_player)

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
	debug_col_testing = "false"
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

function cr_zip(multiplier, normal, polygon)
	local normal = {normal[1] * multiplier, normal[2] * multiplier}
	for i = 1, #polygon.vertices, 2 do
		polygon.vertices[i] = polygon.vertices[i] + normal[1]
		polygon.vertices[i+1] = polygon.vertices[i+1] + normal[2]
	end
end

function SAT_col_dr(A, B, rA, rB)
	-- dynamic collision detection/response function
	local rA = rA or function() end
	local rB = rB or function() end
	-- simple optimization -- do not perform SAT algorithm if A is not within B's bounding box
	if polygon:AABB_collision(A, B) then
		local col1 = polygon:SAT_collision(A, B) -- test for vertex of A inside B
		local col2 = polygon:SAT_collision(B, A) -- test for vertex of B inside A
		if col1 and col2 then
			-- collision happening
			if col1[1] < col2[1] then
				-- vertex of A inside B
				--cr_zip(col1[1], col1[2], A)
			elseif col1[1] > col2[1] then
				--cr_zip(col2[1], col2[2], A)
			else
				-- vertex of B inside A
				--tcr_zip(col1[1], col1[2], A)
			end
			love.graphics.print(col1[1], 0, 0)
			love.graphics.print(col1[2][1], 0, 20)
			love.graphics.print(col1[2][2], 140, 20)
			love.graphics.print(col2[1], 0, 40)
			love.graphics.print(col2[2][1], 0, 60)
			love.graphics.print(col2[2][2], 140, 60)
			love.graphics.setColor(1, 0, 0)
		end
	end
end


  
function love.draw()
	love.graphics.setColor(1, 1, 1)
	--polygon:debug_render_bounding_box(player)

	for i = #bullets, 1, -1 do
		local b = bullets[i]
		love.graphics.circle('fill', b.coordinates[1], b.coordinates[2], b.size)
	end

	polygon:debug_render_bounding_box(pentagron)
	SAT_col_dr(player, pentagron)

	love.graphics.polygon('fill', pentagron.vertices)
	love.graphics.setColor(1, 1, 1)
	love.graphics.polygon('fill', player.vertices)

	polygon:debug_render_coordinates(pentagron.vertices)
	love.graphics.setColor(1, 1, 1)

	love.graphics.polygon('fill', cuber.vertices)

	local v1 = {player.vertices[1], player.vertices[2]}
	local v2 = {player.vertices[3], player.vertices[4]}
	local m = vec2:diff_vec2(v2, v1)

	love.graphics.print(love.timer.getFPS(), 400, 0)
	love.graphics.setColor(0, 1, 0)

	-- love.graphics.circle('fill', v1[1], v1[2], 3)
	-- love.graphics.circle('fill', v2[1], v2[2], 3)
	love.graphics.print(love.mouse.getX(), love.mouse.getX() + 30, love.mouse.getY() + 30)
	love.graphics.print(love.mouse.getY(), love.mouse.getX() + 60, love.mouse.getY() + 30)
end


