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

function polygon:SAT_collision(A, B)
	-- test for A is colliding with B (vertex of A inside face of B)
	-- returns nil if no collision
	-- returns a separation value
	-- - (the difference in space between the vertex of A and the corresponding face of B)

	-- grab all the slopes of polygon B as (x, y) pairs

	local slopes = {}
	for i = 1, #B.vertices, 2 do
		if not B.vertices[i+2] then
			-- necessary for the last polygon face, which loops around to the first vertex
			table.insert(slopes, B.vertices[1] - B.vertices[i])
			table.insert(slopes, B.vertices[2] - B.vertices[i+1])
		else
			table.insert(slopes, B.vertices[i+2] - B.vertices[i])
			table.insert(slopes, B.vertices[i+3] - B.vertices[i+1])
		end
	end
	-- if side of B is perfectly flat, then find out which side of the shape its on so the normal can be corrected

	-- now calculate the normals for each polygon face/slope
	local normalized_slopes = {}
	for i = 1, #slopes, 2 do
		local y = -slopes[i]
		local x = slopes[i+1]
		-- do some number manip to avoid inf/nan values
		local magnitude = math.abs(x)
		if magnitude == 0 then
			y = y / math.abs(y)
		else
			x = x / magnitude
			y = y / magnitude
		end
		if math.abs(y) > x and y ~= 0 then
			magnitude = math.abs(y)
			x = x / magnitude
			y = y / magnitude
		end
		table.insert(normalized_slopes, x)
		table.insert(normalized_slopes, y)
	end

	-- project vertices of A and B onto normals
	-- - then find max and min value of A and B
	
	local separations = {}
	for i = 1, #normalized_slopes, 2 do
		local max_A = -math.huge
		local min_A = math.huge
		local max_B = -math.huge
		local min_B = math.huge
		local normal = {normalized_slopes[i], normalized_slopes[i+1]}
		--print("normal", normal[1], normal[2])
		-- find max(A) and min(A) projected onto the normal
		for j = 1, #A.vertices, 2 do
			local dot = vec2:mult_dot(normal, {A.vertices[j], A.vertices[j+1]})
			max_A = math.max(max_A, dot)
			min_A = math.min(min_A, dot)
		end
		for j = 1, #B.vertices, 2 do
			local dot = vec2:mult_dot(normal, {B.vertices[j], B.vertices[j+1]})
			max_B = math.max(max_B, dot)
			min_B = math.min(min_B, dot)
		end

		-- get all separation values
		local sep1 = max_B - min_A
		local sep2 = min_B - max_A
		local sep3 = max_A - min_B
		local sep4 = min_A - max_B
		print(normal[1], normal[2], sep1, sep2, sep3, sep4)
		if (sep1 < 0 and sep2 < 0) or (sep3 < 0 and sep4 < 0) then
			-- if a collision is not happening in at least one instance, then return
			-- there is no point in continuing the iteration
			return
		end
		-- collect all the negative separation values
		-- if there is a collision, sep1 and sep3 will always be positive, sep2 and sep4 will always be negative
		-- the negative ones are the ones we need to calculate a minimum translation vector
		if sep2 < 0 and sep4 < 0 then
			table.insert(separations, sep2)
			table.insert(separations, normal)
			-- sep2 will always have the correct value for x and y normals (for flat surfaces), so we don't include it in this table
			table.insert(separations, sep4)
			table.insert(separations, normal)
		end
	end
	-- now find the greatest separation value
	local max_sep = -math.huge
	local normal
	for i = 1, #separations, 2 do
		if separations[i] >= max_sep then
			max_sep = separations[i]
			normal = separations[i+1]
		end
	end
	return {math.abs(max_sep), normal}
end

-- if normal is x=1 y=0 (aligned to the x axis):
-- - get centroid of polygon (cx and cy)
-- - compare vertex which is part of the slope used to calculate normal (call this x' and y')
-- - if x' < cx then the normal should be fixed to equal x=-1 y=0
-- - if x' > cx then the normal should be x=1 y=0


function polygon:get_centroid(A)
	local sum_x = 0
	local sum_y = 0
	for i = 1, #A.vertices, 2 do
		sum_x = sum_x + A.vertices[i]
		sum_y = sum_y + A.vertices[i+1]
	end

	local cx = sum_x / (#A.vertices / 2)
	local cy = sum_y / (#A.vertices / 2)

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
