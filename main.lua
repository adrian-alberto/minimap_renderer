local regions = {}
local index = 1
local sepia = {0.666667, 0.603922, 0.513726}
local watercolor = {0.44705882352941, 0.58039215686275 ,0.62745098039216}
local waterhighlight = {0.54705882352941, 0.78039215686275, 0.92745098039216}
local watershadow = {0.22352941176471, 0.29019607843137, 0.31372549019608}
local outlinecolor = {1,1,1,1}


function love.load()
	local startTime = love.timer.getTime()
	print(love.getVersion())
	love.filesystem.setIdentity("minimap")
	love.window.setMode(1200,1000)
	love.graphics.setDefaultFilter("linear", "nearest", 4)

	love.filesystem.createDirectory("inputdata")
	for i, v in pairs(love.filesystem.getDirectoryItems("inputdata")) do
		loadFile("inputdata/"..v)
	end

	outputCombined()
	print(love.timer.getTime() - startTime)

end

function loadFile(fname)
	local pngname = string.match(fname, "inputdata/(.+)%.txt")..".png"
	
	local alreadyGenerated = (love.filesystem.getInfo(pngname) ~= nil) 
	print(pngname, alreadyGenerated)
	local first = true
	local regionName, x, y, w, spp
	local region

	local drawX = 0
	local drawY = 0

	for line in love.filesystem.lines(fname) do
		if first then
			first = false
			line = string.gsub(line, "[^%w ]", "")
			regionName, x, y, w, spp = string.match(line, "(%w+)%s(%S+)%s(%S+)%s(%S+)%s(%S+)")
			--region = newRegion(regionName, x, y, w, spp)
			region = newRegion(regionName, y, -x - w, w, spp)
			if alreadyGenerated then
				break
			end
		else
			--[[drawX = 0
			drawY = drawY + 1
			region.data[drawY] = {}
			region.meta[drawY] = {}
			for char, metachar in string.gmatch(line, "(%S)(%w)") do
				drawX = drawX + 1
				if char == "?" then char = "0" end
				region.data[drawY][drawX] = char
				region.meta[drawY][drawX] = metachar
			end
			--]]
			drawX = w/spp + 1
			drawY = drawY + 1
			
			for color, hbyte, metabyte in string.gmatch(line, "(...)(.)(.)") do

				drawX = drawX - 1
				--if char == "?" then char = "0" end
				if not region.data[drawX] then
					region.data[drawX] = {}
					region.meta[drawX] = {}
				end
				local rbyte, gbyte, bbyte = string.byte(color, 1, 3)
				local r = (rbyte-32)/96
				local g = (gbyte-32)/96
				local b = (bbyte-32)/96

				r = r*.5 + sepia[1]*.5
				g = g*.5 + sepia[2]*.5
				b = b*.5 + sepia[3]*.5


				local height = string.byte(hbyte)
				local _, __, pb, wb = readByte(metabyte)
				region.data[drawX][drawY] = {r,g,b}
				region.meta[drawX][drawY] = {
					height=height,
					isPart=(pb==1),
					isUnderwater=(wb==1),
				}
			end
		end
	end
	if not alreadyGenerated then
		region:shadowcast()
		region:render()
		region:encode()
	else
		region:load()
	end
end


