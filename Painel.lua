--[[
    NOTURNO HUB - v0.5.7
    - FIX: AutoFarm não farma mais na entrada atrasada (aguarda a próxima rodada).
    - Adicionada verificação de função (Role) antes de mover o personagem.
]]

local HUB_NAME = "NOTURNO HUB"
local HUB_VERSION = "0.5.7"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DURACAO = 5
local FADE = 0.5

-- ========== TEMAS ==========
local Themes = {
    Noturno = { Main = Color3.fromRGB(28, 22, 40), Header = Color3.fromRGB(58, 38, 92), Button = Color3.fromRGB(48, 36, 72), Track = Color3.fromRGB(90, 70, 130), Accent = Color3.fromRGB(160, 120, 255), Text = Color3.fromRGB(235, 225, 255) },
    Neon = { Main = Color3.fromRGB(20, 14, 30), Header = Color3.fromRGB(120, 60, 200), Button = Color3.fromRGB(60, 30, 100), Track = Color3.fromRGB(180, 120, 255), Accent = Color3.fromRGB(220, 140, 255), Text = Color3.fromRGB(245, 235, 255) },
    Midnight = { Main = Color3.fromRGB(18, 18, 36), Header = Color3.fromRGB(40, 40, 90), Button = Color3.fromRGB(35, 35, 70), Track = Color3.fromRGB(70, 70, 130), Accent = Color3.fromRGB(120, 140, 255), Text = Color3.fromRGB(225, 230, 255) },
    Void = { Main = Color3.fromRGB(12, 10, 18), Header = Color3.fromRGB(35, 20, 55), Button = Color3.fromRGB(28, 20, 42), Track = Color3.fromRGB(65, 45, 95), Accent = Color3.fromRGB(150, 100, 255), Text = Color3.fromRGB(220, 210, 240) },
    ["Blood Moon"] = { Main = Color3.fromRGB(25, 0, 0), Header = Color3.fromRGB(120, 0, 0), Button = Color3.fromRGB(50, 0, 0), Track = Color3.fromRGB(80, 0, 0), Accent = Color3.fromRGB(255, 10, 10), Text = Color3.fromRGB(255, 180, 180) },
    ["Christmas"] = { Main = Color3.fromRGB(5, 25, 10), Header = Color3.fromRGB(15, 80, 30), Button = Color3.fromRGB(10, 50, 20), Track = Color3.fromRGB(150, 20, 20), Accent = Color3.fromRGB(255, 50, 50), Text = Color3.fromRGB(200, 255, 200) },
    ["Halloween"] = { Main = Color3.fromRGB(15, 5, 20), Header = Color3.fromRGB(60, 10, 80), Button = Color3.fromRGB(30, 5, 40), Track = Color3.fromRGB(120, 60, 0), Accent = Color3.fromRGB(255, 120, 0), Text = Color3.fromRGB(255, 220, 150) },
    ["Valentine"] = { Main = Color3.fromRGB(45, 5, 25), Header = Color3.fromRGB(120, 20, 60), Button = Color3.fromRGB(70, 10, 40), Track = Color3.fromRGB(180, 40, 90), Accent = Color3.fromRGB(255, 105, 180), Text = Color3.fromRGB(255, 210, 230) }
}
local CurrentTheme = "Noturno"
local ThemePreviews = { Noturno = Color3.fromRGB(160, 120, 255), Neon = Color3.fromRGB(220, 140, 255), Midnight = Color3.fromRGB(120, 140, 255), Void = Color3.fromRGB(150, 100, 255), ["Blood Moon"] = Color3.fromRGB(255, 10, 10), ["Christmas"] = Color3.fromRGB(255, 50, 50), ["Halloween"] = Color3.fromRGB(255, 120, 0), ["Valentine"] = Color3.fromRGB(255, 105, 180) }

-- ========== SETTINGS ==========
local Settings = {
    WalkSpeed = 16, JumpPower = 50, FlySpeed = 50,
    FarmSpeed = 25, AvoidMurderer = true, AvoidSheriff = false, ResetWhenFull = true
}

-- ========== LÓGICA DO AUTOFARM ==========
local FarmConnection = nil
local FarmVelocity = nil
local FarmAttachment = nil
local FarmTarget = nil
local IsFarming = false
local ResettingForFull = false
local BagCurrent = nil
local BagMaximum = nil
local OriginalCollision = {}
local FarmCooldown = 0

-- Variáveis de controle de rodada
local RoundActive = false
local RoleCache = {}

-- ========== VERIFICAÇÃO DE FUNÇÃO (ROLE) ==========
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local Gameplay = Remotes and Remotes:FindFirstChild("Gameplay")
local RoleRemote = Gameplay and Gameplay:FindFirstChild("GetCurrentPlayerData")
local CoinCollected = Gameplay and Gameplay:FindFirstChild("CoinCollected")

local function RefreshRoles()
    if not RoleRemote then return end
    task.spawn(function()
        local success, roster = pcall(function() return RoleRemote:InvokeServer() end)
        if success and type(roster) == "table" then RoleCache = roster end
    end)
end

