--[[ NOTURNO HUB - EXTENSÃO: ABA COMBATE
     Versão: 2.8
     Requer: NOTURNO HUB v0.9.6+ já carregado
     
     Novidades v2.8:
       ✅ Kill Aura adicionado (coluna Murderer)
       ✅ Kill Aura Range (slider 5–30 studs)
       ✅ Stabba TODOS os jogadores no raio, não só o que você mira
       ✅ Só ativa se você tiver a faca (Knife)
       ✅ Delay anti-detect entre stabs (0.15s)
       
     Layout:
       🟦 ESQUERDA (Sheriff/Hero/Innocent):
          - Aim Assist (só Murderer, sem Shift Lock)
          - Auto Shot (Murderer)
          - Auto Grab Gun (volta pra posição original)
          - 🎯 Botão Flutuante Shot
          - 🔫 Botão Flutuante Grab Gun
       🟥 DIREITA (Murderer):
          - Hitbox Expander
          - Hitbox Size
          - 🩸 Kill Aura              ← NOVO
          - Kill Aura Range           ← NOVO
          - Auto Kill All
          - 🔪 Botão Flutuante Kill All
       ❌ Auto Win (removido)
]]

local HUB_NAME = "NOTURNO HUB"
local EXT_VERSION = "2.8"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- CONFIG AIM ASSIST
-- ============================================================
local AIM_RANGE = 500
local AIM_SMOOTH = false
local AIM_PRIORITY = Enum.RenderPriority.Camera.Value + 1

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
local CombatPage = PagesContainer and PagesContainer:FindFirstChild("COMBATE")
if not CombatPage then
    warn("[" .. HUB_NAME .. "] Aba COMBATE não encontrada.")
    return
end

for _, child in ipairs(CombatPage:GetChildren()) do
    if child.Name == "CombatExtensionMarker" or child.Name == "CombatDLC_Layout" then
        child:Destroy()
    end
end

local function Create(className, properties, parent)
    local obj = Instance.new(className)
    for k,v in pairs(properties) do obj[k] = v end
    obj.Parent = parent
    return obj
end

Create("Folder", { Name = "CombatExtensionMarker" }, CombatPage)

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
local CombatState = {
    AimAssist = false,
    HitboxExpander = false,
    HitboxSize = 4,
    KillAura = false,        -- NOVO
    KillAuraRange = 10,      -- NOVO
    AutoShot = false,
    AutoGrab = false,
    AutoKill = false,
    FloatShot = false,
    FloatKill = false,
    FloatGrab = false,
}

