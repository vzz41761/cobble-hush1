-- cobble hills UI (HUSH V3)
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Config = getgenv().CobbleConfig
if not Config then warn("[cobble] Config ausente — carregue o Logic primeiro."); return end

-- garante Aim presente mesmo se UI subir antes do merge
Config.Aim = Config.Aim or {
    Enabled = false, AlwaysOn = false, Key = Enum.KeyCode.E,
    FOV = 120, Smooth = 0.55, FireRate = 1/45,
    ShowFOV = true, InvertYaw = false, InvertPitch = false,
}

local Theme = {
    Bg = Color3.fromRGB(16, 18, 25), Sidebar = Color3.fromRGB(22, 24, 33),
    Surface = Color3.fromRGB(30, 33, 45), Text = Color3.fromRGB(240, 242, 250),
    Muted = Color3.fromRGB(120, 126, 145), Accent = Color3.fromRGB(90, 140, 255),
    Off = Color3.fromRGB(40, 44, 58), Danger = Color3.fromRGB(255, 80, 80),
}

local function Tween(inst, props, time)
    TweenService:Create(inst, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad), props):Play()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "CobbleMaster"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
local ok, hui = pcall(function() return gethui and gethui() end)
Gui.Parent = (ok and hui) or game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(500, 420)
Main.Position = UDim2.new(0.5, -250, 0.5, -210)
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = Main

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -30, 1, 0)
TitleText.Position = UDim2.fromOffset(20, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "COBBLE <font color='#5A8CFF'>HUSH</font> <font color='#787E91'>v3</font>"
TitleText.RichText = true
TitleText.TextColor3 = Theme.Text
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -70)
Sidebar.Position = UDim2.new(0, 15, 0, 55)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 1, -20)
TabContainer.Position = UDim2.new(0, 10, 0, 10)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar
Instance.new("UIListLayout", TabContainer).Padding = UDim.new(0, 8)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -160, 1, -70)
Content.Position = UDim2.new(0, 155, 0, 55)
Content.BackgroundColor3 = Theme.Sidebar
Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 10)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -20)
Scroll.Position = UDim2.new(0, 10, 0, 10)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Theme.Accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = Content

local ScrollLayout = Instance.new("UIListLayout", Scroll)
ScrollLayout.Padding = UDim.new(0, 10)
ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 10)
end)

