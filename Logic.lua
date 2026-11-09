-- cobble hills logic (HUSH CLEAN REWRITE)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)
if getgenv().Cobble_Unload then pcall(getgenv().Cobble_Unload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local CAM = Workspace.CurrentCamera
local GETHUI = (gethui and gethui()) or CoreGui

--== CONFIG (Exato do script) ==--
local Config = getgenv().CobbleConfig or {}
Config.Aim = Config.Aim or {
    Enabled = false, Key = Enum.UserInputType.MouseButton2, FOV = 180, Smooth = 8,
    AimPart = "Head", Predict = true, PredictScale = 1.0, PingComp = true,
    GravityComp = false, VisibleOnly = true, TeamCheck = true, Trigger = false,
    TriggerDelay = 50, FOVCircle = true,
}
Config.ESP = Config.ESP or {
    Players = {Enabled = false, Names = true, Health = true, Distance = true, Range = 2000, Color = Color3.fromRGB(255, 80, 80)},
    Walkers = {Enabled = true, Names = true, Health = true, Range = 2500, Color = Color3.fromRGB(255, 50, 50)},
    Loot = {Enabled = false, Range = 1500, Color = Color3.fromRGB(255, 200, 60)},
    Extract = {Enabled = true, Range = 2500, Color = Color3.fromRGB(0, 255, 150)},
}
Config.Modules = Config.Modules or {
    NoBreath = false, NoRecoil = false, NoSpread = false, NoCameraShake = false,
}
Config.Misc = Config.Misc or {
    AntiAFK = true, AutoHeal = false, AutoHealAt = 75, HideFromAC = false, PanicKey = Enum.KeyCode.RightShift,
}
getgenv().CobbleConfig = Config

--== RUNTIME STATE ==--
local Runtime = {
    aimActive = false, target = nil, triggerActive = false, lastTrigger = 0,
    velocityCache = setmetatable({}, {__mode = "k"}),
    espHighlights = {}, espBillboards = {},
    rayParams = RaycastParams.new(), ignoreList = {},
    lastFilterRefresh = 0, modulePatches = {},
    fovCircle = nil, connections = {}, unloaded = false,
}
Runtime.rayParams.FilterType = Enum.RaycastFilterType.Exclude
Runtime.rayParams.IgnoreWater = true

if not LP then warn("[Pressure] no LocalPlayer"); return end
if getgenv().HushCheat then pcall(function() getgenv().HushCheat.Unload() end) end

--== FILTROS ==--
local function getIgnoreList()
    local list = {LP.Character}
    for _, child in ipairs(Workspace:GetChildren()) do
        local n = child.Name
        if n == "Monsters" or n == "Town" or n == "Terrain" then
            table.insert(list, child)
        end
    end
    return list
end

local function refreshFilters()
    local now = tick()
    if now - Runtime.lastFilterRefresh < 1.0 then return end
    Runtime.lastFilterRefresh = now
    Runtime.rayParams.FilterDescendantsInstances = getIgnoreList()
end

--== MATH E TARGETING ==--
local function getAimPart(character)
    if not character then return nil end
    if Config.Aim.AimPart == "Head" then return character:FindFirstChild("Head") end
    return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
end

local function worldToScreen(pos)
    local sp, onScreen = CAM:WorldToViewportPoint(pos)
    if not onScreen or sp.Z <= 0 then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function getVelocity(target)
    local cached = Runtime.velocityCache[target]
    local now = tick()
    if not cached then
        Runtime.velocityCache[target] = {pos = target.Position, t = now, vel = Vector3.zero}
        return Vector3.zero
    end
    local dt = now - cached.t
    if dt > 0.005 and dt < 0.3 then
        local inst = (target.Position - cached.pos) / dt
        if inst.Magnitude > 0.5 then
            if cached.vel.Magnitude > 0.5 then cached.vel = inst * 0.7 + cached.vel * 0.3
            else cached.vel = inst end
        end
        cached.pos = target.Position
        cached.t = now
    end
    if now - cached.t > 3 then Runtime.velocityCache[target] = nil end
    return cached.vel
end

local function isTeammate(player)
    if player == LP then return true end
    if LP.Team and player.Team and LP.Team == player.Team then return true end
    return false
end

local function canSee(targetPart)
    if not Config.Aim.VisibleOnly then return true end
    refreshFilters()
    local origin = CAM.CFrame.Position
    local dir = targetPart.Position - origin
    if dir.Magnitude < 0.5 then return true end
    local ray = Workspace:Raycast(origin, dir, Runtime.rayParams)
    if not ray then return true end
    if ray.Instance == targetPart or targetPart:IsDescendantOf(ray.Instance) then return true end
    return false
end

local function pickTarget()
    local center = Vector2.new(CAM.ViewportSize.X / 2, CAM.ViewportSize.Y / 2)
    local best = nil
    local bestScore = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        if Config.Aim.TeamCheck and isTeammate(player) then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = getAimPart(char)
        if not part then continue end
        local screen = worldToScreen(part.Position)
        if not screen then continue end
        local screenDist = (screen - center).Magnitude
        if screenDist > Config.Aim.FOV then continue end
        if not canSee(part) then continue end
        local worldDist = (part.Position - CAM.CFrame.Position).Magnitude
        local score = screenDist * 0.7 + worldDist * 0.003
        if score < bestScore then
            bestScore = score
            best = {player = player, part = part, screen = screen, worldDist = worldDist}
        end
    end
    return best
end

local function predictPosition(targetPart, playerChar)
    local camPos = CAM.CFrame.Position
    local pos = targetPart.Position
    if not Config.Aim.Predict then return pos end

    local dist = (pos - camPos).Magnitude
    local speed = 2000
    local t = dist / speed

    local vel = Vector3.zero
    if playerChar and playerChar.PrimaryPart then vel = getVelocity(playerChar.PrimaryPart) end
    local lead = vel * t * Config.Aim.PredictScale

    local drop = Vector3.zero
    if Config.Aim.GravityComp then
        local g = Workspace.Gravity
        drop = Vector3.new(0, 0.5 * g * t * t, 0)
    end

    if Config.Aim.PingComp then
        local ping = 0
        pcall(function() ping = LP:GetNetworkPing() end)
        lead = lead + vel * (ping * 0.5) * Config.Aim.PredictScale
    end
    return pos + lead + drop
end

local function applyAim(target, dt)
    local camPos = CAM.CFrame.Position
    local aimPos = predictPosition(target.part, target.player.Character)
    local newCF = CFrame.lookAt(camPos, aimPos)
    local alpha = math.clamp(dt * Config.Aim.Smooth * 1.5, 0.02, 0.9)
    CAM.CFrame = CAM.CFrame:Lerp(newCF, alpha)
end

local function doTrigger(target, now)
    if not Config.Aim.Trigger then return end
    if now - Runtime.lastTrigger < Config.Aim.TriggerDelay / 1000 then return end
    local dir = (target.part.Position - CAM.CFrame.Position).Unit
    if CAM.CFrame.LookVector:Dot(dir) >= 0.9994 then
        Runtime.lastTrigger = now
        pcall(function()
            if mouse1click then mouse1click()
            elseif VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.zero)
            end
        end)
    end