local function GetRole(player)
    local entry = RoleCache[player.Name] or RoleCache[player.UserId]
    if type(entry) == "table" then
        if entry.Dead == true then return "Dead" end
        if entry.Role then return entry.Role end
    end
    -- Se tem faca, é assassino
    local char = player.Character
    local back = player.Backpack
    if (char and char:FindFirstChild("Knife")) or (back and back:FindFirstChild("Knife")) then return "Murderer" end
    if (char and char:FindFirstChild("Gun")) or (back and back:FindFirstChild("Gun")) then return "Sheriff" end
    return "Unknown"
end

local function IsPlayerInRound()
    local character = LocalPlayer.Character
    if not character or not character.Parent then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    -- Verifica se está no lobby
    local lobby = workspace:FindFirstChild("Lobby", true)
    local root = character:FindFirstChild("HumanoidRootPart")
    if lobby and root then
        local lobbyPart = lobby:FindFirstChildWhichIsA("BasePart", true)
        if lobbyPart and (root.Position - lobbyPart.Position).Magnitude < 80 then
            return false -- Está no lobby
        end
    end
    
    -- Verifica se tem uma função ativa
    local role = GetRole(LocalPlayer)
    if role == "Innocent" or role == "Murderer" or role == "Sheriff" or role == "Hero" then
        return true
    end
    
    -- Se o mapa carregou mas não tem função = Entrada atrasada
    local map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("CoinContainer", true)
    if map then return false end -- Entrada atrasada
    
    return false
end

-- ========== LÓGICA DE COLETA ==========
local function GetCoinContainer()
    local map = workspace:FindFirstChild("Map")
    if map then
        local container = map:FindFirstChild("CoinContainer", true)
        if container then return container end
    end
    return workspace:FindFirstChild("CoinContainer", true)
end

local function IsCoin(part)
    if not part or not part.Parent then return false end
    if not part:IsA("BasePart") then return false end
    if part:GetAttribute("Collected") == true then return false end
    if part == FarmTarget and (part.Transparency == 1 or part.Parent == nil) then return false end
    if part:FindFirstChild("CoinVisual") then return true end
    if part:FindFirstChild("Visual") then return true end
    if part.Name:lower():find("coin") then return true end
    return false
end

local function GetNearestCoin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local container = GetCoinContainer()
    if not container then return nil end
    local nearest = nil; local shortest = math.huge
    for _, coin in ipairs(container:GetDescendants()) do
        if IsCoin(coin) and coin ~= FarmTarget then
            local dist = (coin.Position - root.Position).Magnitude
            if dist < shortest then shortest = dist; nearest = coin end
        end
    end
    return nearest
end

local function GetDangerousPlayers()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local dangers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local enemyChar = player.Character
            local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                local role = GetRole(player)
                if (Settings.AvoidMurderer and role == "Murderer") or (Settings.AvoidSheriff and role == "Sheriff") then
                    table.insert(dangers, enemyRoot)
                end
            end
        end
    end
    return dangers
end

local function GetSafeCoin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local dangers = GetDangerousPlayers()
    local container = GetCoinContainer()
    if not container then return nil end
    
    if #dangers == 0 then return GetNearestCoin() end
    
    local nearestSafeCoin = nil
    local shortestDist = math.huge
    local radius = 30
    
    for _, coin in ipairs(container:GetDescendants()) do
        if IsCoin(coin) and coin ~= FarmTarget then
            local distToPlayer = (coin.Position - root.Position).Magnitude
            local isSafe = true
            for _, dangerRoot in ipairs(dangers) do
                if (coin.Position - dangerRoot.Position).Magnitude < radius then isSafe = false; break end
            end
            if isSafe and distToPlayer < shortestDist then
                shortestDist = distToPlayer
                nearestSafeCoin = coin
            end
        end
    end
    return nearestSafeCoin or GetNearestCoin()
end

local function IsBagFull()
    if not BagCurrent or not BagMaximum then return false end
    return BagCurrent >= BagMaximum and BagMaximum > 0
end

local function ApplyNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    if not IsFarming then
        for part, orig in pairs(OriginalCollision) do if part and part.Parent then part.CanCollide = orig end end
        table.clear(OriginalCollision)
        return
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if OriginalCollision[part] == nil then OriginalCollision[part] = part.CanCollide end
            part.CanCollide = false
        end
    end
end

local function StopFarm()
    if FarmConnection then FarmConnection:Disconnect(); FarmConnection = nil end
    if FarmVelocity then FarmVelocity:Destroy(); FarmVelocity = nil end
    if FarmAttachment then FarmAttachment:Destroy(); FarmAttachment = nil end
    FarmTarget = nil
    ApplyNoclip()
end

