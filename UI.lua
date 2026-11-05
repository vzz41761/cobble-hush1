-- cobble hills UI (PRO FLY EDITION)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Config = getgenv().CobbleConfig

local Theme = {
    bg = Color3.fromRGB(15, 16, 20), sidebar = Color3.fromRGB(20, 21, 27),
    surface = Color3.fromRGB(30, 32, 40), text = Color3.fromRGB(220, 222, 230),
    muted = Color3.fromRGB(120, 126, 142), accent = Color3.fromRGB(90, 140, 255),
    off = Color3.fromRGB(45, 48, 56)
}

local function Tween(inst, props, time)
    TweenService:Create(inst, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad), props):Play()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "cobble_hush_ui"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = pcall(function() return gethui and gethui() end) and gethui() or game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(500, 420)
Main.Position = UDim2.new(0.5, -250, 0.5, -210)
Main.BackgroundColor3 = Theme.bg
Main.BorderSizePixel = 0
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Theme.sidebar
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "COBBLE.CC"
Title.TextColor3 = Theme.accent
Title.TextSize = 16
Title.Parent = Sidebar

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 1, -60)
TabContainer.Position = UDim2.new(0, 10, 0, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar
Instance.new("UIListLayout", TabContainer).Padding = UDim.new(0, 5)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -160, 1, -20)
ContentContainer.Position = UDim2.new(0, 150, 0, 10)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = Main

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, 0)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Theme.accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = ContentContainer
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 8)

local function MakeTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Theme.bg
    btn.Font = Enum.Font.GothamMedium
    btn.Text = text
    btn.TextColor3 = Theme.muted
    btn.TextSize = 13
    btn.Parent = TabContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local function MakeToggle(text, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = Scroll
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Theme.text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, 0, 0.5, 0)
    track.Size = UDim2.fromOffset(36, 18)
    track.BackgroundColor3 = Theme.off
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(14, 14)
    dot.Position = UDim2.fromOffset(2, 2)
    dot.BackgroundColor3 = Theme.muted
    dot.Parent = track
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    local function refresh()
        if get() then
            Tween(track, {BackgroundColor3 = Theme.accent})
            Tween(dot, {Position = UDim2.fromOffset(20, 2), BackgroundColor3 = Color3.new(1,1,1)})
        else
            Tween(track, {BackgroundColor3 = Theme.off})
            Tween(dot, {Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Theme.muted})
        end
    end
    btn.MouseButton1Click:Connect(function() set(not get()); refresh() end)
    refresh()
end

local function MakeButton(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 13
    btn.Text = text
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

local Tabs = { Visuals = MakeTab("Visuals"), Combat = MakeTab("Combat"), Utils = MakeTab("Utils") }

local function LoadTab(tabName)
    for _, v in ipairs(Scroll:GetChildren()) do if v:IsA("Frame") or v:IsA("TextButton") then v:Destroy() end end
    for name, btn in pairs(Tabs) do btn.TextColor3 = (name == tabName) and Theme.accent or Theme.muted end

    if tabName == "Visuals" then
        MakeToggle("ESP Enabled", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled = v end)
        MakeToggle("Jogadores", function() return Config.ESP.Players end, function(v) Config.ESP.Players = v end)
        MakeToggle("Monstros", function() return Config.ESP.Monsters end, function(v) Config.ESP.Monsters = v end)
    elseif tabName == "Combat" then
        MakeToggle("Aimbot Enabled", function() return Config.Aimbot.Enabled end, function(v) Config.Aimbot.Enabled = v end)
        MakeToggle("Wall Check", function() return Config.Aimbot.WallCheck end, function(v) Config.Aimbot.WallCheck = v end)
        local tBtn = Instance.new("TextButton")
        tBtn.Size = UDim2.new(1, 0, 0, 35)
        tBtn.BackgroundColor3 = Theme.surface
        tBtn.Text = "Alvo: " .. Config.Aimbot.Target
        tBtn.TextColor3 = Theme.text
        tBtn.Font = Enum.Font.Gotham
        tBtn.Parent = Scroll
        Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
        tBtn.MouseButton1Click:Connect(function()
            Config.Aimbot.Target = (Config.Aimbot.Target == "Listener") and "Hound" or ((Config.Aimbot.Target == "Hound") and "All" or "Listener")
            tBtn.Text = "Alvo: " .. Config.Aimbot.Target
        end)
    elseif tabName == "Utils" then
        -- NOVO: FLY HACK
        MakeToggle("Fly Hack (WASD + Space)", function() return Config.Fly.Enabled end, function(v) Config.Fly.Enabled = v end)
        MakeToggle("Silent Walk", function() return Config.Util.SilentWalk end, function(v) Config.Util.SilentWalk = v end)
        MakeToggle("Force Crouch", function() return Config.Util.ForceCrouch end, function(v) Config.Util.ForceCrouch = v end)
        MakeButton("UNLOAD SCRIPT", Color3.fromRGB(255, 80, 80), function()
            if getgenv().Cobble_Unload then getgenv().Cobble_Unload() end
            Gui:Destroy()
        end)
    end
end

Tabs.Visuals.MouseButton1Click:Connect(function() LoadTab("Visuals") end)
Tabs.Combat.MouseButton1Click:Connect(function() LoadTab("Combat") end)
Tabs.Utils.MouseButton1Click:Connect(function() LoadTab("Utils") end)
LoadTab("Visuals")

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Gui.Enabled = not Gui.Enabled end
end)
