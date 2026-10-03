--[[
    VexUI - Custom UI Library
    Usage: local Library = loadstring(game:HttpGet("YOUR_RAW_URL"))()
    
    local Window = Library:CreateWindow({Title = "My Script"})
    local Tab = Window:AddTab("Main")
    local Box = Tab:AddLeftGroupbox("Combat")
    Box:AddToggle("MyToggle", {Text = "Enable", Default = false, Callback = function(v) print(v) end})
]]

local VexUI = {}
VexUI.__index = VexUI

-- ============ SERVICES ============
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ THEME ============
local Theme = {
    Background = Color3.fromRGB(12, 12, 15),
    Secondary = Color3.fromRGB(18, 18, 22),
    Tertiary = Color3.fromRGB(25, 25, 30),
    Border = Color3.fromRGB(40, 40, 48),
    Text = Color3.fromRGB(235, 235, 240),
    SubText = Color3.fromRGB(140, 140, 155),
    Accent = Color3.fromRGB(200, 30, 40),
    AccentDark = Color3.fromRGB(140, 20, 28),
    ToggleOn = Color3.fromRGB(200, 30, 40),
    ToggleOff = Color3.fromRGB(55, 55, 65),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    TextSize = 14,
    CornerRadius = 6,
}

-- ============ UTILITIES ============
local function Create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

local function Corner(inst, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or Theme.CornerRadius),
        Parent = inst
    })
end

local function Stroke(inst, color, thickness)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst
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

local function MakeDraggable(frame, dragArea)
    dragArea = dragArea or frame
    local dragging, dragStart, startPos
    
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
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
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
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

-- ============ NOTIFICATIONS ============
local NotifContainer

local function EnsureNotifContainer()
    if NotifContainer and NotifContainer.Parent then return NotifContainer end
    local gui = CoreGui:FindFirstChild("VexUI_Notifs")
    if not gui then
        gui = Create("ScreenGui", {
            Name = "VexUI_Notifs",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = CoreGui
        })
    end
    NotifContainer = Create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 300, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        Parent = gui
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = NotifContainer
    })
    return NotifContainer
end

function VexUI:Notify(opts)
    local container = EnsureNotifContainer()
    local title = opts.Title or "Notification"
    local text = opts.Description or opts.Text or ""
    local duration = opts.Time or 4
    
    local notif = Create("Frame", {
        Name = "Notif",
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(1, 320, 0, 0),
        Parent = container
    })
    Corner(notif, 6)
    Stroke(notif, Theme.Border, 1)
    
    -- Accent bar
    local accent = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        Parent = notif
    })
    Corner(accent, 3)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -20, 0, 18),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 26),
        Size = UDim2.new(1, -20, 1, -30),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notif
    })
    
    Tween(notif, 0.25, {Position = UDim2.new(0, 0, 0, 0)})
    
    task.delay(duration, function()
        Tween(notif, 0.25, {Position = UDim2.new(1, 320, 0, 0)})
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- ============ WINDOW ============
local Window = {}
Window.__index = Window

function VexUI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "VexUI"
    local subtitle = opts.Subtitle or ""
    
    local gui = CoreGui:FindFirstChild("VexUI") or Create("ScreenGui", {
        Name = "VexUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui
    })
    
    -- Main Frame
    local main = Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 580, 0, 380),
        Position = UDim2.new(0.5, -290, 0.5, -190),
        Parent = gui
    })
    Corner(main, 8)
    Stroke(main, Theme.Border, 1)
    
    -- Top bar
    local topBar = Create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = main
    })
    Corner(topBar, 8)
    -- square off bottom corners
    Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        Parent = topBar
    })
    
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = topBar
    })
    
    -- Accent dot
    local dot = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0.5, -5),
        Size = UDim2.new(0, 10, 0, 10),
        Parent = topBar
    })
    Corner(dot, 5)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(0, 200, 0, 40),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar
    })
    
    -- Close button
    local closeBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -36, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Font = Theme.FontBold,
        Text = "×",
        TextColor3 = Theme.SubText,
        TextSize = 22,
        Parent = topBar
    })
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, 0.15, {TextColor3 = Theme.Accent})
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, 0.15, {TextColor3 = Theme.SubText})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)
    
    -- Minimize button
    local minBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -66, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Font = Theme.FontBold,
        Text = "−",
        TextColor3 = Theme.SubText,
        TextSize = 22,
        Parent = topBar
    })
    minBtn.MouseEnter:Connect(function()
        Tween(minBtn, 0.15, {TextColor3 = Theme.Accent})
    end)
    minBtn.MouseLeave:Connect(function()
        Tween(minBtn, 0.15, {TextColor3 = Theme.SubText})
    end)
    
    -- Tab bar (left side)
    local tabBar = Create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 140, 1, -40),
        Parent = main
    })
    
    -- Right side square corners
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = tabBar
    })
    
    local tabList = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = tabBar
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = tabList
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = tabList
    })
    
    -- Content area
    local content = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 140, 0, 40),
        Size = UDim2.new(1, -140, 1, -40),
        Parent = main
    })
    
    MakeDraggable(main, topBar)
    
    local windowObj = setmetatable({
        Gui = gui,
        Main = main,
        TabBar = tabList,
        Content = content,
        Tabs = {},
        ActiveTab = nil,
        ToggleKeybind = opts.ToggleKeybind or Enum.KeyCode.RightControl,
        Minimized = false,
    }, Window)
    
    -- Toggle keybind
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == windowObj.ToggleKeybind then
            main.Visible = not main.Visible
        end
    end)
    
    minBtn.MouseButton1Click:Connect(function()
        windowObj.Minimized = not windowObj.Minimized
        -- simple minimize: hide content
        content.Visible = not windowObj.Minimized
        tabBar.Visible = not windowObj.Minimized
        Tween(main, 0.2, {
            Size = windowObj.Minimized and UDim2.new(0, 580, 0, 40) or UDim2.new(0, 580, 0, 380)
        })
    end)
    
    return windowObj
