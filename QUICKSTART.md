# Quick Start Guide

## 1. Start All Services

```bash
docker compose up -d
```

This starts:
- ✅ Vue.js frontend (Nginx) on port 80
- ✅ Python Flask backend on port 5000
- ✅ Logs collected in `logs/` directory

## 2. Access the Application

Open your browser:
- **Frontend**: http://localhost
- **API Direct**: http://localhost:5000/api/hello

## 3. (Optional) Expose via ngrok

If you have an ngrok account:

```bash
# Set your authtoken in .env
echo "NGROK_AUTHTOKEN=your_token_here" >> .env

# Start ngrok tunnel
docker compose up -d ngrok

# View the public URLs
docker compose logs ngrok
```

Then access at the ngrok URLs shown in the logs.

## 4. Stop Services

```bash
docker compose down
```

## That's it! 🎉

The frontend can now communicate with the Python backend.

### Troubleshooting

**Frontend shows error connecting to backend?**
```bash
docker compose logs web
```

**Need to rebuild after making changes?**
```bash
docker compose up -d --build
```

**Want to see logs in real-time?**
```bash
docker compose logs -f
```

See `SETUP.md` for detailed documentation.
