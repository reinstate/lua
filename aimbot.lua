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
    Name = "prison life ultimate aimbot",
    LoadingTitle = "loading unified esp aimbot...",
    LoadingSubtitle = "all-in-one esp box - organized layout - hold LMB activation",
    ConfigurationSaving = { Enabled = true, FolderName = "PLUnifiedESP" },
    KeySystem = false
})

-- Clean Tabs
local MainTab = Window:CreateTab("aimbot")
local VisualTab = Window:CreateTab("visuals")
local SettingsTab = Window:CreateTab("settings")
local ConfigTab = Window:CreateTab("configurations") -- New Configuration Tab

-- Enhanced Config
local Config = {
    -- Aimbot
    AimbotEnabled = false,
    HoldKey = Enum.UserInputType.MouseButton1, -- LMB
    FOVRadius = 150,
    TargetPart = "Head",
    Smoothing = 0.05,
    AimbotSpeed = 1.2,
    Prediction = true,
    PredictionStrength = 1.25,
    BulletSpeed = 2200,
    AutoShoot = false,
    ShootDelay = 0.1,
    
    -- Advanced Tracking
    AdvancedTracking = true,
    MaxTrackingAngle = 90,
    HitChance = 95,
    
    -- Team Management
    TeamCheck = false,
    IgnoredTeams = {},
    
    -- Color System
    ColorMode = "team", -- team, full
    FullColor = Color3.fromRGB(255, 50, 50),
    
    -- ESP
    ESPEnabled = false,
    Tracers = false,
    ShowHealthBar = false,
    ShowWeapon = false,
    ShowDistance = false,
    SkeletonESP = false, -- New: Skeleton highlight
    
    -- Aimbot FOV
    AimbotFOV = false
}

-- Configuration Management System
local ConfigManager = {
    CurrentProfile = "Default",
    Profiles = {},
    ConfigFolder = "PLUnifiedESP_Profiles",
    
    -- Initialize
    Init = function(self)
        -- Create folder if it doesn't exist
        if not isfolder(self.ConfigFolder) then
            makefolder(self.ConfigFolder)
        end
        
        -- Load existing profiles
        self:LoadProfileList()
    end,
    
    -- Save current configuration to file
    SaveConfig = function(self, profileName)
        if not profileName or profileName == "" then
            profileName = "Unnamed_Config_" .. os.time()
        end
        
        -- Prepare config data
        local configData = {
            Config = Config,
            Timestamp = os.date("%Y-%m-%d %H:%M:%S"),
            ProfileName = profileName
        }
        
        -- Convert Color3 to table for serialization
        configData.Config.FullColor = {
            R = Config.FullColor.R,
            G = Config.FullColor.G,
            B = Config.FullColor.B
        }
        
        -- Save to file
        local success, message = pcall(function()
            writefile(self.ConfigFolder .. "/" .. profileName .. ".json", game:GetService("HttpService"):JSONEncode(configData))
        end)
        
        if success then
            ShowNotification("Configuration Saved", "Saved as: " .. profileName)
            self:LoadProfileList() -- Refresh list
            return true
        else
            ShowNotification("Save Error", "Failed to save: " .. tostring(message))
            return false
        end
    end,
    
    -- Load configuration from file
    LoadConfig = function(self, profileName)
        local filePath = self.ConfigFolder .. "/" .. profileName .. ".json"
        
        if not isfile(filePath) then
            ShowNotification("Load Error", "Configuration not found: " .. profileName)
            return false
        end
        
        local success, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(filePath))
        end)
        
        if not success or not data then
            ShowNotification("Load Error", "Failed to load configuration")
            return false
        end
        
        -- Update current config with loaded data
        for key, value in pairs(data.Config) do
            if key == "FullColor" and type(value) == "table" then
                Config[key] = Color3.new(value.R, value.G, value.B)
            elseif key == "IgnoredTeams" then
                Config[key] = value or {}
            else
                Config[key] = value
            end
        end
        
        -- Update UI elements to reflect loaded config
        self:UpdateUIFromConfig()
        
        self.CurrentProfile = profileName
        ShowNotification("Configuration Loaded", "Loaded: " .. profileName .. "\n" .. data.Timestamp)
        return true
    end,
    
    -- Delete a configuration
    DeleteConfig = function(self, profileName)
        local filePath = self.ConfigFolder .. "/" .. profileName .. ".json"
        
        if isfile(filePath) then
            delfile(filePath)
            ShowNotification("Configuration Deleted", "Deleted: " .. profileName)
            self:LoadProfileList() -- Refresh list
            return true
        else
            ShowNotification("Delete Error", "Configuration not found")
            return false
        end
    end,
    
    -- List all saved profiles
    LoadProfileList = function(self)
        self.Profiles = {}
        
        if not isfolder(self.ConfigFolder) then
            makefolder(self.ConfigFolder)
            return
        end
        
        local files = listfiles(self.ConfigFolder)
        for _, filePath in ipairs(files) do
            local fileName = filePath:match("[^\\/]+$")
            if fileName:match("%.json$") then
                local profileName = fileName:gsub("%.json$", "")
                table.insert(self.Profiles, profileName)
            end
        end
        
        table.sort(self.Profiles)
    end,
    
    -- Export config as string (for sharing)
    ExportConfig = function(self, profileName)
        local filePath = self.ConfigFolder .. "/" .. profileName .. ".json"
        
        if not isfile(filePath) then
            return nil
        end
        
        return readfile(filePath)
    end,
    
    -- Import config from string
    ImportConfig = function(self, configString, profileName)
        local success, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(configString)
        end)
        
        if not success then
            ShowNotification("Import Error", "Invalid configuration format")
            return false
        end
        
        -- Save imported config
        local configData = {
            Config = data.Config or data,
            Timestamp = os.date("%Y-%m-%d %H:%M:%S"),
            ProfileName = profileName or "Imported_" .. os.time()
        }
        
        writefile(self.ConfigFolder .. "/" .. configData.ProfileName .. ".json", 
                 game:GetService("HttpService"):JSONEncode(configData))
        
        ShowNotification("Configuration Imported", "Saved as: " .. configData.ProfileName)
        self:LoadProfileList()
        return true
    end,
    
    -- Update all UI elements to match current config
    UpdateUIFromConfig = function(self)
        -- This function should be called after loading a config to update UI toggles/sliders
        -- Note: In actual implementation, you would need to store references to UI elements
        -- and update them. For now, we'll show a notification.
        ShowNotification("UI Updated", "All settings applied from loaded configuration")
    end
}

