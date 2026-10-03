--[[
    VexUI v2 - Modern Premium UI Library
    Usage:
    local Library = loadstring(game:HttpGet("URL"))()
    local Window = Library:CreateWindow({Title = "Vex"})
    local Tab = Window:AddTab("Combat", "⚔")
    local Box = Tab:AddSection("General")
    Box:AddToggle("id", {Text = "Enable", Callback = function(v) end})
]]

local VexUI = {}
VexUI.__index = VexUI

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==================== CONFIG ====================
local Config = {
    -- Colors
    Background       = Color3.fromRGB(15, 15, 20),
    BackgroundLight  = Color3.fromRGB(22, 22, 28),
    CardBackground   = Color3.fromRGB(28, 28, 36),
    CardHover        = Color3.fromRGB(35, 35, 45),
    Border           = Color3.fromRGB(45, 45, 58),
    TextPrimary      = Color3.fromRGB(245, 245, 250),
    TextSecondary    = Color3.fromRGB(150, 150, 170),
    TextMuted        = Color3.fromRGB(90, 90, 110),
    Accent           = Color3.fromRGB(230, 30, 60),
    AccentSecondary  = Color3.fromRGB(180, 20, 80),
    AccentGlow       = Color3.fromRGB(255, 60, 100),
    Success          = Color3.fromRGB(60, 200, 120),
    Warning          = Color3.fromRGB(255, 180, 50),
    Danger           = Color3.fromRGB(255, 70, 70),
    ToggleOn         = Color3.fromRGB(230, 30, 60),
    ToggleOff        = Color3.fromRGB(55, 55, 70),
    
    -- Fonts
    FontLight        = Enum.Font.Gotham,
    FontRegular      = Enum.Font.GothamMedium,
    FontBold         = Enum.Font.GothamBold,
    
    -- Sizes
    CornerLarge      = 12,
    CornerMedium     = 8,
    CornerSmall     = 6,
    WindowSize       = UDim2.new(0, 640, 0, 420),
}

-- ==================== HELPERS ====================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Corner(inst, r)
    return Create("UICorner", {CornerRadius = UDim.new(0, r or Config.CornerMedium), Parent = inst})
end

local function Stroke(inst, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Config.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst
    })
end

local function Gradient(inst, c1, c2, rot, trans)
    return Create("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rot or 0,
        Transparency = trans or NumberSequence.new(0),
        Parent = inst
    })
end

local function Tween(inst, time, props, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(
        time or 0.2,
        style or Enum.EasingStyle.Quint,
        dir or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

local function Padding(inst, top, right, bottom, left)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        Parent = inst
    })
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==================== NOTIFICATIONS ====================
local NotifHolder

local function EnsureNotifs()
    if NotifHolder and NotifHolder.Parent then return NotifHolder end
    local gui = CoreGui:FindFirstChild("VexUI_Notifs")
    if not gui then
        gui = Create("ScreenGui", {
            Name = "VexUI_Notifs",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 9999,
            Parent = CoreGui
        })
    end
    NotifHolder = Create("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -24, 0, 24),
        Size = UDim2.new(0, 320, 1, -48),
        AnchorPoint = Vector2.new(1, 0),
        Parent = gui
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = NotifHolder
    })
    return NotifHolder
end

