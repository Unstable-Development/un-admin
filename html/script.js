// Set to true to enable F8 console debug logging
const DEBUG = true;

// Ensure GetParentResourceName exists (FiveM provides this natively)
if (typeof GetParentResourceName === 'undefined') {
    window.GetParentResourceName = function() {
        return 'un-admin';
    };
}

// Global variables
let currentPermission = 'god';
let currentTab = 'dashboard';
let playersList = [];
let itemsList = [];
let vehiclesList = [];
let selectedPlayerId = null;
let selectedItem = null;
let currentMoneyPlayerId = null;
let inventoryConfig = { inventory: 'qb-inventory', imagePath: 'nui://qb-inventory/html/images/%s' };
let reportsList = [];
let currentReportFilter = 'all';
let selectedReportId = null;

// Clipboard helper function for FiveM NUI
function copyToClipboard(text) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    textArea.style.top = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
        document.execCommand('copy');
        textArea.remove();
        return true;
    } catch (err) {
        console.error('Failed to copy text: ', err);
        textArea.remove();
        return false;
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    initializeTabs();
    initializeSearch();
    setupEventListeners();
});

// Listen for NUI messages
window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch(data.action) {
        case 'openMenu':
            openMenu(data);
            break;
        case 'closeMenu':
            closeMenu();
            break;
        case 'updatePlayers':
            updatePlayersList(data.players);
            break;
        case 'updateItems':
            updateItemsList(data.items);
            break;
        case 'receiveVehicles':
            receiveVehicles(data.vehicles, data.categories);
            break;
        case 'openJobModal':
            openJobModal(data.jobs, data.playerId);
            break;
        case 'updateStats':
            updateStats(data.stats);
            break;
        case 'updateCoords':
            updateCoords(data.coords);
            break;
        case 'addLog':
            addLog(data.log);
            break;
        case 'notification':
            showNotification(data.message, data.type);
            break;
        case 'openReportModal':
            openReportModal();
            break;
        case 'displayReports':
            displayReports(data.reports);
            break;
        case 'updateReportCount':
            updateReportBadge(data.count);
            break;
        case 'displayResources':
            displayResources(data.resources);
            break;
        case 'refreshResources':
            refreshResourcesList();
            break;
        case 'updateEntityInfo':
            updateEntityInfo(data.entityData);
            break;
        case 'hideEntityInfo':
            hideEntityInfo();
            break;
        case 'triggerCopyEntityInfo':
            copyEntityInfo();
            break;
    }
});

