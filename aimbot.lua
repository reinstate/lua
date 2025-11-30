local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local Mouse = lp:GetMouse()

-- Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Prison Life Ultimate Aimbot",
    LoadingTitle = "Loading Unified ESP Aimbot...",
    LoadingSubtitle = "All-in-One ESP Box - Organized Layout - Hold E Activation",
    ConfigurationSaving = { Enabled = true, FolderName = "PLUnifiedESP" },
    KeySystem = false
})

-- Clean Tabs
local MainTab = Window:CreateTab("Aimbot")
local VisualTab = Window:CreateTab("Visuals")
local SettingsTab = Window:CreateTab("Settings")

-- Enhanced Config
local Config = {
    -- Aimbot
    AimbotEnabled = true,
    HoldKey = Enum.KeyCode.E,
    FOVRadius = 150,
    TargetPart = "Head",
    Smoothing = 0.08,
    AimbotSpeed = 1.0,
    Prediction = true,
    PredictionStrength = 1.15,
    BulletSpeed = 2200,
    AutoShoot = true,
    ShootDelay = 0.12,
    
    -- Advanced Tracking
    AdvancedTracking = true,
    MaxTrackingAngle = 120,
    
    -- Team Management
    TeamCheck = true,
    IgnoredTeams = {},
    
    -- Color System
    ColorMode = "Rainbow",
    StaticColor = Color3.fromRGB(148, 0, 211),
    RainbowSpeed = 5,
    
    -- ESP
    ESPEnabled = true,
    Tracers = true,
    UnifiedESPBox = true, -- NEW: Unified ESP Box toggle
    BoxTransparency = 0.7, -- NEW: Box transparency
    BoxSize = 120, -- NEW: Box width
    ShowHealthBar = true,
    ShowWeapon = true,
    ShowDistance = true,
    
    -- Aimbot FOV
    AimbotFOV = true
}

-- FOV Circle (centered to mouse)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Radius = Config.FOVRadius
FOVCircle.Filled = false
FOVCircle.Transparency = 0.9
FOVCircle.Color = Config.StaticColor
FOVCircle.Visible = true

-- ESP Storage for Unified Box System
local ESP = {
    MainBox = {}, -- Unified main box
    Tracers = {},
    NameText = {},
    HealthText = {},
    WeaponText = {},
    DistanceText = {},
    HealthBar = {},
    HealthBarBackground = {}
}

-- Global variables
local CurrentTarget = nil
local HoldingE = false
local LastShot = 0
local rainbowHue = 0
local AutoShooting = false

-- Notification system
local function ShowNotification(title, message)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = 2,
        Image = 4483362458
    })
end

-- Get all teams in game
local function GetTeams()
    local teams = {}
    for _, team in pairs(game:GetService("Teams"):GetTeams()) do
        table.insert(teams, team.Name)
    end
    return teams
end

-- Advanced prediction with bullet physics
local function CalculatePrediction(target, part)
    if not Config.Prediction or not target or not target.Character then
        return part.Position
    end
    
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position end
    
    local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
    local travelTime = distance / Config.BulletSpeed
    local velocity = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.new(0, 0, 0)
    
    local gravity = workspace.Gravity
    local drop = Vector3.new(0, 0.5 * gravity * travelTime * travelTime, 0)
    
    local predictedPosition = part.Position + (velocity * travelTime * Config.PredictionStrength) - drop
    
    return predictedPosition
end

-- Team check with ignore list
local function IsTeamIgnored(player)
    if not Config.TeamCheck then return false end
    if not player.Team then return false end
    
    for _, teamName in pairs(Config.IgnoredTeams) do
        if player.Team.Name == teamName then
            return true
        end
    end
    
    return false
end

-- Check if player has weapon
local function GetPlayerWeapon(player)
    if not player or not player.Character then return "Fist" end
    local tool = player.Character:FindFirstChildOfClass("Tool")
    return tool and tool.Name or "Fist"
end

