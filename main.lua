--[[
    VexUI v3 - Modern Dashboard UI
]]

local VexUI = {
    Version = "3.0.0",
    Toggles = {},
    Options = {},
    CustomIcons = {},
    Gui = nil,
    NotifGui = nil,
    Unloaded = false,
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
    Background      = Color3.fromRGB(11, 11, 15),
    BackgroundAlt   = Color3.fromRGB(15, 15, 20),
    Surface         = Color3.fromRGB(21, 21, 28),
    SurfaceHover    = Color3.fromRGB(28, 28, 38),
    SurfaceActive   = Color3.fromRGB(36, 36, 48),
    SurfaceDeep     = Color3.fromRGB(15, 15, 20),
    Card            = Color3.fromRGB(18, 18, 24),
    Groupbox        = Color3.fromRGB(17, 17, 23),
    Element         = Color3.fromRGB(24, 24, 32),
    ElementHover    = Color3.fromRGB(32, 32, 42),
    Border          = Color3.fromRGB(38, 38, 50),
    BorderSubtle    = Color3.fromRGB(28, 28, 38),
    TextPrimary     = Color3.fromRGB(245, 245, 250),
    TextSecondary   = Color3.fromRGB(160, 160, 180),
    TextMuted       = Color3.fromRGB(105, 105, 128),
    Accent          = Color3.fromRGB(230, 40, 55),
    AccentBright    = Color3.fromRGB(255, 75, 95),
    AccentDark      = Color3.fromRGB(140, 20, 32),
    ToggleOff       = Color3.fromRGB(50, 50, 62),
    Success         = Color3.fromRGB(60, 210, 130),
    Warning         = Color3.fromRGB(240, 190, 70),
    Font            = Enum.Font.Gotham,
    FontMedium      = Enum.Font.GothamMedium,
    FontBold        = Enum.Font.GothamBold,
    R_Window        = 14,
    R_Groupbox      = 12,
    R_Card          = 10,
    R_Element       = 8,
    R_Small         = 6,
    R_Pill          = 999,
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
        if k == "Parent" then parent = v else inst[k] = v end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Corner(inst, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or Theme.R_Element), Parent = inst })
end

local function Stroke(inst, color, thickness, trans)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = trans or 0,
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
    return Create("UIGradient", { Color = ColorSequence.new(seq), Rotation = rotation or 0, Parent = frame })
end

local function Glow(parent, color, rotation, strength)
    local g = Create("Frame", {
        BackgroundColor3 = color, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = parent,
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
    if n == 0 then return "no " .. word .. "s" end
    return n .. " " .. word .. (n == 1 and "" or "s")
end

local function Copy(text)
    local fn = setclipboard or toclipboard or set_clipboard
    if fn then return pcall(fn, text) end
    return false
end

-- ============ DRAGGABLE ============
local function MakeDraggable(frame, handle, getScale)
    local state = { Moved = 0, Dragging = false }
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            state.Dragging = true
            state.Moved = 0
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    state.Dragging = false
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local s = getScale and getScale() or 1
        local d = (input.Position - dragStart) / s
        state.Moved = math.max(state.Moved, d.Magnitude)
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end)

    return state
end

local function TrackDrag(hit, column, onMove)
    local dragging = false
    local function setScroll(v)
        if column then column.ScrollingEnabled = v end
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
    if ok and type(mod) == "table" then IconModule = mod end
end

local IconAliases = { home = "house", gear = "settings", close = "x", plus = "plus", search = "search" }

function VexUI:SetIconModule(mod) IconModule = mod end

function VexUI:AddIcon(name, asset)
    local url = type(asset) == "number" and ("rbxassetid://" .. asset) or asset
    self.CustomIcons[name] = { Url = url, ImageRectOffset = Vector2.new(0, 0), ImageRectSize = Vector2.new(0, 0) }
end

function VexUI:GetIcon(icon)
    local t = type(icon)
    if t == "table" then return icon.Url and icon or nil end
    if t == "number" then return { Url = "rbxassetid://" .. icon, ImageRectOffset = Vector2.new(0, 0), ImageRectSize = Vector2.new(0, 0) } end
    if t ~= "string" or icon == "" then return nil end
    if self.CustomIcons[icon] then return self.CustomIcons[icon] end
    if icon:sub(1, 13) == "rbxassetid://" or icon:sub(1, 4) == "http" then
        return { Url = icon, ImageRectOffset = Vector2.new(0, 0), ImageRectSize = Vector2.new(0, 0) }
    end
    if tonumber(icon) then return self:GetIcon(tonumber(icon)) end
    local name = (icon:gsub("^lucide[-:]", ""))
    name = IconAliases[name] or name
    if IconModule and IconModule.GetAsset then
        local ok, data = pcall(IconModule.GetAsset, name)
        if ok and data then return data end
    end
    return nil
end

local function SetIcon(img, icon)
    local data = VexUI:GetIcon(icon)
    if not data then return false end
    img.Image = data.Url
    img.ImageRectOffset = data.ImageRectOffset or Vector2.new(0, 0)
    img.ImageRectSize = data.ImageRectSize or Vector2.new(0, 0)
    return true
end

local function NewIcon(parent, icon, px, color, fallback)
    local img = Create("ImageLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(px, px),
        ImageColor3 = color, ScaleType = Enum.ScaleType.Fit, Parent = parent,
    })
    if SetIcon(img, icon) then return { Instance = img, Prop = "ImageColor3", Ok = true } end
    img:Destroy()
    local lbl = Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(px, px),
        Font = Theme.FontBold, Text = fallback or "?", TextColor3 = color,
        TextSize = math.floor(px * 0.85), Parent = parent,
    })
    return { Instance = lbl, Prop = "TextColor3", Ok = false }
end

local function TintIcon(ic, color, time) Tween(ic.Instance, time or 0.15, { [ic.Prop] = color }) end