function VexUI:Notify(data)
    local holder = EnsureNotifs()
    local title = data.Title or "Notice"
    local text = data.Description or data.Text or ""
    local duration = data.Time or 4
    local icon = data.Icon or "●"
    local accent = data.Accent or Config.Accent
    
    local card = Create("Frame", {
        Name = "Notif",
        BackgroundColor3 = Config.CardBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 62),
        Position = UDim2.new(1, 340, 0, 0),
        Parent = holder
    })
    Corner(card, Config.CornerMedium)
    Stroke(card, Config.Border, 1)
    Gradient(card, Config.CardBackground, Config.BackgroundLight, 90)
    
    -- Accent bar left
    local bar = Create("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 0, 0, 8),
        Parent = card
    })
    Corner(bar, 3)
    Gradient(bar, accent, Config.AccentSecondary, 90)
    
    -- Icon circle
    local iconBg = Create("Frame", {
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 14),
        Size = UDim2.new(0, 34, 0, 34),
        Parent = card
    })
    Corner(iconBg, 17)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Config.FontBold,
        Text = icon,
        TextColor3 = accent,
        TextSize = 16,
        Parent = iconBg
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 58, 0, 10),
        Size = UDim2.new(1, -70, 0, 18),
        Font = Config.FontBold,
        Text = title,
        TextColor3 = Config.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 58, 0, 28),
        Size = UDim2.new(1, -70, 1, -34),
        Font = Config.FontLight,
        Text = text,
        TextColor3 = Config.TextSecondary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card
    })
    
    Tween(card, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
    
    task.delay(duration, function()
        Tween(card, 0.3, {Position = UDim2.new(1, 340, 0, 0)})
        task.wait(0.35)
        card:Destroy()
    end)
end

-- ==================== WINDOW ====================
local Window = {}
Window.__index = Window

function VexUI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "Vex"
    local subtitle = opts.Subtitle or "Premium"
    
    local gui = Create("ScreenGui", {
        Name = "VexUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = CoreGui
    })
    
    -- Shadow
    local shadow = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857472",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.3,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 450, 450),
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        ZIndex = 0,
        Parent = gui
    })
    
    -- Main window
    local main = Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Config.Background,
        BorderSizePixel = 0,
        Size = Config.WindowSize,
        Position = UDim2.new(0.5, -320, 0.5, -210),
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = gui
    })
    Corner(main, Config.CornerLarge)
    Stroke(main, Config.Border, 1)
    Gradient(main, Config.Background, Color3.fromRGB(10, 10, 14), 135)
    
    -- Glow at top
    local glow = Create("Frame", {
        BackgroundColor3 = Config.Accent,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Parent = main
    })
    Gradient(glow, Config.Accent, Config.AccentSecondary, 0)
    
    -- ==================== SIDEBAR ====================
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Config.BackgroundLight,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 160, 1, 0),
        Parent = main
    })
    Gradient(sidebar, Config.BackgroundLight, Color3.fromRGB(16, 16, 22), 90)
    
    -- Logo area
    local logoArea = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 70),
        Parent = sidebar
    })
    
    local logoIcon = Create("Frame", {
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0, 18),
        Size = UDim2.new(0, 34, 0, 34),
        Parent = logoArea
    })
    Corner(logoIcon, 10)
    Gradient(logoIcon, Config.Accent, Config.AccentSecondary, 45)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Config.FontBold,
        Text = string.sub(title, 1, 1),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 18,
        Parent = logoIcon
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 58, 0, 16),
        Size = UDim2.new(1, -60, 0, 20),
        Font = Config.FontBold,
        Text = title,
        TextColor3 = Config.TextPrimary,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = logoArea
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 58, 0, 34),
        Size = UDim2.new(1, -60, 0, 14),
        Font = Config.FontLight,
        Text = subtitle,
        TextColor3 = Config.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = logoArea
    })
    
    -- Divider
    Create("Frame", {
        BackgroundColor3 = Config.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0, 62),
        Size = UDim2.new(1, -32, 0, 1),
        Parent = sidebar
    })
    
    -- Tab list
    local tabList = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 78),
        Size = UDim2.new(1, 0, 1, -120),
        Parent = sidebar
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        Parent = tabList
    })
    Padding(tabList, 0, 12, 0, 12)
    
    -- Bottom bar with user info
    local bottomBar = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -46),
        Size = UDim2.new(1, 0, 0, 46),
        Parent = sidebar
    })
    
    Create("Frame", {
        BackgroundColor3 = Config.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 0, 1),
        Parent = bottomBar
    })
    
    -- Avatar
    local avatar = Create("ImageLabel", {
        BackgroundColor3 = Config.CardBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(0, 26, 0, 26),
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
        Parent = bottomBar
    })
    Corner(avatar, 13)
    Stroke(avatar, Config.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 10),
        Size = UDim2.new(1, -60, 0, 14),
        Font = Config.FontBold,
        Text = LocalPlayer.DisplayName,
        TextColor3 = Config.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = bottomBar
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 24),
        Size = UDim2.new(1, -60, 0, 12),
        Font = Config.FontLight,
        Text = "Connected",
        TextColor3 = Config.Success,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = bottomBar
    })
    
    -- ==================== CONTENT ====================
    local content = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 0),
        Size = UDim2.new(1, -160, 1, 0),
        Parent = main
    })
    
    -- Header (draggable)
    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = content
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Font = Config.FontBold,
        Text = "Dashboard",
        TextColor3 = Config.TextPrimary,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    -- Window controls
    local controls = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0.5, -10),
        Size = UDim2.new(0, 60, 0, 20),
        Parent = header
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = controls
    })
    
    local function makeCtrlButton(text, hoverColor)
        local btn = Create("TextButton", {
            BackgroundColor3 = Config.CardBackground,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 18, 0, 18),
            Font = Config.FontBold,
            Text = text,
            TextColor3 = Config.TextSecondary,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = controls
        })
        Corner(btn, 9)
        btn.MouseEnter:Connect(function()
            Tween(btn, 0.15, {BackgroundColor3 = hoverColor or Config.CardHover})
            Tween(btn, 0.15, {TextColor3 = Color3.new(1, 1, 1)})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.15, {BackgroundColor3 = Config.CardBackground})
            Tween(btn, 0.15, {TextColor3 = Config.TextSecondary})
        end)
        return btn
    end
    
    local minBtn = makeCtrlButton("−", Config.Warning)
    local closeBtn = makeCtrlButton("×", Config.Danger)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, 0.25, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.3)
        gui.Enabled = false
    end)
    
    -- Tab content holder
    local tabContent = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 1, -40),
        Parent = content
    })
    
    local windowObj = setmetatable({
        Gui = gui,
        Main = main,
        TabList = tabList,
        Content = tabContent,
        Tabs = {},
        ActiveTab = nil,
        Minimized = false,
        HeaderLabel = header:FindFirstChildOfClass("TextLabel"),
    }, Window)
    
    MakeDraggable(main, header)
    
    minBtn.MouseButton1Click:Connect(function()
        windowObj.Minimized = not windowObj.Minimized
        local targetSize = windowObj.Minimized and UDim2.new(0, 640, 0, 40) or Config.WindowSize
        Tween(main, 0.25, {Size = targetSize})
        sidebar.Visible = not windowObj.Minimized
        content.Visible = not windowObj.Minimized
    end)
    
    -- Toggle keybind
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == (opts.ToggleKeybind or Enum.KeyCode.RightControl) then
            gui.Enabled = not gui.Enabled
        end
    end)
    
    return windowObj
