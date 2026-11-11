
--[[
    EMOTE ALWAYS v1.7
    - MEUS EMOTES
    - CATÁLOGO
    - SALVOS
    - 10 emotes por página
    - Paginação
    - Favoritos salvos em arquivo
    - Controle de velocidade
    - LOOP ON/OFF
    - MOVER ON/OFF
    - Botão flutuante EMOTE
    - Tema NOTURNO / ROXO
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = {
    Speed = 1,
    Loop = true,
    StopOnMove = true -- OFF = para ao andar
}

local running = true
local Loading = false
local CurrentTrack = nil
local CurrentAnimation = nil
local SavedEmotes = {}
local InventoryItems = {}
local CatalogPages = nil
local CatalogPageHistory = {}
local CatalogPageIndex = 1
local CurrentTab = "Catalog"

local FILE = "EMOTE_ALWAYS_SAVED.json"
local PAGE_SIZE = 10

local Theme = {
    Main = Color3.fromRGB(20, 15, 35),
    Panel = Color3.fromRGB(30, 22, 48),
    Card = Color3.fromRGB(42, 31, 65),
    Purple = Color3.fromRGB(135, 75, 220),
    Light = Color3.fromRGB(190, 150, 255),
    White = Color3.fromRGB(245, 240, 255),
    Red = Color3.fromRGB(190, 55, 75),
    Green = Color3.fromRGB(65, 170, 115)
}

-- SALVAMENTO

local function loadSaved()
    pcall(function()
        if readfile and isfile and isfile(FILE) then
            local data = HttpService:JSONDecode(readfile(FILE))
            if type(data) == "table" then
                SavedEmotes = data
            end
        end
    end)
end

local function saveSaved()
    pcall(function()
        if writefile then
            writefile(FILE, HttpService:JSONEncode(SavedEmotes))
        end
    end)
end

loadSaved()

local function isSaved(id)
    for _, item in ipairs(SavedEmotes) do
        if tostring(item.Id) == tostring(id) then
            return true
        end
    end
    return false
end

-- PERSONAGEM

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

-- EXECUÇÃO DO EMOTE

local function StopEmote()
    if CurrentTrack then
        pcall(function()
            CurrentTrack:Stop(0.1)
            CurrentTrack:Destroy()
        end)
    end

    CurrentTrack = nil
end

local function LoadTrack(id)
    if not running or not id then return end

    -- MOVER OFF: não inicia enquanto estiver andando
    if Config.StopOnMove and Humanoid
    and Humanoid.MoveDirection.Magnitude > 0.05 then
        return
    end

    StopEmote()

    if not Humanoid or not Animator then return end

    local animId

    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)

    if ok and result and #result > 0 then
        if result[1]:IsA("Animation") then
            animId = result[1].AnimationId
        else
            local found = result[1]:FindFirstChildWhichIsA(
                "Animation",
                true
            )

            if found then
                animId = found.AnimationId
            end
        end
    end

    if not animId or animId == "" then
        animId = "rbxassetid://" .. tostring(id)
    end

    local newAnim = Instance.new("Animation")
    newAnim.AnimationId = animId

    local success, newTrack = pcall(function()
        return Animator:LoadAnimation(newAnim)
    end)

    if not success or not newTrack then
        newAnim:Destroy()
        warn("[EMOTE ALWAYS] Erro ao carregar:", id)
        return
    end

    newTrack.Priority = Enum.AnimationPriority.Action4
    newTrack.Looped = Config.Loop

    for _, track in pairs(Animator:GetPlayingAnimationTracks()) do
        if track.Priority ~= Enum.AnimationPriority.Action4 then
            track:Stop(0.1)
        end
    end

    local played = pcall(function()
        newTrack:Play(0.1, 1, Config.Speed)
    end)

    if not played then
        newTrack:Destroy()
        newAnim:Destroy()
        return
    end

    CurrentTrack = newTrack
    CurrentAnimation = tostring(id)

    print("[EMOTE ALWAYS] Emote executado:", id)
end

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    Animator = Humanoid:WaitForChild("Animator")
    CurrentTrack = nil

    task.wait(1)

    if running and CurrentAnimation then
        LoadTrack(CurrentAnimation)
    end
end)

-- INTERFACE

