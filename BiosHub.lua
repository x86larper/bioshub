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
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function Cam() return workspace.CurrentCamera end
local function T(n) local t = Toggles[n]; return t and t.Value end
local function O(n) local o = Options[n]; return o and o.Value end

-- erros aparecem na tela (para eu conseguir corrigir)
local errSeen = {}
local function report(name, err)
    if not errSeen[name] then
        errSeen[name] = true
        warn("[BiosHub] " .. name .. ": " .. tostring(err))
        pcall(function()
            Library:Notify(name .. " erro: " .. tostring(err):sub(1, 140), 10)
        end)
    end
end

local conns = {}
local function bind(signal, fn, name)
    name = name or "bind"
    local c = signal:Connect(function(...)
        local ok, err = pcall(fn, ...)
        if not ok then report(name, err) end
    end)
    table.insert(conns, c)
    return c
end
local function loop(name, delay, fn)
    task.spawn(function()
        while not Library.Unloaded do
            local d = type(delay) == "function" and delay() or delay
            task.wait(d)
            local ok, err = pcall(fn)
            if not ok then report(name, err) end
        end
    end)
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

loop("AutoHaki", 1, function()
    if T("AutoHaki") then
        local c = getChar()
        if c and not c:FindFirstChild("HasBuso") then
            commF("Buso")
        end
    end
end)

loop("AutoV3V4", 2, function()
    if T("AutoV3") then pressKey(Enum.KeyCode.T) end
    if T("AutoV4") then pressKey(Enum.KeyCode.Y) end
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
end, "AutoFlee")

local MoveBox = Tabs.Main:AddRightGroupbox("Movimento")

MoveBox:AddDropdown("SpeedMode", {
    Values = { "CFrame", "WalkSpeed" }, Default = 1, Multi = false,
    Text = "Modo de velocidade",
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
MoveBox:AddSlider("SoruDelay", {
    Text = "Delay do Soru (s)", Default = 1, Min = 0, Max = 3, Rounding = 1,
})
MoveBox:AddToggle("WalkWater", { Text = "Walk on Water", Default = false })
MoveBox:AddToggle("WalkLava", { Text = "Walk on Lava", Default = false })
MoveBox:AddSlider("WaterHeight", {
    Text = "Altura da água (ajuste)", Default = 113, Min = 80, Max = 200, Rounding = 0,
})
local WalkStatus = MoveBox:AddLabel("Walk: desligado")
MoveBox:AddToggle("Unbreakable", { Text = "Unbreakable Skills (anti-stun)", Default = false })

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
end, "Speed")

bind(RunService.RenderStepped, function()
    if T("SpeedBoost") and not T("Fly") and O("SpeedMode") == "WalkSpeed" then
        local hum = getHum()
        if hum then hum.WalkSpeed = O("MoveSpeed") or 16 end
    end
end, "SpeedRender")

bind(UserInputService.JumpRequest, function()
    if T("InfJump") then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end, "InfJump")

bind(RunService.Stepped, function()
    if T("Noclip") or T("Fly") then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end, "Noclip")

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
        dir = hum.MoveDirection
    end

    local vel = dir.Magnitude > 0 and dir.Unit * (O("FlySpeed") or 80) or Vector3.zero
    flyBV.Velocity = vel
    root.AssemblyLinearVelocity = vel
    flyBG.CFrame = cf
end, "Fly")

-- Infinite Soru
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

local soruState = setmetatable({}, { __mode = "k" })
local lastSoruSearch = 0
loop("InfSoru", 0.05, function()
    if not T("InfSoru") then return end
    if #soruTables == 0 and tick() - lastSoruSearch > 3 then
        lastSoruSearch = tick()
        pcall(findSoru)
    end
    local delay = O("SoruDelay") or 1
    for _, tbl in ipairs(soruTables) do
        pcall(function()
            local st = soruState[tbl]
            if not st then
                st = { seen = tbl.LastUse, usedAt = nil }
                soruState[tbl] = st
            end
            local lu = tbl.LastUse
            -- detecta quando o Soru foi usado e libera de novo depois do delay
            if lu ~= nil and lu ~= 0 and lu ~= st.seen then
                st.seen = lu
                st.usedAt = tick()
            end
            if st.usedAt and tick() - st.usedAt >= delay then
                tbl.LastUse = 0
                st.seen = 0
                st.usedAt = nil
            end
        end)
    end
end)
bind(LocalPlayer.CharacterAdded, function() soruTables = {} end, "SoruChar")

-- Walk on Water / Lava
local lastWalk = ""
local function setWalk(t)
    if t ~= lastWalk then
        lastWalk = t
        WalkStatus:SetText(t)
    end
end

local surfPlat
local waterOrig
local lavaParts = {}
local lavaTouched = {}

local function hidePlat()
    if surfPlat then
        pcall(function() surfPlat:Destroy() end)
        surfPlat = nil
    end
end
local function restoreWater()
    if waterOrig then
        local d = waterOrig
        if d.part and d.part.Parent then
            pcall(function()
                d.part.Size = d.Size
                d.part.CanCollide = d.CanCollide
            end)
        end
        waterOrig = nil
    end
end
local function restoreLava()
    for part, old in pairs(lavaTouched) do
        if part and part.Parent then part.CanTouch = old end
    end
    lavaTouched = {}
end
local function isLavaPart(part)
    if not part:IsA("BasePart") then return false end
    if part.Name:lower():find("lava") then return true end
    return part.Material == Enum.Material.CrackedLava or part.Material == Enum.Material.Magma
end
local function findWaterPlane()
    local map = workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("WaterBase-Plane")
end

