-- cobble hills UI (HUSH V14)
local Players = game:GetService("Players")
local Config = getgenv().CobbleConfig
if not Config then return end

local SU = "https://raw.githubusercontent.com/PulseZax/Slate/refs/heads/main/.lua"
local ok, S = pcall(function() return loadstring(game:HttpGet(SU), "@Slate")() end)
if not ok or not S then return end

S.Theme.Preset("Violet")
S.Theme.Set({ Background = Color3.fromRGB(12, 11, 20), Surface = Color3.fromRGB(22, 19, 34), SurfaceAlt = Color3.fromRGB(31, 26, 46), Elevated = Color3.fromRGB(39, 31, 57), Accent = Color3.fromRGB(157, 105, 255), ToggleOn = Color3.fromRGB(157, 105, 255), Text = Color3.fromRGB(245, 242, 255), Muted = Color3.fromRGB(163, 154, 185), Radius = 12, RowHeight = 42, HeaderHeight = 56 })
pcall(function() S:SetFontFamily("Montserrat") end)

local Window = S:CreateWindow({ Name = "COBBLE <font color='#9D69FF'>HUSH</font>", Subtitle = "V14 IRONCLAD", Icon = "crosshair", Logo = true, Size = UDim2.fromOffset(500, 450), ToggleKey = Enum.KeyCode.Insert, Backdrop = "aurora" })

-- ABA 1: AIMBOT
local tabAim = Window:CreateTab({ Name = "AIMBOT", Icon = "crosshair" })
tabAim:SetColumns(2)
local secAim = tabAim:CreateSection({ Name = "Aimbot" })
secAim:Toggle({ Name = "Ativar Aimbot", Default = true, Callback = function(v) Config.Aimbot.Enabled = v end })
secAim:Toggle({ Name = "Silent Aim (Recomendado)", Default = true, Callback = function(v) Config.Aimbot.Silent = v end })
secAim:Toggle({ Name = "Wall Check", Default = true, Callback = function(v) Config.Aimbot.WallCheck = v end })
secAim:Toggle({ Name = "Party Check", Default = true, Callback = function(v) Config.Aimbot.PartyCheck = v end })
secAim:Slider({ Name = "FOV", Min = 10, Max = 400, Default = 120, Decimals = 0, Step = 1, Callback = function(v) Config.Aimbot.FOV = v end })
secAim:Slider({ Name = "Predição", Min = 0.0, Max = 0.4, Default = 0.15, Decimals = 2, Step = 0.01, Callback = function(v) Config.Aimbot.Prediction = v end })

-- ABA 2: VISUAIS
local tabEsp = Window:CreateTab({ Name = "ESP", Icon = "eye" })
tabEsp:SetColumns(2)
local secEsp = tabEsp:CreateSection({ Name = "ESP" })
secEsp:Toggle({ Name = "Players ESP", Default = true, Callback = function(v) Config.ESP.Players = v end })
secEsp:Toggle({ Name = "Walkers (Monstros)", Default = true, Callback = function(v) Config.ESP.Walkers = v end })
secEsp:Slider({ Name = "Distância Max", Min = 100, Max = 3000, Default = 1000, Decimals = 0, Step = 100, Callback = function(v) Config.ESP.MaxDist = v end })

-- ABA 3: UTILS
local tabUtils = Window:CreateTab({ Name = "UTILS", Icon = "activity" })
tabUtils:SetColumns(2)
local secUtil = tabUtils:CreateSection({ Name = "Mods" })
secUtil:Toggle({ Name = "Fullbright", Default = false, Callback = function(v) Config.Util.Fullbright = v end })
secUtil:Toggle({ Name = "No Grass", Default = false, Callback = function(v) Config.Util.NoGrass = v end })
secUtil:Toggle({ Name = "Infinite Stamina", Default = false, Callback = function(v) Config.Util.InfStamina = v end })
secUtil:Toggle({ Name = "No Recoil", Default = false, Callback = function(v) Config.Util.NoRecoil = v end })
secUtil:Toggle({ Name = "No Spread", Default = false, Callback = function(v) Config.Util.NoSpread = v end })

-- ABA 4: CONFIG
local tabConfig = Window:CreateTab({ Name = "CONFIG", Icon = "wrench" })
tabConfig:SetColumns(1)
tabConfig:CreateSection({ Name = "Sessão" }):Button({ Name = "UNLOAD SCRIPT", Icon = "trash-2", Callback = function()
    if getgenv().Cobble_Unload then getgenv().Cobble_Unload() end
    Window:Destroy(); S:Destroy(); S.Cleanup()
end })

getgenv().Cobble_UI_Loaded = Window
