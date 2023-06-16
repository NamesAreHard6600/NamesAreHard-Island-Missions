--All the leaping tiles data that isn't part of the "library", but also isn't the actual mechanic
--ex: Pawn, assets, etc.
local a = ANIMS

modApi:appendAsset("img/units/mission/propeller.png",mod.resourcePath.."img/units/mission/propeller.png")
modApi:appendAsset("img/units/mission/propellera.png",mod.resourcePath.."img/units/mission/propellera.png")

modApi:appendAsset("img/combat/tiles_grass/invisible.png",mod.resourcePath.."img/tileset/invisible.png")
modApi:appendAsset("img/combat/tiles_grass/moving_tile.png",mod.resourcePath.."img/tileset/moving_tile.png")

a.NAH_Leaping_Tile = a.BaseUnit:new{Image = "units/mission/propeller.png", PosX = -37, PosY = -8}
a.NAH_Leaping_Tilea = a.NAH_Leaping_Tile:new{Image = "units/mission/propellera.png"}


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