local function StartFarm()
    if FarmConnection then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    task.spawn(function()
        while IsFarming do ApplyNoclip(); task.wait(0.1) end
    end)

    FarmAttachment = Instance.new("Attachment"); FarmAttachment.Parent = root
    FarmVelocity = Instance.new("LinearVelocity")
    FarmVelocity.Attachment0 = FarmAttachment; FarmVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    FarmVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    FarmVelocity.ForceLimitsEnabled = false; FarmVelocity.VectorVelocity = Vector3.zero
    FarmVelocity.Enabled = true; FarmVelocity.Parent = root

    FarmConnection = RunService.Heartbeat:Connect(function()
        if not IsFarming then StopFarm(); return end
        if not root.Parent or not FarmVelocity.Parent then StopFarm(); return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then StopFarm(); return end
        
        -- AQUI ESTÁ A PROTEÇÃO PARA ENTRADA ATRASADA
        if not IsPlayerInRound() then
            FarmVelocity.VectorVelocity = Vector3.zero
            return
        end
        
        if os.clock() < FarmCooldown then FarmVelocity.VectorVelocity = Vector3.zero; return end

        if Settings.ResetWhenFull and IsBagFull() and not ResettingForFull then
            ResettingForFull = true
            StopFarm()
            task.delay(0.5, function() hum.Health = 0 end)
            return
        end
        if ResettingForFull then FarmVelocity.VectorVelocity = Vector3.zero; return end

        if not FarmTarget or not IsCoin(FarmTarget) then FarmTarget = GetSafeCoin() end
        if FarmTarget then
            local dist = (FarmTarget.Position - root.Position).Magnitude
            if dist <= 0.5 then 
                FarmVelocity.VectorVelocity = Vector3.zero
                FarmTarget = nil
                task.wait(0.3)
            else 
                FarmVelocity.VectorVelocity = (FarmTarget.Position - root.Position).Unit * Settings.FarmSpeed 
            end
        else 
            FarmVelocity.VectorVelocity = Vector3.zero 
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if IsFarming then
        StopFarm()
        ResettingForFull = false
        BagCurrent = nil
        BagMaximum = nil
        FarmCooldown = os.clock() + 3
        task.wait(1.5)
        if IsFarming then StartFarm() end
    end
end)

-- ========== UTIL ==========
local function Create(className, properties, parent)
    local obj = Instance.new(className)
    for k, v in pairs(properties) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local old = PlayerGui:FindFirstChild("NoturnoHub")
if old then old:Destroy() end
local oldLoader = PlayerGui:FindFirstChild("NoturnoLoader")
if oldLoader then oldLoader:Destroy() end

-- ============================================================
-- TELA DE CARREGAMENTO
-- ============================================================
local LoaderGui = Create("ScreenGui", { Name = "NoturnoLoader", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
local bg = Create("Frame", { Name = "BG", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(15, 10, 20), BorderSizePixel = 0 }, LoaderGui)
Create("TextLabel", { Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0.5, -50), BackgroundTransparency = 1, Text = "🌙 " .. HUB_NAME, TextColor3 = Color3.fromRGB(160, 120, 255), TextSize = 36, Font = Enum.Font.GothamBold }, bg)
Create("TextLabel", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0.5, 10), BackgroundTransparency = 1, Text = "Carregando...", TextColor3 = Color3.fromRGB(235, 225, 255), TextSize = 18, Font = Enum.Font.Gotham }, bg)
local barBg = Create("Frame", { Size = UDim2.new(0, 300, 0, 12), Position = UDim2.new(0.5, -150, 0.5, 60), BackgroundColor3 = Color3.fromRGB(48, 36, 72), BorderSizePixel = 0 }, bg)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, barBg)
local barFill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(160, 120, 255), BorderSizePixel = 0 }, barBg)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, barFill)
TweenService:Create(barFill, TweenInfo.new(DURACAO, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 1, 0) }):Play()

