return function(seconds: number)
	local accumulator = 0
	local last = nil

	return function(): boolean
		local now = os.clock()

		if not last then
			last = now
			return true
		end

		local deltaTime = now - last

		last = now
		accumulator += deltaTime

		if accumulator >= seconds then
			accumulator -= seconds

			return true
		end

		return false
	end
end