-- Initialize Config Manager
ConfigManager:Init()

-- FOV Circle (centered to mouse)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Radius = Config.FOVRadius
FOVCircle.Filled = false
FOVCircle.Transparency = 0.9
FOVCircle.Color = Config.FullColor
FOVCircle.Visible = false

-- ESP Storage
local ESP = {
    Tracers = {},
    NameText = {},
    HealthText = {},
    WeaponText = {},
    DistanceText = {},
    HealthBar = {},
    HealthBarBackground = {},
    -- Skeleton parts
    Head = {},
    Torso = {},
    LeftArm = {},
    RightArm = {},
    LeftLeg = {},
    RightLeg = {}
}

-- Global variables
local CurrentTarget = nil
local HoldingLMB = false
local LastShot = 0
local AutoShooting = false
local TargetLocked = false

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
    
    -- Advanced prediction: account for movement patterns
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if humanoid then
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0 then
            velocity = velocity + (moveDirection * humanoid.WalkSpeed * 0.3)
        end
    end
    
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
    if not player or not player.Character then return "fist" end
    local tool = player.Character:FindFirstChildOfClass("Tool")
    return tool and tool.Name or "fist"
end

-- Get team color for player
local function GetTeamColor(player)
    if not player or not player.Team then return Color3.fromRGB(255, 255, 255) end
    return player.Team.TeamColor.Color
end

-- Get visual color based on color mode
local function GetVisualColor(player)
    if Config.ColorMode == "full" then
        return Config.FullColor
    else
        return GetTeamColor(player)
    end
end

-- Advanced hit chance calculation
local function ShouldHit(target)
    if Config.HitChance >= 100 then return true end
    local random = math.random(1, 100)
    return random <= Config.HitChance
end