// Send message to Lua
function sendAction(action, data = {}) {
    const resourceName = GetParentResourceName();
    fetch(`https://${resourceName}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    }).catch(err => {
        console.error(`[Admin UI] Callback Error: ${action}`, err.message);
    });
}

// Open menu
function openMenu(data) {
    const menu = document.getElementById('adminMenu');
    if (!menu) return;
    
    menu.classList.add('show');
    
    if (data.permission) {
        currentPermission = data.permission;
        const permBadge = document.getElementById('permissionBadge');
        if (permBadge) permBadge.textContent = data.permission.toUpperCase();
    }
    
    if (data.adminName) {
        const adminNameEl = document.getElementById('adminName');
        if (adminNameEl) adminNameEl.textContent = data.adminName;
    }
    
    // Apply server name
    if (data.uiConfig && data.uiConfig.serverName) {
        const serverNameEl = document.getElementById('serverName');
        if (serverNameEl) serverNameEl.textContent = data.uiConfig.serverName.toUpperCase();
    }
    
    // Apply theme colors
    if (data.uiConfig && data.uiConfig.colors) {
        applyThemeColors(data.uiConfig.colors);
    }
    
    if (data.config) {
        initializeQuickActions(data.config.quickActions);
        initializeCategories(data.config.categories);
        initializeWeatherButtons(data.config.weatherTypes);
    }
    
    // Store inventory config
    if (data.inventoryConfig) {
        inventoryConfig = data.inventoryConfig;
        DEBUG && console.log('[Admin UI] Inventory system:', inventoryConfig.inventory);
    }
    
    // Hide tabs based on permission
    filterTabsByPermission(data.access);
    
    // Load initial data for dashboard
    sendAction('requestPlayers');
}

// Convert hex color (#rrggbb) to "r, g, b" string for use in rgba()
function hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? `${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}` : null;
}

// Apply theme colors to CSS variables
function applyThemeColors(colors) {
    if (!colors) return;
    
    const root = document.documentElement;
    if (colors.primary) {
        root.style.setProperty('--primary-color', colors.primary);
        const rgb = hexToRgb(colors.primary);
        if (rgb) {
            root.style.setProperty('--primary-color-rgb', rgb);
            // Pre-build rgba strings at every alpha level used in CSS
            // (avoids rgba(var()) interpolation issues in FiveM's CEF)
            const alphas = { a05: 0.05, a10: 0.1, a15: 0.15, a20: 0.2, a25: 0.25, a30: 0.3, a40: 0.4, a50: 0.5, a60: 0.6, a70: 0.7 };
            for (const [key, alpha] of Object.entries(alphas)) {
                root.style.setProperty(`--primary-${key}`, `rgba(${rgb}, ${alpha})`);
            }
        }
    }
    if (colors.primaryDark) root.style.setProperty('--primary-dark', colors.primaryDark);
    if (colors.primaryLight) root.style.setProperty('--primary-light', colors.primaryLight);
    if (colors.accent) root.style.setProperty('--accent-color', colors.accent);
    
    DEBUG && console.log('[Admin UI] Theme colors applied:', colors);
}

// Close menu
function closeMenu() {
    const menu = document.getElementById('adminMenu');
    if (menu) {
        menu.classList.remove('show');
    }
    sendAction('closeUI');
}

// ESC key to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeMenu();
    }
});

// Initialize tabs
function initializeTabs() {
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            switchTab(tab.dataset.tab);
        });
    });
}

// Switch tab
function switchTab(tabName) {
    DEBUG && console.log('[Admin UI] Switching to tab:', tabName);
    
    // Remove active class from all tabs and content
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
    
    // Add active class to selected tab and content
    const selectedTab = document.querySelector(`[data-tab="${tabName}"]`);
    const selectedContent = document.getElementById(tabName);
    
    if (selectedTab) {
        selectedTab.classList.add('active');
    } else {
        console.error('[Admin UI] Could not find tab:', tabName);
    }
    
    if (selectedContent) {
        selectedContent.classList.add('active');
    } else {
        console.error('[Admin UI] Could not find content:', tabName);
    }
    
    currentTab = tabName;
    
    // Request data for the tab if needed
    if (tabName === 'players') {
        sendAction('requestPlayers');
    } else if (tabName === 'items') {
        sendAction('requestItems');
    } else if (tabName === 'vehicles') {
        sendAction('requestVehicles');
    } else if (tabName === 'logs') {
        sendAction('requestLogs');
    } else if (tabName === 'reports') {
        requestReports('all');
    } else if (tabName === 'server') {
        refreshResourcesList();
    }
}

// Filter tabs by permission
function filterTabsByPermission(access) {
    if (!access) return;
    
    document.querySelectorAll('.tab').forEach(tab => {
        const tabName = tab.dataset.tab;
        // Only hide if explicitly set to false
        if (access[tabName] === false) {
            tab.style.display = 'none';
        } else {
            tab.style.display = 'flex'; // Ensure visible tabs stay flex
        }
    });
}

// Initialize search
function initializeSearch() {
    // Player search
    document.getElementById('playerSearch')?.addEventListener('input', (e) => {
        filterPlayers(e.target.value);
    });
    
    // Item search
    document.getElementById('itemSearch')?.addEventListener('input', (e) => {
        filterItems(e.target.value);
    });
    
    // Vehicle search
    document.getElementById('vehicleSearch')?.addEventListener('input', (e) => {
        filterVehicles(e.target.value);
    });
}

// Update players list
function updatePlayersList(players) {
    playersList = players;
    const grid = document.getElementById('playersGrid');
    if (!grid) return;
    
    grid.innerHTML = '';
    
    if (!players || players.length === 0) {
        grid.innerHTML = '<div style="color: #999; text-align: center; padding: 40px;">No players online</div>';
        return;
    }
    
    players.forEach(player => {
        const card = document.createElement('div');
        card.className = 'player-card';
        card.onclick = () => openPlayerModal(player);
        
        card.innerHTML = `
            <div class="player-header">
                <div class="player-name">${player.name}</div>
                <div class="player-id">ID: ${player.id}</div>
            </div>
            <div class="player-info">
                <div class="info-row">
                    <span class="info-label">Job:</span>
                    <span>${player.job || 'Unemployed'}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Cash:</span>
                    <span>$${formatNumber(player.cash || 0)}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Bank:</span>
                    <span>$${formatNumber(player.bank || 0)}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Ping:</span>
                    <span>${player.ping || 0}ms</span>
                </div>
            </div>
        `;
        
        grid.appendChild(card);
    });
    
    // Update player select in item modal
    updatePlayerSelect(players);
}

// Filter players
function filterPlayers(query) {
    if (!playersList || playersList.length === 0) return;
    
    const filtered = playersList.filter(p => 
        p.name.toLowerCase().includes(query.toLowerCase()) ||
        p.id.toString().includes(query)
    );
    updatePlayersList(filtered);
}

// Update player select dropdown
function updatePlayerSelect(players) {
    const select = document.getElementById('giveToPlayer');
    if (!select) return;
    
    select.innerHTML = '<option value="self">Myself</option>';
    players.forEach(player => {
        const option = document.createElement('option');
        option.value = player.id;
        option.textContent = `${player.name} (${player.id})`;
        select.appendChild(option);
    });
}

// Open player modal
function openPlayerModal(player) {
    selectedPlayerId = player.id;
    const modal = document.getElementById('playerModal');
    if (!modal) return;
    
    const modalBody = modal.querySelector('.modal-body');
    if (!modalBody) return;
    
    const modalName = document.getElementById('modalPlayerName');
    if (modalName) {
        modalName.textContent = `${player.name} - ID: ${player.id}`;
    }
    
    // Main Actions
    const mainActions = [
        { icon: 'location-arrow', label: 'Teleport To', action: 'teleportToPlayer', color: 'primary' },
        { icon: 'hand-paper', label: 'Bring', action: 'bringPlayer', color: 'primary' },
        { icon: 'paper-plane', label: 'Send To Me', action: 'sendToMe', color: 'primary' },
        { icon: 'heart', label: 'Revive', action: 'revivePlayer', color: 'success' },
        { icon: 'shield-alt', label: 'Give Armor', action: 'giveArmor', color: 'success' },
        { icon: 'gas-pump', label: 'Give Fuel', action: 'giveFuel', color: 'success' },
        { icon: 'briefcase', label: 'Set Job', action: 'setJob', color: 'primary' },
        { icon: 'dollar-sign', label: 'Give Money', action: 'giveMoney', color: 'success' },
        { icon: 'eye', label: 'Spectate', action: 'spectatePlayer', color: 'primary' }
    ];
    
    // Admin Actions (moderation)
    const adminActions = [
        { icon: 'user-slash', label: 'Kick', action: 'kickPlayer', color: 'admin' },
        { icon: 'ban', label: 'Ban', action: 'banPlayer', color: 'admin' }
    ];
    
    // Control Actions
    const controlActions = [
        { icon: 'snowflake', label: 'Freeze', action: 'freezePlayer', color: 'warning' },
        { icon: 'skull-crossbones', label: 'Kill', action: 'killPlayer', color: 'danger' },
        { icon: 'ban', label: 'Strip Weapons', action: 'stripWeapons', color: 'warning' }
    ];
    
    // Troll Actions
    const trollActions = [
        { icon: 'hand-rock', label: 'Slap', action: 'slapPlayer', color: 'troll' },
        { icon: 'fire', label: 'Set on Fire', action: 'setOnFire', color: 'troll' },
        { icon: 'bolt', label: 'Electrocute', action: 'electrocute', color: 'troll' },
        { icon: 'rocket', label: 'Fling', action: 'flingPlayer', color: 'troll' },
        { icon: 'glass-martini', label: 'Make Drunk', action: 'makeDrunk', color: 'troll' },
        { icon: 'cube', label: 'Cage', action: 'cagePlayer', color: 'troll' },
        { icon: 'bomb', label: 'Explode', action: 'explodePlayer', color: 'troll' },
        { icon: 'water', label: 'Send to Ocean', action: 'sendToOcean', color: 'troll' },
        { icon: 'parachute-box', label: 'Send to Sky', action: 'sendToSky', color: 'troll' }
    ];
    
    const actions = [...mainActions, ...adminActions, ...controlActions, ...trollActions];
    
    modalBody.innerHTML = '';
    
    // Create sections
    const mainSection = document.createElement('div');
    mainSection.innerHTML = '<h4 class="action-section-title"><i class="fas fa-cog"></i> Main Actions</h4>';
    modalBody.appendChild(mainSection);
    
    const mainGrid = document.createElement('div');
    mainGrid.className = 'action-buttons';
    mainActions.forEach(act => createActionButton(act, mainGrid, player));
    modalBody.appendChild(mainGrid);
    
    const adminSection = document.createElement('div');
    adminSection.innerHTML = '<h4 class="action-section-title"><i class="fas fa-gavel"></i> Admin Actions</h4>';
    modalBody.appendChild(adminSection);
    
    const adminGrid = document.createElement('div');
    adminGrid.className = 'action-buttons';
    adminActions.forEach(act => createActionButton(act, adminGrid, player));
    modalBody.appendChild(adminGrid);
    
    const controlSection = document.createElement('div');
    controlSection.innerHTML = '<h4 class="action-section-title"><i class="fas fa-exclamation-triangle"></i> Control Actions</h4>';
    modalBody.appendChild(controlSection);
    
    const controlGrid = document.createElement('div');
    controlGrid.className = 'action-buttons';
    controlActions.forEach(act => createActionButton(act, controlGrid, player));
    modalBody.appendChild(controlGrid);
    
    const trollSection = document.createElement('div');
    trollSection.innerHTML = '<h4 class="action-section-title"><i class="fas fa-laugh-squint"></i> Troll Actions</h4>';
    modalBody.appendChild(trollSection);
    
    const trollGrid = document.createElement('div');
    trollGrid.className = 'action-buttons';
    trollActions.forEach(act => createActionButton(act, trollGrid, player));
    modalBody.appendChild(trollGrid);
    
    modal.classList.add('show');
}

// Create action button helper
function createActionButton(act, container, player) {
    const btn = document.createElement('button');
    btn.className = 'action-btn' + (act.color ? ` action-${act.color}` : '');
    btn.innerHTML = `
        <i class="fas fa-${act.icon}"></i>
        <span>${act.label}</span>
    `;
    btn.onclick = () => {
        if (act.action === 'giveMoney') {
            openGiveMoneyModal(selectedPlayerId);
            closePlayerModal();
            return;
        }

        sendAction(act.action, { playerId: selectedPlayerId, playerName: player.name });
        closePlayerModal();
    };
    container.appendChild(btn);
}

// Close player modal
function closePlayerModal() {
    const modal = document.getElementById('playerModal');
    if (modal) {
        modal.classList.remove('show');
    }
}

// Update items list
function updateItemsList(items) {
    itemsList = items;
    const grid = document.getElementById('itemsGrid');
    if (!grid) return;
    
    grid.innerHTML = '';
    
    if (!items || items.length === 0) {
        grid.innerHTML = '<div style="color: #999; text-align: center; padding: 40px;">Loading items...</div>';
        return;
    }
    
    items.forEach(item => {
        const card = document.createElement('div');
        card.className = 'item-card';
        card.onclick = () => openItemModal(item);
        
        // Use dynamic image path from detected inventory system
        const imagePath = inventoryConfig.imagePath.replace('%s', item.image);
        
        card.innerHTML = `
            <img src="${imagePath}" class="item-image" onerror="this.src='https://via.placeholder.com/120x120/b604da/ffffff?text=${item.label}'">
            <div class="item-name">${item.label}</div>
            <div class="item-weight">${item.weight}g</div>
            <div class="item-price">FREE</div>
        `;
        
        grid.appendChild(card);
    });
}

// Filter items
function filterItems(query) {
    if (!itemsList || itemsList.length === 0) return;
    
    const filtered = itemsList.filter(item => 
        item.label.toLowerCase().includes(query.toLowerCase()) ||
        item.name.toLowerCase().includes(query.toLowerCase())
    );
    updateItemsList(filtered);
}

// Initialize categories
function initializeCategories(categories) {
    const container = document.getElementById('categoryFilters');
    if (!container) return;
    
    container.innerHTML = '';
    categories.forEach((cat, index) => {
        const btn = document.createElement('button');
        btn.className = 'category-btn' + (index === 0 ? ' active' : '');
        btn.textContent = cat;
        btn.onclick = () => filterByCategory(cat, btn);
        container.appendChild(btn);
    });
}

// Filter by category
function filterByCategory(category, btnElement) {
    document.querySelectorAll('.category-btn').forEach(b => b.classList.remove('active'));
    btnElement.classList.add('active');
    
    if (category === 'All') {
        updateItemsList(itemsList);
    } else {
        sendAction('filterItems', { category });
    }
}

// Open item modal
function openItemModal(item) {
    selectedItem = item;
    const modal = document.getElementById('itemModal');
    if (!modal) return;
    
    const modalName = document.getElementById('modalItemName');
    if (modalName) {
        modalName.textContent = `Give ${item.label}`;
    }
    
    const quantityInput = document.getElementById('itemQuantity');
    if (quantityInput) {
        quantityInput.value = 1;
    }
    
    modal.classList.add('show');
}

// Close item modal
function closeItemModal() {
    const modal = document.getElementById('itemModal');
    if (modal) {
        modal.classList.remove('show');
    }
}

// Give item
function giveItem() {
    const quantity = parseInt(document.getElementById('itemQuantity').value);
    const targetPlayer = document.getElementById('giveToPlayer').value;
    
    sendAction('giveItem', {
        item: selectedItem.name,
        quantity: quantity,
        target: targetPlayer
    });
    
    closeItemModal();
}

// Initialize quick actions
function initializeQuickActions(actions) {
    const grid = document.getElementById('quickActionsGrid');
    if (!grid || !actions) return;
    
    grid.innerHTML = '';
    actions.forEach(action => {
        const btn = document.createElement('button');
        btn.className = 'quick-action-btn';
        btn.innerHTML = `
            <i class="fas fa-${action.icon}"></i>
            <span>${action.label}</span>
        `;
        btn.onclick = () => sendAction(action.action);
        grid.appendChild(btn);
    });
}

// Update stats
function updateStats(stats) {
    const totalPlayersEl = document.getElementById('totalPlayers');
    const uptimeEl = document.getElementById('serverUptime');
    const totalVehiclesEl = document.getElementById('totalVehicles');
    const totalBansEl = document.getElementById('totalBans');
    
    if (totalPlayersEl && stats.playerCount !== undefined) {
        totalPlayersEl.textContent = stats.playerCount;
    }
    if (uptimeEl && stats.uptime) {
        uptimeEl.textContent = stats.uptime;
    }
    if (totalVehiclesEl && stats.vehicleCount !== undefined) {
        totalVehiclesEl.textContent = stats.vehicleCount;
    }
    if (totalBansEl && stats.totalBans !== undefined) {
        totalBansEl.textContent = stats.totalBans;
    }
}

// Update coordinates
function updateCoords(coords) {
    const coordX = document.getElementById('coordX');
    const coordY = document.getElementById('coordY');
    const coordZ = document.getElementById('coordZ');
    const coordH = document.getElementById('coordH');
    
    if (coordX) coordX.value = coords.x.toFixed(2);
    if (coordY) coordY.value = coords.y.toFixed(2);
    if (coordZ) coordZ.value = coords.z.toFixed(2);
    if (coordH) coordH.value = coords.h.toFixed(2);
}

// Copy coordinates - Multiple formats
function copyVector2() {
    const x = document.getElementById('coordX').value;
    const y = document.getElementById('coordY').value;
    
    const coordsString = `vector2(${x}, ${y})`;
    copyToClipboard(coordsString);
    showNotification('vector2 copied to clipboard!', 'success');
}

function copyVector3() {
    const x = document.getElementById('coordX').value;
    const y = document.getElementById('coordY').value;
    const z = document.getElementById('coordZ').value;
    
    const coordsString = `vector3(${x}, ${y}, ${z})`;
    copyToClipboard(coordsString);
    showNotification('vector3 copied to clipboard!', 'success');
}

function copyVector4() {
    const x = document.getElementById('coordX').value;
    const y = document.getElementById('coordY').value;
    const z = document.getElementById('coordZ').value;
    const h = document.getElementById('coordH').value;
    
    const coordsString = `vector4(${x}, ${y}, ${z}, ${h})`;
    copyToClipboard(coordsString);
    showNotification('vector4 copied to clipboard!', 'success');
}

function copyTable() {
    const x = document.getElementById('coordX').value;
    const y = document.getElementById('coordY').value;
    const z = document.getElementById('coordZ').value;
    const h = document.getElementById('coordH').value;
    
    const coordsString = `{x = ${x}, y = ${y}, z = ${z}, w = ${h}}`;
    copyToClipboard(coordsString);
    showNotification('Table format copied to clipboard!', 'success');
}

function copyJson() {
    const x = parseFloat(document.getElementById('coordX').value);
    const y = parseFloat(document.getElementById('coordY').value);
    const z = parseFloat(document.getElementById('coordZ').value);
    const h = parseFloat(document.getElementById('coordH').value);
    
    const coordsString = JSON.stringify({x: x, y: y, z: z, h: h}, null, 2);
    copyToClipboard(coordsString);
    showNotification('JSON format copied to clipboard!', 'success');
}

// Save location
function saveLocation() {
    const locationName = document.getElementById('locationName').value;
    if (!locationName.trim()) {
        showNotification('Please enter a location name', 'error');
        return;
    }
    
    const x = parseFloat(document.getElementById('coordX').value);
    const y = parseFloat(document.getElementById('coordY').value);
    const z = parseFloat(document.getElementById('coordZ').value);
    const h = parseFloat(document.getElementById('coordH').value);
    
    sendAction('saveLocation', {
        name: locationName,
        coords: {x: x, y: y, z: z, h: h}
    });
    
    document.getElementById('locationName').value = '';
    showNotification(`Location "${locationName}" saved!`, 'success');
}

// Teleport to coordinates
function teleportToCoords() {
    const x = parseFloat(document.getElementById('tpX').value);
    const y = parseFloat(document.getElementById('tpY').value);
    const z = parseFloat(document.getElementById('tpZ').value);
    
    if (!isNaN(x) && !isNaN(y) && !isNaN(z)) {
        sendAction('teleportToCoords', { x, y, z });
    }
}

// Initialize weather buttons
function initializeWeatherButtons(weatherTypes) {
    const grid = document.getElementById('weatherGrid');
    if (!grid || !weatherTypes) return;
    
    grid.innerHTML = '';
    weatherTypes.forEach(weather => {
        const btn = document.createElement('button');
        btn.className = 'weather-btn';
        btn.textContent = weather;
        btn.onclick = () => sendAction('setWeather', { weather });
        grid.appendChild(btn);
    });
}

// Initialize time controls
function initializeTimeControls() {
    const timeSlider = document.getElementById('timeSlider');
    const timeDisplay = document.getElementById('timeDisplay');
    
    if (timeSlider && timeDisplay) {
        // Update display as slider moves
        timeSlider.addEventListener('input', (e) => {
            const hour = e.target.value;
            timeDisplay.textContent = `${String(hour).padStart(2, '0')}:00`;
        });
        
        // Send to server only when released (prevents spam)
        timeSlider.addEventListener('change', (e) => {
            const hour = parseInt(e.target.value);
            sendAction('setTime', { hour });
        });
    }
}

// Freeze time
function freezeTime() {
    sendAction('freezeTime');
}

// Send announcement
function sendAnnouncement() {
    const textArea = document.getElementById('announcementText');
    if (!textArea) {
        console.error('[Admin UI] Announcement textarea not found');
        return;
    }
    
    const text = textArea.value;
    if (!text.trim()) {
        showNotification('Please enter an announcement message', 'error');
        return;
    }
    
    DEBUG && console.log('[Admin UI] Sending announcement:', text);
    sendAction('sendAnnouncement', { text });
    textArea.value = '';
    showNotification('Announcement sent to all players', 'success');
}

// Resource management
function startResource() {
    const name = document.getElementById('resourceName').value;
    if (name.trim()) {
        sendAction('startResource', { resource: name });
    }
}

function restartResource() {
    const name = document.getElementById('resourceName').value;
    if (name.trim()) {
        sendAction('restartResource', { resource: name });
    }
}

function stopResource() {
    const name = document.getElementById('resourceName').value;
    if (name.trim()) {
        sendAction('stopResource', { resource: name });
    }
}

// ========================
// RESOURCE MANAGEMENT
// ========================

let resourcesList = [];

// Request resources list
function refreshResourcesList() {
    DEBUG && console.log('[Admin UI] Requesting resources list');
    sendAction('requestResources');
}

// Display resources
function displayResources(resources) {
    resourcesList = resources || [];
    DEBUG && console.log('[Admin UI] Displaying', resourcesList.length, 'resources');
    
    const container = document.getElementById('resourcesList');
    if (!container) {
        console.error('[Admin UI] Resources list container not found');
        return;
    }
    
    // Clear existing content
    container.innerHTML = '';
    
    if (resourcesList.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-box-open fa-3x"></i>
                <h3>No resources found</h3>
            </div>
        `;
        return;
    }
    
    // Sort by name
    resourcesList.sort((a, b) => a.name.localeCompare(b.name));
    
    // Create resource cards
    resourcesList.forEach(resource => {
        const card = document.createElement('div');
        card.className = 'resource-card';
        
        const stateClass = resource.state === 'started' ? 'status-running' : 
                          resource.state === 'stopped' ? 'status-stopped' : 'status-unknown';
        const stateIcon = resource.state === 'started' ? 'fa-check-circle' : 
                         resource.state === 'stopped' ? 'fa-stop-circle' : 'fa-question-circle';
        
        card.innerHTML = `
            <div class="resource-info">
                <div class="resource-name">${resource.name}</div>
                <div class="resource-status ${stateClass}">
                    <i class="fas ${stateIcon}"></i> ${resource.state}
                </div>
            </div>
            <div class="resource-actions">
                ${resource.state === 'stopped' ? 
                    `<button class="btn-resource btn-success" onclick="startResourceByName('${resource.name}')">
                        <i class="fas fa-play"></i> Start
                    </button>` : 
                    `<button class="btn-resource btn-secondary" disabled>
                        <i class="fas fa-play"></i> Start
                    </button>`
                }
                ${resource.state === 'started' ? 
                    `<button class="btn-resource btn-warning" onclick="restartResourceByName('${resource.name}')">
                        <i class="fas fa-redo"></i> Restart
                    </button>` : 
                    `<button class="btn-resource btn-secondary" disabled>
                        <i class="fas fa-redo"></i> Restart
                    </button>`
                }
                ${resource.state === 'started' ? 
                    `<button class="btn-resource btn-danger" onclick="stopResourceByName('${resource.name}')">
                        <i class="fas fa-stop"></i> Stop
                    </button>` : 
                    `<button class="btn-resource btn-secondary" disabled>
                        <i class="fas fa-stop"></i> Stop
                    </button>`
                }
            </div>
        `;
        
        container.appendChild(card);
    });
    
    DEBUG && console.log('[Admin UI] Displayed', resourcesList.length, 'resource cards');
}