-- Advanced target finding with FOV and angle tracking
local function GetBestTarget()
    local best = nil
    local bestScore = -math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    for _, plr in Players:GetPlayers() do
        if plr == lp or not plr.Character then continue end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        local hum = plr.Character:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        if IsTeamIgnored(plr) then continue end

        local part = plr.Character:FindFirstChild(Config.TargetPart) or hrp
        local predictedPos = CalculatePrediction(plr, part)
        local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)

        if onScreen then
            local score = 0
            
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            local cameraForward = Camera.CFrame.LookVector
            local toTarget = (predictedPos - Camera.CFrame.Position).Unit
            local angle = math.deg(math.acos(cameraForward:Dot(toTarget)))
            
            if Config.AimbotFOV then
                if dist <= Config.FOVRadius then
                    score = score + (Config.FOVRadius - dist)
                else
                    if Config.AdvancedTracking and angle <= Config.MaxTrackingAngle then
                        score = score + (Config.MaxTrackingAngle - angle) * 0.5
                    else
                        continue
                    end
                end
            else
                if Config.AdvancedTracking and angle <= Config.MaxTrackingAngle then
                    score = score + (Config.MaxTrackingAngle - angle) * 2
                else
                    score = score - angle * 10
                end
            end
            
            local distance3D = (hrp.Position - Camera.CFrame.Position).Magnitude
            score = score + (1000 / distance3D)
            
            if score > bestScore then
                best = plr
                bestScore = score
            end
        end
    end
    return best
end

-- Improved Auto Shoot function
local function PerformAutoShoot()
    if not Config.AutoShoot or not CurrentTarget or not CurrentTarget.Character then 
        AutoShooting = false
        return 
    end
    
    if tick() - LastShot >= Config.ShootDelay then
        local part = CurrentTarget.Character:FindFirstChild(Config.TargetPart) or CurrentTarget.Character.HumanoidRootPart
        if not part then return end
        
        local predictedPos = CalculatePrediction(CurrentTarget, part)
        
        if ReplicatedStorage:FindFirstChild("MainEvent") then
            ReplicatedStorage.MainEvent:FireServer("Shoot", predictedPos)
            LastShot = tick()
            AutoShooting = true
            
            if Config.ColorMode == "Rainbow" then
                FOVCircle.Color = Color3.fromRGB(255, 255, 0)
                task.delay(0.1, function()
                    if CurrentTarget then
                        FOVCircle.Color = Color3.fromHSV(rainbowHue, 1, 1)
                    end
                end)
            else
                FOVCircle.Color = Color3.fromRGB(255, 255, 0)
                task.delay(0.1, function()
                    if CurrentTarget then
                        FOVCircle.Color = Config.StaticColor
                    end
                end)
            end
        end
    end
end

-- Create Unified ESP Box System
local function CreateESP(player)
    if player == lp or ESP.MainBox[player] then return end
    
    -- Main Unified Box (transparent background)
    ESP.MainBox[player] = Drawing.new("Square")
    ESP.MainBox[player].Thickness = 1
    ESP.MainBox[player].Filled = true
    ESP.MainBox[player].Transparency = Config.BoxTransparency
    ESP.MainBox[player].Visible = false
    
    -- Tracers
    ESP.Tracers[player] = Drawing.new("Line")
    ESP.Tracers[player].Thickness = 2
    ESP.Tracers[player].Visible = false
    
    -- Name Text (top of box)
    ESP.NameText[player] = Drawing.new("Text")
    ESP.NameText[player].Size = 14
    ESP.NameText[player].Center = true
    ESP.NameText[player].Outline = true
    ESP.NameText[player].Visible = false
    
    -- Health Text
    ESP.HealthText[player] = Drawing.new("Text")
    ESP.HealthText[player].Size = 12
    ESP.HealthText[player].Center = true
    ESP.HealthText[player].Outline = true
    ESP.HealthText[player].Visible = false
    
    -- Weapon Text
    ESP.WeaponText[player] = Drawing.new("Text")
    ESP.WeaponText[player].Size = 11
    ESP.WeaponText[player].Center = true
    ESP.WeaponText[player].Outline = true
    ESP.WeaponText[player].Visible = false
    
    -- Distance Text
    ESP.DistanceText[player] = Drawing.new("Text")
    ESP.DistanceText[player].Size = 11
    ESP.DistanceText[player].Center = true
    ESP.DistanceText[player].Outline = true
    ESP.DistanceText[player].Visible = false
    
    -- Health Bar Background
    ESP.HealthBarBackground[player] = Drawing.new("Square")
    ESP.HealthBarBackground[player].Thickness = 1
    ESP.HealthBarBackground[player].Filled = true
    ESP.HealthBarBackground[player].Color = Color3.fromRGB(50, 50, 50)
    ESP.HealthBarBackground[player].Visible = false
    
    -- Health Bar
    ESP.HealthBar[player] = Drawing.new("Square")
    ESP.HealthBar[player].Thickness = 1
    ESP.HealthBar[player].Filled = true
    ESP.HealthBar[player].Visible = false