-- ============ OPTIONS ============
local function NewOption(kind, id, value)
    local obj = { Type = kind, Id = id, Value = value, _changed = {} }
    function obj:OnChanged(fn) table.insert(self._changed, fn); return self end
    local function changed(v)
        obj.Value = v
        for _, fn in ipairs(obj._changed) do task.spawn(fn, v) end
    end
    local registry = (kind == "Toggle") and VexUI.Toggles or VexUI.Options
    registry[id] = obj
    return obj, changed
end

local function GetGuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    return CoreGui
end

local function EnsureGui()
    if VexUI.Gui and VexUI.Gui.Parent then return VexUI.Gui end
    VexUI.Gui = Create("ScreenGui", {
        Name = "VexUI", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100, Parent = GetGuiParent(),
    })
    return VexUI.Gui
end

-- ============ NOTIFICATIONS ============
local NotifContainer

local function EnsureNotifContainer()
    if NotifContainer and NotifContainer.Parent then return NotifContainer end
    VexUI.NotifGui = Create("ScreenGui", {
        Name = "VexUI_Notifs", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 101, Parent = GetGuiParent(),
    })
    NotifContainer = Create("Frame", {
        Name = "Container", BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 320, 1, -40),
        AnchorPoint = Vector2.new(1, 1), Parent = VexUI.NotifGui,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8), Parent = NotifContainer,
    })
    return NotifContainer
end

function VexUI:Notify(opts)
    if type(opts) == "string" then opts = { Description = opts } end
    opts = opts or {}
    local container = EnsureNotifContainer()
    local title = opts.Title or "Notification"
    local text = opts.Description or opts.Text or ""
    local duration = opts.Time or 4

    local holder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 64), Parent = container,
    })
    local notif = Create("Frame", {
        Name = "Notif", BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
        Position = UDim2.new(1, 350, 0, 0), ClipsDescendants = true, Parent = holder,
    })
    Corner(notif, 10)
    Stroke(notif, Theme.BorderSubtle, 1, 0.5)

    local accent = Create("Frame", {
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 3, 1, -24), Parent = notif,
    })
    Corner(accent, 3)

    local iconBox = Create("Frame", {
        BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85,
        BorderSizePixel = 0, Position = UDim2.new(0, 14, 0.5, -18),
        Size = UDim2.fromOffset(36, 36), Parent = notif,
    })
    Corner(iconBox, 10)
    local ic = NewIcon(iconBox, opts.Icon or "bell", 18, Theme.AccentBright, "!")
    ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    ic.Instance.Position = UDim2.fromScale(0.5, 0.5)

    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 60, 0, 14),
        Size = UDim2.new(1, -72, 0, 18), Font = Theme.FontBold,
        Text = title, TextColor3 = Theme.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = notif,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 60, 0, 32),
        Size = UDim2.new(1, -72, 1, -36), Font = Theme.Font,
        Text = text, TextColor3 = Theme.TextSecondary, TextSize = 12,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Parent = notif,
    })

    Tween(notif, 0.25, { Position = UDim2.new(0, 0, 0, 0) })

    task.delay(duration, function()
        pcall(function() Tween(notif, 0.25, { Position = UDim2.new(1, 350, 0, 0) }) end)
        task.wait(0.3); holder:Destroy()
    end)
end

-- ============ CONFIG ============
local ConfigFolder = "VexUI/configs"
local function HasFS() return writefile and readfile and isfile and isfolder and makefolder end
local function EnsureFolders()
    if not isfolder("VexUI") then makefolder("VexUI") end
    if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
end

function VexUI:SaveConfig(name)
    if not name or name == "" then return false, "No name" end
    if not HasFS() then return false, "No filesystem" end
    local data = {}
    for id, o in pairs(self.Toggles) do
        if id:sub(1, 6) ~= "VexUI_" then data[id] = { t = o.Type, v = o.Value } end
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
    if not name or name == "" then return false, "No name" end
    if not HasFS() then return false, "No filesystem" end
    local path = ConfigFolder .. "/" .. name .. ".json"
    if not isfile(path) then return false, "Not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return false, "Corrupt" end
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
    if not (HasFS() and listfiles) then return out end
    pcall(function()
        EnsureFolders()
        for _, path in ipairs(listfiles(ConfigFolder)) do
            local n = path:match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end)
    table.sort(out)
    return out
end

function VexUI:Unload()
    self.Unloaded = true
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
    if self.Gui then self.Gui:Destroy() end
    if self.NotifGui then self.NotifGui:Destroy() end
    table.clear(self.Toggles); table.clear(self.Options)
    if GENV.VexUI_Instance == self then GENV.VexUI_Instance = nil end
end

-- ============ HELPERS ============
local AvatarCache
local function LoadAvatar(img)
    task.spawn(function()
        if not AvatarCache then
            local ok, url = pcall(Players.GetUserThumbnailAsync, Players, LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            if ok then AvatarCache = url end
        end
        if AvatarCache and img.Parent then img.Image = AvatarCache end
    end)
end

local function Card(parent, size, bg, class)
    local isButton = class == "TextButton"
    local f = Create(class or "Frame", {
        BackgroundColor3 = bg or Theme.Card,
        BorderSizePixel = 0, Size = size, Parent = parent,
    })
    if isButton then f.Text = ""; f.AutoButtonColor = false end
    Corner(f, Theme.R_Card)
    return f
end

local function CardText(card, title, desc, titleSize, descScale)
    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 12),
        Size = UDim2.new(1, -32, 0, 20), Font = Theme.FontBold,
        Text = title, TextColor3 = Theme.TextPrimary, TextSize = titleSize or 15,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = card,
    })
    if desc then
        Create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 34),
            Size = UDim2.new(descScale or 1, -32, 0, 28), Font = Theme.Font,
            Text = desc, TextColor3 = Theme.TextSecondary, TextSize = 11,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 2, Parent = card,
        })
    end
end

local function TileRow(parent, order, hScale, hOffset)
    local r = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, hScale, hOffset),
        LayoutOrder = order, Parent = parent,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6), Parent = r,
    })
    return r
end

