-- mission Mission_NAH_Testing

local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath
--local worldConstants = mod.libs.worldConstants

local tiles = {
  Point(4,1),
  Point(4,2),
  Point(4,5),
  Point(4,6),
  Point(5,1),
  Point(5,2),
  Point(5,5),
  Point(5,6),
  Point(6,1),
  Point(6,2),
  Point(6,5),
  Point(6,6),
}

Mission_NAH_Leaping_Control = Mission_Infinite:new {
  Name = "Controled Tiles",
  ControlStickPos = Point(0,3),
  ControlStickId = nil,
}

function Mission_NAH_Leaping_Control:StartMission()
  local control_stick = PAWN_FACTORY:CreatePawn("Control_Stick")
  Board:ClearSpace(self.ControlStickPos)
  Board:AddPawn(control_stick,self.ControlStickPos)
  self.ControlStick = control_stick:GetId()
  for y=0,7 do
    for x=4,6 do
      local point = Point(x,y)
      local pawn = Board:GetPawn(point)
      if pawn then
        pawn:SetSpace(Point(7,pawn:GetSpace().y)) --HACKY
      end
      Board:ClearSpace(point)
      Board:BlockSpawn(point,BLOCKED_PERM)
      Board:SetTerrain(point,TERRAIN_HOLE)
    end
  end
  for i, point in ipairs(tiles) do
    Board:SetTerrain(point,TERRAIN_ROAD)
    Board:SetCustomTile(point,"moving_tile.png")
  end
end


Control_Stick = Pawn:new {
  Image = "generator3",
	Health = 2,
	MoveSpeed = 0,
	--NonGrid = true,
	SkillList = { "Control_Stick_Attack" },
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Pushable = false,
	Corporate = true,
	Corpse = true,
	IgnoreSmoke = true,
	SoundLocation = "/support/earthmover",
}
AddPawn("Control_Stick")

Control_Stick_Attack = Skill:new {
  Name = "Control Tiles",
  Description = "Control which direction tiles leap to."
}

function Control_Stick_Attack:GetTargetArea(p1)
  local ret = PointList()
  ret:push_back(p1+DIR_VECTORS[DIR_UP])
  ret:push_back(p1+DIR_VECTORS[DIR_DOWN])
  return ret
end

function Control_Stick_Attack:GetSkillEffect(p1,p2)
  local ret = SkillEffect()
  local mission = GetCurrentMission()
  local vector = p2-p1

  local from = {}
  local to = {}

  --Search all possible spots for moving tiles
  for y=0,7 do
    for x=4,6 do
      local point = Point(x,y)
      if Board:GetTerrain(point) == TERRAIN_ROAD and Board:GetCustomTile(point) == "moving_tile.png" then
        table.insert(from,point)
        table.insert(to,point+vector)
      end
    end
  end

  ret:AddScript(string.format([[
    NAH_Missions_leapingTiles:move_tiles(%s,%s,'NAH_Leaping_Tile','moving_tile.png','invisible.png')
  ]],save_table(from),save_table(to)))

  return ret
end
