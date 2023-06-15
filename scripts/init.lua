local function init(self)
	--init variables
	local mod = mod_loader.mods[modApi.currentMod]
	local resourcePath = mod.resourcePath
	local scriptPath = mod.scriptPath
	local options = mod_loader.currentModContent[mod.id].options

	self.libs = {}
	self.libs.modApiExt = modapiext
	self.libs.weaponPreview = require(self.scriptPath.."libs/weaponPreview")
	self.libs.worldConstants = require(mod.scriptPath.."libs/worldConstants")

	local NAH_Missions = {
		--"Incinerator",
		--"Falling_Mountains",
		--"Digging",
		"Testing"
	}
	local missionList = easyEdit.missionList:add("NamesAreHard")

	for _, name in ipairs(NAH_Missions) do
		local mission_name = "Mission_NAH_"..name
		require(self.scriptPath.."missions/"..string.lower(name))
		--modApi:appendAsset("img/strategy/mission/"..mission_name..".png", self.resourcePath.."img/strategy/mission/"..mission_name..".png")
		--modApi:appendAsset("img/strategy/mission/small/"..mission_name..".png", self.resourcePath.."img/strategy/mission/small/"..mission_name..".png")
		missionList:addMission(mission_name,false)
	end
end


local function load(self,options,version)

end

local function metadata()

end

return {
  id = "NAH_Island_Missions",
  name = "NamesAreHard Missions",
	--icon = "modIcon.png",
	description = "My collection of missions for the collab island project.",
	modApiVersion = "2.9.1",
	gameVersion = "1.2.83",
  version = "1.0.2",
	requirements = { "kf_ModUtils" }, --cargo cult!
	dependencies = {
		modApiExt = "1.18",
		memedit = "1.0.2",
		easyEdit = "2.0.4",
	},
	metadata = metadata,
	load = load,
	init = init
}

--[[ Background
--TESTING
--Board:AddAnimation(Point(0,0),"cave_background",ANIM_NO_DELAY)
modApi:appendAsset("img/combat/bg_temp1.png",self.resourcePath.."img/combat/bg_temp1.png")
ANIMS.cave_background = Animation:new {
	Image = "combat/bg_temp1.png",
	NumFrames = 1,
	Time = 0.1,
	PosX = -(474/2),
	PosY = -84,
	Loop = true,
	Layer = ANIMS.LAYER_FLOOR,
}]]