-- guarda as partes de lava do mapa (varredura leve a cada 3s)
loop("LavaScan", 3, function()
    if not T("WalkLava") then return end
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local list, n = {}, 0
    for _, v in ipairs(map:GetDescendants()) do
        n = n + 1
        if n % 3000 == 0 then task.wait() end
        if isLavaPart(v) then list[#list + 1] = v end
    end
    lavaParts = list
end)

local function placePlat(root, topY)
    if not surfPlat or not surfPlat.Parent then
        surfPlat = Instance.new("Part")
        surfPlat.Name = "BiosPlatform"
        surfPlat.Anchored = true
        surfPlat.CanCollide = true
        surfPlat.CanQuery = false
        surfPlat.Transparency = 1
        surfPlat.Size = Vector3.new(24, 1, 24)
        surfPlat.Parent = workspace
    end
    surfPlat.CFrame = CFrame.new(root.Position.X, topY - 0.5, root.Position.Z)
end

bind(RunService.Heartbeat, function()
    local wantW, wantL = T("WalkWater"), T("WalkLava")
    if not wantW then restoreWater() end
    if not wantL and next(lavaTouched) then restoreLava() end
    if not wantW and not wantL then
        if surfPlat then hidePlat() end
        setWalk("Walk: desligado")
        return
    end
    local root, char = getRoot(), getChar()
    if not root or not char then return end

    local topY
    local status = {}

    if wantW then
        local wp = findWaterPlane()
        if wp then
            -- metodo principal: engrossa o plano de agua do mapa e deixa solido
            if not waterOrig or waterOrig.part ~= wp then
                restoreWater()
                waterOrig = { part = wp, Size = wp.Size, CanCollide = wp.CanCollide }
            end
            local h = O("WaterHeight") or 113
            if wp.Size.Y ~= h then
                wp.Size = Vector3.new(wp.Size.X, h, wp.Size.Z)
            end
            if not wp.CanCollide then wp.CanCollide = true end
            table.insert(status, "água: plano ok")
        else
            -- plano B: agua de terreno (plataforma sob os pes)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = surfPlat and { char, surfPlat } or { char }
            params.IgnoreWater = false
            local res = workspace:Raycast(root.Position, Vector3.new(0, -50, 0), params)
            if res and res.Material == Enum.Material.Water then
                topY = res.Position.Y
                table.insert(status, "água: terreno")
            else
                table.insert(status, "água: não encontrada")
            end
        end
    end

    if wantL then
        local best
        for _, part in ipairs(lavaParts) do
            if part.Parent then
                local lp = part.CFrame:PointToObjectSpace(root.Position)
                local half = part.Size * 0.5
                if math.abs(lp.X) <= half.X + 2 and math.abs(lp.Z) <= half.Z + 2
                    and lp.Y > -half.Y - 4 and lp.Y < half.Y + 30 then
                    local top = (part.CFrame * Vector3.new(0, half.Y, 0)).Y
                    if not best or top > best then best = top end
                    if lavaTouched[part] == nil then
                        lavaTouched[part] = part.CanTouch
                        part.CanTouch = false
                    end
                end
            end
        end
        if best then
            local want = best + 2
            topY = topY and math.max(topY, want) or want
            table.insert(status, "lava: sobre lava")
        else
            table.insert(status, "lava: " .. #lavaParts .. " partes")
        end
    end
    setWalk("Walk: " .. table.concat(status, " | "))

    if topY then
        placePlat(root, topY)
    else
        hidePlat()
    end
end, "SurfaceWalk")

-- Unbreakable Skills: tira stun/ragdoll/knockback do cliente
local STUN_WORDS = { "stun", "ragdoll", "knock", "freeze", "frozen", "stagger", "flinch" }
local function isStunName(name)
    local n = name:lower()
    for _, w in ipairs(STUN_WORDS) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

bind(RunService.Heartbeat, function()
    if not T("Unbreakable") then return end
    local char, hum, root = getChar(), getHum(), getRoot()
    if not char or not hum then return end

    for _, c in ipairs(char:GetChildren()) do
        if isStunName(c.Name) then
            if c:IsA("BoolValue") then
                if c.Value then c.Value = false end
            elseif c:IsA("NumberValue") or c:IsA("IntValue") then
                if c.Value ~= 0 then c.Value = 0 end
            elseif c:IsA("BodyVelocity") or c:IsA("BodyPosition") or c:IsA("BodyGyro") or c:IsA("BodyForce") then
                c:Destroy()
            end
        end
    end
    for name, val in pairs(char:GetAttributes()) do
        if isStunName(tostring(name)) then
            if val == true then
                char:SetAttribute(name, false)
            elseif type(val) == "number" and val ~= 0 then
                char:SetAttribute(name, 0)
            end
        end
    end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end)
    if hum.PlatformStand and not T("Fly") then hum.PlatformStand = false end
    if root and root.Anchored then root.Anchored = false end
end, "Unbreakable")

-- Debug: copia informacoes para eu ajustar o script
local function fmtV(v) return string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z) end
local function partInfo(part)
    return string.format("%s [%s] pos(%s) size(%s) CanCollide=%s CanQuery=%s Material=%s",
        part:GetFullName(), part.ClassName, fmtV(part.Position), fmtV(part.Size),
        tostring(part.CanCollide), tostring(part.CanQuery), tostring(part.Material))
