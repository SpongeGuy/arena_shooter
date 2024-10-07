local vec2 = require 'lib/vector'

local polygon = {}

function polygon:get_bounding_box(polygon)
	local x_max = -999999
	local y_max = -999999
	local x_min = 999999
	local y_min = 999999
	for i = 1, #polygon.vertices, 2 do
		if polygon.vertices[i] > x_max then x_max = polygon.vertices[i] end
		if polygon.vertices[i] < x_min then x_min = polygon.vertices[i] end
		if polygon.vertices[i+1] > y_max then y_max = polygon.vertices[i+1] end
		if polygon.vertices[i+1] < y_min then y_min = polygon.vertices[i+1] end
	end
	return {x_min, y_min, x_max, y_max}
end

function polygon:AABB_collision(polygon1, polygon2)
	local box1 = polygon1.bounding_box
	local box1_w = box1[3] - box1[1]
	local box1_h = box1[4] - box1[2]
	local box2 = polygon2.bounding_box
	local box2_w = box2[3] - box2[1]
	local box2_h = box2[4] - box2[2]

	if box1[1] + box1_w < box2[1] then return false end
	if box1[2] + box1_h < box2[2] then return false end
	if box2[1] + box2_w < box1[1] then return false end
	if box2[2] + box2_h < box1[2] then return false end
	return true
end

function polygon:SAT_collision(polygon1, polygon2)
	local polygons = {polygon1, polygon2}
	local unit_vectors = {}
	-- I AM COOKING
	for _, polygon in ipairs(polygons) do
		-- get slope of each side of each polygon in {x, y} format
		local x, y
		for i = 1, #polygon.vertices, 2 do
			if not polygon.vertices[i+2] then
				-- final side, only runs once
				y = polygon.vertices[i+1] - polygon.vertices[2]
				x = polygon.vertices[i] - polygon.vertices[1]
			else
				y = polygon.vertices[i+1] - polygon.vertices[i+3]
				x = polygon.vertices[i] - polygon.vertices[i+2]
			end
			table.insert(unit_vectors, x)
			table.insert(unit_vectors, y)
		end
	end


	-- do dot product of unit_vectors * each coordinate of polygons, separate max and min from polygon1 and 2
	for i = 1, #unit_vectors, 2 do
		--print(unit_vectors[i], unit_vectors[i+1])
		local dots1 = {}
		local dots2 = {}
		for j = 1, #polygon1.vertices, 2 do
			local dot = vec2:mult_dot({-unit_vectors[i+1], unit_vectors[i]}, {polygon1.vertices[j], polygon1.vertices[j+1]})
			table.insert(dots1, dot)
		end

		for j = 1, #polygon2.vertices, 2 do
			local dot = vec2:mult_dot({-unit_vectors[i+1], unit_vectors[i]}, {polygon2.vertices[j], polygon2.vertices[j+1]})
			table.insert(dots2, dot)
		end

		if math.max(unpack(dots1)) < math.min(unpack(dots2)) then return false end
		if math.max(unpack(dots2)) < math.min(unpack(dots1)) then return false end
	end
	
	
	return true
end

function polygon:get_centroid(polygon)
	local sum_x = 0
	local sum_y = 0
	for i = 1, #polygon.vertices, 2 do
		sum_x = sum_x + polygon.vertices[i]
		sum_y = sum_y + polygon.vertices[i+1]
	end

	local cx = sum_x / (#polygon.vertices / 2)
	local cy = sum_y / (#polygon.vertices / 2)

	return {cx, cy}
end


function polygon:rotate(dt, polygon, scalar)
	local angle = scalar * dt
	local s = math.sin(angle)
	local c = math.cos(angle)

	-- this is pain
	for i = 1, #polygon.vertices, 2 do
		local x = polygon.vertices[i] - polygon.center[1]
		local y = polygon.vertices[i+1] - polygon.center[2]

		local xnew = x * c - y * s
		local ynew = x * s + y * c

		x = xnew + polygon.center[1]
		y = ynew + polygon.center[2]
		polygon.vertices[i], polygon.vertices[i+1] = x, y
	end

end

function polygon:translate(dt, polygon, vector)
	local dx = vector[1] * dt
	local dy = vector[2] * dt
	for i = 1, #polygon.vertices, 2 do
		
		local x = polygon.vertices[i]
		local y = polygon.vertices[i+1]

		x = x + dx
		y = y + dy

		polygon.vertices[i], polygon.vertices[i+1] = x, y
	end
	polygon.center[1] = polygon.center[1] + dx
	polygon.center[2] = polygon.center[2] + dy
end

function polygon:create(vertices, rotation_speed)
	-- when creating polygons, try to create vertices table starting at the bottom leftmost coordinate
	-- fill the table out with vertices working clockwise spatially
	local p = {}
	p.vertices = vertices
	p.rotation_speed = rotation_speed
	p.center = polygon:get_centroid(p)
	p.bounding_box = polygon:get_bounding_box(p)
	return p
end

function polygon:scale(polygon, scalar)
	for i = 1, #polygon.vertices do
		polygon.vertices[i] = polygon.vertices[i] * scalar
	end
	for i = 1, #polygon.center do
		polygon.center[i] = polygon.center[i] * (scalar)
	end
end

function polygon:debug_render_coordinates(vertices, offset)
	local s = offset or 0
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(0, 1, 0)
	for i = 1, #vertices, 2 do
		love.graphics.print("x:"..vertices[i], vertices[i], vertices[i+1])
		love.graphics.print("y:"..vertices[i+1], vertices[i], vertices[i+1] + 10)
	end
	love.graphics.setColor(r, g, b, a)
end

function polygon:debug_render_bounding_box(polygon)
	love.graphics.rectangle('line', polygon.bounding_box[1], polygon.bounding_box[2], polygon.bounding_box[3] - polygon.bounding_box[1], polygon.bounding_box[4] - polygon.bounding_box[2])
end

return polygon