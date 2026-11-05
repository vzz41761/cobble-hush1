-- cobble hills UI (HUSH V4.1)
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Config = getgenv().CobbleConfig
if not Config then warn("[cobble] Config ausente"); return end

local Theme = {
    Bg=Color3.fromRGB(16,18,25), Sidebar=Color3.fromRGB(22,24,33),
    Surface=Color3.fromRGB(30,33,45), Text=Color3.fromRGB(240,242,250),
    Muted=Color3.fromRGB(120,126,145), Accent=Color3.fromRGB(90,140,255),
    Off=Color3.fromRGB(40,44,58), Danger=Color3.fromRGB(255,80,80),
}
local function Tween(i, p, t) TweenService:Create(i, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad), p):Play() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "CobbleMaster"; Gui.ResetOnSpawn = false; Gui.IgnoreGuiInset = true
local ok, hui = pcall(function() return gethui and gethui() end)
Gui.Parent = (ok and hui) or game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(520, 480)
Main.Position = UDim2.new(0.5, -260, 0.5, -240)
Main.BackgroundColor3 = Theme.Bg; Main.BorderSizePixel = 0; Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,50); TitleBar.BackgroundTransparency = 1; TitleBar.Parent = Main
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1,-30,1,0); TitleText.Position = UDim2.fromOffset(20,0)
TitleText.BackgroundTransparency = 1; TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "COBBLE <font color='#5A8CFF'>HUSH</font> <font color='#787E91'>v4.1</font>"
TitleText.RichText = true; TitleText.TextColor3 = Theme.Text; TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left; TitleText.Parent = TitleBar

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,130,1,-70); Sidebar.Position = UDim2.new(0,15,0,55)
Sidebar.BackgroundColor3 = Theme.Sidebar; Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,10)

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1,-20,1,-20); TabContainer.Position = UDim2.new(0,10,0,10)
TabContainer.BackgroundTransparency = 1; TabContainer.Parent = Sidebar
Instance.new("UIListLayout", TabContainer).Padding = UDim.new(0,8)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-160,1,-70); Content.Position = UDim2.new(0,155,0,55)
Content.BackgroundColor3 = Theme.Sidebar; Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0,10)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,-20,1,-20); Scroll.Position = UDim2.new(0,10,0,10)
Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Theme.Accent; Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.Parent = Content

local ScrollLayout = Instance.new("UIListLayout", Scroll)
ScrollLayout.Padding = UDim.new(0,8)
ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0,0,0, ScrollLayout.AbsoluteContentSize.Y + 10)
end)

local function CreateTab(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,36); b.BackgroundColor3 = Theme.Bg
    b.Font = Enum.Font.GothamMedium; b.Text = text
    b.TextColor3 = Theme.Muted; b.TextSize = 13; b.AutoButtonColor = false
    b.Parent = TabContainer
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    return b
end

local function CreateSection(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,20); l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold; l.Text = text
    l.TextColor3 = Theme.Muted; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = Scroll
end

local function CreateToggle(text, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,30); row.BackgroundTransparency = 1; row.Parent = Scroll
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-60,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium; lbl.Text = text
    lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1,0.5); track.Position = UDim2.new(1,0,0.5,0)
    track.Size = UDim2.fromOffset(36,18); track.BackgroundColor3 = Theme.Off
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(14,14); dot.Position = UDim2.fromOffset(2,2)
    dot.BackgroundColor3 = Theme.Muted; dot.Parent = track
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1,1); btn.BackgroundTransparency = 1; btn.Text = ""; btn.Parent = row
    local function Refresh()
        if get() then
            Tween(track, {BackgroundColor3 = Theme.Accent})
            Tween(dot, {Position = UDim2.fromOffset(20,2), BackgroundColor3 = Color3.new(1,1,1)})
        else
            Tween(track, {BackgroundColor3 = Theme.Off})
            Tween(dot, {Position = UDim2.fromOffset(2,2), BackgroundColor3 = Theme.Muted})
        end
    end
    btn.MouseButton1Click:Connect(function() set(not get()); Refresh() end)
    Refresh()
end