end

local function UpdateESP()
    for player, mainBox in pairs(ESP.MainBox) do
        local shouldShowESP = Config.ESPEnabled and not IsTeamIgnored(player)
        
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            mainBox.Visible = false
            ESP.Tracers[player].Visible = false
            ESP.NameText[player].Visible = false
            ESP.HealthText[player].Visible = false
            ESP.WeaponText[player].Visible = false
            ESP.DistanceText[player].Visible = false
            ESP.HealthBar[player].Visible = false
            ESP.HealthBarBackground[player].Visible = false
            continue
        end
        
        local character = player.Character
        local hrp = character.HumanoidRootPart
        local humanoid = character:FindFirstChild("Humanoid")
        
        if not humanoid or humanoid.Health <= 0 then
            mainBox.Visible = false
            ESP.Tracers[player].Visible = false
            ESP.NameText[player].Visible = false
            ESP.HealthText[player].Visible = false
            ESP.WeaponText[player].Visible = false
            ESP.DistanceText[player].Visible = false
            ESP.HealthBar[player].Visible = false
            ESP.HealthBarBackground[player].Visible = false
            continue
        end
        
        local headPos = Camera:WorldToViewportPoint(character.Head.Position)
        local rootPos = Camera:WorldToViewportPoint(hrp.Position)
        
        if rootPos.Z < 0 then
            mainBox.Visible = false
            ESP.Tracers[player].Visible = false
            ESP.NameText[player].Visible = false
            ESP.HealthText[player].Visible = false
            ESP.WeaponText[player].Visible = false
            ESP.DistanceText[player].Visible = false
            ESP.HealthBar[player].Visible = false
            ESP.HealthBarBackground[player].Visible = false
            continue
        end
        
        -- UNIFIED ESP BOX SYSTEM
        if Config.UnifiedESPBox and shouldShowESP then
            local boxWidth = Config.BoxSize
            local boxHeight = 80 -- Fixed height for all info
            local boxX = rootPos.X - boxWidth/2
            local boxY = headPos.Y - 100 -- Position above head
            
            -- Main Box
            mainBox.Size = Vector2.new(boxWidth, boxHeight)
            mainBox.Position = Vector2.new(boxX, boxY)
            
            -- Apply color mode to box
            if Config.ColorMode == "Rainbow" then
                mainBox.Color = Color3.fromHSV(rainbowHue, 0.3, 0.3) -- Darker for background
            else
                local teamColor = player.Team == lp.Team and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
                mainBox.Color = teamColor
            end
            mainBox.Visible = true
            
            -- Name (Top of box)
            ESP.NameText[player].Text = player.DisplayName
            ESP.NameText[player].Position = Vector2.new(rootPos.X, boxY + 10)
            ESP.NameText[player].Color = Color3.fromRGB(255, 255, 255)
            ESP.NameText[player].Visible = true
            
            -- Health Information
            if Config.ShowHealthBar and humanoid then
                local health = humanoid.Health
                local maxHealth = humanoid.MaxHealth
                local healthPercent = math.max(0, health / maxHealth)
                
                -- Health Text
                ESP.HealthText[player].Text = "HP: " .. math.floor(health) .. "/" .. math.floor(maxHealth)
                ESP.HealthText[player].Position = Vector2.new(rootPos.X, boxY + 25)
                ESP.HealthText[player].Color = Color3.fromRGB(255, 255, 255)
                ESP.HealthText[player].Visible = true
                
                -- Health Bar Background
                local barWidth = boxWidth - 20
                local barHeight = 8
                ESP.HealthBarBackground[player].Size = Vector2.new(barWidth, barHeight)
                ESP.HealthBarBackground[player].Position = Vector2.new(boxX + 10, boxY + 40)
                ESP.HealthBarBackground[player].Visible = true
                
                -- Health Bar
                ESP.HealthBar[player].Size = Vector2.new(barWidth * healthPercent, barHeight)
                ESP.HealthBar[player].Position = Vector2.new(boxX + 10, boxY + 40)
                ESP.HealthBar[player].Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                ESP.HealthBar[player].Visible = true
            else
                ESP.HealthText[player].Visible = false
                ESP.HealthBar[player].Visible = false
                ESP.HealthBarBackground[player].Visible = false
            end
            
            -- Weapon Information
            if Config.ShowWeapon then
                local weapon = GetPlayerWeapon(player)
                ESP.WeaponText[player].Text = "Weapon: " .. weapon
                ESP.WeaponText[player].Position = Vector2.new(rootPos.X, boxY + 55)
                ESP.WeaponText[player].Color = Color3.fromRGB(255, 255, 0)
                ESP.WeaponText[player].Visible = true
            else
                ESP.WeaponText[player].Visible = false
            end
            
            -- Distance Information
            if Config.ShowDistance then
                local distance = lp.Character and (hrp.Position - lp.Character.HumanoidRootPart.Position).Magnitude or 0
                ESP.DistanceText[player].Text = "Distance: " .. math.floor(distance) .. "m"
                ESP.DistanceText[player].Position = Vector2.new(rootPos.X, boxY + 70)
                ESP.DistanceText[player].Color = Color3.fromRGB(200, 200, 200)
                ESP.DistanceText[player].Visible = true
            else
                ESP.DistanceText[player].Visible = false
            end
        else
            mainBox.Visible = false
            ESP.NameText[player].Visible = false
            ESP.HealthText[player].Visible = false
            ESP.WeaponText[player].Visible = false
            ESP.DistanceText[player].Visible = false
            ESP.HealthBar[player].Visible = false
            ESP.HealthBarBackground[player].Visible = false
        end
        
        -- Tracers (from mouse to player)
        if Config.Tracers and shouldShowESP then
            ESP.Tracers[player].From = Vector2.new(Mouse.X, Mouse.Y)
            ESP.Tracers[player].To = Vector2.new(rootPos.X, rootPos.Y)
            
            if Config.ColorMode == "Rainbow" then
                ESP.Tracers[player].Color = Color3.fromHSV(rainbowHue, 1, 1)
            else
                ESP.Tracers[player].Color = player.Team == lp.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 50, 50)
            end
            
            ESP.Tracers[player].Visible = true
        else
            ESP.Tracers[player].Visible = false
        end
    end
