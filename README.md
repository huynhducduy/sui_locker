# SuiLocker Contracts

A decentralized, fully on-chain vault system for storing encrypted data on the Sui blockchain.

## Table of Contents

- [SuiLocker Contracts](#suilocker-contracts)
	- [Table of Contents](#table-of-contents)
	- [Overview](#overview)
	- [Key Features](#key-features)
	- [Core Concepts](#core-concepts)
		- [Data Structures](#data-structures)
		- [Core Operations](#core-operations)
		- [Query Functions](#query-functions)
		- [Events](#events)
	- [API Summary](#api-summary)
	- [Security](#security)
	- [Development](#development)
		- [Prerequisites](#prerequisites)
		- [Commands](#commands)
		- [Deployment](#deployment)
	- [Contributing](#contributing)

## Overview

SuiLocker allows users to create `Vault` objects containing multiple `Entry` objects. Each entry is a soulbound NFT that stores encrypted data. The system provides CRUD operations with comprehensive user registry and event tracking.

## Key Features

✅ **CRUD operations** for vaults and entries
✅ **User-scoped listing** with pagination
✅ **Ownership controls** and access validation
✅ **Soulbound NFT entries** (non-transferable)
✅ **Event emission** for all mutations
✅ **On-chain registry** for efficient querying

## Core Concepts

### Data Structures

- **`Vault`**: Stores vault metadata (name, description, entry count)
- **`Entry`**: Soulbound NFT containing encrypted data, tags, and metadata
- **`GlobalState`**: Singleton shared object managing user registries and global stats
- **`UserRegistryData`**: Per-user tracking of vaults, entries, and unique tags

### Core Operations

- **`create_vault(...)`** / **`create_entry(...)`**: Create new objects
- **`update_vault(...)`** / **`update_entry(...)`**: Update existing objects
- **`delete_vault(...)`** / **`delete_entry(...)`**: Delete objects (vault must be empty)

### Query Functions

- **`list_user_vaults(...)`** / **`list_user_entries(...)`**: Paginated listings
- **`get_user_vault_count(...)`** / **`get_user_entry_count(...)`**: Get counts
- **`get_vault_info(...)`** / **`get_entry_info(...)`**: Get object details

### Events

All operations emit events: `VaultCreated/Updated/Deleted`, `EntryCreated/Updated/Deleted`, `UserRegistryCreated`

## API Summary

**Creation**: `create_vault`, `create_entry`
**Updates**: `update_vault`, `update_entry`
**Deletions**: `delete_vault`, `delete_entry`
**Queries**: `list_user_vaults`, `list_user_entries`, `get_user_*_count`

See `SIMPLIFIED_API_GUIDE.md` and `USER_GUIDE.md` for detailed examples.

## Security

- **Client-Side Encryption**: All sensitive data MUST be encrypted client-side
- **Ownership Controls**: Strict owner-only access to operations
- **Soulbound Design**: Entries cannot be transferred after creation
- **Integrity Checking**: Use `Entry.hash` field to verify data integrity

## Development

### Prerequisites

- Sui CLI ([installation guide](https://docs.sui.io/guides/developer/getting-started/sui-install))

### Commands

```bash
sui move build    # Build contracts
sui move test     # Run tests
```

### Deployment

See deployment guides:

- 🚀 [QUICK_DEPLOY.md](./QUICK_DEPLOY.md)
- 📖 [DEPLOYMENT.md](./DEPLOYMENT.md)

## Contributing

Fork the repo, create a branch, make changes, and open a Pull Request. Ensure tests pass and follow project standards.
