#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Building Docker image...${NC}"

# Build image
docker build -t ghcr.io/cthulhu-engineer/goit-ml-ops/sensor-quality-inference:latest .

echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${BLUE}📤 Pushing to GitHub Container Registry...${NC}"

# Login to GHCR (you'll need to provide token)
echo "Please login to GitHub Container Registry:"
echo "Create token at: https://github.com/settings/tokens (with write:packages scope)"
read -p "Enter GitHub username: " GH_USER
read -sp "Enter GitHub token: " GH_TOKEN
echo ""

echo $GH_TOKEN | docker login ghcr.io -u $GH_USER --password-stdin

# Push image
docker push ghcr.io/cthulhu-engineer/goit-ml-ops/sensor-quality-inference:latest

echo -e "${GREEN}✅ Image pushed successfully!${NC}"
echo ""
echo "Image: ghcr.io/cthulhu-engineer/goit-ml-ops/sensor-quality-inference:latest"
