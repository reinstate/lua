local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "⚡ NEXUS AIO",
    LoadingTitle = "NEXUS AIO Loading...",
    LoadingSubtitle = "Premium All-In-One Hub",
    ConfigurationSaving = {Enabled = true, FolderName = "NexusAIO"},
    KeySystem = false,
    Theme = {
        BackgroundColor = Color3.fromRGB(10, 10, 10),
        SectionBackgroundColor = Color3.fromRGB(20, 20, 20)
    }
})

local MainTab = Window:CreateTab("🎮 Main Features", 6035057668)
local SettingsTab = Window:CreateTab("⚙️ Settings", 7733765391)

local Status = MainTab:CreateLabel("🟢 Status: Ready")

-- Configuration
local Config = {
    Keybinds = {
        ClickTP = Enum.KeyCode.C,
        Fly = Enum.KeyCode.F,
        Noclip = Enum.KeyCode.V
    },
    Defaults = {
        WalkSpeed = 100,
        JumpPower = 150,
        FlySpeed = 50
    }
}

-- State Management
local States = {
    ClickFollow = {Active = false, Target = nil},
    TouchFling = {Active = false},
    ServerFling = {Active = false},
    ClickTP = {Active = false},
    Fly = {Active = false, BodyVelocity = nil, BodyGyro = nil},
    WalkSpeed = {Active = false, Value = Config.Defaults.WalkSpeed},
    JumpPower = {Active = false, Value = Config.Defaults.JumpPower},
    Noclip = {Active = false}
}

local Connections = {}

-- Core Functions
local function ApplyCharacterModifiers()
    task.wait(2)
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if States.WalkSpeed.Active then hum.WalkSpeed = States.WalkSpeed.Value end
    if States.JumpPower.Active then hum.JumpPower = States.JumpPower.Value end
end

lp.CharacterAdded:Connect(ApplyCharacterModifiers)

-- Fly System
local function StartFlying()
    if States.Fly.Active then return end
    States.Fly.Active = true
    
    local character = lp.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Create fly controllers
    States.Fly.BodyVelocity = Instance.new("BodyVelocity")
    States.Fly.BodyGyro = Instance.new("BodyGyro")
    
    States.Fly.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    States.Fly.BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    States.Fly.BodyVelocity.Parent = root
    
    States.Fly.BodyGyro.D = 50
    States.Fly.BodyGyro.P = 1000
    States.Fly.BodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    States.Fly.BodyGyro.CFrame = root.CFrame
    States.Fly.BodyGyro.Parent = root
    
    Status:Set("🚀 Fly: ACTIVE (F to toggle)")
    
    local flyConnection
    flyConnection = RunService.Heartbeat:Connect(function()
        if not States.Fly.Active or not character or not root then 
            flyConnection:Disconnect()
            return 
        end
        
        local cam = workspace.CurrentCamera
        local moveDirection = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        if moveDirection.Magnitude > 0 then
            States.Fly.BodyVelocity.Velocity = moveDirection.Unit * Config.Defaults.FlySpeed
        else
            States.Fly.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        States.Fly.BodyGyro.CFrame = cam.CFrame
    end)
    
    table.insert(Connections, flyConnection)
end

local function StopFlying()
    States.Fly.Active = false
    if States.Fly.BodyVelocity then
        States.Fly.BodyVelocity:Destroy()
        States.Fly.BodyVelocity = nil
    end
    if States.Fly.BodyGyro then
        States.Fly.BodyGyro:Destroy()
        States.Fly.BodyGyro = nil
    end
    Status:Set("✈️ Fly: OFF")
end

-- Touch Fling System
local function StartTouchFling()
    if States.TouchFling.Active then return end
    States.TouchFling.Active = true
    
    local function fling()
        while States.TouchFling.Active do
            RunService.Heartbeat:Wait()
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vel = hrp.Velocity
                hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
            end
        end
    end
    
    task.spawn(fling)
    Status:Set("💥 Touch Fling: ACTIVE")