end

function Window:AddTab(name, icon)
    local tab = setmetatable({
        Name = name,
        Icon = icon or "●",
        Window = self,
        Sections = {},
    }, {__index = Tab})
    
    -- Tab button
    local btn = Create("TextButton", {
        Name = name,
        BackgroundColor3 = Config.CardBackground,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Config.FontRegular,
        Text = "",
        TextColor3 = Config.TextSecondary,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = self.TabList
    })
    Corner(btn, Config.CornerMedium)
    
    -- Indicator
    local indicator = Create("Frame", {
        Name = "Indicator",
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -8),
        Size = UDim2.new(0, 3, 0, 16),
        BackgroundTransparency = 1,
        Parent = btn
    })
    Corner(indicator, 3)
    Gradient(indicator, Config.Accent, Config.AccentSecondary, 90)
    
    -- Icon
    local iconLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = Config.FontBold,
        Text = tab.Icon,
        TextColor3 = Config.TextMuted,
        TextSize = 14,
        Parent = btn
    })
    
    -- Name
    local nameLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(1, -46, 1, 0),
        Font = Config.FontRegular,
        Text = name,
        TextColor3 = Config.TextSecondary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn
    })
    
    tab.Button = btn
    tab.Indicator = indicator
    tab.IconLabel = iconLabel
    tab.NameLabel = nameLabel
    
    -- Content frame
    local frame = Create("Frame", {
        Name = name .. "_Frame",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        Parent = self.Content
    })
    tab.Frame = frame
    
    -- Hover animations
    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btn, 0.2, {BackgroundTransparency = 0.5, BackgroundColor3 = Config.CardBackground})
            Tween(nameLabel, 0.2, {TextColor3 = Config.TextPrimary})
            Tween(iconLabel, 0.2, {TextColor3 = Config.TextPrimary})
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btn, 0.2, {BackgroundTransparency = 1})
            Tween(nameLabel, 0.2, {TextColor3 = Config.TextSecondary})
            Tween(iconLabel, 0.2, {TextColor3 = Config.TextMuted})
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
    if self.ActiveTab == tab then return end
    
    for _, t in ipairs(self.Tabs) do
        t.Frame.Visible = false
        Tween(t.Button, 0.2, {BackgroundTransparency = 1})
        Tween(t.Indicator, 0.2, {BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 8)})
        Tween(t.NameLabel, 0.2, {TextColor3 = Config.TextSecondary})
        Tween(t.IconLabel, 0.2, {TextColor3 = Config.TextMuted})
    end
    
    self.ActiveTab = tab
    tab.Frame.Visible = true
    Tween(tab.Button, 0.2, {BackgroundTransparency = 0.35, BackgroundColor3 = Config.Accent})
    Tween(tab.Indicator, 0.25, {BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0, 22)})
    Tween(tab.NameLabel, 0.2, {TextColor3 = Config.TextPrimary})
    Tween(tab.IconLabel, 0.2, {TextColor3 = Config.AccentGlow})
    
    if self.HeaderLabel then
        self.HeaderLabel.Text = tab.Name
    end