end
local function copyDebug()
    local out = {}
    local function add(t) table.insert(out, t) end
    local char, root, hum = getChar(), getRoot(), getHum()

    add("== Jogador ==")
    if root then add("root: " .. fmtV(root.Position)) end
    if hum then add("estado: " .. tostring(hum:GetState()) .. " | WalkSpeed " .. tostring(hum.WalkSpeed)) end
    if root and char then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char }
        params.IgnoreWater = false
        local res = workspace:Raycast(root.Position, Vector3.new(0, -80, 0), params)
        if res then
            add("raio p/ baixo: " .. res.Instance:GetFullName() .. " | material " .. tostring(res.Material)
                .. " | y " .. string.format("%.1f", res.Position.Y))
        else
            add("raio p/ baixo: nada")
        end
    end

    add("== Partes com 'water' no nome ==")
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("water") then
            n = n + 1
            if n > 12 then break end
            add(partInfo(v))
        end
    end

    add("== Lava (" .. #lavaParts .. " no cache; ligue Walk on Lava antes) ==")
    for i = 1, math.min(#lavaParts, 8) do
        if lavaParts[i].Parent then add(partInfo(lavaParts[i])) end
    end

    add("== Personagem ==")
    if char then
        local k = 0
        for _, c in ipairs(char:GetChildren()) do
            k = k + 1
            if k > 80 then break end
            local val = c:IsA("ValueBase") and (" = " .. tostring(c.Value)) or ""
            add(c.ClassName .. " " .. c.Name .. val)
        end
        for name, val in pairs(char:GetAttributes()) do
            add("attr " .. tostring(name) .. " = " .. tostring(val))
        end
    end

    if setclipboard then
        setclipboard(table.concat(out, "\n"))
        Library:Notify("Debug copiado (" .. #out .. " linhas). Cole aqui no chat.", 5)
    else
        Library:Notify("Seu executor não tem setclipboard.", 4)
    end
end

local DbgMisc = Tabs.Misc:AddRightGroupbox("Debug (me mande o resultado)")
DbgMisc:AddLabel("Para água/lava/stun: fique em cima da água ou lava (com o toggle ligado) e clique no botão. Para o stun, clique logo depois de levar um hit.", true)
DbgMisc:AddButton("Copiar debug (água, lava, personagem)", copyDebug)

--------------------------------------------------------------------
-- AIMBOT
--------------------------------------------------------------------
local AimBox = Tabs.Aimbot:AddLeftGroupbox("Aimbot")

AimBox:AddToggle("Aimbot", { Text = "Aimbot", Default = false }):AddKeyPicker("AimbotKey", {
    Default = "G", SyncToggleState = true, Mode = "Toggle", Text = "Aimbot", NoUI = false,
})
local AimStatus = AimBox:AddLabel("Alvo: aimbot desligado")
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
local AdvBox = Tabs.Aimbot:AddRightGroupbox("Aimbot avançado")
AdvBox:AddLabel("Se alguma skill errar, desligue uma opção por vez para achar a causa.", true)
AdvBox:AddToggle("AimHookMouse", { Text = "Redirecionar Mouse (Hit/Target)", Default = true })
AdvBox:AddToggle("AimHookRays", { Text = "Redirecionar raios da câmera", Default = true })
AdvBox:AddToggle("AimRemotes", { Text = "Redirecionar remotes da skill", Default = true })
AdvBox:AddToggle("AimSticky", { Text = "Manter alvo travado", Default = false })
AdvBox:AddToggle("AimFaceSkill", { Text = "Virar para o alvo ao usar skill", Default = false })
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
FovBox:AddToggle("AimLine", { Text = "Linha até o alvo", Default = true })
FovBox:AddLabel("Cor da linha"):AddColorPicker("AimLineColor", {
    Default = Color3.fromRGB(255, 0, 0), Title = "Cor da linha",
})
FovBox:AddSlider("AimLineThickness", {
    Text = "Espessura da linha", Default = 1, Min = 1, Max = 5, Rounding = 0,
})

local BlackBox = Tabs.Aimbot:AddRightGroupbox("Skill Blacklist")
BlackBox:AddLabel("Marque o que NÃO deve usar o aimbot", true)
BlackBox:AddToggle("BL_M1", { Text = "Ignorar M1", Default = false })
BlackBox:AddToggle("BL_Z", { Text = "Ignorar Z", Default = false })
BlackBox:AddToggle("BL_X", { Text = "Ignorar X", Default = false })
BlackBox:AddToggle("BL_C", { Text = "Ignorar C", Default = false })
BlackBox:AddToggle("BL_V", { Text = "Ignorar V", Default = false })
BlackBox:AddToggle("BL_F", { Text = "Ignorar F", Default = false })

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
if not FOVCircle then
    Library:Notify("Seu executor não tem Drawing; o círculo do FOV não vai aparecer.", 6)
end

local AimLine
if Drawing then
    pcall(function()
        AimLine = Drawing.new("Line")
        AimLine.Visible = false
        AimLine.Transparency = 1
        AimLine.Thickness = 1
        AimLine.Color = Color3.fromRGB(255, 0, 0)
    end)
end

-- Blacklist
local BL = {
    { "BL_Z", Enum.KeyCode.Z }, { "BL_X", Enum.KeyCode.X }, { "BL_C", Enum.KeyCode.C },
    { "BL_V", Enum.KeyCode.V }, { "BL_F", Enum.KeyCode.F },
}
local blockedUntil = 0

local function skillBlocked()
    if tick() < blockedUntil then return true end
    for _, e in ipairs(BL) do
        if T(e[1]) and UserInputService:IsKeyDown(e[2]) then return true end
    end
    if T("BL_M1") and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        return true
    end
    return false
end

bind(UserInputService.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for _, e in ipairs(BL) do
            if T(e[1]) and input.KeyCode == e[2] then blockedUntil = tick() + 0.7 end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and T("BL_M1") then
        blockedUntil = tick() + 0.4
    end
end, "Blacklist")

local faceUntil = 0
local FACE_KEYS = { Z = true, X = true, C = true, V = true, F = true }
bind(UserInputService.InputBegan, function(input)
    if not T("AimFaceSkill") or UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and FACE_KEYS[input.KeyCode.Name] then
        if not T("BL_" .. input.KeyCode.Name) then
            faceUntil = tick() + 0.5
        end
    end
end, "FaceSkill")

local lockedModel

local function evalModel(model, partName, cam, mousePos, myRoot, maxDist)
    if not model or not model.Parent then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local part = model:FindFirstChild(partName) or model:FindFirstChild("HumanoidRootPart")
    if not hum or not part or hum.Health <= 0 then return nil end
    local worldDist = myRoot and (myRoot.Position - part.Position).Magnitude or 0
    if worldDist > maxDist then return nil end
    local sp, onScreen = cam:WorldToViewportPoint(part.Position)
    if not onScreen then return nil end
    local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
    return { model = model, part = part, hum = hum, d = d, dist = worldDist }
end

local function findTarget()
    local cam = Cam()
    if not cam then return nil end
    local mousePos = UserInputService:GetMouseLocation()
    local radius = O("AimFOV") or 150
    local maxDist = O("AimMaxDist") or 500
    local partName = O("AimPart") or "HumanoidRootPart"
    local prio = O("AimPriority") or "Menor vida"
    local myRoot = getRoot()

    -- continua no mesmo alvo enquanto ele estiver valido (evita falhar na troca de alvo)
    if T("AimSticky") and lockedModel then
        local r = evalModel(lockedModel, partName, cam, mousePos, myRoot, maxDist)
        if r and r.d <= radius * 1.6 then return r end
        lockedModel = nil
    end

    local best, bestScore
    for _, model in ipairs(getModels(T("TargetPlayers"), T("TargetNPCs"))) do
        local r = evalModel(model, partName, cam, mousePos, myRoot, maxDist)
        if r and r.d <= radius then
            local score
            if prio == "Menor vida" then
                score = r.hum.Health + r.d / 100000
            elseif prio == "Mais perto do cursor" then
                score = r.d
            else
                score = r.dist
            end
            if not bestScore or score < bestScore then
                bestScore = score
                best = r
            end
        end
    end
    if best then lockedModel = best.model end
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

local lastStatus = ""
local function setStatus(text)
    if text ~= lastStatus then
        lastStatus = text
        AimStatus:SetText(text)
    end
end

pcall(function() RunService:UnbindFromRenderStep("BiosAimbot") end)
RunService:BindToRenderStep("BiosAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    local ok, err = pcall(function()
        local on = T("Aimbot")
        if AimLine then AimLine.Visible = false end
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
            lockedModel = nil
            setStatus("Alvo: aimbot desligado")
            return
        end

        local t = findTarget()
        if not t then
            AimState.active = false
            setStatus("Alvo: nenhum no FOV")
            return
        end
        local pred = O("AimPrediction") or 0
        local vel = t.part.AssemblyLinearVelocity
        AimState.pos = t.part.Position + vel * pred
        AimState.part = t.part
        AimState.toolOk = toolAllowsAim()
        AimState.active = true
        local cam2 = Cam()
        local sp2 = cam2:WorldToViewportPoint(AimState.pos)
        AimState.cam = cam2
        AimState.camPos = cam2.CFrame.Position
        AimState.sp = Vector2.new(sp2.X, sp2.Y)
        AimState.inset = GuiService:GetGuiInset()
        local dirv = AimState.pos - AimState.camPos
        if dirv.Magnitude > 0.01 then
            AimState.hitCF = CFrame.lookAt(AimState.pos, AimState.pos + dirv.Unit)
        else
            AimState.hitCF = CFrame.new(AimState.pos)
        end
        local rr = getRoot()
        AimState.rootPos = rr and rr.Position or AimState.camPos

        if tick() < faceUntil and AimState.toolOk and not T("Fly") then
            local r = getRoot()
            if r then
                local flat = Vector3.new(AimState.pos.X, r.Position.Y, AimState.pos.Z)
                if (flat - r.Position).Magnitude > 0.5 then
                    r.CFrame = CFrame.lookAt(r.Position, flat)
                end
            end
        end
        setStatus(string.format("Alvo: %s (%d HP)", t.model.Name, math.floor(t.hum.Health)))

        if AimLine and T("AimLine") then
            local lineCam = Cam()
            local sp, onScreen = lineCam:WorldToViewportPoint(t.part.Position)
            if onScreen then
                AimLine.From = UserInputService:GetMouseLocation()
                AimLine.To = Vector2.new(sp.X, sp.Y)
                AimLine.Color = O("AimLineColor") or Color3.fromRGB(255, 0, 0)
                AimLine.Thickness = O("AimLineThickness") or 1
                AimLine.Visible = true
            end
        end

        if T("CameraLock") and AimState.toolOk and not skillBlocked() then
            local cam = Cam()
            local alpha = math.clamp(1 - (O("CameraSmooth") or 0.5), 0.02, 1)
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, AimState.pos), alpha)
        end
    end)
    if not ok then report("Aimbot", err) end
end)

