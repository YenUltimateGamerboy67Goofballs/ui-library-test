--[[
    VexUI - Modern Dashboard UI Library
    Version 2.0
]]

local VexUI = {
    Version = "2.0.0",
    Toggles = {},
    Options = {},
    CustomIcons = {},
}

VexUI.__index = VexUI

-- ============ SERVICES ============
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local LocalizationService = game:GetService("LocalizationService")
local LocalPlayer = Players.LocalPlayer

local GENV = (getgenv and getgenv()) or _G
if GENV.VexUI_Instance and GENV.VexUI_Instance.Unload then
    pcall(GENV.VexUI_Instance.Unload, GENV.VexUI_Instance)
end
GENV.VexUI_Instance = VexUI

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Groupbox = {}
Groupbox.__index = Groupbox

-- ============ THEME ============
local Theme = {
    Background = Color3.fromRGB(10, 10, 13),
    Secondary = Color3.fromRGB(16, 16, 20),
    Tertiary = Color3.fromRGB(24, 24, 29),
    Card = Color3.fromRGB(7, 7, 9),
    Border = Color3.fromRGB(42, 42, 50),
    BorderLight = Color3.fromRGB(55, 55, 65),
    Text = Color3.fromRGB(235, 235, 240),
    SubText = Color3.fromRGB(140, 140, 155),
    Accent = Color3.fromRGB(200, 30, 40),
    AccentDark = Color3.fromRGB(140, 20, 28),
    ToggleOn = Color3.fromRGB(200, 30, 40),
    ToggleOff = Color3.fromRGB(55, 55, 65),
    Success = Color3.fromRGB(46, 204, 113),
    Warning = Color3.fromRGB(236, 190, 60),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    TextSize = 14,
    CornerRadius = 6,
}
VexUI.Theme = Theme

-- ============ UTILITIES ============
local Connections = {}

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

local function Create(className, props)
    local inst = Instance.new(className)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            parent = v
        else
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function Corner(inst, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or Theme.CornerRadius),
        Parent = inst,
    })
end

local function Stroke(inst, color, thickness)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })
end

local function Tween(inst, time, props, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(
        time or 0.15,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

local function Gradient(frame, keypoints, rotation)
    local seq = {}
    for _, k in ipairs(keypoints) do
        table.insert(seq, ColorSequenceKeypoint.new(k[1], k[2]))
    end
    return Create("UIGradient", {
        Color = ColorSequence.new(seq),
        Rotation = rotation or 0,
        Parent = frame,
    })
end

local function Glow(parent, color, rotation, strength)
    local g = Create("Frame", {
        Name = "Glow",
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1,
        Parent = parent,
    })
    Corner(g, 10)
    Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1 - (strength or 0.5)),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = rotation or 0,
        Parent = g,
    })
    return g
end

local function Round(v, decimals)
    local m = 10 ^ (decimals or 0)
    return math.floor(v * m + 0.5) / m
end

local function FormatTime(s)
    s = math.floor(s)
    return string.format("%02d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
end

local function Plural(n, word)
    if n == 0 then
        return "no " .. word .. "s"
    end
    return n .. " " .. word .. (n == 1 and "" or "s")
end

local function Copy(text)
    local fn = setclipboard or toclipboard or set_clipboard
    if fn then
        return pcall(fn, text)
    end
    return false
end

local function MakeDraggable(frame, handle, getScale)
    local state = { Moved = 0 }
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            state.Moved = 0
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local s = getScale and getScale() or 1
            local d = (input.Position - dragStart) / s
            state.Moved = math.max(state.Moved, d.Magnitude)
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    return state
end

local function TrackDrag(hit, column, onMove)
    local dragging = false
    local function setScroll(v)
        if column then
            column.ScrollingEnabled = v
        end
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setScroll(false)
            onMove(input.Position)
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            onMove(input.Position)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            setScroll(true)
        end
    end)
end

-- ============ LUCIDE ICONS ============
local IconModule
do
    local ok, mod = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/mstudio45/lucide-roblox-direct/refs/heads/main/source.lua"
        ))()
    end)
    if ok and type(mod) == "table" then
        IconModule = mod
    end
end

local IconAliases = { home = "house", gear = "settings", close = "x", plus = "plus", search = "search" }

function VexUI:SetIconModule(mod)
    IconModule = mod
end

function VexUI:AddIcon(name, asset)
    local url = type(asset) == "number" and ("rbxassetid://" .. asset) or asset
    self.CustomIcons[name] = {
        Url = url,
        ImageRectOffset = Vector2.new(0, 0),
        ImageRectSize = Vector2.new(0, 0),
    }
end

function VexUI:GetIcon(icon)
    local t = type(icon)
    if t == "table" then
        return icon.Url and icon or nil
    end
    if t == "number" then
        return { Url = "rbxassetid://" .. icon, ImageRectOffset = Vector2.new(0, 0), ImageRectSize = Vector2.new(0, 0) }
    end
    if t ~= "string" or icon == "" then
        return nil
    end
    if self.CustomIcons[icon] then
        return self.CustomIcons[icon]
    end
    if icon:sub(1, 13) == "rbxassetid://" or icon:sub(1, 4) == "http" then
        return { Url = icon, ImageRectOffset = Vector2.new(0, 0), ImageRectSize = Vector2.new(0, 0) }
    end
    if tonumber(icon) then
        return self:GetIcon(tonumber(icon))
    end

    local name = (icon:gsub("^lucide[-:]", ""))
    name = IconAliases[name] or name
    if IconModule and IconModule.GetAsset then
        local ok, data = pcall(IconModule.GetAsset, name)
        if ok and data then
            return data
        end
    end
    return nil
end

local function SetIcon(img, icon)
    local data = VexUI:GetIcon(icon)
    if not data then
        return false
    end
    img.Image = data.Url
    img.ImageRectOffset = data.ImageRectOffset or Vector2.new(0, 0)
    img.ImageRectSize = data.ImageRectSize or Vector2.new(0, 0)
    return true
end

local function NewIcon(parent, icon, px, color, fallback)
    local img = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(px, px),
        ImageColor3 = color,
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    })
    if SetIcon(img, icon) then
        return { Instance = img, Prop = "ImageColor3", Ok = true }
    end
    img:Destroy()
    local lbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(px, px),
        Font = Theme.FontBold,
        Text = fallback or "?",
        TextColor3 = color,
        TextSize = math.floor(px * 0.85),
        Parent = parent,
    })
    return { Instance = lbl, Prop = "TextColor3", Ok = false }
end

local function TintIcon(ic, color, time)
    Tween(ic.Instance, time or 0.15, { [ic.Prop] = color })
end

-- ============ OPTION REGISTRY ============
local function NewOption(kind, id, value)
    local obj = { Type = kind, Id = id, Value = value, _changed = {} }

    function obj:OnChanged(fn)
        table.insert(self._changed, fn)
        return self
    end

    local function changed(v)
        obj.Value = v
        for _, fn in ipairs(obj._changed) do
            task.spawn(fn, v)
        end
    end

    local registry = (kind == "Toggle") and VexUI.Toggles or VexUI.Options
    registry[id] = obj
    return obj, changed
end

-- ============ GUI CONTAINER ============
local function GetGuiParent()
    local ok, hui = pcall(function()
        return gethui and gethui()
    end)
    if ok and hui then
        return hui
    end
    return CoreGui
end

