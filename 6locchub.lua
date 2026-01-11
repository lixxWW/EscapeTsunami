local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- =========================
-- UTILITY FUNCTIONS
-- =========================
local function getChar()
    return lp.Character or lp.CharacterAdded:Wait()
end

-- =========================
-- TELEPORT SYSTEM WITH TWEEN
-- =========================
local function smoothTeleport(targetCF, duration)
    local char = getChar()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    -- Smooth teleport usando TweenService
    local tweenInfo = TweenInfo.new(
        duration or 0.5, -- durata predefinita di 0.5 secondi
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCF})
    tween:Play()
    
    -- Aspetta che il tween finisca
    tween.Completed:Wait()
    
    return true
end

local function quickTeleport(targetCF)
    local char = getChar()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = targetCF
    return true
end

local SAFE_ZONE_CF = CFrame.new(138.0323639, 3.5332172, -32.5189972)
local SECRET_ZONE_CF = CFrame.new(2609.7604980, -2.4667714, 11.5024195)
local MAIN_ISLAND_CF = CFrame.new(0, 10, 0)

-- =========================
-- FLIGHT SYSTEM
-- =========================
local flying = false
local flySpeed = 50
local flyControl = {f = 0, b = 0, l = 0, r = 0}
local flyConnection
local flyBV, flyBG

local function startFly()
    if flying then return end
    flying = true
    
    local char = getChar()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Parent = hrp
    
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not flying then return end
        
        local cam = workspace.CurrentCamera
        local speed = flySpeed
        
        flyBG.CFrame = cam.CFrame
        
        local moveDir = Vector3.new(
            flyControl.r - flyControl.l,
            0,
            flyControl.f - flyControl.b
        )
        
        if moveDir:Dot(moveDir) > 0 then
            moveDir = moveDir.Unit
        end
        
        flyBV.Velocity = ((cam.CFrame.LookVector * (flyControl.f - flyControl.b)) + 
                         (cam.CFrame.RightVector * (flyControl.r - flyControl.l))) * speed
    end)
    
    hum.PlatformStand = true
end

local function stopFly()
    if not flying then return end
    flying = false
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    
    local char = getChar()
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.PlatformStand = false
    end
end

-- =========================
-- ENHANCED GOD MODE
-- =========================
local godMode = false
local godModeConnections = {}

local function enableGodMode()
    godMode = true
    local char = getChar()
    local hum = char:WaitForChild("Humanoid")
    
    hum.MaxHealth = math.huge
    hum.Health = math.huge
    
    -- Health monitoring
    table.insert(godModeConnections, hum:GetPropertyChangedSignal("Health"):Connect(function()
        if godMode then hum.Health = math.huge end
    end))
    
    table.insert(godModeConnections, hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if godMode then hum.MaxHealth = math.huge end
    end))
    
    -- Prevent death
    table.insert(godModeConnections, hum.Died:Connect(function()
        if godMode then
            hum.Health = math.huge
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end))
    
    -- Continuous health protection
    table.insert(godModeConnections, RunService.Heartbeat:Connect(function()
        if godMode and hum and hum.Parent then
            if hum.Health ~= math.huge then hum.Health = math.huge end
            if hum.MaxHealth ~= math.huge then hum.MaxHealth = math.huge end
        end
    end))
end

local function disableGodMode()
    godMode = false
    
    for _, conn in pairs(godModeConnections) do
        if conn then conn:Disconnect() end
    end
    godModeConnections = {}
    
    local char = getChar()
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.MaxHealth = 100
        hum.Health = 100
    end
end

-- =========================
-- ENHANCED NOCLIP
-- =========================
local noclipEnabled = false
local noclipConnection

