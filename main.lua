local regions = {}
local colors = {}
local colors2 = {}
local shadows = {}
local index = 1
local sepia = {0.666667, 0.603922, 0.513726}
--local watercolor = {0.566667, 0.503922, 0.443726}

local outlinecolor = {1,1,1}
colors.Slate = {0.176471, 0.176471, 0.176471}
colors.Pavement = {0.580392, 0.580392, 0.54902}
colors.Limestone = {0.690196, 0.619608, 0.556863}
colors.Salt = {0.745098, 0.572549, 0.776471}
colors.LeafyGrass = {0.45098, 0.517647, 0.290196}
colors.Asphalt = {0.482353, 0.423529, 0.466667}
colors.CrackedLava = {0.819608, 0.54902, 0.215686}
colors.Ground = {0.333333, 0.298039, 0.192157}
colors.Basalt = {0.0666667, 0.0666667, 0.0666667}
colors.Mud = {0.14902, 0.113725, 0.0901961}
colors.Sandstone = {0.439216, 0.352941, 0.286275}
colors.Snow = {0.764706, 0.780392, 0.854902}
colors.Glacier = {0.231373, 0.231373, 0.231373}
colors.Rock = {0.117647, 0.117647, 0.117647}
colors.Concrete = {0.498039, 0.4, 0.247059}
colors.Cobblestone = {0.517647, 0.482353, 0.352941}
colors.WoodPlanks = {0.545098, 0.427451, 0.309804}
colors.Sand = {0.666667, 0.603922, 0.513726}
colors.Brick = {0.541176, 0.337255, 0.243137}
colors.Ice = {0.756863, 0.835294, 0.878431}
colors.Grass = {0.415686, 0.498039, 0.247059}

colors.SmoothPlastic = {220/255,220/255,220/255}
colors.Plastic = {220/255,220/255,220/255}
colors.Wood = {174/255,145/255,115/255}
colors.Foil = {220/255,220/255,220/255}
colors.Fabric = {220/255,220/255,220/255}
colors.Glass = {220/255,220/255,220/255}
colors.Granite = {0.498039, 0.4, 0.247059}
colors.CorrodedMetal = {220/255,220/255,220/255}
colors.Marble = {0.498039, 0.4, 0.247059}
colors.Pebble = {0.498039, 0.4, 0.247059}

colors.Metal = {220/255,220/255,220/255}
colors.DiamondPlate = {220/255,220/255,220/255}
colors.Neon = {220/255,220/255,220/255}

colors.Water = {114/255,148/255,160/255,0}--{0.566667, 0.503922, 0.413726,0}

local watercolor = {colors.Water[1], colors.Water[2],colors.Water[3]}
local materialCodes = {
	["Plastic"] = "a",
	["Wood"] = "b",
	["Slate"] = "c",
	["Concrete"] = "d",
	["CorrodedMetal"] = "e",
	["DiamondPlate"] = "f",
	["Foil"] = "g",
	["Grass"] = "h",
	["Ice"] = "i",
	["Marble"] = "j",
	["Granite"] = "k",
	["Brick"] = "l",
	["Pebble"] = "m",
	["Sand"] = "n",
	["Fabric"] = "o",
	["SmoothPlastic"] = "p",
	["Metal"] = "q",
	["WoodPlanks"] = "r",
	["Cobblestone"] = "s",
	["Rock"] = "t",
	["Glacier"] = "u",
	["Snow"] = "v",
	["Sandstone"] = "w",
	["Mud"] = "x",
	["Basalt"] = "y",
	["Ground"] = "z",
	["Water"] = "0",
	["CrackedLava"] = "1",
	["Neon"] = "2",
	["Glass"] = "3",
	["Asphalt"] = "4",
	["LeafyGrass"] = "5",
	["Salt"] = "6",
	["Limestone"] = "7",
	["Pavement"] = "8",
}

for material, color in pairs(colors) do
	color[1] = (color[1] + sepia[1])/2
	color[2] = (color[2] + sepia[2])/2
	color[3] = (color[3] + sepia[3])/2
	colors2[materialCodes[material]] = color
	local s = 0.7
	local shadow = {color[1]*s, color[2]*s, color[3]*s, 0.5}
	shadows[materialCodes[material]] = shadow
	print(material, unpack(color))
end

for i, v in pairs(materialCodes) do
	if not colors2[v] then print(i) end
end