local function EnsureGui()
    if VexUI.Gui and VexUI.Gui.Parent then
        return VexUI.Gui
    end
    VexUI.Gui = Create("ScreenGui", {
        Name = "VexUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Parent = GetGuiParent(),
    })
    return VexUI.Gui
end

-- ============ NOTIFICATIONS ============
local NotifContainer

local function EnsureNotifContainer()
    if NotifContainer and NotifContainer.Parent then
        return NotifContainer
    end
    VexUI.NotifGui = Create("ScreenGui", {
        Name = "VexUI_Notifs",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 101,
        Parent = GetGuiParent(),
    })
    NotifContainer = Create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 300, 1, -40),
        AnchorPoint = Vector2.new(1, 1),
        Parent = VexUI.NotifGui,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = NotifContainer,
    })
    return NotifContainer
end

function VexUI:Notify(opts)
    if type(opts) == "string" then
        opts = { Description = opts }
    end
    opts = opts or {}
    local container = EnsureNotifContainer()
    local title = opts.Title or "Notification"
    local text = opts.Description or opts.Text or ""
    local duration = opts.Time or 4

    local holder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 62),
        Parent = container,
    })
    local notif = Create("Frame", {
        Name = "Notif",
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.new(1, 340, 0, 0),
        ClipsDescendants = true,
        Parent = holder,
    })
    Corner(notif, 8)
    Stroke(notif, Theme.Border, 1)

    local accent = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 3, 1, -24),
        Parent = notif,
    })
    Corner(accent, 3)

    local ic = NewIcon(notif, opts.Icon or "bell", 18, Theme.Accent, "!")
    ic.Instance.Position = UDim2.new(0, 14, 0, 9)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 8),
        Size = UDim2.new(1, -48, 0, 18),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 26),
        Size = UDim2.new(1, -48, 1, -30),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notif,
    })

    Tween(notif, 0.25, { Position = UDim2.new(0, 0, 0, 0) })

    task.delay(duration, function()
        pcall(function()
            Tween(notif, 0.25, { Position = UDim2.new(1, 340, 0, 0) })
        end)
        task.wait(0.3)
        holder:Destroy()
    end)
end

-- ============ CHANGELOG SYSTEM ============
function VexUI:ShowChangelog(opts)
    opts = opts or {}
    local scriptName = opts.Title or "Script"
    local version = opts.Version or "1.0.0"
    local entries = opts.Entries or {}
    local discord = opts.Discord

    if VexUI._ChangelogGui and VexUI._ChangelogGui.Parent then
        VexUI._ChangelogGui:Destroy()
    end
    VexUI._ChangelogGui = Create("ScreenGui", {
        Name = "VexUI_Changelog",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = GetGuiParent(),
    })
    local gui = VexUI._ChangelogGui

    local overlay = Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = gui,
    })

    local card = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.55),
        Size = UDim2.fromOffset(520, 480),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = overlay,
    })
    Corner(card, 14)
    Stroke(card, Theme.Border, 1)

    local topBar = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 3),
        Parent = card,
    })
    Corner(topBar, 3)
    Gradient(topBar, {
        { 0, Theme.AccentDark },
        { 0.5, Theme.Accent },
        { 1, Theme.AccentDark },
    }, 0)

    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 70),
        Parent = card,
    })
    local logoBox = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(24, 20),
        Size = UDim2.fromOffset(34, 34),
        Parent = header,
    })
    Corner(logoBox, 10)
    Gradient(logoBox, {
        { 0, Theme.Accent },
        { 1, Theme.AccentDark },
    }, 45)
    local logoIco = NewIcon(logoBox, "sparkles", 18, Color3.new(1, 1, 1), "*")
    logoIco.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    logoIco.Instance.Position = UDim2.fromScale(0.5, 0.5)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(70, 22),
        Size = UDim2.new(1, -90, 0, 20),
        Font = Theme.FontBold,
        Text = scriptName,
        TextColor3 = Theme.Text,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(70, 42),
        Size = UDim2.new(1, -90, 0, 14),
        Font = Theme.Font,
        Text = "Version " .. version,
        TextColor3 = Theme.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local closeBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -44, 0, 22),
        Size = UDim2.fromOffset(24, 24),
        Text = "X",
        Font = Theme.FontBold,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = header,
    })
    Corner(closeBtn, 6)
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, 0.15, { BackgroundColor3 = Theme.Accent, TextColor3 = Color3.new(1, 1, 1) })
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, 0.15, { BackgroundColor3 = Theme.Tertiary, TextColor3 = Theme.SubText })
    end)

    local scroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 84),
        Size = UDim2.new(1, -32, 1, -160),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Border,
        ScrollBarImageTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = card,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = scroll,
    })

    local typeColors = {
        Added = Theme.Success,
        Fixed = Color3.fromRGB(90, 170, 240),
        Removed = Color3.fromRGB(240, 100, 100),
        Changed = Theme.Warning,
        Improved = Color3.fromRGB(180, 120, 240),
    }

    for i, entry in ipairs(entries) do
        local eType, eText
        if entry.Type and entry.Text then
            eType = entry.Type
            eText = entry.Text
        else
            for k, v in pairs(entry) do
                eType = k
                eText = v
                break
            end
        end

        local color = typeColors[eType] or Theme.Accent

        local row = Create("Frame", {
            BackgroundColor3 = Theme.Tertiary,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -6, 0, 32),
            LayoutOrder = i,
            Parent = scroll,
        })
        Corner(row, 8)

        local pill = Create("Frame", {
            BackgroundColor3 = color,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(8, 6),
            Size = UDim2.fromOffset(70, 20),
            Parent = row,
        })
        Corner(pill, 6)
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = Theme.FontBold,
            Text = eType,
            TextColor3 = color,
            TextSize = 10,
            Parent = pill,
        })

        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(86, 0),
            Size = UDim2.new(1, -96, 1, 0),
            Font = Theme.Font,
            Text = tostring(eText),
            TextColor3 = Theme.Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = row,
        })
    end

    local footer = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -64),
        Size = UDim2.new(1, 0, 0, 52),
        Parent = card,
    })

    local okBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 6),
        Size = UDim2.new(1, -60, 0, 34),
        Font = Theme.FontBold,
        Text = "Continue",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        AutoButtonColor = false,
        Parent = footer,
    })
    Corner(okBtn, 10)
    Gradient(okBtn, {
        { 0, Theme.Accent },
        { 1, Theme.AccentDark },
    }, 45)

    Tween(card, 0.35, {
        BackgroundTransparency = 0.04,
        Position = UDim2.fromScale(0.5, 0.5),
    }, Enum.EasingStyle.Back)

    local function close()
        Tween(card, 0.25, {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.55),
        })
        task.wait(0.3)
        gui:Destroy()
    end

    closeBtn.MouseButton1Click:Connect(close)
    okBtn.MouseButton1Click:Connect(close)
end

-- ============ CONFIG ============
local ConfigFolder = "VexUI/configs"

local function HasFS()
    return writefile and readfile and isfile and isfolder and makefolder
end

local function EnsureFolders()
    if not isfolder("VexUI") then
        makefolder("VexUI")
    end
    if not isfolder(ConfigFolder) then
        makefolder(ConfigFolder)
    end
end

