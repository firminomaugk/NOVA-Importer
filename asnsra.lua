--[[ RBXM Importer Dashboard
     Baca file .rbxm / .rbxl dari folder Delta/Workspace
     Layout: Dashboard (Overview / Assets / Settings) + tombol toggle bulat
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- ================= SETTINGS =================
local Settings = {
    ParentTo = "Workspace",   -- Workspace / ReplicatedStorage
    MoveToPlayer = true,      -- pindahkan hasil import ke posisi karakter
}

-- ================= GUI PARENT =================
local function getGuiParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()
local OLD = guiParent:FindFirstChild("RBXMImporterGui")
if OLD then OLD:Destroy() end

-- ================= HELPERS =================
local C = {
    bg      = Color3.fromRGB(14, 12, 32),
    side    = Color3.fromRGB(18, 16, 40),
    card    = Color3.fromRGB(20, 18, 46),
    row     = Color3.fromRGB(22, 20, 50),
    sel     = Color3.fromRGB(44, 40, 120),
    accent  = Color3.fromRGB(178, 130, 240),
    accent2 = Color3.fromRGB(124, 92, 255),
    text    = Color3.fromRGB(255, 255, 255),
    sub     = Color3.fromRGB(170, 170, 200),
    stroke  = Color3.fromRGB(70, 66, 130),
    ok      = Color3.fromRGB(110, 220, 150),
    err     = Color3.fromRGB(255, 110, 120),
}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    new("UICorner", {CornerRadius = UDim.new(0, r)}, o)
end

local function stroke(o, col, t)
    new("UIStroke", {Color = col or C.stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end

local function label(parent, text, size, pos, sz, font, col, align)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextSize = size,
        Position = pos,
        Size = sz,
        Font = font or Enum.Font.GothamBold,
        TextColor3 = col or C.text,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function makeDraggable(handle, target)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = i.Position
            startPos = target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startInput
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ================= ASSET SCAN =================
local assets = {}
local filter = "ALL"

local function scanAssets()
    assets = {}
    local ok, list = pcall(listfiles, "")
    if not ok or type(list) ~= "table" then
        ok, list = pcall(listfiles, ".")
    end
    if ok and type(list) == "table" then
        for _, p in ipairs(list) do
            local name = p:match("[^/\\]+$") or p
            local ext = name:match("%.(%w+)$")
            ext = ext and ext:lower()
            if ext == "rbxm" or ext == "rbxmx" or ext == "rbxl" or ext == "rbxlx" then
                table.insert(assets, {
                    path = p,
                    name = name,
                    kind = (ext == "rbxm" or ext == "rbxmx") and "RBXM" or "RBXL",
                })
            end
        end
    end
    table.sort(assets, function(a, b) return a.name:lower() < b.name:lower() end)
end

-- ================= IMPORT =================
local function importAsset(a)
    local getAsset = getcustomasset or getsynasset
    if not getAsset then
        return false, "Executor tidak support getcustomasset"
    end
    local ok, res = pcall(function()
        local id = getAsset(a.path)
        local objs = game:GetObjects(id)
        local parent = (Settings.ParentTo == "ReplicatedStorage") and game:GetService("ReplicatedStorage") or workspace
        local count = 0
        for _, o in ipairs(objs) do
            o.Parent = parent
            if Settings.MoveToPlayer and parent == workspace then
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if o:IsA("Model") then
                        o:PivotTo(hrp.CFrame * CFrame.new(0, 0, -8))
                    elseif o:IsA("BasePart") then
                        o.CFrame = hrp.CFrame * CFrame.new(0, 0, -8)
                    end
                end
            end
            count += 1
        end
        return count
    end)
    if ok then return true, res end
    return false, tostring(res)
end

-- ================= MAIN GUI =================
local gui = new("ScreenGui", {
    Name = "RBXMImporterGui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
}, guiParent)

local main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 580, 0, 340),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, gui)
corner(main, 16)
stroke(main, Color3.fromRGB(40, 36, 90), 1)

-- Sidebar
local side = new("Frame", {
    Size = UDim2.new(0, 170, 1, 0),
    BackgroundColor3 = C.side,
    BorderSizePixel = 0,
}, main)
corner(side, 16)
new("Frame", { -- tutup sudut kanan sidebar
    Position = UDim2.new(1, -16, 0, 0),
    Size = UDim2.new(0, 16, 1, 0),
    BackgroundColor3 = C.side,
    BorderSizePixel = 0,
}, side)

local logo = new("Frame", {
    Position = UDim2.new(0, 14, 0, 14),
    Size = UDim2.new(0, 40, 0, 40),
    BackgroundColor3 = Color3.fromRGB(28, 24, 70),
}, side)
corner(logo, 10)
stroke(logo, C.accent2, 1)
label(logo, "RBXM", 11, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, C.accent, Enum.TextXAlignment.Center)

label(side, LP.DisplayName, 13, UDim2.new(0, 62, 0, 16), UDim2.new(1, -70, 0, 18))
label(side, "v1.0 IMPORTER", 10, UDim2.new(0, 62, 0, 34), UDim2.new(1, -70, 0, 14), Enum.Font.Gotham, C.sub)

-- Header (kanan)
local title = label(main, "Dashboard", 20, UDim2.new(0, 186, 0, 14), UDim2.new(0, 300, 0, 26), Enum.Font.GothamBlack)
local subtitle = label(main, "Manage your local Roblox assets seamlessly", 11, UDim2.new(0, 186, 0, 40), UDim2.new(0, 330, 0, 16), Enum.Font.Gotham, C.sub)

local closeBtn = new("TextButton", {
    Position = UDim2.new(1, -34, 0, 12),
    Size = UDim2.new(0, 22, 0, 22),
    BackgroundTransparency = 1,
    Text = "✕",
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.text,
}, main)

makeDraggable(main, main)

-- Content area
local content = new("Frame", {
    Position = UDim2.new(0, 170, 0, 66),
    Size = UDim2.new(1, -170, 1, -66),
    BackgroundTransparency = 1,
}, main)

local pages = {}
local function makePage(name)
    local f = new("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
    }, content)
    pages[name] = f
    return f
end

-- ============ Page: Assets ============
local pAssets = makePage("Assets")

local function statCard(parent, x, value, caption)
    local c = new("Frame", {
        Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(0, 186, 0, 56),
        BackgroundColor3 = C.card,
    }, parent)
    corner(c, 12)
    stroke(c, C.stroke, 1)
    local v = label(c, value, 20, UDim2.new(0, 14, 0, 6), UDim2.new(1, -20, 0, 24), Enum.Font.GothamBlack)
    label(c, caption, 10, UDim2.new(0, 14, 0, 32), UDim2.new(1, -20, 0, 16), Enum.Font.GothamMedium, C.sub)
    return v
end

local totalLbl = statCard(pAssets, 16, "0", "TOTAL ASSETS")
local kindLbl = statCard(pAssets, 210, "0 / 0", "RBXM / RBXL")

local filterBtns = {}
local fx = 16
for _, name in ipairs({"ALL", "RBXM", "RBXL"}) do
    local b = new("TextButton", {
        Position = UDim2.new(0, fx, 0, 66),
        Size = UDim2.new(0, 84, 0, 28),
        BackgroundColor3 = C.accent,
        BackgroundTransparency = 1,
        Text = name,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.text,
        AutoButtonColor = false,
    }, pAssets)
    corner(b, 14)
    filterBtns[name] = b
    fx += 96
end

local list = new("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 102),
    Size = UDim2.new(1, -20, 1, -112),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.accent2,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, pAssets)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, list)
