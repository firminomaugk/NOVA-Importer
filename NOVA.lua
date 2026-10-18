
-- NOVA RBXM IMPORTER V1
-- GUI + file scanner prototype
-- Delta / Roblox Studio Lite
-- Catatan: API file dan loader RBXM perlu disesuaikan
-- jika tidak tersedia pada executor.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- Hapus GUI lama jika script dijalankan ulang
pcall(function()
    CoreGui:FindFirstChild("NOVA_RBXM_IMPORTER"):Destroy()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "NOVA_RBXM_IMPORTER"
gui.ResetOnSpawn = false

pcall(function()
    gui.Parent = CoreGui
end)

if not gui.Parent then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local cyan = Color3.fromRGB(0, 213, 255)
local dark = Color3.fromRGB(14, 19, 29)
local panel = Color3.fromRGB(24, 32, 46)
local muted = Color3.fromRGB(145, 161, 180)
local white = Color3.fromRGB(245, 250, 255)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(360, 430),
    Position = UDim2.new(0.5, -180, 0.5, -215),
    BackgroundColor3 = dark,
    BorderSizePixel = 0
}, gui)

make("UICorner", {CornerRadius = UDim.new(0, 14)}, main)
make("UIStroke", {Color = cyan, Thickness = 1.3, Transparency = 0.25}, main)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundColor3 = panel,
    BorderSizePixel = 0
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 14)}, header)