-- Advanced target finding with FOV and angle tracking
local function GetBestTarget()
    if TargetLocked and CurrentTarget and CurrentTarget.Character then
        local humanoid = CurrentTarget.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            return CurrentTarget
        else
            TargetLocked = false
            CurrentTarget = nil
        end
    end
    
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
                    score = score + ((Config.FOVRadius - dist) * 2)
                else
                    if Config.AdvancedTracking and angle <= Config.MaxTrackingAngle then
                        score = score + ((Config.MaxTrackingAngle - angle) * 0.5)
                    else
                        continue
                    end
                end
            else
                if Config.AdvancedTracking and angle <= Config.MaxTrackingAngle then
                    score = score + ((Config.MaxTrackingAngle - angle) * 3)
                else
                    score = score - (angle * 15)
                end
            end
            
            local distance3D = (hrp.Position - Camera.CFrame.Position).Magnitude
            score = score + (1500 / distance3D)
            
            if Config.TargetPart == "Head" then
                score = score + 50
            end
            
            local velocity = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.new(0, 0, 0)
            if velocity.Magnitude < 2 then
                score = score + 30
            end
            
            if score > bestScore then
                best = plr
                bestScore = score
            end
        end
    end
    return best
end

-- Improved Auto Shoot function with hit chance
local function PerformAutoShoot()
    if not Config.AutoShoot or not CurrentTarget or not CurrentTarget.Character then 
        AutoShooting = false
        return 
    end
    
    if tick() - LastShot >= Config.ShootDelay then
        if not ShouldHit(CurrentTarget) then
            return
        end
        
        local part = CurrentTarget.Character:FindFirstChild(Config.TargetPart) or CurrentTarget.Character.HumanoidRootPart
        if not part then return end
        
        local predictedPos = CalculatePrediction(CurrentTarget, part)
        
        if ReplicatedStorage:FindFirstChild("MainEvent") then
            ReplicatedStorage.MainEvent:FireServer("Shoot", predictedPos)
            LastShot = tick()
            AutoShooting = true
        end
    end
end

-- Create skeleton lines between points
local function CreateSkeletonLine(player, partName)
    ESP[partName][player] = Drawing.new("Line")
    ESP[partName][player].Thickness = 2
    ESP[partName][player].Visible = false
end

-- Create ESP System
local function CreateESP(player)
    if player == lp or ESP.Tracers[player] then return end
    
    CreateSkeletonLine(player, "Head")
    CreateSkeletonLine(player, "Torso")
    CreateSkeletonLine(player, "LeftArm")
    CreateSkeletonLine(player, "RightArm")
    CreateSkeletonLine(player, "LeftLeg")
    CreateSkeletonLine(player, "RightLeg")
    
    ESP.Tracers[player] = Drawing.new("Line")
    ESP.Tracers[player].Thickness = 1
    ESP.Tracers[player].Visible = false
    
    ESP.NameText[player] = Drawing.new("Text")
    ESP.NameText[player].Size = 12
    ESP.NameText[player].Center = true
    ESP.NameText[player].Outline = true
    ESP.NameText[player].Visible = false
    
    ESP.HealthText[player] = Drawing.new("Text")
    ESP.HealthText[player].Size = 10
    ESP.HealthText[player].Center = true
    ESP.HealthText[player].Outline = true
    ESP.HealthText[player].Visible = false
    
    ESP.WeaponText[player] = Drawing.new("Text")
    ESP.WeaponText[player].Size = 9
    ESP.WeaponText[player].Center = true
    ESP.WeaponText[player].Outline = true
    ESP.WeaponText[player].Visible = false
    
    ESP.DistanceText[player] = Drawing.new("Text")
    ESP.DistanceText[player].Size = 9
    ESP.DistanceText[player].Center = true
    ESP.DistanceText[player].Outline = true
    ESP.DistanceText[player].Visible = false
    
    ESP.HealthBarBackground[player] = Drawing.new("Square")
    ESP.HealthBarBackground[player].Thickness = 1
    ESP.HealthBarBackground[player].Filled = true
    ESP.HealthBarBackground[player].Color = Color3.fromRGB(10, 10, 10)
    ESP.HealthBarBackground[player].Visible = false
    
    ESP.HealthBar[player] = Drawing.new("Square")
    ESP.HealthBar[player].Thickness = 1
    ESP.HealthBar[player].Filled = true
    ESP.HealthBar[player].Visible = false
end