// Filter resources by search
function filterResources() {
    const searchInput = document.getElementById('resourceSearch');
    if (!searchInput) return;
    
    const searchTerm = searchInput.value.toLowerCase();
    const cards = document.querySelectorAll('.resource-card');
    
    cards.forEach(card => {
        const resourceName = card.querySelector('.resource-name').textContent.toLowerCase();
        if (resourceName.includes(searchTerm)) {
            card.style.display = 'flex';
        } else {
            card.style.display = 'none';
        }
    });
}

// Resource actions
function startResourceByName(resourceName) {
    DEBUG && console.log('[Admin UI] Starting resource:', resourceName);
    sendAction('startResource', { resource: resourceName });
}

function restartResourceByName(resourceName) {
    DEBUG && console.log('[Admin UI] Restarting resource:', resourceName);
    sendAction('restartResource', { resource: resourceName });
}

function stopResourceByName(resourceName) {
    DEBUG && console.log('[Admin UI] Stopping resource:', resourceName);
    sendAction('stopResource', { resource: resourceName });
}

// Developer tools
function toggleNoclip() {
    sendAction('toggleNoclip');
}

function toggleAirwalk() {
    sendAction('toggleAirwalk');
}

function toggleGodmode() {
    sendAction('toggleGodmode');
}

