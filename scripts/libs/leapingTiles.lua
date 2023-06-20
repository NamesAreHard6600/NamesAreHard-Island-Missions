--Custom Lib Designed for the flying island

--[[
VERSION 1.0.0
Use: Create a global or local copy like so:

local mod = mod_loader.mods[modApi.currentMod]
NAH_Missions_LeapingTiles = require(mod.scriptPath.."libs/leapingTiles"):init("NAH_Leaping_Tile","moving_tile.png","invisible.png")

If you want to run this in a script i.e. effect:AddScript(), you'll need it to be global

NAH_Missions_LeapingTiles:move_tiles({from},{to})

That will then move tiles from a list of points to a list of points.
See documentation at move_tiles() for more info

NOTE:
Capitalization is not my strong suit, and I kinda defaulted to python
Sorry if it's not what you would expect
]]--

local this = {}

--Initializes a copy of leaping tiles, with the following info
--@param spawn_pawn: The type of the pawn that is used to make the tile leap
--For leaping buildings, you should have additional pawns for each of the different building types
--Name it the same as spawn_pawn and append _[CurrentHealth]_[MaxHealth]
--Ex: A pawn that has a 2 buildings that's damaged once should be named spawn_pawn_1_2
--You realistically should have _1_1, _0_1, _2_2, _1_2, _0_2,
--There is a function to append all the assets automatically
--@param custom_tile: The custom tile that will be set to the new location - "" if it's a normal tile
--@param invisible_tile: The custom tile for your tileset that is invisible - it should just be an empty sprite
--This prevents units from falling to their deaths
function this:init(spawn_pawn, custom_tile, invisible_tile)
  assert(type(spawn_pawn) == 'string', "LEAPING TILES INIT: spawn_pawn is not a string")
  assert(type(custom_tile) == 'string', "LEAPING TILES INIT: custom_tile is not a string")
  assert(type(invisible_tile) == 'string', "LEAPING TILES INIT: invisible_tile is not a string")
  self.SpawnPawn = spawn_pawn
  self.CustomTile = custom_tile
  self.InvisibleTile = invisible_tile
  return self
end

function this:append_assets(prefix)
  assert(type(prefix) == 'string', "LEAPING TILES APPEND: prefix is not a string")

  local mod = mod_loader.mods[modApi.currentMod]
  local suffixes = {
    "",
    "_1_1",
    "_0_1",
    "_2_2",
    "_1_2",
    "_0_2",
  }
  for i, suffix in ipairs(suffixes) do
    modApi:appendAsset("img/units/mission/"..prefix..suffix..".png",mod.resourcePath.."img/units/mission/"..prefix..suffix..".png")
  end
end

function this:leap_tile(p1,p2,effect)
  local dir = GetDirection(p1-p2)

  effect:AddLeap(Board:GetPath(p1, p2, PATH_FLYER), NO_DELAY) --Leaps the tile (technically)
  --The second leap moves any pawns on it, if there's a pawn that's not a leap tile
  local pawn = Board:GetPawn(p1)
  if pawn and not pawn:GetType():find("^"..self.SpawnPawn) then
    effect:AddLeap(Board:GetPath(p1, p2, PATH_FLYER), NO_DELAY)
  end

  local animation = SpaceDamage(p1)
  animation.sAnimation = "airpush_"..dir
  effect:AddDamage(animation)

  return effect
end

function this:get_effect(from, to)
  local ret = SkillEffect()

  local distance = from[1]:Manhattan(to[1])

  local dying_pawns = {}

  for i, point in ipairs(to) do
    local pawn = Board:GetPawn(point)
    if pawn and not list_contains(from,point) then
      table.insert(dying_pawns,pawn:GetId())
    end
  end

  for i, point in ipairs(from) do
    local p1 = point
    local p2 = to[i]
    ret = self:leap_tile(p1,p2,ret)
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