local function StatTile(row, order, title, value, wScale, onClick)
    local btn = Create("TextButton", {
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
        Size = UDim2.new(wScale, -3, 1, 0), LayoutOrder = order,
        Text = "", AutoButtonColor = false, Parent = row,
    })
    Corner(btn, 8)

    local holder = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = btn })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 2), Parent = holder,
    })
    Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8), Parent = holder })

    Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15),
        LayoutOrder = 1, Font = Theme.FontBold, Text = title,
        TextColor3 = Theme.TextPrimary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
    })
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 12),
        LayoutOrder = 2, Font = Theme.Font, Text = value,
        TextColor3 = Theme.TextSecondary, TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
    })

    if onClick then
        btn.MouseEnter:Connect(function() Tween(btn, 0.15, { BackgroundColor3 = Theme.ElementHover }) end)
        btn.MouseLeave:Connect(function() Tween(btn, 0.15, { BackgroundColor3 = Theme.Element }) end)
        btn.MouseButton1Click:Connect(function() task.spawn(onClick) end)
    end

    return { Button = btn, Set = function(text) valueLabel.Text = text end }
end

local function JoinDiscord(invite)
    local code = invite:match("discord%.gg/([%w%-_]+)") or invite:match("discord%.com/invite/([%w%-_]+)") or invite
    Copy("https://discord.gg/" .. code)
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if req then
        pcall(req, {
            Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["Origin"] = "https://discord.com" },
            Body = HttpService:JSONEncode({ cmd = "INVITE_BROWSER", args = { code = code }, nonce = HttpService:GenerateGUID(false) }),
        })
    end
    VexUI:Notify({ Title = "Discord", Description = "Invite copied: discord.gg/" .. code, Icon = "circle-check" })
end

local function GetPing()
    local ok, v = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    return ok and v or nil
end
local function GetExecutorName()
    local ok, name = pcall(function() return identifyexecutor() end)
    return (ok and name) or "Unknown executor"
end

