-- cobble hills logic (REAL HUSH OPTIMIZED)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

getgenv().CobbleConfig = {
    ESP = { 
        Enabled = true, 
        Players = false, 
        Monsters = true, 
        Loot = true, 
        MaxDist = 300,
        -- FILTRO DE LOOT REAL
        LootFilters = {
            Keys = true,
            Meds = true,
            Weapons = true,
            Money = true,
            Misc = false
        }
    },
    Aimbot = { Enabled = true, Silent = true, HoldMode = true, Key = Enum.UserInputType.MouseButton2, FOV = 150, Smoothness = 0.25, Target = "Listener", WallCheck = true },
    Util = { Speed = 16, SilentWalk = true, AutoPickup = true, HitboxExpand = false, HitboxSize = 8 }
}

local Config = getgenv().CobbleConfig
local CachedEntities = {}
local espObjects = {}
local fovCircle = Drawing.new("Circle")

fovCircle.Thickness = 1.5
fovCircle.NumSides = 60
fovCircle.Color = Color3.fromRGB(90, 140, 255)

-- FUNÇÃO QUE CHECA SE O ITEM ENTRA NO FILTRO
local function ShouldShowLoot(itemName)
    local name = itemName:lower()
    
    if Config.ESP.LootFilters.Keys then
        if name:find("key") or name:find("card") then return true end
    end
    if Config.ESP.LootFilters.Meds then
        if name:find("bandage") or name:find("pill") or name:find("med") or name:find("antiviral") or name:find("health") then return true end
    end
    if Config.ESP.LootFilters.Weapons then
        if name:find("pistol") or name:find("revolver") or name:find("gun") or name:find("pipe") or name:find("bat") or name:find("knife") or name:find("ammo") or name:find("flashlight") then return true end
    end
    if Config.ESP.LootFilters.Money then
        if name:find("coin") or name:find("cash") or name:find("scrap") or name:find("jewel") then return true end
    end
    if Config.ESP.LootFilters.Misc then
        return true -- Mostra tudo se o Misc estiver ligado
    end
    
    return false
end