function VexUI:SaveConfig(name)
    if not name or name == "" then
        return false, "Kein Name angegeben"
    end
    if not HasFS() then
        return false, "Executor unterstuetzt keine Dateifunktionen"
    end

    local data = {}
    for id, o in pairs(self.Toggles) do
        if id:sub(1, 6) ~= "VexUI_" then
            data[id] = { t = o.Type, v = o.Value }
        end
    end
    for id, o in pairs(self.Options) do
        if id:sub(1, 6) ~= "VexUI_" then
            local v = o.Value
            if typeof(v) == "Color3" then
                v = { math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5) }
            end
            data[id] = { t = o.Type, v = v }
        end
    end

    local ok, err = pcall(function()
        EnsureFolders()
        writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return ok, err
end

function VexUI:LoadConfig(name)
    if not name or name == "" then
        return false, "Kein Name angegeben"
    end
    if not HasFS() then
        return false, "Executor unterstuetzt keine Dateifunktionen"
    end
    local path = ConfigFolder .. "/" .. name .. ".json"
    if not isfile(path) then
        return false, "Config nicht gefunden"
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        return false, "Config ist beschaedigt"
    end

    for id, entry in pairs(data) do
        local o = self.Toggles[id] or self.Options[id]
        if o and o.Set then
            local v = entry.v
            if o.Type == "ColorPicker" and type(v) == "table" then
                v = Color3.fromRGB(v[1], v[2], v[3])
            end
            pcall(o.Set, v)
        end
    end
    return true
end

function VexUI:ListConfigs()
    local out = {}
    if not (HasFS() and listfiles) then
        return out
    end
    pcall(function()
        EnsureFolders()
        for _, path in ipairs(listfiles(ConfigFolder)) do
            local n = path:match("([^/\\]+)%.json$")
            if n then
                table.insert(out, n)
            end
        end
    end)
    table.sort(out)
    return out
end

-- ============ UNLOAD ============
function VexUI:Unload()
    self.Unloaded = true
    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    table.clear(Connections)
    if self.Gui then
        self.Gui:Destroy()
    end
    if self.NotifGui then
        self.NotifGui:Destroy()
    end
    if self._ChangelogGui then
        self._ChangelogGui:Destroy()
    end
    table.clear(self.Toggles)
    table.clear(self.Options)
    if GENV.VexUI_Instance == self then
        GENV.VexUI_Instance = nil
    end
end

-- ============ CARD HELPERS ============
local AvatarCache

local function LoadAvatar(img)
    task.spawn(function()
        if not AvatarCache then
            local ok, url = pcall(Players.GetUserThumbnailAsync, Players, LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            if ok then
                AvatarCache = url
            end
        end
        if AvatarCache and img.Parent then
            img.Image = AvatarCache
        end
    end)
end

local function Card(parent, size, bg, class)
    local isButton = class == "TextButton"
    local f = Create(class or "Frame", {
        BackgroundColor3 = bg or Theme.Card,
        BorderSizePixel = 0,
        Size = size,
        Parent = parent,
    })
    if isButton then
        f.Text = ""
        f.AutoButtonColor = false
    end
    Corner(f, 10)
    Stroke(f, Theme.Border, 1)
    return f
end

local function CardText(card, title, desc, titleSize, descScale)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -28, 0, 20),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = titleSize or 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = card,
    })
    if desc then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 31),
            Size = UDim2.new(descScale or 1, -28, 0, 28),
            Font = Theme.Font,
            Text = desc,
            TextColor3 = Theme.SubText,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 2,
            Parent = card,
        })
    end
end

local function TileRow(parent, order, hScale, hOffset)
    local r = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, hScale, hOffset),
        LayoutOrder = order,
        Parent = parent,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = r,
    })
    return r
end

local function StatTile(row, order, title, value, wScale, onClick)
    local btn = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(22, 22, 27),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(wScale, -3, 1, 0),
        LayoutOrder = order,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    Corner(btn, 8)
    local strk = Stroke(btn, Theme.Border, 1)

    local holder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = btn,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 1),
        Parent = holder,
    })
    Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 6), Parent = holder })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 15),
        LayoutOrder = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 12),
        LayoutOrder = 2,
        Font = Theme.Font,
        Text = value,
        TextColor3 = Theme.SubText,
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    if onClick then
        btn.MouseEnter:Connect(function()
            Tween(strk, 0.15, { Color = Theme.Accent })
        end)
        btn.MouseLeave:Connect(function()
            Tween(strk, 0.15, { Color = Theme.Border })
        end)
        btn.MouseButton1Click:Connect(function()
            task.spawn(onClick)
        end)
    end

    return {
        Button = btn,
        Set = function(text)
            valueLabel.Text = text
        end,
    }
end

local function JoinDiscord(invite)
    local code = invite:match("discord%.gg/([%w%-_]+)")
        or invite:match("discord%.com/invite/([%w%-_]+)")
        or invite
    Copy("https://discord.gg/" .. code)

    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if req then
        pcall(req, {
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["Origin"] = "https://discord.com" },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = { code = code },
                nonce = HttpService:GenerateGUID(false),
            }),
        })
    end
    VexUI:Notify({ Title = "Discord", Description = "Invite copied: discord.gg/" .. code, Icon = "circle-check" })
end

