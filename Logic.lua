-- cobble hills logic (HUSH V3)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

if not Drawing then
    warn("[cobble] executor sem API Drawing — abortando.")
    return
end

-- ==========================================
-- CONFIG (merge com a existente)
-- ==========================================
local defaults = {
    ESP  = { Enabled = true, Box = true, Chams = true, Name = true, Dist = true, MaxDist = 500 },
    Loot = { Enabled = true, MaxDist = 150 },
    Util = { SilentWalk = true, Fullbright = false },
    Aim  = {
        Enabled    = true,
        AlwaysOn   = false,
        Key        = Enum.KeyCode.E,
        FOV        = 120,       -- raio em pixels a partir do centro da tela
        Smooth     = 0.55,      -- 1.0 = snap instantâneo, menor = mais suave
        FireRate   = 1/45,      -- segundos entre FireServer no Look
        ShowFOV    = true,
        InvertYaw  = false,
        InvertPitch= false,
    },
}

local Config = getgenv().CobbleConfig or {}
for section, vals in pairs(defaults) do
    Config[section] = Config[section] or {}
    for k, v in pairs(vals) do
        if Config[section][k] == nil then Config[section][k] = v end
    end
end
getgenv().CobbleConfig = Config

-- ==========================================
-- CONNECTION TABLE (pra unload limpar)
-- ==========================================
local connections = {}
local alive = true
local function track(conn) connections[#connections+1] = conn; return conn end

-- ==========================================
-- FULLBRIGHT (aplica uma vez no toggle)
-- ==========================================
local FB_DEFAULT = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, ExposureCompensation = Lighting.ExposureCompensation,
}
local fbState = nil

local function applyFullbright()
    Lighting.Ambient               = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient        = Color3.new(1, 1, 1)
    Lighting.Brightness            = 3
    Lighting.ClockTime             = 14
    Lighting.FogEnd                = 1e5
    Lighting.ExposureCompensation  = 1
end
local function restoreFullbright()
    for k, v in pairs(FB_DEFAULT) do pcall(function() Lighting[k] = v end) end
end

-- ==========================================
-- PLAYER CACHE (2x/s, com bounding box)
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
                        local ok, cf, size = pcall(function()
                            local c, s = char:GetBoundingBox()
                            return c, s
                        end)
                        local sx, sy = 2, 5
                        if ok and cf and size then sx, sy = size.X, size.Y end
                        temp[char] = {
                            Player = plr, Hum = hum, Root = root,
                            Head   = char:FindFirstChild("Head"),
                            SizeX  = sx, SizeY = sy,
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
-- LOOT CACHE (scan único + DescendantAdded)
-- ==========================================
local LootPrompts = {}
local LOOT_KEYWORDS = {
    "gun","key","med","bandage","flash","ammo","weapon","knife","battery",
    "health","armor","vest","tool","radio","map","food","water",
    "pistol","rifle","shotgun","smg","mag",
}

local function matchLoot(name)
    local l = name:lower()
    for _, kw in ipairs(LOOT_KEYWORDS) do
        if l:find(kw, 1, true) then return true end
    end
    return false
end

local function resolveLootName(inst)
    local node = inst
    for _ = 1, 4 do
        if not node then break end
        local n = node.Name
        if n ~= "" and n ~= "Handle" and n ~= "Part" and n ~= "Mesh" and not n:match("^Part%d*$") then
            return n
        end
        node = node.Parent
    end
    return inst.Name
end

local function registerPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    local part = prompt.Parent
    if not part or not part:IsA("BasePart") then return end
    local nm = resolveLootName(part)
    if not matchLoot(nm) then return end
    LootPrompts[prompt] = { Name = nm, Root = part }
end

task.spawn(function()
    -- scan inicial cedendo frame a cada 200 nodes
    local count = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if not alive then return end
        if d:IsA("ProximityPrompt") then registerPrompt(d) end
        count = count + 1
        if count % 200 == 0 then task.wait() end
    end
    -- hook pra prompts novos
    track(Workspace.DescendantAdded:Connect(function(d)
        if d:IsA("ProximityPrompt") then registerPrompt(d) end
    end))
    -- prune: prompts destruídos saem do cache
    while alive do
        task.wait(3)
        for p in pairs(LootPrompts) do
            if not p.Parent or not p:IsDescendantOf(Workspace) then
                LootPrompts[p] = nil
            end
        end
    end
end)

-- ==========================================
-- LOOK REMOTE
-- ==========================================
local LookRemote
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    if remotes then
        LookRemote = remotes:WaitForChild("Look", 15)
    end
    if not LookRemote then warn("[cobble] Look remote não encontrado.") end
end)

