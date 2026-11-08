-- cobble hills logic (HUSH V6.2 - FULL RESGATE)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)
if getgenv().Cobble_Unload then pcall(getgenv().Cobble_Unload) end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

if not Drawing then warn("[cobble] sem Drawing API"); return end

-- ==========================================
-- CONFIG
-- ==========================================
local defaults = {
    ESP  = {
        Enabled=true, Box=true, Chams=true, Name=true, Dist=true, Weapon=true,
        Walker     = { Enabled=true, Box=true, Name=true, Dist=true, Health=true },
        Vehicle    = { Enabled=true, Name=true, Dist=true },
        Extraction = { Enabled=true, Name=true, Dist=true },
        LootBag    = { Enabled=true, Dist=true },
        Body       = { Enabled=false, Name=true },
        WorldFind  = { Enabled=true, Name=true },
        Watcher    = { Enabled=false },
    },
    Loot = {
        Enabled=true, MaxDist=150, Labels=true,
        TierEnabled = { [0]=true,[1]=true,[2]=true,[3]=false },
        PerContainer = {},
    },
    Util = {
        SilentWalk=true, Fullbright=false, NightVision=false,
        Breath=false, AutoPickup=false,
    },
    AutoPickupRadius = 8,
    AutoPickupRate   = 0.7,
    Aim  = {
        Enabled=true, AlwaysOn=false, Key=Enum.UserInputType.MouseButton2,
        FOV=60, Smooth=0.45, ShowFOV=true,
        Bone="head", Prediction=0.15, WallCheck=true, TeamCheck=true,
        Silent=false, Visual=false, 
        MagicSnap=true, AutoFire=true, FireDelay=0.1 -- TRIGGERBOT
    },
    HUD  = { Enabled=true },
}

local Config = getgenv().CobbleConfig or {}
local function merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v)
        elseif dst[k] == nil then dst[k] = v end
    end
end
for s, tbl in pairs(defaults) do
    if type(tbl) == "table" then
        Config[s] = Config[s] or {}
        merge(Config[s], tbl)
    elseif Config[s] == nil then Config[s] = tbl end
end
getgenv().CobbleConfig = Config

local connections = {}
local alive = true
local function track(c) connections[#connections+1] = c; return c end

-- ==========================================
-- FUNÇÕES DE TIME E LUZ
-- ==========================================
local function isTeammate(plr)
    if not LocalPlayer.Team then return false end
    if plr.Team == LocalPlayer.Team then return true end
    if LocalPlayer.TeamColor and plr.TeamColor == LocalPlayer.TeamColor then return true end
    return false
end

local FB_DEFAULT = { Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime, FogEnd=Lighting.FogEnd, ExposureCompensation=Lighting.ExposureCompensation }
local function applyFullbright()
    Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1)
    Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 1e5; Lighting.ExposureCompensation = 1
end
local function restoreFullbright() for k, v in pairs(FB_DEFAULT) do pcall(function() Lighting[k] = v end) end end

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 15)
local function R(name) return RemotesFolder and RemotesFolder:FindFirstChild(name) or nil end

local NightVisionRemote = R("NightVision")
local LookRemote        = R("Look")
local LootRemote        = R("Loot")
local InvActionRem      = R("InvAction")
local DoorRemote        = R("Door")
local PaperMapRem       = R("PaperMap")
local BreathRemote      = R("Breath")
local DownedRemote      = R("Downed")
local MoveRemote        = R("Move")
local StanceRemote      = R("Stance")
local DeployRemote      = R("Deploy")
local ReplayRemote      = R("Replay")

-- ==========================================
-- CACHES
-- ==========================================
local CachedPlayers = {}
task.spawn(function()
    while alive do
        local temp = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char then
                    local hum  = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if hum and root and hum.Health > 0 then
                        local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
                        local sx, sy = 2, 5
                        if ok and cf and size then sx, sy = size.X, size.Y end
                        temp[char] = { Player=plr, Hum=hum, Root=root, Head=char:FindFirstChild("Head"), SizeX=sx, SizeY=sy }
                    end
                end
            end
        end
        CachedPlayers = temp
        task.wait(0.2)
    end
end)