-- ============ WINDOW ============
function VexUI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "VexUI"
    local subtitle = opts.Subtitle or ""
    local size = opts.Size or UDim2.fromOffset(720, 440)
    local gui = EnsureGui()

    local shadow = Create("ImageLabel", {
        Name = "Shadow", BackgroundTransparency = 1,
        Image = "rbxassetid://5028857472", ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.55, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 450, 450),
        Size = UDim2.new(size.X.Scale, size.X.Offset + 50, size.Y.Scale, size.Y.Offset + 50),
        Position = UDim2.new(0.5, -size.X.Offset / 2 - 25, 0.5, -size.Y.Offset / 2 - 25),
        ZIndex = 0, Parent = gui,
    })

    local main = Create("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = size,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = opts.Transparency or 0,
        BorderSizePixel = 0, ClipsDescendants = true, Parent = gui,
    })
    Corner(main, Theme.R_Window)
    Stroke(main, Theme.BorderSubtle, 1, 0.5)

    local uiScale = Create("UIScale", { Parent = main })

    Connect(main:GetPropertyChangedSignal("Position"), function()
        shadow.Position = UDim2.new(
            main.Position.X.Scale, main.Position.X.Offset - 25,
            main.Position.Y.Scale, main.Position.Y.Offset - 25
        )
    end)

    local topBar = Create("Frame", {
        Name = "TopBar", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52), Parent = main,
    })
    local gradBar = Create("Frame", {
        BackgroundColor3 = Theme.BorderSubtle, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1), Parent = topBar,
    })
    Gradient(gradBar, {
        { 0, Theme.BorderSubtle },
        { 0.5, Theme.Border },
        { 1, Theme.BorderSubtle },
    }, 0)

    local logoBox = Create("Frame", {
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0.5, -13),
        Size = UDim2.fromOffset(26, 26), Parent = topBar,
    })
    Corner(logoBox, 8)
    Gradient(logoBox, {
        { 0, Theme.AccentBright },
        { 1, Theme.AccentDark },
    }, 45)
    local logoIco = NewIcon(logoBox, opts.Icon or "moon", 15, Color3.new(1, 1, 1), "R")
    logoIco.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    logoIco.Instance.Position = UDim2.fromScale(0.5, 0.5)

    local titleHolder = Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 56, 0, 0),
        Size = UDim2.new(1, -180, 1, 0), Parent = topBar,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8), Parent = titleHolder,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 20), LayoutOrder = 1,
        Font = Theme.FontBold, Text = title,
        TextColor3 = Theme.TextPrimary, TextSize = 15, Parent = titleHolder,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 20), LayoutOrder = 2,
        Font = Theme.Font, Text = subtitle,
        TextColor3 = Theme.TextMuted, TextSize = 12, Parent = titleHolder,
    })

    local btnHolder = Create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.X, Parent = topBar,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6), Parent = btnHolder,
    })

    local function TopButton(order, icon, fallback, hoverColor)
        local b = Create("TextButton", {
            BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
            Size = UDim2.fromOffset(30, 30), LayoutOrder = order,
            Text = "", AutoButtonColor = false, Parent = btnHolder,
        })
        Corner(b, 9)
        local s = Stroke(b, Theme.BorderSubtle, 1, 0.5)
        local ic = NewIcon(b, icon, 14, Theme.TextSecondary, fallback)
        ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Instance.Position = UDim2.fromScale(0.5, 0.5)
        b.MouseEnter:Connect(function()
            TintIcon(ic, Color3.new(1, 1, 1))
            Tween(b, 0.18, { BackgroundColor3 = hoverColor })
            Tween(s, 0.18, { Color = hoverColor, Transparency = 0 })
        end)
        b.MouseLeave:Connect(function()
            TintIcon(ic, Theme.TextSecondary)
            Tween(b, 0.18, { BackgroundColor3 = Theme.Surface })
            Tween(s, 0.18, { Color = Theme.BorderSubtle, Transparency = 0.5 })
        end)
        return b
    end

    local minBtn = TopButton(1, "minus", "-", Theme.Warning)
    local closeBtn = TopButton(2, "x", "x", Theme.Accent)

    local body = Create("Frame", {
        Name = "Body", BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 1, -52), Parent = main,
    })

    local sidebar = Create("Frame", {
        Name = "Sidebar", BackgroundTransparency = 1,
        Size = UDim2.new(0, 64, 1, 0), ZIndex = 5, Parent = body,
    })
    local sidebarDiv = Create("Frame", {
        BackgroundColor3 = Theme.BorderSubtle, BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0), Parent = sidebar,
    })
    Gradient(sidebarDiv, {
        { 0, Theme.Background },
        { 0.5, Theme.BorderSubtle },
        { 1, Theme.Background },
    }, 90)

    local tabList = Create("Frame", {
        Name = "TabList", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -76), Parent = sidebar,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 8), Parent = tabList,
    })
    Create("UIPadding", { PaddingTop = UDim.new(0, 14), Parent = tabList })

    local content = Create("Frame", {
        Name = "Content", BackgroundTransparency = 1,
        Position = UDim2.new(0, 64, 0, 0),
        Size = UDim2.new(1, -64, 1, 0), Parent = body,
    })

    local bottomBar = Create("Frame", {
        Name = "BottomBar", BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -14),
        Size = UDim2.fromOffset(48, 48), Parent = sidebar,
    })

    local avatarBtn = Create("ImageButton", {
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.fromOffset(2, 2),
        ScaleType = Enum.ScaleType.Crop,
        AutoButtonColor = false, Parent = bottomBar,
    })
    Corner(avatarBtn, 12)
    local avStroke = Stroke(avatarBtn, Theme.Accent, 1.5, 0.3)
    LoadAvatar(avatarBtn)

    local onlineDot = Create("Frame", {
        BackgroundColor3 = Theme.Success, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 2, 1, 2),
        Size = UDim2.fromOffset(12, 12), Parent = avatarBtn,
    })
    Corner(onlineDot, 6)
    local dotOutline = Create("Frame", {
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16), ZIndex = 0, Parent = onlineDot,
    })
    Corner(dotOutline, 8)
    onlineDot.ZIndex = 2

    MakeDraggable(main, topBar, function() return uiScale.Scale end)

    local windowObj = setmetatable({
        Gui = gui, Main = main, Body = body,
        TabBar = tabList, Content = content,
        Scale = uiScale, Title = title,
        Tabs = {}, ActiveTab = nil, HomeTab = nil,
        ToggleKeybind = opts.ToggleKeybind or Enum.KeyCode.RightControl,
        Minimized = false, Alive = true, Size = size,
    }, Window)

    local function updateScale()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        local fit = math.min((vp.X - 24) / math.max(size.X.Offset, 1), (vp.Y - 24) / math.max(size.Y.Offset, 1))
        uiScale.Scale = math.clamp(math.min(opts.Scale or 1, fit), 0.5, 2)
    end
    updateScale()
    if workspace.CurrentCamera then
        Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
    end

    avatarBtn.MouseEnter:Connect(function() Tween(avStroke, 0.2, { Color = Theme.AccentBright, Transparency = 0 }) end)
    avatarBtn.MouseLeave:Connect(function() Tween(avStroke, 0.2, { Color = Theme.Accent, Transparency = 0.3 }) end)

    avatarBtn.MouseButton1Click:Connect(function()
        if windowObj.HomeTab then windowObj:SelectTab(windowObj.HomeTab) end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, 0.2, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
        for _, d in ipairs(main:GetDescendants()) do
            if d:IsA("GuiObject") and d.BackgroundTransparency < 1 then
                Tween(d, 0.2, { BackgroundTransparency = 1 })
            end
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                Tween(d, 0.2, { TextTransparency = 1 })
            end
            if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                Tween(d, 0.2, { ImageTransparency = 1 })
            end
        end
        task.wait(0.25)
        main.Visible = false
    end)

    minBtn.MouseButton1Click:Connect(function()
        windowObj.Minimized = not windowObj.Minimized
        if windowObj.Minimized then
            body.Visible = false
            Tween(main, 0.25, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 52) }, Enum.EasingStyle.Quint)
        else
            Tween(main, 0.25, { Size = size }, Enum.EasingStyle.Quint)
            task.delay(0.2, function() body.Visible = true end)
        end
    end)

    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == windowObj.ToggleKeybind then
            main.Visible = not main.Visible
        end
    end)

    return windowObj
end

function Window:Toggle() self.Main.Visible = not self.Main.Visible end
function Window:Notify(opts) VexUI:Notify(opts) end

function Window:AddTab(name, icon)
    local tab = setmetatable({
        Name = name, Window = self, Icon = icon, Groupboxes = {},
    }, Tab)

    local btn = Create("TextButton", {
        Name = name, BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.fromOffset(46, 46),
        LayoutOrder = #self.Tabs + 1, Text = "",
        AutoButtonColor = false, Parent = self.TabBar,
    })
    Corner(btn, 12)
    local strk = Stroke(btn, Theme.Accent, 1, 1)

    local ic = NewIcon(btn, icon, 22, Theme.TextMuted, string.upper(string.sub(name, 1, 1)))
    ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    ic.Instance.Position = UDim2.fromScale(0.5, 0.5)

    local tip = Create("TextLabel", {
        BackgroundColor3 = Theme.Surface, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(1, 12, 0.5, 0), AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0), Font = Theme.FontMedium,
        Text = name, TextColor3 = Theme.TextPrimary, TextSize = 12,
        Visible = false, ZIndex = 10, Parent = btn,
    })
    Corner(tip, 8)
    Stroke(tip, Theme.BorderSubtle, 1, 0.5)
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = tip,
    })

    local frame = Create("Frame", {
        Name = name .. "_Content", BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1), Visible = false, Parent = self.Content,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = frame,
    })

    local function Column(nameStr, pos)
        local col = Create("ScrollingFrame", {
            Name = nameStr, BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = pos, Size = UDim2.new(0.5, -5, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.BorderSubtle,
            ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
        })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10), Parent = col,
        })
        Create("UIPadding", { PaddingRight = UDim.new(0, 4), Parent = col })
        return col
    end

    tab.Button = btn; tab.Frame = frame
    tab.Left = Column("Left", UDim2.new(0, 0, 0, 0))
    tab.Right = Column("Right", UDim2.new(0.5, 5, 0, 0))
    tab._btn = btn; tab._stroke = strk; tab._icon = ic

    btn.MouseEnter:Connect(function()
        tip.Visible = true
        if self.ActiveTab ~= tab then
            Tween(btn, 0.18, { BackgroundTransparency = 0.6, BackgroundColor3 = Theme.SurfaceHover })
            TintIcon(ic, Theme.TextPrimary)
        end
    end)
    btn.MouseLeave:Connect(function()
        tip.Visible = false
        if self.ActiveTab ~= tab then
            Tween(btn, 0.18, { BackgroundTransparency = 1 })
            TintIcon(ic, Theme.TextMuted)
        end
    end)
    btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

    table.insert(self.Tabs, tab)
    if not self.ActiveTab then self:SelectTab(tab) end
    return tab
