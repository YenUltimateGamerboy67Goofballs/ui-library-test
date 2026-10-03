--[[
    VexUI v6 - Fixed Home Page
    - Working 2-Column layout
    - Proper Cards with grid wrapping
    - Big Buttons
    - Section Headers with red accent
]]

local VexUI = {}
VexUI.__index = VexUI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ==================== PALETTE ====================
local Palette = {
    BgOuter      = Color3.fromRGB(13, 13, 15),
    BgInner      = Color3.fromRGB(20, 20, 22),
    BgCard       = Color3.fromRGB(26, 26, 29),
    BgCardInner  = Color3.fromRGB(34, 34, 38),
    BgButton     = Color3.fromRGB(40, 40, 44),
    BgButtonHov  = Color3.fromRGB(50, 50, 55),
    BgGreen      = Color3.fromRGB(30, 60, 45),
    BgYellow     = Color3.fromRGB(55, 50, 30),
    BgBlue       = Color3.fromRGB(45, 70, 180),
    
    Border       = Color3.fromRGB(38, 38, 42),
    BorderLight  = Color3.fromRGB(52, 52, 58),
    
    TextPrimary  = Color3.fromRGB(240, 240, 245),
    TextSecond   = Color3.fromRGB(150, 150, 158),
    TextMuted    = Color3.fromRGB(100, 100, 108),
    
    Accent       = Color3.fromRGB(220, 40, 50),
    Green        = Color3.fromRGB(90, 220, 130),
    Yellow       = Color3.fromRGB(230, 200, 90),
    Blue         = Color3.fromRGB(70, 130, 220),
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

local function Tween(inst, time, props, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(
        time or 0.2,
        style or Enum.EasingStyle.Quint,
        dir or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
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
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
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
            Name = "VexUI_Notifs", ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 9999, Parent = CoreGui
        })
    end
    NotifHolder = Create("Frame", {
        Name = "Holder", BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 320, 1, -40),
        AnchorPoint = Vector2.new(1, 0), Parent = gui
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8), Parent = NotifHolder
    })
    return NotifHolder
end

