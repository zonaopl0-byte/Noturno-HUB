--[[
    NOTURNO HUB - v0.3.9
    - Removido o cartão de perfil (criador) da tela de carregamento.
    - Versionamento SemVer: 0.0.9 -> 0.1.0 -> 0.1.9 -> 0.2.0 -> 0.3.0
]]

local HUB_NAME = "NOTURNO HUB"
local HUB_VERSION = "0.3.9"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========== CONFIGURAÇÕES DO LOADING ==========
local DURACAO = 5
local FADE = 0.5

-- ========== TEMAS ==========
local Themes = {
    Noturno = {
        Main   = Color3.fromRGB(28, 22, 40),
        Header = Color3.fromRGB(58, 38, 92),
        Button = Color3.fromRGB(48, 36, 72),
        Track  = Color3.fromRGB(90, 70, 130),
        Accent = Color3.fromRGB(160, 120, 255),
        Text   = Color3.fromRGB(235, 225, 255)
    },
    Neon = {
        Main   = Color3.fromRGB(20, 14, 30),
        Header = Color3.fromRGB(120, 60, 200),
        Button = Color3.fromRGB(60, 30, 100),
        Track  = Color3.fromRGB(180, 120, 255),
        Accent = Color3.fromRGB(220, 140, 255),
        Text   = Color3.fromRGB(245, 235, 255)
    },
    Midnight = {
        Main   = Color3.fromRGB(18, 18, 36),
        Header = Color3.fromRGB(40, 40, 90),
        Button = Color3.fromRGB(35, 35, 70),
        Track  = Color3.fromRGB(70, 70, 130),
        Accent = Color3.fromRGB(120, 140, 255),
        Text   = Color3.fromRGB(225, 230, 255)
    },
    Void = {
        Main   = Color3.fromRGB(12, 10, 18),
        Header = Color3.fromRGB(35, 20, 55),
        Button = Color3.fromRGB(28, 20, 42),
        Track  = Color3.fromRGB(65, 45, 95),
        Accent = Color3.fromRGB(150, 100, 255),
        Text   = Color3.fromRGB(220, 210, 240)
    },
    ["Blood Moon"] = {
        Main   = Color3.fromRGB(25, 0, 0),
        Header = Color3.fromRGB(120, 0, 0),
        Button = Color3.fromRGB(50, 0, 0),
        Track  = Color3.fromRGB(80, 0, 0),
        Accent = Color3.fromRGB(255, 10, 10),
        Text   = Color3.fromRGB(255, 180, 180)
    },
    ["Christmas"] = {
        Main   = Color3.fromRGB(5, 25, 10),
        Header = Color3.fromRGB(15, 80, 30),
        Button = Color3.fromRGB(10, 50, 20),
        Track  = Color3.fromRGB(150, 20, 20),
        Accent = Color3.fromRGB(255, 50, 50),
        Text   = Color3.fromRGB(200, 255, 200)
    },
    ["Halloween"] = {
        Main   = Color3.fromRGB(15, 5, 20),
        Header = Color3.fromRGB(60, 10, 80),
        Button = Color3.fromRGB(30, 5, 40),
        Track  = Color3.fromRGB(120, 60, 0),
        Accent = Color3.fromRGB(255, 120, 0),
        Text   = Color3.fromRGB(255, 220, 150)
    },
    ["Valentine"] = {
        Main   = Color3.fromRGB(45, 5, 25),
        Header = Color3.fromRGB(120, 20, 60),
        Button = Color3.fromRGB(70, 10, 40),
        Track  = Color3.fromRGB(180, 40, 90),
        Accent = Color3.fromRGB(255, 105, 180),
        Text   = Color3.fromRGB(255, 210, 230)
    }
}
local CurrentTheme = "Noturno"

-- ========== PREVIEWS DE TEMA ==========
local ThemePreviews = {
    Noturno = Color3.fromRGB(160, 120, 255),
    Neon = Color3.fromRGB(220, 140, 255),
    Midnight = Color3.fromRGB(120, 140, 255),
    Void = Color3.fromRGB(150, 100, 255),
    ["Blood Moon"] = Color3.fromRGB(255, 10, 10),
    ["Christmas"] = Color3.fromRGB(255, 50, 50),
    ["Halloween"] = Color3.fromRGB(255, 120, 0),
    ["Valentine"] = Color3.fromRGB(255, 105, 180)
}