local CombatConnections = {}
local IsBusy = false
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
    elseif entry.Type == "Slider" then
        o.BackgroundColor3 = Theme.Button
        if entry.Label then entry.Label.TextColor3 = Theme.Text end
        if entry.Bar then entry.Bar.BackgroundColor3 = Theme.Track end
        if entry.Fill then entry.Fill.BackgroundColor3 = Theme.Accent end
    elseif entry.Type == "Float" then
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
-- HELPERS ROLE / ARMAS
-- ============================================================
local function HasToolIn(player, name)
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    return (char and char:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
end
local function GetGun(player)
    local p = player or LocalPlayer
    return HasToolIn(p, "Gun") or HasToolIn(p, "Revolver")
end
local function GetKnife(player)
    local p = player or LocalPlayer
    return HasToolIn(p, "Knife")
end
local function GetRole(player)
    if not player then return "Unknown" end
    if GetKnife(player) then return "Murderer" end
    if GetGun(player) then
        if player.Team and string.lower(player.Team.Name):find("hero") then return "Hero" end
        return "Sheriff"
    end
    if player:GetAttribute("Dead") == true then return "Dead" end
    local r = player:GetAttribute("Role")
    if r then
        local s = string.lower(tostring(r))
        if s:find("murder") then return "Murderer" end
        if s:find("sheriff") then return "Sheriff" end
        if s:find("hero") then return "Hero" end
        if s:find("dead") then return "Dead" end
        if s:find("innocent") then return "Innocent" end
    end
    if player.Team then
        local t = string.lower(player.Team.Name)
        if t:find("murder") then return "Murderer" end
        if t:find("sheriff") then return "Sheriff" end
        if t:find("hero") then return "Hero" end
    end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return "Dead" end
    return "Innocent"
end
local function GetMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetRole(p) == "Murderer" then return p end
    end
    return nil
end
local function GetRoot(player)
    local char = player and player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function GetAlivePlayers()
    local alive = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then table.insert(alive, p) end
        end
    end
    return alive
end

-- ============================================================
-- BUSCA GUNDROP
-- ============================================================
local function FindGunDrop()
    local drop = workspace:FindFirstChild("GunDrop")
    if drop then return drop end
    for _, name in ipairs({ "Gun_Drop", "GunDrop2", "Gun", "RevolverDrop", "DroppedGun" }) do
        local d = workspace:FindFirstChild(name)
        if d and d:IsA("BasePart") then return d end
    end
    local rec = workspace:FindFirstChild("GunDrop", true)
    if rec then return rec end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("gundrop") or n:find("gun_drop") or n:find("droppedgun") then
                return obj
            end
        end
    end
    return nil
end

local function GetBasePart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

-- ============================================================
-- AUTO GRAB GUN
-- ============================================================
local function AutoGrabGun()
    if IsBusy then return end
    IsBusy = true
    local myRoot = GetRoot(LocalPlayer)
    if not myRoot then IsBusy = false; return end
    local dropObj = FindGunDrop()
    if not dropObj then
        print("[GrabGun] GunDrop não encontrado.")
        IsBusy = false
        return
    end
    local part = GetBasePart(dropObj)
    if not part then IsBusy = false; return end

    local savedCFrame = myRoot.CFrame
    myRoot.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)

    local touched = false
    if firetouchinterest then
        pcall(function()
            firetouchinterest(myRoot, part, 0)
            task.wait(0.05)
            firetouchinterest(myRoot, part, 1)
            touched = true
        end)
    end
    if not touched then
        myRoot.CFrame = CFrame.new(part.Position)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end

    task.wait(0.5)
    if not GetGun(LocalPlayer) then task.wait(2) end

    myRoot = GetRoot(LocalPlayer)
    if myRoot then
        myRoot.CFrame = savedCFrame
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end
    IsBusy = false
end

-- ============================================================
-- COMBATE
-- ============================================================
local function ShootTarget(targetPlayer)
    local gun = GetGun()
    local myRoot = GetRoot(LocalPlayer)
    local targetRoot = GetRoot(targetPlayer)
    if not gun or not myRoot or not targetRoot then return false end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if gun.Parent ~= LocalPlayer.Character and hum then
        pcall(function() hum:EquipTool(gun) end)
        task.wait(0.15)
    end
    local att = myRoot:FindFirstChild("GunRaycastAttachment")
    local origin = (att and att.WorldCFrame) or myRoot.CFrame
    local ev = gun:FindFirstChild("Shoot")
    if ev then
        pcall(function() ev:FireServer(origin, targetRoot.CFrame) end)
        return true
    end
    return false
end

local function AutoShootMurderer()
    if IsBusy then return false, false end
    IsBusy = true
    local m = GetMurderer()
    if not m then IsBusy = false; return false, true end
    local myRoot = GetRoot(LocalPlayer)
    local tRoot = GetRoot(m)
    if not myRoot or not tRoot then IsBusy = false; return false, false end
    local home = myRoot.CFrame
    myRoot.CFrame = tRoot.CFrame * CFrame.new(0,0,5)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.15)
    local ok = ShootTarget(m)
    task.wait(0.35)
    local h = m.Character and m.Character:FindFirstChildOfClass("Humanoid")
    local dead = not h or h.Health <= 0
    if not dead then
        myRoot.CFrame = home
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end
    IsBusy = false
    return ok, dead
end

local function StabTarget(targetPlayer)
    local knife = GetKnife()
    local myRoot = GetRoot(LocalPlayer)
    local tRoot = GetRoot(targetPlayer)
    if not knife or not myRoot or not tRoot then return false end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if knife.Parent ~= LocalPlayer.Character and hum then
        pcall(function() hum:EquipTool(knife) end)
        task.wait(0.1)
    end
    myRoot.CFrame = tRoot.CFrame * CFrame.new(0,0,2)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.1)
    local events = knife:FindFirstChild("Events")
    if not events then return false end
    for _, n in ipairs({"KnifeStabbed","Stab","Slash","Attack","KnifeAttack"}) do
        local ev = events:FindFirstChild(n)
        if ev and ev:IsA("RemoteEvent") then
            pcall(function() ev:FireServer() end)
            break
        end
    end
    task.wait(0.05)
    for _, n in ipairs({"HandleTouched","Touched","Hit"}) do
        local ev = events:FindFirstChild(n)
        if ev and ev:IsA("RemoteEvent") then
            pcall(function() ev:FireServer(tRoot) end)
            return true
        end
    end
    return false