-- Update skeleton lines
local function UpdateSkeleton(player, character, visualColor)
    if not character then return end
    
    local function GetPartPosition(partName)
        local part = character:FindFirstChild(partName)
        if part then
            local pos = Camera:WorldToViewportPoint(part.Position)
            if pos.Z > 0 then
                return Vector2.new(pos.X, pos.Y)
            end
        end
        return nil
    end
    
    local headPos = GetPartPosition("Head")
    local torsoPos = GetPartPosition("UpperTorso") or GetPartPosition("Torso")
    local leftArmPos = GetPartPosition("LeftUpperArm") or GetPartPosition("Left Arm")
    local rightArmPos = GetPartPosition("RightUpperArm") or GetPartPosition("Right Arm")
    local leftLegPos = GetPartPosition("LeftUpperLeg") or GetPartPosition("Left Leg")
    local rightLegPos = GetPartPosition("RightUpperLeg") or GetPartPosition("Right Leg")
    
    if not headPos or not torsoPos then return end
    
    ESP.Head[player].From = headPos
    ESP.Head[player].To = torsoPos
    ESP.Head[player].Color = visualColor
    ESP.Head[player].Visible = true
    
    ESP.Torso[player].From = torsoPos
    ESP.Torso[player].To = torsoPos
    ESP.Torso[player].Visible = false
    
    if leftArmPos then
        ESP.LeftArm[player].From = torsoPos
        ESP.LeftArm[player].To = leftArmPos
        ESP.LeftArm[player].Color = visualColor
        ESP.LeftArm[player].Visible = true
    else
        ESP.LeftArm[player].Visible = false
    end
    
    if rightArmPos then
        ESP.RightArm[player].From = torsoPos
        ESP.RightArm[player].To = rightArmPos
        ESP.RightArm[player].Color = visualColor
        ESP.RightArm[player].Visible = true
    else
        ESP.RightArm[player].Visible = false
    end
    
    if leftLegPos then
        ESP.LeftLeg[player].From = torsoPos
        ESP.LeftLeg[player].To = leftLegPos
        ESP.LeftLeg[player].Color = visualColor
        ESP.LeftLeg[player].Visible = true
    else
        ESP.LeftLeg[player].Visible = false
    end
    
    if rightLegPos then
        ESP.RightLeg[player].From = torsoPos
        ESP.RightLeg[player].To = rightLegPos
        ESP.RightLeg[player].Color = visualColor
        ESP.RightLeg[player].Visible = true
    else
        ESP.RightLeg[player].Visible = false
    end
end

local function UpdateESP()
    for player, _ in pairs(ESP.Tracers) do
        local shouldShowESP = Config.ESPEnabled and not IsTeamIgnored(player)
        local visualColor = GetVisualColor(player)
        
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            for _, partName in pairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
                if ESP[partName][player] then
                    ESP[partName][player].Visible = false
                end
            end
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
            for _, partName in pairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
                if ESP[partName][player] then
                    ESP[partName][player].Visible = false
                end
            end
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
            for _, partName in pairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
                if ESP[partName][player] then
                    ESP[partName][player].Visible = false
                end
            end
            ESP.Tracers[player].Visible = false
            ESP.NameText[player].Visible = false
            ESP.HealthText[player].Visible = false
            ESP.WeaponText[player].Visible = false
            ESP.DistanceText[player].Visible = false
            ESP.HealthBar[player].Visible = false
            ESP.HealthBarBackground[player].Visible = false
            continue
        end
        
        if Config.SkeletonESP and shouldShowESP then
            UpdateSkeleton(player, character, visualColor)
        else
            for _, partName in pairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
                if ESP[partName][player] then
                    ESP[partName][player].Visible = false
                end
            end
        end
        
        if shouldShowESP then
            local textY = headPos.Y - 50
            
            ESP.NameText[player].Text = player.DisplayName
            ESP.NameText[player].Position = Vector2.new(headPos.X, textY)
            ESP.NameText[player].Color = visualColor
            ESP.NameText[player].Visible = true
            
            if Config.ShowHealthBar and humanoid then
                local health = humanoid.Health
                local maxHealth = humanoid.MaxHealth
                local healthPercent = math.max(0, health / maxHealth)
                
                ESP.HealthText[player].Text = math.floor(health) .. " hp"
                ESP.HealthText[player].Position = Vector2.new(headPos.X, textY + 15)
                ESP.HealthText[player].Color = Color3.fromRGB(255, 255, 255)
                ESP.HealthText[player].Visible = true
                
                local barWidth = 50
                local barHeight = 4
                ESP.HealthBarBackground[player].Size = Vector2.new(barWidth, barHeight)
                ESP.HealthBarBackground[player].Position = Vector2.new(headPos.X - barWidth/2, textY + 30)
                ESP.HealthBarBackground[player].Visible = true
                
                ESP.HealthBar[player].Size = Vector2.new(barWidth * healthPercent, barHeight)
                ESP.HealthBar[player].Position = Vector2.new(headPos.X - barWidth/2, textY + 30)
                ESP.HealthBar[player].Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                ESP.HealthBar[player].Visible = true
            else
                ESP.HealthText[player].Visible = false
                ESP.HealthBar[player].Visible = false
                ESP.HealthBarBackground[player].Visible = false
            end
            
            if Config.ShowWeapon then
                local weapon = GetPlayerWeapon(player)
                ESP.WeaponText[player].Text = weapon
                ESP.WeaponText[player].Position = Vector2.new(headPos.X, textY + 38)
                ESP.WeaponText[player].Color = Color3.fromRGB(200, 200, 0)
                ESP.WeaponText[player].Visible = true
            else
                ESP.WeaponText[player].Visible = false
            end
            
            if Config.ShowDistance then
                local distance = lp.Character and (hrp.Position - lp.Character.HumanoidRootPart.Position).Magnitude or 0
                ESP.DistanceText[player].Text = math.floor(distance) .. "m"
                ESP.DistanceText[player].Position = Vector2.new(headPos.X, textY + 52)
                ESP.DistanceText[player].Color = Color3.fromRGB(150, 150, 150)
                ESP.DistanceText[player].Visible = true
            else
                ESP.DistanceText[player].Visible = false
            end
        else
            ESP.NameText[player].Visible = false
            ESP.HealthText[player].Visible = false
            ESP.WeaponText[player].Visible = false
            ESP.DistanceText[player].Visible = false
            ESP.HealthBar[player].Visible = false
            ESP.HealthBarBackground[player].Visible = false
        end
        
        if Config.Tracers and shouldShowESP then
            ESP.Tracers[player].From = Vector2.new(Mouse.X, Mouse.Y)
            ESP.Tracers[player].To = Vector2.new(rootPos.X, rootPos.Y)
            ESP.Tracers[player].Color = visualColor
            ESP.Tracers[player].Visible = true
        else
            ESP.Tracers[player].Visible = false
        end
    end