end

function Window:SelectTab(tab)
    if self.ActiveTab == tab then return end
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
    tab.Left:Destroy(); tab.Right:Destroy()
    self.HomeTab = tab
    local page = tab.Frame

    local header = Create("Frame", {
        BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 76), Parent = page,
    })
    Corner(header, Theme.R_Groupbox)
    Gradient(header, {
        { 0, Theme.Card },
        { 1, Theme.BackgroundAlt },
    }, 135)

    local avatarBox = Create("ImageLabel", {
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        Position = UDim2.fromOffset(16, 16),
        Size = UDim2.fromOffset(44, 44),
        ScaleType = Enum.ScaleType.Crop, Parent = header,
    })
    Corner(avatarBox, 12)
    Stroke(avatarBox, Theme.Accent, 1.5, 0.3)
    LoadAvatar(avatarBox)

    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(74, 18),
        Size = UDim2.new(1, -90, 0, 20), Font = Theme.FontBold,
        Text = opts.Greeting or ("Hello, " .. LocalPlayer.DisplayName .. "!"),
        TextColor3 = Theme.TextPrimary, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(74, 42),
        Size = UDim2.new(1, -90, 0, 16), Font = Theme.Font,
        Text = opts.Subtitle or (LocalPlayer.Name .. " · " .. self.Title),
        TextColor3 = Theme.TextMuted, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })

    local cols = Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 88),
        Size = UDim2.new(1, 0, 1, -88), Parent = page,
    })
    local function ColumnFrame(pos)
        local c = Create("Frame", {
            BackgroundTransparency = 1, Position = pos,
            Size = UDim2.new(0.5, -5, 1, 0), Parent = cols,
        })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10), Parent = c,
        })
        return c
    end
    local left = ColumnFrame(UDim2.new(0, 0, 0, 0))
    local right = ColumnFrame(UDim2.new(0.5, 5, 0, 0))

    local hasDiscord = opts.Discord ~= nil and opts.Discord ~= ""
    local server = Card(left, hasDiscord and UDim2.new(1, 0, 0.72, -5) or UDim2.new(1, 0, 1, 0), Theme.Card)
    server.LayoutOrder = 1
    Glow(server, Theme.Success, -45, 0.2)
    CardText(server, "Server", "Information on the session you're currently in")

    local grid = Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 56),
        Size = UDim2.new(1, -28, 1, -68), ZIndex = 2, Parent = server,
    })
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = grid })

    local function joinScript()
        local code = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)', game.PlaceId, game.JobId)
        local ok = Copy(code)
        VexUI:Notify({
            Title = ok and "Copied" or "Copy failed",
            Description = ok and "Join script copied to clipboard" or "Your executor has no clipboard function",
            Icon = ok and "copy" or "triangle-alert",
        })
    end

    local r1 = TileRow(grid, 1, 1/3, -4)
    local tPlayers = StatTile(r1, 1, "Players", "-", 0.38)
    local tMax = StatTile(r1, 2, "Maximum Players", "-", 0.62)
    local r2 = TileRow(grid, 2, 1/3, -4)
    local tLatency = StatTile(r2, 1, "Latency", "-", 0.3)
    local tRegion = StatTile(r2, 2, "Server Region", "-", 0.7)
    local r3 = TileRow(grid, 3, 1/3, -4)
    local tTime = StatTile(r3, 1, "In server for", "00:00:00", 0.42)
    StatTile(r3, 2, "Join Script", "Tap to copy join script", 0.58, joinScript)

    if hasDiscord then
        local dc = Card(left, UDim2.new(1, 0, 0.28, -5), Color3.new(1, 1, 1), "TextButton")
        dc.LayoutOrder = 2
        Gradient(dc, {
            { 0, Color3.fromRGB(88, 101, 242) },
            { 0.55, Color3.fromRGB(52, 32, 112) },
            { 1, Color3.fromRGB(14, 12, 24) },
        }, 8)
        local dl = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = dc })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center, Parent = dl,
        })
        Create("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = dl })
        Create("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 24),
            LayoutOrder = 1, Font = Theme.FontBold, Text = "Discord",
            TextColor3 = Color3.new(1, 1, 1), TextSize = 19,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = dl,
        })
        Create("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 16),
            LayoutOrder = 2, Font = Theme.Font,
            Text = "Tap to join the Discord Server",
            TextColor3 = Color3.fromRGB(215, 218, 255), TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = dl,
        })
        dc.MouseButton1Click:Connect(function() task.spawn(JoinDiscord, opts.Discord) end)
    end

    local required = opts.RequiredFunctions or { "loadstring" }
    local supported = true
    local env = (getgenv and getgenv()) or _G
    for _, fn in ipairs(required) do if env[fn] == nil then supported = false; break end end

    local exec = Card(right, UDim2.new(1, 0, 0.3, -5), Color3.new(1, 1, 1))
    exec.LayoutOrder = 1
    if supported then
        Gradient(exec, {
            { 0, Color3.fromRGB(180, 45, 60) },
            { 0.6, Color3.fromRGB(60, 20, 28) },
            { 1, Color3.fromRGB(16, 10, 13) },
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
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 34),
        Size = UDim2.new(1, -32, 1, -42), Font = Theme.Font,
        Text = supported and "Your executor seems to support this script." or "Your executor might not support all features.",
        TextColor3 = Color3.fromRGB(235, 225, 230), TextSize = 12,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 2, Parent = exec,
    })

    local friends = Card(right, UDim2.new(1, 0, 0.7, -5), Theme.Card)
    friends.LayoutOrder = 2
    Glow(friends, Theme.Warning, -135, 0.15)
    CardText(friends, "Friends", "Find out what your friends are currently doing", 17, 0.62)

    local fgrid = Create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -14),
        Size = UDim2.new(1, -28, 0, 112), ZIndex = 2, Parent = friends,
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
        tMax.Set(Players.MaxPlayers .. " can join")
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
                    if ok and isFriend then inServer = inServer + 1 end
                end
            end
            local online = 0
            local okOn, list = pcall(function() return LocalPlayer:GetFriendsOnline(200) end)
            if okOn and type(list) == "table" then online = #list end
            local total = 0
            local okAll, pages = pcall(Players.GetFriendsAsync, Players, LocalPlayer.UserId)
            if okAll and pages then
                pcall(function()
                    while true do
                        total = total + #pages:GetCurrentPage()
                        if pages.IsFinished then break end
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
        local ok, region = pcall(function() return LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer) end)
        tRegion.Set(ok and region or "N/A")
    end)

    task.spawn(function()
        local n = 0
        while self.Alive and not VexUI.Unloaded do
            pcall(refreshLive)
            if n % 60 == 0 then refreshFriends() end
            n = n + 1
            task.wait(1)
        end
    end)

    tab.Refresh = function() pcall(refreshLive); refreshFriends() end
    return tab