local GUI = Instance.new("ScreenGui")
GUI.Name = "EmoteAlwaysGUI"
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 999
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(330, 430)
Main.Position = UDim2.new(0.5, -165, 0.5, -215)
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 42)
Top.BackgroundColor3 = Theme.Panel
Top.BackgroundTransparency = 0.12
Top.Parent = Main

Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 9)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌙 EMOTE ALWAYS"
Title.TextColor3 = Theme.Light
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(30, 28)
Minimize.Position = UDim2.new(1, -68, 0, 7)
Minimize.BackgroundColor3 = Theme.Card
Minimize.Text = "-"
Minimize.TextColor3 = Theme.White
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 18
Minimize.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 28)
Close.Position = UDim2.new(1, -34, 0, 7)
Close.BackgroundColor3 = Theme.Red
Close.Text = "X"
Close.TextColor3 = Theme.White
Close.Font = Enum.Font.GothamBold
Close.TextSize = 14
Close.Parent = Top

Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 6)
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)

local Floating = Instance.new("TextButton")
Floating.Name = "EmoteFloatingButton"
Floating.Size = UDim2.fromOffset(100, 38)
Floating.Position = UDim2.new(0, 15, 1, -110)
Floating.BackgroundColor3 = Theme.Purple
Floating.BackgroundTransparency = 0.15
Floating.BorderSizePixel = 0
Floating.Text = "EMOTE"
Floating.TextColor3 = Theme.White
Floating.TextSize = 14
Floating.Font = Enum.Font.GothamBold
Floating.Visible = false
Floating.Parent = GUI

Instance.new("UICorner", Floating).CornerRadius = UDim.new(0, 8)

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Theme.Light
FloatingStroke.Thickness = 1.2
FloatingStroke.Parent = Floating

-- FUNÇÃO DOS BOTÕES

local function makeButton(parent, text, size, position, color)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Theme.White
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = parent

    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

    return b
end

-- ABAS

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1, -10, 0, 34)
Tabs.Position = UDim2.fromOffset(5, 48)
Tabs.BackgroundTransparency = 1
Tabs.Parent = Main

local InventoryTab = makeButton(
    Tabs,
    "MEUS EMOTES",
    UDim2.new(0.33, -3, 1, 0),
    UDim2.new(0, 0, 0, 0),
    Theme.Card
)

local CatalogTab = makeButton(
    Tabs,
    "CATÁLOGO",
    UDim2.new(0.33, -3, 1, 0),
    UDim2.new(0.335, 0, 0, 0),
    Theme.Purple
)

local SavedTab = makeButton(
    Tabs,
    "SALVOS",
    UDim2.new(0.33, -3, 1, 0),
    UDim2.new(0.67, 0, 0, 0),
    Theme.Card
)

-- PESQUISA

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(0.72, -5, 0, 32)
SearchBox.Position = UDim2.fromOffset(5, 89)
SearchBox.BackgroundColor3 = Theme.Panel
SearchBox.TextColor3 = Theme.White
SearchBox.PlaceholderColor3 = Theme.Light
SearchBox.PlaceholderText = "Pesquisar emotes..."
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 12
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = Main

Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

local SearchButton = makeButton(
    Main,
    "BUSCAR",
    UDim2.new(0.25, 0, 0, 32),
    UDim2.new(0.75, 0, 0, 89),
    Theme.Purple
)

-- LISTA

local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, -10, 0, 195)
List.Position = UDim2.fromOffset(5, 129)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 3
List.ScrollBarImageColor3 = Theme.Light
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 7)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = List

local function clearList()
    for _, child in ipairs(List:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function updateCanvas()
    task.wait()
    List.CanvasSize = UDim2.new(
        0,
        0,
        0,
        Layout.AbsoluteContentSize.Y + 10
    )
end

local function showMessage(message)
    clearList()

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 55)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextWrapped = true
    label.TextColor3 = Theme.Light
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.Parent = List
end

-- CARTÕES DE EMOTES

