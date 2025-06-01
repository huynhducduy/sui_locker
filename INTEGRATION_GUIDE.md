# SuiLocker Contracts - Integration Guide

Complete guide for integrating SuiLocker contracts into web applications and dApps.

## Table of Contents

- [Overview](#overview)
- [SDK Setup](#sdk-setup)
- [Authentication](#authentication)
- [Core Integration Patterns](#core-integration-patterns)
- [Frontend Examples](#frontend-examples)
- [Backend Integration](#backend-integration)
- [Event Handling](#event-handling)
- [State Management](#state-management)
- [Error Handling](#error-handling)
- [Performance Optimization](#performance-optimization)
- [Security Considerations](#security-considerations)

## Overview

This guide shows how to integrate SuiLocker contracts into modern web applications using TypeScript/JavaScript, React, and other popular frameworks.

### Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Sui Network   │    │   SuiLocker     │
│   Application   │◄──►│   (RPC/WebSocket│◄──►│   Contracts     │
│   (React/Vue)   │    │   Connection)   │    │   (Move)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## SDK Setup

### Installation

```bash
# Core Sui SDK
npm install @mysten/sui.js

# Optional: Additional utilities
npm install @suiet/wallet-kit  # For wallet integration
npm install @mysten/dapp-kit   # For dApp utilities
```

### Basic Configuration

```typescript
// config/sui.ts
import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';

export const NETWORK = 'testnet'; // or 'mainnet'
export const PACKAGE_ID = 'YOUR_PACKAGE_ID';
export const GLOBAL_REGISTRY_TRACKER_ID = 'YOUR_GLOBAL_REGISTRY_TRACKER_ID';

export const suiClient = new SuiClient({
  url: getFullnodeUrl(NETWORK),
});

// Contract configuration
export const CONTRACT_CONFIG = {
  packageId: PACKAGE_ID,
  globalRegistryTracker: GLOBAL_REGISTRY_TRACKER_ID,
  clockId: '0x6',
  modules: {
    suiLocker: 'sui_locker',
  },
} as const;
```

## Authentication

### Wallet Integration

```typescript
// hooks/useWallet.ts
import { ConnectButton, useWallet } from '@suiet/wallet-kit';
import { useState, useEffect } from 'react';

export function useWalletConnection() {
  const wallet = useWallet();
  const [userRegistry, setUserRegistry] = useState<string | null>(null);

  useEffect(() => {
    if (wallet.connected && wallet.address) {
      // Check if user has registry
      checkUserRegistry(wallet.address);
    }
  }, [wallet.connected, wallet.address]);

  const checkUserRegistry = async (address: string) => {
    try {
      // Query user registry from global tracker
      const registryId = await getUserRegistryId(address);
      setUserRegistry(registryId);
    } catch (error) {
      console.log('User registry not found');
      setUserRegistry(null);
    }
  };

  return {
    ...wallet,
    userRegistry,
    needsRegistrySetup: wallet.connected && !userRegistry,
  };
}
```

### User Registry Setup

```typescript
// services/registry.ts
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { CONTRACT_CONFIG, suiClient } from '../config/sui';

export async function getUserRegistryInfo(userAddress: string): Promise<any> {
  try {
    const result = await suiClient.call({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::get_user_registry_info`,
      arguments: [CONTRACT_CONFIG.globalState, userAddress],
    });

    return result;
  } catch (error) {
    return null;
  }
}

export async function checkUserRegistry(userAddress: string): Promise<boolean> {
  try {
    const result = await suiClient.call({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::user_has_registry`,
      arguments: [CONTRACT_CONFIG.globalState, userAddress],
    });

    return result[0] as boolean;
  } catch (error) {
    return false;
  }
}
```

## Core Integration Patterns

### Vault Management

```typescript
// services/vaults.ts
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { CONTRACT_CONFIG } from '../config/sui';

export interface VaultData {
  name: string;
  description?: string;
  imageUrl?: string;
  thumbnailUrl?: string;
}

export class VaultService {
  constructor(private wallet: any, private userRegistry: string) {}

  async createVault(data: VaultData) {
    const tx = new TransactionBlock();

    tx.moveCall({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::create_vault_entry`,
      arguments: [
        tx.object(this.userRegistry),
        tx.object(CONTRACT_CONFIG.clockId),
        tx.pure(Array.from(new TextEncoder().encode(data.name))),
        tx.pure(data.description ? Array.from(new TextEncoder().encode(data.description)) : []),
        tx.pure(data.imageUrl ? Array.from(new TextEncoder().encode(data.imageUrl)) : []),
        tx.pure(data.thumbnailUrl ? Array.from(new TextEncoder().encode(data.thumbnailUrl)) : []),
      ],
    });

    return await this.wallet.signAndExecuteTransactionBlock({
      transactionBlock: tx,
      options: {
        showObjectChanges: true,
        showEvents: true,
      },
    });
  }

  async listUserVaults(start = 0, limit = 10) {
    const result = await suiClient.call({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::list_user_vaults`,
      arguments: [this.userRegistry, start, limit],
    });

    const [vaultIds, totalCount, hasMore] = result;

    // Fetch vault details
    const vaults = await Promise.all(
      (vaultIds as string[]).map(id => this.getVaultInfo(id))
    );

    return {
      vaults,
      totalCount: totalCount as number,
      hasMore: hasMore as boolean,
    };
  }

  async getVaultInfo(vaultId: string) {
    const result = await suiClient.call({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::get_vault_info`,
      arguments: [vaultId],
    });

    const [name, description, imageUrl, thumbnailUrl, createdAt, entryCount, owner] = result;

    return {
      id: vaultId,
      name: new TextDecoder().decode(new Uint8Array(name as number[])),
      description: description ? new TextDecoder().decode(new Uint8Array(description as number[])) : null,
      imageUrl: imageUrl ? new TextDecoder().decode(new Uint8Array(imageUrl as number[])) : null,
      thumbnailUrl: thumbnailUrl ? new TextDecoder().decode(new Uint8Array(thumbnailUrl as number[])) : null,
      createdAt: new Date(createdAt as number),
      entryCount: entryCount as number,
      owner: owner as string,
    };
  }

  async updateVault(vaultId: string, data: VaultData) {
    const tx = new TransactionBlock();

    tx.moveCall({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::update_vault`,
      arguments: [
        tx.object(vaultId),
        tx.pure(Array.from(new TextEncoder().encode(data.name))),
        tx.pure(data.description ? Array.from(new TextEncoder().encode(data.description)) : []),
        tx.pure(data.imageUrl ? Array.from(new TextEncoder().encode(data.imageUrl)) : []),
        tx.pure(data.thumbnailUrl ? Array.from(new TextEncoder().encode(data.thumbnailUrl)) : []),
      ],
    });

    return await this.wallet.signAndExecuteTransactionBlock({
      transactionBlock: tx,
    });
  }

  async deleteVault(vaultId: string) {
    const tx = new TransactionBlock();

    tx.moveCall({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::delete_vault`,
      arguments: [
        tx.object(vaultId),
        tx.object(this.userRegistry),
      ],
    });

    return await this.wallet.signAndExecuteTransactionBlock({
      transactionBlock: tx,
    });
  }
}
```

### Entry Management

```typescript
// services/entries.ts
export interface EntryData {
  name: string;
  hash: string;
  content: string;
  type?: string;
  description?: string;
  tags?: string[];
  notes?: string;
  imageUrl?: string;
  thumbnailUrl?: string;
  link?: string;
}

export class EntryService {
  constructor(private wallet: any, private userRegistry: string) {}

  async createEntry(vaultId: string, data: EntryData) {
    const tx = new TransactionBlock();

    tx.moveCall({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::create_entry_entry`,
      arguments: [
        tx.object(vaultId),
        tx.object(this.userRegistry),
        tx.object(CONTRACT_CONFIG.clockId),
        tx.pure(Array.from(new TextEncoder().encode(data.name))),
        tx.pure(Array.from(new TextEncoder().encode(data.hash))),
        tx.pure(Array.from(new TextEncoder().encode(data.content))),
        tx.pure(data.type ? Array.from(new TextEncoder().encode(data.type)) : []),
        tx.pure(data.description ? Array.from(new TextEncoder().encode(data.description)) : []),
        tx.pure((data.tags || []).map(tag => Array.from(new TextEncoder().encode(tag)))),
        tx.pure(data.notes ? Array.from(new TextEncoder().encode(data.notes)) : []),
        tx.pure(data.imageUrl ? Array.from(new TextEncoder().encode(data.imageUrl)) : []),
        tx.pure(data.thumbnailUrl ? Array.from(new TextEncoder().encode(data.thumbnailUrl)) : []),
        tx.pure(data.link ? Array.from(new TextEncoder().encode(data.link)) : []),
      ],
    });

    return await this.wallet.signAndExecuteTransactionBlock({
      transactionBlock: tx,
      options: {
        showObjectChanges: true,
        showEvents: true,
      },
    });
  }

  async listUserEntries(start = 0, limit = 20) {
    const result = await suiClient.call({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::list_user_entries`,
      arguments: [this.userRegistry, start, limit],
    });

    const [entryIds, totalCount, hasMore] = result;

    const entries = await Promise.all(
      (entryIds as string[]).map(id => this.getEntryInfo(id))
    );

    return {
      entries,
      totalCount: totalCount as number,
      hasMore: hasMore as boolean,
    };
  }

  async getEntryInfo(entryId: string) {
    const result = await suiClient.call({
      target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.modules.suiLocker}::get_entry_info`,
      arguments: [entryId],
    });

    const [vaultId, name, hash, content, type, description, tags, notes, imageUrl, thumbnailUrl, link, createdAt, updatedAt, owner] = result;

    return {
      id: entryId,
      vaultId: vaultId as string,
      name: new TextDecoder().decode(new Uint8Array(name as number[])),
      hash: new TextDecoder().decode(new Uint8Array(hash as number[])),
      content: new TextDecoder().decode(new Uint8Array(content as number[])),
      type: type ? new TextDecoder().decode(new Uint8Array(type as number[])) : null,
      description: description ? new TextDecoder().decode(new Uint8Array(description as number[])) : null,
      tags: (tags as number[][]).map(tag => new TextDecoder().decode(new Uint8Array(tag))),
      notes: notes ? new TextDecoder().decode(new Uint8Array(notes as number[])) : null,
      imageUrl: imageUrl ? new TextDecoder().decode(new Uint8Array(imageUrl as number[])) : null,
      thumbnailUrl: thumbnailUrl ? new TextDecoder().decode(new Uint8Array(thumbnailUrl as number[])) : null,
      link: link ? new TextDecoder().decode(new Uint8Array(link as number[])) : null,
      createdAt: new Date(createdAt as number),
      updatedAt: new Date(updatedAt as number),
      owner: owner as string,
    };
  }
}
```

## Frontend Examples

### React Component for Vault Management

```typescript
// components/VaultManager.tsx
import React, { useState, useEffect } from 'react';
import { VaultService } from '../services/vaults';
import { useWalletConnection } from '../hooks/useWallet';

export function VaultManager() {
  const { wallet, userRegistry } = useWalletConnection();
  const [vaults, setVaults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [vaultService, setVaultService] = useState<VaultService | null>(null);

  useEffect(() => {
    if (wallet && userRegistry) {
      setVaultService(new VaultService(wallet, userRegistry));
    }
  }, [wallet, userRegistry]);

  useEffect(() => {
    if (vaultService) {
      loadVaults();
    }
  }, [vaultService]);

  const loadVaults = async () => {
    if (!vaultService) return;

    setLoading(true);
    try {
      const result = await vaultService.listUserVaults();
      setVaults(result.vaults);
    } catch (error) {
      console.error('Failed to load vaults:', error);
    } finally {
      setLoading(false);
    }
  };

  const createVault = async (data: { name: string; description: string }) => {
    if (!vaultService) return;

    try {
      await vaultService.createVault(data);
      await loadVaults(); // Refresh list
    } catch (error) {
      console.error('Failed to create vault:', error);
    }
  };

  if (!wallet.connected) {
    return <div>Please connect your wallet</div>;
  }

  if (!userRegistry) {
    return <div>Setting up user registry...</div>;
  }

  return (
    <div className="vault-manager">
      <h2>My Vaults</h2>

      <VaultCreateForm onSubmit={createVault} />

      {loading ? (
        <div>Loading vaults...</div>
      ) : (
        <div className="vault-list">
          {vaults.map((vault: any) => (
            <VaultCard key={vault.id} vault={vault} onUpdate={loadVaults} />
          ))}
        </div>
      )}
    </div>
  );
}

function VaultCreateForm({ onSubmit }: { onSubmit: (data: any) => void }) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({ name, description });
    setName('');
    setDescription('');
  };

  return (
    <form onSubmit={handleSubmit} className="vault-form">
      <input
        type="text"
        placeholder="Vault name"
        value={name}
        onChange={(e) => setName(e.target.value)}
        required
      />
      <textarea
        placeholder="Description (optional)"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />
      <button type="submit">Create Vault</button>
    </form>
  );
}
```

## Event Handling

### Real-time Updates

```typescript
// hooks/useContractEvents.ts
import { useEffect, useState } from 'react';
import { suiClient, CONTRACT_CONFIG } from '../config/sui';

export function useContractEvents(userAddress?: string) {
  const [events, setEvents] = useState([]);

  useEffect(() => {
    if (!userAddress) return;

    let subscription: any;

    const subscribeToEvents = async () => {
      subscription = await suiClient.subscribeEvent({
        filter: {
          Package: CONTRACT_CONFIG.packageId,
        },
        onMessage: (event) => {
          // Filter events for current user
          if (event.parsedJson?.owner === userAddress) {
            setEvents(prev => [event, ...prev].slice(0, 100)); // Keep last 100 events
          }
        },
      });
    };

    subscribeToEvents();

    return () => {
      if (subscription) {
        subscription.unsubscribe();
      }
    };
  }, [userAddress]);

  return events;
}
```

### Event Processing

```typescript
// utils/eventProcessor.ts
export function processContractEvent(event: any) {
  const eventType = event.type.split('::').pop();

  switch (eventType) {
    case 'VaultCreated':
      return {
        type: 'VAULT_CREATED',
        vaultId: event.parsedJson.vault_id,
        owner: event.parsedJson.owner,
        name: event.parsedJson.name,
        timestamp: new Date(event.parsedJson.created_at),
      };

    case 'EntryCreated':
      return {
        type: 'ENTRY_CREATED',
        entryId: event.parsedJson.entry_id,
        vaultId: event.parsedJson.vault_id,
        owner: event.parsedJson.owner,
        name: event.parsedJson.name,
        timestamp: new Date(event.parsedJson.created_at),
      };

    default:
      return {
        type: 'UNKNOWN',
        data: event.parsedJson,
      };
  }
}
```

## State Management

### Using Redux Toolkit

```typescript
// store/suiLockerSlice.ts
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { VaultService, EntryService } from '../services';

export const loadVaults = createAsyncThunk(
  'suiLocker/loadVaults',
  async ({ vaultService }: { vaultService: VaultService }) => {
    return await vaultService.listUserVaults();
  }
);

const suiLockerSlice = createSlice({
  name: 'suiLocker',
  initialState: {
    vaults: [],
    entries: [],
    loading: false,
    error: null,
  },
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(loadVaults.pending, (state) => {
        state.loading = true;
      })
      .addCase(loadVaults.fulfilled, (state, action) => {
        state.loading = false;
        state.vaults = action.payload.vaults;
      })
      .addCase(loadVaults.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      });
  },
});

export default suiLockerSlice.reducer;
```

## Error Handling

### Comprehensive Error Handler

```typescript
// utils/errorHandler.ts
export function handleContractError(error: any): { message: string; code?: string } {
  if (error.message?.includes('E_NOT_OWNER')) {
    return {
      message: "You don't have permission to perform this action",
      code: 'E_NOT_OWNER',
    };
  }

  if (error.message?.includes('E_VAULT_NOT_FOUND')) {
    return {
      message: 'Vault not found',
      code: 'E_VAULT_NOT_FOUND',
    };
  }

  if (error.message?.includes('InsufficientGas')) {
    return {
      message: 'Insufficient gas for transaction',
      code: 'INSUFFICIENT_GAS',
    };
  }

  if (error.message?.includes('User rejected')) {
    return {
      message: 'Transaction was cancelled',
      code: 'USER_REJECTED',
    };
  }

  return {
    message: error.message || 'An unexpected error occurred',
    code: 'UNKNOWN_ERROR',
  };
}
```

## Performance Optimization

### Caching Strategy

```typescript
// utils/cache.ts
class ContractCache {
  private cache = new Map();
  private ttl = 5 * 60 * 1000; // 5 minutes

  set(key: string, value: any) {
    this.cache.set(key, {
      value,
      timestamp: Date.now(),
    });
  }

  get(key: string) {
    const item = this.cache.get(key);
    if (!item) return null;

    if (Date.now() - item.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }

    return item.value;
  }

  clear() {
    this.cache.clear();
  }
}

export const contractCache = new ContractCache();
```

### Batch Operations

```typescript
// utils/batchOperations.ts
export async function batchLoadVaultDetails(vaultIds: string[]) {
  const BATCH_SIZE = 10;
  const batches = [];

  for (let i = 0; i < vaultIds.length; i += BATCH_SIZE) {
    batches.push(vaultIds.slice(i, i + BATCH_SIZE));
  }

  const results = await Promise.all(
    batches.map(batch =>
      Promise.all(
        batch.map(id => vaultService.getVaultInfo(id))
      )
    )
  );

  return results.flat();
}
```

## Security Considerations

### Input Validation

```typescript
// utils/validation.ts
export function validateVaultData(data: any): { isValid: boolean; errors: string[] } {
  const errors = [];

  if (!data.name || typeof data.name !== 'string' || data.name.trim().length === 0) {
    errors.push('Vault name is required');
  }

  if (data.name && data.name.length > 100) {
    errors.push('Vault name must be 100 characters or less');
  }

  if (data.description && data.description.length > 500) {
    errors.push('Description must be 500 characters or less');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}
```

### Content Encryption

```typescript
// utils/encryption.ts
import CryptoJS from 'crypto-js';

export function encryptContent(content: string, password: string): string {
  return CryptoJS.AES.encrypt(content, password).toString();
}

export function decryptContent(encryptedContent: string, password: string): string {
  const bytes = CryptoJS.AES.decrypt(encryptedContent, password);
  return bytes.toString(CryptoJS.enc.Utf8);
}

export function generateHash(content: string): string {
  return CryptoJS.SHA256(content).toString();
}
```

---

This integration guide provides a solid foundation for building applications with SuiLocker contracts. Remember to always test on testnet first and implement proper error handling and user feedback mechanisms.
