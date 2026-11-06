
--[[ NOTURNO HUB - EXTENSÃO: ABA TROLL
     Versão: 1.4
     Requer: NOTURNO HUB v0.9.6+ já carregado
     
     Funções:
       🏷 Name Spoof         (local, mostra "🌙 NOTURNO 🌙")
       🧲 Stick to Player    (gruda ATRÁS do jogador selecionado)
       💥 Fling              (arremessa via colisão com velocidade)
       👤 Seletor de jogador (lista viva)

     Fix v1.4:
       - Fling agora usa AssemblyLinearVelocity no PRÓPRIO personagem
         (antes aplicava BodyVelocity no alvo e não funcionava por
          causa do network ownership)
]]

local HUB_NAME = "NOTURNO HUB"
local EXT_VERSION = "1.4"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- PALETA OFICIAL
-- ============================================================
local Themes = {
    Noturno = { Main = Color3.fromRGB(28,22,40), Header = Color3.fromRGB(58,38,92),
        Button = Color3.fromRGB(48,36,72), Track = Color3.fromRGB(90,70,130),
        Accent = Color3.fromRGB(160,120,255), Text = Color3.fromRGB(235,225,255) },
    Neon = { Main = Color3.fromRGB(20,14,30), Header = Color3.fromRGB(120,60,200),
        Button = Color3.fromRGB(60,30,100), Track = Color3.fromRGB(180,120,255),
        Accent = Color3.fromRGB(220,140,255), Text = Color3.fromRGB(245,235,255) },
    Midnight = { Main = Color3.fromRGB(18,18,36), Header = Color3.fromRGB(40,40,90),
        Button = Color3.fromRGB(35,35,70), Track = Color3.fromRGB(70,70,130),
        Accent = Color3.fromRGB(120,140,255), Text = Color3.fromRGB(225,230,255) },
    Void = { Main = Color3.fromRGB(12,10,18), Header = Color3.fromRGB(35,20,55),
        Button = Color3.fromRGB(28,20,42), Track = Color3.fromRGB(65,45,95),
        Accent = Color3.fromRGB(150,100,255), Text = Color3.fromRGB(220,210,240) },
    ["Blood Moon"] = { Main = Color3.fromRGB(25,0,0), Header = Color3.fromRGB(120,0,0),
        Button = Color3.fromRGB(50,0,0), Track = Color3.fromRGB(80,0,0),
        Accent = Color3.fromRGB(255,10,10), Text = Color3.fromRGB(255,180,180) },
    Christmas = { Main = Color3.fromRGB(5,25,10), Header = Color3.fromRGB(15,80,30),
        Button = Color3.fromRGB(10,50,20), Track = Color3.fromRGB(150,20,20),
        Accent = Color3.fromRGB(255,50,50), Text = Color3.fromRGB(200,255,200) },
    Halloween = { Main = Color3.fromRGB(15,5,20), Header = Color3.fromRGB(60,10,80),
        Button = Color3.fromRGB(30,5,40), Track = Color3.fromRGB(120,60,0),
        Accent = Color3.fromRGB(255,120,0), Text = Color3.fromRGB(255,220,150) },
    Valentine = { Main = Color3.fromRGB(45,5,25), Header = Color3.fromRGB(120,20,60),
        Button = Color3.fromRGB(70,10,40), Track = Color3.fromRGB(180,40,90),
        Accent = Color3.fromRGB(255,105,180), Text = Color3.fromRGB(255,210,230) },
}

-- ============================================================
-- DETECÇÃO DO HUB
-- ============================================================
local ScreenGui = PlayerGui:FindFirstChild("NoturnoHub") or PlayerGui:FindFirstChild("HelloKittyHub")
if not ScreenGui then
    warn("[" .. HUB_NAME .. "] Hub não encontrado. Execute o hub primeiro.")
    return
end

local Main = ScreenGui:FindFirstChild("Main")
local PagesContainer = Main and Main:FindFirstChild("PagesContainer")
local TrollPage = PagesContainer and PagesContainer:FindFirstChild("TROLL")
if not TrollPage then
    warn("[" .. HUB_NAME .. "] Aba TROLL não encontrada.")
    return
end