function VexUI:Notify(data)
    local holder = EnsureNotifs()
    local title = data.Title or "Notice"
    local text = data.Description or data.Text or ""
    local duration = data.Time or 4
    
    local card = Create("Frame", {
        Name = "Notif", BackgroundColor3 = Palette.BgCard,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(1, 340, 0, 0),
        Parent = holder
    })
    Corner(card, 8)
    Stroke(card, Palette.BorderLight, 1)
    
    local bar = Create("Frame", {
        BackgroundColor3 = Palette.Accent, BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 0, 0, 8),
        Parent = card
    })
    Corner(bar, 3)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(1, -28, 0, 18),
        Font = Fonts.Bold, Text = title,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 28),
        Size = UDim2.new(1, -28, 1, -32),
        Font = Fonts.Light, Text = text,
        TextColor3 = Palette.TextSecond, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = card
    })
    
    Tween(card, 0.3, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
    
    task.delay(duration, function()
        Tween(card, 0.25, {Position = UDim2.new(1, 340, 0, 0)})
        task.wait(0.3)
        card:Destroy()
    end)
end

-- ==================== WINDOW ====================
local Window = {}
Window.__index = Window

function VexUI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "Vex"
    local subtitle = opts.Subtitle or ""
    
    local gui = Create("ScreenGui", {
        Name = "VexUI", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999, Parent = CoreGui
    })
    
    local outer = Create("Frame", {
        Name = "Outer", BackgroundColor3 = Palette.BgOuter,
        BorderSizePixel = 0, Size = UDim2.new(0, 740, 0, 470),
        Position = UDim2.new(0.5, -370, 0.5, -235),
        ClipsDescendants = false, ZIndex = 1, Parent = gui
    })
    Corner(outer, 10)
    Stroke(outer, Palette.Border, 1.5)
    
    local main = Create("Frame", {
        Name = "Main", BackgroundColor3 = Palette.BgInner,
        BorderSizePixel = 0, Size = UDim2.new(1, -6, 1, -6),
        Position = UDim2.new(0, 3, 0, 3),
        ClipsDescendants = true, ZIndex = 2, Parent = outer
    })
    Corner(main, 8)
    
    -- Top bar
    local topBar = Create("Frame", {
        Name = "TopBar", BackgroundColor3 = Palette.BgOuter,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 44),
        ZIndex = 3, Parent = main
    })
    
    Create("Frame", {
        BackgroundColor3 = Palette.Border, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1), ZIndex = 4, Parent = topBar
    })
    
    local logoIcon = Create("Frame", {
        BackgroundColor3 = Palette.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0.5, -9),
        Size = UDim2.new(0, 18, 0, 18),
        ZIndex = 5, Parent = topBar
    })
    Corner(logoIcon, 4)
    
    Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Font = Fonts.Bold, Text = string.sub(title, 1, 1),
        TextColor3 = Color3.new(1, 1, 1), TextSize = 11,
        ZIndex = 6, Parent = logoIcon
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        Font = Fonts.Bold, Text = title,
        TextColor3 = Palette.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = topBar
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40 + (#title * 8) + 10, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Fonts.Light, Text = subtitle,
        TextColor3 = Palette.TextMuted, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = topBar
    })
    
    -- Window controls
    local controls = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 0),
        Size = UDim2.new(0, 60, 0, 44),
        ZIndex = 5, Parent = topBar
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4), Parent = controls
    })
    
    local function makeWinBtn(symbol, hoverColor)
        local btn = Create("TextButton", {
            BackgroundColor3 = Palette.BgInner, BackgroundTransparency = 0.5,
            BorderSizePixel = 0, Size = UDim2.new(0, 24, 0, 24),
            Font = Fonts.Bold, Text = symbol,
            TextColor3 = Palette.TextSecond, TextSize = 14,
            AutoButtonColor = false, ZIndex = 6, Parent = controls
        })
        Corner(btn, 5)
        btn.MouseEnter:Connect(function()
            Tween(btn, 0.15, {BackgroundTransparency = 0, BackgroundColor3 = hoverColor})
            Tween(btn, 0.15, {TextColor3 = Color3.new(1, 1, 1)})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.15, {BackgroundTransparency = 0.5, BackgroundColor3 = Palette.BgInner})
            Tween(btn, 0.15, {TextColor3 = Palette.TextSecond})
        end)
        return btn
    end
    
    local minBtn = makeWinBtn("−", Palette.Yellow)
    local closeBtn = makeWinBtn("×", Palette.Accent)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(outer, 0.25, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.3)
        gui.Enabled = false
    end)
    
    -- Icon sidebar
    local iconBar = Create("Frame", {
        Name = "IconBar", BackgroundColor3 = Palette.BgOuter,
        BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, 50, 1, -44),
        ZIndex = 3, Parent = main
    })
    
    Create("Frame", {
        BackgroundColor3 = Palette.Border, BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0), ZIndex = 4, Parent = iconBar
    })
    
    local iconList = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -60),
        ZIndex = 4, Parent = iconBar
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6), Parent = iconList
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 14), Parent = iconList
    })
    
    local avatarBottom = Create("ImageLabel", {
        BackgroundColor3 = Palette.BgCard, BorderSizePixel = 0,
        Position = UDim2.new(0.5, -17, 1, -50),
        Size = UDim2.new(0, 34, 0, 34),
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
        ZIndex = 5, Parent = iconBar
    })
    Corner(avatarBottom, 7)
    Stroke(avatarBottom, Palette.Border, 1)
    
    -- Content area
    local contentArea = Create("Frame", {
        Name = "ContentArea", BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 44),
        Size = UDim2.new(1, -50, 1, -44),
        ZIndex = 3, Parent = main
    })
    
    local contentHolder = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 14),
        Size = UDim2.new(1, -28, 1, -28),
        ZIndex = 4, Parent = contentArea
    })
    
    -- User card
    local userCard = Create("Frame", {
        BackgroundColor3 = Palette.BgCard, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 72),
        ZIndex = 5, Parent = contentHolder
    })
    Corner(userCard, 8)
    Stroke(userCard, Palette.Border, 1)
    
    local userAccent = Create("Frame", {
        BackgroundColor3 = Palette.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 10),
        Size = UDim2.new(0, 3, 1, -20),
        ZIndex = 6, Parent = userCard
    })
    Corner(userAccent, 2)
    
    local avatarBig = Create("ImageLabel", {
        BackgroundColor3 = Palette.BgInner, BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0.5, -22),
        Size = UDim2.new(0, 44, 0, 44),
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
        ZIndex = 6, Parent = userCard
    })
    Corner(avatarBig, 6)
    Stroke(avatarBig, Palette.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 74, 0, 16),
        Size = UDim2.new(1, -86, 0, 20),
        Font = Fonts.Bold, Text = "Hello, " .. LocalPlayer.DisplayName .. "!",
        TextColor3 = Palette.TextPrimary, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6, Parent = userCard
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 74, 0, 38),
        Size = UDim2.new(1, -86, 0, 16),
        Font = Fonts.Light, Text = LocalPlayer.Name .. " - " .. title .. " " .. subtitle,
        TextColor3 = Palette.TextSecond, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6, Parent = userCard
    })
    
    local tabContent = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 84),
        Size = UDim2.new(1, 0, 1, -84),
        ZIndex = 5, Parent = contentHolder
    })
    
    local windowObj = setmetatable({
        Gui = gui, Outer = outer, Main = main,
        IconList = iconList, Content = tabContent,
        Tabs = {}, ActiveTab = nil,
    }, Window)
    
    MakeDraggable(outer, topBar)
    
    minBtn.MouseButton1Click:Connect(function()
        local minimized = outer.Size.Y.Offset == 44
        Tween(outer, 0.25, {
            Size = minimized and UDim2.new(0, 740, 0, 470) or UDim2.new(0, 740, 0, 44)
        }, Enum.EasingStyle.Quart)
        iconBar.Visible = minimized
        contentArea.Visible = minimized
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
        Name = name, Icon = icon, Window = self,
    }, {__index = Tab})
    
    local isImage = typeof(icon) == "string" and icon:sub(1, 11) == "rbxassetid:"
    
    local btn = Create("TextButton", {
        Name = name, BackgroundColor3 = Palette.BgCard,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(0, 34, 0, 34),
        Font = Fonts.Bold, Text = "",
        AutoButtonColor = false, ZIndex = 5, Parent = self.IconList
    })
    Corner(btn, 7)
    local strk = Stroke(btn, Palette.Border, 1, 1)
    
    if isImage then
        Create("ImageLabel", {
            Name = "Icon", BackgroundTransparency = 1,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0.5, -9, 0.5, -9),
            Image = icon,
            ImageColor3 = Palette.TextMuted,
            ZIndex = 6, Parent = btn
        })
    else
        Create("TextLabel", {
            Name = "Icon", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Fonts.Bold, Text = tostring(icon or "?"),
            TextColor3 = Palette.TextMuted, TextSize = 15,
            ZIndex = 6, Parent = btn
        })
    end
    
    tab.Button = btn
    tab.Stroke = strk
    
    local frame = Create("Frame", {
        Name = name .. "_Frame", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 5, Parent = self.Content
    })
    tab.Frame = frame
    
    local function getIcon() return btn:FindFirstChild("Icon") end
    
    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btn, 0.15, {BackgroundTransparency = 0.3, BackgroundColor3 = Palette.BgCard})
            Tween(getIcon(), 0.15, isImage and {ImageColor3 = Palette.TextPrimary} or {TextColor3 = Palette.TextPrimary})
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btn, 0.15, {BackgroundTransparency = 1})
            Tween(getIcon(), 0.15, isImage and {ImageColor3 = Palette.TextMuted} or {TextColor3 = Palette.TextMuted})
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
        Tween(t.Button, 0.2, {BackgroundTransparency = 1, BackgroundColor3 = Palette.BgCard})
        Tween(t.Stroke, 0.2, {Transparency = 1, Color = Palette.Border})
        local ic = t.Button:FindFirstChild("Icon")
        if ic then
            local isImg = ic:IsA("ImageLabel")
            Tween(ic, 0.2, isImg and {ImageColor3 = Palette.TextMuted} or {TextColor3 = Palette.TextMuted})
        end
    end
    
    self.ActiveTab = tab
    tab.Frame.Visible = true
    Tween(tab.Button, 0.2, {BackgroundTransparency = 0, BackgroundColor3 = Palette.Accent})
    Tween(tab.Stroke, 0.2, {Transparency = 1, Color = Palette.Accent})
    local ic = tab.Button:FindFirstChild("Icon")
    if ic then
        local isImg = ic:IsA("ImageLabel")
        Tween(ic, 0.2, isImg and {ImageColor3 = Color3.new(1, 1, 1)} or {TextColor3 = Color3.new(1, 1, 1)})
    end
