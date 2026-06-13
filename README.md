# Exposing a Dockerized Python App to the Internet with ngrok

A step-by-step tutorial showing how to run a **Python (Flask)** application
inside **Docker** and make it reachable from the public internet using
**ngrok** — all orchestrated with Docker Compose.

---

## Why ngrok?

When you develop locally, your app lives on `localhost` and the outside world
can't reach it. ngrok creates a secure tunnel that gives your local container a
public `https://....ngrok-free.app` URL. That's invaluable for:

- **Testing webhooks** (Stripe, GitHub, payment gateways, social-login callbacks)
- **Sharing a work-in-progress** with a client or teammate
- **Testing on a real mobile device** over the internet

---

## How the pieces fit together

```
                         ngrok cloud
                              │  https://abc123.ngrok-free.app
                              │
        ┌─────────────────────┴──────────────────────┐
        │                Docker network                │
        │                                              │
        │   ┌───────────────┐       ┌──────────────┐  │
        │   │  ngrok agent  │──────▶│  web (Flask)  │  │
        │   │  :4040 (UI)   │ web:5000   :5000       │  │
        │   └───────────────┘       └──────────────┘  │
        └──────────────────────────────────────────────┘
```

The key idea: **the ngrok container forwards to the Flask container by its
Docker service name** (`web:5000`), because both are on the same Docker network.

---

## Project layout

```
ngrok/
├── app/
│   ├── main.py            # Flask app (/, /api/hello, /webhook)
│   ├── requirements.txt   # Flask
│   └── Dockerfile         # Python 3.12 environment
├── logs/
│   └── webhooks.log       # one JSON line per webhook hit (git-ignored)
├── docker-compose.yml     # 'web' + 'ngrok' services
├── ngrok.yml              # ngrok tunnel config (authtoken from env)
├── .env.example           # template for your authtoken
├── .env                   # your actual authtoken (git-ignored)
├── get-ngrok-url.sh       # prints the live public URL
└── README.md
```

---

## Step 1 — Get an ngrok authtoken

1. Create a free account at <https://dashboard.ngrok.com/signup>
2. Copy your token from <https://dashboard.ngrok.com/get-started/your-authtoken>
3. Put it in a `.env` file:

```bash
cp .env.example .env
# edit .env and paste your token into NGROK_AUTHTOKEN
```

---

## Step 2 — Build & run the Python app (local only)

```bash
docker compose up -d web --build
```

Visit <http://localhost:5000> — you should see the "It works!" page.
The app is running in a container, but only reachable locally.

---

## Step 3 — Open the public tunnel

```bash
docker compose up -d ngrok --build
```

This starts two containers: `web` (Flask) and `ngrok` (the tunnel).
The `ngrok` service has `depends_on: web`, so `web` starts automatically even
if it wasn't already running.

---

## Step 4 — Find your public URL

```bash
curl -s http://localhost:4040/api/tunnels | grep -Po '"public_url":"\K[^"]+' | head -1
```

Or use the helper script:

```bash
./get-ngrok-url.sh
```

You'll get something like:

```
🔗 Your ngrok public URLs:
==========================
  ✅ python-app: https://abc123.ngrok-free.app

🌐 Inspect requests at: http://localhost:4040
```

Open that `https://...` URL from any device, anywhere.

---

## Step 5 — Test it

```bash
# Replace with YOUR public URL
URL=https://abc123.ngrok-free.app

curl $URL/api/hello
curl -X POST $URL/webhook -H "Content-Type: application/json" -d '{"event":"test"}'
```

Open <http://localhost:4040> to **inspect every request** — headers, body,
response — and even **replay** them. Great for debugging webhooks.

---

## Step 6 — Webhook logging

Every POST to `/webhook` is logged as a JSON line in `logs/webhooks.log`:

```json
{"time": "2026-06-13T01:00:00Z", "source_ip": "1.2.3.4", "event": "push", "delivery": "abc-123", "payload": {...}}
```

Watch it live:

```bash
tail -f logs/webhooks.log
```

Fields logged per hit:

| Field | Description |
|---|---|
| `time` | UTC timestamp |
| `source_ip` | IP address of the caller |
| `event` | `X-GitHub-Event` header (e.g. `push`, `ping`) |
| `delivery` | `X-GitHub-Delivery` header (GitHub's unique ID per request) |
| `payload` | Full JSON body |

The file rotates at 1 MB and keeps 5 backups.

---

## Testing with a real GitHub webhook

1. Go to any repo you own → **Settings → Webhooks → Add webhook**
2. Set **Payload URL** to `https://<your-ngrok-url>/webhook`
3. Set **Content type** to `application/json`
4. Leave **Secret** blank for now
5. Choose **Just the push event** and click **Add webhook**

GitHub sends a `ping` event immediately. You'll see it appear in
`logs/webhooks.log` and at <http://localhost:4040>.

---

## How the configuration works

### `docker-compose.yml`

- **`web`** builds the image in `app/`, exposes port `5000`, and mounts
  `./logs` so webhook log files are written to your host machine.
- **`ngrok`** uses the official `ngrok/ngrok:latest` image and mounts
  `ngrok.yml`. It declares `depends_on: web`, so starting `ngrok` also
  starts `web`.
- Both share `tutorial_net`, which is what lets ngrok reach the app as `web:5000`.

### `ngrok.yml`

```yaml
version: "2"
# authtoken is NOT set here — the agent reads NGROK_AUTHTOKEN from the env
web_addr: "0.0.0.0:4040"   # makes the UI reachable from the host
tunnels:
  python-app:
    proto: http
    addr: web:5000          # docker service name : internal port
    inspect: true
```

> The ngrok agent does **not** expand `${VAR}` placeholders inside `ngrok.yml`.
> Leave `authtoken` out of the file entirely and set `NGROK_AUTHTOKEN` in your
> `.env` — the agent picks it up from the environment automatically.

---

## Common commands

```bash
# App only, no tunnel
docker compose up -d web --build

# App + public tunnel
docker compose up -d ngrok --build

# Get the public URL
curl -s http://localhost:4040/api/tunnels | grep -Po '"public_url":"\K[^"]+' | head -1

# Watch webhook log
tail -f logs/webhooks.log

# Tail container logs
docker compose logs -f web
docker compose logs -f ngrok

# Stop everything
docker compose down
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `ERR_NGROK_105` / auth error | `NGROK_AUTHTOKEN` is missing or wrong in `.env`. |
| `ERR_NGROK_4018` | Token expired or account limit reached — check your dashboard. |
| No tunnels in `get-ngrok-url.sh` | The ngrok container isn't running — `docker compose up -d ngrok`. |
| Tunnel up but 502 / "bad gateway" | The `web` app isn't ready — check `docker compose logs web`. |
| `logs/webhooks.log` permission denied | Run `sudo chown -R $USER:$USER logs/` once to fix ownership. |
| Want a fixed domain | Free plan gives random URLs on each restart; reserve a static domain in the ngrok dashboard and add `domain:` under the tunnel in `ngrok.yml`. |
| Browser shows interstitial warning | Add header `ngrok-skip-browser-warning: true` to API/curl requests. |

---

## Notes on the free plan

- One online tunnel at a time, random URL on each restart.
- An interstitial warning page appears for browser visits (skippable for API
  calls via the `ngrok-skip-browser-warning` header).
- More than enough for webhook testing and demos.