end

--== LOOP DO AIMBOT ==--
if Drawing then
    Runtime.fovCircle = Drawing.new("Circle")
    Runtime.fovCircle.Visible = false
    Runtime.fovCircle.Thickness = 1
    Runtime.fovCircle.NumSides = 60
    Runtime.fovCircle.Color = Color3.fromRGB(0, 185, 255)
    Runtime.fovCircle.Transparency = 0.6
    Runtime.fovCircle.Filled = false
end

table.insert(Runtime.connections, RunService.RenderStepped:Connect(function(dt)
    if Runtime.unloaded or not Config.Aim.Enabled then
        if Runtime.fovCircle then Runtime.fovCircle.Visible = false end
        return
    end
    local target = pickTarget()
    Runtime.target = target

    if Runtime.fovCircle then
        Runtime.fovCircle.Visible = Config.Aim.FOVCircle
        Runtime.fovCircle.Radius = Config.Aim.FOV
        local vs = CAM.ViewportSize
        Runtime.fovCircle.Position = Vector2.new(vs.X / 2, vs.Y / 2)
    end

    if not target then return end
    applyAim(target, dt)
    doTrigger(target, tick())
end))

--== ESP LOOP (HUSH MAP) ==--
local function clearESP(instance)
    if Runtime.espHighlights[instance] then pcall(function() Runtime.espHighlights[instance]:Destroy() end); Runtime.espHighlights[instance] = nil end
    if Runtime.espBillboards[instance] then pcall(function() Runtime.espBillboards[instance]:Destroy() end); Runtime.espBillboards[instance] = nil end
end