local MONSTER_COLOR = { Listener = Color3.fromRGB(255, 60, 60), Mother = Color3.fromRGB(220, 0, 220) }
local CachedWalkers = {}
task.spawn(function()
    while alive do
        local temp = {}
        local function add(m)
            local hum = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                temp[m] = { Model=m, Hum=hum, Root=root, Name=m.Name, Color=MONSTER_COLOR[m.Name] or Color3.fromRGB(255,120,80) }
            end
        end
        local monsters = Workspace:FindFirstChild("Monsters")
        if monsters then 
            for _, m in ipairs(monsters:GetChildren()) do 
                if m:IsA("Model") then add(m) end 
            end 
        end
        local mother = Workspace:FindFirstChild("Mother")
        if mother and mother:IsA("Model") then add(mother) end
        CachedWalkers = temp
        task.wait(0.4)
    end
end)

local CachedExtractions = {}
task.spawn(function()
    while alive do
        local temp = {}
        local town = Workspace:FindFirstChild("Town")
        local exits = town and town:FindFirstChild("Exits")
        if exits then
            for _, exit in ipairs(exits:GetChildren()) do
                local ext = exit:FindFirstChild("Extraction")
                if ext then
                    local pos
                    local prompt = ext:FindFirstChild("ExtractPrompt", true)
                    if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then 
                        pos = prompt.Parent.Position
                    else 
                        local bp = ext:FindFirstChildWhichIsA("BasePart", true)
                        if bp then pos = bp.Position end 
                    end
                    if pos then temp[exit] = { Name=exit.Name, Pos=pos } end
                end
            end
        end
        CachedExtractions = temp
        task.wait(2)
    end
end)