local function GetPing()
    local ok, v = pcall(function()
        return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    return ok and v or nil
end

local function GetExecutorName()
    local ok, name = pcall(function()
        return identifyexecutor()
    end)
    return (ok and name) or "Unknown executor"
end

-- ============ WINDOW ============
function VexUI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "VexUI"
    local subtitle = opts.Subtitle or ""
    local size = opts.Size or UDim2.fromOffset(700, 430)
    local gui = EnsureGui()

    local main = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = opts.Transparency or 0.04,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui,
    })
    Corner(main, 12)
    Stroke(main, Theme.Border, 1)
    local uiScale = Create("UIScale", { Parent = main })

    local topBar = Create("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 46),
        Parent = main,
    })
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = topBar,
    })

    local logo = NewIcon(topBar, opts.Icon or "moon", 22, Theme.Accent, "V")
    logo.Instance.Position = UDim2.new(0, 16, 0.5, -11)

    local titleHolder = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 48, 0, 0),
        Size = UDim2.new(1, -170, 1, 0),
        Parent = topBar,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = titleHolder,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 20),
        LayoutOrder = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 15,
        Parent = titleHolder,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 20),
        LayoutOrder = 2,
        Font = Theme.Font,
        Text = subtitle,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        Parent = titleHolder,
    })

    local btnHolder = Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = topBar,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = btnHolder,
    })

    local function TopButton(order, icon, fallback)
        local b = Create("TextButton", {
            BackgroundColor3 = Theme.Tertiary,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(28, 28),
            LayoutOrder = order,
            Text = "",
            AutoButtonColor = false,
            Parent = btnHolder,
        })
        Corner(b, 8)
        local s = Stroke(b, Theme.Border, 1)
        local ic = NewIcon(b, icon, 14, Theme.SubText, fallback)
        ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Instance.Position = UDim2.fromScale(0.5, 0.5)
        b.MouseEnter:Connect(function()
            TintIcon(ic, Theme.Text)
            Tween(s, 0.15, { Color = Theme.Accent })
        end)
        b.MouseLeave:Connect(function()
            TintIcon(ic, Theme.SubText)
            Tween(s, 0.15, { Color = Theme.Border })
        end)
        return b
    end

    local minBtn = TopButton(1, "minus", "-")
    local closeBtn = TopButton(2, "x", "x")

    local body = Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(1, 0, 1, -46),
        Parent = main,
    })
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 1, 0),
        ZIndex = 5,
        Parent = body,
    })
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = sidebar,
    })

    local tabList = Create("Frame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -64),
        Parent = sidebar,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = tabList,
    })
    Create("UIPadding", { PaddingTop = UDim.new(0, 10), Parent = tabList })

    local content = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 60, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Parent = body,
    })

    local avatarBtn = Create("ImageButton", {
        Name = "Avatar",
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -10),
        Size = UDim2.fromOffset(42, 42),
        ScaleType = Enum.ScaleType.Crop,
        AutoButtonColor = false,
        Parent = sidebar,
    })
    Corner(avatarBtn, 10)
    Stroke(avatarBtn, Theme.Border, 1)
    LoadAvatar(avatarBtn)

    MakeDraggable(main, topBar, function()
        return uiScale.Scale
    end)

    local windowObj = setmetatable({
        Gui = gui,
        Main = main,
        Body = body,
        TabBar = tabList,
        Content = content,
        Scale = uiScale,
        Title = title,
        Tabs = {},
        ActiveTab = nil,
        HomeTab = nil,
        ToggleKeybind = opts.ToggleKeybind or Enum.KeyCode.RightControl,
        Minimized = false,
        Alive = true,
        Size = size,
    }, Window)

    local function updateScale()
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local vp = cam.ViewportSize
        local fit = math.min((vp.X - 24) / math.max(size.X.Offset, 1), (vp.Y - 24) / math.max(size.Y.Offset, 1))
        uiScale.Scale = math.clamp(math.min(opts.Scale or 1, fit), 0.5, 2)
    end
    updateScale()
    if workspace.CurrentCamera then
        Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
    end

    avatarBtn.MouseButton1Click:Connect(function()
        if windowObj.HomeTab then
            windowObj:SelectTab(windowObj.HomeTab)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    minBtn.MouseButton1Click:Connect(function()
        windowObj.Minimized = not windowObj.Minimized
        if windowObj.Minimized then
            Tween(main, 0.2, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 46) })
            task.delay(0.2, function()
                if windowObj.Minimized then
                    body.Visible = false
                end
            end)
        else
            body.Visible = true
            Tween(main, 0.2, { Size = size })
        end
    end)

    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then
            return
        end
        if input.KeyCode == windowObj.ToggleKeybind then
            windowObj:Toggle()
        end
    end)

    local wantButton = opts.ToggleButton
    if wantButton == nil then
        wantButton = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    end
    if wantButton then
        local fb = Create("TextButton", {
            Name = "ToggleButton",
            BackgroundColor3 = Theme.Secondary,
            Position = UDim2.new(0, 16, 0.5, -22),
            Size = UDim2.fromOffset(44, 44),
            Text = "",
            AutoButtonColor = false,
            Parent = gui,
        })
        Corner(fb, 12)
        Stroke(fb, Theme.Border, 1)
        local fic = NewIcon(fb, opts.Icon or "moon", 22, Theme.Accent, "V")
        fic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
        fic.Instance.Position = UDim2.fromScale(0.5, 0.5)
        local drag = MakeDraggable(fb, fb)
        fb.MouseButton1Click:Connect(function()
            if drag.Moved < 6 then
                windowObj:Toggle()
            end
        end)
        windowObj.ToggleButton = fb
    end

    return windowObj
end

function Window:Toggle()
    self.Main.Visible = not self.Main.Visible
end

function Window:Notify(opts)
    VexUI:Notify(opts)
end

function Window:Destroy()
    self.Alive = false
    self.Main:Destroy()
    if self.ToggleButton then
        self.ToggleButton:Destroy()
    end
end

function Window:AddTab(name, icon)
    local tab = setmetatable({
        Name = name,
        Window = self,
        Icon = icon,
        Groupboxes = {},
    }, Tab)

    local btn = Create("TextButton", {
        Name = name,
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(42, 42),
        LayoutOrder = #self.Tabs + 1,
        Text = "",
        AutoButtonColor = false,
        Parent = self.TabBar,
    })
    Corner(btn, 10)
    local strk = Stroke(btn, Theme.Border, 1)
    strk.Transparency = 1

    local ic = NewIcon(btn, icon, 20, Theme.SubText, string.upper(string.sub(name, 1, 1)))
    ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    ic.Instance.Position = UDim2.fromScale(0.5, 0.5)

    local tip = Create("TextLabel", {
        BackgroundColor3 = Theme.Secondary,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(1, 10, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        Font = Theme.Font,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 12,
        Visible = false,
        ZIndex = 10,
        Parent = btn,
    })
    Corner(tip, 6)
    Stroke(tip, Theme.Border, 1)
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        Parent = tip,
    })

    local frame = Create("Frame", {
        Name = name .. "_Content",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = self.Content,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = frame,
    })

    local function Column(nameStr, pos)
        local col = Create("ScrollingFrame", {
            Name = nameStr,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = pos,
            Size = UDim2.new(0.5, -5, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = frame,
        })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = col,
        })
        Create("UIPadding", { PaddingRight = UDim.new(0, 4), Parent = col })
        return col
    end

    tab.Button = btn
    tab.Frame = frame
    tab.Left = Column("Left", UDim2.new(0, 0, 0, 0))
    tab.Right = Column("Right", UDim2.new(0.5, 5, 0, 0))
    tab._btn = btn
    tab._stroke = strk
    tab._icon = ic

    btn.MouseEnter:Connect(function()
        tip.Visible = true
        if self.ActiveTab ~= tab then
            Tween(btn, 0.15, { BackgroundTransparency = 0.6 })
            TintIcon(ic, Theme.Text)
        end
    end)
    btn.MouseLeave:Connect(function()
        tip.Visible = false
        if self.ActiveTab ~= tab then
            Tween(btn, 0.15, { BackgroundTransparency = 1 })
            TintIcon(ic, Theme.SubText)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)
    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    if self.ActiveTab == tab then
        return
    end
    for _, t in ipairs(self.Tabs) do
        t.Frame.Visible = false
        t:_SetActive(false)
    end
    self.ActiveTab = tab
    tab.Frame.Visible = true
    tab:_SetActive(true)
end

