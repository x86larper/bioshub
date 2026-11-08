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
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function Cam() return workspace.CurrentCamera end
local function T(n) local t = Toggles[n]; return t and t.Value end
local function O(n) local o = Options[n]; return o and o.Value end

local conns = {}
local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(conns, c)
    return c
end

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
    local args = { ... }
    local ok, res = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
    end)
    return ok and res or nil
end

-- lista de modelos alvo (players e/ou NPCs)
local function getModels(wantPlayers, wantNPCs)
    local list = {}
    if wantPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                table.insert(list, p.Character)
            end
        end
    end
    if wantNPCs then
        local folder = workspace:FindFirstChild("Enemies")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") then table.insert(list, m) end
            end
        end
    end
    return list
end

local Window = Library:CreateWindow({
    Title = "Bios Hub | Blox Fruits",
    Center = true,
    AutoShow = true,
    TabPadding = 6,
    Size = UDim2.fromOffset(700, 620),
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Aimbot = Window:AddTab("Aimbot"),
    Combat = Window:AddTab("Combat"),
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

task.spawn(function()
    while task.wait(1) and not Library.Unloaded do
        if T("AutoHaki") then
            local c = getChar()
            if c and not c:FindFirstChild("HasBuso") then
                commF("Buso")
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) and not Library.Unloaded do
        if T("AutoV3") then pressKey(Enum.KeyCode.T) end
        if T("AutoV4") then pressKey(Enum.KeyCode.Y) end
    end
end)

local fleeing = false
bind(RunService.Heartbeat, function()
    if not T("AutoFlee") then
        fleeing = false
        return
    end
    local hum, root = getHum(), getRoot()
    if not hum or not root or hum.MaxHealth <= 0 then return end
    local pct = hum.Health / hum.MaxHealth * 100
    local limit = O("FleeHP") or 30
    if pct <= limit and not fleeing then
        fleeing = true
        root.CFrame = root.CFrame + Vector3.new(0, 300, 0)
    elseif pct > limit + 20 then
        fleeing = false
    end
end)

-- Movimento
local MoveBox = Tabs.Main:AddRightGroupbox("Movimento")

MoveBox:AddDropdown("SpeedMode", {
    Values = { "CFrame", "WalkSpeed" }, Default = 1, Multi = false,
    Text = "Modo de velocidade",
    Tooltip = "CFrame costuma funcionar melhor no Blox Fruits",
})
MoveBox:AddSlider("MoveSpeed", {
    Text = "Move Speed", Default = 50, Min = 16, Max = 300, Rounding = 0,
})
MoveBox:AddToggle("SpeedBoost", { Text = "Speed Boost", Default = false })
MoveBox:AddSlider("JumpHeight", {
    Text = "Jump Height", Default = 50, Min = 50, Max = 300, Rounding = 0,
})
MoveBox:AddToggle("HighJump", { Text = "High Jump", Default = false })
MoveBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
MoveBox:AddToggle("Noclip", { Text = "Noclip", Default = false })

MoveBox:AddToggle("Fly", { Text = "Fly", Default = false }):AddKeyPicker("FlyKey", {
    Default = "H", SyncToggleState = true, Mode = "Toggle", Text = "Fly", NoUI = false,
})
MoveBox:AddSlider("FlySpeed", {
    Text = "Fly Speed", Default = 80, Min = 10, Max = 400, Rounding = 0,
})

MoveBox:AddToggle("InfSoru", { Text = "Infinite Soru", Default = false })

-- Velocidade e pulo
bind(RunService.Heartbeat, function(dt)
    local hum, root = getHum(), getRoot()
    if not hum or not root then return end
    if T("SpeedBoost") and not T("Fly") then
        local speed = O("MoveSpeed") or 16
        if O("SpeedMode") == "WalkSpeed" then
            hum.WalkSpeed = speed
        else
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                local extra = math.max(speed - 16, 0)
                root.CFrame = root.CFrame + md.Unit * extra * dt
            end
        end
    end
    if T("HighJump") then
        hum.UseJumpPower = true
        hum.JumpPower = O("JumpHeight") or 50
    end
end)

bind(RunService.RenderStepped, function()
    if T("SpeedBoost") and not T("Fly") and O("SpeedMode") == "WalkSpeed" then
        local hum = getHum()
        if hum then hum.WalkSpeed = O("MoveSpeed") or 16 end
    end
end)

bind(UserInputService.JumpRequest, function()
    if T("InfJump") then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

bind(RunService.Stepped, function()
    if T("Noclip") or T("Fly") then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- Fly
local flyBV, flyBG
local function cleanFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

bind(RunService.Heartbeat, function()
    if not T("Fly") then
        if flyBV or flyBG then cleanFly() end
        return
    end
    local root, hum = getRoot(), getHum()
    local cam = Cam()
    if not root or not hum or not cam then return end

    if not flyBV or flyBV.Parent ~= root then
        if flyBV then flyBV:Destroy() end
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "BiosFlyBV"
        flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBV.P = 1e5
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = root
    end
    if not flyBG or flyBG.Parent ~= root then
        if flyBG then flyBG:Destroy() end
        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "BiosFlyBG"
        flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyBG.P = 1e5
        flyBG.Parent = root
    end
    hum.PlatformStand = true

    local cf = cam.CFrame
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
    if dir.Magnitude == 0 and hum.MoveDirection.Magnitude > 0 then
        dir = hum.MoveDirection -- celular
    end

    local vel = dir.Magnitude > 0 and dir.Unit * (O("FlySpeed") or 80) or Vector3.zero
    flyBV.Velocity = vel
    root.AssemblyLinearVelocity = vel
    flyBG.CFrame = cf
end)

-- Infinite Soru (precisa de getgc / debug.getupvalues no executor)
local soruTables = {}
local function findSoru()
    soruTables = {}
    if not (getgc and debug and debug.getupvalues and getfenv) then return end
    local char = getChar()
    local soru = char and char:FindFirstChild("Soru")
    if not soru then return end
    for _, v in ipairs(getgc()) do
        if type(v) == "function" and (not islclosure or islclosure(v)) then
            local ok, env = pcall(getfenv, v)
            if ok and type(env) == "table" and rawget(env, "script") == soru then
                local ok2, ups = pcall(debug.getupvalues, v)
                if ok2 and type(ups) == "table" then
                    for _, u in pairs(ups) do
                        if type(u) == "table" then
                            table.insert(soruTables, u)
                        end
                    end
                end
            end
        end
    end
end

Toggles.InfSoru:OnChanged(function()
    if Toggles.InfSoru.Value and not (getgc and debug and debug.getupvalues) then
        Library:Notify("Seu executor não suporta getgc/debug.getupvalues; Infinite Soru não vai funcionar.", 6)
    end
end)

task.spawn(function()
    local lastSearch = 0
    while task.wait(0.1) and not Library.Unloaded do
        if T("InfSoru") then
            if #soruTables == 0 and tick() - lastSearch > 3 then
                lastSearch = tick()
                pcall(findSoru)
            end
            for _, tbl in ipairs(soruTables) do
                pcall(function() tbl.LastUse = 0 end)
            end
        end
    end
end)
bind(LocalPlayer.CharacterAdded, function() soruTables = {} end)

--------------------------------------------------------------------
-- AIMBOT
--------------------------------------------------------------------
local AimBox = Tabs.Aimbot:AddLeftGroupbox("Aimbot")

AimBox:AddToggle("Aimbot", { Text = "Aimbot", Default = false }):AddKeyPicker("AimbotKey", {
    Default = "G", SyncToggleState = true, Mode = "Toggle", Text = "Aimbot", NoUI = false,
})
AimBox:AddToggle("TargetPlayers", { Text = "Target Player", Default = true })
AimBox:AddToggle("TargetNPCs", { Text = "Target NPC", Default = true })
AimBox:AddDropdown("AimPriority", {
    Values = { "Menor vida", "Mais perto do cursor", "Mais perto de mim" },
    Default = 1, Multi = false, Text = "Prioridade",
})
AimBox:AddDropdown("AimPart", {
    Values = { "HumanoidRootPart", "Head" }, Default = 1, Multi = false, Text = "Parte do alvo",
})
AimBox:AddToggle("SkillAimbot", { Text = "Aimbot em skills/melee", Default = true })
AimBox:AddToggle("GunAimbot", { Text = "Gun Aimbot", Default = true })
AimBox:AddSlider("AimMaxDist", {
    Text = "Distância máxima", Default = 500, Min = 20, Max = 2000, Rounding = 0,
})
AimBox:AddSlider("AimPrediction", {
    Text = "Previsão de movimento", Default = 0, Min = 0, Max = 0.5, Rounding = 2,
})
AimBox:AddToggle("CameraLock", { Text = "Camera Lock (puxa a câmera)", Default = false })
AimBox:AddSlider("CameraSmooth", {
    Text = "Suavização da câmera", Default = 0.5, Min = 0, Max = 0.95, Rounding = 2,
})

local FovBox = Tabs.Aimbot:AddRightGroupbox("FOV do aimbot")
FovBox:AddSlider("AimFOV", {
    Text = "Tamanho do FOV", Default = 150, Min = 10, Max = 600, Rounding = 0,
})
FovBox:AddSlider("AimFOVThickness", {
    Text = "Espessura", Default = 1, Min = 1, Max = 5, Rounding = 0,
})
FovBox:AddLabel("Cor do FOV"):AddColorPicker("AimFOVColor", {
    Default = Color3.fromRGB(255, 255, 255), Title = "Cor do FOV",
})

local BlackBox = Tabs.Aimbot:AddRightGroupbox("Skill Blacklist")
BlackBox:AddLabel("Marque o que NÃO deve usar o aimbot", true)
BlackBox:AddDropdown("SkillBlacklist", {
    Values = { "M1", "Z", "X", "C", "V", "F" },
    Default = 1, Multi = true, Text = "Ataques ignorados",
})

local AimState = { active = false, pos = nil, part = nil, toolOk = true }

local FOVCircle
if Drawing then
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Visible = false
        FOVCircle.Filled = false
        FOVCircle.NumSides = 64
        FOVCircle.Transparency = 1
    end)
end

-- Blacklist de skills
local blacklistKeys, blacklistM1 = {}, false
local blockedUntil = 0
local function rebuildBlacklist()
    blacklistKeys, blacklistM1 = {}, false
    local v = O("SkillBlacklist")
    if type(v) == "table" then
        for name, on in pairs(v) do
            if on then
                if name == "M1" then
                    blacklistM1 = true
                else
                    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
                    if ok and kc then table.insert(blacklistKeys, kc) end
                end
            end
        end
    end
end
Options.SkillBlacklist:OnChanged(rebuildBlacklist)
rebuildBlacklist()

local function skillBlocked()
    if tick() < blockedUntil then return true end
    for _, kc in ipairs(blacklistKeys) do
        if UserInputService:IsKeyDown(kc) then return true end
    end
    if blacklistM1 and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        return true
    end
    return false
end

bind(UserInputService.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for _, kc in ipairs(blacklistKeys) do
            if input.KeyCode == kc then blockedUntil = tick() + 0.7 end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and blacklistM1 then
        blockedUntil = tick() + 0.4
    end
end)

-- Escolha do alvo
local function findTarget()
    local cam = Cam()
    if not cam then return nil end
    local mousePos = UserInputService:GetMouseLocation()
    local radius = O("AimFOV") or 150
    local maxDist = O("AimMaxDist") or 500
    local partName = O("AimPart") or "HumanoidRootPart"
    local prio = O("AimPriority") or "Menor vida"
    local myRoot = getRoot()

    local best, bestScore
    for _, model in ipairs(getModels(T("TargetPlayers"), T("TargetNPCs"))) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        local part = model:FindFirstChild(partName) or model:FindFirstChild("HumanoidRootPart")
        if hum and part and hum.Health > 0 then
            local worldDist = myRoot and (myRoot.Position - part.Position).Magnitude or 0
            if worldDist <= maxDist then
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                    if d <= radius then
                        local score
                        if prio == "Menor vida" then
                            score = hum.Health + d / 100000
                        elseif prio == "Mais perto do cursor" then
                            score = d
                        else
                            score = worldDist
                        end
                        if not bestScore or score < bestScore then
                            bestScore = score
                            best = { model = model, part = part }
                        end
                    end
                end
            end
        end
    end
    return best
end

local function toolAllowsAim()
    local c = getChar()
    local tool = c and c:FindFirstChildOfClass("Tool")
    if tool and tool.ToolTip == "Gun" then
        return T("GunAimbot") == true
    end
    return T("SkillAimbot") == true
end

pcall(function() RunService:UnbindFromRenderStep("BiosAimbot") end)
RunService:BindToRenderStep("BiosAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    local on = T("Aimbot")
    if FOVCircle then
        FOVCircle.Visible = on and true or false
        if on then
            FOVCircle.Position = UserInputService:GetMouseLocation()
            FOVCircle.Radius = O("AimFOV") or 150
            FOVCircle.Thickness = O("AimFOVThickness") or 1
            FOVCircle.Color = O("AimFOVColor") or Color3.new(1, 1, 1)
        end
    end
    if not on then
        AimState.active = false
        return
    end

    local t = findTarget()
    if not t then
        AimState.active = false
        return
    end
    local pred = O("AimPrediction") or 0
    local vel = t.part.AssemblyLinearVelocity
    AimState.pos = t.part.Position + vel * pred
    AimState.part = t.part
    AimState.toolOk = toolAllowsAim()
    AimState.active = true

    if T("CameraLock") and AimState.toolOk and not skillBlocked() then
        local cam = Cam()
        local alpha = math.clamp(1 - (O("CameraSmooth") or 0.5), 0.02, 1)
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, AimState.pos), alpha)
    end
end)

