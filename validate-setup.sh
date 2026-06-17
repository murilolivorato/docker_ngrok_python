#!/bin/bash

# Validate Docker setup for Vue.js + Python project
set -e

echo "🔍 Validating Docker project setup..."
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check Docker
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Docker not installed${NC}"
    ((ERRORS++))
fi

# Check Docker Compose
echo -n "Checking Docker Compose... "
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Docker Compose not installed${NC}"
    ((ERRORS++))
fi

echo ""
echo "📁 Checking project structure..."
echo ""

# Check critical files and directories
files=(
    "docker-compose.yml"
    "app/Dockerfile"
    "app/main.py"
    "app/requirements.txt"
    "frontend/Dockerfile"
    "frontend/package.json"
    "frontend/vite.config.js"
    "frontend/index.html"
    "frontend/src/App.vue"
    "frontend/src/main.js"
    "frontend/nginx.conf"
    "ngrok.yml"
)

for file in "${files[@]}"; do
    echo -n "  $file ... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Missing${NC}"
        ((ERRORS++))
    fi
done

echo ""
echo "✅ Checking configuration files..."
echo ""

# Check docker-compose.yml syntax
echo -n "  docker-compose.yml syntax ... "
if docker compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Invalid syntax${NC}"
    ((ERRORS++))
fi

# Check for CORS in backend
echo -n "  Flask CORS enabled ... "
if grep -q "flask_cors\|CORS" app/main.py; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} CORS not found"
    ((WARNINGS++))
fi

# Check for Flask-CORS in requirements
echo -n "  Flask-CORS in requirements ... "
if grep -q "Flask-CORS" app/requirements.txt; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Flask-CORS not in requirements.txt${NC}"
    ((ERRORS++))
fi

# Check ngrok config
echo -n "  ngrok.yml has tunnels ... "
if grep -q "tunnels:" ngrok.yml; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ No tunnels configured${NC}"
    ((ERRORS++))
fi

echo ""
echo "📝 Checking documentation..."
echo ""

docs=(
    "QUICKSTART.md"
    "SETUP.md"
    "PROJECT_SUMMARY.md"
)

for doc in "${docs[@]}"; do
    echo -n "  $doc ... "
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC} Missing (optional)"
        ((WARNINGS++))
    fi
done

echo ""
echo "🔐 Checking environment files..."
echo ""

# Check .env
echo -n "  .env file ... "
if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} .env not found (create from .env.example)"
    ((WARNINGS++))
fi

# Check .env.example
echo -n "  .env.example file ... "
if [ -f ".env.example" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} .env.example not found"
    ((WARNINGS++))
fi

echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Project is ready to use.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. docker compose up -d          (start services)"
    echo "  2. Open http://localhost        (access frontend)"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Project is mostly ready with $WARNINGS warnings${NC}"
    echo ""
    echo "Warnings:"
    if [ ! -f ".env" ]; then
        echo "  • Create .env file (copy from .env.example)"
    fi
    echo ""
    exit 0
else
    echo -e "${RED}✗ Setup failed with $ERRORS errors and $WARNINGS warnings${NC}"
    echo ""
    echo "Please fix the errors above and run this script again."
    echo ""
    exit 1
fi