end

-- ==================== TAB ====================
local Tab = {}
Tab.__index = Tab

function Tab:AddTwoColumnLayout()
    local container = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 5, Parent = self.Frame
    })
    
    -- Left column
    local leftCol = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 1, 0),
        ZIndex = 5, Parent = container
    })
    local leftLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10), Parent = leftCol
    })
    
    -- Right column
    local rightCol = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 1, 0),
        ZIndex = 5, Parent = container
    })
    local rightLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10), Parent = rightCol
    })
    
    return {
        Left = setmetatable({Frame = leftCol, Layout = leftLayout}, {__index = Column}),
        Right = setmetatable({Frame = rightCol, Layout = rightLayout}, {__index = Column}),
    }
end

function Tab:AddSection(name, subtitle)
    local section = setmetatable({
        Name = name, Subtitle = subtitle, Elements = {},
    }, {__index = Section})
    
    local wrapper = Create("Frame", {
        Name = name, BackgroundColor3 = Palette.BgCard,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 100),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 5, Parent = self.Frame
    })
    Corner(wrapper, 8)
    Stroke(wrapper, Palette.Border, 1)
    
    local accent = Create("Frame", {
        BackgroundColor3 = Palette.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 12),
        Size = UDim2.new(0, 3, 0, 22),
        ZIndex = 6, Parent = wrapper
    })
    Corner(accent, 2)
    
    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 56),
        ZIndex = 6, Parent = wrapper
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 12),
        Size = UDim2.new(1, -32, 0, 18),
        Font = Fonts.Bold, Text = name,
        TextColor3 = Palette.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7, Parent = header
    })
    
    if subtitle then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 30),
            Size = UDim2.new(1, -32, 0, 14),
            Font = Fonts.Light, Text = subtitle,
            TextColor3 = Palette.TextSecond, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7, Parent = header
        })
    end
    
    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 62),
        Size = UDim2.new(1, -24, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 6, Parent = wrapper
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6), Parent = content
    })
    Create("UIPadding", {
        PaddingBottom = UDim.new(0, 12), Parent = content
    })
    
    section.Frame = wrapper
    section.Content = content
    return section