local function CreateSlider(text, minv, maxv, get, set, step)
    step = step or 1
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,44); holder.BackgroundTransparency = 1; holder.Parent = Scroll
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,0,16); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium; lbl.Text = text
    lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = holder
    local val = Instance.new("TextLabel")
    val.Size = UDim2.fromOffset(50,16); val.Position = UDim2.new(1,-50,0,0)
    val.BackgroundTransparency = 1; val.Font = Enum.Font.Gotham
    val.TextColor3 = Theme.Accent; val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right; val.Parent = holder
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,0,0,6); track.Position = UDim2.new(0,0,0,26)
    track.BackgroundColor3 = Theme.Off; track.Parent = holder
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0); fill.BackgroundColor3 = Theme.Accent; fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local handle = Instance.new("Frame")
    handle.Size = UDim2.fromOffset(14,14); handle.AnchorPoint = Vector2.new(0.5,0.5)
    handle.Position = UDim2.new(0,0,0.5,0); handle.BackgroundColor3 = Color3.new(1,1,1)
    handle.Parent = track
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1,0)
    local function Refresh()
        local v = tonumber(get()) or minv
        local a = math.clamp((v-minv)/(maxv-minv),0,1)
        fill.Size = UDim2.new(a,0,1,0); handle.Position = UDim2.new(a,0,0.5,0)
        if step >= 1 then val.Text = tostring(math.floor(v))
        else val.Text = string.format("%.2f", v) end
    end
    local dragging = false
    local function SetFromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw = minv + (maxv-minv) * a
        local q = math.floor(raw/step + 0.5) * step
        set(math.clamp(q, minv, maxv)); Refresh()
    end
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; SetFromX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then SetFromX(i.Position.X) end end)
    Refresh()
end

local function CreateButton(text, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,34); b.BackgroundColor3 = color
    b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13; b.Text = text; b.AutoButtonColor = false; b.Parent = Scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    b.MouseButton1Click:Connect(cb); return b
end

local function bindLabel(b)
    if typeof(b) ~= "EnumItem" then return "?" end
    if b.EnumType == Enum.KeyCode then return b.Name end
    if b == Enum.UserInputType.MouseButton1 then return "MB1" end
    if b == Enum.UserInputType.MouseButton2 then return "MB2" end
    if b == Enum.UserInputType.MouseButton3 then return "MB3" end
    return b.Name
end

local function CreateKeybind(text, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,30); row.BackgroundTransparency = 1; row.Parent = Scroll
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-110,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium; lbl.Text = text
    lbl.TextColor3 = Theme.Text; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local kb = Instance.new("TextButton")
    kb.Size = UDim2.fromOffset(100,22); kb.AnchorPoint = Vector2.new(1,0.5)
    kb.Position = UDim2.new(1,0,0.5,0); kb.BackgroundColor3 = Theme.Surface
    kb.Font = Enum.Font.GothamBold; kb.TextColor3 = Theme.Accent
    kb.TextSize = 12; kb.Text = bindLabel(get()); kb.AutoButtonColor = false
    kb.Parent = row
    Instance.new("UICorner", kb).CornerRadius = UDim.new(0,6)
    local cap = false
    kb.MouseButton1Click:Connect(function() cap = true; kb.Text = "pressione..."; kb.TextColor3 = Theme.Muted end)
    UserInputService.InputBegan:Connect(function(i, gpe)
        if not cap then return end
        if gpe and i.UserInputType == Enum.UserInputType.MouseButton1 then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            set(i.KeyCode); kb.Text = bindLabel(i.KeyCode); kb.TextColor3 = Theme.Accent; cap = false
        elseif i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.MouseButton3 then
            set(i.UserInputType); kb.Text = bindLabel(i.UserInputType); kb.TextColor3 = Theme.Accent; cap = false
        end
    end)
end

local Tabs = { Visuals=CreateTab("Visuals"), Aim=CreateTab("Aim"), Utils=CreateTab("Utils") }
local function clearScroll()
    for _, v in ipairs(Scroll:GetChildren()) do
        if v:IsA("Frame") or v:IsA("TextButton") or v:IsA("TextLabel") then v:Destroy() end
    end
end