-- ==========================================
-- SILENT AIM (Heartbeat)
-- ==========================================
local aimHeld  = false
local hasAim   = false
local curYaw, curPitch = 0, 0
local fireAcc  = 0
local swAcc    = 0
local lastFB   = nil

local function getAimTarget()
    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, Config.Aim.FOV
    for _, data in pairs(CachedPlayers) do
        if data.Hum.Health > 0 then
            local headPos = data.Head and data.Head.Position
                or (data.Root.Position + Vector3.new(0, data.SizeY * 0.4, 0))
            local sp, onScreen = Camera:WorldToViewportPoint(headPos)
            if sp.Z > 0 and onScreen then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d < bestD then bestD = d; best = data end
            end
        end
    end
    return best
end

track(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.Aim.Key then aimHeld = true end
end))
track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Config.Aim.Key then aimHeld = false; hasAim = false end
end))

track(RunService.Heartbeat:Connect(function(dt)
    -- fullbright por transição
    if Config.Util.Fullbright ~= lastFB then
        lastFB = Config.Util.Fullbright
        if lastFB then applyFullbright() else restoreFullbright() end
    end

    -- silent walk
    if Config.Util.SilentWalk then
        swAcc = swAcc + dt
        if swAcc >= 0.1 then
            swAcc = 0
            local char = LocalPlayer.Character
            if char then
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("Sound") then
                        local n = d.Name:lower()
                        if n:find("step") or n:find("walk") or n:find("foot") then
                            d.Volume = 0
                            d.Playing = false
                        end
                    end
                end
            end
        end
    end

    -- silent aim
    if not (Config.Aim.Enabled and LookRemote) then hasAim = false; return end
    if not (Config.Aim.AlwaysOn or aimHeld) then hasAim = false; return end

    local target = getAimTarget()
    if not target then hasAim = false; return end

    local camPos = Camera.CFrame.Position
    local aimPos = target.Head and target.Head.Position
        or (target.Root.Position + Vector3.new(0, target.SizeY * 0.35, 0))

    local dir = aimPos - camPos
    if dir.Magnitude < 0.05 then return end
    dir = dir.Unit

    local yaw   = math.atan2(-dir.X, -dir.Z)
    local pitch = math.asin(math.clamp(dir.Y, -1, 1))
    if Config.Aim.InvertYaw   then yaw   = -yaw   end
    if Config.Aim.InvertPitch then pitch = -pitch end

    if not hasAim then
        curYaw, curPitch = yaw, pitch
        hasAim = true
    else
        local t = math.clamp(Config.Aim.Smooth, 0.01, 1)
        local dY = ((yaw - curYaw + math.pi) % (math.pi * 2)) - math.pi
        curYaw   = curYaw + dY * t
        curPitch = curPitch + (pitch - curPitch) * t
    end

    fireAcc = fireAcc + dt
    if fireAcc >= Config.Aim.FireRate then
        fireAcc = 0
        pcall(function() LookRemote:FireServer(curYaw, curPitch) end)
    end
end))

-- ==========================================
-- DRAWINGS: ESP / LOOT / FOV
-- ==========================================
local espData = {}       -- [char] = { box, hbg, hfill, dot, name, dist, highlight }
local lootDraw  = {}     -- [prompt] = Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Filled    = false
fovCircle.NumSides  = 60
fovCircle.Color     = Color3.fromRGB(90, 140, 255)
fovCircle.Transparency = 0.55
fovCircle.Visible   = false

