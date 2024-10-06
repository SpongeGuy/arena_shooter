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


function polygon:rotate(dt, polygon)
	local angle = polygon.rotation_speed * dt
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
	local p = {}
	p.vertices = vertices
	p.rotation_speed = rotation_speed
	p.center = polygon:get_centroid(p)
	p.bounding_box = polygon:get_bounding_box(p)
	return p
end

function polygon:print_coordinates(vertices)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(0, 1, 0)
	for i = 1, #vertices, 2 do
		love.graphics.print("x:"..vertices[i], vertices[i], vertices[i+1])
		love.graphics.print("y:"..vertices[i+1], vertices[i], vertices[i+1] + 10)
	end
	love.graphics.setColor(r, g, b, a)
end

return polygon