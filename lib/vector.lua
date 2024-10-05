local vector = {}

function vector:vec2_diff_vec2(vector1, vector2)
	-- this is good for finding the distance between two coordinates
	local nvector = {}
	nvector.x = vector2.x - vector1.x
	nvector.y = vector2.y - vector1.y
	return nvector
end

function vector:vec2_mult_scalar(vector, factor)
	local nvector = {}
	nvector.x = vector.x * factor
	nvector.y = vector.y * factor
	return nvector
end

function vector:vec2_mult_vec2(vector1, vector2)
	local nvector = {}
	nvector.x = vector1.x * vector2.x
	nvector.y = vector1.y * vector2.y
	return nvector
end

function vector:vec2_add_vec2(vector1, vector2)
	local nvector = {}
	nvector.x = vector1.x + vector2.x
	nvector.y = vector1.y + vector2.y
	return nvector
end

function vector:vec2_normalize(vector)
	local x, y = vector.x, vector.y
	local magnitude = math.sqrt(x*x + y*y)

	if magnitude == 0 then
		return {x = 0, y = 0}
	end

	local nx = x / magnitude
	local ny = y / magnitude

	return {x = nx, y = ny}
end

return vector