-- ============================================================
-- PAINEL PRINCIPAL
-- ============================================================
local ScreenGui = Create("ScreenGui", { Name = "NoturnoHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
local Theme = Themes[CurrentTheme]
local Main = Create("Frame", { Name = "Main", Size = UserInputService.TouchEnabled and UDim2.new(0.96, 0, 0.85, 0) or UDim2.fromOffset(600, 500), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Main, BorderSizePixel = 0, Active = true, Visible = false, ZIndex = 1 }, ScreenGui)
Create("UISizeConstraint", { MinSize = Vector2.new(320, 350), MaxSize = Vector2.new(600, 520) }, Main)
Create("UICorner", { CornerRadius = UDim.new(0, 14) }, Main)
Create("UIStroke", { Color = Theme.Accent, Thickness = 1.5, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Main)

local Header = Create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = Theme.Header, BorderSizePixel = 0, Active = true, ZIndex = 10 }, Main)
Create("UICorner", { CornerRadius = UDim.new(0, 14) }, Header)
local DragBlock = Create("TextButton", { Name = "DragBlock", Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 11 }, Header)
Create("TextLabel", { Size = UDim2.new(1, -110, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, Text = "🌙 " .. HUB_NAME, TextColor3 = Theme.Text, TextSize = 17, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 }, Header)
local Minimize = Create("TextButton", { Size = UDim2.fromOffset(34, 30), Position = UDim2.new(1, -84, 0, 14), BackgroundColor3 = Theme.Button, Text = "—", TextColor3 = Theme.Text, TextSize = 20, Font = Enum.Font.GothamBold, ZIndex = 13, Active = true }, Header)
Create("UICorner", { CornerRadius = UDim.new(0, 8) }, Minimize)
local CloseBtn = Create("TextButton", { Size = UDim2.fromOffset(34, 30), Position = UDim2.new(1, -46, 0, 14), BackgroundColor3 = Color3.fromRGB(180, 50, 70), Text = "✕", TextColor3 = Color3.new(1, 1, 1), TextSize = 18, Font = Enum.Font.GothamBold, ZIndex = 13, Active = true }, Header)
Create("UICorner", { CornerRadius = UDim.new(0, 8) }, CloseBtn)
local Floating = Create("TextButton", { Name = "FloatingButton", Size = UDim2.fromOffset(45, 45), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), BackgroundColor3 = Theme.Header, Text = "🌙", TextSize = 24, TextColor3 = Theme.Text, Visible = false, Active = true, ZIndex = 50 }, ScreenGui)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, Floating)
Create("UIStroke", { Color = Theme.Accent, Thickness = 1.5, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Floating)

local dragging, dragStart, startPos = false, nil, nil
DragBlock.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = Main.Position end
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

Minimize.MouseButton1Click:Connect(function() Main.Visible = false; Floating.Visible = true end)
Floating.MouseButton1Click:Connect(function() Main.Visible = true; Floating.Visible = false end)

local function UnloadHub() ScreenGui:Destroy(); if LoaderGui then LoaderGui:Destroy() end; StopFarm(); print("[" .. HUB_NAME .. "] Hub desexecutado.") end
local ClosePending = false; local CloseTimeout = nil
CloseBtn.MouseButton1Click:Connect(function()
    if not ClosePending then
        ClosePending = true; CloseBtn.Text = "?"; CloseBtn.BackgroundColor3 = Color3.fromRGB(120, 25, 55)
        CloseTimeout = task.delay(3, function() if ClosePending and CloseBtn and CloseBtn.Parent then ClosePending = false; CloseBtn.Text = "✕"; CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 70) end end)
        return
    end
    ClosePending = false; if CloseTimeout then pcall(function() task.cancel(CloseTimeout) end) end; UnloadHub()
end)

local Sidebar = Create("ScrollingFrame", { Name = "Sidebar", Size = UDim2.new(0, 160, 1, -78), Position = UDim2.fromOffset(8, 70), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = Theme.Accent, ZIndex = 2 }, Main)
Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Sidebar)
local PagesContainer = Create("Frame", { Name = "PagesContainer", Size = UDim2.new(1, -182, 1, -80), Position = UDim2.fromOffset(174, 70), BackgroundTransparency = 1, ZIndex = 2 }, Main)

local Pages, TabButtons = {}, {}
local function CreatePage(name)
    local page = Create("ScrollingFrame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ScrollBarImageColor3 = Theme.Accent }, PagesContainer)
    Create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2) }, page)
    local rowsContainer = Create("Frame", { Name = "Rows", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, page)
    Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Vertical }, rowsContainer)
    Pages[name] = { Page = page, Rows = rowsContainer }
    return Pages[name]
end
local function SelectPage(name)
    for pageName, data in pairs(Pages) do data.Page.Visible = pageName == name end
    for tabName, button in pairs(TabButtons) do
        button.BackgroundTransparency = tabName == name and 0 or 0.6
        button.TextTransparency = tabName == name and 0 or 0.2
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Transparency = tabName == name and 0.3 or 0.7 end
    end
end
local function CreateTab(name, label)
    local button = Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Button, BackgroundTransparency = 0.6, Text = label, TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, Sidebar)
    Create("UICorner", { CornerRadius = UDim.new(0, 9) }, button)
    Create("UIPadding", { PaddingLeft = UDim.new(0, 12) }, button)
    Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.7, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
    TabButtons[name] = button
    button.MouseButton1Click:Connect(function() SelectPage(name) end)
end

local PlayerPage = CreatePage("PLAYER"); local CombatPage = CreatePage("COMBATE"); local TrollPage = CreatePage("TROLL")
local TeleportPage = CreatePage("TELEPORTE"); local FarmPage = CreatePage("FARM"); local ConfigPage = CreatePage("CONFIGURACAO"); local AboutPage = CreatePage("ABOUT")

CreateTab("PLAYER", "👤  PLAYER"); CreateTab("COMBATE", "🎯  COMBATE"); CreateTab("TROLL", "😈  TROLL")
CreateTab("TELEPORTE", "📍  TELEPORTE"); CreateTab("FARM", "💰  FARM"); CreateTab("CONFIGURACAO", "⚙  CONFIG"); CreateTab("ABOUT", "ℹ  ABOUT")
SelectPage("PLAYER")

local ToggleButtons = {}; local SliderObjects = {}
local function AddButton(page, text, callback)
    local button = Create("TextButton", { Size = UDim2.new(1, -6, 0, 30), BackgroundColor3 = Theme.Button, Text = text, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold }, page)
    Create("UICorner", { CornerRadius = UDim.new(0, 7) }, button)
    button.MouseButton1Click:Connect(callback)
    return button
end