end

-- ==================== TAB ====================
local Tab = {}
Tab.__index = Tab

function Tab:AddSection(name, icon)
    local section = setmetatable({
        Name = name,
        Elements = {},
        Tab = self,
    }, {__index = Section})
    
    local frame = Create("Frame", {
        Name = name,
        BackgroundColor3 = Config.CardBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self.Frame
    })
    Corner(frame, Config.CornerMedium)
    Stroke(frame, Config.Border, 1)
    
    -- Header
    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = frame
    })
    
    -- Icon circle
    local iconBg = Create("Frame", {
        BackgroundColor3 = Config.Accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0.5, -11),
        Size = UDim2.new(0, 22, 0, 22),
        Parent = header
    })
    Corner(iconBg, 6)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Config.FontBold,
        Text = icon or "●",
        TextColor3 = Config.Accent,
        TextSize = 12,
        Parent = iconBg
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 46, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Config.FontBold,
        Text = name,
        TextColor3 = Config.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    -- Divider
    Create("Frame", {
        BackgroundColor3 = Config.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 42),
        Size = UDim2.new(1, -28, 0, 1),
        Parent = frame
    })
    
    -- Scroll
    local scroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 48),
        Size = UDim2.new(1, 0, 1, -54),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Config.Border,
        ScrollBarImageTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = frame
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = scroll
    })
    Padding(scroll, 4, 14, 14, 14)
    
    local layout = scroll:FindFirstChildOfClass("UIListLayout")
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    section.Frame = frame
    section.Scroll = scroll
    return section
end

-- ==================== SECTION ====================
local Section = {}
Section.__index = Section

function Section:AddDivider()
    local div = Create("Frame", {
        BackgroundColor3 = Config.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self.Scroll
    })
    return div
end

function Section:AddLabel(text)
    local lbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Config.FontLight,
        Text = text,
        TextColor3 = Config.TextSecondary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Scroll
    })
    return lbl
end