end

local function StopTouchFling()
    States.TouchFling.Active = false
    Status:Set("💥 Touch Fling: OFF")
end

-- Hidden Fling System
local function StartHiddenFling()
    if States.ServerFling.Active then return end
    States.ServerFling.Active = true
    
    task.spawn(function()
        while States.ServerFling.Active do
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local old = hrp.Velocity
                hrp.Velocity = old * 30000 + Vector3.new(0, 35000, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = old
            end
            task.wait()
        end
    end)
end

local function StopHiddenFling()
    States.ServerFling.Active = false
end

-- Keybind System
local function SetupKeybinds()
    -- Fly Toggle
    local flyBind = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Config.Keybinds.Fly then
            if States.Fly.Active then
                StopFlying()
            else
                StartFlying()
            end
        end
    end)
    table.insert(Connections, flyBind)
    
    -- Noclip Toggle
    local noclipBind = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Config.Keybinds.Noclip then
            States.Noclip.Active = not States.Noclip.Active
            if States.Noclip.Active then
                local conn = RunService.Stepped:Connect(function()
                    if lp.Character then
                        for _, part in ipairs(lp.Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
                table.insert(Connections, conn)
                Status:Set("👻 Noclip: ACTIVE (V to toggle)")
            else
                Status:Set("👻 Noclip: OFF")
            end
        end
    end)
    table.insert(Connections, noclipBind)
end

-- UI Elements
MainTab:CreateSection("🎯 Movement")

MainTab:CreateToggle({
    Name = "🚀 Fly (Press F)",
    CurrentValue = false,
    Callback = function(v)
        if v then
            StartFlying()
        else
            StopFlying()
        end
    end
})

MainTab:CreateToggle({
    Name = "📡 Click TP (Press C)",
    CurrentValue = false,
    Callback = function(v)
        States.ClickTP.Active = v
        if v then
            Status:Set("📡 Click TP: ACTIVE (C to teleport)")
            local connection = UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                if not States.ClickTP.Active then return end
                if input.KeyCode == Config.Keybinds.ClickTP then
                    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    local cam = workspace.CurrentCamera
                    if root and cam then
                        local pos = mouse.Hit.Position + Vector3.new(0, 4, 0)
                        root.CFrame = CFrame.new(pos, pos + cam.CFrame.LookVector)
                        Status:Set("✨ Teleported!")
                    end
                end
            end)
            table.insert(Connections, connection)
        else
            Status:Set("📡 Click TP: OFF")
        end
    end
})

MainTab:CreateToggle({
    Name = "👥 Click Follow",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Status:Set("👥 Click Follow: ACTIVE - Click a player")
            local followConnection = RunService.Heartbeat:Connect(function()
                if States.ClickFollow.Target and States.ClickFollow.Target.Character then
                    local myhrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    local tgt = States.ClickFollow.Target.Character:FindFirstChild("HumanoidRootPart")
                    if myhrp and tgt then
                        myhrp.CFrame = tgt.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end)
            table.insert(Connections, followConnection)

            local clickConnection = mouse.Button1Down:Connect(function()
                local target = mouse.Target
                if target then
                    local model = target:FindFirstAncestorWhichIsA("Model")
                    local player = Players:GetPlayerFromCharacter(model)
                    if player and player ~= lp then
                        States.ClickFollow.Target = player
                        Status:Set("🎯 Locked: " .. player.DisplayName)
                    end
                end
            end)
            table.insert(Connections, clickConnection)
        else
            States.ClickFollow.Target = nil
            Status:Set("👥 Click Follow: OFF")
        end
    end
})

MainTab:CreateSection("💥 Combat")

MainTab:CreateToggle({
    Name = "💥 Touch Fling",
    CurrentValue = false,
    Callback = function(v)
        if v then
            StartTouchFling()
        else
            StopTouchFling()
        end
    end
})