end

function Window:AddTab(name, icon)
    local tab = setmetatable({
        Name = name,
        Window = self,
        Groupboxes = {},
        Buttons = {},
    }, {__index = Tab})
    
    local btn = Create("TextButton", {
        Name = name,
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Font = Theme.Font,
        Text = "  " .. name,
        TextColor3 = Theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TabBar
    })
    Corner(btn, 6)
    
    local contentFrame = Create("Frame", {
        Name = name .. "_Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        Parent = self.Content
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = contentFrame
    })
    
    tab.Button = btn
    tab.Frame = contentFrame
    
    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btn, 0.15, {BackgroundTransparency = 0.5, TextColor3 = Theme.Text})
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btn, 0.15, {BackgroundTransparency = 1, TextColor3 = Theme.SubText})
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Auto select first
    if not self.ActiveTab then
        self:SelectTab(tab)
    end
    
    return tab
end

function Window:SelectTab(tab)
    if self.ActiveTab == tab then return end
    
    for _, t in ipairs(self.Tabs) do
        t.Frame.Visible = false
        Tween(t.Button, 0.15, {
            BackgroundColor3 = Theme.Tertiary,
            BackgroundTransparency = 1,
            TextColor3 = Theme.SubText
        })
    end
    
    self.ActiveTab = tab
    tab.Frame.Visible = true
    Tween(tab.Button, 0.15, {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.85,
        TextColor3 = Theme.Text
    })
end

-- ============ TAB ============
local Tab = {}
Tab.__index = Tab

function Tab:AddLeftGroupbox(name)
    return self:_AddGroupbox(name, UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
end

function Tab:AddRightGroupbox(name)
    return self:_AddGroupbox(name, UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
end

function Tab:_AddGroupbox(name, pos, size)
    local box = setmetatable({
        Name = name,
        Elements = {},
        Tab = self,
    }, {__index = Groupbox})
    
    local frame = Create("Frame", {
        Name = name,
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = pos,
        Size = size,
        Parent = self.Frame
    })
    Corner(frame, 6)
    Stroke(frame, Theme.Border, 1)
    
    -- Title
    local titleFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        Parent = frame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Theme.FontBold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleFrame
    })
    
    -- Divider
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 26),
        Size = UDim2.new(1, -20, 0, 1),
        Parent = frame
    })
    
    -- Scrollable content
    local scroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 1, -36),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = frame
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = scroll
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 8),
        Parent = scroll
    })
    
    local layout = scroll:FindFirstChildOfClass("UIListLayout")
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)
    
    box.Frame = frame
    box.Scroll = scroll
    return box