local function CreateCard(item, savedMode)
    local id = item.AssetId or item.Id
    if not id then return end

    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -5, 0, 76)
    Card.BackgroundColor3 = Theme.Card
    Card.Parent = List

    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 7)

    local Image = Instance.new("ImageLabel")
    Image.Size = UDim2.fromOffset(58, 58)
    Image.Position = UDim2.fromOffset(7, 9)
    Image.BackgroundTransparency = 1
    Image.Image = "rbxthumb://type=Asset&id="
        .. tostring(id) .. "&w=150&h=150"
    Image.Parent = Card

    local Name = Instance.new("TextLabel")
    Name.Size = UDim2.new(1, -150, 0, 35)
    Name.Position = UDim2.fromOffset(72, 5)
    Name.BackgroundTransparency = 1
    Name.Text = item.Name or "Emote"
    Name.TextColor3 = Theme.White
    Name.Font = Enum.Font.GothamBold
    Name.TextSize = 11
    Name.TextWrapped = true
    Name.TextXAlignment = Enum.TextXAlignment.Left
    Name.Parent = Card

    local Play = makeButton(
        Card,
        "PLAY",
        UDim2.fromOffset(55, 25),
        UDim2.new(1, -125, 1, -32),
        Theme.Green
    )

    Play.MouseButton1Click:Connect(function()
        LoadTrack(id)
    end)

    local Second = makeButton(
        Card,
        savedMode and "DEL" or (isSaved(id) and "✓" or "SAVE"),
        UDim2.fromOffset(55, 25),
        UDim2.new(1, -63, 1, -32),
        savedMode and Theme.Red or Theme.Purple
    )

    Second.MouseButton1Click:Connect(function()
        if savedMode then
            for i, v in ipairs(SavedEmotes) do
                if tostring(v.Id) == tostring(id) then
                    table.remove(SavedEmotes, i)
                    break
                end
            end

            saveSaved()
            Card:Destroy()
            updateCanvas()
        else
            if isSaved(id) then return end

            table.insert(SavedEmotes, {
                Id = id,
                AssetId = id,
                Name = item.Name or "Emote"
            })

            saveSaved()
            Second.Text = "✓"
        end
    end)
end

-- FILTRO

local function filterItems(items)
    local result = {}
    local keyword = string.lower(SearchBox.Text or "")

    for _, item in ipairs(items) do
        if keyword == ""
        or string.find(
            string.lower(tostring(item.Name or "")),
            keyword,
            1,
            true
        ) then
            table.insert(result, item)
        end
    end

    return result
end

local function showItems(items)
    clearList()

    for _, item in ipairs(filterItems(items)) do
        CreateCard(item, false)
    end

    updateCanvas()
end

local function ShowSaved()
    clearList()

    for _, item in ipairs(filterItems(SavedEmotes)) do
        CreateCard(item, true)
    end

    updateCanvas()
end

-- PAGINAÇÃO

local PageLabel = Instance.new("TextLabel")
PageLabel.Size = UDim2.fromOffset(100, 24)
PageLabel.Position = UDim2.new(0.5, -50, 0, 326)
PageLabel.BackgroundTransparency = 1
PageLabel.Text = "Página 1"
PageLabel.TextColor3 = Theme.Light
PageLabel.Font = Enum.Font.GothamBold
PageLabel.TextSize = 11
PageLabel.Parent = Main

local PreviousButton = makeButton(
    Main,
    "‹",
    UDim2.fromOffset(36, 26),
    UDim2.new(0.5, -85, 0, 325),
    Theme.Purple
)

local NextButton = makeButton(
    Main,
    "›",
    UDim2.fromOffset(36, 26),
    UDim2.new(0.5, 49, 0, 325),
    Theme.Purple
)

local function updatePageControls()
    local catalog = CurrentTab == "Catalog"

    PageLabel.Visible = catalog
    PreviousButton.Visible = catalog
    NextButton.Visible = catalog

    PageLabel.Text = "Página " .. CatalogPageIndex

    PreviousButton.BackgroundTransparency =
        CatalogPageIndex <= 1 and 0.5 or 0

    NextButton.BackgroundTransparency =
        (CatalogPages and CatalogPages.IsFinished) and 0.5 or 0
end

local function convertCatalogPage(items)
    local converted = {}

    for _, item in ipairs(items) do
        table.insert(converted, {
            Id = item.Id,
            AssetId = item.Id,
            Name = item.Name or "Emote"
        })
    end

    return converted
end

local function showCatalogPage()
    local items = CatalogPageHistory[CatalogPageIndex] or {}
    showItems(items)
    updatePageControls()
end

local function SearchCatalog(keyword)
    if Loading then return end

    Loading = true
    CatalogPageIndex = 1
    CatalogPageHistory = {}
    CatalogPages = nil

    showMessage("Pesquisando catálogo...")

    task.spawn(function()
        local success, pages = pcall(function()
            local params = CatalogSearchParams.new()
            params.SearchKeyword = keyword or ""
            params.AssetTypes = {
                Enum.AvatarAssetType.EmoteAnimation
            }
            params.Limit = PAGE_SIZE
            params.SortType = Enum.CatalogSortType.Relevance

            return AvatarEditorService:SearchCatalog(params)
        end)

        if success and pages then
            CatalogPages = pages

            local ok, items = pcall(function()
                return pages:GetCurrentPage()
            end)

            if ok and items then
                CatalogPageHistory[1] =
                    convertCatalogPage(items)
            end
        end

        Loading = false

        if CurrentTab == "Catalog" then
            if CatalogPageHistory[1] then
                showCatalogPage()
            else
                showMessage("Não foi possível carregar o catálogo.")
            end
        end
    end)
