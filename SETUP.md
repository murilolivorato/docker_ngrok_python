# Vue.js + Python + Docker + ngrok Setup

This project demonstrates a full-stack application with:
- **Frontend**: Vue.js 3 application served by Nginx
- **Backend**: Python Flask API with CORS support
- **Tunneling**: ngrok for exposing services to the public internet
- **Containerization**: Docker & Docker Compose

## Project Structure

```
.
├── frontend/                 # Vue.js application
│   ├── src/
│   │   ├── App.vue          # Main component
│   │   └── main.js          # Entry point
│   ├── index.html           # HTML template
│   ├── package.json         # Node.js dependencies
│   ├── vite.config.js       # Vite configuration
│   ├── nginx.conf           # Nginx server configuration
│   ├── Dockerfile           # Multi-stage Docker build
│   └── .env.example         # Environment variables template
│
├── app/                      # Python Flask backend
│   ├── main.py              # Flask application
│   ├── requirements.txt      # Python dependencies
│   └── Dockerfile           # Python environment
│
├── docker-compose.yml        # Docker Compose configuration
├── ngrok.yml                 # ngrok tunnel configuration
├── .env                      # Environment variables (secrets)
└── .env.example              # Environment variables template
```

## Quick Start

### 1. Prerequisites

- Docker & Docker Compose installed
- ngrok account and authtoken (if you want to expose to the internet)

### 2. Environment Setup

```bash
# Copy the example .env file
cp .env.example .env

# Add your ngrok authtoken to .env
# NGROK_AUTHTOKEN=your_token_here
```

### 3. Run Everything

```bash
# Start all services (frontend, backend, logs collected)
docker compose up -d

# Check if services are running
docker compose ps
```

**Access the application:**
- Frontend: http://localhost (or http://localhost:80)
- Backend API: http://localhost:5000
- ngrok Inspection UI: http://localhost:4040

### 4. Optional: Expose with ngrok

```bash
# Start the ngrok tunnel
docker compose up -d ngrok

# Get the public URLs
docker compose logs ngrok | grep -i "started tunnel"
```

The ngrok dashboard at `http://localhost:4040` shows all incoming requests.

## Running Services Individually

```bash
# Start only the backend
docker compose up -d web

# Start only the frontend
docker compose up -d frontend

# Start backend + ngrok tunnel
docker compose up -d web ngrok

# Start everything
docker compose up -d
```

## Development

### Frontend Development

If you want to work on the Vue.js app locally with hot reload:

```bash
cd frontend
npm install
npm run dev
```

The dev server runs on `http://localhost:3000` and proxies API calls to the Python backend at `http://localhost:5000`.

### Backend Development

The Flask backend runs with `debug=True` in Docker, so changes to `app/main.py` are reflected immediately.

For local development without Docker:

```bash
cd app
pip install -r requirements.txt
python main.py
```

The backend API runs on `http://localhost:5000`.

## Frontend Features

The Vue.js frontend demonstrates:
- **Component**: Single Vue component (`App.vue`) with reactive data
- **API Integration**: Axios HTTP client for backend communication
- **Error Handling**: Loading and error states
- **Styling**: Responsive CSS with gradient background
- **Webhook Testing**: Form to send test payloads to the backend

## Backend API Endpoints

- `GET /` - HTML landing page
- `GET /api/hello` - JSON endpoint returning server info
- `POST /webhook` - Webhook receiver (logs all payloads)

All endpoints support CORS, so the frontend can communicate freely.

## Docker Images

The Docker Compose setup builds and runs:

1. **frontend** (Nginx)
   - Multi-stage build: Node.js build stage → Nginx production image
   - Serves Vue.js SPA with intelligent routing
   - Proxies `/api` and `/webhook` requests to the backend

2. **web** (Python)
   - Flask application with CORS enabled
   - Exposes port 5000
   - Logs webhook requests to `logs/webhooks.log`

3. **ngrok** (optional)
   - Creates HTTP tunnels to frontend (port 80) and backend (port 5000)
   - Requires `NGROK_AUTHTOKEN` in `.env`

## Logs and Debugging

View logs from all services:

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f frontend
docker compose logs -f web
docker compose logs -f ngrok

# Backend webhook logs
docker compose exec web tail -f logs/webhooks.log
```

## Environment Variables

Create a `.env` file based on `.env.example`:

```bash
# Required for ngrok tunneling
NGROK_AUTHTOKEN=your_ngrok_token_here

# Optional - set UID/GID for container user (matches your local user)
UID=1000
GID=1000
```

## Cleanup

```bash
# Stop all services
docker compose down

# Remove volumes (logs, etc.)
docker compose down -v

# Remove images
docker compose down -v --rmi all
```

## Troubleshooting

### Frontend shows "Failed to connect to backend"
- Ensure the `web` service is running: `docker compose ps`
- Check backend logs: `docker compose logs web`
- Verify CORS is enabled in the backend (should be automatic)

### ngrok tunnels not starting
- Check `NGROK_AUTHTOKEN` in `.env` is correct
- View ngrok logs: `docker compose logs ngrok`
- Visit ngrok dashboard: http://localhost:4040

### Port conflicts
- Change port mappings in `docker-compose.yml` if ports are in use
- Frontend default: 80 → 3000 (dev)
- Backend default: 5000
- ngrok UI: 4040

## Next Steps

- **Customize the Vue component**: Edit `frontend/src/App.vue`
- **Add backend routes**: Edit `app/main.py`
- **Deploy**: Build images and run on a server with Docker
- **Scale**: Use Docker Compose to run multiple instances

## Resources

- [Vue.js Documentation](https://vuejs.org/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [ngrok Documentation](https://ngrok.com/docs)
