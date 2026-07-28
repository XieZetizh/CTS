local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Services = {
    RunService = game:GetService("RunService"),
    UserInput = game:GetService("UserInputService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting")
}
local LocalPlayer = Services.Players.LocalPlayer

local ESP = {
    Enabled = true,
    HullColor = Color3.fromRGB(200, 50, 230),
    FillTransparency = 0.5,
    OutlineTransparency = 0,
    Highlights = {}
}

local Fly = {
    Active = false,
    Speed = 70,
    Root = nil
}

-- ===== ระบบ ESP ทำงานจริง =====
local function CleanESP()
    for model, highlight in pairs(ESP.Highlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    table.clear(ESP.Highlights)
end

local function ApplyESP(model)
    if not model or not model:IsA("Model") then return end
    if model.Name == "Chassis" .. LocalPlayer.Name then return end -- ข้ามรถของตัวเอง
    
    if not ESP.Highlights[model] then
        local hl = Instance.new("Highlight")
        hl.Name = "CTS_ESP_Highlight"
        hl.Adornee = model
        hl.FillColor = ESP.HullColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = ESP.FillTransparency
        hl.OutlineTransparency = ESP.OutlineTransparency
        hl.Enabled = ESP.Enabled
        hl.Parent = model
        
        ESP.Highlights[model] = hl
    else
        ESP.Highlights[model].Enabled = ESP.Enabled
    end
end

local function UpdateESP()
    if not ESP.Enabled then
        CleanESP()
        return
    end
    
    local vehicles = Services.Workspace:FindFirstChild("Vehicles")
    if vehicles then
        for _, child in ipairs(vehicles:GetChildren()) do
            if child:IsA("Model") and child.Name ~= "Chassis" .. LocalPlayer.Name then
                ApplyESP(child)
            end
        end
    end
end

-- ===== อ่านข้อมูลกระสุน =====
local function GetCurrentAmmoData()
    local ammoList = {}
    pcall(function()
        local vehicles = Services.Workspace:FindFirstChild("Vehicles")
        if not vehicles then return end
        
        local chassis = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
        if not chassis then return end
        
        local gunFolder = chassis:FindFirstChild("Gun")
        if not gunFolder then return end
        
        for _, gunWeapon in ipairs(gunFolder:GetChildren()) do
            local config = gunWeapon:FindFirstChild("Config")
            if config then
                local shells = config:FindFirstChild("Shells")
                if shells then
                    for _, folder in ipairs(shells:GetChildren()) do
                        local pen = folder:FindFirstChild("Penetration") and folder.Penetration.Value or 0
                        local vel = folder:FindFirstChild("MuzzleVelocity") and folder.MuzzleVelocity.Value or 0
                        table.insert(ammoList, {
                            Name = folder.Name,
                            Penetration = pen,
                            Velocity = vel
                        })
                    end
                end
            end
        end
    end)
    return ammoList
end

-- ===== ระบบ Fly =====
local bv = Instance.new("BodyVelocity")
bv.Name = "TankFlyVelocity"
bv.MaxForce = Vector3.new(500000, 500000, 500000)

local bg = Instance.new("BodyGyro")
bg.Name = "TankFlyGyro"
bg.MaxTorque = Vector3.new(500000, 500000, 500000)
bg.D = 120

local function startFly()
    pcall(function()
        local vehicles = workspace:FindFirstChild("Vehicles")
        if not vehicles then return end
        local tankModel = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
        if not tankModel then return end
        
        local hull = tankModel:FindFirstChild("Hull") or tankModel:FindFirstChildWhichIsA("BasePart")
        if hull then
            Fly.Root = hull
            bv.Parent = Fly.Root
            bg.Parent = Fly.Root
            Fly.Active = true
        end
    end)
end

local function stopFly()
    Fly.Active = false
    bv.Parent = nil
    bg.Parent = nil
end

-- ===== UI Rayfield =====
local Window = Rayfield:CreateWindow({
    Name = "C.T.S",
    LoadingTitle = "Cursed Tank Simulator",
    LoadingSubtitle = "by XieZetizH",
    ConfigurationSaving = { Enabled = false },
    Discord = false,
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local VisualTab = Window:CreateTab("Visual", 4483362458)
local WeaponTab = Window:CreateTab("Weapon", 4483362458)
local FlyTab = Window:CreateTab("Fly", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- 1. Main Tab
MainTab:CreateSection("ESP Settings")
MainTab:CreateToggle({
    Name = "Enable ESP", CurrentValue = true, Flag = "ESPToggle",
    Callback = function(Value) 
        ESP.Enabled = Value
        UpdateESP()
    end,
})

MainTab:CreateColorPicker({
    Name = "ESP Color",
    Color = ESP.HullColor,
    Flag = "ESPColor",
    Callback = function(Value)
        ESP.HullColor = Value
        for _, hl in pairs(ESP.Highlights) do
            if hl then hl.FillColor = Value end
        end
    end
})

-- 2. Visual Tab
VisualTab:CreateSection("Visual Effects")
VisualTab:CreateToggle({
    Name = "Remove Fog", CurrentValue = false, Flag = "RemoveFogFlag",
    Callback = function(Value)
        for _, child in ipairs(Services.Lighting:GetChildren()) do
            if child:IsA("Atmosphere") then
                child.Density = Value and 0 or 0.35
            end
        end
    end,
})

-- 3. Weapon Tab
WeaponTab:CreateSection("Shell Information")
WeaponTab:CreateButton({
    Name = "Check Ammo Penetration & Speed",
    Callback = function()
        local ammoData = GetCurrentAmmoData()
        if #ammoData == 0 then
            Rayfield:Notify({
                Title = "Weapon Info",
                Content = "You must be inside a Tank/Vehicle!",
                Duration = 4
            })
        else
            for _, ammo in ipairs(ammoData) do
                Rayfield:Notify({
                    Title = "Shell: " .. ammo.Name,
                    Content = "Penetration: " .. tostring(ammo.Penetration) .. " mm | Velocity: " .. tostring(ammo.Velocity) .. " m/s",
                    Duration = 6
                })
            end
        end
    end,
})

-- 4. Fly Tab
FlyTab:CreateSection("Vehicle Flight")
FlyTab:CreateToggle({
    Name = "Enable Vehicle Fly", CurrentValue = false, Flag = "VehicleFlyToggle",
    Callback = function(Value)
        if Value then startFly() else stopFly() end
    end,
})

FlyTab:CreateSlider({
    Name = "Fly Speed", Range = {10, 300}, Increment = 5,
    CurrentValue = 70, Flag = "FlySpeedFlag",
    Callback = function(Value) Fly.Speed = Value end,
})

-- 5. Settings Tab
SettingsTab:CreateSection("Credits")
SettingsTab:CreateLabel("Script Developer: XieZetizH")

SettingsTab:CreateSection("Unload")
SettingsTab:CreateButton({
    Name = "Destroy Script UI",
    Callback = function()
        stopFly()
        CleanESP()
        Rayfield:Destroy()
    end,
})

-- Loop ตรวจจับรถและอัปเดต ESP ตลอดเวลา
task.spawn(function()
    while task.wait(2) do
        UpdateESP()
    end
end)

-- Loop บิน (RenderStepped)
Services.RunService.RenderStepped:Connect(function()
    if Fly.Active and Fly.Root and Fly.Root.Parent then
        pcall(function()
            local cam = Services.Workspace.CurrentCamera
            local moveVec = Vector3.zero
            
            if Services.UserInput:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
            if Services.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec = moveVec - Vector3.new(0, 1, 0) end
            
            if moveVec.Magnitude > 0 then
                bv.Velocity = moveVec.Unit * Fly.Speed
            else
                bv.Velocity = Vector3.zero
            end
            bg.CFrame = cam.CFrame
        end)
    end
end)
