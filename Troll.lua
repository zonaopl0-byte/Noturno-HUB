--[[
    NOTURNO HUB - EXTENSÃO: ABA TROLL
     Versão: 2.6.2
     Base: v2.6.1

     Novidades v2.6.2:
       ✅ Injeta versão no ABOUT automaticamente (Indicador 3)
       ✅ NuclearLaunch verifica alvo antes de restaurar
       ✅ FlingBusy resetado no unload
       ✅ glueConn cancelado no unload
       ✅ StopStick(syncToggle) sincroniza UI
       ✅ SetFlingNoclip ignora partes de Tool
       ✅ ApplySpectateCamera com task.wait(0.1)
       ✅ DestroySpectateOverlay limpa AllUIElements
]]

local HUB_NAME = "NOTURNO HUB"
local EXT_VERSION = "2.6.2"

local SPOOF_TEXT = "Noturno HUB"
local CHAT_FALLBACK_ENABLED = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
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
local AboutPage = PagesContainer and PagesContainer:FindFirstChild("ABOUT")

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
    StickToggle = nil,
    StickMissFrames = 0,
}

local SpectateState = {
    Enabled = false,
    Target = nil,
    Conn = nil,
    Toggle = nil,
}

local SpectateOverlay = {}

-- ABOUT
local AboutCard = nil
local AboutCardStroke = nil
local AboutTitle = nil
local AboutVersion = nil

local AllUIElements = {}
local function Register(entry) table.insert(AllUIElements, entry) end

local function ApplyThemeToEntry(entry)
    local o = entry.Obj
    if not o or not o.Parent then return end
    if entry.Type == "Header" then
        o.TextColor3 = Theme.Text
    elseif entry.Type == "Divider" then
        o.BackgroundColor3 = Theme.Track
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
    elseif entry.Type == "FloatingOverlay" then
        o.BackgroundColor3 = Theme.Main
        local stroke = o:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = Theme.Accent end
    elseif entry.Type == "FloatingButton" then
        o.BackgroundColor3 = Theme.Button
        o.TextColor3 = Theme.Text
    elseif entry.Type == "FloatingLabel" then
        o.TextColor3 = Theme.Accent
    end
end

local function ReapplyTheme()
    for _, entry in ipairs(AllUIElements) do
        pcall(ApplyThemeToEntry, entry)
    end
    -- ABOUT
    if AboutCard and AboutCard.Parent then AboutCard.BackgroundColor3 = Theme.Button end
    if AboutCardStroke and AboutCardStroke.Parent then AboutCardStroke.Color = Theme.Accent end
    if AboutTitle and AboutTitle.Parent then AboutTitle.TextColor3 = Theme.Text end
    if AboutVersion and AboutVersion.Parent then AboutVersion.TextColor3 = Theme.Accent end
end

-- ============================================================
-- ✅ INJEÇÃO NO ABOUT (Indicador 3)
-- ============================================================
local function FindAboutRows()
    if not AboutPage then
        AboutPage = PagesContainer and PagesContainer:FindFirstChild("ABOUT")
    end
    if not AboutPage then return nil end
    return AboutPage:FindFirstChild("Rows")
end

local function FindEmptySlotInRows(rows)
    if not rows then return nil end
    local lines = {}
    for _, child in ipairs(rows:GetChildren()) do
        if child:IsA("Frame") then
            local layout = child:FindFirstChildOfClass("UIListLayout")
            if layout and layout.FillDirection == Enum.FillDirection.Horizontal then
                table.insert(lines, child)
            end
        end
    end
    table.sort(lines, function(a,b) return a.LayoutOrder < b.LayoutOrder end)

    for _, line in ipairs(lines) do
        for _, card in ipairs(line:GetChildren()) do
            if card:IsA("Frame") then
                -- ✅ Pula cards já injetados por outras extensões
                local injectedBy = card:GetAttribute("InjectedBy")
                if injectedBy and injectedBy ~= "Troll" then
                    -- não é nosso, pula
                else
                    local hasText = false
                    for _, desc in ipairs(card:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Text and desc.Text ~= "" then
                            hasText = true
                            break
                        end
                    end
                    if not hasText then
                        return card
                    end
                end
            end
        end
    end
    return nil
end

local function CreateAboutCard(rows)
    if not rows then return nil end
    local card = Create("Frame", {
        Size = UDim2.new(0.47,0,0,70),
        BackgroundColor3 = Theme.Button,
        BorderSizePixel = 0,
        LayoutOrder = 960,
    }, rows)
    Create("UICorner", { CornerRadius = UDim.new(0,8) }, card)
    local stroke = Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.5 }, card)
    return card, stroke
