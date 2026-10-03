local Library = loadstring(game:HttpGet("URL"))()
local Window = Library:CreateWindow({
    Title = "Vex",
    Subtitle = ".gg/vex"
})

local HomeTab = Window:AddTab("Home", "rbxassetid://YOUR_HOME_ICON")
local CombatTab = Window:AddTab("Combat", "rbxassetid://YOUR_SWORD_ICON")
local VisualsTab = Window:AddTab("Visuals", "rbxassetid://YOUR_EYE_ICON")
local SettingsTab = Window:AddTab("Settings", "rbxassetid://YOUR_GEAR_ICON")

-- ===== HOME PAGE (2-Spalten) =====
local layout = HomeTab:AddTwoColumnLayout()

-- Linke Spalte
local serverSec = layout.Left:AddSection("Server", "Information on the session you're currently in")
serverSec:AddCard("Players", {
    Subtext = #game.Players:GetPlayers() .. " playing",
    Callback = function() Library:Notify({Title = "Players", Description = "Copy list", Time = 3}) end
})
serverSec:AddCard("Maximum Players", {Subtext = game.Players.MaxPlayers .. " players can join"})
serverSec:AddCard("Latency", {Subtext = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms"})
serverSec:AddCard("Server Region", {Subtext = "US"})
serverSec:AddCard("In server for", {
    Subtext = "00:00:20",
    Color = Palette.BgGreen
})
serverSec:AddCard("Join Script", {
    Subtext = "Tap to copy join script",
    Callback = function()
        setclipboard("game:GetService('TeleportService'):TeleportToPlaceInstance(" .. game.PlaceId .. ", '" .. game.JobId .. "')")
        Library:Notify({Title = "Copied", Description = "Join script copied!", Time = 2})
    end
})

local discordSec = layout.Left:AddSection("Discord", "")
discordSec:AddBigButton("Discord", {
    Subtext = "Tap to join the Discord Server",
    Color = Palette.BgBlue,
    Callback = function()
        setclipboard("https://discord.gg/vex")
        Library:Notify({Title = "Discord", Description = "Link copied!", Time = 3})
    end
})

-- Rechte Spalte
local waveSec = layout.Right:AddSection("Wave", "Your executor seems to support this script")
waveSec:AddCard("Supported", {
    Subtext = "All features available",
    Color = Palette.BgGreen
})

local friendsSec = layout.Right:AddSection("Friends", "Find out what your friends are currently doing")
friendsSec:AddCard("In Server", {Subtext = "no friends", Color = Palette.BgGreen})
friendsSec:AddCard("Offline", {Subtext = "28 friends", Color = Palette.BgYellow})
friendsSec:AddCard("Online", {Subtext = "2 friends", Color = Palette.BgGreen})
friendsSec:AddCard("All", {Subtext = "100 friends"})
