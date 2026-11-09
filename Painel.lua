--[[
    NOTURNO HUB - PAINEL PRINCIPAL
    Versão: 0.9.9

    Novidades v0.9.9:
    - ✅ Save system agora salva/carrega configurações das extensões
      (Combat, Troll, Farm) via registry _G.NoturnoHub_Extensions

    Herdado v0.9.8:
    - Anti-Fling portado do Mario Hub
    - Contador de moedas usa emoji 💲
    - FIX: TpToMap não teleporta mais para o lobby / fora do mapa
    - ABOUT: 4 indicadores (47%, alinhados à direita)
    - Card criador (94% centralizado)
]]

local HUB_NAME = "NOTURNO HUB"
local HUB_VERSION = "0.9.9"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local DURACAO = 5
local FADE = 0.5

-- ========== TEMAS ==========
local Themes = {
    Noturno = { Main = Color3.fromRGB(28,22,40), Header = Color3.fromRGB(58,38,92), Button = Color3.fromRGB(48,36,72), Track = Color3.fromRGB(90,70,130), Accent = Color3.fromRGB(160,120,255), Text = Color3.fromRGB(235,225,255) },
    Neon = { Main = Color3.fromRGB(20,14,30), Header = Color3.fromRGB(120,60,200), Button = Color3.fromRGB(60,30,100), Track = Color3.fromRGB(180,120,255), Accent = Color3.fromRGB(220,140,255), Text = Color3.fromRGB(245,235,255) },
    Midnight = { Main = Color3.fromRGB(18,18,36), Header = Color3.fromRGB(40,40,90), Button = Color3.fromRGB(35,35,70), Track = Color3.fromRGB(70,70,130), Accent = Color3.fromRGB(120,140,255), Text = Color3.fromRGB(225,230,255) },
    Void = { Main = Color3.fromRGB(12,10,18), Header = Color3.fromRGB(35,20,55), Button = Color3.fromRGB(28,20,42), Track = Color3.fromRGB(65,45,95), Accent = Color3.fromRGB(150,100,255), Text = Color3.fromRGB(220,210,240) },
    ["Blood Moon"] = { Main = Color3.fromRGB(25,0,0), Header = Color3.fromRGB(120,0,0), Button = Color3.fromRGB(50,0,0), Track = Color3.fromRGB(80,0,0), Accent = Color3.fromRGB(255,10,10), Text = Color3.fromRGB(255,180,180) },
    Christmas = { Main = Color3.fromRGB(5,25,10), Header = Color3.fromRGB(15,80,30), Button = Color3.fromRGB(10,50,20), Track = Color3.fromRGB(150,20,20), Accent = Color3.fromRGB(255,50,50), Text = Color3.fromRGB(200,255,200) },
    Halloween = { Main = Color3.fromRGB(15,5,20), Header = Color3.fromRGB(60,10,80), Button = Color3.fromRGB(30,5,40), Track = Color3.fromRGB(120,60,0), Accent = Color3.fromRGB(255,120,0), Text = Color3.fromRGB(255,220,150) },
    Valentine = { Main = Color3.fromRGB(45,5,25), Header = Color3.fromRGB(120,20,60), Button = Color3.fromRGB(70,10,40), Track = Color3.fromRGB(180,40,90), Accent = Color3.fromRGB(255,105,180), Text = Color3.fromRGB(255,210,230) }
}

local CurrentTheme = "Noturno"
local ThemePreviews = { Noturno = Color3.fromRGB(160,120,255), Neon = Color3.fromRGB(220,140,255), Midnight = Color3.fromRGB(120,140,255), Void = Color3.fromRGB(150,100,255), ["Blood Moon"] = Color3.fromRGB(255,10,10), Christmas = Color3.fromRGB(255,50,50), Halloween = Color3.fromRGB(255,120,0), Valentine = Color3.fromRGB(255,105,180) }

-- ========== SETTINGS ==========
local Settings = {
    WalkSpeed = 16, JumpPower = 50, FlySpeed = 50,
    Noclip = false, AntiFling = false, AntiAfk = false,
    FlyEnabled = false, InfJump = false, LimitInfJump = false,
    WalkSpeedEnabled = false, JumpPowerEnabled = false,
    ESP_Players = false, ESP_Gun = false, ESP_Coin = false,
    XRay = false, Fullbright = false,
    FlingVelocityCap = 120, FlingAngularCap = 10
}

-- ========== VARIÁVEIS GLOBAIS ==========
local FlyVelocity, FlyGyro, FlyConnection
local AntiFlingConnection, AntiAfkConnection, InfJumpConnection
local OriginalCollision = {}
local InfJumpCount = 0
local LastJumpTime = 0
local FlingSavedCollide = {}
local SteppedConnections = {}
local XRayOriginal = {}
local XRayConnection
local FullbrightOriginal = nil
local RoleCache = {}
local ESPObjects = {}
local ESPGun = { Target = nil, Highlight = nil, Billboard = nil }
local ESPCoins = {}
local RoleFetchBusy = false
local LastRoleFetch = 0
local RoleFetchStart = 0
local SavedWaypoint = nil
local ToggleButtons = {}
local ResetAllToggles = nil

-- ✅ Registry global pra extensões (SAVE SYSTEM)
_G.NoturnoHub_Extensions = _G.NoturnoHub_Extensions or {}
_G.NoturnoHub_LastLoaded = _G.NoturnoHub_LastLoaded or nil

-- ========== UTIL ==========
local function Create(className, properties, parent)
    local obj = Instance.new(className)
    for k,v in pairs(properties) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local old = PlayerGui:FindFirstChild("NoturnoHub")
if old then old:Destroy() end
local oldLoader = PlayerGui:FindFirstChild("NoturnoLoader")
if oldLoader then oldLoader:Destroy() end

-- ============================================================
-- LOADER
-- ============================================================
local LoaderGui = Create("ScreenGui", { Name = "NoturnoLoader", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
local bg = Create("Frame", { Name = "BG", Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.fromRGB(15,10,20), BorderSizePixel = 0 }, LoaderGui)
Create("TextLabel", { Size = UDim2.new(1,0,0,60), Position = UDim2.new(0,0,0.5,-50), BackgroundTransparency = 1, Text = "🌙 " .. HUB_NAME, TextColor3 = Color3.fromRGB(160,120,255), TextSize = 36, Font = Enum.Font.GothamBold }, bg)
Create("TextLabel", { Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0.5,10), BackgroundTransparency = 1, Text = "Carregando...", TextColor3 = Color3.fromRGB(235,225,255), TextSize = 18, Font = Enum.Font.Gotham }, bg)
local barBg = Create("Frame", { Size = UDim2.new(0,300,0,12), Position = UDim2.new(0.5,-150,0.5,60), BackgroundColor3 = Color3.fromRGB(48,36,72), BorderSizePixel = 0 }, bg)
Create("UICorner", { CornerRadius = UDim.new(1,0) }, barBg)
local barFill = Create("Frame", { Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.fromRGB(160,120,255), BorderSizePixel = 0 }, barBg)
Create("UICorner", { CornerRadius = UDim.new(1,0) }, barFill)
TweenService:Create(barFill, TweenInfo.new(DURACAO,Enum.EasingStyle.Linear), {Size = UDim2.new(1,0,1,0)}):Play()

-- ============================================================
-- PAINEL
-- ============================================================
local ScreenGui = Create("ScreenGui", { Name = "NoturnoHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
local Theme = Themes[CurrentTheme]

local Main = Create("Frame", {
    Name = "Main",
    Size = UserInputService.TouchEnabled and UDim2.new(0.96,0,0.85,0) or UDim2.fromOffset(600,500),
    Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5),
    BackgroundColor3 = Theme.Main, BorderSizePixel = 0, Active = true, Visible = false, ZIndex = 1
}, ScreenGui)
Create("UISizeConstraint", { MinSize = Vector2.new(320,350), MaxSize = Vector2.new(600,520) }, Main)
Create("UICorner", { CornerRadius = UDim.new(0,14) }, Main)
Create("UIStroke", { Color = Theme.Accent, Thickness = 1.5, Transparency = 0.55 }, Main)

local Header = Create("Frame", { Name = "Header", Size = UDim2.new(1,0,0,58), BackgroundColor3 = Theme.Header, BorderSizePixel = 0, Active = true, ZIndex = 10 }, Main)
Create("UICorner", { CornerRadius = UDim.new(0,14) }, Header)
local DragBlock = Create("TextButton", { Name = "DragBlock", Size = UDim2.new(1,-100,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 11 }, Header)
Create("TextLabel", { Size = UDim2.new(1,-110,1,0), Position = UDim2.fromOffset(16,0), BackgroundTransparency = 1, Text = "🌙 " .. HUB_NAME, TextColor3 = Theme.Text, TextSize = 17, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 }, Header)
local Minimize = Create("TextButton", { Size = UDim2.fromOffset(34,30), Position = UDim2.new(1,-84,0,14), BackgroundColor3 = Theme.Button, Text = "—", TextColor3 = Theme.Text, TextSize = 20, Font = Enum.Font.GothamBold, ZIndex = 13 }, Header)
Create("UICorner", { CornerRadius = UDim.new(0,8) }, Minimize)
local CloseBtn = Create("TextButton", { Size = UDim2.fromOffset(34,30), Position = UDim2.new(1,-46,0,14), BackgroundColor3 = Color3.fromRGB(180,50,70), Text = "✕", TextColor3 = Color3.new(1,1,1), TextSize = 18, Font = Enum.Font.GothamBold, ZIndex = 13 }, Header)
Create("UICorner", { CornerRadius = UDim.new(0,8) }, CloseBtn)
local Floating = Create("TextButton", { Name = "FloatingButton", Size = UDim2.fromOffset(45,45), AnchorPoint = Vector2.new(0.5,0), Position = UDim2.new(0.5,0,0,6), BackgroundColor3 = Theme.Header, Text = "🌙", TextSize = 24, TextColor3 = Theme.Text, Visible = false, Active = true, ZIndex = 50 }, ScreenGui)
Create("UICorner", { CornerRadius = UDim.new(1,0) }, Floating)
Create("UIStroke", { Color = Theme.Accent, Thickness = 1.5, Transparency = 0.4 }, Floating)

-- ========== CONTADOR DE MOEDAS ==========
local CoinCounterFrame = Create("Frame", {
    Name = "CoinCounter", Size = UDim2.fromOffset(120, 40),
    Position = UDim2.new(1, -140, 1, -60),
    BackgroundColor3 = Color3.fromRGB(20, 20, 25), BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Visible = false, ZIndex = 100
}, ScreenGui)
Create("UICorner", { CornerRadius = UDim.new(0, 8) }, CoinCounterFrame)
Create("UIStroke", { Color = Color3.fromRGB(255, 215, 0), Thickness = 1.5, Transparency = 0.3 }, CoinCounterFrame)
local CoinCounterText = Create("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Text = "💲 Moedas: 0", TextColor3 = Color3.fromRGB(255, 215, 0),
    TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center
}, CoinCounterFrame)

-- ========== ARRASTAR MAIN ==========
local dragging, dragStart, startPos = false,nil,nil
DragBlock.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
DragBlock.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ========== ARRASTAR FLOATING ==========
local floatingDragging, floatingStart, floatingStartPos = false, nil, nil
Floating.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatingDragging = true; floatingStart = input.Position; floatingStartPos = Floating.Position
    end
end)
Floating.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then floatingDragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if floatingDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - floatingStart
        Floating.Position = UDim2.new(floatingStartPos.X.Scale, floatingStartPos.X.Offset + delta.X, floatingStartPos.Y.Scale, floatingStartPos.Y.Offset + delta.Y)
    end
end)

