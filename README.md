# Nexus Hub

A personal productivity dashboard that brings together your calendar, tasks, email, school schedule, and more in one unified interface.

## Features

- **Dashboard** - Overview with current time, task status, and upcoming events
- **Calendar** - Google Calendar integration with event management
- **Tasks** - Task management with deadlines and categories
- **Email** - Gmail integration for quick inbox access
- **School** - Timetable and schedule management via IServ
- **Training** - Workout and training schedule tracker
- **Projects** - Project organization and tracking
- **Knowledge Base** - Personal wiki and notes collection
- **Notes** - Quick note-taking
- **Pomodoro** - Focus timer with work/break intervals
- **Bookmarks** - Link collection and organization
- **Assistant** - AI-powered assistant

## Quick Start

### Local Development

1. Clone the repository
2. Run the setup script (first time only):
   ```bash
   ./setup.sh
   ```
3. Start Nexus Hub:
   ```bash
   ./start.sh
   ```
4. Open http://localhost:5050 in your browser

### What setup.sh does

The setup script automatically:
- Checks system requirements (Python 3, pip)
- Creates a Python virtual environment
- Installs all required packages (Flask, Google APIs, IServ API, etc.)
- Creates configuration files
- Initializes the database

Your friends can simply run `./setup.sh` and follow the prompts - no manual installation needed!

### Mobile Access (Android & iOS)

Nexus Hub works as a Progressive Web App (PWA) on mobile devices:

1. Start the server on your Mac with `./start.sh`
2. Note the **Mobile URL** shown in the terminal (e.g., `http://192.168.1.x:5050`)
3. On your phone, open this URL in the browser
4. Install as app:
   - **iOS**: Tap Share > "Add to Home Screen"
   - **Android**: Tap menu > "Add to Home Screen" or "Install App"

The mobile app works offline and syncs when connected.

### Environment Variables

Copy `.env.example` to `.env` and configure:

```
SECRET_KEY=your-secret-key
FLASK_ENV=development

GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_PROJECT_ID=your-project-id
```

## Cloud Deployment (Render)

Deploy your own Nexus Hub in one click - no Mac needed!

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/LeonManuel0705/Nexus)

**Or manually:**
1. Fork this repository to your GitHub
2. Go to [render.com](https://render.com) and sign up (free)
3. Click "New" → "Blueprint" → Connect your forked repo
4. Render will auto-configure everything from `render.yaml`

**After deployment:**
- Your app will be at `https://your-app-name.onrender.com`
- Add it to your phone's home screen as a PWA
- Each user creates their own account with separate data

**Note:** Free tier sleeps after 15 min inactivity (first load takes ~30 sec to wake)

The `render.yaml` blueprint configures:
- Python 3.11 web service (Frankfurt)
- PostgreSQL database (free tier)
- Automatic SSL/HTTPS

## Tech Stack

- **Backend**: Flask, Flask-SocketIO
- **Database**: SQLite (local) / PostgreSQL (production)
- **Frontend**: Vanilla JavaScript, CSS
- **APIs**: Google Calendar, Gmail, IServ
- **PWA**: Installable on Android & iOS with offline support

## Project Structure

```
Nexus/
├── app/
│   ├── app.py              # Main Flask application
│   ├── database.py         # Database abstraction layer
│   ├── calendar_service.py # Google Calendar integration
│   ├── google_oauth.py     # OAuth authentication
│   ├── iserv_service.py    # IServ API integration
│   ├── static/             # CSS, JS, images
│   └── templates/          # HTML templates
├── data/                   # Local SQLite database
├── setup.sh                # Automated setup script
├── start.sh                # Start script
├── requirements.txt        # Production dependencies
├── render.yaml             # Render deployment config
└── .env.example            # Environment template
```

## License

Private project.
