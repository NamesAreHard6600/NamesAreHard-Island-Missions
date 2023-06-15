-- mission Mission_NAH_Testing

local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath
local worldConstants = mod.libs.worldConstants

local a = ANIMS

modApi:appendAsset("img/units/mission/propeller.png",mod.resourcePath.."img/units/mission/propeller.png")
modApi:appendAsset("img/units/mission/propellera.png",mod.resourcePath.."img/units/mission/propellera.png")

modApi:appendAsset("img/combat/tiles_grass/invisible.png",mod.resourcePath.."img/tileset/invisible.png")
modApi:appendAsset("img/combat/tiles_grass/moving_tile.png",mod.resourcePath.."img/tileset/moving_tile.png")

a.NAH_Propeller = a.BaseUnit:new{Image = "units/mission/propeller.png", PosX = -37, PosY = -8, Layer = LAYER_FLOOR}
a.NAH_Propellera = a.NAH_Propeller:new{Image = "units/mission/propellera.png", NumFrames = 1}

local centers = {Point(5,5), Point(5,2)}
local tiles = {{Point(5,5),Point(4,5),Point(5,4),Point(6,5),Point(5,6)},{Point(5,2),Point(4,2),Point(5,1),Point(6,2),Point(5,3)}}

Mission_NAH_Testing = Mission_Infinite:new {
  Name = "Testing",
  Environment = "Env_Moving_Tiles",
  Centers = centers,
  MovingTiles = tiles,
}

function Mission_NAH_Testing:StartMission()
  for i, point in ipairs(self.MovingTiles[1]) do
    Board:ClearSpace(point)
    Board:SetCustomTile(point,"moving_tile.png")
  end
end

Env_Moving_Tiles = Environment:new{
  Name = "Moving Tiles",
  Text = "The land has ballons that float around.", --Descriptive
  CombatName = "MOVING TILES",
  StratText = "MOVING TILES",
  CombatIcon = "advanced/combat/tile_icon/tile_wind_up.png",
  Position = 1,
  Centers = centers,
  MovingTiles = tiles,
  Ready = false,
}
--TODO:
--DESCRIPTION

function Env_Moving_Tiles:MarkBoard()
  if self.Ready then
    local otherPos = self.Position%2+1
    local combatIcon = self.Position == 1 and "advanced/combat/tile_icon/tile_wind_up.png" or "advanced/combat/tile_icon/tile_wind_down.png"
    for i, point in ipairs(self.MovingTiles[self.Position]) do
      Board:MarkSpaceImage(point, combatIcon, GL_Color(255,226,88,0.75))
    end
    for i, point in ipairs(self.MovingTiles[otherPos]) do
      Board:MarkSpaceImage(point, "combat/tile_icon/tile_airstrike.png", GL_Color(255,226,88,0.75))
    end
  end
end

function Env_Moving_Tiles:IsEffect() return self.Ready end

function Env_Moving_Tiles:Plan()
  self.Ready = true
  return false
end

local function move_tile(p1,p2,effect)
  local pawn = Board:GetPawn(p1)
  if pawn and pawn:GetType() == "NAH_Propeller" then
    effect:AddCharge(Board:GetPath(p1, p2, pawn:GetPathProf()), NO_DELAY)
    --The second charge moves any pawns on it
    effect:AddCharge(Board:GetPath(p1, p2, pawn:GetPathProf()), NO_DELAY)
  end
  return effect
end

local function move_tiles(mission)
  local ret = SkillEffect()
  local new_speed = .25

  local currPos = mission.Position
  local newPos = mission.Position%2+1
  local distance = mission.MovingTiles[currPos][1]:Manhattan(mission.MovingTiles[newPos][1])

  worldConstants:setSpeed(ret,new_speed)

  for i, point in ipairs(mission.MovingTiles[currPos]) do
    local p1 = point
    local p2 = mission.MovingTiles[newPos][i]
    ret = move_tile(p1,p2,ret)
  end

  ret:AddDelay(0.08 * distance * worldConstants:getDefaultSpeed() / new_speed)
  worldConstants:resetSpeed(ret)

	return ret
end


function Env_Moving_Tiles:ApplyEffect()
  local currPos = self.Position
  local newPos = self.Position%2+1
  self.Ready = false

  --Add pawns and set invisible tile
  for i, point in ipairs(self.MovingTiles[currPos]) do
    local pawn = PAWN_FACTORY:CreatePawn("NAH_Propeller")
    Board:AddPawn(pawn,point)
    pawn:MoveToBottom() --Move it to the bottom so that we access it when needed
    Board:SetCustomTile(point,"invisible.png")
    --Board:SetTerrain(point,TERRAIN_HOLE)
  end

  --schmoving
  effect = move_tiles(self)

  Board:AddEffect(effect)

  --Needs to wait some time for stuff to start moving
  modApi:scheduleHook(100, function()
    --Remove the invisible tile
    for i, point in ipairs(self.MovingTiles[currPos]) do
      Board:SetTerrain(point,TERRAIN_HOLE)
    end
    --Add invisible tiles to end point
    for i, point in ipairs(self.MovingTiles[newPos]) do
      Board:SetTerrain(point,TERRAIN_ROAD)
      Board:SetCustomTile(point,"invisible.png")
    end
  end)

  modApi:conditionalHook(
  function()
    return not Board:IsBusy() --Wait for the last effect to finish fully
  end,
  function()
    --Kill the pawns and replace with tiles
    for i, point in ipairs(self.MovingTiles[newPos]) do
      local pawn = Board:GetPawn(point)
      if pawn and pawn:GetType() == "NAH_Propeller" then
        pawn:SetSpace(Point(-1,-1))
        pawn:Kill(false)
      end
      Board:SetCustomTile(point,"moving_tile.png")
    end
  end
  )

  self.Position = newPos

  return false
end


NAH_Propeller = {
  Name = "Moving Tile",
  Health = 2,
  MoveSpeed = 4,
  Image = "NAH_Propeller", --Change
  SoundLocation = "/support/civilian_tank/", --Probably Change
  DefaultTeam = TEAM_NONE,
  --SkillList = {"NAH_ExcavatorSkill"},
  IsPortrait = false,
  Massive = true,
  Flying = true,
  --MoveSkill = "NAH_Propeller_Move"
}
AddPawn("NAH_Propeller")

--[[
NAH_Propeller_Move = Move:new
{
}

function NAH_Propeller_Move:GetTargetArea(point)
	local ret = PointList()
  for dir=DIR_START, DIR_END do
    for i=1, 7 do
      local curr = point + DIR_VECTORS[dir]*i
      if Board:IsValid(curr) then
        ret:push_back(curr)
      else
        break
      end
    end
  end
  return ret
end

function NAH_Propeller_Move:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
  local new_speed = .25
  local distance = p2:Manhattan(p1)
  LOG("THIS MOVE SKILL")

  worldConstants:setSpeed(ret,new_speed)
	--local mission = GetCurrentMission()
  for dir=DIR_START, DIR_END do
    local vector = DIR_VECTORS[dir]
    local new_point = p1 + vector
    local pawn = Board:GetPawn(new_point)
    if pawn and pawn:GetType() == "NAH_Propeller" then
      ret:AddCharge(Board:GetPath(new_point, p2+vector, Pawn:GetPathProf()), NO_DELAY)
    end
  end

	ret:AddCharge(Board:GetPath(p1, p2, Pawn:GetPathProf()), NO_DELAY)

  ret:AddDelay(0.08 * distance * worldConstants:getDefaultSpeed() / new_speed)
  worldConstants:resetSpeed(ret)

	return ret
end
]]