new("UIPadding", {PaddingRight = UDim.new(0, 6)}, list)

local statusLbl = label(main, "", 11, UDim2.new(0, 186, 1, -22), UDim2.new(1, -200, 0, 16), Enum.Font.GothamMedium, C.sub)
statusLbl.ZIndex = 5
local function setStatus(t, col)
    statusLbl.Text = t
    statusLbl.TextColor3 = col or C.sub
end

local function refreshList()
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local nm, nl = 0, 0
    for _, a in ipairs(assets) do
        if a.kind == "RBXM" then nm += 1 else nl += 1 end
    end
    totalLbl.Text = tostring(#assets)
    kindLbl.Text = nm .. " / " .. nl

    for name, b in pairs(filterBtns) do
        b.BackgroundTransparency = (name == filter) and 0 or 1
        b.TextColor3 = (name == filter) and C.text or C.sub
    end

    local shown = 0
    for i, a in ipairs(assets) do
        if filter == "ALL" or a.kind == filter then
            shown += 1
            local r = new("Frame", {
                Size = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = C.row,
                LayoutOrder = i,
            }, list)
            corner(r, 10)

            local ic = new("Frame", {
                Position = UDim2.new(0, 10, 0.5, -16),
                Size = UDim2.new(0, 32, 0, 32),
                BackgroundColor3 = Color3.fromRGB(34, 30, 90),
            }, r)
            corner(ic, 8)
            label(ic, "</>", 11, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, C.accent, Enum.TextXAlignment.Center)

            label(r, a.name, 13, UDim2.new(0, 52, 0, 8), UDim2.new(1, -140, 0, 18))
            label(r, a.name, 10, UDim2.new(0, 52, 0, 27), UDim2.new(1, -140, 0, 14), Enum.Font.Gotham, C.sub)

            local imp = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(0, 74, 0, 28),
                BackgroundColor3 = C.accent,
                Text = "IMPORT",
                TextSize = 11,
                Font = Enum.Font.GothamBlack,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            }, r)
            corner(imp, 8)

            local busy = false
            imp.MouseButton1Click:Connect(function()
                if busy then return end
                busy = true
                imp.Text = "..."
                setStatus("Importing " .. a.name .. "...", C.sub)
                task.spawn(function()
                    local ok, res = importAsset(a)
                    if ok then
                        imp.Text = "DONE"
                        setStatus("Berhasil import " .. a.name .. " (" .. tostring(res) .. " object)", C.ok)
                    else
                        imp.Text = "FAIL"
                        setStatus("Gagal: " .. tostring(res), C.err)
                    end
                    task.wait(1.5)
                    imp.Text = "IMPORT"
                    busy = false
                end)
            end)
        end
    end

    if shown == 0 then
        local e = new("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1}, list)
        label(e, "Tidak ada file .rbxm / .rbxl di folder Workspace", 12, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Enum.Font.Gotham, C.sub, Enum.TextXAlignment.Center)
    end
end

for name, b in pairs(filterBtns) do
    b.MouseButton1Click:Connect(function()
        filter = name
        refreshList()
    end)
end

-- ============ Page: Overview ============
local pOverview = makePage("Overview")
do
    local card = new("Frame", {
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -32, 0, 150),
        BackgroundColor3 = C.card,
    }, pOverview)
    corner(card, 12)
    stroke(card, C.stroke, 1)
    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -28, 1, -20),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.sub,
        Text = "Cara pakai:\n\n1. Taruh file .rbxm / .rbxl di folder Delta/Workspace\n2. Buka tab Assets, klik Rescan Assets\n3. Tekan IMPORT di file yang mau dimasukkan\n\nHasil import akan masuk ke Workspace (bisa diganti di Settings).",
    }, card)
