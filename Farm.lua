--[[
    NOTURNO HUB - EXTENSÃO: ABA FARM
     Versão: 1.0.9
     Base: 1.0.8

     Novidades 1.0.9:
       ✅ Injeta versão no ABOUT automaticamente (Indicador 4)
       ✅ Previne duplicação ao recarregar (FarmActive attribute)
       ✅ SignalConns órfãs limpas antes de reiniciar
       ✅ CharacterAdded com task.delay (não trava evento)
       ✅ PickFarmTarget com early-exit (< 5 studs)
       ✅ CoinCollected verifica se é do LocalPlayer

     Herdado de 1.0.8:
       - Noclip só ativo durante movimento real do farm
     Herdado de 1.0.7:
       - Fallback conservador de detecção de round
]]

local HUB_NAME = "NOTURNO HUB"
local EXT_VERSION = "1.0.9"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- PALETA
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
-- DETECÇÃO
-- ============================================================
local ScreenGui = PlayerGui:FindFirstChild("NoturnoHub")
    or PlayerGui:FindFirstChild("HelloKittyHub")
if not ScreenGui then
    warn("[" .. HUB_NAME .. "] Hub não encontrado. Execute o hub primeiro.")
    return
end

local Main = ScreenGui:FindFirstChild("Main")
local PagesContainer = Main and Main:FindFirstChild("PagesContainer")
local FarmPage = PagesContainer and PagesContainer:FindFirstChild("FARM")
local AboutPage = PagesContainer and PagesContainer:FindFirstChild("ABOUT")

if not FarmPage then
    warn("[" .. HUB_NAME .. "] Aba FARM não encontrada.")
    return
end

-- ✅ FIX: se já estava ativo, limpa primeiro
if ScreenGui:GetAttribute("FarmActive") == true then
    local oldCleanup = ScreenGui:GetAttribute("FarmCleanup")
    if type(oldCleanup) == "function" then
        pcall(oldCleanup)
    end
end
ScreenGui:SetAttribute("FarmActive", true)

for _, child in ipairs(FarmPage:GetChildren()) do
    if child.Name == "FarmExtensionMarker" or child.Name == "FarmDLC_Layout" then
        child:Destroy()
    end
end

local function Create(className, properties, parent)
    local obj = Instance.new(className)
    for k,v in pairs(properties) do obj[k] = v end
    obj.Parent = parent
    return obj
end

Create("Folder", { Name = "FarmExtensionMarker" }, FarmPage)

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

local AllUIElements = {}
local function Register(entry) table.insert(AllUIElements, entry) end

-- ABOUT
local AboutCard = nil
local AboutCardStroke = nil
local AboutTitle = nil
local AboutVersion = nil

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
    elseif entry.Type == "Slider" then
        o.BackgroundColor3 = Theme.Button
        if entry.Label then entry.Label.TextColor3 = Theme.Text end
        if entry.Bar then entry.Bar.BackgroundColor3 = Theme.Track end
    elseif entry.Type == "BagProgress" then
        o.BackgroundColor3 = Theme.Button
        if entry.Title then entry.Title.TextColor3 = Theme.Text end
        if entry.Bg then entry.Bg.BackgroundColor3 = Theme.Track end
    elseif entry.Type == "Status" then
        o.TextColor3 = Theme.Text
    end
end

local function ReapplyTheme()
    for _, entry in ipairs(AllUIElements) do
        pcall(ApplyThemeToEntry, entry)
    end
    if AboutCard and AboutCard.Parent then AboutCard.BackgroundColor3 = Theme.Button end
    if AboutCardStroke and AboutCardStroke.Parent then AboutCardStroke.Color = Theme.Accent end
    if AboutTitle and AboutTitle.Parent then AboutTitle.TextColor3 = Theme.Text end
    if AboutVersion and AboutVersion.Parent then AboutVersion.TextColor3 = Theme.Accent end
end

