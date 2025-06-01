# SuiLocker Contracts Deployment Guide

This document provides comprehensive instructions for deploying the SuiLocker smart contracts to the Sui blockchain.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Network Configuration](#network-configuration)
- [Building and Testing](#building-and-testing)
- [Deployment Process](#deployment-process)
- [Post-Deployment Setup](#post-deployment-setup)
- [Integration Guide](#integration-guide)
- [Troubleshooting](#troubleshooting)
- [Network-Specific Instructions](#network-specific-instructions)

## Prerequisites

### Required Software

1. **Sui CLI** (version 1.0.0 or later)

   ```bash
   # Install Sui CLI
   cargo install --locked --git https://github.com/MystenLabs/sui.git --branch mainnet sui

   # Verify installation
   sui --version
   ```

2. **Rust** (required for building)

   ```bash
   # Install Rust if not already installed
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

   # Verify installation
   rustc --version
   ```

3. **Git** (for cloning the repository)

### Sui Wallet Setup

1. **Create a new wallet** (if you don't have one):

   ```bash
   sui client new-address ed25519
   ```

2. **Import existing wallet** (if you have a mnemonic):

   ```bash
   sui client new-address ed25519 --alias my-wallet
   ```

3. **Verify wallet configuration**:

   ```bash
   sui client addresses
   sui client active-address
   ```

### Network Configuration

Configure your Sui CLI to connect to the desired network:

#### Mainnet

```bash
sui client new-env --alias mainnet --rpc https://fullnode.mainnet.sui.io:443
sui client switch --env mainnet
```

#### Testnet

```bash
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
sui client switch --env testnet
```

#### Devnet

```bash
sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443
sui client switch --env devnet
```

#### Local Network

```bash
sui client new-env --alias local --rpc http://127.0.0.1:9000
sui client switch --env local
```

Verify your network configuration:

```bash
sui client envs
sui client active-env
```

## Funding Your Wallet

### For Testnet/Devnet

Request faucet tokens:

```bash
# For testnet
sui client faucet --address YOUR_ADDRESS

# For devnet
sui client faucet --address YOUR_ADDRESS
```

### For Mainnet

You'll need to transfer SUI tokens to your wallet address from an exchange or another wallet.

Verify your balance:

```bash
sui client balance
```

## Building and Testing

### 1. Clone and Navigate to Project

```bash
git clone <your-repository-url>
cd sui_locker_contracts
```

### 2. Build the Contracts

```bash
# Clean build
sui move build

# Build with verbose output
sui move build --verbose
```

Expected output:

```
BUILDING sui_locker
Successfully verified dependencies on-chain against source.
```

### 3. Run Tests

```bash
# Run all tests
sui move test

# Run tests with verbose output
sui move test --verbose

# Run specific test
sui move test test_create_vault_with_registry
```

Expected test results:

```
[ PASS    ] sui_locker::sui_locker::test_comprehensive_entry_queries
[ PASS    ] sui_locker::sui_locker::test_create_vault_with_registry
[ PASS    ] sui_locker::sui_locker::test_entry_operations_with_registry
[ PASS    ] sui_locker::sui_locker::test_listing_functions
[ PASS    ] sui_locker::sui_locker::test_query_edge_cases
[ PASS    ] sui_locker::sui_locker::test_registry_tracking
[ PASS    ] sui_locker::sui_locker::test_tag_and_simple_queries
[ PASS    ] sui_locker::sui_locker::test_vault_queries
[ PASS    ] sui_locker::sui_locker_tests::test_entry_filter_creation
[ PASS    ] sui_locker::sui_locker_tests::test_pagination_creation
[ PASS    ] sui_locker::sui_locker_tests::test_vault_filter_creation
Test result: OK. Total tests: 35; passed: 35; failed: 0
```

## Deployment Process

### 1. Pre-Deployment Checks

Verify your setup:

```bash
# Check active address
sui client active-address

# Check network
sui client active-env

# Check balance (ensure you have enough for gas)
sui client balance

# Verify build passes
sui move build
```

### 2. Deploy to Network

#### Option A: Standard Deployment

```bash
# Deploy with recommended gas budget
sui client publish --gas-budget 20000000
```

#### Option B: Deployment with Custom Gas Budget

```bash
# For complex deployments or congested networks
sui client publish --gas-budget 30000000
```

#### Option C: Deployment with Skip Dependency Verification

```bash
# If you encounter dependency issues
sui client publish --gas-budget 20000000 --skip-dependency-verification
```

### 3. Deployment Output

After successful deployment, you'll see output similar to:

```
Successfully verified dependencies on-chain against source.
Transaction Digest: ABCD1234...
╭─────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Effects                                                                                 │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Digest: ABCD1234...                                                                               │
│ Status: Success                                                                                     │
│ Executed Epoch: 123                                                                               │
│ Gas Used: 5,678,900                                                                               │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Created Objects                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──                                                                                              │
│  │ ObjectID: 0x1234...                                                                           │
│  │ Sender: 0xabc...                                                                              │
│  │ Owner: Immutable                                                                               │
│  │ ObjectType: 0x2::package::Package                                                             │
│  └──                                                                                              │
│  ┌──                                                                                              │
│  │ ObjectID: 0x5678...                                                                           │
│  │ Sender: 0xabc...                                                                              │
│  │ Owner: Shared                                                                                  │
│  │ ObjectType: 0x1234::sui_locker::GlobalRegistryTracker                                        │
│  └──                                                                                              │
╰─────────────────────────────────────────────────────────────────────────────────────────────────╯
```

### 4. Record Important Information

**IMPORTANT**: Save these values from the deployment output:

1. **Package ID**: The ObjectID of the Package (Immutable object)
   - Example: `0x1234abcd...`
   - This is your deployed contract address

2. **GlobalRegistryTracker Object ID**: The ObjectID of the Shared object
   - Example: `0x5678efgh...`
   - This is required for user registry operations

3. **Transaction Digest**: For verification
   - Example: `ABCD1234...`

## Post-Deployment Setup

### 1. Verify Deployment

Check that your package was deployed successfully:

```bash
# View package info
sui client object <PACKAGE_ID>

# View global registry tracker
sui client object <GLOBAL_REGISTRY_TRACKER_ID>
```

### 2. Update Configuration Files

Create a `deployment.json` file to track your deployment:

```json
{
  "network": "testnet",
  "package_id": "0x1234abcd...",
  "global_registry_tracker_id": "0x5678efgh...",
  "transaction_digest": "ABCD1234...",
  "deployed_at": "2024-01-15T10:30:00Z",
  "deployer": "0xabc123..."
}
```

### 3. Test Basic Functionality

Test the deployment by creating your first vault:

```bash
# This will create a vault (registry is automatically created)
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function create_vault \
  --args "My First Vault" "Description" "" <GLOBAL_STATE> <CLOCK> \
  --gas-budget 10000000
```

## Integration Guide

### 1. Frontend Integration

For web applications, you'll need:

```javascript
// Example configuration for @mysten/sui.js
const config = {
  packageId: 'YOUR_PACKAGE_ID',
  globalStateId: 'YOUR_GLOBAL_STATE_ID',
  network: 'testnet' // or mainnet, devnet
};

// Create a vault (registry is automatically created)
const createVault = async (signer) => {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${config.packageId}::sui_locker::create_vault`,
    arguments: [
      tx.pure(Array.from(new TextEncoder().encode("My Vault"))),
      tx.pure(Array.from(new TextEncoder().encode("Description"))),
      tx.pure([]),
      tx.object(config.globalStateId),
      tx.object('0x6') // Clock object
    ]
  });

  return await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options: { showEffects: true }
  });
};
```

### 2. Backend Integration

For backend services:

```python
# Example with pysui
from pysui import SuiConfig, SyncClient

config = SuiConfig.user_config()
client = SyncClient(config)

PACKAGE_ID = "YOUR_PACKAGE_ID"
GLOBAL_STATE_ID = "YOUR_GLOBAL_STATE_ID"

# Example function call to create vault
def create_vault(name: str, description: str):
    transaction = {
        "package": PACKAGE_ID,
        "module": "sui_locker",
        "function": "create_vault",
        "arguments": [name, description, "", GLOBAL_STATE_ID, "0x6"],
        "type_arguments": []
    }
    return client.execute_move_call(transaction)
```

### 3. Mobile Integration

For mobile apps using Flutter/React Native, use the appropriate Sui SDK for your platform.

## Troubleshooting

### Common Issues and Solutions

#### 1. Insufficient Gas

**Error**: `InsufficientGas`
**Solution**:

```bash
# Increase gas budget
sui client publish --gas-budget 30000000

# Or check your balance
sui client balance
```

#### 2. Dependency Verification Failed

**Error**: `DependencyVerificationFailed`
**Solution**:

```bash
# Skip dependency verification
sui client publish --gas-budget 20000000 --skip-dependency-verification
```

#### 3. Network Connection Issues

**Error**: `Network timeout` or `Connection refused`
**Solution**:

```bash
# Check network configuration
sui client active-env

# Switch to different RPC endpoint
sui client new-env --alias backup-testnet --rpc https://testnet.sui.rpcpool.com:443
sui client switch --env backup-testnet
```

#### 4. Build Failures

**Error**: `Build failed`
**Solution**:

```bash
# Clean and rebuild
rm -rf build/
sui move build

# Check Move.toml configuration
cat Move.toml
```

#### 5. Address/Package Not Found

**Error**: `ObjectNotFound`
**Solution**:

```bash
# Verify object exists
sui client object <OBJECT_ID>

# Check transaction status
sui client txn <TRANSACTION_DIGEST>
```

### Debug Commands

```bash
# View transaction details
sui client txn <TRANSACTION_DIGEST>

# View object details
sui client object <OBJECT_ID>

# Check gas usage
sui client gas

# View recent transactions
sui client txs --address <YOUR_ADDRESS>
```

## Network-Specific Instructions

### Mainnet Deployment

**Important Considerations:**

- Ensure thorough testing on testnet first
- Have sufficient SUI for gas fees (recommend 0.1+ SUI)
- Use lower gas budgets to avoid overpaying
- Consider deployment during low-traffic periods

```bash
# Mainnet deployment command
sui client switch --env mainnet
sui client publish --gas-budget 15000000
```

### Testnet Deployment (Recommended for Development)

```bash
sui client switch --env testnet
sui client faucet  # Get test tokens
sui client publish --gas-budget 20000000
```

### Devnet Deployment (Latest Features)

```bash
sui client switch --env devnet
sui client faucet
sui client publish --gas-budget 25000000
```

### Local Development Network

```bash
# Start local network (if running locally)
sui start

# Deploy to local network
sui client switch --env local
sui client publish --gas-budget 10000000
```

## Security Considerations

1. **Private Key Protection**: Never share your private keys or mnemonics
2. **Gas Budget**: Don't set excessive gas budgets to avoid overpaying
3. **Network Verification**: Always verify you're on the correct network
4. **Code Verification**: Ensure your source code matches what you're deploying
5. **Object Ownership**: Verify object ownership after deployment

## Cost Estimation

Typical deployment costs (approximate):

- **Devnet/Testnet**: Free (faucet tokens)
- **Mainnet**:
  - Contract deployment: ~0.02-0.05 SUI
  - User registry creation: ~0.001-0.002 SUI per user
  - Vault creation: ~0.001-0.003 SUI per vault
  - Entry creation: ~0.001-0.005 SUI per entry

## Next Steps

After successful deployment:

1. **Test Core Functionality**: Create a user registry, vault, and entry
2. **Set Up Monitoring**: Monitor your contracts using Sui Explorer
3. **Document Integration**: Update your application with the new package ID
4. **User Onboarding**: Guide users through creating their registries
5. **Event Indexing**: Set up indexing for contract events if needed

## Support

For additional help:

- [Sui Documentation](https://docs.sui.io/)
- [Sui Discord](https://discord.gg/sui)
- [Move Language Reference](https://move-language.github.io/move/)
- [SuiLocker GitHub Issues](YOUR_GITHUB_REPO/issues)

---

**Remember**: Always test thoroughly on testnet before deploying to mainnet!