function toggleInvisible() {
    sendAction('toggleInvisible');
}

function toggleCoords() {
    sendAction('toggleCoords');
}

function toggleDeleteLaser() {
    sendAction('toggleDeleteLaser');
}

function toggleEntityInfo() {
    sendAction('toggleEntityInfo');
}

// Quick actions
function fixVehicle() {
    sendAction('fixVehicle');
}

function refuelVehicle() {
    sendAction('refuelVehicle');
}

function healSelf() {
    sendAction('healSelf');
}

function tpWaypoint() {
    sendAction('tpWaypoint');
}

function clearArea() {
    sendAction('clearArea');
}

function toggleNoclipDashboard() {
    sendAction('toggleNoclip');
}

function toggleAirwalkDashboard() {
    sendAction('toggleAirwalk');
}

function freezeAllPlayers() {
    sendAction('freezeAllPlayers');
}

function reviveAllPlayers() {
    sendAction('reviveAllPlayers');
}

function deleteAllVehicles() {
    sendAction('deleteAllVehicles');
}

function clearAreaPeds() {
    sendAction('clearAreaPeds');
}

// Add log
function addLog(log) {
    const container = document.getElementById('logsList');
    if (!container) return;
    
    const logItem = document.createElement('div');
    logItem.className = 'log-item';
    logItem.innerHTML = `
        <div class="log-header">
            <span class="log-admin">${log.admin}</span>
            <span class="log-time">${log.time}</span>
        </div>
        <div class="log-action">${log.action}</div>
    `;
    
    container.insertBefore(logItem, container.firstChild);
    
    // Keep only last 50 logs
    while (container.children.length > 50) {
        container.removeChild(container.lastChild);
    }
}

