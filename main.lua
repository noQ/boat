
display.setStatusBar( display.HiddenStatusBar )
-- activate multitiuch 
system.activate( "multitouch" )
-- include Corona's "physics" library
local physics = require "physics"
-- inlclude "lime" - to load map
local lime	  = require("lime")
--include ui
local ui = require("ui")

-- start physics and set gravity
physics.start();
physics.setGravity(0,0)
-- set velocity
--physics.setVelocityIterations(7) 

-- set accelerometer interval
system.setAccelerometerInterval(50)
 
-- start recording and set volume (1.0 = maximum)
media.setSoundVolume(1.0)
r = media.newRecording()
-- start recording sounds
r:startRecording()
r:startTuner()

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5

local STATE_IDLE 	 = "Idle"
local STATE_MOVING 	 = "Moving"
local STATE_FLOATING = "Floating"

local PHASE_START	= "began"
local PHASE_MOVED	= "moved"
local PHASE_END		= "ended"
local PHASE_CANCELED= "cancelled"
-- define directions : left and right 
local DIRECTION_LEFT = -1
local DIRECTION_RIGHT = 1
-- set start point 
local currentMapYPosition = 2278
local currentMapXPosition = 100
-- accelerometre motion x,y
local motionX = 0;
local motionY = 0;
local yMapPos		 = 2260
local jumpPos 		 = 900
local mapSpeed 		 = 20
local fleaSpeed		 = 10

-- set gravity and friction
local gravity  = .09
local friction = 0.8 
local speedX,speedY


-- Disable culling.  With the new screen culling you will need to update the map if it is bigger than a screen.
lime.disableScreenCulling()

-----------------------------------------------------------------------------------------
-- LOAD MAP
--  
-----------------------------------------------------------------------------------------

-- Load your map
local map = lime.loadMap("level1.tmx")

-- load player (boat)
local onPlayerProperty = function(property, type, object)
	player = object.sprite
end
-- add property listner for player (based on property IsPlayer - defined in level1.tmx)
map:addPropertyListener("IsPlayer", onPlayerProperty)

-- Create the visual
local visual = lime.createVisual(map)

-- build physical map
local physicalMap = lime.buildPhysical(map)
-- set map point
function mapToZero()
	-- Position the map over the central tree
	map:setPosition(currentMapXPosition, currentMapYPosition)
end

-- this function will move the map
function moveMap(moveX,moveY)
	map:slideToPosition(moveX, moveY,1000)
end



-- player action
local function isMoving(self,event)
	if yMapPos < 360 then
		end_text = display.newText("Game Over", 120,110, "Helvetica")
		self.canMove = false
	end
	
    --print("==== event ==== ")
    for k,v in pairs(event) do
    	print(k,v)
    end
	
	if self.canMove then
			print("yes...is moving!")
			-- scale object 
			self.state = STATE_MOVING

			-- set boat new position
			xPos = event.x
			yPos = self.y - 50
			-- move the map
			yMapPos = yMapPos - 50
			if self.y < 75 then
				moveMap(xPos,yMapPos)
			end
			-- save new flea coords
			--local vx, vy = self:getLinearVelocity()
			--print("velocity")
			--print(vx,vy)
			--print("=====")
			--self:setLinearVelocity(0,self.velocity)
			--self:applyLinearImpulse( 0, -2, 1, 1 )

			-- self.y = yPos
			-- self.x = xPos
	end
	player:prepare("anim" .. self.state)
	player:play()
	return self
end

local function isBoatMovedWithFinger(self)
	if self.canMove then
		self.state = STATE_FLOATING
	end
	player:prepare("anim" .. self.state)
	player:play()					
	return self		
end

local function isStoped(self)
	if self.canMove then
		self.state = STATE_IDLE
	end
	player:prepare("anim" .. self.state)
	player:play()					
	return self
end

-- create touch event
local onPlayerTouch = function(self,event)

	-- read phase 
	local tevt	= event.target
	local phase = tostring(event.phase)
	if self.canMove then
		-- user touch the player 
		if phase == PHASE_START then		-- user put the finger on actor
			self = isMoving(self,event)
		elseif phase == PHASE_MOVED then	-- user move the actor with finger
			self = isBoatMovedWithFinger(self)
		elseif phase == PHASE_END then	-- touch removed
			self = isStoped(self) 
		end
	end
end

