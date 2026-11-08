-- cobble hills logic (HUSH V12 - EXACT NEXHUB CLONE)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)
if getgenv().Cobble_Unload then pcall(getgenv().Cobble_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not Drawing then warn("[cobble] Sem Drawing API"); return end

-- ==========================================
-- CONFIGURAÇÃO EXATA (Baseada nas chaves do NexHub)
-- ==========================================
local Config = getgenv().CobbleConfig or {}

-- Aimbot
Config.Aimbot = Config.Aimbot or {
    Enabled = false, Silent = false, AlwaysOn = false,
    FOV = 180, Smooth = 8, SmoothMode = "Linear", -- Linear, Exponential, Instant
    WallCheck = true, PartyCheck = true, AimDowned = false, CarCabinAim = true,
    IgnoreNewRaiders = true, TargetPart = "Head", MaxDist = 1000,
    Prediction = 1.0, PingComp = true
}

-- ESP - Categorizado exatamente como no código dele
Config.ESP = Config.ESP or {
    Players = { Enabled = false, Name = true, Health = true, Distance = true, Weapon = true, PartyCheck = true, HighlightParty = true, HideTeammates = false, MaxDist = 2000 },
    LootBags = { Enabled = false, Name = true, Distance = true, MaxDist = 1500, MaxCount = 50 },
    Airdrops = { Enabled = false, Name = true, Distance = true, HideOpened = true, MaxDist = 1500 },
    Containers = { Enabled = false, Name = true, Distance = true, HideOpened = true, MaxDist = 2500 },
    Safes = { Enabled = false, Name = true, Distance = true, HideOpened = true, MaxDist = 2500 },
    Items = { Enabled = false, Name = true, Distance = true, Types = {"all"}, MaxDist = 1000 },
    Events = { Enabled = false, FragCrates = false, HeliCrash = true, MaxDist = 3500 },
    Walkers = { Enabled = true, Name = true, Health = true, Distance = true }
}

-- Utils
Config.Util = Config.Util or {
    Fullbright = false, InfStamina = false, AutoHoldBreath = false,
    AutoHeal = false, HealPriority = "Medkit", HealThreshold = 75,
    NoRecoil = false, NoSpread = false, InstaInteract = false,
    AutoHijack = false, CombatBreath = false, ACBypass = false
}

getgenv().CobbleConfig = Config

local connections = {}
local alive = true
local function track(c) connections[#connections+1] = c; return c end

-- ==========================================
-- FUNÇÕES DE CHECAGEM
-- ==========================================
local function isTeammate(plr)
    if not plr then return false end
    -- Party check
    local myParty = LP:GetAttribute("Party")
    local theirParty = plr:GetAttribute("Party")
    if myParty and theirParty and myParty == theirParty then return true end
    -- Team check (fallback)
    if LP.Team and plr.Team == LP.Team then return true end
    if LP.TeamColor and plr.TeamColor == LP.TeamColor then return true end
    return false
end

local function isNewRaider(plr)
    return plr.AccountAge < 15 or (plr:GetAttribute("NewRaider") == true)
end

local function isDowned(plr)
    return plr:GetAttribute("Downed") == true or plr:GetAttribute("IsDowned") == true
end

-- ==========================================
-- MODS E BYPASS
-- ==========================================
-- AC Bypass (j() do NexHub)
task.spawn(function()
    local getupvalues, setupvalue = debug.getupvalues, debug.setupvalue
    local filtergc = getgenv().filtergc or _G.filtergc
    if not (getupvalues and setupvalue and filtergc) then return end
    
    local ok, funcs = pcall(filtergc, "function", {Constants = {"FireServer", "bor", "clock"}}, false)
    if ok and type(funcs) == "table" then
        for _, fn in ipairs(funcs) do
            local src = debug.info(fn, "s")
            if type(src) == "string" and src:sub(-9) == ".ClientAC" then
                local upvals = getupvalues(fn)
                local teleportTable = upvals[4]
                local target = upvals[1]
                if type(target) == "table" and type(teleportTable) == "table" and rawget(target, "Teleporte") == 1 then
                    for k in pairs(target) do teleportTable[k] = math.huge end
                    print("[cobble] AC Bypass ativado.")
                end
            end
        end
    end
end)

-- No Recoil / No Spread (GunTuning)
task.spawn(function()
    local Weapons = ReplicatedStorage:FindFirstChild("Weapons")
    local GunTuning = Weapons and Weapons:FindFirstChild("GunTuning")
    if not GunTuning then return end
    
    local ok, tuning = pcall(require, GunTuning)
    if not ok or not tuning then return end
    
    track(RunService.Heartbeat:Connect(function()
        if Config.Util.NoRecoil and tuning.SetRecoil then pcall(function() tuning.SetRecoil(0) end) end
        if Config.Util.NoSpread and tuning.SetSpread then pcall(function() tuning.SetSpread(0) end) end
    end))
end)

-- ==========================================
-- CACHE DE ENTIDADES E LOOT (A CHAVE DO ESP)
-- ==========================================
local Cached = {
    Players = {},
    Walkers = {},
    Bags = {},
    Airdrops = {},
    Containers = {},
    Safes = {},
    Items = {},
    Events = {}
}

task.spawn(function()
    while alive do
        local pTemp, wTemp = {}, {}
        local bagTemp, airTemp, contTemp, safeTemp, itemTemp, eventTemp = {}, {}, {}, {}, {}, {}
        
        -- Players
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local head = plr.Character:FindFirstChild("Head")
                if hum and root and head then
                    if hum.Health > 0 or isDowned(plr) then
                        pTemp[plr] = {
                            Char=plr.Character, Hum=hum, Root=root, Head=head,
                            Plr=plr, Downed=isDowned(plr), NewRaider=isNewRaider(plr)
                        }
                    end
                end
            end
        end
        Cached.Players = pTemp
        
        -- Walkers
        local monsters = Workspace:FindFirstChild("Monsters")
        if monsters then
            for _, m in ipairs(monsters:GetChildren()) do
                local hum, root = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    wTemp[m] = { Hum=hum, Root=root, Name=m.Name }
                end
            end
        end
        Cached.Walkers = wTemp
        
        -- LOOT (A Chave: Só adiciona se o Prompt estiver Enabled)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parent = obj.Parent
                local part = parent
                if part and part:IsA("Model") then part = part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart", true) end
                if part and part:IsA("BasePart") then
                    local name = parent.Name:lower()
                    local action = obj.ActionText:lower()
                    
                    if name:find("lootbag") or name:find("bag") then
                        bagTemp[obj] = { Part=part, Name=parent.Name, Dist=0 }
                    elseif name:find("airdrop") then
                        airTemp[obj] = { Part=part, Name="AirDrop", Dist=0 }
                    elseif name:find("crate") or name:find("container") or name:find("weaponcrate") then
                        contTemp[obj] = { Part=part, Name=parent.Name, Dist=0 }
                    elseif name:find("safe") or name:find("vault") then
                        safeTemp[obj] = { Part=part, Name=parent.Name, Dist=0 }
                    elseif action:find("pickup") or action:find("take") or name:find("item") then
                        itemTemp[obj] = { Part=part, Name=parent.Name, Dist=0 }
                    end
                end
            end
        end
        Cached.Bags = bagTemp
        Cached.Airdrops = airTemp
        Cached.Containers = contTemp
        Cached.Safes = safeTemp
        Cached.Items = itemTemp
        
        -- Events (Frag Crates, Heli Crash)
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name:find("Frag") or obj.Name:find("Crash") or obj.Name:find("Heli") then
                local part = obj:FindFirstChildWhichIsA("BasePart", true)
                if part then eventTemp[obj] = { Part=part, Name=obj.Name } end
            end
        end
        Cached.Events = eventTemp
        
        task.wait(1.5) -- Otimização
    end
end)

-- ==========================================
-- AIMBOT E TRIGGERBOT (COM PING COMP E CAR CABIN)
-- ==========================================
local aimHeld, aimTarget = false, nil

local function isVisible(targetChar)
    if not Config.Aimbot.WallCheck then return true end
    local head = targetChar:FindFirstChild("Head")
    if not head then return false end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { LP.Character, targetChar }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    return Workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position), rp) == nil
