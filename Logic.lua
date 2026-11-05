-- cobble hills logic (HUSH V2 - NO LAG)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

getgenv().CobbleConfig = {
    ESP = { Enabled = true, Box = true, Chams = true, Name = true, Dist = true },
    Loot = { Enabled = true, MaxDist = 150 }, -- Distância do loot reduzida pra 150
    Util = { SilentWalk = true, Fullbright = false }
}
local Config = getgenv().CobbleConfig

-- ==========================================
-- 1. FULLBRIGHT AGRESSIVO
-- ==========================================
task.spawn(function()
    while task.wait(0.1) do
        if Config.Util.Fullbright then
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.OutdoorAmbient = Color3.new(1,1,1)
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 10000
            Lighting.ExposureCompensation = 1
        end
    end
end)

-- ==========================================
-- 2. SILENT WALK
-- ==========================================
task.spawn(function()
    while task.wait(0.1) do
        if not Config.Util.SilentWalk then continue end
        local char = LocalPlayer.Character
        if char then
            local lfoot = char:FindFirstChild("LeftFoot")
            local rfoot = char:FindFirstChild("RightFoot")
            if lfoot and lfoot:FindFirstChild("Footstep") then lfoot.Footstep.Volume = 0; lfoot.Footstep.Playing = false end
            if rfoot and rfoot:FindFirstChild("Footstep") then rfoot.Footstep.Volume = 0; rfoot.Footstep.Playing = false end
        end
    end
end)

-- ==========================================
-- 3. CACHE DE JOGADORES
-- ==========================================
local CachedPlayers = {}
task.spawn(function()
    while task.wait(0.5) do
        local temp = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    temp[plr.Character] = { Player = plr, Hum = hum, Root = hrp }
                end
            end
        end
        CachedPlayers = temp
    end
end)

-- ==========================================
-- 4. CACHE DO LOOT (RODA EM BACKGROUND, SEM LAG)
-- ==========================================
local CachedLoot = {}
task.spawn(function()
    while task.wait(1) do -- Roda 1x por segundo, não 60x
        if not Config.Loot.Enabled then CachedLoot = {}; continue end
        local temp = {}
        local camPos = Camera.CFrame.Position
        
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Parent and v.Parent:IsA("BasePart") then
                local part = v.Parent
                local dist = (camPos - part.Position).Magnitude
                
                if dist <= Config.Loot.MaxDist then
                    local itemName = part.Parent and part.Parent.Name or part.Name
                    local lowerName = itemName:lower()
                    
                    -- FILTRO: Só mostra coisa que presta (Arma, Chave, Remédio, Lanterna)
                    if lowerName:find("gun") or lowerName:find("key") or lowerName:find("med") or lowerName:find("bandage") or lowerName:find("flash") or lowerName:find("ammo") or lowerName:find("weapon") or lowerName:find("knife") or lowerName:find("battery") then
                        temp[part] = { Name = itemName, Root = part }
                    end
                end
            end
        end
        CachedLoot = temp
    end
end)

-- ==========================================
-- 5. RENDERIZAÇÃO (ESP E LOOT)
-- ==========================================
local espObjects, chamsObjects, lootObjects = {}, {}, {}

local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, obj in pairs(espObjects) do for _, d in pairs(obj) do d.Visible = false end end
        return
    end
    local active = {}
    for char, data in pairs(CachedPlayers) do
        active[char] = true
        if not espObjects[char] then
            espObjects[char] = { name = Drawing.new("Text"), dist = Drawing.new("Text") }
            espObjects[char].name.Size = 13; espObjects[char].name.Center = true; espObjects[char].name.Outline = true
            espObjects[char].dist.Size = 12; espObjects[char].dist.Center = true; espObjects[char].dist.Outline = true
        end
        
        if Config.ESP.Chams then
            if not chamsObjects[char] then
                local h = Instance.new("Highlight")
                h.Name = "CobbleChams"; h.FillColor = Color3.fromRGB(255, 50, 50); h.OutlineColor = Color3.new(1,1,1)
                h.FillTransparency = 0.5; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = char
                chamsObjects[char] = h
            end
        end

        local obj = espObjects[char]
        local head = char:FindFirstChild("Head") or data.Root
        local sp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
        
        if sp.Z > 0 then
            obj.name.Visible = Config.ESP.Name; obj.name.Text = data.Player.Name; obj.name.Color = Color3.fromRGB(255, 255, 255); obj.name.Position = Vector2.new(sp.X, sp.Y - 20)
            obj.dist.Visible = Config.ESP.Dist; obj.dist.Text = math.floor((Camera.CFrame.Position - data.Root.Position).Magnitude) .. "m"; obj.dist.Position = Vector2.new(sp.X, sp.Y + 10)
        else
            obj.name.Visible = false; obj.dist.Visible = false
        end
    end
end

local function UpdateLoot()
    if not Config.Loot.Enabled then
        for _, txt in pairs(lootObjects) do txt:Remove() end
        lootObjects = {}
        return
    end
    
    local active = {}
    for part, data in pairs(CachedLoot) do
        active[part] = true
        if not lootObjects[part] then
            local txt = Drawing.new("Text")
            txt.Size = 12; txt.Center = true; txt.Outline = true; txt.Color = Color3.fromRGB(255, 215, 0)
            lootObjects[part] = txt
        end
        
        local sp = Camera:WorldToViewportPoint(data.Root.Position)
        if sp.Z > 0 then
            lootObjects[part].Visible = true
            lootObjects[part].Text = "[" .. data.Name .. "]"
            lootObjects[part].Position = Vector2.new(sp.X, sp.Y)
        else
            lootObjects[part].Visible = false
        end
    end
    
    -- Limpa desenhos de itens que saíram do cache
    for part, txt in pairs(lootObjects) do
        if not active[part] then txt:Remove(); lootObjects[part] = nil end
    end
end

RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateLoot()
end)

getgenv().Cobble_Unload = function()
    for _, obj in pairs(espObjects) do for _, d in pairs(obj) do pcall(function() d:Remove() end) end end
    for _, h in pairs(chamsObjects) do pcall(function() h:Destroy() end) end
    for _, txt in pairs(lootObjects) do pcall(function() txt:Remove() end) end
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.Brightness = 1
end