for _, child in ipairs(TrollPage:GetChildren()) do
    if child.Name == "TrollExtensionMarker" or child.Name == "TrollDLC_Layout" then
        child:Destroy()
    end
end

local function Create(className, properties, parent)
    local obj = Instance.new(className)
    for k,v in pairs(properties) do obj[k] = v end
    obj.Parent = parent
    return obj
end

Create("Folder", { Name = "TrollExtensionMarker" }, TrollPage)

-- ============================================================
-- TEMA
-- ============================================================
local function ColorDistance(a, b)
    return math.sqrt((a.R-b.R)^2 + (a.G-b.G)^2 + (a.B-b.B)^2)
end
local function DetectThemeName()
    local mc = Main.BackgroundColor3
    local bestName, bestDist = "Noturno", math.huge
    for name, palette in pairs(Themes) do
        local d = ColorDistance(mc, palette.Main)
        if d < bestDist then bestName, bestDist = name, d end
    end
    return bestName
end

local CurrentThemeName = DetectThemeName()
local Theme = Themes[CurrentThemeName] or Themes.Noturno

-- ============================================================
-- ESTADO
-- ============================================================
local TrollState = {
    NameSpoof = false,
    Stick = false,
    StickTarget = nil,
    StickConn = nil,
}

local AllUIElements = {}
local function Register(entry) table.insert(AllUIElements, entry) end

local function ApplyThemeToEntry(entry)
    local o = entry.Obj
    if not o or not o.Parent then return end
    if entry.Type == "Header" then
        o.TextColor3 = Theme.Text
    elseif entry.Type == "ToggleRow" then
        o.BackgroundColor3 = Theme.Button
        if entry.Label then entry.Label.TextColor3 = Theme.Text end
        if entry.Track then
            local isOn = entry.Track:GetAttribute("Active") == true
            entry.Track.BackgroundColor3 = isOn and Theme.Header or Theme.Track
            local stroke = entry.Track:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Theme.Accent
                stroke.Transparency = isOn and 0.3 or 0.7
            end
        end
    elseif entry.Type == "Button" then
        o.BackgroundColor3 = Theme.Button
        o.TextColor3 = Theme.Text
        local stroke = o:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = Theme.Accent end
    end
end

local function ReapplyTheme()
    for _, entry in ipairs(AllUIElements) do
        pcall(ApplyThemeToEntry, entry)
    end
end

-- ============================================================
-- HELPERS
-- ============================================================
local function GetRoot(player)
    local p = player or LocalPlayer
    local char = p.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- NAME SPOOF
-- ============================================================
local function ApplyNameSpoof(on)
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local old = head:FindFirstChild("__TrollNameSpoof")
    if old then old:Destroy() end

    if on then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "__TrollNameSpoof"
        billboard.Adornee = head
        billboard.Size = UDim2.fromOffset(200, 50)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "🌙 NOTURNO 🌙"
        label.TextColor3 = Color3.fromRGB(255, 215, 0)
        label.TextStrokeTransparency = 0.2
        label.Font = Enum.Font.GothamBold
        label.TextSize = 18
        label.Parent = billboard
    end
end

-- ============================================================
-- STICK TO PLAYER (ATRÁS do alvo)
-- ============================================================
local function StopStick()
    TrollState.Stick = false
    if TrollState.StickConn then
        pcall(function() TrollState.StickConn:Disconnect() end)
        TrollState.StickConn = nil
    end
end

local function StartStick(target)
    StopStick()
    if not target then return end
    TrollState.Stick = true
    TrollState.StickTarget = target

    TrollState.StickConn = RunService.Heartbeat:Connect(function()
        if not TrollState.Stick then return end
        local tRoot = GetRoot(target)
        local myRoot = GetRoot()
        if not tRoot or not myRoot then return end
        -- 2 studs ATRÁS do alvo (mesma orientação dele)
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end)
end

-- ============================================================
-- FLING (método correto: velocidade no PRÓPRIO personagem)
-- ============================================================
local FlingsBusy = false