-- ============ HOME TAB ============
function Window:AddHomeTab(opts)
    opts = opts or {}
    local tab = self:AddTab(opts.Name or "Home", opts.Icon or "house")
    tab.Left:Destroy()
    tab.Right:Destroy()
    self.HomeTab = tab
    local page = tab.Frame

    local avatarBox = Create("ImageLabel", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(64, 64),
        ScaleType = Enum.ScaleType.Crop,
        Parent = page,
    })
    Corner(avatarBox, 12)
    Stroke(avatarBox, Theme.Border, 1)
    LoadAvatar(avatarBox)

    local header = Card(page, UDim2.new(1, -72, 0, 64), Theme.Card)
    header.Position = UDim2.fromOffset(72, 0)
    local hl = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = header })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 2),
        Parent = hl,
    })
    Create("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = hl })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 22),
        LayoutOrder = 1,
        Font = Theme.FontBold,
        Text = opts.Greeting or ("Hello, " .. LocalPlayer.DisplayName),
        TextColor3 = Theme.Text,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hl,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 16),
        LayoutOrder = 2,
        Font = Theme.Font,
        Text = opts.Subtitle or (LocalPlayer.Name .. " - " .. self.Title),
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hl,
    })

    local cols = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 72),
        Size = UDim2.new(1, 0, 1, -72),
        Parent = page,
    })
    local function ColumnFrame(pos)
        local c = Create("Frame", {
            BackgroundTransparency = 1,
            Position = pos,
            Size = UDim2.new(0.5, -4, 1, 0),
            Parent = cols,
        })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = c,
        })
        return c
    end
    local left = ColumnFrame(UDim2.new(0, 0, 0, 0))
    local right = ColumnFrame(UDim2.new(0.5, 4, 0, 0))

    local hasDiscord = opts.Discord ~= nil and opts.Discord ~= ""
    local server = Card(left, hasDiscord and UDim2.new(1, 0, 0.72, -4) or UDim2.new(1, 0, 1, 0), Theme.Card)
    server.LayoutOrder = 1
    Glow(server, Theme.Success, -45, 0.3)
    CardText(server, "Server", "Information on the session you're currently in")

    local grid = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 52),
        Size = UDim2.new(1, -24, 1, -62),
        ZIndex = 2,
        Parent = server,
    })
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = grid })

    local function joinScript()
        local code = string.format(
            'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)',
            game.PlaceId, game.JobId
        )
        local ok = Copy(code)
        VexUI:Notify({
            Title = ok and "Copied" or "Copy failed",
            Description = ok and "Join script copied to clipboard" or "Your executor has no clipboard function",
            Icon = ok and "copy" or "triangle-alert",
        })
    end

    local r1 = TileRow(grid, 1, 1 / 3, -4)
    local tPlayers = StatTile(r1, 1, "Players", "-", 0.38)
    local tMax = StatTile(r1, 2, "Maximum Players", "-", 0.62)
    local r2 = TileRow(grid, 2, 1 / 3, -4)
    local tLatency = StatTile(r2, 1, "Latency", "-", 0.3)
    local tRegion = StatTile(r2, 2, "Server Region", "-", 0.7)
    local r3 = TileRow(grid, 3, 1 / 3, -4)
    local tTime = StatTile(r3, 1, "In server for", "00:00:00", 0.42)
    StatTile(r3, 2, "Join Script", "Tap to copy join script", 0.58, joinScript)

    if hasDiscord then
        local dc = Card(left, UDim2.new(1, 0, 0.28, -4), Color3.new(1, 1, 1), "TextButton")
        dc.LayoutOrder = 2
        Gradient(dc, {
            { 0, Color3.fromRGB(84, 98, 240) },
            { 0.55, Color3.fromRGB(52, 32, 112) },
            { 1, Color3.fromRGB(10, 8, 16) },
        }, 8)
        local dl = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = dc })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = dl,
        })
        Create("UIPadding", { PaddingLeft = UDim.new(0, 14), Parent = dl })
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -14, 0, 24),
            LayoutOrder = 1,
            Font = Theme.FontBold,
            Text = "Discord",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 19,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = dl,
        })
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -14, 0, 16),
            LayoutOrder = 2,
            Font = Theme.Font,
            Text = "Tap to join the Discord Server",
            TextColor3 = Color3.fromRGB(215, 218, 255),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = dl,
        })
        dc.MouseButton1Click:Connect(function()
            task.spawn(JoinDiscord, opts.Discord)
        end)
    end

    local required = opts.RequiredFunctions or { "loadstring" }
    local supported = true
    local env = (getgenv and getgenv()) or _G
    for _, fn in ipairs(required) do
        if env[fn] == nil then
            supported = false
            break
        end
    end

    local exec = Card(right, UDim2.new(1, 0, 0.3, -4), Color3.new(1, 1, 1))
    exec.LayoutOrder = 1
    if supported then
        Gradient(exec, {
            { 0, Color3.fromRGB(150, 38, 46) },
            { 0.6, Color3.fromRGB(58, 18, 22) },
            { 1, Color3.fromRGB(16, 9, 11) },
        }, 20)
    else
        Gradient(exec, {
            { 0, Color3.fromRGB(150, 110, 30) },
            { 0.6, Color3.fromRGB(58, 44, 16) },
            { 1, Color3.fromRGB(16, 12, 8) },
        }, 20)
    end
    CardText(exec, GetExecutorName(), nil, 17)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 32),
        Size = UDim2.new(1, -28, 1, -40),
        Font = Theme.Font,
        Text = supported and "Your executor seems to support this script."
            or "Your executor might not support all features of this script.",
        TextColor3 = Color3.fromRGB(240, 225, 225),
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 2,
        Parent = exec,
    })

    local friends = Card(right, UDim2.new(1, 0, 0.7, -4), Theme.Card)
    friends.LayoutOrder = 2
    Glow(friends, Theme.Warning, -135, 0.25)
    CardText(friends, "Friends", "Find out what your friends are currently doing", 17, 0.62)

    local fgrid = Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 12, 1, -12),
        Size = UDim2.new(1, -24, 0, 106),
        ZIndex = 2,
        Parent = friends,
    })
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = fgrid })
    local fr1 = TileRow(fgrid, 1, 0.5, -3)
    local tInServer = StatTile(fr1, 1, "In Server", "-", 0.5)
    local tOffline = StatTile(fr1, 2, "Offline", "-", 0.5)
    local fr2 = TileRow(fgrid, 2, 0.5, -3)
    local tOnline = StatTile(fr2, 1, "Online", "-", 0.5)
    local tAll = StatTile(fr2, 2, "All", "-", 0.5)

    local function refreshLive()
        tPlayers.Set(#Players:GetPlayers() .. " playing")
        tMax.Set(Players.MaxPlayers .. " players can join this server")
        local ping = GetPing()
        tLatency.Set(ping and (ping .. "ms") or "N/A")
        tTime.Set(FormatTime(time()))
    end

    local function refreshFriends()
        task.spawn(function()
            local inServer = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local ok, isFriend = pcall(LocalPlayer.IsFriendsWith, LocalPlayer, p.UserId)
                    if ok and isFriend then
                        inServer = inServer + 1
                    end
                end
            end

            local online = 0
            local okOn, list = pcall(function()
                return LocalPlayer:GetFriendsOnline(200)
            end)
            if okOn and type(list) == "table" then
                online = #list
            end

            local total = 0
            local okAll, pages = pcall(Players.GetFriendsAsync, Players, LocalPlayer.UserId)
            if okAll and pages then
                pcall(function()
                    while true do
                        total = total + #pages:GetCurrentPage()
                        if pages.IsFinished then
                            break
                        end
                        pages:AdvanceToNextPageAsync()
                    end
                end)
            end

            tInServer.Set(Plural(inServer, "friend"))
            tOnline.Set(Plural(online, "friend"))
            tAll.Set(Plural(total, "friend"))
            tOffline.Set(Plural(math.max(total - online, 0), "friend"))
        end)
    end

    task.spawn(function()
        local ok, region = pcall(function()
            return LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
        end)
        tRegion.Set(ok and region or "N/A")
    end)

    task.spawn(function()
        local n = 0
        while self.Alive and not VexUI.Unloaded do
            pcall(refreshLive)
            if n % 60 == 0 then
                refreshFriends()
            end
            n = n + 1
            task.wait(1)
        end
    end)

    tab.Refresh = function()
        pcall(refreshLive)
        refreshFriends()
    end
    return tab
end

-- ============ INFO TAB ============
function Window:AddInfoTab(opts)
    opts = opts or {}
    local tab = self:AddTab(opts.Name or "Info", opts.Icon or "info")
    tab.Left:Destroy()
    tab.Right:Destroy()
    local page = tab.Frame

    local hero = Card(page, UDim2.new(1, 0, 0, 100), Theme.Card)
    Gradient(hero, {
        { 0, Theme.Card },
        { 0.5, Color3.fromRGB(14, 14, 20) },
        { 1, Theme.Card },
    }, 135)
    Glow(hero, Theme.Accent, -45, 0.3)

    local heroIcon = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(20, 20),
        Size = UDim2.fromOffset(60, 60),
        Parent = hero,
    })
    Corner(heroIcon, 14)
    Gradient(heroIcon, {
        { 0, Theme.Accent },
        { 1, Theme.AccentDark },
    }, 45)
    local hi = NewIcon(heroIcon, opts.Icon or "shield-check", 30, Color3.new(1, 1, 1), "R")
    hi.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    hi.Instance.Position = UDim2.fromScale(0.5, 0.5)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(96, 24),
        Size = UDim2.new(1, -110, 0, 24),
        Font = Theme.FontBold,
        Text = opts.Title or "Ravine",
        TextColor3 = Theme.Text,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hero,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(96, 52),
        Size = UDim2.new(1, -110, 0, 16),
        Font = Theme.Font,
        Text = opts.Subtitle or "Advanced Utility Suite",
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hero,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(96, 72),
        Size = UDim2.new(1, -110, 0, 14),
        Font = Theme.Font,
        Text = "v" .. (opts.Version or "1.0.0"),
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hero,
    })

    local cols = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 112),
        Size = UDim2.new(1, 0, 1, -112),
        Parent = page,
    })
    local function Col(pos)
        local c = Create("Frame", {
            BackgroundTransparency = 1,
            Position = pos,
            Size = UDim2.new(0.5, -5, 1, 0),
            Parent = cols,
        })
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = c })
        return c
    end
    local left = Col(UDim2.new(0, 0, 0, 0))
    local right = Col(UDim2.new(0.5, 5, 0, 0))

    local serverCard = Card(left, UDim2.new(1, 0, 0, 240), Theme.Card)
    serverCard.LayoutOrder = 1
    Glow(serverCard, Theme.Success, -45, 0.25)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.new(1, -28, 0, 18),
        Font = Theme.FontBold,
        Text = "Server Information",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = serverCard,
    })

    local function infoRow(parent, order, label, value)
        local r = Create("Frame", {
            BackgroundColor3 = Theme.Tertiary,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -24, 0, 32),
            Position = UDim2.fromOffset(12, 36 + (order - 1) * 36),
            Parent = parent,
        })
        Corner(r, 6)
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            Font = Theme.Font,
            Text = label,
            TextColor3 = Theme.SubText,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = r,
        })
        local vl = Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.5, -10, 1, 0),
            Font = Theme.FontBold,
            Text = tostring(value),
            TextColor3 = Theme.Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = r,
        })
        return vl
    end

    infoRow(serverCard, 1, "Job ID", game.JobId:sub(1, 8) .. "...")
    infoRow(serverCard, 2, "Place ID", tostring(game.PlaceId))
    local pingLbl = infoRow(serverCard, 3, "Ping", "-")
    local playersLbl = infoRow(serverCard, 4, "Players", "-")
    infoRow(serverCard, 5, "Max Players", tostring(game.Players.MaxPlayers))

    local execCard = Card(right, UDim2.new(1, 0, 0, 130), Theme.Card)
    execCard.LayoutOrder = 1
    Glow(execCard, Theme.Warning, -135, 0.2)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.new(1, -28, 0, 18),
        Font = Theme.FontBold,
        Text = "Executor",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = execCard,
    })

    local execName = GetExecutorName()
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 38),
        Size = UDim2.new(1, -28, 0, 20),
        Font = Theme.FontBold,
        Text = execName,
        TextColor3 = Theme.Accent,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = execCard,
    })

    local okCount = 0
    local total = 4
    local checks = {
        loadstring ~= nil,
        getgc ~= nil,
        hookfunction ~= nil,
        (setclipboard ~= nil or toclipboard ~= nil),
    }
    for _, c in ipairs(checks) do
        if c then okCount = okCount + 1 end
    end

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 62),
        Size = UDim2.new(1, -28, 0, 14),
        Font = Theme.Font,
        Text = "Compat: " .. okCount .. "/" .. total .. " functions",
        TextColor3 = Theme.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = execCard,
    })

    local barBg = Create("Frame", {
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 84),
        Size = UDim2.new(1, -28, 0, 6),
        Parent = execCard,
    })
    Corner(barBg, 3)
    local barFill = Create("Frame", {
        BackgroundColor3 = okCount >= 3 and Theme.Success or Theme.Warning,
        BorderSizePixel = 0,
        Size = UDim2.new(okCount / total, 0, 1, 0),
        Parent = barBg,
    })
    Corner(barFill, 3)

    if opts.Discord then
        local dcCard = Card(right, UDim2.new(1, 0, 0, 80), Color3.new(1, 1, 1), "TextButton")
        dcCard.LayoutOrder = 2
        Gradient(dcCard, {
            { 0, Color3.fromRGB(88, 101, 242) },
            { 0.55, Color3.fromRGB(52, 32, 112) },
            { 1, Color3.fromRGB(14, 12, 24) },
        }, 8)

        local dl = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = dcCard })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            Parent = dl,
        })
        Create("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = dl })
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 22),
            LayoutOrder = 1,
            Font = Theme.FontBold,
            Text = "Join our Discord",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = dl,
        })
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 14),
            LayoutOrder = 2,
            Font = Theme.Font,
            Text = opts.Discord,
            TextColor3 = Color3.fromRGB(215, 218, 255),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = dl,
        })

        dcCard.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard("https://" .. opts.Discord) end
            VexUI:Notify({ Title = "Discord", Description = "Link copied!", Icon = "circle-check" })
        end)
    end

    task.spawn(function()
        while self.Alive and not VexUI.Unloaded do
            pcall(function()
                local ok, ping = pcall(function()
                    return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                pingLbl.Text = ok and (ping .. "ms") or "N/A"
                playersLbl.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
            end)
            task.wait(2)
        end
    end)

    return tab
end

-- ============ SETTINGS TAB ============
function Window:AddSettingsTab(opts)
    opts = opts or {}
    local tab = self:AddTab(opts.Name or "Settings", opts.Icon or "settings")

    local menu = tab:AddLeftGroupbox("Menu", "layout-dashboard")
    local keybind = menu:AddKeyPicker("VexUI_MenuKey", {
        Text = "Menu keybind",
        Default = self.ToggleKeybind.Name,
    })
    keybind:OnChanged(function(keyName)
        local ok, key = pcall(function()
            return Enum.KeyCode[keyName]
        end)
        if ok and key then
            self.ToggleKeybind = key
        end
    end)
    menu:AddButton("Unload UI", {
        Icon = "power",
        Callback = function()
            VexUI:Unload()
        end,
    })

    local cfg = tab:AddRightGroupbox("Config", "save")
    local nameBox = cfg:AddTextbox("VexUI_ConfigName", { Text = "Config name", Placeholder = "default" })
    local list = cfg:AddDropdown("VexUI_ConfigList", { Text = "Configs", Values = VexUI:ListConfigs() })

    local function currentName()
        local n = nameBox.Get()
        if n == "" then
            n = list.Get()
        end
        return n
    end

    cfg:AddButton("Save config", {
        Icon = "save",
        Callback = function()
            local n = currentName()
            local ok, err = VexUI:SaveConfig(n)
            VexUI:Notify({
                Title = ok and "Config saved" or "Save failed",
                Description = ok and n or tostring(err),
                Icon = ok and "circle-check" or "triangle-alert",
            })
            list.Refresh(VexUI:ListConfigs())
        end,
    })
    cfg:AddButton("Load config", {
        Icon = "folder",
        Callback = function()
            local n = currentName()
            local ok, err = VexUI:LoadConfig(n)
            VexUI:Notify({
                Title = ok and "Config loaded" or "Load failed",
                Description = ok and n or tostring(err),
                Icon = ok and "circle-check" or "triangle-alert",
            })
        end,
    })
    cfg:AddButton("Refresh list", {
        Icon = "refresh-cw",
        Callback = function()
            list.Refresh(VexUI:ListConfigs())
        end,
    })

    return tab
end

-- ============ TAB METHODS ============
function Tab:_SetActive(active)
    Tween(self._btn, 0.15, { BackgroundTransparency = active and 0 or 1 })
    Tween(self._stroke, 0.15, { Transparency = active and 0 or 1 })
    TintIcon(self._icon, active and Theme.Text or Theme.SubText)
end

function Tab:AddLeftGroupbox(name, icon)
    return self:_AddGroupbox(name, icon, self.Left)
end

function Tab:AddRightGroupbox(name, icon)
    return self:_AddGroupbox(name, icon, self.Right)
end

-- *** FIXED GROUPBOX: outer + inner frame with 1px padding = perfect border ***
function Tab:_AddGroupbox(name, icon, column)
    local box = setmetatable({
        Name = name,
        Tab = self,
        Column = column,
        _n = 0,
    }, Groupbox)

    -- OUTER = border color
    local outer = Create("Frame", {
        Name = name .. "_Outer",
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self.Groupboxes + 1,
        Parent = column,
    })
    Corner(outer, 9)
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 1),
        PaddingBottom = UDim.new(0, 1),
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 1),
        Parent = outer,
    })

    -- INNER = actual content
    local frame = Create("Frame", {
        Name = name,
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = outer,
    })
    Corner(frame, 8)
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })

    local titleFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = 1,
        Parent = frame,
    })
    local x = 12
    if icon then
        local ic = NewIcon(titleFrame, icon, 16, Theme.Accent, "")
        ic.Instance.Position = UDim2.new(0, 12, 0.5, -8)
        x = 34
    end
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(1, -x - 12, 1, 0),
        Font = Theme.FontBold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleFrame,
    })
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        LayoutOrder = 2,
        Parent = frame,
    })

    local container = Create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
        Parent = frame,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = container,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = container,
    })

    box.Frame = frame
    box.Outer = outer
    box.Container = container
    box.Scroll = container
    table.insert(self.Groupboxes, box)
    return box
