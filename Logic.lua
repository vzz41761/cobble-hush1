-- cobble hills logic
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

getgenv().CobbleConfig = {
    ESP = { Enabled = true, Players = false, Monsters = true, Box = true, Name = true, Dist = true },
    Aimbot = { Enabled = true, HoldMode = true, Key = Enum.UserInputType.MouseButton2, FOV = 150, Smoothness = 0.25, Target = "Listener", WallCheck = true },
    Util = { NoClip = false, Speed = 16, SilentWalk = true, ForceCrouch = false },
    -- ADICIONE SEUS TELEPORTES AQUI EMBAIXO (substitua os números)
    Teleports = {
        ["Spawn"] = Vector3.new(0, 10, 0),
        ["Casa Vermelha"] = Vector3.new(100, 10, 150),
        ["Esconderijo"] = Vector3.new(-200, 5, 50)
    }
}

local Config = getgenv().CobbleConfig
local CachedEntities = {}
local espObjects = {}
local fovCircle = Drawing.new("Circle")

fovCircle.Thickness = 1.5
fovCircle.NumSides = 60
fovCircle.Color = Color3.fromRGB(90, 140, 255)

task.spawn(function()
    while task.wait(0.5) do
        local temp = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then temp[plr.Character] = { Type = "Player", Name = plr.Name } end
            end
        end
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and (v.Name == "Listener" or v.Name == "Hound") then
                local hum = v:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then temp[v] = { Type = v.Name, Name = v.Name } end
            end
        end
        CachedEntities = temp
    end
end)

local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, obj in pairs(espObjects) do for _, d in pairs(obj) do d.Visible = false end end
        return
    end

    for char, info in pairs(CachedEntities) do
        if not espObjects[char] then
            espObjects[char] = { box = Drawing.new("Square"), name = Drawing.new("Text"), dist = Drawing.new("Text") }
            espObjects[char].box.Thickness = 1
            espObjects[char].name.Size = 13
            espObjects[char].name.Center = true
            espObjects[char].name.Outline = true
            espObjects[char].dist.Size = 12
            espObjects[char].dist.Center = true
            espObjects[char].dist.Outline = true
        end

        local obj = espObjects[char]
        local show, color = false, Color3.fromRGB(60, 150, 255)

        if info.Type == "Player" and Config.ESP.Players then show = true; color = Color3.fromRGB(60, 150, 255) end
        if info.Type == "Listener" and Config.ESP.Monsters then show = true; color = Color3.fromRGB(255, 60, 60) end
        if info.Type == "Hound" and Config.ESP.Monsters then show = true; color = Color3.fromRGB(200, 60, 255) end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head") or root

        if show and root and head then
            local top3 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
            local bot3 = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
            if top3.Z > 0 and bot3.Z > 0 then
                local topV, botV = Vector2.new(top3.X, top3.Y), Vector2.new(bot3.X, bot3.Y)
                local h = botV.Y - topV.Y
                local w = h * 0.55
                local bx = topV.X - w * 0.5

                obj.box.Visible, obj.box.Color = Config.ESP.Box, color
                obj.box.Position, obj.box.Size = Vector2.new(bx, topV.Y), Vector2.new(w, h)
                obj.name.Visible, obj.name.Color = Config.ESP.Name, color
                obj.name.Text = "[" .. info.Type .. "]"
                obj.name.Position = Vector2.new(topV.X, topV.Y - 16)
                obj.dist.Visible = Config.ESP.Dist
                obj.dist.Text = math.floor((Camera.CFrame.Position - root.Position).Magnitude) .. "m"
                obj.dist.Position = Vector2.new(topV.X, botV.Y + 2)
            else
                obj.box.Visible, obj.name.Visible, obj.dist.Visible = false, false, false
            end
        else
            obj.box.Visible, obj.name.Visible, obj.dist.Visible = false, false, false
        end
    end
end

local function GetTarget()
    local mouse = UserInputService:GetMouseLocation()
    local camPos = Camera.CFrame.Position
    local best, bestDist = nil, Config.Aimbot.FOV

    for char, info in pairs(CachedEntities) do
        if Config.Aimbot.Target == "All" or info.Type == Config.Aimbot.Target then
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
                    local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                    if d < bestDist then best, bestDist = part, d end
                end
            end
        end
    end
    return best
end

RunService:BindToRenderStep("CobbleHushAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if not Config.Aimbot.Enabled then return end
    local isKeyDown = Config.Aimbot.Key.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(Config.Aimbot.Key) or UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
    if isKeyDown then
        local target = GetTarget()
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, target.Position), Config.Aimbot.Smoothness)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateESP()
    fovCircle.Visible = Config.Aimbot.Enabled
    if fovCircle.Visible then
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = Config.Aimbot.FOV
    end
end)

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.Util.ForceCrouch and 6 or Config.Util.Speed end
        if Config.Util.NoClip then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        if Config.Util.SilentWalk then for _, v in ipairs(char:GetDescendants()) do if v:IsA("Sound") then v.Volume = 0; v.Playing = false end end end
    end
end)

-- Função de Teleporte
getgenv().CobbleTP = function(name)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = Config.Teleports[name]
        if pos then
            char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        end
    end
end

getgenv().Cobble_Unload = function()
    pcall(function() RunService:UnbindFromRenderStep("CobbleHushAimbot") end)
    for _, obj in pairs(espObjects) do for _, d in pairs(obj) do pcall(function() d:Remove() end) end end
    pcall(function() fovCircle:Remove() end)
end