-- ========== SETTINGS ==========
local Settings = {
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 50,
    FarmSpeed = 22,
}

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
-- 1. TELA DE CARREGAMENTO (SOBREPÕE TUDO)
-- ============================================================
local LoaderGui = Create("ScreenGui", {
    Name = "NoturnoLoader",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local bg = Create("Frame", {
    Name = "BG",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(15, 10, 20),
    BorderSizePixel = 0
}, LoaderGui)

local titulo = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 60),
    Position = UDim2.new(0, 0, 0.5, -50),
    BackgroundTransparency = 1,
    Text = "🌙 " .. HUB_NAME,
    TextColor3 = Color3.fromRGB(160, 120, 255),
    TextSize = 36,
    Font = Enum.Font.GothamBold
}, bg)

local sub = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0.5, 10),
    BackgroundTransparency = 1,
    Text = "Carregando...",
    TextColor3 = Color3.fromRGB(235, 225, 255),
    TextSize = 18,
    Font = Enum.Font.Gotham
}, bg)

-- ========== BARRA DE PROGRESSO ==========
local barBg = Create("Frame", {
    Size = UDim2.new(0, 300, 0, 12),
    Position = UDim2.new(0.5, -150, 0.5, 60),
    BackgroundColor3 = Color3.fromRGB(48, 36, 72),
    BorderSizePixel = 0
}, bg)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, barBg)

local barFill = Create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(160, 120, 255),
    BorderSizePixel = 0
}, barBg)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, barFill)

-- Animação da barra de 0 a 100%
local tween = TweenService:Create(barFill, TweenInfo.new(DURACAO, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 1, 0) })
tween:Play()