end

-- ==================== COLUMN ====================
local Column = {}
Column.__index = Column

function Column:AddSection(name, subtitle)
    local section = setmetatable({
        Name = name, Subtitle = subtitle, Elements = {},
    }, {__index = Section})
    
    local wrapper = Create("Frame", {
        Name = name, BackgroundColor3 = Palette.BgCard,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 100),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 5, Parent = self.Frame
    })
    Corner(wrapper, 8)
    Stroke(wrapper, Palette.Border, 1)
    
    local accent = Create("Frame", {
        BackgroundColor3 = Palette.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 12),
        Size = UDim2.new(0, 3, 0, 22),
        ZIndex = 6, Parent = wrapper
    })
    Corner(accent, 2)
    
    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 56),
        ZIndex = 6, Parent = wrapper
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 12),
        Size = UDim2.new(1, -32, 0, 18),
        Font = Fonts.Bold, Text = name,
        TextColor3 = Palette.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7, Parent = header
    })
    
    if subtitle then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 30),
            Size = UDim2.new(1, -32, 0, 14),
            Font = Fonts.Light, Text = subtitle,
            TextColor3 = Palette.TextSecond, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7, Parent = header
        })
    end
    
    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 62),
        Size = UDim2.new(1, -24, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 6, Parent = wrapper
    })
    
    -- GRID layout - 2 cards per row
    local grid = Create("UIGridLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellSize = UDim2.new(0.5, -3, 0, 50),
        CellPadding = UDim2.new(0, 6, 0, 6),
        Parent = content
    })
    Create("UIPadding", {
        PaddingBottom = UDim.new(0, 8), Parent = content
    })
    
    section.Frame = wrapper
    section.Content = content
    section.Grid = grid
    section.IsGrid = true
    return section
end

-- ==================== SECTION ====================
local Section = {}
Section.__index = Section

