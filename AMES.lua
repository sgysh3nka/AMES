local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local roles = {}

local Murder, Sheriff, Hero
local characterConnections = {}

local playerGui = game:GetService("CoreGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DragButtonGui"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local textButton = Instance.new("TextButton")
textButton.Name = "HighlightButton"
textButton.Size = UDim2.new(0, 200, 0, 50)
textButton.Position = UDim2.new(0.5, -100, 0.1, 0)
textButton.Text = "ESP: Off"
textButton.TextScaled = true
textButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
textButton.TextColor3 = Color3.new(1, 1, 1)
textButton.Parent = screenGui

local function setupCharacterListeners(player)
    if characterConnections[player] then
        characterConnections[player]:Disconnect()
    end
    
    characterConnections[player] = player.CharacterAdded:Connect(function(character)
        if isHighlightActive then
            character:WaitForChild("Humanoid")
            if not character:FindFirstChild("Highlight") then
                Instance.new("Highlight", character)
            end
            UpdateHighlights()
        end
    end)
end

function CreateHighlight()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if player.Character then
                player.Character:WaitForChild("Humanoid")
                if not player.Character:FindFirstChild("Highlight") then
                    Instance.new("Highlight", player.Character)
                end
            end
            setupCharacterListeners(player)
        end
    end
end

function DeleteHighlight()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("Highlight")
            if highlight then
                highlight:Destroy()
            end
        end
        if characterConnections[player] then
            characterConnections[player]:Disconnect()
            characterConnections[player] = nil
        end
    end
end

function UpdateHighlights()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("Highlight") then
            local Highlight = player.Character:FindFirstChild("Highlight")
            if player.Name == Sheriff and IsAlive(player) then
                Highlight.FillColor = Color3.fromRGB(0, 0, 255)
            elseif player.Name == Murder and IsAlive(player) then
                Highlight.FillColor = Color3.fromRGB(255, 0, 0)
            elseif player.Name == Hero and IsAlive(player) and not IsAlive(game.Players[Sheriff]) then
                Highlight.FillColor = Color3.fromRGB(255, 250, 0)
            else
                Highlight.FillColor = Color3.fromRGB(0, 255, 0)
            end
        end
    end
end

function IsAlive(player)
    for name, data in pairs(roles) do
        if player.Name == name then
            return not data.Killed and not data.Dead
        end
    end
    return false
end

LP.CharacterAdded:Connect(function(character)
    if isHighlightActive then
        CreateHighlight()
        UpdateHighlights()
    end
end)

Players.PlayerAdded:Connect(function(player)
    if isHighlightActive then
        setupCharacterListeners(player)
    end
end)

RunService.Heartbeat:Connect(function()
    roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    for name, data in pairs(roles) do
        if data.Role == "Murderer" then
            Murder = name
        elseif data.Role == 'Sheriff' then
            Sheriff = name
        elseif data.Role == 'Hero' then
            Hero = name
        end
    end
end)

local dragging = false
local dragInput, dragStart, startPos

local isHighlightActive = false
local updateConnection = nil

local function updateInput(input)
    if dragging then
        local delta = input.Position - dragStart
        textButton.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end

textButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = textButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

textButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

textButton.MouseButton1Click:Connect(function()
    if not isHighlightActive then
        isHighlightActive = true
        textButton.Text = "ESP: On"
        textButton.BackgroundColor3 = Color3.fromRGB(215, 0, 0)
        CreateHighlight()
    
        if updateConnection then
            updateConnection:Disconnect()
        end
        
        updateConnection = RunService.Heartbeat:Connect(function()
            UpdateHighlights()
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                setupCharacterListeners(player)
            end
        end
    else
        isHighlightActive = false
        textButton.Text = "ESP: Off"
        textButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
        
        DeleteHighlight()
    end
end)