end

local function FillAboutCard(card, stroke)
    if not card or not card.Parent then return end
    for _, child in ipairs(card:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    card:SetAttribute("InjectedBy", "Troll")

    AboutTitle = Create("TextLabel", {
        Size = UDim2.new(1,0,0,26),
        Position = UDim2.fromOffset(0,12),
        BackgroundTransparency = 1,
        Text = "😈 Troll",
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center
    }, card)

    AboutVersion = Create("TextLabel", {
        Size = UDim2.new(1,0,0,20),
        Position = UDim2.fromOffset(0,38),
        BackgroundTransparency = 1,
        Text = "Versão: " .. EXT_VERSION,
        TextColor3 = Theme.Accent,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center
    }, card)

    AboutCard = card
    AboutCardStroke = stroke
end

local function InjectAboutVersion()
    local rows = FindAboutRows()
    if not rows then return end

    if AboutCard and AboutCard.Parent then
        if AboutVersion and AboutVersion.Parent then
            AboutVersion.Text = "Versão: " .. EXT_VERSION
            AboutVersion.TextColor3 = Theme.Accent
        end
        if AboutTitle and AboutTitle.Parent then
            AboutTitle.TextColor3 = Theme.Text
        end
        if AboutCardStroke and AboutCardStroke.Parent then
            AboutCardStroke.Color = Theme.Accent
        end
        if AboutCard then AboutCard.BackgroundColor3 = Theme.Button end
        return
    end

    local slot = FindEmptySlotInRows(rows)
    local stroke
    if slot then
        stroke = slot:FindFirstChildOfClass("UIStroke")
        FillAboutCard(slot, stroke)
        print("[" .. HUB_NAME .. "] Indicador Troll injetado em slot existente.")
    else
        local newCard, newStroke = CreateAboutCard(rows)
        if newCard then
            FillAboutCard(newCard, newStroke)
            print("[" .. HUB_NAME .. "] Indicador Troll criado em novo card.")
        end
    end
end

local function RemoveAboutInjection()
    if AboutCard and AboutCard.Parent then
        AboutCard:Destroy()
    end
    AboutCard = nil
    AboutCardStroke = nil
    AboutTitle = nil
    AboutVersion = nil
end

-- ============================================================
-- HELPERS
-- ============================================================
local function GetRoot(player)
    local p = player or LocalPlayer
    local char = p.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsToolPart(part)
    local p = part
    while p and p ~= LocalPlayer.Character do
        if p:IsA("Tool") then return true end
        p = p.Parent
    end
    return false
end

-- ============================================================
-- CHAT FALLBACK
-- ============================================================
local function SendChatFallback()
    if not CHAT_FALLBACK_ENABLED then return end
    pcall(function()
        local channels = TextChatService:FindFirstChild("TextChannels")
        local general = channels and channels:FindFirstChild("RBXGeneral")
        if general then
            general:SendAsync(SPOOF_TEXT)
        end
    end)
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
        billboard.Size = UDim2.fromOffset(220, 50)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = SPOOF_TEXT
        label.TextColor3 = Color3.fromRGB(160, 120, 255)
        label.TextStrokeTransparency = 0.2
        label.TextStrokeColor3 = Color3.fromRGB(28, 22, 40)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 20
        label.Parent = billboard

        SendChatFallback()
    end
end

-- ============================================================
-- STICK TO PLAYER (com syncToggle)
-- ============================================================
local STICK_GRACE_FRAMES = 30

local function StopStick(syncToggle)
    TrollState.Stick = false
    TrollState.StickTarget = nil
    TrollState.StickMissFrames = 0
    if TrollState.StickConn then
        pcall(function() TrollState.StickConn:Disconnect() end)
        TrollState.StickConn = nil
    end
    if syncToggle and TrollState.StickToggle then
        TrollState.StickToggle.SetState(false)
    end
end

local function StartStick(target)
    StopStick(false)
    if not target then return end
    TrollState.Stick = true
    TrollState.StickTarget = target
    TrollState.StickMissFrames = 0

    TrollState.StickConn = RunService.Heartbeat:Connect(function()
        if not TrollState.Stick then return end
        if not target or not target.Parent then
            StopStick(true)
            return
        end
        local myRoot = GetRoot()
        if not myRoot then return end
        local tRoot = GetRoot(target)
        if not tRoot then
            TrollState.StickMissFrames = TrollState.StickMissFrames + 1
            if TrollState.StickMissFrames >= STICK_GRACE_FRAMES then
                StopStick(true)
            end
            return
        end
        TrollState.StickMissFrames = 0
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end)
end

-- ============================================================
-- SPECTATE
-- ============================================================
local AdvanceSpectate

local function GetSpectateCandidates()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(list, p)
            end
        end
    end
    return list
end

local function UpdateSpectateLabel()
    local frame = SpectateOverlay.Frame
    if not frame or not frame.Parent then return end
    if SpectateState.Enabled then
        frame.Visible = true
        local lbl = SpectateOverlay.Label
        if lbl and lbl.Parent then
            if SpectateState.Target and SpectateState.Target.Parent then
                lbl.Text = "👁 " .. SpectateState.Target.Name
            else
                lbl.Text = "👁 (procurando...)"
            end
        end
    else
        frame.Visible = false
    end
end

local function ApplySpectateCamera()
    if not SpectateState.Enabled then return end
    local t = SpectateState.Target
    if not t or not t.Parent then
        if AdvanceSpectate then
            AdvanceSpectate(1)
            task.wait(0.1)  -- ✅ evita loop apertado
        end
        return
    end
    local tHum = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera
    if tHum and cam and cam.CameraSubject ~= tHum then
        cam.CameraSubject = tHum
    end
end

local function StartSpectateAt(target)
    if not target then return end
    SpectateState.Enabled = true
    SpectateState.Target = target
    if not SpectateState.Conn then
        SpectateState.Conn = RunService.Heartbeat:Connect(ApplySpectateCamera)
    end
    ApplySpectateCamera()
    UpdateSpectateLabel()
end

local function StopSpectate(resetToggle)
    SpectateState.Enabled = false
    SpectateState.Target = nil
    if SpectateState.Conn then
        pcall(function() SpectateState.Conn:Disconnect() end)
        SpectateState.Conn = nil
    end
    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera
    if myHum and cam then cam.CameraSubject = myHum end
    if resetToggle and SpectateState.Toggle then
        SpectateState.Toggle.SetState(false)
    end
    UpdateSpectateLabel()
end

AdvanceSpectate = function(direction)
    local candidates = GetSpectateCandidates()
    if #candidates == 0 then
        StopSpectate(true)
        return
    end
    local currentIdx
    for i, p in ipairs(candidates) do
        if p == SpectateState.Target then currentIdx = i; break end
    end
    direction = direction or 1
    local newIdx
    if not currentIdx then
        newIdx = (direction >= 0) and 1 or #candidates
    else
        newIdx = ((currentIdx - 1 + direction) % #candidates) + 1
    end
    SpectateState.Target = candidates[newIdx]
    UpdateSpectateLabel()
end

-- ============================================================
-- SPECTATE OVERLAY
-- ============================================================
local function IsPointOverButton(frame, point)
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextButton") and child.Visible then
            local ap, as = child.AbsolutePosition, child.AbsoluteSize
            if point.X >= ap.X and point.X <= ap.X + as.X
               and point.Y >= ap.Y and point.Y <= ap.Y + as.Y then
                return true
            end
        end
    end
    return false
end

local function CreateSpectateOverlay()
    local gui = Instance.new("ScreenGui")
    gui.Name = "Noturno_Troll_SpectateOverlay"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10000
    gui.IgnoreGuiInset = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mounted = false
    pcall(function()
        local hui = gethui and gethui()
        if hui and typeof(hui) == "Instance" then
            gui.Parent = hui
            mounted = true
        end
    end)
    if not mounted then
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
    end
    if not gui.Parent then
        gui.Parent = PlayerGui
    end

    local frame = Create("Frame", {
        Name = "Overlay",
        Size = UDim2.fromOffset(380, 44),
        Position = UDim2.new(0.5, -190, 1, -60),
        BackgroundColor3 = Theme.Main,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Visible = false,
        Active = true,
    }, gui)
    Create("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
    Create("UIStroke", {
        Color = Theme.Accent, Thickness = 1, Transparency = 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, frame)

    local prevBtn = Create("TextButton", {
        Size = UDim2.new(0, 76, 1, -8),
        Position = UDim2.fromOffset(4, 4),
        BackgroundColor3 = Theme.Button,
        Text = "⏮ Anterior",
        TextColor3 = Theme.Text, TextSize = 10,
        Font = Enum.Font.GothamBold, BorderSizePixel = 0,
        Active = true, AutoButtonColor = false, ZIndex = 2,
    }, frame)
    Create("UICorner", { CornerRadius = UDim.new(0, 7) }, prevBtn)

    local nextBtn = Create("TextButton", {
        Size = UDim2.new(0, 76, 1, -8),
        Position = UDim2.fromOffset(276, 4),
        BackgroundColor3 = Theme.Button,
        Text = "⏭ Próximo",
        TextColor3 = Theme.Text, TextSize = 10,
        Font = Enum.Font.GothamBold, BorderSizePixel = 0,
        Active = true, AutoButtonColor = false, ZIndex = 2,
    }, frame)
    Create("UICorner", { CornerRadius = UDim.new(0, 7) }, nextBtn)

    local label = Create("TextLabel", {
        Size = UDim2.new(0, 188, 1, -8),
        Position = UDim2.fromOffset(84, 4),
        BackgroundTransparency = 1,
        Text = "👁 (procurando...)",
        TextColor3 = Theme.Accent, TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 2,
    }, frame)

    local closeBtn = Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.fromOffset(356, 12),
        BackgroundColor3 = Color3.fromRGB(200, 40, 40),
        Text = "✕",
        TextColor3 = Color3.new(1, 1, 1), TextSize = 12,
        Font = Enum.Font.GothamBold, BorderSizePixel = 0,
        Active = true, AutoButtonColor = false, ZIndex = 3,
    }, frame)
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, closeBtn)

    local dragging = false
    local dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if IsPointOverButton(frame, input.Position) then return end
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end)
    local dragConn = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        local vp = workspace.CurrentCamera.ViewportSize
        local newX = math.clamp(startPos.X.Offset + delta.X, -frame.AbsoluteSize.X + 40, vp.X - 40)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - 40)
        frame.Position = UDim2.fromOffset(newX, newY)
    end)
    local dragEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    prevBtn.MouseButton1Click:Connect(function()
        if SpectateState.Enabled then AdvanceSpectate(-1) end
    end)
    nextBtn.MouseButton1Click:Connect(function()
        if SpectateState.Enabled then AdvanceSpectate(1) end
    end)
    closeBtn.MouseButton1Click:Connect(function()
        StopSpectate(true)
    end)

    Register({ Type = "FloatingOverlay", Obj = frame })
    Register({ Type = "FloatingButton", Obj = prevBtn })
    Register({ Type = "FloatingButton", Obj = nextBtn })
    Register({ Type = "FloatingLabel", Obj = label })

    SpectateOverlay.Gui = gui
    SpectateOverlay.Frame = frame
    SpectateOverlay.Label = label
    SpectateOverlay.DragConn = dragConn
    SpectateOverlay.DragEndConn = dragEndConn