local function enableNoclip()
    if noclipEnabled then return end
    noclipEnabled = true
    
    noclipConnection = RunService.Stepped:Connect(function()
        if noclipEnabled then
            local char = getChar()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function disableNoclip()
    noclipEnabled = false
    
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- =========================
-- BRAINROT ENHANCED SCANNER
-- =========================
local brainrotRarities = {
    Celestial = true,
    Secret = true,
    Cosmic = true,
    Mythical = true,
    Legendary = false,
    Epic = false,
    Rare = false,
    Uncommon = false,
    Common = false
}

local brainrotMutations = {
    Gold = true,
    Emerald = true,
    Blood = true,
    None = true
}

local autoTpBrainrotEnabled = false
local autoTpBrainrotLoop
local brainrotScanDelay = 0.1
local brainrotTeleportHeight = 5
local lastNotificationTime = 0
local NOTIFICATION_COOLDOWN = 5 -- secondi tra le notifiche

local function findNearestBrainrot()
    local activeBrainrots = workspace:FindFirstChild("ActiveBrainrots")
    if not activeBrainrots then 
        return nil, "No ActiveBrainrots folder found"
    end
    
    local char = getChar()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, "No HumanoidRootPart found" end
    
    local nearest = nil
    local nearestDistance = math.huge
    local totalFound = 0
    
    for rarity, enabled in pairs(brainrotRarities) do
        if enabled then
            local rarityFolder = activeBrainrots:FindFirstChild(rarity)
            if rarityFolder then
                for _, brainrot in pairs(rarityFolder:GetChildren()) do
                    if brainrot:IsA("Model") then
                        local mutation = brainrot:GetAttribute("Mutation") or "None"
                        
                        -- DEBUG: Stampiamo cosa troviamo
                        -- print("Found brainrot:", brainrot.Name, "Rarity:", rarity, "Mutation:", mutation)
                        
                        if brainrotMutations[mutation] == true then
                            local primaryPart = brainrot.PrimaryPart or brainrot:FindFirstChildWhichIsA("BasePart")
                            
                            if primaryPart then
                                local distance = (hrp.Position - primaryPart.Position).Magnitude
                                totalFound = totalFound + 1
                                
                                -- DEBUG
                                -- print(string.format("  ✓ Matches filters! Distance: %.0f studs", distance))
                                
                                if distance < nearestDistance then
                                    nearestDistance = distance
                                    nearest = {
                                        model = brainrot,
                                        position = primaryPart.CFrame,
                                        rarity = rarity,
                                        mutation = mutation,
                                        distance = distance
                                    }
                                end
                            else
                                -- print("  ✗ No primary part found")
                            end
                        else
                            -- print(string.format("  ✗ Mutation filter mismatch: %s (enabled: %s)", mutation, tostring(brainrotMutations[mutation])))
                        end
                    end
                end
            else
                -- print("No folder for rarity:", rarity)
            end
        end
    end
    
    -- DEBUG
    if totalFound == 0 then
        -- print("DEBUG: Total brainrots found matching filters: 0")
        -- print("Current filters - Rarities enabled:")
        for rarity, enabled in pairs(brainrotRarities) do
            if enabled then
                -- print("  - " .. rarity .. ": " .. tostring(enabled))
            end
        end
        -- print("Current filters - Mutations enabled:")
        for mutation, enabled in pairs(brainrotMutations) do
            -- print("  - " .. mutation .. ": " .. tostring(enabled))
        end
    else
        -- print(string.format("DEBUG: Found %d brainrots matching filters, nearest: %.0f studs", totalFound, nearestDistance))
    end
    
    return nearest, nearestDistance
end

local function teleportToBrainrot(brainrotInfo)
    if not brainrotInfo or not brainrotInfo.model.Parent then
        return false, "Brainrot no longer exists"
    end
    
    local targetCF = brainrotInfo.position + Vector3.new(0, brainrotTeleportHeight, 0)
    local distance = brainrotInfo.distance
    
    -- Calcola durata del tween in base alla distanza
    local tweenDuration = math.min(1, math.max(0.2, distance / 500)) -- Min 0.2s, Max 1s
    
    if distance > 50 then
        return smoothTeleport(targetCF, tweenDuration), "Success"
    else
        return quickTeleport(targetCF), "Success"
    end
end

local function startAutoTpBrainrot()
    if autoTpBrainrotEnabled then return end
    autoTpBrainrotEnabled = true
    
    autoTpBrainrotLoop = task.spawn(function()
        local lastTpTime = 0
        local TP_COOLDOWN = 2 -- secondi tra i teleport
        
        while autoTpBrainrotEnabled do
            local currentTime = tick()
            local nearestBrainrot, distance = findNearestBrainrot()
            
            if nearestBrainrot and distance > 20 and (currentTime - lastTpTime) > TP_COOLDOWN then
                local success, message = teleportToBrainrot(nearestBrainrot)
                
                if success then
                    lastTpTime = currentTime
                    
                    -- Notifica solo ogni 5 secondi o quando cambia target
                    if (currentTime - lastNotificationTime) > NOTIFICATION_COOLDOWN then
                        local mutationText = nearestBrainrot.mutation ~= "None" and " ["..nearestBrainrot.mutation.."]" or ""
                        Rayfield:Notify({
                            Title = "Auto TP",
                            Content = string.format("%s%s (%s) - %d studs", 
                                nearestBrainrot.model.Name, mutationText, nearestBrainrot.rarity, math.floor(distance)),
                            Duration = 2,
                        })
                        lastNotificationTime = currentTime
                    end
                end
            end
            
            task.wait(brainrotScanDelay)
        end
    end)
    
    Rayfield:Notify({
        Title = "Auto TP Brainrot",
        Content = "Activated! Searching for brainrots...",
        Duration = 3,
    })
end

local function stopAutoTpBrainrot()
    autoTpBrainrotEnabled = false
    if autoTpBrainrotLoop then
        task.cancel(autoTpBrainrotLoop)
        autoTpBrainrotLoop = nil
    end
    
    Rayfield:Notify({
        Title = "Auto TP Brainrot",
        Content = "Deactivated",
        Duration = 2,
    })
end

-- =========================
-- AUTO DELETE TSUNAMI
-- =========================
local autoDeleteTsunamiEnabled = false
local autoDeleteTsunamiConnection

local function startAutoDeleteTsunami()
    if autoDeleteTsunamiEnabled then return end
    autoDeleteTsunamiEnabled = true
    
    autoDeleteTsunamiConnection = RunService.Heartbeat:Connect(function()
        if autoDeleteTsunamiEnabled then
            pcall(function()
                local activeTsunamis = workspace:FindFirstChild("ActiveTsunamis")
                if activeTsunamis then
                    for _, tsunami in pairs(activeTsunamis:GetChildren()) do
                        if tsunami:IsA("Model") and tsunami.Name:match("^Wave%d+$") then
                            tsunami:Destroy()
                        end
                    end
                end
            end)
        end
    end)
end

local function stopAutoDeleteTsunami()
    autoDeleteTsunamiEnabled = false
    
    if autoDeleteTsunamiConnection then
        autoDeleteTsunamiConnection:Disconnect()
        autoDeleteTsunamiConnection = nil
    end
end

-- =========================
-- AUTO FARM FUNCTIONS
-- =========================
local autoCollectEnabled = false
local autoCollectLoop
local autoRebirthEnabled = false
local autoRebirthLoop
local autoUpgradeSpeedEnabled = false
local autoUpgradeSpeedLoop
local upgradeSpeedAmount = 10

local function startAutoCollect()
    if autoCollectEnabled then return end
    autoCollectEnabled = true
    
    autoCollectLoop = task.spawn(function()
        while autoCollectEnabled do
            pcall(function()
                for i = 1, 20 do
                    RS.RemoteEvents.CollectMoney:FireServer("Slot" .. i)
                end
            end)
            task.wait(2)
        end
    end)
end

local function stopAutoCollect()
    autoCollectEnabled = false
    if autoCollectLoop then
        task.cancel(autoCollectLoop)
        autoCollectLoop = nil
    end
end

local function startAutoRebirth()
    if autoRebirthEnabled then return end
    autoRebirthEnabled = true
    
    autoRebirthLoop = task.spawn(function()
        while autoRebirthEnabled do
            task.spawn(function()
                pcall(function()
                    RS.RemoteFunctions.Rebirth:InvokeServer()
                end)
            end)
            task.wait(1)
        end
    end)
end

local function stopAutoRebirth()
    autoRebirthEnabled = false
    if autoRebirthLoop then
        task.cancel(autoRebirthLoop)
        autoRebirthLoop = nil
    end
end

local function startAutoUpgradeSpeed()
    if autoUpgradeSpeedEnabled then return end
    autoUpgradeSpeedEnabled = true
    
    autoUpgradeSpeedLoop = task.spawn(function()
        while autoUpgradeSpeedEnabled do
            task.spawn(function()
                pcall(function()
                    RS.RemoteFunctions.UpgradeSpeed:InvokeServer(upgradeSpeedAmount)
                end)
            end)
            task.wait(0.5)
        end
    end)
end

local function stopAutoUpgradeSpeed()
    autoUpgradeSpeedEnabled = false
    if autoUpgradeSpeedLoop then
        task.cancel(autoUpgradeSpeedLoop)
        autoUpgradeSpeedLoop = nil
    end
end

-- =========================
-- CHARACTER AUTO-RESET
-- =========================
lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    
    if godMode then
        enableGodMode()
    end
    if noclipEnabled then
        enableNoclip()
    end
end)

