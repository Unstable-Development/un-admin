Config = {}

-- ==============================================
-- UI CUSTOMIZATION
-- ==============================================

-- Server Name (appears on top of admin panel)
Config.ServerName = 'unstable'

-- UI Theme Color
-- Options: 'purple', 'blue', 'green', 'red', 'orange', 'yellow'
Config.UITheme = 'blue'

-- Theme Color Definitions (HEX colors)
Config.ThemeColors = {
    purple = {
        primary = '#b604da',
        primaryDark = '#8a0398',
        primaryLight = '#d633ff',
        accent = '#9b59b6'
    },
    blue = {
        primary = '#0a84ff',
        primaryDark = '#0066cc',
        primaryLight = '#3a9eff',
        accent = '#3498db'
    },
    green = {
        primary = '#30d158',
        primaryDark = '#28a745',
        primaryLight = '#5ae37d',
        accent = '#2ecc71'
    },
    red = {
        primary = '#ff453a',
        primaryDark = '#dc3545',
        primaryLight = '#ff6b62',
        accent = '#e74c3c'
    },
    orange = {
        primary = '#ff9f0a',
        primaryDark = '#e67e00',
        primaryLight = '#ffb340',
        accent = '#f39c12'
    },
    yellow = {
        primary = '#ffd60a',
        primaryDark = '#e6c200',
        primaryLight = '#ffe140',
        accent = '#f1c40f'
    }
}

-- ==============================================
-- KEYBINDS & COMMANDS
-- ==============================================

-- Command to open admin menu
Config.Command = 'pa'

-- Keybind to open menu (optional, set to nil to disable)
Config.OpenKey = 'PAGEDOWN'

-- Keybind to toggle noclip (optional, set to nil to disable)
Config.NoclipKey = 'F2'

-- Keybind to toggle airwalk mode (optional, set to nil to disable)
Config.AirwalkKey = 'J'

-- Permission Levels
Config.Permissions = {
    ['qbcore.god'] = 'god',
    ['qbcore.admin'] = 'admin',
    ['qbcore.mod'] = 'mod'
}

-- Discord Webhook for logging admin actions
Config.Webhook = '' -- Add your Discord webhook URL here

-- ==============================================
-- REPORT SYSTEM
-- ==============================================

-- Report System Configuration
Config.ReportSystem = {
    enabled = true,
    command = 'report', -- Command players use to open report UI
    webhook = '', -- Discord webhook for reports (leave empty to disable)
    embedColor = 15158332, -- Red color for Discord embeds (decimal)
    minReportLength = 10, -- Minimum characters for a report
    maxReportLength = 500, -- Maximum characters for a report
    cooldown = 60, -- Cooldown in seconds between reports per player
    notifyAdmins = true, -- Send notification to online admins when report received
    autoClose = false, -- Automatically close reports after set time
    autoCloseTime = 3600, -- Time in seconds before auto-closing (1 hour)
}

-- Feature Access by Permission Level
Config.FeatureAccess = {
    ['god'] = {
        dashboard = true,
        players = true,
        items = true,
        vehicles = true,
        server = true,
        developer = true,
        jobs = true,
        economy = true,
        logs = true,
        resources = true,
        reports = true
    },
    ['admin'] = {
        dashboard = true,
        players = true,
        items = true,
        vehicles = true,
        server = true,
        developer = false,
        jobs = true,
        economy = true,
        logs = true,
        resources = false,
        reports = true
    },
    ['mod'] = {
        dashboard = true,
        players = true,
        items = false,
        vehicles = true,
        server = false,
        developer = false,
        jobs = false,
        economy = false,
        logs = false,
        resources = false,
        reports = true
    }
}

