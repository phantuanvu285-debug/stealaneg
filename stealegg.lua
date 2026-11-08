-- ValueHat GUI 5 - Sửa lỗi không tìm thấy nơi về + Về đúng Vùng an toàn
local UI = loadstring(game:HttpGet('https://raw.githubusercontent.com/ValueHat-Script/Valuehat-script/refs/heads/main/ValueHatGui5.lua'))().Init("Steal an Egg: Time Travel")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ==== CẤU HÌNH ====
local Biomes = Workspace.Biomes
local EGG_NAME = "NestModel"

local PROMPT_RANGE = 5
local AREA_MARGIN = 10
local ROUND_DELAY = 0.5
local WAIT_STABLE = 0.35
local WAIT_PICKUP = 0.4

local autoEgg = false
local selectedArea = nil

-- ==== HÀM HỖ TRỢ ====
local function getPos(obj)
    if obj:IsA("Model") then return obj:GetPivot().Position
    elseif obj:IsA("BasePart") then return obj.Position end
end

local function getBounds(area)
    if area:IsA("Model") then return area:GetBoundingBox()
    elseif area:IsA("BasePart") then return area.CFrame, area.Size end
end

local function inArea(pos, cf, size)
    local rel = cf:PointToObjectSpace(pos)
    return math.abs(rel.X) <= size.X/2 + AREA_MARGIN
       and math.abs(rel.Y) <= size.Y/2 + AREA_MARGIN
       and math.abs(rel.Z) <= size.Z/2 + AREA_MARGIN
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function firePromptsNear(root)
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local p = d.Parent
            local pos = p and ((p:IsA("Attachment") and p.WorldPosition) or getPos(p))
            if pos and (pos - root.Position).Magnitude <= PROMPT_RANGE then
                d.HoldDuration = 0
                fireproximityprompt(d)
            end
        end
    end
end

-- ==== SỬA LỖI TÌM VÙNG AN TOÀN ====
local function getReturnCF()
    -- Cách 1: Tìm tên chính xác
    local safeZone = Workspace:FindFirstChild("SafeZone")
    -- Cách 2: Tìm tên gần giống
    if not safeZone then
        for _, d in ipairs(Workspace:GetChildren()) do
            local name = d.Name:lower()
            if name:find("safe") or name:find("an") and name:find("toan") then
                safeZone = d
                break
            end
        end
    end
    -- Cách 3: Tìm TextLabel hiển thị "Vùng an toàn"
    if not safeZone then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("BillboardGui") then
                local txt = d.Text or ""
                if tostring(txt):find("Vùng an toàn") or tostring(txt):lower():find("safe") then
                    local par = d.Parent
                    for _ = 1, 5 do
                        if par and (par:IsA("BasePart") or par:IsA("Model")) then
                            safeZone = par
                            break
                        end
                        par = par.Parent
                    end
                    if safeZone then break end
                end
            end
        end
    end
    -- Lấy tọa độ
    if safeZone then
        local part = safeZone:IsA("BasePart") and safeZone or safeZone:FindFirstChildWhichIsA("BasePart", true)
        if part then
            print("✅ Tìm thấy Vùng an toàn tại: " .. part.Name)
            return CFrame.new(part.Position + Vector3.new(0, 4, 0))
        end
    end
    -- Cách cuối: về vị trí xuất phát của người chơi
    local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawn then
        print("⚠️ Dùng Spawn làm nơi về")
        return spawn.CFrame + Vector3.new(0, 4, 0)
    end
    print("❌ Không tìm thấy nơi về nào!")
    return nil
end

-- ==== DANH SÁCH KHU VỰC ====
local names = {}
for _, area in ipairs(Biomes:GetChildren()) do
    if area.Name:sub(1, 6) == "Biome_" then
        table.insert(names, area.Name)
    end
end

UI:Dropdown("Dropdown", "Chọn Khu Vực", names, function(selected)
    selectedArea = selected
end)

-- ==== AUTO EGG ====
UI:Toggle("Toggle", "Auto Egg", function(enabled)
    autoEgg = enabled
    if not enabled then return end

    task.spawn(function()
        local returnHomeCF = getReturnCF()
        if not returnHomeCF then return end

        while autoEgg do
            local area = selectedArea and Biomes:FindFirstChild(selectedArea)
            local cf, size
            if area then
                cf, size = getBounds(area)
            end

            local didWork = false
            if area then
                for _, egg in ipairs(area:GetDescendants()) do
                    if not autoEgg then break end
                    if egg.Name == EGG_NAME then
                        local root = getRoot()
                        local pos = getPos(egg)
                        if root and pos and (not cf or inArea(pos, cf, size)) then
                            didWork = true
                            
                            -- 1. Đến trứng
                            root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                            task.wait(WAIT_STABLE)
                            
                            -- 2. Nhặt
                            root = getRoot()
                            if root then
                                firePromptsNear(root)
                                task.wait(WAIT_PICKUP)
                            end
                            
                            -- 3. Về Vùng an toàn
                            root = getRoot()
                            if root then
                                root.CFrame = returnHomeCF
                            end
                            task.wait(ROUND_DELAY)
                        end
                    end
                end
            end

            if not didWork then
                task.wait(1)
            end
        end
    end)
end)