-- ============================================================
-- 2. PAINEL PRINCIPAL (INVISÍVEL ATÉ CARREGAR)
-- ============================================================
local ScreenGui = Create("ScreenGui", {
    Name = "NoturnoHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local Theme = Themes[CurrentTheme]

local Main = Create("Frame", {
    Name = "Main",
    Size = UserInputService.TouchEnabled and UDim2.new(0.96, 0, 0.85, 0) or UDim2.fromOffset(600, 500),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.Main,
    BorderSizePixel = 0,
    Active = true,
    Visible = false,
    ZIndex = 1
}, ScreenGui)
Create("UISizeConstraint", { MinSize = Vector2.new(320, 350), MaxSize = Vector2.new(600, 520) }, Main)
Create("UICorner", { CornerRadius = UDim.new(0, 14) }, Main)
Create("UIStroke", { Color = Theme.Accent, Thickness = 1.5, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Main)

-- ========== HEADER ==========
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

-- ========== DRAG ==========
local dragging, dragStart, startPos = false, nil, nil
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

-- ========== MINIMIZAR ==========
Minimize.MouseButton1Click:Connect(function() Main.Visible = false; Floating.Visible = true end)
Floating.MouseButton1Click:Connect(function() Main.Visible = true; Floating.Visible = false end)

-- ========== DESEXECUTAR (X) ==========
local ClosePending = false
local CloseTimeout = nil
local function UnloadHub() ScreenGui:Destroy(); if LoaderGui then LoaderGui:Destroy() end; print("[" .. HUB_NAME .. "] Hub desexecutado.") end
CloseBtn.MouseButton1Click:Connect(function()
    if not ClosePending then
        ClosePending = true; CloseBtn.Text = "?"; CloseBtn.BackgroundColor3 = Color3.fromRGB(120, 25, 55)
        CloseTimeout = task.delay(3, function()
            if ClosePending and CloseBtn and CloseBtn.Parent then ClosePending = false; CloseBtn.Text = "✕"; CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 70) end
        end)
        return
    end
    ClosePending = false; if CloseTimeout then pcall(function() task.cancel(CloseTimeout) end) end; UnloadHub()
end)

-- ========== SIDEBAR ==========
local Sidebar = Create("ScrollingFrame", { Name = "Sidebar", Size = UDim2.new(0, 160, 1, -78), Position = UDim2.fromOffset(8, 70), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = Theme.Accent, ZIndex = 2 }, Main)
Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Sidebar)

local PagesContainer = Create("Frame", { Name = "PagesContainer", Size = UDim2.new(1, -182, 1, -80), Position = UDim2.fromOffset(174, 70), BackgroundTransparency = 1, ZIndex = 2 }, Main)

-- ========== SISTEMA DE PÁGINAS ==========
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

local PlayerPage      = CreatePage("PLAYER")
local CombatPage      = CreatePage("COMBATE")
local TrollPage       = CreatePage("TROLL")
local TeleportPage    = CreatePage("TELEPORTE")
local FarmPage        = CreatePage("FARM")
local ConfigPage      = CreatePage("CONFIGURACAO")
local AboutPage       = CreatePage("ABOUT")

CreateTab("PLAYER", "👤  PLAYER")
CreateTab("COMBATE", "🎯  COMBATE")
CreateTab("TROLL", "😈  TROLL")
CreateTab("TELEPORTE", "📍  TELEPORTE")
CreateTab("FARM", "💰  FARM")
CreateTab("CONFIGURACAO", "⚙  CONFIG")
CreateTab("ABOUT", "ℹ  ABOUT")
SelectPage("PLAYER")

-- ========== COMPONENTES AUXILIARES ==========
local ToggleButtons = {}
local SliderObjects = {}
local function StyleButton(btn) Create("UICorner", { CornerRadius = UDim.new(0, 7) }, btn); Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.75, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, btn) end
local function AddButton(page, text, callback)
    local button = Create("TextButton", { Size = UDim2.new(1, -6, 0, 30), BackgroundColor3 = Theme.Button, Text = text, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamBold }, page)
    Create("UICorner", { CornerRadius = UDim.new(0, 7) }, button)
    button.MouseButton1Click:Connect(callback)
    return button
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
    CurrentTheme = name
    Theme = theme

    Main.BackgroundColor3 = theme.Main
    Header.BackgroundColor3 = theme.Header
    Floating.BackgroundColor3 = theme.Header
    Sidebar.BackgroundColor3 = theme.Main
    Sidebar.ScrollBarImageColor3 = theme.Header
    Minimize.BackgroundColor3 = theme.Button

    local mainStroke = Main:FindFirstChildOfClass("UIStroke")
    if mainStroke then mainStroke.Color = theme.Accent end

    for _, button in pairs(TabButtons) do 
        button.BackgroundColor3 = theme.Button 
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = theme.Accent end
    end

    for _, data in pairs(Pages) do
        for _, object in ipairs(data.Page:GetDescendants()) do
            if object:IsA("UIStroke") then object.Color = theme.Accent end
            if object:IsA("TextButton") then
                if object.BackgroundTransparency < 1 then object.BackgroundColor3 = theme.Button end
                object.TextColor3 = theme.Text
            elseif object:IsA("TextBox") then
                object.BackgroundColor3 = theme.Button
                object.TextColor3 = theme.Text
            elseif object:IsA("Frame") and (object.Name == "SliderContainer" or object.Name == "ToggleContainer") then
                object.BackgroundColor3 = theme.Button
            elseif object:IsA("TextLabel") then
                if object.TextColor3 ~= Color3.fromRGB(255, 90, 130) then object.TextColor3 = theme.Text end
            end
        end
    end

    if AboutLeft then AboutLeft.BackgroundColor3 = theme.Button end
    if AboutStroke then AboutStroke.Color = theme.Accent end
    if AboutTitle then AboutTitle.TextColor3 = theme.Text end
    if AboutVersion then AboutVersion.TextColor3 = theme.Accent end
    if ThemeSelector then ThemeSelector.Text = "Tema: " .. name .. "  ▼" end

    for tName, btn in pairs(ThemeOptionButtons) do
        local color = ThemePreviews[tName] or theme.Button
        btn.TextColor3 = color
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = color end
    end
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
    local stroke = option:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Color = previewColor end
    ThemeOptionButtons[themeName] = option
end