local function FlingPlayer(target)
    if not target or target == LocalPlayer then return end
    local tChar = target.Character
    if not tChar then return end

    local myRoot = GetRoot(LocalPlayer)
    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return end

    -- Salva posição original do seu personagem
    local originalCFrame = myRoot.CFrame

    -- 1. Teleporta colado no alvo (para colidir)
    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.5)
    myRoot.AssemblyLinearVelocity = Vector3.zero

    -- 2. Aplica velocidade GIGANTE no SEU personagem (você controla)
    myRoot.AssemblyLinearVelocity = Vector3.new(
        math.random(-1000, 1000),
        math.random(500, 1000),
        math.random(-1000, 1000)
    )

    -- 3. Gira seu personagem para aumentar a transferência de energia
    myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 99999)

    -- 4. Espera a colisão acontecer
    task.wait(0.25)

    -- 5. Restaura seu personagem
    if myRoot and myRoot.Parent then
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
        myRoot.CFrame = originalCFrame
    end
end

-- ============================================================
-- UI HELPERS
-- ============================================================
local function AddHeader(parent, text, order)
    local lbl = Create("TextLabel", {
        Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1,
        Text = text, TextColor3 = Theme.Text, TextSize = 12,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = order or 1,
    }, parent)
    Register({ Type = "Header", Obj = lbl })
    return lbl
end

local function AddToggle(parent, title, initial, callback, order)
    local row = Create("Frame", {
        Size = UDim2.new(1,0,0,34), BackgroundColor3 = Theme.Button,
        BorderSizePixel = 0, LayoutOrder = order or 10,
    }, parent)
    Create("UICorner", { CornerRadius = UDim.new(0,7) }, row)
    local label = Create("TextLabel", {
        Size = UDim2.new(1,-60,1,0), Position = UDim2.fromOffset(10,0),
        BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text,
        TextSize = 11, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = Create("Frame", {
        Name = "ToggleTrack", Size = UDim2.fromOffset(36,20),
        Position = UDim2.new(1,-46,0.5,-10),
        BackgroundColor3 = initial and Theme.Header or Theme.Track,
        BorderSizePixel = 0,
    }, row)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, track)
    Create("UIStroke", { Color = Theme.Accent, Thickness = 1,
        Transparency = initial and 0.3 or 0.7 }, track)
    local knob = Create("Frame", {
        Size = UDim2.fromOffset(14,14),
        Position = initial and UDim2.new(1,-17,0,3) or UDim2.fromOffset(3,3),
        BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, track)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, knob)
    local hitbox = Create("TextButton", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false,
    }, row)
    track:SetAttribute("Active", initial)
    local function updateVisual(enabled)
        track:SetAttribute("Active", enabled)
        track.BackgroundColor3 = enabled and Theme.Header or Theme.Track
        knob.Position = enabled and UDim2.new(1,-17,0,3) or UDim2.fromOffset(3,3)
        local stroke = track:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Transparency = enabled and 0.3 or 0.7 end
    end
    hitbox.MouseButton1Click:Connect(function()
        if not hitbox.Active then return end
        local newState = not (track:GetAttribute("Active") == true)
        updateVisual(newState)
        callback(newState)
    end)
    Register({ Type = "ToggleRow", Obj = row, Label = label, Track = track })
    return { Row = row, SetState = updateVisual }
end

local function AddButton(parent, text, callback, order)
    local btn = Create("TextButton", {
        Size = UDim2.new(1,0,0,30), BackgroundColor3 = Theme.Button,
        Text = text, TextColor3 = Theme.Text, TextSize = 11,
        Font = Enum.Font.GothamBold, LayoutOrder = order or 10,
    }, parent)
    Create("UICorner", { CornerRadius = UDim.new(0,7) }, btn)
    Create("UIStroke", { Color = Theme.Accent, Thickness = 1, Transparency = 0.6 }, btn)
    btn.MouseButton1Click:Connect(callback)
    Register({ Type = "Button", Obj = btn })
    return btn
end

-- ============================================================
-- SELETOR DE JOGADOR
-- ============================================================
local SelectedPlayer = nil
local PlayerListBtn, PlayerList, RefreshList

local function SelectTarget(p)
    SelectedPlayer = p
    TrollState.StickTarget = p
    if PlayerListBtn and PlayerListBtn.Parent then
        PlayerListBtn.Text = p and ("🎯 Alvo: " .. p.Name .. "  ▼") or "🎯 Selecione um jogador  ▼"
    end
end