end

-- ============================================================
-- FLING v2.2 (modo nuclear)
-- ============================================================
local FLING_FORCE        = 450000
local FLING_TIME         = 5.0
local FLING_TARGET_PUSH  = 25000
local FLING_TARGET_SPIN  = 180000
local FLING_INJECT_EVERY = 3

local FLING_NUKE_ENABLED = true
local FLING_NUKE_VEL     = 1000000
local FLING_NUKE_SPIN    = 100000
local FLING_NUKE_HOLD    = 5.0

local FlingBusy = false
local FlingSavedCollide = {}
local FlingNoclipConn = nil
local ActiveGlueConn = nil
local ActiveSpin = nil
local ActiveTargetSpin = nil

local function SetFlingNoclip(enabled)
    if FlingNoclipConn then
        pcall(function() FlingNoclipConn:Disconnect() end)
        FlingNoclipConn = nil
    end
    if not enabled then
        for part, canCollide in pairs(FlingSavedCollide) do
            if part.Parent then part.CanCollide = canCollide end
        end
        table.clear(FlingSavedCollide)
        return
    end
    FlingNoclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and not IsToolPart(part) then
                if FlingSavedCollide[part] == nil then
                    FlingSavedCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)
end

local function NuclearLaunch(target)
    local targetRoot = GetRoot(target)
    if not targetRoot or not targetRoot.Parent then return end

    local targetChar = target.Character
    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHum then return end

    local savedState = targetHum:GetState()
    local savedPlatformStand = targetHum.PlatformStand
    local savedWalkSpeed = targetHum.WalkSpeed

    pcall(function()
        targetHum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        targetHum:ChangeState(Enum.HumanoidStateType.Physics)
        targetHum.PlatformStand = true
        targetHum.WalkSpeed = 0
    end)

    local bv = Instance.new("BodyVelocity")
    bv.Name = "__TrollNukeVel"
    bv.MaxForce = Vector3.new(1e12, 1e12, 1e12)
    bv.P = 1e6
    bv.Velocity = Vector3.new(0, FLING_NUKE_VEL, 0)
    pcall(function() bv.Parent = targetRoot end)

    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "__TrollNukeSpin"
    bav.MaxTorque = Vector3.new(1e12, 1e12, 1e12)
    bav.P = 1e6
    bav.AngularVelocity = Vector3.new(FLING_NUKE_SPIN, FLING_NUKE_SPIN, FLING_NUKE_SPIN)
    pcall(function() bav.Parent = targetRoot end)

    local started = os.clock()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if os.clock() - started >= FLING_NUKE_HOLD then
            if conn then conn:Disconnect() end
            return
        end
        local currentRoot = GetRoot(target)
        local currentHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if not currentRoot or not currentHum then return end
        pcall(function()
            currentRoot.AssemblyLinearVelocity = Vector3.new(0, FLING_NUKE_VEL, 0)
            currentRoot.AssemblyAngularVelocity = Vector3.new(FLING_NUKE_SPIN, FLING_NUKE_SPIN, FLING_NUKE_SPIN)
            if currentHum:GetState() ~= Enum.HumanoidStateType.Physics then
                currentHum:ChangeState(Enum.HumanoidStateType.Physics)
            end
            if not currentHum.PlatformStand then
                currentHum.PlatformStand = true
            end
            if bv.Parent ~= currentRoot then bv.Parent = currentRoot end
            if bav.Parent ~= currentRoot then bav.Parent = currentRoot end
        end)
    end)

    task.delay(FLING_NUKE_HOLD, function()
        if bv and bv.Parent then bv:Destroy() end
        if bav and bav.Parent then bav:Destroy() end
        -- ✅ verifica se o alvo ainda existe antes de restaurar
        local t = target
        if not t or not t.Parent then return end
        local currentChar = t.Character
        if not currentChar then return end
        local currentHum = currentChar:FindFirstChildOfClass("Humanoid")
        if currentHum and currentHum.Parent then
            pcall(function()
                currentHum.PlatformStand = savedPlatformStand
                currentHum.WalkSpeed = savedWalkSpeed
                currentHum:ChangeState(savedState)
            end)
        end
    end)
