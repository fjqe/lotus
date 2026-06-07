if _G.LotusAutoGenRunning then return end
_G.LotusAutoGenRunning = true

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

local Config = {
    MaxPuzzles = 15,             -- Number of puzzle
    PromptDelay = 0.05,          -- Delay of proximity prompt or shii
    ActionDelay = 0.15,          -- RE delay
    TeleportOffset = Vector3.new(0, 0, -2) -- ofset shii of da center
}

local puzzlesCompleted = 0
local automationEnabled = true
local scriptUrl = "https://raw.githubusercontent.com/fjqe/lotus/refs/heads/main/autogenlotus.lua"

local function armTeleportQueue()
    local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport)
    if queueFunction then
        local payload = string.format([[
            task.wait(4) -- Safe buffer allowing local character instances and workspace files to load
            pcall(function()
                loadstring(game:HttpGet("%s"))()
            end)
        ]], scriptUrl)
        
        pcall(function()
            queueFunction(payload)
        end)
    end
end

armTeleportQueue()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LotusAutomationUI"
ScreenGui.ResetOnSpawn = false

local successGui, errGui = pcall(function() ScreenGui.Parent = CoreGui end)
if not successGui then ScreenGui.Parent = lp:WaitForChild("PlayerGui") end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 130)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 33) 
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UIBorder = Instance.new("UIStroke")
UIBorder.Color = Color3.fromRGB(50, 50, 55)
UIBorder.Thickness = 1
UIBorder.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = " > lotus // autogen [freemium]"
TitleLabel.TextColor3 = Color3.fromRGB(180, 180, 185)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "gens: 0 / " .. tostring(Config.MaxPuzzles)
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 145)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, -20, 0, 35)
ToggleButton.Position = UDim2.new(0, 10, 0, 75)
ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "active"
ToggleButton.TextColor3 = Color3.fromRGB(100, 220, 140) 
ToggleButton.TextSize = 12
ToggleButton.Font = Enum.Font.Code
ToggleButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 4)
ButtonCorner.Parent = ToggleButton

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Color = Color3.fromRGB(60, 60, 65)
ButtonStroke.Thickness = 1
ButtonStroke.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    automationEnabled = not automationEnabled
    if automationEnabled then
        ToggleButton.Text = "active"
        ToggleButton.TextColor3 = Color3.fromRGB(100, 220, 140)
    else
        ToggleButton.Text = "disabled"
        ToggleButton.TextColor3 = Color3.fromRGB(220, 100, 100)
    end
end)

local function updateUI()
    StatusLabel.Text = "Puzzles: " .. tostring(puzzlesCompleted) .. " / " .. tostring(Config.MaxPuzzles)
end

local function initiateServerRotation()
    StatusLabel.Text = "Finding new server instance..."
    StatusLabel.TextColor3 = Color3.fromRGB(230, 180, 80)
    print("[Automation]: Target met. Executing public instance server hop...")
    
    local serverListUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    
    task.spawn(function()
        while true do
            local success, rawData = pcall(function()
                return game:HttpGet(serverListUrl)
            end)
            
            if success and rawData then
                local decodeSuccess, decoded = pcall(function()
                    return HttpService:JSONDecode(rawData)
                end)
                
                if decodeSuccess and decoded and decoded.data then
                    for _, server in ipairs(decoded.data) do
                        if server.id and server.id ~= game.JobId and tonumber(server.playing) < tonumber(server.maxPlayers) then
                            print("[Automation]: Found distinct match! Transferring to instance: " .. tostring(server.id))
                            
                            armTeleportQueue()
                            
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, lp)
                            end)
                            task.wait(2)
                        end
                    end
                end
            end
            
            armTeleportQueue()
            pcall(function()
                TeleportService:Teleport(game.PlaceId, lp)
            end)
            task.wait(5)
        end
    end)
end

task.spawn(function()
    while puzzlesCompleted < Config.MaxPuzzles do
        if automationEnabled then
            local mapFolder = Workspace:FindFirstChild("Map") 
                and Workspace.Map:FindFirstChild("Ingame") 
                and Workspace.Map.Ingame:FindFirstChild("Map")
                
            if mapFolder then
                for _, genNode in ipairs(mapFolder:GetChildren()) do
                    if puzzlesCompleted >= Config.MaxPuzzles or not automationEnabled then break end
                    
                    if genNode.Name:match("Generator") then
                        local progressAttr = genNode:GetAttribute("Progress")
                        local progressInstance = genNode:FindFirstChild("Progress")
                        local currentProgress = progressAttr or (progressInstance and progressInstance.Value) or 0
                        
                        if currentProgress < 100 then
                            local positions = genNode:FindFirstChild("Positions")
                            local centerNode = positions and positions:FindFirstChild("Center")
                            local char = lp.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            
                            if centerNode and hrp then
                                hrp.CFrame = centerNode.CFrame * CFrame.new(Config.TeleportOffset)
                                task.wait(0.12)
                                
                                for _, object in ipairs(genNode:GetDescendants()) do
                                    if object:IsA("ProximityPrompt") then
                                        if Config.PromptDelay > 0 then
                                            task.wait(Config.PromptDelay)
                                        end
                                        if typeof(fireproximityprompt) == "function" then
                                            fireproximityprompt(object)
                                        end
                                    end
                                end
                                
                                local remoteEvent = genNode:FindFirstChild("Remotes") and genNode.Remotes:FindFirstChild("RE")
                                if remoteEvent and remoteEvent:IsA("RemoteEvent") then
                                    remoteEvent:FireServer()
                                    puzzlesCompleted = puzzlesCompleted + 1
                                    updateUI()
                                    print("completed: (" .. tostring(puzzlesCompleted) .. "/" .. tostring(Config.MaxPuzzles) .. ")")
                                end
                                
                                task.wait(Config.ActionDelay)
                            end
                        end
                    end
                end
            else
                task.wait(1)
            end
        end
        task.wait(0.5)
    end
    
    initiateServerRotation()
end)