local function BuildPlayerSelector(parent, order)
    PlayerListBtn = AddButton(parent, "🎯 Selecione um jogador  ▼", function()
        if RefreshList then RefreshList() end
        if PlayerList then PlayerList.Visible = not PlayerList.Visible end
    end, order or 10)

    PlayerList = Create("Frame", {
        Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Visible = false,
        LayoutOrder = (order or 10) + 1,
    }, parent)
    Create("UIListLayout", { Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder }, PlayerList)

    RefreshList = function()
        for _, c in ipairs(PlayerList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local b = Create("TextButton", {
                    Size = UDim2.new(1,0,0,26), BackgroundColor3 = Theme.Track,
                    Text = p.Name, TextColor3 = Theme.Text, TextSize = 11,
                    Font = Enum.Font.Gotham, LayoutOrder = i,
                }, PlayerList)
                Create("UICorner", { CornerRadius = UDim.new(0,6) }, b)
                b.MouseButton1Click:Connect(function()
                    SelectTarget(p)
                    PlayerList.Visible = false
                end)
            end
        end
    end

    RefreshList()
end

-- ============================================================
-- LAYOUT
-- ============================================================
local LayoutFrame = Create("Frame", {
    Name = "TrollDLC_Layout",
    Size = UDim2.new(1,-6,0,0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 200,
}, TrollPage:FindFirstChild("Rows") or TrollPage)

local Col = Create("Frame", {
    Size = UDim2.new(1,0,0,0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
}, LayoutFrame)
Create("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder }, Col)

-- ============================================================
-- INJEÇÃO
-- ============================================================
AddHeader(Col, "🏷 NAME SPOOF", 1)
AddToggle(Col, "🏷 Mostrar '🌙 NOTURNO 🌙' acima de você", false, function(state)
    TrollState.NameSpoof = state
    ApplyNameSpoof(state)
end, 2)

AddHeader(Col, "👤 SELECIONAR JOGADOR", 3)
BuildPlayerSelector(Col, 4)

AddHeader(Col, "🎪 INTERAÇÃO", 6)
AddToggle(Col, "🧲 Stick to Player (grudar ATRÁS)", false, function(state)
    if state then
        if not SelectedPlayer then
            warn("[Troll] Selecione um jogador primeiro.")
            return
        end
        StartStick(SelectedPlayer)
    else
        StopStick()
    end
end, 7)

AddButton(Col, "💥 Fling (arremessar alvo)", function()
    if not SelectedPlayer then
        warn("[Troll] Selecione um jogador primeiro.")
        return
    end
    task.spawn(function() FlingPlayer(SelectedPlayer) end)
end, 8)

AddButton(Col, "💥 Fling TODOS", function()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                FlingPlayer(p)
                task.wait(0.3)
            end
        end
    end)
end, 9)

-- ============================================================
-- LOOP DE TEMA
-- ============================================================
task.spawn(function()
    local lastTheme = CurrentThemeName
    while ScreenGui.Parent and Main.Parent do
        local newName = DetectThemeName()
        if newName ~= lastTheme then
            lastTheme = newName
            Theme = Themes[newName] or Themes.Noturno
            CurrentThemeName = newName
            ReapplyTheme()
        end
        task.wait(1)
    end
end)

-- ============================================================
-- ROUNDSTART
-- ============================================================
local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
local Gameplay = Remotes and Remotes:FindFirstChild("Gameplay")
local RoundStart = Gameplay and Gameplay:FindFirstChild("RoundStart")
if RoundStart and RoundStart:IsA("RemoteEvent") then
    RoundStart.OnClientEvent:Connect(function()
        StopStick()
        if TrollState.NameSpoof then
            task.delay(0.5, function()
                ApplyNameSpoof(true)
            end)
        end
    end)
end

-- ============================================================
-- LIMPEZA
-- ============================================================
ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then
        StopStick()
        local char = LocalPlayer.Character
        if char then
            local head = char:FindFirstChild("Head")
            local spoof = head and head:FindFirstChild("__TrollNameSpoof")
            if spoof then spoof:Destroy() end
        end
    end
end)

print("[" .. HUB_NAME .. "] Extensão TROLL v" .. EXT_VERSION .. " | Tema: " .. CurrentThemeName)