Minimize.MouseButton1Click:Connect(function() Main.Visible = false; Floating.Visible = true end)
Floating.MouseButton1Click:Connect(function() Main.Visible = true; Floating.Visible = false end)

-- ============================================================
-- ESP
-- ============================================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local Gameplay = Remotes and Remotes:FindFirstChild("Gameplay")
local RoleRemote = Gameplay and Gameplay:FindFirstChild("GetCurrentPlayerData")
local RoundStart = Gameplay and Gameplay:FindFirstChild("RoundStart")

local RoleColors = {
    Innocent = Color3.fromRGB(0,255,70), Murderer = Color3.fromRGB(255,35,35),
    Sheriff = Color3.fromRGB(40,130,255), Hero = Color3.fromRGB(0,255,255),
    Dead = Color3.fromRGB(50,50,50), Unknown = Color3.fromRGB(255,255,255)
}

local function NormalizeRole(role)
    local value = string.lower(tostring(role or ""))
    if value:find("murder") or value == "assassino" then return "Murderer" end
    if value:find("sheriff") or value == "xerife" then return "Sheriff" end
    if value:find("hero") or value == "heroi" then return "Hero" end
    if value:find("dead") or value == "morto" then return "Dead" end
    if value:find("innocent") or value == "inocente" then return "Innocent" end
    return nil
end

local function RefreshRoles(force)
    if RoleFetchBusy then
        if os.clock() - RoleFetchStart > 5 then RoleFetchBusy = false else return end
    end
    if not force and os.clock() - LastRoleFetch < 3 then return end
    LastRoleFetch = os.clock()
    if not RoleRemote or not RoleRemote.Parent then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local gameplay = remotes and remotes:FindFirstChild("Gameplay")
        RoleRemote = gameplay and gameplay:FindFirstChild("GetCurrentPlayerData")
    end
    if not RoleRemote or not RoleRemote:IsA("RemoteFunction") then return end
    RoleFetchBusy = true
    RoleFetchStart = os.clock()
    task.spawn(function()
        local success, roster = pcall(function() return RoleRemote:InvokeServer() end)
        if success and type(roster) == "table" then RoleCache = roster end
        RoleFetchBusy = false
    end)
end