-- Hooks: Mouse.Hit/Target e argumentos Vector3 dos remotes de skill/arma
local spyLog = {}
local spyNames = {
    ["RE/RegisterAttack"] = true, ["RE/RegisterHit"] = true,
    ["RE/ShootGunEvent"] = true, ["RemoteEvent"] = true,
}
local aimRemoteNames = { ["RemoteEvent"] = true, ["RE/ShootGunEvent"] = true }

local oldIndex, oldNamecall
--------------------------------------------------------------------
-- COMBAT
--------------------------------------------------------------------
local FastBox = Tabs.Combat:AddLeftGroupbox("Fast Attack")
FastBox:AddToggle("FastAttack", { Text = "Fast Attack", Default = false })
FastBox:AddDropdown("FastMethod", {
    Values = { "Remotes (M1 invisível)", "Cliques" }, Default = 1, Multi = false,
    Text = "Método",
})
FastBox:AddSlider("FastAttackDelay", {
    Text = "Delay (segundos)", Default = 0.1, Min = 0.01, Max = 1, Rounding = 2,
})
FastBox:AddSlider("FastAttackRange", {
    Text = "Alcance", Default = 60, Min = 10, Max = 200, Rounding = 0,
})
FastBox:AddToggle("FastNPCs", { Text = "Atacar NPCs", Default = true })
FastBox:AddToggle("FastPlayers", { Text = "Atacar players", Default = false })
local FastStatus = FastBox:AddLabel("Status: desligado")

local function getNet()
    local m = ReplicatedStorage:FindFirstChild("Modules")
    return m and m:FindFirstChild("Net")
end

