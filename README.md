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
2. Run the start script:
   ```bash
   ./Nexus.command
   ```
3. Open http://localhost:5001 in your browser

The script automatically:
- Creates a Python virtual environment (first run only)
- Installs dependencies
- Starts the Flask server
- Opens the browser

### Environment Variables

Copy `.env.example` to `.env` and configure:

```
SECRET_KEY=your-secret-key
FLASK_ENV=development

GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_PROJECT_ID=your-project-id
```

## Cloud Deployment

Nexus Hub supports deployment to Render.com with PostgreSQL.

1. Fork this repository
2. Create a new Web Service on Render
3. Connect your repository
4. Add environment variables for Google OAuth
5. Deploy

The included `render.yaml` blueprint configures:
- Python 3.11 web service
- PostgreSQL database
- Automatic SSL
- Frankfurt region

## Tech Stack

- **Backend**: Flask, Flask-SocketIO
- **Database**: SQLite (local) / PostgreSQL (production)
- **Frontend**: Vanilla JavaScript, CSS
- **APIs**: Google Calendar, Gmail, IServ
- **PWA**: Installable as a Progressive Web App

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
├── requirements.txt        # Production dependencies
├── render.yaml             # Render deployment config
└── .env.example            # Environment template
```

## License

Private project.
