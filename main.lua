--[[
    RavineUI - Modern Dashboard UI Library
    Version 2.2

    THEME SYSTEM (live, alles wird sofort umgefaerbt):
        RavineUI:SetTheme("Ocean")                 -- Preset: Crimson, Ocean, Violet, Emerald, Amber, Rose, Cyan, Orange
        RavineUI:SetAccent(Color3.fromRGB(255, 80, 0))
        RavineUI:SetRainbow(true, 0.15)            -- Rainbow-Akzent (Speed = Zyklen pro Sekunde)
        RavineUI:AddThemePreset("Mint", Color3.fromRGB(60, 220, 170))
        RavineUI:OnThemeChanged(function() ... end)
        Window:SetTransparency(0.1)                -- Fenster-Transparenz (0 bis 0.7)
        Beim Erstellen: CreateWindow({ ThemePreset = "Violet" })  oder  CreateWindow({ Accent = Color3.fromRGB(...) })
        Die Auswahl der User (Settings > Appearance) wird in RavineUI/theme.json gespeichert und gewinnt gegen
        ThemePreset/Accent. Mit IgnoreSavedTheme = true wird die gespeicherte Auswahl ignoriert.

    SEARCH BAR:
        Lupe oben in der Titelleiste (oder Strg+F am PC). Durchsucht alle Tabs und alle Elemente,
        Klick auf ein Ergebnis springt zum Tab, scrollt zum Element und laesst es aufleuchten.
        Box:AddToggle("X", { Text = "Auto Farm", Keywords = "grind xp level" })   -- zusaetzliche Suchbegriffe
        Box:AddToggle("X", { Text = "Geheim", Searchable = false })               -- nicht auffindbar
        Window:OpenSearch("farm")  Window:CloseSearch()  Window:ToggleSearch()
        CreateWindow({ Search = false })                                          -- Suche komplett aus

    Mobile:
        Handy wird automatisch erkannt und die UI automatisch kleiner skaliert.
        local Window = RavineUI:CreateWindow({
            Title = "Mein Script",
            MobileScale = 0.7,   -- optional, kleiner = kleinere UI auf dem Handy (Standard 0.7)
            -- Mobile = true,    -- optional: Mobile-Modus erzwingen (zum Testen am PC)
        })
        Die UI passt immer auf den Bildschirm: Resize und UI-scale-Slider sind auf die
        Bildschirmgroesse begrenzt und das Fenster bleibt im sichtbaren Bereich.

    Dropdown mit Mehrfachauswahl:
        local dd = Box:AddDropdown("Targets", {
            Text = "Targets",
            Values = { "Players", "NPCs", "Bosses" },
            Multi = true,
            Default = { "Players" },            -- Array {"A","B"} oder Map {A = true}
            Callback = function(selected)       -- selected = { Players = true, Bosses = true }
                print(selected.Players)
            end,
        })
        Library.Options.Targets.Value           -- Map { [Name] = true }
        dd.GetSelected()                        -- geordnetes Array { "Players", "Bosses" }
        dd.Set({ "NPCs" })  dd.SelectAll()  dd.Clear()

    Deaktivierte Elemente (wie bei Obsidian) + Tooltips:
        local t = Box:AddToggle("AutoFarmV2", {
            Text = "Auto Farm V2",
            Disabled = true,                              -- ausgegraut, mit Schloss, nicht bedienbar
            DisabledTooltip = "Premium only - join our Discord",   -- erscheint beim Hovern (Handy: antippen)
            Tooltip = "Normaler Tooltip (optional)",
        })
        t:SetDisabled(false)                  -- freischalten (t.SetDisabled(false) geht auch)
        t:SetDisabledTooltip("anderer Text")  t:SetTooltip("...")
        t.Disabled   t:IsDisabled()
        Gilt fuer AddToggle, AddButton, AddSlider, AddDropdown, AddTextbox, AddColorPicker, AddKeyPicker.
        Deaktivierte Elemente ignorieren Set/SetValue (auch beim Config-Laden).
        AddButton gibt jetzt ein Objekt zurueck (die TextButton-Instanz ist unter .Instance).
]]

local RavineUI = {
    Version = "2.2.0",
    Toggles = {},
    Options = {},
    CustomIcons = {},
}

RavineUI.__index = RavineUI
RavineUI.Build = "theme-search-12"

-- ============ SERVICES ============
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Touch-Geraet ohne Tastatur = Mobile (kann in CreateWindow mit Mobile = true/false ueberschrieben werden)
RavineUI.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
-- Faktor, mit dem die UI auf dem Handy automatisch verkleinert wird
RavineUI.MobileScale = 0.7

local GENV = (getgenv and getgenv()) or _G
if GENV.RavineUI_Instance and GENV.RavineUI_Instance.Unload then
    pcall(GENV.RavineUI_Instance.Unload, GENV.RavineUI_Instance)
end
GENV.RavineUI_Instance = RavineUI

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
    Divider = Color3.fromRGB(70, 70, 84),
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
RavineUI.Theme = Theme

-- Aktueller Zustand der Theme-Auswahl (wird in RavineUI/theme.json gespeichert)
RavineUI.ThemeState = {
    Preset = "Crimson",
    Accent = Theme.Accent,
    Rainbow = false,
    RainbowSpeed = 0.15,
    Transparency = 0.04,
}

-- Jedes Element, dessen Farbe beim Erstellen einer Theme-Farbe entspricht, wird hier (schwach) vermerkt.
-- Beim Theme-Wechsel werden diese Elemente live umgefaerbt. Schwache Keys = zerstoerte Elemente verschwinden von selbst.
local ThemeBinds = setmetatable({}, { __mode = "k" })
local ThemeHooks = {}
local ThemedProps = {
    BackgroundColor3 = true,
    TextColor3 = true,
    ImageColor3 = true,
    BorderColor3 = true,
    Color = true,
    ScrollBarImageColor3 = true,
    PlaceholderColor3 = true,
}

local function BindTheme(inst, prop, value)
    if typeof(value) ~= "Color3" then
        return
    end
    for key, c in pairs(Theme) do
        if typeof(c) == "Color3" and c == value then
            local list = ThemeBinds[inst]
            if not list then
                list = {}
                ThemeBinds[inst] = list
            end
            table.insert(list, { prop, key })
            return
        end
    end
end

-- ============ UTILITIES ============
local Connections = {}

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

-- noTheme = true: Farben dieses Elements werden NIE vom Theme umgefaerbt (z. B. Farbwaehler-Vorschau)
local function Create(className, props, noTheme)
    local inst = Instance.new(className)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            parent = v
        else
            inst[k] = v
            if not noTheme and ThemedProps[k] then
                BindTheme(inst, k, v)
            end
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

local function ScaleColor(c, f)
    return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end

-- Erlaubt sowohl obj.Set(x) als auch obj:Set(x) (bei ":" wird obj selbst als erstes Argument uebergeben)
local function Arg(obj, a, b)
    if a == obj then
        return b
    end
    return a
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

function RavineUI:SetIconModule(mod)
    IconModule = mod
end

function RavineUI:AddIcon(name, asset)
    local url = type(asset) == "number" and ("rbxassetid://" .. asset) or asset
    self.CustomIcons[name] = {
        Url = url,
        ImageRectOffset = Vector2.new(0, 0),
        ImageRectSize = Vector2.new(0, 0),
    }
end

function RavineUI:GetIcon(icon)
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
    local data = RavineUI:GetIcon(icon)
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

local function IsCustomImage(icon)
    local t = type(icon)
    if t == "number" then
        return true
    end
    if t == "string" then
        return icon:sub(1, 13) == "rbxassetid://" or icon:sub(1, 4) == "http" or tonumber(icon) ~= nil
    end
    return false
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

    local registry = (kind == "Toggle") and RavineUI.Toggles or RavineUI.Options
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
    if RavineUI.Gui and RavineUI.Gui.Parent then
        return RavineUI.Gui
    end
    RavineUI.Gui = Create("ScreenGui", {
        Name = "RavineUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Parent = GetGuiParent(),
    })
    return RavineUI.Gui
end

-- ============ TOOLTIP ============
-- Ein gemeinsamer Tooltip, haengt direkt im ScreenGui (wird also nie von ScrollingFrames abgeschnitten)
local Tip = { Frame = nil, Label = nil, Conn = nil, Token = 0, Bounds = nil }

local function TipEnsure()
    if Tip.Frame and Tip.Frame.Parent then
        return Tip.Frame
    end
    local gui = EnsureGui()
    local f = Create("Frame", {
        Name = "Tooltip",
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        Visible = false,
        ZIndex = 1000,
        Parent = gui,
    })
    Corner(f, 6)
    Stroke(f, Theme.Border, 1)
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 7),
        Parent = f,
    })
    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        Font = Theme.Font,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1001,
        Parent = f,
    })
    Create("UISizeConstraint", { MaxSize = Vector2.new(260, 1000), Parent = label })
    Tip.Frame = f
    Tip.Label = label
    return f
end

local function TipHide()
    Tip.Token = Tip.Token + 1
    Tip.Bounds = nil
    if Tip.Conn then
        Tip.Conn:Disconnect()
        Tip.Conn = nil
    end
    if Tip.Frame then
        Tip.Frame.Visible = false
    end
end

-- Versteckt nur, wenn der Tooltip gerade zu diesem Element gehoert
local function TipHideFor(bounds)
    if Tip.Bounds == bounds then
        TipHide()
    end
end

local function TipPlace(tx, ty, flipY)
    local f = Tip.Frame
    if not f then
        return
    end
    local vp = (RavineUI.Gui and RavineUI.Gui.AbsoluteSize) or Vector2.new(1920, 1080)
    local sz = f.AbsoluteSize
    local px = math.clamp(tx, 4, math.max(vp.X - sz.X - 4, 4))
    local py = ty
    if py + sz.Y > vp.Y - 4 then
        py = flipY - sz.Y
    end
    f.Position = UDim2.fromOffset(px, math.max(py, 4))
end