end

-- ============ SETTINGS TAB ============
function Window:AddSettingsTab(opts)
    opts = opts or {}
    local tab = self:AddTab(opts.Name or "Settings", opts.Icon or "settings")

    local menu = tab:AddLeftGroupbox("Menu", "layout-dashboard")
    local keybind = menu:AddKeyPicker("VexUI_MenuKey", {
        Text = "Menu keybind", Default = self.ToggleKeybind.Name,
    })
    keybind:OnChanged(function(keyName)
        local ok, key = pcall(function() return Enum.KeyCode[keyName] end)
        if ok and key then self.ToggleKeybind = key end
    end)
    menu:AddButton("Unload UI", { Icon = "power", Callback = function() VexUI:Unload() end })

    local cfg = tab:AddRightGroupbox("Config", "save")
    local nameBox = cfg:AddTextbox("VexUI_ConfigName", { Text = "Config name", Placeholder = "default" })
    local list = cfg:AddDropdown("VexUI_ConfigList", { Text = "Configs", Values = VexUI:ListConfigs() })
    local function currentName() local n = nameBox.Get(); if n == "" then n = list.Get() end; return n end

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
        Callback = function() list.Refresh(VexUI:ListConfigs()) end,
    })
    return tab
end

-- ============ TAB ============
function Tab:_SetActive(active)
    Tween(self._btn, 0.2, { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = active and Theme.Accent or Theme.Surface })
    Tween(self._stroke, 0.2, { Transparency = active and 1 or 1 })
    TintIcon(self._icon, active and Color3.new(1, 1, 1) or Theme.TextMuted)
end

function Tab:AddLeftGroupbox(name, icon) return self:_AddGroupbox(name, icon, self.Left) end
function Tab:AddRightGroupbox(name, icon) return self:_AddGroupbox(name, icon, self.Right) end

function Tab:_AddGroupbox(name, icon, column)
    local box = setmetatable({
        Name = name, Tab = self, Column = column, _n = 0,
    }, Groupbox)

    local frame = Create("Frame", {
        Name = name, BackgroundColor3 = Theme.Groupbox,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self.Groupboxes + 1, Parent = column,
    })
    Corner(frame, Theme.R_Groupbox)
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })

    local titleFrame = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42),
        LayoutOrder = 1, Parent = frame,
    })

    local x = 14
    if icon then
        local iconBg = Create("Frame", {
            BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 14, 0.5, -12),
            Size = UDim2.fromOffset(24, 24), Parent = titleFrame,
        })
        Corner(iconBg, 8)
        local ic = NewIcon(iconBg, icon, 14, Theme.AccentBright, "")
        ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Instance.Position = UDim2.fromScale(0.5, 0.5)
        x = 48
    end

    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(1, -x - 14, 1, 0),
        Font = Theme.FontBold, Text = name,
        TextColor3 = Theme.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = titleFrame,
    })

    Create("Frame", {
        BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 0, 42),
        LayoutOrder = 2, Parent = frame,
    })

    local container = Create("Frame", {
        Name = "Container", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3, Parent = frame,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8), Parent = container,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = container,
    })

    box.Frame = frame; box.Container = container; box.Scroll = container
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
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 38),
        ClipsDescendants = clip or false,
    })
    Corner(row, Theme.R_Element)
    return row
end

local function RowLabel(row, text, rightInset, height)
    return Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -(14 + (rightInset or 14)), 0, height or 38),
        Font = Theme.FontMedium, Text = text, TextColor3 = Theme.TextPrimary,
        TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
end

local function HitButton(row, height)
    return Create("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 38),
        Text = "", Parent = row,
    })
end

function Groupbox:AddDivider()
    return Add(self, "Frame", {
        BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1),
    })
end

function Groupbox:AddLabel(text)
    return Add(self, "TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.Y, Font = Theme.Font,
        Text = text, TextColor3 = Theme.TextSecondary, TextSize = 13,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    })
end