function Section:AddCard(text, opts)
    opts = opts or {}
    local subtext = opts.Subtext or ""
    local callback = opts.Callback or function() end
    local bg = opts.Color or Palette.BgCardInner
    
    local card = Create("TextButton", {
        BackgroundColor3 = bg, BorderSizePixel = 0,
        Size = self.IsGrid and UDim2.new(1, 0, 1, 0) or UDim2.new(1, 0, 0, 46),
        Text = "", AutoButtonColor = false,
        ZIndex = 7, Parent = self.Content
    })
    Corner(card, 6)
    Stroke(card, Palette.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -16, 0, 16),
        Font = Fonts.Bold, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 8, Parent = card
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 24),
        Size = UDim2.new(1, -16, 0, 18),
        Font = Fonts.Light, Text = subtext,
        TextColor3 = Palette.TextSecond, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 8, Parent = card
    })
    
    card.MouseEnter:Connect(function()
        Tween(card, 0.15, {BackgroundColor3 = Palette.BgButtonHov})
    end)
    card.MouseLeave:Connect(function()
        Tween(card, 0.15, {BackgroundColor3 = bg})
    end)
    card.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
    
    return card
end

function Section:AddBigButton(text, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local bg = opts.Color or Palette.BgBlue
    local subtext = opts.Subtext
    
    local h = subtext and 60 or 48
    
    local btn = Create("TextButton", {
        BackgroundColor3 = bg, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, h),
        Text = "", AutoButtonColor = false,
        ZIndex = 7, Parent = self.Content
    })
    Corner(btn, 6)
    Stroke(btn, Palette.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, subtext and 10 or 0),
        Size = UDim2.new(1, -20, 0, subtext and 20 or h),
        Font = Fonts.Bold, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = btn
    })
    
    if subtext then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 30),
            Size = UDim2.new(1, -20, 0, 16),
            Font = Fonts.Light, Text = subtext,
            TextColor3 = Palette.TextPrimary, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = btn
        })
    end
    
    btn.MouseEnter:Connect(function()
        local c = bg
        Tween(btn, 0.15, {BackgroundColor3 = Color3.new(
            math.min(c.R + 0.08, 1), math.min(c.G + 0.08, 1), math.min(c.B + 0.08, 1)
        )})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.15, {BackgroundColor3 = bg})
    end)
    btn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
    
    return btn
end

function Section:AddLabel(text)
    return Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
        Font = Fonts.Light, Text = text,
        TextColor3 = Palette.TextSecond, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7, Parent = self.Content
    })
end