-- Saved Teleport Locations
Config.TeleportLocations = {
    {name = 'Police Department', coords = vector3(428.9, -984.5, 30.7)},
    {name = 'Pillbox Hospital', coords = vector3(304.1, -600.5, 43.3)},
    {name = 'Legion Square', coords = vector3(215.9, -810.1, 30.7)},
    {name = 'Paleto Bay', coords = vector3(-104.5, 6328.5, 31.5)},
    {name = 'Sandy Shores', coords = vector3(1836.0, 3686.5, 34.2)},
    {name = 'Los Santos Airport', coords = vector3(-1034.6, -2733.6, 13.8)},
    {name = 'Mount Chiliad', coords = vector3(501.5, 5604.1, 797.9)},
    {name = 'Del Perro Pier', coords = vector3(-1850.3, -1248.0, 8.6)},
}

-- Vehicle Categories
Config.VehicleCategories = {
    'Super',
    'Sports',
    'Sports Classics',
    'Sedans',
    'SUVs',
    'Off-Road',
    'Motorcycles',
    'Emergency',
    'Service',
    'Industrial',
    'Boats',
    'Helicopters',
    'Planes'
}

-- Weather Types
Config.WeatherTypes = {
    'EXTRASUNNY',
    'CLEAR',
    'NEUTRAL',
    'SMOG',
    'FOGGY',
    'OVERCAST',
    'CLOUDS',
    'CLEARING',
    'RAIN',
    'THUNDER',
    'SNOW',
    'BLIZZARD',
    'SNOWLIGHT',
    'XMAS',
    'HALLOWEEN'
}

-- Quick Action Buttons (Dashboard)
Config.QuickActions = {
    {label = 'Fix Vehicle', action = 'fixVehicle', icon = 'wrench'},
    {label = 'Refuel Vehicle', action = 'refuelVehicle', icon = 'gas-pump'},
    {label = 'Heal Self', action = 'healSelf', icon = 'heart'},
    {label = 'Noclip', action = 'toggleNoclip', icon = 'ghost'},
    {label = 'TP Waypoint', action = 'tpWaypoint', icon = 'map-marker'},
    {label = 'God Mode', action = 'toggleGodmode', icon = 'shield'},
    {label = 'Invisible', action = 'toggleInvisible', icon = 'eye-slash'},
    {label = 'Clear Area', action = 'clearArea', icon = 'broom'}
}

-- ==============================================
-- INVENTORY & FUEL SYSTEM AUTO-DETECTION
-- ==============================================

-- Inventory System (Auto-detects if set to 'auto')
Config.Inventory = {
    system = 'auto', -- 'auto', 'qb-inventory', 'codem-inventory', 'ox_inventory', 'qs-inventory', 'ps-inventory'
    
    -- Detection priority (first started resource wins)
    priority = {
        'codem-inventory',     -- CodeM inventory (fastest)
        'ox_inventory',        -- Overextended inventory
        'ak47_qb_inventory',   -- AK47 QBCore inventory
        'qs-inventory',        -- Quasar inventory
        'ps-inventory',        -- Project Sloth inventory
        'tgiann-inventory',    -- TGiann inventory
        'origen_inventory',    -- Origen inventory
        'core_inventory',      -- Core inventory
        'mf-inventory',        -- MF inventory
        'linden_inventory',    -- Linden inventory
        'qb-inventory',        -- QBCore default (fallback)
    },
    
    -- Image paths for each system (auto-configured)
    imagePaths = {
        ['qb-inventory']       = 'nui://qb-inventory/html/images/%s',
        ['ak47_qb_inventory']  = 'nui://ak47_qb_inventory/html/images/%s',
        ['codem-inventory']    = 'nui://codem-inventory/html/itemimages/%s',
        ['ox_inventory']       = 'nui://ox_inventory/web/images/%s',
        ['qs-inventory']       = 'nui://qs-inventory/html/img/%s',
        ['ps-inventory']       = 'nui://ps-inventory/html/images/%s',
        ['tgiann-inventory']   = 'nui://tgiann-inventory/web/dist/images/%s',
        ['origen_inventory']   = 'nui://origen_inventory/html/images/%s',
        ['core_inventory']     = 'nui://core_inventory/html/images/%s',
        ['mf-inventory']       = 'nui://mf-inventory/html/images/%s',
        ['linden_inventory']   = 'nui://linden_inventory/html/images/%s',
    }
}