end

-- ============ GROUPBOX ELEMENTS ============
local function Add(self, className, props)
    self._n = self._n + 1
    props.LayoutOrder = self._n
    props.Parent = self.Container
    return Create(className, props)
end

local function AddRow(self, height, clip)
    local row = Add(self, "Frame", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 34),
        ClipsDescendants = clip or false,
    })
    Corner(row, 6)
    Stroke(row, Theme.Border, 1)
    return row
end

local function RowLabel(row, text, rightInset)
    return Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -(12 + (rightInset or 12)), 0, 34),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
end

local function HitButton(row, height)
    return Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 34),
        Text = "",
        Parent = row,
    })
end

function Groupbox:AddDivider()
    return Add(self, "Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
    })
end

function Groupbox:AddLabel(text)
    return Add(self, "TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
end

function Groupbox:AddButton(name, opts)
    if type(opts) == "function" then
        opts = { Callback = opts }
    end
    opts = opts or {}
    local callback = opts.Callback or function() end

    local btn = Add(self, "TextButton", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        Font = Theme.Font,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        AutoButtonColor = false,
    })
    Corner(btn, 6)
    local strk = Stroke(btn, Theme.Border, 1)

    if opts.Icon then
        local ic = NewIcon(btn, opts.Icon, 16, Theme.Text, "")
        ic.Instance.Position = UDim2.new(0, 12, 0.5, -8)
    end

    btn.MouseEnter:Connect(function()
        Tween(btn, 0.15, { BackgroundColor3 = Theme.Accent })
        Tween(strk, 0.15, { Color = Theme.Accent })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.15, { BackgroundColor3 = Theme.Tertiary })
        Tween(strk, 0.15, { Color = Theme.Border })
    end)
    btn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)

    return btn