// Add to recent actions
function addRecentAction(text) {
    const container = document.getElementById('recentActions');
    if (!container) return;
    
    const actionItem = document.createElement('div');
    actionItem.className = 'action-item';
    actionItem.innerHTML = `
        <i class="fas fa-check-circle"></i>
        <span>${text}</span>
        <span class="action-time">Just now</span>
    `;
    
    container.insertBefore(actionItem, container.firstChild);
    
    // Keep only last 10 actions
    while (container.children.length > 10) {
        container.removeChild(container.lastChild);
    }
}

// Show notification
function showNotification(message, type = 'info') {
    addRecentAction(message);
    
    // Create toast notification
    const toast = document.createElement('div');
    toast.className = `toast-notification toast-${type}`;
    toast.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
        <span>${message}</span>
    `;
    
    document.body.appendChild(toast);
    
    // Trigger animation
    setTimeout(() => toast.classList.add('show'), 10);
    
    // Remove after 3 seconds
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Utility: Format number with commas
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// Setup event listeners
function setupEventListeners() {
    // Close modals on background click
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.classList.remove('show');
            }
        });
    });
    
    // Initialize time controls
    initializeTimeControls();
    
    // Vehicle spawn target change handler
    const spawnTargetSelect = document.getElementById('spawnTargetPlayer');
    if (spawnTargetSelect) {
        spawnTargetSelect.addEventListener('change', (e) => {
            const targetGroup = document.getElementById('targetPlayerIdGroup');
            if (targetGroup) {
                targetGroup.style.display = e.target.value === 'other' ? 'block' : 'none';
            }
        });
    }
}

// ========================================
// VEHICLE SPAWNING SYSTEM
// ========================================

let vehiclesData = {};
let vehicleCategories = [];
let currentVehicleCategory = 'all';
let selectedVehicle = null;

// Receive vehicles from server
function receiveVehicles(vehicles, categories) {
    DEBUG && console.log('[Admin UI] Received vehicles data:', vehicles);
    DEBUG && console.log('[Admin UI] Received categories:', categories);
    
    vehiclesData = vehicles || {};
    vehicleCategories = categories || [];
    populateVehicleCategories();
    displayVehicles('all');
}

// Populate vehicle category buttons
function populateVehicleCategories() {
    const container = document.getElementById('vehicleCategories');
    if (!container) return;
    
    container.innerHTML = '';
    
    // Add "All" category
    const allBtn = document.createElement('button');
    allBtn.className = 'vehicle-category-btn active';
    allBtn.innerHTML = `<i class="fas fa-th"></i> All`;
    allBtn.onclick = () => filterVehicleCategory('all', allBtn);
    container.appendChild(allBtn);
    
    // Add other categories if they exist
    if (vehicleCategories && vehicleCategories.length > 0) {
        vehicleCategories.forEach(cat => {
            const btn = document.createElement('button');
            btn.className = 'vehicle-category-btn';
            btn.innerHTML = `<i class="fas fa-${cat.icon || 'car'}"></i> ${cat.name}`;
            btn.onclick = () => filterVehicleCategory(cat.id, btn);
            container.appendChild(btn);
        });
    }
}

// Filter vehicles by category
function filterVehicleCategory(category, button) {
    currentVehicleCategory = category;
    
    // Update active button
    document.querySelectorAll('.vehicle-category-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    button.classList.add('active');
    
    // Display filtered vehicles
    displayVehicles(category);
}

// Display vehicles in grid
function displayVehicles(category) {
    const grid = document.getElementById('vehiclesGrid');
    if (!grid) return;
    
    grid.innerHTML = '';
    
    if (!vehiclesData || Object.keys(vehiclesData).length === 0) {
        grid.innerHTML = '<div style="color: #999; text-align: center; padding: 40px;">No vehicles available</div>';
        return;
    }
    
    let vehicleCount = 0;
    
    if (category === 'all') {
        // Display all vehicles from all categories
        Object.keys(vehiclesData).forEach(catKey => {
            if (vehiclesData[catKey] && Array.isArray(vehiclesData[catKey])) {
                vehiclesData[catKey].forEach(vehicle => {
                    grid.appendChild(createVehicleCard(vehicle));
                    vehicleCount++;
                });
            }
        });
    } else {
        // Display vehicles from specific category
        if (vehiclesData[category] && Array.isArray(vehiclesData[category])) {
            vehiclesData[category].forEach(vehicle => {
                grid.appendChild(createVehicleCard(vehicle));
                vehicleCount++;
            });
        } else {
            console.warn(`[Admin UI] No vehicles found for category: ${category}`);
            grid.innerHTML = `<div style="color: #999; text-align: center; padding: 40px;">No vehicles in this category</div>`;
        }
    }
    
    DEBUG && console.log(`[Admin UI] Displayed ${vehicleCount} vehicles for category: ${category}`);
}

// Create vehicle card element
function createVehicleCard(vehicle) {
    const card = document.createElement('div');
    card.className = 'vehicle-card';
    card.onclick = () => openVehicleModal(vehicle);
    
    card.innerHTML = `
        <div class="vehicle-card-icon">
            <i class="fas fa-car"></i>
        </div>
        <div class="vehicle-card-name">${vehicle.name}</div>
        <div class="vehicle-card-brand">${vehicle.brand}</div>
        <div class="vehicle-card-model">${vehicle.model}</div>
    `;
    
    return card;
}

// Open vehicle spawn modal
function openVehicleModal(vehicle) {
    selectedVehicle = vehicle;
    
    const modalName = document.getElementById('modalVehicleName');
    const modalBrand = document.getElementById('vehicleModalBrand');
    const modalModel = document.getElementById('vehicleModalModel');
    const vehicleModal = document.getElementById('vehicleModal');
    
    if (modalName) modalName.textContent = `Spawn ${vehicle.name}`;
    if (modalBrand) modalBrand.textContent = vehicle.brand;
    if (modalModel) modalModel.textContent = vehicle.model;
    
    // Reset options
    const spawnOwned = document.getElementById('spawnOwned');
    if (spawnOwned) spawnOwned.checked = false;
    
    const targetPlayer = document.getElementById('spawnTargetPlayer');
    if (targetPlayer) targetPlayer.value = 'self';
    
    const targetIdGroup = document.getElementById('targetPlayerIdGroup');
    if (targetIdGroup) targetIdGroup.style.display = 'none';
    
    if (vehicleModal) vehicleModal.classList.add('show');
}

// Close vehicle modal
function closeVehicleModal() {
    const modal = document.getElementById('vehicleModal');
    if (modal) {
        modal.classList.remove('show');
    }
    selectedVehicle = null;
}

// Spawn vehicle
function spawnVehicle() {
    if (!selectedVehicle) {
        console.error('[Admin UI] No vehicle selected');
        return;
    }
    
    const spawnOwnedEl = document.getElementById('spawnOwned');
    const spawnTargetEl = document.getElementById('spawnTargetPlayer');
    const targetIdEl = document.getElementById('targetPlayerId');
    
    if (!spawnOwnedEl || !spawnTargetEl) {
        console.error('[Admin UI] Vehicle modal elements not found');
        return;
    }
    
    const spawnOwned = spawnOwnedEl.checked;
    const spawnTarget = spawnTargetEl.value;
    const targetId = targetIdEl ? targetIdEl.value : null;
    
    DEBUG && console.log('[Admin UI] Spawning vehicle:', selectedVehicle.model, 'owned:', spawnOwned, 'target:', spawnTarget);
    
    if (spawnTarget === 'self') {
        // Spawn for self
        if (spawnOwned) {
            sendAction('spawnVehicleOwned', { vehicleModel: selectedVehicle.model });
        } else {
            sendAction('spawnVehicle', { vehicleModel: selectedVehicle.model });
        }
    } else {
        // Spawn for another player
        if (!targetId || targetId < 1) {
            alert('Please enter a valid player server ID');
            return;
        }
        
        if (spawnOwned) {
            sendAction('giveVehicleOwned', { 
                targetId: parseInt(targetId), 
                vehicleModel: selectedVehicle.model 
            });
        } else {
            sendAction('giveVehicleTemp', { 
                targetId: parseInt(targetId), 
                vehicleModel: selectedVehicle.model 
            });
        }
    }
    
    closeVehicleModal();
}

// Vehicle search filter
function filterVehicles(search) {
    const searchLower = search.toLowerCase();
    const allCards = document.querySelectorAll('.vehicle-card');
    
    allCards.forEach(card => {
        const name = card.querySelector('.vehicle-card-name').textContent.toLowerCase();
        const brand = card.querySelector('.vehicle-card-brand').textContent.toLowerCase();
        const model = card.querySelector('.vehicle-card-model').textContent.toLowerCase();
        
        const matches = name.includes(searchLower) || 
                       brand.includes(searchLower) || 
                       model.includes(searchLower);
        
        card.style.display = matches ? 'block' : 'none';
    });
}

// ============================================
// JOB MODAL FUNCTIONS
// ============================================

let jobsData = [];
let currentJobPlayerId = null;

// Open job selection modal
function openJobModal(jobs, playerId) {
    jobsData = jobs;
    currentJobPlayerId = playerId;
    
    const jobSelect = document.getElementById('jobSelect');
    const gradeSelect = document.getElementById('gradeSelect');
    const jobModal = document.getElementById('jobModal');
    
    if (!jobSelect || !gradeSelect || !jobModal) {
        console.error('[Admin UI] Job modal elements not found');
        return;
    }
    
    // Clear existing options
    jobSelect.innerHTML = '<option value="">-- Choose a job --</option>';
    gradeSelect.innerHTML = '<option value="">-- Select a job first --</option>';
    gradeSelect.disabled = true;
    
    // Populate jobs dropdown
    jobs.forEach(job => {
        const option = document.createElement('option');
        option.value = job.name;
        option.textContent = job.label;
        option.dataset.jobData = JSON.stringify(job);
        jobSelect.appendChild(option);
    });
    
    // Reset and show modal
    const jobInfo = document.getElementById('jobInfo');
    if (jobInfo) jobInfo.style.display = 'none';
    
    const submitBtn = document.getElementById('submitJobBtn');
    if (submitBtn) submitBtn.disabled = true;
    
    jobModal.classList.add('show');
    DEBUG && console.log('[Admin UI] Job modal opened with', jobs.length, 'jobs');
}

// Update grade dropdown when job is selected
function updateGradeDropdown() {
    const jobSelect = document.getElementById('jobSelect');
    const gradeSelect = document.getElementById('gradeSelect');
    const jobInfo = document.getElementById('jobInfo');
    const submitBtn = document.getElementById('submitJobBtn');
    
    if (!jobSelect || !gradeSelect) return;
    
    const selectedOption = jobSelect.options[jobSelect.selectedIndex];
    
    if (!selectedOption || !selectedOption.value) {
        gradeSelect.innerHTML = '<option value="">-- Select a job first --</option>';
        gradeSelect.disabled = true;
        if (jobInfo) jobInfo.style.display = 'none';
        if (submitBtn) submitBtn.disabled = true;
        return;
    }
    
    const jobData = JSON.parse(selectedOption.dataset.jobData);
    
    // Clear and enable grade select
    gradeSelect.innerHTML = '<option value="">-- Choose a grade --</option>';
    gradeSelect.disabled = false;
    
    // Populate grades
    jobData.grades.forEach(grade => {
        const option = document.createElement('option');
        option.value = grade.level;
        option.textContent = `${grade.level} - ${grade.name} ($${grade.payment})`;
        option.dataset.gradeData = JSON.stringify(grade);
        gradeSelect.appendChild(option);
    });
    
    // Show job info
    if (jobInfo) {
        const jobType = document.getElementById('jobType');
        if (jobType) {
            jobType.textContent = jobData.type.toUpperCase();
        }
        jobInfo.style.display = 'block';
    }
    
    DEBUG && console.log('[Admin UI] Loaded', jobData.grades.length, 'grades for job:', jobData.label);
}

// Update payment display when grade is selected
function updatePaymentInfo() {
    const gradeSelect = document.getElementById('gradeSelect');
    const jobPayment = document.getElementById('jobPayment');
    const submitBtn = document.getElementById('submitJobBtn');
    
    if (!gradeSelect) return;
    
    const selectedOption = gradeSelect.options[gradeSelect.selectedIndex];
    
    if (selectedOption && selectedOption.value && selectedOption.dataset.gradeData) {
        const gradeData = JSON.parse(selectedOption.dataset.gradeData);
        if (jobPayment) {
            jobPayment.textContent = gradeData.payment;
        }
        if (submitBtn) {
            submitBtn.disabled = false;
        }
    } else {
        if (submitBtn) {
            submitBtn.disabled = true;
        }
    }
}

// Add event listener for grade selection
document.addEventListener('DOMContentLoaded', () => {
    const gradeSelect = document.getElementById('gradeSelect');
    if (gradeSelect) {
        gradeSelect.addEventListener('change', updatePaymentInfo);
    }
});

// Close job modal
function closeJobModal() {
    const modal = document.getElementById('jobModal');
    if (modal) {
        modal.classList.remove('show');
    }
    currentJobPlayerId = null;
}

// Submit job change
function submitJobChange() {
    const jobSelect = document.getElementById('jobSelect');
    const gradeSelect = document.getElementById('gradeSelect');
    
    if (!jobSelect || !gradeSelect || !currentJobPlayerId) {
        console.error('[Admin UI] Missing required data for job change');
        return;
    }
    
    const selectedJob = jobSelect.value;
    const selectedGrade = parseInt(gradeSelect.value);
    
    if (!selectedJob || isNaN(selectedGrade)) {
        alert('Please select both a job and a grade');
        return;
    }
    
    DEBUG && console.log('[Admin UI] Setting job:', selectedJob, 'grade:', selectedGrade, 'for player:', currentJobPlayerId);
    
    sendAction('submitJobChange', {
        playerId: currentJobPlayerId,
        job: selectedJob,
        grade: selectedGrade
    });
    
    closeJobModal();
}

// ============================================
// GIVE MONEY MODAL FUNCTIONS
// ============================================

function openGiveMoneyModal(playerId) {
    currentMoneyPlayerId = Number(playerId) || null;

    const modal = document.getElementById('giveMoneyModal');
    const playerIdInput = document.getElementById('giveMoneyPlayerId');
    const amountInput = document.getElementById('giveMoneyAmount');
    const typeSelect = document.getElementById('giveMoneyType');

    if (!modal || !playerIdInput || !amountInput || !typeSelect) {
        console.error('[Admin UI] Give money modal elements not found');
        return;
    }

    playerIdInput.value = currentMoneyPlayerId || '';
    amountInput.value = '';
    typeSelect.value = 'cash';

    modal.classList.add('show');
    amountInput.focus();
}

function closeGiveMoneyModal() {
    const modal = document.getElementById('giveMoneyModal');
    if (modal) {
        modal.classList.remove('show');
    }
    currentMoneyPlayerId = null;
}

function submitGiveMoney() {
    const playerIdInput = document.getElementById('giveMoneyPlayerId');
    const amountInput = document.getElementById('giveMoneyAmount');
    const typeSelect = document.getElementById('giveMoneyType');

    if (!playerIdInput || !amountInput || !typeSelect) {
        console.error('[Admin UI] Give money form elements not found');
        return;
    }

    const playerId = Number(playerIdInput.value);
    const amount = Number(amountInput.value);
    const moneyType = typeSelect.value;

    if (!playerId || playerId < 1) {
        alert('Please enter a valid Player ID.');
        return;
    }

    if (!amount || amount < 1) {
        alert('Please enter a valid amount greater than 0.');
        return;
    }

    if (moneyType !== 'cash' && moneyType !== 'bank') {
        alert('Please select a valid account type.');
        return;
    }

    sendAction('giveMoney', {
        playerId,
        moneyType,
        amount: Math.floor(amount)
    });

    closeGiveMoneyModal();
}

// ========================
// REPORT SYSTEM FUNCTIONS
// ========================

// Open report submission modal (for players)
function openReportModal() {
    const reportModal = document.getElementById('reportModal');
    const reportMessage = document.getElementById('reportMessage');
    const charCount = document.getElementById('reportCharCount');
    
    if (!reportModal || !reportMessage) return;
    
    // Reset form
    reportMessage.value = '';
    charCount.textContent = '0';
    
    // Add character counter listener
    reportMessage.oninput = function() {
        charCount.textContent = this.value.length;
    };
    
    reportModal.classList.add('show');
    DEBUG && console.log('[Admin UI] Report modal opened');
}

// Close report submission modal
function closeReportModal() {
    const reportModal = document.getElementById('reportModal');
    if (reportModal) {
        reportModal.classList.remove('show');
        DEBUG && console.log('[Admin UI] Report modal closed');
        
        // Notify client that modal was closed
        sendAction('closeReportModal', {});
    }
}

// Submit a new report
function submitReport() {
    const reportMessage = document.getElementById('reportMessage');
    
    if (!reportMessage) {
        console.error('[Admin UI] Report message field not found');
        return;
    }
    
    const message = reportMessage.value.trim();
    
    // Validate message length (minimum 10, maximum 500)
    if (message.length < 10) {
        alert('Report message must be at least 10 characters long');
        return;
    }
    
    if (message.length > 500) {
        alert('Report message cannot exceed 500 characters');
        return;
    }
    
    DEBUG && console.log('[Admin UI] Submitting report:', message);
    
    // Send to client
    sendAction('submitReport', { message: message });
    
    // Close modal
    closeReportModal();
}

// Request reports list from server
function requestReports(filter = 'all') {
    DEBUG && console.log('[Admin UI] Requesting reports with filter:', filter);
    currentReportFilter = filter;
    sendAction('requestReports', { filter: filter });
}

// Display reports in the reports tab
function displayReports(reports) {
    reportsList = Array.isArray(reports) ? reports.filter(r => r && typeof r === 'object') : [];
    DEBUG && console.log('[Admin UI] Displaying', reportsList.length, 'reports');
    
    const reportsContainer = document.getElementById('reportsList');
    if (!reportsContainer) {
        console.error('[Admin UI] Reports container not found');
        return;
    }
    
    // Update badge count (only open reports)
    const openReports = reportsList.filter(r => r.status === 'open');
    updateReportBadge(openReports.length);
    
    // Clear existing content
    reportsContainer.innerHTML = '';
    
    // Filter reports based on current filter
    let filteredReports = reportsList;
    if (currentReportFilter === 'open') {
        filteredReports = reportsList.filter(r => r.status === 'open');
    } else if (currentReportFilter === 'resolved') {
        filteredReports = reportsList.filter(r => r.status === 'resolved');
    }
    
    // Show empty state if no reports
    if (filteredReports.length === 0) {
        reportsContainer.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-inbox fa-3x"></i>
                <h3>No ${currentReportFilter === 'all' ? '' : currentReportFilter} reports</h3>
                <p>Reports submitted by players will appear here</p>
            </div>
        `;
        return;
    }
    
    // Create report cards
    filteredReports.forEach(report => {
        const reportId = Number(report.id) || 0;
        const reportStatus = report.status === 'resolved' ? 'resolved' : 'open';
        const reportMessage = typeof report.message === 'string' ? report.message : '';
        const reportPlayerName = report.playerName || 'Unknown';
        const reportPlayerId = report.playerId ?? 'N/A';
        const reportTimestamp = Number(report.timestamp) || Math.floor(Date.now() / 1000);

        const reportCard = document.createElement('div');
        reportCard.className = 'report-card';
        reportCard.onclick = () => viewReport(reportId);
        
        const statusClass = reportStatus === 'open' ? 'status-open' : 'status-resolved';
        const statusIcon = reportStatus === 'open' ? 'fa-exclamation-circle' : 'fa-check-circle';
        
        // Format timestamp
        const date = new Date(reportTimestamp * 1000); // Convert seconds to milliseconds
        const timeString = date.toLocaleString();
        
        // Truncate message if too long
        let displayMessage = reportMessage;
        if (displayMessage.length > 100) {
            displayMessage = displayMessage.substring(0, 100) + '...';
        }
        
        reportCard.innerHTML = `
            <div class="report-header">
                <div class="report-id">#${reportId}</div>
                <div class="report-status ${statusClass}">
                    <i class="fas ${statusIcon}"></i> ${reportStatus.toUpperCase()}
                </div>
            </div>
            <div class="report-player">
                <i class="fas fa-user"></i> ${reportPlayerName} (ID: ${reportPlayerId})
            </div>
            <div class="report-message-preview">
                ${displayMessage}
            </div>
            <div class="report-time">
                <i class="fas fa-clock"></i> ${timeString}
            </div>
            ${report.resolvedBy ? `<div class="report-resolved-by">Resolved by ${report.resolvedBy}</div>` : ''}
        `;
        
        reportsContainer.appendChild(reportCard);
    });
}