function Section:AddButton(text, opts)
    opts = opts or {}
    local callback = type(opts) == "function" and opts or (opts.Callback or function() end)
    local icon = opts.Icon or ""
    
    local btn = Create("TextButton", {
        BackgroundColor3 = Config.BackgroundLight,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        Font = Config.FontRegular,
        Text = "",
        TextColor3 = Config.TextPrimary,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = self.Scroll
    })
    Corner(btn, Config.CornerSmall)
    local strk = Stroke(btn, Config.Border, 1)
    
    -- Glow overlay
    local glow = Create("Frame", {
        BackgroundColor3 = Config.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = btn
    })
    Corner(glow, Config.CornerSmall)
    
    if icon ~= "" then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 20, 1, 0),
            Font = Config.FontBold,
            Text = icon,
            TextColor3 = Config.Accent,
            TextSize = 13,
            Parent = btn
        })
    end
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, icon ~= "" and 38 or 12, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Config.FontRegular,
        Text = text,
        TextColor3 = Config.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn
    })
    
    btn.MouseEnter:Connect(function()
        Tween(btn, 0.2, {BackgroundColor3 = Config.CardHover})
        Tween(glow, 0.2, {BackgroundTransparency = 0.9})
        Tween(strk, 0.2, {Color = Config.Accent})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.2, {BackgroundColor3 = Config.BackgroundLight})
        Tween(glow, 0.2, {BackgroundTransparency = 1})
        Tween(strk, 0.2, {Color = Config.Border})
    end)
    btn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
    
    return btn
end

function Section:AddToggle(id, opts)
    opts = opts or {}
    local state = opts.Default or false
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local desc = opts.Description or nil
    
    local height = desc and 52 or 38
    
    local container = Create("Frame", {
        BackgroundColor3 = Config.BackgroundLight,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height),
        Parent = self.Scroll
    })
    Corner(container, Config.CornerSmall)
    local strk = Stroke(container, Config.Border, 1)
    
    -- Toggle switch
    local track = Create("Frame", {
        BackgroundColor3 = state and Config.ToggleOn or Config.ToggleOff,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -50, 0.5, -10),
        Size = UDim2.new(0, 36, 0, 20),
        Parent = container
    })
    Corner(track, 10)
    local trackStroke = Stroke(track, state and Config.AccentGlow or Config.Border, 1, state and 0.5 or 0)
    
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Parent = track
    })
    Corner(thumb, 8)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, desc and 8 or 0),
        Size = UDim2.new(1, -70, 0, desc and 18 or height),
        Font = Config.FontRegular,
        Text = text,
        TextColor3 = Config.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    if desc then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 26),
            Size = UDim2.new(1, -70, 0, 16),
            Font = Config.FontLight,
            Text = desc,
            TextColor3 = Config.TextMuted,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
    end
    
    local obj = {Id = id, State = state}
    
    local function setState(v, fire)
        state = v
        Tween(track, 0.2, {BackgroundColor3 = state and Config.ToggleOn or Config.ToggleOff})
        Tween(trackStroke, 0.2, {
            Color = state and Config.AccentGlow or Config.Border,
            Transparency = state and 0.5 or 0
        })
        Tween(thumb, 0.25, {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }, Enum.EasingStyle.Back)
        obj.State = state
        if fire then task.spawn(callback, state) end
    end
    
    local click = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = container
    })
    click.MouseButton1Click:Connect(function() setState(not state, true) end)
    
    click.MouseEnter:Connect(function()
        Tween(container, 0.15, {BackgroundColor3 = Config.CardHover})
    end)
    click.MouseLeave:Connect(function()
        Tween(container, 0.15, {BackgroundColor3 = Config.BackgroundLight})
    end)
    
    obj.Set = function(v) setState(v, true) end
    obj.Get = function() return state end
    
    return obj
end

