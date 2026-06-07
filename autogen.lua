-- Guard clause to prevent duplicate execution loops if re-injected
if _G.LotusAutoGenRunning then return end
_G.LotusAutoGenRunning = true

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

---------------------------------------------------------
-- [ CONFIGURATION ]
---------------------------------------------------------
local Config = {
    MaxPuzzles = 15,             -- Number of puzzles to complete before hopping
    PromptDelay = 0.05,          -- Delay before interacting with proximity prompts
    ActionDelay = 0.15,          -- Delay after firing the remote event
    TeleportOffset = Vector3.new(0, 0, -2) -- Adjustment offset relative to generator center
}

local puzzlesCompleted = 0
local automationEnabled = true

---------------------------------------------------------
-- [ TELEPORT AUTO-RUN REGISTRATION ]
---------------------------------------------------------
local function armTeleportQueue()
    local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport)
    if queueFunction then
        -- This string represents the exact execution sequence carried over server boundaries
        local payload = [[
            task.wait(3) -- Safety buffer to ensure data models load fully
            pcall(function()
                -- If you host your script online (e.g. GitHub raw), replace the below fallback with your loadstring.
                -- Otherwise, this payload can safely invoke your primary loader block.
                print("[Lotus]: Auto-reloading script execution loop...")
            end)
        ]]
        
        -- Alternatively, to pass this entire source code directly through serialization without an external URL:
        -- We can read from a local file or pass the code layout structure cleanly.
        pcall(function()
            queueFunction(payload)
        end)
    end
end

-- Pre-arm the queue immediately upon script startup
armTeleportQueue()

---------------------------------------------------------
-- [ MINIMALIST CODE-EDITOR STYLE UI ]
---------------------------------------------------------
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

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "lotus // autogen freemium"
TitleLabel.TextColor3 = Color3.fromRGB(180, 180, 185)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Puzzles: 0 / " .. tostring(Config.MaxPuzzles)
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 145)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, -20, 0, 35)
ToggleButton.Position = UDim2.new(0, 10, 0, 75)
ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "STATUS: ACTIVE"
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
        ToggleButton.Text = "STATUS: ACTIVE"
        ToggleButton.TextColor3 = Color3.fromRGB(100, 220, 140)
    else
        ToggleButton.Text = "STATUS: DISABLED"
        ToggleButton.TextColor3 = Color3.fromRGB(220, 100, 100)
    end
end)

local function updateUI()
    StatusLabel.Text = "Puzzles: " .. tostring(puzzlesCompleted) .. " / " .. tostring(Config.MaxPuzzles)
end

---------------------------------------------------------
-- [ ADVANCED SERVER HOPPER ]
---------------------------------------------------------
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
                            print("[Automation]: Found match! Transferring to instance: " .. tostring(server.id))
                            
                            -- Ensure the payload re-arms right before execution of the connection switch
                            armTeleportQueue()
                            
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, lp)
                            end)
                            task.wait(2)
                        end
                    end
                end
            end
            
            -- Fallback structural cycle if specific instance requests time out
            armTeleportQueue()
            pcall(function()
                TeleportService:Teleport(game.PlaceId, lp)
            end)
            task.wait(5)
        end
    end)
end

---------------------------------------------------------
-- [ AUTOMATION EXECUTION LOOP ]
---------------------------------------------------------
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
                                    print("[Automation]: Puzzle steps completed: (" .. tostring(puzzlesCompleted) .. "/" .. tostring(Config.MaxPuzzles) .. ")")
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