-- Folgt dem Mauszeiger; verschwindet, sobald der Cursor das Element (bounds) verlaesst
local function TipShow(text, bounds)
    TipHide()
    if not text or text == "" then
        return
    end
    local f = TipEnsure()
    Tip.Label.Text = text
    Tip.Bounds = bounds
    f.Visible = true
    local function update()
        if bounds and not bounds.Parent then
            TipHide()
            return
        end
        local m = UserInputService:GetMouseLocation()
        if bounds then
            local p, sz = bounds.AbsolutePosition, bounds.AbsoluteSize
            if m.X < p.X or m.Y < p.Y or m.X > p.X + sz.X or m.Y > p.Y + sz.Y then
                TipHide()
                return
            end
        end
        TipPlace(m.X + 14, m.Y + 18, m.Y - 10)
    end
    update()
    if Tip.Frame and Tip.Frame.Visible then
        Tip.Conn = RunService.RenderStepped:Connect(update)
    end
end

-- Fuer Touch: Tooltip kurz unter dem Element zeigen
local function TipFlash(text, target)
    TipHide()
    if not text or text == "" then
        return
    end
    local f = TipEnsure()
    Tip.Label.Text = text
    Tip.Bounds = target
    f.Visible = true
    local token = Tip.Token
    local function place()
        if Tip.Token == token and target.Parent then
            local p, sz = target.AbsolutePosition, target.AbsoluteSize
            TipPlace(p.X, p.Y + sz.Y + 6, p.Y - 6)
        end
    end
    place()
    task.defer(place)
    task.delay(2.5, function()
        if Tip.Token == token then
            TipHide()
        end
    end)
end

function RavineUI:HideTooltip()
    TipHide()
end

-- ============ NOTIFICATIONS ============
local NotifContainer

local function EnsureNotifContainer()
    if NotifContainer and NotifContainer.Parent then
        return NotifContainer
    end
    RavineUI.NotifGui = Create("ScreenGui", {
        Name = "RavineUI_Notifs",
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
        Parent = RavineUI.NotifGui,
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

function RavineUI:Notify(opts)
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
function RavineUI:ShowChangelog(opts)
    opts = opts or {}
    local scriptName = opts.Title or "Script"
    local version = opts.Version or "1.0.0"
    local entries = opts.Entries or {}
    local discord = opts.Discord

    -- Letzten Changelog merken (ohne OnClose), damit der Home-Tab ihn wieder oeffnen kann
    local stored = {}
    for k, v in pairs(opts) do
        if k ~= "OnClose" then
            stored[k] = v
        end
    end
    RavineUI._LastChangelog = stored

    if RavineUI._ChangelogGui and RavineUI._ChangelogGui.Parent then
        RavineUI._ChangelogGui:Destroy()
    end

    local gui = Create("ScreenGui", {
        Name = "RavineUI_Changelog",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = GetGuiParent(),
    })
    RavineUI._ChangelogGui = gui

    local size = UDim2.fromOffset(520, 470)

    -- ============ WINDOW (gleich wie Main) ============
    local main = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = RavineUI.ThemeState.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui,
    })
    Corner(main, 12)
    Stroke(main, Theme.Border, 1)
    local uiScale = Create("UIScale", { Parent = main })

    local function fitScale()
        local cam = workspace.CurrentCamera
        if not cam then
            return 1
        end
        local vp = cam.ViewportSize
        local fit = math.min((vp.X - 24) / size.X.Offset, (vp.Y - 24) / size.Y.Offset)
        local s = math.min(1, fit)
        if RavineUI.IsMobile then
            s = s * (RavineUI.MobileScale or 0.7)
        end
        return math.clamp(s, 0.25, 2)
    end
    local targetScale = fitScale()
    uiScale.Scale = targetScale * 0.94

    -- ============ TOPBAR (gleich wie Main) ============
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

    local logo = NewIcon(topBar, opts.Icon or "scroll-text", 22, Theme.Accent, "•")
    logo.Instance.Position = UDim2.new(0, 16, 0.5, -11)

    local titleHolder = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 48, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
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
        Text = scriptName,
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
        Text = "Changelog  v" .. version,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        Parent = titleHolder,
    })

    local closeBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        Text = "",
        AutoButtonColor = false,
        Parent = topBar,
    })
    Corner(closeBtn, 8)
    local closeStrk = Stroke(closeBtn, Theme.Border, 1)
    local closeIco = NewIcon(closeBtn, "x", 14, Theme.SubText, "x")
    closeIco.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIco.Instance.Position = UDim2.fromScale(0.5, 0.5)
    closeBtn.MouseEnter:Connect(function()
        TintIcon(closeIco, Theme.Text)
        Tween(closeStrk, 0.15, { Color = Theme.Accent })
    end)
    closeBtn.MouseLeave:Connect(function()
        TintIcon(closeIco, Theme.SubText)
        Tween(closeStrk, 0.15, { Color = Theme.Border })
    end)

    -- ============ DATEN ============
    local typeIcons = {
        Added = "plus",
        Improved = "sparkles",
        Changed = "refresh-cw",
        Fixed = "wrench",
        Removed = "minus",
    }
    local typeOrder = { "Added", "Improved", "Changed", "Fixed", "Removed" }

    local groups, extra = {}, {}
    for _, entry in ipairs(entries) do
        local eType, eText
        if entry.Type and entry.Text then
            eType, eText = entry.Type, entry.Text
        else
            for k, v in pairs(entry) do
                eType, eText = k, v
                break
            end
        end
        eType = tostring(eType or "Changed")
        if not groups[eType] then
            groups[eType] = {}
            if not typeIcons[eType] then
                table.insert(extra, eType)
            end
        end
        table.insert(groups[eType], tostring(eText))
    end

    -- ============ SCROLL ============
    local scroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 56),
        Size = UDim2.new(1, -20, 1, -120),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = main,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = scroll,
    })
    Create("UIPadding", { PaddingRight = UDim.new(0, 4), Parent = scroll })

    -- Fake-Tab, damit die echten Groupboxen der Main UI benutzt werden
    local fakeTab = { Groupboxes = {} }

    local function buildGroup(typeName)
        local list = groups[typeName]
        if not list then
            return
        end
        local box = Tab._AddGroupbox(fakeTab, typeName, typeIcons[typeName] or "info", scroll)
        for _, text in ipairs(list) do
            box._n = box._n + 1
            local row = Create("Frame", {
                BackgroundColor3 = Theme.Tertiary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = box._n,
                Parent = box.Container,
            })
            Corner(row, 6)
            Stroke(row, Theme.Border, 1)
            Create("UIPadding", {
                PaddingBottom = UDim.new(0, 9),
                Parent = row,
            })

            local ic = NewIcon(row, typeIcons[typeName] or "info", 14, Theme.Accent, "•")
            ic.Instance.Position = UDim2.fromOffset(12, 10)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(36, 9),
                Size = UDim2.new(1, -48, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Theme.Font,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = row,
            })
        end
    end

    for _, t in ipairs(typeOrder) do
        buildGroup(t)
    end
    for _, t in ipairs(extra) do
        buildGroup(t)
    end

    -- ============ FOOTER ============
    local footer = Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 54),
        Parent = main,
    })
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = footer,
    })

    local infoHolder = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -150, 1, 0),
        Parent = footer,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 1),
        Parent = infoHolder,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        LayoutOrder = 1,
        Font = Theme.FontBold,
        Text = scriptName .. "  v" .. version,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = infoHolder,
    })
    if discord then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            LayoutOrder = 2,
            Font = Theme.Font,
            Text = discord,
            TextColor3 = Theme.SubText,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = infoHolder,
        })
    end

    -- Button im gleichen Stil wie Groupbox:AddButton
    local okBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(112, 34),
        Font = Theme.Font,
        Text = "Continue",
        TextColor3 = Theme.Text,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = footer,
    })
    Corner(okBtn, 6)
    local okStrk = Stroke(okBtn, Theme.Border, 1)
    okBtn.TextXAlignment = Enum.TextXAlignment.Left
    Create("UIPadding", { PaddingLeft = UDim.new(0, 14), Parent = okBtn })
    local okIco = NewIcon(okBtn, "arrow-right", 14, Theme.Text, ">")
    okIco.Instance.AnchorPoint = Vector2.new(1, 0.5)
    okIco.Instance.Position = UDim2.new(1, -10, 0.5, 0)

    okBtn.MouseEnter:Connect(function()
        Tween(okBtn, 0.15, { BackgroundColor3 = Theme.Accent })
        Tween(okStrk, 0.15, { Color = Theme.Accent })
    end)
    okBtn.MouseLeave:Connect(function()
        Tween(okBtn, 0.15, { BackgroundColor3 = Theme.Tertiary })
        Tween(okStrk, 0.15, { Color = Theme.Border })
    end)

    -- ============ ENTRANCE / DRAG / CLOSE ============
    Tween(uiScale, 0.2, { Scale = targetScale })

    MakeDraggable(main, topBar, function()
        return uiScale.Scale
    end)

    local closing = false
    local function close()
        if closing then
            return
        end
        closing = true
        Tween(uiScale, 0.15, { Scale = targetScale * 0.94 })
        task.wait(0.15)
        gui:Destroy()
        if opts.OnClose then
            task.spawn(opts.OnClose)
        end
    end

    closeBtn.MouseButton1Click:Connect(close)
    okBtn.MouseButton1Click:Connect(close)
end

-- ============ CONFIG ============
local ConfigFolder = "RavineUI/configs"

local function HasFS()
    return writefile and readfile and isfile and isfolder and makefolder
end

local function EnsureFolders()
    if not isfolder("RavineUI") then
        makefolder("RavineUI")
    end
    if not isfolder(ConfigFolder) then
        makefolder(ConfigFolder)
    end
end

function RavineUI:SaveConfig(name)
    if not name or name == "" then
        return false, "Kein Name angegeben"
    end
    if not HasFS() then
        return false, "Executor unterstuetzt keine Dateifunktionen"
    end

    local data = {}
    for id, o in pairs(self.Toggles) do
        if id:sub(1, 9) ~= "RavineUI_" then
            data[id] = { t = o.Type, v = o.Value }
        end
    end
    for id, o in pairs(self.Options) do
        if id:sub(1, 9) ~= "RavineUI_" then
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

