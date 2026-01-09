/**
 * Nexus Connection Manager
 * Centralized connection state management with caching and WiFi detection
 */
const NexusConnection = {
    state: {
        internetAvailable: null,    // null = unknown, true/false = checked
        iservAvailable: null,
        isSchoolNetwork: false,     // True if on WERDER-EHG (IServ only, no internet)
        lastCheck: null,
        checkInProgress: false
    },

    SCHOOL_WIFI_NAME: 'WERDER-EHG',
    CACHE_KEY: 'nexus_connection_state',
    SESSION_KEY: 'nexus_session_started',
    CACHE_DURATION: 60000,  // 1 minute cache
    PING_TIMEOUT: 500,      // 500ms max for ping

    /**
     * Initialize connection manager
     * Only performs connectivity check on fresh session
     */
    async init() {
        // Load cached state from sessionStorage
        this.loadCachedState();

        // Check if this is a fresh session or tab navigation
        const isInitialLoad = !sessionStorage.getItem(this.SESSION_KEY);

        if (isInitialLoad || !this.state.lastCheck) {
            sessionStorage.setItem(this.SESSION_KEY, 'true');
            await this.checkConnectivity();
        }

        // Dispatch ready event
        window.dispatchEvent(new CustomEvent('nexus-connection-ready', {
            detail: this.state
        }));

        return this.state;
    },

    /**
     * Load cached connection state from sessionStorage
     */
    loadCachedState() {
        try {
            const cached = sessionStorage.getItem(this.CACHE_KEY);
            if (cached) {
                const parsed = JSON.parse(cached);
                const age = Date.now() - parsed.lastCheck;
                if (age < this.CACHE_DURATION) {
                    Object.assign(this.state, parsed);
                    return true;
                }
            }
        } catch (e) {
            console.warn('Failed to load cached connection state:', e);
        }
        return false;
    },

    /**
     * Save current state to sessionStorage
     */
    saveState() {
        this.state.lastCheck = Date.now();
        try {
            sessionStorage.setItem(this.CACHE_KEY, JSON.stringify(this.state));
        } catch (e) {
            console.warn('Failed to save connection state:', e);
        }
    },

    /**
     * Check connectivity with fast parallel pings
     */
    async checkConnectivity() {
        if (this.state.checkInProgress) return this.state;
        this.state.checkInProgress = true;

        try {
            // Fast parallel checks with short timeouts
            const [internet, iserv] = await Promise.allSettled([
                this.checkInternet(),
                this.checkIServ()
            ]);

            this.state.internetAvailable = internet.status === 'fulfilled' && internet.value;
            this.state.iservAvailable = iserv.status === 'fulfilled' && iserv.value;

            // Detect school network: IServ works but internet doesn't
            // This happens when connected to WERDER-EHG WiFi
            this.state.isSchoolNetwork = this.state.iservAvailable && !this.state.internetAvailable;

            this.saveState();
        } catch (e) {
            console.error('Connection check failed:', e);
        } finally {
            this.state.checkInProgress = false;
        }

        return this.state;
    },

    /**
     * Fast internet connectivity check via local ping endpoint
     */
    async checkInternet() {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.PING_TIMEOUT);

        try {
            const response = await fetch('/api/ping', {
                method: 'HEAD',
                signal: controller.signal,
                cache: 'no-store'
            });
            clearTimeout(timeoutId);
            return response.ok;
        } catch {
            clearTimeout(timeoutId);
            return false;
        }
    },

    /**
     * Fast IServ availability check
     */
    async checkIServ() {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.PING_TIMEOUT);

        try {
            const response = await fetch('/api/iserv/ping', {
                method: 'HEAD',
                signal: controller.signal,
                cache: 'no-store'
            });
            clearTimeout(timeoutId);
            return response.ok;
        } catch {
            clearTimeout(timeoutId);
            return false;
        }
    },

    /**
     * Check if external APIs should be called (weather, etc.)
     * Returns false if on school network or offline
     */
    shouldCallExternalAPI() {
        return this.state.internetAvailable === true && !this.state.isSchoolNetwork;
    },

    /**
     * Check if IServ calls should be made
     */
    shouldCallIServ() {
        return this.state.iservAvailable === true;
    },

    /**
     * Check if we're on the school network (WERDER-EHG)
     */
    isOnSchoolNetwork() {
        return this.state.isSchoolNetwork;
    },

    /**
     * Check if we're fully offline
     */
    isOffline() {
        return !this.state.internetAvailable && !this.state.iservAvailable;
    },

    /**
     * Force refresh connectivity check
     */
    async refresh() {
        this.state.lastCheck = null;
        return this.checkConnectivity();
    },

    /**
     * Get human-readable connection status
     */
    getStatusText() {
        if (this.isOffline()) {
            return 'Offline';
        } else if (this.state.isSchoolNetwork) {
            return 'Schulnetzwerk (nur IServ)';
        } else if (this.state.internetAvailable) {
            return 'Online';
        }
        return 'Verbindung wird geprüft...';
    }
};

// Export for module usage if needed
if (typeof module !== 'undefined' && module.exports) {
    module.exports = NexusConnection;
}