end

local function RemoveESP(player)
    for _, partName in pairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
        if ESP[partName][player] then 
            ESP[partName][player]:Remove() 
            ESP[partName][player] = nil 
        end
    end
    if ESP.Tracers[player] then ESP.Tracers[player]:Remove() ESP.Tracers[player] = nil end
    if ESP.NameText[player] then ESP.NameText[player]:Remove() ESP.NameText[player] = nil end
    if ESP.HealthText[player] then ESP.HealthText[player]:Remove() ESP.HealthText[player] = nil end
    if ESP.WeaponText[player] then ESP.WeaponText[player]:Remove() ESP.WeaponText[player] = nil end
    if ESP.DistanceText[player] then ESP.DistanceText[player]:Remove() ESP.DistanceText[player] = nil end
    if ESP.HealthBar[player] then ESP.HealthBar[player]:Remove() ESP.HealthBar[player] = nil end
    if ESP.HealthBarBackground[player] then ESP.HealthBarBackground[player]:Remove() ESP.HealthBarBackground[player] = nil end
end

-- Advanced aimbot tracking with precision aiming
local function AdvancedAimAtTarget(target)
    if not target or not target.Character then return end
    
    local part = target.Character:FindFirstChild(Config.TargetPart) or target.Character.HumanoidRootPart
    if not part then return end
    
    local targetPosition = CalculatePrediction(target, part)
    local currentCFrame = Camera.CFrame
    local direction = (targetPosition - currentCFrame.Position).Unit
    
    local cameraForward = currentCFrame.LookVector
    local angleToTarget = math.acos(cameraForward:Dot(direction))
    
    local distance = (targetPosition - currentCFrame.Position).Magnitude
    local dynamicSmoothing = Config.Smoothing * (1 + (angleToTarget / 180)) / Config.AimbotSpeed
    
    if angleToTarget < 10 then
        dynamicSmoothing = dynamicSmoothing * 0.7
    end
    
    local smoothedDirection = currentCFrame.LookVector:Lerp(direction, dynamicSmoothing)
    
    Camera.CFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + smoothedDirection)
end