MainTab:CreateToggle({
    Name = "🌐 Server Fling",
    CurrentValue = false,
    Callback = function(v)
        States.ServerFling.Active = v
        if v then
            Status:Set("🌐 Server Fling: ACTIVE")
            StartHiddenFling()
            task.spawn(function()
                while States.ServerFling.Active do
                    for _, player in Players:GetPlayers() do
                        if not States.ServerFling.Active or player == lp then continue end
                        local targetHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP and myHRP then
                            Status:Set("🌀 Flinging: " .. player.DisplayName)
                            for i = 1, 40 do
                                if not States.ServerFling.Active then break end
                                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
                                task.wait(0.1)
                            end
                        end
                    end
                end
                StopHiddenFling()
            end)
        else
            StopHiddenFling()
            Status:Set("🌐 Server Fling: OFF")
        end
    end
})

MainTab:CreateSection("⚡ Stats")

local speedSlider = MainTab:CreateSlider({
    Name = "🏃‍♂️ Walk Speed",
    Range = {16, 500},
    Increment = 5,
    CurrentValue = Config.Defaults.WalkSpeed,
    Callback = function(v)
        States.WalkSpeed.Value = v
        if States.WalkSpeed.Active then
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
            Status:Set("🏃‍♂️ Speed: " .. v)
        end
    end
})

MainTab:CreateToggle({
    Name = "🏃‍♂️ Enable Walk Speed",
    CurrentValue = false,
    Callback = function(v)
        States.WalkSpeed.Active = v
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum.WalkSpeed = v and States.WalkSpeed.Value or 16 
            Status:Set(v and ("🏃‍♂️ Speed: " .. States.WalkSpeed.Value) or "🏃‍♂️ Speed: OFF")
        end
    end
})

local jumpSlider = MainTab:CreateSlider({
    Name = "🦘 Jump Power",
    Range = {50, 500},
    Increment = 5,
    CurrentValue = Config.Defaults.JumpPower,
    Callback = function(v)
        States.JumpPower.Value = v
        if States.JumpPower.Active then
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
            Status:Set("🦘 Jump: " .. v)
        end
    end
})

MainTab:CreateToggle({
    Name = "🦘 Enable Jump Power",
    CurrentValue = false,
    Callback = function(v)
        States.JumpPower.Active = v
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum.JumpPower = v and States.JumpPower.Value or 50 
            Status:Set(v and ("🦘 Jump: " .. States.JumpPower.Value) or "🦘 Jump: OFF")
        end
    end
})

-- Settings Tab
SettingsTab:CreateSection("🎹 Keybinds")

SettingsTab:CreateKeybind({
    Name = "Click TP Key",
    CurrentKeybind = Config.Keybinds.ClickTP,
    Callback = function(Key)
        Config.Keybinds.ClickTP = Key
        Status:Set("🔑 Click TP keybind updated")
    end
})

SettingsTab:CreateKeybind({
    Name = "Fly Key",
    CurrentKeybind = Config.Keybinds.Fly,
    Callback = function(Key)
        Config.Keybinds.Fly = Key
        Status:Set("🔑 Fly keybind updated")
    end
})

SettingsTab:CreateKeybind({
    Name = "Noclip Key",
    CurrentKeybind = Config.Keybinds.Noclip,
    Callback = function(Key)
        Config.Keybinds.Noclip = Key
        Status:Set("🔑 Noclip keybind updated")
    end
})

-- Initialize
SetupKeybinds()

Rayfield:Notify({
    Title = "⚡ NEXUS AIO LOADED",
    Content = "All features activated!\n• Fly (F) • Click TP (C) • Noclip (V)\n• Touch Fling • Server Fling • Stats",
    Duration = 6,
    Image = 6035057668
})

Status:Set("🎉 NEXUS AIO Ready! Check keybinds in Settings.")

print("⚡ NEXUS AIO - Fully Loaded & Optimized")