end

local function RemoveESP(player)
    if ESP.MainBox[player] then ESP.MainBox[player]:Remove() ESP.MainBox[player] = nil end
    if ESP.Tracers[player] then ESP.Tracers[player]:Remove() ESP.Tracers[player] = nil end
    if ESP.NameText[player] then ESP.NameText[player]:Remove() ESP.NameText[player] = nil end
    if ESP.HealthText[player] then ESP.HealthText[player]:Remove() ESP.HealthText[player] = nil end
    if ESP.WeaponText[player] then ESP.WeaponText[player]:Remove() ESP.WeaponText[player] = nil end
    if ESP.DistanceText[player] then ESP.DistanceText[player]:Remove() ESP.DistanceText[player] = nil end
    if ESP.HealthBar[player] then ESP.HealthBar[player]:Remove() ESP.HealthBar[player] = nil end
    if ESP.HealthBarBackground[player] then ESP.HealthBarBackground[player]:Remove() ESP.HealthBarBackground[player] = nil end
end

-- Advanced aimbot tracking with speed control
local function AdvancedAimAtTarget(target)
    if not target or not target.Character then return end
    
    local part = target.Character:FindFirstChild(Config.TargetPart) or target.Character.HumanoidRootPart
    if not part then return end
    
    local targetPosition = CalculatePrediction(target, part)
    local currentCFrame = Camera.CFrame
    local direction = (targetPosition - currentCFrame.Position).Unit
    
    local cameraForward = currentCFrame.LookVector
    local angleToTarget = math.acos(cameraForward:Dot(direction))
    
    local effectiveSmoothing = Config.Smoothing / Config.AimbotSpeed
    local smoothedDirection = currentCFrame.LookVector:Lerp(direction, effectiveSmoothing)
    
    local screenPos = Camera:WorldToViewportPoint(targetPosition)
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local distFromMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
    
    if Config.AdvancedTracking and distFromMouse > Config.FOVRadius then
        local trackingDirection = currentCFrame.LookVector:Lerp(direction, effectiveSmoothing * 0.5)
        Camera.CFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + trackingDirection)
    else
        Camera.CFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + smoothedDirection)
    end
end