end

function Groupbox:AddToggle(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local state = opts.Default or false
    local obj, changed = NewOption("Toggle", id, state)

    local row = AddRow(self, 34)
    RowLabel(row, opts.Text or id, 60)

    local track = Create("Frame", {
        BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -46, 0.5, -10),
        Size = UDim2.fromOffset(36, 20),
        Parent = row,
    })
    Corner(track, 10)
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        Parent = track,
    })
    Corner(thumb, 8)

    local function setState(v)
        state = v and true or false
        Tween(track, 0.15, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff })
        Tween(thumb, 0.15, {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        })
        changed(state)
        task.spawn(callback, state)
    end

    HitButton(row, 34).MouseButton1Click:Connect(function()
        setState(not state)
    end)

    obj.Container = row
    obj.Set = setState
    obj.Get = function()
        return state
    end
    function obj:SetValue(v)
        setState(v)
    end
    return obj
end

function Groupbox:AddSlider(id, opts)
    opts = opts or {}
    local min = opts.Min or 0
    local max = opts.Max or 100
    local callback = opts.Callback or function() end
    local suffix = opts.Suffix or ""
    local rounding = opts.Rounding or 0
    local range = math.max(max - min, 1e-9)
    local value = math.clamp(opts.Default or min, min, max)
    local obj, changed = NewOption("Slider", id, value)

    local row = AddRow(self, 46)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 4),
        Size = UDim2.new(1, -80, 0, 18),
        Font = Theme.Font,
        Text = opts.Text or id,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -62, 0, 4),
        Size = UDim2.new(0, 50, 0, 18),
        Font = Theme.FontBold,
        Text = tostring(value) .. suffix,
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local barBg = Create("Frame", {
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 6),
        Parent = row,
    })
    Corner(barBg, 3)
    local fill = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new((value - min) / range, 0, 1, 0),
        Parent = barBg,
    })
    Corner(fill, 3)
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / range, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        ZIndex = 2,
        Parent = barBg,
    })
    Corner(thumb, 6)

    local hit = Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 24),
        Text = "",
        Parent = row,
    })

    local function render(v, time)
        local rel = (v - min) / range
        Tween(fill, time, { Size = UDim2.new(rel, 0, 1, 0) })
        Tween(thumb, time, { Position = UDim2.new(rel, 0, 0.5, 0) })
        valueLabel.Text = tostring(v) .. suffix
    end

    local function setValue(v, time)
        value = math.clamp(Round(v, rounding), min, max)
        render(value, time or 0.05)
        changed(value)
        task.spawn(callback, value)
    end

    TrackDrag(hit, self.Column, function(pos)
        local rel = math.clamp((pos.X - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1), 0, 1)
        setValue(min + range * rel)
    end)

    obj.Set = function(v)
        setValue(v, 0.1)
    end
    obj.Get = function()
        return value
    end
    function obj:SetValue(v)
        setValue(v, 0.1)
    end
    return obj
end