function Section:AddSlider(id, opts)
    opts = opts or {}
    local min = opts.Min or 0
    local max = opts.Max or 100
    local default = opts.Default or min
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local suffix = opts.Suffix or ""
    local rounding = opts.Rounding or 0
    local value = default
    
    local container = Create("Frame", {
        BackgroundColor3 = Config.BackgroundLight,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        Parent = self.Scroll
    })
    Corner(container, Config.CornerSmall)
    Stroke(container, Config.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -80, 0, 16),
        Font = Config.FontRegular,
        Text = text,
        TextColor3 = Config.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 8),
        Size = UDim2.new(0, 56, 0, 16),
        Font = Config.FontBold,
        Text = tostring(value) .. suffix,
        TextColor3 = Config.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })
    
    -- Track
    local barBg = Create("Frame", {
        BackgroundColor3 = Config.ToggleOff,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 36),
        Size = UDim2.new(1, -28, 0, 4),
        Parent = container
    })
    Corner(barBg, 2)
    
    local fill = Create("Frame", {
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        Parent = barBg
    })
    Corner(fill, 2)
    Gradient(fill, Config.Accent, Config.AccentSecondary, 0)
    
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 2,
        Parent = barBg
    })
    Corner(thumb, 6)
    Stroke(thumb, Config.Accent, 2)
    
    local dragging = false
    
    local function updateFromInput(input)
        local relX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local newVal = min + (max - min) * relX
        if rounding > 0 then
            local mult = 10 ^ rounding
            newVal = math.floor(newVal * mult + 0.5) / mult
        else
            newVal = math.floor(newVal + 0.5)
        end
        value = newVal
        Tween(fill, 0.05, {Size = UDim2.new(relX, 0, 1, 0)})
        Tween(thumb, 0.05, {Position = UDim2.new(relX, 0, 0.5, 0)})
        valueLabel.Text = tostring(value) .. suffix
        callback(value)
    end
    
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
        or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return {
        Set = function(v)
            v = math.clamp(v, min, max)
            value = v
            local relX = (v - min) / (max - min)
            Tween(fill, 0.1, {Size = UDim2.new(relX, 0, 1, 0)})
            Tween(thumb, 0.1, {Position = UDim2.new(relX, 0, 0.5, 0)})
            valueLabel.Text = tostring(value) .. suffix
            callback(value)
        end,
        Get = function() return value end
    }
end

function Section:AddDropdown(id, opts)
    opts = opts or {}
    local values = opts.Values or {}
    local default = opts.Default or (values[1] or "")
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local current = default
    local open = false
    
    local container = Create("Frame", {
        BackgroundColor3 = Config.BackgroundLight,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        ClipsDescendants = false,
        ZIndex = 5,
        Parent = self.Scroll
    })
    Corner(container, Config.CornerSmall)
    Stroke(container, Config.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -110, 1, 0),
        Font = Config.FontRegular,
        Text = text,
        TextColor3 = Config.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local currentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -100, 0, 0),
        Size = UDim2.new(0, 70, 1, 0),
        Font = Config.FontRegular,
        Text = tostring(current),
        TextColor3 = Config.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })
    
    local arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -22, 0, 0),
        Size = UDim2.new(0, 12, 1, 0),
        Font = Config.FontBold,
        Text = "▾",
        TextColor3 = Config.TextMuted,
        TextSize = 12,
        Parent = container
    })
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = container
    })
    
    -- List
    local list = Create("ScrollingFrame", {
        BackgroundColor3 = Config.CardBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Config.Border,
        Visible = false,
        ZIndex = 50,
        Parent = container
    })
    Corner(list, Config.CornerSmall)
    Stroke(list, Config.Border, 1)
    local layout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        Parent = list
    })
    Padding(list, 4, 4, 4, 4)
    
    local optionButtons = {}
    local function refresh()
        for _, b in ipairs(optionButtons) do b:Destroy() end
        optionButtons = {}
        for _, val in ipairs(values) do
            local opt = Create("TextButton", {
                BackgroundColor3 = Config.BackgroundLight,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 26),
                Font = Config.FontLight,
                Text = tostring(val),
                TextColor3 = Config.TextPrimary,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                Parent = list
            })
            Corner(opt, Config.CornerSmall)
            Padding(opt, 0, 0, 0, 8)
            opt.MouseEnter:Connect(function()
                Tween(opt, 0.15, {BackgroundTransparency = 0.7, BackgroundColor3 = Config.Accent})
            end)
            opt.MouseLeave:Connect(function()
                Tween(opt, 0.15, {BackgroundTransparency = 1})
            end)
            opt.MouseButton1Click:Connect(function()
                current = val
                currentLabel.Text = tostring(val)
                open = false
                Tween(list, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
                task.wait(0.15)
                list.Visible = false
                callback(val)
            end)
            table.insert(optionButtons, opt)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
    end
    
    refresh()
    
    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            list.Visible = true
            local target = math.min(#values * 29 + 10, 160)
            Tween(list, 0.2, {Size = UDim2.new(1, 0, 0, target)})
            Tween(arrow, 0.15, {Rotation = 180})
        else
            Tween(list, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
            Tween(arrow, 0.15, {Rotation = 0})
            task.wait(0.15)
            list.Visible = false
        end
    end)
    
    return {
        Set = function(v) current = v; currentLabel.Text = tostring(v); callback(v) end,
        Get = function() return current end,
        Refresh = function(newVals) values = newVals; refresh() end
    }
end

function Section:AddInput(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local placeholder = opts.Placeholder or "Type here..."
    local default = opts.Default or ""
    
    local container = Create("Frame", {
        BackgroundColor3 = Config.BackgroundLight,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = self.Scroll
    })
    Corner(container, Config.CornerSmall)
    Stroke(container, Config.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.4, -14, 1, 0),
        Font = Config.FontRegular,
        Text = text,
        TextColor3 = Config.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local box = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.4, 0, 0, 0),
        Size = UDim2.new(0.6, -14, 1, 0),
        Font = Config.FontLight,
        Text = default,
        PlaceholderText = placeholder,
        TextColor3 = Config.TextPrimary,
        PlaceholderColor3 = Config.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ClearTextOnFocus = false,
        Parent = container
    })
    
    box.Focused:Connect(function()
        Tween(container, 0.15, {BackgroundColor3 = Config.CardHover})
    end)
    box.FocusLost:Connect(function()
        Tween(container, 0.15, {BackgroundColor3 = Config.BackgroundLight})
        callback(box.Text)
    end)
    
    return box