-- Fuel System (Auto-detects if set to 'auto')
Config.Fuel = {
    enabled = true,
    -- 'auto' will detect the first running fuel resource
    -- Supported: 'ox_fuel', 'Renewed-Fuel', 'LegacyFuel', 'rcore_fuel', 'lj-fuel',
    --            'cdn-fuel', 'ps-fuel', 'qb-fuel', 'okokGasStation', 'ti_fuel',
    --            'K4MB1_Fuel', 't1ger_fuel', 'myFuel', 'qs-fuelstations',
    --            'sadoj-fuel', 'gacha_fuel', 'cd_fuel'
    system = 'auto',
    
    -- Detection priority (first started resource wins)
    -- Reorder as needed for your server
    priority = {
        'rcore_fuel',       -- RCore fuel (most reliable)
        'Renewed-Fuel',     -- Renewed Fuel
        'LegacyFuel',       -- Legacy Fuel
        'ox_fuel',          -- Overextended (check after rcore)
        'lj-fuel',          -- LJ fuel
        'cdn-fuel',         -- CDN fuel
        'ps-fuel',          -- Project Sloth fuel
        'qb-fuel',          -- QBCore default
        'okokGasStation',   -- OkOk gas station
        'ti_fuel',          -- TI fuel
        'K4MB1_Fuel',       -- K4MB1 fuel
        't1ger_fuel',       -- T1ger fuel
        'myFuel',           -- myFuel
        'qs-fuelstations',  -- Quasar fuel stations
        'sadoj-fuel',       -- Sadoj fuel
        'gacha_fuel',       -- Gacha fuel
        'cd_fuel',          -- CD fuel
    }
}

-- Vehicle Key System (Auto-detects if set to 'auto')
Config.Keys = {
    -- 'auto' will detect the first running vehicle key resource
    -- Supported: 'qb-vehiclekeys', 'qbx_vehiclekeys',
    --            'wasabi_carlock', 'qs-vehiclekeys', 'Renewed-Vehiclekeys',
    --            'ps-vehiclekeys', 'mk_vehiclekeys', 't1ger_keys', 'okokVehicleKeys',
    --            'ic3d_vehiclekeys', 'xd_locksystem_v2',
    --            'xd_locksystem', 'fivecode_carkeys', 'cd_vehiclekeys',
    --            'MrNewbVehicleKeys'
    system = 'auto',
    
    -- Detection priority (first started resource wins)
    -- Reorder as needed for your server
    priority = {
        'MrNewbVehicleKeys',    -- MrNewb keys (most common)
        'qb-vehiclekeys',       -- QBCore default
        'qbx_vehiclekeys',      -- QBX/QBox keys
        'wasabi_carlock',       -- Wasabi car lock
        'qs-vehiclekeys',       -- Quasar vehicle keys
        'Renewed-Vehiclekeys',  -- Renewed vehicle keys
        'ps-vehiclekeys',       -- Project Sloth keys
        'mk_vehiclekeys',       -- ManKind vehicle keys
        't1ger_keys',           -- T1GER keys
        'okokVehicleKeys',      -- OkOK vehicle keys
        'ic3d_vehiclekeys',     -- ic3d advanced keys
        'xd_locksystem_v2',     -- xd locksystem v2
        'xd_locksystem',        -- xd locksystem v1
        'fivecode_carkeys',     -- Fivecode car keys
        'cd_vehiclekeys',       -- CD vehicle keys
    }
}

