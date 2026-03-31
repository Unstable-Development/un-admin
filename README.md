# 🛡️ un-admin

## ✨ Key Features

### 🎯 Auto-Detection System
- **Multi-Inventory Support:** Automatically detects and adapts to qb-inventory, codem-inventory, qs-inventory, ps-inventory, or ox_inventory
- **Multi-Fuel Support:** Automatically detects and works with rcore_fuel, lj-fuel, cdn-fuel, ps-fuel, ox_fuel, or qb-fuel
- **No manual configuration needed** - Just install and run!

### 🎨 Customizable UI Themes
Choose from 6 pre-built color themes in `config.lua`:
- **Purple** (default) - `#b604da`
- **Blue** - `#3b82f6`
- **Green** - `#10b981`
- **Red** - `#ef4444`
- **Orange** - `#f97316`
- **Yellow** - `#eab308`

Dynamic theme switching + custom server name display!

### 📋 Report System
- Players use `/report` to submit reports (10-500 characters)
- Admins manage reports through dedicated Reports tab
- Discord webhook integration for notifications
- 60-second cooldown system
- Status tracking (Open/Resolved)
- Real-time badge counter with pulse animation

### 👥 Player Management
- View all online players with job, money, and ping
- Teleport to / Bring / Send players
- Revive / Heal / Give Armor
- Give Fuel (universal fuel system support)
- Set Job & Grade with visual picker
- Give Money (Cash/Bank)
- Freeze / Kill / Kick / Ban
- Spectate mode

### 🎭 Troll Actions (Fun Commands)
- 👋 **Slap** - Ragdoll + launch
- 🔥 **Set on Fire** - 10-second burn
- ⚡ **Electrocute** - Shock effect
- 🚀 **Fling** - Launch into sky
- 🍺 **Make Drunk** - 30s drunk effect
- 🗃️ **Cage** - Trap in cage
- 👥 **Clone** - NPC duplicate
- 💣 **Explode** - Boom!
- 🌊 **Ocean** / ☁️ **Sky** - Teleports

### 🛒 Admin Shop (Items)
- Browse and give any item from your inventory system
- Search and filter by category
- Item images displayed
- Give to self or any player
- Custom quantities

### 🚗 Vehicle Management
- Spawn any vehicle by model name
- Vehicle categories (Super, Sports, Emergency, etc.)
- Fix/delete vehicles
- Save vehicles to database (owned)
- Give vehicles to other players

### 🌦️ Server Controls
- Change weather (15+ types)
- Time control with slider
- Freeze/unfreeze time
- Server announcements
- **Enhanced Resource Management (God only)**
  - List all server resources with real-time status
  - Search/filter resources by name
  - Individual Start/Restart/Stop buttons for each resource
  - Cards show resource state (started/stopped)
  - Auto-refresh after actions
  - Action buttons disable intelligently based on resource state

### 🛠️ Developer Tools (God Only)
- **Noclip** - WASD + Q/E + Shift
- **God Mode** - Invincibility
- **Invisible** - Toggle visibility
- **Coordinates Display** - Copy in multiple formats (vector2, vector3, vector4, table, JSON)
- **Delete Laser** - Point and delete
- **Entity Info** - Detailed entity viewer

### 📊 Dashboard
- Live player count
- Server uptime
- Quick action buttons
- Recent actions feed
- Server statistics

---

## 📦 Installation

1. Place `un-admin` folder in your resources directory:
   ```
   resources/[your-category]/un-admin/
   ```

2. Add to `server.cfg`:
   ```cfg
   ensure un-admin
   ```

3. Configure permissions in `permissions.cfg`:
   ```cfg
   add_ace group.god qbcore.god allow
   add_ace group.admin qbcore.admin allow
   add_ace group.mod qbcore.mod allow
   
   # Add users to groups
   add_principal identifier.license:YOUR_LICENSE group.god
   ```

4. **(Optional)** Configure Discord webhooks in `config.lua`:
   ```lua
   Config.Webhook = 'YOUR_DISCORD_WEBHOOK_URL'  -- Admin actions
   Config.ReportSystem.webhook = 'YOUR_REPORT_WEBHOOK_URL'  -- Reports
   ```

5. **(Optional)** Customize UI theme in `config.lua`:
   ```lua
   Config.ServerName = "Your Server Name"
   Config.UITheme = "purple"  -- purple, blue, green, red, orange, yellow
   ```

---

## 🎮 Usage

### Opening the Menu
**Command:** `/pa`

**Default Keybind:** None (can be set in config.lua)

### Navigation
- Click tabs to switch sections
- Search bars to filter content
- Click players/items/vehicles for actions
- **ESC** to close menu

### Permission Levels
- **God** (`qbcore.god`) - Full access to all features
- **Admin** (`qbcore.admin`) - Most features (no dev tools, no resource mgmt)
- **Mod** (`qbcore.mod`) - Basic features (players, vehicles)

### Report System
- **Players:** Use `/report YOUR_MESSAGE` to submit
- **Admins:** View Reports tab, click to manage, resolve or delete
- Badge shows count of open reports

