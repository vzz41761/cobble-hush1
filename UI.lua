-- cobble hills UI (HUSH V7)
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
    Subtitle = "V7 ULTIMATE", 
    Icon = "crosshair", Logo = true, 
    Size = UDim2.fromOffset(500, 420), 
    ToggleKey = Enum.KeyCode.Insert, 
    Backdrop = "aurora" 
})

-- ==========================================
-- ABA 1: AIMBOT & TRIGGERBOT
-- ==========================================
local tabAim = Window:CreateTab({ Name = "AIMBOT", Icon = "crosshair" })
tabAim:SetColumns(2)

local secAim = tabAim:CreateSection({ Name = "Aimbot Settings" })
secAim:Toggle({ Name = "Ativar Aimbot", Default = true, Callback = function(v) Config.Aim.Enabled = v end })
secAim:Toggle({ Name = "Mostrar FOV", Default = true, Callback = function(v) Config.Aim.ShowFOV = v end })
secAim:Toggle({ Name = "Wall Check (Só Visível)", Default = true, Callback = function(v) Config.Aim.WallCheck = v end })
secAim:Toggle({ Name = "Team Check (Ignorar Aliados)", Default = true, Callback = function(v) Config.Aim.TeamCheck = v end })

local secTrigger = tabAim:CreateSection({ Name = "Triggerbot (Magic Bullet)" })
secTrigger:Toggle({ Name = "Magic Snap (Invisível)", Default = true, Callback = function(v) Config.Aim.MagicSnap = v end })
secTrigger:Toggle({ Name = "Auto-Fire (Atirar Auto)", Default = true, Callback = function(v) Config.Aim.AutoFire = v end })
secTrigger:Slider({ Name = "Delay do Tiro (s)", Min = 0.05, Max = 0.5, Default = 0.1, Decimals = 2, Step = 0.01, Callback = function(v) Config.Aim.FireDelay = v end })
secTrigger:Paragraph({ Name = "Como usar", Text = "Mantenha o botão direito (ou E) pressionado." })

local secTuning = tabAim:CreateSection({ Name = "Tuning" })
secTuning:Slider({ Name = "FOV (Raio)", Min = 5, Max = 400, Default = 60, Decimals = 0, Step = 1, Callback = function(v) Config.Aim.FOV = v end })
secTuning:Slider({ Name = "Suavidade (Visual)", Min = 0.05, Max = 1.0, Default = 0.45, Decimals = 2, Step = 0.01, Callback = function(v) Config.Aim.Smooth = v end })
secTuning:Slider({ Name = "Predição (s)", Min = 0.0, Max = 0.4, Default = 0.15, Decimals = 2, Step = 0.01, Callback = function(v) Config.Aim.Prediction = v end })
secTuning:Dropdown({ Name = "Parte do Corpo", Options = {"head", "chest"}, Default = "head", Callback = function(v) Config.Aim.Bone = v end })

-- ==========================================
-- ABA 2: ESP & LOOT
-- ==========================================
local tabEsp = Window:CreateTab({ Name = "ESP & LOOT", Icon = "eye" })
tabEsp:SetColumns(2)

local secEspP = tabEsp:CreateSection({ Name = "Jogadores & Walkers" })
secEspP:Toggle({ Name = "ESP Jogadores", Default = true, Callback = function(v) Config.ESP.Enabled = v end })
secEspP:Toggle({ Name = "Chams (Highlight)", Default = true, Callback = function(v) Config.ESP.Chams = v end })
secEspP:Toggle({ Name = "Arma na Mão", Default = true, Callback = function(v) Config.ESP.Weapon = v end })
secEspP:Toggle({ Name = "Walker ESP", Default = true, Callback = function(v) Config.ESP.Walker.Enabled = v end })
secEspP:Toggle({ Name = "Walker Health", Default = true, Callback = function(v) Config.ESP.Walker.Health = v end })

local secEspW = tabEsp:CreateSection({ Name = "Mundo & Extração" })
secEspW:Toggle({ Name = "Extração (Exits)", Default = true, Callback = function(v) Config.ESP.Extraction.Enabled = v end })
secEspW:Toggle({ Name = "Veículos", Default = true, Callback = function(v) Config.ESP.Vehicle.Enabled = v end })
secEspW:Toggle({ Name = "Sacos de Loot (Bags)", Default = true, Callback = function(v) Config.ESP.LootBag.Enabled = v end })
secEspW:Toggle({ Name = "World Finds", Default = true, Callback = function(v) Config.ESP.WorldFind.Enabled = v end })
secEspW:Toggle({ Name = "Corpos (Bodies)", Default = false, Callback = function(v) Config.ESP.Body.Enabled = v end })

