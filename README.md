# Nexus

A personal productivity system that brings together your calendar, tasks, email, school schedule, and more in one unified interface. Available as a native mobile app and web dashboard.

## Apps

### Mobile App (Flutter)
Native Android app with offline-first architecture.

**Features:**
- Dashboard with personalized overview
- Task management with deadlines and priorities
- Calendar with Google Calendar sync
- IServ integration (timetable, substitutions, homework)
- Training tracker with workout plans
- Email integration
- Notes with markdown support
- Bookmarks collection
- Review system for spaced repetition

### Web Dashboard (Flask)
Browser-based dashboard for desktop use.

**Features:**
- All mobile features accessible via browser
- Google OAuth authentication
- Progressive Web App (PWA) support
- Real-time updates via WebSocket

### Landing Page (Next.js)
Modern marketing website at [nexus website].

## Quick Start

### Mobile App

```bash
cd flutter_app
flutter pub get
flutter run
```

### Web Dashboard

```bash
./setup.sh  # First time only
./start.sh
# Open http://localhost:5050
```

### Landing Page Development

```bash
cd landing-page
npm install
npm run dev
# Open http://localhost:3000
```

Build for production:
```bash
npm run build
# Output exported to ../site/
```

## Project Structure

```
Nexus/
├── flutter_app/           # Flutter mobile app
│   ├── lib/
│   │   ├── screens/       # App screens
│   │   ├── providers/     # State management
│   │   ├── services/      # API & database services
│   │   └── widgets/       # Reusable components
│   └── pubspec.yaml
├── app/                   # Flask web backend
│   ├── app.py             # Main Flask application
│   ├── static/            # CSS, JS, images
│   └── templates/         # HTML templates
├── landing-page/          # Next.js marketing site
│   ├── app/               # Next.js app router pages
│   ├── components/        # React components
│   └── next.config.mjs
├── site/                  # Static export for Netlify
├── setup.sh               # Backend setup script
├── start.sh               # Backend start script
└── requirements.txt       # Python dependencies
```

## Tech Stack

**Mobile App:**
- Flutter / Dart
- SQLite (local database)
- Provider (state management)

**Web Backend:**
- Flask, Flask-SocketIO
- SQLite (local) / PostgreSQL (production)
- Google Calendar & Gmail APIs
- IServ API

**Landing Page:**
- Next.js 16 with App Router
- Tailwind CSS v4
- Framer Motion
- Static export for Netlify

## Deployment

**Landing Page (Netlify):**
- Publish directory: `site/`
- No build command needed (pre-built)

**Web Backend (Render):**
- Uses `render.yaml` blueprint
- PostgreSQL database included

## Environment Variables

Copy `.env.example` to `.env`:

```
SECRET_KEY=your-secret-key
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_PROJECT_ID=your-project-id
```

## Roadmap

See the [Roadmap](/landing-page/app/roadmap/page.tsx) for planned features including:
- Widget customization
- Public transit integration
- Focus mode
- AI assistant
- Cloud sync (opt-in)
- Habit tracking

## License

Private project.