function RavineUI:LoadConfig(name)
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

function RavineUI:ListConfigs()
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
function RavineUI:Unload()
    self.Unloaded = true
    TipHide()
    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    table.clear(Connections)
    self._rainbowConn = nil
    table.clear(ThemeHooks)
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
    if GENV.RavineUI_Instance == self then
        GENV.RavineUI_Instance = nil
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
    RavineUI:Notify({ Title = "Discord", Description = "Invite copied: discord.gg/" .. code, Icon = "circle-check" })
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

-- ============ SCALE SPEICHERN ============
-- Handy und PC speichern getrennt, damit eine PC-Scale nie auf dem Handy landet
local function ScaleFile(mobile)
    return mobile and "RavineUI/scale_mobile.txt" or "RavineUI/scale.txt"
end

local function ReadSavedScale(mobile)
    if not HasFS() then
        return nil
    end
    local ok, v = pcall(function()
        if isfile(ScaleFile(mobile)) then
            return tonumber(readfile(ScaleFile(mobile)))
        end
        return nil
    end)
    if ok and v then
        return math.clamp(v, 0.25, 2)
    end
    return nil
end

local function WriteSavedScale(v, mobile)
    if not HasFS() then
        return
    end
    pcall(function()
        EnsureFolders()
        writefile(ScaleFile(mobile), tostring(v))
    end)
end

-- ============ THEME SYSTEM ============
local Presets = {
    { Name = "Crimson", Color = Color3.fromRGB(200, 30, 40) },
    { Name = "Ocean", Color = Color3.fromRGB(37, 124, 235) },
    { Name = "Violet", Color = Color3.fromRGB(139, 92, 246) },
    { Name = "Emerald", Color = Color3.fromRGB(34, 180, 95) },
    { Name = "Amber", Color = Color3.fromRGB(235, 150, 20) },
    { Name = "Rose", Color = Color3.fromRGB(236, 64, 140) },
    { Name = "Cyan", Color = Color3.fromRGB(8, 170, 200) },
    { Name = "Orange", Color = Color3.fromRGB(240, 105, 30) },
}

local function NearColor(a, b, tol)
    return math.abs(a.R - b.R) <= tol and math.abs(a.G - b.G) <= tol and math.abs(a.B - b.B) <= tol
end

-- Setzt neue Theme-Farben und faerbt alle gebundenen Elemente um, die gerade noch die alte Farbe haben.
-- (Ein Toggle, der gerade "aus" ist, hat z. B. ToggleOff-Farbe und wird deshalb nicht angefasst.)
local function ApplyColors(new, tol)
    local old = {}
    for k, v in pairs(new) do
        old[k] = Theme[k]
        Theme[k] = v
    end
    tol = tol or (RavineUI.ThemeState.Rainbow and 0.15 or 0.004)
    for inst, list in pairs(ThemeBinds) do
        for _, b in ipairs(list) do
            local key = b[2]
            local o, n = old[key], new[key]
            if o and n and NearColor(inst[b[1]], o, tol) then
                inst[b[1]] = n
            end
        end
    end
    for _, fn in ipairs(ThemeHooks) do
        pcall(fn)
    end
end

local function DarkenColor(c, f)
    local h, s, v = Color3.toHSV(c)
    return Color3.fromHSV(h, s, v * f)
end

function RavineUI:SetAccent(color, fromRainbow, tolOverride)
    if typeof(color) ~= "Color3" then
        return
    end
    if not fromRainbow then
        self.ThemeState.Accent = color
    end
    ApplyColors({
        Accent = color,
        ToggleOn = color,
        AccentDark = DarkenColor(color, 0.7),
    }, tolOverride)
end

function RavineUI:SetTheme(name)
    for _, p in ipairs(Presets) do
        if p.Name == name then
            self.ThemeState.Preset = p.Name
            self:SetAccent(p.Color)
            return true
        end
    end
    return false
end

function RavineUI:GetThemeNames()
    local out = {}
    for _, p in ipairs(Presets) do
        table.insert(out, p.Name)
    end
    return out
end

function RavineUI:AddThemePreset(name, color)
    if type(name) ~= "string" or typeof(color) ~= "Color3" then
        return
    end
    for _, p in ipairs(Presets) do
        if p.Name == name then
            p.Color = color
            return
        end
    end
    table.insert(Presets, { Name = name, Color = color })
end

function RavineUI:OnThemeChanged(fn)
    if type(fn) == "function" then
        table.insert(ThemeHooks, fn)
    end
end

-- Rainbow-Akzent. speed = Farbzyklen pro Sekunde (0.02 bis 1)
function RavineUI:SetRainbow(on, speed, silent)
    local ts = self.ThemeState
    if speed then
        ts.RainbowSpeed = math.clamp(tonumber(speed) or 0.15, 0.02, 1)
    end
    ts.Rainbow = on and true or false
    if self._rainbowConn then
        self._rainbowConn:Disconnect()
        self._rainbowConn = nil
    end
    if ts.Rainbow then
        local last = 0
        self._rainbowConn = Connect(RunService.Heartbeat, function()
            local now = os.clock()
            if now - last < 0.04 then
                return
            end
            last = now
            self:SetAccent(Color3.fromHSV((now * ts.RainbowSpeed) % 1, 0.85, 0.95), true)
        end)
    else
        -- zurueck zur gewaehlten Akzentfarbe (grosse Toleranz, weil Tweens noch laufen koennen)
        self:SetAccent(ts.Accent, false, 0.15)
    end
    if not silent then
        self:_QueueThemeSave()
    end
end

-- ---- Speichern / Laden (RavineUI/theme.json) ----
local ThemeFile = "RavineUI/theme.json"

local function ReadSavedTheme()
    if not HasFS() then
        return nil
    end
    local ok, data = pcall(function()
        if isfile(ThemeFile) then
            return HttpService:JSONDecode(readfile(ThemeFile))
        end
        return nil
    end)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

function RavineUI:SaveTheme()
    if not HasFS() then
        return false
    end
    local ts = self.ThemeState
    local a = ts.Accent
    pcall(function()
        EnsureFolders()
        writefile(ThemeFile, HttpService:JSONEncode({
            Preset = ts.Preset,
            Accent = {
                math.floor(a.R * 255 + 0.5),
                math.floor(a.G * 255 + 0.5),
                math.floor(a.B * 255 + 0.5),
            },
            Rainbow = ts.Rainbow,
            RainbowSpeed = ts.RainbowSpeed,
            Transparency = ts.Transparency,
        }))
    end)
    return true
end

-- Speichert erst, wenn eine halbe Sekunde nichts mehr geaendert wurde (Slider/Farbwaehler feuern sehr oft)
function RavineUI:_QueueThemeSave()
    self._themeSaveToken = (self._themeSaveToken or 0) + 1
    local token = self._themeSaveToken
    task.delay(0.6, function()
        if token == self._themeSaveToken and not self.Unloaded then
            self:SaveTheme()
        end
    end)
end

function RavineUI:_InitTheme(opts)
    local ts = self.ThemeState
    if typeof(opts.Accent) == "Color3" then
        ts.Preset = "Custom"
        self:SetAccent(opts.Accent)
    elseif opts.ThemePreset then
        self:SetTheme(opts.ThemePreset)
    end
    if opts.Transparency then
        ts.Transparency = math.clamp(tonumber(opts.Transparency) or 0.04, 0, 0.7)
    end

    if opts.IgnoreSavedTheme then
        return
    end
    local saved = ReadSavedTheme()
    if not saved then
        return
    end
    local a = saved.Accent
    if type(a) == "table" and #a >= 3 then
        local function ch(x)
            return math.clamp(tonumber(x) or 0, 0, 255)
        end
        self:SetAccent(Color3.fromRGB(ch(a[1]), ch(a[2]), ch(a[3])))
        ts.Preset = type(saved.Preset) == "string" and saved.Preset or "Custom"
    end
    if saved.RainbowSpeed then
        ts.RainbowSpeed = math.clamp(tonumber(saved.RainbowSpeed) or ts.RainbowSpeed, 0.02, 1)
    end
    if saved.Transparency then
        ts.Transparency = math.clamp(tonumber(saved.Transparency) or ts.Transparency, 0, 0.7)
    end
    if saved.Rainbow == true then
        self:SetRainbow(true, nil, true)
    end
end

-- ============ SEARCH ============
local SearchTypeIcons = {
    Toggle = "toggle-right",
    Slider = "sliders-horizontal",
    Dropdown = "list",
    Textbox = "type",
    ColorPicker = "palette",
    KeyPicker = "keyboard",
    Button = "mouse-pointer-click",
    Tab = "layout-dashboard",
}

