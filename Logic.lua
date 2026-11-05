-- cobble hills logic (HUSH V3.6)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

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
    ESP  = { Enabled=true, Box=true, Chams=true, Name=true, Dist=true },
    Loot = {
        Enabled=true, MaxDist=150, Labels=true,
        TierEnabled = { [0]=true,[1]=true,[2]=true,[3]=false },
        PerContainer = {},
    },
    Util = { SilentWalk=true, Fullbright=false },
    Aim  = {
        Enabled=true, AlwaysOn=false, Key=Enum.KeyCode.E,
        FOV=120, Smooth=0.55, ShowFOV=true,
        Bone="head", Prediction=0.0,
        InvertYaw=false, InvertPitch=false, Debug=false,
        Silent=false, Visual=true,
    },
}

local Config = getgenv().CobbleConfig or {}
for s, tbl in pairs(defaults) do
    Config[s] = Config[s] or {}
    for k, v in pairs(tbl) do
        if Config[s][k] == nil then Config[s][k] = v end
    end
end
getgenv().CobbleConfig = Config

local connections = {}
local alive = true
local function track(c) connections[#connections+1] = c; return c end

-- ==========================================
-- FULLBRIGHT
-- ==========================================
local FB_DEFAULT = {
    Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
    Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
    FogEnd=Lighting.FogEnd, ExposureCompensation=Lighting.ExposureCompensation,
}
local function applyFullbright()
    Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1)
    Lighting.Brightness = 3; Lighting.ClockTime = 14
    Lighting.FogEnd = 1e5; Lighting.ExposureCompensation = 1
end
local function restoreFullbright()
    for k, v in pairs(FB_DEFAULT) do pcall(function() Lighting[k] = v end) end
end

-- ==========================================
-- PLAYER CACHE
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
                        temp[char] = {
                            Player=plr, Hum=hum, Root=root,
                            Head=char:FindFirstChild("Head"),
                            SizeX=sx, SizeY=sy,
                        }
                    end
                end
            end
        end
        CachedPlayers = temp
        task.wait(0.5)
    end
end)

-- ==========================================
-- LOOT: tiers default + per-container
-- ==========================================
local LOOT_DEFAULT_TIER = {
    GunLocker=0, WeaponCrate=0, GunCabinet=0, Lockbox=0,
    Briefcase=0, Wallet=0, Register=0, LoadCrate=0,

    MedicineCabinet=1, Toolbox=1, Locker=1, Crate=1, Fridge=1,
    Trunk=1, Cooler=1, SupplyCrate=1, MedFridge=1, Freezer=1,
    IceChest=1, Cargo=1,

    Dresser=2, KitchenCabinet=2, Shelf=2, Nightstand=2, Counter=2,
    Cabinet=2, Dumpster=2, Drawers=2, FilingCabinet=2, FileCabinet=2,
    Desk=2, Cupboard=2, CardCatalog=2, Workbench=2, LabCabinet=2,
    Bookcase=2, CoffeeCounter=2, Paper=2,

    CodeFragment=3, RedPaper=3, RecordPlayer=3,
}

local TIER_COLOR = {
    [0]=Color3.fromRGB(255, 80, 80),
    [1]=Color3.fromRGB(255, 200, 60),
    [2]=Color3.fromRGB(240, 220, 100),
    [3]=Color3.fromRGB(180, 180, 180),
}

local LootPrompts    = {}
local LootContainers = {}

local function registerContainer(name)
    if LOOT_DEFAULT_TIER[name] == nil then return end
    if not LootContainers[name] then
        LootContainers[name] = true
        if Config.Loot.PerContainer[name] == nil then
            Config.Loot.PerContainer[name] = true
        end
    end
end

local function containerVisible(name)
    local tier = LOOT_DEFAULT_TIER[name]
    if tier == nil then return false end
    if not Config.Loot.TierEnabled[tier] then return false end
    return Config.Loot.PerContainer[name] ~= false
end

local function resolveContainer(inst)
    local node = inst
    for _ = 1, 4 do
        if not node then break end
        if LOOT_DEFAULT_TIER[node.Name] then
            return node.Name, LOOT_DEFAULT_TIER[node.Name]
        end
        node = node.Parent
    end
    return nil
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
        count = count + 1
        if count % 200 == 0 then task.wait() end
    end
    track(Workspace.DescendantAdded:Connect(function(d)
        if d:IsA("ProximityPrompt") then registerPrompt(d) end
    end))
    while alive do
        task.wait(3)
        for p in pairs(LootPrompts) do
            if not p.Parent or not p:IsDescendantOf(Workspace) then LootPrompts[p] = nil end
        end
    end