-- Ambulance/Death System (Auto-detects if set to 'auto')
Config.Ambulance = {
    -- 'auto' will detect the first running ambulance/death resource
    -- Supported: 'qb-ambulancejob', 'wasabi_ambulance', 'ars_ambulancejob',
    --            'ak47_ambulancejob', 'rcore_ambulance'
    -- Set to 'none' to always use un-admin native fallback revive
    system = 'auto',

    -- Detection priority (first started resource wins)
    priority = {
        'wasabi_ambulance',     -- Wasabi ambulance (check first)
        'qb-ambulancejob',      -- QBCore default
        'ars_ambulancejob',     -- ARS ambulance
        'ak47_ambulancejob',    -- AK47 ambulance
        'rcore_ambulance',      -- RCore ambulance
    },

    -- If true, also runs un-admin fallback revive after framework revive
    -- Useful for heavily customized ambulance scripts.
    forceFallback = false,
}

-- Troll Action Settings
Config.TrollSettings = {
    drunkDuration = 30000,      -- 30 seconds
    cageDuration = 30000,       -- 30 seconds
    fireDuration = 10000,       -- 10 seconds
    slapForce = 15.0,          -- Force applied when slapping player
    allowTrollActions = true    -- Set to false to disable troll actions entirely
}

-- Ocean Coordinates (for Send to Ocean troll)
-- Far north in the Pacific Ocean, away from the map
Config.OceanCoords = vector3(1500.0, 7000.0, 1.0)

-- Item Categories (for filtering in admin shop)
Config.ItemCategories = {
    'All',
    'Weapons',
    'Food',
    'Drinks',
    'Items',
    'Materials',
    'Tools',
    'Electronics',
    'Drugs',
    'Other'
}

-- ==============================================
-- ADVANCED PLAYER MANAGEMENT
-- ==============================================

-- Player History Tracking
Config.PlayerHistory = {
    enabled = true,
    trackBans = true,
    trackNames = true,
    trackConnections = true,
    maxHistoryDays = 90, -- Days to keep history
    webhook = '' -- Optional separate webhook for player history
}

-- Session Recording
Config.SessionRecording = {
    enabled = true,
    recordPosition = true,
    recordActions = true,
    recordChat = false, -- Privacy consideration
    saveInterval = 60000, -- 1 minute
    maxRecordingTime = 7200000, -- 2 hours max per session
}

-- Reputation System
Config.ReputationSystem = {
    enabled = true,
    defaultRep = 100,
    minRep = 0,
    maxRep = 1000,
    actions = {
        warning = -10,
        kick = -25,
        ban = -100,
        unban = 50,
        commend = 25
    }
}

-- AFK Detection
Config.AFKDetection = {
    enabled = true,
    timeout = 900000, -- 15 minutes
    kickOnAFK = false, -- Just flag, don't auto-kick
    notifyAdmins = true,
    excludeAdmins = true
}

-- Multi-Ban System
Config.MultiBan = {
    enabled = true,
    banByHardwareID = true,
    banBySteam = true,
    banByDiscord = true,
    banByIP = true,
    banByLicense = true
}

-- ==============================================
-- ECONOMY & STATISTICS
-- ==============================================

Config.Economy = {
    tracking = true,
    maxCash = 999999999,
    maxBank = 999999999,
    defaultStarterCash = 5000,
    defaultStarterBank = 10000,
    logTransactions = true,
    transactionHistoryDays = 30
}

Config.EconomyDashboard = {
    enabled = true,
    showTotalMoney = true,
    showRichestPlayers = true,
    showRecentTransactions = true,
    refreshInterval = 30000 -- 30 seconds
}

Config.WealthRedistribution = {
    enabled = true,
    requireConfirmation = true,
    minPercentage = 1,
    maxPercentage = 100
}

Config.JobStatistics = {
    enabled = true,
    trackJobActivity = true,
    trackJobPayouts = true,
    showTopJobs = true
}

-- ==============================================
-- ADVANCED VEHICLE FEATURES
-- ==============================================

Config.VehicleHistory = {
    enabled = true,
    trackOwners = true,
    trackSales = true,
    trackScraps = true,
    daysToKeep = 60
}