-- Baut das Such-Panel (schwebt ueber dem Inhalt) und gibt eine kleine API zurueck
local function BuildSearch(win, main, onState)
    local entries = {}
    local shown = {}
    local api = { Entries = entries, IsOpen = false }

    local panel = Create("Frame", {
        Name = "SearchPanel",
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 68, 0, 54),
        Size = UDim2.new(1, -76, 1, -62),
        Visible = false,
        Active = true,
        ZIndex = 60,
        Parent = main,
    })
    Corner(panel, 10)
    Stroke(panel, Theme.Border, 1)

    local inputRow = Create("Frame", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(1, -20, 0, 38),
        Parent = panel,
    })
    Corner(inputRow, 8)
    local inputStroke = Stroke(inputRow, Theme.Border, 1)

    local sIcon = NewIcon(inputRow, "search", 16, Theme.SubText, "?")
    sIcon.Instance.AnchorPoint = Vector2.new(0, 0.5)
    sIcon.Instance.Position = UDim2.new(0, 12, 0.5, 0)

    local box = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 0),
        Size = UDim2.new(1, -76, 1, 0),
        Font = Theme.Font,
        Text = "",
        PlaceholderText = "Search all options...",
        PlaceholderColor3 = Theme.SubText,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputRow,
    })

    local clearBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        Parent = inputRow,
    })
    local clearIcon = NewIcon(clearBtn, "x", 14, Theme.SubText, "x")
    clearIcon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    clearIcon.Instance.Position = UDim2.fromScale(0.5, 0.5)
    clearBtn.MouseEnter:Connect(function()
        TintIcon(clearIcon, Theme.Text)
    end)
    clearBtn.MouseLeave:Connect(function()
        TintIcon(clearIcon, Theme.SubText)
    end)

    local info = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 52),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Theme.Font,
        Text = "",
        TextColor3 = Theme.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = panel,
    })

    local results = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 74),
        Size = UDim2.new(1, -20, 1, -84),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = panel,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = results,
    })
    Create("UIPadding", { PaddingRight = UDim.new(0, 4), Parent = results })

    local empty = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 96),
        Size = UDim2.new(1, -32, 0, 40),
        Font = Theme.Font,
        Text = "",
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextWrapped = true,
        Parent = panel,
    })

    -- Scrollt die Spalte zum Element und laesst es kurz aufleuchten
    local function reveal(e)
        local frame, col = e.Frame, e.Column
        if not (frame and frame.Parent and col and col.Parent) then
            return
        end
        local scale = math.max(win.Scale.Scale, 0.01)
        local rel = (frame.AbsolutePosition.Y - col.AbsolutePosition.Y) / scale
        local maxY = math.max((col.AbsoluteCanvasSize.Y - col.AbsoluteWindowSize.Y) / scale, 0)
        local target = math.clamp(col.CanvasPosition.Y + rel - 50, 0, maxY)
        Tween(col, 0.25, { CanvasPosition = Vector2.new(0, target) })

        local stroke = frame:FindFirstChildOfClass("UIStroke")
        if stroke then
            task.spawn(function()
                pcall(function()
                    for _ = 1, 2 do
                        Tween(stroke, 0.18, { Color = Theme.Accent, Thickness = 2 })
                        task.wait(0.3)
                        Tween(stroke, 0.25, { Color = Theme.Border, Thickness = 1 })
                        task.wait(0.35)
                    end
                end)
            end)
        end
    end

    local function jump(e)
        api.SetOpen(false)
        win:SelectTab(e.Tab)
        if e.Frame then
            task.delay(0.1, function()
                reveal(e)
            end)
        end
    end

    local function makeRow(e, order)
        local btn = Create("TextButton", {
            BackgroundColor3 = Theme.Tertiary,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 44),
            LayoutOrder = order,
            Text = "",
            AutoButtonColor = false,
            Parent = results,
        })
        Corner(btn, 8)
        local st = Stroke(btn, Theme.Border, 1)

        local ic = NewIcon(btn, SearchTypeIcons[e.Type] or "search", 16, Theme.Accent, "•")
        ic.Instance.AnchorPoint = Vector2.new(0, 0.5)
        ic.Instance.Position = UDim2.new(0, 12, 0.5, 0)

        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 38, 0, 6),
            Size = UDim2.new(1, -50, 0, 18),
            Font = Theme.FontBold,
            Text = e.Name,
            TextColor3 = Theme.Text,
            TextSize = 13,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btn,
        })

        local sub
        if e.Type == "Tab" then
            sub = "Tab"
        else
            sub = (e.Tab and e.Tab.Name or "") .. " / " .. tostring(e.Group or "")
        end
        if e.Obj and e.Obj.Disabled then
            sub = sub .. "  -  locked"
        end
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 38, 0, 24),
            Size = UDim2.new(1, -50, 0, 14),
            Font = Theme.Font,
            Text = sub,
            TextColor3 = Theme.SubText,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btn,
        })

        btn.MouseEnter:Connect(function()
            Tween(st, 0.12, { Color = Theme.Accent })
        end)
        btn.MouseLeave:Connect(function()
            Tween(st, 0.12, { Color = Theme.Border })
        end)
        btn.MouseButton1Click:Connect(function()
            jump(e)
        end)
    end

    local function render(query)
        for _, c in ipairs(results:GetChildren()) do
            if c:IsA("TextButton") then
                c:Destroy()
            end
        end
        shown = {}

        local tokens = {}
        for t in query:lower():gmatch("%S+") do
            table.insert(tokens, t)
        end

        if #tokens == 0 then
            info.Text = Plural(#entries, "option") .. " searchable"
            empty.Text = "Type to search every option across all tabs"
            empty.Visible = true
            return
        end

        local scored = {}
        for _, e in ipairs(entries) do
            local score = 0
            for _, t in ipairs(tokens) do
                local i = e.Lower:find(t, 1, true)
                if i then
                    score = score + (i == 1 and 3 or 2)
                elseif e.Blob:find(t, 1, true) then
                    score = score + 1
                else
                    score = 0
                    break
                end
            end
            if score > 0 then
                table.insert(scored, { s = score, e = e })
            end
        end
        table.sort(scored, function(a, b)
            if a.s ~= b.s then
                return a.s > b.s
            end
            return a.e.Lower < b.e.Lower
        end)

        for i = 1, math.min(#scored, 40) do
            shown[i] = scored[i].e
            makeRow(scored[i].e, i)
        end

        info.Text = Plural(#shown, "result") .. (#scored > #shown and " (showing first 40)" or "")
        empty.Visible = #shown == 0
        if #shown == 0 then
            empty.Text = 'No results for "' .. query .. '"'
        end
    end

    box:GetPropertyChangedSignal("Text"):Connect(function()
        clearBtn.Visible = box.Text ~= ""
        render(box.Text)
    end)
    box.Focused:Connect(function()
        Tween(inputStroke, 0.15, { Color = Theme.Accent })
    end)
    box.FocusLost:Connect(function(enterPressed, input)
        Tween(inputStroke, 0.15, { Color = Theme.Border })
        if input and input.KeyCode == Enum.KeyCode.Escape then
            api.SetOpen(false)
        elseif enterPressed and shown[1] then
            jump(shown[1])
        end
    end)
    clearBtn.MouseButton1Click:Connect(function()
        box.Text = ""
        box:CaptureFocus()
    end)

    function api.SetOpen(v, query)
        v = v and true or false
        if v == api.IsOpen then
            if v and query then
                box.Text = query
            end
            return
        end
        api.IsOpen = v
        TipHide()
        panel.Visible = v
        if v then
            box.Text = query or ""
            render(box.Text)
            -- kurz warten, sonst landet die Taste, die die Suche geoeffnet hat (Strg+F), im Textfeld
            task.delay(0.05, function()
                if api.IsOpen then
                    box:CaptureFocus()
                end
            end)
        else
            pcall(function()
                box:ReleaseFocus()
            end)
        end
        if onState then
            onState(v)
        end
    end

    function api.Add(e)
        e.Name = tostring(e.Name or "?")
        e.Type = e.Type or "Option"
        e.Lower = e.Name:lower()
        e.Blob = (e.Name .. " " .. (e.Tab and e.Tab.Name or "") .. " " .. tostring(e.Group or "")
            .. " " .. e.Type .. " " .. tostring(e.Keywords or "")):lower()
        table.insert(entries, e)
    end

    return api
end

-- ============ WINDOW ============
function RavineUI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "RavineUI"
    local subtitle = opts.Subtitle or ""
    local mobile = opts.Mobile
    if mobile == nil then
        mobile = RavineUI.IsMobile
    end
    RavineUI.IsMobile = mobile
    RavineUI.MobileScale = opts.MobileScale or 0.7 -- Faktor nur fuer Handy-Nutzer
    RavineUI:_InitTheme(opts)
    local size = opts.Size or (mobile and UDim2.fromOffset(600, 380) or UDim2.fromOffset(700, 430))
    local savedScale = ReadSavedScale(mobile)
    local gui = EnsureGui()

    local main = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = RavineUI.ThemeState.Transparency,
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

    -- Logo: eigene rbxassetid (opts.Logo) wird groesser und ohne Faerbung angezeigt
    local logoSrc = opts.Logo or opts.Icon or "moon"
    local customLogo = IsCustomImage(logoSrc)
    local logoPx = math.clamp(opts.LogoSize or (customLogo and 32 or 22), 12, 44)
    local logoX = customLogo and 12 or 16
    local logo = NewIcon(topBar, logoSrc, logoPx, customLogo and Color3.new(1, 1, 1) or Theme.Accent, "V")
    logo.Instance.AnchorPoint = Vector2.new(0, 0.5)
    logo.Instance.Position = UDim2.new(0, logoX, 0.5, 0)
    local titleX = logoX + logoPx + 10

    -- Platz rechts fuer die Topbar-Buttons (mit Lupe 3 Buttons, ohne 2)
    local reserve = (opts.Search ~= false) and 158 or 122

    local titleHolder = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, titleX, 0, 0),
        Size = UDim2.new(1, -(titleX + reserve), 1, 0),
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

    -- Gibt den Button und eine kleine API (SetActive faerbt den Button dauerhaft in der Akzentfarbe) zurueck
    local function TopButton(order, icon, fallback)
        local active = false
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
            TintIcon(ic, active and Theme.Accent or Theme.SubText)
            Tween(s, 0.15, { Color = active and Theme.Accent or Theme.Border })
        end)
        local api = {
            SetActive = function(v)
                active = v and true or false
                TintIcon(ic, active and Theme.Accent or Theme.SubText)
                Tween(s, 0.15, { Color = active and Theme.Accent or Theme.Border })
            end,
        }
        return b, api
    end

    local searchBtn, searchApi
    if opts.Search ~= false then
        searchBtn, searchApi = TopButton(1, "search", "S")
    end
    local minBtn = TopButton(2, "minus", "-")
    local closeBtn = TopButton(3, "x", "x")

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
        UserScale = savedScale,
    }, Window)
    windowObj.Logo = logo
    windowObj.TitleHolder = titleHolder
    windowObj._logoX = logoX
    windowObj._reserve = reserve

    -- Suche (vor den Tabs bauen, damit jeder Tab und jedes Element sich registrieren kann)
    if searchBtn then
        windowObj._search = BuildSearch(windowObj, main, function(v)
            searchApi.SetActive(v)
        end)
        searchBtn.MouseButton1Click:Connect(function()
            windowObj:ToggleSearch()
        end)
    end

    -- Haelt das Fenster komplett im sichtbaren Bereich
    local function clampToScreen()
        local ps = gui.AbsoluteSize
        if ps.X <= 0 or ps.Y <= 0 then
            return
        end
        local w = size.X.Offset * uiScale.Scale
        local h = (windowObj.Minimized and 46 or size.Y.Offset) * uiScale.Scale
        local cx = main.Position.X.Scale * ps.X + main.Position.X.Offset
        local cy = main.Position.Y.Scale * ps.Y + main.Position.Y.Offset
        cx = math.clamp(cx, w / 2, math.max(ps.X - w / 2, w / 2))
        cy = math.clamp(cy, h / 2, math.max(ps.Y - h / 2, h / 2))
        main.Position = UDim2.fromScale(cx / ps.X, cy / ps.Y)
    end

    local function updateScale()
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local vp = cam.ViewportSize
        local fit = math.min((vp.X - 24) / math.max(size.X.Offset, 1), (vp.Y - 24) / math.max(size.Y.Offset, 1))
        local maxScale = math.clamp(fit, 0.25, 2) -- groesser als der Bildschirm geht nie

        local s
        if windowObj.UserScale then
            s = math.min(windowObj.UserScale, maxScale)
        else
            s = math.min(opts.Scale or 1, fit)
            if mobile then
                s = s * RavineUI.MobileScale
            end
        end
        uiScale.Scale = math.clamp(s, 0.25, 2)
        clampToScreen()
    end
    windowObj._updateScale = updateScale
    updateScale()

    -- Fenster waechst automatisch in der Hoehe, wenn die Tab-Leiste sonst unter das Profilbild ragen wuerde
    windowObj._ensureHeight = function(minHeight)
        if size.Y.Scale ~= 0 or size.Y.Offset >= minHeight then
            return
        end
        size = UDim2.new(size.X.Scale, size.X.Offset, 0, minHeight)
        windowObj.Size = size
        if not windowObj.Minimized then
            Tween(main, 0.2, { Size = size })
        end
        updateScale()
    end
    if workspace.CurrentCamera then
        Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
    end

    -- ============ RESIZE ============
    -- Rechts, links, unten oder an der Ecke ziehen: die ganze UI skaliert gleichmaessig um die Mitte
    local resizeLayer
    if opts.Resizable ~= false then
        resizeLayer = Create("Frame", {
            Name = "Resize",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 50,
            Parent = main,
        })

        local EDGE = mobile and 12 or 8
        local CORNER = mobile and 30 or 22

        -- a = feste Kanten des Fensters beim Start des Ziehens (L = links, T = oben, R = rechts)
        -- r/b/d: links und oben bleiben stehen, l: rechts und oben bleiben stehen
        local function applyDrag(mode, pos, a)
            local W, H = size.X.Offset, size.Y.Offset
            local ps = gui.AbsoluteSize
            local s
            if mode == "r" then
                s = (pos.X - a.L) / W
            elseif mode == "l" then
                s = (a.R - pos.X) / W
            elseif mode == "b" then
                s = (pos.Y - a.T) / H
            else
                s = ((pos.X - a.L) / W + (pos.Y - a.T) / H) / 2
            end

            -- nie groesser als der Bildschirm
            local maxS = math.clamp(math.min((ps.X - 24) / W, (ps.Y - 24) / H), 0.25, 2)
            s = math.clamp(s, 0.25, maxS)

            local cx = (mode == "l") and (a.R - s * W / 2) or (a.L + s * W / 2)
            local cy = a.T + s * H / 2

            -- Fenster bleibt komplett im Bild
            local hw, hh = s * W / 2, s * H / 2
            cx = math.clamp(cx, hw, math.max(ps.X - hw, hw))
            cy = math.clamp(cy, hh, math.max(ps.Y - hh, hh))
            main.Position = UDim2.fromScale(cx / ps.X, cy / ps.Y)

            windowObj.UserScale = s
            uiScale.Scale = s
        end

        local function onResizeEnd()
            local pct = math.floor(uiScale.Scale * 100 + 0.5)
            windowObj:SetScale(pct / 100, true)
            if windowObj._scaleSlider then
                windowObj._scaleSlider.Set(pct)
            end
        end

        local function Handle(name, pos, sz, mode, isCorner)
            local h = Create("TextButton", {
                Name = name,
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = pos,
                Size = sz,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 50,
                Parent = resizeLayer,
            })

            local dots = {}
            if isCorner then
                local o = CORNER - 8
                for _, p in ipairs({ { o, o }, { o, o - 6 }, { o - 6, o } }) do
                    local d = Create("Frame", {
                        BackgroundColor3 = Theme.SubText,
                        BackgroundTransparency = 0.3,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(p[1], p[2]),
                        Size = UDim2.fromOffset(2, 2),
                        ZIndex = 51,
                        Parent = h,
                    })
                    Corner(d, 1)
                    table.insert(dots, d)
                end
            end

            -- Kanten bleiben unsichtbar, nur die Punkte an der Ecke werden beim Anfassen heller
            local function setHot(on)
                for _, d in ipairs(dots) do
                    Tween(d, 0.12, { BackgroundColor3 = on and Theme.Text or Theme.SubText })
                end
            end

            local dragging = false
            local anchors
            h.MouseEnter:Connect(function()
                if not dragging then
                    setHot(true)
                end
            end)
            h.MouseLeave:Connect(function()
                if not dragging then
                    setHot(false)
                end
            end)
            h.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    local p, sz = main.AbsolutePosition, main.AbsoluteSize
                    anchors = { L = p.X, T = p.Y, R = p.X + sz.X }
                    setHot(true)
                end
            end)
            Connect(UserInputService.InputChanged, function(input)
                if dragging and anchors and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    applyDrag(mode, input.Position, anchors)
                end
            end)
            Connect(UserInputService.InputEnded, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    dragging = false
                    setHot(false)
                    onResizeEnd()
                end
            end)
            return h
        end

        -- Kanten (die Topbar bleibt frei, damit man das Fenster weiter verschieben kann)
        Handle("Right", UDim2.new(1, -EDGE, 0, 46), UDim2.new(0, EDGE, 1, -46 - CORNER), "r", false)
        Handle("Left", UDim2.new(0, 0, 0, 46), UDim2.new(0, EDGE, 1, -46 - EDGE), "l", false)
        Handle("Bottom", UDim2.new(0, 0, 1, -EDGE), UDim2.new(1, -CORNER, 0, EDGE), "b", false)
        -- Ecke unten rechts (zuletzt erstellt, liegt oben)
        Handle("Corner", UDim2.new(1, -CORNER, 1, -CORNER), UDim2.fromOffset(CORNER, CORNER), "d", true)
    end

    avatarBtn.MouseButton1Click:Connect(function()
        if windowObj.HomeTab then
            windowObj:SelectTab(windowObj.HomeTab)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        windowObj:CloseSearch()
        main.Visible = false
    end)

    minBtn.MouseButton1Click:Connect(function()
        windowObj:CloseSearch()
        windowObj.Minimized = not windowObj.Minimized
        if windowObj.Minimized then
            Tween(main, 0.2, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 46) })
            task.delay(0.2, function()
                if windowObj.Minimized then
                    body.Visible = false
                    if resizeLayer then
                        resizeLayer.Visible = false
                    end
                end
            end)
        else
            body.Visible = true
            if resizeLayer then
                resizeLayer.Visible = true
            end
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
        -- Strg+F oeffnet die Suche (nur Linke Strg-Taste, Rechte Strg ist standardmaessig der Menue-Toggle)
        if input.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            and main.Visible and windowObj._search then
            windowObj:ToggleSearch()
        end
    end)

    local wantButton = opts.ToggleButton
    if wantButton == nil then
        wantButton = mobile
    end
    if wantButton then
        local fb = Create("TextButton", {
            Name = "ToggleButton",
            BackgroundColor3 = Theme.Secondary,
            Position = UDim2.new(0, 16, 0.5, -24),
            Size = UDim2.fromOffset(48, 48),
            Text = "",
            AutoButtonColor = false,
            Parent = gui,
        })
        Corner(fb, 12)
        Stroke(fb, Theme.Border, 1)
        local fic = NewIcon(fb, logoSrc, customLogo and 30 or 22, customLogo and Color3.new(1, 1, 1) or Theme.Accent, "V")
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
    TipHide()
    if self.Main.Visible then
        self:CloseSearch()
    end
    self.Main.Visible = not self.Main.Visible