end

-- ============================================================
-- 🩸 KILL AURA (NOVO)
-- ------------------------------------------------------------
-- Stabba TODOS os jogadores dentro do raio configurado.
-- Não teleporta — aplica o stab direto na posição do alvo.
-- Só roda se o LocalPlayer tiver a faca.
-- ============================================================
local function RunKillAura()
    if not CombatState.KillAura then return end
    if not GetKnife() then return end

    local myRoot = GetRoot(LocalPlayer)
    if not myRoot then return end
    local myPos = myRoot.Position
    local range = CombatState.KillAuraRange

    for _, p in ipairs(Players:GetPlayers()) do
        if not CombatState.KillAura then break end
        if p ~= LocalPlayer then
            local char = p.Character
            local tRoot = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - myPos).Magnitude
                if dist <= range then
                    pcall(StabTarget, p)
                    task.wait(0.15)
                end
            end
        end
    end
end

local function StartKillAura()
    task.spawn(function()
        while CombatState.KillAura and ScreenGui.Parent do
            pcall(RunKillAura)
            task.wait(0.25)
        end
    end)
end

-- ============================================================
-- LOOPS AUTO
-- ============================================================
local function StartAutoShot()
    task.spawn(function()
        while CombatState.AutoShot and ScreenGui.Parent do
            pcall(function()
                local m = GetMurderer()
                if m and GetGun() then AutoShootMurderer() end
            end)
            task.wait(0.5)
        end
    end)
end
local function StartAutoGrab()
    task.spawn(function()
        while CombatState.AutoGrab and ScreenGui.Parent do
            pcall(AutoGrabGun)
            task.wait(2)
        end
    end)
end
local function StartAutoKill()
    task.spawn(function()
        while CombatState.AutoKill and ScreenGui.Parent do
            pcall(function()
                if GetKnife() then
                    for _, t in ipairs(GetAlivePlayers()) do
                        if not CombatState.AutoKill then break end
                        StabTarget(t)
                        task.wait(0.4)
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

-- ============================================================
-- BOTÕES FLUTUANTES
-- ============================================================
local FloatingBtnShot, FloatingBtnKill, FloatingBtnGrab
local FLOAT_SIZE = 60
local FLOAT_GAP = 6

local function GetJumpPos()
    local jb
    pcall(function()
        local tg = LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
        if tg then jb = tg:FindFirstChild("JumpButton") end
    end)
    if jb then
        return UDim2.new(jb.Position.X.Scale, jb.Position.X.Offset - 120,
                         jb.Position.Y.Scale, jb.Position.Y.Offset - 90)
    end
    return UDim2.new(1, -150, 1, -180)
end

local function GetFloatAnchor() return GetJumpPos() end
local function GetShotPos() return GetFloatAnchor() end
local function GetGrabPos()
    local base = GetFloatAnchor()
    return UDim2.new(base.X.Scale, base.X.Offset - FLOAT_SIZE - FLOAT_GAP,
                     base.Y.Scale, base.Y.Offset)
end
local function GetKillPos()
    local base = GetFloatAnchor()
    return UDim2.new(base.X.Scale, base.X.Offset,
                     base.Y.Scale, base.Y.Offset - FLOAT_SIZE - FLOAT_GAP)
end

local function FlashButton(btn, baseColor)
    if not btn or not btn.Parent then return end
    btn.BackgroundColor3 = Color3.fromRGB(100, 220, 130)
    task.delay(0.25, function()
        if btn and btn.Parent then btn.BackgroundColor3 = baseColor end
    end)
end

local function CreateFloatingShot()
    if FloatingBtnShot then FloatingBtnShot:Destroy() end
    local btn = Create("TextButton", {
        Name = "CombatFloatShot", Size = UDim2.fromOffset(FLOAT_SIZE,FLOAT_SIZE),
        Position = GetShotPos(), BackgroundColor3 = Theme.Button,
        Text = "SHOT\nMURDER", TextColor3 = Theme.Text, TextSize = 11,
        Font = Enum.Font.GothamBold, ZIndex = 999,
    }, ScreenGui)
    Create("UICorner", { CornerRadius = UDim.new(0,10) }, btn)
    Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.4 }, btn)
    btn.MouseButton1Click:Connect(function()
        local m = GetMurderer()
        if m then
            FlashButton(btn, Theme.Button)
            ShootTarget(m)
        end
    end)
    FloatingBtnShot = btn
    Register({ Type = "Float", Obj = btn })