// Filter reports
function filterReports(status) {
    DEBUG && console.log('[Admin UI] Filtering reports:', status);
    currentReportFilter = status;
    
    // Update filter buttons
    const filterButtons = document.querySelectorAll('.reports-filter button');
    filterButtons.forEach(btn => {
        btn.classList.remove('active');
        if (btn.textContent.toLowerCase().includes(status)) {
            btn.classList.add('active');
        }
    });
    
    // Re-display with current filter
    displayReports(reportsList);
}

// View full report details
function viewReport(reportId) {
    const normalizedId = Number(reportId);
    const report = reportsList.find(r => Number(r.id) === normalizedId);
    if (!report) {
        console.error('[Admin UI] Report not found:', reportId);
        return;
    }
    
    DEBUG && console.log('[Admin UI] Viewing report:', normalizedId);
    selectedReportId = normalizedId;
    
    const reportViewModal = document.getElementById('reportViewModal');
    if (!reportViewModal) return;
    
    // Populate modal with report data
    document.getElementById('viewReportId').textContent = '#' + (report.id ?? normalizedId);
    document.getElementById('viewReportPlayer').textContent = `${report.playerName} (ID: ${report.playerId})`;
    
    const statusElement = document.getElementById('viewReportStatus');
    const statusClass = report.status === 'open' ? 'status-open' : 'status-resolved';
    const statusIcon = report.status === 'open' ? 'fa-exclamation-circle' : 'fa-check-circle';
    statusElement.innerHTML = `<span class="${statusClass}"><i class="fas ${statusIcon}"></i> ${report.status.toUpperCase()}</span>`;
    
    const date = new Date(report.timestamp * 1000); // Convert seconds to milliseconds
    document.getElementById('viewReportTime').textContent = date.toLocaleString();
    document.getElementById('viewReportMessage').textContent = report.message || '';
    
    // Show/hide resolved by info
    const resolvedByRow = document.getElementById('viewResolvedByRow');
    if (report.resolvedBy) {
        document.getElementById('viewResolvedBy').textContent = report.resolvedBy;
        resolvedByRow.style.display = 'flex';
    } else {
        resolvedByRow.style.display = 'none';
    }
    
    // Show/hide action buttons based on status
    const resolveBtn = document.getElementById('resolveReportBtn');
    if (report.status === 'resolved') {
        resolveBtn.style.display = 'none';
    } else {
        resolveBtn.style.display = 'inline-block';
    }
    
    reportViewModal.classList.add('show');
}

