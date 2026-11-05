-- cobble hills logic (HUSH ULTIMATE)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

getgenv().CobbleConfig = {
    ESP = { Enabled = true, Box = true, Chams = true, Name = true, Dist = true },
    Loot = { Enabled = true, MaxDist = 1000 },
    Util = { SilentWalk = true, FastVault = false, Fullbright = false }
}
local Config = getgenv().CobbleConfig

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local MoveRemote = Remotes and Remotes:FindFirstChild("Move")

-- ==========================================
-- SILENT WALK (Muta os sons locais do pé)
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
-- FAST VAULT (Spamma o remote de Vault)
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if not Config.Util.FastVault or not MoveRemote then continue end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Tenta spammar o vault pra frente pra "voar" rasante
            pcall(function()
                MoveRemote:FireServer("vault", Camera.CFrame.LookVector * 50, {})
            end)
        end
    end
end)

-- ==========================================
-- CACHE DE JOGADORES E LOOPS
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

local espObjects, chamsObjects = {}, {}

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

-- ==========================================
-- LOOT ESP (Usando ProximityPrompts Genéricos)
-- ==========================================
local lootObjects = {}
local function UpdateLoot()
    if not Config.Loot.Enabled then
        for _, v in pairs(lootObjects) do v:Remove() end
        lootObjects = {}
        return
    end
    
    local activeLoot = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Parent and v.Parent:IsA("BasePart") then
            local part = v.Parent
            local dist = (Camera.CFrame.Position - part.Position).Magnitude
            if dist < Config.Loot.MaxDist then
                activeLoot[part] = true
                if not lootObjects[part] then
                    local txt = Drawing.new("Text")
                    txt.Size = 12; txt.Center = true; txt.Outline = true; txt.Color = Color3.fromRGB(255, 215, 0)
                    lootObjects[part] = txt
                end
                
                local sp = Camera:WorldToViewportPoint(part.Position)
                if sp.Z > 0 then
                    lootObjects[part].Visible = true
                    lootObjects[part].Text = "[" .. v.Parent.Parent.Name .. "]"
                    lootObjects[part].Position = Vector2.new(sp.X, sp.Y)
                else
                    lootObjects[part].Visible = false
                end
            end
        end
    end
    
    for part, txt in pairs(lootObjects) do
        if not activeLoot[part] then txt:Remove(); lootObjects[part] = nil end
    end
end

-- ==========================================
-- LOOPS
-- ==========================================
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateLoot()
    if Config.Util.Fullbright then
        Lighting.Ambient = Color3.new(1,1,1); Lighting.Brightness = 2
    end
end)

getgenv().Cobble_Unload = function()
    for _, obj in pairs(espObjects) do for _, d in pairs(obj) do pcall(function() d:Remove() end) end end
    for _, h in pairs(chamsObjects) do pcall(function() h:Destroy() end) end
    for _, txt in pairs(lootObjects) do pcall(function() txt:Remove() end) end
end
