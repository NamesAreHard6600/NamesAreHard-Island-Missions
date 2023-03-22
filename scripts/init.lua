local function init(self)
	--init variables
	local mod = mod_loader.mods[modApi.currentMod]
	local resourcePath = mod.resourcePath
	local scriptPath = mod.scriptPath
	local options = mod_loader.currentModContent[mod.id].options

	self.libs = {}
	self.libs.modApiExt = modapiext
	local NAH_Missions = {
		"Incinerator",
	}

	for _, name in ipairs(NAH_Missions) do
		local mission_name = "Mission_NAH_"..name
		require(self.scriptPath.."missions/"..string.lower(name))
		modApi:appendAsset("img/strategy/mission/"..mission_name..".png", self.resourcePath.."img/strategy/mission/"..mission_name..".png")
		modApi:appendAsset("img/strategy/mission/small/"..mission_name..".png", self.resourcePath.."img/strategy/mission/small/"..mission_name..".png")
	end
	local archive = easyEdit.missionList:get("archive")
	archive:addMission("Mission_NAH_Incinerator",false)

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