end

function Window:SetLogoSize(px)
    px = math.clamp(tonumber(px) or 32, 12, 44)
    local inst = self.Logo.Instance
    inst.Size = UDim2.fromOffset(px, px)
    local titleX = self._logoX + px + 10
    self.TitleHolder.Position = UDim2.new(0, titleX, 0, 0)
    self.TitleHolder.Size = UDim2.new(1, -(titleX + (self._reserve or 122)), 1, 0)
end

-- Skaliert die ganze UI. scale = 1 ist normal, nil = automatisch an den Bildschirm anpassen.
-- Die Scale wird immer auf "passt in den Bildschirm" begrenzt.
function Window:SetScale(scale, save)
    if scale then
        self.UserScale = math.clamp(tonumber(scale) or 1, 0.25, 2)
    else
        self.UserScale = nil
    end
    if self._updateScale then
        self._updateScale()
    end
    if save and self.UserScale then
        WriteSavedScale(self.Scale.Scale, RavineUI.IsMobile)
    end
end

function Window:GetScale()
    return self.Scale.Scale
end

-- Groesste Scale, bei der das Fenster noch komplett auf den Bildschirm passt
function Window:GetMaxScale()
    local ps = self.Gui.AbsoluteSize
    if ps.X <= 0 or ps.Y <= 0 then
        local cam = workspace.CurrentCamera
        ps = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    end
    return math.clamp(
        math.min((ps.X - 24) / math.max(self.Size.X.Offset, 1), (ps.Y - 24) / math.max(self.Size.Y.Offset, 1)),
        0.25, 2
    )
end

-- Fenster-Transparenz (0 = voll sichtbar, 0.7 = sehr durchsichtig)
function Window:SetTransparency(t)
    t = math.clamp(tonumber(t) or 0.04, 0, 0.7)
    RavineUI.ThemeState.Transparency = t
    self.Main.BackgroundTransparency = t
    RavineUI:_QueueThemeSave()