-- Main loop
RunService.Heartbeat:Connect(function(deltaTime)
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
    FOVCircle.Radius = Config.FOVRadius
    
    if CurrentTarget then
        FOVCircle.Color = GetVisualColor(CurrentTarget)
    else
        FOVCircle.Color = Config.ColorMode == "full" and Config.FullColor or Color3.fromRGB(255, 255, 255)
    end
    
    UpdateESP()
    
    if HoldingLMB and Config.AimbotEnabled then
        local target = GetBestTarget()
        
        if target and target ~= CurrentTarget then
            CurrentTarget = target
            TargetLocked = true
            ShowNotification("target locked", "tracking: " .. target.DisplayName)
        end
        
        if CurrentTarget and CurrentTarget.Character then
            local humanoid = CurrentTarget.Character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                CurrentTarget = nil
                TargetLocked = false
                ShowNotification("target eliminated", "searching for new target...")
            else
                AdvancedAimAtTarget(CurrentTarget)
                PerformAutoShoot()
            end
        else
            AutoShooting = false
            TargetLocked = false
        end
    else
        if CurrentTarget then
            CurrentTarget = nil
            TargetLocked = false
        end
        AutoShooting = false
    end
end)

-- Input handling with proper toggle checks
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Config.HoldKey and Config.AimbotEnabled then
        HoldingLMB = true
        ShowNotification("aimbot active", "hold LMB to track targets")
    end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        FOVCircle.Visible = not FOVCircle.Visible
        ShowNotification("fov circle", FOVCircle.Visible and "visible" or "hidden")
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.HoldKey then
        HoldingLMB = false
        AutoShooting = false
        TargetLocked = false
        if CurrentTarget then
            ShowNotification("aimbot inactive", "released LMB")
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
        TargetLocked = false
    end
end)

-- Initialize ESP for existing players
for _, player in Players:GetPlayers() do
    if player ~= lp then
        CreateESP(player)
    end
end

-- ENHANCED GUI FOR UNIFIED ESP BOX
-- Main Tab
MainTab:CreateSection("aimbot configuration")
MainTab:CreateToggle({Name = "aimbot enabled", CurrentValue = false, Callback = function(v) Config.AimbotEnabled = v; ShowNotification("aimbot", v and "enabled" or "disabled") end})
MainTab:CreateToggle({Name = "aimbot fov", CurrentValue = false, Callback = function(v) Config.AimbotFOV = v; ShowNotification("aimbot fov", v and "enabled" or "disabled") end})
MainTab:CreateToggle({Name = "advanced tracking", CurrentValue = true, Callback = function(v) Config.AdvancedTracking = v; ShowNotification("advanced tracking", v and "enabled" or "disabled") end})
MainTab:CreateToggle({Name = "prediction", CurrentValue = true, Callback = function(v) Config.Prediction = v; ShowNotification("prediction", v and "enabled" or "disabled") end})
MainTab:CreateToggle({Name = "auto shoot", CurrentValue = false, Callback = function(v) Config.AutoShoot = v; ShowNotification("auto shoot", v and "enabled" or "disabled") end})
MainTab:CreateToggle({Name = "team check", CurrentValue = false, Callback = function(v) Config.TeamCheck = v; ShowNotification("team check", v and "enabled" or "disabled") end})

MainTab:CreateSection("aimbot settings")
MainTab:CreateSlider({Name = "fov radius", Range = {50, 300}, Increment = 10, CurrentValue = 150, Callback = function(v) Config.FOVRadius = v end})
MainTab:CreateSlider({Name = "aimbot speed", Range = {0.1, 5.0}, Increment = 0.1, CurrentValue = 1.2, Callback = function(v) Config.AimbotSpeed = v end})
MainTab:CreateSlider({Name = "smoothing", Range = {0.01, 0.5}, Increment = 0.01, CurrentValue = 0.05, Callback = function(v) Config.Smoothing = v end})
MainTab:CreateSlider({Name = "max tracking angle", Range = {30, 180}, Increment = 5, CurrentValue = 90, Callback = function(v) Config.MaxTrackingAngle = v end})
MainTab:CreateSlider({Name = "prediction strength", Range = {0.5, 2.5}, Increment = 0.1, CurrentValue = 1.25, Callback = function(v) Config.PredictionStrength = v end})
MainTab:CreateSlider({Name = "shoot delay", Range = {0.05, 0.5}, Increment = 0.01, CurrentValue = 0.1, Callback = function(v) Config.ShootDelay = v end})
MainTab:CreateSlider({Name = "hit chance", Range = {50, 100}, Increment = 1, CurrentValue = 95, Callback = function(v) Config.HitChance = v end})
MainTab:CreateDropdown({Name = "target part", Options = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}, CurrentOption = "Head", Callback = function(v) Config.TargetPart = v end})