local secLoot = tabEsp:CreateSection({ Name = "Containers (Loot)" })
secLoot:Toggle({ Name = "Loot ESP", Default = true, Callback = function(v) Config.Loot.Enabled = v end })
secLoot:Slider({ Name = "Alcance (m)", Min = 50, Max = 500, Default = 150, Decimals = 0, Step = 10, Callback = function(v) Config.Loot.MaxDist = v end })
secLoot:Toggle({ Name = "Tier 0 (Armas)", Default = true, Callback = function(v) Config.Loot.TierEnabled[0] = v end })
secLoot:Toggle({ Name = "Tier 1 (Médico/Tools)", Default = true, Callback = function(v) Config.Loot.TierEnabled[1] = v end })
secLoot:Toggle({ Name = "Tier 2 (Mobília)", Default = true, Callback = function(v) Config.Loot.TierEnabled[2] = v end })

-- ==========================================
-- ABA 3: UTILS E AMBIENTE
-- ==========================================
local tabUtils = Window:CreateTab({ Name = "UTILS", Icon = "settings" })
tabUtils:SetColumns(2)

local secUtil = tabUtils:CreateSection({ Name = "Movimento & Visão" })
secUtil:Toggle({ Name = "Fullbright (Tirar Escuro)", Default = false, Callback = function(v) Config.Util.Fullbright = v end })
secUtil:Toggle({ Name = "Night Vision", Default = false, Callback = function(v) Config.Util.NightVision = v end })
secUtil:Toggle({ Name = "Silent Walk (Passo Mudo)", Default = true, Callback = function(v) Config.Util.SilentWalk = v end })
secUtil:Toggle({ Name = "Prender Respiração", Default = false, Callback = function(v) Config.Util.Breath = v end })

local secAuto = tabUtils:CreateSection({ Name = "Auto-Pickup (Farm)" })
secAuto:Toggle({ Name = "Auto Pegar Loot", Default = false, Callback = function(v) Config.Util.AutoPickup = v end })
secAuto:Slider({ Name = "Raio de Coleta (m)", Min = 2, Max = 20, Default = 8, Decimals = 0, Step = 1, Callback = function(v) Config.AutoPickupRadius = v end })

local secHUD = tabUtils:CreateSection({ Name = "Interface (HUD)" })
secHUD:Toggle({ Name = "Ligar HUD", Default = true, Callback = function(v) Config.HUD.Enabled = v end })

-- ==========================================
-- ABA 4: AÇÕES MANUAIS (REMOTES)
-- ==========================================
local tabActions = Window:CreateTab({ Name = "AÇÕES", Icon = "zap" })
tabActions:SetColumns(2)

local secAct1 = tabActions:CreateSection({ Name = "Ações do Jogo" })
secAct1:Button({ Name = "Deploy / Respawn", Callback = function() if getgenv().Cobble_Deploy then getgenv().Cobble_Deploy() end end })
secAct1:Button({ Name = "Flashlight", Callback = function() if getgenv().Cobble_Flashlight then getgenv().Cobble_Flashlight() end end })
secAct1:Button({ Name = "Toggle Stance", Callback = function() if getgenv().Cobble_Stance then getgenv().Cobble_Stance(true) end end })
secAct1:Button({ Name = "Arrest (Surrender)", Callback = function() if getgenv().Cobble_Arrest then getgenv().Cobble_Arrest() end end })

local secAct2 = tabActions:CreateSection({ Name = "Forçar Ações (Bypass)" })
secAct2:Button({ Name = "Force Loot (takeAll)", Callback = function() if getgenv().Cobble_ForcePickup then getgenv().Cobble_ForcePickup() end end })
secAct2:Button({ Name = "Force Door (Abrir)", Callback = function() if getgenv().Cobble_ForceDoor then getgenv().Cobble_ForceDoor() end end })
secAct2:Button({ Name = "Force Vault (Pular)", Callback = function() if getgenv().Cobble_ForceVault then getgenv().Cobble_ForceVault(1,0,0) end end })

local secAct3 = tabActions:CreateSection({ Name = "Remotes Específicos" })
secAct3:Button({ Name = "Paper Map (Abrir)", Callback = function() if getgenv().Cobble_PaperMap then getgenv().Cobble_PaperMap(true) end end })
secAct3:Button({ Name = "Downed (Press)", Callback = function() if getgenv().Cobble_Downed then getgenv().Cobble_Downed(true) end end })
secAct3:Button({ Name = "Equip Sledgehammer", Callback = function() if getgenv().Cobble_Equip then getgenv().Cobble_Equip("sledgehammer") end end })

-- ==========================================
-- ABA 5: CONFIG
-- ==========================================
local tabConfig = Window:CreateTab({ Name = "CONFIG", Icon = "wrench" })
tabConfig:SetColumns(1)
tabConfig:CreateSection({ Name = "Sessão" }):Button({ Name = "UNLOAD SCRIPT", Icon = "trash-2", Callback = function()
    if getgenv().Cobble_Unload then getgenv().Cobble_Unload() end
    Window:Destroy(); S:Destroy(); S.Cleanup()
end })

getgenv().Cobble_UI_Loaded = Window