-- =========================
-- GUI WINDOW
-- =========================
local Window = Rayfield:CreateWindow({
   Name = "🔥 6locc Hub | Escape Tsunami",
   LoadingTitle = "Loading Premium Hub...",
   LoadingSubtitle = "by y6locc",
   ConfigurationSaving = {Enabled = false},
   Discord = {Enabled = false},
   KeySystem = false,
})

-- =========================
-- TAB: PLAYER
-- =========================
local PlayerTab = Window:CreateTab("Player", "user")
PlayerTab:CreateSection("Character")

PlayerTab:CreateToggle({
   Name = "God Mode (Immortality)",
   CurrentValue = false,
   Flag = "ToggleGodMode",
   Callback = function(Value)
      if Value then
         enableGodMode()
      else
         disableGodMode()
      end
   end,
})

PlayerTab:CreateToggle({
   Name = "Noclip (Walk Through Walls)",
   CurrentValue = false,
   Flag = "ToggleNoclip",
   Callback = function(Value)
      if Value then
         enableNoclip()
      else
         disableNoclip()
      end
   end,
})

PlayerTab:CreateToggle({
   Name = "Flight",
   CurrentValue = false,
   Flag = "ToggleFly",
   Callback = function(Value)
      if Value then
         startFly()
      else
         stopFly()
      end
   end,
})