end

local function getPredictionPosition(target, dist)
    local pos = target.Head.Position
    
    -- Car Cabin Aim
    if Config.Aimbot.CarCabinAim and target.Hum.SeatPart then
        pos = target.Hum.SeatPart.Position + Vector3.new(0, 1.5, 0)
    end
    
    -- Prediction
    if Config.Aimbot.Prediction > 0 then
        local v = target.Root.AssemblyLinearVelocity
        if v.Magnitude > 0.5 then
            local vel = v * Config.Aimbot.Prediction
            -- Ping Compensation
            if Config.Aimbot.PingComp then
                local ping = LP:GetNetworkPing() * 1000
                local factor = math.clamp(ping / 100, 0, 2)
                vel = vel * factor
            end
            pos = pos + vel
        end
    end
    return pos
end

local function pickTarget()
    if aimTarget and aimTarget.Plr.Character == aimTarget.Root.Parent and aimTarget.Hum.Health > 0 then
        if Config.Aimbot.PartyCheck and isTeammate(aimTarget.Plr) then aimTarget = nil; return nil end
        if isVisible(aimTarget.Char) then return aimTarget end
    end
    aimTarget = nil
    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, Config.Aimbot.FOV
    
    for _, d in pairs(Cached.Players) do
        -- Filtros
        local skip = false
        if d.Downed and not Config.Aimbot.AimDowned then skip = true end
        if Config.Aimbot.PartyCheck and isTeammate(d.Plr) then skip = true end
        if Config.Aimbot.IgnoreNewRaiders and d.NewRaider then skip = true end
        
        if not skip and isVisible(d.Char) then
            local targetPos = getPredictionPosition(d, (Camera.CFrame.Position - d.Root.Position).Magnitude)
            local sp, on = Camera:WorldToViewportPoint(targetPos)
            if sp.Z > 0 and on then
                local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if dist < bestD then
                    bestD = dist; best = d
                end
            end
        end
    end
    aimTarget = best
    return best