local CachedLootBags, CachedBodies, CachedWorldFinds, CachedWatchers, CachedVehicles = {}, {}, {}, {}, {}
local function anyPartPos(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model.Position end
    local bp = model:FindFirstChildWhichIsA("BasePart", true)
    return bp and bp.Position or nil
end

task.spawn(function()
    while alive do
        local lb, bo, wf, wa, ve = {}, {}, {}, {}, {}
        local folder = Workspace:FindFirstChild("LootBags")
        if folder then for _, bag in ipairs(folder:GetChildren()) do local pos = anyPartPos(bag); if pos then lb[bag] = { Name=bag.Name, Pos=pos } end end end
        CachedLootBags = lb

        folder = Workspace:FindFirstChild("Bodies")
        if folder then for _, b in ipairs(folder:GetChildren()) do local pos = anyPartPos(b); if pos then bo[b] = { Name=b.Name, Pos=pos } end end end
        CachedBodies = bo

        folder = Workspace:FindFirstChild("WorldFinds")
        if folder then for _, w in ipairs(folder:GetChildren()) do local pos = anyPartPos(w); if pos then wf[w] = { Name=w.Name, Pos=pos } end end end
        CachedWorldFinds = wf

        folder = Workspace:FindFirstChild("Watchers")
        if folder then for _, w in ipairs(folder:GetChildren()) do local pos = anyPartPos(w); if pos then wa[w] = { Name=w.Name, Pos=pos } end end end
        CachedWatchers = wa

        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("VehicleSeat") then
                local model = d
                while model and model.Parent and not model.Parent:IsA("Workspace") do
                    if model:IsA("Model") and (model.Name:lower():find("car") or model.Name:lower():find("sedan") or model.Name:lower():find("van") or model.Name:lower():find("truck") or model.Name:lower():find("cruiser") or model.Name:lower():find("humvee") or model.Name:lower():find("chopper") or model.Name:lower():find("super")) then break end
                    model = model.Parent
                end
                if model and model:IsA("Model") then ve[model] = { Name=model.Name, Pos=d.Position, Occupant=d.Occupant and d.Occupant.Name or nil } end
            end
        end
        CachedVehicles = ve
        task.wait(1.5)
    end
end)

-- ==========================================
-- LOOT CONTAINERS
-- ==========================================
local LOOT_DEFAULT_TIER = {
    GunLocker=0, WeaponCrate=0, GunCabinet=0, Lockbox=0, Briefcase=0, Wallet=0, Register=0, LoadCrate=0,
    MedicineCabinet=1, Toolbox=1, Locker=1, Crate=1, Fridge=1, Trunk=1, Cooler=1, SupplyCrate=1, MedFridge=1, Freezer=1, IceChest=1, Cargo=1,
    Dresser=2, KitchenCabinet=2, Shelf=2, Nightstand=2, Counter=2, Cabinet=2, Dumpster=2, Drawers=2, FilingCabinet=2, FileCabinet=2, Desk=2, Cupboard=2, CardCatalog=2, Workbench=2, LabCabinet=2, Bookcase=2, CoffeeCounter=2, Paper=2,
    CodeFragment=3, RedPaper=3, RecordPlayer=3,
}
local TIER_COLOR = { [0]=Color3.fromRGB(255,80,80), [1]=Color3.fromRGB(255,200,60), [2]=Color3.fromRGB(240,220,100), [3]=Color3.fromRGB(180,180,180) }
local LootPrompts, LootContainers = {}, {}

local function registerContainer(name)
    if LOOT_DEFAULT_TIER[name] == nil then return end
    if not LootContainers[name] then LootContainers[name] = true; if Config.Loot.PerContainer[name] == nil then Config.Loot.PerContainer[name] = true end end
end
local function containerVisible(name)
    local t = LOOT_DEFAULT_TIER[name]
    if t == nil then return false end
    if not Config.Loot.TierEnabled[t] then return false end
    return Config.Loot.PerContainer[name] ~= false
end
local function resolveContainer(inst)
    local node = inst
    for _ = 1, 4 do if not node then break end; if LOOT_DEFAULT_TIER[node.Name] then return node.Name, LOOT_DEFAULT_TIER[node.Name] end; node = node.Parent end
end
local function registerPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    local part = prompt.Parent
    if not part or not part:IsA("BasePart") then return end
    local name, tier = resolveContainer(part)
    if not name then return end
    registerContainer(name)
    LootPrompts[prompt] = { Tier=tier, Name=name, Root=part }
end
task.spawn(function()
    local count = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if not alive then return end
        if d:IsA("ProximityPrompt") then registerPrompt(d) end
        count = count + 1; if count % 200 == 0 then task.wait() end
    end
    track(Workspace.DescendantAdded:Connect(function(d) if d:IsA("ProximityPrompt") then registerPrompt(d) end end))
    while alive do task.wait(3); for p in pairs(LootPrompts) do if not p.Parent or not p:IsDescendantOf(Workspace) then LootPrompts[p] = nil end end end
end)

-- ==========================================
-- AIMBOT + TRIGGERBOT
-- ==========================================
local aimHeld, aimTarget = false, nil
local lastFire = 0

local function isAimInput(input)
    local b = Config.Aim.Key
    if typeof(b) ~= "EnumItem" then return false end
    if b.EnumType == Enum.KeyCode then return input.KeyCode == b end
    return input.UserInputType == b
end

local function isVisible(targetChar)
    if not Config.Aim.WallCheck then return true end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { LocalPlayer.Character, targetChar }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local hit = Workspace:Raycast(Camera.CFrame.Position, (targetChar.Head.Position - Camera.CFrame.Position), rp)
    return hit == nil
end

local function pickTarget()
    if aimTarget and aimTarget.Player.Character == aimTarget.Root.Parent and aimTarget.Hum.Health > 0 then
        if Config.Aim.TeamCheck and isTeammate(aimTarget.Player) then aimTarget = nil; return nil end
        if isVisible(aimTarget.Root.Parent) then return aimTarget end
    end
    aimTarget = nil
    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, Config.Aim.FOV
    for _, d in pairs(CachedPlayers) do
        if d.Hum.Health > 0 and isVisible(d.Root.Parent) then
            if not (Config.Aim.TeamCheck and isTeammate(d.Player)) then
                local part = (Config.Aim.Bone == "head" and d.Head) or (Config.Aim.Bone == "chest" and d.Root) or d.Root
                if part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if sp.Z > 0 and on then
                        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if dist < bestD then bestD = dist; best = d end
                    end
                end
            end
        end
    end
    aimTarget = best
    return best
end

local function aimPointOf(t)
    local part = (Config.Aim.Bone == "head" and t.Head) or (Config.Aim.Bone == "chest" and t.Root) or t.Head or t.Root
    local pos = part.Position
    if Config.Aim.Prediction > 0 then
        local v = t.Root.AssemblyLinearVelocity
        if v.Magnitude > 0.5 then pos = pos + v * Config.Aim.Prediction end
    end
    return pos
end

track(UserInputService.InputBegan:Connect(function(i, gpe) if not gpe and isAimInput(i) then aimHeld = true; aimTarget = nil end end))
track(UserInputService.InputEnded:Connect(function(i) if isAimInput(i) then aimHeld = false; aimTarget = nil end end))

RunService:BindToRenderStep("cobble_aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not Config.Aim.Enabled then return end
    if not (Config.Aim.AlwaysOn or aimHeld) then return end
    
    local t = pickTarget()
    if not t then return end
    
    local targetPos = aimPointOf(t)
    local oldCFrame = Camera.CFrame

    if Config.Aim.MagicSnap then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    elseif Config.Aim.Visual then
        local want = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        local s = math.clamp(Config.Aim.Smooth, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(want, 1 - (1 - s) ^ (dt * 60))
    end

    if Config.Aim.AutoFire and (tick() - lastFire > Config.Aim.FireDelay) then
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            lastFire = tick()
            pcall(function() tool:Activate() end)
            if mouse1click then pcall(mouse1click) end
        end
    end

    if Config.Aim.MagicSnap then
        Camera.CFrame = oldCFrame
    end
end)

-- Silent Aim Hook Fallback
task.spawn(function()
    if not LookRemote or not (getrawmetatable and setreadonly) then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if m == "FireServer" and self == LookRemote and alive and Config.Aim.Enabled and (Config.Aim.AlwaysOn or aimHeld) then
            local t = pickTarget()
            if t then
                local dir = aimPointOf(t) - Camera.CFrame.Position
                if dir.Magnitude > 0.05 then
                    dir = dir.Unit
                    local yaw   = math.atan2(-dir.X, -dir.Z)
                    local pitch = math.asin(math.clamp(dir.Y, -1, 1))
                    return old(self, yaw, pitch)
                end
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ==========================================
-- ESP DRAWINGS
-- ==========================================
local ESP_KEYS = {"box","hbg","hfill","dot","name","dist","weapon","hb","hbf"}
local espData = {}

local function newObj()
    local o = {
        box=Drawing.new("Square"), hbg=Drawing.new("Square"), hfill=Drawing.new("Square"),
        dot=Drawing.new("Circle"), name=Drawing.new("Text"), dist=Drawing.new("Text"),
        weapon=Drawing.new("Text"), hb=Drawing.new("Square"), hbf=Drawing.new("Square"),
    }
    o.box.Thickness=1; o.box.Filled=false; o.box.Color=Color3.fromRGB(90,140,255)
    o.hbg.Filled=true; o.hbg.Color=Color3.new(0,0,0); o.hbg.Transparency=0.45
    o.hfill.Filled=true
    o.dot.Filled=true; o.dot.Radius=3; o.dot.NumSides=12; o.dot.Color=Color3.new(1,1,1)
    o.name.Center=true; o.name.Outline=true; o.name.Size=13; o.name.Color=Color3.new(1,1,1)
    o.dist.Center=true; o.dist.Outline=true; o.dist.Size=12; o.dist.Color=Color3.fromRGB(200,205,220)
    o.weapon.Center=true; o.weapon.Outline=true; o.weapon.Size=12; o.weapon.Color=Color3.fromRGB(255,200,60)
    o.hb.Filled=true; o.hb.Color=Color3.new(0,0,0); o.hb.Transparency=0.45
    o.hbf.Filled=true
    return o
end
local function destroyObj(o)
    for _, k in ipairs(ESP_KEYS) do if o[k] then pcall(function() o[k]:Remove() end) end end
    if o.highlight then pcall(function() o.highlight:Destroy() end) end
end
local function hideObj(o) for _, k in ipairs(ESP_KEYS) do o[k].Visible = false end end

local lootDraw, bagDraw, bodyDraw, wfDraw, watcherDraw, extractDraw, vehicleDraw = {}, {}, {}, {}, {}, {}, {}
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1; fovCircle.Filled = false; fovCircle.NumSides = 60; fovCircle.Color = Color3.fromRGB(90,140,255); fovCircle.Transparency = 0.55; fovCircle.Visible = false

local hudBg, hudHpBg, hudHpFill, hudHpText, hudWeapon, hudExtract = Drawing.new("Square"), Drawing.new("Square"), Drawing.new("Square"), Drawing.new("Text"), Drawing.new("Text"), Drawing.new("Text")
hudBg.Filled=true; hudBg.Color=Color3.new(0,0,0); hudBg.Transparency=0.5
hudHpBg.Filled=true; hudHpBg.Color=Color3.new(0.1,0.1,0.1); hudHpBg.Transparency=0.3
hudHpFill.Filled=true
hudHpText.Outline=true; hudHpText.Size=14; hudHpText.Color=Color3.new(1,1,1)
hudWeapon.Outline=true; hudWeapon.Size=14; hudWeapon.Color=Color3.fromRGB(255,200,60)
hudExtract.Outline=true; hudExtract.Size=13; hudExtract.Color=Color3.fromRGB(120,255,140)

local function updatePlayerESP()
    local active = {}
    if Config.ESP.Enabled then
        local camRight = Camera.CFrame.RightVector
        for char, data in pairs(CachedPlayers) do
            if data.Hum.Health > 0 then
                active[char] = true
                local o = espData[char] or newObj(); espData[char] = o
                local rp = data.Root.Position
                local topS, topOn = Camera:WorldToViewportPoint(rp + Vector3.new(0, data.SizeY*0.5, 0))
                local botS, botOn = Camera:WorldToViewportPoint(rp - Vector3.new(0, data.SizeY*0.5, 0))
                local rgtS        = Camera:WorldToViewportPoint(rp + camRight * (data.SizeX*0.5 + 0.05))
                if topS.Z>0 and botS.Z>0 and rgtS.Z>0 and topOn and botOn then
                    local cx = (topS.X + botS.X) * 0.5
                    local h = botS.Y - topS.Y
                    local w = math.abs(rgtS.X - cx) * 2
                    if h > 2 and w > 1 then
                        local bx, by = cx - w*0.5, topS.Y
                        o.box.Position = Vector2.new(bx, by); o.box.Size = Vector2.new(w, h); o.box.Visible = Config.ESP.Box
                        local frac = math.clamp(data.Hum.Health / math.max(data.Hum.MaxHealth,1), 0, 1)
                        local hx = bx - 6
                        o.hbg.Position = Vector2.new(hx, by); o.hbg.Size = Vector2.new(3, h); o.hbg.Visible = true
                        o.hfill.Position = Vector2.new(hx, by + h*(1-frac)); o.hfill.Size = Vector2.new(3, math.max(h*frac, 1))
                        o.hfill.Color = Color3.fromRGB(255*(1-frac), 255*frac, 60); o.hfill.Visible = true
                        o.dot.Position = Vector2.new(cx, by+8); o.dot.Visible = true
                        
                        local color = Config.Aim.TeamCheck and isTeammate(data.Player) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
                        o.box.Color = color; o.name.Color = color; o.dist.Color = color
                        
                        o.name.Visible = Config.ESP.Name; o.name.Text = data.Player.Name; o.name.Position = Vector2.new(cx, by-16)
                        local d = math.floor((Camera.CFrame.Position - rp).Magnitude)
                        o.dist.Visible = Config.ESP.Dist; o.dist.Text = d .. "m"; o.dist.Position = Vector2.new(cx, botS.Y + 4)
                        local tool = char:FindFirstChildOfClass("Tool")
                        if Config.ESP.Weapon and tool then o.weapon.Visible = true; o.weapon.Text = tool.Name; o.weapon.Position = Vector2.new(cx, botS.Y + 18)
                        else o.weapon.Visible = false end
                    else hideObj(o) end
                else hideObj(o) end
                if Config.ESP.Chams then
                    if not o.highlight then
                        local hl = Instance.new("Highlight"); hl.FillColor = Color3.fromRGB(90,140,255); hl.OutlineColor = Color3.new(1,1,1)
                        hl.FillTransparency = 0.55; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = char; o.highlight = hl
                    end
                elseif o.highlight then pcall(function() o.highlight:Destroy() end); o.highlight = nil end
            end
        end
    end
    for char, o in pairs(espData) do if not active[char] then destroyObj(o); espData[char] = nil end end
end

local walkerData = {}
local function updateWalkerESP()
    local active = {}
    if Config.ESP.Walker.Enabled then
        local cfg = Config.ESP.Walker
        for model, data in pairs(CachedWalkers) do
            if data.Hum.Health > 0 then
                active[model] = true
                local o = walkerData[model] or newObj(); walkerData[model] = o
                o.box.Color = data.Color; o.hbf.Color = data.Color; o.dot.Color = data.Color
                local rp = data.Root.Position
                local ok, c, s = pcall(function() return data.Model:GetBoundingBox() end)
                local h = (ok and s) and s.Y or 5
                local topS, topOn = Camera:WorldToViewportPoint(rp + Vector3.new(0, h*0.5, 0))
                local botS, botOn = Camera:WorldToViewportPoint(rp - Vector3.new(0, h*0.5, 0))
                if topS.Z>0 and botS.Z>0 and topOn and botOn then
                    local cx = (topS.X + botS.X) * 0.5; local hh = botS.Y - topS.Y; local w = hh * 0.55
                    if hh > 3 then
                        local bx, by = cx - w*0.5, topS.Y
                        o.box.Position = Vector2.new(bx, by); o.box.Size = Vector2.new(w, hh); o.box.Visible = cfg.Box
                        o.name.Visible = cfg.Name; o.name.Text = data.Name; o.name.Color = data.Color; o.name.Position = Vector2.new(cx, by-16)
                        local d = math.floor((Camera.CFrame.Position - rp).Magnitude)
                        o.dist.Visible = cfg.Dist; o.dist.Text = d .. "m"; o.dist.Position = Vector2.new(cx, botS.Y + 4)
                        if cfg.Health then
                            local frac = math.clamp(data.Hum.Health / math.max(data.Hum.MaxHealth,1), 0, 1); local hx = bx - 6
                            o.hb.Position = Vector2.new(hx, by); o.hb.Size = Vector2.new(3, hh); o.hb.Visible = true
                            o.hbf.Position = Vector2.new(hx, by + hh*(1-frac)); o.hbf.Size = Vector2.new(3, math.max(hh*frac,1)); o.hbf.Visible = true
                        else o.hb.Visible = false; o.hbf.Visible = false end
                        o.dot.Position = Vector2.new(cx, by+8); o.dot.Visible = true
                    else hideObj(o) end
                else hideObj(o) end
            end
        end
    end
    for model, o in pairs(walkerData) do if not active[model] then destroyObj(o); walkerData[model] = nil end end
end

local function updateLoot()
    if not Config.Loot.Enabled then for p, d in pairs(lootDraw) do pcall(function() d:Remove() end) end; lootDraw = {}; return end
    local camPos = Camera.CFrame.Position; local active = {}
    for prompt, info in pairs(LootPrompts) do
        if prompt.Parent and info.Root.Parent and containerVisible(info.Name) then
            local dist = (camPos - info.Root.Position).Magnitude
            if dist <= Config.Loot.MaxDist then
                active[prompt] = true
                local d = lootDraw[prompt]
                if not d then
                    d = Drawing.new("Text"); d.Size = (info.Tier==0) and 14 or ((info.Tier==1) and 13 or 12)
                    d.Center=true; d.Outline=true; d.Color = TIER_COLOR[info.Tier] or Color3.new(1,1,1); lootDraw[prompt] = d
                end
                local sp, on = Camera:WorldToViewportPoint(info.Root.Position)
                if sp.Z>0 and on then
                    d.Text = Config.Loot.Labels and (info.Name .. " [" .. math.floor(dist) .. "m]") or ("[" .. math.floor(dist) .. "m]")
                    d.Position = Vector2.new(sp.X, sp.Y); d.Visible = true
                else d.Visible = false end
            end
        end
    end
    for p, d in pairs(lootDraw) do if not active[p] then pcall(function() d:Remove() end); lootDraw[p] = nil end end
end

local function drawSimpleSet(cache, source, visibleFn, colorFn, textFn, size, maxDist)
    local camPos = Camera.CFrame.Position; local active = {}
    for key, info in pairs(source) do
        if visibleFn(info) then
            local pos = info.Pos; local dist = (camPos - pos).Magnitude
            if dist <= maxDist then
                active[key] = true
                local d = cache[key]
                if not d then d = Drawing.new("Text"); d.Size = size or 12; d.Center = true; d.Outline = true; cache[key] = d end
                d.Color = colorFn(info); local sp, on = Camera:WorldToViewportPoint(pos)
                if sp.Z>0 and on then d.Text = textFn(info, dist); d.Position = Vector2.new(sp.X, sp.Y); d.Visible = true else d.Visible = false end
            end
        end
    end
    for k, d in pairs(cache) do if not active[k] then pcall(function() d:Remove() end); cache[k] = nil end end
end

local EXTRACT_COLOR = Color3.fromRGB(100, 255, 140)
local function updateMisc()
    drawSimpleSet(extractDraw, CachedExtractions, function() return Config.ESP.Extraction.Enabled end, function() return EXTRACT_COLOR end, function(info, d) return "EXIT " .. info.Name .. " [" .. math.floor(d) .. "m]" end, 13, 99999)
    drawSimpleSet(bagDraw, CachedLootBags, function() return Config.ESP.LootBag.Enabled end, function() return Color3.fromRGB(255, 100, 200) end, function(info, d) return "BAG [" .. math.floor(d) .. "m]" end, 12, 200)
    drawSimpleSet(bodyDraw, CachedBodies, function() return Config.ESP.Body.Enabled end, function() return Color3.fromRGB(150, 150, 150) end, function(info) return info.Name end, 11, 120)
    drawSimpleSet(wfDraw, CachedWorldFinds, function() return Config.ESP.WorldFind.Enabled end, function() return Color3.fromRGB(120, 200, 255) end, function(info, d) return info.Name .. " [" .. math.floor(d) .. "m]" end, 12, 200)
    drawSimpleSet(watcherDraw, CachedWatchers, function() return Config.ESP.Watcher.Enabled end, function() return Color3.fromRGB(200, 100, 255) end, function(info) return info.Name end, 11, 300)
    drawSimpleSet(vehicleDraw, CachedVehicles, function() return Config.ESP.Vehicle.Enabled end, function(info) return info.Occupant and Color3.fromRGB(255,80,80) or Color3.fromRGB(120,255,180) end, function(info, d)
        local occ = info.Occupant and (" • " .. info.Occupant) or ""
        return info.Name .. occ .. " [" .. math.floor(d) .. "m]"
    end, 12, 400)
end

local function updateHUD()
    if not Config.HUD.Enabled then hudBg.Visible=false; hudHpBg.Visible=false; hudHpFill.Visible=false; hudHpText.Visible=false; hudWeapon.Visible=false; hudExtract.Visible=false; return end
    local lx, ly = 20, 20
    hudBg.Position = Vector2.new(lx-8, ly-8); hudBg.Size = Vector2.new(240, 82); hudBg.Visible = true
    local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local frac = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
        hudHpBg.Position = Vector2.new(lx, ly); hudHpBg.Size = Vector2.new(200, 16); hudHpBg.Visible = true
        hudHpFill.Position = Vector2.new(lx, ly); hudHpFill.Size = Vector2.new(200*frac, 16); hudHpFill.Color = Color3.fromRGB(255*(1-frac), 255*frac, 60); hudHpFill.Visible = true
        hudHpText.Text = string.format("HP %d / %d", hum.Health, hum.MaxHealth); hudHpText.Position = Vector2.new(lx+4, ly-2); hudHpText.Visible = true
        local tool = char:FindFirstChildOfClass("Tool")
        hudWeapon.Text = tool and ("Arma: " .. tool.Name) or "Arma: desarmado"; hudWeapon.Position = Vector2.new(lx, ly+24); hudWeapon.Visible = true
    end
    local camPos = Camera.CFrame.Position; local best, bestD = nil, math.huge
    for _, info in pairs(CachedExtractions) do local d = (camPos - info.Pos).Magnitude; if d < bestD then bestD = d; best = info end end
    if best then hudExtract.Text = ("Extract: %s [%dm]"):format(best.Name, math.floor(bestD)); hudExtract.Position = Vector2.new(lx, ly+46); hudExtract.Visible = true
    else hudExtract.Visible = false end
end

track(RunService.RenderStepped:Connect(function()
    updatePlayerESP(); updateWalkerESP(); updateLoot(); updateMisc(); updateHUD()
    if Config.Aim.Enabled and Config.Aim.ShowFOV and (Config.Aim.AlwaysOn or aimHeld) then
        fovCircle.Position = Camera.ViewportSize * 0.5; fovCircle.Radius = Config.Aim.FOV; fovCircle.Visible = true
    else fovCircle.Visible = false end
end))

-- ==========================================
-- UTILS
-- ==========================================
local lastPickup = 0
local function tryAutoPickup()
    if not (Config.Util.AutoPickup and LootRemote) then return end
    if tick() - lastPickup < Config.AutoPickupRate then return end
    local char = LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local best, bestD = nil, Config.AutoPickupRadius
    for prompt, info in pairs(LootPrompts) do
        if prompt.Parent and info.Root.Parent then
            local d = (root.Position - info.Root.Position).Magnitude
            if d < bestD then bestD = d; best = info.Root end
        end
    end
    if best then lastPickup = tick(); pcall(function() LootRemote:FireServer("takeAll", best) end) end
end

local lastFB, lastNV, lastBreath = nil, nil, nil
track(RunService.Heartbeat:Connect(function()
    if Config.Util.Fullbright ~= lastFB then lastFB = Config.Util.Fullbright; if lastFB then applyFullbright() else restoreFullbright() end end
    if Config.Util.NightVision ~= lastNV then lastNV = Config.Util.NightVision; if NightVisionRemote then pcall(function() NightVisionRemote:FireServer() end) end end
    if Config.Util.Breath ~= lastBreath then lastBreath = Config.Util.Breath; if BreathRemote then pcall(function() BreathRemote:FireServer(lastBreath) end) end end
    tryAutoPickup()
end))

task.spawn(function()
    while alive do
        if Config.Util.SilentWalk and LocalPlayer.Character then
            for _, d in ipairs(LocalPlayer.Character:GetDescendants()) do
                if d:IsA("Sound") then
                    local n = d.Name:lower()
                    if n:find("step") or n:find("walk") or n:find("foot") then d.Volume = 0; d.Playing = false end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- ACTIONS (INCLUINDO O MOVE ITEM)
-- ==========================================
local stanceSeq = 0
getgenv().Cobble_Stance = function(state) if StanceRemote then stanceSeq = stanceSeq + 1; StanceRemote:FireServer(state and true or false, stanceSeq) end end
getgenv().Cobble_Flashlight = function() local f = R("Flashlight"); if f then f:FireServer() end end
getgenv().Cobble_Arrest = function() local a = RemotesFolder and RemotesFolder:FindFirstChild("Arrest"); if a then a:FireServer("surrender") end end
getgenv().Cobble_Deploy = function() if DeployRemote then DeployRemote:FireServer() end end
getgenv().Cobble_Replay = function(mode) if ReplayRemote then ReplayRemote:FireServer(mode or "start") end end
getgenv().Cobble_Equip = function(name) local g = RemotesFolder and RemotesFolder:FindFirstChild("Gun"); if g then g:FireServer("Equip", name) end end
getgenv().Cobble_MoveItem = function(id, qty) if InvActionRem then InvActionRem:FireServer({ action = "Safe", from = "safe", id = id, qty = qty or 1, to = "backpack" }) end end

getgenv().Cobble_ForcePickup = function()
    if not LootRemote then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local best, bestD = nil, 15
    for prompt, info in pairs(LootPrompts) do
        if prompt.Parent and info.Root.Parent then local d = (root.Position - info.Root.Position).Magnitude; if d < bestD then bestD = d; best = info.Root end end
    end
    if best then pcall(function() LootRemote:FireServer("takeAll", best) end) end
end
getgenv().Cobble_ForceDoor = function()
    if not DoorRemote then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local best, bestD = nil, 20
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Name:lower():find("door") then
            local part = d.Parent; if part and part:IsA("BasePart") then local dist = (part.Position - root.Position).Magnitude; if dist < bestD then bestD = dist; best = part end end
        end
    end
    if best then pcall(function() DoorRemote:FireServer(best, "use") end) end
end
getgenv().Cobble_ForceVault = function() if MoveRemote then MoveRemote:FireServer("vault", Vector3.new(1,0,0), { top = Vector3.new(0,0,0), k = "vault", t = 0.5, a = 0 }) end end
getgenv().Cobble_PaperMap = function(open) if PaperMapRem then PaperMapRem:FireServer(open and "open" or "close", open and "map" or nil) end end
getgenv().Cobble_Downed = function(press) if DownedRemote then DownedRemote:FireServer("press", press and true or false) end end

getgenv().Cobble_Unload = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("cobble_aim") end)
    for _, o in pairs(espData) do destroyObj(o) end
    for _, o in pairs(walkerData) do destroyObj(o) end
    for _, cache in ipairs({lootDraw, bagDraw, bodyDraw, wfDraw, watcherDraw, extractDraw, vehicleDraw}) do for _, d in pairs(cache) do pcall(function() d:Remove() end) end end
    pcall(function() fovCircle:Remove() end)
    for _, d in ipairs({hudBg,hudHpBg,hudHpFill,hudHpText,hudWeapon,hudExtract}) do pcall(function() d:Remove() end) end
    restoreFullbright()
    if getgenv().Cobble_UI_Loaded then getgenv().Cobble_UI_Loaded:Destroy() end
    print("[cobble] HUSH V6.2 Unloaded.")
end