-- 2. SISTEMA DE SALVAMENTO
local SaveFolder = "NoturnoHub"
local AutoLoadPath = SaveFolder .. "/autoload.txt"
local SelectedConfig = nil
local SaveStatus, ConfigList, ConfigNameBox, ConfigListBtn

local function FileSystemReady()
    return type(makefolder) == "function" and type(isfolder) == "function" and type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function" and type(listfiles) == "function" and type(delfile) == "function"
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
local function MakeSnapshot()
    local data = { Version = 1, Theme = CurrentTheme, Settings = {} }
    for key, value in pairs(Settings) do
        if type(value) == "boolean" or type(value) == "number" then data.Settings[key] = value end
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
    local order = { "AntiFling", "AntiAfk", "XRay", "FullBright", "ESP", "ESP_Gun", "Fly", "Noclip", "AvoidMurderer", "ResetWhenFull", "AutoFarm" }
    for _, key in ipairs(order) do
        local item = ToggleButtons[key]; local value = data.Settings[key]
        if item and type(value) == "boolean" then Settings[key] = value; item.Update(value); if item.Callback then pcall(item.Callback, value) end end
    end
    if type(data.Theme) == "string" and Themes[data.Theme] then ApplyTheme(data.Theme) end
    SelectedConfig = name; SetSaveStatus("'" .. name .. "' carregada!")
    return true
end
local function RefreshConfigs()
    local ok, err = EnsureSaveFolder()
    if not ok then SetSaveStatus(err); return end
    if ConfigList then for _, child in ipairs(ConfigList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end end
    local found = {}
    local listOk, files = pcall(listfiles, SaveFolder)
    if listOk and type(files) == "table" then
        for _, path in ipairs(files) do local base = tostring(path):match("([^/\\]+)%.json$"); if base then table.insert(found, base) end end
    end
    table.sort(found)
    for i, name in ipairs(found) do
        local entry = AddButton(ConfigList, name, function()
            SelectedConfig = name; ConfigNameBox.Text = name; ConfigListBtn.Text = "Salvo: " .. name .. "  ▼"; ConfigList.Visible = false; SetSaveStatus("Selecionada: " .. name)
        end)
        entry.Size = UDim2.new(1, 0, 0, 27); entry.LayoutOrder = i
    end
    SetSaveStatus(#found .. " configuracao(oes) encontrada(s).")
end

-- UI DO SALVAMENTO
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
SaveStatus = Create("TextLabel", { Size = UDim2.new(1, -6, 0, 34), BackgroundTransparency = 1, Text = "Status: Pronto.", TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }, ConfigRows)
AddButton(ConfigRows, "🔄  Atualizar lista", function() RefreshConfigs() end)

local UnloadBtn = AddButton(ConfigRows, "⏻  Desexecutar Hub", function() UnloadHub() end)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 70)
Create("UIStroke", { Color = Color3.fromRGB(255, 90, 130), Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, UnloadBtn)

-- ============================================================
-- 3. INICIALIZAÇÃO E FIM DO CARREGAMENTO
-- ============================================================
if type(isfile) == "function" and type(readfile) == "function" and isfile(AutoLoadPath) then
    local ok, name = pcall(readfile, AutoLoadPath)
    if ok and type(name) == "string" then task.wait(0.5); LoadConfig(name) end
end
RefreshConfigs()

-- Espera o tempo do loading terminar
task.wait(DURACAO)

-- Mostra o painel e faz o fade out do loading
Main.Visible = true

local fadeTween = TweenService:Create(bg, TweenInfo.new(FADE, Enum.EasingStyle.Linear), { BackgroundTransparency = 1 })
TweenService:Create(titulo, TweenInfo.new(FADE), { TextTransparency = 1 }):Play()
TweenService:Create(sub, TweenInfo.new(FADE), { TextTransparency = 1 }):Play()
TweenService:Create(barBg, TweenInfo.new(FADE), { BackgroundTransparency = 1 }):Play()
TweenService:Create(barFill, TweenInfo.new(FADE), { BackgroundTransparency = 1 }):Play()
fadeTween:Play()
fadeTween.Completed:Wait()

LoaderGui:Destroy()
print("[" .. HUB_NAME .. "] v" .. HUB_VERSION .. " carregado!")