PlayerTab:CreateSlider({
   Name = "Flight Speed",
   Range = {10, 300},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 50,
   Flag = "sliderflyspeed",
   Callback = function(Value)
      flySpeed = Value
   end,
})

PlayerTab:CreateButton({
   Name = "Infinite Jump Toggle",
   Callback = function()
      _G.infinjump = not _G.infinjump
      if _G.infinjump then
         local m = lp:GetMouse()
         m.KeyDown:connect(function(k)
            if k:byte() == 32 then
               local humanoid = lp.Character:FindFirstChildOfClass('Humanoid')
               if humanoid then
                  humanoid:ChangeState('Jumping')
                  task.wait()
                  humanoid:ChangeState('Seated')
               end
            end
         end)
      end
   end,
})

-- =========================
-- TAB: AUTO FARM
-- =========================
local FarmTab = Window:CreateTab("Auto Farm", "zap")
FarmTab:CreateSection("Money")

FarmTab:CreateToggle({
   Name = "Auto Collect Money",
   CurrentValue = false,
   Flag = "ToggleAutoCollect",
   Callback = function(Value)
      if Value then
         startAutoCollect()
      else
         stopAutoCollect()
      end
   end,
})

FarmTab:CreateToggle({
   Name = "Auto Delete Tsunami",
   CurrentValue = false,
   Flag = "ToggleAutoDeleteTsunami",
   Callback = function(Value)
      if Value then
         startAutoDeleteTsunami()
      else
         stopAutoDeleteTsunami()
      end
   end,
})

FarmTab:CreateSection("Rebirth & Upgrades")

FarmTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "ToggleAutoRebirth",
   Callback = function(Value)
      if Value then
         startAutoRebirth()
      else
         stopAutoRebirth()
      end
   end,
})

