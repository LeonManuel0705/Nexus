/**
 * Nexus Hub Application
 * Life management dashboard
 */

// ==========================================
// TRANSLATIONS (du-form German)
// ==========================================

const translations = {
    en: {
        // Navigation
        nav_home: 'Home',
        nav_tasks: 'Tasks',
        nav_calendar: 'Calendar',
        nav_notes: 'Notes',
        nav_bookmarks: 'Bookmarks',
        nav_email: 'Email',
        nav_settings: 'Settings',

        // Home
        weather: 'Weather',
        quick_access: 'Quick Access',
        apps: 'Apps',
        email: 'Email',
        pomodoro: 'Pomodoro',

        // Tasks
        tasks: 'Tasks',
        tasks_subtitle: 'Stay organized',
        all: 'All',
        today: 'Today',
        pending: 'Pending',
        add_task_placeholder: 'Add a task...',
        add_task: 'Add Task',
        edit_task: 'Edit Task',
        task_title: 'Title',
        due_date: 'Due Date',
        priority: 'Priority',
        priority_high: 'High',
        priority_medium: 'Medium',
        priority_low: 'Low',
        delete: 'Delete',
        save: 'Save',
        no_tasks: 'No tasks',

        // Calendar
        calendar: 'Calendar',
        calendar_subtitle: 'Your schedule at a glance',
        upcoming_events: 'Upcoming Events',
        add_event: 'Add Event',
        edit_event: 'Edit Event',
        event_title: 'Title',
        date: 'Date',
        time: 'Time',
        description: 'Description',
        no_events: 'No upcoming events',
        calendar_no_access: 'Calendar access needed. Grant permission in System Settings → Privacy & Security → Calendars.',
        calendar_connect_google: 'Connect your Google account in Email to sync your calendar.',
        calendar_reauth_needed: 'Calendar access not granted. Please sign out and sign in again in Email settings.',

        // Notes
        notes: 'Notes',
        notes_subtitle: 'Quick notes and thoughts',
        words: 'words',
        start_typing: 'Start typing...',
        delete_note: 'Delete note',
        rename_note: 'Rename note:',
        cannot_delete_last: 'Cannot delete the last note',

        // Bookmarks
        bookmarks: 'Bookmarks',
        bookmarks_subtitle: 'Your saved links',
        add_bookmark: 'Add Bookmark',
        edit_bookmark: 'Edit Bookmark',
        bookmark_title: 'Title',
        bookmark_url: 'URL',
        category: 'Category',
        no_bookmarks: 'No bookmarks yet. Click + to add one.',

        // Pomodoro
        pomodoro_title: 'Pomodoro Timer',
        sessions_today: 'sessions today',
        session_today: 'session today',
        ready: 'Ready',
        working: 'Working...',
        break_time: 'Break time!',
        paused: 'Paused',
        how_it_works: 'How it works',
        work_focus: 'Work for 25 minutes with full focus',
        take_break: 'Take a 5-minute break',
        repeat_track: 'Repeat and track your sessions',
        timer_settings: 'Timer Settings',
        work_duration: 'Work Duration (min)',
        break_duration: 'Break Duration (min)',

        // Email
        email_subtitle: 'Your connected email accounts',
        no_email_accounts: 'No email accounts connected. Click + to add one.',
        loading_emails: 'Loading emails...',
        back: 'Back',
        add_email_account: 'Add Email Account',
        email_address: 'Email Address',
        password: 'Password / App Password',
        provider: 'Provider',
        gmail_hint: 'For Gmail, use an App Password (Google Account > Security > App Passwords)',
        imap_hint: 'For Outlook/Hotmail, use your regular password. For Gmail, you need an App Password.',
        add_account: 'Add Account',
        compose_email: 'Compose Email',
        to: 'To',
        subject: 'Subject',
        message: 'Message',
        cancel: 'Cancel',
        send: 'Send',
        from: 'From',
        no_emails: 'No emails found',
        sign_in_google: 'Sign in with Google',
        google_oauth_hint: 'Recommended for Gmail - uses secure Google login',
        google_auth_title: 'Google Sign-In',
        google_auth_step1: '1. Click the button below to open Google Sign-In:',
        google_auth_step2: '2. Sign in and authorize access, then copy the code shown:',
        open_google_signin: 'Open Google Sign-In',
        connect_account: 'Connect Account',
        or: 'or',

        // Settings
        settings: 'Settings',
        settings_subtitle: 'Configure your Nexus hub',
        appearance: 'Appearance',
        switch_dark: 'Switch to Dark Mode',
        switch_light: 'Switch to Light Mode',
        weather_location: 'Weather Location',
        current_location: 'Current Location',
        not_set: 'Not set',
        change_location: 'Change Location',
        auto_detect: 'Auto-detect',
        data_backup: 'Data Backup',
        backup_description: 'Export your tasks, notes, bookmarks, and settings to a JSON file, or import from a backup.',
        export_data: 'Export Data',
        import_data: 'Import Data',
        clear_data: 'Clear Data',
        clear_warning: 'Warning: This will permanently delete all your local data.',
        clear_all: 'Clear All Data',
        confirm_clear: 'Are you sure you want to delete all data? This cannot be undone.',
        set_location: 'Set Your Location',
        enter_city: 'Could not auto-detect your location. Please enter your city:',
        city: 'City',
        save_location: 'Save Location',
        about_nexus: 'About Nexus',
        about_description: 'Your personal life management hub',
        about_features: 'Manage tasks, calendar, notes, and more - all in one place.',
        about_storage: 'All data is stored locally in your browser.',

        // Common
        loading: 'Loading...',
        error: 'Error',
        offline: 'Offline',
        showing_cached: 'Showing cached emails (offline)',
        just_now: 'Just now',
        ago: 'ago'
    },
    de: {
        // Navigation
        nav_home: 'Start',
        nav_tasks: 'Aufgaben',
        nav_calendar: 'Kalender',
        nav_notes: 'Notizen',
        nav_bookmarks: 'Lesezeichen',
        nav_email: 'E-Mail',
        nav_settings: 'Einstellungen',

        // Home
        weather: 'Wetter',
        quick_access: 'Schnellzugriff',
        apps: 'Apps',
        email: 'E-Mail',
        pomodoro: 'Pomodoro',

        // Tasks
        tasks: 'Aufgaben',
        tasks_subtitle: 'Bleib organisiert',
        all: 'Alle',
        today: 'Heute',
        pending: 'Offen',
        add_task_placeholder: 'Aufgabe hinzufügen...',
        add_task: 'Aufgabe hinzufügen',
        edit_task: 'Aufgabe bearbeiten',
        task_title: 'Titel',
        due_date: 'Fälligkeitsdatum',
        priority: 'Priorität',
        priority_high: 'Hoch',
        priority_medium: 'Mittel',
        priority_low: 'Niedrig',
        delete: 'Löschen',
        save: 'Speichern',
        no_tasks: 'Keine Aufgaben',

        // Calendar
        calendar: 'Kalender',
        calendar_subtitle: 'Dein Terminplan auf einen Blick',
        upcoming_events: 'Kommende Termine',
        add_event: 'Termin hinzufügen',
        edit_event: 'Termin bearbeiten',
        event_title: 'Titel',
        date: 'Datum',
        time: 'Uhrzeit',
        description: 'Beschreibung',
        no_events: 'Keine kommenden Termine',
        calendar_no_access: 'Kalenderzugriff benötigt. Erteile die Berechtigung in Systemeinstellungen → Datenschutz & Sicherheit → Kalender.',
        calendar_connect_google: 'Verbinde dein Google-Konto unter E-Mail, um deinen Kalender zu synchronisieren.',
        calendar_reauth_needed: 'Kalenderzugriff nicht erteilt. Bitte melde dich ab und wieder an in den E-Mail-Einstellungen.',

        // Notes
        notes: 'Notizen',
        notes_subtitle: 'Schnelle Notizen und Gedanken',
        words: 'Wörter',
        start_typing: 'Schreib los...',
        delete_note: 'Notiz löschen',
        rename_note: 'Notiz umbenennen:',
        cannot_delete_last: 'Du kannst die letzte Notiz nicht löschen',

        // Bookmarks
        bookmarks: 'Lesezeichen',
        bookmarks_subtitle: 'Deine gespeicherten Links',
        add_bookmark: 'Lesezeichen hinzufügen',
        edit_bookmark: 'Lesezeichen bearbeiten',
        bookmark_title: 'Titel',
        bookmark_url: 'URL',
        category: 'Kategorie',
        no_bookmarks: 'Noch keine Lesezeichen. Klick auf + um eins hinzuzufügen.',

        // Pomodoro
        pomodoro_title: 'Pomodoro-Timer',
        sessions_today: 'Sitzungen heute',
        session_today: 'Sitzung heute',
        ready: 'Bereit',
        working: 'Am Arbeiten...',
        break_time: 'Pause!',
        paused: 'Pausiert',
        how_it_works: 'So funktioniert es',
        work_focus: 'Arbeite 25 Minuten mit voller Konzentration',
        take_break: 'Mach eine 5-Minuten-Pause',
        repeat_track: 'Wiederhole und verfolge deine Sitzungen',
        timer_settings: 'Timer-Einstellungen',
        work_duration: 'Arbeitszeit (Min)',
        break_duration: 'Pausenzeit (Min)',

        // Email
        email_subtitle: 'Deine verbundenen E-Mail-Konten',
        no_email_accounts: 'Keine E-Mail-Konten verbunden. Klick auf + um eins hinzuzufügen.',
        loading_emails: 'Lade E-Mails...',
        back: 'Zurück',
        add_email_account: 'E-Mail-Konto hinzufügen',
        email_address: 'E-Mail-Adresse',
        password: 'Passwort / App-Passwort',
        provider: 'Anbieter',
        gmail_hint: 'Für Gmail brauchst du ein App-Passwort (Google-Konto > Sicherheit > App-Passwörter)',
        imap_hint: 'Für Outlook/Hotmail verwendest du dein normales Passwort. Für Gmail brauchst du ein App-Passwort.',
        add_account: 'Konto hinzufügen',
        compose_email: 'E-Mail schreiben',
        to: 'An',
        subject: 'Betreff',
        message: 'Nachricht',
        cancel: 'Abbrechen',
        send: 'Senden',
        from: 'Von',
        no_emails: 'Keine E-Mails gefunden',
        sign_in_google: 'Mit Google anmelden',
        google_oauth_hint: 'Empfohlen für Gmail - nutzt sichere Google-Anmeldung',
        google_auth_title: 'Google-Anmeldung',
        google_auth_step1: '1. Klick auf den Button unten um die Google-Anmeldung zu öffnen:',
        google_auth_step2: '2. Melde dich an und erlaube den Zugriff, dann kopiere den angezeigten Code:',
        open_google_signin: 'Google-Anmeldung öffnen',
        connect_account: 'Konto verbinden',
        or: 'oder',

        // Settings
        settings: 'Einstellungen',
        settings_subtitle: 'Konfiguriere deinen Nexus-Hub',
        appearance: 'Aussehen',
        switch_dark: 'Zu dunklem Modus wechseln',
        switch_light: 'Zu hellem Modus wechseln',
        weather_location: 'Wetter-Standort',
        current_location: 'Aktueller Standort',
        not_set: 'Nicht festgelegt',
        change_location: 'Standort ändern',
        auto_detect: 'Automatisch erkennen',
        data_backup: 'Datensicherung',
        backup_description: 'Exportiere deine Aufgaben, Notizen, Lesezeichen und Einstellungen in eine JSON-Datei, oder importiere aus einem Backup.',
        export_data: 'Daten exportieren',
        import_data: 'Daten importieren',
        clear_data: 'Daten löschen',
        clear_warning: 'Achtung: Dies löscht alle deine lokalen Daten dauerhaft.',
        clear_all: 'Alle Daten löschen',
        confirm_clear: 'Bist du sicher, dass du alle Daten löschen möchtest? Das kann nicht rückgängig gemacht werden.',
        set_location: 'Standort festlegen',
        enter_city: 'Dein Standort konnte nicht automatisch erkannt werden. Bitte gib deine Stadt ein:',
        city: 'Stadt',
        save_location: 'Standort speichern',
        about_nexus: 'Über Nexus',
        about_description: 'Dein persönlicher Lebensmanagement-Hub',
        about_features: 'Verwalte Aufgaben, Kalender, Notizen und mehr - alles an einem Ort.',
        about_storage: 'Alle Daten werden lokal in deinem Browser gespeichert.',

        // Common
        loading: 'Lädt...',
        error: 'Fehler',
        offline: 'Offline',
        showing_cached: 'Zeige gespeicherte E-Mails (offline)',
        just_now: 'Gerade eben',
        ago: 'her'
    }
};