end

-- ---- Suche ----
function Window:OpenSearch(query)
    if self._search and not self.Minimized then
        self._search.SetOpen(true, query)
    end
end

function Window:CloseSearch()
    if self._search then
        self._search.SetOpen(false)
    end
end

function Window:ToggleSearch()
    if self._search and not self.Minimized then
        self._search.SetOpen(not self._search.IsOpen)
    end
end

function Window:IsSearchOpen()
    return self._search ~= nil and self._search.IsOpen
end

-- Eigenen Eintrag in den Suchindex aufnehmen: { Name = "...", Tab = tab, Group = "...", Frame = instanz, Column = scrollingframe, Keywords = "..." }
function Window:AddSearchEntry(entry)
    if self._search and type(entry) == "table" and entry.Tab then
        self._search.Add(entry)
    end
end

function Window:Notify(opts)
    RavineUI:Notify(opts)
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
        if RavineUI.IsMobile then
            tip.Visible = false
        end
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    -- Tab selbst ist auch ueber die Suche auffindbar
    if self._search then
        self._search.Add({ Name = name, Type = "Tab", Tab = tab, Group = "" })
    end

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    -- Platz fuer alle Tabs: Topbar 46 + Avatar-Bereich 64 + Tabs (je 42 + 6 Abstand) + etwas Luft
    if self._ensureHeight then
        self._ensureHeight(116 + 48 * #self.Tabs)
    end

    return tab
end

function Window:SelectTab(tab)
    -- Tab-Wechsel schliesst die Suche
    if self._search then
        self._search.SetOpen(false)
    end
    if self.ActiveTab == tab then
        return
    end
    TipHide()
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
    local cl = opts.Changelog or RavineUI._LastChangelog
    local hasChangelog = type(cl) == "table"
    local hasBottom = hasDiscord or hasChangelog
    local server = Card(left, hasBottom and UDim2.new(1, 0, 0.72, -4) or UDim2.new(1, 0, 1, 0), Theme.Card)
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
        RavineUI:Notify({
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

    local bottom
    if hasBottom then
        bottom = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0.28, -4),
            LayoutOrder = 2,
            Parent = left,
        })
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = bottom,
        })
    end
    local bothCards = hasDiscord and hasChangelog
    local cardW = bothCards and UDim2.new(0.5, -4, 1, 0) or UDim2.new(1, 0, 1, 0)

    if hasDiscord then
        local dc = Card(bottom, cardW, Color3.new(1, 1, 1), "TextButton")
        dc.LayoutOrder = 1
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
            Text = bothCards and "Tap to join" or "Tap to join the Discord Server",
            TextColor3 = Color3.fromRGB(215, 218, 255),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = dl,
        })
        dc.MouseButton1Click:Connect(function()
            task.spawn(JoinDiscord, opts.Discord)
        end)
    end

    if hasChangelog then
        local cc = Card(bottom, cardW, Theme.Card, "TextButton")
        cc.LayoutOrder = 2
        local ccStroke = cc:FindFirstChildOfClass("UIStroke")
        Glow(cc, Theme.Accent, -45, 0.25)

        local count = type(cl.Entries) == "table" and #cl.Entries or 0
        CardText(cc, "Changelog", "Version " .. tostring(cl.Version or RavineUI.Version) .. " - " .. Plural(count, "change"), 19)

        local cIcon = NewIcon(cc, "scroll-text", 18, Theme.Accent, "•")
        cIcon.Instance.Position = UDim2.new(1, -32, 0, 12)
        cIcon.Instance.ZIndex = 2

        cc.MouseEnter:Connect(function()
            Tween(ccStroke, 0.15, { Color = Theme.Accent })
        end)
        cc.MouseLeave:Connect(function()
            Tween(ccStroke, 0.15, { Color = Theme.Border })
        end)
        cc.MouseButton1Click:Connect(function()
            local data = {}
            for k, v in pairs(cl) do
                if k ~= "OnClose" then
                    data[k] = v
                end
            end
            RavineUI:ShowChangelog(data)
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
        -- Verlauf wird aus der Akzentfarbe berechnet und bei Theme-Wechsel neu gemalt
        local execGrad = Gradient(exec, {
            { 0, Color3.fromRGB(150, 38, 46) },
            { 0.6, Color3.fromRGB(58, 18, 22) },
            { 1, Color3.fromRGB(16, 9, 11) },
        }, 20)
        local function paintExec()
            local a = Theme.Accent
            execGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, ScaleColor(a, 0.78)),
                ColorSequenceKeypoint.new(0.6, ScaleColor(a, 0.3)),
                ColorSequenceKeypoint.new(1, ScaleColor(a, 0.08)),
            })
        end
        paintExec()
        table.insert(ThemeHooks, paintExec)
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
        while self.Alive and not RavineUI.Unloaded do
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