Config.BulkVehicleOperations = {
    enabled = true,
    allowDeleteAbandoned = true,
    abandonedDays = 30,
    allowResetGarages = true,
    allowDeleteAll = true,
    requireConfirmation = true
}

Config.VehicleBlacklist = {
    enabled = true,
    blacklistedVehicles = {
        -- 'khanjali', -- Example: block tank
        -- 'vigilante', -- Example: block vigilante
    }
}

Config.HandlingEditor = {
    enabled = true,
    allowRealTimeEdit = true,
    saveCustomHandling = true,
    resetOnRestart = false
}

-- ==============================================
-- DEVELOPER TOOLS (Extended)
-- ==============================================

Config.ResourceMonitor = {
    enabled = true,
    showCPU = true,
    showMemory = true,
    showThreads = true,
    refreshInterval = 2000, -- 2 seconds
    warningThreshold = {
        cpu = 10.0, -- %
        memory = 100.0 -- MB
    }
}

Config.ConsoleAccess = {
    enabled = true,
    allowServerCommands = true,
    logCommands = true,
    restrictedCommands = {
        'quit',
        'shutdown',
        'restart'
    }
}

Config.EntityInspector = {
    enabled = true,
    showModel = true,
    showCoords = true,
    showOwner = true,
    showNetID = true,
    allowTeleportTo = true
}

Config.AnimationPreview = {
    enabled = true,
    categories = {
        'Dance',
        'Greet',
        'Work',
        'Ambient',
        'Sports',
        'Scenario'
    }
}

-- ==============================================
-- SECURITY & ANTI-CHEAT
-- ==============================================

Config.AntiCheat = {
    enabled = true,
    logSuspiciousActivity = true,
    autoKickThreshold = 3,
    autoBanThreshold = 5,
    checks = {
        godMode = true,
        speedHacks = true,
        teleportHacks = true,
        weaponSpawn = true,
        resourceInjection = true,
        noclip = true,
        superJump = true
    },
    whitelist = {
        -- Add admin identifiers to whitelist from checks
    }
}

Config.Screenshots = {
    enabled = true,
    webhook = '', -- Screenshot upload webhook
    quality = 1.0,
    maxSize = 5242880, -- 5MB
    allowManual = true
}

Config.ResourceBlocker = {
    enabled = true,
    allowedResources = {}, -- Empty = all allowed
    blockedResources = {
        -- 'eulen', -- Example
        -- 'lynx', -- Example
    },
    notifyOnBlock = true
}

Config.AutomatedReports = {
    enabled = true,
    allowPlayerReports = true,
    requireReason = true,
    minReasonLength = 10,
    webhook = '' -- Reports webhook
}

-- ==============================================
-- COMMUNICATION
-- ==============================================

Config.Announcements = {
    defaultDuration = 10000, -- 10 seconds
    positions = {
        'top',
        'center',
        'bottom'
    },
    styles = {
        {name = 'Info', color = '#3498db'},
        {name = 'Success', color = '#2ecc71'},
        {name = 'Warning', color = '#f39c12'},
        {name = 'Error', color = '#e74c3c'},
        {name = 'Event', color = '#9b59b6'}
    },
    allowFormatting = true,
    maxLength = 500
}

Config.AdminChat = {
    enabled = true,
    command = 'ac',
    showInConsole = true,
    webhook = '', -- Admin chat webhook
    allowImages = false
}

Config.WarningSystem = {
    enabled = true,
    maxWarnings = 3,
    autoKickOnMax = true,
    autoBanOnMax = false,
    warningExpiry = 86400000, -- 24 hours
    notifyPlayer = true,
    logWarnings = true
}

Config.MessageTemplates = {
    enabled = true,
    templates = {
        {name = 'RDM Warning', message = 'You have been warned for Random Deathmatch. Next offense will result in a kick.'},
        {name = 'VDM Warning', message = 'You have been warned for Vehicle Deathmatch. Please review server rules.'},
        {name = 'FailRP Warning', message = 'You have been warned for FailRP. Please stay in character.'},
        {name = 'Metagaming Warning', message = 'You have been warned for metagaming. Do not use outside information.'},
        {name = 'Welcome Message', message = 'Welcome to the server! Please read the rules and enjoy your stay.'},
        {name = 'Event Starting', message = 'A server event is starting! Check the map for details.'},
    }
}

