--Custom Lib Designed for the flying island

local this = {}

local function leap_tile(p1,p2,effect)
  local dir = GetDirection(p1-p2)

  effect:AddLeap(Board:GetPath(p1, p2, PATH_FLYER), NO_DELAY)
  --The second leap moves any pawns on it
  effect:AddLeap(Board:GetPath(p1, p2, PATH_FLYER), NO_DELAY)

  local animation = SpaceDamage(p1)
  animation.sAnimation = "airpush_"..dir
  effect:AddDamage(animation)

  return effect
end

local function get_effect(from, to, spawn_pawn)
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

  for i, point in ipairs(from) do
    local p1 = point
    local p2 = to[i]
    ret = leap_tile(p1,p2,ret)
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
--@param spawn_pawn: The type of the pawn that is used to make the tile leap
--@param custom_tile: The custom tile that will be set to the new location - empty if it's a normal tile
--@param invisible_tile: The custom tile for your tileset that is invisible - it should just be an empty sprite
--Error Catching:
--Checks that all the from tiles are valid, and stops the movement if it is not
--Checks that all the to tiles are valid, and stops the movement if it is not
function this:move_tiles(from, to, spawn_pawn, custom_tile, invisible_tile)
  assert(type(from) == 'table', "LEAPING TILES: from is not a table")
  assert(type(to) == 'table', "LEAPING TILES: to is not a table")
  assert(type(spawn_pawn) == 'string', "LEAPING TILES: spawn_pawn is not a string")
  assert(type(custom_tile) == 'string', "LEAPING TILES: custom_tile is not a string")
  assert(type(invisible_tile) == 'string', "LEAPING TILES: invisible_tile is not a string")
  assert(#from == #to, "LEAPING TILES: from and to are different lengths")

  --Make copies so we can edit them
  from = copy_table(from)
  to = copy_table(to)

  --Find all the bad indexes
  bad_indexes = {}
  for i, point in ipairs(from) do
    local point2 = to[i]
    --From isn't a ground tile, we can't throw it.
    --To isn't a hole, it can't land safely.
    if Board:GetTerrain(point) ~= TERRAIN_ROAD or Board:GetTerrain(point2) ~= TERRAIN_HOLE then
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

  --Add and store tile pawns, and set tiles to invisible tiles
  local leaping_tiles = {}
  for i, point in ipairs(from) do
    local pawn = PAWN_FACTORY:CreatePawn(spawn_pawn)
    Board:AddPawn(pawn,point)
    pawn:MoveToBottom() --Move it to the bottom so that we access it when needed
    Board:SetCustomTile(point,invisible_tile)
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
      Board:SetCustomTile(point,"") --Reset Invisible
    end
    --Add invisible tiles to end point
    for i, point in ipairs(to) do
      Board:SetTerrain(point,TERRAIN_ROAD)
      Board:SetCustomTile(point,invisible_tile)
    end
  end)

  --Wait for leap to finish: It takes 800 msec
  modApi:scheduleHook(800,
  function()
    --Kill All Tile Pawns and Place Tiles Back
    for k, id in ipairs(leaping_tiles) do
      local pawn = Board:GetPawn(id)
      Board:SetCustomTile(pawn:GetSpace(),custom_tile)
      pawn:SetSpace(Point(-1,-1))
      pawn:Kill(true)
    end
  end
  )
end

--Moves a single tile instead of multiple, and just takes a point instead of a table
--@params see move_tile
function this:move_tile(from, to, spawn_pawn, custom_tile, invisible_tile)
  assert(type(from) == 'userdata', "from is not a point")
  assert(type(to) == 'userdata', "to is not a point")
  this:move_tiles({from},{to},spawn_pawn,custom_tile,invisible_tile)
end

return this
