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
		for i = 1, #polygon.vertices, 2 do
			local coord1, coord2, u
			if not polygon.vertices[i+2] then
				-- this will get the final side of the polygon which wraps around back to the first coordinate
				coord1 = {polygon.vertices[i], polygon.vertices[i+1]}
				print(coord1[1], coord1[2])
				coord2 = {polygon.vertices[1], polygon.vertices[2]}
			else
				coord1 = {polygon.vertices[i], polygon.vertices[i+1]}
				print(coord1[1], coord1[2])
				coord2 = {polygon.vertices[i+2], polygon.vertices[i+3]}
			end
			u = (vec2:diff_vec2(coord1, coord2))
			x = coord1[1] - coord2[1]
			y = coord1[2] - coord2[2]
			table.insert(unit_vectors, x)
			table.insert(unit_vectors, y)
			-- unit vector is difference between two coordinates (slope vector) normalized
		end
	end
	for i = 1, #unit_vectors, 2 do
		--print(unit_vectors[i+1] / unit_vectors[i])
	end
	-- now that we have the unit vectors, we compare the maximum and minimum x values for each polygon relative to each axis in the table
	-- if the maximum value of polygon1 is less than the minimum of polygon2 then there is no collision, return false
	-- or if the max value of polygon2 is less than minimum of polygon1 then there is no collision
	local max1 = -999999
	local min1 = 999999
	local max2 = -999999
	local min2 = 999999
	for i = 1, #unit_vectors, 2 do
		print("unitvector:", unit_vectors[i], unit_vectors[i+1])
		-- use dot product on each polygon's vertices
		-- find min and max x values of projected polygons
		for j = 1, #polygon1.vertices, 2 do
			local x = vec2:mult_dot({unit_vectors[i], unit_vectors[i+1]}, {polygon1.vertices[j], polygon1.vertices[j+1]})

			if x < min1 then min1 = x end
			if x > max1 then max1 = x end
			print(unit_vectors[i], unit_vectors[i+1], polygon1.vertices[j], polygon1.vertices[j+1], x, max1, min1)
		end

		for j = 1, #polygon2.vertices, 2 do
			local x = vec2:mult_dot({unit_vectors[i], unit_vectors[i+1]}, {polygon2.vertices[j], polygon2.vertices[j+1]})
			if x < min2 then min2 = x end
			if x > max2 then max2 = x end
		end
		if max1 < min2 then return false end
		if max2 < min1 then return false end
		-- print(max1)
		-- print(max2)
		print()
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