end

NextButton.MouseButton1Click:Connect(function()
    if Loading or CurrentTab ~= "Catalog" or not CatalogPages then
        return
    end

    if CatalogPages.IsFinished then return end

    if CatalogPageHistory[CatalogPageIndex + 1] then
        CatalogPageIndex += 1
        showCatalogPage()
        return
    end

    Loading = true
    showMessage("Carregando próxima página...")

    task.spawn(function()
        local success = pcall(function()
            CatalogPages:AdvanceToNextPageAsync()
        end)

        if success then
            local ok, items = pcall(function()
                return CatalogPages:GetCurrentPage()
            end)

            if ok and items then
                CatalogPageIndex += 1
                CatalogPageHistory[CatalogPageIndex] =
                    convertCatalogPage(items)
            end
        end

        Loading = false

        if CurrentTab == "Catalog" then
            showCatalogPage()
        end
    end)
end)

PreviousButton.MouseButton1Click:Connect(function()
    if Loading or CurrentTab ~= "Catalog" then return end
    if CatalogPageIndex <= 1 then return end

    CatalogPageIndex -= 1
    showCatalogPage()
end)

-- INVENTÁRIO

local function LoadInventory()
    if Loading then return end

    Loading = true
    showMessage("Carregando seus emotes...")

    task.spawn(function()
        local success, pages = pcall(function()
            return AvatarEditorService:GetInventoryAsync({
                Enum.AvatarAssetType.EmoteAnimation
            })
        end)

        if not success then
            pcall(function()
                AvatarEditorService:PromptAllowInventoryReadAccess()
            end)

            local event =
                AvatarEditorService.PromptAllowInventoryReadAccessCompleted

            local granted = false

            if event then
                local finished = false

                local connection = event:Connect(function(result)
                    granted =
                        result == Enum.AvatarPromptResult.Success
                    finished = true
                end)

                local start = os.clock()

                while not finished and os.clock() - start < 60 do
                    task.wait(0.2)
                end

                connection:Disconnect()
            end

            if granted then
                success, pages = pcall(function()
                    return AvatarEditorService:GetInventoryAsync({
                        Enum.AvatarAssetType.EmoteAnimation
                    })
                end)
            end
        end

        InventoryItems = {}

        if success and pages then
            repeat
                local ok, items = pcall(function()
                    return pages:GetCurrentPage()
                end)

                if ok and items then
                    for _, item in ipairs(items) do
                        table.insert(InventoryItems, {
                            Id = item.AssetId or item.Id,
                            AssetId = item.AssetId or item.Id,
                            Name = item.Name or "Emote"
                        })
                    end
                end

                if pages.IsFinished then break end

                local nextOK = pcall(function()
                    pages:AdvanceToNextPageAsync()
                end)

                if not nextOK then break end
            until pages.IsFinished
        end

        Loading = false

        if CurrentTab == "Inventory" then
            if #InventoryItems > 0 then
                showItems(InventoryItems)
            else
                showMessage(
                    "Nenhum emote encontrado ou acesso ao inventário indisponível."
                )
            end
        end
    end)
end

-- TROCA DE ABAS

local function SelectTab(tab)
    CurrentTab = tab

    InventoryTab.BackgroundColor3 =
        tab == "Inventory" and Theme.Purple or Theme.Card

    CatalogTab.BackgroundColor3 =
        tab == "Catalog" and Theme.Purple or Theme.Card

    SavedTab.BackgroundColor3 =
        tab == "Saved" and Theme.Purple or Theme.Card

    SearchBox.Visible = tab ~= "Saved"
    SearchButton.Visible = tab ~= "Saved"

    if tab == "Inventory" then
        SearchBox.PlaceholderText = "Filtrar meus emotes..."

        if #InventoryItems == 0 then
            LoadInventory()
        else
            showItems(InventoryItems)
        end

    elseif tab == "Catalog" then
        SearchBox.PlaceholderText = "Pesquisar emotes..."

        if CatalogPageHistory[CatalogPageIndex] then
            showCatalogPage()
        else
            SearchCatalog(SearchBox.Text)
        end

    elseif tab == "Saved" then
        ShowSaved()
    end

    updatePageControls()