function newRegion(regionName, x, y, w, spp)
	print(regionName, x, y, w)
	local r = {}
	r.name = regionName
	r.x = tonumber(x)
	r.y = tonumber(y)
	r.w = tonumber(w)
	r.h = tonumber(w)
	r.spp = tonumber(spp)
	r.data = {}
	r.meta = {}
	r.canvas = love.graphics.newCanvas(r.w/2, r.h/2)

	function r:shadowcast()
		local default = {height=0}
		function check(x, y)
			return (self.meta[y] and self.meta[y][x] or default)
		end
		for y, row in pairs(self.meta) do
			for x, me in pairs(row) do
				local prev = check(x-1, y-1)
				local referenceHeight = prev.shadowHeight or prev.height

				if me.height > referenceHeight then
					me.highlightValue = me.height - referenceHeight
				elseif me.height < referenceHeight - 0.5 then
					me.shadowValue = referenceHeight - me.height
					me.shadowHeight = referenceHeight - 0.5
				end
			end
		end
	end

	function r:render()
		
		local default = {height=0}
		function check(x, y)
			return (self.meta[y] and self.meta[y][x] or default)
		end

		love.graphics.setCanvas(self.canvas)

		for y, row in pairs(self.data) do
			for x, color in pairs(row) do
				local r,g,b = unpack(color)
				local meta = self.meta[y][x]
				local h = meta.height/96
				love.graphics.setColor(r,g,b, meta.isUnderwater and 0 or 1)
				love.graphics.rectangle("fill",x*2-1,y*2-1,2,2)
			end
		end
		for y, row in pairs(self.meta) do
			for x, me in pairs(row) do
				--normal highlighting
				if me.isUnderwater then
					local a = 1 - math.min(1,math.sqrt((x*spp-self.w/2)^2 + (y*spp-self.h/2)^2) / (self.w/2) )
					love.graphics.setBlendMode("replace")
					if me.highlightValue then
						local r,g,b = unpack(waterhighlight)
						love.graphics.setColor(r,g,b, a)
						love.graphics.points(x*2+1,y*2)
					elseif me.shadowValue then
						local r,g,b = unpack(watershadow)
						love.graphics.setColor(r,g,b, a)
						if me.shadowValue > 5 then
							love.graphics.points(x*2+1,y*2, x*2, y*2+1,x*2+1,y*2+1)
						elseif (y + x) % 2 == 0 then
							love.graphics.points(x*2+1,y*2+1, x*2, y*2)
						else
							love.graphics.points(x*2+1,y*2, x*2, y*2+1)
						end
					end
				else
					if me.highlightValue then
						love.graphics.setBlendMode("screen")
						love.graphics.setColor(0.4,0.4,0.4)
						love.graphics.points(x*2+1,y*2+1, x*2, y*2)
					elseif me.shadowValue then
						love.graphics.setBlendMode("multiply", "premultiplied")
						love.graphics.setColor(0.7,0.7,0.7, 1)
						if me.shadowValue > 5 then
							love.graphics.points(x*2+1,y*2, x*2, y*2+1,x*2+1,y*2+1)
						elseif (y + x) % 2 == 0 then
							love.graphics.points(x*2+1,y*2+1, x*2, y*2)
						else
							love.graphics.points(x*2+1,y*2, x*2, y*2+1)
						end
					end
				end
			end
		end
				--OUTLINES
		for y, row in pairs(self.meta) do
			for x, me in pairs(row) do
				if not me.isUnderwater then
					love.graphics.setBlendMode("replace")
					love.graphics.setColor(unpack(outlinecolor))
					local right = check(x+1, y)
					local left = check(x-1, y)
					local up = check(x, y-1)
					local down = check(x, y+1)

					if right.isUnderwater then
						love.graphics.points(x*2+2, y*2, x*2+2, y*2+1)
					end
					if left.isUnderwater then
						love.graphics.points(x*2-1, y*2, x*2-1, y*2+1)
					end
					if up.isUnderwater then
						love.graphics.points(x*2, y*2-1, x*2+1, y*2-1)
					end
					if down.isUnderwater then
						love.graphics.points(x*2, y*2+1, x*2+1, y*2+1)
					end
					love.graphics.setBlendMode("alpha")
					love.graphics.setColor(0,0,0,0.4)
					if me.isPart then
						if not right.isUnderwater and right.height < me.height-2 then
							love.graphics.points(x*2+2, y*2, x*2+2, y*2+1)
						end
						if not left.isUnderwater and left.height < me.height-2 then
							love.graphics.points(x*2-1, y*2, x*2-1, y*2+1)
						end
						if not up.isUnderwater and up.height < me.height-2 then
							love.graphics.points(x*2, y*2-1, x*2+1, y*2-1)
						end
						if not down.isUnderwater and down.height < me.height-2 then
							love.graphics.points(x*2, y*2+1, x*2+1, y*2+1)
						end
					end
				end
			end
		end
		love.graphics.setCanvas()
	end


	function r:encode()
		local idata = self.canvas:newImageData()
		idata:encode("png", regionName..".png")
		--self.idata = idata
		self.image = love.graphics.newImage(idata)
		self.canvas = nil
	end

	function r:load()
		local idata = love.image.newImageData(regionName..".png")
		--self.idata = idata
		self.image = love.graphics.newImage(idata)
	end

	table.insert(regions, r)
	
	return r