end

track(UserInputService.InputBegan:Connect(function(i, gpe) 
    if not gpe and (i.UserInputType == Enum.UserInputType.MouseButton2 or i.KeyCode == Enum.KeyCode.E) then 
        aimHeld = true; aimTarget = nil 
    end 
end))
track(UserInputService.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton2 or i.KeyCode == Enum.KeyCode.E then 
        aimHeld = false; aimTarget = nil 
    end 
end))

RunService:BindToRenderStep("cobble_aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not Config.Aimbot.Enabled or not (Config.Aimbot.AlwaysOn or aimHeld) then return end
    local t = pickTarget()
    if not t then return end
    
    local targetPos = getPredictionPosition(t, (Camera.CFrame.Position - t.Root.Position).Magnitude)
    local oldCFrame = Camera.CFrame
    
    if Config.Aimbot.Silent then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    end
    
    -- Auto Fire
    if aimHeld then
        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
    end
    
    if Config.Aimbot.Silent then
        Camera.CFrame = oldCFrame
    end
end)

-- ==========================================
-- UTILITÁRIOS (HEAL, STAMINA, BREATH, FULLBRIGHT)
-- ==========================================
local lastHeal = 0
local lastBreath = 0

track(RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    -- Stamina / Breath
    if Config.Util.InfStamina then
        pcall(function() hum:SetAttribute("Stamina", 100) end)
        pcall(function() hum:SetAttribute("Breath", 100) end)
    end
    
    -- Auto Heal
    if Config.Util.AutoHeal and hum.Health < (hum.MaxHealth * (Config.Util.HealThreshold / 100)) and tick() - lastHeal > 1.5 then
        local backpack = LP:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                local n = tool.Name:lower()
                if n:find(Config.Util.HealPriority:lower()) or n:find("med") or n:find("kit") then
                    lastHeal = tick()
                    hum:EquipTool(tool)
                    task.wait(0.2)
                    pcall(function() tool:Activate() end)
                    break
                end
            end
        end
    end
    
    -- Auto Breath
    if Config.Util.AutoHoldBreath and tick() - lastBreath > 1 then
        lastBreath = tick()
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Breath")
        if remote then pcall(function() remote:FireServer(true) end) end
    end
    
    -- Fullbright Forçado
    if Config.Util.Fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.FogEnd = 100000
    end
end))

-- Auto Hijack e Insta Interact
task.spawn(function()
    while alive do
        if Config.Util.AutoHijack or Config.Util.InstaInteract then
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        local part = prompt.Parent
                        if part and part:IsA("BasePart") then
                            local dist = (root.Position - part.Position).Magnitude
                            
                            if Config.Util.InstaInteract then
                                prompt.HoldDuration = 0
                            end
                            
                            if Config.Util.AutoHijack and dist < 15 then
                                local pName = part.Name:lower()
                                if pName:find("car") or pName:find("vehicle") or pName:find("hijack") then
                                    pcall(function() fireproximityprompt(prompt) end)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end)

-- ==========================================
-- ESP DRAWINGS (EXATAMENTE COMO O CLONE)
-- ==========================================
local Draw = { Players = {}, Walkers = {}, Bags = {}, Airdrops = {}, Containers = {}, Safes = {}, Items = {}, Events = {} }
local espAccum = 0

