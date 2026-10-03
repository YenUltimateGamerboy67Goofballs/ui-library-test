--[[
    VexUI v3 - Ultra Modern Glassmorphism UI
    local Library = loadstring(game:HttpGet("URL"))()
    local Window = Library:CreateWindow({Title = "Vex"})
    local Tab = Window:AddTab("Combat", "⚔")
    local Box = Tab:AddSection("General", "★")
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

-- ==================== COLOR PALETTE ====================
local Palette = {
    -- Background layers (deep purple-blue)
    BgDeep        = Color3.fromRGB(10, 8, 20),
    BgMain        = Color3.fromRGB(18, 15, 32),
    BgGlass       = Color3.fromRGB(28, 24, 48),
    BgCard        = Color3.fromRGB(35, 30, 58),
    BgCardHover   = Color3.fromRGB(45, 38, 72),
    
    -- Borders
    Border        = Color3.fromRGB(60, 50, 100),
    BorderLight   = Color3.fromRGB(80, 70, 130),
    
    -- Text
    TextPrimary   = Color3.fromRGB(250, 250, 255),
    TextSecondary = Color3.fromRGB(170, 165, 200),
    TextMuted     = Color3.fromRGB(110, 105, 140),
    
    -- Accents (purple/pink/cyan)
    Accent1       = Color3.fromRGB(160, 80, 255),  -- Purple
    Accent2       = Color3.fromRGB(255, 60, 180),  -- Pink
    Accent3       = Color3.fromRGB(0, 220, 255),   -- Cyan
    AccentGlow    = Color3.fromRGB(200, 120, 255),
    
    -- States
    Success       = Color3.fromRGB(80, 240, 160),
    Warning       = Color3.fromRGB(255, 200, 60),
    Danger        = Color3.fromRGB(255, 80, 120),
    
    -- Toggles
    ToggleOn      = Color3.fromRGB(160, 80, 255),
    ToggleOff     = Color3.fromRGB(55, 50, 80),
}

local Fonts = {
    Light   = Enum.Font.Gotham,
    Regular = Enum.Font.GothamMedium,
    Bold    = Enum.Font.GothamBold,
}

-- ==================== HELPERS ====================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    return inst
end

local function Corner(inst, r)
    return Create("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = inst})
end

local function Stroke(inst, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Palette.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst
    })
end

local function Gradient(inst, c1, c2, rotation, transparency)
    return Create("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rotation or 0,
        Transparency = transparency or NumberSequence.new(0),
        Parent = inst
    })
end

local function Gradient3(inst, c1, c2, c3, rotation)
    return Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(0.5, c2),
            ColorSequenceKeypoint.new(1, c3),
        }),
        Rotation = rotation or 0,
        Parent = inst
    })
end

local function Tween(inst, time, props, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(
        time or 0.25,
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

-- ==================== ANIMATED GRADIENT ====================
local function AnimateGradient(gradient, speed)
    speed = speed or 1
    task.spawn(function()
        local hue = 0
        while gradient and gradient.Parent do
            hue = (hue + 0.003 * speed) % 1
            local c1 = Color3.fromHSV(hue, 0.7, 1)
            local c2 = Color3.fromHSV((hue + 0.15) % 1, 0.7, 1)
            local c3 = Color3.fromHSV((hue + 0.3) % 1, 0.7, 1)
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, c1),
                ColorSequenceKeypoint.new(0.5, c2),
                ColorSequenceKeypoint.new(1, c3),
            })
            RunService.Heartbeat:Wait()
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
            Name = "VexUI_Notifs", ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 9999, Parent = CoreGui
        })
    end
    NotifHolder = Create("Frame", {
        Name = "Holder", BackgroundTransparency = 1,
        Position = UDim2.new(1, -24, 0, 24),
        Size = UDim2.new(0, 340, 1, -48),
        AnchorPoint = Vector2.new(1, 0), Parent = gui
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10), Parent = NotifHolder
    })
    return NotifHolder
end

