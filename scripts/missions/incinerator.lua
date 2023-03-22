-- mission Mission_NAH_Incinerator

local path = mod_loader.mods[modApi.currentMod].scriptPath
local this = {id = "Mission_NAH_Incinerator"}

Mission_NAH_Incinerator = Mission_Infinite:new{
  Name = "Incinerator",
  Objectives = Objective("Destroy the Missile Turret",1,1),
}

function Mission_NAH_Incinerator:StartMission()
	for i=2,5 do --Temporary, look at how other things add things to random places
    for j=2,5 do
      local point = Point(i,j)
      if not Board:IsBlocked(point,PATH_GROUND) then
        Board:AddPawn("DNT_IceCrawler1",point)
      end
    end
  end
end