-- um ataque pelos remotes do jogo contra todos os alvos no alcance
local function remoteAttackOnce(tool, root, range, wantPlayers, wantNPCs)
    local targets, parts, main = {}, {}, nil
    for _, m in ipairs(getModels(wantPlayers, wantNPCs)) do
        local hum = m:FindFirstChildOfClass("Humanoid")
        local part = m:FindFirstChild("HumanoidRootPart")
        if hum and part and hum.Health > 0 and (part.Position - root.Position).Magnitude <= range then
            table.insert(targets, { m, part })
            table.insert(parts, part)
            main = main or part
        end
    end
    if not main then return "sem alvo no alcance" end

    local net = getNet()
    local RA = net and net:FindFirstChild("RE/RegisterAttack")
    local RH = net and net:FindFirstChild("RE/RegisterHit")
    local SG = net and net:FindFirstChild("RE/ShootGunEvent")
    if tool.ToolTip == "Gun" then
        if SG then
            SG:FireServer(main.Position, parts)
            return "atacando (arma) x" .. #targets
        end
        return "remote de arma não encontrado"
    end
    if RA and RH then
        RA:FireServer(0)
        RH:FireServer(main, targets)
        return "atacando x" .. #targets
    end
    return "remotes de ataque não encontrados"
end

loop("FastAttack", function() return math.max(O("FastAttackDelay") or 0.1, 0.01) end, function()
    if not T("FastAttack") then
        if FastStatus.Text ~= "Status: desligado" then FastStatus:SetText("Status: desligado") end
        return
    end
    local c, root = getChar(), getRoot()
    local tool = c and c:FindFirstChildOfClass("Tool")
    if not tool or not root then
        FastStatus:SetText("Status: equipe uma arma/estilo")
        return
    end

    if O("FastMethod") == "Cliques" then
        pcall(function() tool:Activate() end)
        local cam = Cam()
        VirtualUser:Button1Down(Vector2.new(0, 0), cam and cam.CFrame)
        VirtualUser:Button1Up(Vector2.new(0, 0), cam and cam.CFrame)
        FastStatus:SetText("Status: clicando")
        return
    end

    FastStatus:SetText("Status: " .. remoteAttackOnce(tool, root, O("FastAttackRange") or 60, T("FastPlayers"), T("FastNPCs")))
end)