end

local function FlingPlayer(target, duration)
    if not target or target == LocalPlayer then return false end
    if FlingBusy then return false end
    local root = GetRoot()
    if not root then return false end

    FlingBusy = true
    duration = duration or FLING_TIME
    local home = root.CFrame

    ActiveSpin = Instance.new("BodyAngularVelocity")
    ActiveSpin.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    ActiveSpin.AngularVelocity = Vector3.new(FLING_FORCE * 0.3, FLING_FORCE, FLING_FORCE * 0.3)
    ActiveSpin.Parent = root

    ActiveTargetSpin = Instance.new("BodyAngularVelocity")
    ActiveTargetSpin.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    ActiveTargetSpin.AngularVelocity = Vector3.zero

    SetFlingNoclip(true)

    local started = os.clock()
    local frameCount = 0

    ActiveGlueConn = RunService.Stepped:Connect(function()
        if not root.Parent then return end
        if os.clock() - started >= duration then return end
        local currentTarget = GetRoot(target)
        if not currentTarget then return end
        root.CFrame = currentTarget.CFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = ActiveSpin.AngularVelocity

        if ActiveTargetSpin.Parent ~= currentTarget then
            ActiveTargetSpin.Parent = currentTarget
        end

        frameCount = frameCount + 1
        if frameCount % FLING_INJECT_EVERY == 0 then
            pcall(function()
                currentTarget.AssemblyLinearVelocity = Vector3.new(
                    math.random(-FLING_TARGET_PUSH, FLING_TARGET_PUSH),
                    FLING_TARGET_PUSH * 2,
                    math.random(-FLING_TARGET_PUSH, FLING_TARGET_PUSH)
                )
                currentTarget.AssemblyAngularVelocity = Vector3.new(
                    math.random(-FLING_TARGET_SPIN, FLING_TARGET_SPIN),
                    FLING_TARGET_SPIN,
                    math.random(-FLING_TARGET_SPIN, FLING_TARGET_SPIN)
                )
            end)
            if ActiveTargetSpin.Parent then
                ActiveTargetSpin.AngularVelocity = Vector3.new(
                    FLING_TARGET_SPIN, FLING_TARGET_SPIN, FLING_TARGET_SPIN
                )
            end
        end
    end)

    task.wait(duration)

    if ActiveGlueConn then ActiveGlueConn:Disconnect(); ActiveGlueConn = nil end
    if ActiveSpin then ActiveSpin:Destroy(); ActiveSpin = nil end
    if ActiveTargetSpin and ActiveTargetSpin.Parent then ActiveTargetSpin:Destroy() end
    ActiveTargetSpin = nil

    if FLING_NUKE_ENABLED then
        NuclearLaunch(target)
    else
        local finalTarget = GetRoot(target)
        if finalTarget and finalTarget.Parent then
            pcall(function()
                finalTarget.AssemblyLinearVelocity = Vector3.new(
                    math.random(-8000, 8000), 50000, math.random(-8000, 8000)
                )
                finalTarget.AssemblyAngularVelocity = Vector3.new(
                    math.random(-200000, 200000),
                    math.random(-200000, 200000),
                    math.random(-200000, 200000)
                )
            end)
        end
    end

    if root.Parent then
        root.AssemblyAngularVelocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = home
    end
    SetFlingNoclip(false)
    FlingBusy = false
    return true
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