end)

getgenv().Cobble_LootContainers = function()
    local list = {}
    for name in pairs(LootContainers) do
        list[#list+1] = { Name=name, Tier=LOOT_DEFAULT_TIER[name] }
    end
    table.sort(list, function(a, b)
        if a.Tier ~= b.Tier then return a.Tier < b.Tier end
        return a.Name < b.Name
    end)
    return list
end

-- ==========================================
-- AIM: target picker + hooks
-- ==========================================
local LookRemote
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    if remotes then LookRemote = remotes:WaitForChild("Look", 15) end
end)

local aimHeld   = false
local aimTarget = nil
local curYaw, curPitch = 0, 0
local hasAim = false

local function pickTarget()
    if aimTarget then
        local stillOk = aimTarget.Player.Character == aimTarget.Root.Parent
            and aimTarget.Hum.Health > 0
        if stillOk then return aimTarget end
        aimTarget = nil
    end
    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, Config.Aim.FOV
    for _, data in pairs(CachedPlayers) do
        if data.Hum.Health > 0 then
            local part = (Config.Aim.Bone == "head" and data.Head)
                      or (Config.Aim.Bone == "chest" and data.Root)
                      or data.Root
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if sp.Z > 0 and onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestD then bestD = d; best = data end
                end
            end
        end
    end
    aimTarget = best
    return best
end

local function aimPointOf(target)
    local part = (Config.Aim.Bone == "head" and target.Head)
              or (Config.Aim.Bone == "chest" and target.Root)
              or (Config.Aim.Bone == "root"  and target.Root)
              or target.Head or target.Root
    local pos = part.Position
    if Config.Aim.Prediction > 0 then
        local v = target.Root.AssemblyLinearVelocity
        if v.Magnitude > 0.5 then
            pos = pos + v * Config.Aim.Prediction
        end
    end
    return pos
end

track(UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Config.Aim.Key then aimHeld = true; aimTarget = nil end
end))
track(UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Config.Aim.Key then aimHeld = false; aimTarget = nil; hasAim = false end
end))

-- visual aim (camera lock), roda DEPOIS do camera controller
RunService:BindToRenderStep("cobble_aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not Config.Aim.Enabled or not Config.Aim.Visual then return end
    if not (Config.Aim.AlwaysOn or aimHeld) then return end
    local target = pickTarget()
    if not target then return end
    local aimPos = aimPointOf(target)
    local camPos = Camera.CFrame.Position
    local want   = CFrame.lookAt(camPos, aimPos)
    local t      = math.clamp(Config.Aim.Smooth, 0.01, 1)
    local alpha  = 1 - (1 - t) ^ (dt * 60)
    Camera.CFrame = Camera.CFrame:Lerp(want, alpha)
end)

-- silent aim (namecall hook) — opcional
task.spawn(function()
    while not LookRemote do task.wait(0.1) end
    if not (getrawmetatable and setreadonly) then
        warn("[cobble] executor sem getrawmetatable — silent aim off")
        return
    end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self == LookRemote and alive then
            if Config.Aim.Enabled and Config.Aim.Silent and (Config.Aim.AlwaysOn or aimHeld) then
                local target = pickTarget()
                if target then
                    local aimPos = aimPointOf(target)
                    local dir = aimPos - Camera.CFrame.Position
                    if dir.Magnitude > 0.05 then
                        dir = dir.Unit
                        local yaw   = math.atan2(-dir.X, -dir.Z)
                        local pitch = math.asin(math.clamp(dir.Y, -1, 1))
                        if Config.Aim.InvertYaw   then yaw   = -yaw   end
                        if Config.Aim.InvertPitch then pitch = -pitch end
                        local t = math.clamp(Config.Aim.Smooth, 0.01, 1)
                        if not hasAim then curYaw, curPitch = yaw, pitch; hasAim = true
                        else
                            local dY = ((yaw - curYaw + math.pi) % (math.pi*2)) - math.pi
                            curYaw   = curYaw + dY * t
                            curPitch = curPitch + (pitch - curPitch) * t
                        end
                        if Config.Aim.Debug then
                            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                            print(("[cobble-aim] silent yaw=%.3f pitch=%.3f target=%s weapon=%s"):format(
                                curYaw, curPitch, target.Player.Name, tool and tool.Name or "none"))
                        end
                        return old(self, curYaw, curPitch)
                    end
                end
                hasAim = false
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
    print("[cobble] silent aim hook instalado")
end)

