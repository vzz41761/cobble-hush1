-- cobble hills logic (HUSH V14 - IRONCLAD)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)
if getgenv().Cobble_Unload then pcall(getgenv().Cobble_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIG (BLINDADO)
local Config = getgenv().CobbleConfig or {}
if type(Config.Aimbot) ~= "table" then Config.Aimbot = {} end
Config.Aimbot.Enabled = Config.Aimbot.Enabled ~= false
Config.Aimbot.Silent = Config.Aimbot.Silent ~= false
Config.Aimbot.Key = Config.Aimbot.Key or Enum.UserInputType.MouseButton2
Config.Aimbot.FOV = Config.Aimbot.FOV or 120
Config.Aimbot.Smooth = Config.Aimbot.Smooth or 0.35
Config.Aimbot.Prediction = Config.Aimbot.Prediction or 0.15
Config.Aimbot.WallCheck = Config.Aimbot.WallCheck ~= false
Config.Aimbot.PartyCheck = Config.Aimbot.PartyCheck ~= false
Config.Aimbot.CarCabinAim = Config.Aimbot.CarCabinAim ~= false

if type(Config.ESP) ~= "table" then Config.ESP = {} end
Config.ESP.Players = Config.ESP.Players ~= false
Config.ESP.Walkers = Config.ESP.Walkers ~= false
Config.ESP.MaxDist = Config.ESP.MaxDist or 1000

if type(Config.Util) ~= "table" then Config.Util = {} end
Config.Util.Fullbright = Config.Util.Fullbright == true
Config.Util.NoGrass = Config.Util.NoGrass == true
Config.Util.InfStamina = Config.Util.InfStamina == true
Config.Util.NoSpread = Config.Util.NoSpread == true
Config.Util.NoRecoil = Config.Util.NoRecoil == true
getgenv().CobbleConfig = Config

local connections = {}
local alive = true
local function track(c) connections[#connections+1] = c; return c end

local function isTeammate(plr)
    if not plr then return false end
    local myP, theirP = LP:GetAttribute("Party"), plr:GetAttribute("Party")
    if myP and theirP and myP == theirP then return true end
    return LP.Team and plr.Team == LP.Team
end

local CachedPlayers, CachedWalkers = {}, {}
local espFolder = Instance.new("Folder", gethui and gethui() or CoreGui)
espFolder.Name = "CobbleESP_Guis"

local function getTargetPos(t)
    if not t or not t.Root then return nil end
    local pos = (t.Head and t.Head.Position) or t.Root.Position
    if Config.Aimbot.CarCabinAim and t.Hum and t.Hum.SeatPart then 
        pos = t.Hum.SeatPart.Position + Vector3.new(0, 1.5, 0) 
    end
    if Config.Aimbot.Prediction > 0 and t.Root.AssemblyLinearVelocity then
        local v = t.Root.AssemblyLinearVelocity
        if v.Magnitude > 0.5 then pos = pos + (v * Config.Aimbot.Prediction) end
    end
    return pos
end

local function isVisible(targetChar)
    if not Config.Aimbot.WallCheck then return true end
    if not targetChar or not targetChar:FindFirstChild("Head") then return false end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { LP.Character, targetChar }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local hit = Workspace:Raycast(Camera.CFrame.Position, (targetChar.Head.Position - Camera.CFrame.Position), rp)
    return hit == nil
end

task.spawn(function()
    while alive do
        local pTemp, wTemp = {}, {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local head = plr.Character:FindFirstChild("Head")
                if hum and root and head and hum.Health > 0 then
                    pTemp[plr] = { Char=plr.Character, Hum=hum, Root=root, Head=head, Plr=plr }
                end
            end
        end
        CachedPlayers = pTemp

        local monsters = Workspace:FindFirstChild("Monsters")
        if monsters then
            for _, m in ipairs(monsters:GetChildren()) do
                local hum, root = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then wTemp[m] = { Hum=hum, Root=root, Name=m.Name } end
            end
        end
        CachedWalkers = wTemp
        task.wait(0.5)
    end
end)

local aimHeld = false
track(UserInputService.InputBegan:Connect(function(i, gpe) 
    if not gpe and (i.UserInputType == Config.Aimbot.Key) then aimHeld = true end 
end))
track(UserInputService.InputEnded:Connect(function(i) 
    if i.UserInputType == Config.Aimbot.Key then aimHeld = false end 
end))

local function pickTarget()
    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, Config.Aimbot.FOV
    for _, d in pairs(CachedPlayers) do
        if not (Config.Aimbot.PartyCheck and isTeammate(d.Plr)) and isVisible(d.Char) then
            local targetPos = getTargetPos(d)
            if targetPos then
                local sp, on = Camera:WorldToViewportPoint(targetPos)
                if sp.Z > 0 and on and (Vector2.new(sp.X, sp.Y) - center).Magnitude < bestD then
                    bestD = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    best = d
                end
            end
        end
    end
    return best
end

local oldIndex, oldNamecall
local mt = getrawmetatable(game)
local wrap = newcclosure or function(f) return f end
setreadonly(mt, false)
oldIndex = mt.__index
oldNamecall = mt.__namecall

mt.__index = wrap(function(self, key)
    if aimHeld and Config.Aimbot.Enabled and Config.Aimbot.Silent and self == LP:GetMouse() then
        local target = pickTarget()
        if target then
            if key == "Hit" then return CFrame.new(getTargetPos(target)) end
            if key == "Target" then return target.Head end
        end
    end
    return oldIndex(self, key)
end)

mt.__namecall = wrap(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "Raycast" and Config.Util.NoSpread and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
        local target = pickTarget()
        local dir
        if target then
            dir = (getTargetPos(target) - args[1]).Unit
        else
            dir = Camera.CFrame.LookVector
        end
        args[2] = dir * args[2].Magnitude
        return oldNamecall(self, table.unpack(args))
    end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

RunService:BindToRenderStep("cobble_visual", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not Config.Aimbot.Enabled or Config.Aimbot.Silent or not aimHeld then return end
    local target = pickTarget()
    if target then
        local targetPos = getTargetPos(target)
        if targetPos then
            local want = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(want, math.clamp(Config.Aimbot.Smooth, 0.01, 1))
        end
    end
end)

task.spawn(function()
    local Weapons = ReplicatedStorage:WaitForChild("Weapons", 10)
    local GunTuning = Weapons and Weapons:WaitForChild("GunTuning", 10)
    if GunTuning then
        local tuning = require(GunTuning)
        track(RunService.Heartbeat:Connect(function()
            if Config.Util.NoRecoil then pcall(function() tuning.SetRecoil(0) end) end
        end))
    end
end)

track(RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if Config.Util.Fullbright then
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 1e5
        Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1)
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if cc then cc.Brightness = 1; cc.Contrast = 0; cc.Saturation = 0 end
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo then atmo.Density = 0; atmo.Haze = 0; atmo.Glare = 0 end
    end

    if Config.Util.InfStamina and hum then
        pcall(function() hum:SetAttribute("Stamina", 100) end)
        for _, v in ipairs(char:GetDescendants()) do
            if (v:IsA("IntValue") or v:IsA("NumberValue")) and v.Name:lower():find("stamina") then v.Value = 100 end
        end
    end

    if Config.Util.NoGrass then
        Workspace.Terrain.Decoration = false
        local grass = Workspace:FindFirstChild("HushGrass")
        if grass then for _, g in ipairs(grass:GetDescendants()) do if g:IsA("BasePart") then g.Transparency = 1 end end end
    end
end))

local ESP_Objects = {}
local function createESP(name, color, offset)
    local bg = Instance.new("BillboardGui", espFolder)
    bg.Name = "ESP_" .. name
    bg.AlwaysOnTop = true
    bg.Size = UDim2.fromOffset(200, 50)
    bg.StudsOffset = offset or Vector3.new(0, 3.5, 0)
    
    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.fromScale(1, 1)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = color
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.GothamBold
    tl.TextScaled = true
    tl.Text = name
    return bg, tl
end

track(RunService.Heartbeat:Connect(function()
    local camPos = Camera.CFrame.Position
    
    for plr, data in pairs(CachedPlayers) do
        local dist = (camPos - data.Root.Position).Magnitude
        if Config.ESP.Players and dist <= Config.ESP.MaxDist then
            if not ESP_Objects[plr] then
                local color = isTeammate(plr) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,60,60)
                local bg, tl = createESP(plr.Name, color, Vector3.new(0, 3.5, 0))
                bg.Adornee = data.Head
                ESP_Objects[plr] = { bg = bg, tl = tl }
            end
            local obj = ESP_Objects[plr]
            if obj and obj.tl then
                obj.tl.Text = string.format("%s [%dm]\nHP: %d", plr.Name, math.floor(dist), math.floor(data.Hum.Health))
            end
        elseif ESP_Objects[plr] then
            pcall(function() ESP_Objects[plr].bg:Destroy() end)
            ESP_Objects[plr] = nil
        end
    end

    for m, data in pairs(CachedWalkers) do
        local dist = (camPos - data.Root.Position).Magnitude
        if Config.ESP.Walkers and dist <= Config.ESP.MaxDist then
            if not ESP_Objects[m] then
                local bg, tl = createESP(data.Name, Color3.fromRGB(255, 0, 0), Vector3.new(0, 4, 0))
                bg.Adornee = data.Root
                ESP_Objects[m] = { bg = bg, tl = tl }
            end
            local obj = ESP_Objects[m]
            if obj and obj.tl then obj.tl.Text = string.format("👾 %s [%dm]", data.Name, math.floor(dist)) end
        elseif ESP_Objects[m] then
            pcall(function() ESP_Objects[m].bg:Destroy() end)
            ESP_Objects[m] = nil
        end
    end

    for key, obj in pairs(ESP_Objects) do
        if type(key) == "userdata" then
            if not CachedPlayers[key] then pcall(function() obj.bg:Destroy() end); ESP_Objects[key] = nil end
        else
            if not CachedWalkers[key] then pcall(function() obj.bg:Destroy() end); ESP_Objects[key] = nil end
        end
    end
end))

getgenv().Cobble_Unload = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("cobble_visual") end)
    if mt and setreadonly then
        setreadonly(mt, false)
        if oldIndex then mt.__index = oldIndex end
        if oldNamecall then mt.__namecall = oldNamecall end
        setreadonly(mt, true)
    end
    for _, obj in pairs(ESP_Objects) do pcall(function() obj.bg:Destroy() end) end
    pcall(function() espFolder:Destroy() end)
    if getgenv().Cobble_UI_Loaded then getgenv().Cobble_UI_Loaded:Destroy() end