local function AddDivider(parent, order)
    local line = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Track,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        LayoutOrder = order or 5,
    }, parent)
    Register({ Type = "Divider", Obj = line })
    return line
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

local function AddButton(parent, text, callback, order, sizeOverride)
    local btn = Create("TextButton", {
        Size = sizeOverride or UDim2.new(1,0,0,30),
        BackgroundColor3 = Theme.Button,
        Text = text, TextColor3 = Theme.Text, TextSize = 11,
        Font = Enum.Font.GothamBold, LayoutOrder = order or 10,
    }, parent)
    Create("UICorner", { CornerRadius = UDim.new(0,7) }, btn)
    Create("UIStroke", { Color = Theme.Accent, Thickness = 1, Transparency = 0.6 }, btn)
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    Register({ Type = "Button", Obj = btn })
    return btn
end

local function AddButtonRow(parent, buttons, order)
    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = order or 10,
    }, parent)
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, row)
    local count = #buttons
    local pad = 8
    for i, spec in ipairs(buttons) do
        local size = UDim2.new(1/count, -(pad * (count - 1) / count), 1, 0)
        AddButton(row, spec.Text, spec.Callback, i, size)
    end
    return row
end

-- ============================================================
-- SELETOR DE JOGADOR
-- ============================================================
local SelectedPlayer = nil
local PlayerListBtn, PlayerList, RefreshList