function Section:AddButton(text, opts)
    opts = opts or {}
    local callback = type(opts) == "function" and opts or (opts.Callback or function() end)
    
    local btn = Create("TextButton", {
        BackgroundColor3 = Palette.BgCardInner, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Fonts.Bold, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 12,
        AutoButtonColor = false, ZIndex = 7, Parent = self.Content
    })
    Corner(btn, 6)
    local strk = Stroke(btn, Palette.Border, 1)
    
    btn.MouseEnter:Connect(function()
        Tween(btn, 0.15, {BackgroundColor3 = Palette.BgButtonHov})
        Tween(strk, 0.15, {Color = Palette.BorderLight})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.15, {BackgroundColor3 = Palette.BgCardInner})
        Tween(strk, 0.15, {Color = Palette.Border})
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
    
    local h = desc and 54 or 40
    
    local container = Create("Frame", {
        BackgroundColor3 = Palette.BgCardInner, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, h),
        ZIndex = 7, Parent = self.Content
    })
    Corner(container, 6)
    local strk = Stroke(container, Palette.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, desc and 8 or 0),
        Size = UDim2.new(1, -80, 0, desc and 20 or h),
        Font = Fonts.Bold, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    if desc then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 28),
            Size = UDim2.new(1, -80, 0, 16),
            Font = Fonts.Light, Text = desc,
            TextColor3 = Palette.TextSecond, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = container
        })
    end
    
    local track = Create("Frame", {
        BackgroundColor3 = state and Palette.Accent or Palette.BgButton,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -50, 0.5, -10),
        Size = UDim2.new(0, 36, 0, 20),
        ZIndex = 8, Parent = container
    })
    Corner(track, 10)
    
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16), ZIndex = 9, Parent = track
    })
    Corner(thumb, 8)
    
    local obj = {Id = id, State = state}
    
    local function setState(v, fire)
        state = v
        Tween(track, 0.2, {BackgroundColor3 = state and Palette.Accent or Palette.BgButton})
        Tween(thumb, 0.2, {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }, Enum.EasingStyle.Back)
        obj.State = state
        if fire then task.spawn(callback, state) end
    end
    
    local click = Create("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Text = "", ZIndex = 9, Parent = container
    })
    click.MouseButton1Click:Connect(function() setState(not state, true) end)
    
    click.MouseEnter:Connect(function()
        Tween(container, 0.15, {BackgroundColor3 = Palette.BgButtonHov})
    end)
    click.MouseLeave:Connect(function()
        Tween(container, 0.15, {BackgroundColor3 = Palette.BgCardInner})
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
        BackgroundColor3 = Palette.BgCardInner, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        ZIndex = 7, Parent = self.Content
    })
    Corner(container, 6)
    Stroke(container, Palette.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -90, 0, 16),
        Font = Fonts.Bold, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 8),
        Size = UDim2.new(0, 58, 0, 16),
        Font = Fonts.Bold, Text = tostring(value) .. suffix,
        TextColor3 = Palette.Accent, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 8, Parent = container
    })
    
    local barBg = Create("Frame", {
        BackgroundColor3 = Palette.BgButton, BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 36),
        Size = UDim2.new(1, -24, 0, 4),
        ZIndex = 8, Parent = container
    })
    Corner(barBg, 2)
    
    local fill = Create("Frame", {
        BackgroundColor3 = Palette.Accent, BorderSizePixel = 0,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        ZIndex = 9, Parent = barBg
    })
    Corner(fill, 2)
    
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12), ZIndex = 10, Parent = barBg
    })
    Corner(thumb, 6)
    Stroke(thumb, Palette.Accent, 1.5)
    
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
        BackgroundColor3 = Palette.BgCardInner, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ClipsDescendants = false, ZIndex = 7, Parent = self.Content
    })
    Corner(container, 6)
    Stroke(container, Palette.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -110, 1, 0),
        Font = Fonts.Bold, Text = text,
        TextColor3 = Palette.TextPrimary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8, Parent = container
    })
    
    local currentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -100, 0, 0),
        Size = UDim2.new(0, 70, 1, 0),
        Font = Fonts.Regular, Text = tostring(current),
        TextColor3 = Palette.Accent, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 8, Parent = container
    })
    
    local arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -22, 0, 0),
        Size = UDim2.new(0, 14, 1, 0),
        Font = Fonts.Bold, Text = "▾",
        TextColor3 = Palette.TextMuted, TextSize = 12,
        ZIndex = 8, Parent = container
    })
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Text = "", ZIndex = 8, Parent = container
    })
    
    local list = Create("ScrollingFrame", {
        BackgroundColor3 = Palette.BgOuter, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Palette.Accent,
        Visible = false, ZIndex = 100, Parent = container
    })
    Corner(list, 6)
    Stroke(list, Palette.BorderLight, 1)
    local layout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2), Parent = list
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4), Parent = list
    })
    
    local optionButtons = {}
    local function refresh()
        for _, b in ipairs(optionButtons) do b:Destroy() end
        optionButtons = {}
        for _, val in ipairs(values) do
            local opt = Create("TextButton", {
                BackgroundColor3 = Palette.BgCardInner, BackgroundTransparency = 1,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 26),
                Font = Fonts.Light, Text = tostring(val),
                TextColor3 = Palette.TextPrimary, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, ZIndex = 101, Parent = list
            })
            Corner(opt, 4)
            Create("UIPadding", {PaddingLeft = UDim.new(0, 8), Parent = opt})
            opt.MouseEnter:Connect(function()
                Tween(opt, 0.12, {BackgroundTransparency = 0, BackgroundColor3 = Palette.Accent})
            end)
            opt.MouseLeave:Connect(function()
                Tween(opt, 0.12, {BackgroundTransparency = 1})
            end)
            opt.MouseButton1Click:Connect(function()
                current = val
                currentLabel.Text = tostring(val)
                open = false
                Tween(list, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
                Tween(arrow, 0.15, {Rotation = 0})
                task.wait(0.15)
                list.Visible = false
                callback(val)
            end)
            table.insert(optionButtons, opt)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)
    end
    refresh()
    
    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            list.Visible = true
            local tgt = math.min(#values * 28 + 10, 160)
            Tween(list, 0.2, {Size = UDim2.new(1, 0, 0, tgt)})
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
        Refresh = function(nv) values = nv; refresh() end
    }
end

-- ==================== INIT ====================
VexUI.Theme = Palette

return VexUI
