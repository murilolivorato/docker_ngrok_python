.PHONY: help up down restart logs build dev-frontend dev-backend clean ngrok-start ngrok-logs webhook-logs

help:
	@echo "Vue.js + Python + Docker + ngrok - Available Commands"
	@echo ""
	@echo "  make up                 Start all services (frontend, backend, optional ngrok)"
	@echo "  make down               Stop all services"
	@echo "  make restart            Restart all services"
	@echo "  make logs               View logs from all services (streaming)"
	@echo "  make build              Rebuild Docker images"
	@echo ""
	@echo "  make dev-frontend       Run Vue.js dev server locally (with npm run dev)"
	@echo "  make dev-backend        Run Python Flask locally (python main.py)"
	@echo ""
	@echo "  make ngrok-start        Start ngrok tunneling (requires NGROK_AUTHTOKEN in .env)"
	@echo "  make ngrok-logs         View ngrok logs and public URLs"
	@echo "  make webhook-logs       View webhook log file"
	@echo ""
	@echo "  make clean              Remove all containers, images, volumes"
	@echo "  make status             Show status of all services"
	@echo ""

# Main commands
up:
	@echo "Starting all services..."
	docker compose up -d
	@echo "✓ Services started"
	@echo ""
	@echo "Access the application:"
	@echo "  Frontend:  http://localhost"
	@echo "  Backend:   http://localhost:5000"
	@echo "  ngrok UI:  http://localhost:4040"

down:
	@echo "Stopping all services..."
	docker compose down
	@echo "✓ Services stopped"

restart: down up

status:
	@docker compose ps

logs:
	docker compose logs -f

build:
	@echo "Building images..."
	docker compose build --no-cache
	@echo "✓ Build complete"

# Development commands
dev-frontend:
	@echo "Starting Vue.js dev server..."
	@cd frontend && npm install && npm run dev

dev-backend:
	@echo "Starting Flask dev server..."
	@cd app && pip install -r requirements.txt && python main.py

# ngrok commands
ngrok-start:
	@echo "Starting ngrok tunnels..."
	docker compose up -d ngrok
	@echo "✓ ngrok started"
	@echo ""
	@make ngrok-logs

ngrok-logs:
	@echo "Fetching ngrok URLs..."
	@docker compose logs ngrok | grep -A 5 "started tunnel" || echo "Tunnels still starting..."

webhook-logs:
	@echo "Webhook log file:"
	docker compose exec web tail -100 logs/webhooks.log

# Cleanup commands
clean:
	@echo "⚠️  Removing all containers, images, and volumes..."
	docker compose down -v --rmi all
	@echo "✓ Cleaned up"

clean-volumes:
	@echo "Removing volumes (logs/webhooks.log, etc.)..."
	docker compose down -v
	@echo "✓ Volumes removed"

rebuild:
	@make clean
	@make build
	@make up

# Shortcuts
ps:
	docker compose ps

shell-backend:
	docker compose exec web /bin/bash

shell-frontend:
	docker compose exec frontend /bin/sh

test-api:
	@echo "Testing backend API..."
	curl -s http://localhost:5000/api/hello | jq . || echo "Backend not responding"

test-webhook:
	@echo "Sending test webhook..."
	curl -X POST http://localhost:5000/webhook \
		-H "Content-Type: application/json" \
		-d '{"test": true, "message": "Hello from Makefile"}'
	@echo ""