-- ============================================================
-- INJEÇÃO NO ABOUT (Indicador 4)
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
                local injectedBy = card:GetAttribute("InjectedBy")
                if not injectedBy or injectedBy == "Farm" then
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
        LayoutOrder = 970,
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
    card:SetAttribute("InjectedBy", "Farm")

    AboutTitle = Create("TextLabel", {
        Size = UDim2.new(1,0,0,26),
        Position = UDim2.fromOffset(0,12),
        BackgroundTransparency = 1,
        Text = "💰 Farm",
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
        if AboutTitle and AboutTitle.Parent then AboutTitle.TextColor3 = Theme.Text end
        if AboutCardStroke and AboutCardStroke.Parent then AboutCardStroke.Color = Theme.Accent end
        if AboutCard then AboutCard.BackgroundColor3 = Theme.Button end
        return
    end
    local slot = FindEmptySlotInRows(rows)
    local stroke
    if slot then
        stroke = slot:FindFirstChildOfClass("UIStroke")
        FillAboutCard(slot, stroke)
        print("[" .. HUB_NAME .. "] Indicador Farm injetado em slot existente.")
    else
        local newCard, newStroke = CreateAboutCard(rows)
        if newCard then
            FillAboutCard(newCard, newStroke)
            print("[" .. HUB_NAME .. "] Indicador Farm criado em novo card.")
        end
    end
end

local function RemoveAboutInjection()
    if AboutCard and AboutCard.Parent then AboutCard:Destroy() end
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

local function GetHumanoid(player)
    local p = player or LocalPlayer
    local char = p.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsTargetStillValid(coin)
    if not coin or not coin.Parent or not coin:IsA("BasePart") then return false end
    if coin:GetAttribute("Collected") == true then return false end
    return true
end

local function GetCoinContainer()
    local map = workspace:FindFirstChild("Map")
    if map then
        local c = map:FindFirstChild("CoinContainer", true)
        if c then return c end
    end
    return workspace:FindFirstChild("CoinContainer", true)
end

local function HasRoundTool()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local hasKnife = (char and char:FindFirstChild("Knife"))
        or (backpack and backpack:FindFirstChild("Knife"))
    local hasGun = (char and char:FindFirstChild("Gun"))
        or (backpack and backpack:FindFirstChild("Gun"))
    return hasKnife or hasGun
end

local function IsNearMap(root)
    local map = workspace:FindFirstChild("Map")
    if not map or not map:IsA("Model") then return false end
    local ok, cframe, size = pcall(function() return map:GetBoundingBox() end)
    local mapCFrame, mapSize
    if ok and type(cframe) == "CFrame" and typeof(size) == "Vector3" then
        mapCFrame, mapSize = cframe, size
    else
        local primary = map.PrimaryPart or map:FindFirstChildWhichIsA("BasePart", true)
        if not primary then return false end
        mapCFrame = primary.CFrame
        mapSize = Vector3.new(200, 200, 200)
    end
    local dist = (root.Position - mapCFrame.Position).Magnitude
    local radius = math.max(mapSize.X, mapSize.Y, mapSize.Z) / 2
    return dist < radius + 100
end

local RoundActive = nil

local function IsInActiveRound()
    local hum = GetHumanoid()
    if not hum or hum.Health <= 0 then return false, "morto" end
    local root = GetRoot()
    if not root then return false, "sem personagem" end
    local container = GetCoinContainer()
    if not container then return false, "fora de partida" end
    if RoundActive == false then return false, "round encerrado" end
    if RoundActive == true then return true, "em partida" end
    if HasRoundTool() then return true, "em partida (tem ferramenta)" end
    if IsNearMap(root) then return true, "em partida (perto do mapa)" end
    return false, "aguardando início da rodada"
end

-- ============================================================
-- NOCLIP FARM
-- ============================================================
local FarmNoclipActive = false
local FarmNoclipSaved = {}
local FarmNoclipConn = nil

local function ApplyFarmNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if FarmNoclipSaved[part] == nil then
                FarmNoclipSaved[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
end

local function RestoreFarmNoclip()
    for part, original in pairs(FarmNoclipSaved) do
        if part and part.Parent then part.CanCollide = original end
    end
    table.clear(FarmNoclipSaved)
end

local function StartFarmNoclip()
    if FarmNoclipActive then return end
    FarmNoclipActive = true
    if FarmNoclipConn then pcall(function() FarmNoclipConn:Disconnect() end) end
    FarmNoclipConn = RunService.Stepped:Connect(function()
        if not FarmNoclipActive then return end
        ApplyFarmNoclip()
    end)
    ApplyFarmNoclip()
end

local function StopFarmNoclip()
    if not FarmNoclipActive then return end
    FarmNoclipActive = false
    if FarmNoclipConn then
        pcall(function() FarmNoclipConn:Disconnect() end)
        FarmNoclipConn = nil
    end
    RestoreFarmNoclip()
end

local function SyncFarmNoclip(shouldBeOn)
    if shouldBeOn and not FarmNoclipActive then
        StartFarmNoclip()
    elseif not shouldBeOn and FarmNoclipActive then
        StopFarmNoclip()
    end
end

-- ============================================================
-- ESTADO
-- ============================================================
local FarmState = {
    Conn = nil, Velocity = nil, Attachment = nil, Target = nil,
    Waiting = false, BagCurrent = 0, BagMaximum = 0,
    ResetUsedThisRound = false, LastStatus = "", StealCount = 0,
}

local FarmSettings = {
    AutoFarm = false, FarmSpeed = 22, AvoidMurderer = true,
    MurdererRadius = 30, ResetWhenFull = false,
}

local FarmUI = { StatusLabel = nil, BagTitle = nil, BagFill = nil }

-- ============================================================
-- SINAIS
-- ============================================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local Gameplay = Remotes and Remotes:FindFirstChild("Gameplay")
local CoinCollected = Gameplay and Gameplay:FindFirstChild("CoinCollected")
local CoinsStarted = Gameplay and Gameplay:FindFirstChild("CoinsStarted")
local RoundStart = Gameplay and Gameplay:FindFirstChild("RoundStart")
local RoundEnd = Gameplay and Gameplay:FindFirstChild("RoundEnd")

-- ============================================================
-- LÓGICA
-- ============================================================
local function SetFarmStatus(text)
    if FarmState.LastStatus == text then return end
    FarmState.LastStatus = text
    if FarmUI.StatusLabel and FarmUI.StatusLabel.Parent then
        FarmUI.StatusLabel.Text = "Status: " .. text
    end
end

local function UpdateBagDisplay()
    local title = FarmUI.BagTitle
    local fill = FarmUI.BagFill
    if not title or not title.Parent or not fill or not fill.Parent then return end
    if FarmState.BagMaximum <= 0 then
        title.Text = "MOCHILA: aguardando..."
        fill.Size = UDim2.new(0,0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(100,255,130)
        return
    end
    local pct = math.clamp(FarmState.BagCurrent / FarmState.BagMaximum, 0, 1)
    title.Text = string.format("MOCHILA: %d/%d (%d%%)",
        FarmState.BagCurrent, FarmState.BagMaximum, math.floor(pct*100))
    fill.Size = UDim2.new(pct, 0, 1, 0)
    if pct >= 1 then fill.BackgroundColor3 = Color3.fromRGB(255,45,65)
    elseif pct >= 0.75 then fill.BackgroundColor3 = Color3.fromRGB(255,170,50)
    else fill.BackgroundColor3 = Color3.fromRGB(100,255,130) end
end

local function IsBagFull()
    return FarmState.BagMaximum > 0 and FarmState.BagCurrent >= FarmState.BagMaximum
end

local function IsCoinPart(p)
    if not p or not p.Parent or not p:IsA("BasePart") then return false end
    if p:GetAttribute("Collected") == true then return false end
    return true
end

local function GetMurdererRoot()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local backpack = p:FindFirstChild("Backpack")
            local hasKnife = (char and char:FindFirstChild("Knife"))
                or (backpack and backpack:FindFirstChild("Knife"))
            if hasKnife then
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then return root end
            end
        end
    end
    return nil
end

-- ✅ FIX: early-exit se achar moeda < 5 studs
local function PickFarmTarget()
    local root = GetRoot()
    if not root then return nil end
    local container = GetCoinContainer()
    if not container then return nil end
    local murdererRoot = FarmSettings.AvoidMurderer and GetMurdererRoot() or nil
    local best, bestDist = nil, math.huge
    local safest, safestDist = nil, -math.huge
    for _, coin in ipairs(container:GetDescendants()) do
        if IsCoinPart(coin) then
            local dMe = (coin.Position - root.Position).Magnitude
            -- ✅ early-exit: já achou uma muito perto
            if dMe < 5 and (not murdererRoot or (coin.Position - murdererRoot.Position).Magnitude > FarmSettings.MurdererRadius) then
                return coin
            end
            if murdererRoot then
                local dMur = (coin.Position - murdererRoot.Position).Magnitude
                if dMur > safestDist then safest, safestDist = coin, dMur end
                if dMur > FarmSettings.MurdererRadius and dMe < bestDist then
                    best, bestDist = coin, dMe
                end
            elseif dMe < bestDist then
                best, bestDist = coin, dMe
            end
        end
    end
    return best or safest
end

local function StopFarm()
    if FarmState.Conn then
        pcall(function() FarmState.Conn:Disconnect() end)
        FarmState.Conn = nil
    end
    if FarmState.Velocity then
        pcall(function() FarmState.Velocity:Destroy() end)
        FarmState.Velocity = nil
    end
    if FarmState.Attachment then
        pcall(function() FarmState.Attachment:Destroy() end)
        FarmState.Attachment = nil
    end
    FarmState.Target = nil
    FarmState.Waiting = false
    StopFarmNoclip()
end

local function StartFarm()
    if FarmState.Conn then return end
    if not FarmSettings.AutoFarm then return end

    local inRound, reason = IsInActiveRound()
    if not inRound then
        SetFarmStatus("aguardando entrar em partida (" .. reason .. ")")
        return
    end

    local root = GetRoot()
    local hum = GetHumanoid()
    if not root or not hum or hum.Health <= 0 then return end

    FarmState.Attachment = Instance.new("Attachment")
    FarmState.Attachment.Name = "__FarmAttachment"
    FarmState.Attachment.Parent = root

    FarmState.Velocity = Instance.new("LinearVelocity")
    FarmState.Velocity.Name = "__FarmVelocity"
    FarmState.Velocity.Attachment0 = FarmState.Attachment
    FarmState.Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    FarmState.Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    FarmState.Velocity.ForceLimitsEnabled = false
    FarmState.Velocity.VectorVelocity = Vector3.zero
    FarmState.Velocity.Enabled = false
    FarmState.Velocity.Parent = root

    FarmState.Conn = RunService.Heartbeat:Connect(function()
        if not FarmSettings.AutoFarm then StopFarm(); return end

        local inRound2, reason2 = IsInActiveRound()
        if not inRound2 then
            if FarmState.Velocity and FarmState.Velocity.Enabled then
                FarmState.Velocity.Enabled = false
            end
            SyncFarmNoclip(false)
            FarmState.Target = nil
            FarmState.Waiting = false
            SetFarmStatus("aguardando entrar em partida (" .. reason2 .. ")")
            return
        end

        local currentRoot = GetRoot()
        local currentHum = GetHumanoid()
        if not currentRoot or not currentHum or currentHum.Health <= 0 then
            StopFarm()
            SetFarmStatus("personagem morto, farm parado")
            return
        end

        if not FarmState.Velocity or not FarmState.Velocity.Parent then
            StopFarm()
            return
        end

        if IsBagFull() then
            if FarmState.Velocity.Enabled then FarmState.Velocity.Enabled = false end
            SyncFarmNoclip(false)
            SetFarmStatus("mochila cheia! (você pode andar)")
            if FarmSettings.ResetWhenFull and not FarmState.ResetUsedThisRound then
                FarmState.ResetUsedThisRound = true
                StopFarm()
                task.wait(0.5)
                if currentHum.Parent and currentHum.Health > 0 then
                    pcall(function() currentHum.Health = 0 end)
                end
            end
            return
        end

        if FarmState.Target and not IsTargetStillValid(FarmState.Target) then
            FarmState.Target = nil
            FarmState.Waiting = false
            FarmState.StealCount = FarmState.StealCount + 1
            SetFarmStatus(string.format("moeda roubada! retargetando... (%d)", FarmState.StealCount))
        end

        if FarmState.Waiting then
            if FarmState.Velocity.Enabled then FarmState.Velocity.Enabled = false end
            SyncFarmNoclip(false)
            return
        end

        if not FarmState.Target then
            FarmState.Target = PickFarmTarget()
        end

        if not FarmState.Target then
            if FarmState.Velocity.Enabled then FarmState.Velocity.Enabled = false end
            SyncFarmNoclip(false)
            SetFarmStatus("livre — pode andar (aguardando moeda)")
            return
        end

        local delta = FarmState.Target.Position - currentRoot.Position
        local dist = delta.Magnitude

        if dist <= 0.5 then
            if FarmState.Velocity.Enabled then FarmState.Velocity.Enabled = false end
            SyncFarmNoclip(false)
            FarmState.Target = nil
            FarmState.Waiting = true
            SetFarmStatus("coletando...")
            task.spawn(function()
                task.wait(0.2)
                FarmState.Waiting = false
            end)
            return
        end

        SyncFarmNoclip(true)

        local spd = FarmSettings.FarmSpeed
        if dist < 3 then
            spd = math.max(4, math.min(spd, dist * 8))
        end
        FarmState.Velocity.VectorVelocity = delta.Unit * spd
        if not FarmState.Velocity.Enabled then FarmState.Velocity.Enabled = true end
        SetFarmStatus("farmando...")
    end)
end

-- ============================================================
-- UI HELPERS
-- ============================================================
local function AddHeader(parent, text, order)
    local lbl = Create("TextLabel", {
        Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1,
        Text = text, TextColor3 = Theme.Text, TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = order or 1,
    }, parent)
    Register({ Type = "Header", Obj = lbl })
    return lbl
end

local function AddDivider(parent, order)
    local line = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Track, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, LayoutOrder = order or 5,
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

local function AddSlider(parent, title, setting, min, max, step, order)
    local frame = Create("Frame", {
        Name = "SliderContainer", Size = UDim2.new(1,0,0,55),
        BackgroundColor3 = Theme.Button, BorderSizePixel = 0,
        LayoutOrder = order or 10,
    }, parent)
    Create("UICorner", { CornerRadius = UDim.new(0,7) }, frame)
    local label = Create("TextLabel", {
        Size = UDim2.new(1,-16,0,22), Position = UDim2.fromOffset(8,2),
        BackgroundTransparency = 1,
        Text = title .. ": " .. tostring(FarmSettings[setting]),
        TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    local bar = Create("Frame", {
        Name = "SliderBackground", Size = UDim2.new(1,-20,0,8),
        Position = UDim2.fromOffset(10,35),
        BackgroundColor3 = Theme.Track, BorderSizePixel = 0, Active = true,
    }, frame)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, bar)
    local fill = Create("Frame", {
        Name = "SliderFill", Size = UDim2.new(0,0,1,0),
        BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, bar)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, fill)
    local knob = Create("Frame", {
        Name = "SliderKnob", Size = UDim2.fromOffset(16,16),
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,0,0.5,0),
        BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, bar)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, knob)
    local dragging = false
    local function Update(value)
        value = math.clamp(value, min, max)
        value = math.floor(value/step + 0.5) * step
        FarmSettings[setting] = math.clamp(value, min, max)
        local pct = (FarmSettings[setting] - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        label.Text = title .. ": " .. tostring(FarmSettings[setting])
    end
    local function UpdateFromInput(input)
        if bar.AbsoluteSize.X <= 0 then return end
        local pct = math.clamp(
            (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0, 1)
        Update(min + (max - min) * pct)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; UpdateFromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    Register({ Type = "Slider", Obj = frame, Label = label, Bar = bar })
    Update(FarmSettings[setting])
    return frame
end

local function AddBagProgress(parent, order)
    local frame = Create("Frame", {
        Name = "BagProgress", Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Theme.Button, BorderSizePixel = 0,
        LayoutOrder = order or 10,
    }, parent)
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, frame)
    local title = Create("TextLabel", {
        Name = "BagTitle",
        Size = UDim2.new(1,-16,0,20), Position = UDim2.fromOffset(8,3),
        BackgroundTransparency = 1, Text = "MOCHILA: aguardando...",
        TextColor3 = Theme.Text, TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    local bg = Create("Frame", {
        Name = "BagBg",
        Size = UDim2.new(1,-16,0,14), Position = UDim2.fromOffset(8,30),
        BackgroundColor3 = Theme.Track, BorderSizePixel = 0,
    }, frame)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, bg)
    local fill = Create("Frame", {
        Name = "BagFill", Size = UDim2.new(0,0,1,0),
        BackgroundColor3 = Color3.fromRGB(100,255,130), BorderSizePixel = 0,
    }, bg)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, fill)
    FarmUI.BagTitle = title
    FarmUI.BagFill = fill
    Register({ Type = "BagProgress", Obj = frame, Title = title, Bg = bg })
    return frame
end

-- ============================================================
-- LAYOUT
-- ============================================================
local LayoutFrame = Create("Frame", {
    Name = "FarmDLC_Layout",
    Size = UDim2.new(1,-6,0,0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 200,
}, FarmPage:FindFirstChild("Rows") or FarmPage)

local Col = Create("Frame", {
    Size = UDim2.new(1,0,0,0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
}, LayoutFrame)
Create("UIListLayout", {
    Padding = UDim.new(0,8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Col)

-- ============================================================
-- INJEÇÃO
-- ============================================================
AddHeader(Col, "💰 AUTO FARM", 1)

AddToggle(Col, "Auto Farm Coins", false, function(state)
    FarmSettings.AutoFarm = state
    if state then
        FarmState.ResetUsedThisRound = false
        FarmState.Target = nil
        FarmState.Waiting = false
        FarmState.StealCount = 0
        SetFarmStatus("AutoFarm ativado")
        StartFarm()
    else
        StopFarm()
        SetFarmStatus("AutoFarm desativado")
    end
end, 2)

AddSlider(Col, "Velocidade do Farm", "FarmSpeed", 5, 50, 1, 3)

AddDivider(Col, 4)

AddBagProgress(Col, 5)

AddDivider(Col, 6)

AddHeader(Col, "🛡 SEGURANÇA", 7)

AddToggle(Col, "Evitar Assassino", FarmSettings.AvoidMurderer, function(state)
    FarmSettings.AvoidMurderer = state
end, 8)

AddSlider(Col, "Distância Segura", "MurdererRadius", 10, 100, 5, 9)

AddDivider(Col, 10)

AddToggle(Col, "Reset quando Mochila Cheia", FarmSettings.ResetWhenFull, function(state)
    FarmSettings.ResetWhenFull = state
end, 11)

AddDivider(Col, 12)

FarmUI.StatusLabel = Create("TextLabel", {
    Size = UDim2.new(1,0,0,30),
    BackgroundTransparency = 1,
    Text = "Status: Pronto.",
    TextColor3 = Theme.Text, TextSize = 10,
    Font = Enum.Font.Gotham,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 13,
}, Col)
Register({ Type = "Status", Obj = FarmUI.StatusLabel })

-- ============================================================
-- SINAIS (com limpeza)
-- ============================================================
local SignalConns = {}
local function TrackConn(conn)
    table.insert(SignalConns, conn)
    return conn
end

if CoinCollected and CoinCollected:IsA("RemoteEvent") then
    TrackConn(CoinCollected.OnClientEvent:Connect(function(player, cur, max)
        -- ✅ FIX: ignora eventos de outros players
        if player and player ~= LocalPlayer then return end
        cur = tonumber(cur); max = tonumber(max)
        if cur and max and max > 0 then
            FarmState.BagCurrent = cur
            FarmState.BagMaximum = max
            UpdateBagDisplay()
        end
    end))
end

local function OnRoundReset()
    FarmState.BagCurrent = 0
    FarmState.BagMaximum = 0
    FarmState.ResetUsedThisRound = false
    FarmState.StealCount = 0
    UpdateBagDisplay()
    StopFarm()
    if FarmSettings.AutoFarm then
        SetFarmStatus("nova rodada, retomando...")
        task.delay(1, function()
            if FarmSettings.AutoFarm then StartFarm() end
        end)
    end
end

if CoinsStarted and CoinsStarted:IsA("RemoteEvent") then
    TrackConn(CoinsStarted.OnClientEvent:Connect(function()
        RoundActive = true
        OnRoundReset()
    end))
end
if RoundStart and RoundStart:IsA("RemoteEvent") then
    TrackConn(RoundStart.OnClientEvent:Connect(function()
        RoundActive = true
        FarmState.ResetUsedThisRound = false
        FarmState.StealCount = 0
    end))
end
if RoundEnd and RoundEnd:IsA("RemoteEvent") then
    TrackConn(RoundEnd.OnClientEvent:Connect(function()
        RoundActive = false
        StopFarm()
        if FarmSettings.AutoFarm then
            SetFarmStatus("aguardando próxima rodada")
        end
    end))
end

-- ✅ FIX: task.delay em vez de task.wait
TrackConn(LocalPlayer.CharacterAdded:Connect(function()
    StopFarmNoclip()
    FarmState.BagCurrent = 0
    FarmState.BagMaximum = 0
    FarmState.ResetUsedThisRound = false
    FarmState.Target = nil
    FarmState.Waiting = false
    UpdateBagDisplay()
    StopFarm()
    task.delay(1, function()
        if FarmSettings.AutoFarm then
            local hum = GetHumanoid()
            if hum and hum.Health > 0 then
                StartFarm()
            end
        end
    end)
end))

-- ============================================================
-- MONITOR
-- ============================================================
task.spawn(function()
    while ScreenGui.Parent and FarmPage.Parent do
        if FarmSettings.AutoFarm and not FarmState.Conn then
            local inRound = IsInActiveRound()
            if inRound then
                StartFarm()
            end
        end
        task.wait(1)
    end
    StopFarm()
end)

-- ============================================================
-- ✅ INJETA NO ABOUT
-- ============================================================
task.spawn(function()
    task.wait(0.9)
    pcall(InjectAboutVersion)
end)

-- Manutenção do ABOUT
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
-- TEMA
-- ============================================================
task.spawn(function()
    local lastTheme = CurrentThemeName
    while ScreenGui.Parent and FarmPage.Parent do
        local newName = DetectThemeName()
        if newName ~= lastTheme then
            lastTheme = newName
            Theme = Themes[newName] or Themes.Noturno
            CurrentThemeName = newName
            ReapplyTheme()
        end
        task.wait(2)
    end
end)

-- ============================================================
-- CLEANUP
-- ============================================================
local function FullCleanup()
    StopFarm()
    StopFarmNoclip()
    for _, conn in ipairs(SignalConns) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(SignalConns)
    pcall(RemoveAboutInjection)
end

-- Registra cleanup pro guard de reload
ScreenGui:SetAttribute("FarmCleanup", FullCleanup)

ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then
        ScreenGui:SetAttribute("FarmActive", false)
        FullCleanup()
    end
end)

print("[" .. HUB_NAME .. "] Extensão FARM v" .. EXT_VERSION .. " | Tema: " .. CurrentThemeName)
print("[About] Versão do Farm injetada automaticamente no Indicador 4")