FastBox:AddToggle("RemoteSpy", { Text = "Remote Spy (debug)", Default = false })
FastBox:AddButton("Copiar log do Remote Spy", function()
    local function ser(v, depth)
        depth = depth or 0
        local t = typeof(v)
        if t == "string" then return '"' .. v .. '"'
        elseif t == "Instance" then
            local ok, n = pcall(function() return v:GetFullName() end)
            return "Instance(" .. tostring(ok and n or v.Name) .. ")"
        elseif t == "table" then
            if depth >= 3 then return "{...}" end
            local out, n = {}, 0
            for k, x in pairs(v) do
                n = n + 1
                if n > 12 then break end
                table.insert(out, "[" .. tostring(k) .. "]=" .. ser(x, depth + 1))
            end
            return "{" .. table.concat(out, ", ") .. "}"
        end
        return t .. "(" .. tostring(v) .. ")"
    end
    local lines = {}
    for _, e in ipairs(spyLog) do
        local a = {}
        for i = 1, e.args.n do table.insert(a, ser(e.args[i])) end
        local line = e.name .. ":" .. e.method .. "(" .. table.concat(a, ", ") .. ")"
        if e.aim ~= nil then line = line .. "  [aimbot " .. (e.aim and "ativo" or "inativo") .. "]" end
        if e.mod then
            local b = {}
            for i = 1, e.mod.n do table.insert(b, ser(e.mod[i])) end
            line = line .. "  ==> (" .. table.concat(b, ", ") .. ")"
        end
        table.insert(lines, line)
    end
    if #lines == 0 then
        Library:Notify("Log vazio. Ligue o spy e ataque normalmente (M1) antes.", 5)
    elseif setclipboard then
        setclipboard(table.concat(lines, "\n"))
        Library:Notify("Log copiado (" .. #lines .. " linhas).", 4)
    else
        Library:Notify("Seu executor não tem setclipboard.", 4)
    end
end)

local DragonBox = Tabs.Combat:AddLeftGroupbox("Dragonstorm M1")
DragonBox:AddToggle("DragonM1", { Text = "Dragonstorm Fast M1", Default = false })
DragonBox:AddSlider("DragonDelay", {
    Text = "Delay (segundos)", Default = 0.1, Min = 0.02, Max = 1, Rounding = 2,
})
DragonBox:AddSlider("DragonRange", {
    Text = "Alcance", Default = 150, Min = 20, Max = 500, Rounding = 0,
})
DragonBox:AddToggle("DragonAnyGun", { Text = "Usar em qualquer arma", Default = false })
local DragonStatus = DragonBox:AddLabel("Status: desligado")

local function isDragonTool(tool)
    local n = tool.Name:lower():gsub("%s", "")
    return n:find("dragonstorm") ~= nil
end

loop("DragonM1", function() return math.max(O("DragonDelay") or 0.1, 0.02) end, function()
    if not T("DragonM1") then
        DragonStatus:SetText("Status: desligado")
        return
    end
    local c, root = getChar(), getRoot()
    local tool = c and c:FindFirstChildOfClass("Tool")
    if not tool or not root then
        DragonStatus:SetText("Status: equipe o Dragonstorm")
        return
    end
    if not (isDragonTool(tool) or (T("DragonAnyGun") and tool.ToolTip == "Gun")) then
        DragonStatus:SetText("Status: equipe o Dragonstorm")
        return
    end

    -- alvo: o do aimbot, senao o mais perto no alcance
    local targetPart
    if AimState.active and AimState.part and AimState.part.Parent then
        targetPart = AimState.part
    else
        local range, bestD = O("DragonRange") or 150, nil
        for _, m in ipairs(getModels(T("FastPlayers"), T("FastNPCs"))) do
            local hum = m:FindFirstChildOfClass("Humanoid")
            local part = m:FindFirstChild("HumanoidRootPart")
            if hum and part and hum.Health > 0 then
                local d = (part.Position - root.Position).Magnitude
                if d <= range and (not bestD or d < bestD) then
                    bestD, targetPart = d, part
                end
            end
        end
    end
    if not targetPart then
        DragonStatus:SetText("Status: sem alvo no alcance")
        return
    end

    local net = getNet()
    local SG = net and net:FindFirstChild("RE/ShootGunEvent")
    if SG then
        SG:FireServer(targetPart.Position, { targetPart })
    end
    pcall(function() tool:Activate() end)
    DragonStatus:SetText("Status: atirando em " .. tostring(targetPart.Parent and targetPart.Parent.Name))
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
local HitStatus = HitBox:AddLabel("Alvos: 0")
HitBox:AddDropdown("HitboxParts", {
    Values = { "Só HumanoidRootPart", "HRP + Cabeça + Torso" }, Default = 1, Multi = false,
    Text = "Partes aumentadas",
})
HitBox:AddSlider("HitboxRange", {
    Text = "Aplicar até (studs)", Default = 300, Min = 30, Max = 1000, Rounding = 0,
})
HitBox:AddToggle("HitboxAssist", { Text = "Hit assist (M1 com alcance estendido)", Default = false })
HitBox:AddLabel("Hit assist usa os mesmos remotes do Fast Attack: ao dar M1, registra o golpe nos alvos dentro do tamanho da hitbox.", true)

local hitboxOriginal = {}
local hitboxAdorn = {}
local hitboxList = {}

local function restoreHitbox(part)
    local d = hitboxOriginal[part]
    if d and part and part.Parent then
        part.Size = d.Size
        part.CanCollide = d.CanCollide
        part.Massless = d.Massless
        part.CanTouch = d.CanTouch
        part.CanQuery = d.CanQuery
    end
    hitboxOriginal[part] = nil
end
local function removeAdorn(part)
    local a = hitboxAdorn[part]
    if a then a:Destroy() end
    hitboxAdorn[part] = nil
end

-- lista de partes alvo (atualiza 5x por segundo)
loop("HitboxScan", 0.2, function()
    local list, count = {}, 0
    local root = getRoot()
    local maxD = O("HitboxRange") or 300
    local names = { "HumanoidRootPart" }
    if O("HitboxParts") == "HRP + Cabeça + Torso" then
        names = { "HumanoidRootPart", "Head", "UpperTorso", "Torso" }
    end
    for _, model in ipairs(getModels(T("HitboxPlayers"), T("HitboxNPCs"))) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 and (not root or (hrp.Position - root.Position).Magnitude <= maxD) then
            count = count + 1
            for _, n in ipairs(names) do
                local part = model:FindFirstChild(n)
                if part and part:IsA("BasePart") then list[#list + 1] = part end
            end
        end
    end
    hitboxList = list
    HitStatus:SetText("Alvos com hitbox: " .. count)
end)

-- aplica a cada frame (o jogo nao consegue voltar o tamanho)
bind(RunService.Heartbeat, function()
    local on, show = T("Hitbox"), T("HitboxVisual")
    local s = O("HitboxSize") or 15
    local inList = {}
    for _, part in ipairs(hitboxList) do
        if part.Parent then
            inList[part] = true
            if on then
                if not hitboxOriginal[part] then
                    hitboxOriginal[part] = {
                        Size = part.Size, CanCollide = part.CanCollide, Massless = part.Massless,
                        CanTouch = part.CanTouch, CanQuery = part.CanQuery,
                    }
                end
                local size = (part.Name == "HumanoidRootPart") and s or math.max(s * 0.7, 2)
                part.Size = Vector3.new(size, size, size)
                part.CanCollide = false
                part.Massless = true
                part.CanTouch = true
                part.CanQuery = true
            end
            if show and part.Name == "HumanoidRootPart" then
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
        if not (on and inList[part]) then restoreHitbox(part) end
    end
    for part in pairs(hitboxAdorn) do
        if not (show and inList[part]) then removeAdorn(part) end
    end
end, "Hitbox")

-- Hit assist: ao dar M1, registra o golpe nos alvos dentro da hitbox
bind(UserInputService.InputBegan, function(input)
    if not T("HitboxAssist") or UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    local c, root = getChar(), getRoot()
    local tool = c and c:FindFirstChildOfClass("Tool")
    if not tool or not root then return end
    remoteAttackOnce(tool, root, (O("HitboxSize") or 15) + 10, T("HitboxPlayers"), T("HitboxNPCs"))
end, "HitboxAssist")

--------------------------------------------------------------------
-- AURA
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
end, "Aura")

--------------------------------------------------------------------
-- ESP
--------------------------------------------------------------------
local EspBox = Tabs.ESP:AddLeftGroupbox("ESP")
EspBox:AddToggle("PlayerESP", { Text = "Player ESP", Default = false })
EspBox:AddToggle("FruitESP", { Text = "Fruit ESP", Default = false })
EspBox:AddToggle("NameESP", { Text = "Nomes + distância", Default = true })
EspBox:AddToggle("BountyESP", { Text = "Mostrar bounty", Default = true })
EspBox:AddToggle("PvpESP", { Text = "Mostrar status de PvP", Default = true })
EspBox:AddLabel("Cor Players"):AddColorPicker("PlayerESPColor", {
    Default = Color3.fromRGB(255, 60, 60), Title = "Cor Players",
})
EspBox:AddLabel("Cor Frutas"):AddColorPicker("FruitESPColor", {
    Default = Color3.fromRGB(255, 170, 0), Title = "Cor Frutas",
})

local function fmtNum(n)
    n = tonumber(n) or 0
    if n >= 1e9 then return string.format("%.1fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3) end
    return tostring(math.floor(n))
end

local function getBounty(p)
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local n = v.Name:lower()
            if v:IsA("ValueBase") and (n:find("bounty") or n:find("honor")) then
                return v.Value
            end
        end
    end
    return nil
end

local function scanPvp(inst)
    if not inst then return nil end
    for name, val in pairs(inst:GetAttributes()) do
        if tostring(name):lower():find("pvp") then return val, tostring(name) end
    end
    for _, c in ipairs(inst:GetChildren()) do
        if c:IsA("ValueBase") and c.Name:lower():find("pvp") then return c.Value, c.Name end
    end
    return nil
end

local function getPvp(p)
    local val, name = scanPvp(p)
    if val == nil then val, name = scanPvp(p.Character) end
    if val ~= nil then
        if type(val) == "boolean" then
            local disabled = name and name:lower():find("disabled")
            local on = val
            if disabled then on = not val end
            return on and "ON" or "OFF"
        end
        return tostring(val)
    end
    if p.Character and p.Character:FindFirstChildOfClass("ForceField") then
        return "OFF (safe zone)"
    end
    return "?"
end

local espCache = {}
local function clearESPEntry(obj)
    local e = espCache[obj]
    if e then
        if e.hl then pcall(function() e.hl:Destroy() end) end
        if e.bb then pcall(function() e.bb:Destroy() end) end
        espCache[obj] = nil
    end
end

local function espPart(adornee)
    if adornee:IsA("Model") then
        return adornee:FindFirstChild("Head") or adornee:FindFirstChild("HumanoidRootPart") or adornee.PrimaryPart
    end
    return adornee:FindFirstChildWhichIsA("BasePart", true)
end

local function makeESP(obj, adornee, label, colorOption, extra)
    local part = espPart(adornee)
    if not part then
        clearESPEntry(obj)
        return
    end
    local e = espCache[obj]
    -- se o personagem morreu/renasceu, os objetos antigos sumiram: recria
    if e and (e.adornee ~= adornee or e.part ~= part or not e.hl.Parent or not e.bb.Parent) then
        clearESPEntry(obj)
        e = nil
    end
    if not e then
        e = { adornee = adornee, part = part }
        e.hl = Instance.new("Highlight")
        e.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        e.hl.Adornee = adornee
        e.hl.Parent = adornee
        e.bb = Instance.new("BillboardGui")
        e.bb.Size = UDim2.new(0, 220, 0, 48)
        e.bb.AlwaysOnTop = true
        e.bb.StudsOffset = Vector3.new(0, 3, 0)
        e.bb.Adornee = part
        e.bb.Parent = part
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
    local dist = root and math.floor((root.Position - part.Position).Magnitude) or 0
    local text = string.format("%s [%dm]", label, dist)
    if extra and extra ~= "" then text = text .. "\n" .. extra end
    e.txt.Text = text
end

loop("ESP", 0.5, function()
    local seen = {}
    if T("PlayerESP") then
        for _, p in ipairs(Players:GetPlayers()) do
            local ch = p.Character
            if p ~= LocalPlayer and ch and ch.Parent then
                seen[p] = true
                -- cada jogador em pcall: um erro em um nao derruba o ESP dos outros
                local ok, err = pcall(function()
                    local parts = {}
                    if T("BountyESP") then
                        local b = getBounty(p)
                        table.insert(parts, "Bounty: " .. (b and fmtNum(b) or "?"))
                    end
                    if T("PvpESP") then
                        table.insert(parts, "PvP: " .. getPvp(p))
                    end
                    makeESP(p, ch, p.Name, "PlayerESPColor", table.concat(parts, " | "))
                end)
                if not ok then
                    clearESPEntry(p)
                    report("ESP", err)
                end
            end
        end
    end
    if T("FruitESP") then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Tool") and obj.Name:find("Fruit") then
                seen[obj] = true
                local ok, err = pcall(makeESP, obj, obj, obj.Name, "FruitESPColor")
                if not ok then
                    clearESPEntry(obj)
                    report("FruitESP", err)
                end
            end
        end
    end
    for obj in pairs(espCache) do
        if not seen[obj] then clearESPEntry(obj) end
    end
end)

local DbgBox = Tabs.ESP:AddRightGroupbox("Debug do ESP")
DbgBox:AddLabel("Se o status de PvP aparecer como '?', escolha um jogador e copie o dump para me mandar.", true)
DbgBox:AddDropdown("DumpPlayer", { SpecialType = "Player", Text = "Jogador" })
DbgBox:AddButton("Copiar dump do jogador", function()
    local p = Players:FindFirstChild(O("DumpPlayer") or "")
    if not p then
        Library:Notify("Escolha um jogador.", 3)
        return
    end
    local out = {}
    local function dump(label, inst)
        if not inst then return end
        table.insert(out, "== " .. label .. " ==")
        for k, v in pairs(inst:GetAttributes()) do
            table.insert(out, "attr " .. tostring(k) .. " = " .. tostring(v))
        end
        local n = 0
        for _, c in ipairs(inst:GetChildren()) do
            n = n + 1
            if n > 60 then break end
            local val = ""
            if c:IsA("ValueBase") then val = " = " .. tostring(c.Value) end
            table.insert(out, c.ClassName .. " " .. c.Name .. val)
        end
    end
    dump("Player", p)
    dump("leaderstats", p:FindFirstChild("leaderstats"))
    dump("Character", p.Character)
    if setclipboard then
        setclipboard(table.concat(out, "\n"))
        Library:Notify("Dump copiado.", 4)
    else
        Library:Notify("Seu executor não tem setclipboard.", 4)
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
end, "CamFOV")

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
end, "AntiAFK")

MiscBox:AddToggle("FullBright", { Text = "Full Bright", Default = false })
bind(RunService.RenderStepped, function()
    if T("FullBright") then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
    end
end, "FullBright")

MiscBox:AddButton("Boost de FPS (manual)", function()
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

-- Automáticos
local AutoBox = Tabs.Misc:AddLeftGroupbox("Automático")
AutoBox:AddToggle("AutoFastMode", { Text = "Auto Fast Mode (menos efeitos)", Default = true })
AutoBox:AddToggle("NoMusic", { Text = "Auto No Background Music", Default = true })
AutoBox:AddToggle("NoCameraShake", { Text = "Auto No Camera Shake", Default = true })

-- Fast Mode: desliga partículas/efeitos pesados
local function fastDisable(obj)
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
        or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        obj.Enabled = false
    end
end
local function applyFastMode()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    Lighting.GlobalShadows = false
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
            or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        fastDisable(v)
        n = n + 1
        if n % 2000 == 0 then task.wait() end
    end
end
bind(workspace.DescendantAdded, function(obj)
    if T("AutoFastMode") then fastDisable(obj) end
end, "FastModeAdd")
Toggles.AutoFastMode:OnChanged(function()
    if Toggles.AutoFastMode.Value then task.spawn(applyFastMode) end
end)
if T("AutoFastMode") then task.spawn(applyFastMode) end

-- Sem música
local mutedSounds = {}
local function isMusic(s)
    return s:IsA("Sound")
        and (s.Looped or s.Name:lower():find("music"))
        and not s:FindFirstAncestorWhichIsA("BasePart")
end
local function sweepSounds(list)
    for _, s in ipairs(list) do
        if isMusic(s) then
            if mutedSounds[s] == nil then mutedSounds[s] = s.Volume end
            s.Volume = 0
        end
    end
end
loop("NoMusic", 1, function()
    if T("NoMusic") then
        sweepSounds(SoundService:GetDescendants())
        sweepSounds(workspace:GetChildren())
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then sweepSounds(pg:GetDescendants()) end
    elseif next(mutedSounds) ~= nil then
        for s, vol in pairs(mutedSounds) do
            if s and s.Parent then s.Volume = vol end
        end
        mutedSounds = {}
    end
end)

-- Sem tremor de câmera
bind(RunService.RenderStepped, function()
    if T("NoCameraShake") then
        local hum = getHum()
        if hum and hum.CameraOffset ~= Vector3.zero then
            hum.CameraOffset = Vector3.zero
        end
    end
end, "NoCameraShake")

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
-- SHOP
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
    hidePlat()
    restoreLava()
    restoreWater()
    pcall(function() RunService:UnbindFromRenderStep("BiosAimbot") end)
    AimState.active = false
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    if AimLine then pcall(function() AimLine:Remove() end) end
    for part in pairs(hitboxOriginal) do restoreHitbox(part) end
    for part in pairs(hitboxAdorn) do removeAdorn(part) end
    for obj in pairs(espCache) do clearESPEntry(obj) end
    if auraHL then auraHL:Destroy() end
    for s, vol in pairs(mutedSounds) do
        if s and s.Parent then s.Volume = vol end
    end
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

-- Hooks do aimbot (por ultimo, para nunca atrapalhar a criacao do menu)
local okHooks, errHooks = pcall(function()
local function retarget(v)
    local ty = typeof(v)
    local rp = AimState.rootPos
    if ty == "Vector3" then
        local m = v.Magnitude
        if m <= 5 then
            -- parece uma direcao: aponta para o alvo mantendo o tamanho
            if m < 0.001 then return nil end
            local d = AimState.pos - rp
            if d.Magnitude < 0.01 then return nil end
            return d.Unit * m
        end
        if (v - rp).Magnitude < 8 then return nil end -- parece a origem, nao o destino
        return AimState.pos
    elseif ty == "CFrame" then
        if (v.Position - rp).Magnitude < 8 then return nil end
        return AimState.hitCF
    end
    return nil
end

local hooksOk = false
if hookmetamethod and newcclosure and checkcaller and getnamecallmethod then
    hooksOk = pcall(function()
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if AimState.active and AimState.toolOk and self == Mouse and not checkcaller() and T("AimHookMouse") then
                if key == "Hit" or key == "Target" or key == "UnitRay" or key == "X" or key == "Y" then
                    if not skillBlocked() then
                        if key == "Hit" then
                            return AimState.hitCF
                        elseif key == "Target" then
                            return AimState.part
                        elseif key == "UnitRay" then
                            return Ray.new(AimState.camPos, (AimState.pos - AimState.camPos).Unit)
                        elseif key == "X" then
                            return AimState.sp.X
                        else
                            return AimState.sp.Y - AimState.inset.Y
                        end
                    end
                end
            end
            return oldIndex(self, key)
        end))

        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() then
                if method == "FireServer" or method == "InvokeServer" then
                    local name = self.Name
                    local par = self.Parent
                    local isTool = par ~= nil and par.ClassName == "Tool"
                    local entry
                    if T("RemoteSpy") and (spyNames[name] or isTool) then
                        entry = { name = name, method = method, args = table.pack(...), aim = AimState.active }
                        spyLog[#spyLog + 1] = entry
                        if #spyLog > 40 then table.remove(spyLog, 1) end
                    end
                    if AimState.active and AimState.toolOk and T("AimRemotes")
                        and (isTool or aimRemoteNames[name]) and not skillBlocked() then
                        local args = table.pack(...)
                        for i = 1, args.n do
                            local nv = retarget(args[i])
                            if nv ~= nil then
                                args[i] = nv
                                break
                            end
                        end
                        if entry then entry.mod = args end
                        if setnamecallmethod then setnamecallmethod(method) end
                        return oldNamecall(self, table.unpack(args, 1, args.n))
                    end
                elseif AimState.active and AimState.toolOk and AimState.sp and T("AimHookRays") then
                    if (method == "ViewportPointToRay" or method == "ScreenPointToRay") and self == AimState.cam then
                        if not skillBlocked() then
                            return Ray.new(AimState.camPos, (AimState.pos - AimState.camPos).Unit)
                        end
                    elseif method == "GetMouseLocation" and self == UserInputService then
                        if not skillBlocked() then
                            return AimState.sp
                        end
                    end
                end
            end
            if setnamecallmethod then setnamecallmethod(method) end
            return oldNamecall(self, ...)
        end))
    end)
end
if not hooksOk then
    Library:Notify("Seu executor não suporta hooks; o aimbot só funciona pelo Camera Lock.", 8)
end


end)
if not okHooks then report("Hooks", errHooks) end

Library:Notify("Bios Hub carregado!", 5)
