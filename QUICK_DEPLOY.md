# Quick Deployment Reference

## TL;DR - One-Command Deployment

```bash
# Deploy to testnet (recommended for development)
./scripts/deploy.sh testnet

# Deploy to mainnet (production)
./scripts/deploy.sh mainnet 15000000

# Deploy to devnet (latest features)
./scripts/deploy.sh devnet
```

## Prerequisites Check

```bash
# Install Sui CLI
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch mainnet sui

# Verify installation
sui --version

# Check/create wallet
sui client addresses
sui client active-address
```

## Common Commands

### Build & Test
```bash
sui move build
sui move test
```

### Network Setup
```bash
# Add testnet
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
sui client switch --env testnet

# Get testnet tokens
sui client faucet
```

### Manual Deployment
```bash
# Standard deployment
sui client publish --gas-budget 20000000

# With dependency skip (if needed)
sui client publish --gas-budget 20000000 --skip-dependency-verification
```

### Post-Deployment
```bash
# Verify package
sui client object <PACKAGE_ID>

# Test user registry creation
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function create_user_registry_entry \
  --args <GLOBAL_REGISTRY_TRACKER_ID> \
  --gas-budget 10000000
```

## Important IDs to Save

After deployment, save these values:

1. **Package ID** - Your contract address
2. **GlobalRegistryTracker ID** - Required for user operations
3. **Transaction Digest** - For verification

The deployment script automatically saves these to a JSON file.

## Gas Budget Guidelines

- **Testnet/Devnet**: 20,000,000 (generous for safety)
- **Mainnet**: 15,000,000 (more conservative)
- **Complex Networks**: 30,000,000 (if facing issues)

## Common Issues

| Issue | Solution |
|-------|----------|
| `InsufficientGas` | Increase gas budget |
| `DependencyVerificationFailed` | Add `--skip-dependency-verification` |
| `Network timeout` | Switch to different RPC endpoint |
| `Build failed` | Run `sui move build` first |
| `No balance` | Use `sui client faucet` (testnet/devnet) |

## Quick Troubleshooting

```bash
# Check current status
sui client active-env
sui client active-address
sui client balance

# Debug deployment
sui client txn <TRANSACTION_DIGEST>
sui client object <OBJECT_ID>
```

---

For detailed instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md)
