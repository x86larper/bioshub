-- Bios Hub | Blox Fruits | UI: Linoria
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function pressKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end
local function commF(...)
    local ok, res = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer(...)
    end)
    return ok and res or nil
end

local Window = Library:CreateWindow({
    Title = "Bios Hub | Blox Fruits",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Aura = Window:AddTab("Aura"),
    ESP = Window:AddTab("ESP"),
    FOV = Window:AddTab("FOV"),
    Teleport = Window:AddTab("Teleport"),
    Misc = Window:AddTab("Misc"),
    Shop = Window:AddTab("Shop"),
    Server = Window:AddTab("Server"),
    Settings = Window:AddTab("Settings"),
}

--------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------
local MainBox = Tabs.Main:AddLeftGroupbox("Main")

MainBox:AddToggle("AutoHaki", { Text = "Auto Haki", Default = false })
MainBox:AddToggle("AutoV3", { Text = "Auto V3", Default = false })
MainBox:AddToggle("AutoV4", { Text = "Auto V4", Default = false })
MainBox:AddToggle("AutoFlee", { Text = "Auto Flee", Default = false })
MainBox:AddSlider("FleeHP", {
    Text = "Flee HP Threshold (%)", Default = 30, Min = 1, Max = 100, Rounding = 0,
})

MainBox:AddInput("MoveSpeed", {
    Text = "Move Speed", Default = "50", Numeric = true, Finished = true,
})
MainBox:AddToggle("SpeedBoost", { Text = "Speed Boost", Default = false })
MainBox:AddInput("JumpHeight", {
    Text = "Jump Height", Default = "50", Numeric = true, Finished = true,
})
MainBox:AddToggle("HighJump", { Text = "High Jump", Default = false })
MainBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
MainBox:AddToggle("Noclip", { Text = "Noclip", Default = false })

-- Auto Haki (Buso)
task.spawn(function()
    while task.wait(1) do
        if Toggles.AutoHaki.Value then
            local c = getChar()
            if c and not c:FindFirstChild("HasBuso") then
                commF("Buso")
            end
        end
    end
end)

-- Auto V3 (tecla T) / Auto V4 (tecla Y)
task.spawn(function()
    while task.wait(2) do
        if Toggles.AutoV3.Value then pressKey(Enum.KeyCode.T) end
        if Toggles.AutoV4.Value then pressKey(Enum.KeyCode.Y) end
    end
end)

-- Auto Flee: sobe para o ceu quando a vida fica baixa
local fleeing = false
RunService.Heartbeat:Connect(function()
    if not Toggles.AutoFlee.Value then
        fleeing = false
        return
    end
    local hum, root = getHum(), getRoot()
    if not hum or not root or hum.MaxHealth <= 0 then return end
    local pct = hum.Health / hum.MaxHealth * 100
    if pct <= Options.FleeHP.Value and not fleeing then
        fleeing = true
        root.CFrame = root.CFrame + Vector3.new(0, 300, 0)
    elseif pct > Options.FleeHP.Value + 20 then
        fleeing = false
    end
end)

-- Velocidade / Pulo
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if not hum then return end
    if Toggles.SpeedBoost.Value then
        hum.WalkSpeed = tonumber(Options.MoveSpeed.Value) or 16
    end
    if Toggles.HighJump.Value then
        hum.UseJumpPower = true
        hum.JumpPower = tonumber(Options.JumpHeight.Value) or 50
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Toggles.InfJump.Value then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if Toggles.Noclip.Value then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- Fly
local flying = false
local flyBV, flyBG
local function stopFly()
    flying = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end
local function startFly()
    local root, hum = getRoot(), getHum()
    if not root or not hum then return end
    flying = true
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 9e4
    flyBG.Parent = root
end

MainBox:AddButton("Fly", function()
    if flying then stopFly() else startFly() end
end)
MainBox:AddSlider("FlySpeed", {
    Text = "Fly Speed", Default = 60, Min = 10, Max = 300, Rounding = 0,
})

RunService.RenderStepped:Connect(function()
    if not flying or not flyBV or not flyBG then return end
    local dir = Vector3.zero
    local cf = Camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
    flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Options.FlySpeed.Value or Vector3.zero
    flyBG.CFrame = cf
end)

LocalPlayer.CharacterAdded:Connect(function()
    flying = false
    flyBV, flyBG = nil, nil
end)

--------------------------------------------------------------------
-- AURA (efeito visual no personagem)
--------------------------------------------------------------------
local AuraBox = Tabs.Aura:AddLeftGroupbox("Aura")
AuraBox:AddToggle("AuraVisual", { Text = "Aura visual", Default = false })
AuraBox:AddLabel("Cor da aura"):AddColorPicker("AuraColor", {
    Default = Color3.fromRGB(0, 170, 255), Title = "Cor da aura",
})
AuraBox:AddSlider("AuraTransparency", {
    Text = "Transparência", Default = 0.5, Min = 0, Max = 1, Rounding = 2,
})

local auraHL
RunService.Heartbeat:Connect(function()
    local c = getChar()
    if Toggles.AuraVisual.Value and c then
        if not auraHL or auraHL.Parent ~= c then
            if auraHL then auraHL:Destroy() end
            auraHL = Instance.new("Highlight")
            auraHL.Name = "BiosAura"
            auraHL.Adornee = c
            auraHL.Parent = c
        end
        auraHL.FillColor = Options.AuraColor.Value
        auraHL.OutlineColor = Options.AuraColor.Value
        auraHL.FillTransparency = Options.AuraTransparency.Value
    elseif auraHL then
        auraHL:Destroy()
        auraHL = nil
    end
end)

--------------------------------------------------------------------
-- ESP
--------------------------------------------------------------------
local EspBox = Tabs.ESP:AddLeftGroupbox("ESP")
EspBox:AddToggle("PlayerESP", { Text = "Player ESP", Default = false })
EspBox:AddToggle("FruitESP", { Text = "Fruit ESP", Default = false })
EspBox:AddToggle("NameESP", { Text = "Nomes + distância", Default = true })
EspBox:AddLabel("Cor Players"):AddColorPicker("PlayerESPColor", {
    Default = Color3.fromRGB(255, 60, 60), Title = "Cor Players",
})
EspBox:AddLabel("Cor Frutas"):AddColorPicker("FruitESPColor", {
    Default = Color3.fromRGB(255, 170, 0), Title = "Cor Frutas",
})

local espCache = {}
local function clearESPEntry(obj)
    local e = espCache[obj]
    if e then
        if e.hl then e.hl:Destroy() end
        if e.bb then e.bb:Destroy() end
        espCache[obj] = nil
    end
end
local function makeESP(obj, adornee, label, colorOption)
    local e = espCache[obj]
    if not e then
        e = {}
        e.hl = Instance.new("Highlight")
        e.hl.Adornee = adornee
        e.hl.Parent = adornee
        e.bb = Instance.new("BillboardGui")
        e.bb.Size = UDim2.new(0, 200, 0, 30)
        e.bb.AlwaysOnTop = true
        e.bb.StudsOffset = Vector3.new(0, 3, 0)
        e.bb.Adornee = adornee
        e.bb.Parent = adornee
        e.txt = Instance.new("TextLabel")
        e.txt.Size = UDim2.fromScale(1, 1)
        e.txt.BackgroundTransparency = 1
        e.txt.TextStrokeTransparency = 0
        e.txt.Font = Enum.Font.GothamBold
        e.txt.TextSize = 13
        e.txt.Parent = e.bb
        espCache[obj] = e
    end
    local col = Options[colorOption].Value
    e.hl.FillColor = col
    e.hl.OutlineColor = col
    e.txt.TextColor3 = col
    e.bb.Enabled = Toggles.NameESP.Value
    local root = getRoot()
    local part = adornee:IsA("Model") and (adornee:FindFirstChild("HumanoidRootPart") or adornee.PrimaryPart)
        or adornee:FindFirstChildWhichIsA("BasePart", true)
    local dist = (root and part) and math.floor((root.Position - part.Position).Magnitude) or 0
    e.txt.Text = string.format("%s [%dm]", label, dist)
end

task.spawn(function()
    while task.wait(0.5) do
        local seen = {}
        if Toggles.PlayerESP.Value then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    seen[p] = true
                    makeESP(p, p.Character, p.Name, "PlayerESPColor")
                end
            end
        end
        if Toggles.FruitESP.Value then
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Tool") and obj.Name:find("Fruit") then
                    seen[obj] = true
                    makeESP(obj, obj, obj.Name, "FruitESPColor")
                end
            end
        end
        for obj in pairs(espCache) do
            if not seen[obj] then clearESPEntry(obj) end
        end
    end
end)

--------------------------------------------------------------------
-- FOV
--------------------------------------------------------------------
local FovBox = Tabs.FOV:AddLeftGroupbox("Campo de visão")
FovBox:AddToggle("CustomFOV", { Text = "FOV personalizado", Default = false })
FovBox:AddSlider("FOVValue", {
    Text = "FOV", Default = 70, Min = 30, Max = 120, Rounding = 0,
})
RunService.RenderStepped:Connect(function()
    if Toggles.CustomFOV.Value then
        Camera.FieldOfView = Options.FOVValue.Value
    end
end)

--------------------------------------------------------------------
-- TELEPORT
--------------------------------------------------------------------
local TpBox = Tabs.Teleport:AddLeftGroupbox("Teleport")
TpBox:AddDropdown("TpPlayer", {
    SpecialType = "Player", Text = "Jogador", Tooltip = "Escolha um jogador",
})
TpBox:AddButton("Teleportar para o jogador", function()
    local name = Options.TpPlayer.Value
    local target = name and Players:FindFirstChild(name)
    local tr = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    if tr and root then
        root.CFrame = tr.CFrame * CFrame.new(0, 0, 3)
    else
        Library:Notify("Jogador não encontrado.", 3)
    end
end)

local CoordBox = Tabs.Teleport:AddRightGroupbox("Coordenadas")
CoordBox:AddInput("TpX", { Text = "X", Default = "0", Numeric = true })
CoordBox:AddInput("TpY", { Text = "Y", Default = "100", Numeric = true })
CoordBox:AddInput("TpZ", { Text = "Z", Default = "0", Numeric = true })
CoordBox:AddButton("Teleportar", function()
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(
            tonumber(Options.TpX.Value) or 0,
            tonumber(Options.TpY.Value) or 100,
            tonumber(Options.TpZ.Value) or 0
        )
    end
end)

--------------------------------------------------------------------
-- MISC
--------------------------------------------------------------------
local MiscBox = Tabs.Misc:AddLeftGroupbox("Misc")
MiscBox:AddToggle("AntiAFK", { Text = "Anti-AFK", Default = true })
LocalPlayer.Idled:Connect(function()
    if Toggles.AntiAFK.Value then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

MiscBox:AddToggle("FullBright", { Text = "Full Bright", Default = false })
RunService.RenderStepped:Connect(function()
    if Toggles.FullBright.Value then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
    end
end)

MiscBox:AddButton("Boost de FPS", function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
    Library:Notify("Boost de FPS aplicado.", 3)
end)

--------------------------------------------------------------------
-- SHOP (remotes do jogo; podem mudar com atualizações)
--------------------------------------------------------------------
local ShopBox = Tabs.Shop:AddLeftGroupbox("Habilidades")
local function buyBtn(text, ...)
    local args = { ... }
    ShopBox:AddButton(text, function()
        commF(unpack(args))
        Library:Notify("Pedido enviado: " .. text, 3)
    end)
end
buyBtn("Comprar Geppo", "BuyHaki", "Geppo")
buyBtn("Comprar Buso Haki", "BuyHaki", "Buso")
buyBtn("Comprar Soru", "BuyHaki", "Soru")
buyBtn("Comprar Observation Haki", "KenTalk", "Buy")

local FruitBox = Tabs.Shop:AddRightGroupbox("Frutas")
FruitBox:AddButton("Loja de frutas (Blox Fruit Dealer)", function()
    local result = commF("GetFruits")
    if result then
        Library:Notify("Lista de frutas carregada.", 3)
    else
        Library:Notify("Não foi possível obter a loja.", 3)
    end
end)

--------------------------------------------------------------------
-- SERVER
--------------------------------------------------------------------
local ServerBox = Tabs.Server:AddLeftGroupbox("Servidor")
ServerBox:AddButton("Rejoin", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
ServerBox:AddButton("Server Hop", function()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId ..
            "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and data and data.data then
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                return
            end
        end
    end
    Library:Notify("Nenhum servidor disponível.", 3)
end)
ServerBox:AddButton("Copiar JobId", function()
    if setclipboard then
        setclipboard(game.JobId)
        Library:Notify("JobId copiado.", 3)
    end
end)
ServerBox:AddLabel("Jogadores: " .. #Players:GetPlayers())

--------------------------------------------------------------------
-- SETTINGS
--------------------------------------------------------------------
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Descarregar script", function()
    stopFly()
    Library:Unload()
end)
MenuGroup:AddLabel("Tecla do menu"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift", NoUI = true, Text = "Tecla do menu",
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("BiosHub")
SaveManager:SetFolder("BiosHub/BloxFruits")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify("Bios Hub carregado!", 5)
