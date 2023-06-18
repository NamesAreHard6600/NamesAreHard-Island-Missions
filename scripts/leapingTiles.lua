--All the leaping tiles data that isn't part of the "library", but also isn't the actual mechanic
--ex: Pawn, assets, etc.
local mod = mod_loader.mods[modApi.currentMod]
local a = ANIMS

--Global Copy
NAH_Missions_leapingTiles = mod.libs.leapingTiles

local suffixes = {
  "",
  "_1_1",
  "_0_1",
  "_2_2",
  "_1_2",
  "_0_2",
}

--Tileset
modApi:appendAsset("img/combat/tiles_grass/invisible.png",mod.resourcePath.."img/tileset/invisible.png")
modApi:appendAsset("img/combat/tiles_grass/moving_tile.png",mod.resourcePath.."img/tileset/moving_tile.png")

--"pawns"
for i, suffix in ipairs(suffixes) do
  modApi:appendAsset("img/units/mission/leaping_tile"..suffix..".png",mod.resourcePath.."img/units/mission/leaping_tile"..suffix..".png")
end


--Fun Copy Paste Time

--Pawn ANIMS
a.NAH_Leaping_Tile = a.BaseUnit:new{Image = "units/mission/leaping_tile.png", PosX = -37, PosY = -13}
a.NAH_Leaping_Tilea = a.NAH_Leaping_Tile:new{}

a.NAH_Leaping_Tile_1_1 = a.NAH_Leaping_Tile:new{Image = "units/mission/leaping_tile_1_1.png"}
a.NAH_Leaping_Tile_1_1a = a.NAH_Leaping_Tile_1_1:new{}

a.NAH_Leaping_Tile_0_1 = a.NAH_Leaping_Tile:new{Image = "units/mission/leaping_tile_0_1.png"}
a.NAH_Leaping_Tile_0_1a = a.NAH_Leaping_Tile_0_1:new{}

a.NAH_Leaping_Tile_2_2 = a.NAH_Leaping_Tile:new{Image = "units/mission/leaping_tile_2_2.png"}
a.NAH_Leaping_Tile_2_2a = a.NAH_Leaping_Tile_2_2:new{}

a.NAH_Leaping_Tile_1_2 = a.NAH_Leaping_Tile:new{Image = "units/mission/leaping_tile_1_2.png"}
a.NAH_Leaping_Tile_1_2a = a.NAH_Leaping_Tile_1_2:new{}

a.NAH_Leaping_Tile_0_2 = a.NAH_Leaping_Tile:new{Image = "units/mission/leaping_tile_0_2.png"}
a.NAH_Leaping_Tile_0_2a = a.NAH_Leaping_Tile_0_2:new{}

NAH_Leaping_Tile = {
  Name = "Moving Tile",
  Image = "NAH_Leaping_Tile",
  DefaultTeam = TEAM_NONE,
  IsPortrait = false,
  Massive = true,
  Flying = true,
}
AddPawn("NAH_Leaping_Tile")

--_currenthealth_maxhealth
NAH_Leaping_Tile_1_1 = {
  Name = "Moving Tile",
  Image = "NAH_Leaping_Tile_1_1", --This would change
  DefaultTeam = TEAM_NONE,
  IsPortrait = false,
  Massive = true,
  Flying = true,
}
AddPawn("NAH_Leaping_Tile_1_1")

NAH_Leaping_Tile_0_1 = {
  Name = "Moving Tile",
  Image = "NAH_Leaping_Tile_0_1", --This would change
  DefaultTeam = TEAM_NONE,
  IsPortrait = false,
  Massive = true,
  Flying = true,
}
AddPawn("NAH_Leaping_Tile_0_1")

NAH_Leaping_Tile_2_2 = {
  Name = "Moving Tile",
  Image = "NAH_Leaping_Tile_2_2", --This would change
  DefaultTeam = TEAM_NONE,
  IsPortrait = false,
  Massive = true,
  Flying = true,
}
AddPawn("NAH_Leaping_Tile_2_2")

NAH_Leaping_Tile_1_2 = {
  Name = "Moving Tile",
  Image = "NAH_Leaping_Tile_1_2", --This would change
  DefaultTeam = TEAM_NONE,
  IsPortrait = false,
  Massive = true,
  Flying = true,
}
AddPawn("NAH_Leaping_Tile_1_2")

NAH_Leaping_Tile_0_2 = {
  Name = "Moving Tile",
  Image = "NAH_Leaping_Tile_0_2", --This would change
  DefaultTeam = TEAM_NONE,
  IsPortrait = false,
  Massive = true,
  Flying = true,
}
AddPawn("NAH_Leaping_Tile_0_2")