---

## ⚙️ Configuration

### Main Settings (`config.lua`)

```lua
-- Basic Setup
Config.Command = 'pa'              -- Menu command
Config.OpenKey = nil               -- Optional keybind (e.g., 'F2')
Config.Webhook = ''                -- Discord webhook for admin actions

-- UI Customization
Config.ServerName = "un-admin"     -- Display name in menu
Config.UITheme = "purple"          -- Color theme

-- Available Themes
Config.ThemeColors = {
    purple = { primary = "#b604da", dark = "#8b0eb5" },
    blue = { primary = "#3b82f6", dark = "#2563eb" },
    green = { primary = "#10b981", dark = "#059669" },
    red = { primary = "#ef4444", dark = "#dc2626" },
    orange = { primary = "#f97316", dark = "#ea580c" },
    yellow = { primary = "#eab308", dark = "#ca8a04" }
}

-- Auto-Detection (Leave as-is, automatically detects!)
Config.AutoDetect = {
    inventory = true,  -- Auto-detect inventory system
    fuel = true        -- Auto-detect fuel system
}

-- Report System
Config.ReportSystem = {
    enabled = true,
    command = 'report',
    webhook = '',                          -- Discord webhook URL
    cooldown = 60,                         -- Seconds between reports
    minLength = 10,                        -- Minimum characters
    maxLength = 500,                       -- Maximum characters
    notifyAdmins = true                    -- Notify online admins
}
```

### Feature Access by Permission

Customize what each rank can access in `Config.FeatureAccess`:

```lua
Config.FeatureAccess = {
    ['god'] = {
        dashboard = true,
        players = true,
        items = true,
        vehicles = true,
        server = true,
        developer = true,  -- Noclip, coords, etc.
        jobs = true,
        economy = true,
        logs = true,
        resources = true,
        reports = true
    },
    ['admin'] = {
        developer = false,   -- No dev tools
        resources = false,   -- No resource management
        -- ... rest enabled
    },
    ['mod'] = {
        items = false,       -- No item spawning
        server = false,      -- No weather/time
        economy = false,     -- No money giving
        -- ... limited access
    }
}
```

---

## 🔧 Technical Details

### Auto-Detection

On resource start, the system automatically:
1. Checks `GetResourceState()` for all supported inventory systems
2. Checks for all supported fuel systems
3. Configures universal wrappers to work with detected systems
4. Logs detected systems to console

**Supported Inventories:**
- qb-inventory
- codem-inventory
- qs-inventory
- ps-inventory
- ox_inventory

**Supported Fuel Systems:**
- rcore_fuel
- lj-fuel
- cdn-fuel
- ps-fuel
- ox_fuel
- qb-fuel

### File Structure

```
un-admin/
├── fxmanifest.lua
├── config.lua              # All configuration
├── README.md               # This file
├── server/
│   └── server_main.lua     # Server-side logic
├── client/
│   └── client_main.lua     # Client-side logic
└── html/
    ├── index.html          # UI structure
    ├── script.js           # UI logic
    └── style.css           # Styling + themes
```

### Security
- ✅ Server-side permission validation
- ✅ ACE permission integration
- ✅ Action logging (console, in-game, Discord)
- ✅ Rate limiting (report cooldowns)
- ✅ Input validation

---

## 🐛 Troubleshooting

### Menu Won't Open
- Check you have proper permissions (`qbcore.god`, `qbcore.admin`, or `qbcore.mod`)
- Verify `permissions.cfg` is configured correctly
- Check F8 console for Lua errors

### Items Not Showing
- Ensure your inventory system is running
- Check console for auto-detection messages: `[un-admin] Detected inventory: xxx`
- Verify inventory export functions are accessible

### Reports Not Working
- Ensure `Config.ReportSystem.enabled = true`
- Check for command conflicts with other resources
- Verify admin permissions for viewing reports

### Discord Webhooks Not Sending
- Verify webhook URL is correct (starts with `https://discord.com/api/webhooks/`)
- Check webhook channel has proper permissions
- Test webhook with external tools first

---

## 📋 Dependencies

**Required:**
- qb-core

**Optional (Auto-detected):**
- Any supported inventory system (for item giving)
- Any supported fuel system (for fuel giving)
- oxmysql (for ban system and vehicle saving)

---

## 🎯 Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/pa` | Open admin menu | god/admin/mod |
| `/report [message]` | Submit player report | all players |

---

## 📝 Changelog

### Latest Updates
- ✅ Multi-inventory auto-detection system
- ✅ Multi-fuel auto-detection system
- ✅ 6 customizable UI theme options
- ✅ Dynamic server name configuration
- ✅ Comprehensive report system with Discord webhooks
- ✅ Real-time report badge counter
- ✅ Enhanced job selection modal
- ✅ Full rebrand from "Prelude Admin" to "un-admin"

---

## 💡 Credits

Originally created for internal use, now refined for production environments.

---

**Command to Open:** `/pa`  
**Permissions:** `qbcore.god` | `qbcore.admin` | `qbcore.mod`  

**Enjoy your production-ready admin menu!** 🚀