end

local function CreateFloatingGrab()
    if FloatingBtnGrab then FloatingBtnGrab:Destroy() end
    local btn = Create("TextButton", {
        Name = "CombatFloatGrab", Size = UDim2.fromOffset(FLOAT_SIZE,FLOAT_SIZE),
        Position = GetGrabPos(), BackgroundColor3 = Theme.Button,
        Text = "GRAB\nGUN", TextColor3 = Theme.Text, TextSize = 11,
        Font = Enum.Font.GothamBold, ZIndex = 999,
    }, ScreenGui)
    Create("UICorner", { CornerRadius = UDim.new(0,10) }, btn)
    Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.4 }, btn)
    btn.MouseButton1Click:Connect(function()
        print("[GrabGun] Botão tocado!")
        FlashButton(btn, Theme.Button)
        task.spawn(AutoGrabGun)
    end)
    FloatingBtnGrab = btn
    Register({ Type = "Float", Obj = btn })
end

local function CreateFloatingKill()
    if FloatingBtnKill then FloatingBtnKill:Destroy() end
    local btn = Create("TextButton", {
        Name = "CombatFloatKill", Size = UDim2.fromOffset(FLOAT_SIZE,FLOAT_SIZE),
        Position = GetKillPos(), BackgroundColor3 = Theme.Button,
        Text = "KILL\nALL", TextColor3 = Theme.Text, TextSize = 11,
        Font = Enum.Font.GothamBold, ZIndex = 999,
    }, ScreenGui)
    Create("UICorner", { CornerRadius = UDim.new(0,10) }, btn)
    Create("UIStroke", { Color = Theme.Accent, Thickness = 1.2, Transparency = 0.4 }, btn)
    btn.MouseButton1Click:Connect(function()
        task.spawn(function()
            if not GetKnife() then return end
            FlashButton(btn, Theme.Button)
            for _, t in ipairs(GetAlivePlayers()) do
                StabTarget(t)
                task.wait(0.5)
            end
        end)
    end)
    FloatingBtnKill = btn
    Register({ Type = "Float", Obj = btn })
end

local function RepositionFloatingButtons()
    if FloatingBtnShot and FloatingBtnShot.Parent then FloatingBtnShot.Position = GetShotPos() end
    if FloatingBtnGrab and FloatingBtnGrab.Parent then FloatingBtnGrab.Position = GetGrabPos() end
    if FloatingBtnKill and FloatingBtnKill.Parent then FloatingBtnKill.Position = GetKillPos() end
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
    return {
        Row = row, SetState = updateVisual,
        Lock = function() hitbox.Active = false; row.BackgroundTransparency = 0.4 end,
        Unlock = function() hitbox.Active = true; row.BackgroundTransparency = 0 end,
    }
end

local function AddSlider(parent, title, initial, min, max, step, callback, order)
    local frame = Create("Frame", {
        Size = UDim2.new(1,0,0,55), BackgroundColor3 = Theme.Button,
        BorderSizePixel = 0, LayoutOrder = order or 10,
    }, parent)
    Create("UICorner", { CornerRadius = UDim.new(0,7) }, frame)
    local label = Create("TextLabel", {
        Size = UDim2.new(1,-16,0,22), Position = UDim2.fromOffset(8,2),
        BackgroundTransparency = 1, Text = title .. ": " .. tostring(initial),
        TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    local bar = Create("Frame", {
        Name = "SliderBackground", Size = UDim2.new(1,-20,0,8),
        Position = UDim2.fromOffset(10,35), BackgroundColor3 = Theme.Track,
        BorderSizePixel = 0, Active = true,
    }, frame)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, bar)
    local fill = Create("Frame", {
        Name = "SliderFill", Size = UDim2.new((initial-min)/(max-min),0,1,0),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
    }, bar)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, fill)
    local knob = Create("Frame", {
        Size = UDim2.fromOffset(16,16), AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new((initial-min)/(max-min),0,0.5,0),
        BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, bar)
    Create("UICorner", { CornerRadius = UDim.new(1,0) }, knob)
    local dragging = false
    local function setValue(val)
        val = math.clamp(val, min, max)
        val = math.floor(val/step + 0.5) * step
        val = math.clamp(val, min, max)
        local pct = (val-min)/(max-min)
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,0,0.5,0)
        label.Text = title .. ": " .. tostring(val)
        callback(val)
    end
    local function fromInput(input)
        if bar.AbsoluteSize.X <= 0 then return end
        local pct = math.clamp((input.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        setValue(min + (max-min) * pct)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; fromInput(input)
        end
    end)
    local ic = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)
    local ie = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(CombatConnections, ic)
    table.insert(CombatConnections, ie)
    Register({ Type = "Slider", Obj = frame, Label = label, Bar = bar, Fill = fill })
    return frame
