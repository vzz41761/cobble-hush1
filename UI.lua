-- cobble hills UI (HUSH V12 - EXACT CLONE)
local Players = game:GetService("Players")
local Config = getgenv().CobbleConfig
if not Config then return end

local SU = "https://raw.githubusercontent.com/PulseZax/Slate/refs/heads/main/.lua"
local ok, S = pcall(function() return loadstring(game:HttpGet(SU), "@Slate")() end)
if not ok or not S then return end

S.Theme.Preset("Violet")
S.Theme.Set({ 
    Background = Color3.fromRGB(12, 11, 20), Surface = Color3.fromRGB(22, 19, 34), 
    SurfaceAlt = Color3.fromRGB(31, 26, 46), Elevated = Color3.fromRGB(39, 31, 57), 
    Accent = Color3.fromRGB(157, 105, 255), ToggleOn = Color3.fromRGB(157, 105, 255), 
    Text = Color3.fromRGB(245, 242, 255), Muted = Color3.fromRGB(163, 154, 185), 
    Radius = 12, RowHeight = 42, HeaderHeight = 56 
})
pcall(function() S:SetFontFamily("Montserrat") end)

local Window = S:CreateWindow({ 
    Name = "COBBLE <font color='#9D69FF'>HUSH</font>", 
    Subtitle = "V12 EXACT CLONE", 
    Icon = "crosshair", Logo = true, 
    Size = UDim2.fromOffset(520, 500), 
    ToggleKey = Enum.KeyCode.Insert, 
    Backdrop = "aurora" 
})

-- ==========================================
-- ABA 1: AIMBOT
-- ==========================================
local tabAim = Window:CreateTab({ Name = "AIMBOT", Icon = "crosshair" })
tabAim:SetColumns(2)

local secAim = tabAim:CreateSection({ Name = "Aimbot Settings" })
secAim:Toggle({ Name = "Ativar Aimbot", Default = false, Callback = function(v) Config.Aimbot.Enabled = v end })
secAim:Toggle({ Name = "Silent Aim (Invisível)", Default = false, Callback = function(v) Config.Aimbot.Silent = v end })
secAim:Toggle({ Name = "Sempre Ativo (Always On)", Default = false, Callback = function(v) Config.Aimbot.AlwaysOn = v end })
secAim:Toggle({ Name = "Wall Check", Default = true, Callback = function(v) Config.Aimbot.WallCheck = v end })
secAim:Toggle({ Name = "Party Check", Default = true, Callback = function(v) Config.Aimbot.PartyCheck = v end })
secAim:Slider({ Name = "FOV", Min = 5, Max = 400, Default = 180, Decimals = 0, Step = 1, Callback = function(v) Config.Aimbot.FOV = v end })
secAim:Slider({ Name = "Suavidade", Min = 1, Max = 25, Default = 8, Decimals = 0, Step = 1, Callback = function(v) Config.Aimbot.Smooth = v end })
secAim:Slider({ Name = "Predição", Min = 0.1, Max = 2.5, Default = 1.0, Decimals = 1, Step = 0.1, Callback = function(v) Config.Aimbot.Prediction = v end })
secAim:Dropdown({ Name = "Parte do Corpo", Options = {"Head", "Torso", "Nearest"}, Default = "Head", Callback = function(v) Config.Aimbot.TargetPart = v end })

local secFilter = tabAim:CreateSection({ Name = "Filtros Extras" })
secFilter:Toggle({ Name = "Car Cabin Aim (Blindados)", Default = true, Callback = function(v) Config.Aimbot.CarCabinAim = v end })
secFilter:Toggle({ Name = "Mirar em Downed", Default = false, Callback = function(v) Config.Aimbot.AimDowned = v end })
secFilter:Toggle({ Name = "Ignorar New Raiders (Alt)", Default = true, Callback = function(v) Config.Aimbot.IgnoreNewRaiders = v end })
secFilter:Toggle({ Name = "Ping Compensation", Default = true, Callback = function(v) Config.Aimbot.PingComp = v end })

-- ==========================================
-- ABA 2: MAIN / UTILS
-- ==========================================
local tabMain = Window:CreateTab({ Name = "MAIN", Icon = "activity" })
tabMain:SetColumns(2)

local secUtil = tabMain:CreateSection({ Name = "Utilitários" })
secUtil:Toggle({ Name = "Fullbright", Default = false, Callback = function(v) Config.Util.Fullbright = v end })
secUtil:Toggle({ Name = "No Grass", Default = false, Callback = function(v) Config.Util.NoGrass = v end })
secUtil:Toggle({ Name = "Infinite Stamina", Default = false, Callback = function(v) Config.Util.InfStamina = v end })
secUtil:Toggle({ Name = "Auto Hold Breath", Default = false, Callback = function(v) Config.Util.AutoHoldBreath = v end })
secUtil:Toggle({ Name = "Auto Heal", Default = false, Callback = function(v) Config.Util.AutoHeal = v end })
secUtil:Toggle({ Name = "Insta Interact", Default = false, Callback = function(v) Config.Util.InstaInteract = v end })
secUtil:Toggle({ Name = "Auto Hijack", Default = false, Callback = function(v) Config.Util.AutoHijack = v end })

