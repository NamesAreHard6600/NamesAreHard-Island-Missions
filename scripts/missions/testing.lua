-- mission Mission_NAH_Testing

local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath
local worldConstants = mod.libs.worldConstants

local a = ANIMS

modApi:appendAsset("img/units/mission/propeller.png",mod.resourcePath.."img/units/mission/propeller.png")
modApi:appendAsset("img/units/mission/propellera.png",mod.resourcePath.."img/units/mission/propellera.png")

modApi:appendAsset("img/combat/tiles_grass/invisible.png",mod.resourcePath.."img/tileset/invisible.png")
modApi:appendAsset("img/combat/tiles_grass/moving_tile.png",mod.resourcePath.."img/tileset/moving_tile.png")

a.NAH_Leaping_Tile = a.BaseUnit:new{Image = "units/mission/propeller.png", PosX = -37, PosY = -8}
a.NAH_Leaping_Tilea = a.NAH_Leaping_Tile:new{Image = "units/mission/propellera.png"}

local tiles = {{Point(5,5),Point(4,5),Point(5,4),Point(6,5),Point(5,6)},{Point(5,2),Point(4,2),Point(5,1),Point(6,2),Point(5,3)}}

Mission_NAH_Testing = Mission_Infinite:new {
  Name = "Testing",
  Environment = "Env_Moving_Tiles",
  MovingTiles = tiles,
}

function Mission_NAH_Testing:StartMission()
  for i, point in ipairs(self.MovingTiles[1]) do
    Board:ClearSpace(point)
    Board:SetCustomTile(point,"moving_tile.png")
  end
end

Env_Moving_Tiles = Environment:new{
  Name = "Leaping Tiles",
  Text = "Magic tiles are leaping around the island.", --Descriptive
  CombatName = "LEAPING TILES",
  StratText = "LEAPING TILES",
  CombatIcon = "advanced/combat/tile_icon/tile_wind_up.png",
  Position = 1,
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
      if Board:GetTerrain(point) == TERRAIN_ROAD then
        Board:MarkSpaceImage(point, combatIcon, GL_Color(255,226,88,0.75))
      end
    end
    for i, point in ipairs(self.MovingTiles[otherPos]) do
      if Board:GetTerrain(self.MovingTiles[self.Position][i]) == TERRAIN_ROAD then
        Board:MarkSpaceImage(point, "combat/tile_icon/tile_airstrike.png", GL_Color(255,226,88,0.75))
      end
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
  if pawn and pawn:GetType() == "NAH_Leaping_Tile" then
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

  ret:AddDelay(0.45) --Timing based on in game testing

  for k, id in ipairs(dying_pawns) do
    ret:AddScript(string.format([[
      local pawn = Board:GetPawn(%s)
      pawn:SetFlying(false)
      pawn:Fall(4)
    ]],id)) --modApi:runLater(pawn:SetSpace(Point(-1,-1)))
  end

	return ret
end

--Moves all the tiles at "from" locations to "to" locations
--Checks that all the from tiles are valid, and stops the movement if it is not
--from: The list of points we are moving tiles from
--to: The list of points we are moving tiles to, as matched with from
local function move_tiles(from, to)
  assert(type(from) == 'table')
  assert(type(to) == 'table')
  assert(#from == #to)

  --Make copies so we can edit them
  from = copy_table(from)
  to = copy_table(to)

  --Find all the bad indexes
  bad_indexes = {}
  for i, point in ipairs(from) do
    if Board:GetTerrain(point) ~= TERRAIN_ROAD then --Isn't a ground tile, we can't throw it
      table.insert(bad_indexes,i)
    end
  end

  --Working backwards, remove the bad indexes
  for k, v in ipairs(reverse_table(bad_indexes)) do
    table.remove(from,v)
    table.remove(to,v)
  end

  --Add and store tile pawns, and set tiles to invisible tiles
  local leaping_tiles = {}
  for i, point in ipairs(from) do
    local pawn = PAWN_FACTORY:CreatePawn("NAH_Leaping_Tile")
    Board:AddPawn(pawn,point)
    pawn:MoveToBottom() --Move it to the bottom so that we access it when needed
    Board:SetCustomTile(point,"invisible.png")
    table.insert(leaping_tiles,pawn:GetId())
  end

  --Get and trigger the leaps and such
  effect = get_effect(from,to)
  Board:AddEffect(effect)

  --Wait some time, then...
  modApi:scheduleHook(100, function()
    --Remove the invisible tiles
    for i, point in ipairs(from) do
      Board:SetTerrain(point,TERRAIN_HOLE)
    end
    --Add invisible tiles to end point
    for i, point in ipairs(to) do
      Board:SetTerrain(point,TERRAIN_ROAD)
      Board:SetCustomTile(point,"invisible.png")
    end
  end)

  --Wait for leap to finish: It takes 800 msec
  modApi:scheduleHook(800,
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


NAH_Leaping_Tile = {
  Name = "Moving Tile",
  Health = 2,
  MoveSpeed = 4,
  Image = "NAH_Leaping_Tile", --Change
  SoundLocation = "/support/civilian_tank/", --Probably Change
  DefaultTeam = TEAM_NONE,
  --SkillList = {"NAH_ExcavatorSkill"},
  IsPortrait = false,
  Massive = true,
  Flying = true,
}
AddPawn("NAH_Leaping_Tile")