end

function outputCombined()
	local w = 625
	local h = 625
	local combinedCanvas = love.graphics.newCanvas(w,h)
	love.graphics.setCanvas(combinedCanvas)
	--love.graphics.clear(unpack(watercolor))
	love.graphics.setColor(1,1,1, 255)
	love.graphics.setBlendMode("alpha","premultiplied")
	for i, region in pairs(regions) do
		local x = region.x - 1342 - 1000
		local y = region.y + 6170 - 1000
		local scale = .125

		local drawx = math.floor(x*scale/2) + math.floor(w/2)
		local drawy = math.floor(y*scale/2) + math.floor(h/2)
		love.graphics.draw(region.image,drawx, drawy,0,scale,scale)
		--love.graphics.circle("line", x*scale/2 + region.w*scale/4 + w/2, y*scale/2 + region.w*scale/4 + h/2, region.w*scale/4)
	end
	love.graphics.setCanvas()
	local idata = combinedCanvas:newImageData()
	idata:encode("png", "combined.png")
	combinedCanvas = nil
end

function love.draw()
	local w, h = love.graphics.getDimensions()
	love.graphics.clear(unpack(watercolor))
	love.graphics.setCanvas()
	love.graphics.setColor(1,1,1, 255)
	love.graphics.setBlendMode("alpha","premultiplied")
	for i, region in pairs(regions) do

		--love.graphics.draw(region.image,region.x/20 + w/2, region.y/20 + h/2,0,0.1,0.1)
		local cycleIndex = ((index) % (#regions+1)) 
		if cycleIndex == 0 then
			local x = region.x - 1342 - 1000
			local y = region.y + 6170 - 1000
			local scale = .125
			love.graphics.draw(region.image,x*scale/2 + w/2, y*scale/2 + h/2,0,scale,scale)
			love.graphics.circle("line", x*scale/2 + region.w*scale/4 + w/2, y*scale/2 + region.w*scale/4 + h/2, region.w*scale/4)
		elseif i == cycleIndex then
			love.graphics.draw(region.image,w/2,h/2,0,1,1,region.w/4, region.h/4)

		end
		--love.graphics.circle("line",w/2,h/2,regions[1].w/4)
	end
	love.graphics.setBlendMode("alpha")
	
	love.graphics.print(love.timer.getFPS(),10,10)
end

function love.keypressed(key)
	if key == "right" then
		index = index + 1
	elseif key == "left" then
		index = index - 1
	end
end


local byteTable = {128, 64, 32, 16, 8, 4, 2, 1}
function readByte(char)
	local short = string.byte(char)
	local out = {}
	for i = 1, 8 do
		local x = byteTable[i]
		if short >= x then
			out[i] = 1
			short = short - x
		else
			out[i] = 0
		end
	end
	local b128, b64, b32, b16, b8, b4, b2, b1 = unpack(out)
	return b128, b64, b32, b16, b8, b4, b2, b1
end

function readColorByte(char)
	local _,_, rh, rl, gh, gl, bh, bl = readByte(char)
	local r = rh*0.5 + rl*0.25
	local g = gh*0.5 + gl*0.25
	local b = bh*0.5 + bl*0.25

	return r,g,b
end