function VexUI:Notify(data)
    local holder = EnsureNotifs()
    local title = data.Title or "Notice"
    local text = data.Description or data.Text or ""
    local duration = data.Time or 4
    
    local card = Create("Frame", {
        Name = "Notif", BackgroundColor3 = Palette.BgGlass,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(1, 360, 0, 0), ClipsDescendants = true,
        Parent = holder
    })
    Corner(card, 12)
    local cardStroke = Stroke(card, Palette.BorderLight, 1)
    Gradient(card, Palette.BgGlass, Palette.BgMain, 135)
    
    -- Animated glow bar
    local bar = Create("Frame", {
        BackgroundColor3 = Palette.Accent1, BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0), Parent = card
    })
    local barGradient = Gradient3(bar, Palette.Accent1, Palette.Accent2, Palette.Accent3, 90)
    AnimateGradient(barGradient, 1)
    
    -- Glow
    local glow = Create("Frame", {
        BackgroundColor3 = Palette.Accent1, BackgroundTransparency = 0.7,
        BorderSizePixel = 0, Size = UDim2.new(0, 20, 1, 0), Parent = card
    })
    Gradient(glow, Palette.Accent2, Palette.BgGlass, 90, NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    }))
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 14),
        Size = UDim2.new(1, -30, 0, 20),
        Font = Fonts.Bold, Text = title,
        TextColor3 = Palette.TextPrimary, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 36),
        Size = UDim2.new(1, -30, 1, -40),
        Font = Fonts.Light, Text = text,
        TextColor3 = Palette.TextSecondary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = card
    })
    
    Tween(card, 0.4, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
    
    task.delay(duration, function()
        Tween(card, 0.3, {Position = UDim2.new(1, 360, 0, 0)})
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
    local subtitle = opts.Subtitle or "Modern"
    
    local gui = Create("ScreenGui", {
        Name = "VexUI", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999, Parent = CoreGui
    })
    
    -- Background blur effect (fake)
    local shadow = Create("ImageLabel", {
        BackgroundTransparency = 1, Image = "rbxassetid://5028857472",
        ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.2,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 450, 450),
        Size = UDim2.new(1, 60, 1, 60),
        Position = UDim2.new(0, -30, 0, -30),
        ZIndex = 0, Parent = gui
    })
    
    -- Main window
    local main = Create("Frame", {
        Name = "Main", BackgroundColor3 = Palette.BgMain,
        BorderSizePixel = 0, Size = UDim2.new(0, 680, 0, 440),
        Position = UDim2.new(0.5, -340, 0.5, -220),
        ClipsDescendants = true, ZIndex = 1, Parent = gui
    })
    Corner(main, 16)
    local mainStroke = Stroke(main, Palette.BorderLight, 1, 0.3)
    local mainGradient = Gradient(main, Palette.BgMain, Palette.BgDeep, 135)
    
    -- Animated top glow bar
    local topGlow = Create("Frame", {
        BackgroundColor3 = Palette.Accent1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 3), ZIndex = 5, Parent = main
    })
    local topGlowGrad = Gradient3(topGlow, Palette.Accent1, Palette.Accent2, Palette.Accent3, 0)
    AnimateGradient(topGlowGrad, 1.5)
    
    -- Ambient light blobs inside main
    local blob1 = Create("Frame", {
        BackgroundColor3 = Palette.Accent1, BackgroundTransparency = 0.85,
        BorderSizePixel = 0, Size = UDim2.new(0, 300, 0, 300),
        Position = UDim2.new(0, -100, 0, -100),
        ZIndex = 0, Parent = main
    })
    Corner(blob1, 150)
    
    local blob2 = Create("Frame", {
        BackgroundColor3 = Palette.Accent3, BackgroundTransparency = 0.9,
        BorderSizePixel = 0, Size = UDim2.new(0, 250, 0, 250),
        Position = UDim2.new(1, -150, 1, -150),
        ZIndex = 0, Parent = main
    })
    Corner(blob2, 125)
    
    -- ==================== SIDEBAR ====================
    local sidebar = Create("Frame", {
        Name = "Sidebar", BackgroundColor3 = Palette.BgGlass,
        BackgroundTransparency = 0.4, BorderSizePixel = 0,
        Size = UDim2.new(0, 180, 1, 0), ZIndex = 2, Parent = main
    })
    Corner(sidebar, 16)
    local sideGradient = Gradient(sidebar, Palette.BgGlass, Palette.BgDeep, 90)
    
    -- Square off right side
    Create("Frame", {
        BackgroundColor3 = Palette.BgGlass, BackgroundTransparency = 0.4,
        BorderSizePixel = 0, Position = UDim2.new(1, -16, 0, 0),
        Size = UDim2.new(0, 16, 1, 0), ZIndex = 2, Parent = sidebar
    })
    
    -- Logo area
    local logoArea = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 80),
        ZIndex = 3, Parent = sidebar
    })
    
    -- Logo icon with animated gradient
    local logoIcon = Create("Frame", {
        BackgroundColor3 = Palette.Accent1, BorderSizePixel = 0,
        Position = UDim2.new(0, 20, 0, 22), Size = UDim2.new(0, 40, 0, 40),
        ZIndex = 4, Parent = logoArea
    })
    Corner(logoIcon, 12)
    local logoGrad = Gradient3(logoIcon, Palette.Accent1, Palette.Accent2, Palette.Accent3, 45)
    AnimateGradient(logoGrad, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Font = Fonts.Bold, Text = string.sub(title, 1, 1),
        TextColor3 = Color3.new(1, 1, 1), TextSize = 22, ZIndex = 5, Parent = logoIcon
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 70, 0, 22),
        Size = UDim2.new(1, -80, 0, 22),
        Font = Fonts.Bold, Text = title,
        TextColor3 = Palette.TextPrimary, TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = logoArea
    })
    
    -- Subtitle with gradient-ish text
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 70, 0, 42),
        Size = UDim2.new(1, -80, 0, 16),
        Font = Fonts.Light, Text = subtitle,
        TextColor3 = Palette.Accent3, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = logoArea
    })
    
    -- Divider with gradient
    local div1 = Create("Frame", {
        BackgroundColor3 = Palette.BorderLight, BorderSizePixel = 0,
        Position = UDim2.new(0, 20, 0, 76),
        Size = UDim2.new(1, -40, 0, 1),
        BackgroundTransparency = 0.5, ZIndex = 3, Parent = sidebar
    })
    Gradient(div1, Palette.Accent1, Palette.BgGlass, 0, NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    }))
    
    -- Tab list
    local tabList = Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 90),
        Size = UDim2.new(1, 0, 1, -140), ZIndex = 3, Parent = sidebar
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4), Parent = tabList
    })
    Padding(tabList, 0, 12, 0, 12)
    
    -- Bottom user info
    local bottomBar = Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -56),
        Size = UDim2.new(1, 0, 0, 56), ZIndex = 3, Parent = sidebar
    })
    
    local userCard = Create("Frame", {
        BackgroundColor3 = Palette.BgCard, BackgroundTransparency = 0.4,
        BorderSizePixel = 0, Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -24, 0, 44), ZIndex = 4, Parent = bottomBar
    })
    Corner(userCard, 10)
    Stroke(userCard, Palette.BorderLight, 1, 0.5)
    Gradient(userCard, Palette.BgCard, Palette.BgGlass, 90)
    
    local avatar = Create("ImageLabel", {
        BackgroundColor3 = Palette.BgDeep, BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0.5, -15),
        Size = UDim2.new(0, 30, 0, 30),
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
        ZIndex = 5, Parent = userCard
    })
    Corner(avatar, 15)
    Stroke(avatar, Palette.Accent1, 1.5)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 8),
        Size = UDim2.new(1, -50, 0, 14),
        Font = Fonts.Bold, Text = LocalPlayer.DisplayName,
        TextColor3 = Palette.TextPrimary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = userCard
    })
    
    -- Status with pulsing dot
    local statusDot = Create("Frame", {
        BackgroundColor3 = Palette.Success, BorderSizePixel = 0,
        Position = UDim2.new(0, 42, 0, 26),
        Size = UDim2.new(0, 6, 0, 6), ZIndex = 5, Parent = userCard
    })
    Corner(statusDot, 3)
    
    -- Pulse animation
    task.spawn(function()
        while statusDot and statusDot.Parent do
            Tween(statusDot, 0.8, {BackgroundTransparency = 0.5})
            task.wait(0.8)
            Tween(statusDot, 0.8, {BackgroundTransparency = 0})
            task.wait(0.8)
        end
    end)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 54, 0, 22),
        Size = UDim2.new(1, -60, 0, 12),
        Font = Fonts.Light, Text = "Connected",
        TextColor3 = Palette.Success, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = userCard
    })
    
    -- ==================== CONTENT ====================
    local content = Create("Frame", {
        Name = "Content", BackgroundTransparency = 1,
        Position = UDim2.new(0, 180, 0, 0),
        Size = UDim2.new(1, -180, 1, 0), ZIndex = 3, Parent = main
    })
    
    -- Header
    local header = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50),
        ZIndex = 4, Parent = content
    })
    
    local headerLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(1, -110, 1, 0),
        Font = Fonts.Bold, Text = "Dashboard",
        TextColor3 = Palette.TextPrimary, TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = header
    })
    
    -- Controls
    local controls = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -80, 0.5, -11),
        Size = UDim2.new(0, 70, 0, 22), ZIndex = 5, Parent = header
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6), Parent = controls
    })
    
    local function makeCtrlBtn(symbol, hoverColor)
        local btn = Create("TextButton", {
            BackgroundColor3 = Palette.BgCard, BorderSizePixel = 0,
            Size = UDim2.new(0, 22, 0, 22),
            Font = Fonts.Bold, Text = symbol,
            TextColor3 = Palette.TextSecondary, TextSize = 13,
            AutoButtonColor = false, ZIndex = 5, Parent = controls
        })
        Corner(btn, 11)
        Stroke(btn, Palette.Border, 1, 0.5)
        local s = btn:FindFirstChildOfClass("UIStroke")
        btn.MouseEnter:Connect(function()
            Tween(btn, 0.2, {BackgroundColor3 = hoverColor})
            Tween(btn, 0.2, {TextColor3 = Color3.new(1, 1, 1)})
            Tween(s, 0.2, {Color = hoverColor})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.2, {BackgroundColor3 = Palette.BgCard})
            Tween(btn, 0.2, {TextColor3 = Palette.TextSecondary})
            Tween(s, 0.2, {Color = Palette.Border})
        end)
        return btn
    end
    
    local minBtn = makeCtrlBtn("−", Palette.Warning)
    local closeBtn = makeCtrlBtn("×", Palette.Danger)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, 0.3, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.35)
        gui.Enabled = false
    end)
    
    -- Tab content holder
    local tabContent = Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(1, 0, 1, -50), ZIndex = 4, Parent = content
    })
    
    local windowObj = setmetatable({
        Gui = gui, Main = main, TabList = tabList,
        Content = tabContent, Tabs = {}, ActiveTab = nil,
        Minimized = false, HeaderLabel = headerLabel,
    }, Window)
    
    MakeDraggable(main, header)
    
    minBtn.MouseButton1Click:Connect(function()
        windowObj.Minimized = not windowObj.Minimized
        local tgt = windowObj.Minimized and UDim2.new(0, 680, 0, 50) or UDim2.new(0, 680, 0, 440)
        Tween(main, 0.3, {Size = tgt}, Enum.EasingStyle.Quart)
        sidebar.Visible = not windowObj.Minimized
        content.Visible = not windowObj.Minimized
    end)
    
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
        Name = name, Icon = icon or "●", Window = self, Sections = {},
    }, {__index = Tab})
    
    local btn = Create("TextButton", {
        Name = name, BackgroundColor3 = Palette.Accent1,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 42), Font = Fonts.Regular,
        Text = "", AutoButtonColor = false, ZIndex = 4, Parent = self.TabList
    })
    Corner(btn, 10)
    
    -- Active state glow overlay
    local activeGlow = Create("Frame", {
        BackgroundColor3 = Palette.Accent1,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 4, Parent = btn
    })
    Corner(activeGlow, 10)
    local activeGrad = Gradient(activeGlow, Palette.Accent1, Palette.Accent2, 90)
    
    -- Left indicator bar
    local indicator = Create("Frame", {
        Name = "Indicator", BackgroundColor3 = Palette.Accent3,
        BorderSizePixel = 0, Position = UDim2.new(0, -3, 0.5, -10),
        Size = UDim2.new(0, 3, 0, 20), BackgroundTransparency = 1, ZIndex = 6, Parent = btn
    })
    Corner(indicator, 2)
    Gradient(indicator, Palette.Accent3, Palette.Accent2, 90)
    
    -- Icon
    local iconLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(0, 22, 1, 0),
        Font = Fonts.Bold, Text = tab.Icon,
        TextColor3 = Palette.TextMuted, TextSize = 15,
        ZIndex = 5, Parent = btn
    })
    
    -- Name
    local nameLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Fonts.Regular, Text = name,
        TextColor3 = Palette.TextSecondary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = btn
    })
    
    tab.Button = btn
    tab.Indicator = indicator
    tab.IconLabel = iconLabel
    tab.NameLabel = nameLabel
    tab.ActiveGlow = activeGlow
    
    -- Content
    local frame = Create("Frame", {
        Name = name .. "_Frame", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 4, Parent = self.Content
    })
    tab.Frame = frame
    
    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btn, 0.2, {BackgroundTransparency = 0.7})
            Tween(nameLabel, 0.2, {TextColor3 = Palette.TextPrimary})
            Tween(iconLabel, 0.2, {TextColor3 = Palette.TextPrimary})
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btn, 0.2, {BackgroundTransparency = 1})
            Tween(nameLabel, 0.2, {TextColor3 = Palette.TextSecondary})
            Tween(iconLabel, 0.2, {TextColor3 = Palette.TextMuted})
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
        Tween(t.Button, 0.25, {BackgroundTransparency = 1})
        Tween(t.Indicator, 0.25, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, -3, 0.5, -10)
        })
        Tween(t.NameLabel, 0.25, {TextColor3 = Palette.TextSecondary})
        Tween(t.IconLabel, 0.25, {TextColor3 = Palette.TextMuted})
    end
    
    self.ActiveTab = tab
    tab.Frame.Visible = true
    Tween(tab.Button, 0.25, {BackgroundTransparency = 0.3})
    Tween(tab.Indicator, 0.3, {
        BackgroundTransparency = 0,
        Position = UDim2.new(0, 0, 0.5, -10)
    }, Enum.EasingStyle.Back)
    Tween(tab.NameLabel, 0.25, {TextColor3 = Palette.TextPrimary})
    Tween(tab.IconLabel, 0.25, {TextColor3 = Color3.new(1, 1, 1)})
    
    if self.HeaderLabel then
        self.HeaderLabel.Text = tab.Name
    end