end

-- ============ Page: Settings ============
local pSettings = makePage("Settings")
do
    local function toggleRow(y, text, get, set, labelFn)
        local r = new("Frame", {
            Position = UDim2.new(0, 16, 0, y),
            Size = UDim2.new(1, -32, 0, 44),
            BackgroundColor3 = C.card,
        }, pSettings)
        corner(r, 10)
        stroke(r, C.stroke, 1)
        label(r, text, 12, UDim2.new(0, 14, 0, 0), UDim2.new(1, -120, 1, 0))
        local b = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.new(0, 90, 0, 26),
            BackgroundColor3 = C.accent2,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextColor3 = C.text,
            Text = labelFn(),
        }, r)
        corner(b, 8)
        b.MouseButton1Click:Connect(function()
            set()
            b.Text = labelFn()
        end)
    end

    toggleRow(0, "Import ke", nil, function()
        Settings.ParentTo = (Settings.ParentTo == "Workspace") and "ReplicatedStorage" or "Workspace"
    end, function() return Settings.ParentTo == "Workspace" and "Workspace" or "RepStorage" end)

    toggleRow(54, "Pindah ke posisi karakter", nil, function()
        Settings.MoveToPlayer = not Settings.MoveToPlayer
    end, function() return Settings.MoveToPlayer and "ON" or "OFF" end)
