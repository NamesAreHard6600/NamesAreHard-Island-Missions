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
    effect:AddLeap(Board:GetPath(p1, p2, pawn:GetPathProf()), NO_DELAY)
    --The second leap moves any pawns on it
    effect:AddLeap(Board:GetPath(p1, p2, pawn:GetPathProf()), NO_DELAY)
  end
  return effect
end

local function get_effect(from, to)
  local ret = SkillEffect()
  local new_speed = .25

  local distance = from[1]:Manhattan(to[1])

  local dying_pawns = {}

  for i, point in ipairs(to) do
    local pawn = Board:GetPawn(point)
    if pawn then
      table.insert(dying_pawns,pawn:GetId())
    end
  end

  worldConstants:setSpeed(ret,new_speed)

  for i, point in ipairs(from) do
    local p1 = point
    local p2 = to[i]
    ret = move_tile(p1,p2,ret)
  end

  ret:AddDelay(0.45) --Slightly less than leap time

  for k, id in ipairs(dying_pawns) do
    ret:AddScript(string.format([[
      local pawn = Board:GetPawn(%s)
      pawn:SetFlying(false)
      pawn:Fall(4)
    ]],id)) --modApi:runLater(pawn:SetSpace(Point(-1,-1)))
  end

	return ret
end

--from: The list of points we are moving tiles from
--to: The list of points we are moving tiles to, as matched with from
local function move_tiles(from, to)
  assert(type(from) == 'table')
  assert(type(to) == 'table')
  assert(#from == #to)

  local leaping_tiles = {}
  --Add pawns and set invisible tile
  for i, point in ipairs(from) do
    local pawn = PAWN_FACTORY:CreatePawn("NAH_Propeller")
    Board:AddPawn(pawn,point)
    --I don't know how important this is anymore.
    pawn:MoveToBottom() --Move it to the bottom so that we access it when needed
    Board:SetCustomTile(point,"invisible.png")
    table.insert(leaping_tiles,pawn:GetId())
  end

  --schmoving
  effect = get_effect(from,to)

  Board:AddEffect(effect)

  --Needs to wait some time for stuff to start moving
  modApi:scheduleHook(100, function()
    --Remove the invisible tile
    for i, point in ipairs(from) do
      Board:SetTerrain(point,TERRAIN_HOLE)
    end
    --Add invisible tiles to end point
    for i, point in ipairs(to) do
      Board:SetTerrain(point,TERRAIN_ROAD)
      Board:SetCustomTile(point,"invisible.png")
    end
  end)

  modApi:scheduleHook(800, --Wait for leap to finish: It takes 800 msec
  function()
    --Kill All Tile Pawns and Place Tiles Back
    for k, id in ipairs(leaping_tiles) do
      local pawn = Board:GetPawn(id)
      Board:SetCustomTile(pawn:GetSpace(),"moving_tile.png")
      pawn:SetSpace(Point(-1,-1))
      pawn:Kill(true)
    end
  end
  )
end

function Env_Moving_Tiles:ApplyEffect()
  local currPos = self.Position
  local newPos = self.Position%2+1
  self.Ready = false

  move_tiles(self.MovingTiles[currPos],self.MovingTiles[newPos])

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