local function CreateTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Theme.Bg
    btn.Font = Enum.Font.GothamMedium
    btn.Text = text
    btn.TextColor3 = Theme.Muted
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Parent = TabContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local function CreateSection(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text
    lbl.TextColor3 = Theme.Muted
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Scroll
    return lbl
end

local function CreateToggle(text, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = Scroll
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, 0, 0.5, 0)
    track.Size = UDim2.fromOffset(38, 20)
    track.BackgroundColor3 = Theme.Off
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(16, 16)
    dot.Position = UDim2.fromOffset(2, 2)
    dot.BackgroundColor3 = Theme.Muted
    dot.Parent = track
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local function Refresh()
        if get() then
            Tween(track, {BackgroundColor3 = Theme.Accent})
            Tween(dot, {Position = UDim2.fromOffset(20, 2), BackgroundColor3 = Color3.new(1,1,1)})
        else
            Tween(track, {BackgroundColor3 = Theme.Off})
            Tween(dot, {Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Theme.Muted})
        end
    end
    btn.MouseButton1Click:Connect(function() set(not get()); Refresh() end)
    Refresh()
end

local function CreateSlider(text, min, max, get, set, step)
    step = step or 1
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 48)
    holder.BackgroundTransparency = 1
    holder.Parent = Scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 0, 16)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local valText = Instance.new("TextLabel")
    valText.Size = UDim2.fromOffset(50, 16)
    valText.Position = UDim2.new(1, -50, 0, 0)
    valText.BackgroundTransparency = 1
    valText.Font = Enum.Font.Gotham
    valText.TextColor3 = Theme.Accent
    valText.TextSize = 12
    valText.TextXAlignment = Enum.TextXAlignment.Right
    valText.Parent = holder

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 26)
    track.BackgroundColor3 = Theme.Off
    track.Parent = holder
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.fromOffset(14, 14)
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.Position = UDim2.new(0, 0, 0.5, 0)
    handle.BackgroundColor3 = Color3.new(1,1,1)
    handle.Parent = track
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

    local function Refresh()
        local v = tonumber(get()) or min
        local a = math.clamp((v - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        handle.Position = UDim2.new(a, 0, 0.5, 0)
        if step >= 1 then
            valText.Text = tostring(math.floor(v))
        else
            valText.Text = string.format("%.2f", v)
        end
    end

    local dragging = false
    local function SetFromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * a
        local quantized = math.floor(raw / step + 0.5) * step
        set(math.clamp(quantized, min, max))
        Refresh()
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; SetFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then SetFromX(i.Position.X) end
    end)
    Refresh()
end

local function CreateButton(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 13
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- keybind capture
local function CreateKeybind(text, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = Scroll
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.fromOffset(100, 24)
    keyBtn.AnchorPoint = Vector2.new(1, 0.5)
    keyBtn.Position = UDim2.new(1, 0, 0.5, 0)
    keyBtn.BackgroundColor3 = Theme.Surface
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextColor3 = Theme.Accent
    keyBtn.TextSize = 12
    keyBtn.Text = get().Name
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = row
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

    local capturing = false
    keyBtn.MouseButton1Click:Connect(function()
        capturing = true
        keyBtn.Text = "pressione..."
        keyBtn.TextColor3 = Theme.Muted
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not capturing then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            set(input.KeyCode)
            keyBtn.Text = input.KeyCode.Name
            keyBtn.TextColor3 = Theme.Accent
            capturing = false
        end
    end)
end

local Tabs = {
    Visuals = CreateTab("Visuals"),
    Aim     = CreateTab("Aim"),
    Utils   = CreateTab("Utils"),
}

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
        CreateToggle("Box + Health Bar", function() return Config.ESP.Box end, function(v) Config.ESP.Box = v end)
        CreateToggle("Chams (Highlight)", function() return Config.ESP.Chams end, function(v) Config.ESP.Chams = v end)
        CreateToggle("Nome", function() return Config.ESP.Name end, function(v) Config.ESP.Name = v end)
        CreateToggle("Distância", function() return Config.ESP.Dist end, function(v) Config.ESP.Dist = v end)

        CreateSection("LOOT")
        CreateToggle("Loot ESP", function() return Config.Loot.Enabled end, function(v) Config.Loot.Enabled = v end)
        CreateSlider("Alcance (m)", 50, 500, function() return Config.Loot.MaxDist end, function(v) Config.Loot.MaxDist = v end, 10)

    elseif tabName == "Aim" then
        CreateSection("SILENT AIM (LOOK REMOTE)")
        CreateToggle("Habilitado", function() return Config.Aim.Enabled end, function(v) Config.Aim.Enabled = v end)
        CreateToggle("Sempre Ativo", function() return Config.Aim.AlwaysOn end, function(v) Config.Aim.AlwaysOn = v end)
        CreateKeybind("Tecla de mira", function() return Config.Aim.Key end, function(v) Config.Aim.Key = v end)
        CreateToggle("Mostrar FOV", function() return Config.Aim.ShowFOV end, function(v) Config.Aim.ShowFOV = v end)

        CreateSection("TUNING")
        CreateSlider("FOV (px)", 20, 400, function() return Config.Aim.FOV end, function(v) Config.Aim.FOV = v end, 5)
        CreateSlider("Suavidade", 0.05, 1.0, function() return Config.Aim.Smooth end, function(v) Config.Aim.Smooth = v end, 0.05)
        CreateSlider("Taxa de envio (Hz)", 10, 60, function() return 1 / Config.Aim.FireRate end, function(v) Config.Aim.FireRate = 1 / v end, 1)

        CreateSection("CALIBRAÇÃO")
        CreateToggle("Inverter Yaw", function() return Config.Aim.InvertYaw end, function(v) Config.Aim.InvertYaw = v end)
        CreateToggle("Inverter Pitch", function() return Config.Aim.InvertPitch end, function(v) Config.Aim.InvertPitch = v end)

    elseif tabName == "Utils" then
        CreateSection("MOVIMENTO")
        CreateToggle("Silent Walk (passo mudo)", function() return Config.Util.SilentWalk end, function(v) Config.Util.SilentWalk = v end)

        CreateSection("AMBIENTE")
        CreateToggle("Fullbright", function() return Config.Util.Fullbright end, function(v) Config.Util.Fullbright = v end)

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

-- drag da janela
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- toggle visibilidade
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Gui.Enabled = not Gui.Enabled end
end)