-- ==========================================
-- ESP + LOOT DRAWINGS
-- ==========================================
local espData  = {}
local lootDraw = {}
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1; fovCircle.Filled = false; fovCircle.NumSides = 60
fovCircle.Color = Color3.fromRGB(90, 140, 255); fovCircle.Transparency = 0.55
fovCircle.Visible = false

local function createESPObj()
    local o = {
        box=Drawing.new("Square"), hbg=Drawing.new("Square"), hfill=Drawing.new("Square"),
        dot=Drawing.new("Circle"), name=Drawing.new("Text"), dist=Drawing.new("Text"),
    }
    o.box.Thickness=1; o.box.Filled=false; o.box.Color=Color3.fromRGB(90, 140, 255)
    o.hbg.Filled=true; o.hbg.Color=Color3.new(0,0,0); o.hbg.Transparency=0.45
    o.hfill.Filled=true
    o.dot.Filled=true; o.dot.Radius=3; o.dot.NumSides=12; o.dot.Color=Color3.new(1,1,1)
    o.name.Center=true; o.name.Outline=true; o.name.Size=13; o.name.Color=Color3.new(1,1,1)
    o.dist.Center=true; o.dist.Outline=true; o.dist.Size=12; o.dist.Color=Color3.fromRGB(200,205,220)
    return o
end

local function destroyESPObj(o)
    for _, k in ipairs({"box","hbg","hfill","dot","name","dist"}) do
        if o[k] then pcall(function() o[k]:Remove() end) end
    end
    if o.highlight then pcall(function() o.highlight:Destroy() end) end
end

local function updateESP()
    local active = {}
    if Config.ESP.Enabled then
        local camRight = Camera.CFrame.RightVector
        for char, data in pairs(CachedPlayers) do
            if data.Hum.Health > 0 then
                active[char] = true
                local o = espData[char]
                if not o then o = createESPObj(); espData[char] = o end

                local rootPos = data.Root.Position
                local topW = rootPos + Vector3.new(0, data.SizeY*0.5, 0)
                local botW = rootPos - Vector3.new(0, data.SizeY*0.5, 0)
                local rgtW = rootPos + camRight * (data.SizeX*0.5 + 0.05)

                local topS, topOn = Camera:WorldToViewportPoint(topW)
                local botS, botOn = Camera:WorldToViewportPoint(botW)
                local rgtS        = Camera:WorldToViewportPoint(rgtW)

                if topS.Z > 0 and botS.Z > 0 and rgtS.Z > 0 and topOn and botOn then
                    local cx = (topS.X + botS.X) * 0.5
                    local h  = botS.Y - topS.Y
                    local w  = math.abs(rgtS.X - cx) * 2
                    if h > 2 and w > 1 then
                        local bx, by = cx - w*0.5, topS.Y
                        o.box.Position = Vector2.new(bx, by)
                        o.box.Size     = Vector2.new(w, h)
                        o.box.Visible  = Config.ESP.Box

                        local frac = math.clamp(data.Hum.Health / math.max(data.Hum.MaxHealth, 1), 0, 1)
                        local hx = bx - 6
                        o.hbg.Position = Vector2.new(hx, by)
                        o.hbg.Size     = Vector2.new(3, h)
                        o.hbg.Visible  = true
                        o.hfill.Position = Vector2.new(hx, by + h*(1-frac))
                        o.hfill.Size     = Vector2.new(3, math.max(h*frac, 1))
                        o.hfill.Color    = Color3.fromRGB(255*(1-frac), 255*frac, 60)
                        o.hfill.Visible  = true

                        o.dot.Position = Vector2.new(cx, by + 8); o.dot.Visible = true
                        o.name.Visible = Config.ESP.Name
                        o.name.Text    = data.Player.Name
                        o.name.Position= Vector2.new(cx, by - 16)

                        local dist = math.floor((Camera.CFrame.Position - rootPos).Magnitude)
                        o.dist.Visible = Config.ESP.Dist
                        o.dist.Text    = dist .. "m"
                        o.dist.Position= Vector2.new(cx, botS.Y + 4)
                    else
                        for _, k in ipairs({"box","hbg","hfill","dot","name","dist"}) do o[k].Visible = false end
                    end
                else
                    for _, k in ipairs({"box","hbg","hfill","dot","name","dist"}) do o[k].Visible = false end
                end

                if Config.ESP.Chams then
                    if not o.highlight then
                        local hl = Instance.new("Highlight")
                        hl.FillColor        = Color3.fromRGB(90, 140, 255)
                        hl.OutlineColor     = Color3.new(1,1,1)
                        hl.FillTransparency = 0.55
                        hl.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent           = char
                        o.highlight = hl
                    end
                elseif o.highlight then
                    pcall(function() o.highlight:Destroy() end); o.highlight = nil
                end
            end
        end
    end
    for char, o in pairs(espData) do
        if not active[char] then destroyESPObj(o); espData[char] = nil end
    end