local function SelectTarget(p)
    SelectedPlayer = p
    TrollState.StickTarget = p
    if TrollState.Stick and p then
        StartStick(p)
    end
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
-- CRIA OVERLAY
-- ============================================================
CreateSpectateOverlay()

-- ============================================================
-- INJEÇÃO
-- ============================================================
AddHeader(Col, "🏷 NAME SPOOF", 1)
AddToggle(Col, "Mostrar 'Noturno HUB' acima de você", false, function(state)
    TrollState.NameSpoof = state
    ApplyNameSpoof(state)
end, 2)

AddDivider(Col, 3)

AddHeader(Col, "👤 SELECIONAR JOGADOR", 4)
BuildPlayerSelector(Col, 5)

AddDivider(Col, 6)

AddHeader(Col, "🎪 AÇÕES", 7)

TrollState.StickToggle = AddToggle(Col, "🧲 Stick to Player (grudar ATRÁS)", false, function(state)
    if state then
        if not SelectedPlayer then
            warn("[Troll] Selecione um jogador primeiro.")
            if TrollState.StickToggle then TrollState.StickToggle.SetState(false) end
            return
        end
        StartStick(SelectedPlayer)
    else
        StopStick(false)
    end
end, 8)

SpectateState.Toggle = AddToggle(Col, "👁 Spectate (botões flutuantes)", false, function(state)
    if state then
        local candidates = GetSpectateCandidates()
        if #candidates == 0 then
            warn("[Troll] Nenhum jogador vivo disponível para spectar.")
            if SpectateState.Toggle then SpectateState.Toggle.SetState(false) end
            return
        end
        StartSpectateAt(candidates[1])
    else
        StopSpectate(false)
    end
end, 9)

