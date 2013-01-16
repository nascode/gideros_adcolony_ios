require "adcolony"

print("AdColony test")

local ready = true

-- LIST OF EVENTS --

adcolony:addEventListener(Event.VIDEO_INITIALIZED, function()
	print("VIDEO_INITIALIZED")
end)

adcolony:addEventListener(Event.VIDEO_READY, function()
	print("VIDEO_READY") -- then show video
	if not ready then 
		adcolony:showVideo() 
	end
end)

adcolony:addEventListener(Event.VIDEO_NOT_READY, function()
	print("VIDEO_NOT_READY")
	ready = false
end)

adcolony:addEventListener(Event.VIDEO_STARTED, function()
	print("VIDEO_STARTED")
end)

adcolony:addEventListener(Event.VIDEO_FINISHED, function()
	print("VIDEO_FINISHED")
end)


-- LIST OF API --

-- configure (default id) and prefetch video
adcolony:configure("appbdee68ae27024084bb334a", "vzf8e4e97704c4445c87504e") 

-- show video
--adcolony:showVideo()

-- show video to get coins with confirmation (not completed)
--adcolony:offerV4VC(nil, true) 

-- show video to get coins without confirmation (not completed)
--adcolony:showV4VC(nil,true) 

-- check whether adcolony has been configured or not
--adcolony:isConfigured()

-- enable/disable adcolony, default is enabled on ios
--adcolony:enable(true)