FarmTab:CreateToggle({
   Name = "Auto Upgrade Speed",
   CurrentValue = false,
   Flag = "ToggleAutoUpgradeSpeed",
   Callback = function(Value)
      if Value then
         startAutoUpgradeSpeed()
      else
         stopAutoUpgradeSpeed()
      end
   end,
})

FarmTab:CreateSlider({
   Name = "Speed Upgrade Amount",
   Range = {1, 100},
   Increment = 1,
   Suffix = "Amount",
   CurrentValue = 10,
   Flag = "sliderUpgradeSpeed",
   Callback = function(Value)
      upgradeSpeedAmount = Value
   end,
})

-- =========================
-- TAB: BRAINROTS
-- =========================
local BrainrotTab = Window:CreateTab("Brainrots", "target")

BrainrotTab:CreateSection("Filters - Rarity")
for rarity, enabled in pairs(brainrotRarities) do
    BrainrotTab:CreateToggle({
        Name = rarity,
        CurrentValue = enabled,
        Flag = "Filter" .. rarity,
        Callback = function(Value)
            brainrotRarities[rarity] = Value
            -- Notifica quando cambi un filtro
            Rayfield:Notify({
                Title = "Filter Updated",
                Content = rarity .. ": " .. (Value and "Enabled" or "Disabled"),
                Duration = 2,
            })
        end,
    })
end

BrainrotTab:CreateSection("Filters - Mutation")
for mutation, enabled in pairs(brainrotMutations) do
    BrainrotTab:CreateToggle({
        Name = mutation,
        CurrentValue = enabled,
        Flag = "FilterMutation" .. mutation,
        Callback = function(Value)
            brainrotMutations[mutation] = Value
            -- Notifica quando cambi un filtro
            Rayfield:Notify({
                Title = "Filter Updated",
                Content = "Mutation " .. mutation .. ": " .. (Value and "Enabled" or "Disabled"),
                Duration = 2,
            })
        end,
    })
end

BrainrotTab:CreateSection("Auto Farm")

BrainrotTab:CreateToggle({
   Name = "Auto TP To Brainrot",
   CurrentValue = false,
   Flag = "ToggleAutoTpBrainrot",
   Callback = function(Value)
      if Value then
         startAutoTpBrainrot()
      else
         stopAutoTpBrainrot()
      end
   end,
})

BrainrotTab:CreateSlider({
   Name = "Teleport Height",
   Range = {0, 20},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = 5,
   Flag = "sliderTpHeight",
   Callback = function(Value)
      brainrotTeleportHeight = Value
   end,
})

BrainrotTab:CreateSlider({
   Name = "Scan Delay",
   Range = {0.05, 1},
   Increment = 0.05,
   Suffix = "Seconds",
   CurrentValue = 0.1,
   Flag = "sliderScanDelay",
   Callback = function(Value)
      brainrotScanDelay = Value
   end,
})

BrainrotTab:CreateButton({
   Name = "TP To Closest Brainrot",
   Callback = function()
      local nearestBrainrot, distance = findNearestBrainrot()
      
      if nearestBrainrot then
         -- Mostra informazioni di debug
         print("DEBUG INFO:")
         print("  Found brainrot:", nearestBrainrot.model.Name)
         print("  Rarity:", nearestBrainrot.rarity)
         print("  Mutation:", nearestBrainrot.mutation)
         print("  Distance:", math.floor(distance), "studs")
         
         local success, message = teleportToBrainrot(nearestBrainrot)
         
         if success then
            local mutationText = nearestBrainrot.mutation ~= "None" and " ["..nearestBrainrot.mutation.."]" or ""
            Rayfield:Notify({
               Title = "Teleport Success",
               Content = string.format("Teleported to %s%s (%s)", 
                  nearestBrainrot.model.Name, mutationText, nearestBrainrot.rarity),
               Duration = 3,
            })
         else
            Rayfield:Notify({
               Title = "Teleport Failed",
               Content = message,
               Duration = 3,
            })
         end
      else
         -- Mostra informazioni di debug sul perché non trova nulla
         print("DEBUG: No brainrots found. Checking workspace...")
         
         local activeBrainrots = workspace:FindFirstChild("ActiveBrainrots")
         if not activeBrainrots then
            print("  ✗ ActiveBrainrots folder not found in workspace")
         else
            print("  ✓ ActiveBrainrots folder found")
            for _, child in pairs(activeBrainrots:GetChildren()) do
                print("  - Folder:", child.Name)
            end
         end
         
         Rayfield:Notify({
            Title = "No Brainrots Found",
            Content = "Check console (F9) for debug info",
            Duration = 5,
         })
      end
   end,
})