-- ============ SETTINGS TAB ============
function Window:AddSettingsTab(opts)
    opts = opts or {}
    local tab = self:AddTab(opts.Name or "Settings", opts.Icon or "settings")

    local menu = tab:AddLeftGroupbox("Menu", "layout-dashboard")
    if not RavineUI.IsMobile then
        local keybind = menu:AddKeyPicker("RavineUI_MenuKey", {
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
    end

    -- Scale wird erst angewendet, wenn der Slider kurz stillsteht (sonst springt die UI unter dem Finger)
    -- Das Maximum passt sich dem Geraet an: groesser als der Bildschirm geht nie
    local scaleToken = 0
    self._scaleSlider = menu:AddSlider("RavineUI_Scale", {
        Text = "UI scale",
        Min = 40,
        Max = math.max(50, math.min(200, math.floor(self:GetMaxScale() * 100))),
        Default = math.floor(self.Scale.Scale * 100 + 0.5),
        Rounding = 0,
        Suffix = "%",
        Callback = function(v)
            scaleToken += 1
            local token = scaleToken
            task.delay(0.25, function()
                if token == scaleToken then
                    self:SetScale(v / 100, true)
                end
            end)
        end,
    })

    menu:AddButton("Unload UI", {
        Icon = "power",
        Callback = function()
            RavineUI:Unload()
        end,
    })

    -- ---- Appearance: Theme-Preset, eigene Akzentfarbe, Rainbow, Transparenz ----
    local look = tab:AddLeftGroupbox("Appearance", "palette")
    local ts = RavineUI.ThemeState
    local syncing = false -- verhindert, dass sich Dropdown und Farbwaehler gegenseitig ausloesen
    local picker

    local names = RavineUI:GetThemeNames()
    table.insert(names, "Custom")

    local presetDD = look:AddDropdown("RavineUI_ThemePreset", {
        Text = "Theme",
        Values = names,
        Default = ts.Preset,
        Callback = function(name)
            if syncing then
                return
            end
            if name ~= "Custom" then
                RavineUI:SetTheme(name)
                syncing = true
                if picker then
                    picker.Set(ts.Accent)
                end
                syncing = false
            else
                ts.Preset = "Custom"
            end
            RavineUI:_QueueThemeSave()
        end,
    })

    picker = look:AddColorPicker("RavineUI_AccentColor", {
        Text = "Accent color",
        Default = ts.Accent,
        Searchable = true,
        Keywords = "color colour theme custom",
        Callback = function(c)
            if syncing then
                return
            end
            ts.Preset = "Custom"
            RavineUI:SetAccent(c)
            syncing = true
            presetDD.Set("Custom")
            syncing = false
            RavineUI:_QueueThemeSave()
        end,
    })

    look:AddToggle("RavineUI_Rainbow", {
        Text = "Rainbow accent",
        Default = ts.Rainbow,
        Keywords = "rgb animated color",
        Callback = function(v)
            RavineUI:SetRainbow(v)
        end,
    })

    look:AddSlider("RavineUI_RainbowSpeed", {
        Text = "Rainbow speed",
        Min = 2,
        Max = 100,
        Default = math.clamp(math.floor(ts.RainbowSpeed * 100 + 0.5), 2, 100),
        Rounding = 0,
        Suffix = "%",
        Callback = function(v)
            ts.RainbowSpeed = v / 100
            RavineUI:_QueueThemeSave()
        end,
    })

    look:AddSlider("RavineUI_Transparency", {
        Text = "Window transparency",
        Min = 0,
        Max = 60,
        Default = math.clamp(math.floor(ts.Transparency * 100 + 0.5), 0, 60),
        Rounding = 0,
        Suffix = "%",
        Keywords = "opacity see through",
        Callback = function(v)
            self:SetTransparency(v / 100)
        end,
    })

    local cfg = tab:AddRightGroupbox("Config", "save")
    local nameBox = cfg:AddTextbox("RavineUI_ConfigName", { Text = "Config name", Placeholder = "default" })
    local list = cfg:AddDropdown("RavineUI_ConfigList", { Text = "Configs", Values = RavineUI:ListConfigs() })

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
            local ok, err = RavineUI:SaveConfig(n)
            RavineUI:Notify({
                Title = ok and "Config saved" or "Save failed",
                Description = ok and n or tostring(err),
                Icon = ok and "circle-check" or "triangle-alert",
            })
            list.Refresh(RavineUI:ListConfigs())
        end,
    })
    cfg:AddButton("Load config", {
        Icon = "folder",
        Callback = function()
            local n = currentName()
            local ok, err = RavineUI:LoadConfig(n)
            RavineUI:Notify({
                Title = ok and "Config loaded" or "Load failed",
                Description = ok and n or tostring(err),
                Icon = ok and "circle-check" or "triangle-alert",
            })
        end,
    })
    cfg:AddButton("Refresh list", {
        Icon = "refresh-cw",
        Callback = function()
            list.Refresh(RavineUI:ListConfigs())
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

function Tab:_AddGroupbox(name, icon, column)
    local box = setmetatable({
        Name = name,
        Tab = self,
        Column = column,
        _n = 0,
    }, Groupbox)

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

-- Traegt ein Element in den Suchindex des Fensters ein (opts.Searchable = false schliesst es aus,
-- opts.Keywords = "a b c" oder { "a", "b" } fuegt zusaetzliche Suchbegriffe hinzu)
local function RegisterSearch(self, kind, label, frame, obj, opts)
    local tab = self.Tab
    local win = tab and tab.Window
    if not (win and win._search) or opts.Searchable == false then
        return
    end
    local kw = opts.Keywords
    if type(kw) == "table" then
        kw = table.concat(kw, " ")
    end
    win._search.Add({
        Name = tostring(label),
        Type = kind,
        Tab = tab,
        Group = self.Name,
        Frame = frame,
        Column = self.Column,
        Obj = obj,
        Keywords = kw and tostring(kw) or "",
    })
end

-- Deaktivieren (wie bei Obsidian): graut das Element aus, blockiert alle Eingaben und zeigt optional einen Tooltip
local function MakeDisabler(target, radius, opts)
    local d = { Tip = opts.DisabledTooltip }
    local overlay = Create("TextButton", {
        Name = "DisabledOverlay",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 20,
        Parent = target,
    })
    Corner(overlay, radius or 6)
    local lock = NewIcon(overlay, "lock", 14, Theme.SubText, "!")
    lock.Instance.AnchorPoint = Vector2.new(1, 0.5)
    lock.Instance.Position = UDim2.new(1, -12, 0.5, 0)
    lock.Instance.ZIndex = 21

    overlay.MouseEnter:Connect(function()
        if d.Tip then
            TipShow(d.Tip, overlay)
        end
    end)
    overlay.MouseLeave:Connect(function()
        TipHideFor(overlay)
    end)
    overlay.MouseButton1Click:Connect(function()
        if d.Tip and UserInputService.TouchEnabled then
            TipFlash(d.Tip, overlay)
        end
    end)

    d.Overlay = overlay
    d.Set = function(v)
        overlay.Visible = v
        if not v then
            TipHideFor(overlay)
        end
    end
    return d
end

-- Haengt SetDisabled / SetDisabledTooltip / IsDisabled an ein Element. onChange(v) wird bei jedem Wechsel gerufen.
local function AttachDisable(obj, target, radius, opts, onChange)
    local d = MakeDisabler(target, radius, opts)
    obj.Disabled = false
    obj.SetDisabled = function(a, b)
        local v = Arg(obj, a, b) and true or false
        obj.Disabled = v
        d.Set(v)
        if onChange then
            onChange(v)
        end
    end
    obj.SetDisabledTooltip = function(a, b)
        d.Tip = Arg(obj, a, b)
    end
    obj.IsDisabled = function()
        return obj.Disabled
    end
    if opts.Disabled then
        obj.SetDisabled(true)
    end
end

-- Normaler Hover-Tooltip (opts.Tooltip / obj:SetTooltip). Nur mit Maus, auf reinen Touch-Geraeten gibt es keinen Hover.
local function AttachTooltip(obj, target, opts)
    local text = opts.Tooltip
    local hooked = false
    local count, token = 0, 0

    local function enter()
        count = count + 1
        if count == 1 then
            token = token + 1
            local mine = token
            task.delay(0.4, function()
                if mine == token and count > 0 and text and not obj.Disabled then
                    TipShow(text, target)
                end
            end)
        end
    end
    local function leave()
        count = math.max(count - 1, 0)
        if count == 0 then
            token = token + 1
            TipHideFor(target)
        end
    end
    local function hook(o)
        o.MouseEnter:Connect(enter)
        o.MouseLeave:Connect(leave)
    end
    local function ensure()
        if hooked then
            return
        end
        hooked = true
        hook(target)
        for _, c in ipairs(target:GetDescendants()) do
            if c:IsA("GuiButton") or c:IsA("TextBox") then
                hook(c)
            end
        end
    end

    obj.SetTooltip = function(a, b)
        text = Arg(obj, a, b)
        if text and not (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
            ensure()
        end
    end
    if text then
        obj.SetTooltip(text)
    end
end

-- thickness = Dicke der Linie in Pixel (Standard 2), drumherum kommt zusaetzlicher Abstand
function Groupbox:AddDivider(thickness)
    local t = thickness or 2
    local holder = Add(self, "Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, t + 12),
    })
    local line = Create("Frame", {
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, t),
        Parent = holder,
    })
    Corner(line, t)
    return holder
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
    -- Objekt statt nackter Instanz (Lesezugriffe wie obj.Text werden an die TextButton-Instanz weitergereicht)
    local obj = setmetatable({ Instance = btn, Container = btn, Type = "Button" }, {
        __index = function(_, k)
            return btn[k]
        end,
    })
    obj.SetText = function(a, b)
        btn.Text = tostring(Arg(obj, a, b))
    end

    btn.MouseButton1Click:Connect(function()
        if obj.Disabled then
            return
        end
        task.spawn(callback)
        if RavineUI.IsMobile then
            task.delay(0.15, function()
                pcall(function()
                    Tween(btn, 0.15, { BackgroundColor3 = Theme.Tertiary })
                    Tween(strk, 0.15, { Color = Theme.Border })
                end)
            end)
        end
    end)

    AttachTooltip(obj, btn, opts)
    AttachDisable(obj, btn, 6, opts)
    RegisterSearch(self, "Button", name, btn, obj, opts)
    return obj
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
        if obj.Disabled then
            return
        end
        setState(not state)
    end)

    obj.Container = row
    obj.Set = function(a, b)
        if obj.Disabled then
            return
        end
        setState(Arg(obj, a, b))
    end
    obj.Get = function()
        return state
    end
    function obj:SetValue(v)
        obj.Set(v)
    end
    AttachTooltip(obj, row, opts)
    AttachDisable(obj, row, 6, opts)
    RegisterSearch(self, "Toggle", opts.Text or id, row, obj, opts)
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
        if obj.Disabled then
            return
        end
        local rel = math.clamp((pos.X - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1), 0, 1)
        setValue(min + range * rel)
    end)

    obj.Container = row
    obj.Set = function(a, b)
        if obj.Disabled then
            return
        end
        setValue(Arg(obj, a, b), 0.1)
    end
    obj.Get = function()
        return value
    end
    function obj:SetValue(v)
        obj.Set(v)
    end
    AttachTooltip(obj, row, opts)
    AttachDisable(obj, row, 6, opts)
    RegisterSearch(self, "Slider", opts.Text or id, row, obj, opts)
    return obj
end