end

-- ==================== TAB ====================
local Tab = {}
Tab.__index = Tab

function Tab:AddSection(name, icon)
    local section = setmetatable({
        Name = name, Elements = {}, Tab = self,
    }, {__index = Section})
    
    local frame = Create("Frame", {
        Name = name, BackgroundColor3 = Palette.BgCard,
        BackgroundTransparency = 0.3, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 5, Parent = self.Frame
    })
    Corner(frame, 14)
    Stroke(frame, Palette.BorderLight, 1, 0.5)
    Gradient(frame, Palette.BgCard, Palette.BgGlass, 135)
    
    -- Header
    local header = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 6, Parent = frame
    })
    
    -- Icon with gradient
    local iconBg = Create("Frame", {
        BackgroundColor3 = Palette.Accent1, BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24), ZIndex = 7, Parent = header
    })
    Corner(iconBg, 8)
    local iconGrad = Gradient3(iconBg, Palette.Accent1, Palette.Accent2, Palette.Accent3, 45)
    AnimateGradient(iconGrad, 1.2)
    
    Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Font = Fonts.Bold, Text = icon or "★",
        TextColor3 = Color3.new(1, 1, 1), TextSize = 13,
        ZIndex = 8, Parent = iconBg
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Fonts.Bold, Text = name,
        TextColor3 = Palette.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7, Parent = header
    })
    
    -- Gradient divider
    local divider = Create("Frame", {
        BackgroundColor3 = Palette.BorderLight, BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0, 48),
        Size = UDim2.new(1, -32, 0, 1),
        BackgroundTransparency = 0.4, ZIndex = 6, Parent = frame
    })
    Gradient(divider, Palette.Accent1, Palette.Border, 0, NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    }))
    
    -- Scroll
    local scroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 54),
        Size = UDim2.new(1, 0, 1, -60), CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3, ScrollBarImageColor3 = Palette.Accent1,
        ScrollBarImageTransparency = 0.3, BorderSizePixel = 0,
        ZIndex = 6, Parent = frame
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8), Parent = scroll
    })
    Padding(scroll, 6, 16, 16, 16)
    
    local layout = scroll:FindFirstChildOfClass("UIListLayout")
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
    end)
    
    section.Frame = frame
    section.Scroll = scroll
    return section