-- Silent aim: troca Mouse.Hit / Mouse.Target quando o jogo lê
local oldIndex
if hookmetamethod and newcclosure and checkcaller then
    local ok = pcall(function()
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if AimState.active and AimState.toolOk and self == Mouse and not checkcaller() then
                if key == "Hit" or key == "Target" then
                    if not skillBlocked() then
                        if key == "Hit" then
                            return CFrame.new(AimState.pos)
                        else
                            return AimState.part
                        end
                    end
                end
            end
            return oldIndex(self, key)
        end))
    end)
    if not ok then
        Library:Notify("Silent aim indisponível; use o Camera Lock.", 6)
    end
else
    Library:Notify("Seu executor não tem hookmetamethod; use o Camera Lock.", 6)
end

--------------------------------------------------------------------
-- COMBAT
--------------------------------------------------------------------
local FastBox = Tabs.Combat:AddLeftGroupbox("Fast Attack")
FastBox:AddToggle("FastAttack", { Text = "Fast Attack", Default = false })
FastBox:AddSlider("FastAttackDelay", {
    Text = "Delay (segundos)", Default = 0.1, Min = 0.01, Max = 1, Rounding = 2,
})
FastBox:AddLabel("Funciona por cliques automáticos, então o jogo ainda limita o combo.", true)