-- ============================================================
-- BOTÕES DE NUKE
-- ============================================================
local NukeTodosArmed = false
local NukeTodosTimer = nil
local NUKE_TODOS_CONFIRM_TIME = 3

AddButtonRow(Col, {
    { Text = "☢️ Nuke (infinito)", Callback = function()
        if not SelectedPlayer then
            warn("[Troll] Selecione um jogador primeiro.")
            return
        end
        task.spawn(function() FlingPlayer(SelectedPlayer) end)
    end },

    { Text = "☢️ Nuke TODOS", Callback = function(btn)
        if NukeTodosArmed then
            NukeTodosArmed = false
            if NukeTodosTimer then pcall(task.cancel, NukeTodosTimer); NukeTodosTimer = nil end
            if btn and btn.Parent then
                btn.Text = "☢️ Nuke TODOS"
                pcall(function() btn.BackgroundColor3 = Theme.Button end)
            end
            task.spawn(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        pcall(FlingPlayer, p, 1.2)
                        task.wait(0.15)
                    end
                end
            end)
            return
        end
        NukeTodosArmed = true
        if btn and btn.Parent then
            btn.Text = "⚠️ CONFIRMAR? (" .. NUKE_TODOS_CONFIRM_TIME .. "s)"
            pcall(function() btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40) end)
        end
        if NukeTodosTimer then pcall(task.cancel, NukeTodosTimer) end
        NukeTodosTimer = task.delay(NUKE_TODOS_CONFIRM_TIME, function()
            NukeTodosArmed = false
            NukeTodosTimer = nil
            if btn and btn.Parent then
                btn.Text = "☢️ Nuke TODOS"
                pcall(function() btn.BackgroundColor3 = Theme.Button end)
            end
        end)
    end },
}, 10)

