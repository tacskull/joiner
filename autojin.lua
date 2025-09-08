-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Configurações
local MinMS = 5000000 -- 5M/s padrão
local AutoJoinEnabled = false

-- Função para formatar dinheiro
local function formatMoney(num)
    return string.format("%.1fM", num / 1e6)
end

local function parseMoney(str)
    if not str then return 0 end
    local num, suffix = str:match("([%d%.]+)([MK]?)")
    num = tonumber(num) or 0
    if suffix=="M" then return num*1e6 end
    if suffix=="K" then return num*1e3 end
    return num
end

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoJoinUI"
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.4, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(60,0,90)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,40)
Title.Position = UDim2.new(0,0,0,0)
Title.BackgroundColor3 = Color3.fromRGB(80,0,120)
Title.Text = "ROOS AUTOJOINER 10M"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0,10)
TitleCorner.Parent = Title

-- Toggle ON/OFF
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -20, 0, 35)
Toggle.Position = UDim2.new(0,10,0,60)
Toggle.BackgroundColor3 = Color3.fromRGB(100,0,160)
Toggle.Text = "Auto Join: OFF"
Toggle.TextColor3 = Color3.fromRGB(255,100,100)
Toggle.Font = Enum.Font.GothamBold
Toggle.TextSize = 16
Toggle.Parent = MainFrame

Toggle.MouseButton1Click:Connect(function()
    AutoJoinEnabled = not AutoJoinEnabled
    Toggle.Text = "Auto Join: "..(AutoJoinEnabled and "ON" or "OFF")
    Toggle.TextColor3 = AutoJoinEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)

-- Min M/s
local MinLabel = Instance.new("TextLabel")
MinLabel.Size = UDim2.new(1,-20,0,25)
MinLabel.Position = UDim2.new(0,10,0,105)
MinLabel.BackgroundTransparency = 1
MinLabel.Text = "Min M/s: "..formatMoney(MinMS)
MinLabel.TextColor3 = Color3.fromRGB(255,255,255)
MinLabel.Font = Enum.Font.Gotham
MinLabel.TextSize = 14
MinLabel.Parent = MainFrame

local MinBox = Instance.new("TextBox")
MinBox.Size = UDim2.new(1,-20,0,25)
MinBox.Position = UDim2.new(0,10,0,130)
MinBox.BackgroundColor3 = Color3.fromRGB(80,0,120)
MinBox.Text = tostring(MinMS/1e6)
MinBox.TextColor3 = Color3.fromRGB(255,255,255)
MinBox.Font = Enum.Font.Gotham
MinBox.TextSize = 14
MinBox.ClearTextOnFocus = false
MinBox.Parent = MainFrame

MinBox.FocusLost:Connect(function()
    local val = tonumber(MinBox.Text)
    if val then
        MinMS = math.clamp(val*1e6, 1e6, 1e9)
        MinLabel.Text = "Min M/s: "..formatMoney(MinMS)
        MinBox.Text = tostring(MinMS/1e6)
    else
        MinBox.Text = tostring(MinMS/1e6)
    end
end)

-- Conecta WS
local WS_URL = "ws://5.255.97.147:6767/script"
local ws
if syn and syn.websocket then
    ws = syn.websocket.connect(WS_URL)
elseif WebSocket then
    ws = WebSocket.connect(WS_URL)
elseif http and http.websocket then
    ws = http.websocket.connect(WS_URL)
else
    warn("Executor não suporta WebSocket!")
    return
end

ws.OnMessage:Connect(function(msg)
    local ok,data = pcall(function() return HttpService:JSONDecode(msg) end)
    if not ok or type(data)~="table" then return end

    local server10m = data.all_data and data.all_data["10m"]
    if not server10m then return end

    local moneyStr = server10m.money_per_sec or "$0/s"
    local moneyVal = parseMoney(moneyStr)

    if AutoJoinEnabled and moneyVal >= MinMS then
        local placeId = tonumber(data.data.place_id or "109983668079237")
        local jobId = server10m.job_id_pc

        if placeId and jobId then
            print("[AutoJoin 10M] Entrando no servidor:", server10m.name, "|", moneyStr)
            TeleportService:TeleportToPlaceInstance(placeId, jobId, Players.LocalPlayer)
        else
            warn("[AutoJoin 10M] Dados inválidos para teleport:", placeId, jobId)
        end
    else
        print("[AutoJoin 10M] Ignorado:", moneyStr, "< Min "..formatMoney(MinMS))
    end
end)