-- Main loop
RunService.Heartbeat:Connect(function(deltaTime)
    -- Update FOV circle position (centered to mouse)
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
    FOVCircle.Radius = Config.FOVRadius
    
    -- Update rainbow colors
    rainbowHue = (rainbowHue + deltaTime * Config.RainbowSpeed) % 1
    
    -- Update FOV circle color with Color Mode
    if Config.ColorMode == "Rainbow" then
        if HoldingE and CurrentTarget then
            FOVCircle.Color = Color3.fromHSV(rainbowHue, 1, 1)
        else
            FOVCircle.Color = Color3.fromHSV(rainbowHue, 1, 1)
        end
    else
        if HoldingE and CurrentTarget then
            FOVCircle.Color = Color3.fromRGB(0, 255, 0)
        else
            FOVCircle.Color = Config.StaticColor
        end
    end
    
    -- Update ESP
    UpdateESP()
    
    -- Advanced aimbot logic when holding E (only if aimbot is enabled)
    if HoldingE and Config.AimbotEnabled then
        local target = GetBestTarget()
        
        if target and target ~= CurrentTarget then
            CurrentTarget = target
            ShowNotification("Target Locked", "Tracking: " .. target.DisplayName)
        end
        
        if CurrentTarget then
            AdvancedAimAtTarget(CurrentTarget)
            PerformAutoShoot()
        else
            AutoShooting = false
        end
    else
        if CurrentTarget then
            CurrentTarget = nil
        end
        AutoShooting = false
    end
end)

-- Input handling with proper toggle checks
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.HoldKey and Config.AimbotEnabled then
        HoldingE = true
        ShowNotification("Aimbot Active", "Hold E to track targets")
    end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        FOVCircle.Visible = not FOVCircle.Visible
        ShowNotification("FOV Circle", FOVCircle.Visible and "Visible" or "Hidden")
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Config.HoldKey then
        HoldingE = false
        AutoShooting = false
        if CurrentTarget then
            ShowNotification("Aimbot Inactive", "Released E key")
        end
    end
end)

-- Player management
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        CreateESP(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
    if CurrentTarget == player then
        CurrentTarget = nil
    end
end)

-- Initialize ESP for existing players
for _, player in Players:GetPlayers() do
    if player ~= lp then
        CreateESP(player)
    end
end

-- ENHANCED GUI FOR UNIFIED ESP BOX
-- Main Tab (same as before)
MainTab:CreateSection("Aimbot Configuration")
MainTab:CreateToggle({Name = "Aimbot Enabled", CurrentValue = true, Callback = function(v) Config.AimbotEnabled = v; ShowNotification("Aimbot", v and "ENABLED" or "DISABLED") end})
MainTab:CreateToggle({Name = "Aimbot FOV", CurrentValue = true, Callback = function(v) Config.AimbotFOV = v; ShowNotification("Aimbot FOV", v and "ENABLED" or "DISABLED") end})
MainTab:CreateToggle({Name = "Advanced Tracking", CurrentValue = true, Callback = function(v) Config.AdvancedTracking = v; ShowNotification("Advanced Tracking", v and "ENABLED" or "DISABLED") end})
MainTab:CreateToggle({Name = "Prediction", CurrentValue = true, Callback = function(v) Config.Prediction = v; ShowNotification("Prediction", v and "ENABLED" or "DISABLED") end})
MainTab:CreateToggle({Name = "Auto Shoot", CurrentValue = true, Callback = function(v) Config.AutoShoot = v; ShowNotification("Auto Shoot", v and "ENABLED" or "DISABLED") end})
MainTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Config.TeamCheck = v; ShowNotification("Team Check", v and "ENABLED" or "DISABLED") end})

MainTab:CreateSection("Aimbot Settings")
MainTab:CreateSlider({Name = "FOV Radius", Range = {50, 300}, Increment = 10, CurrentValue = 150, Callback = function(v) Config.FOVRadius = v end})
MainTab:CreateSlider({Name = "Aimbot Speed", Range = {0.1, 5.0}, Increment = 0.1, CurrentValue = 1.0, Callback = function(v) Config.AimbotSpeed = v end})
MainTab:CreateSlider({Name = "Smoothing", Range = {0.01, 0.5}, Increment = 0.01, CurrentValue = 0.08, Callback = function(v) Config.Smoothing = v end})
MainTab:CreateSlider({Name = "Max Tracking Angle", Range = {30, 180}, Increment = 5, CurrentValue = 120, Callback = function(v) Config.MaxTrackingAngle = v end})
MainTab:CreateSlider({Name = "Prediction Strength", Range = {0.5, 2.5}, Increment = 0.1, CurrentValue = 1.15, Callback = function(v) Config.PredictionStrength = v end})
MainTab:CreateSlider({Name = "Shoot Delay", Range = {0.05, 0.5}, Increment = 0.01, CurrentValue = 0.12, Callback = function(v) Config.ShootDelay = v end})
MainTab:CreateDropdown({Name = "Target Part", Options = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}, CurrentOption = "Head", Callback = function(v) Config.TargetPart = v end})