end-- cobble hills logic (HUSH V15 - TRUE NEXHUB ENGINE)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)
if getgenv().Cobble_Unload then pcall(getgenv().Cobble_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LP:GetMouse()

-- CONFIG (Baseado no documento)
local Config = getgenv().CobbleConfig or {}
Config.Aimbot = Config.Aimbot or { Enabled=true, Silent=true, Key=Enum.UserInputType.MouseButton2, FOV=120, Smooth=0.35, Prediction=0.15, WallCheck=true, PartyCheck=true }
Config.ESP = Config.ESP or { Enabled=true, Players=true, Walkers=true, MaxDist=1000 }
Config.Util = Config.Util or { Fullbright=false, NoGrass=false, InfStamina=false, NoSpread=false, NoRecoil=false, AutoHeal=false }
getgenv().CobbleConfig = Config

local connections = {}
local alive = true
local function track(c) connections[#connections+1] = c; return c end

-- ANTI-DETECÇÃO (Wrapper Instance.new pro CoreGui)
local OldInstance = Instance.new
local function safeInstance(class, parent)
    local obj = OldInstance(class)
    if parent then obj.Parent = parent end
    return obj
end

-- ==========================================
-- UPVALUE PATCHING (O SEGREDO DO NO RECOIL/SPREAD)
-- ==========================================
local OriginalUpvalues = {}
task.spawn(function()
    local getupvalues = debug.getupvalues or getupvalue
    local setupvalue = debug.setupvalue or setupvalue
    
    -- Tenta achar o módulo ClientBreath ou Weapon Module
    local Modules = ReplicatedStorage:FindFirstChild("Modules") 
    if Modules then
        local WeaponConfig = Modules:FindFirstChild("WeaponConfig") or Modules:FindFirstChild("Config")
        if WeaponConfig then
            local ok, mod = pcall(require, WeaponConfig)
            if ok and type(mod) == "table" then
                -- Salva originais
                OriginalUpvalues.Recoil = mod.Recoil or 1
                OriginalUpvalues.Spread = mod.Spread or 1
                
                track(RunService.Heartbeat:Connect(function()
                    if Config.Util.NoRecoil then pcall(function() mod.Recoil = 0 end) end
                    if Config.Util.NoSpread then pcall(function() mod.Spread = 0 end) end
                end))
            end
        end
    end
end)

-- ==========================================
-- CACHES
-- ==========================================
local CachedPlayers, CachedWalkers = {}, {}
local espFolder = safeInstance("Folder", gethui and gethui() or CoreGui)
espFolder.Name = "CobbleESP_Guis"

local function isTeammate(plr)
    if not plr then return false end
    local myP, theirP = LP:GetAttribute("Party"), plr:GetAttribute("Party")
    if myP and theirP and myP == theirP then return true end
    return LP.Team and plr.Team == LP.Team
end

local function getTargetPart(targetChar)
    -- A Cadeia de FindFirstChild exata do NexHub
    return targetChar:FindFirstChild("Head") 
        or targetChar:FindFirstChild("UpperTorso") 
        or targetChar:FindFirstChild("Torso")
        or targetChar:FindFirstChild("HumanoidRootPart")
end

local function getTargetPos(t)
    if not t or not t.Root then return nil end
    local pos = (t.Head and t.Head.Position) or t.Root.Position
    if Config.Aimbot.Prediction > 0 then
        local v = t.Root.AssemblyLinearVelocity
        if v.Magnitude > 0.5 then 
            local ping = LP:GetNetworkPing() / 2
            pos = pos + (v * Config.Aimbot.Prediction) + (v * ping)
        end
    end
    return pos
end

task.spawn(function()
    while alive do
        local pTemp, wTemp = {}, {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local part = getTargetPart(plr.Character)
                if hum and root and part and hum.Health > 0 then
                    pTemp[plr] = { Char=plr.Character, Hum=hum, Root=root, Head=part, Plr=plr }
                end
            end
        end
        CachedPlayers = pTemp

        local monsters = Workspace:FindFirstChild("Monsters")
        if monsters then
            for _, m in ipairs(monsters:GetChildren()) do
                local hum, root = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then wTemp[m] = { Hum=hum, Root=root, Name=m.Name } end
            end
        end
        CachedWalkers = wTemp
        task.wait(0.5)
    end
end)

-- ==========================================
-- AIMBOT (HOOK NO MOUSE.HIT/TARGET)
-- ==========================================
local aimHeld = false
track(UserInputService.InputBegan:Connect(function(i, gpe) 
    if not gpe and (i.UserInputType == Config.Aimbot.Key) then aimHeld = true end 
end))
track(UserInputService.InputEnded:Connect(function(i) 
    if i.UserInputType == Config.Aimbot.Key then aimHeld = false end 
end))

local function isVisible(targetChar)
    if not Config.Aimbot.WallCheck then return true end
    local part = getTargetPart(targetChar)
    if not part then return false end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { LP.Character, targetChar }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    return Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position), rp) == nil
end

local function pickTarget()
    local center = Camera.ViewportSize * 0.5
    local best, bestD = nil, Config.Aimbot.FOV
    for _, d in pairs(CachedPlayers) do
        if not (Config.Aimbot.PartyCheck and isTeammate(d.Plr)) and isVisible(d.Char) then
            local targetPos = getTargetPos(d)
            if targetPos then
                local sp, on = Camera:WorldToViewportPoint(targetPos)
                if sp.Z > 0 and on and (Vector2.new(sp.X, sp.Y) - center).Magnitude < bestD then
                    bestD = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    best = d
                end
            end
        end
    end
    return best
end

-- METATABLE HOOK (Silent Aim via Mouse)
local oldIndex, oldNamecall
local mt = getrawmetatable(game)
local wrap = newcclosure or function(f) return f end
setreadonly(mt, false)
oldIndex = mt.__index
oldNamecall = mt.__namecall

mt.__index = wrap(function(self, key)
    if aimHeld and Config.Aimbot.Enabled and Config.Aimbot.Silent and self == Mouse then
        local target = pickTarget()
        if target then
            local targetPos = getTargetPos(target)
            if key == "Hit" then return CFrame.new(targetPos) end
            if key == "Target" then return target.Head end
        end
    end
    return oldIndex(self, key)
end)

-- HOOK NO NAMECALL (Triggerbot)
mt.__namecall = wrap(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Triggerbot do NexHub
    if method == "Raycast" and aimHeld and Config.Aimbot.Enabled then
        local target = pickTarget()
        if target then
            local targetPos = getTargetPos(target)
            local unitDir = (targetPos - Camera.CFrame.Position).Unit
            if Camera.CFrame.LookVector:Dot(unitDir) >= 0.9994 then
                if mouse1click then pcall(mouse1click) end
            end
        end
    end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- ==========================================
-- UTILS
-- ==========================================
track(RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if Config.Util.Fullbright then
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 1e5
        Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1)
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if cc then cc.Brightness = 1; cc.Contrast = 0; cc.Saturation = 0 end
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo then atmo.Density = 0; atmo.Haze = 0; atmo.Glare = 0 end
    end

    if Config.Util.InfStamina and hum then
        pcall(function() hum:SetAttribute("Stamina", 100) end)
    end

    if Config.Util.NoGrass then
        Workspace.Terrain.Decoration = false
        local grass = Workspace:FindFirstChild("HushGrass")
        if grass then for _, g in ipairs(grass:GetDescendants()) do if g:IsA("BasePart") then g.Transparency = 1 end end end
    end
end))