function Groupbox:AddDropdown(id, opts)
    opts = opts or {}
    local values = opts.Values or {}
    local callback = opts.Callback or function() end
    local current = opts.Default or (values[1] or "")
    local open = false
    local obj, changed = NewOption("Dropdown", id, current)

    local row = AddRow(self, 34, true)
    RowLabel(row, opts.Text or id, 130)

    local currentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -130, 0, 0),
        Size = UDim2.new(0, 104, 0, 34),
        Font = Theme.Font,
        Text = tostring(current),
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })
    local arrow = NewIcon(row, "chevron-down", 14, Theme.SubText, "v")
    arrow.Instance.Position = UDim2.new(1, -22, 0, 10)

    local hit = HitButton(row, 34)

    local list = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, 38),
        Size = UDim2.new(1, -12, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        Visible = false,
        Parent = row,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = list,
    })

    local buttons = {}
    local function listHeight()
        return math.min(#values * 26, 130)
    end

    local function setOpen(v)
        open = v
        if v then
            list.Visible = true
            Tween(row, 0.18, { Size = UDim2.new(1, 0, 0, 38 + listHeight() + 6) })
            Tween(list, 0.18, { Size = UDim2.new(1, -12, 0, listHeight()) })
        else
            Tween(row, 0.18, { Size = UDim2.new(1, 0, 0, 34) })
            Tween(list, 0.18, { Size = UDim2.new(1, -12, 0, 0) })
            task.delay(0.18, function()
                if not open then
                    list.Visible = false
                end
            end)
        end
    end

    local function select(val)
        current = val
        currentLabel.Text = tostring(val)
        for _, b in ipairs(buttons) do
            b.TextColor3 = (b.Text == tostring(current)) and Theme.Accent or Theme.Text
        end
        changed(val)
        task.spawn(callback, val)
    end

    local function refresh()
        for _, b in ipairs(buttons) do
            b:Destroy()
        end
        buttons = {}
        for i, val in ipairs(values) do
            local option = Create("TextButton", {
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 24),
                LayoutOrder = i,
                Font = Theme.Font,
                Text = tostring(val),
                TextColor3 = (tostring(val) == tostring(current)) and Theme.Accent or Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                Parent = list,
            })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = option })
            Corner(option, 4)
            option.MouseEnter:Connect(function()
                Tween(option, 0.1, { BackgroundTransparency = 0.7 })
            end)
            option.MouseLeave:Connect(function()
                Tween(option, 0.1, { BackgroundTransparency = 1 })
            end)
            option.MouseButton1Click:Connect(function()
                select(val)
                setOpen(false)
            end)
            table.insert(buttons, option)
        end
    end
    refresh()

    hit.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)

    obj.Container = row
    obj.Set = function(v)
        select(v)
    end
    obj.Get = function()
        return current
    end
    obj.Refresh = function(newValues)
        values = newValues
        refresh()
        if open then
            setOpen(true)
        end
    end
    function obj:SetValue(v)
        select(v)
    end
    return obj
end

function Groupbox:AddTextbox(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local obj, changed = NewOption("Textbox", id, opts.Default or "")

    local row = AddRow(self, 42)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 5),
        Size = UDim2.new(1, -24, 0, 14),
        Font = Theme.Font,
        Text = opts.Text or id,
        TextColor3 = Theme.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local box = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 21),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Theme.Font,
        Text = opts.Default or "",
        PlaceholderText = opts.Placeholder or "",
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = row,
    })

    box.FocusLost:Connect(function()
        changed(box.Text)
        task.spawn(callback, box.Text)
    end)

    obj.Instance = box
    obj.Container = row
    obj.Set = function(t)
        box.Text = tostring(t)
        changed(box.Text)
        task.spawn(callback, box.Text)
    end
    obj.Get = function()
        return box.Text
    end
    function obj:SetValue(t)
        obj.Set(t)
    end
    return obj
end

function Groupbox:AddColorPicker(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local color = opts.Default or Color3.fromRGB(255, 255, 255)
    local h, s, v = Color3.toHSV(color)
    local open = false
    local PICK_H = 100
    local obj, changed = NewOption("ColorPicker", id, color)

    local row = AddRow(self, 34, true)
    RowLabel(row, opts.Text or id, 60)

    local swatch = Create("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -40, 0, 7),
        Size = UDim2.fromOffset(28, 20),
        Parent = row,
    })
    Corner(swatch, 4)
    Stroke(swatch, Theme.Border, 1)
    local hit = HitButton(row, 34)

    local area = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 40),
        Size = UDim2.new(1, -20, 0, PICK_H),
        Parent = row,
    })
    local sv = Create("Frame", {
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -24, 1, 0),
        Parent = area,
    })
    Corner(sv, 4)
    local white = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1,
        Parent = sv,
    })
    Corner(white, 4)
    Create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
        Parent = sv,
    })
    Corner(black, 4)
    Create("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = black })
    local svCursor = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        ZIndex = 3,
        Parent = sv,
    })
    Corner(svCursor, 4)
    Stroke(svCursor, Color3.new(0, 0, 0), 1)

    local hueBar = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -16, 0, 0),
        Size = UDim2.new(0, 16, 1, 0),
        Parent = area,
    })
    Corner(hueBar, 4)
    local hueKeys = {}
    for i = 0, 6 do
        table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.999), 1, 1)))
    end
    Create("UIGradient", { Color = ColorSequence.new(hueKeys), Rotation = 90, Parent = hueBar })
    local hueCursor = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 4, 0, 3),
        ZIndex = 3,
        Parent = hueBar,
    })
    Stroke(hueCursor, Color3.new(0, 0, 0), 1)

    local function render()
        color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = color
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0.5, h)
    end
    local function commit()
        render()
        changed(color)
        task.spawn(callback, color)
    end
    render()

    TrackDrag(sv, self.Column, function(pos)
        s = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
        v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        commit()
    end)
    TrackDrag(hueBar, self.Column, function(pos)
        h = math.clamp((pos.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 1)
        commit()
    end)

    hit.MouseButton1Click:Connect(function()
        open = not open
        Tween(row, 0.18, { Size = UDim2.new(1, 0, 0, open and (40 + PICK_H + 10) or 34) })
    end)

    obj.Container = row
    obj.Set = function(c)
        h, s, v = Color3.toHSV(c)
        commit()
    end
    obj.Get = function()
        return color
    end
    function obj:SetValue(c)
        obj.Set(c)
    end
    return obj
end

function Groupbox:AddKeyPicker(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local current = opts.Default or "F"
    local listening = false
    local obj, changed = NewOption("KeyPicker", id, current)

    local row = AddRow(self, 34)
    RowLabel(row, opts.Text or id, 82)

    local keyLabel = Create("TextButton", {
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -70, 0.5, -10),
        Size = UDim2.fromOffset(58, 20),
        Font = Theme.FontBold,
        Text = current,
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
        Parent = row,
    })
    Corner(keyLabel, 4)
    Stroke(keyLabel, Theme.Border, 1)

    keyLabel.MouseButton1Click:Connect(function()
        listening = true
        keyLabel.Text = "..."
    end)

    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then
            return
        end
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                if input.KeyCode ~= Enum.KeyCode.Escape then
                    current = input.KeyCode.Name
                    changed(current)
                end
                keyLabel.Text = current
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == current then
            task.spawn(callback)
        end
    end)

    obj.Container = row
    obj.Set = function(k)
        current = k
        keyLabel.Text = k
        changed(k)
    end
    obj.Get = function()
        return current
    end
    function obj:SetValue(k)
        obj.Set(k)
    end
    return obj
end

-- ============ INIT ============
return VexUI