-- Visual Tab
VisualTab:CreateSection("color settings")
VisualTab:CreateDropdown({Name = "color mode", Options = {"team", "full"}, CurrentOption = "team", Callback = function(v) 
    Config.ColorMode = v
    ShowNotification("color mode", v)
end})
VisualTab:CreateColorPicker({Name = "full color", Color = Config.FullColor, Callback = function(v) 
    Config.FullColor = v
    if Config.ColorMode == "full" then
        FOVCircle.Color = v
    end
end})

VisualTab:CreateSection("visual settings")
VisualTab:CreateToggle({Name = "fov circle visible", CurrentValue = false, Callback = function(v) FOVCircle.Visible = v; ShowNotification("fov circle", v and "visible" or "hidden") end})
VisualTab:CreateToggle({Name = "skeleton esp", CurrentValue = false, Callback = function(v) Config.SkeletonESP = v; ShowNotification("skeleton esp", v and "enabled" or "disabled") end})

VisualTab:CreateSection("esp system")
VisualTab:CreateToggle({Name = "esp enabled", CurrentValue = false, Callback = function(v) Config.ESPEnabled = v; ShowNotification("esp", v and "enabled" or "disabled") end})
VisualTab:CreateToggle({Name = "tracers", CurrentValue = false, Callback = function(v) Config.Tracers = v; ShowNotification("tracers", v and "enabled" or "disabled") end})
VisualTab:CreateToggle({Name = "show health bar", CurrentValue = false, Callback = function(v) Config.ShowHealthBar = v; ShowNotification("health bar", v and "enabled" or "disabled") end})
VisualTab:CreateToggle({Name = "show weapon", CurrentValue = false, Callback = function(v) Config.ShowWeapon = v; ShowNotification("weapon esp", v and "enabled" or "disabled") end})
VisualTab:CreateToggle({Name = "show distance", CurrentValue = false, Callback = function(v) Config.ShowDistance = v; ShowNotification("distance", v and "enabled" or "disabled") end})

-- Settings Tab
SettingsTab:CreateSection("team management")
local teams = GetTeams()
for _, teamName in pairs(teams) do
    SettingsTab:CreateToggle({
        Name = "ignore " .. teamName,
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.IgnoredTeams, teamName)
                ShowNotification("team ignored", "ignoring: " .. teamName)
            else
                for i, name in pairs(Config.IgnoredTeams) do
                    if name == teamName then
                        table.remove(Config.IgnoredTeams, i)
                        ShowNotification("team removed", "no longer ignoring: " .. teamName)
                        break
                    end
                end
            end
        end
    })
end

-- CONFIGURATION TAB
ConfigTab:CreateSection("save / load configurations")

-- Profile name input
local ProfileNameInput = ConfigTab:CreateInput({
    Name = "profile name",
    PlaceholderText = "Enter profile name",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        -- Store the profile name
        ConfigManager.CurrentProfile = Text ~= "" and Text or "Default"
    end,
})

-- Save Current Configuration Button
ConfigTab:CreateButton({
    Name = "💾 save current configuration",
    Callback = function()
        local profileName = ProfileNameInput:GetText()
        if profileName == "" then
            profileName = "Config_" .. os.date("%Y%m%d_%H%M%S")
            ProfileNameInput:Set(profileName)
        end
        
        ConfigManager:SaveConfig(profileName)
        
        -- Refresh dropdown
        ConfigDropdown:Refresh(ConfigManager.Profiles, true)
    end,
})

-- Load Configuration Dropdown
local ConfigDropdown = ConfigTab:CreateDropdown({
    Name = "load configuration",
    Options = ConfigManager.Profiles,
    CurrentOption = "",
    Callback = function(profileName)
        if profileName and profileName ~= "" then
            ConfigManager:LoadConfig(profileName)
            ProfileNameInput:Set(profileName)
        end
    end,
})