-- Dropdown: Einzelauswahl (Standard) oder Mehrfachauswahl mit Multi = true
-- Dropdown: Einzelauswahl (Standard) oder Mehrfachauswahl mit Multi = true
-- Suchleiste: Search = true / false. Ohne Angabe erscheint sie automatisch ab 8 Eintraegen.
function Groupbox:AddDropdown(id, opts)
    opts = opts or {}
    local values = opts.Values or {}
    local callback = opts.Callback or function() end
    local multi = opts.Multi == true
    local current = nil
    if not multi then
        current = opts.Default or (values[1] or "")
    end
    local selected = {} -- nur Multi: [tostring(Wert)] = true
    local open = false
    local visibleCount = #values

    -- ---- Multi-Helfer ----
    local function inValues(key)
        for _, v in ipairs(values) do
            if tostring(v) == key then
                return true
            end
        end
        return false
    end

    -- akzeptiert Array {"A","B"}, Map {A = true} oder einen einzelnen Wert
    local function toMap(v)
        local map = {}
        local function add(x)
            local k = tostring(x)
            if inValues(k) then
                map[k] = true
            end
        end
        if type(v) == "table" then
            for k, val in pairs(v) do
                if type(k) == "number" then
                    add(val)
                elseif val then
                    add(k)
                end
            end
        elseif v ~= nil and v ~= "" then
            add(v)
        end
        return map
    end

    local function snapshot()
        local m = {}
        for k in pairs(selected) do
            m[k] = true
        end
        return m
    end

    local function count()
        local n = 0
        for _ in pairs(selected) do
            n = n + 1
        end
        return n
    end

    local function summary()
        local n = count()
        if n == 0 then
            return "None"
        end
        if n == 1 then
            for k in pairs(selected) do
                return k
            end
        end
        return n .. " selected"
    end

    if multi then
        selected = toMap(opts.Default)
    end

    local obj, changed = NewOption("Dropdown", id, multi and snapshot() or current)

    local row = AddRow(self, 34, true)
    RowLabel(row, opts.Text or id, 130)

    local currentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -130, 0, 0),
        Size = UDim2.new(0, 104, 0, 34),
        Font = Theme.Font,
        Text = multi and summary() or tostring(current),
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })
    local arrow = NewIcon(row, "chevron-down", 14, Theme.SubText, "v")
    arrow.Instance.Position = UDim2.new(1, -22, 0, 10)

    local hit = HitButton(row, 34)

    -- ---- Suchleiste ----
    local function searchOn()
        if opts.Search ~= nil then
            return opts.Search == true
        end
        return #values >= 8
    end
    local function listTop()
        return searchOn() and 68 or 38
    end
    local function listHeight()
        if visibleCount == 0 then
            return 26
        end
        return math.min(visibleCount * 26, 130)
    end
    local function fullHeight()
        return listTop() + listHeight() + 6
    end

    local searchFrame = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, 38),
        Size = UDim2.new(1, -12, 0, 26),
        Visible = false,
        Parent = row,
    })
    Corner(searchFrame, 5)
    local searchStroke = Stroke(searchFrame, Theme.Border, 1)

    local searchIcon = NewIcon(searchFrame, "search", 13, Theme.SubText, "?")
    searchIcon.Instance.AnchorPoint = Vector2.new(0, 0.5)
    searchIcon.Instance.Position = UDim2.new(0, 8, 0.5, 0)

    local searchBox = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -52, 1, 0),
        Font = Theme.Font,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.SubText,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = searchFrame,
    })

    local clearBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -4, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        Parent = searchFrame,
    })
    local clearIcon = NewIcon(clearBtn, "x", 12, Theme.SubText, "x")
    clearIcon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    clearIcon.Instance.Position = UDim2.fromScale(0.5, 0.5)
    clearBtn.MouseEnter:Connect(function()
        TintIcon(clearIcon, Theme.Text)
    end)
    clearBtn.MouseLeave:Connect(function()
        TintIcon(clearIcon, Theme.SubText)
    end)

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

    local emptyLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 0, 38),
        Size = UDim2.new(1, -12, 0, 26),
        Font = Theme.Font,
        Text = "No results",
        TextColor3 = Theme.SubText,
        TextSize = 12,
        Visible = false,
        Parent = row,
    })

    local entries = {}

    local function relayout()
        if not open then
            return
        end
        list.Position = UDim2.new(0, 6, 0, listTop())
        emptyLabel.Position = UDim2.new(0, 6, 0, listTop())
        emptyLabel.Visible = visibleCount == 0
        list.Visible = visibleCount > 0
        Tween(row, 0.12, { Size = UDim2.new(1, 0, 0, fullHeight()) })
        Tween(list, 0.12, { Size = UDim2.new(1, -12, 0, visibleCount > 0 and listHeight() or 0) })
    end

    local function applyFilter()
        local q = (searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", ""))
        visibleCount = 0
        for _, e in ipairs(entries) do
            local show = q == "" or tostring(e.Value):lower():find(q, 1, true) ~= nil
            e.Button.Visible = show
            if show then
                visibleCount = visibleCount + 1
            end
        end
        list.CanvasPosition = Vector2.new(0, 0)
        relayout()
    end

    local function setOpen(v)
        open = v
        if v then
            searchFrame.Visible = searchOn()
            list.Position = UDim2.new(0, 6, 0, listTop())
            emptyLabel.Position = UDim2.new(0, 6, 0, listTop())
            emptyLabel.Visible = visibleCount == 0
            list.Visible = visibleCount > 0
            Tween(row, 0.18, { Size = UDim2.new(1, 0, 0, fullHeight()) })
            Tween(list, 0.18, { Size = UDim2.new(1, -12, 0, visibleCount > 0 and listHeight() or 0) })
            -- am Handy nicht automatisch fokussieren (sonst springt die Tastatur auf)
            if searchOn() and not RavineUI.IsMobile then
                task.delay(0.05, function()
                    if open then
                        searchBox:CaptureFocus()
                    end
                end)
            end
        else
            pcall(function()
                searchBox:ReleaseFocus()
            end)
            Tween(row, 0.18, { Size = UDim2.new(1, 0, 0, 34) })
            Tween(list, 0.18, { Size = UDim2.new(1, -12, 0, 0) })
            emptyLabel.Visible = false
            task.delay(0.18, function()
                if not open then
                    list.Visible = false
                    searchFrame.Visible = false
                    if searchBox.Text ~= "" then
                        searchBox.Text = "" -- Filter zuruecksetzen
                    end
                end
            end)
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        clearBtn.Visible = searchBox.Text ~= ""
        applyFilter()
    end)
    searchBox.Focused:Connect(function()
        Tween(searchStroke, 0.15, { Color = Theme.Accent })
    end)
    searchBox.FocusLost:Connect(function(enterPressed)
        Tween(searchStroke, 0.15, { Color = Theme.Border })
        -- Enter waehlt bei Einzelauswahl den ersten Treffer
        if enterPressed and not multi then
            for _, e in ipairs(entries) do
                if e.Button.Visible then
                    e.Button.MouseButton1Click:Fire()
                    break
                end
            end
        end
    end)
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        if not RavineUI.IsMobile then
            searchBox:CaptureFocus()
        end
    end)

    local function isSelected(val)
        if multi then
            return selected[tostring(val)] == true
        end
        return tostring(val) == tostring(current)
    end

    -- Ruhe-Zustand der Option: bei Multi sind gewaehlte Eintraege leicht eingefaerbt
    local function restTransparency(val)
        return (multi and isSelected(val)) and 0.85 or 1
    end

    local function styleEntry(e)
        local sel = isSelected(e.Value)
        e.Button.TextColor3 = sel and Theme.Accent or Theme.Text
        e.Check.Instance.Visible = multi and sel
        Tween(e.Button, 0.1, { BackgroundTransparency = restTransparency(e.Value) })
    end

    -- Einzelauswahl
    local function choose(val)
        current = val
        currentLabel.Text = tostring(val)
        for _, e in ipairs(entries) do
            styleEntry(e)
        end
        changed(val)
        task.spawn(callback, val)
    end

    -- Mehrfachauswahl
    local function applyMulti()
        currentLabel.Text = summary()
        for _, e in ipairs(entries) do
            styleEntry(e)
        end
        local snap = snapshot()
        changed(snap)
        task.spawn(callback, snap)
    end

    local function toggleMulti(val)
        local k = tostring(val)
        if selected[k] then
            selected[k] = nil
        else
            selected[k] = true
        end
        applyMulti()
    end

    local function refresh()
        for _, e in ipairs(entries) do
            e.Button:Destroy()
        end
        entries = {}
        for i, val in ipairs(values) do
            local option = Create("TextButton", {
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = restTransparency(val),
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 24),
                LayoutOrder = i,
                Font = Theme.Font,
                Text = tostring(val),
                TextColor3 = isSelected(val) and Theme.Accent or Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                Parent = list,
            })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = option })
            Corner(option, 4)
            local check = NewIcon(option, "check", 14, Theme.Accent, "•")
            check.Instance.Position = UDim2.new(1, -22, 0.5, -7)
            check.Instance.Visible = multi and isSelected(val)
            table.insert(entries, { Button = option, Check = check, Value = val })

            option.MouseEnter:Connect(function()
                Tween(option, 0.1, { BackgroundTransparency = 0.7 })
            end)
            option.MouseLeave:Connect(function()
                Tween(option, 0.1, { BackgroundTransparency = restTransparency(val) })
            end)
            option.MouseButton1Click:Connect(function()
                if multi then
                    -- Liste bleibt offen, damit man mehrere Eintraege nacheinander waehlen kann
                    toggleMulti(val)
                else
                    choose(val)
                    setOpen(false)
                end
            end)
        end
        applyFilter()
    end
    refresh()

    hit.MouseButton1Click:Connect(function()
        if obj.Disabled then
            return
        end
        setOpen(not open)
    end)

    obj.Container = row
    obj.Multi = multi
    obj.Set = function(a, b)
        if obj.Disabled then
            return
        end
        local v = Arg(obj, a, b)
        if multi then
            selected = toMap(v)
            applyMulti()
        else
            choose(v)
        end
    end
    obj.Get = function()
        if multi then
            return snapshot()
        end
        return current
    end
    -- geordnetes Array der gewaehlten Werte (bei Einzelauswahl: Array mit einem Wert)
    obj.GetSelected = function()
        local out = {}
        if multi then
            for _, v in ipairs(values) do
                if selected[tostring(v)] then
                    table.insert(out, v)
                end
            end
        elseif current ~= nil and current ~= "" then
            table.insert(out, current)
        end
        return out
    end
    obj.SelectAll = function()
        if multi and not obj.Disabled then
            selected = toMap(values)
            applyMulti()
        end
    end
    obj.Clear = function()
        if multi and not obj.Disabled then
            selected = {}
            applyMulti()
        end
    end
    obj.Refresh = function(a, b)
        local newValues = Arg(obj, a, b)
        if type(newValues) ~= "table" then
            return
        end
        values = newValues
        local before = count()
        if multi then
            -- Auswahl auf Werte beschraenken, die es noch gibt
            selected = toMap(selected)
        end
        refresh()
        if multi then
            currentLabel.Text = summary()
            if count() ~= before then
                applyMulti()
            end
        end
        if open then
            searchFrame.Visible = searchOn()
            relayout()
        end
    end
    function obj:SetValue(v)
        obj.Set(v)
    end
    AttachTooltip(obj, row, opts)
    AttachDisable(obj, row, 6, opts, function(v)
        if v and open then
            setOpen(false)
        end
    end)
    RegisterSearch(self, "Dropdown", opts.Text or id, row, obj, opts)
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
    obj.Set = function(a, b)
        if obj.Disabled then
            return
        end
        local t = Arg(obj, a, b)
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
    AttachTooltip(obj, row, opts)
    AttachDisable(obj, row, 6, opts, function(v)
        box.TextEditable = not v
        if v then
            pcall(function()
                if box:IsFocused() then
                    box:ReleaseFocus()
                end
            end)
        end
    end)
    RegisterSearch(self, "Textbox", opts.Text or id, row, obj, opts)
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

    -- Vorschau und Farbfeld sind Benutzerfarben und duerfen NIE vom Theme umgefaerbt werden (noTheme = true)
    local swatch = Create("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -40, 0, 7),
        Size = UDim2.fromOffset(28, 20),
        Parent = row,
    }, true)
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
    }, true)
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
        if obj.Disabled then
            return
        end
        open = not open
        Tween(row, 0.18, { Size = UDim2.new(1, 0, 0, open and (40 + PICK_H + 10) or 34) })
    end)

    obj.Container = row
    obj.Set = function(a, b)
        if obj.Disabled then
            return
        end
        local c = Arg(obj, a, b)
        h, s, v = Color3.toHSV(c)
        commit()
    end
    obj.Get = function()
        return color
    end
    function obj:SetValue(c)
        obj.Set(c)
    end
    AttachTooltip(obj, row, opts)
    AttachDisable(obj, row, 6, opts, function(v)
        if v and open then
            open = false
            Tween(row, 0.18, { Size = UDim2.new(1, 0, 0, 34) })
        end
    end)
    RegisterSearch(self, "ColorPicker", opts.Text or id, row, obj, opts)
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
        if obj.Disabled then
            return
        end
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
        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == current
            and not obj.Disabled then
            task.spawn(callback)
        end
    end)

    obj.Container = row
    obj.Set = function(a, b)
        if obj.Disabled then
            return
        end
        local k = Arg(obj, a, b)
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
    AttachTooltip(obj, row, opts)
    AttachDisable(obj, row, 6, opts, function(v)
        if v then
            listening = false
            keyLabel.Text = current
        end
    end)
    RegisterSearch(self, "KeyPicker", opts.Text or id, row, obj, opts)
    return obj
end

-- ============ INIT ============
return RavineUI