local function drawText(cache, key, pos, text, color, size)
    local d = cache[key]
    if not d then 
        d = Drawing.new("Text")
        d.Center = true
        d.Outline = true
        d.Size = size or 12
        d.Color = color
        cache[key] = d 
    end
    local sp, on = Camera:WorldToViewportPoint(pos)
    if sp.Z > 0 and on then 
        d.Text = text
        d.Position = Vector2.new(sp.X, sp.Y)
        d.Visible = true 
    else 
        d.Visible = false 
    end
end

track(RunService.RenderStepped:Connect(function(dt)
    espAccum = espAccum + dt
    if espAccum < 0.033 then return end -- 30 FPS throttle
    espAccum = 0
    
    local camPos = Camera.CFrame.Position
    local activeP, activeW, activeB, activeA, activeC, activeS, activeI, activeE = {}, {}, {}, {}, {}, {}, {}, {}
    
    -- Players
    if Config.ESP.Players.Enabled then
        for plr, data in pairs(Cached.Players) do
            local dist = (camPos - data.Root.Position).Magnitude
            if dist <= Config.ESP.Players.MaxDist then
                if not (Config.ESP.Players.HideTeammates and isTeammate(plr)) then
                    activeP[plr] = true
                    local o = Draw.Players[plr]
                    if not o then
                        o = { box=Drawing.new("Square"), name=Drawing.new("Text"), dist=Drawing.new("Text") }
                        o.box.Thickness = 1; o.box.Filled = false
                        o.name.Center = true; o.name.Outline = true
                        o.dist.Center = true; o.dist.Outline = true
                        Draw.Players[plr] = o
                    end
                    
                    -- Cores
                    local isParty = isTeammate(plr) and Config.ESP.Players.PartyCheck
                    local color = isParty and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 60, 60)
                    if data.Downed then color = Color3.fromRGB(255, 200, 0) end
                    
                    o.box.Color = color
                    o.name.Color = color
                    o.dist.Color = color
                    
                    local topS, topOn = Camera:WorldToViewportPoint(data.Root.Position + Vector3.new(0, 3, 0))
                    local botS, botOn = Camera:WorldToViewportPoint(data.Root.Position - Vector3.new(0, 3, 0))
                    
                    if topS.Z > 0 and topOn and botOn then
                        local cx = (topS.X + botS.X) * 0.5
                        local h = botS.Y - topS.Y
                        local w = h * 0.6
                        o.box.Position = Vector2.new(cx - w/2, topS.Y)
                        o.box.Size = Vector2.new(w, h)
                        o.box.Visible = true
                        
                        o.name.Text = plr.Name .. (data.Downed and " [DOWN]" or "")
                        o.name.Position = Vector2.new(cx, topS.Y - 16)
                        o.name.Visible = Config.ESP.Players.Name
                        
                        o.dist.Text = math.floor(dist) .. "m"
                        o.dist.Position = Vector2.new(cx, botS.Y + 4)
                        o.dist.Visible = Config.ESP.Players.Distance
                    else
                        o.box.Visible=false; o.name.Visible=false; o.dist.Visible=false
                    end
                end
            end
        end
    end
    for p, o in pairs(Draw.Players) do if not activeP[p] then o.box.Visible=false; o.name.Visible=false; o.dist.Visible=false end end
    
    -- Walkers
    if Config.ESP.Walkers.Enabled then
        for m, data in pairs(Cached.Walkers) do
            local dist = (camPos - data.Root.Position).Magnitude
            if dist < 1500 then
                activeW[m] = true
                drawText(Draw.Walkers, m, data.Root.Position + Vector3.new(0, 3, 0), "👾 " .. data.Name, Color3.fromRGB(255, 0, 0), 13)
            end
        end
    end
    for m, d in pairs(Draw.Walkers) do if not activeW[m] then d.Visible = false end end
    
    -- Loot Bags
    if Config.ESP.LootBags.Enabled then
        local count = 0
        for prompt, data in pairs(Cached.Bags) do
            if count < Config.ESP.LootBags.MaxCount and prompt.Enabled then
                local dist = (camPos - data.Part.Position).Magnitude
                if dist <= Config.ESP.LootBags.MaxDist then
                    activeB[prompt] = true
                    count = count + 1
                    local text = Config.ESP.LootBags.Name and ("🎒 " .. data.Name) or "🎒"
                    if Config.ESP.LootBags.Distance then text = text .. " [" .. math.floor(dist) .. "m]" end
                    drawText(Draw.Bags, prompt, data.Part.Position, text, Color3.fromRGB(255, 100, 200), 12)
                end
            end
        end
    end
    for p, d in pairs(Draw.Bags) do if not activeB[p] then d.Visible = false end end
    
    -- Airdrops
    if Config.ESP.Airdrops.Enabled then
        for prompt, data in pairs(Cached.Airdrops) do
            if not (Config.ESP.Airdrops.HideOpened and not prompt.Enabled) then
                local dist = (camPos - data.Part.Position).Magnitude
                if dist <= Config.ESP.Airdrops.MaxDist then
                    activeA[prompt] = true
                    local text = Config.ESP.Airdrops.Name and "📦 AIRDROP" or "📦"
                    if Config.ESP.Airdrops.Distance then text = text .. " [" .. math.floor(dist) .. "m]" end
                    drawText(Draw.Airdrops, prompt, data.Part.Position, text, Color3.fromRGB(0, 200, 255), 13)
                end
            end
        end
    end
    for p, d in pairs(Draw.Airdrops) do if not activeA[p] then d.Visible = false end end
    
    -- Containers
    if Config.ESP.Containers.Enabled then
        for prompt, data in pairs(Cached.Containers) do
            if not (Config.ESP.Containers.HideOpened and not prompt.Enabled) then
                local dist = (camPos - data.Part.Position).Magnitude
                if dist <= Config.ESP.Containers.MaxDist then
                    activeC[prompt] = true
                    local text = Config.ESP.Containers.Name and data.Name or "📦"
                    if Config.ESP.Containers.Distance then text = text .. " [" .. math.floor(dist) .. "m]" end
                    drawText(Draw.Containers, prompt, data.Part.Position, text, Color3.fromRGB(255, 150, 50), 12)
                end
            end
        end
    end
    for p, d in pairs(Draw.Containers) do if not activeC[p] then d.Visible = false end end
    
    -- Safes
    if Config.ESP.Safes.Enabled then
        for prompt, data in pairs(Cached.Safes) do
            if not (Config.ESP.Safes.HideOpened and not prompt.Enabled) then
                local dist = (camPos - data.Part.Position).Magnitude
                if dist <= Config.ESP.Safes.MaxDist then
                    activeS[prompt] = true
                    local text = Config.ESP.Safes.Name and ("🔐 " .. data.Name) or "🔐"
                    if Config.ESP.Safes.Distance then text = text .. " [" .. math.floor(dist) .. "m]" end
                    drawText(Draw.Safes, prompt, data.Part.Position, text, Color3.fromRGB(255, 200, 50), 12)
                end
            end
        end
    end
    for p, d in pairs(Draw.Safes) do if not activeS[p] then d.Visible = false end end
    
    -- Items
    if Config.ESP.Items.Enabled then
        for prompt, data in pairs(Cached.Items) do
            if prompt.Enabled then
                local dist = (camPos - data.Part.Position).Magnitude
                if dist <= Config.ESP.Items.MaxDist then
                    activeI[prompt] = true
                    local text = Config.ESP.Items.Name and data.Name or "📦"
                    if Config.ESP.Items.Distance then text = text .. " [" .. math.floor(dist) .. "m]" end
                    drawText(Draw.Items, prompt, data.Part.Position, text, Color3.fromRGB(180, 200, 255), 11)
                end
            end
        end
    end
    for p, d in pairs(Draw.Items) do if not activeI[p] then d.Visible = false end end
    
    -- Events (Frag Crates / Heli Crash)
    if Config.ESP.Events.Enabled then
        for obj, data in pairs(Cached.Events) do
            local dist = (camPos - data.Part.Position).Magnitude
            if dist <= Config.ESP.Events.MaxDist then
                activeE[obj] = true
                local text = "🔴 " .. data.Name
                drawText(Draw.Events, obj, data.Part.Position, text, Color3.fromRGB(255, 80, 80), 13)
            end
        end
    end
    for o, d in pairs(Draw.Events) do if not activeE[o] then d.Visible = false end end
end))

getgenv().Cobble_Unload = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    
    for _, cache in pairs(Draw) do
        for _, d in pairs(cache) do
            if type(d) == "table" then
                if d.box then d.box:Remove() end
                if d.name then d.name:Remove() end
                if d.dist then d.dist:Remove() end
            else
                d:Remove()
            end
        end
    end
    
    if getgenv().Cobble_UI_Loaded then getgenv().Cobble_UI_Loaded:Destroy() end
end