-- ==========================================
-- ESP (HIGHLIGHT + BILLBOARD GUI)
-- ==========================================
local ESP_Objects = {}

track(RunService.Heartbeat:Connect(function()
    local camPos = Camera.CFrame.Position
    
    for plr, data in pairs(CachedPlayers) do
        local dist = (camPos - data.Root.Position).Magnitude
        if Config.ESP.Players and dist <= Config.ESP.MaxDist then
            if not ESP_Objects[plr] then
                local color = isTeammate(plr) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,60,60)
                
                -- Highlight (O segredo visual do NexHub)
                local hl = safeInstance("Highlight", plr.Character)
                hl.FillColor = color
                hl.OutlineColor = Color3.new(1,1,1)
                hl.FillTransparency = 0.5
                
                -- Billboard
                local bg = safeInstance("BillboardGui", espFolder)
                bg.AlwaysOnTop = true
                bg.Size = UDim2.fromOffset(200, 50)
                bg.StudsOffset = Vector3.new(0, 3.5, 0)
                bg.Adornee = data.Head
                
                local tl = safeInstance("TextLabel", bg)
                tl.Size = UDim2.fromScale(1, 1)
                tl.BackgroundTransparency = 1
                tl.TextColor3 = color
                tl.TextStrokeTransparency = 0
                tl.Font = Enum.Font.GothamBold
                tl.TextScaled = true
                
                ESP_Objects[plr] = { hl = hl, bg = bg, tl = tl }
            end
            
            local obj = ESP_Objects[plr]
            obj.tl.Text = string.format("%s [%dm]\nHP: %d", plr.Name, math.floor(dist), math.floor(data.Hum.Health))
        elseif ESP_Objects[plr] then
            pcall(function() ESP_Objects[plr].hl:Destroy() end)
            pcall(function() ESP_Objects[plr].bg:Destroy() end)
            ESP_Objects[plr] = nil
        end
    end

    for m, data in pairs(CachedWalkers) do
        local dist = (camPos - data.Root.Position).Magnitude
        if Config.ESP.Walkers and dist <= Config.ESP.MaxDist then
            if not ESP_Objects[m] then
                local hl = safeInstance("Highlight", m)
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.FillTransparency = 0.5
                
                local bg = safeInstance("BillboardGui", espFolder)
                bg.AlwaysOnTop = true
                bg.Size = UDim2.fromOffset(200, 50)
                bg.StudsOffset = Vector3.new(0, 4, 0)
                bg.Adornee = data.Root
                
                local tl = safeInstance("TextLabel", bg)
                tl.Size = UDim2.fromScale(1, 1)
                tl.BackgroundTransparency = 1
                tl.TextColor3 = Color3.fromRGB(255, 0, 0)
                tl.Font = Enum.Font.GothamBold
                tl.TextScaled = true
                
                ESP_Objects[m] = { hl = hl, bg = bg, tl = tl }
            end
            ESP_Objects[m].tl.Text = string.Format("👾 %s [%dm]", data.Name, math.floor(dist))
        elseif ESP_Objects[m] then
            pcall(function() ESP_Objects[m].hl:Destroy() end)
            pcall(function() ESP_Objects[m].bg:Destroy() end)
            ESP_Objects[m] = nil
        end
    end
end))

-- ==========================================
-- UNLOAD
-- ==========================================
getgenv().Cobble_Unload = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    
    if mt and setreadonly then
        setreadonly(mt, false)
        if oldIndex then mt.__index = oldIndex end
        if oldNamecall then mt.__namecall = oldNamecall end
        setreadonly(mt, true)
    end
    
    -- Restaura Upvalues
    if OriginalUpvalues.Recoil then pcall(function() OriginalUpvalues.Recoil = OriginalUpvalues.Recoil end) end
    
    for _, obj in pairs(ESP_Objects) do
        pcall(function() obj.hl:Destroy() end)
        pcall(function() obj.bg:Destroy() end)
    end
    pcall(function() espFolder:Destroy() end)
    if getgenv().Cobble_UI_Loaded then getgenv().Cobble_UI_Loaded:Destroy() end
    print("[cobble] V15 Unloaded.")
end
