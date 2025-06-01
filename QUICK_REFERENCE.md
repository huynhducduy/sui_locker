# SuiLocker Contracts - Quick Reference

Quick reference for developers integrating with SuiLocker contracts.

## Essential IDs

After deployment, you'll need these IDs:

- **Package ID**: `<PACKAGE_ID>` - The contract address
- **Global Registry Tracker ID**: `<GLOBAL_REGISTRY_TRACKER_ID>` - Required for user operations
- **Clock ID**: `0x6` - System clock object

## Basic Operations

### Create Vault

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function create_vault \
  --args "My Vault" "Description" "image_url" <GLOBAL_STATE> <CLOCK> \
  --gas-budget 10000000
```

### Create Entry

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function create_entry_entry \
  --args <VAULT_ID> <USER_REGISTRY_ID> 0x6 "encrypted_name" "content_hash" "encrypted_content" "application/json" "Description" '["tag1","tag2"]' "Notes" "" "" "https://example.com" \
  --gas-budget 10000000
```

### Read Operations

```bash
# Get vault info
sui client call --package <PACKAGE_ID> --module sui_locker --function get_vault_info --args <VAULT_ID>

# Get entry info
sui client call --package <PACKAGE_ID> --module sui_locker --function get_entry_info --args <ENTRY_ID>

# List user vaults (start=0, limit=10)
sui client call --package <PACKAGE_ID> --module sui_locker --function list_user_vaults --args <USER_REGISTRY_ID> 0 10

# List user entries (start=0, limit=20)
sui client call --package <PACKAGE_ID> --module sui_locker --function list_user_entries --args <USER_REGISTRY_ID> 0 20
```

## TypeScript Integration

```typescript
import { SuiClient } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';

const client = new SuiClient({ url: 'https://fullnode.testnet.sui.io:443' });

// Create vault
const tx = new TransactionBlock();
tx.moveCall({
  target: `${packageId}::sui_locker::create_vault_entry`,
  arguments: [
    tx.object(registryId),
    tx.object('0x6'),
    tx.pure(Array.from(new TextEncoder().encode('My Vault'))),
    tx.pure(Array.from(new TextEncoder().encode('Description'))),
    tx.pure([]), // No image
    tx.pure([]), // No thumbnail
  ],
});

const result = await client.signAndExecuteTransactionBlock({
  transactionBlock: tx,
  signer: keypair,
});
```

## Function Reference

### Entry Functions (CLI Direct Call)

| Function | Gas Budget | Purpose |
|----------|------------|---------|
| `create_vault` | 10M | Create vault |
| `create_entry` | 10M | Create entry |

### Query Functions (Read-Only)

| Function | Returns |
|----------|---------|
| `get_vault_info` | Vault details |
| `get_entry_info` | Entry details |
| `list_user_vaults` | Paginated vault list |
| `list_user_entries` | Paginated entry list |
| `list_user_tags` | User's unique tags |

### Management Functions (Requires Ownership)

| Function | Gas Budget | Purpose |
|----------|------------|---------|
| `update_vault` | 8M | Update vault |
| `update_entry` | 8M | Update entry |
| `delete_entry` | 6M | Delete entry |
| `delete_vault` | 6M | Delete vault |

## Error Codes

| Code | Constant | Meaning |
|------|----------|---------|
| 1 | `E_NOT_OWNER` | Not the owner |
| 2 | `E_VAULT_NOT_FOUND` | Vault doesn't exist |
| 3 | `E_ENTRY_NOT_FOUND` | Entry doesn't exist |
| 4 | `E_INVALID_PAGINATION` | Invalid pagination params |

## Gas Budget Guidelines

| Operation | Recommended Gas |
|-----------|-----------------|
| Registry Setup | 10,000,000 |
| Create Operations | 10,000,000 |
| Update Operations | 8,000,000 |
| Delete Operations | 6,000,000 |
| Read Operations | 1,000,000 |

## Network Configuration

### Testnet (Development)

```bash
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
sui client switch --env testnet
sui client faucet  # Get test tokens
```

### Mainnet (Production)

```bash
sui client new-env --alias mainnet --rpc https://fullnode.mainnet.sui.io:443
sui client switch --env mainnet
```

## Common Patterns

### Batch Operations

```typescript
// Create vault and entry in one transaction
const tx = new TransactionBlock();

const vault = tx.moveCall({
  target: `${packageId}::sui_locker::create_vault`,
  arguments: [/* vault args */],
});

tx.moveCall({
  target: `${packageId}::sui_locker::create_entry`,
  arguments: [vault, /* other entry args */],
});
```

### Event Listening

```typescript
// Listen for vault creation events
const events = await client.queryEvents({
  query: {
    MoveEventType: `${packageId}::sui_locker::VaultCreated`
  }
});
```

## Debug Commands

```bash
# Check object details
sui client object <OBJECT_ID>

# Verify transaction
sui client txn <TRANSACTION_DIGEST>

# Check current environment
sui client active-env
sui client active-address
sui client balance

# Dry run before execution
sui client call --dry-run --package <PACKAGE_ID> --module sui_locker --function get_vault_info --args <VAULT_ID>
```

---

For complete documentation, see [USER_GUIDE.md](./USER_GUIDE.md)