const HubApp = {
    state: {
        theme: localStorage.getItem('hub_theme') || 'light',
        language: localStorage.getItem('hub_language') || 'en',
        currentDate: new Date(),
        viewDate: new Date(),
        events: JSON.parse(localStorage.getItem('hub_events') || '[]'),
        weather: JSON.parse(localStorage.getItem('hub_weather') || 'null'),
        location: JSON.parse(localStorage.getItem('hub_location') || 'null'),
        todos: JSON.parse(localStorage.getItem('hub_todos') || '[]'),
        notes: JSON.parse(localStorage.getItem('hub_notes') || '[{"id":"default","title":"Note 1","content":"","updatedAt":""}]'),
        activeNoteId: localStorage.getItem('hub_active_note') || 'default',
        bookmarks: JSON.parse(localStorage.getItem('hub_bookmarks') || '[]'),
        pomodoro: JSON.parse(localStorage.getItem('hub_pomodoro') || '{"workDuration":25,"breakDuration":5,"todaySessions":0,"lastSessionDate":""}'),
        editingEventId: null,
        editingTodoId: null,
        editingBookmarkId: null,
        todoFilter: 'all',
        isOnline: navigator.onLine,
        pomodoroTimer: null,
        pomodoroTimeLeft: 25 * 60,
        pomodoroIsWork: true,
        pomodoroRunning: false,
        macOSEvents: [],
        emailAccounts: [],
        currentEmailAccount: null,
        emails: [],
        currentEmail: null,
        currentEmailMsgId: null,
        googleCalendars: [],
        selectedCalendarAccount: null
    },

    // ==========================================
    // THEME
    // ==========================================

    initTheme() {
        document.body.setAttribute('data-theme', this.state.theme);
        this.updateThemeIcon();
    },

    updateThemeIcon() {
        const sunIcon = document.querySelector('.sun-icon');
        const moonIcon = document.querySelector('.moon-icon');
        if (sunIcon && moonIcon) {
            if (this.state.theme === 'dark') {
                sunIcon.classList.add('hidden');
                moonIcon.classList.remove('hidden');
            } else {
                sunIcon.classList.remove('hidden');
                moonIcon.classList.add('hidden');
            }
        }
    },

    toggleTheme() {
        this.state.theme = this.state.theme === 'dark' ? 'light' : 'dark';
        document.body.setAttribute('data-theme', this.state.theme);
        localStorage.setItem('hub_theme', this.state.theme);
        this.updateThemeIcon();
    },

    // ==========================================
    // TRANSLATION
    // ==========================================

    t(key) {
        const lang = this.state.language;
        return translations[lang]?.[key] || translations.en[key] || key;
    },

    initLanguage() {
        this.applyTranslations();
        this.updateLanguageButtons();
        document.getElementById('htmlRoot')?.setAttribute('lang', this.state.language);
    },

    setLanguage(lang) {
        this.state.language = lang;
        localStorage.setItem('hub_language', lang);
        this.applyTranslations();
        this.updateLanguageButtons();
        document.getElementById('htmlRoot')?.setAttribute('lang', lang);
    },

    updateLanguageButtons() {
        document.querySelectorAll('.lang-selector button').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.lang === this.state.language);
        });
    },

    applyTranslations() {
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            const translated = this.t(key);
            if (translated) {
                el.textContent = translated;
            }
        });

        // Update placeholders
        document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
            const key = el.getAttribute('data-i18n-placeholder');
            el.placeholder = this.t(key);
        });
    },

    // ==========================================
    // EMAIL
    // ==========================================

    async initEmail() {
        await this.loadEmailAccounts();
        this.renderEmailAccountsBar();
        if (this.state.emailAccounts.length > 0) {
            this.state.currentEmailAccount = this.state.emailAccounts[0].email;
            await this.loadEmails();
        }
        this.initEmailEventListeners();
    },

    async loadEmailAccounts() {
        try {
            const response = await fetch('/api/email/accounts');
            const data = await response.json();
            if (data.success !== false) {
                this.state.emailAccounts = data;
            }
        } catch (err) {
            console.log('Could not load email accounts');
        }
    },

    renderEmailAccountsBar() {
        const bar = document.getElementById('emailAccountsBar');
        const noAccountsMsg = document.getElementById('noAccountsMsg');
        if (!bar) return;

        if (this.state.emailAccounts.length === 0) {
            if (noAccountsMsg) noAccountsMsg.style.display = 'block';
            return;
        }

        if (noAccountsMsg) noAccountsMsg.style.display = 'none';

        bar.innerHTML = this.state.emailAccounts.map(acc => `
            <button class="email-account-tab ${acc.email === this.state.currentEmailAccount ? 'active' : ''}"
                    data-email="${this.escapeHtml(acc.email)}">
                <span>${this.escapeHtml(acc.email.split('@')[0])}</span>
                <span class="remove-account" data-email="${this.escapeHtml(acc.email)}" title="Remove">×</span>
            </button>
        `).join('');

        // Handle tab clicks for switching accounts
        bar.querySelectorAll('.email-account-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                // Ignore if clicking on remove button
                if (!e.target.classList.contains('remove-account')) {
                    this.switchEmailAccount(tab.dataset.email);
                }
            });
        });

        // Handle remove button clicks separately
        bar.querySelectorAll('.remove-account').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation(); // Prevent tab switch
                e.preventDefault();
                this.removeEmailAccount(btn.dataset.email);
            });
        });
    },

    async switchEmailAccount(email) {
        this.state.currentEmailAccount = email;
        this.renderEmailAccountsBar();
        await this.loadEmails();
    },

    async loadEmails() {
        if (!this.state.currentEmailAccount) return;

        const list = document.getElementById('emailList');
        const loading = document.getElementById('emailLoading');
        const cacheKey = `hub_emails_${this.state.currentEmailAccount}`;

        if (loading) loading.style.display = 'flex';
        if (list) list.innerHTML = '';

        try {
            const response = await fetch(`/api/email/messages/${encodeURIComponent(this.state.currentEmailAccount)}`);
            const data = await response.json();

            if (loading) loading.style.display = 'none';

            if (data.success && data.emails) {
                this.state.emails = data.emails;
                // Cache the last 10 emails for offline use
                try {
                    const toCache = data.emails.slice(0, 10);
                    localStorage.setItem(cacheKey, JSON.stringify(toCache));
                } catch (e) { /* localStorage full or unavailable */ }
                this.renderEmailList();
            } else {
                if (list) list.innerHTML = `<p class="no-items">${data.error || this.t('no_emails')}</p>`;
            }
        } catch (err) {
            if (loading) loading.style.display = 'none';
            // Try to load from cache when offline
            try {
                const cached = localStorage.getItem(cacheKey);
                if (cached) {
                    this.state.emails = JSON.parse(cached);
                    this.renderEmailList(true); // true = offline mode
                    return;
                }
            } catch (e) { /* no cache */ }
            if (list) list.innerHTML = `<p class="no-items">${this.t('offline')}</p>`;
        }
    },

    renderEmailList(isOffline = false) {
        const list = document.getElementById('emailList');
        if (!list) return;

        if (this.state.emails.length === 0) {
            list.innerHTML = `<p class="no-items">${this.t('no_emails')}</p>`;
            return;
        }

        let html = '';
        if (isOffline) {
            html = `<div class="offline-notice">${this.t('showing_cached')}</div>`;
        }

        html += this.state.emails.map(email => `
            <div class="email-item ${!email.read ? 'unread' : ''}" data-id="${email.id}">
                <span class="email-date">${email.date}</span>
                <div class="email-from">${this.escapeHtml(email.from_name || email.from)}</div>
                <div class="email-subject">${this.escapeHtml(email.subject)}</div>
                <div class="email-preview">${this.escapeHtml(email.preview)}</div>
            </div>
        `).join('');

        list.innerHTML = html;

        list.querySelectorAll('.email-item').forEach(item => {
            item.addEventListener('click', () => this.viewEmail(item.dataset.id));
        });
    },

    async viewEmail(msgId) {
        const detailPanel = document.getElementById('emailDetailPanel');
        const mainWidget = document.querySelector('.widget-full:not(.email-detail-panel)');
        const content = document.getElementById('emailDetailContent');

        if (!detailPanel || !content) return;

        try {
            const response = await fetch(`/api/email/message/${encodeURIComponent(this.state.currentEmailAccount)}/${msgId}`);
            const data = await response.json();

            if (data.success && data.email) {
                this.state.currentEmail = data.email;
                this.state.currentEmailMsgId = msgId;

                content.innerHTML = `
                    <div class="email-detail-header">
                        <h3 class="email-detail-subject">${this.escapeHtml(data.email.subject)}</h3>
                        <div class="email-detail-meta">
                            <span><strong>${this.t('from')}:</strong> ${this.escapeHtml(data.email.from_name)} &lt;${this.escapeHtml(data.email.from)}&gt;</span>
                            <span><strong>${this.t('date')}:</strong> ${data.email.date}</span>
                        </div>
                    </div>
                    <div class="email-detail-body">${this.escapeHtml(data.email.body)}</div>
                `;

                if (mainWidget) mainWidget.style.display = 'none';
                detailPanel.style.display = 'block';
            }
        } catch (err) {
            console.error('Error loading email:', err);
        }
    },

    async deleteEmail() {
        if (!this.state.currentEmailMsgId || !this.state.currentEmailAccount) return;

        if (!confirm('Move this email to trash?')) return;

        try {
            const response = await fetch(`/api/email/message/${encodeURIComponent(this.state.currentEmailAccount)}/${this.state.currentEmailMsgId}`, {
                method: 'DELETE'
            });
            const data = await response.json();

            if (data.success) {
                this.closeEmailDetail();
                await this.loadEmails();
            } else {
                alert(data.error || 'Failed to delete email');
            }
        } catch (err) {
            console.error('Error deleting email:', err);
            alert('Failed to delete email');
        }
    },

    openComposeModal(to = '', subject = '', body = '') {
        document.getElementById('composeTo').value = to;
        document.getElementById('composeSubject').value = subject;
        document.getElementById('composeBody').value = body;
        document.getElementById('composeError').style.display = 'none';
        document.getElementById('composeModal').classList.add('active');
    },

    closeEmailDetail() {
        const detailPanel = document.getElementById('emailDetailPanel');
        const mainWidget = document.querySelector('.widget-full:not(.email-detail-panel)');

        if (detailPanel) detailPanel.style.display = 'none';
        if (mainWidget) mainWidget.style.display = 'block';

        this.state.currentEmail = null;
    },

    async addEmailAccount(email, password, provider) {
        const errorEl = document.getElementById('accountError');

        try {
            const response = await fetch('/api/email/accounts', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password, provider })
            });
            const data = await response.json();

            if (data.success) {
                document.getElementById('addAccountModal').classList.remove('active');
                document.getElementById('addAccountForm').reset();
                await this.loadEmailAccounts();
                this.renderEmailAccountsBar();
                this.state.currentEmailAccount = email;
                await this.loadEmails();
            } else {
                if (errorEl) {
                    errorEl.textContent = data.error;
                    errorEl.style.display = 'block';
                }
            }
        } catch (err) {
            if (errorEl) {
                errorEl.textContent = this.t('error');
                errorEl.style.display = 'block';
            }
        }
    },

    async removeEmailAccount(email) {
        if (!confirm(`Remove ${email}?`)) return;

        try {
            const response = await fetch(`/api/email/accounts/${encodeURIComponent(email)}`, { method: 'DELETE' });
            const data = await response.json();
            console.log('Remove account response:', data);

            await this.loadEmailAccounts();
            this.renderEmailAccountsBar();

            if (this.state.currentEmailAccount === email) {
                this.state.currentEmailAccount = this.state.emailAccounts[0]?.email || null;
                if (this.state.currentEmailAccount) {
                    await this.loadEmails();
                } else {
                    const emailList = document.getElementById('emailList');
                    if (emailList) emailList.innerHTML = '';
                }
            }
        } catch (err) {
            console.error('Error removing account:', err);
        }
    },

    async sendEmail(to, subject, body) {
        if (!this.state.currentEmailAccount) return { success: false, error: 'No account selected' };

        try {
            const response = await fetch('/api/email/send', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    from_email: this.state.currentEmailAccount,
                    to_email: to,
                    subject,
                    body
                })
            });
            return await response.json();
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    initEmailEventListeners() {
        // Compose button
        const composeEmailBtn = document.getElementById('composeEmailBtn');
        if (composeEmailBtn) {
            composeEmailBtn.addEventListener('click', () => {
                this.openComposeModal();
            });
        }

        // Delete email button
        const deleteEmailBtn = document.getElementById('deleteEmailBtn');
        if (deleteEmailBtn) {
            deleteEmailBtn.addEventListener('click', () => {
                this.deleteEmail();
            });
        }

        // Add account button
        const addAccountBtn = document.getElementById('addAccountBtn');
        if (addAccountBtn) {
            addAccountBtn.addEventListener('click', () => {
                document.getElementById('addAccountModal').classList.add('active');
            });
        }

        // Add account modal close
        const addAccountModalClose = document.getElementById('addAccountModalClose');
        if (addAccountModalClose) {
            addAccountModalClose.addEventListener('click', () => {
                document.getElementById('addAccountModal').classList.remove('active');
            });
        }

        // Add account form
        const addAccountForm = document.getElementById('addAccountForm');
        if (addAccountForm) {
            addAccountForm.addEventListener('submit', (e) => {
                e.preventDefault();
                const email = document.getElementById('accountEmail').value;
                const password = document.getElementById('accountPassword').value;
                const provider = document.getElementById('accountProvider').value;
                this.addEmailAccount(email, password, provider);
            });
        }

        // Back button
        const backBtn = document.getElementById('emailBackBtn');
        if (backBtn) {
            backBtn.addEventListener('click', () => this.closeEmailDetail());
        }

        // Compose modal
        const composeModalClose = document.getElementById('composeModalClose');
        if (composeModalClose) {
            composeModalClose.addEventListener('click', () => {
                document.getElementById('composeModal').classList.remove('active');
            });
        }

        const cancelCompose = document.getElementById('cancelCompose');
        if (cancelCompose) {
            cancelCompose.addEventListener('click', () => {
                document.getElementById('composeModal').classList.remove('active');
            });
        }

        const composeForm = document.getElementById('composeForm');
        if (composeForm) {
            composeForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const to = document.getElementById('composeTo').value;
                const subject = document.getElementById('composeSubject').value;
                const body = document.getElementById('composeBody').value;
                const result = await this.sendEmail(to, subject, body);
                if (result.success) {
                    document.getElementById('composeModal').classList.remove('active');
                    composeForm.reset();
                } else {
                    const errorEl = document.getElementById('composeError');
                    if (errorEl) {
                        errorEl.textContent = result.error;
                        errorEl.style.display = 'block';
                    }
                }
            });
        }

        // Reply button
        const replyBtn = document.getElementById('replyEmailBtn');
        if (replyBtn) {
            replyBtn.addEventListener('click', () => {
                if (!this.state.currentEmail) return;
                document.getElementById('composeTo').value = this.state.currentEmail.from;
                document.getElementById('composeSubject').value = `Re: ${this.state.currentEmail.subject}`;
                document.getElementById('composeBody').value = `\n\n---\n${this.state.currentEmail.body}`;
                document.getElementById('composeModal').classList.add('active');
            });
        }

        // Modal backdrop close
        ['addAccountModal', 'composeModal'].forEach(id => {
            const modal = document.getElementById(id);
            if (modal) {
                modal.addEventListener('click', (e) => {
                    if (e.target === modal) modal.classList.remove('active');
                });
            }
        });
    },

    async loadEmailPreview() {
        const container = document.getElementById('emailPreviewList');
        if (!container) return;

        try {
            const response = await fetch('/api/email/accounts');
            const accounts = await response.json();

            if (!accounts || accounts.length === 0) {
                return; // Keep the default "no accounts" message
            }

            // Fetch emails from first account
            const account = accounts[0];
            const emailResponse = await fetch(`/api/email/messages/${encodeURIComponent(account.email)}?limit=3`);
            const data = await emailResponse.json();

            if (data.success && data.emails && data.emails.length > 0) {
                container.innerHTML = data.emails.slice(0, 3).map(email => `
                    <a href="/hub/email" class="email-item ${!email.read ? 'unread' : ''}">
                        <span class="email-date">${email.date}</span>
                        <div class="email-from">${this.escapeHtml(email.from_name || email.from)}</div>
                        <div class="email-subject">${this.escapeHtml(email.subject)}</div>
                    </a>
                `).join('');
            } else {
                container.innerHTML = `<p class="no-items">${this.t('no_emails')}</p>`;
            }
        } catch (err) {
            console.log('Could not load email preview');
        }
    },

    // ==========================================
    // CLOCK
    // ==========================================

    initClock() {
        this.updateClock();
        setInterval(() => this.updateClock(), 1000);
    },

    updateClock() {
        const now = new Date();
        const clockTime = document.getElementById('clockTime');
        const clockDate = document.getElementById('clockDate');

        if (clockTime) {
            clockTime.textContent = now.toLocaleTimeString('de-DE', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
        }
        if (clockDate) {
            clockDate.textContent = now.toLocaleDateString('de-DE', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
        }
    },

    // ==========================================
    // POMODORO
    // ==========================================

    initPomodoro() {
        const today = new Date().toISOString().split('T')[0];
        if (this.state.pomodoro.lastSessionDate !== today) {
            this.state.pomodoro.todaySessions = 0;
            this.state.pomodoro.lastSessionDate = today;
            this.savePomodoro();
        }
        this.state.pomodoroTimeLeft = this.state.pomodoro.workDuration * 60;
        this.updatePomodoroDisplay();
        this.updatePomodoroSessions();

        // Load settings into inputs if they exist
        const workInput = document.getElementById('workDuration');
        const breakInput = document.getElementById('breakDuration');
        if (workInput) workInput.value = this.state.pomodoro.workDuration;
        if (breakInput) breakInput.value = this.state.pomodoro.breakDuration;
    },

    updatePomodoroDisplay() {
        const mins = Math.floor(this.state.pomodoroTimeLeft / 60);
        const secs = this.state.pomodoroTimeLeft % 60;
        const timeEl = document.getElementById('pomodoroTime');
        if (timeEl) {
            timeEl.textContent = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
        }

        const totalTime = this.state.pomodoroIsWork ?
            this.state.pomodoro.workDuration * 60 :
            this.state.pomodoro.breakDuration * 60;
        const progress = (totalTime - this.state.pomodoroTimeLeft) / totalTime;
        const circumference = 2 * Math.PI * 45;
        const ringEl = document.getElementById('pomodoroRing');
        if (ringEl) {
            ringEl.style.strokeDashoffset = circumference * (1 - progress);
        }
    },

    updatePomodoroSessions() {
        const sessionsEl = document.getElementById('pomodoroSessions');
        if (sessionsEl) {
            sessionsEl.textContent = `${this.state.pomodoro.todaySessions} session${this.state.pomodoro.todaySessions !== 1 ? 's' : ''} today`;
        }
    },

    startPomodoro() {
        if (this.state.pomodoroRunning) return;
        this.state.pomodoroRunning = true;

        const startBtn = document.getElementById('pomodoroStart');
        const pauseBtn = document.getElementById('pomodoroPause');
        const statusEl = document.getElementById('pomodoroStatus');

        if (startBtn) startBtn.style.display = 'none';
        if (pauseBtn) pauseBtn.style.display = 'flex';
        if (statusEl) statusEl.textContent = this.state.pomodoroIsWork ? 'Working...' : 'Break';

        this.state.pomodoroTimer = setInterval(() => {
            this.state.pomodoroTimeLeft--;
            this.updatePomodoroDisplay();

            if (this.state.pomodoroTimeLeft <= 0) {
                this.pomodoroComplete();
            }
        }, 1000);
    },

    pausePomodoro() {
        this.state.pomodoroRunning = false;
        clearInterval(this.state.pomodoroTimer);

        const startBtn = document.getElementById('pomodoroStart');
        const pauseBtn = document.getElementById('pomodoroPause');
        const statusEl = document.getElementById('pomodoroStatus');

        if (startBtn) startBtn.style.display = 'flex';
        if (pauseBtn) pauseBtn.style.display = 'none';
        if (statusEl) statusEl.textContent = 'Paused';
    },

    resetPomodoro() {
        this.pausePomodoro();
        this.state.pomodoroIsWork = true;
        this.state.pomodoroTimeLeft = this.state.pomodoro.workDuration * 60;
        this.updatePomodoroDisplay();
        const statusEl = document.getElementById('pomodoroStatus');
        if (statusEl) statusEl.textContent = 'Ready';
    },

    pomodoroComplete() {
        this.pausePomodoro();
        this.playNotificationSound();

        const statusEl = document.getElementById('pomodoroStatus');

        if (this.state.pomodoroIsWork) {
            this.state.pomodoro.todaySessions++;
            this.state.pomodoro.lastSessionDate = new Date().toISOString().split('T')[0];
            this.savePomodoro();
            this.updatePomodoroSessions();
            this.state.pomodoroIsWork = false;
            this.state.pomodoroTimeLeft = this.state.pomodoro.breakDuration * 60;
            if (statusEl) statusEl.textContent = 'Break time!';
        } else {
            this.state.pomodoroIsWork = true;
            this.state.pomodoroTimeLeft = this.state.pomodoro.workDuration * 60;
            if (statusEl) statusEl.textContent = 'Ready';
        }
        this.updatePomodoroDisplay();
    },

    playNotificationSound() {
        try {
            const audioContext = new (window.AudioContext || window.webkitAudioContext)();
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();
            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);
            oscillator.frequency.value = 800;
            oscillator.type = 'sine';
            gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
            oscillator.start(audioContext.currentTime);
            oscillator.stop(audioContext.currentTime + 0.5);
        } catch (e) {
            console.log('Could not play notification sound');
        }
    },

    savePomodoro() {
        localStorage.setItem('hub_pomodoro', JSON.stringify(this.state.pomodoro));
    },

    // ==========================================
    // TODOS
    // ==========================================

    initTodos() {
        this.renderTodos();
    },

    renderTodos() {
        const list = document.getElementById('todoList');
        if (!list) return;

        const today = new Date().toISOString().split('T')[0];

        let filtered = this.state.todos;
        if (this.state.todoFilter === 'today') {
            filtered = this.state.todos.filter(t => t.dueDate === today);
        } else if (this.state.todoFilter === 'pending') {
            filtered = this.state.todos.filter(t => !t.completed);
        }

        filtered.sort((a, b) => {
            if (a.completed !== b.completed) return a.completed ? 1 : -1;
            const priorityOrder = { high: 0, medium: 1, low: 2 };
            return priorityOrder[a.priority] - priorityOrder[b.priority];
        });

        if (filtered.length === 0) {
            list.innerHTML = `<p class="no-items">${this.t('no_tasks')}</p>`;
            return;
        }

        list.innerHTML = filtered.map(todo => `
            <div class="todo-item ${todo.completed ? 'completed' : ''} priority-${todo.priority}" data-id="${todo.id}">
                <input type="checkbox" class="todo-checkbox" ${todo.completed ? 'checked' : ''}>
                <span class="todo-title">${this.escapeHtml(todo.title)}</span>
                ${todo.dueDate ? `<span class="todo-due">${new Date(todo.dueDate + 'T12:00').toLocaleDateString('de-DE', { day: 'numeric', month: 'short' })}</span>` : ''}
                <button class="todo-edit" title="Edit">...</button>
            </div>
        `).join('');

        list.querySelectorAll('.todo-checkbox').forEach(cb => {
            cb.addEventListener('change', (e) => {
                const id = e.target.closest('.todo-item').dataset.id;
                this.toggleTodo(id);
            });
        });

        list.querySelectorAll('.todo-edit').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = e.target.closest('.todo-item').dataset.id;
                this.openTodoModal(id);
            });
        });
    },

    addQuickTodo() {
        const input = document.getElementById('todoInput');
        if (!input) return;

        const title = input.value.trim();
        if (!title) return;

        this.state.todos.push({
            id: Date.now().toString(),
            title,
            dueDate: '',
            priority: 'medium',
            completed: false,
            createdAt: new Date().toISOString()
        });
        this.saveTodos();
        this.renderTodos();
        input.value = '';
    },

    toggleTodo(id) {
        const todo = this.state.todos.find(t => t.id === id);
        if (todo) {
            todo.completed = !todo.completed;
            this.saveTodos();
            this.renderTodos();
        }
    },

    openTodoModal(id = null) {
        const modal = document.getElementById('todoModal');
        if (!modal) return;

        const title = document.getElementById('todoModalTitle');
        const deleteBtn = document.getElementById('deleteTodo');

        if (id) {
            const todo = this.state.todos.find(t => t.id === id);
            if (!todo) return;
            if (title) title.textContent = 'Edit Task';
            document.getElementById('todoTitle').value = todo.title;
            document.getElementById('todoDueDate').value = todo.dueDate || '';
            document.getElementById('todoPriority').value = todo.priority;
            this.state.editingTodoId = id;
            if (deleteBtn) deleteBtn.style.display = 'block';
        } else {
            if (title) title.textContent = 'Add Task';
            document.getElementById('todoTitle').value = '';
            document.getElementById('todoDueDate').value = '';
            document.getElementById('todoPriority').value = 'medium';
            this.state.editingTodoId = null;
            if (deleteBtn) deleteBtn.style.display = 'none';
        }
        modal.classList.add('active');
    },

    saveTodoFromModal(e) {
        e.preventDefault();
        const todo = {
            id: this.state.editingTodoId || Date.now().toString(),
            title: document.getElementById('todoTitle').value,
            dueDate: document.getElementById('todoDueDate').value,
            priority: document.getElementById('todoPriority').value,
            completed: false,
            createdAt: new Date().toISOString()
        };

        if (this.state.editingTodoId) {
            const existing = this.state.todos.find(t => t.id === this.state.editingTodoId);
            if (existing) {
                todo.completed = existing.completed;
                todo.createdAt = existing.createdAt;
            }
            const idx = this.state.todos.findIndex(t => t.id === this.state.editingTodoId);
            if (idx !== -1) this.state.todos[idx] = todo;
        } else {
            this.state.todos.push(todo);
        }

        this.saveTodos();
        this.renderTodos();
        document.getElementById('todoModal').classList.remove('active');
    },

    deleteTodo() {
        if (!this.state.editingTodoId) return;
        this.state.todos = this.state.todos.filter(t => t.id !== this.state.editingTodoId);
        this.saveTodos();
        this.renderTodos();
        document.getElementById('todoModal').classList.remove('active');
    },

    saveTodos() {
        localStorage.setItem('hub_todos', JSON.stringify(this.state.todos));
    },

    // ==========================================
    // NOTES
    // ==========================================

    initNotes() {
        if (!this.state.notes.find(n => n.id === this.state.activeNoteId)) {
            this.state.activeNoteId = this.state.notes[0]?.id || 'default';
        }
        this.renderNoteTabs();
        this.loadActiveNote();
    },

    renderNoteTabs() {
        const tabs = document.getElementById('notesTabs');
        if (!tabs) return;

        tabs.innerHTML = this.state.notes.map(note => `
            <button class="note-tab ${note.id === this.state.activeNoteId ? 'active' : ''}"
                    data-id="${note.id}" title="${this.escapeHtml(note.title)}">
                ${this.escapeHtml(note.title.substring(0, 8))}${note.title.length > 8 ? '...' : ''}
            </button>
        `).join('');

        tabs.querySelectorAll('.note-tab').forEach(tab => {
            tab.addEventListener('click', () => {
                this.switchNote(tab.dataset.id);
            });
            tab.addEventListener('dblclick', () => {
                const newTitle = prompt('Rename note:', this.state.notes.find(n => n.id === tab.dataset.id)?.title);
                if (newTitle) this.renameNote(tab.dataset.id, newTitle);
            });
        });
    },

    switchNote(id) {
        this.saveCurrentNote();
        this.state.activeNoteId = id;
        localStorage.setItem('hub_active_note', id);
        this.renderNoteTabs();
        this.loadActiveNote();
    },

    loadActiveNote() {
        const note = this.state.notes.find(n => n.id === this.state.activeNoteId);
        const noteContent = document.getElementById('noteContent');
        if (noteContent) {
            noteContent.value = note?.content || '';
        }
        this.updateWordCount();
    },

    saveCurrentNote() {
        const note = this.state.notes.find(n => n.id === this.state.activeNoteId);
        const noteContent = document.getElementById('noteContent');
        if (note && noteContent) {
            note.content = noteContent.value;
            note.updatedAt = new Date().toISOString();
            this.saveNotes();
        }
    },

    addNote() {
        const newNote = {
            id: Date.now().toString(),
            title: `Note ${this.state.notes.length + 1}`,
            content: '',
            updatedAt: new Date().toISOString()
        };
        this.state.notes.push(newNote);
        this.saveNotes();
        this.switchNote(newNote.id);
    },

    renameNote(id, title) {
        const note = this.state.notes.find(n => n.id === id);
        if (note) {
            note.title = title;
            this.saveNotes();
            this.renderNoteTabs();
        }
    },

    deleteCurrentNote() {
        if (this.state.notes.length <= 1) {
            alert('Cannot delete the last note');
            return;
        }
        if (!confirm('Delete this note?')) return;

        this.state.notes = this.state.notes.filter(n => n.id !== this.state.activeNoteId);
        this.saveNotes();
        this.state.activeNoteId = this.state.notes[0].id;
        this.renderNoteTabs();
        this.loadActiveNote();
    },

    updateWordCount() {
        const content = document.getElementById('noteContent');
        const wordCount = document.getElementById('wordCount');
        if (content && wordCount) {
            const text = content.value.trim();
            const words = text ? text.split(/\s+/).length : 0;
            wordCount.textContent = `${words} word${words !== 1 ? 's' : ''}`;
        }
    },

    saveNotes() {
        localStorage.setItem('hub_notes', JSON.stringify(this.state.notes));
    },

    // ==========================================
    // BOOKMARKS
    // ==========================================

    initBookmarks() {
        this.renderBookmarks();
    },

    renderBookmarks() {
        const list = document.getElementById('bookmarksList');
        if (!list) return;

        const categories = [...new Set(this.state.bookmarks.map(b => b.category))];

        if (this.state.bookmarks.length === 0) {
            list.innerHTML = `<p class="no-items">${this.t('no_bookmarks')}</p>`;
            return;
        }

        list.innerHTML = categories.map(cat => `
            <div class="bookmark-category">
                <div class="category-header">${this.escapeHtml(cat)}</div>
                <div class="category-links">
                    ${this.state.bookmarks.filter(b => b.category === cat).map(b => `
                        <a href="${this.escapeHtml(b.url)}" target="_blank" rel="noopener" class="bookmark-link" data-id="${b.id}">
                            <img src="https://www.google.com/s2/favicons?domain=${new URL(b.url).hostname}&sz=32"
                                 alt="" class="bookmark-favicon" onerror="this.style.display='none'">
                            <span>${this.escapeHtml(b.title)}</span>
                        </a>
                    `).join('')}
                </div>
            </div>
        `).join('');

        list.querySelectorAll('.bookmark-link').forEach(link => {
            link.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                this.openBookmarkModal(link.dataset.id);
            });
        });
    },

    openBookmarkModal(id = null) {
        const modal = document.getElementById('bookmarkModal');
        if (!modal) return;

        const title = document.getElementById('bookmarkModalTitle');
        const deleteBtn = document.getElementById('deleteBookmark');

        if (id) {
            const bookmark = this.state.bookmarks.find(b => b.id === id);
            if (!bookmark) return;
            if (title) title.textContent = 'Edit Bookmark';
            document.getElementById('bookmarkTitle').value = bookmark.title;
            document.getElementById('bookmarkUrl').value = bookmark.url;
            document.getElementById('bookmarkCategory').value = bookmark.category;
            this.state.editingBookmarkId = id;
            if (deleteBtn) deleteBtn.style.display = 'block';
        } else {
            if (title) title.textContent = 'Add Bookmark';
            document.getElementById('bookmarkTitle').value = '';
            document.getElementById('bookmarkUrl').value = '';
            document.getElementById('bookmarkCategory').value = 'Other';
            this.state.editingBookmarkId = null;
            if (deleteBtn) deleteBtn.style.display = 'none';
        }
        modal.classList.add('active');
    },

    saveBookmarkFromModal(e) {
        e.preventDefault();
        const bookmark = {
            id: this.state.editingBookmarkId || Date.now().toString(),
            title: document.getElementById('bookmarkTitle').value,
            url: document.getElementById('bookmarkUrl').value,
            category: document.getElementById('bookmarkCategory').value
        };

        if (this.state.editingBookmarkId) {
            const idx = this.state.bookmarks.findIndex(b => b.id === this.state.editingBookmarkId);
            if (idx !== -1) this.state.bookmarks[idx] = bookmark;
        } else {
            this.state.bookmarks.push(bookmark);
        }

        this.saveBookmarks();
        this.renderBookmarks();
        document.getElementById('bookmarkModal').classList.remove('active');
    },

    deleteBookmark() {
        if (!this.state.editingBookmarkId) return;
        this.state.bookmarks = this.state.bookmarks.filter(b => b.id !== this.state.editingBookmarkId);
        this.saveBookmarks();
        this.renderBookmarks();
        document.getElementById('bookmarkModal').classList.remove('active');
    },

    saveBookmarks() {
        localStorage.setItem('hub_bookmarks', JSON.stringify(this.state.bookmarks));
    },

    // ==========================================
    // CALENDAR
    // ==========================================

    async initCalendar() {
        await this.loadCalendarAccounts();
        this.renderCalendar();
        this.renderEvents();
        await this.fetchCalendarEvents();
    },

    async loadCalendarAccounts() {
        // Load Google accounts (same as email accounts)
        try {
            const response = await fetch('/api/email/accounts');
            const accounts = await response.json();
            const googleAccounts = accounts.filter(a => a.provider === 'gmail_oauth');

            const select = document.getElementById('calendarAccountSelect');
            if (select) {
                if (googleAccounts.length === 0) {
                    select.innerHTML = '<option value="">No Google Account</option>';
                    select.disabled = true;
                } else {
                    select.innerHTML = googleAccounts.map(acc =>
                        `<option value="${this.escapeHtml(acc.email)}">${this.escapeHtml(acc.email)}</option>`
                    ).join('');
                    select.disabled = false;
                    this.state.selectedCalendarAccount = googleAccounts[0].email;

                    // Load calendars for the account
                    await this.loadGoogleCalendars();
                }

                select.addEventListener('change', async (e) => {
                    this.state.selectedCalendarAccount = e.target.value;
                    await this.loadGoogleCalendars();
                    await this.fetchCalendarEvents();
                });
            }
        } catch (err) {
            console.log('Could not load calendar accounts');
        }
    },

    async loadGoogleCalendars() {
        if (!this.state.selectedCalendarAccount) return;

        try {
            const response = await fetch(`/api/calendar/google/calendars?account=${encodeURIComponent(this.state.selectedCalendarAccount)}`);
            const data = await response.json();

            if (data.success && data.calendars) {
                this.state.googleCalendars = data.calendars;

                // Update calendar selector in event modal
                const calSelect = document.getElementById('eventCalendar');
                if (calSelect) {
                    calSelect.innerHTML = data.calendars
                        .filter(c => c.access_role === 'owner' || c.access_role === 'writer')
                        .map(c => `<option value="${this.escapeHtml(c.id)}" ${c.primary ? 'selected' : ''}>${this.escapeHtml(c.name)}</option>`)
                        .join('');
                }
            }
        } catch (err) {
            console.log('Could not load Google calendars');
        }
    },

    async fetchCalendarEvents() {
        try {
            const accountParam = this.state.selectedCalendarAccount ? `&account=${encodeURIComponent(this.state.selectedCalendarAccount)}` : '';
            const response = await fetch(`/api/calendar/events?days=30${accountParam}`);
            const data = await response.json();

            if (data.success && data.events) {
                this.state.macOSEvents = data.events;
                this.state.calendarError = null;
                this.state.calendarSource = data.account ? 'google' : 'macos';
                this.renderCalendar();
                this.renderEvents();
            } else if (data.error === 'not_authenticated') {
                // No Google account - show hint to connect
                this.state.calendarError = this.t('calendar_connect_google');
                this.renderEvents();
            } else if (data.error === 'scope_needed') {
                // Need to re-auth for calendar scope
                this.state.calendarError = data.message || this.t('calendar_reauth_needed');
                this.renderEvents();
            } else if (data.error === 'no_calendars' || data.error === 'permission_needed' || data.error === 'no_permission') {
                this.state.calendarError = data.message || this.t('calendar_no_access');
                this.renderEvents();
            }
        } catch (err) {
            console.log('Could not fetch calendar events:', err);
        }
    },

    getAllEvents() {
        const localEvents = this.state.events || [];
        const externalEvents = this.state.macOSEvents || [];

        const eventMap = new Map();
        localEvents.forEach(e => eventMap.set(e.id, { ...e, source: 'local' }));

        // Normalize external events (Google/macOS) to have consistent date/time fields
        externalEvents.forEach(e => {
            if (!eventMap.has(e.id)) {
                eventMap.set(e.id, {
                    ...e,
                    // Normalize: Google uses start_date/start_time, ensure date/time exist
                    date: e.date || e.start_date,
                    time: e.time || e.start_time || null,
                    source: e.source || 'external'
                });
            }
        });

        return Array.from(eventMap.values());
    },

    renderCalendar() {
        const grid = document.getElementById('calendarGrid');
        const monthEl = document.getElementById('calendarMonth');
        if (!grid || !monthEl) return;

        const year = this.state.viewDate.getFullYear();
        const month = this.state.viewDate.getMonth();

        monthEl.textContent = this.state.viewDate.toLocaleDateString('de-DE', { month: 'long', year: 'numeric' });

        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        const startDay = firstDay.getDay() || 7;

        let html = '<div class="calendar-weekdays">';
        ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'].forEach(day => html += `<span>${day}</span>`);
        html += '</div><div class="calendar-days">';

        for (let i = 1; i < startDay; i++) html += '<span class="empty"></span>';

        const today = new Date();
        const allEvents = this.getAllEvents();
        for (let day = 1; day <= lastDay.getDate(); day++) {
            const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
            const isToday = today.getFullYear() === year && today.getMonth() === month && today.getDate() === day;
            const hasEvents = allEvents.some(e => e.date === dateStr);
            html += `<span class="day${isToday ? ' today' : ''}${hasEvents ? ' has-events' : ''}" data-date="${dateStr}">${day}</span>`;
        }
        html += '</div>';
        grid.innerHTML = html;

        grid.querySelectorAll('.day').forEach(el => {
            el.addEventListener('click', () => this.openEventModal(el.dataset.date));
        });
    },

    renderEvents() {
        const list = document.getElementById('eventsList');
        if (!list) return;

        // Show calendar error if any
        if (this.state.calendarError) {
            const errorHtml = `<div class="calendar-error">${this.state.calendarError}</div>`;
            list.insertAdjacentHTML('beforebegin', errorHtml);
        }

        const todayStr = new Date().toISOString().split('T')[0];
        const allEvents = this.getAllEvents();
        const upcoming = allEvents
            .filter(e => e.date >= todayStr)
            .sort((a, b) => {
                const dateCompare = a.date.localeCompare(b.date);
                if (dateCompare !== 0) return dateCompare;
                return (a.time || '').localeCompare(b.time || '');
            })
            .slice(0, 8);

        if (upcoming.length === 0) {
            list.innerHTML = `<p class="no-items">${this.t('no_events')}</p>`;
            return;
        }

        list.innerHTML = upcoming.map(event => {
            const isExternal = event.source === 'macos' || event.source === 'google' || event.source === 'external';
            const calendarName = event.calendar ? this.escapeHtml(event.calendar) : '';
            const colorStyle = event.calendar_color ? `border-left-color: ${event.calendar_color}` : '';
            return `
            <div class="event-item ${isExternal ? 'external-event' : 'local-event'}" data-id="${event.id}" data-source="${event.source || 'local'}" style="${colorStyle}">
                <div class="event-date">${new Date(event.date + 'T12:00').toLocaleDateString('de-DE', { weekday: 'short', day: 'numeric', month: 'short' })}${event.time ? ' · ' + event.time : ''}</div>
                <div class="event-title">${this.escapeHtml(event.title)}</div>
                ${calendarName ? `<div class="event-calendar">${calendarName}</div>` : ''}
                ${event.location ? `<div class="event-location">📍 ${this.escapeHtml(event.location)}</div>` : ''}
            </div>
        `}).join('');

        list.querySelectorAll('.event-item').forEach(el => {
            el.addEventListener('click', () => {
                const source = el.dataset.source;
                const event = this.getAllEvents().find(e => e.id === el.dataset.id);

                if (!event) return;

                if (source === 'google') {
                    // Allow editing Google Calendar events
                    this.openEventModal(event.date || event.start_date, event);
                } else if (source === 'macos' || source === 'external') {
                    // macOS events are read-only - show info
                    const sourceText = source === 'macos' ? 'macOS Calendar' : 'External Calendar';
                    alert(`📅 ${event.title}\n📆 ${event.date || event.start_date} ${event.time || event.start_time || ''}\n${event.location ? '📍 ' + event.location : ''}\n${event.description ? '\n' + event.description : ''}\n\n(From ${sourceText} - read only)`);
                } else {
                    // Local events
                    this.openEventModal(event.date, event);
                }
            });
        });
    },

    openEventModal(date, event = null) {
        const modal = document.getElementById('eventModal');
        if (!modal) return;

        // Clear any previous errors
        const errorEl = document.getElementById('eventError');
        if (errorEl) errorEl.style.display = 'none';

        document.getElementById('eventDate').value = date;

        if (event) {
            document.getElementById('eventModalTitle').textContent = this.t('edit_event');
            document.getElementById('eventTitle').value = event.title || '';
            document.getElementById('eventTime').value = event.time || event.start_time || '';
            document.getElementById('eventEndDate').value = event.end_date || '';
            document.getElementById('eventEndTime').value = event.end_time || '';
            document.getElementById('eventLocation').value = event.location || '';
            document.getElementById('eventDescription').value = event.description || '';

            this.state.editingEventId = event.id;
            this.state.editingEventSource = event.source || 'local';
            this.state.editingEventCalendarId = event.calendar_id || 'primary';

            document.getElementById('deleteEvent').style.display = 'block';
        } else {
            document.getElementById('eventModalTitle').textContent = this.t('add_event');
            document.getElementById('eventTitle').value = '';
            document.getElementById('eventTime').value = '';
            document.getElementById('eventEndDate').value = '';
            document.getElementById('eventEndTime').value = '';
            document.getElementById('eventLocation').value = '';
            document.getElementById('eventDescription').value = '';

            this.state.editingEventId = null;
            this.state.editingEventSource = null;
            this.state.editingEventCalendarId = null;

            document.getElementById('deleteEvent').style.display = 'none';
        }
        modal.classList.add('active');
    },

    async saveEvent(e) {
        e.preventDefault();

        const errorEl = document.getElementById('eventError');
        const calendarId = document.getElementById('eventCalendar')?.value || 'primary';

        const eventData = {
            title: document.getElementById('eventTitle').value,
            date: document.getElementById('eventDate').value,
            time: document.getElementById('eventTime').value || null,
            end_date: document.getElementById('eventEndDate').value || null,
            end_time: document.getElementById('eventEndTime').value || null,
            location: document.getElementById('eventLocation').value || null,
            description: document.getElementById('eventDescription').value || null,
            calendar_id: calendarId,
            account: this.state.selectedCalendarAccount
        };

        // If we have a Google account, save to Google Calendar
        if (this.state.selectedCalendarAccount) {
            try {
                let response;
                if (this.state.editingEventId && (this.state.editingEventSource === 'google' || this.state.editingEventSource === 'external')) {
                    // Update existing Google event
                    response = await fetch(`/api/calendar/events/${this.state.editingEventId}`, {
                        method: 'PUT',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(eventData)
                    });
                } else if (this.state.editingEventId && this.state.editingEventSource === 'local') {
                    // Update local event (existing behavior)
                    const event = { ...eventData, id: this.state.editingEventId };
                    const idx = this.state.events.findIndex(e => e.id === this.state.editingEventId);
                    if (idx !== -1) this.state.events[idx] = event;
                    localStorage.setItem('hub_events', JSON.stringify(this.state.events));
                    document.getElementById('eventModal').classList.remove('active');
                    this.renderCalendar();
                    this.renderEvents();
                    return;
                } else {
                    // Create new Google event
                    response = await fetch('/api/calendar/events', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(eventData)
                    });
                }

                const result = await response.json();

                if (result.success) {
                    document.getElementById('eventModal').classList.remove('active');
                    await this.fetchCalendarEvents();
                    this.renderCalendar();
                    this.renderEvents();
                } else {
                    if (errorEl) {
                        errorEl.textContent = result.error || 'Failed to save event';
                        errorEl.style.display = 'block';
                    }
                }
            } catch (err) {
                if (errorEl) {
                    errorEl.textContent = 'Connection error';
                    errorEl.style.display = 'block';
                }
            }
        } else {
            // Save locally (existing behavior)
            const event = {
                id: this.state.editingEventId || Date.now().toString(),
                ...eventData
            };

            if (this.state.editingEventId) {
                const idx = this.state.events.findIndex(e => e.id === this.state.editingEventId);
                if (idx !== -1) this.state.events[idx] = event;
            } else {
                this.state.events.push(event);
            }

            localStorage.setItem('hub_events', JSON.stringify(this.state.events));
            document.getElementById('eventModal').classList.remove('active');
            this.renderCalendar();
            this.renderEvents();
        }
    },

    async deleteEvent() {
        if (!this.state.editingEventId) return;

        const errorEl = document.getElementById('eventError');

        // Check if it's a Google Calendar event
        if (this.state.editingEventSource === 'google' || this.state.editingEventSource === 'external') {
            if (!confirm('Delete this event from Google Calendar?')) return;

            try {
                const calendarId = this.state.editingEventCalendarId || 'primary';
                const accountParam = this.state.selectedCalendarAccount ? `&account=${encodeURIComponent(this.state.selectedCalendarAccount)}` : '';
                const response = await fetch(`/api/calendar/events/${this.state.editingEventId}?calendar_id=${encodeURIComponent(calendarId)}${accountParam}`, {
                    method: 'DELETE'
                });

                const result = await response.json();

                if (result.success) {
                    document.getElementById('eventModal').classList.remove('active');
                    await this.fetchCalendarEvents();
                    this.renderCalendar();
                    this.renderEvents();
                } else {
                    if (errorEl) {
                        errorEl.textContent = result.error || 'Failed to delete event';
                        errorEl.style.display = 'block';
                    }
                }
            } catch (err) {
                if (errorEl) {
                    errorEl.textContent = 'Connection error';
                    errorEl.style.display = 'block';
                }
            }
        } else {
            // Delete local event
            this.state.events = this.state.events.filter(e => e.id !== this.state.editingEventId);
            localStorage.setItem('hub_events', JSON.stringify(this.state.events));
            document.getElementById('eventModal').classList.remove('active');
            this.renderCalendar();
            this.renderEvents();
        }
    },

    // ==========================================
    // WEATHER
    // ==========================================

    async initWeather() {
        if (this.state.weather && this.state.location) {
            this.renderWeather();
            if (Date.now() - new Date(this.state.weather.timestamp) > 30 * 60 * 1000) {
                this.refreshWeather();
            }
        } else if (this.state.location) {
            await this.refreshWeather();
        } else {
            await this.detectLocation();
        }
    },

    async detectLocation() {
        const content = document.getElementById('weatherContent');
        if (content) content.innerHTML = '<div class="weather-loading">Detecting location...</div>';

        try {
            const response = await fetch('https://ipapi.co/json/');
            if (!response.ok) throw new Error('Location detection failed');
            const data = await response.json();
            this.state.location = { city: data.city, lat: data.latitude, lon: data.longitude };
            localStorage.setItem('hub_location', JSON.stringify(this.state.location));
            await this.refreshWeather();
        } catch (err) {
            const modal = document.getElementById('locationModal');
            if (modal) modal.classList.add('active');
        }
    },

    async setManualLocation(city) {
        const content = document.getElementById('weatherContent');
        if (content) content.innerHTML = '<div class="weather-loading">Finding city...</div>';

        const modal = document.getElementById('locationModal');
        if (modal) modal.classList.remove('active');

        try {
            const response = await fetch(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(city)}&count=1`);
            const data = await response.json();
            if (!data.results?.length) throw new Error('City not found');
            const result = data.results[0];
            this.state.location = { city: result.name, lat: result.latitude, lon: result.longitude };
            localStorage.setItem('hub_location', JSON.stringify(this.state.location));
            await this.refreshWeather();
        } catch (err) {
            if (content) content.innerHTML = '<div class="weather-error">City not found</div>';
            setTimeout(() => {
                if (modal) modal.classList.add('active');
            }, 2000);
        }
    },

    async refreshWeather() {
        if (!this.state.location) {
            await this.detectLocation();
            return;
        }
        if (!navigator.onLine) {
            if (this.state.weather) this.renderWeather();
            else {
                const content = document.getElementById('weatherContent');
                if (content) content.innerHTML = '<div class="weather-error">Offline</div>';
            }
            return;
        }

        const content = document.getElementById('weatherContent');
        if (content) content.innerHTML = '<div class="weather-loading">Loading...</div>';

        try {
            const { lat, lon } = this.state.location;
            const response = await fetch(`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto`);
            if (!response.ok) throw new Error('Weather fetch failed');
            const data = await response.json();
            this.state.weather = { current: data.current, daily: data.daily, timestamp: new Date().toISOString() };
            localStorage.setItem('hub_weather', JSON.stringify(this.state.weather));
            this.renderWeather();
        } catch (err) {
            if (this.state.weather) this.renderWeather();
            else if (content) content.innerHTML = '<div class="weather-error">Error</div>';
        }
    },

    renderWeather() {
        const { weather, location } = this.state;
        const content = document.getElementById('weatherContent');
        const locationEl = document.getElementById('weatherLocation');
        const updatedEl = document.getElementById('weatherUpdated');

        if (!weather?.current || !content) {
            if (content) content.innerHTML = '<div class="weather-error">No data</div>';
            return;
        }

        const emojis = { 0: '☀️', 1: '🌤️', 2: '⛅', 3: '☁️', 45: '🌫️', 48: '🌫️', 51: '🌧️', 53: '🌧️', 55: '🌧️', 61: '🌧️', 63: '🌧️', 65: '🌧️', 71: '🌨️', 73: '🌨️', 75: '🌨️', 80: '🌦️', 81: '🌦️', 82: '🌦️', 95: '⛈️', 96: '⛈️', 99: '⛈️' };
        const code = weather.current.weather_code;

        content.innerHTML = `
            <div class="weather-current">
                <div class="weather-icon">${emojis[code] || '🌡️'}</div>
                <div class="weather-temp">${Math.round(weather.current.temperature_2m)}°C</div>
            </div>
            <div class="weather-forecast">
                ${weather.daily.time.slice(1, 4).map((date, i) => `
                    <div class="forecast-day">
                        <span class="forecast-name">${new Date(date).toLocaleDateString('de-DE', { weekday: 'short' })}</span>
                        <span class="forecast-icon">${emojis[weather.daily.weather_code[i + 1]] || '🌡️'}</span>
                        <span class="forecast-temps">${Math.round(weather.daily.temperature_2m_max[i + 1])}°</span>
                    </div>
                `).join('')}
            </div>
        `;

        if (locationEl) locationEl.textContent = location.city;

        if (updatedEl) {
            const diffMins = Math.round((Date.now() - new Date(weather.timestamp)) / 60000);
            updatedEl.textContent = diffMins < 1 ? 'Just now' : diffMins < 60 ? `${diffMins}m ago` : new Date(weather.timestamp).toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
        }
    },

    // ==========================================
    // ONLINE STATUS
    // ==========================================

    updateOnlineStatus() {
        const indicator = document.getElementById('offlineIndicator');
        if (indicator) {
            indicator.classList.toggle('visible', !navigator.onLine);
        }
        this.state.isOnline = navigator.onLine;
    },

    // ==========================================
    // DATA EXPORT/IMPORT
    // ==========================================

    exportData() {
        const data = {};
        ['hub_theme', 'hub_events', 'hub_todos', 'hub_notes', 'hub_bookmarks', 'hub_pomodoro', 'hub_location'].forEach(key => {
            const val = localStorage.getItem(key);
            if (val) data[key] = JSON.parse(val);
        });
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `nexus-backup-${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        URL.revokeObjectURL(url);
    },

    importData(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const data = JSON.parse(e.target.result);
                Object.entries(data).forEach(([key, value]) => {
                    localStorage.setItem(key, JSON.stringify(value));
                });
                location.reload();
            } catch (err) {
                alert('Invalid backup file');
            }
        };
        reader.readAsText(file);
    },

    // ==========================================
    // UTILITIES
    // ==========================================

    escapeHtml(str) {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    },

    // ==========================================
    // EVENT LISTENERS
    // ==========================================

    initEventListeners() {
        // Theme toggle
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.addEventListener('click', () => this.toggleTheme());
        }

        // Initialize theme
        this.initTheme();

        // Language selector
        document.querySelectorAll('.lang-selector button').forEach(btn => {
            btn.addEventListener('click', () => this.setLanguage(btn.dataset.lang));
        });

        // Initialize language
        this.initLanguage();

        // Online status
        window.addEventListener('online', () => this.updateOnlineStatus());
        window.addEventListener('offline', () => this.updateOnlineStatus());
        this.updateOnlineStatus();

        // Calendar navigation
        const prevMonth = document.getElementById('prevMonth');
        const nextMonth = document.getElementById('nextMonth');
        if (prevMonth) {
            prevMonth.addEventListener('click', () => {
                this.state.viewDate.setMonth(this.state.viewDate.getMonth() - 1);
                this.renderCalendar();
            });
        }
        if (nextMonth) {
            nextMonth.addEventListener('click', () => {
                this.state.viewDate.setMonth(this.state.viewDate.getMonth() + 1);
                this.renderCalendar();
            });
        }

        // Add event button
        const addEventBtn = document.getElementById('addEventBtn');
        if (addEventBtn) {
            addEventBtn.addEventListener('click', () => this.openEventModal(new Date().toISOString().split('T')[0]));
        }

        // Event modal
        const eventModalClose = document.getElementById('eventModalClose');
        const eventForm = document.getElementById('eventForm');
        const deleteEventBtn = document.getElementById('deleteEvent');
        if (eventModalClose) {
            eventModalClose.addEventListener('click', () => document.getElementById('eventModal').classList.remove('active'));
        }
        if (eventForm) {
            eventForm.addEventListener('submit', (e) => this.saveEvent(e));
        }
        if (deleteEventBtn) {
            deleteEventBtn.addEventListener('click', () => this.deleteEvent());
        }

        // Weather refresh
        const refreshWeather = document.getElementById('refreshWeather');
        if (refreshWeather) {
            refreshWeather.addEventListener('click', () => this.refreshWeather());
        }

        // Location form
        const locationForm = document.getElementById('locationForm');
        if (locationForm) {
            locationForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.setManualLocation(document.getElementById('cityInput').value);
            });
        }

        // Pomodoro controls
        const pomodoroStart = document.getElementById('pomodoroStart');
        const pomodoroPause = document.getElementById('pomodoroPause');
        const pomodoroReset = document.getElementById('pomodoroReset');
        if (pomodoroStart) pomodoroStart.addEventListener('click', () => this.startPomodoro());
        if (pomodoroPause) pomodoroPause.addEventListener('click', () => this.pausePomodoro());
        if (pomodoroReset) pomodoroReset.addEventListener('click', () => this.resetPomodoro());

        // Pomodoro settings
        const workDuration = document.getElementById('workDuration');
        const breakDuration = document.getElementById('breakDuration');
        if (workDuration) {
            workDuration.addEventListener('change', (e) => {
                this.state.pomodoro.workDuration = parseInt(e.target.value);
                this.savePomodoro();
                this.resetPomodoro();
            });
        }
        if (breakDuration) {
            breakDuration.addEventListener('change', (e) => {
                this.state.pomodoro.breakDuration = parseInt(e.target.value);
                this.savePomodoro();
            });
        }

        // Todo filters
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this.state.todoFilter = btn.dataset.filter;
                this.renderTodos();
            });
        });

        // Todo input
        const todoInput = document.getElementById('todoInput');
        const addTodoBtn = document.getElementById('addTodoBtn');
        if (todoInput) {
            todoInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') this.addQuickTodo();
            });
        }
        if (addTodoBtn) {
            addTodoBtn.addEventListener('click', () => this.addQuickTodo());
        }

        // Todo modal
        const todoModalClose = document.getElementById('todoModalClose');
        const todoForm = document.getElementById('todoForm');
        const deleteTodoBtn = document.getElementById('deleteTodo');
        if (todoModalClose) {
            todoModalClose.addEventListener('click', () => document.getElementById('todoModal').classList.remove('active'));
        }
        if (todoForm) {
            todoForm.addEventListener('submit', (e) => this.saveTodoFromModal(e));
        }
        if (deleteTodoBtn) {
            deleteTodoBtn.addEventListener('click', () => this.deleteTodo());
        }

        // Notes
        const noteContent = document.getElementById('noteContent');
        const addNoteBtn = document.getElementById('addNoteBtn');
        const deleteNoteBtn = document.getElementById('deleteNoteBtn');
        if (noteContent) {
            noteContent.addEventListener('input', () => {
                this.saveCurrentNote();
                this.updateWordCount();
            });
        }
        if (addNoteBtn) {
            addNoteBtn.addEventListener('click', () => this.addNote());
        }
        if (deleteNoteBtn) {
            deleteNoteBtn.addEventListener('click', () => this.deleteCurrentNote());
        }

        // Bookmarks
        const addBookmarkBtn = document.getElementById('addBookmarkBtn');
        const bookmarkModalClose = document.getElementById('bookmarkModalClose');
        const bookmarkForm = document.getElementById('bookmarkForm');
        const deleteBookmarkBtn = document.getElementById('deleteBookmark');
        if (addBookmarkBtn) {
            addBookmarkBtn.addEventListener('click', () => this.openBookmarkModal());
        }
        if (bookmarkModalClose) {
            bookmarkModalClose.addEventListener('click', () => document.getElementById('bookmarkModal').classList.remove('active'));
        }
        if (bookmarkForm) {
            bookmarkForm.addEventListener('submit', (e) => this.saveBookmarkFromModal(e));
        }
        if (deleteBookmarkBtn) {
            deleteBookmarkBtn.addEventListener('click', () => this.deleteBookmark());
        }

        // Modal backdrop close
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) modal.classList.remove('active');
            });
        });
    }
};

// Export for use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = HubApp;
}