local function createESPObj(char)
    local o = {
        box    = Drawing.new("Square"),
        hbg    = Drawing.new("Square"),
        hfill  = Drawing.new("Square"),
        dot    = Drawing.new("Circle"),
        name   = Drawing.new("Text"),
        dist   = Drawing.new("Text"),
    }
    o.box.Thickness = 1; o.box.Filled = false
    o.box.Color = Color3.fromRGB(90, 140, 255)
    o.hbg.Filled = true; o.hbg.Color = Color3.new(0, 0, 0); o.hbg.Transparency = 0.45
    o.hfill.Filled = true
    o.dot.Filled = true; o.dot.Radius = 3; o.dot.NumSides = 12; o.dot.Color = Color3.new(1, 1, 1)
    o.name.Center = true; o.name.Outline = true; o.name.Size = 13; o.name.Color = Color3.new(1, 1, 1)
    o.dist.Center = true; o.dist.Outline = true; o.dist.Size = 12; o.dist.Color = Color3.fromRGB(200, 205, 220)
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
                if not o then o = createESPObj(char); espData[char] = o end

                local rootPos = data.Root.Position
                local halfY   = data.SizeY * 0.5
                local topWorld = rootPos + Vector3.new(0, halfY, 0)
                local botWorld = rootPos - Vector3.new(0, halfY, 0)
                local rgtWorld = rootPos + camRight * (data.SizeX * 0.5 + 0.05)

                local topS, topOn = Camera:WorldToViewportPoint(topWorld)
                local botS, botOn = Camera:WorldToViewportPoint(botWorld)
                local rgtS        = Camera:WorldToViewportPoint(rgtWorld)

                if topS.Z > 0 and botS.Z > 0 and rgtS.Z > 0 and topOn and botOn then
                    local cx   = (topS.X + botS.X) * 0.5
                    local h    = botS.Y - topS.Y
                    local w    = math.abs(rgtS.X - cx) * 2
                    if h > 2 and w > 1 then
                        local bx, by = cx - w * 0.5, topS.Y

                        o.box.Position = Vector2.new(bx, by)
                        o.box.Size     = Vector2.new(w, h)
                        o.box.Visible  = Config.ESP.Box

                        local frac = math.clamp(data.Hum.Health / math.max(data.Hum.MaxHealth, 1), 0, 1)
                        local hx   = bx - 6
                        o.hbg.Position = Vector2.new(hx, by)
                        o.hbg.Size     = Vector2.new(3, h)
                        o.hbg.Visible  = true
                        o.hfill.Position = Vector2.new(hx, by + h * (1 - frac))
                        o.hfill.Size     = Vector2.new(3, math.max(h * frac, 1))
                        o.hfill.Color    = Color3.fromRGB(255 * (1 - frac), 255 * frac, 60)
                        o.hfill.Visible  = true

                        o.dot.Position = Vector2.new(cx, by + 8)
                        o.dot.Visible  = true

                        o.name.Visible  = Config.ESP.Name
                        o.name.Text     = data.Player.Name
                        o.name.Position = Vector2.new(cx, by - 16)

                        local dist = math.floor((Camera.CFrame.Position - rootPos).Magnitude)
                        o.dist.Visible  = Config.ESP.Dist
                        o.dist.Text     = dist .. "m"
                        o.dist.Position = Vector2.new(cx, botS.Y + 4)
                    else
                        o.box.Visible = false; o.hbg.Visible = false; o.hfill.Visible = false
                        o.dot.Visible = false; o.name.Visible = false; o.dist.Visible = false
                    end
                else
                    o.box.Visible = false; o.hbg.Visible = false; o.hfill.Visible = false
                    o.dot.Visible = false; o.name.Visible = false; o.dist.Visible = false
                end

                if Config.ESP.Chams then
                    if not o.highlight then
                        local hl = Instance.new("Highlight")
                        hl.FillColor       = Color3.fromRGB(90, 140, 255)
                        hl.OutlineColor    = Color3.new(1, 1, 1)
                        hl.FillTransparency= 0.55
                        hl.DepthMode       = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent          = char
                        o.highlight = hl
                    end
                elseif o.highlight then
                    pcall(function() o.highlight:Destroy() end)
                    o.highlight = nil
                end
            end
        end
    end

    -- prune quem saiu
    for char, o in pairs(espData) do
        if not active[char] then
            destroyESPObj(o)
            espData[char] = nil
        end
    end
end

local function updateLoot()
    if not Config.Loot.Enabled then
        for p, d in pairs(lootDraw) do pcall(function() d:Remove() end); lootDraw[p] = nil end
        return
    end
    local camPos = Camera.CFrame.Position
    local active = {}
    for prompt, info in pairs(LootPrompts) do
        if prompt.Parent and info.Root.Parent then
            local dist = (camPos - info.Root.Position).Magnitude
            if dist <= Config.Loot.MaxDist then
                active[prompt] = true
                local d = lootDraw[prompt]
                if not d then
                    d = Drawing.new("Text")
                    d.Size = 12; d.Center = true; d.Outline = true
                    d.Color = Color3.fromRGB(255, 215, 0)
                    lootDraw[prompt] = d
                end
                local sp, onScreen = Camera:WorldToViewportPoint(info.Root.Position)
                if sp.Z > 0 and onScreen then
                    d.Text     = info.Name .. " [" .. math.floor(dist) .. "m]"
                    d.Position = Vector2.new(sp.X, sp.Y)
                    d.Visible  = true
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
-- UNLOAD
-- ==========================================
getgenv().Cobble_Unload = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    for _, o in pairs(espData) do destroyESPObj(o) end
    espData = {}
    for _, d in pairs(lootDraw) do pcall(function() d:Remove() end) end
    lootDraw = {}
    LootPrompts = {}
    pcall(function() fovCircle:Remove() end)
    restoreFullbright()
    local char = LocalPlayer.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Sound") then
                local n = d.Name:lower()
                if n:find("step") or n:find("walk") or n:find("foot") then
                    pcall(function() d.Volume = 1 end)
                end
            end
        end
    end
end