// Close report view modal
function closeReportViewModal() {
    const reportViewModal = document.getElementById('reportViewModal');
    if (reportViewModal) {
        reportViewModal.classList.remove('show');
        selectedReportId = null;
        const resolveBtn = document.getElementById('resolveReportBtn');
        if (resolveBtn) resolveBtn.disabled = false;
        DEBUG && console.log('[Admin UI] Report view modal closed');
    }
}

// Resolve a report
function resolveReportById() {
    const reportId = Number(selectedReportId);
    if (!reportId) {
        console.error('[Admin UI] No report selected');
        return;
    }

    closeReportViewModal()

    DEBUG && console.log('[Admin UI] Resolving report:', reportId);

    try {
        sendAction('resolveReport', { reportId });

        reportsList = reportsList.map(report => {
            if (Number(report.id) === reportId) {
                report.status = 'resolved';
            }
            return report;
        });
        displayReports(reportsList);
    } catch (err) {
        console.error('[Admin UI] Resolve report error:', err);
    }

    setTimeout(() => requestReports(currentReportFilter), 250);
}

// Update report badge count
function updateReportBadge(count) {
    const badge = document.getElementById('reportBadge');
    if (badge) {
        badge.textContent = count;
        badge.style.display = count > 0 ? 'inline-block' : 'none';
        DEBUG && console.log('[Admin UI] Updated report badge:', count);
    }
}