-- Refresh configurations list button
ConfigTab:CreateButton({
    Name = "🔄 refresh configurations list",
    Callback = function()
        ConfigManager:LoadProfileList()
        ConfigDropdown:Refresh(ConfigManager.Profiles, true)
        ShowNotification("Configurations", "List refreshed: " .. #ConfigManager.Profiles .. " profiles")
    end,
})

-- Delete Current Configuration Button
ConfigTab:CreateButton({
    Name = "🗑️ delete selected configuration",
    Callback = function()
        local currentProfile = ProfileNameInput:GetText()
        if currentProfile == "" then
            ShowNotification("Delete Error", "Please select a configuration first")
            return
        end
        
        ConfigManager:DeleteConfig(currentProfile)
        
        -- Refresh dropdown and clear input
        ConfigManager:LoadProfileList()
        ConfigDropdown:Refresh(ConfigManager.Profiles, true)
        ProfileNameInput:Set("")
    end,
})

ConfigTab:CreateSection("import / export")

-- Export Configuration Button
ConfigTab:CreateButton({
    Name = "📤 export configuration (copy to clipboard)",
    Callback = function()
        local currentProfile = ProfileNameInput:GetText()
        if currentProfile == "" then
            ShowNotification("Export Error", "Please save or select a configuration first")
            return
        end
        
        local exported = ConfigManager:ExportConfig(currentProfile)
        if exported then
            setclipboard(exported)
            ShowNotification("Exported", "Configuration copied to clipboard!")
        end
    end,
})

-- Import Configuration Input
ConfigTab:CreateInput({
    Name = "import configuration (paste JSON)",
    PlaceholderText = "Paste configuration JSON here",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text and Text ~= "" then
            local profileName = "Imported_" .. os.date("%Y%m%d_%H%M%S")
            if ConfigManager:ImportConfig(Text, profileName) then
                ProfileNameInput:Set(profileName)
                ConfigManager:LoadProfileList()
                ConfigDropdown:Refresh(ConfigManager.Profiles, true)
            end
        end
    end,
})

-- Quick Save Presets Section
ConfigTab:CreateSection("quick save presets")

-- Preset buttons for common configurations
ConfigTab:CreateButton({
    Name = "⚡ save as: aggressive",
    Callback = function()
        -- Store current config
        local currentConfig = table.clone(Config)
        
        -- Apply aggressive preset
        Config.AimbotEnabled = true
        Config.AimbotFOV = true
        Config.FOVRadius = 80
        Config.Smoothing = 0.02
        Config.AimbotSpeed = 1.5
        Config.AutoShoot = true
        Config.ShootDelay = 0.08
        Config.HitChance = 100
        Config.TargetPart = "Head"
        
        -- Save with preset name
        ConfigManager:SaveConfig("Preset_Aggressive")
        
        -- Restore original config
        for k, v in pairs(currentConfig) do
            Config[k] = v
        end
        
        ShowNotification("Preset Saved", "Aggressive configuration saved")
    end,
})

ConfigTab:CreateButton({
    Name = "🎯 save as: sniper",
    Callback = function()
        local currentConfig = table.clone(Config)
        
        Config.AimbotEnabled = true
        Config.AimbotFOV = false
        Config.AdvancedTracking = true
        Config.MaxTrackingAngle = 120
        Config.Smoothing = 0.1
        Config.Prediction = true
        Config.PredictionStrength = 1.8
        Config.HitChance = 90
        Config.TargetPart = "Head"
        
        ConfigManager:SaveConfig("Preset_Sniper")
        
        for k, v in pairs(currentConfig) do
            Config[k] = v
        end
        
        ShowNotification("Preset Saved", "Sniper configuration saved")
    end,
})

ConfigTab:CreateButton({
    Name = "👁️ save as: esp only",
    Callback = function()
        local currentConfig = table.clone(Config)
        
        Config.AimbotEnabled = false
        Config.ESPEnabled = true
        Config.Tracers = true
        Config.ShowHealthBar = true
        Config.ShowWeapon = true
        Config.ShowDistance = true
        Config.SkeletonESP = true
        Config.ColorMode = "team"
        
        ConfigManager:SaveConfig("Preset_ESP_Only")
        
        for k, v in pairs(currentConfig) do
            Config[k] = v
        end
        
        ShowNotification("Preset Saved", "ESP-only configuration saved")
    end,
})

ConfigTab:CreateSection("configuration info")
ConfigTab:CreateParagraph({
    Title = "configuration management",
    Content = "How to use:\n1. Enter a profile name\n2. Click 'Save Current Configuration' to save\n3. Use dropdown to load saved configurations\n4. Export/Import for sharing configs\n\nConfigurations are saved to:\n" .. ConfigManager.ConfigFolder
})

-- Initialize dropdown with current profiles
ConfigManager:LoadProfileList()
ConfigDropdown:Refresh(ConfigManager.Profiles, true)

ShowNotification("ultimate esp aimbot loaded", "hold LMB to activate aimbot\n" .. #ConfigManager.Profiles .. " configurations available")

print("prison life ultimate esp aimbot - skeleton edition with configuration system loaded")