-- ==============================================
-- ADVANCED TELEPORTATION
-- ==============================================

Config.TeleportHistory = {
    enabled = true,
    maxHistory = 10,
    showInMenu = true,
    allowQuickReturn = true
}

Config.SavedLocationSets = {
    enabled = true,
    allowImport = true,
    allowExport = true,
    maxSets = 5,
    maxLocationsPerSet = 50
}

Config.TeleportToVehicle = {
    enabled = true,
    searchByPlate = true,
    searchByModel = true,
    showPreview = true
}

Config.InteriorScanner = {
    enabled = true,
    scanInterval = 5000, -- 5 seconds
    showOnMap = true,
    interiors = {
        'Appartments',
        'Garages',
        'Bunkers',
        'Facilities',
        'Businesses',
        'Custom'
    }
}

-- ==============================================
-- RECORDING & REPLAY
-- ==============================================

Config.AdminActionReplay = {
    enabled = true,
    recordAllActions = true,
    maxReplayTime = 3600000, -- 1 hour
    allowPlayback = true,
    saveReplays = true
}

Config.PlayerPOVRecording = {
    enabled = true,
    maxDuration = 600000, -- 10 minutes
    quality = 'medium',
    saveLocation = './recordings/',
    allowDownload = true
}

Config.IncidentRecorder = {
    enabled = true,
    allowTags = true,
    allowNotes = true,
    autoSaveOnBan = true,
    autoSaveOnKick = true,
    keepDays = 30
}

-- ==============================================
-- ANALYTICS & REPORTING
-- ==============================================

Config.ServerStatsDashboard = {
    enabled = true,
    showPlayerGraph = true,
    showPeakTimes = true,
    showRevenue = false, -- If using donations/shop
    dataRetentionDays = 30
}

Config.AdminActivityReport = {
    enabled = true,
    trackActions = true,
    trackOnlineTime = true,
    generateWeeklyReport = true,
    webhook = '' -- Admin report webhook
}

Config.PlayerDemographics = {
    enabled = true,
    trackPopularJobs = true,
    trackPopularVehicles = true,
    trackPopularLocations = true,
    updateInterval = 3600000 -- 1 hour
}

Config.Heatmaps = {
    enabled = true,
    trackDeaths = true,
    trackActivity = true,
    trackVehicleSpawns = true,
    resolution = 50, -- Grid size in meters
    updateInterval = 300000 -- 5 minutes
}

-- ==============================================
-- INTEGRATION FEATURES
-- ==============================================

Config.DiscordIntegration = {
    enabled = false, -- Set to true and configure
    botToken = '',
    guildId = '',
    channels = {
        logs = '',
        adminChat = '',
        reports = '',
        bans = ''
    },
    allowCommands = true,
    commands = {
        players = true,
        kick = true,
        announce = true,
        restart = true
    }
}

Config.WebhookAPI = {
    enabled = false,
    endpoints = {
        playerJoin = '',
        playerLeave = '',
        adminAction = '',
        serverStatus = ''
    },
    includeServerInfo = true,
    rateLimitPerMinute = 60
}

Config.MultiServer = {
    enabled = false,
    servers = {
        -- {name = 'Server 1', ip = '127.0.0.1:30120', token = 'your-api-token'},
        -- {name = 'Server 2', ip = '127.0.0.1:30121', token = 'your-api-token'},
    },
    allowCrossServerTP = false,
    allowCrossServerBan = true
}

Config.TabletControl = {
    enabled = false,
    requireAuth = true,
    apiKey = '', -- Generate secure API key
    allowRemoteCommands = true,
    limitedFeatures = true -- Restrict some features on mobile
}