end

-- ============================================================
-- AIM ASSIST
-- ============================================================
local AimBindName = "NoturnoAimAssist"
local OriginalCameraType = nil
local AimBound = false

local function UpdateCamera()
    if not CombatState.AimAssist then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local murderer = GetMurderer()
    if not murderer then return end
    local mChar = murderer.Character
    local mHead = mChar and mChar:FindFirstChild("Head")
    local mHum = mChar and mChar:FindFirstChildOfClass("Humanoid")
    if not mHead or not mHum or mHum.Health <= 0 then return end
    local dist = (mHead.Position - root.Position).Magnitude
    if dist > AIM_RANGE then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    if camera.CameraType ~= Enum.CameraType.Scriptable then
        if not OriginalCameraType then OriginalCameraType = camera.CameraType end
        camera.CameraType = Enum.CameraType.Scriptable
    end
    local targetCFrame = CFrame.new(camera.CFrame.Position, mHead.Position)
    if AIM_SMOOTH then
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.35)
    else
        camera.CFrame = targetCFrame
    end
end

local function StartAimAssist()
    if not AimBound then
        RunService:BindToRenderStep(AimBindName, AIM_PRIORITY, UpdateCamera)
        AimBound = true
        print("[AimAssist] Ativado — funciona COM ou SEM Shift Lock")
    end
end

local function StopAimAssist()
    if AimBound then
        pcall(function() RunService:UnbindFromRenderStep(AimBindName) end)
        AimBound = false
    end
    local camera = workspace.CurrentCamera
    if camera and OriginalCameraType then
        camera.CameraType = OriginalCameraType
        OriginalCameraType = nil
    end
    print("[AimAssist] Desativado — câmera livre")
end

-- ============================================================
-- HITBOX
-- ============================================================
local function SetHitbox(player, size)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not hrp:FindFirstChild("__CombatHitbox") then
        Create("BoolValue", { Name = "__CombatHitbox" }, hrp)
    end
    hrp.Size = Vector3.new(size, size, size)
    hrp.Transparency = 0.7
    hrp.CanCollide = false
