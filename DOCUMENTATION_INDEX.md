# SuiLocker Contracts - Documentation Index

Welcome to the SuiLocker contracts documentation. This index provides an overview of all available documentation to help you understand and use the deployed SuiLocker smart contracts.

## 📚 Documentation Overview

The SuiLocker documentation is organized into several guides, each targeting different use cases and skill levels:

### 🏁 Getting Started

1. **[USER_GUIDE.md](./USER_GUIDE.md)** - **Comprehensive User Guide**
   - Complete reference for using SuiLocker contracts
   - Prerequisites, setup, and basic concepts
   - Step-by-step instructions for all operations
   - API reference and troubleshooting
   - **Target**: End users and developers new to SuiLocker

2. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - **Quick Reference**
   - Concise command reference for common operations
   - Essential IDs and configuration
   - Function reference with gas budgets
   - Debug commands and common patterns
   - **Target**: Experienced developers who need quick lookup

### 🔧 Development & Integration

3. **[INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)** - **Integration Guide**
   - Complete guide for building applications with SuiLocker
   - SDK setup, authentication, and integration patterns
   - React/TypeScript examples and best practices
   - Event handling, state management, and security
   - **Target**: Frontend/fullstack developers building dApps

### 🚀 Deployment Resources

4. **[DEPLOYMENT.md](./DEPLOYMENT.md)** - **Deployment Guide**
   - Comprehensive deployment instructions
   - Network configuration and environment setup
   - Post-deployment setup and verification
   - **Target**: DevOps, developers deploying contracts

5. **[QUICK_DEPLOY.md](./QUICK_DEPLOY.md)** - **Quick Deployment**
   - One-command deployment scripts
   - Common troubleshooting scenarios
   - Essential post-deployment steps
   - **Target**: Developers familiar with deployment

## 🏗️ Contract Architecture

### Core Components

```
SuiLocker System
└── sui_locker::sui_locker (Main Module)
    ├── Vault Management
    ├── Entry Management
    ├── User Registry System
    ├── Integrated Query Operations
    │   ├── Filtering & Pagination
    │   ├── Sorting Operations
    │   └── Complex Queries
    └── Events & Display
```

### Key Data Structures

- **Vault**: Container for organizing entries
- **Entry**: Individual data items (soulbound NFTs)
- **UserRegistry**: Tracks user's vaults and entries
- **GlobalRegistryTracker**: Maps users to their registries
- **EntryQueryResult**: Query results for entries with pagination
- **VaultQueryResult**: Query results for vaults with pagination

## 🎯 Quick Start Paths

### For End Users
1. Read [Getting Started](./USER_GUIDE.md#getting-started) section
2. Follow [Basic Usage](./USER_GUIDE.md#basic-usage) examples
3. Refer to [API Reference](./USER_GUIDE.md#api-reference) as needed

### For Developers Building Applications
1. Review [Integration Overview](./INTEGRATION_GUIDE.md#overview)
2. Set up [SDK and Authentication](./INTEGRATION_GUIDE.md#sdk-setup)
3. Implement [Core Integration Patterns](./INTEGRATION_GUIDE.md#core-integration-patterns)
4. Use [Quick Reference](./QUICK_REFERENCE.md) for commands

### For Contract Deployment
1. Follow [Quick Deploy](./QUICK_DEPLOY.md) for simple deployment
2. Use [Deployment Guide](./DEPLOYMENT.md) for detailed instructions
3. Complete [Post-Deployment Setup](./DEPLOYMENT.md#post-deployment-setup)

## 📋 Essential Information

### Required IDs (After Deployment)
- **Package ID**: Your contract address
- **Global Registry Tracker ID**: Required for user operations
- **User Registry ID**: Created once per user (one-time setup)

### Key Networks
- **Testnet**: `https://fullnode.testnet.sui.io:443` (Development)
- **Mainnet**: `https://fullnode.mainnet.sui.io:443` (Production)

### Gas Budget Guidelines
| Operation | Recommended Gas |
|-----------|-----------------|
| Registry Setup | 10,000,000 |
| Create Operations | 10,000,000 |
| Update Operations | 8,000,000 |
| Delete Operations | 6,000,000 |
| Read Operations | 1,000,000 |

## 🔗 Quick Links

### Command Examples
```bash
# Create user registry (one-time setup)
sui client call --package <PACKAGE_ID> --module sui_locker --function create_user_registry_entry --args <GLOBAL_REGISTRY_TRACKER_ID> --gas-budget 10000000

# Create vault
sui client call --package <PACKAGE_ID> --module sui_locker --function create_vault_entry --args <USER_REGISTRY_ID> 0x6 "My Vault" "Description" "" "" --gas-budget 10000000

# List user vaults
sui client call --package <PACKAGE_ID> --module sui_locker --function list_user_vaults --args <USER_REGISTRY_ID> 0 10
```

### TypeScript Integration
```typescript
import { SuiClient } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';

const client = new SuiClient({ url: 'https://fullnode.testnet.sui.io:443' });
const tx = new TransactionBlock();
// See INTEGRATION_GUIDE.md for complete examples
```

## 🛡️ Security Best Practices

1. **Always encrypt sensitive data** before storing on-chain
2. **Validate content hashes** to ensure data integrity
3. **Test on testnet first** before mainnet deployment
4. **Keep private keys secure** and never share them
5. **Use appropriate gas budgets** to avoid transaction failures

## 🆘 Support & Troubleshooting

### Common Issues
- **`E_NOT_OWNER`**: Verify you own the object you're trying to modify
- **`InsufficientGas`**: Increase gas budget for the operation
- **`ObjectNotFound`**: Verify object IDs are correct and exist

### Debug Commands
```bash
# Check object details
sui client object <OBJECT_ID>

# Verify transaction
sui client txn <TRANSACTION_DIGEST>

# Check current setup
sui client active-env
sui client active-address
sui client balance
```

### Where to Get Help
1. **Documentation**: Start with the relevant guide above
2. **Debug**: Use the troubleshooting sections in each guide
3. **Community**: Join the Sui developer community
4. **Issues**: Report bugs on the project repository

## 📝 Document Versions

All documentation is current as of the latest contract deployment. Key documents:

- **USER_GUIDE.md**: Complete user and developer reference
- **QUICK_REFERENCE.md**: Concise command and function reference
- **INTEGRATION_GUIDE.md**: Application development guide
- **DEPLOYMENT.md**: Comprehensive deployment instructions
- **QUICK_DEPLOY.md**: Simplified deployment reference

---

**Note**: Always use the most recent contract IDs from your deployment artifacts. The placeholder `<PACKAGE_ID>` and other IDs in examples must be replaced with actual values from your deployment.

## Quick Start Commands

```bash
# After deployment, create your first vault:
sui client call --package <PACKAGE_ID> --module sui_locker --function create_vault --args "My First Vault" "Description" "" <GLOBAL_STATE> <CLOCK> --gas-budget 10000000
```