local function AddSlider(page, title, setting, minimum, maximum, step)
    local frame = Create("Frame", { Name = "SliderContainer", Size = UDim2.new(1, -6, 0, 55), BackgroundColor3 = Theme.Button, BorderSizePixel = 0 }, page)
    Create("UICorner", { CornerRadius = UDim.new(0, 7) }, frame)
    local label = Create("TextLabel", { Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 2), BackgroundTransparency = 1, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, frame)
    local bar = Create("Frame", { Name = "SliderBackground", Size = UDim2.new(1, -20, 0, 8), Position = UDim2.fromOffset(10, 35), BackgroundColor3 = Theme.Track, BorderSizePixel = 0, Active = true }, frame)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
    local fill = Create("Frame", { Name = "SliderFill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
    local knob = Create("Frame", { Name = "SliderKnob", Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
    
    local dragging = false
    local function Update(value)
        value = math.clamp(value, minimum, maximum)
        value = math.floor(value / step + 0.5) * step
        Settings[setting] = math.clamp(value, minimum, maximum)
        local percent = (Settings[setting] - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, 0, 0.5, 0)
        label.Text = title .. ": " .. tostring(Settings[setting])
    end
    local function UpdateFromInput(input)
        if bar.AbsoluteSize.X <= 0 then return end
        local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        Update(minimum + (maximum - minimum) * percent)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; UpdateFromInput(input) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateFromInput(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    table.insert(SliderObjects, { Frame = frame, Bar = bar, Fill = fill, Knob = knob, Setting = setting, Set = Update, Minimum = minimum, Maximum = maximum, Step = step })
    Update(Settings[setting])
    return frame
end

-- ============================================================
-- ABA FARM
-- ============================================================
local FarmStatus = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "Status: Desativado", TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, FarmPage.Rows)
FarmStatus.LayoutOrder = 1

local function CreateFarmToggle(title, isActive, callback)
    local row = Create("Frame", { Name = "FarmToggleRow", Size = UDim2.new(1, -6, 0, 34), BackgroundColor3 = Theme.Button, BorderSizePixel = 0 }, FarmPage.Rows)
    Create("UICorner", { CornerRadius = UDim.new(0, 7) }, row)
    Create("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local track = Create("Frame", { Name = "ToggleTrack", Size = UDim2.fromOffset(36, 20), Position = UDim2.new(1, -46, 0.5, -10), BackgroundColor3 = isActive and Theme.Header or Theme.Track, BorderSizePixel = 0 }, row)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local knob = Create("Frame", { Name = "ToggleKnob", Size = UDim2.fromOffset(14, 14), Position = isActive and UDim2.new(1, -17, 0, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
    local hitbox = Create("TextButton", { Name = "ToggleHitbox", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, row)
    local function updateVisual(enabled) track.BackgroundColor3 = enabled and Theme.Header or Theme.Track; knob.Position = enabled and UDim2.new(1, -17, 0, 3) or UDim2.fromOffset(3, 3) end
    hitbox.MouseButton1Click:Connect(function() local newState = not isActive; isActive = newState; updateVisual(newState); callback(newState) end)
    return row, updateVisual
end

local AutoFarmToggle, UpdateAutoFarmVisual = CreateFarmToggle("Ativar Auto Farm", false, function(state)
    IsFarming = state
    if state then
        StartFarm()
        FarmStatus.Text = "Status: Ativado (Rodando)"
        FarmStatus.TextColor3 = Color3.fromRGB(100, 255, 130)
    else
        StopFarm()
        FarmStatus.Text = "Status: Desativado"
        FarmStatus.TextColor3 = Theme.Text
    end
end)
AutoFarmToggle.LayoutOrder = 2

local FarmSpeedSlider = AddSlider(FarmPage.Rows, "Velocidade do Farm", "FarmSpeed", 5, 50, 1)
FarmSpeedSlider.LayoutOrder = 3

local AvoidMurdererToggle = CreateFarmToggle("Evitar Assassino", Settings.AvoidMurderer, function(state) Settings.AvoidMurderer = state end)
AvoidMurdererToggle.LayoutOrder = 4

local AvoidSheriffToggle = CreateFarmToggle("Evitar Xerife", Settings.AvoidSheriff, function(state) Settings.AvoidSheriff = state end)
AvoidSheriffToggle.LayoutOrder = 5

local AutoResetToggle = CreateFarmToggle("Auto Reset (Mochila Cheia)", Settings.ResetWhenFull, function(state) Settings.ResetWhenFull = state end)
AutoResetToggle.LayoutOrder = 6

local BagFrame = Create("Frame", { Name = "BagProgress", Size = UDim2.new(1, -6, 0, 58), BackgroundColor3 = Theme.Button, BorderSizePixel = 0, LayoutOrder = 7 }, FarmPage.Rows)
Create("UICorner", { CornerRadius = UDim.new(0, 8) }, BagFrame)
local BagTitle = Create("TextLabel", { Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 3), BackgroundTransparency = 1, Text = "MOCHILA: aguardando dados...", TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, BagFrame)
local BagBackground = Create("Frame", { Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 30), BackgroundColor3 = Theme.Track, BorderSizePixel = 0 }, BagFrame)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, BagBackground)
local BagFill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(100, 255, 130), BorderSizePixel = 0 }, BagBackground)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, BagFill)

local function UpdateBagDisplay()
    if not BagCurrent or not BagMaximum or BagMaximum <= 0 then
        BagTitle.Text = "MOCHILA: aguardando dados..."; BagFill.Size = UDim2.new(0, 0, 1, 0); BagFill.BackgroundColor3 = Color3.fromRGB(255, 220, 80); return
    end
    local percent = math.clamp(BagCurrent / BagMaximum, 0, 1)
    BagTitle.Text = string.format("MOCHILA: %d/%d (%d%%)", BagCurrent, BagMaximum, math.floor(percent * 100))
    BagFill.Size = UDim2.new(percent, 0, 1, 0)
    if percent >= 1 then BagFill.BackgroundColor3 = Color3.fromRGB(255, 45, 65)
    elseif percent >= 0.75 then BagFill.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
    else BagFill.BackgroundColor3 = Color3.fromRGB(100, 255, 130) end
end

if CoinCollected and CoinCollected:IsA("RemoteEvent") then
    CoinCollected.OnClientEvent:Connect(function(_, current, maximum)
        current = tonumber(current); maximum = tonumber(maximum)
        if current and maximum and maximum > 0 then
            BagCurrent = current; BagMaximum = maximum
            UpdateBagDisplay()
        end
    end)
end

-- ============================================================
-- ABA ABOUT
-- ============================================================
local AboutRow = Create("Frame", { Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, AboutPage.Rows)
local AboutLeft = Create("Frame", { Size = UDim2.new(0.47, 0, 0, 65), Position = UDim2.new(0.01, 0, 0, 0), BackgroundColor3 = Theme.Button, BorderSizePixel = 0 }, AboutRow)
Create("UICorner", { CornerRadius = UDim.new(0, 8) }, AboutLeft)
local AboutStroke = Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, AboutLeft)
local AboutTitle = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "🌙 Painel HUB", TextColor3 = Theme.Text, TextSize = 15, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center }, AboutLeft)
local AboutVersion = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 35), BackgroundTransparency = 1, Text = "Versão: " .. HUB_VERSION, TextColor3 = Theme.Accent, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center }, AboutLeft)