function Groupbox:AddButton(name, opts)
    if type(opts) == "function" then opts = { Callback = opts } end
    opts = opts or {}
    local callback = opts.Callback or function() end

    local btn = Add(self, "TextButton", {
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38), Font = Theme.FontMedium,
        Text = "", TextColor3 = Theme.TextPrimary, TextSize = 13,
        AutoButtonColor = false,
    })
    Corner(btn, Theme.R_Element)

    local x = 14
    if opts.Icon then
        local ic = NewIcon(btn, opts.Icon, 16, Theme.TextSecondary, "")
        ic.Instance.Position = UDim2.new(0, 14, 0.5, -8)
        ic.Instance.Name = "BtnIcon"
        x = 40
    end

    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(1, -x - 14, 1, 0), Font = Theme.FontMedium,
        Text = name, TextColor3 = Theme.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })

    btn.MouseEnter:Connect(function()
        Tween(btn, 0.18, { BackgroundColor3 = Theme.ElementHover })
        local bi = btn:FindFirstChild("BtnIcon")
        if bi then Tween(bi, 0.18, { ImageColor3 = Theme.AccentBright }) end
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.18, { BackgroundColor3 = Theme.Element })
        local bi = btn:FindFirstChild("BtnIcon")
        if bi then Tween(bi, 0.18, { ImageColor3 = Theme.TextSecondary }) end
    end)
    btn.MouseButton1Click:Connect(function() task.spawn(callback) end)

    return btn
end

function Groupbox:AddToggle(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local state = opts.Default or false
    local obj, changed = NewOption("Toggle", id, state)

    local row = AddRow(self, 42)
    RowLabel(row, opts.Text or id, 70, 42)

    local track = Create("Frame", {
        BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff,
        BorderSizePixel = 0, Position = UDim2.new(1, -56, 0.5, -12),
        Size = UDim2.fromOffset(44, 24), Parent = row,
    })
    Corner(track, 12)
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
        Size = UDim2.fromOffset(20, 20), Parent = track,
    })
    Corner(thumb, 10)

    local function setState(v)
        state = v and true or false
        Tween(track, 0.18, { BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff })
        Tween(thumb, 0.2, {
            Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
        }, Enum.EasingStyle.Back)
        changed(state); task.spawn(callback, state)
    end

    HitButton(row, 42).MouseButton1Click:Connect(function() setState(not state) end)

    obj.Container = row; obj.Set = setState
    obj.Get = function() return state end
    function obj:SetValue(v) setState(v) end
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

    local row = AddRow(self, 52)
    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 6),
        Size = UDim2.new(1, -90, 0, 18), Font = Theme.FontMedium,
        Text = opts.Text or id, TextColor3 = Theme.TextPrimary,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -70, 0, 6),
        Size = UDim2.new(0, 56, 0, 18), Font = Theme.FontBold,
        Text = tostring(value) .. suffix, TextColor3 = Theme.AccentBright,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })

    local barBg = Create("Frame", {
        BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 34),
        Size = UDim2.new(1, -28, 0, 6), Parent = row,
    })
    Corner(barBg, 3)
    local fill = Create("Frame", {
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Size = UDim2.new((value - min) / range, 0, 1, 0), Parent = barBg,
    })
    Corner(fill, 3)
    Gradient(fill, {
        { 0, Theme.AccentDark },
        { 1, Theme.AccentBright },
    }, 0)

    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / range, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), ZIndex = 2, Parent = barBg,
    })
    Corner(thumb, 7)
    Stroke(thumb, Theme.Accent, 2)

    local hit = Create("TextButton", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 28), Text = "", Parent = row,
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
        changed(value); task.spawn(callback, value)
    end

    TrackDrag(hit, self.Column, function(pos)
        local rel = math.clamp((pos.X - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1), 0, 1)
        setValue(min + range * rel)
    end)

    obj.Set = function(v) setValue(v, 0.1) end
    obj.Get = function() return value end
    function obj:SetValue(v) setValue(v, 0.1) end
    return obj
end

function Groupbox:AddDropdown(id, opts)
    opts = opts or {}
    local values = opts.Values or {}
    local callback = opts.Callback or function() end
    local current = opts.Default or (values[1] or "")
    local open = false
    local obj, changed = NewOption("Dropdown", id, current)

    local row = AddRow(self, 42, true)
    RowLabel(row, opts.Text or id, 140, 42)

    local currentLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -140, 0, 0),
        Size = UDim2.new(0, 110, 0, 42), Font = Theme.FontMedium,
        Text = tostring(current), TextColor3 = Theme.AccentBright,
        TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })
    local arrow = NewIcon(row, "chevron-down", 14, Theme.TextMuted, "v")
    arrow.Instance.Position = UDim2.new(1, -26, 0, 14)

    local hit = HitButton(row, 42)

    local list = Create("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 46),
        Size = UDim2.new(1, -16, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.BorderSubtle,
        Visible = false, Parent = row,
    })
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), Parent = list })

    local buttons = {}
    local function listHeight() return math.min(#values * 30, 150) end

    local function setOpen(v)
        open = v
        if v then
            list.Visible = true
            Tween(row, 0.2, { Size = UDim2.new(1, 0, 0, 42 + listHeight() + 8) })
            Tween(list, 0.2, { Size = UDim2.new(1, -16, 0, listHeight()) })
            Tween(arrow.Instance, 0.2, { Rotation = 180 })
        else
            Tween(row, 0.2, { Size = UDim2.new(1, 0, 0, 42) })
            Tween(list, 0.2, { Size = UDim2.new(1, -16, 0, 0) })
            Tween(arrow.Instance, 0.2, { Rotation = 0 })
            task.delay(0.2, function() if not open then list.Visible = false end end)
        end
    end

    local function select(val)
        current = val
        currentLabel.Text = tostring(val)
        for _, b in ipairs(buttons) do
            b.TextColor3 = (b.Text == tostring(current)) and Theme.AccentBright or Theme.TextPrimary
        end
        changed(val); task.spawn(callback, val)
    end

    local function refresh()
        for _, b in ipairs(buttons) do b:Destroy() end
        buttons = {}
        for i, val in ipairs(values) do
            local option = Create("TextButton", {
                BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
                BorderSizePixel = 0, Size = UDim2.new(1, -4, 0, 28),
                LayoutOrder = i, Font = Theme.FontMedium,
                Text = tostring(val),
                TextColor3 = (tostring(val) == tostring(current)) and Theme.AccentBright or Theme.TextPrimary,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, Parent = list,
            })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = option })
            Corner(option, 6)
            option.MouseEnter:Connect(function() Tween(option, 0.12, { BackgroundTransparency = 0.85 }) end)
            option.MouseLeave:Connect(function() Tween(option, 0.12, { BackgroundTransparency = 1 }) end)
            option.MouseButton1Click:Connect(function() select(val); setOpen(false) end)
            table.insert(buttons, option)
        end
    end
    refresh()

    hit.MouseButton1Click:Connect(function() setOpen(not open) end)

    obj.Container = row; obj.Set = function(v) select(v) end
    obj.Get = function() return current end
    obj.Refresh = function(newValues)
        values = newValues; refresh()
        if open then setOpen(true) end
    end
    function obj:SetValue(v) select(v) end
    return obj
