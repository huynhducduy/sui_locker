# SuiLocker Contracts - User Guide

Welcome to the SuiLocker User Guide! This document provides comprehensive instructions for interacting with the deployed SuiLocker smart contracts on the Sui blockchain. SuiLocker allows you to securely store and manage encrypted data on-chain.

## Table of Contents

- [SuiLocker Contracts - User Guide](#suilocker-contracts---user-guide)
	- [Table of Contents](#table-of-contents)
	- [Overview](#overview)
		- [Key Features](#key-features)
	- [Prerequisites](#prerequisites)
		- [Software Requirements](#software-requirements)
		- [Network Configuration](#network-configuration)
		- [Required Object IDs](#required-object-ids)
	- [Core Concepts](#core-concepts)
		- [Vaults](#vaults)
		- [Entries (Soulbound NFTs)](#entries-soulbound-nfts)
		- [User Registry](#user-registry)
		- [Global State](#global-state)
	- [Basic Operations (Using `sui client call`)](#basic-operations-using-sui-client-call)
		- [A. Creating a Vault](#a-creating-a-vault)
		- [B. Creating an Entry](#b-creating-an-entry)
	- [Querying Data (Read Operations)](#querying-data-read-operations)
		- [A. Get Vault Information](#a-get-vault-information)
		- [B. Get Entry Information](#b-get-entry-information)
		- [C. List User Vaults (Paginated)](#c-list-user-vaults-paginated)
		- [D. List User Entries (Paginated)](#d-list-user-entries-paginated)
		- [E. List User Tags (Paginated)](#e-list-user-tags-paginated)
		- [F. Get User Statistics](#f-get-user-statistics)
		- [G. Get Global Application Statistics](#g-get-global-application-statistics)
	- [Modifying Data (Update Operations)](#modifying-data-update-operations)
		- [A. Updating a Vault](#a-updating-a-vault)
		- [B. Updating an Entry](#b-updating-an-entry)
	- [Deleting Data](#deleting-data)
		- [A. Deleting an Entry](#a-deleting-an-entry)
		- [B. Deleting a Vault (Important Preconditions)](#b-deleting-a-vault-important-preconditions)
	- [Understanding `Option` Types in Arguments](#understanding-option-types-in-arguments)
	- [Troubleshooting Common Issues](#troubleshooting-common-issues)
		- [Common Issues](#common-issues)
		- [Debugging Tips](#debugging-tips)
	- [Security Best Practices](#security-best-practices)
		- [Security](#security)
		- [Performance](#performance)
		- [Data Management](#data-management)
		- [Development](#development)
	- [Gas Budget Guidelines](#gas-budget-guidelines)
	- [Support](#support)

## Overview

SuiLocker is a decentralized, permissionless, SUI-native vault system designed for storing and managing your encrypted data directly on the Sui blockchain. It provides a secure and user-centric way to organize sensitive information.

Each user can create multiple `Vault` objects. Each `Vault` can, in turn, hold multiple `Entry` objects. These `Entry` objects are essentially soulbound Non-Fungible Tokens (NFTs), meaning they are tied to your wallet and cannot be transferred after creation.

### Key Features

- ✅ **Secure Encrypted Data Storage**: Store your client-side encrypted data with on-chain references.
- ✅ **Soulbound Entries**: Entries are non-transferable NFTs, ensuring they remain with the owner.
- ✅ **Full CRUD Operations**: Create, Read, Update, and Delete functionality for both vaults and entries.
- ✅ **Efficient Listing with Pagination**: Retrieve lists of your vaults, entries, and tags with support for pagination, making it scalable for many items.
- ✅ **Tag Management**: Organize and categorize your entries using custom tags. The system helps track unique tags per user.
- ✅ **Comprehensive Event Emission**: All significant actions (creations, updates, deletions) emit events, which is ideal for off-chain indexing and monitoring.
- ✅ **On-Chain User Registry**: An efficient system tracks all vaults and entries belonging to a user, facilitating quick lookups.

## Prerequisites

Before you begin interacting with the SuiLocker contracts, please ensure you have the following set up:

### Software Requirements

1. **Sui Command Line Interface (CLI)**: Ensure you have the latest version of the Sui CLI installed. This tool is essential for all interactions with the Sui network.

    ```bash
    # Install or update Sui CLI by following the official Sui documentation:
    # https://docs.sui.io/guides/developer/getting-started/sui-install

    # Verify installation and check version
    sui --version
    ```

2. **Sui Wallet**: You need an active Sui wallet with an address and some SUI tokens for gas fees.
    - You can use browser extension wallets like [Sui Wallet](https://chrome.google.com/webstore/detail/sui-wallet/opcgpfmipidbgpenhmajoajpbobppdil) or [Suiet Wallet](https://chrome.google.com/webstore/detail/suiet-sui-wallet/khpkpbbcccdmmclmpigdgddabeilkdpd).
    - Alternatively, the Sui CLI provides wallet functionalities (`sui client active-address`, `sui client new-address`, etc.).

### Network Configuration

Configure your Sui CLI to connect to the desired network where the SuiLocker contracts are deployed (e.g., Testnet, Mainnet, or a local network).

```bash
# Example: Switch to Sui Testnet
sui client switch --env testnet

# Example: Switch to Sui Mainnet
sui client switch --env mainnet

# If the environment doesn't exist, create it first:
# For Testnet:
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
# For Mainnet:
sui client new-env --alias mainnet --rpc https://fullnode.mainnet.sui.io:443
```

Ensure your active address on the chosen network has SUI tokens for gas.

### Required Object IDs

To interact with the SuiLocker contracts, you will need the following IDs:

1. **Package ID**: The on-chain ID of the deployed `sui_locker` package. This will be provided by the deployer of the contract. Replace `<PACKAGE_ID>` in all examples with this value.
2. **GlobalState Object ID**: The ID of the shared `GlobalState` object. This object is created when the `sui_locker` package is first published (usually via an `init` function). This ID is also provided by the deployer. Replace `<GLOBAL_STATE_ID>` in examples with this value.
3. **Clock Object ID**: This is a standard Sui system object. Its ID is always `0x6`. Replace `<CLOCK_ID>` with `0x6` in examples.

*(Ask the person or documentation source that directed you to this guide for the correct `<PACKAGE_ID>` and `<GLOBAL_STATE_ID>` for the network you are using.)*

## Core Concepts

Understanding these concepts is key to using SuiLocker effectively.

### Vaults

A `Vault` is a container object that you own. It's used to organize your encrypted entries. Each vault has:

- `id`: Unique identifier.
- `owner`: Your Sui address.
- `name`: A human-readable name for the vault (e.g., "Personal Passwords", "Work Documents").
- `description`: An optional longer description.
- `image_url`: An optional URL for a representative image.
- `created_at`: Timestamp of when it was created.
- `entry_count`: How many entries are currently inside this vault.

### Entries (Soulbound NFTs)

An `Entry` represents an individual piece of encrypted data stored within one of your vaults. Think of it as a secure note or record.

- **Soulbound Nature**: Once created, an `Entry` is tied to your wallet (its owner) and cannot be transferred to another user. It also cannot be taken out of its parent vault and moved to another (it would need to be deleted and recreated).
- **Fields**:
  - `id`: Unique identifier.
  - `owner`: Your Sui address.
  - `vault_id`: The ID of the `Vault` it belongs to.
  - `name`: Encrypted name/title of the entry (e.g., client-side encrypted "My Bank Login").
  - `hash`: A cryptographic hash (e.g., SHA-256) of the *encrypted content*, used to verify data integrity.
  - `content`: The actual encrypted data (e.g., client-side encrypted password details).
  - `entry_type`: Optional MIME type (e.g., "application/json", "text/plain") to describe the content.
  - `description`: Optional encrypted short description.
  - `tags`: A list of strings for categorizing the entry (e.g., `["bank", "login", "2FA"]`).
  - `notes`: Optional encrypted additional notes.
  - `image_url`: Optional URL for an image related to the entry.
  - `link`: Optional URL relevant to the entry.
  - `created_at`: Timestamp of creation.
  - `updated_at`: Timestamp of the last update.

**Important**: The SuiLocker contracts *do not* encrypt or decrypt your data. You must perform encryption and decryption on your client application before sending data to the `create_entry` or `update_entry` functions, and after fetching it with `get_entry_info`.

### User Registry

For each user who interacts with SuiLocker (by creating a vault or entry), the system maintains a `UserRegistryData` entry. This is not an object you directly own but is stored within the `GlobalState` object, associated with your address.

- **Purpose**: Tracks all your vault IDs, entry IDs, and unique tags.
- **Automatic**: You don't need to create this manually; it's handled when you call `create_vault` or `create_entry` for the first time.
- **Contents**:
  - `vaults: vector<ID>`: List of your vault IDs.
  - `entries: vector<ID>`: List of all your entry IDs.
  - `vault_count: u64`: Total number of your vaults.
  - `entry_count: u64`: Total number of your entries.
  - `unique_tags: VecSet<String>`: A unique set of all tags you've used across your entries.

### Global State

The `GlobalState` object is a single, shared object central to the SuiLocker application.

- It holds all `UserRegistryData` entries as dynamic fields.
- It also stores `GlobalStats` (total users, total vaults, total entries in the system).
- You will use its ID (`<GLOBAL_STATE_ID>`) in most transaction calls.

## Basic Operations (Using `sui client call`)

This section shows how to perform common actions using the `sui client call` command. Remember to replace placeholders like `<PACKAGE_ID>`, `<GLOBAL_STATE_ID>`, `<YOUR_VAULT_ID_HERE>`, etc., with actual values.

**Note on Gas**: All transactions require a gas budget. The `--gas-budget` values in the examples (e.g., `10000000 MIST` or `20000000 MIST`) are illustrative. Adjust as needed based on network conditions and current gas prices. `1 SUI = 1,000,000,000 MIST`.

### A. Creating a Vault

This creates a new vault owned by you. Your user registry is automatically initialized if this is your first interaction.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function create_vault \
  --args \
    "My Personal Vault" \
    "This vault stores my personal encrypted items." \
    "https://example.com/vault_image.png" \
    <GLOBAL_STATE_ID> \
    0x6 `# Clock object ID` \
  --gas-budget 20000000
```

**Arguments for `create_vault`**:

1. `name: String` - The desired name for your vault.
2. `description: String` - An optional description. Pass `""` for no description.
3. `image_url: String` - An optional image URL. Pass `""` for no image URL.
4. `global_state: &mut GlobalState` - The ID of the shared `GlobalState` object (`<GLOBAL_STATE_ID>`).
5. `clock: &Clock` - The Clock object ID (`0x6`).

**Output**: The command will output details of the transaction, including the ID of the newly created `Vault` object. **Save this Vault ID!** You'll need it to add entries or manage the vault later.

### B. Creating an Entry

This creates a new encrypted entry within one of your existing vaults.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function create_entry \
  --args \
    <YOUR_VAULT_ID_HERE> `# ID of the vault to add this entry to` \
    "Encrypted Login Name" `# Encrypted name for the entry` \
    "sha256_hash_of_the_encrypted_content_goes_here" `# Hash of encrypted content` \
    "Actual_client_side_encrypted_data_payload" `# Encrypted content` \
    "application/json" `# Optional: MIME type of content, or ""` \
    "Encrypted description of this entry" `# Optional: Encrypted description, or ""` \
    '["work", "credentials", "api_key"]' `# Tags: JSON array of strings` \
    "Encrypted notes for this entry" `# Optional: Encrypted notes, or ""` \
    "https://example.com/entry_image.png" `# Optional: Image URL, or ""` \
    "https://relevant-service.com/login" `# Optional: Link, or ""` \
    <GLOBAL_STATE_ID> \
    0x6 `# Clock object ID` \
  --gas-budget 30000000
```

**Arguments for `create_entry`**:

1. `vault: &mut Vault` - The ID of the `Vault` object where this entry will be stored (`<YOUR_VAULT_ID_HERE>`).
2. `name: String` - Encrypted name/title for the entry.
3. `hash: String` - A hash (e.g., SHA-256) of the `content` field (calculated client-side on the encrypted data).
4. `content: String` - The client-side encrypted data payload.
5. `entry_type: String` - Optional. MIME type (e.g., "text/plain"). Use `""` if not applicable.
6. `description: String` - Optional. Encrypted description. Use `""` if not applicable.
7. `tags: vector<String>` - A JSON array of strings for tags. E.g., `'["tag1", "tag2"]'`. Use `'[]'` for no tags.
8. `notes: String` - Optional. Encrypted notes. Use `""` if not applicable.
9. `image_url: String` - Optional. URL for an image. Use `""` if not applicable.
10. `link: String` - Optional. A relevant URL. Use `""` if not applicable.
11. `global_state: &mut GlobalState` - The ID of the shared `GlobalState` object (`<GLOBAL_STATE_ID>`).
12. `clock: &Clock` - The Clock object ID (`0x6`).

**Output**: The command will output transaction details, including the ID of the newly created `Entry` object. **Save this Entry ID!** You'll need it for updates or deletion.

## Querying Data (Read Operations)

These operations allow you to retrieve information about your vaults, entries, and overall usage. They do not modify any on-chain data and typically have lower gas costs.

**Note on User Address**: For functions that list user-specific data (vaults, entries, tags), the contract uses the sender's address from the transaction context (`ctx.sender()`) to identify the user. Therefore, you don't explicitly pass the user's address as an argument in these `sui client call` examples; it's implicit.

### A. Get Vault Information

Retrieves details for a specific vault you own.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function get_vault_info \
  --args <YOUR_VAULT_ID_HERE> `# ID of the Vault object` \
  --gas-budget 10000000
```

**Arguments for `get_vault_info`**:

1. `vault: &Vault` - The ID of the `Vault` object you want to inspect.

**Output**: Returns a tuple with vault details: `(id, owner, name, description, image_url, created_at, entry_count)`.

### B. Get Entry Information

Retrieves details for a specific entry you own.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function get_entry_info \
  --args <YOUR_ENTRY_ID_HERE> `# ID of the Entry object` \
  --gas-budget 10000000
```

**Arguments for `get_entry_info`**:

1. `entry: &Entry` - The ID of the `Entry` object.

**Output**: Returns a tuple with entry details: `(id, owner, vault_id, name, hash, content, entry_type, description, tags, notes, image_url, link, created_at, updated_at)`.

### C. List User Vaults (Paginated)

Lists IDs of vaults owned by you (the transaction sender), with pagination.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function list_user_vaults \
  --args \
    <GLOBAL_STATE_ID> \
    0   `# Start index (e.g., 0 for the first page)` \
    10  `# Limit (e.g., number of items per page)` \
  --gas-budget 10000000
```

**Arguments for `list_user_vaults`**:

1. `global_state: &GlobalState` - The ID of the shared `GlobalState` object.
2. `user: address` - (Implicitly the sender) The user whose vaults to list.
3. `start: u64` - The starting offset for pagination.
4. `limit: u64` - The maximum number of vault IDs to return.

**Output**: Returns a `VaultQueryResult` struct: `{ vaults: vector<ID>, total_count: u64, has_more: bool }`.

### D. List User Entries (Paginated)

Lists IDs of all entries owned by you, across all your vaults, with pagination.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function list_user_entries \
  --args \
    <GLOBAL_STATE_ID> \
    0   `# Start index` \
    20  `# Limit` \
  --gas-budget 10000000
```

**Arguments for `list_user_entries`**:

1. `global_state: &GlobalState` - The ID of the shared `GlobalState` object.
2. `user: address` - (Implicitly the sender) The user whose entries to list.
3. `start: u64` - The starting offset for pagination.
4. `limit: u64` - The maximum number of entry IDs to return.

**Output**: Returns an `EntryQueryResult` struct: `{ entries: vector<ID>, total_count: u64, has_more: bool }`.

### E. List User Tags (Paginated)

Lists all unique tags you have used across your entries, with pagination.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function list_user_tags \
  --args \
    <GLOBAL_STATE_ID> \
    0   `# Start index` \
    50  `# Limit` \
  --gas-budget 10000000
```

**Arguments for `list_user_tags`**:

1. `global_state: &GlobalState` - The ID of the shared `GlobalState` object.
2. `user: address` - (Implicitly the sender) The user whose tags to list.
3. `start: u64` - The starting offset for pagination.
4. `limit: u64` - The maximum number of tags to return.

**Output**: Returns a tuple: `(tags: vector<String>, total_count: u64, has_more: bool)`.

### F. Get User Statistics

Retrieves counts of vaults, entries, and unique tags for your user account.

```bash
# Get vault count for the sender
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function get_user_vault_count \
  --args <GLOBAL_STATE_ID> <YOUR_SUI_ADDRESS> \
  --gas-budget 10000000

# Get entry count for the sender
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function get_user_entry_count \
  --args <GLOBAL_STATE_ID> <YOUR_SUI_ADDRESS> \
  --gas-budget 10000000

# Get unique tag count for the sender
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function get_user_tag_count \
  --args <GLOBAL_STATE_ID> <YOUR_SUI_ADDRESS> \
  --gas-budget 10000000

# Alternatively, get all three user counts at once:
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function get_user_registry_info \
  --args <GLOBAL_STATE_ID> <YOUR_SUI_ADDRESS> \
  --gas-budget 10000000
```

**Arguments for count functions (e.g., `get_user_vault_count`)**:

1. `global_state: &GlobalState` - The ID of the shared `GlobalState` object.
2. `user: address` - The Sui address of the user whose stats you want. (For `sui client call`, this will be your active address if not specified, but the function signature requires it explicitly).

**Output for `get_user_registry_info`**: Returns a tuple `(vault_count: u64, entry_count: u64, tag_count: u64)`.

### G. Get Global Application Statistics

Retrieves total counts for users, vaults, and entries across the entire SuiLocker application.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function get_global_stats \
  --args <GLOBAL_STATE_ID> \
  --gas-budget 10000000
```

**Arguments for `get_global_stats`**:

1. `global_state: &GlobalState` - The ID of the shared `GlobalState` object.

**Output**: Returns a tuple `(total_users: u64, total_vaults: u64, total_entries: u64)`.

## Modifying Data (Update Operations)

These operations allow you to change the details of your existing vaults and entries.

### A. Updating a Vault

Modify the name, description, or image URL of a vault you own.
See [Understanding `Option` Types in Arguments](#understanding-option-types-in-arguments) for how to update or clear optional fields.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function update_vault \
  --args \
    <YOUR_VAULT_ID_HERE> `# ID of the Vault object to update` \
    "option::some(\"New Vault Name\")" `# New name (use JSON for Option<String>)` \
    "option::some(option::some(\"New Description for my vault.\"))" `# New description (Option<Option<String>>)` \
    "option::none()" `# To leave image_url unchanged (Option<Option<String>>)` \
    0x6 `# Clock object ID` \
  --gas-budget 20000000
```

**Arguments for `update_vault`**:

1. `vault: &mut Vault` - The ID of your `Vault` object.
2. `name: Option<String>` - To update, `"option::some(\"new_name\")"`. To leave unchanged, `"option::none()"`.
3. `description: Option<Option<String>>` - To update, `"option::some(option::some(\"new_desc\"))"`. To clear, `"option::some(option::none())"`. To leave unchanged, `"option::none()"`.
4. `image_url: Option<Option<String>>` - Same logic as `description`.
5. `clock: &Clock` - The Clock object ID (`0x6`).

### B. Updating an Entry

Modify details of an entry you own. This is a comprehensive function allowing updates to most fields.
See [Understanding `Option` Types in Arguments](#understanding-option-types-in-arguments) for handling optional parameters.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function update_entry \
  --args \
    <YOUR_ENTRY_ID_HERE> `# ID of the Entry to update` \
    "option::some(\"Updated Encrypted Name\")" `# name: Option<String>` \
    "option::none()" `# hash: Option<String> (leaving unchanged)` \
    "option::none()" `# content: Option<String> (leaving unchanged)` \
    "option::some(option::some(\"text\/plain\"))" `# entry_type: Option<Option<String>>` \
    "option::some(option::some(\"New encrypted description.\"))" `# description: Option<Option<String>>` \
    "option::some([\"new_tag1\", \"personal\"])" `# tags: Option<vector<String>> (replaces all tags)` \
    "option::some(option::none())" `# notes: Option<Option<String>> (to clear notes)` \
    "option::none()" `# image_url: Option<Option<String>> (leaving unchanged)` \
    "option::none()" `# link: Option<Option<String>> (leaving unchanged)` \
    <GLOBAL_STATE_ID> \
    0x6 `# Clock object ID` \
  --gas-budget 30000000
```

**Arguments for `update_entry`** (Refer to `README.md` or source for full list; main ones shown):

1. `entry: &mut Entry` - ID of your `Entry` object.
2. `name: Option<String>` - New encrypted name or `"option::none()"`.
3. `hash: Option<String>` - New hash or `"option::none()"`.
4. `content: Option<String>` - New encrypted content or `"option::none()"`.
5. `entry_type: Option<Option<String>>` - Update, clear, or leave unchanged.
6. `description: Option<Option<String>>` - Update, clear, or leave unchanged.
7. `tags: Option<vector<String>>` - To update, `"option::some([\"t1\", \"t2\"])"`. To leave unchanged, `"option::none()"`. This replaces the entire tag list for the entry.
8. `notes: Option<Option<String>>` - Update, clear, or leave unchanged.
9. `image_url: Option<Option<String>>` - Update, clear, or leave unchanged.
10. `link: Option<Option<String>>` - Update, clear, or leave unchanged.
11. `global_state: &mut GlobalState` - The ID of the shared `GlobalState` object.
12. `clock: &Clock` - The Clock object ID (`0x6`).

## Deleting Data

These operations permanently remove your vaults or entries from the blockchain.

### A. Deleting an Entry

Removes an entry from its vault and deletes the `Entry` object.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function delete_entry \
  --args \
    <YOUR_ENTRY_ID_HERE> `# ID of the Entry object to delete` \
    <PARENT_VAULT_ID_OF_THE_ENTRY> `# ID of the Vault this entry belongs to` \
    <GLOBAL_STATE_ID> \
  --gas-budget 20000000
```

**Arguments for `delete_entry`**:

1. `entry: Entry` - The ID of the `Entry` object (it will be consumed).
2. `vault: &mut Vault` - The ID of the parent `Vault` object.
3. `global_state: &mut GlobalState` - The ID of the shared `GlobalState` object.

### B. Deleting a Vault (Important Preconditions)

Deletes a `Vault` object. **CRITICAL: You MUST delete all entries within a vault BEFORE you can delete the vault itself.** The operation will fail if the vault is not empty.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module sui_locker \
  --function delete_vault \
  --args \
    <YOUR_VAULT_ID_TO_DELETE> `# ID of the Vault (must be empty)` \
    <GLOBAL_STATE_ID> \
  --gas-budget 20000000
```

**Arguments for `delete_vault`**:

1. `vault: Vault` - The ID of the `Vault` object to delete (it will be consumed).
2. `global_state: &mut GlobalState` - The ID of the shared `GlobalState` object.

**Precondition**: The vault's `entry_count` must be 0.

## Understanding `Option` Types in Arguments

In some cases, you may need to pass empty strings or empty arrays as arguments. For example, if you don't want to update the image or thumbnail, you can pass empty strings (`""`) for those arguments.

## Troubleshooting Common Issues

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `E_NOT_OWNER` | Trying to modify someone else's object | Use objects you own |
| `E_VAULT_NOT_FOUND` | Vault ID doesn't exist | Verify vault ID is correct |
| `E_ENTRY_NOT_FOUND` | Entry ID doesn't exist | Verify entry ID is correct |
| `E_INVALID_PAGINATION` | Invalid start/limit values | Use valid pagination parameters |
| `InsufficientGas` | Not enough gas for transaction | Increase gas budget |
| `ObjectNotFound` | Object ID doesn't exist | Verify object IDs are correct |

### Debugging Tips

1. **Verify Object Ownership**:

   ```bash
   sui client object <OBJECT_ID>
   ```

2. **Check Transaction Status**:

   ```bash
   sui client txn <TRANSACTION_DIGEST>
   ```

3. **Validate Network and Address**:

   ```bash
   sui client active-env
   sui client active-address
   ```

4. **Test with Dry Run**:

   ```bash
   sui client call --dry-run \
     --package <PACKAGE_ID> \
     --module sui_locker \
     --function get_vault_info \
     --args <VAULT_ID>
   ```

## Security Best Practices

### Security

1. **Encrypt Sensitive Data**: Always encrypt sensitive content before storing
2. **Validate Checksums**: Use the hash field to verify content integrity
3. **Keep Private Keys Secure**: Never share your wallet private keys
4. **Use Testnet First**: Test thoroughly on testnet before using mainnet

### Performance

1. **Batch Operations**: Use programmable transaction blocks for multiple operations
2. **Pagination**: Use pagination for large lists to avoid gas limits
3. **Optimize Gas**: Set appropriate gas budgets based on operation complexity

### Data Management

1. **Organize with Tags**: Use consistent tagging for better organization
2. **Meaningful Names**: Use descriptive names for vaults and entries
3. **Regular Backups**: Keep local backups of important data
4. **Version Control**: Track content changes through hash validation

### Development

1. **Test Locally**: Use local Sui network for development
2. **Handle Errors**: Implement proper error handling in applications
3. **Monitor Events**: Listen to contract events for real-time updates
4. **Cache Wisely**: Cache frequently accessed data appropriately

## Gas Budget Guidelines

| Operation | Recommended Gas Budget |
|-----------|----------------------|
| Create User Registry | 10,000,000 |
| Create Vault | 10,000,000 |
| Create Entry | 10,000,000 |
| Update Operations | 8,000,000 |
| Delete Operations | 6,000,000 |
| Read Operations | 1,000,000 |
| List Operations | 2,000,000 |

## Support

For technical support:

1. **Documentation**: Check this guide and the project README
2. **Issues**: Report bugs on the project repository
3. **Community**: Join the Sui developer community
4. **Testing**: Use testnet for development and testing

---

**Important**: Always test your integration on testnet before deploying to mainnet. Keep your private keys secure and never share them with anyone.
