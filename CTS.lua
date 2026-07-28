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
    TeamCheck = false,
    ShowDistance = false,
    EnableFill = true,
    EnableOutline = true,
    Instances = {},
    HullColor = Color3.new(0.8, 0.2, 0.9),
    TurretColor = Color3.new(0.2, 0.9, 0.4),
    FillTransparency = 0.5,
    OutlineTransparency = 0.2
}

local Mark = {
    Enabled = false,
    Distance = 1000,
    DecalID = "11552476728",
    OffsetY = 50,
    Size = 25
}

local Fly = {
    Active = false,
    Speed = 70,
    Root = nil
}

local Other = {
    RemoveFog = false,
    PenView = false
}

local PenView = {
    UI = nil,
    HeartbeatConnection = nil,
    LastPart = nil,
    LastChassisName = nil,
    ArmorTypes = {
        "Structural Steel", "RHA", "HHRA", "CHA", "NERA", "Internal RHA", "Internal HHRA",
        "Internal CHA", "Composite Screen", "Rubber-fabric Screen", "Internal Aluminium",
        "Aluminium", "Aluminium Alloy", "Internal Aluminium Alloy", "Internal Structural Steel",
        "ERA", "Wood", "Armour"
    }
}

-- Safe Get Penetration
local function PenView_GetPenetration()
    local success, result = pcall(function()
        local vehicles = Services.Workspace:FindFirstChild("Vehicles")
        if not vehicles then return 200 end
        
        local chassis = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
        if not chassis then return 200 end
        
        local gunFolder = chassis:FindFirstChild("Gun")
        if not gunFolder then return 200 end
        
        for _, gunWeapon in ipairs(gunFolder:GetChildren()) do
            local config = gunWeapon:FindFirstChild("Config")
            if config then
                local shells = config:FindFirstChild("Shells")
                if shells then
                    for _, folder in ipairs(shells:GetChildren()) do
                        local penVal = folder:FindFirstChild("Penetration")
                        if penVal then return penVal.Value end
                    end
                end
            end
        end
        return 200
    end)
    return success and result or 200
end

local function PenView_FindGunBrick(chassis)
    if not chassis then return nil end
    local gun = chassis:FindFirstChild("Gun", true)
    if not gun then return nil end
    for _, obj in ipairs(gun:GetDescendants()) do
        if obj.Name == "GunBrick" then return obj end
    end
    return nil
end

local function PenView_CreateUI()
    pcall(function()
        for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if v.Name == "PenViewport" then v:Destroy() end
        end
    end)
    
    local sg = Instance.new("ScreenGui")
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = -100
    sg.Name = "PenViewport"
    sg.Parent = LocalPlayer.PlayerGui
    
    local vp = Instance.new("ViewportFrame", sg)
    vp.Size = UDim2.new(1, 0, 1, 0)
    vp.BackgroundTransparency = 1
    vp.ImageTransparency = 0.25
    vp.ZIndex = -100
    
    local cam = Instance.new("Camera")
    vp.CurrentCamera = cam
    cam.CameraType = Enum.CameraType.Scriptable
    
    return {viewport = vp, vpcam = cam}
end

local function PenView_StartHeartbeat(ui)
    if PenView.HeartbeatConnection then PenView.HeartbeatConnection:Disconnect() end
    PenView.LastPart = nil
    
    PenView.HeartbeatConnection = Services.RunService.Heartbeat:Connect(function()
        pcall(function()
            if not ui or not ui.viewport or not ui.viewport.Parent then return end
            
            local vehicles = Services.Workspace:FindFirstChild("Vehicles")
            if not vehicles then return end
            
            local chassis = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
            if not chassis then return end
            
            local gunBrick = PenView_FindGunBrick(chassis)
            if not gunBrick then return end
            
            local pen = PenView_GetPenetration()
            local origin = gunBrick.Position + gunBrick.CFrame.LookVector * 2
            local dir = gunBrick.CFrame.LookVector
            
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {chassis, Services.Workspace:FindFirstChild("Projectiles")}
            rayParams.IgnoreWater = true
            
            local result = Services.Workspace:Raycast(origin, dir * 3000, rayParams)
            if result and result.Instance and table.find(PenView.ArmorTypes, result.Instance.Name) then
                -- Render Viewport Logic
            end
        end)
    end)
end

local function PenView_Start()
    PenView.UI = PenView_CreateUI()
    PenView_StartHeartbeat(PenView.UI)
end

local function PenView_Stop()
    if PenView.HeartbeatConnection then
        PenView.HeartbeatConnection:Disconnect()
        PenView.HeartbeatConnection = nil
    end
    pcall(function()
        local vp = LocalPlayer.PlayerGui:FindFirstChild("PenViewport")
        if vp then vp:Destroy() end
    end)
end

-- Fly Helpers
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

-- Rayfield Window Setup
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
local FlyTab = Window:CreateTab("Fly", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

MainTab:CreateToggle({
    Name = "Enable ESP", CurrentValue = true, Flag = "ESPToggle",
    Callback = function(Value) ESP.Enabled = Value end,
})

VisualTab:CreateToggle({
    Name = "Enable Penetration View", CurrentValue = false, Flag = "PenViewFlag",
    Callback = function(Value)
        Other.PenView = Value
        if Value then PenView_Start() else PenView_Stop() end
    end,
})

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

SettingsTab:CreateButton({
    Name = "Unload UI",
    Callback = function()
        stopFly()
        PenView_Stop()
        Rayfield:Destroy()
    end,
})

-- RenderStepped for Fly
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