end

-- ============ GROUPBOX ============
local Groupbox = {}
Groupbox.__index = Groupbox

function Groupbox:AddDivider()
    local div = Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self.Scroll
    })
    return div
end

function Groupbox:AddLabel(text)
    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Scroll
    })
    return label
end

function Groupbox:AddButton(name, opts)
    opts = opts or {}
    local callback = type(opts) == "function" and opts or (opts.Callback or function() end)
    
    local btn = Create("TextButton", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Font = Theme.Font,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = self.Scroll
    })
    Corner(btn, 5)
    local strk = Stroke(btn, Theme.Border, 1)
    
    btn.MouseEnter:Connect(function()
        Tween(btn, 0.15, {BackgroundColor3 = Theme.Accent})
        Tween(strk, 0.15, {Color = Theme.Accent})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.15, {BackgroundColor3 = Theme.Tertiary})
        Tween(strk, 0.15, {Color = Theme.Border})
    end)
    btn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
    
    return btn
end

function Groupbox:AddToggle(id, opts)
    opts = opts or {}
    local default = opts.Default or false
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local state = default
    
    local container = Create("Frame", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self.Scroll
    })
    Corner(container, 5)
    Stroke(container, Theme.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    -- Toggle track
    local track = Create("Frame", {
        BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -46, 0.5, -10),
        Size = UDim2.new(0, 36, 0, 20),
        Parent = container
    })
    Corner(track, 10)
    
    -- Toggle thumb
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Parent = track
    })
    Corner(thumb, 8)
    
    local toggleObj = {}
    
    local function setState(newState, fireCallback)
        state = newState
        Tween(track, 0.15, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
        Tween(thumb, 0.15, {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        })
        if fireCallback then
            task.spawn(callback, state)
        end
    end
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = container
    })
    
    btn.MouseButton1Click:Connect(function()
        setState(not state, true)
    end)
    
    toggleObj.Container = container
    toggleObj.Set = function(v) setState(v, true) end
    toggleObj.Get = function() return state end
    
    -- Store for save/load
    toggleObj.Id = id
    return toggleObj
end

function Groupbox:AddSlider(id, opts)
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
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 46),
        Parent = self.Scroll
    })
    Corner(container, 5)
    Stroke(container, Theme.Border, 1)
    
    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 4),
        Size = UDim2.new(1, -60, 0, 18),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, 4),
        Size = UDim2.new(0, 50, 0, 18),
        Font = Theme.FontBold,
        Text = tostring(value) .. suffix,
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })
    
    -- Track
    local barBg = Create("Frame", {
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 6),
        Parent = container
    })
    Corner(barBg, 3)
    
    local fill = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        Parent = barBg
    })
    Corner(fill, 3)
    
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 2,
        Parent = barBg
    })
    Corner(thumb, 6)
    
    local slider = {}
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    slider.Set = function(v)
        v = math.clamp(v, min, max)
        value = v
        local relX = (v - min) / (max - min)
        Tween(fill, 0.1, {Size = UDim2.new(relX, 0, 1, 0)})
        Tween(thumb, 0.1, {Position = UDim2.new(relX, 0, 0.5, 0)})
        valueLabel.Text = tostring(value) .. suffix
        callback(value)
    end
    slider.Get = function() return value end
    
    return slider
end

