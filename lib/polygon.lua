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


function polygon:test_SAT_collision(A, B)
  local polygons = {A, B}
  local separation = -math.huge
  local normals = {}
  for _, polygon in ipairs(polygons) do
    local fucksakes = {}
    for i = 1, #polygon.vertices, 2 do
      local x, y
      if not polygon.vertices[i+2] then
        y = polygon.vertices[i+1] - polygon.vertices[2]
        x = polygon.vertices[i] - polygon.vertices[1]
      else
        y = polygon.vertices[i+1] - polygon.vertices[i+3]
        x = polygon.vertices[i] - polygon.vertices[i+2]
      end
      local magnitude = x
      if magnitude == 0 then
        magnitude = 1
        y = y / y
      end
      print("polygon slope vector: ", -y, x)
      table.insert(fucksakes, -y/magnitude)
      table.insert(fucksakes, x/magnitude)
    end
    -- this way, each polygon has a list of normals
    -- figure out a way to delete copies of normals later
    table.insert(normals, fucksakes)
  end

  local min_separation = math.huge
  for p = 1, #polygons do
    local polygon = polygons[p]
    for i = 1, #normals, 2 do
      if normals[p][i] < 0 and normals[p][i+1] < 0 then
        normals[p][i] = -normals[p][i]
        normals[p][i+1] = -normals[p][i+1]
      end
      local normal = {normals[p][i], normals[p][i+1]}
      print("normals", normal[1], normal[2])
      local A_projected = {}
      local B_projected = {}
      for x = 1, #A.vertices, 2 do
        local vector = {A.vertices[x], A.vertices[x+1]}
        local proj = vec2:mult_dot(normal, vector)
        table.insert(A_projected, proj)
      end
      for x = 1, #B.vertices, 2 do
        local vector = {B.vertices[x], B.vertices[x+1]}
        local proj = vec2:mult_dot(normal, vector)
        table.insert(B_projected, proj)
      end
      local A_max = math.max(unpack(A_projected))
      local A_min = math.min(unpack(A_projected))
      local B_max = math.max(unpack(B_projected))
      local B_min = math.min(unpack(B_projected))
      print(i, A_max, A_min, B_max, B_min)
      print(i, A_max - B_min, B_max - A_min)
      min_separation = math.min(min_separation, A_max - B_min, B_max - A_min)
      print("min_sep: ", min_separation)
    end
    if math.abs(min_separation) > separation then
      separation = min_separation
    end
  end
  print("separation:", separation)
  return separation
end

function polygon:death(A, B)
  local polygons = {A, B}
  local unit_vectors = {}
  for _, polygon in ipairs(polygons) do
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
      local magnitude = x
      if magnitude == 0 then
        magnitude = 1
        y = 1
      end
			table.insert(unit_vectors, x/magnitude)
			table.insert(unit_vectors, y/magnitude)
    end
  end

  local separation = 0
  local relevant_normal = {}
  local separations = {}

  for i = 1, #unit_vectors, 2 do
    local A_max = -math.huge
    local B_max = -math.huge
    local A_min = math.huge
    local B_min = math.huge

    local normal = {-unit_vectors[i+1], unit_vectors[i]}
    if (normal[1] < 0 and normal[2] < 0) then
      normal[1] = -normal[1]
      normal[2] = -normal[2]
    end

    local min_separation = math.huge

    for j = 1, #A.vertices, 2 do
      local coordinate = {A.vertices[j], A.vertices[j+1]}
      print(vec2:mult_dot(normal, coordinate))
      A_min = math.min(A_min, vec2:mult_dot(normal, coordinate))
      A_max = math.max(A_max, vec2:mult_dot(normal, coordinate))

    end
    for j = 1, #B.vertices, 2 do
      local coordinate = {B.vertices[j], B.vertices[j+1]}
      B_min = math.min(B_min, vec2:mult_dot(normal, coordinate))
      B_max = math.max(B_max, vec2:mult_dot(normal, coordinate))
    end
    print("normal: ", normal[1], normal[2])
    print(i, A_max, A_min, B_max, B_min)
    print(i, A_max - B_min, B_max - A_min)
    min_separation = math.min(min_separation, A_max - B_min, B_max - A_min)
    print("min_sep:", min_separation)
    table.insert(separations, min_separation)
    table.insert(separations, normal)
  end

  local is_colliding = true
  for i = 1, #separations, 2 do
    local value = separations[i]
    if (value < 0) then is_colliding = false end
  end

  if (is_colliding) then
    for i = 1, #separations, 2 do
      local value = separations[i]
      local normal = separations[i+1]
      if (value > separation) then
        separation = value
        relevant_normal = normal
      end
    end
  else
    for i = 1, #separations, 2 do
      local value = separations[i]
      local normal = separations[i+1]
      if (value < separation) then
        separation = value
        relevant_normal = normal
      end
    end
  end
  print()
  return {separation, relevant_normal}
end


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