// ============================================== 
// Entity Info Overlay Functions
// ==============================================

let currentEntityData = null;

function updateEntityInfo(entityData) {
    if (!entityData) return;
    
    currentEntityData = entityData;
    const overlay = document.getElementById('entityInfoOverlay');
    
    if (overlay) {
        overlay.style.display = 'block';
        overlay.classList.add('show');
        
        // Update entity type
        const typeElement = document.getElementById('entityType');
        if (typeElement) {
            const typeIcon = entityData.type === 'Vehicle' ? '🚗' : 
                           entityData.type === 'Ped' ? '🚶' : 
                           entityData.type === 'Object' ? '📦' : '❓';
            typeElement.textContent = `${typeIcon} ${entityData.type}`;
        }
        
        // Update model
        const modelElement = document.getElementById('entityModel');
        if (modelElement) modelElement.textContent = entityData.model || '-';
        
        // Update hash
        const hashElement = document.getElementById('entityHash');
        if (hashElement) hashElement.textContent = entityData.hash || '-';
        
        // Update coords
        const coordsElement = document.getElementById('entityCoords');
        if (coordsElement && entityData.coords) {
            coordsElement.textContent = `${entityData.coords.x.toFixed(2)}, ${entityData.coords.y.toFixed(2)}, ${entityData.coords.z.toFixed(2)}`;
        }
        
        // Update heading
        const headingElement = document.getElementById('entityHeading');
        if (headingElement) headingElement.textContent = entityData.heading ? `${entityData.heading.toFixed(2)}°` : '-';
        
        // Update network
        const networkElement = document.getElementById('entityNetwork');
        if (networkElement) {
            networkElement.textContent = entityData.netId ? `Net ID: ${entityData.netId}` : 'Local Entity';
        }
    }
}

function hideEntityInfo() {
    const overlay = document.getElementById('entityInfoOverlay');
    if (overlay) {
        overlay.style.display = 'none';
        overlay.classList.remove('show');
    }
    currentEntityData = null;
}

function copyEntityInfo() {
    if (!currentEntityData) return;
    
    const text = `Entity Information:
Type: ${currentEntityData.type}
Model: ${currentEntityData.model}
Hash: ${currentEntityData.hash}
Coords: vector3(${currentEntityData.coords.x.toFixed(2)}, ${currentEntityData.coords.y.toFixed(2)}, ${currentEntityData.coords.z.toFixed(2)})
Heading: ${currentEntityData.heading ? currentEntityData.heading.toFixed(2) : '0.00'}
Network ID: ${currentEntityData.netId || 'N/A'}`;
    
    // navigator.clipboard is blocked in FiveM NUI (no HTTPS context)
    // Use execCommand fallback which works in CEF/NUI
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.cssText = 'position:fixed;top:-9999px;left:-9999px;opacity:0;';
    document.body.appendChild(ta);
    ta.focus();
    ta.select();
    const success = document.execCommand('copy');
    document.body.removeChild(ta);

    if (success) {
        const btn = document.querySelector('.entity-copy-btn');
        if (btn) {
            const originalHTML = btn.innerHTML;
            btn.innerHTML = '<i class="fas fa-check"></i> Copied!';
            btn.style.background = 'rgba(40, 167, 69, 0.3)';
            btn.style.borderColor = '#28a745';
            btn.style.color = '#28a745';
            setTimeout(() => {
                btn.innerHTML = originalHTML;
                btn.style.background = '';
                btn.style.borderColor = '';
                btn.style.color = '';
            }, 2000);
        }
    } else {
        console.error('[Admin UI] execCommand copy failed');
    }
}