function Groupbox:AddDropdown(id, opts)
    opts = opts or {}
    local values = opts.Values or {}
    local default = opts.Default or (values[1] or "")
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local current = default
    local open = false
    
    local container = Create("Frame", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self.Scroll
    })
    Corner(container, 5)
    Stroke(container, Theme.Border, 1)
    container.ClipsDescendants = false
    
    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local currentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -90, 0, 0),
        Size = UDim2.new(0, 70, 1, 0),
        Font = Theme.Font,
        Text = tostring(current),
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })
    
    local arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 0, 0),
        Size = UDim2.new(0, 12, 1, 0),
        Font = Theme.FontBold,
        Text = "▾",
        TextColor3 = Theme.SubText,
        TextSize = 12,
        Parent = container
    })
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = container
    })
    
    -- Dropdown list
    local list = Create("ScrollingFrame", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        Visible = false,
        ZIndex = 5,
        Parent = container
    })
    Corner(list, 5)
    Stroke(list, Theme.Border, 1)
    local layout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = list
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = list
    })
    
    local buttons = {}
    local function refresh()
        for _, b in pairs(buttons) do b:Destroy() end
        buttons = {}
        for _, val in ipairs(values) do
            local option = Create("TextButton", {
                BackgroundColor3 = Theme.Secondary,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                Font = Theme.Font,
                Text = tostring(val),
                TextColor3 = Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = list
            })
            Create("UIPadding", {PaddingLeft = UDim.new(0, 6), Parent = option})
            Corner(option, 4)
            option.MouseEnter:Connect(function()
                Tween(option, 0.1, {BackgroundTransparency = 0.6, BackgroundColor3 = Theme.Accent})
            end)
            option.MouseLeave:Connect(function()
                Tween(option, 0.1, {BackgroundTransparency = 1})
            end)
            option.MouseButton1Click:Connect(function()
                current = val
                currentLabel.Text = tostring(val)
                open = false
                Tween(list, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
                task.wait(0.15)
                list.Visible = false
                callback(val)
            end)
            table.insert(buttons, option)
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
            local targetSize = math.min(#values * 26 + 8, 150)
            Tween(list, 0.15, {Size = UDim2.new(1, 0, 0, targetSize)})
        else
            Tween(list, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
            task.wait(0.15)
            list.Visible = false
        end
    end)
    
    local dd = {}
    dd.Set = function(v)
        current = v
        currentLabel.Text = tostring(v)
        callback(v)
    end
    dd.Get = function() return current end
    dd.Refresh = function(newValues)
        values = newValues
        refresh()
    end
    
    return dd
end

function Groupbox:AddTextbox(id, opts)
    opts = opts or {}
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local placeholder = opts.Placeholder or ""
    local default = opts.Default or ""
    
    local container = Create("Frame", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self.Scroll
    })
    Corner(container, 5)
    Stroke(container, Theme.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -20, 0, 14),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local box = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 14),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Theme.Font,
        Text = default,
        PlaceholderText = placeholder,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = container
    })
    
    box.FocusLost:Connect(function()
        callback(box.Text)
    end)
    
    return box
end

function Groupbox:AddColorPicker(id, opts)
    opts = opts or {}
    local default = opts.Default or Color3.fromRGB(255, 255, 255)
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local color = default
    
    local container = Create("Frame", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self.Scroll
    })
    Corner(container, 5)
    Stroke(container, Theme.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local swatch = Create("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -40, 0.5, -10),
        Size = UDim2.new(0, 28, 0, 20),
        Parent = container
    })
    Corner(swatch, 4)
    Stroke(swatch, Theme.Border, 1)
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = container
    })
    
    btn.MouseButton1Click:Connect(function()
        -- Simple: cycle through rainbow for demo, or use a real picker
        -- For real picker, you'd make a popup with HSV sliders
        -- Simplified: cycle hue
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

function Groupbox:AddKeyPicker(id, opts)
    opts = opts or {}
    local default = opts.Default or "F"
    local callback = opts.Callback or function() end
    local text = opts.Text or id
    local mode = opts.Mode or "Toggle"
    local current = default
    local listening = false
    
    local container = Create("Frame", {
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self.Scroll
    })
    Corner(container, 5)
    Stroke(container, Theme.Border, 1)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local keyLabel = Create("TextButton", {
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -70, 0.5, -10),
        Size = UDim2.new(0, 58, 0, 20),
        Font = Theme.FontBold,
        Text = current,
        TextColor3 = Theme.Text,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = container
    })
    Corner(keyLabel, 4)
    Stroke(keyLabel, Theme.Border, 1)
    
    keyLabel.MouseButton1Click:Connect(function()
        listening = true
        keyLabel.Text = "..."
    end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode.Name
                keyLabel.Text = current
                listening = false
            end
        else
            if input.KeyCode.Name == current then
                callback()
            end
        end
    end)
    
    return {
        Set = function(k) current = k; keyLabel.Text = k end,
        Get = function() return current end
    }
end

-- ============ INIT ============
VexUI.Theme = Theme

return VexUI