end

-- ============ Sidebar nav ============
local navButtons = {}
local function showPage(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(navButtons) do
        b.BackgroundTransparency = (n == name) and 0 or 1
    end
    title.Text = (name == "Settings") and "Settings" or ((name == "Overview") and "Overview" or "Dashboard")
    if name == "Assets" then refreshList() end
end

local function navButton(name, y)
    local b = new("TextButton", {
        Position = UDim2.new(0, 10, 0, y),
        Size = UDim2.new(1, -20, 0, 40),
        BackgroundColor3 = C.sel,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, side)
    corner(b, 10)
    label(b, name, 13, UDim2.new(0, 46, 0, 0), UDim2.new(1, -50, 1, 0), Enum.Font.GothamMedium)
    local icons = {Overview = "▦", Assets = "▣", Settings = "⚙"}
    label(b, icons[name] or "•", 16, UDim2.new(0, 14, 0, 0), UDim2.new(0, 24, 1, 0), Enum.Font.GothamBold, C.accent, Enum.TextXAlignment.Center)
    navButtons[name] = b
    b.MouseButton1Click:Connect(function() showPage(name) end)
end

navButton("Overview", 76)
navButton("Assets", 122)
navButton("Settings", 168)

new("Frame", {
    Position = UDim2.new(0, 16, 0, 226),
    Size = UDim2.new(1, -32, 0, 1),
    BackgroundColor3 = C.stroke,
    BorderSizePixel = 0,
}, side)
label(side, "QUICK TOOLS", 10, UDim2.new(0, 16, 0, 236), UDim2.new(1, -32, 0, 14), Enum.Font.GothamBold, C.sub)

local rescan = new("TextButton", {
    Position = UDim2.new(0, 10, 0, 256),
    Size = UDim2.new(1, -20, 0, 38),
    BackgroundColor3 = Color3.fromRGB(26, 24, 66),
    Text = "",
    AutoButtonColor = false,
}, side)
corner(rescan, 10)
label(rescan, "↻", 16, UDim2.new(0, 14, 0, 0), UDim2.new(0, 24, 1, 0), Enum.Font.GothamBold, C.accent, Enum.TextXAlignment.Center)
label(rescan, "Rescan Assets", 12, UDim2.new(0, 46, 0, 0), UDim2.new(1, -50, 1, 0))
rescan.MouseButton1Click:Connect(function()
    scanAssets()
    refreshList()
    setStatus("Rescan selesai: " .. #assets .. " file ditemukan", C.ok)
end)

-- ================= TOGGLE BUTTONS (kiri atas) =================
local function circleBtn(x, y, text, tsize)
    local b = new("TextButton", {
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, 46, 0, 46),
        BackgroundColor3 = Color3.fromRGB(20, 22, 50),
        Text = text,
        TextSize = tsize or 22,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.text,
        AutoButtonColor = true,
    }, gui)
    corner(b, 23)
    stroke(b, Color3.fromRGB(60, 60, 130), 1)
    return b
end

local btnLogo = circleBtn(14, 14, "◼", 18)
local btnMenu = circleBtn(68, 14, "≡", 26)
local btnSkull = circleBtn(14, 66, "☠", 20)
btnSkull.BackgroundColor3 = Color3.fromRGB(40, 24, 80)

local function toggle()
    main.Visible = not main.Visible
end
btnLogo.MouseButton1Click:Connect(toggle)
btnMenu.MouseButton1Click:Connect(toggle)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)
btnSkull.MouseButton1Click:Connect(function() gui:Destroy() end)

-- ================= START =================
scanAssets()
showPage("Assets")