-- check collision
local function onPlayerCollision(self,event)
	print("begin collision: " .. event.phase)
	if event.phase == "began" then
	
		-- boat can pickup the item 
		if event.other.IsPickup then
			print("Item is pickup = true")
			local text = nil
			local item = event.other
			
			local onTransitionEnd = function(transEvt)
				if transEvt["removeSelf"] then
					transEvt:removeSelf()
				end
			end
			-- remove object when transition is complete
			transition.to(item,{ time = 300,alpha=0, onComplete=onTransitionEnd})

			-- here you can define a lot of items			
			if item.pickupType == "item" then
				-- is the secret map ?		
				if item.itemName == "map" then
					text = display.newText( "Hidden Map discovered!", 0, 0, "Helvetica", 16 )
					system.vibrate()
				end
				-- is empty bottle
				if item.itemName == "emptybottle" then
					text = display.newText( "Empty bottle discovered!", 0, 0, "Helvetica", 16 )
					system.vibrate()
				end
				-- bottle with points
				if item.itemName == "bottle" then
					text = display.newText("You got " .. item.pointsValue .. " Points!", 0, 0, "Helvetica", 16 )
					system.vibrate()
				end
			end
			-- is healt ?
			if item.pickupType == "health" then 
				text = display.newText( item.healthValue .. " Extra Health!", 0, 0, "Helvetica", 16 )
				system.vibrate()
			end
			-- write on scree
			if text then
				text:setTextColor(255, 255, 255)
				-- display on center
				text.x = display.contentCenterX
				text.y = text.height / 2
			end
			-- remove text when complete
			transition.to(text, {time = 1100, alpha = 0, onComplete=onTransitionEnd})
			
		end
		if event.other.IsObstacle then
			print("collision - obstacle")
			player.canMove = false
			end_text = display.newText("Actor is dead!", 120,110, "Helvetica")
			physics.pause()
			if player then
				player:removeSelf()	-- widgets must be manually removed
				player = nil
			end
		end		
	elseif (event.phase == "ended") then
		if event.other.IsGround then
			player.canMove = true
		end
	end
end

local frequency = display.newText("freq", 120, 150, native.systemFont, 16)
frequency:setTextColor(255, 255, 255)


local onUpdate = function(event)
	-- if recording then move the player if user blow in the microphone 
	if r:isRecording () then
	    local micVolume = r:getTunerVolume()
	    if micVolume == 0 then
			player.state = STATE_IDLE
			player:prepare("anim" .. player.state)
			player:play()
	    	return 
	    end
	    
		-- Convert RMS power to dB scale
    	micVolume = 20 * 0.301 * math.log(micVolume)
    	if (tonumber(micVolume) > -4 ) then -- moving objects

				local num = tonumber(micVolume)
				frequency.text = tostring("Moving Vol: " .. micVolume)
				frequency.size = 13
				
				player.state = STATE_MOVING
				local vx, vy = player:getLinearVelocity()								
				player:applyForce(0, -5, player.x, -player.y)
				if vx ~= 0 then
					player:setLinearVelocity(vx * 0.15, vy)
				end

				-- set player position
				player.x = player.x + motionX
				player.x = player.x + motionY
				
				player:prepare("anim" .. player.state)
				player:play()
				
		elseif ( tonumber(micVolume) > -20 ) then -- moving objects
				
				local num = tonumber(micVolume)
				frequency.text = tostring("Iddle Vol: " .. micVolume)
				frequency.size = 13
			
				player.state = STATE_IDLE
				
				local vx, vy = player:getLinearVelocity()
				if vx ~= 0 then
					player:setLinearVelocity(vx * 0.1, vy)
				end
				player:applyForce(0, -1.2, player.x, -player.y)

				-- set player position
				player.x = player.x + motionX/2
				player.x = player.x + motionY/2
				
				player:prepare("anim" .. player.state)
				player:play()
				
				
		elseif ( tonumber(micVolume) < -40 ) then
		
			local num = tonumber(micVolume)
			frequency.text = tostring("Vol: " .. micVolume)
			frequency.size = 13
			
			player.state = STATE_IDLE
			player:setLinearVelocity(0,-1.0)
			
			-- set player position
			player.x = player.x
			player.x = player.x
			
			player:prepare("anim" .. player.state)
			player:play()
			
		end
		
	else
		print("Mic is off! Turn on the microphone!")
	
		player.state = STATE_IDLE
		player:prepare("anim" .. player.state)
		player:play()
	end
	-- update map event
	map:update(event)
	
end

local function onAccelerate(event)
	motionX = 15 * event.xGravity;
	motionY = 15 * event.yGravity;
end

-- set map to zero point
mapToZero()

-- set focus on plyaer
map.setFocus(player)

player.touch 	  = onPlayerTouch
player.collision  = onPlayerCollision

player:addEventListener("touch",player)
player:addEventListener("collision",player)

Runtime:addEventListener("enterFrame", onUpdate)
-- use accelerometer to move the boat
Runtime:addEventListener("accelerometer",onAccelerate)

player.state = STATE_IDLE
player:toFront()
player:prepare("anim" .. player.state)
player:play()