local secHeal = tabMain:CreateSection({ Name = "Auto Heal Config" })
secHeal:Dropdown({ Name = "Prioridade de Cura", Options = {"Medkit", "Bandage", "Kit"}, Default = "Medkit", Callback = function(v) Config.Util.HealPriority = v end })
secHeal:Slider({ Name = "Threshold (%)", Min = 10, Max = 90, Default = 75, Decimals = 0, Step = 5, Callback = function(v) Config.Util.HealThreshold = v end })

local secMods = tabMain:CreateSection({ Name = "Weapon Mods" })
secMods:Toggle({ Name = "No Recoil", Default = false, Callback = function(v) Config.Util.NoRecoil = v end })
secMods:Toggle({ Name = "No Spread", Default = false, Callback = function(v) Config.Util.NoSpread = v end })

-- ==========================================
-- ABA 3: ESP
-- ==========================================
local tabEsp = Window:CreateTab({ Name = "ESP", Icon = "eye" })
tabEsp:SetColumns(2)

local secEspP = tabEsp:CreateSection({ Name = "Jogadores" })
secEspP:Toggle({ Name = "Players ESP", Default = false, Callback = function(v) Config.ESP.Players.Enabled = v end })
secEspP:Toggle({ Name = "Nome", Default = true, Callback = function(v) Config.ESP.Players.Name = v end })
secEspP:Toggle({ Name = "Distância", Default = true, Callback = function(v) Config.ESP.Players.Distance = v end })
secEspP:Toggle({ Name = "Hide Teammates", Default = false, Callback = function(v) Config.ESP.Players.HideTeammates = v end })
secEspP:Slider({ Name = "Distância Max", Min = 100, Max = 3000, Default = 2000, Decimals = 0, Step = 100, Callback = function(v) Config.ESP.Players.MaxDist = v end })

local secEspW = tabEsp:CreateSection({ Name = "Mundo" })
secEspW:Toggle({ Name = "Loot Bags", Default = false, Callback = function(v) Config.ESP.LootBags.Enabled = v end })
secEspW:Toggle({ Name = "Airdrops", Default = false, Callback = function(v) Config.ESP.Airdrops.Enabled = v end })
secEspW:Toggle({ Name = "Containers", Default = false, Callback = function(v) Config.ESP.Containers.Enabled = v end })
secEspW:Toggle({ Name = "Safes", Default = false, Callback = function(v) Config.ESP.Safes.Enabled = v end })
secEspW:Toggle({ Name = "Items Soltos", Default = false, Callback = function(v) Config.ESP.Items.Enabled = v end })
secEspW:Toggle({ Name = "Eventos (Frag/Heli)", Default = false, Callback = function(v) Config.ESP.Events.Enabled = v end })

local secEspDetail = tabEsp:CreateSection({ Name = "Detalhes do Loot" })
secEspDetail:Toggle({ Name = "Loot Names", Default = true, Callback = function(v) 
    Config.ESP.LootBags.Name = v; Config.ESP.Airdrops.Name = v; Config.ESP.Containers.Name = v; Config.ESP.Safes.Name = v; Config.ESP.Items.Name = v
end })
secEspDetail:Toggle({ Name = "Loot Distance", Default = true, Callback = function(v) 
    Config.ESP.LootBags.Distance = v; Config.ESP.Airdrops.Distance = v; Config.ESP.Containers.Distance = v; Config.ESP.Safes.Distance = v; Config.ESP.Items.Distance = v
end })
secEspDetail:Toggle({ Name = "Hide Opened (Só Vazio)", Default = true, Callback = function(v) 
    Config.ESP.LootBags.HideOpened = v; Config.ESP.Airdrops.HideOpened = v; Config.ESP.Containers.HideOpened = v; Config.ESP.Safes.HideOpened = v
end })

-- ==========================================
-- ABA 4: CONFIG
-- ==========================================
local tabConfig = Window:CreateTab({ Name = "CONFIG", Icon = "wrench" })
tabConfig:SetColumns(1)

local secSess = tabConfig:CreateSection({ Name = "Sessão" })
secSess:Button({ Name = "UNLOAD SCRIPT", Icon = "trash-2", Callback = function()
    if getgenv().Cobble_Unload then getgenv().Cobble_Unload() end
    Window:Destroy(); S:Destroy(); S.Cleanup()
end })

getgenv().Cobble_UI_Loaded = Window
