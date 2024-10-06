local vec2 = {}

function vec2:diff_vec2(vector1, vector2)
	-- this is good for finding the distance between two coordinates
	local nvector = {}
	nvector[1] = vector2[1] - vector1[1]
	nvector[2] = vector2[2] - vector1[2]
	return nvector
end

function vec2:mult_scalar(vector, factor)
	local nvector = {}
	nvector[1] = vector[1] * factor
	nvector[2] = vector[2] * factor
	return nvector
end

function vec2:mult_vec2(vector1, vector2)
	local nvector = {}
	nvector[1] = vector1[1] * vector2[1]
	nvector[2] = vector1[2] * vector2[2]
	return nvector
end

function vec2:add_vec2(vector1, vector2)
	local nvector = {}
	nvector[1] = vector1[1] + vector2[1]
	nvector[2] = vector1[2] + vector2[2]
	return nvector
end

function vec2:normalize(vector)
	local x, y = vector[1], vector[2]
	local magnitude = math.sqrt(x*x + y*y)

	if magnitude == 0 then
		return {0, 0}
	end

	local nx = x / magnitude
	local ny = y / magnitude

	return {nx, ny}
end



return vec2