make("TextLabel", {
    Position = UDim2.fromOffset(15, 8),
    Size = UDim2.new(1, -75, 0, 27),
    BackgroundTransparency = 1,
    Text = "NOVA IMPORTER",
    TextColor3 = cyan,
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

make("TextLabel", {
    Position = UDim2.fromOffset(16, 35),
    Size = UDim2.new(1, -70, 0, 18),
    BackgroundTransparency = 1,
    Text = "RBXM / RBXL  •  MOBILE",
    TextColor3 = muted,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local close = make("TextButton", {
    Position = UDim2.new(1, -42, 0, 13),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = Color3.fromRGB(50, 61, 78),
    Text = "—",
    TextColor3 = white,
    Font = Enum.Font.GothamBold,
    TextSize = 18
}, header)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, close)

local status = make("TextLabel", {
    Position = UDim2.fromOffset(14, 72),
    Size = UDim2.new(1, -28, 0, 22),
    BackgroundTransparency = 1,
    Text = "Folder: Storage/Delta/Workspace",
    TextColor3 = muted,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
}, main)

local search = make("TextBox", {
    Position = UDim2.fromOffset(14, 101),
    Size = UDim2.new(1, -28, 0, 36),
    BackgroundColor3 = panel,
    TextColor3 = white,
    PlaceholderColor3 = muted,
    PlaceholderText = "Cari file...",
    Text = "",
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    TextSize = 12
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, search)

local tabs = make("Frame", {
    Position = UDim2.fromOffset(14, 146),
    Size = UDim2.new(1, -28, 0, 32),
    BackgroundTransparency = 1
}, main)

local currentTab = "ALL"
local tabButtons = {}

for i, name in ipairs({"ALL", "RBXM", "RBXL"}) do
    local b = make("TextButton", {
        Position = UDim2.new((i-1)/3, 0, 0, 0),
        Size = UDim2.new(1/3, -4, 1, 0),
        BackgroundColor3 = name == currentTab and cyan or panel,
        Text = name,
        TextColor3 = name == currentTab and dark or white,
        Font = Enum.Font.GothamBold,
        TextSize = 11
    }, tabs)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    tabButtons[name] = b
end

local list = make("ScrollingFrame", {
    Position = UDim2.fromOffset(14, 188),
    Size = UDim2.new(1, -28, 1, -246),
    BackgroundColor3 = Color3.fromRGB(18, 25, 37),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = cyan,
    CanvasSize = UDim2.new(0, 0, 0, 0)
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 9)}, list)

local layout = make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder
}, list)

local refresh = make("TextButton", {
    Position = UDim2.new(0, 14, 1, -48),
    Size = UDim2.new(1, -28, 0, 34),
    BackgroundColor3 = cyan,
    Text = "SCAN FILES",
    TextColor3 = dark,
    Font = Enum.Font.GothamBold,
    TextSize = 12
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, refresh)

local floating = make("TextButton", {
    Position = UDim2.new(0, 18, 0.5, -25),
    Size = UDim2.fromOffset(52, 52),
    BackgroundColor3 = dark,
    Text = "N",
    TextColor3 = cyan,
    Font = Enum.Font.GothamBlack,
    TextSize = 23,
    Visible = false
}, gui)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, floating)
make("UIStroke", {Color = cyan, Thickness = 2}, floating)

close.MouseButton1Click:Connect(function()
    main.Visible = false
    floating.Visible = true
end)

floating.MouseButton1Click:Connect(function()
    main.Visible = true
    floating.Visible = false
end)

local function clearRows()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function addRow(fileName, fileType)
    local row = make("Frame", {
        Size = UDim2.new(1, -8, 0, 66),
        BackgroundColor3 = panel,
        BorderSizePixel = 0
    }, list)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, row)

    make("TextLabel", {
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -100, 0, 35),
        BackgroundTransparency = 1,
        Text = fileName,
        TextColor3 = white,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    make("TextLabel", {
        Position = UDim2.fromOffset(10, 43),
        Size = UDim2.fromOffset(55, 15),
        BackgroundTransparency = 1,
        Text = fileType,
        TextColor3 = cyan,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local import = make("TextButton", {
        Position = UDim2.new(1, -76, 0.5, -14),
        Size = UDim2.fromOffset(66, 28),
        BackgroundColor3 = Color3.fromRGB(0, 113, 142),
        Text = "IMPORT",
        TextColor3 = white,
        Font = Enum.Font.GothamBold,
        TextSize = 9
    }, row)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, import)

    import.MouseButton1Click:Connect(function()
        status.Text = "Import belum terhubung: " .. fileName
        status.TextColor3 = Color3.fromRGB(255, 194, 100)
    end)
end

local function scan()
    clearRows()
    status.Text = "Mencoba membaca daftar file..."
    local found = {}

    -- Placeholder: fungsi file API belum tentu tersedia di Delta.
    local ok, files = pcall(function()
        return listfiles("Storage/Delta/Workspace")
    end)

    if ok and type(files) == "table" then
        for _, path in ipairs(files) do
            local name = tostring(path):match("[^/\\]+$") or tostring(path)
            local ext = name:lower():match("%.([%w]+)$")
            local kind = ext == "rbxm" and "RBXM"
                or ext == "rbxl" and "RBXL"
                or ext == "rbxlx" and "RBXL"
                or nil

            if kind then
                table.insert(found, {name = name, kind = kind, path = path})
            end
        end
    end

    local shown = 0
    for _, file in ipairs(found) do
        local matchesTab = currentTab == "ALL" or currentTab == file.kind
        local matchesSearch = file.name:lower():find(search.Text:lower(), 1, true)

        if matchesTab and matchesSearch then
            addRow(file.name, file.kind)
            shown += 1
        end
    end

    if shown == 0 then
        addRow("Belum ada file terbaca", "INFO")
        status.Text = ok and "0 file ditemukan" or
            "API listfiles tidak tersedia / folder tidak terbaca"
    else
        status.Text = tostring(shown) .. " file ditemukan"
    end

    task.defer(function()
        list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)
end

for name, b in pairs(tabButtons) do
    b.MouseButton1Click:Connect(function()
        currentTab = name
        for tabName, button in pairs(tabButtons) do
            button.BackgroundColor3 = tabName == name and cyan or panel
            button.TextColor3 = tabName == name and dark or white
        end
        scan()
    end)
end

search:GetPropertyChangedSignal("Text"):Connect(scan)
refresh.MouseButton1Click:Connect(scan)

-- Drag panel menggunakan sentuhan atau mouse
local UserInputService = game:GetService("UserInputService")
local dragging, dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

scan()