-- ============================================================
-- ✅ INJETA A VERSÃO NO ABOUT
-- ============================================================
task.spawn(function()
    task.wait(0.7)
    pcall(InjectAboutVersion)
end)

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
            UpdateSpectateLabel()
        end
        task.wait(1)
    end
end)

-- Loop de manutenção do ABOUT
task.spawn(function()
    while ScreenGui.Parent do
        pcall(function()
            if not AboutCard or not AboutCard.Parent then
                InjectAboutVersion()
            elseif AboutVersion and AboutVersion.Parent then
                if AboutVersion.Text ~= "Versão: " .. EXT_VERSION then
                    AboutVersion.Text = "Versão: " .. EXT_VERSION
                end
            end
        end)
        task.wait(3)
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
        StopStick(true)
        StopSpectate(true)
        if TrollState.NameSpoof then
            task.delay(0.5, function() ApplyNameSpoof(true) end)
        end
        pcall(InjectAboutVersion)
    end)
end

-- ============================================================
-- LIMPEZA
-- ============================================================
local function DestroySpectateOverlay()
    if SpectateOverlay.DragConn then
        pcall(function() SpectateOverlay.DragConn:Disconnect() end)
        SpectateOverlay.DragConn = nil
    end
    if SpectateOverlay.DragEndConn then
        pcall(function() SpectateOverlay.DragEndConn:Disconnect() end)
        SpectateOverlay.DragEndConn = nil
    end
    if SpectateOverlay.Gui then
        pcall(function() SpectateOverlay.Gui:Destroy() end)
        SpectateOverlay.Gui = nil
        SpectateOverlay.Frame = nil
        SpectateOverlay.Label = nil
    end
    -- ✅ limpa registros da UI destruída
    for i = #AllUIElements, 1, -1 do
        local e = AllUIElements[i]
        if e.Type == "FloatingOverlay" or e.Type == "FloatingButton" or e.Type == "FloatingLabel" then
            if not e.Obj or not e.Obj.Parent then
                table.remove(AllUIElements, i)
            end
        end
    end
end

ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then
        StopStick(false)
        StopSpectate(false)
        SetFlingNoclip(false)

        -- ✅ reseta flag de fling e cancela conexões pendentes
        FlingBusy = false
        if ActiveGlueConn then pcall(function() ActiveGlueConn:Disconnect() end); ActiveGlueConn = nil end
        if ActiveSpin then pcall(function() ActiveSpin:Destroy() end); ActiveSpin = nil end
        if ActiveTargetSpin then pcall(function() ActiveTargetSpin:Destroy() end); ActiveTargetSpin = nil end

        DestroySpectateOverlay()

        if NukeTodosTimer then pcall(task.cancel, NukeTodosTimer); NukeTodosTimer = nil end
        NukeTodosArmed = false

        local char = LocalPlayer.Character
        if char then
            local head = char:FindFirstChild("Head")
            local spoof = head and head:FindFirstChild("__TrollNameSpoof")
            if spoof then spoof:Destroy() end
        end

        pcall(RemoveAboutInjection)
    end
end)

print("[" .. HUB_NAME .. "] Extensão TROLL v" .. EXT_VERSION .. " | Tema: " .. CurrentThemeName)
print("[About] Versão do Troll injetada automaticamente no Indicador 3")