end

function Groupbox:AddTextbox(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local obj, changed = NewOption("Textbox", id, opts.Default or "")

    local row = AddRow(self, 48)
    Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 7),
        Size = UDim2.new(1, -28, 0, 14), Font = Theme.Font,
        Text = opts.Text or id, TextColor3 = Theme.TextMuted,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local box = Create("TextBox", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 24),
        Size = UDim2.new(1, -28, 0, 18), Font = Theme.Font,
        Text = opts.Default or "", PlaceholderText = opts.Placeholder or "",
        TextColor3 = Theme.TextPrimary, PlaceholderColor3 = Theme.TextMuted,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = row,
    })

    box.FocusLost:Connect(function()
        changed(box.Text); task.spawn(callback, box.Text)
    end)

    obj.Instance = box; obj.Container = row
    obj.Set = function(t)
        box.Text = tostring(t); changed(box.Text); task.spawn(callback, box.Text)
    end
    obj.Get = function() return box.Text end
    function obj:SetValue(t) obj.Set(t) end
    return obj
end

function Groupbox:AddColorPicker(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local color = opts.Default or Color3.fromRGB(255, 255, 255)
    local h, s, v = Color3.toHSV(color)
    local open = false
    local PICK_H = 108
    local obj, changed = NewOption("ColorPicker", id, color)

    local row = AddRow(self, 42, true)
    RowLabel(row, opts.Text or id, 70, 42)

    local swatch = Create("Frame", {
        BackgroundColor3 = color, BorderSizePixel = 0,
        Position = UDim2.new(1, -48, 0, 11),
        Size = UDim2.fromOffset(34, 22), Parent = row,
    })
    Corner(swatch, 6)
    Stroke(swatch, Theme.BorderSubtle, 1, 0.3)
    local hit = HitButton(row, 42)

    local area = Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 46),
        Size = UDim2.new(1, -24, 0, PICK_H), Parent = row,
    })
    local sv = Create("Frame", {
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0, Size = UDim2.new(1, -28, 1, 0), Parent = area,
    })
    Corner(sv, 6)
    local white = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = sv,
    })
    Corner(white, 6)
    Create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = sv,
    })
    Corner(black, 6)
    Create("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = black })
    local svCursor = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
        ZIndex = 3, Parent = sv,
    })
    Corner(svCursor, 5)
    Stroke(svCursor, Color3.new(0, 0, 0), 2)

    local hueBar = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 20, 1, 0), Parent = area,
    })
    Corner(hueBar, 6)
    local hueKeys = {}
    for i = 0, 6 do
        table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.999), 1, 1)))
    end
    Create("UIGradient", { Color = ColorSequence.new(hueKeys), Rotation = 90, Parent = hueBar })
    local hueCursor = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 3),
        ZIndex = 3, Parent = hueBar,
    })
    Corner(hueCursor, 2)
    Stroke(hueCursor, Color3.new(0, 0, 0), 1)

    local function render()
        color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = color
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0.5, h)
    end
    local function commit()
        render(); changed(color); task.spawn(callback, color)
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
        Tween(row, 0.2, { Size = UDim2.new(1, 0, 0, open and (46 + PICK_H + 12) or 42) })
    end)

    obj.Container = row
    obj.Set = function(c) h, s, v = Color3.toHSV(c); commit() end
    obj.Get = function() return color end
    function obj:SetValue(c) obj.Set(c) end
    return obj
end

function Groupbox:AddKeyPicker(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local current = opts.Default or "F"
    local listening = false
    local obj, changed = NewOption("KeyPicker", id, current)

    local row = AddRow(self, 42)
    RowLabel(row, opts.Text or id, 90, 42)

    local keyLabel = Create("TextButton", {
        BackgroundColor3 = Theme.SurfaceDeep, BorderSizePixel = 0,
        Position = UDim2.new(1, -76, 0.5, -13),
        Size = UDim2.fromOffset(62, 26), Font = Theme.FontBold,
        Text = current, TextColor3 = Theme.TextPrimary,
        TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false, Parent = row,
    })
    Corner(keyLabel, 6)
    Stroke(keyLabel, Theme.BorderSubtle, 1, 0.3)

    keyLabel.MouseButton1Click:Connect(function()
        listening = true
        keyLabel.Text = "..."
        Tween(keyLabel, 0.15, { BackgroundColor3 = Theme.Accent })
    end)

    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                if input.KeyCode ~= Enum.KeyCode.Escape then
                    current = input.KeyCode.Name
                    changed(current)
                end
                keyLabel.Text = current
                Tween(keyLabel, 0.15, { BackgroundColor3 = Theme.SurfaceDeep })
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == current then
            task.spawn(callback)
        end
    end)

    obj.Container = row
    obj.Set = function(k)
        current = k; keyLabel.Text = k; changed(k)
    end
    obj.Get = function() return current end
    function obj:SetValue(k) obj.Set(k) end
    return obj
end

-- ============ INIT ============
return VexUI