local function GetPlayerTool(player, name)
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    return (character and character:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
end

local function GetRole(player)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return "Dead" end
    local entry = RoleCache[player.Name] or RoleCache[player.UserId] or RoleCache[tostring(player.UserId)]
    if type(entry) == "table" then
        if entry.Dead then return "Dead" end
        local role = NormalizeRole(entry.Role or entry.role)
        if role then return role end
    elseif type(entry) == "string" then
        local role = NormalizeRole(entry)
        if role then return role end
    end
    if GetPlayerTool(player, "Knife") then return "Murderer" end
    if GetPlayerTool(player, "Gun") or GetPlayerTool(player, "Revolver") then return "Sheriff" end
    return "Unknown"
end

local function RemoveESP(player)
    local objects = ESPObjects[player]
    if objects then
        if objects.Highlight then objects.Highlight:Destroy() end
        if objects.Billboard then objects.Billboard:Destroy() end
        ESPObjects[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not character or not head then return end
    RemoveESP(player)
    local role = GetRole(player)
    local color = RoleColors[role] or RoleColors.Unknown
    local highlight = Instance.new("Highlight")
    highlight.Name = "KittyESP"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color; highlight.OutlineColor = color
    highlight.FillTransparency = 0.55; highlight.OutlineTransparency = 0
    highlight.Parent = ScreenGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KittyESPInfo"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(180,45)
    billboard.StudsOffset = Vector3.new(0,3,0)
    billboard.AlwaysOnTop = true
    billboard.Parent = ScreenGui
    local label = Create("TextLabel", {
        Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
        Text = player.Name.." ["..role.."]", TextColor3 = color,
        TextStrokeTransparency = 0.25, TextStrokeColor3 = Color3.new(0,0,0),
        TextSize = 13, Font = Enum.Font.GothamBold
    }, billboard)
    ESPObjects[player] = { Highlight = highlight, Billboard = billboard, Label = label, Character = character }
end

local function UpdateESP()
    if not Settings.ESP_Players then return end
    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local head = character and character:FindFirstChild("Head")
            if head then
                local objects = ESPObjects[player]
                if not objects or objects.Character ~= character or not objects.Highlight or not objects.Highlight.Parent then
                    CreateESP(player)
                else
                    local role = GetRole(player)
                    local color = RoleColors[role] or RoleColors.Unknown
                    objects.Highlight.FillColor = color
                    objects.Highlight.OutlineColor = color
                    if objects.Label then
                        objects.Label.Text = player.Name.." ["..role.."]"
                        objects.Label.TextColor3 = color
                    end
                end
            else
                RemoveESP(player)
            end
        end
    end
end

local function EnableESP(enabled)
    if enabled then RefreshRoles(true); UpdateESP()
    else for player in pairs(ESPObjects) do RemoveESP(player) end end
end

local function RemoveGunDropESP()
    if ESPGun.Highlight then ESPGun.Highlight:Destroy(); ESPGun.Highlight = nil end
    if ESPGun.Billboard then ESPGun.Billboard:Destroy(); ESPGun.Billboard = nil end
    ESPGun.Target = nil
end

local function GetGunAdornee(target)
    if not target then return nil end
    if target:IsA("BasePart") then return target end
    if target:IsA("Model") then return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true) end
    return target:FindFirstChildWhichIsA("BasePart", true)
end

local function UpdateGunDropESP()
    if not Settings.ESP_Gun then
        if ESPGun.Target then RemoveGunDropESP() end
        return
    end
    local drop = workspace:FindFirstChild("GunDrop", true)
    if drop == ESPGun.Target and ESPGun.Highlight and ESPGun.Highlight.Parent then return end
    RemoveGunDropESP()
    if not drop then return end
    local adornee = GetGunAdornee(drop)
    if not adornee then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "HelloKittyGunDropESP"
    highlight.Adornee = drop
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
    highlight.FillTransparency = 0.35; highlight.OutlineTransparency = 0
    highlight.Parent = ScreenGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HelloKittyGunDropLabel"
    billboard.Adornee = adornee
    billboard.Size = UDim2.fromOffset(130, 32)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = ScreenGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
    label.Text = "GUN DROP"; label.TextColor3 = Color3.fromRGB(0, 255, 255)
    label.TextStrokeColor3 = Color3.new(0, 0, 0); label.TextStrokeTransparency = 0.15
    label.Font = Enum.Font.GothamBold; label.TextSize = 14
    label.Parent = billboard
    ESPGun.Target = drop; ESPGun.Highlight = highlight; ESPGun.Billboard = billboard
end

local function EnableGunESP(state)
    Settings.ESP_Gun = state
    if state then UpdateGunDropESP() else RemoveGunDropESP() end
end

local function RemoveCoinESP()
    for coin, objects in pairs(ESPCoins) do
        if objects.Highlight then objects.Highlight:Destroy() end
    end
    table.clear(ESPCoins)
    CoinCounterFrame.Visible = false
end

local function IsCoin(part)
    if not part or not part.Parent or not part:IsA("BasePart") then return false end
    if part:GetAttribute("Collected") == true then return false end
    if part.Name == "Coin" then return true end
    if part:FindFirstChild("CoinVisual") then return true end
    if part:FindFirstChild("Visual") then return true end
    if part.Name:lower():find("coin") then return true end
    return false
end

local function GetCoinContainer()
    local map = workspace:FindFirstChild("Map")
    local container = map and map:FindFirstChild("CoinContainer")
    if not container then container = workspace:FindFirstChild("CoinContainer", true) end
    return container
end

local function UpdateCoinESP()
    if not Settings.ESP_Coin then
        if next(ESPCoins) then RemoveCoinESP() end
        return
    end
    local container = GetCoinContainer()
    if not container then
        if next(ESPCoins) then RemoveCoinESP() end
        return
    end
    local currentCoins = {}
    local coinCount = 0
    for _, coin in ipairs(container:GetDescendants()) do
        if IsCoin(coin) then
            currentCoins[coin] = true
            coinCount = coinCount + 1
            if not ESPCoins[coin] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "CoinESP"
                highlight.Adornee = coin
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.FillColor = Color3.fromRGB(255, 215, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                highlight.FillTransparency = 0.4; highlight.OutlineTransparency = 0
                highlight.Parent = ScreenGui
                ESPCoins[coin] = { Highlight = highlight }
            end
        end
    end
    CoinCounterFrame.Visible = true
    CoinCounterText.Text = "💲 Moedas: " .. coinCount
    for coin, objects in pairs(ESPCoins) do
        if not currentCoins[coin] or not coin.Parent then
            if objects.Highlight then objects.Highlight:Destroy() end
            ESPCoins[coin] = nil
        end
    end
end

local function EnableCoinESP(state)
    Settings.ESP_Coin = state
    if state then UpdateCoinESP() else RemoveCoinESP() end
end

-- ============================================================
-- X-RAY / FULLBRIGHT
-- ============================================================
local function IsPlayerCharacterPart(part)
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and part:IsDescendantOf(character) then return true end
    end
    return false
end

local function ApplyXRay(part)
    if not part:IsA("BasePart") then return end
    if IsPlayerCharacterPart(part) then return end
    if XRayOriginal[part] == nil then XRayOriginal[part] = part.LocalTransparencyModifier end
    part.LocalTransparencyModifier = 0.65
end

local function EnableXRay(state)
    Settings.XRay = state
    if XRayConnection then XRayConnection:Disconnect(); XRayConnection = nil end
    if state then
        for _, part in ipairs(workspace:GetDescendants()) do ApplyXRay(part) end
        XRayConnection = workspace.DescendantAdded:Connect(function(part)
            task.defer(function() if Settings.XRay and part.Parent then ApplyXRay(part) end end)
        end)
    else
        for part, original in pairs(XRayOriginal) do
            if part and part.Parent then part.LocalTransparencyModifier = original end
        end
        table.clear(XRayOriginal)
    end
end

local function EnableFullbright(state)
    Settings.Fullbright = state
    if state then
        if not FullbrightOriginal then
            FullbrightOriginal = {
                ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness,
                Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
                GlobalShadows = Lighting.GlobalShadows, ExposureCompensation = Lighting.ExposureCompensation
            }
        end
        Lighting.ClockTime = 14; Lighting.Brightness = 3
        Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.GlobalShadows = false; Lighting.ExposureCompensation = 0.3
    else
        if FullbrightOriginal then
            for property, value in pairs(FullbrightOriginal) do Lighting[property] = value end
            FullbrightOriginal = nil
        end
    end
end

-- ============================================================
-- TELEPORTE
-- ============================================================
local TeleportStatus
local function SetTPStatus(msg) if TeleportStatus and TeleportStatus.Parent then TeleportStatus.Text = "Status: " .. msg end end

local function DoTeleport(targetPos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then SetTPStatus("Personagem não encontrado."); return false end
    if not targetPos then SetTPStatus("Destino inválido."); return false end
    local tempNoclip = false
    if not Settings.Noclip then
        tempNoclip = true
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if OriginalCollision[part] == nil then OriginalCollision[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end
    root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    if tempNoclip then
        task.delay(0.3, function()
            if not Settings.Noclip then
                for part, orig in pairs(OriginalCollision) do
                    if part and part.Parent then part.CanCollide = orig end
                end
                table.clear(OriginalCollision)
            end
        end)
    end
    return true
end

local function TpToPlayer(player)
    if not player or player == LocalPlayer then SetTPStatus("Jogador inválido."); return end
    local char = player.Character
    local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not targetRoot then SetTPStatus("Jogador não spawnou ainda."); return end
    if DoTeleport(targetRoot.Position) then SetTPStatus("Teleportado para " .. player.Name .. ".") end
end

local function TpToMurderer()
    RefreshRoles(true); task.wait(0.5)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetRole(p) == "Murderer" then
            TpToPlayer(p); SetTPStatus("TP para o Murderer (" .. p.Name .. ")."); return
        end
    end
    SetTPStatus("Murderer não encontrado.")
end

local function TpToSheriff()
    RefreshRoles(true); task.wait(0.5)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetRole(p) == "Sheriff" then
            TpToPlayer(p); SetTPStatus("TP para o Xerife (" .. p.Name .. ")."); return
        end
    end
    SetTPStatus("Xerife não encontrado.")
end

local function TpToLobby()
    local lobbyPos
    local lobby = workspace:FindFirstChild("Lobby")
    if not lobby then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:lower() == "lobby" then lobby = obj; break end
        end
    end
    if lobby then
        if lobby:IsA("Model") then
            if lobby.PrimaryPart then lobbyPos = lobby.PrimaryPart.Position
            else
                local part = lobby:FindFirstChildWhichIsA("BasePart", true)
                if part then lobbyPos = part.Position end
            end
        elseif lobby:IsA("BasePart") then lobbyPos = lobby.Position end
    end
    if not lobbyPos then
        local map = workspace:FindFirstChild("Map")
        for _, sl in ipairs(workspace:GetDescendants()) do
            if sl:IsA("SpawnLocation") then
                if not (map and sl:IsDescendantOf(map)) then lobbyPos = sl.Position; break end
            end
        end
    end
    if not lobbyPos then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then lobbyPos = root.Position end
    end
    if not lobbyPos then SetTPStatus("Lobby não encontrado."); return end
    if DoTeleport(lobbyPos) then SetTPStatus("Teleportado para o lobby.") end
end

local function TpToMap()
    local lobbyPos = nil
    local lobbyObj = workspace:FindFirstChild("Lobby")
    if lobbyObj then
        if lobbyObj:IsA("Model") and lobbyObj.PrimaryPart then
            lobbyPos = lobbyObj.PrimaryPart.Position
        else
            local lp = lobbyObj:FindFirstChildWhichIsA("BasePart", true)
            if lp then lobbyPos = lp.Position end
        end
    end
    local bestPlayer, bestDist = nil, 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c = p.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local dist = lobbyPos and (r.Position - lobbyPos).Magnitude or 1e9
                if dist > bestDist then bestDist = dist; bestPlayer = p end
            end
        end
    end
    if bestPlayer and (not lobbyPos or bestDist > 60) then
        local r = bestPlayer.Character and bestPlayer.Character:FindFirstChild("HumanoidRootPart")
        if r and DoTeleport(r.Position) then SetTPStatus("TP para o mapa (via " .. bestPlayer.Name .. ")."); return end
    end
    local mapContainer = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Maps") or workspace:FindFirstChild("CurrentMap")
    if not mapContainer then
        for _, obj in ipairs(workspace:GetChildren()) do
            if (obj:IsA("Folder") or obj:IsA("Model")) and obj.Name:lower():find("^map") then mapContainer = obj; break end
        end
    end
    local mapModel = nil
    if mapContainer then
        if mapContainer:IsA("Model") then mapModel = mapContainer
        elseif mapContainer:IsA("Folder") then
            for _, child in ipairs(mapContainer:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") then mapModel = child; break end
            end
        end
    end
    if not mapModel then
        local blacklist = { ["Lobby"] = true, ["Players"] = true, ["Terrain"] = true, ["Camera"] = true }
        local biggest, biggestSize = nil, 0
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and not blacklist[obj.Name] then
                local isChar = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == obj then isChar = true; break end
                end
                if not isChar then
                    local ok, _, size = pcall(function() return obj:GetBoundingBox() end)
                    if ok and size then
                        local volume = size.X * size.Y * size.Z
                        if volume > biggestSize then biggest, biggestSize = obj, volume end
                    end
                end
            end
        end
        mapModel = biggest
    end
    if not mapModel then SetTPStatus("Mapa não encontrado."); return end
    local spawnPos = nil
    for _, obj in ipairs(mapModel:GetDescendants()) do
        if obj:IsA("SpawnLocation") and obj.Transparency < 1 then spawnPos = obj.Position; break end
    end
    if not spawnPos then
        for _, obj in ipairs(mapModel:GetDescendants()) do
            if obj.Name == "HumanoidRootPart" and obj:IsA("BasePart") then spawnPos = obj.Position; break end
        end
    end
    if not spawnPos and mapModel:IsA("Model") and mapModel.PrimaryPart then
        local pp = mapModel.PrimaryPart
        if pp.Position.Y > -50 then spawnPos = pp.Position end
    end
    if not spawnPos then
        local ok, cf, size = pcall(function() return mapModel:GetBoundingBox() end)
        if ok and cf and size then spawnPos = cf.Position + Vector3.new(0, size.Y * 0.4, 0) end
    end
    if not spawnPos then SetTPStatus("Não foi possível localizar um ponto no mapa."); return end
    if DoTeleport(spawnPos) then SetTPStatus("Teleportado para o mapa do round.") end
end

local function SaveWaypoint()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then SetTPStatus("Personagem não encontrado."); return end
    SavedWaypoint = root.Position
    SetTPStatus(string.format("Waypoint salvo (%.0f, %.0f, %.0f).", SavedWaypoint.X, SavedWaypoint.Y, SavedWaypoint.Z))
end

local function TpToWaypoint()
    if not SavedWaypoint then SetTPStatus("Nenhum waypoint salvo."); return end
    if DoTeleport(SavedWaypoint) then SetTPStatus("Teleportado para o waypoint.") end
end

local function ClearWaypoint() SavedWaypoint = nil; SetTPStatus("Waypoint limpo.") end

-- ============================================================
-- UNLOAD
-- ============================================================
local function UnloadHub()
    Settings.FlyEnabled = false
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if FlyVelocity then FlyVelocity:Destroy(); FlyVelocity = nil end
    if FlyGyro then FlyGyro:Destroy(); FlyGyro = nil end
    Settings.Noclip = false
    for part, orig in pairs(OriginalCollision) do
        if part and part.Parent then part.CanCollide = orig end
    end
    table.clear(OriginalCollision)
    Settings.AntiFling = false
    if AntiFlingConnection then AntiFlingConnection:Disconnect(); AntiFlingConnection = nil end
    for part, orig in pairs(FlingSavedCollide) do
        if part and part.Parent then part.CanCollide = orig end
    end
    table.clear(FlingSavedCollide)
    Settings.AntiAfk = false
    if AntiAfkConnection then AntiAfkConnection:Disconnect(); AntiAfkConnection = nil end
    Settings.InfJump = false
    if InfJumpConnection then InfJumpConnection:Disconnect(); InfJumpConnection = nil end
    for _, conn in ipairs(SteppedConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    table.clear(SteppedConnections)
    EnableXRay(false)
    EnableFullbright(false)
    Settings.ESP_Players = false
    for player in pairs(ESPObjects) do RemoveESP(player) end
    Settings.ESP_Gun = false; RemoveGunDropESP()
    Settings.ESP_Coin = false; RemoveCoinESP()
    if ResetAllToggles then ResetAllToggles() end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false; hum.AutoRotate = true
        hum.WalkSpeed = 16; hum.UseJumpPower = true; hum.JumpPower = 50
    end
    ScreenGui:Destroy()
    if LoaderGui then LoaderGui:Destroy() end
    print("[" .. HUB_NAME .. "] Hub desexecutado.")
end

local ClosePending = false
local CloseTimeout = nil
CloseBtn.MouseButton1Click:Connect(function()
    if not ClosePending then
        ClosePending = true; CloseBtn.Text = "?"; CloseBtn.BackgroundColor3 = Color3.fromRGB(120,25,55)
        CloseTimeout = task.delay(3,function()
            if ClosePending and CloseBtn and CloseBtn.Parent then
                ClosePending = false; CloseBtn.Text = "✕"; CloseBtn.BackgroundColor3 = Color3.fromRGB(180,50,70)
            end
        end)
        return
    end
    ClosePending = false
    if CloseTimeout then pcall(function() task.cancel(CloseTimeout) end) end
    UnloadHub()
end)

-- ============================================================
-- ABAS
-- ============================================================
local Sidebar = Create("ScrollingFrame", { Name = "Sidebar", Size = UDim2.new(0,160,1,-78), Position = UDim2.fromOffset(8,70), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = Theme.Accent, ZIndex = 2 }, Main)
Create("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder }, Sidebar)
local PagesContainer = Create("Frame", { Name = "PagesContainer", Size = UDim2.new(1,-182,1,-80), Position = UDim2.fromOffset(174,70), BackgroundTransparency = 1, ZIndex = 2 }, Main)

local Pages = {}
local TabButtons = {}

local function CreatePage(name)
    local page = Create("ScrollingFrame", { Name = name, Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ScrollBarImageColor3 = Theme.Accent }, PagesContainer)
    Create("UIPadding", { PaddingRight = UDim.new(0,6), PaddingTop = UDim.new(0,2) }, page)
    local rowsContainer = Create("Frame", { Name = "Rows", Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, page)
    Create("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder }, rowsContainer)
    Pages[name] = { Page = page, Rows = rowsContainer }
    return Pages[name]
end

local function SelectPage(name)
    for pageName,data in pairs(Pages) do data.Page.Visible = pageName == name end
    for tabName,button in pairs(TabButtons) do
        button.BackgroundTransparency = tabName == name and 0 or 0.6
        button.TextTransparency = tabName == name and 0 or 0.2
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Transparency = tabName == name and 0.3 or 0.7 end
    end
end

local function CreateTab(name,label)
    local button = Create("TextButton", { Size = UDim2.new(1,0,0,30), BackgroundColor3 = Theme.Button, BackgroundTransparency = 0.6, Text = label, TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, Sidebar)
    Create("UICorner", { CornerRadius = UDim.new(0,9) }, button)
    Create("UIPadding", { PaddingLeft = UDim.new(0,12) }, button)
    Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.7 }, button)
    TabButtons[name] = button
    button.MouseButton1Click:Connect(function() SelectPage(name) end)
end

local PlayerPage = CreatePage("PLAYER")
local VisualsPage = CreatePage("VISUALS")
local CombatPage = CreatePage("COMBATE")
local TrollPage = CreatePage("TROLL")
local TeleportPage = CreatePage("TELEPORTE")
local FarmPage = CreatePage("FARM")
local ConfigPage = CreatePage("CONFIGURACAO")
local AboutPage = CreatePage("ABOUT")

CreateTab("PLAYER","👤  PLAYER")
CreateTab("VISUALS","👁  VISUALS")
CreateTab("COMBATE","🎯  COMBATE")
CreateTab("TROLL","😈  TROLL")
CreateTab("TELEPORTE","📍  TELEPORTE")
CreateTab("FARM","💰  FARM")
CreateTab("CONFIGURACAO","⚙  CONFIG")
CreateTab("ABOUT","ℹ  ABOUT")
SelectPage("PLAYER")

-- ============================================================
-- BOTÕES E SLIDERS
-- ============================================================
local SliderObjects = {}
ResetAllToggles = function()
    for key, item in pairs(ToggleButtons) do
        if Settings[key] ~= nil then
            Settings[key] = false
            item.Update(false)
        end
    end
end

local function AddButton(page,text,callback)
    local button = Create("TextButton", { Size = UDim2.new(1,-6,0,30), BackgroundColor3 = Theme.Button, Text = text, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold }, page)
    Create("UICorner", { CornerRadius = UDim.new(0,7) }, button)
    button.MouseButton1Click:Connect(callback)
    return button
end

local function AddSlider(page,title,setting,minimum,maximum,step)
    local frame = Create("Frame", { Name = "SliderContainer", Size = UDim2.new(1,-6,0,55), BackgroundColor3 = Theme.Button, BorderSizePixel = 0 }, page)
    Create("UICorner", { CornerRadius = UDim.new(0,7) }, frame)
    local label = Create("TextLabel", { Size = UDim2.new(1,-16,0,22), Position = UDim2.fromOffset(8,2), BackgroundTransparency = 1, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, frame)
    local bar = Create("Frame", { Name = "SliderBackground", Size = UDim2.new(1,-20,0,8), Position = UDim2.fromOffset(10,35), BackgroundColor3 = Theme.Track, BorderSizePixel = 0, Active = true }, frame)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, bar)
    local fill = Create("Frame", { Name = "SliderFill", Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 }, bar)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, fill)
    local knob = Create("Frame", { Name = "SliderKnob", Size = UDim2.fromOffset(16,16), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,0,0.5,0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 }, bar)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, knob)
    local sliderDragging = false
    local function Update(value)
        value = math.clamp(value,minimum,maximum); value = math.floor(value / step + 0.5) * step
        Settings[setting] = math.clamp(value,minimum,maximum)
        local percent = (Settings[setting]-minimum)/(maximum-minimum)
        fill.Size = UDim2.new(percent,0,1,0); knob.Position = UDim2.new(percent,0,0.5,0)
        label.Text = title .. ": " .. tostring(Settings[setting])
    end
    local function UpdateFromInput(input)
        if bar.AbsoluteSize.X <= 0 then return end
        local percent = math.clamp((input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        Update(minimum+(maximum-minimum)*percent)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = true; UpdateFromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateFromInput(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliderDragging = false end
    end)
    table.insert(SliderObjects,{ Frame = frame, Bar = bar, Fill = fill, Knob = knob, Setting = setting, Set = Update, Minimum = minimum, Maximum = maximum, Step = step })
    Update(Settings[setting])
    return frame
end

local function CreateCustomToggle(page, title, setting, callback)
    local row = Create("Frame", { Name = "FarmToggleRow", Size = UDim2.new(1,-6,0,34), BackgroundColor3 = Theme.Button, BorderSizePixel = 0 }, page.Rows)
    Create("UICorner", { CornerRadius = UDim.new(0,7) }, row)
    Create("TextLabel", { Size = UDim2.new(1,-60,1,0), Position = UDim2.fromOffset(10,0), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local track = Create("Frame", { Name = "ToggleTrack", Size = UDim2.fromOffset(36,20), Position = UDim2.new(1,-46,0.5,-10), BackgroundColor3 = Settings[setting] and Theme.Header or Theme.Track, BorderSizePixel = 0 }, row)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, track)
    local knob = Create("Frame", { Name = "ToggleKnob", Size = UDim2.fromOffset(14,14), Position = Settings[setting] and UDim2.new(1,-17,0,3) or UDim2.fromOffset(3,3), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 }, track)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, knob)
    local hitbox = Create("TextButton", { Name = "ToggleHitbox", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, row)
    local function updateVisual(enabled)
        track.BackgroundColor3 = enabled and Theme.Header or Theme.Track
        knob.Position = enabled and UDim2.new(1,-17,0,3) or UDim2.fromOffset(3,3)
    end
    hitbox.MouseButton1Click:Connect(function()
        local newState = not Settings[setting]
        Settings[setting] = newState
        updateVisual(newState)
        callback(newState)
    end)
    ToggleButtons[setting] = { Row = row, Update = updateVisual, Callback = callback }
    return row
end

-- ========== ABA PLAYER ==========
CreateCustomToggle(PlayerPage, "Noclip","Noclip",function(state)
    if not state then
        for part,orig in pairs(OriginalCollision) do
            if part and part.Parent then part.CanCollide = orig end
        end
        table.clear(OriginalCollision)
    end
end)

CreateCustomToggle(PlayerPage, "Anti-Fling","AntiFling",function(state)
    if AntiFlingConnection then AntiFlingConnection:Disconnect(); AntiFlingConnection = nil end
    if state then
        AntiFlingConnection = RunService.Stepped:Connect(function()
            if not Settings.AntiFling then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local character = player.Character
                if not character then continue end
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        if FlingSavedCollide[part] == nil then FlingSavedCollide[part] = part.CanCollide end
                        part.CanCollide = false
                    end
                end
            end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local v = root.AssemblyLinearVelocity
            if v.Magnitude > Settings.FlingVelocityCap then root.AssemblyLinearVelocity = v.Unit * Settings.FlingVelocityCap end
            local w = root.AssemblyAngularVelocity
            if w.Magnitude > Settings.FlingAngularCap then root.AssemblyAngularVelocity = w.Unit * Settings.FlingAngularCap end
        end)
    else
        for part, original in pairs(FlingSavedCollide) do
            if part and part.Parent then part.CanCollide = original end
        end
        table.clear(FlingSavedCollide)
    end
end)

CreateCustomToggle(PlayerPage, "Anti-AFK","AntiAfk",function(state)
    if state then
        if not AntiAfkConnection then
            AntiAfkConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    else
        if AntiAfkConnection then AntiAfkConnection:Disconnect(); AntiAfkConnection = nil end
    end
end)

local DefaultWalkSpeed = 16
local DefaultJumpPower = 50
task.spawn(function()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.5)
        DefaultWalkSpeed = hum.WalkSpeed
        DefaultJumpPower = hum.JumpPower
    end
end)

CreateCustomToggle(PlayerPage, "Ativar WalkSpeed","WalkSpeedEnabled",function(state)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = state and Settings.WalkSpeed or DefaultWalkSpeed end
end)

local WalkSpeedSlider = AddSlider(PlayerPage.Rows, "WalkSpeed", "WalkSpeed", 16, 120, 1)
WalkSpeedSlider.LayoutOrder = 5

local JumpPowerToggle = CreateCustomToggle(PlayerPage, "Ativar JumpPower","JumpPowerEnabled",function(state)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true; hum.JumpPower = state and Settings.JumpPower or DefaultJumpPower end
end)
JumpPowerToggle.LayoutOrder = 6

local JumpPowerSlider = AddSlider(PlayerPage.Rows, "JumpPower", "JumpPower", 50, 120, 1)
JumpPowerSlider.LayoutOrder = 7

-- FLY
local function StopFly()
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if FlyVelocity then FlyVelocity:Destroy(); FlyVelocity = nil end
    if FlyGyro then FlyGyro:Destroy(); FlyGyro = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false; hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function StartFly()
    StopFly()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand = true; hum.AutoRotate = false
    FlyVelocity = Instance.new("BodyVelocity"); FlyVelocity.MaxForce = Vector3.new(1e6,1e6,1e6); FlyVelocity.P = 12500; FlyVelocity.Velocity = Vector3.zero; FlyVelocity.Parent = root
    FlyGyro = Instance.new("BodyGyro"); FlyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6); FlyGyro.P = 15000; FlyGyro.D = 1000; FlyGyro.CFrame = Camera.CFrame; FlyGyro.Parent = root
    FlyConnection = RunService.Heartbeat:Connect(function()
        if not Settings.FlyEnabled then StopFly(); return end
        if not root.Parent or not hum.Parent then StopFly(); return end
        Camera = workspace.CurrentCamera
        local moveDir = hum.MoveDirection
        local look = Camera.CFrame.LookVector
        local velocity = Vector3.zero
        if moveDir.Magnitude > 0.01 then
            local flatLook = Vector3.new(look.X,0,look.Z)
            local alignment = 0
            if flatLook.Magnitude > 0.001 then alignment = math.abs(moveDir:Dot(flatLook.Unit)) end
            velocity = Vector3.new(moveDir.X * Settings.FlySpeed, look.Y * Settings.FlySpeed * alignment, moveDir.Z * Settings.FlySpeed)
        end
        FlyVelocity.Velocity = velocity
        FlyGyro.CFrame = CFrame.new(root.Position,root.Position + look)
    end)
end

local FlyToggle = CreateCustomToggle(PlayerPage, "Fly","FlyEnabled",function(state)
    if state then StartFly() else StopFly() end
end)
FlyToggle.LayoutOrder = 8

local FlySpeedSlider = AddSlider(PlayerPage.Rows, "Fly Speed", "FlySpeed", 10, 350, 10)
FlySpeedSlider.LayoutOrder = 9

-- INFINITE JUMP
CreateCustomToggle(PlayerPage, "Infinite Jump","InfJump",function(state)
    if state then
        if InfJumpConnection then InfJumpConnection:Disconnect() end
        InfJumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and Settings.InfJump then
                if os.clock() - LastJumpTime < 0.1 then return end
                LastJumpTime = os.clock()
                local st = hum:GetState()
                local noChao = (st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.RunningNoPhysics)
                if noChao then InfJumpCount = 1; return end
                if Settings.LimitInfJump then
                    if InfJumpCount < 2 then hum:ChangeState(Enum.HumanoidStateType.Jumping); InfJumpCount += 1 end
                else hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    else
        if InfJumpConnection then InfJumpConnection:Disconnect(); InfJumpConnection = nil end
    end
end).LayoutOrder = 10

local LimitInfJumpToggle = CreateCustomToggle(PlayerPage, "Limitar Inf Jump (2x)","LimitInfJump",function(state) end)
LimitInfJumpToggle.LayoutOrder = 11

table.insert(SteppedConnections, RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics then
            InfJumpCount = 0
        end
    end
end))

table.insert(SteppedConnections, RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if Settings.WalkSpeedEnabled and hum.WalkSpeed ~= Settings.WalkSpeed then hum.WalkSpeed = Settings.WalkSpeed end
        if Settings.JumpPowerEnabled then
            hum.UseJumpPower = true
            if hum.JumpPower ~= Settings.JumpPower then hum.JumpPower = Settings.JumpPower end
        end
        if Settings.Noclip then
            for _,part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if OriginalCollision[part] == nil then OriginalCollision[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        end
    end
end))

-- ========== ABA VISUALS ==========
CreateCustomToggle(VisualsPage, "ESP Player","ESP_Players",function(state) EnableESP(state) end)
CreateCustomToggle(VisualsPage, "ESP Gun","ESP_Gun",function(state) EnableGunESP(state) end)
CreateCustomToggle(VisualsPage, "ESP Coin","ESP_Coin",function(state) EnableCoinESP(state) end)
CreateCustomToggle(VisualsPage, "X-Ray","XRay",function(state) EnableXRay(state) end)
CreateCustomToggle(VisualsPage, "FullBright","Fullbright",function(state) EnableFullbright(state) end)

-- ========== ABA TELEPORTE ==========
TeleportStatus = Create("TextLabel", {
    Size = UDim2.new(1,-6,0,34), BackgroundTransparency = 1,
    Text = "Status: Pronto.", TextColor3 = Theme.Text, TextSize = 10,
    Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left
}, TeleportPage.Rows)

Create("TextLabel", {
    Size = UDim2.new(1,-6,0,20), BackgroundTransparency = 1,
    Text = "👤 Teleportar para jogador", TextColor3 = Theme.Text,
    TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left
}, TeleportPage.Rows)

local PlayerListBtn = AddButton(TeleportPage.Rows, "Selecionar jogador  ▼", function() end)
local PlayerList = Create("Frame", { Size = UDim2.new(1,-6,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, TeleportPage.Rows)
Create("UIListLayout", { Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder }, PlayerList)

local SelectedPlayer = nil
local function RefreshPlayerList()
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local players = Players:GetPlayers()
    for i, p in ipairs(players) do
        if p ~= LocalPlayer then
            local btn = Create("TextButton", {
                Size = UDim2.new(1,0,0,26), BackgroundColor3 = Theme.Track,
                Text = p.Name, TextColor3 = Theme.Text, TextSize = 11,
                Font = Enum.Font.Gotham, LayoutOrder = i
            }, PlayerList)
            Create("UICorner", { CornerRadius = UDim.new(0,6) }, btn)
            btn.MouseButton1Click:Connect(function()
                SelectedPlayer = p
                PlayerListBtn.Text = "Jogador: " .. p.Name .. "  ▼"
                PlayerList.Visible = false
                SetTPStatus("Selecionado: " .. p.Name)
            end)
        end
    end
end

PlayerListBtn.MouseButton1Click:Connect(function()
    RefreshPlayerList()
    PlayerList.Visible = not PlayerList.Visible
end)

AddButton(TeleportPage.Rows, "📍 Teleportar para jogador selecionado", function()
    if not SelectedPlayer then SetTPStatus("Selecione um jogador primeiro."); return end
    TpToPlayer(SelectedPlayer)
end)
AddButton(TeleportPage.Rows, "🔪 Teleportar para o Murderer", function() TpToMurderer() end)
AddButton(TeleportPage.Rows, "🔫 Teleportar para o Xerife", function() TpToSheriff() end)
AddButton(TeleportPage.Rows, "🚪 Teleportar para o Lobby", function() TpToLobby() end)
AddButton(TeleportPage.Rows, "🗺 Teleportar para o Mapa (Round)", function() TpToMap() end)

Create("TextLabel", {
    Size = UDim2.new(1,-6,0,20), BackgroundTransparency = 1,
    Text = "📌 Waypoint", TextColor3 = Theme.Text,
    TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left
}, TeleportPage.Rows)

AddButton(TeleportPage.Rows, "💾 Salvar waypoint aqui", function() SaveWaypoint() end)
AddButton(TeleportPage.Rows, "🎯 Teleportar para waypoint", function() TpToWaypoint() end)
AddButton(TeleportPage.Rows, "🗑 Limpar waypoint", function() ClearWaypoint() end)

-- ============================================================
-- LOOPS ESP
-- ============================================================
task.spawn(function()
    while ScreenGui.Parent do
        if Settings.ESP_Gun then pcall(UpdateGunDropESP) end
        task.wait(0.5)
    end
    RemoveGunDropESP()
end)
task.spawn(function()
    while ScreenGui.Parent do
        if Settings.ESP_Coin then pcall(UpdateCoinESP) end
        task.wait(0.5)
    end
    RemoveCoinESP()
end)
task.spawn(function()
    while ScreenGui.Parent do
        if Settings.ESP_Players then pcall(UpdateESP) end
        task.wait(0.5)
    end
end)
task.spawn(function()
    while ScreenGui.Parent do
        if Settings.ESP_Players then pcall(RefreshRoles, false) end
        task.wait(3)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
    RoleCache[player.Name] = nil
    RoleCache[player.UserId] = nil
    if SelectedPlayer == player then
        SelectedPlayer = nil
        PlayerListBtn.Text = "Selecionar jogador  ▼"
    end
end)

Players.PlayerAdded:Connect(function()
    if PlayerList.Visible then RefreshPlayerList() end
end)

if RoundStart and RoundStart:IsA("RemoteEvent") then
    RoundStart.OnClientEvent:Connect(function()
        table.clear(RoleCache)
        if Settings.Fullbright then EnableFullbright(true) end
        if Settings.ESP_Players then
            task.delay(0.5, function() RefreshRoles(true); UpdateESP() end)
        end
    end)
end

-- ============================================================
-- ABA ABOUT
-- ============================================================
local function CreateVersionIndicator(index, layoutOrder)
    local card = Create("Frame", {
        Size = UDim2.new(0.47,0,0,70),
        BackgroundColor3 = Theme.Button,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder or index
    }, AboutPage.Rows)
    Create("UICorner", { CornerRadius = UDim.new(0,8) }, card)
    local stroke = Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.5 }, card)
    local title = nil
    local value = nil
    if index == 1 then
        title = Create("TextLabel", {
            Size = UDim2.new(1,0,0,26), Position = UDim2.fromOffset(0,12),
            BackgroundTransparency = 1, Text = "🌙 Painel HUB",
            TextColor3 = Theme.Text, TextSize = 14, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center
        }, card)
        value = Create("TextLabel", {
            Size = UDim2.new(1,0,0,20), Position = UDim2.fromOffset(0,38),
            BackgroundTransparency = 1, Text = "Versão: " .. HUB_VERSION,
            TextColor3 = Theme.Accent, TextSize = 12, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center
        }, card)
    end
    return card, stroke, title, value
end

local AboutRow1 = Create("Frame", {
    Size = UDim2.new(1,-12,0,70), BackgroundTransparency = 1, LayoutOrder = 900
}, AboutPage.Rows)
Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder
}, AboutRow1)

local VerCard1, VerStroke1, VerTitle1, VerValue1 = CreateVersionIndicator(1, 1)
VerCard1.Parent = AboutRow1
local VerCard2, VerStroke2, VerTitle2, VerValue2 = CreateVersionIndicator(2, 2)
VerCard2.Parent = AboutRow1

local AboutRow2 = Create("Frame", {
    Size = UDim2.new(1,-12,0,70), BackgroundTransparency = 1, LayoutOrder = 901
}, AboutPage.Rows)
Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder
}, AboutRow2)

local VerCard3, VerStroke3, VerTitle3, VerValue3 = CreateVersionIndicator(3, 3)
VerCard3.Parent = AboutRow2
local VerCard4, VerStroke4, VerTitle4, VerValue4 = CreateVersionIndicator(4, 4)
VerCard4.Parent = AboutRow2

local CREATOR_ID   = 493241893
local CREATOR_NAME = "Guilherme_FOX123"

Create("Frame", { Size = UDim2.new(1,0,0,10), BackgroundTransparency = 1, LayoutOrder = 902 }, AboutPage.Rows)

local CreatorWrapper = Create("Frame", {
    Size = UDim2.new(1,-12,0,80), BackgroundTransparency = 1, LayoutOrder = 903
}, AboutPage.Rows)

local CreatorCard = Create("Frame", {
    Size = UDim2.new(0.94,0,1,0), Position = UDim2.new(0.03,0,0,0),
    BackgroundColor3 = Theme.Header, BorderSizePixel = 0
}, CreatorWrapper)
Create("UICorner", { CornerRadius = UDim.new(0,10) }, CreatorCard)
local CreatorStroke = Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.4 }, CreatorCard)