task.spawn(function()
    while not Library.Unloaded do
        task.wait(math.max(O("FastAttackDelay") or 0.1, 0.01))
        if T("FastAttack") then
            local c = getChar()
            local tool = c and c:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
            pcall(function()
                local cam = Cam()
                VirtualUser:Button1Down(Vector2.new(0, 0), cam and cam.CFrame)
                VirtualUser:Button1Up(Vector2.new(0, 0), cam and cam.CFrame)
            end)
        end
    end
end)

local HitBox = Tabs.Combat:AddRightGroupbox("Hitbox")
HitBox:AddToggle("Hitbox", { Text = "Hitbox Extender", Default = false })
HitBox:AddToggle("HitboxPlayers", { Text = "Em players", Default = true })
HitBox:AddToggle("HitboxNPCs", { Text = "Em NPCs", Default = true })
HitBox:AddSlider("HitboxSize", {
    Text = "Tamanho", Default = 15, Min = 2, Max = 60, Rounding = 0,
})
HitBox:AddToggle("HitboxVisual", { Text = "Hitbox Visual", Default = false })
HitBox:AddLabel("Cor da hitbox"):AddColorPicker("HitboxColor", {
    Default = Color3.fromRGB(255, 0, 80), Title = "Cor da hitbox",
})

local hitboxOriginal = {}
local hitboxAdorn = {}