end

InventoryTab.MouseButton1Click:Connect(function()
    SelectTab("Inventory")
end)

CatalogTab.MouseButton1Click:Connect(function()
    SelectTab("Catalog")
end)

SavedTab.MouseButton1Click:Connect(function()
    SelectTab("Saved")
end)

SearchButton.MouseButton1Click:Connect(function()
    if CurrentTab == "Catalog" then
        SearchCatalog(SearchBox.Text)
    elseif CurrentTab == "Inventory" then
        showItems(InventoryItems)
    end
end)

SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and CurrentTab == "Catalog" then
        SearchCatalog(SearchBox.Text)
    end
end)

-- CONTROLES INFERIORES

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.fromOffset(65, 27)
SpeedBox.Position = UDim2.fromOffset(5, 365)
SpeedBox.BackgroundColor3 = Theme.Panel
SpeedBox.TextColor3 = Theme.White
SpeedBox.Text = "1"
SpeedBox.PlaceholderText = "Velocidade"
SpeedBox.Font = Enum.Font.GothamBold
SpeedBox.TextSize = 12
SpeedBox.Parent = Main

Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 5)

SpeedBox.FocusLost:Connect(function()
    local value = tonumber(SpeedBox.Text)

    if value then
        Config.Speed = math.clamp(value, 0.1, 5)

        if CurrentTrack then
            pcall(function()
                CurrentTrack:AdjustSpeed(Config.Speed)
            end)
        end
    end

    SpeedBox.Text = tostring(Config.Speed)
end)

local LoopButton = makeButton(
    Main,
    "LOOP: ON",
    UDim2.fromOffset(75, 27),
    UDim2.fromOffset(75, 365),
    Theme.Green
)

LoopButton.MouseButton1Click:Connect(function()
    Config.Loop = not Config.Loop

    LoopButton.Text =
        Config.Loop and "LOOP: ON" or "LOOP: OFF"

    LoopButton.BackgroundColor3 =
        Config.Loop and Theme.Green or Theme.Card

    if CurrentTrack then
        CurrentTrack.Looped = Config.Loop
    end
end)

local StopButton = makeButton(
    Main,
    "STOP",
    UDim2.fromOffset(65, 27),
    UDim2.fromOffset(155, 365),
    Theme.Red
)

StopButton.MouseButton1Click:Connect(function()
    StopEmote()
    CurrentAnimation = nil
    Status.Text = "EMOTE ALWAYS | Parado"
end)

-- TOGGLE MOVER
-- OFF = para ao andar
-- ON = continua enquanto anda

local MoveButton = makeButton(
    Main,
    "MOVER: OFF",
    UDim2.fromOffset(100, 27),
    UDim2.fromOffset(225, 365),
    Theme.Card
)

MoveButton.MouseButton1Click:Connect(function()
    Config.StopOnMove = not Config.StopOnMove

    MoveButton.Text = Config.StopOnMove
        and "MOVER: OFF"
        or "MOVER: ON"

    MoveButton.BackgroundColor3 = Config.StopOnMove
        and Theme.Card
        or Theme.Green
end)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -10, 0, 18)
Status.Position = UDim2.fromOffset(5, 405)
Status.BackgroundTransparency = 1
Status.Text = "EMOTE ALWAYS | Pronto"
Status.TextColor3 = Theme.Light
Status.Font = Enum.Font.Gotham
Status.TextSize = 10
Status.Parent = Main

-- MONITOR DE MOVIMENTO

local monitor = RunService.Heartbeat:Connect(function()
    if not running then return end
    if not Config.StopOnMove then return end
    if not Humanoid or not CurrentTrack then return end

    -- Só interrompe quando MOVER estiver OFF
    if Humanoid.MoveDirection.Magnitude > 0.05 then
        StopEmote()
        CurrentAnimation = nil
        Status.Text = "EMOTE ALWAYS | Parado por movimento"
    end
end)

-- MINIMIZAR / REABRIR

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Floating.Visible = true
end)

Floating.MouseButton1Click:Connect(function()
    Main.Visible = true
    Floating.Visible = false
end)

-- ARRASTAR PAINEL

local dragging = false
local dragStart
local startPosition

Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- FECHAR

Close.MouseButton1Click:Connect(function()
    running = false
    StopEmote()

    if monitor then
        monitor:Disconnect()
    end

    GUI:Destroy()
end)

-- INICIALIZAÇÃO

SelectTab("Catalog")
SearchCatalog("")

print("[EMOTE ALWAYS v1.7] Carregado!")