function love.load()
	local startTime = love.timer.getTime()
	print(love.getVersion())
	love.filesystem.setIdentity("minimap")
	love.window.setMode(1200,1000)
	love.graphics.setDefaultFilter("linear", "nearest", 8)

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
			for char, metachar in string.gmatch(line, "(%S)(%w)") do
				drawX = drawX - 1
				if char == "?" then char = "0" end
				if not region.data[drawX] then
					region.data[drawX] = {}
					region.meta[drawX] = {}
				end
				region.data[drawX][drawY] = char
				region.meta[drawX][drawY] = metachar
			end
		end
	end
	if not alreadyGenerated then
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

	function r:render()
		function check(x, y)
			return self.data[y] and self.data[y][x]
		end

		love.graphics.setCanvas(self.canvas)
		--love.graphics.clear(128/255,145/255,168/255)
		for y, row in pairs(self.data) do
			for x, char in pairs(row) do
				if colors2[char] then
					love.graphics.setBlendMode("alpha")
					love.graphics.setColor(unpack(colors2[char]))

					love.graphics.rectangle("fill",x*2-1,y*2-1,2,2)
					if self.meta[y][x] == "L" then
						--do nothing lol
					elseif self.meta[y][x] == "S" then
						--[[if char ~= "0" then
							love.graphics.setColor(unpack(shadows[char]))
						else
							local alpha = 1 - math.min(1,math.sqrt((x*spp-self.w/2)^2 + (y*spp-self.h/2)^2) / (self.w/2) )
							love.graphics.setColor(watercolor[1]/2,watercolor[2]/2,watercolor[3]/2, math.sqrt(alpha)/2)
						end]]

						local r,g,b = unpack(shadows[char])
						if char ~= "0" then
							love.graphics.setColor(r,g,b)
						else
							local a = 1 - math.min(1,math.sqrt((x*spp-self.w/2)^2 + (y*spp-self.h/2)^2) / (self.w/2) )
							love.graphics.setColor(r,g,b,a)
						end

						if (y + x) % 2 == 0 then
							love.graphics.points(x*2+1,y*2+1, x*2, y*2)
						else
							love.graphics.points(x*2+1,y*2, x*2, y*2+1)
						end
					elseif self.meta[y][x] == "B" then
						local r,g,b = unpack(shadows[char])
						if char ~= "0" then
							love.graphics.setColor(r,g,b)
						else
							local a = 1 - math.min(1,math.sqrt((x*spp-self.w/2)^2 + (y*spp-self.h/2)^2) / (self.w/2) )
							love.graphics.setColor(r,g,b,a)
						end

						love.graphics.points(x*2+1,y*2, x*2, y*2+1,x*2+1,y*2+1)
					elseif self.meta[y][x] == "H" then
						local r, g, b = love.graphics.getColor()
						
						if char ~= "0" then
							love.graphics.setColor(math.min(1,r+0.2), math.min(1,g+0.2), math.min(1,b+0.2))
							love.graphics.points(x*2+1,y*2+1, x*2, y*2)
						else
							local a = 1 - math.min(1,math.sqrt((x*spp-self.w/2)^2 + (y*spp-self.h/2)^2) / (self.w/2) )
							love.graphics.setColor(math.min(1,r+0.1), math.min(1,g+0.2), math.min(1,b+0.3), a)
							love.graphics.points(x*2+1,y*2)
						end
					elseif tonumber(self.meta[y][x]) then

						--DEPTH: NOT USED IN CURRENT VERSION
						local depth = tonumber(self.meta[y][x])
						local alpha = 1 - (math.floor(depth*4)/4 + 1)/10
						local distanceAlpha = 1 - math.min(1,math.sqrt((x*spp-self.w/2)^2 + (y*spp-self.h/2)^2) / (self.w/2) )
						local r, g, b = unpack(watercolor)
						local r2 = r/2
						local g2 = g/2
						local b2 = b/2
						r = r*alpha + r2*(1-alpha)
						g = g*alpha + g2*(1-alpha)
						b = b*alpha + b2*(1-alpha)
						love.graphics.setColor(r,g,b, 1)
						love.graphics.rectangle("fill",x*2-1,y*2-1,2,2)
					end

					--love.graphics.setColor(colors[char][1]*.5,colors[char][2]*.5,colors[char][3]*.5)
					love.graphics.setColor(unpack(outlinecolor))

					local right = check(x+1, y)
					local left = check(x-1, y)
					local up = check(x, y-1)
					local down = check(x, y+1)

					if right and right ~= char and right == "0" then
						love.graphics.points(x*2+2, y*2, x*2+2, y*2+1)
					end
					if left and left ~= char and left == "0" then
						love.graphics.points(x*2-1, y*2, x*2-1, y*2+1)
					end
					if up and up ~= char and up == "0" then
						love.graphics.points(x*2, y*2-1, x*2+1, y*2-1)
					end
					if down and down ~= char and down == "0" then
						love.graphics.points(x*2, y*2+1, x*2+1, y*2+1)
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
		love.graphics.draw(region.image,x*scale/2 + w/2, y*scale/2 + h/2,0,scale,scale)
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