-- CACHE ULTRA OTIMIZADO (Só o que tá perto e é útil)
task.spawn(function()
    while task.wait(0.5) do
        local temp = {}
        local camPos = Camera.CFrame.Position
        
        -- Players e Monstros
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 and (camPos - hrp.Position).Magnitude < Config.ESP.MaxDist then 
                    temp[plr.Character] = { Type = "Player", Name = plr.Name, Root = hrp } 
                end
            end
        end

        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") then
                local hum = v:FindFirstChildOfClass("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                
                if hrp and (camPos - hrp.Position).Magnitude < Config.ESP.MaxDist then
                    if hum and hum.Health > 0 and (v.Name == "Listener" or v.Name == "Hound") then
                        temp[v] = { Type = v.Name, Name = v.Name, Root = hrp }
                    elseif not hum then
                        -- É um item
                        if ShouldShowLoot(v.Name) then
                            temp[v] = { Type = "Loot", Name = v.Name, Root = hrp }
                        end
                    end
                end
            end
        end
        CachedEntities = temp
    end
end)

-- AUTO PICKUP RÁPIDO
task.spawn(function()
    while task.wait(0.1) do
        if Config.Util.AutoPickup and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, info in pairs(CachedEntities) do
                    if info.Type == "Loot" then
                        local dist = (hrp.Position - info.Root.Position).Magnitude
                        if dist < 15 then
                            pcall(function()
                                if firetouchinterest then
                                    firetouchinterest(hrp, info.Root, 0)
                                    task.wait(0.05)
                                    firetouchinterest(hrp, info.Root, 1)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- HITBOX EXPANDER
task.spawn(function()
    while task.wait(2) do
        if Config.Util.HitboxExpand then
            for char, info in pairs(CachedEntities) do
                if (info.Type == "Listener" or info.Type == "Hound") and char:FindFirstChild("HumanoidRootPart") then
                    if char.HumanoidRootPart.Size.X ~= Config.Util.HitboxSize then
                        char.HumanoidRootPart.Size = Vector3.new(Config.Util.HitboxSize, Config.Util.HitboxSize, Config.Util.HitboxSize)
                        char.HumanoidRootPart.Transparency = 0.7
                        char.HumanoidRootPart.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- ESP OTIMIZADO
local function UpdateESP()
    local camPos = Camera.CFrame.Position
    local activeObjects = {}

    if Config.ESP.Enabled then
        for char, info in pairs(CachedEntities) do
            local show, color = false, Color3.fromRGB(60, 150, 255)
            
            if info.Type == "Player" and Config.ESP.Players then show = true; color = Color3.fromRGB(60, 150, 255) end
            if info.Type == "Listener" and Config.ESP.Monsters then show = true; color = Color3.fromRGB(255, 60, 60) end
            if info.Type == "Hound" and Config.ESP.Monsters then show = true; color = Color3.fromRGB(200, 60, 255) end
            if info.Type == "Loot" and Config.ESP.Loot then show = true; color = Color3.fromRGB(255, 215, 0) end

            if show and info.Root then
                local dist = (camPos - info.Root.Position).Magnitude
                if dist < Config.ESP.MaxDist then
                    local sp = Camera:WorldToViewportPoint(info.Root.Position)
                    if sp.Z > 0 then
                        activeObjects[char] = true
                        if not espObjects[char] then
                            espObjects[char] = { name = Drawing.new("Text") }
                            espObjects[char].name.Size = 13
                            espObjects[char].name.Center = true
                            espObjects[char].name.Outline = true
                        end
                        local obj = espObjects[char]
                        obj.name.Visible = true
                        obj.name.Color = color
                        obj.name.Text = info.Name .. " [" .. math.floor(dist) .. "m]"
                        obj.name.Position = Vector2.new(sp.X, sp.Y)
                    end
                end
            end
        end
    end

    for char, obj in pairs(espObjects) do
        if not activeObjects[char] then
            if obj.name then obj.name:Remove() end
            espObjects[char] = nil
        end
    end
end

-- SILENT AIM & AIMBOT
local function GetTarget(silent)
    local mouse = UserInputService:GetMouseLocation()
    local center = Camera.ViewportSize / 2
    local targetPos = silent and center or mouse
    
    local camPos = Camera.CFrame.Position
    local best, bestDist = nil, Config.Aimbot.FOV

    for char, info in pairs(CachedEntities) do
        if info.Type ~= "Loot" and (Config.Aimbot.Target == "All" or info.Type == Config.Aimbot.Target) then
            local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if part then
                if Config.Aimbot.WallCheck then
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = { LocalPlayer.Character, char }
                    if Workspace:Raycast(camPos, part.Position - camPos, params) then continue end
                end
                local sp = Camera:WorldToViewportPoint(part.Position)
                if sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - targetPos).Magnitude
                    if d < bestDist then best, bestDist = part, d end
                end
            end
        end
    end
    return best
end

local oldIndex
local mt = getrawmetatable(game)
setreadonly(mt, false)
oldIndex = mt.__index
mt.__index = newcclosure(function(self, key)
    if Config.Aimbot.Enabled and Config.Aimbot.Silent then
        local isKeyDown = Config.Aimbot.Key.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(Config.Aimbot.Key) or UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
        if isKeyDown and self == Mouse then
            if key == "Hit" or key == "Target" then
                local target = GetTarget(true)
                if target then return target end
            end
        end
    end
    return oldIndex(self, key)
end)
setreadonly(mt, true)

RunService:BindToRenderStep("CobbleHushAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if not Config.Aimbot.Enabled or Config.Aimbot.Silent then return end
    local isKeyDown = Config.Aimbot.Key.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(Config.Aimbot.Key) or UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
    if isKeyDown then
        local target = GetTarget(false)
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, target.Position), Config.Aimbot.Smoothness)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateESP()
    fovCircle.Visible = Config.Aimbot.Enabled and not Config.Aimbot.Silent
    if fovCircle.Visible then
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = Config.Aimbot.FOV
    end
end)

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.Util.Speed end
        if Config.Util.SilentWalk then for _, v in ipairs(char:GetDescendants()) do if v:IsA("Sound") then v.Volume = 0; v.Playing = false end end end
    end
end)

getgenv().Cobble_Unload = function()
    pcall(function() RunService:UnbindFromRenderStep("CobbleHushAimbot") end)
    for _, obj in pairs(espObjects) do if obj.name then pcall(function() obj.name:Remove() end) end end
    pcall(function() fovCircle:Remove() end)
    pcall(function()
        setreadonly(mt, false)
        mt.__index = oldIndex
        setreadonly(mt, true)
    end)
end
