# InvestBot Initial Setup Guide

Complete step-by-step setup instructions to get InvestBot running 100% from scratch.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [System Requirements](#system-requirements)
- [Step 1: Repository Setup](#step-1-repository-setup)
- [Step 2: Environment Configuration](#step-2-environment-configuration)
- [Step 3: Database Setup](#step-3-database-setup)
- [Step 4: Dependencies Installation](#step-4-dependencies-installation)
- [Step 5: API Keys Configuration](#step-5-api-keys-configuration)
- [Step 6: Services Startup](#step-6-services-startup)
- [Step 7: Health Verification](#step-7-health-verification)
- [Step 8: Test Suite Execution](#step-8-test-suite-execution)
- [Step 9: Initial Data Setup](#step-9-initial-data-setup)
- [Step 10: Production Deployment](#step-10-production-deployment)
- [Troubleshooting](#troubleshooting)
- [Quick Reference](#quick-reference)

## 🔧 Prerequisites

### Required Software
- **Node.js**: 18.0+ ([Download](https://nodejs.org/))
- **Docker**: Latest version ([Download](https://www.docker.com/))
- **Docker Compose**: Included with Docker Desktop
- **Git**: Latest version ([Download](https://git-scm.com/))

### Optional but Recommended
- **Visual Studio Code**: With TypeScript and Docker extensions
- **TablePlus** or **pgAdmin**: For database management
- **Postman** or **Insomnia**: For API testing

### System Requirements
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 5GB free space
- **OS**: macOS, Linux, or Windows with WSL2
- **Network**: Stable internet connection for API integrations

## 🚀 Step 1: Repository Setup

### 1.1 Clone Repository
```bash
# Clone the repository
git clone <your-repository-url> investbot
cd investbot

# Verify project structure
ls -la
```

**Expected output:**
```
backend/
frontend/ 
tests/
docker-compose.yml
package.json
README.md
```

### 1.2 Check Project Integrity
```bash
# Run status check
node check-status.js
```

**Expected output:**
```
✅ All critical files present
✅ API routes implemented
✅ Services layer complete
✅ Test suite ready
```

---

## 🔐 Step 2: Environment Configuration

### 2.1 Create Environment Files

#### Main Environment File
```bash
# Copy template
cp .env.example .env

# Edit with your settings
nano .env
```

**Required `.env` configuration:**
```bash
# Database Configuration
DATABASE_URL="postgresql://investbot:secure_password@localhost:5433/investbot"
REDIS_URL="redis://localhost:6379"

# API Keys (Get from respective providers)
OPENAI_API_KEY="sk-your-openai-key-here"
ALPACA_API_KEY="your-alpaca-key"
ALPACA_SECRET_KEY="your-alpaca-secret"
ALPACA_BASE_URL="https://paper-api.alpaca.markets"  # Paper trading

# Optional APIs
COINGECKO_API_KEY="your-coingecko-key"
MEMESCAN_API_KEY="your-memescan-key"

# Security
JWT_SECRET="your-super-secure-jwt-secret-minimum-32-characters"
ENCRYPTION_KEY="your-32-character-encryption-key"

# Application Settings
NODE_ENV="development"
LOG_LEVEL="info"
PORT=3000
BACKEND_PORT=3001

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000  # 15 minutes
RATE_LIMIT_MAX_REQUESTS=100

# Trading Settings
DEFAULT_RISK_TOLERANCE="MODERATE"
MAX_DAILY_LOSS=1000
MAX_POSITION_SIZE=0.1  # 10% of portfolio
```

#### Test Environment File
```bash
# Copy for testing
cp .env .env.test

# Edit test-specific settings
nano .env.test
```

**Test environment modifications:**
```bash
# Use test database
DATABASE_URL="postgresql://test_user:test_pass@localhost:5432/investbot_test"

# Use sandbox/test API keys
ALPACA_BASE_URL="https://paper-api.alpaca.markets"
OPENAI_API_KEY="sk-test-your-test-key"

# Lower limits for testing
RATE_LIMIT_MAX_REQUESTS=1000
MAX_DAILY_LOSS=100
```

---

## 🗄️ Step 3: Database Setup

### 3.1 Start Database Services
```bash
# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Wait for services to be ready (30-60 seconds)
sleep 60

# Verify database is running
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE                 STATUS
xxx            postgres:16-alpine    Up X minutes (healthy)
xxx            redis:7-alpine        Up X minutes (healthy)
```

### 3.2 Database Initialization
```bash
# Navigate to backend
cd backend

# Install dependencies first
npm install

# Run database migrations
npx prisma migrate deploy

# Generate Prisma client
npx prisma generate

# Seed initial data (optional)
npx prisma db seed
```

### 3.3 Verify Database Connection
```bash
# Test connection
npx prisma studio
```
- Opens database management UI at `http://localhost:5555`
- Verify tables are created correctly

---

## 📦 Step 4: Dependencies Installation

### 4.1 Backend Dependencies
```bash
# Install backend packages
cd backend
npm install

# Verify critical packages
npm list typescript prisma @prisma/client express
```

### 4.2 Frontend Dependencies
```bash
# Install frontend packages
cd ../frontend
npm install

# Install missing UI components
npm install lucide-react recharts @radix-ui/react-icons @types/node

# Install test dependencies
npm install --save-dev @playwright/test jest @types/jest

# Verify critical packages
npm list next react typescript @prisma/client
```

### 4.3 Shared Dependencies
```bash
# Install shared package dependencies
cd ../shared
npm install

# Build shared package
npm run build
```

### 4.4 Root Dependencies
```bash
# Install root level dependencies
cd ..
npm install

# Install Playwright browsers
npx playwright install

# Verify Playwright installation
npx playwright --version
```

---

## 🔑 Step 5: API Keys Configuration

### 5.1 OpenAI API Key Setup
1. Visit [OpenAI API Keys](https://platform.openai.com/api-keys)
2. Create new API key
3. Copy key to `.env` file
4. Test connection:
```bash
curl -X POST http://localhost:3000/api/openai-test \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'
```

### 5.2 Alpaca Trading API Setup
1. Visit [Alpaca Markets](https://alpaca.markets/)
2. Create paper trading account
3. Generate API keys
4. Add to `.env` file
5. Test connection:
```bash
# Test will be available after services start
```

### 5.3 Optional API Keys
**CoinGecko (for crypto data):**
1. Visit [CoinGecko API](https://www.coingecko.com/en/api)
2. Get free API key
3. Add to `.env` file

**MemeScan (for memecoin data):**
1. Contact provider for API access
2. Add key to `.env` file

### 5.4 Verify API Configuration
```bash
# Run API key verification script
cd tests
node scripts/verify-api-keys.js
```

---

## 🚀 Step 6: Services Startup

### 6.1 Start All Services (Recommended)
```bash
# From project root
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

**Expected services:**
- **PostgreSQL**: Port 5433
- **Redis**: Port 6379  
- **Backend API**: Port 3001
- **Frontend**: Port 3000
- **Nginx**: Port 80 (production)

### 6.2 Alternative: Manual Startup
If Docker issues occur, start services manually:

#### Terminal 1 - Backend
```bash
cd backend
npm run dev
```

#### Terminal 2 - Frontend
```bash
cd frontend
npm run dev
```

#### Terminal 3 - Database (if needed)
```bash
# Use local PostgreSQL and Redis installations
```

### 6.3 Monitor Startup Logs
```bash
# Follow all service logs
docker-compose logs -f

# Follow specific service
docker-compose logs -f frontend
docker-compose logs -f backend
```

**Wait for these success messages:**
```
backend    | ✅ Server started on port 3001
frontend   | ✅ Next.js ready on http://localhost:3000
postgres   | database system is ready to accept connections
redis      | Ready to accept connections
```

---

## 🏥 Step 7: Health Verification

### 7.1 Service Health Checks
```bash
# Check all services
curl http://localhost:3000/api/health
curl http://localhost:3001/api/health

# Detailed status check
node check-status.js
```

**Expected responses:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "services": {
    "database": "connected",
    "redis": "connected",
    "apis": "configured"
  }
}
```

### 7.2 Database Connectivity
```bash
# Test database queries
curl http://localhost:3000/api/system-status
```

### 7.3 Frontend Loading
1. Open browser: `http://localhost:3000`
2. Verify dashboard loads
3. Check navigation menu works
4. Test responsive design

**Expected:**
- ✅ Dashboard displays
- ✅ Navigation works  
- ✅ No console errors
- ✅ Real-time data loading

### 7.4 API Endpoint Testing
```bash
# Test critical endpoints
curl -X POST http://localhost:3000/api/trade-validation \
  -H "Content-Type: application/json" \
  -d '{"action":"validate","data":{"symbol":"AAPL","action":"buy","quantity":1,"price":150}}'

curl http://localhost:3000/api/bot-config

curl http://localhost:3000/api/market/status
```

---

## 🧪 Step 8: Test Suite Execution

### 8.1 Quick Health Test
```bash
# Run basic health tests
npm run test:health-check
```

### 8.2 Unit Tests
```bash
# Run all API unit tests
cd tests
npm run test:unit

# Run specific test phases
npm run test:phase1  # Foundation
npm run test:phase2  # Trading Core
npm run test:phase3  # Advanced Features
```

**Expected output:**
```
✅ Phase 1: Foundation Tests - 15/15 passed
✅ Phase 2: Trading Core Tests - 12/12 passed  
✅ Phase 3: Advanced Features Tests - 18/18 passed
```

### 8.3 E2E Tests
```bash
# Ensure services are running first
npm run test:e2e

# Or specific browser
npm run test:e2e:chromium
```

### 8.4 Comprehensive Test Suite
```bash
# Run complete test suite (20-30 minutes)
./run-all-tests.sh

# View detailed reports
open test-results/test-report.html
```

**Success criteria:**
- ✅ All unit tests pass (85%+ coverage)
- ✅ All E2E tests pass
- ✅ No critical failures
- ✅ Performance within limits

---

## 💾 Step 9: Initial Data Setup

### 9.1 Configure API Providers
1. Navigate to: `http://localhost:3000/api-config`
2. Add OpenAI configuration:
   - **Provider**: OpenAI
   - **API Key**: Your OpenAI key
   - **Base URL**: `https://api.openai.com/v1`
   - **Model**: `gpt-4`
3. Test connection
4. Save configuration

### 9.2 Set Up Trading Bot
1. Navigate to: `http://localhost:3000/bot-config`
2. Configure trading settings:
   - **Max Daily Loss**: $100 (for testing)
   - **Trading Mode**: Paper Trading
   - **Asset Allocation**: 60% Stocks, 30% Crypto, 10% Memecoins
   - **Risk Tolerance**: Moderate
   - **Confidence Threshold**: 0.7
3. Save configuration

### 9.3 Configure Data Feeds
1. Navigate to: `http://localhost:3000/system` → Data Feeds
2. Add data sources:
   - **Alpaca**: Stock market data
   - **CoinGecko**: Cryptocurrency data
   - **Custom**: Any additional feeds
3. Test connections
4. Save configuration

### 9.4 Verify Initial Setup
```bash
# Check configurations were saved
curl http://localhost:3000/api/bot-config
curl http://localhost:3000/api/api-config
curl http://localhost:3000/api/data-feeds
```

---

## 🌐 Step 10: Production Deployment

### 10.1 Production Environment Setup
```bash
# Create production environment file
cp .env .env.production

# Edit production settings
nano .env.production
```

**Production environment changes:**
```bash
NODE_ENV="production"
LOG_LEVEL="warn"

# Use production database
DATABASE_URL="postgresql://prod_user:secure_pass@prod-db:5432/investbot_prod"

# Use production API endpoints
ALPACA_BASE_URL="https://api.alpaca.markets"  # Live trading

# Stronger security
JWT_SECRET="production-super-secure-jwt-secret-64-characters-minimum"

# Production limits
RATE_LIMIT_MAX_REQUESTS=50
MAX_DAILY_LOSS=5000
```

### 10.2 Production Build
```bash
# Build all services
docker-compose -f docker-compose.prod.yml build

# Start production services
docker-compose -f docker-compose.prod.yml up -d
```

### 10.3 SSL Configuration
```bash
# Configure SSL certificates in nginx/nginx.conf
# Or use Let's Encrypt with certbot

# Update docker-compose.prod.yml with SSL settings
```

### 10.4 Monitoring Setup
```bash
# Set up monitoring (optional)
# - Prometheus for metrics
# - Grafana for dashboards
# - AlertManager for notifications
```

---

## 🚨 Troubleshooting

### Common Issues

#### Issue: "Port already in use"
```bash
# Kill processes using ports
lsof -ti :3000 | xargs kill -9
lsof -ti :3001 | xargs kill -9

# Or use different ports in docker-compose.yml
```

#### Issue: "Database connection failed"
```bash
# Check database is running
docker ps | grep postgres

# Check connection string in .env
# Verify DATABASE_URL format

# Reset database
docker-compose down -v
docker-compose up -d postgres
```

#### Issue: "API keys not working"
```bash
# Verify keys in .env file
cat .env | grep API_KEY

# Test individual APIs
node tests/scripts/verify-api-keys.js

# Check API provider status pages
```

#### Issue: "Frontend not loading"
```bash
# Check frontend logs
docker-compose logs frontend

# Clear Next.js cache
cd frontend
rm -rf .next
npm run dev
```

#### Issue: "Tests failing"
```bash
# Run individual test phases
npm run test:phase1
npm run test:phase2

# Check test database
npm run test:db:check

# Reset test environment
npm run test:clean
npm run test:install
```

### Debug Mode
```bash
# Enable verbose logging
export DEBUG=*
npm run dev

# Run specific component in debug mode
cd backend
npm run dev:debug

cd frontend
npm run dev:debug
```

### Performance Issues
```bash
# Check system resources
docker stats

# Optimize memory usage
export NODE_OPTIONS="--max-old-space-size=4096"

# Reduce parallel workers
export TEST_WORKERS=1
```

---

## 🎯 Quick Reference

### Essential Commands
```bash
# Start everything
docker-compose up -d

# Stop everything  
docker-compose down

# View logs
docker-compose logs -f

# Run tests
./tests/run-all-tests.sh

# Check status
node check-status.js

# Reset everything
docker-compose down -v && docker-compose up -d --build
```

### Important URLs
- **Frontend Dashboard**: `http://localhost:3000`
- **Backend API**: `http://localhost:3001`
- **Database Admin**: `http://localhost:5555` (Prisma Studio)
- **API Documentation**: `http://localhost:3000/api-docs`

### Default Credentials
- **Database**: `investbot` / `secure_password`
- **Test Database**: `test_user` / `test_pass`
- **Admin**: Configured in your `.env` file

### File Locations
- **Logs**: `logs/`
- **Database**: `database/`
- **Test Results**: `test-results/`
- **Screenshots**: `tests/e2e/screenshots/`

---

## ✅ Success Checklist

After completing all steps, verify these items:

### ✅ **Basic Functionality**
- [ ] All services start without errors
- [ ] Frontend loads at `http://localhost:3000`
- [ ] Backend responds at `http://localhost:3001`
- [ ] Database connections work
- [ ] API keys are configured

### ✅ **Core Features**  
- [ ] Bot configuration saves successfully
- [ ] API configuration connects to external services
- [ ] Trading validation works
- [ ] Market data feeds connect
- [ ] Dashboard displays real data

### ✅ **Advanced Features**
- [ ] AI analysis generates reports
- [ ] Autonomous bot can be started/stopped
- [ ] Research workers execute tasks
- [ ] Risk management systems active
- [ ] Emergency stop functions work

### ✅ **Testing & Quality**
- [ ] All unit tests pass (45+ tests)
- [ ] E2E tests pass (browser automation)
- [ ] Test coverage > 85%
- [ ] No critical security warnings
- [ ] Performance within acceptable limits

### ✅ **Production Readiness**
- [ ] Environment variables secured
- [ ] Database properly configured
- [ ] API rate limiting active
- [ ] Monitoring and logging set up
- [ ] Backup procedures defined

---

## 🎉 Congratulations!

You now have a **fully functional, professional-grade AI trading platform** with:

- **9 API endpoints** for complete trading functionality
- **Autonomous bot management** with real AI decision-making
- **Multi-layer risk management** and safety systems
- **Real-time market data** integration
- **Comprehensive test coverage** (unit + E2E)
- **Production-ready deployment** with Docker

### Next Steps:
1. **Start Trading**: Configure your first trading strategies
2. **Monitor Performance**: Use the dashboard to track your bot
3. **Customize**: Adjust risk parameters and trading rules
4. **Scale**: Deploy to production when ready

### Support:
- **Documentation**: See `/tests/README.md` for detailed testing info
- **API Reference**: Visit `http://localhost:3000/api-docs`
- **Troubleshooting**: Check this guide's troubleshooting section

**Happy Trading! 🚀**

---

*Last updated: $(date)*  
*InvestBot Development Team*