--Leaps all the tiles at "from" locations to "to" locations
--@param from: The list of points we are moving tiles from
--@param to: The list of points we are moving tiles to, as matched with from (index 1 of from goes to index 1 of to)
--Error Catching:
--Checks that all the from tiles are valid, and stops the movement if it is not
--Checks that all the to tiles are valid, and stops the movement if it is not
--DOES check if the to tile is also moving
--DOES NOT CHECK if two tiles are leaping to the same point
--DOES NOT CHECK if the from tile is a "leaping tile" i.e. it will leap ANY tile (visuals will be off if doing so)
function this:move_tiles(from, to)
  assert(type(from) == 'table', "LEAPING TILES: from is not a table")
  assert(type(to) == 'table', "LEAPING TILES: to is not a table")
  assert(#from == #to, "LEAPING TILES: from and to are different lengths")

  --Make copies so we can edit them
  from = copy_table(from)
  to = copy_table(to)

  --Find all the bad indexes and removes them (repeat until there's none left)
  repeat
    bad_indexes = {}
    for i, point in ipairs(from) do
      local point2 = to[i]

      if false or
      not Board:IsValid(point) or --Not Valid
      not Board:IsValid(point2) or --Not Valid
      not (Board:GetTerrain(point) == TERRAIN_ROAD or Board:GetTerrain(point) == TERRAIN_BUILDING) or --From isn't a ground tile or building, we can't throw it.
      (Board:GetTerrain(point2) ~= TERRAIN_HOLE and not list_contains(from, point2)) or --To isn't a hole, it can't land safely, unless it's also moving (why we repeat, in case a from isn't valid)
      point == point2 then --We're trying to jump to the same point, that breaks things, so just don't
        table.insert(bad_indexes,i)
      end
    end

    --Working backwards, remove the bad indexes
    for k, v in ipairs(reverse_table(bad_indexes)) do
      table.remove(from,v)
      table.remove(to,v)
    end

    --No good tiles
    if #from == 0 then
      return
    end
  until #bad_indexes == 0

  --Remove Webs (I don't like how it's done)
  local pawns = {}
  for i, point in ipairs(from) do
    local pawn = Board:GetPawn(point)
    if pawn then
      table.insert(pawns,{pawn:GetId(),pawn:GetSpace()})
      pawn:SetSpace(Point(-1,-1))
    end
  end
  modApi:runLater(function()
    for k, list in ipairs(pawns) do
      Board:GetPawn(list[1]):SetSpace(list[2])
    end
  end)

  modApi:conditionalHook(
  function()
    return not Board:IsBusy() --Wait for webs to be gone
  end,
  function()
    --Add and store tile pawns, and set tiles to invisible tiles, and store buildings
    local leaping_tiles = {}
    for i, point in ipairs(from) do
      local pawn = PAWN_FACTORY:CreatePawn(self.SpawnPawn)
      local current_health = 0
      local max_health = 0
      if Board:GetTerrain(point) == TERRAIN_BUILDING then
        current_health = Board:GetHealth(point)
        max_health = Board:GetMaxHealth(point)
        pawn = PAWN_FACTORY:CreatePawn(self.SpawnPawn.."_"..current_health.."_"..max_health)
        Board:SetTerrain(point,TERRAIN_ROAD) --This would have to move, but for testing, it's here
      end
      Board:AddPawn(pawn,point)
      --pawn:MoveToBottom() --Not yet
      Board:SetCustomTile(point,self.InvisibleTile)
      table.insert(leaping_tiles,{pawn:GetId(),current_health,max_health})
    end

    --Get and trigger the leaps and such
    effect = self:get_effect(from,to)
    Board:AddEffect(effect)

    --Move Leaping Tiles to the bottom (visual)
    for k, list in ipairs(leaping_tiles) do
      local pawn = Board:GetPawn(list[1]) --id
      pawn:MoveToBottom()
    end

    --Wait a little bit
    modApi:scheduleHook(50,function()
      --Remove invisible tiles from start point
      for i, point in ipairs(from) do
        Board:SetTerrain(point,TERRAIN_HOLE)
        Board:SetCustomTile(point,"") --Reset Invisible Custom Tile
      end
    end)

    --Wait most of the time, then...
    modApi:scheduleHook(750, function()
      --Add invisible tiles to end point
      for i, point in ipairs(to) do
        Board:SetTerrain(point,TERRAIN_ROAD)
        Board:SetCustomTile(point,self.InvisibleTile)
      end
    end)

    --Wait for leap to finish: It takes 800 msec
    modApi:scheduleHook(800, function()
      --Kill All Tile Pawns and Place Tiles Back and add in buildings
      for k, list in ipairs(leaping_tiles) do
        local pawn = Board:GetPawn(list[1]) --id
        local point = pawn:GetSpace()
        Board:SetCustomTile(point,self.CustomTile)
        Board:RemovePawn(pawn)
        --Add in buildings
        if list[3] ~= 0 then
          Board:SetTerrain(point,TERRAIN_BUILDING)
          Board:SetHealth(point,list[2],list[3])
          Board:SetPopulated(true,point)
        end
      end
    end)
  end)
end

--Moves a single tile instead of multiple, and just takes a point instead of a table
--If you have multiple tiles to move, it's highly suggested you use move_tiles() to catch errors
--@params see move_tile
function this:move_tile(from, to)
  assert(type(from) == 'userdata', "LEAPING TILES: from is not a point")
  assert(type(to) == 'userdata', "LEAPING TILES: to is not a point")
  this:move_tiles({from},{to})
end

return this

--[[DEBUG
Board:SetHealth(Point(5,5),2,2); Board:SetHealth(Point(4,5),1,2); Board:SetHealth(Point(6,5),0,2); Board:SetHealth(Point(5,4),1,1); Board:SetHealth(Point(5,6),0,1);

]]