end

function Section:AddKeybind(id, opts)
    opts = opts or {}
    local default = opts.Default or "F"
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local current = default
    local listening = false
    
    local container = Create("Frame", {
        BackgroundColor3 = Config.BackgroundLight,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = self.Scroll
    })
    Corner(container, Config.CornerSmall)
    Stroke(container, Config.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Config.FontRegular,
        Text = text,
        TextColor3 = Config.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local keyBtn = Create("TextButton", {
        BackgroundColor3 = Config.CardBackground,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -68, 0.5, -11),
        Size = UDim2.new(0, 56, 0, 22),
        Font = Config.FontBold,
        Text = current,
        TextColor3 = Config.Accent,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = container
    })
    Corner(keyBtn, Config.CornerSmall)
    Stroke(keyBtn, Config.Border, 1)
    
    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        Tween(keyBtn, 0.15, {BackgroundColor3 = Config.Accent, TextColor3 = Color3.new(1, 1, 1)})
    end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode.Name
                keyBtn.Text = current
                listening = false
                Tween(keyBtn, 0.15, {BackgroundColor3 = Config.CardBackground, TextColor3 = Config.Accent})
            end
        else
            if input.KeyCode.Name == current then
                task.spawn(callback)
            end
        end
    end)
    
    return {
        Set = function(k) current = k; keyBtn.Text = k end,
        Get = function() return current end
    }
end

function Section:AddColorPicker(id, opts)
    opts = opts or {}
    local default = opts.Default or Color3.fromRGB(255, 255, 255)
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local color = default
    
    local container = Create("Frame", {
        BackgroundColor3 = Config.BackgroundLight,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = self.Scroll
    })
    Corner(container, Config.CornerSmall)
    Stroke(container, Config.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Config.FontRegular,
        Text = text,
        TextColor3 = Config.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local swatch = Create("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -46, 0.5, -10),
        Size = UDim2.new(0, 32, 0, 20),
        Parent = container
    })
    Corner(swatch, Config.CornerSmall)
    Stroke(swatch, Config.Border, 1)
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = container
    })
    
    btn.MouseButton1Click:Connect(function()
        local h, s, v = Color3.toHSV(color)
        h = (h + 0.1) % 1
        color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = color
        callback(color)
    end)
    
    return {
        Set = function(c) color = c; swatch.BackgroundColor3 = c; callback(c) end,
        Get = function() return color end
    }
end

-- ==================== INIT ====================
VexUI.Theme = Config

return VexUI
