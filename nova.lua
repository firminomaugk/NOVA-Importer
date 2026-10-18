
-- NOVA IMPORTER V2
-- Ganti fungsi scan() lama dengan fungsi ini.

local FOLDER_PATHS = {
    "/storage/emulated/0/Delta/Workspace",
    "storage/emulated/0/Delta/Workspace",
    "Delta/Workspace",
    "Workspace",
}

local function scan()
    clearRows()

    status.TextColor3 = Color3.fromRGB(0, 213, 255)
    status.Text = "Memeriksa API file..."

    -- Periksa apakah fungsi pemindai tersedia
    if type(listfiles) ~= "function" then
        status.TextColor3 = Color3.fromRGB(255, 194, 100)
        status.Text = "API listfiles tidak tersedia"
        addRow(
            "Delta tidak menyediakan listfiles pada lingkungan ini",
            "API INFO"
        )
        return
    end

    local filesFound = {}
    local errors = {}

    for _, folderPath in ipairs(FOLDER_PATHS) do
        local ok, result = pcall(function()
            return listfiles(folderPath)
        end)

        if ok and type(result) == "table" then
            for _, path in ipairs(result) do
                local fullPath = tostring(path)
                local name = fullPath:match("[^/\\]+$") or fullPath
                local ext = name:lower():match("%.([%w]+)$")

                if ext == "rbxm"
                    or ext == "rbxl"
                    or ext == "rbxlx" then

                    local kind = ext == "rbxm" and "RBXM" or "RBXL"

                    table.insert(filesFound, {
                        name = name,
                        kind = kind,
                        path = fullPath
                    })
                end
            end

            -- Folder berhasil dibaca; hentikan percobaan path
            status.Text = "Folder terbaca: " .. folderPath
            break
        else
            table.insert(
                errors,
                folderPath .. " -> " .. tostring(result)
            )
        end
    end

    local shown = 0

    for _, file in ipairs(filesFound) do
        local matchesTab =
            currentTab == "ALL" or currentTab == file.kind

        local matchesSearch =
            file.name:lower():find(
                search.Text:lower(), 1, true
            )

        if matchesTab and matchesSearch then
            addRow(file.name, file.kind)
            shown = shown + 1
        end
    end

    if shown > 0 then
        status.TextColor3 = Color3.fromRGB(0, 213, 255)
        status.Text = "File ditemukan: " .. shown
    elseif #errors == #FOLDER_PATHS then
        status.TextColor3 = Color3.fromRGB(255, 194, 100)
        status.Text = "Semua path gagal dibaca"

        addRow(
            "Tidak bisa membaca folder melalui API yang tersedia",
            "SCAN INFO"
        )
    else
        status.TextColor3 = Color3.fromRGB(255, 194, 100)
        status.Text = "Folder terbaca, tetapi file RBXM/RBXL tidak ditemukan"

        addRow(
            "Periksa nama file dan lokasi penyimpanannya",
            "SCAN INFO"
        )
    end

    task.defer(function()
        list.CanvasSize = UDim2.new(
            0, 0, 0, layout.AbsoluteContentSize.Y + 8
        )
    end)
end