end

-- ==================== SECTION ====================
local Section = {}
Section.__index = Section

function Section:AddDivider()
    return Create("Frame", {
        BackgroundColor3 = Palette.BorderLight,
        BorderSizePixel = 0, BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 1), ZIndex = 7, Parent = self.Scroll
    })
end

function Section:AddLabel(text)
    return Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
        Font = Fonts.Light, Text = text,
        TextColor3 = Palette.TextSecondary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7, Parent = self.Scroll
    })
end

function Section:AddButton(text, opts)
    opts = opts or {}
    local callback = type(opts) == "function" and opts or (opts.Callback or function() end)
    local icon = opts.Icon or ""
    
    local btn = Create("TextButton", {
        BackgroundColor3 = Palette.BgGlass, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40),
        Font = Fonts.Regular, Text = "", AutoButtonColor = false,
        ZIndex = 7, Parent = self.Scroll
    })
    Corner(btn, 10)
    local strk = Stroke(btn, Palette.BorderLight, 1, 0.5)
    local btnGrad = Gradient(btn, Palette.BgGlass, Palette.BgCard, 90)
    
    -- Hover glow overlay
    local glow = Create("Frame", {
        BackgroundColor3 = Palette.Accent1, BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 7, Parent = btn
    })
    Corner(glow, 10)
    local glowGrad = Gradient(glow, Palette.Accent1, Palette.Accent2, 45)
    
    if icon ~= "" then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(0, 22, 1, 0),
            Font = Fonts.Bold, Text = icon,
            TextColor3 = Palette.Accent2, TextSize = 14,
            ZIndex = 9, Parent = btn
        })
    end
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, icon ~= "" and 44 or 14, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Fonts.Regular, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9, Parent = btn
    })
    
    btn.MouseEnter:Connect(function()
        Tween(btn, 0.2, {BackgroundTransparency = 0.1})
        Tween(glow, 0.2, {BackgroundTransparency = 0.75})
        Tween(strk, 0.2, {Color = Palette.Accent1, Transparency = 0.3})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.2, {BackgroundTransparency = 0.3})
        Tween(glow, 0.2, {BackgroundTransparency = 1})
        Tween(strk, 0.2, {Color = Palette.BorderLight, Transparency = 0.5})
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
    local desc = opts.Description
    
    local height = desc and 54 or 42
    
    local container = Create("Frame", {
        BackgroundColor3 = Palette.BgGlass, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, height),
        ZIndex = 7, Parent = self.Scroll
    })
    Corner(container, 10)
    local strk = Stroke(container, Palette.BorderLight, 1, 0.5)
    
    -- Toggle track with gradient when on
    local track = Create("Frame", {
        BackgroundColor3 = state and Palette.Accent1 or Palette.ToggleOff,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -54, 0.5, -11),
        Size = UDim2.new(0, 40, 0, 22), ZIndex = 8, Parent = container
    })
    Corner(track, 11)
    local trackStroke = Stroke(track, state and Palette.AccentGlow or Palette.Border, 1, state and 0.3 or 0.7)
    local trackGrad = Gradient3(track, Palette.Accent1, Palette.Accent2, Palette.Accent3, 0)
    
    -- Thumb
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
        Size = UDim2.new(0, 18, 0, 18), ZIndex = 9, Parent = track
    })
    Corner(thumb, 9)
    
    -- Text
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, desc and 8 or 0),
        Size = UDim2.new(1, -80, 0, desc and 20 or height),
        Font = Fonts.Regular, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    if desc then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 28),
            Size = UDim2.new(1, -80, 0, 16),
            Font = Fonts.Light, Text = desc,
            TextColor3 = Palette.TextMuted, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = container
        })
    end
    
    local obj = {Id = id, State = state}
    
    local function setState(v, fire)
        state = v
        Tween(track, 0.25, {
            BackgroundColor3 = state and Palette.Accent1 or Palette.ToggleOff
        })
        Tween(trackStroke, 0.25, {
            Color = state and Palette.AccentGlow or Palette.Border,
            Transparency = state and 0.3 or 0.7
        })
        Tween(thumb, 0.3, {
            Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }, Enum.EasingStyle.Back)
        obj.State = state
        if fire then task.spawn(callback, state) end
    end
    
    local click = Create("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Text = "", ZIndex = 8, Parent = container
    })
    click.MouseButton1Click:Connect(function() setState(not state, true) end)
    
    click.MouseEnter:Connect(function()
        Tween(container, 0.2, {BackgroundTransparency = 0.1})
        Tween(strk, 0.2, {Color = Palette.Accent1, Transparency = 0.4})
    end)
    click.MouseLeave:Connect(function()
        Tween(container, 0.2, {BackgroundTransparency = 0.3})
        Tween(strk, 0.2, {Color = Palette.BorderLight, Transparency = 0.5})
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
        BackgroundColor3 = Palette.BgGlass, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 56),
        ZIndex = 7, Parent = self.Scroll
    })
    Corner(container, 10)
    Stroke(container, Palette.BorderLight, 1, 0.5)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(1, -100, 0, 16),
        Font = Fonts.Regular, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -80, 0, 10),
        Size = UDim2.new(0, 64, 0, 16),
        Font = Fonts.Bold, Text = tostring(value) .. suffix,
        TextColor3 = Palette.Accent2, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 8, Parent = container
    })
    
    -- Track
    local barBg = Create("Frame", {
        BackgroundColor3 = Palette.ToggleOff, BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0, 40),
        Size = UDim2.new(1, -32, 0, 5),
        ZIndex = 8, Parent = container
    })
    Corner(barBg, 3)
    
    local fill = Create("Frame", {
        BackgroundColor3 = Palette.Accent1, BorderSizePixel = 0,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        ZIndex = 9, Parent = barBg
    })
    Corner(fill, 3)
    Gradient3(fill, Palette.Accent1, Palette.Accent2, Palette.Accent3, 0)
    
    -- Thumb with glow
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14), ZIndex = 10, Parent = barBg
    })
    Corner(thumb, 7)
    local thumbStroke = Stroke(thumb, Palette.Accent2, 2)
    
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
        BackgroundColor3 = Palette.BgGlass, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42),
        ClipsDescendants = false, ZIndex = 7, Parent = self.Scroll
    })
    Corner(container, 10)
    Stroke(container, Palette.BorderLight, 1, 0.5)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -120, 1, 0),
        Font = Fonts.Regular, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    local currentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -110, 0, 0),
        Size = UDim2.new(0, 76, 1, 0),
        Font = Fonts.Bold, Text = tostring(current),
        TextColor3 = Palette.Accent2, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 8, Parent = container
    })
    
    local arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -26, 0, 0),
        Size = UDim2.new(0, 16, 1, 0),
        Font = Fonts.Bold, Text = "▾",
        TextColor3 = Palette.TextMuted, TextSize = 14,
        ZIndex = 8, Parent = container
    })
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Text = "", ZIndex = 8, Parent = container
    })
    
    local list = Create("ScrollingFrame", {
        BackgroundColor3 = Palette.BgDeep, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 6),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3, ScrollBarImageColor3 = Palette.Accent1,
        Visible = false, ZIndex = 100, Parent = container
    })
    Corner(list, 10)
    Stroke(list, Palette.Accent1, 1, 0.4)
    local layout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3), Parent = list
    })
    Padding(list, 5, 5, 5, 5)
    
    local optionButtons = {}
    local function refresh()
        for _, b in ipairs(optionButtons) do b:Destroy() end
        optionButtons = {}
        for _, val in ipairs(values) do
            local opt = Create("TextButton", {
                BackgroundColor3 = Palette.Accent1, BackgroundTransparency = 1,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28),
                Font = Fonts.Light, Text = tostring(val),
                TextColor3 = Palette.TextPrimary, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, ZIndex = 101, Parent = list
            })
            Corner(opt, 6)
            Padding(opt, 0, 0, 0, 10)
            opt.MouseEnter:Connect(function()
                Tween(opt, 0.15, {BackgroundTransparency = 0.8})
            end)
            opt.MouseLeave:Connect(function()
                Tween(opt, 0.15, {BackgroundTransparency = 1})
            end)
            opt.MouseButton1Click:Connect(function()
                current = val
                currentLabel.Text = tostring(val)
                open = false
                Tween(list, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
                Tween(arrow, 0.2, {Rotation = 0})
                task.wait(0.2)
                list.Visible = false
                callback(val)
            end)
            table.insert(optionButtons, opt)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
        end)
    end
    refresh()
    
    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            list.Visible = true
            local tgt = math.min(#values * 31 + 14, 180)
            Tween(list, 0.25, {Size = UDim2.new(1, 0, 0, tgt)}, Enum.EasingStyle.Quart)
            Tween(arrow, 0.2, {Rotation = 180})
        else
            Tween(list, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
            Tween(arrow, 0.2, {Rotation = 0})
            task.wait(0.2)
            list.Visible = false
        end
    end)
    
    return {
        Set = function(v) current = v; currentLabel.Text = tostring(v); callback(v) end,
        Get = function() return current end,
        Refresh = function(nv) values = nv; refresh() end
    }
end

function Section:AddInput(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local placeholder = opts.Placeholder or "Type here..."
    local default = opts.Default or ""
    
    local container = Create("Frame", {
        BackgroundColor3 = Palette.BgGlass, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42),
        ZIndex = 7, Parent = self.Scroll
    })
    Corner(container, 10)
    Stroke(container, Palette.BorderLight, 1, 0.5)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(0.4, -16, 1, 0),
        Font = Fonts.Regular, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    local box = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.4, 0, 0, 0),
        Size = UDim2.new(0.6, -16, 1, 0),
        Font = Fonts.Light, Text = default,
        PlaceholderText = placeholder,
        TextColor3 = Palette.Accent2, PlaceholderColor3 = Palette.TextMuted,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
        ClearTextOnFocus = false, ZIndex = 8, Parent = container
    })
    
    box.Focused:Connect(function()
        Tween(container, 0.15, {BackgroundTransparency = 0.1})
    end)
    box.FocusLost:Connect(function()
        Tween(container, 0.15, {BackgroundTransparency = 0.3})
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
        BackgroundColor3 = Palette.BgGlass, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42),
        ZIndex = 7, Parent = self.Scroll
    })
    Corner(container, 10)
    Stroke(container, Palette.BorderLight, 1, 0.5)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Font = Fonts.Regular, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    local keyBtn = Create("TextButton", {
        BackgroundColor3 = Palette.BgDeep, BorderSizePixel = 0,
        Position = UDim2.new(1, -74, 0.5, -12),
        Size = UDim2.new(0, 60, 0, 24),
        Font = Fonts.Bold, Text = current,
        TextColor3 = Palette.Accent2, TextSize = 11,
        AutoButtonColor = false, ZIndex = 8, Parent = container
    })
    Corner(keyBtn, 8)
    local keyStroke = Stroke(keyBtn, Palette.Accent1, 1, 0.4)
    
    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        Tween(keyBtn, 0.2, {BackgroundColor3 = Palette.Accent1})
        Tween(keyBtn, 0.2, {TextColor3 = Color3.new(1, 1, 1)})
    end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode.Name
                keyBtn.Text = current
                listening = false
                Tween(keyBtn, 0.2, {BackgroundColor3 = Palette.BgDeep})
                Tween(keyBtn, 0.2, {TextColor3 = Palette.Accent2})
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
    local default = opts.Default or Color3.fromRGB(160, 80, 255)
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local color = default
    
    local container = Create("Frame", {
        BackgroundColor3 = Palette.BgGlass, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42),
        ZIndex = 7, Parent = self.Scroll
    })
    Corner(container, 10)
    Stroke(container, Palette.BorderLight, 1, 0.5)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Fonts.Regular, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    local swatch = Create("Frame", {
        BackgroundColor3 = color, BorderSizePixel = 0,
        Position = UDim2.new(1, -54, 0.5, -11),
        Size = UDim2.new(0, 38, 0, 22),
        ZIndex = 8, Parent = container
    })
    Corner(swatch, 8)
    Stroke(swatch, Palette.TextPrimary, 1.5, 0.5)
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Text = "", ZIndex = 9, Parent = container
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
VexUI.Theme = Palette

return VexUI