-- Visual Tab
VisualTab:CreateSection("Color System")
VisualTab:CreateDropdown({Name = "Color Mode", Options = {"Rainbow", "Static"}, CurrentOption = "Rainbow", Callback = function(v) Config.ColorMode = v; ShowNotification("Color Mode", v) end})
VisualTab:CreateColorPicker({Name = "Static Color", Color = Config.StaticColor, Callback = function(v) Config.StaticColor = v; if Config.ColorMode == "Static" then FOVCircle.Color = v end end})
VisualTab:CreateSlider({Name = "Rainbow Speed", Range = {1, 20}, Increment = 1, CurrentValue = 5, Callback = function(v) Config.RainbowSpeed = v end})

VisualTab:CreateSection("Visual Settings")
VisualTab:CreateToggle({Name = "FOV Circle Visible", CurrentValue = true, Callback = function(v) FOVCircle.Visible = v; ShowNotification("FOV Circle", v and "Visible" or "Hidden") end})

VisualTab:CreateSection("Unified ESP Box System")
VisualTab:CreateToggle({Name = "ESP Enabled", CurrentValue = true, Callback = function(v) Config.ESPEnabled = v; ShowNotification("ESP", v and "ENABLED" or "DISABLED") end})
VisualTab:CreateToggle({Name = "Unified ESP Box", CurrentValue = true, Callback = function(v) Config.UnifiedESPBox = v; ShowNotification("Unified Box", v and "ENABLED" or "DISABLED") end})
VisualTab:CreateToggle({Name = "Tracers", CurrentValue = true, Callback = function(v) Config.Tracers = v; ShowNotification("Tracers", v and "ENABLED" or "DISABLED") end})
VisualTab:CreateToggle({Name = "Show Health Bar", CurrentValue = true, Callback = function(v) Config.ShowHealthBar = v; ShowNotification("Health Bar", v and "ENABLED" or "DISABLED") end})
VisualTab:CreateToggle({Name = "Show Weapon", CurrentValue = true, Callback = function(v) Config.ShowWeapon = v; ShowNotification("Weapon ESP", v and "ENABLED" or "DISABLED") end})
VisualTab:CreateToggle({Name = "Show Distance", CurrentValue = true, Callback = function(v) Config.ShowDistance = v; ShowNotification("Distance", v and "ENABLED" or "DISABLED") end})

VisualTab:CreateSection("Box Settings")
VisualTab:CreateSlider({Name = "Box Transparency", Range = {0.1, 0.9}, Increment = 0.1, CurrentValue = 0.7, Callback = function(v) Config.BoxTransparency = v end})
VisualTab:CreateSlider({Name = "Box Width", Range = {80, 200}, Increment = 10, CurrentValue = 120, Callback = function(v) Config.BoxSize = v end})

-- Settings Tab
SettingsTab:CreateSection("Team Management")
local teams = GetTeams()
for _, teamName in pairs(teams) do
    SettingsTab:CreateToggle({
        Name = "Ignore " .. teamName,
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.IgnoredTeams, teamName)
                ShowNotification("Team Ignored", "Ignoring: " .. teamName)
            else
                for i, name in pairs(Config.IgnoredTeams) do
                    if name == teamName then
                        table.remove(Config.IgnoredTeams, i)
                        ShowNotification("Team Removed", "No longer ignoring: " .. teamName)
                        break
                    end
                end
            end
        end
    })
end

SettingsTab:CreateSection("Information")
SettingsTab:CreateParagraph({
    Title = "Unified ESP Box",
    Content = "All player information organized in one clean box:\n• Name at top\n• Health bar with text\n• Current weapon\n• Distance to player\n• Transparent background for visibility"
})

ShowNotification("Unified ESP Loaded", "All player info in one organized box!")

print("Prison Life Unified ESP Aimbot - All-in-One Box Edition Loaded")