end

local function updateLoot()
    if not Config.Loot.Enabled then
        for p, d in pairs(lootDraw) do pcall(function() d:Remove() end) end
        lootDraw = {}
        return
    end
    local camPos = Camera.CFrame.Position
    local active = {}
    for prompt, info in pairs(LootPrompts) do
        if prompt.Parent and info.Root.Parent and containerVisible(info.Name) then
            local dist = (camPos - info.Root.Position).Magnitude
            if dist <= Config.Loot.MaxDist then
                active[prompt] = true
                local d = lootDraw[prompt]
                if not d then
                    d = Drawing.new("Text")
                    d.Size = (info.Tier == 0) and 14 or ((info.Tier == 1) and 13 or 12)
                    d.Center = true; d.Outline = true
                    d.Color = TIER_COLOR[info.Tier] or Color3.new(1,1,1)
                    lootDraw[prompt] = d
                end
                local sp, onScreen = Camera:WorldToViewportPoint(info.Root.Position)
                if sp.Z > 0 and onScreen then
                    d.Text = Config.Loot.Labels
                        and (info.Name .. " [" .. math.floor(dist) .. "m]")
                        or ("[" .. math.floor(dist) .. "m]")
                    d.Position = Vector2.new(sp.X, sp.Y)
                    d.Visible = true
                else
                    d.Visible = false
                end
            end
        end
    end
    for p, d in pairs(lootDraw) do
        if not active[p] then pcall(function() d:Remove() end); lootDraw[p] = nil end
    end
end

track(RunService.RenderStepped:Connect(function()
    updateESP()
    updateLoot()
    if Config.Aim.Enabled and Config.Aim.ShowFOV and (Config.Aim.AlwaysOn or aimHeld) then
        fovCircle.Position = Camera.ViewportSize * 0.5
        fovCircle.Radius   = Config.Aim.FOV
        fovCircle.Visible  = true
    else
        fovCircle.Visible = false
    end
end))

-- ==========================================
-- SILENT WALK + FULLBRIGHT LOOP
-- ==========================================
task.spawn(function()
    while alive do
        if Config.Util.SilentWalk and LocalPlayer.Character then
            for _, d in ipairs(LocalPlayer.Character:GetDescendants()) do
                if d:IsA("Sound") then
                    local n = d.Name:lower()
                    if n:find("step") or n:find("walk") or n:find("foot") then
                        d.Volume = 0; d.Playing = false
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

local lastFB = nil
track(RunService.Heartbeat:Connect(function()
    if Config.Util.Fullbright ~= lastFB then
        lastFB = Config.Util.Fullbright
        if lastFB then applyFullbright() else restoreFullbright() end
    end
end))

-- ==========================================
-- UNLOAD
-- ==========================================
getgenv().Cobble_Unload = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    pcall(function() RunService:UnbindFromRenderStep("cobble_aim") end)
    for _, o in pairs(espData) do destroyESPObj(o) end
    espData = {}
    for _, d in pairs(lootDraw) do pcall(function() d:Remove() end) end
    lootDraw = {}
    LootPrompts = {}
    pcall(function() fovCircle:Remove() end)
    restoreFullbright()
end
