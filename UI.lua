-- cobble hills UI (HUSH ULTIMATE)
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Config = getgenv().CobbleConfig
if not Config then return end

local Theme = {
    Bg = Color3.fromRGB(16, 18, 25), Sidebar = Color3.fromRGB(22, 24, 33),
    Surface = Color3.fromRGB(30, 33, 45), Text = Color3.fromRGB(240, 242, 250),
    Muted = Color3.fromRGB(120, 126, 145), Accent = Color3.fromRGB(90, 140, 255),
    Off = Color3.fromRGB(40, 44, 58), Green = Color3.fromRGB(80, 220, 130)
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
Main.Size = UDim2.fromOffset(500, 400)
Main.Position = UDim2.new(0.5, -250, 0.5, -200)
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Theme.Accent; stroke.Transparency = 0.8

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = Main

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -30, 1, 0)
TitleText.Position = UDim2.fromOffset(20, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "COBBLE <font color='#5A8CFF'>HUSH</font>"
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
end

local Tabs = { Visuals = CreateTab("Visuals"), Utils = CreateTab("Utils") }

local function LoadTab(tabName)
    for _, v in ipairs(Scroll:GetChildren()) do
        if v:IsA("Frame") or v:IsA("TextButton") then v:Destroy() end
    end
    for name, btn in pairs(Tabs) do
        btn.TextColor3 = (name == tabName) and Theme.Accent or Theme.Muted
    end

    if tabName == "Visuals" then
        CreateToggle("Jogadores ESP", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled = v end)
        CreateToggle("Chams (Player)", function() return Config.ESP.Chams end, function(v) Config.ESP.Chams = v end)
        CreateToggle("Loot ESP (Itens)", function() return Config.Loot.Enabled end, function(v) Config.Loot.Enabled = v end)
    elseif tabName == "Utils" then
        CreateToggle("Silent Walk (Zero Som)", function() return Config.Util.SilentWalk end, function(v) Config.Util.SilentWalk = v end)
        CreateToggle("Fast Vault (Voa Rasante)", function() return Config.Util.FastVault end, function(v) Config.Util.FastVault = v end)
        CreateToggle("Fullbright (Luz Total)", function() return Config.Util.Fullbright end, function(v) Config.Util.Fullbright = v end)
        
        CreateButton("UNLOAD SCRIPT", Color3.fromRGB(255, 80, 80), function()
            if getgenv().Cobble_Unload then getgenv().Cobble_Unload() end
            Gui:Destroy()
        end)
    end
end

Tabs.Visuals.MouseButton1Click:Connect(function() LoadTab("Visuals") end)
Tabs.Utils.MouseButton1Click:Connect(function() LoadTab("Utils") end)
LoadTab("Visuals")

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

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Gui.Enabled = not Gui.Enabled end
end)