-- ========== LÓGICA DE TEMA ==========
local ApplyTheme
local ThemeSelector, ThemeOptions, ThemeOptionButtons = nil, nil, {}
ApplyTheme = function(name)
    local theme = Themes[name]
    if not theme then return end
    CurrentTheme = name; Theme = theme
    Main.BackgroundColor3 = theme.Main; Header.BackgroundColor3 = theme.Header; Floating.BackgroundColor3 = theme.Header
    Sidebar.BackgroundColor3 = theme.Main; Sidebar.ScrollBarImageColor3 = theme.Header; Minimize.BackgroundColor3 = theme.Button
    local mainStroke = Main:FindFirstChildOfClass("UIStroke"); if mainStroke then mainStroke.Color = theme.Accent end
    for _, button in pairs(TabButtons) do button.BackgroundColor3 = theme.Button; local stroke = button:FindFirstChildOfClass("UIStroke"); if stroke then stroke.Color = theme.Accent end end
    for _, data in pairs(Pages) do
        for _, object in ipairs(data.Page:GetDescendants()) do
            if object:IsA("UIStroke") then object.Color = theme.Accent end
            if object:IsA("TextButton") then if object.BackgroundTransparency < 1 then object.BackgroundColor3 = theme.Button end; object.TextColor3 = theme.Text
            elseif object:IsA("TextBox") then object.BackgroundColor3 = theme.Button; object.TextColor3 = theme.Text
            elseif object:IsA("Frame") and (object.Name == "SliderContainer" or object.Name == "ToggleContainer" or object.Name == "FarmToggleRow" or object.Name == "BagProgress") then object.BackgroundColor3 = theme.Button
            elseif object:IsA("TextLabel") then if object.TextColor3 ~= Color3.fromRGB(255, 90, 130) then object.TextColor3 = theme.Text end end
        end
    end
    if BagFrame then BagFrame.BackgroundColor3 = theme.Button end; if BagBackground then BagBackground.BackgroundColor3 = theme.Track end
    if AboutLeft then AboutLeft.BackgroundColor3 = theme.Button end; if AboutStroke then AboutStroke.Color = theme.Accent end
    if AboutTitle then AboutTitle.TextColor3 = theme.Text end; if AboutVersion then AboutVersion.TextColor3 = theme.Accent end
    if ThemeSelector then ThemeSelector.Text = "Tema: " .. name .. "  ▼" end
    for tName, btn in pairs(ThemeOptionButtons) do local color = ThemePreviews[tName] or theme.Button; btn.TextColor3 = color; local stroke = btn:FindFirstChildOfClass("UIStroke"); if stroke then stroke.Color = color end end
end