local function setESP(instance, label, color, distance)
    if not instance or not instance.Parent then return end
    local hl = Runtime.espHighlights[instance]
    if not hl then
        hl = Instance.new("Highlight")
        hl.Adornee = instance; hl.Name = "CobbleESP"; hl.FillTransparency = 0.6; hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = GETHUI
        Runtime.espHighlights[instance] = hl
    end
    hl.FillColor = color; hl.OutlineColor = color

    local bb = Runtime.espBillboards[instance]
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Size = UDim2.fromOffset(180, 44); bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true; bb.Adornee = instance; bb.Parent = GETHUI
        local label_ui = Instance.new("TextLabel")
        label_ui.Size = UDim2.fromScale(1, 1); label_ui.BackgroundTransparency = 1
        label_ui.Font = Enum.Font.GothamBold; label_ui.TextSize = 13; label_ui.TextStrokeTransparency = 0.4
        label_ui.TextColor3 = color; label_ui.TextStrokeColor3 = Color3.new(0,0,0); label_ui.Parent = bb
        Runtime.espBillboards[instance] = bb
    end
    local distanceStr = distance and string.format(" [%dm]", math.floor(distance)) or ""
    bb:FindFirstChildOfClass("TextLabel").Text = tostring(label) .. distanceStr
end

local espTick = 0
table.insert(Runtime.connections, RunService.Heartbeat:Connect(function(dt)
    if Runtime.unloaded then return end
    espTick = espTick + dt
    if espTick < 0.2 then return end
    espTick = 0

    -- Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 and Config.ESP.Players.Enabled then
            local dist = (root.Position - CAM.CFrame.Position).Magnitude
            if dist <= Config.ESP.Players.Range then
                local color = isTeammate(player) and Color3.fromRGB(60, 210, 120) or Config.ESP.Players.Color
                local part = getAimPart(char) or root
                local label = Config.ESP.Players.Health and string.format("HP: %d | %s", math.floor(hum.Health), player.Name) or player.Name
                setESP(part, label, color, Config.ESP.Players.Distance and dist or nil)
            else clearESP(root) end
        elseif root then clearESP(root) end
    end

    -- Walkers (Monsters)
    local monsters = Workspace:FindFirstChild("Monsters")
    if monsters and Config.ESP.Walkers.Enabled then
        for _, m in ipairs(monsters:GetChildren()) do
            local root = m:FindFirstChild("HumanoidRootPart")
            local hum = m:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local dist = (root.Position - CAM.CFrame.Position).Magnitude
                if dist <= Config.ESP.Walkers.Range then
                    local label = Config.ESP.Walkers.Health and string.format("%s [HP: %d]", m.Name, math.floor(hum.Health)) or m.Name
                    setESP(root, label, Config.ESP.Walkers.Color, dist)
                else clearESP(root) end
            end
        end
    end

    -- Extract (Exits)
    local town = Workspace:FindFirstChild("Town")
    local exits = town and town:FindFirstChild("Exits")
    if exits and Config.ESP.Extract.Enabled then
        for _, exit in ipairs(exits:GetChildren()) do
            local ext = exit:FindFirstChild("Extraction")
            if ext then
                local prompt = ext:FindFirstChild("ExtractPrompt", true)
                local part = prompt and prompt.Parent
                if part then
                    local dist = (part.Position - CAM.CFrame.Position).Magnitude
                    if dist <= Config.ESP.Extract.Range then
                        setESP(part, "EXIT: " .. exit.Name, Config.ESP.Extract.Color, dist)
                    else clearESP(part) end
                end
            end
        end
    end
end))

--== MODULE PATCHING ==--
local function patchConfigField(module, fieldName, value)
    if type(module) ~= "table" then return false end
    local found = false
    local function search(t, depth)
        if depth > 4 or type(t) ~= "table" then return end
        for k, v in pairs(t) do
            if k == fieldName then t[k] = value; found = true
            elseif type(v) == "table" then search(v, depth + 1) end
        end
    end
    search(module, 0)
    return found
end

local function applyModulePatches()
    local Weapons = ReplicatedStorage:FindFirstChild("Weapons")
    local GunTuning = Weapons and Weapons:FindFirstChild("GunTuning")
    if GunTuning then
        local ok, tuning = pcall(require, GunTuning)
        if ok and type(tuning) == "table" then
            if Config.Modules.NoRecoil then pcall(function() tuning.SetRecoil(0) end) end
            if Config.Modules.NoSpread then pcall(function() tuning.SetSpread(0) end) end
        end
    end
end

--== MISC ==--
table.insert(Runtime.connections, LP.Idled:Connect(function()
    if Runtime.unloaded or not Config.Misc.AntiAFK then return end
    pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end)
end))

--== PUBLIC API ==--
getgenv().HushCheat = {
    Config = Config, Runtime = Runtime,
    Unload = function()
        Runtime.unloaded = true
        for _, c in ipairs(Runtime.connections) do pcall(function() c:Disconnect() end) end
        for obj, _ in pairs(Runtime.espHighlights) do clearESP(obj) end
        if Runtime.fovCircle then pcall(function() Runtime.fovCircle:Remove() end) end
        if getgenv().Cobble_UI_Loaded then getgenv().Cobble_UI_Loaded:Destroy() end
        getgenv().HushCheat = nil
    end
}
