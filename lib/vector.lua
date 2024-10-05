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

function vector:get_dims(vector)
	local vn, vm = 0, 0
	for n = 1, #vector do
		if type(vector[n]) == 'table' then
			for m = 1, #vector[n] do
				if m > vm then vm = m end
			end
			if n > vn then vn = n end
		else
			if n > vm then vm = n end
			vn = 1
		end
	end
	return {vn, vm}
end

-- dot product of
-- unit vector along an axis (which is the difference between two adjacent vertices (first vertex has to have a greater magnitude than the 2nd))
-- vector of a point on the shape

-- if not (max(A) < min(B) and max(B) < min(A)) for all axes then shape A and B are touching

function vector:print(vector)
	local m = 1 -- columns
	local n = 1 -- rows
	-- matrices must be rectangular
	for m = 1, #vector do
		if type(vector[m]) == 'table' then
			local str = ""
			for n = 1, #vector[m] do
				str = str .. vector[m][n] .. "\t"
			end
			print(str)
		else
			print(vector[m])
		end
	end
	print("\n")
end

return vector