-- ============================================================
-- ABA CONFIGURAÇÃO
-- ============================================================
local ConfigRows = ConfigPage.Rows
ThemeSelector = AddButton(ConfigRows, "Tema: " .. CurrentTheme .. "  ▼", function() ThemeOptions.Visible = not ThemeOptions.Visible end)
ThemeOptions = Create("Frame", { Name = "ThemeOptions", Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, ConfigRows)
Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, ThemeOptions)
for _, themeName in ipairs({ "Noturno", "Neon", "Midnight", "Void", "Blood Moon", "Christmas", "Halloween", "Valentine" }) do
    local option = AddButton(ThemeOptions, themeName, function() ApplyTheme(themeName); ThemeOptions.Visible = false end)
    option.Size = UDim2.new(1, 0, 0, 29)
    local previewColor = ThemePreviews[themeName] or Color3.new(1, 1, 1)
    option.TextColor3 = previewColor
    local stroke = option:FindFirstChildOfClass("UIStroke"); if stroke then stroke.Color = previewColor end
    ThemeOptionButtons[themeName] = option
end

local SaveFolder = "NoturnoHub"; local AutoLoadPath = SaveFolder .. "/autoload.txt"
local SelectedConfig = nil; local SaveStatus, ConfigList, ConfigNameBox, ConfigListBtn
local function FileSystemReady() return type(makefolder) == "function" and type(isfolder) == "function" and type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function" and type(listfiles) == "function" and type(delfile) == "function" end
local function EnsureSaveFolder() if not FileSystemReady() then return false, "Executor sem suporte a arquivos." end; local ok, err = pcall(function() if not isfolder(SaveFolder) then makefolder(SaveFolder) end end); if not ok then return false, tostring(err) end; return true end
local function CleanConfigName(name) name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", ""); name = name:gsub("[^%w%s_%-]", "_"):gsub("%s+", "_"); if name == "" then return nil end; return name end
local function ConfigPath(name) return SaveFolder .. "/" .. name .. ".json" end
local function SetSaveStatus(message) if SaveStatus and SaveStatus.Parent then SaveStatus.Text = "Status: " .. message end end
local function MakeSnapshot() local data = { Version = 1, Theme = CurrentTheme, Settings = {} }; for key, value in pairs(Settings) do if type(value) == "boolean" or type(value) == "number" then data.Settings[key] = value end end; return data end
local function SaveConfig(name) local ok, err = EnsureSaveFolder(); if not ok then SetSaveStatus(err); return false end; name = CleanConfigName(name); if not name then SetSaveStatus("Digite um nome valido."); return false end; local encodedOk, contents = pcall(function() return HttpService:JSONEncode(MakeSnapshot()) end); if not encodedOk then SetSaveStatus("Erro ao preparar configuracao."); return false end; local writeOk, writeErr = pcall(writefile, ConfigPath(name), contents); if not writeOk then SetSaveStatus("Falha ao salvar: " .. tostring(writeErr)); return false end; SelectedConfig = name; SetSaveStatus("Configuracao '" .. name .. "' salva!"); return true end
local function LoadConfig(name) local ok, err = EnsureSaveFolder(); if not ok then SetSaveStatus(err); return false end; name = CleanConfigName(name); if not name or not isfile(ConfigPath(name)) then SetSaveStatus("Configuracao nao encontrada."); return false end; local readOk, contents = pcall(readfile, ConfigPath(name)); if not readOk then SetSaveStatus("Nao foi possivel ler o arquivo."); return false end; local decodeOk, data = pcall(function() return HttpService:JSONDecode(contents) end); if not decodeOk or type(data) ~= "table" or type(data.Settings) ~= "table" then SetSaveStatus("Arquivo de configuracao invalido."); return false end; for _, slider in ipairs(SliderObjects) do local value = data.Settings[slider.Setting]; if type(value) == "number" then slider.Set(value) end end; for key, item in pairs(ToggleButtons) do if Settings[key] == true and item.Callback then pcall(item.Callback, false) end; Settings[key] = false; item.Update(false) end; local order = { "AvoidMurderer", "AvoidSheriff", "ResetWhenFull" }; for _, key in ipairs(order) do local item = ToggleButtons[key]; local value = data.Settings[key]; if item and type(value) == "boolean" then Settings[key] = value; item.Update(value); if item.Callback then pcall(item.Callback, value) end end end; if type(data.Theme) == "string" and Themes[data.Theme] then ApplyTheme(data.Theme) end; SelectedConfig = name; SetSaveStatus("'" .. name .. "' carregada!"); return true end
local function RefreshConfigs() local ok, err = EnsureSaveFolder(); if not ok then SetSaveStatus(err); return end; if ConfigList then for _, child in ipairs(ConfigList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end end; local found = {}; local listOk, files = pcall(listfiles, SaveFolder); if listOk and type(files) == "table" then for _, path in ipairs(files) do local base = tostring(path):match("([^/\\]+)%.json$"); if base then table.insert(found, base) end end end; table.sort(found); for i, name in ipairs(found) do local entry = AddButton(ConfigList, name, function() SelectedConfig = name; ConfigNameBox.Text = name; ConfigListBtn.Text = "Salvo: " .. name .. "  ▼"; ConfigList.Visible = false; SetSaveStatus("Selecionada: " .. name) end); entry.Size = UDim2.new(1, 0, 0, 27); entry.LayoutOrder = i end; SetSaveStatus(#found .. " configuracao(oes) encontrada(s).") end

Create("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "💾 SALVAMENTO", TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, ConfigRows)
local inputRow = Create("Frame", { Size = UDim2.new(1, -6, 0, 34), BackgroundTransparency = 1 }, ConfigRows)
ConfigNameBox = Create("TextBox", { Size = UDim2.new(1, -75, 1, 0), BackgroundColor3 = Theme.Button, TextColor3 = Theme.Text, PlaceholderText = "Nome...", PlaceholderColor3 = Color3.fromRGB(235, 220, 230), Text = "", TextSize = 12, Font = Enum.Font.Gotham, ClearTextOnFocus = false }, inputRow)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, ConfigNameBox)
local btnSave = Create("TextButton", { Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(1, -70, 0, 0), BackgroundColor3 = Color3.fromRGB(60, 160, 90), Text = "Salvar", TextColor3 = Color3.new(1,1,1), TextSize = 11, Font = Enum.Font.GothamBold }, inputRow)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, btnSave)
btnSave.MouseButton1Click:Connect(function() SaveConfig(ConfigNameBox.Text); RefreshConfigs() end)

ConfigListBtn = AddButton(ConfigRows, "Nenhuma config salva  ▼", function() RefreshConfigs(); ConfigList.Visible = not ConfigList.Visible end)
ConfigList = Create("Frame", { Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, ConfigRows)
Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, ConfigList)

AddButton(ConfigRows, "📂  Carregar configuracao", function() LoadConfig(ConfigNameBox.Text ~= "" and ConfigNameBox.Text or SelectedConfig) end)
AddButton(ConfigRows, "🗑  Excluir configuracao", function() local ok, err = EnsureSaveFolder(); if not ok then SetSaveStatus(err); return end; local name = CleanConfigName(ConfigNameBox.Text ~= "" and ConfigNameBox.Text or SelectedConfig); if not name or not isfile(ConfigPath(name)) then SetSaveStatus("Configuracao nao encontrada."); return end; local deleted, deleteErr = pcall(delfile, ConfigPath(name)); if deleted then if SelectedConfig == name then SelectedConfig = nil end; SetSaveStatus("Configuracao excluida."); RefreshConfigs() else SetSaveStatus("Falha ao excluir: " .. tostring(deleteErr)) end end)
AddButton(ConfigRows, "⭐  Definir Auto Load", function() local ok, err = EnsureSaveFolder(); if not ok then SetSaveStatus(err); return end; local name = CleanConfigName(ConfigNameBox.Text ~= "" and ConfigNameBox.Text or SelectedConfig); if not name or not isfile(ConfigPath(name)) then SetSaveStatus("Salve ou selecione uma config primeiro."); return end; local wrote, writeErr = pcall(writefile, AutoLoadPath, name); if wrote then SetSaveStatus("'" .. name .. "' sera carregada ao iniciar!") else SetSaveStatus("Falha no Auto Load: " .. tostring(writeErr)) end end)
AddButton(ConfigRows, "🚫  Remover Auto Load", function() if type(isfile) == "function" and type(delfile) == "function" and isfile(AutoLoadPath) then pcall(delfile, AutoLoadPath) end; SetSaveStatus("Carregamento automatico removido.") end)
SaveStatus = Create("TextLabel", { Size = UDim2.new(1, -6, 0, 34), BackgroundTransparency = 1, Text = "Status: Pronto.", TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }, ConfigRows)
AddButton(ConfigRows, "🔄  Atualizar lista", function() RefreshConfigs() end)

local UnloadBtn = AddButton(ConfigRows, "⏻  Desexecutar Hub", function() UnloadHub() end)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 70)
Create("UIStroke", { Color = Color3.fromRGB(255, 90, 130), Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, UnloadBtn)

-- ============================================================
-- INICIALIZAÇÃO
-- ============================================================
if type(isfile) == "function" and type(readfile) == "function" and isfile(AutoLoadPath) then
    local ok, name = pcall(readfile, AutoLoadPath)
    if ok and type(name) == "string" then task.wait(0.5); LoadConfig(name) end
end
RefreshConfigs()
task.wait(DURACAO)
Main.Visible = true
local fadeTween = TweenService:Create(bg, TweenInfo.new(FADE, Enum.EasingStyle.Linear), { BackgroundTransparency = 1 })
for _, obj in ipairs(bg:GetDescendants()) do
    if obj:IsA("TextLabel") then TweenService:Create(obj, TweenInfo.new(FADE), { TextTransparency = 1 }):Play() end
    if obj:IsA("Frame") then TweenService:Create(obj, TweenInfo.new(FADE), { BackgroundTransparency = 1 }):Play() end
end
fadeTween:Play()
fadeTween.Completed:Wait()
LoaderGui:Destroy()
print("[" .. HUB_NAME .. "] v" .. HUB_VERSION .. " carregado!")
