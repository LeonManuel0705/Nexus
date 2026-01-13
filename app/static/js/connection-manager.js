
const NexusConnection = {
    state: {
        internetAvailable: null,
        iservAvailable: null,
        isSchoolNetwork: false,
        lastCheck: null,
        checkInProgress: false
    },

    SCHOOL_WIFI_NAME: 'WERDER-EHG',
    CACHE_KEY: 'nexus_connection_state',
    SESSION_KEY: 'nexus_session_started',
    CACHE_DURATION: 60000,
    PING_TIMEOUT: 500,

    async init() {

        this.loadCachedState();

        const isInitialLoad = !sessionStorage.getItem(this.SESSION_KEY);

        if (isInitialLoad || !this.state.lastCheck) {
            sessionStorage.setItem(this.SESSION_KEY, 'true');
            await this.checkConnectivity();
        }

        window.dispatchEvent(new CustomEvent('nexus-connection-ready', {
            detail: this.state
        }));

        return this.state;
    },

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

    saveState() {
        this.state.lastCheck = Date.now();
        try {
            sessionStorage.setItem(this.CACHE_KEY, JSON.stringify(this.state));
        } catch (e) {
            console.warn('Failed to save connection state:', e);
        }
    },

    async checkConnectivity() {
        if (this.state.checkInProgress) return this.state;
        this.state.checkInProgress = true;

        try {

            const [internet, iserv] = await Promise.allSettled([
                this.checkInternet(),
                this.checkIServ()
            ]);

            this.state.internetAvailable = internet.status === 'fulfilled' && internet.value;
            this.state.iservAvailable = iserv.status === 'fulfilled' && iserv.value;

            this.state.isSchoolNetwork = this.state.iservAvailable && !this.state.internetAvailable;

            this.saveState();
        } catch (e) {
            console.error('Connection check failed:', e);
        } finally {
            this.state.checkInProgress = false;
        }

        return this.state;
    },

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

    shouldCallExternalAPI() {
        return this.state.internetAvailable === true && !this.state.isSchoolNetwork;
    },

    shouldCallIServ() {
        return this.state.iservAvailable === true;
    },

    isOnSchoolNetwork() {
        return this.state.isSchoolNetwork;
    },

    isOffline() {
        return !this.state.internetAvailable && !this.state.iservAvailable;
    },

    async refresh() {
        this.state.lastCheck = null;
        return this.checkConnectivity();
    },

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

if (typeof module !== 'undefined' && module.exports) {
    module.exports = NexusConnection;
}