local function LoadTab(tabName)
    clearScroll()
    for name, btn in pairs(Tabs) do
        btn.TextColor3 = (name == tabName) and Theme.Accent or Theme.Muted
    end

    if tabName == "Visuals" then
        CreateSection("JOGADORES")
        CreateToggle("ESP Habilitado", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled = v end)
        CreateToggle("Box + Health", function() return Config.ESP.Box end, function(v) Config.ESP.Box = v end)
        CreateToggle("Chams", function() return Config.ESP.Chams end, function(v) Config.ESP.Chams = v end)
        CreateToggle("Nome", function() return Config.ESP.Name end, function(v) Config.ESP.Name = v end)
        CreateToggle("Distância", function() return Config.ESP.Dist end, function(v) Config.ESP.Dist = v end)
        CreateToggle("Arma na mão", function() return Config.ESP.Weapon end, function(v) Config.ESP.Weapon = v end)

        CreateSection("WALKERS / MONSTERS")
        CreateToggle("Walker ESP", function() return Config.ESP.Walker.Enabled end, function(v) Config.ESP.Walker.Enabled = v end)
        CreateToggle("Box", function() return Config.ESP.Walker.Box end, function(v) Config.ESP.Walker.Box = v end)
        CreateToggle("Nome", function() return Config.ESP.Walker.Name end, function(v) Config.ESP.Walker.Name = v end)
        CreateToggle("Distância", function() return Config.ESP.Walker.Dist end, function(v) Config.ESP.Walker.Dist = v end)
        CreateToggle("Health bar", function() return Config.ESP.Walker.Health end, function(v) Config.ESP.Walker.Health = v end)

        CreateSection("EXTRAÇÃO")
        CreateToggle("Extraction ESP", function() return Config.ESP.Extraction.Enabled end, function(v) Config.ESP.Extraction.Enabled = v end)

        CreateSection("VEÍCULOS")
        CreateToggle("Vehicle ESP", function() return Config.ESP.Vehicle.Enabled end, function(v) Config.ESP.Vehicle.Enabled = v end)

        CreateSection("MUNDO")
        CreateToggle("LootBags (players mortos)", function() return Config.ESP.LootBag.Enabled end, function(v) Config.ESP.LootBag.Enabled = v end)
        CreateToggle("Bodies (corpos)", function() return Config.ESP.Body.Enabled end, function(v) Config.ESP.Body.Enabled = v end)
        CreateToggle("WorldFinds (itens no chão)", function() return Config.ESP.WorldFind.Enabled end, function(v) Config.ESP.WorldFind.Enabled = v end)
        CreateToggle("Watchers", function() return Config.ESP.Watcher.Enabled end, function(v) Config.ESP.Watcher.Enabled = v end)

        CreateSection("LOOT — GERAL")
        CreateToggle("Loot ESP", function() return Config.Loot.Enabled end, function(v) Config.Loot.Enabled = v end)
        CreateToggle("Mostrar nomes", function() return Config.Loot.Labels end, function(v) Config.Loot.Labels = v end)
        CreateSlider("Alcance (m)", 30, 500, function() return Config.Loot.MaxDist end, function(v) Config.Loot.MaxDist = v end, 10)

        CreateSection("LOOT — TIERS")
        for _, row in ipairs({
            {"T0 — Armas", 0}, {"T1 — Médico/Tool", 1}, {"T2 — Mobília", 2}, {"T3 — Info", 3},
        }) do
            local tier = row[2]
            CreateToggle(row[1], function() return Config.Loot.TierEnabled[tier] end, function(v) Config.Loot.TierEnabled[tier] = v end)
        end

        CreateSection("LOOT — CONTAINERS")
        local containers = (getgenv().Cobble_LootContainers and getgenv().Cobble_LootContainers()) or {}
        local lastTier = nil
        local tierNames = { [0]="T0 — Armas", [1]="T1 — Médico/Tool", [2]="T2 — Mobília", [3]="T3 — Info" }
        for _, c in ipairs(containers) do
            if c.Tier ~= lastTier then
                lastTier = c.Tier
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1,0,0,16); l.BackgroundTransparency = 1
                l.Font = Enum.Font.Gotham; l.Text = tierNames[c.Tier] or ("T" .. tostring(c.Tier))
                l.TextColor3 = Theme.Muted; l.TextSize = 11
                l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = Scroll
            end
            local nm = c.Name
            CreateToggle(nm,
                function() return Config.Loot.PerContainer[nm] ~= false end,
                function(v) Config.Loot.PerContainer[nm] = v end)
        end
        CreateButton("RE-SCAN CONTAINERS", Theme.Surface, function() LoadTab("Visuals") end)

    elseif tabName == "Aim" then
        CreateSection("AIMBOT")
        CreateToggle("Habilitado", function() return Config.Aim.Enabled end, function(v) Config.Aim.Enabled = v end)
        CreateToggle("Sempre Ativo", function() return Config.Aim.AlwaysOn end, function(v) Config.Aim.AlwaysOn = v end)
        CreateKeybind("Tecla/botão de mira", function() return Config.Aim.Key end, function(v) Config.Aim.Key = v end)
        CreateToggle("Mostrar FOV", function() return Config.Aim.ShowFOV end, function(v) Config.Aim.ShowFOV = v end)
        CreateToggle("Debug", function() return Config.Aim.Debug end, function(v) Config.Aim.Debug = v end)

        CreateSection("MODO")
        CreateToggle("Visual (câmera gruda)", function() return Config.Aim.Visual end, function(v) Config.Aim.Visual = v end)
        CreateToggle("Silent (câmera não mexe)", function() return Config.Aim.Silent end, function(v) Config.Aim.Silent = v end)

        CreateSection("TUNING")
        CreateSlider("FOV (px)", 20, 400, function() return Config.Aim.FOV end, function(v) Config.Aim.FOV = v end, 5)
        CreateSlider("Suavidade", 0.05, 1.0, function() return Config.Aim.Smooth end, function(v) Config.Aim.Smooth = v end, 0.05)
        CreateSlider("Predição (s)", 0.0, 0.3, function() return Config.Aim.Prediction end, function(v) Config.Aim.Prediction = v end, 0.01)

        CreateSection("OSSO")
        CreateButton("Head", Config.Aim.Bone=="head" and Theme.Accent or Theme.Surface, function() Config.Aim.Bone="head"; LoadTab("Aim") end)
        CreateButton("Chest", Config.Aim.Bone=="chest" and Theme.Accent or Theme.Surface, function() Config.Aim.Bone="chest"; LoadTab("Aim") end)
        CreateButton("Root", Config.Aim.Bone=="root" and Theme.Accent or Theme.Surface, function() Config.Aim.Bone="root"; LoadTab("Aim") end)

        CreateSection("CALIBRAÇÃO (silent)")
        CreateToggle("Inverter Yaw", function() return Config.Aim.InvertYaw end, function(v) Config.Aim.InvertYaw = v end)
        CreateToggle("Inverter Pitch", function() return Config.Aim.InvertPitch end, function(v) Config.Aim.InvertPitch = v end)

    elseif tabName == "Utils" then
        CreateSection("HUD")
        CreateToggle("HUD ligado", function() return Config.HUD.Enabled end, function(v) Config.HUD.Enabled = v end)

        CreateSection("MOVIMENTO")
        CreateToggle("Silent Walk", function() return Config.Util.SilentWalk end, function(v) Config.Util.SilentWalk = v end)
        CreateToggle("Prender respiração", function() return Config.Util.Breath end, function(v) Config.Util.Breath = v end)

        CreateSection("AMBIENTE")
        CreateToggle("Fullbright", function() return Config.Util.Fullbright end, function(v) Config.Util.Fullbright = v end)
        CreateToggle("Night Vision", function() return Config.Util.NightVision end, function(v) Config.Util.NightVision = v end)

        CreateSection("AUTO-PICKUP")
        CreateToggle("Auto-Pickup (containers)", function() return Config.Util.AutoPickup end, function(v) Config.Util.AutoPickup = v end)
        CreateSlider("Raio auto-pickup (m)", 2, 20, function() return Config.AutoPickupRadius end, function(v) Config.AutoPickupRadius = v end, 1)

        CreateSection("AÇÕES")
        CreateButton("FORÇAR PICKUP (takeAll)", Theme.Surface, function()
            if getgenv().Cobble_ForcePickup then getgenv().Cobble_ForcePickup() end
        end)
        CreateButton("FORÇAR DOOR", Theme.Surface, function()
            if getgenv().Cobble_ForceDoor then getgenv().Cobble_ForceDoor() end
        end)
        CreateButton("FORÇAR VAULT (frente)", Theme.Surface, function()
            if getgenv().Cobble_ForceVault then getgenv().Cobble_ForceVault(1, 0, 0) end
        end)
        CreateButton("DEPLOY / RESPAWN", Theme.Surface, function()
            if getgenv().Cobble_Deploy then getgenv().Cobble_Deploy() end
        end)
        CreateButton("FLASHLIGHT", Theme.Surface, function()
            if getgenv().Cobble_Flashlight then getgenv().Cobble_Flashlight() end
        end)
        CreateButton("STANCE toggle", Theme.Surface, function()
            if getgenv().Cobble_Stance then getgenv().Cobble_Stance(true) end
        end)
        CreateButton("ARRESTS (surrender)", Theme.Surface, function()
            if getgenv().Cobble_Arrest then getgenv().Cobble_Arrest() end
        end)
        CreateButton("REPLAY START", Theme.Surface, function()
            if getgenv().Cobble_Replay then getgenv().Cobble_Replay("start") end
        end)
        CreateButton("ABRIR PAPERMAP", Theme.Surface, function()
            if getgenv().Cobble_PaperMap then getgenv().Cobble_PaperMap(true) end
        end)
        CreateButton("DOWNED press true", Theme.Surface, function()
            if getgenv().Cobble_Downed then getgenv().Cobble_Downed(true) end
        end)
        CreateButton("EQUIP sledgehammer", Theme.Surface, function()
            if getgenv().Cobble_Equip then getgenv().Cobble_Equip("sledgehammer") end
        end)

        CreateSection("SESSÃO")
        CreateButton("UNLOAD SCRIPT", Theme.Danger, function()
            if getgenv().Cobble_Unload then pcall(getgenv().Cobble_Unload) end
            Gui:Destroy()
        end)
    end
end

Tabs.Visuals.MouseButton1Click:Connect(function() LoadTab("Visuals") end)
Tabs.Aim.MouseButton1Click:Connect(function() LoadTab("Aim") end)
Tabs.Utils.MouseButton1Click:Connect(function() LoadTab("Utils") end)
LoadTab("Visuals")

local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightShift then Gui.Enabled = not Gui.Enabled end
end)
