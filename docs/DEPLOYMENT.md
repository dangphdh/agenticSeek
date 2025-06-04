# AgenticSeek Deployment Guide

This guide provides detailed instructions for deploying AgenticSeek locally. AgenticSeek is a private, local AI assistant that runs entirely on your machine without any cloud dependencies.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Installation Methods](#installation-methods)
4. [Deployment Options](#deployment-options)
5. [Configuration](#configuration)
6. [Starting Services](#starting-services)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Deployment](#advanced-deployment)

## Prerequisites

Before deploying AgenticSeek, ensure you have the following installed on your system:

### Required Software

1. **Python 3.10** (Recommended - other versions may cause dependency issues)
2. **Docker** (Latest version)
3. **Docker Compose** (Latest version)
4. **Google Chrome** (Latest version)
5. **ChromeDriver** (Automatically handled by installation scripts)

### System Requirements

- **RAM**: Minimum 8GB (16GB+ recommended for better performance)
- **Storage**: At least 10GB free space
- **OS**: Linux (Ubuntu/Debian recommended), macOS, or Windows
- **Internet**: Required for initial setup and web browsing capabilities

### Pre-installation Checks

#### Linux/macOS
```bash
# Check Python version
python3 --version

# Check Docker
docker --version
docker-compose --version

# Check if Docker daemon is running
docker info

# Check Chrome installation
google-chrome --version  # Linux
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version  # macOS
```

#### Windows
```cmd
# Check Python version
python --version

# Check Docker
docker --version
docker-compose --version

# Check Docker daemon
docker info
```

## Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Fosowl/agenticSeek.git
cd agenticSeek
```

### 2. Environment Configuration

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit the `.env` file with your preferred settings:

```bash
# Essential Configuration
WORK_DIR=/path/to/your/workspace  # Directory AgenticSeek can access
SEARXNG_BASE_URL=http://localhost:8080
BACKEND_PORT=7777

# LLM Configuration (for local models)
OLLAMA_PORT=11434
LM_STUDIO_PORT=1234
CUSTOM_ADDITIONAL_LLM_PORT=8000

# Optional API Keys (for external models)
OPENAI_API_KEY=your_openai_key_here
DEEPSEEK_API_KEY=your_deepseek_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here
```

**Important Notes:**
- Set `WORK_DIR` to a directory on your local machine that AgenticSeek can read and interact with
- Keep the directory size under 2GB to avoid Docker mounting issues
- API keys are optional - only needed if using external LLM providers

## Installation Methods

### Method 1: Automatic Installation (Recommended)

The automatic installation script will detect your OS and install all dependencies:

#### Linux/macOS
```bash
chmod +x install.sh
./install.sh
```

#### Windows
```cmd
install.bat
```

### Method 2: Manual Installation

If automatic installation fails, follow these manual steps:

#### Linux (Ubuntu/Debian)
```bash
# Update system packages
sudo apt-get update

# Install Python 3.10 and development tools
sudo apt-get install -y python3.10 python3.10-dev python3.10-venv python3.10-pip

# Install system dependencies
sudo apt-get install -y \
    build-essential \
    alsa-utils \
    portaudio19-dev \
    python3-pyaudio \
    libgtk-3-dev \
    libnotify-dev \
    libgconf-2-4 \
    libnss3 \
    libxss1

# Install Docker
sudo apt-get install -y docker.io docker-compose

# Add user to docker group (requires logout/login)
sudo usermod -aG docker $USER

# Create virtual environment
python3.10 -m venv agentic_seek_env
source agentic_seek_env/bin/activate

# Install Python dependencies
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

#### macOS
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew update
brew install python@3.10
brew install --cask chromedriver
brew install portaudio

# Install Docker Desktop manually from https://docker.com

# Create virtual environment
python3.10 -m venv agentic_seek_env
source agentic_seek_env/bin/activate

# Install Python dependencies
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

#### Windows
```cmd
# Install Python 3.10 from python.org
# Install Docker Desktop from docker.com
# Install Google Chrome

# Install pyreadline3 for Windows
pip install pyreadline3

# Create virtual environment
python -m venv agentic_seek_env
agentic_seek_env\Scripts\activate

# Install dependencies
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

## Deployment Options

AgenticSeek offers two main deployment modes:

### Mode 1: Core Services (Backend on Host)
This mode runs the frontend and search services in containers while keeping the backend on the host machine.

### Mode 2: Full Containerized Deployment
This mode runs all services including the backend in containers.

## Configuration

### Basic Configuration

Edit `config.ini` for basic settings:

```ini
[GENERAL]
provider_name = ollama
provider_server_address = http://127.0.0.1:11434
headless_browser = true
stealth_mode = true
```

### Advanced Configuration

For advanced users, additional configuration options are available:

- **Browser Settings**: Configure headless mode and stealth settings
- **Provider Settings**: Choose between different LLM providers (ollama, lm-studio, etc.)
- **Audio Settings**: Configure voice input/output settings

## Starting Services

### Quick Start (Recommended)

For most users, use the full deployment mode:

#### Linux/macOS
```bash
# Start all services
sudo ./start_services.sh full
```

#### Windows
```cmd
start ./start_services.cmd full
```

### Core Services Only

If you prefer to run the backend manually:

#### Linux/macOS
```bash
# Start core services (frontend + search)
sudo ./start_services.sh
```

#### Windows
```cmd
start ./start_services.cmd
```

Then start the backend manually:
```bash
# Activate virtual environment
source agentic_seek_env/bin/activate  # Linux/macOS
# agentic_seek_env\Scripts\activate  # Windows

# Start backend
python3 api.py
```

### CLI Mode

For command-line interface usage:

```bash
# Install packages first
./install.sh  # or install.bat on Windows

# Start core services
sudo ./start_services.sh  # Linux/macOS
# start ./start_services.cmd  # Windows

# Run CLI interface
python3 cli.py
```

## Verification

### 1. Check Service Status

Verify all services are running:

```bash
# Check Docker containers
docker ps

# Expected containers:
# - searxng (port 8080)
# - redis
# - frontend (port 3000)
# - backend (port 7777) - if using full mode
```

### 2. Access Web Interface

Open your browser and navigate to:
- **Frontend**: http://localhost:3000
- **SearXNG**: http://localhost:8080

### 3. Test Functionality

1. **Web Interface**: Send a test message to verify the AI responds
2. **Search**: Test web search functionality
3. **File Access**: Verify AgenticSeek can access your `WORK_DIR`

## Troubleshooting

### Common Issues

#### 1. Docker Permission Issues
```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in

# Or run with sudo
sudo ./start_services.sh full
```

#### 2. Port Conflicts
```bash
# Check if ports are in use
netstat -tulpn | grep :3000
netstat -tulpn | grep :8080
netstat -tulpn | grep :7777

# Kill processes using these ports if needed
sudo kill -9 $(lsof -t -i:3000)
```

#### 3. ChromeDriver Issues
```bash
# Check ChromeDriver installation
chromedriver --version

# For manual installation, download from:
# https://sites.google.com/chromium.org/driver/getting-started
```

#### 4. Python Dependencies
```bash
# If you encounter package conflicts
pip install --force-reinstall -r requirements.txt

# For audio issues on Linux
sudo apt-get install portaudio19-dev python3-pyaudio
```

#### 5. SearXNG Connection Issues
```bash
# Check if SearXNG is accessible
curl http://localhost:8080

# Verify environment variable
echo $SEARXNG_BASE_URL
```

### Container Logs

Check logs for debugging:

```bash
# View all container logs
docker-compose logs

# View specific service logs
docker-compose logs searxng
docker-compose logs frontend
docker-compose logs backend
```

### Memory Issues

If experiencing memory issues:

```bash
# Check system resources
free -h
df -h

# Reduce Docker resource usage in Docker Desktop settings
# Or increase system RAM/swap
```

## Advanced Deployment

### Remote LLM Server Setup

For users with powerful servers, you can run the LLM on a separate machine:

#### On the Server
```bash
# Clone repository
git clone --depth 1 https://github.com/Fosowl/agenticSeek.git
cd agenticSeek/llm_server/

# Install server dependencies
pip3 install -r requirements.txt

# Start LLM server
python3 app.py --provider ollama --port 3333
```

#### On the Client
Update your `.env` file to point to the remote server:
```bash
CUSTOM_ADDITIONAL_LLM_PORT=3333
# Update provider_server_address in config.ini to server IP
```

### Production Deployment

For production deployments:

1. **Use a reverse proxy** (nginx) for SSL termination
2. **Configure firewall** to only expose necessary ports
3. **Set up monitoring** for container health
4. **Configure backup** for important data
5. **Use Docker secrets** for sensitive configuration

### Scale Considerations

- **Single User**: Default configuration is sufficient
- **Multiple Users**: Consider scaling Redis and implementing user session management
- **High Performance**: Use GPU-accelerated containers for LLM inference

## Security Considerations

1. **Network Security**: AgenticSeek runs locally, but ensure firewall is configured
2. **File Access**: `WORK_DIR` should only contain files you want AI to access
3. **API Keys**: Store securely and never commit to version control
4. **Browser Security**: Stealth mode reduces detection but doesn't guarantee anonymity

## Maintenance

### Regular Updates

```bash
# Update repository
git pull origin main

# Rebuild containers
docker-compose down
docker-compose build --no-cache
```

### Cleanup

```bash
# Remove unused Docker resources
docker system prune -a

# Clear logs
docker-compose logs --tail=0 -f > /dev/null
```

---

**Note**: AgenticSeek is actively developed. Check the [GitHub repository](https://github.com/Fosowl/agenticSeek) for the latest updates and features.

For additional help, join the [Discord community](https://discord.gg/8hGDaME3TC) or check the [main README](../README.md).