end
local function ResetHitbox(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local tag = hrp:FindFirstChild("__CombatHitbox")
    if tag then
        hrp.Size = Vector3.new(2, 2, 1)
        hrp.Transparency = 1
        tag:Destroy()
    end
end
local function UpdateHitboxes()
    if not CombatState.HitboxExpander then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ResetHitbox(p) end
        end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                SetHitbox(p, CombatState.HitboxSize)
            else
                ResetHitbox(p)
            end
        end
    end
end

-- ============================================================
-- LAYOUT 2 COLUNAS
-- ============================================================
local LayoutFrame = Create("Frame", {
    Name = "CombatDLC_Layout",
    Size = UDim2.new(1,-6,0,0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 200,
}, CombatPage:FindFirstChild("Rows") or CombatPage)

local LeftCol = Create("Frame", {
    Size = UDim2.new(0.5, -4, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
}, LayoutFrame)
Create("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder }, LeftCol)

local RightCol = Create("Frame", {
    Size = UDim2.new(0.5, -4, 0, 0),
    Position = UDim2.new(0.5, 4, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
}, LayoutFrame)
Create("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder }, RightCol)

-- ============================================================
-- INJEÇÃO — ESQUERDA
-- ============================================================
AddHeader(LeftCol, "🎯 SHERIFF / HERO", 1)

AddToggle(LeftCol, "Aim Assist (só Murderer)", false, function(state)
    CombatState.AimAssist = state
    if state then StartAimAssist() else StopAimAssist() end
end, 2)

AddToggle(LeftCol, "Auto Shot (Murderer)", false, function(state)
    CombatState.AutoShot = state
    if state then StartAutoShot() end
end, 3)

AddToggle(LeftCol, "Auto Grab Gun", false, function(state)
    CombatState.AutoGrab = state
    if state then StartAutoGrab() end
end, 4)

AddToggle(LeftCol, "🎯 Botão Flutuante Shot", false, function(state)
    CombatState.FloatShot = state
    if state then CreateFloatingShot()
    elseif FloatingBtnShot then FloatingBtnShot:Destroy(); FloatingBtnShot = nil end
end, 5)

AddToggle(LeftCol, "🔫 Botão Flutuante Grab Gun", false, function(state)
    CombatState.FloatGrab = state
    if state then CreateFloatingGrab()
    elseif FloatingBtnGrab then FloatingBtnGrab:Destroy(); FloatingBtnGrab = nil end
end, 6)

-- ============================================================
-- INJEÇÃO — DIREITA (Murderer) ← KILL AURA AQUI
-- ============================================================
AddHeader(RightCol, "🔪 MURDERER", 1)

AddToggle(RightCol, "Hitbox Expander", false, function(state)
    CombatState.HitboxExpander = state
    if not state then UpdateHitboxes() end
end, 2)

AddSlider(RightCol, "Hitbox Size", 4, 2, 20, 1, function(val)
    CombatState.HitboxSize = val
    if CombatState.HitboxExpander then UpdateHitboxes() end
end, 3)

-- 🩸 NOVO: Kill Aura
AddToggle(RightCol, "🩸 Kill Aura", false, function(state)
    CombatState.KillAura = state
    if state then StartKillAura() end
end, 4)

AddSlider(RightCol, "Kill Aura Range", 10, 5, 30, 1, function(val)
    CombatState.KillAuraRange = val
end, 5)

AddToggle(RightCol, "Auto Kill All", false, function(state)
    CombatState.AutoKill = state
    if state then StartAutoKill() end
end, 6)

AddToggle(RightCol, "🔪 Botão Flutuante Kill All", false, function(state)
    CombatState.FloatKill = state
    if state then CreateFloatingKill()
    elseif FloatingBtnKill then FloatingBtnKill:Destroy(); FloatingBtnKill = nil end
end, 7)

-- ============================================================
-- LOOPS
-- ============================================================
task.spawn(function()
    while ScreenGui.Parent do
        if CombatState.HitboxExpander then pcall(UpdateHitboxes) end
        task.wait(0.5)
    end
end)

task.spawn(function()
    local lastTheme = CurrentThemeName
    while ScreenGui.Parent and Main.Parent do
        local newName = DetectThemeName()
        if newName ~= lastTheme then
            lastTheme = newName
            Theme = Themes[newName] or Themes.Noturno
            CurrentThemeName = newName
            ReapplyTheme()
            print("[" .. HUB_NAME .. "] Extensão COMBATE -> tema: " .. newName)
        end
        task.wait(1)
    end
end)

-- ============================================================
-- ROUNDSTART
-- ============================================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local Gameplay = Remotes and Remotes:FindFirstChild("Gameplay")
local RoundStart = Gameplay and Gameplay:FindFirstChild("RoundStart")
if RoundStart and RoundStart:IsA("RemoteEvent") then
    RoundStart.OnClientEvent:Connect(function()
        if CombatState.FloatShot and not FloatingBtnShot then CreateFloatingShot() end
        if CombatState.FloatGrab and not FloatingBtnGrab then CreateFloatingGrab() end
        if CombatState.FloatKill and not FloatingBtnKill then CreateFloatingKill() end
    end)
end

pcall(function()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        RepositionFloatingButtons()
    end)
end)

-- ============================================================
-- LIMPEZA
-- ============================================================
ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then
        CombatState.AimAssist = false
        CombatState.HitboxExpander = false
        CombatState.KillAura = false
        CombatState.AutoShot = false
        CombatState.AutoGrab = false
        CombatState.AutoKill = false
        StopAimAssist()
        for _, conn in ipairs(CombatConnections) do
            pcall(function() conn:Disconnect() end)
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ResetHitbox(p) end
        end
        if FloatingBtnShot then FloatingBtnShot:Destroy() end
        if FloatingBtnGrab then FloatingBtnGrab:Destroy() end
        if FloatingBtnKill then FloatingBtnKill:Destroy() end
    end
end)

print("[" .. HUB_NAME .. "] Extensão COMBATE v" .. EXT_VERSION .. " | Tema: " .. CurrentThemeName)
print("[KillAura] Range padrão: 10 studs | Só ativa com faca equipada/backpack")
