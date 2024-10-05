local vector = {}

function vector:vec2_diff_vec2(vector1, vector2)
	-- this is good for finding the distance between two coordinates
	local nvector = {}
	nvector[1] = vector2[1] - vector1[1]
	nvector[2] = vector2[2] - vector1[2]
	return nvector
end

function vector:vec2_mult_scalar(vector, factor)
	local nvector = {}
	nvector[1] = vector[1] * factor
	nvector[2] = vector[2] * factor
	return nvector
end

function vector:vec2_mult_vec2(vector1, vector2)
	local nvector = {}
	nvector[1] = vector1[1] * vector2[1]
	nvector[2] = vector1[2] * vector2[2]
	return nvector
end

function vector:vec2_add_vec2(vector1, vector2)
	local nvector = {}
	nvector[1] = vector1[1] + vector2[1]
	nvector[2] = vector1[2] + vector2[2]
	return nvector
end

function vector:vec2_normalize(vector)
	local x, y = vector[1], vector[2]
	local magnitude = math.sqrt(x*x + y*y)

	if magnitude == 0 then
		return {0, 0}
	end

	local nx = x / magnitude
	local ny = y / magnitude

	return {nx, ny}
end

function vector:print(vector)

end

return vector