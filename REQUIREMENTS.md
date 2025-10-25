# InvestBot Requirements

## Overview

InvestBot is a conservative, data-driven automated trading platform focused on memecoins and cryptocurrency markets. The system executes frequent, small-profit trades using historical data analysis combined with external market intelligence. Multiple independent instances can run simultaneously with different strategies and capital allocations, scaling through trade frequency rather than position size.

## Core Features

### 1. Dual-Track Trading (Crypto-Focused)
- **Primary Focus**: Memecoins and cryptocurrency trading with quick trades
- **Secondary**: Stock trading if broker API supports it
- **Configurable Profiles**: Different trading strategies and risk parameters per instance
- **Independent Instances**: Each bot runs autonomously with separate API keys and databases

### 2. Intelligent Decision Making
- **Data Sources**: Historical price/volume data + external market intelligence project
- **Pattern Recognition**: Analysis of historical patterns for quick opportunities
- **External Intelligence**: Integration with consolidated crypto/memecoin analysis
- **Conservative Approach**: Data-driven decisions, not speculative predictions

### 3. Autonomous Operation
- **Fully Automated**: No human intervention required under risk limits
- **Quick Trades**: Short-term positions with 1-5% profit targets
- **Frequent Trading**: Scale through trade frequency, not position size
- **Manual Override**: Emergency stop and risk adjustment controls

### 4. Risk Management (Conservative)
- **Capital Preservation**: Strict position sizing (1-2% of capital per trade)
- **Quick Profit-Taking**: Immediate selling at 1-5% gains
- **Tight Stop Losses**: 0.5-1% loss limits per trade
- **Daily Limits**: Maximum trade frequency and capital usage controls

### 5. User Interface
- **Simple Dashboard**: Trade activity feed, win/loss statistics, performance metrics
- **Real-Time Monitoring**: Live trade execution and P&L updates
- **Manual Controls**: Pause/resume, risk adjustment, emergency stops
- **Email Notifications**: Trade alerts and daily performance summaries
- **Multi-Instance View**: Monitor all bot instances from single interface

## Technical Architecture

### Frontend
- **Framework**: Svelte
- **Styling**: Tailwind CSS
- **Real-Time**: WebSocket integration for live trade updates
- **Authentication**: Admin user/password protection

### Backend
- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js with REST API
- **Database**: PostgreSQL with Prisma ORM (per instance)
- **Security**: Encrypted sensitive data, secure API key storage
- **Monitoring**: Health checks and performance metrics

### External Integrations
- **Trading APIs**:
  - Jupiter API (Solana DEX aggregation for fast execution)
  - Raydium SDK (Direct Solana trading)
  - Alpaca Markets (Stocks, if supported)
- **Data Sources**:
  - Historical price and volume data
  - External memecoin intelligence project
  - On-chain metrics and trading data
- **Notification**:
  - Email service for alerts and summaries

### Deployment Architecture
- **Raspberry Pi (Home)**: Always-on instance with specific capital/profile
- **EC2 (Cloud)**: Always-on instance with different capital/profile
- **Independent Instances**: Separate databases, API keys, and configurations
- **Synchronization**: No data sync - each instance operates independently

## Security Requirements

### Authentication & Authorization
- **Admin Access**: Username/password authentication for dashboard
- **Instance Isolation**: Each bot instance has separate credentials
- **API Key Security**: Encrypted storage in per-instance databases
- **Network Security**: VPN access for home deployment

### Data Protection
- **Encryption**: All sensitive data encrypted at rest
- **Secure Storage**: API keys and trading credentials protected
- **Backup Security**: Encrypted daily backups with 30-day retention
- **Access Control**: Restricted access to trading controls

## Performance Requirements

### Response Times
- **Trade Execution**: Sub-second analysis to order execution
- **Data Processing**: Real-time analysis of market intelligence
- **UI Updates**: Live dashboard updates without perceptible delay
- **Reliability**: Zero decision loss or system failures

### Resource Constraints
- **Raspberry Pi**: 16GB RAM, optimized for continuous operation
- **EC2**: Scalable cloud resources for high-frequency trading
- **Database**: Efficient storage for high-frequency trade logs
- **Network**: Reliable connectivity for real-time data feeds

### Scalability
- **Multiple Instances**: Independent bots with different strategies
- **Distributed Load**: Load distributed across brokerage systems
- **Trade Frequency**: High-frequency small trades for scalability
- **Resource Efficiency**: Lightweight design for home deployment

## Development Phases

### Phase 1: Core Infrastructure
- Basic bot framework with TypeScript/Express
- PostgreSQL database setup with encryption
- Historical data analysis integration
- External market intelligence API integration

### Phase 2: Trading Integration
- Jupiter/Solana integration for quick trades
- Conservative risk management and position sizing
- Quick profit-taking automation
- High-frequency trade logging

### Phase 3: User Interface & Deployment
- Svelte dashboard with real-time trade monitoring
- Authentication and security features
- Raspberry Pi and EC2 deployment configurations
- Multi-instance management interface

## Acceptance Criteria

### MVP (Phase 1)
- [ ] Bot can analyze historical data + external intelligence
- [ ] Quick trade opportunities identified and validated
- [ ] Conservative risk limits prevent excessive losses
- [ ] Basic dashboard shows trade activity and statistics
- [ ] Manual override and emergency stops work

### Enhanced Features (Phase 2)
- [ ] Multiple independent instances running
- [ ] Quick profit-taking at 1-5% targets working
- [ ] Win rate tracking and performance metrics
- [ ] Email notifications for trades and daily summaries
- [ ] Emergency stop and manual override controls

### Production Ready (Phase 3)
- [ ] Raspberry Pi and EC2 deployments stable
- [ ] Encrypted databases and secure API key management
- [ ] Comprehensive monitoring and health checks
- [ ] Backup and recovery procedures
- [ ] Multi-instance management dashboard

## Assumptions & Constraints

### Technical Assumptions
- Access to required trading APIs and data sources
- Reliable internet connectivity for real-time data feeds
- Compatible external intelligence API for memecoin data
- Sufficient Raspberry Pi performance for analysis and trading

### Business Assumptions
- Conservative approach acceptable with smaller but consistent returns
- User comfortable with fully autonomous frequent trading
- Multiple broker accounts available for different instances
- External intelligence source provides reliable market insights

### Development Assumptions
- Greenfield development with modern tooling
- Open source libraries meet security requirements
- Historical data + external intelligence provides viable signals
- Quick trading approach feasible on target hardware

## Success Metrics

### Performance Goals
- **Uptime**: 99%+ availability across all instances
- **Execution Speed**: Sub-second decision to trade execution
- **Win Rate**: 55-65% profitable trades
- **Average Win**: 2-4% per winning trade
- **Average Loss**: 0.5-1% per losing trade
- **Profit Factor**: >1.2 (gross profits / gross losses)
- **Maximum Drawdown**: <5% portfolio decline

### User Experience Goals
- **Dashboard Load**: Instant loading of trade activity data
- **Trade Monitoring**: Real-time visibility into active trades
- **Notification Delivery**: Reliable email alerts within minutes
- **Instance Monitoring**: Clear visibility into all bot instances

### Trading Goals
- **Risk Management**: Strict adherence to position limits and stop losses
- **Strategy Effectiveness**: Consistent small profits through frequent trading
- **Data Utilization**: Effective combination of historical + external intelligence
- **Scalability**: Successful operation of multiple independent instances