-- Aggiungi un pulsante per refresh e debug
BrainrotTab:CreateButton({
   Name = "Refresh & Debug Info",
   Callback = function()
      print("=== BRAINROT DEBUG INFO ===")
      print("Current filters:")
      print("Rarities enabled:")
      for rarity, enabled in pairs(brainrotRarities) do
          if enabled then
              print("  - " .. rarity)
          end
      end
      print("Mutations enabled:")
      for mutation, enabled in pairs(brainrotMutations) do
          if enabled then
              print("  - " .. mutation)
          end
      end
      
      local nearestBrainrot, distance = findNearestBrainrot()
      if nearestBrainrot then
          print("Nearest brainrot found:")
          print("  Name:", nearestBrainrot.model.Name)
          print("  Rarity:", nearestBrainrot.rarity)
          print("  Mutation:", nearestBrainrot.mutation)
          print("  Distance:", math.floor(distance), "studs")
      else
          print("No brainrots found with current filters")
      end
      print("=== END DEBUG ===")
      
      Rayfield:Notify({
         Title = "Debug Info",
         Content = "Check console (F9) for detailed info",
         Duration = 3,
      })
   end,
})

-- =========================
-- TAB: TELEPORTS
-- =========================
local TeleportTab = Window:CreateTab("Teleports", "map-pin")
TeleportTab:CreateSection("Locations")

TeleportTab:CreateButton({
   Name = "Safe Zone",
   Callback = function()
      smoothTeleport(SAFE_ZONE_CF, 0.5)
   end,
})

TeleportTab:CreateButton({
   Name = "Secret Zone",
   Callback = function()
      smoothTeleport(SECRET_ZONE_CF, 0.5)
   end,
})

TeleportTab:CreateButton({
   Name = "Main Island",
   Callback = function()
      smoothTeleport(MAIN_ISLAND_CF, 0.5)
   end,
})

-- =========================
-- TAB: SETTINGS
-- =========================
local SettingsTab = Window:CreateTab("Settings", "settings")
SettingsTab:CreateSection("Configuration")

SettingsTab:CreateButton({
   Name = "Join Discord Server",
   Callback = function()
      if setclipboard then
         setclipboard("https://discord.gg/ccWsCMJWsX")
         Rayfield:Notify({
            Title = "Discord",
            Content = "Link copied to clipboard!",
            Duration = 3,
         })
      end
   end,
})

SettingsTab:CreateButton({
   Name = "Respawn Character",
   Callback = function()
      lp.Character:BreakJoints()
   end,
})

SettingsTab:CreateButton({
   Name = "Destroy GUI",
   Callback = function()
      Rayfield:Destroy()
   end,
})

-- =========================
-- FLIGHT CONTROLS
-- =========================
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        flyControl.f = 1
    elseif input.KeyCode == Enum.KeyCode.S then
        flyControl.b = 1
    elseif input.KeyCode == Enum.KeyCode.A then
        flyControl.l = 1
    elseif input.KeyCode == Enum.KeyCode.D then
        flyControl.r = 1
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        flyControl.f = 0
    elseif input.KeyCode == Enum.KeyCode.S then
        flyControl.b = 0
    elseif input.KeyCode == Enum.KeyCode.A then
        flyControl.l = 0
    elseif input.KeyCode == Enum.KeyCode.D then
        flyControl.r = 0
    end
end)

-- =========================
-- INITIALIZATION
-- =========================
Rayfield:Notify({
   Title = "6locc Hub Loaded",
   Content = "Auto TP: None mutation is now enabled by default",
   Duration = 5,
})

print("6locc Hub - Escape Tsunami Loaded Successfully!")
print("Note: None mutation filter is now ENABLED by default")