local AvatarFrame = Create("Frame", {
    Size = UDim2.fromOffset(60,60), Position = UDim2.fromOffset(10,10),
    BackgroundColor3 = Theme.Main, BorderSizePixel = 0
}, CreatorCard)
Create("UICorner", { CornerRadius = UDim.new(1,0) }, AvatarFrame)
local AvatarStroke = Create("UIStroke", { Color = Theme.Accent, Thickness = 1.5, Transparency = 0.3 }, AvatarFrame)

local AvatarImage = Create("ImageLabel", {
    Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. CREATOR_ID .. "&w=150&h=150",
    ScaleType = Enum.ScaleType.Fit
}, AvatarFrame)
Create("UICorner", { CornerRadius = UDim.new(1,0) }, AvatarImage)

local CreatorTitle = Create("TextLabel", {
    Size = UDim2.new(1,-85,0,18), Position = UDim2.fromOffset(80,10),
    BackgroundTransparency = 1, Text = "👑  Criador",
    TextColor3 = Theme.Accent, TextSize = 11, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, CreatorCard)

local CreatorName = Create("TextLabel", {
    Size = UDim2.new(1,-85,0,24), Position = UDim2.fromOffset(80,30),
    BackgroundTransparency = 1, Text = CREATOR_NAME,
    TextColor3 = Theme.Text, TextSize = 17, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, CreatorCard)

local CreatorId = Create("TextLabel", {
    Size = UDim2.new(1,-85,0,16), Position = UDim2.fromOffset(80,56),
    BackgroundTransparency = 1, Text = "ID: " .. tostring(CREATOR_ID),
    TextColor3 = Theme.Accent, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, CreatorCard)

-- ============================================================
-- TEMAS
-- ============================================================
local ApplyTheme
local ThemeSelector, ThemeOptions
local ThemeOptionButtons = {}

ApplyTheme = function(name)
    local theme = Themes[name]
    if not theme then return end
    CurrentTheme = name; Theme = theme
    Main.BackgroundColor3 = theme.Main; Header.BackgroundColor3 = theme.Header
    Floating.BackgroundColor3 = theme.Header; Sidebar.ScrollBarImageColor3 = theme.Header
    Minimize.BackgroundColor3 = theme.Button
    local mainStroke = Main:FindFirstChildOfClass("UIStroke")
    if mainStroke then mainStroke.Color = theme.Accent end
    for _,button in pairs(TabButtons) do
        button.BackgroundColor3 = theme.Button
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = theme.Accent end
    end
    for _,data in pairs(Pages) do
        for _,object in ipairs(data.Page:GetDescendants()) do
            if object:IsA("UIStroke") then object.Color = theme.Accent
            elseif object:IsA("TextButton") then
                if object.BackgroundTransparency < 1 then object.BackgroundColor3 = theme.Button end
                object.TextColor3 = theme.Text
            elseif object:IsA("TextBox") then
                object.BackgroundColor3 = theme.Button; object.TextColor3 = theme.Text
            elseif object:IsA("Frame") and (object.Name == "SliderContainer" or object.Name == "FarmToggleRow") then
                object.BackgroundColor3 = theme.Button
            elseif object:IsA("Frame") and object.Name == "ToggleTrack" then
                local enabled = false
                for key, item in pairs(ToggleButtons) do
                    if item.Row == object.Parent then enabled = Settings[key] == true; break end
                end
                object.BackgroundColor3 = enabled and theme.Header or theme.Track
            elseif object:IsA("Frame") and object.Name == "ToggleKnob" then
                object.BackgroundColor3 = Color3.new(1,1,1)
            elseif object:IsA("TextLabel") then
                if object.TextColor3 ~= Color3.fromRGB(255,90,130) then object.TextColor3 = theme.Text end
            end
        end
    end
    if VerCard1 then VerCard1.BackgroundColor3 = theme.Button end
    if VerStroke1 then VerStroke1.Color = theme.Accent end
    if VerTitle1 then VerTitle1.TextColor3 = theme.Text end
    if VerValue1 then VerValue1.TextColor3 = theme.Accent end
    if VerCard2 then VerCard2.BackgroundColor3 = theme.Button end
    if VerStroke2 then VerStroke2.Color = theme.Accent end
    if VerCard3 then VerCard3.BackgroundColor3 = theme.Button end
    if VerStroke3 then VerStroke3.Color = theme.Accent end
    if VerCard4 then VerCard4.BackgroundColor3 = theme.Button end
    if VerStroke4 then VerStroke4.Color = theme.Accent end
    if CreatorCard then
        CreatorCard.BackgroundColor3 = theme.Header
        if CreatorStroke then CreatorStroke.Color = theme.Accent end
    end
    if AvatarFrame then AvatarFrame.BackgroundColor3 = theme.Main end
    if AvatarStroke then AvatarStroke.Color = theme.Accent end
    if CreatorTitle then CreatorTitle.TextColor3 = theme.Accent end
    if CreatorName then CreatorName.TextColor3 = theme.Text end
    if CreatorId then CreatorId.TextColor3 = theme.Accent end
    if ThemeSelector then ThemeSelector.Text = "Tema: " .. name .. "  ▼" end
    for tName,btn in pairs(ThemeOptionButtons) do
        local color = ThemePreviews[tName] or theme.Button
        btn.TextColor3 = color
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = color end
    end
    for key, item in pairs(ToggleButtons) do
        if item.Update then item.Update(Settings[key] == true) end
    end
end

-- ============================================================
-- CONFIG
-- ============================================================
local ConfigRows = ConfigPage.Rows
ThemeSelector = AddButton(ConfigRows, "Tema: " .. CurrentTheme .. "  ▼", function() ThemeOptions.Visible = not ThemeOptions.Visible end)
ThemeOptions = Create("Frame", { Name = "ThemeOptions", Size = UDim2.new(1,-6,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, ConfigRows)
Create("UIListLayout", { Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder }, ThemeOptions)

for _,themeName in ipairs({ "Noturno", "Neon", "Midnight", "Void", "Blood Moon", "Christmas", "Halloween", "Valentine" }) do
    local option = AddButton(ThemeOptions,themeName,function() ApplyTheme(themeName); ThemeOptions.Visible = false end)
    option.Size = UDim2.new(1,0,0,29)
    local previewColor = ThemePreviews[themeName] or Color3.new(1,1,1)
    option.TextColor3 = previewColor
    local stroke = option:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Color = previewColor end
    ThemeOptionButtons[themeName] = option
end

-- SISTEMA DE SALVAMENTO
local SaveFolder = "NoturnoHub"
local AutoLoadPath = SaveFolder .. "/autoload.txt"
local SelectedConfig = nil
local SaveStatus, ConfigList, ConfigNameBox, ConfigListBtn

local function FileSystemReady()
    return type(makefolder) == "function" and type(isfolder) == "function"
        and type(writefile) == "function" and type(readfile) == "function"
        and type(isfile) == "function" and type(listfiles) == "function" and type(delfile) == "function"
end

local function EnsureSaveFolder()
    if not FileSystemReady() then return false, "Executor sem suporte a arquivos." end
    local ok, err = pcall(function() if not isfolder(SaveFolder) then makefolder(SaveFolder) end end)
    if not ok then return false, tostring(err) end
    return true
end

local function CleanConfigName(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[^%w%s_%-]", "_"):gsub("%s+", "_")
    if name == "" then return nil end
    return name
end

local function ConfigPath(name) return SaveFolder .. "/" .. name .. ".json" end
local function SetSaveStatus(message) if SaveStatus and SaveStatus.Parent then SaveStatus.Text = "Status: " .. message end end

-- ✅ SNAPSHOT com extensões
local function MakeSnapshot()
    local data = { Version = 2, Theme = CurrentTheme, Settings = {}, Extensions = {} }
    for key, value in pairs(Settings) do
        if type(value) == "boolean" or type(value) == "number" then
            data.Settings[key] = value
        end
    end
    for extName, ext in pairs(_G.NoturnoHub_Extensions) do
        if type(ext) == "table" and type(ext.GetSettings) == "function" then
            local ok, s = pcall(ext.GetSettings)
            if ok and type(s) == "table" then
                local copy = {}
                for k, v in pairs(s) do
                    if type(v) == "boolean" or type(v) == "number" then
                        copy[k] = v
                    end
                end
                data.Extensions[extName] = copy
            end
        end
    end
    return data
end

local function SaveConfig(name)
    local ok, err = EnsureSaveFolder()
    if not ok then SetSaveStatus(err); return false end
    name = CleanConfigName(name)
    if not name then SetSaveStatus("Digite um nome valido."); return false end
    local encodedOk, contents = pcall(function() return HttpService:JSONEncode(MakeSnapshot()) end)
    if not encodedOk then SetSaveStatus("Erro ao preparar configuracao."); return false end
    local writeOk, writeErr = pcall(writefile, ConfigPath(name), contents)
    if not writeOk then SetSaveStatus("Falha ao salvar: " .. tostring(writeErr)); return false end
    SelectedConfig = name; SetSaveStatus("Configuracao '" .. name .. "' salva!")
    return true
end

local function LoadConfig(name)
    local ok, err = EnsureSaveFolder()
    if not ok then SetSaveStatus(err); return false end
    name = CleanConfigName(name)
    if not name or not isfile(ConfigPath(name)) then SetSaveStatus("Configuracao nao encontrada."); return false end
    local readOk, contents = pcall(readfile, ConfigPath(name))
    if not readOk then SetSaveStatus("Nao foi possivel ler o arquivo."); return false end
    local decodeOk, data = pcall(function() return HttpService:JSONDecode(contents) end)
    if not decodeOk or type(data) ~= "table" or type(data.Settings) ~= "table" then SetSaveStatus("Arquivo de configuracao invalido."); return false end
    for _, slider in ipairs(SliderObjects) do
        local value = data.Settings[slider.Setting]
        if type(value) == "number" then slider.Set(value) end
    end
    for key, item in pairs(ToggleButtons) do
        if Settings[key] == true and item.Callback then pcall(item.Callback, false) end
        Settings[key] = false; item.Update(false)
    end
    local order = {
        "AntiFling", "AntiAfk", "Noclip",
        "WalkSpeedEnabled", "JumpPowerEnabled",
        "FlyEnabled", "InfJump", "LimitInfJump",
        "XRay", "Fullbright",
        "ESP_Players", "ESP_Gun", "ESP_Coin"
    }
    for _, key in ipairs(order) do
        local item = ToggleButtons[key]; local value = data.Settings[key]
        if item and type(value) == "boolean" then
            Settings[key] = value; item.Update(value)
            if item.Callback then pcall(item.Callback, value) end
        end
    end
    if type(data.Theme) == "string" and Themes[data.Theme] then ApplyTheme(data.Theme) end

    -- ✅ APLICA EXTENSÕES
    if type(data.Extensions) == "table" then
        _G.NoturnoHub_LastLoaded = data.Extensions
        local applied = 0
        for extName, extData in pairs(data.Extensions) do
            local ext = _G.NoturnoHub_Extensions[extName]
            if ext and type(ext.SetSettings) == "function" then
                local okExt = pcall(ext.SetSettings, extData)
                if okExt then applied = applied + 1 end
            end
        end
        print("[" .. HUB_NAME .. "] Extensões carregadas: " .. applied .. "/" .. #(function() local t={} for k in pairs(data.Extensions) do t[#t+1]=k end return t end)())
    end

    SelectedConfig = name; SetSaveStatus("'" .. name .. "' carregada!")
    return true
end

local function RefreshConfigs()
    local ok, err = EnsureSaveFolder()
    if not ok then SetSaveStatus(err); return end
    if ConfigList then
        for _, child in ipairs(ConfigList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
    end
    local found = {}
    local listOk, files = pcall(listfiles, SaveFolder)
    if listOk and type(files) == "table" then
        for _, path in ipairs(files) do
            local base = tostring(path):match("([^/\\]+)%.json$")
            if base then table.insert(found, base) end
        end
    end
    table.sort(found)
    for i, name in ipairs(found) do
        local entry = AddButton(ConfigList, name, function()
            SelectedConfig = name; ConfigNameBox.Text = name
            ConfigListBtn.Text = "Salvo: " .. name .. "  ▼"; ConfigList.Visible = false
            SetSaveStatus("Selecionada: " .. name)
        end)
        entry.Size = UDim2.new(1, 0, 0, 27); entry.LayoutOrder = i
    end
    SetSaveStatus(#found .. " configuracao(oes) encontrada(s).")
end

Create("TextLabel", { Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1, Text = "💾 SALVAMENTO", TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, ConfigRows)
local inputRow = Create("Frame", { Size = UDim2.new(1,-6,0,34), BackgroundTransparency = 1 }, ConfigRows)
ConfigNameBox = Create("TextBox", { Size = UDim2.new(1,-75,1,0), BackgroundColor3 = Theme.Button, TextColor3 = Theme.Text, PlaceholderText = "Nome...", PlaceholderColor3 = Color3.fromRGB(235,220,230), Text = "", TextSize = 12, Font = Enum.Font.Gotham, ClearTextOnFocus = false }, inputRow)
Create("UICorner", { CornerRadius = UDim.new(0,7) }, ConfigNameBox)
local btnSave = Create("TextButton", { Size = UDim2.new(0,70,1,0), Position = UDim2.new(1,-70,0,0), BackgroundColor3 = Color3.fromRGB(60,160,90), Text = "Salvar", TextColor3 = Color3.new(1,1,1), TextSize = 11, Font = Enum.Font.GothamBold }, inputRow)
Create("UICorner", { CornerRadius = UDim.new(0,7) }, btnSave)
btnSave.MouseButton1Click:Connect(function() SaveConfig(ConfigNameBox.Text); RefreshConfigs() end)

ConfigListBtn = AddButton(ConfigRows, "Nenhuma config salva  ▼", function() RefreshConfigs(); ConfigList.Visible = not ConfigList.Visible end)
ConfigList = Create("Frame", { Size = UDim2.new(1,-6,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, ConfigRows)
Create("UIListLayout", { Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder }, ConfigList)

AddButton(ConfigRows, "📂  Carregar configuracao", function() LoadConfig(ConfigNameBox.Text ~= "" and ConfigNameBox.Text or SelectedConfig) end)
AddButton(ConfigRows, "🗑  Excluir configuracao", function()
    local ok, err = EnsureSaveFolder()
    if not ok then SetSaveStatus(err); return end
    local name = CleanConfigName(ConfigNameBox.Text ~= "" and ConfigNameBox.Text or SelectedConfig)
    if not name or not isfile(ConfigPath(name)) then SetSaveStatus("Configuracao nao encontrada."); return end
    local deleted, deleteErr = pcall(delfile, ConfigPath(name))
    if deleted then
        if SelectedConfig == name then SelectedConfig = nil end
        SetSaveStatus("Configuracao excluida."); RefreshConfigs()
    else SetSaveStatus("Falha ao excluir: " .. tostring(deleteErr)) end
end)
AddButton(ConfigRows, "⭐  Definir Auto Load", function()
    local ok, err = EnsureSaveFolder()
    if not ok then SetSaveStatus(err); return end
    local name = CleanConfigName(ConfigNameBox.Text ~= "" and ConfigNameBox.Text or SelectedConfig)
    if not name or not isfile(ConfigPath(name)) then SetSaveStatus("Salve ou selecione uma config primeiro."); return end
    local wrote, writeErr = pcall(writefile, AutoLoadPath, name)
    if wrote then SetSaveStatus("'" .. name .. "' sera carregada ao iniciar!") else SetSaveStatus("Falha no Auto Load: " .. tostring(writeErr)) end
end)
AddButton(ConfigRows, "🚫  Remover Auto Load", function()
    if type(isfile) == "function" and type(delfile) == "function" and isfile(AutoLoadPath) then pcall(delfile, AutoLoadPath) end
    SetSaveStatus("Carregamento automatico removido.")
end)

SaveStatus = Create("TextLabel", { Size = UDim2.new(1,-6,0,34), BackgroundTransparency = 1, Text = "Status: Pronto.", TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }, ConfigRows)
AddButton(ConfigRows, "🔄  Atualizar lista", function() RefreshConfigs() end)

local UnloadBtn = AddButton(ConfigRows, "⏻  Desexecutar Hub", function() UnloadHub() end)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(150,40,70)
Create("UIStroke", { Color = Color3.fromRGB(255,90,130), Thickness = 1.2 }, UnloadBtn)

-- INICIALIZAÇÃO
if type(isfile) == "function" and type(readfile) == "function" and isfile(AutoLoadPath) then
    local ok, name = pcall(readfile, AutoLoadPath)
    if ok and type(name) == "string" then task.wait(0.5); LoadConfig(name) end
end

RefreshConfigs()
task.wait(DURACAO)
Main.Visible = true
local fadeTween = TweenService:Create(bg, TweenInfo.new(FADE,Enum.EasingStyle.Linear), {BackgroundTransparency = 1})
for _,obj in ipairs(bg:GetDescendants()) do
    if obj:IsA("TextLabel") then TweenService:Create(obj, TweenInfo.new(FADE), {TextTransparency = 1}):Play() end
    if obj:IsA("Frame") then TweenService:Create(obj, TweenInfo.new(FADE), {BackgroundTransparency = 1}):Play() end
end
fadeTween:Play()
fadeTween:Completed:Wait()
LoaderGui:Destroy()
print("[" .. HUB_NAME .. "] v" .. HUB_VERSION .. " carregado!")
print("[Save] Registry de extensões inicializado — pronto pra receber Combat/Troll/Farm")