local function restoreHitbox(part)
    local data = hitboxOriginal[part]
    if data and part and part.Parent then
        part.Size = data.Size
        part.CanCollide = data.CanCollide
    end
    hitboxOriginal[part] = nil
end
local function removeAdorn(part)
    local a = hitboxAdorn[part]
    if a then a:Destroy() end
    hitboxAdorn[part] = nil
end

task.spawn(function()
    while task.wait(0.1) and not Library.Unloaded do
        local active, shown = {}, {}
        local models = getModels(T("HitboxPlayers"), T("HitboxNPCs"))
        for _, model in ipairs(models) do
            local part = model:FindFirstChild("HumanoidRootPart")
            local hum = model:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                if T("Hitbox") then
                    active[part] = true
                    if not hitboxOriginal[part] then
                        hitboxOriginal[part] = { Size = part.Size, CanCollide = part.CanCollide }
                    end
                    local s = O("HitboxSize") or 15
                    part.Size = Vector3.new(s, s, s)
                    part.CanCollide = false
                end
                if T("HitboxVisual") then
                    shown[part] = true
                    local a = hitboxAdorn[part]
                    if not a or a.Parent == nil then
                        a = Instance.new("BoxHandleAdornment")
                        a.AlwaysOnTop = true
                        a.ZIndex = 5
                        a.Transparency = 0.7
                        a.Adornee = part
                        a.Parent = Cam() or workspace
                        hitboxAdorn[part] = a
                    end
                    a.Size = part.Size
                    a.Color3 = O("HitboxColor") or Color3.fromRGB(255, 0, 80)
                end
            end
        end
        for part in pairs(hitboxOriginal) do
            if not active[part] then restoreHitbox(part) end
        end
        for part in pairs(hitboxAdorn) do
            if not shown[part] then removeAdorn(part) end
        end
    end
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
bind(RunService.Heartbeat, function()
    local c = getChar()
    if T("AuraVisual") and c then
        if not auraHL or auraHL.Parent ~= c then
            if auraHL then auraHL:Destroy() end
            auraHL = Instance.new("Highlight")
            auraHL.Name = "BiosAura"
            auraHL.Adornee = c
            auraHL.Parent = c
        end
        auraHL.FillColor = O("AuraColor") or Color3.new(0, 0.6, 1)
        auraHL.OutlineColor = auraHL.FillColor
        auraHL.FillTransparency = O("AuraTransparency") or 0.5
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
    local col = O(colorOption) or Color3.new(1, 1, 1)
    e.hl.FillColor = col
    e.hl.OutlineColor = col
    e.txt.TextColor3 = col
    e.bb.Enabled = T("NameESP") and true or false
    local root = getRoot()
    local part = adornee:IsA("Model") and (adornee:FindFirstChild("HumanoidRootPart") or adornee.PrimaryPart)
        or adornee:FindFirstChildWhichIsA("BasePart", true)
    local dist = (root and part) and math.floor((root.Position - part.Position).Magnitude) or 0
    e.txt.Text = string.format("%s [%dm]", label, dist)
end

task.spawn(function()
    while task.wait(0.5) and not Library.Unloaded do
        local seen = {}
        if T("PlayerESP") then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    seen[p] = true
                    makeESP(p, p.Character, p.Name, "PlayerESPColor")
                end
            end
        end
        if T("FruitESP") then
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
-- FOV (câmera)
--------------------------------------------------------------------
local CamFovBox = Tabs.FOV:AddLeftGroupbox("Campo de visão")
CamFovBox:AddToggle("CustomFOV", { Text = "FOV personalizado", Default = false })
CamFovBox:AddSlider("FOVValue", {
    Text = "FOV", Default = 70, Min = 30, Max = 120, Rounding = 0,
})
bind(RunService.RenderStepped, function()
    if T("CustomFOV") then
        local cam = Cam()
        if cam then cam.FieldOfView = O("FOVValue") or 70 end
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
    local name = O("TpPlayer")
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
            tonumber(O("TpX")) or 0,
            tonumber(O("TpY")) or 100,
            tonumber(O("TpZ")) or 0
        )
    end
end)

--------------------------------------------------------------------
-- MISC
--------------------------------------------------------------------
local MiscBox = Tabs.Misc:AddLeftGroupbox("Misc")
MiscBox:AddToggle("AntiAFK", { Text = "Anti-AFK", Default = true })
bind(LocalPlayer.Idled, function()
    if T("AntiAFK") then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

MiscBox:AddToggle("FullBright", { Text = "Full Bright", Default = false })
bind(RunService.RenderStepped, function()
    if T("FullBright") then
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

local RemBox = Tabs.Misc:AddRightGroupbox("Stats e Raça (gasta fragmentos)")
RemBox:AddButton({
    Text = "Reset Stats (clique 2x)",
    DoubleClick = true,
    Func = function()
        local r1 = commF("BlackbeardReward", "Refund", "1")
        task.wait(0.3)
        local r2 = commF("BlackbeardReward", "Refund", "2")
        Library:Notify("Reset de stats enviado. Resposta: " .. tostring(r2 or r1), 5)
    end,
})
RemBox:AddButton({
    Text = "Girar raça (clique 2x)",
    DoubleClick = true,
    Func = function()
        local r1 = commF("BlackbeardReward", "Reroll", "1")
        task.wait(0.3)
        local r2 = commF("BlackbeardReward", "Reroll", "2")
        Library:Notify("Giro de raça enviado. Resposta: " .. tostring(r2 or r1), 5)
    end,
})

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
MenuGroup:AddButton("Descarregar script", function() Library:Unload() end)
MenuGroup:AddLabel("Tecla do menu"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift", NoUI = true, Text = "Tecla do menu",
})
Library.ToggleKeybind = Options.MenuKeybind

Library:OnUnload(function()
    cleanFly()
    pcall(function() RunService:UnbindFromRenderStep("BiosAimbot") end)
    AimState.active = false
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    for part in pairs(hitboxOriginal) do restoreHitbox(part) end
    for part in pairs(hitboxAdorn) do removeAdorn(part) end
    for obj in pairs(espCache) do clearESPEntry(obj) end
    if auraHL then auraHL:Destroy() end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
end)

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
