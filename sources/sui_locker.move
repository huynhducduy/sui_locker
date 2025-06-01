/*
/// Module: sui_locker
module sui_locker::sui_locker;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions

/// Module: sui_locker
module sui_locker::sui_locker {
    use std::string::{Self, String};
    use std::vector;
    use std::option::{Self, Option};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::display;
    use sui::package;
    use sui::dynamic_field;
    use sui::vec_set::{Self, VecSet};

    // ======== Constants ========

    const E_NOT_OWNER: u64 = 1;
    const E_VAULT_NOT_FOUND: u64 = 2;
    const E_ENTRY_NOT_FOUND: u64 = 3;
    const E_INVALID_PAGINATION: u64 = 4;
    const E_GLOBAL_STATE_NOT_FOUND: u64 = 5;

    // Dynamic field keys
    public struct UserRegistryKey has copy, drop, store { user: address }
    public struct GlobalStatsKey has copy, drop, store {}

    // ======== Structs ========

    /// The main vault object that contains metadata
    public struct Vault has key, store {
        id: UID,
        owner: address,
        name: String,
        description: Option<String>,
        image_url: Option<String>,
        created_at: u64,
        updated_at: u64,
        entry_count: u64,
    }

    /// Individual entry within a vault (soulbound NFT)
    public struct Entry has key, store {
        id: UID,
        owner: address,
        vault_id: ID,
        name: String,
        hash: String,
        content: String,
        entry_type: Option<String>,
        description: Option<String>,
        tags: vector<String>,
        notes: Option<String>,
        image_url: Option<String>,
        link: Option<String>,
        created_at: u64,
        updated_at: u64,
    }

    /// User registry data stored as dynamic field
    public struct UserRegistryData has store {
        vaults: vector<ID>,
        entries: vector<ID>,
        vault_count: u64,
        entry_count: u64,
        unique_tags: VecSet<String>,
    }

    /// Global statistics stored as dynamic field
    public struct GlobalStats has store {
        total_users: u64,
        total_vaults: u64,
        total_entries: u64,
    }

    /// Global state object using dynamic fields (singleton)
    public struct GlobalState has key {
        id: UID,
        version: u64,
    }

    /// One-time witness for creating display objects
    public struct SUI_LOCKER has drop {}

    // ======== Events ========

    public struct VaultCreated has copy, drop {
        vault_id: ID,
        owner: address,
        name: String,
        created_at: u64,
    }

    public struct VaultUpdated has copy, drop {
        vault_id: ID,
        owner: address,
        name: String,
        updated_at: u64,
    }

    public struct VaultDeleted has copy, drop {
        vault_id: ID,
        owner: address,
    }

    public struct EntryCreated has copy, drop {
        entry_id: ID,
        vault_id: ID,
        owner: address,
        name: String,
        created_at: u64,
    }

    public struct EntryUpdated has copy, drop {
        entry_id: ID,
        vault_id: ID,
        owner: address,
        name: String,
        updated_at: u64,
    }

    public struct EntryDeleted has copy, drop {
        entry_id: ID,
        vault_id: ID,
        owner: address,
    }

    public struct UserRegistryInitialized has copy, drop {
        user: address,
        global_state_id: ID,
    }

    public struct GlobalStateCreated has copy, drop {
        global_state_id: ID,
    }

    // ======== Functions ========

    fun init(otw: SUI_LOCKER, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);

        // Create display objects for better NFT representation
        let mut vault_display = display::new_with_fields<Vault>(
            &publisher,
            vector[string::utf8(b"name"), string::utf8(b"description"), string::utf8(b"image_url")],
            vector[string::utf8(b"{name}"), string::utf8(b"{description}"), string::utf8(b"{image_url}")],
            ctx
        );
        display::update_version(&mut vault_display);

        let mut entry_display = display::new_with_fields<Entry>(
            &publisher,
            vector[string::utf8(b"name"), string::utf8(b"description"), string::utf8(b"image_url")],
            vector[string::utf8(b"{name}"), string::utf8(b"{description}"), string::utf8(b"{image_url}")],
            ctx
        );
        display::update_version(&mut entry_display);

        // Create global state object with dynamic fields
        let mut global_state = GlobalState {
            id: object::new(ctx),
            version: 1,
        };

        // Initialize global statistics
        let stats = GlobalStats {
            total_users: 0,
            total_vaults: 0,
            total_entries: 0,
        };
        dynamic_field::add(&mut global_state.id, GlobalStatsKey {}, stats);

        let global_state_id = object::uid_to_inner(&global_state.id);

        event::emit(GlobalStateCreated {
            global_state_id,
        });

        transfer::share_object(global_state);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(vault_display, tx_context::sender(ctx));
        transfer::public_transfer(entry_display, tx_context::sender(ctx));
    }

    // ======== No-Parameter API ========

    public entry fun create_vault(
        name: vector<u8>,
        description: vector<u8>,
        image_url: vector<u8>,
        global_state: &mut GlobalState,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        // Ensure user has registry
        ensure_user_registry(global_state, user);

        let vault = create_vault_internal(
            string::utf8(name),
            if (vector::length(&description) > 0) option::some(string::utf8(description)) else option::none(),
            if (vector::length(&image_url) > 0) option::some(string::utf8(image_url)) else option::none(),
            clock,
            ctx
        );

        let vault_id = object::uid_to_inner(&vault.id);

        // Update registry via dynamic fields
        update_user_registry_vault_created(global_state, user, vault_id);

        transfer::public_transfer(vault, user);
    }

    public entry fun create_entry(
        vault: &mut Vault,
        name: vector<u8>,
        hash: vector<u8>,
        content: vector<u8>,
        entry_type: vector<u8>,
        description: vector<u8>,
        tags: vector<vector<u8>>,
        notes: vector<u8>,
        image_url: vector<u8>,
        link: vector<u8>,
        global_state: &mut GlobalState,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        // Ensure user has registry
        ensure_user_registry(global_state, user);

        let mut tag_strings = vector::empty<String>();
        let mut i = 0;
        while (i < vector::length(&tags)) {
            vector::push_back(&mut tag_strings, string::utf8(*vector::borrow(&tags, i)));
            i = i + 1;
        };

        let entry = create_entry_internal(
            vault,
            string::utf8(name),
            string::utf8(hash),
            string::utf8(content),
            if (vector::length(&entry_type) > 0) option::some(string::utf8(entry_type)) else option::none(),
            if (vector::length(&description) > 0) option::some(string::utf8(description)) else option::none(),
            tag_strings,
            if (vector::length(&notes) > 0) option::some(string::utf8(notes)) else option::none(),
            if (vector::length(&image_url) > 0) option::some(string::utf8(image_url)) else option::none(),
            if (vector::length(&link) > 0) option::some(string::utf8(link)) else option::none(),
            clock,
            ctx
        );

        let entry_id = object::uid_to_inner(&entry.id);

        // Update registry via dynamic fields
        update_user_registry_entry_created(global_state, user, entry_id, &tag_strings);

        transfer::public_transfer(entry, user);
    }

    // ======== Internal Helper Functions ========

    /// Internal helper to ensure user has a registry using dynamic fields
    fun ensure_user_registry(global_state: &mut GlobalState, user: address) {
        let key = UserRegistryKey { user };

        if (!dynamic_field::exists_(&global_state.id, key)) {
            let registry = UserRegistryData {
                vaults: vector::empty<ID>(),
                entries: vector::empty<ID>(),
                vault_count: 0,
                entry_count: 0,
                unique_tags: vec_set::empty<String>(),
            };

            dynamic_field::add(&mut global_state.id, key, registry);

            // Update global stats
            let stats_key = GlobalStatsKey {};
            let stats = dynamic_field::borrow_mut<GlobalStatsKey, GlobalStats>(&mut global_state.id, stats_key);
            stats.total_users = stats.total_users + 1;

            event::emit(UserRegistryInitialized {
                user,
                global_state_id: object::uid_to_inner(&global_state.id),
            });
        }
    }

    /// Update user registry when vault is created
    fun update_user_registry_vault_created(global_state: &mut GlobalState, user: address, vault_id: ID) {
        let key = UserRegistryKey { user };
        let registry = dynamic_field::borrow_mut<UserRegistryKey, UserRegistryData>(&mut global_state.id, key);

        vector::push_back(&mut registry.vaults, vault_id);
        registry.vault_count = registry.vault_count + 1;

        // Update global stats
        let stats_key = GlobalStatsKey {};
        let stats = dynamic_field::borrow_mut<GlobalStatsKey, GlobalStats>(&mut global_state.id, stats_key);
        stats.total_vaults = stats.total_vaults + 1;
    }

    /// Update user registry when entry is created
    fun update_user_registry_entry_created(
        global_state: &mut GlobalState,
        user: address,
        entry_id: ID,
        tags: &vector<String>
    ) {
        let key = UserRegistryKey { user };
        let registry = dynamic_field::borrow_mut<UserRegistryKey, UserRegistryData>(&mut global_state.id, key);

        vector::push_back(&mut registry.entries, entry_id);
        registry.entry_count = registry.entry_count + 1;

        // Add unique tags
        let mut i = 0;
        while (i < vector::length(tags)) {
            let tag = vector::borrow(tags, i);
            if (!vec_set::contains(&registry.unique_tags, tag)) {
                vec_set::insert(&mut registry.unique_tags, *tag);
            };
            i = i + 1;
        };

        // Update global stats
        let stats_key = GlobalStatsKey {};
        let stats = dynamic_field::borrow_mut<GlobalStatsKey, GlobalStats>(&mut global_state.id, stats_key);
        stats.total_entries = stats.total_entries + 1;
    }

    /// Create a new vault (internal function)
    fun create_vault_internal(
        name: String,
        description: Option<String>,
        image_url: Option<String>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Vault {
        let vault_id = object::new(ctx);
        let owner = tx_context::sender(ctx);
        let created_at = clock::timestamp_ms(clock);

        let vault = Vault {
            id: vault_id,
            owner,
            name,
            description,
            image_url,
            created_at,
            updated_at: created_at,
            entry_count: 0,
        };

        let vault_object_id = object::uid_to_inner(&vault.id);

        event::emit(VaultCreated {
            vault_id: vault_object_id,
            owner,
            name: vault.name,
            created_at,
        });

        vault
    }

    /// Create a new entry in a vault (internal function)
    fun create_entry_internal(
        vault: &mut Vault,
        name: String,
        hash: String,
        content: String,
        entry_type: Option<String>,
        description: Option<String>,
        tags: vector<String>,
        notes: Option<String>,
        image_url: Option<String>,
        link: Option<String>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Entry {
        assert!(vault.owner == tx_context::sender(ctx), E_NOT_OWNER);

        let entry_id = object::new(ctx);
        let owner = tx_context::sender(ctx);
        let vault_id = object::uid_to_inner(&vault.id);
        let created_at = clock::timestamp_ms(clock);

        let entry = Entry {
            id: entry_id,
            owner,
            vault_id,
            name,
            hash,
            content,
            entry_type,
            description,
            tags: tags,
            notes,
            image_url,
            link,
            created_at,
            updated_at: created_at,
        };

        vault.entry_count = vault.entry_count + 1;

        let entry_object_id = object::uid_to_inner(&entry.id);

        event::emit(EntryCreated {
            entry_id: entry_object_id,
            vault_id,
            owner,
            name: entry.name,
            created_at,
        });

        entry
    }

    // ======== Core Update/Delete Functions ========

    /// Update an existing vault
    public fun update_vault(
        vault: &mut Vault,
        name: Option<String>,
        description: Option<Option<String>>,
        image_url: Option<Option<String>>,
        clock: &Clock,
        ctx: &TxContext
    ) {
        assert!(vault.owner == tx_context::sender(ctx), E_NOT_OWNER);

        if (option::is_some(&name)) {
            vault.name = option::destroy_some(name);
        };

        if (option::is_some(&description)) {
            vault.description = option::destroy_some(description);
        };

        if (option::is_some(&image_url)) {
            vault.image_url = option::destroy_some(image_url);
        };

        vault.updated_at = clock::timestamp_ms(clock);

        event::emit(VaultUpdated {
            vault_id: object::uid_to_inner(&vault.id),
            owner: vault.owner,
            name: vault.name,
            updated_at: vault.updated_at,
        });
    }

    /// Delete a vault (only works for empty vaults)
    ///
    /// NOTE: This function only works for vaults with no entries.
    /// Users must delete all entries individually before deleting the vault.
    /// This is due to Move's object model where owned objects cannot be
    /// programmatically retrieved from within smart contracts.
    public fun delete_vault(
        vault: Vault,
        global_state: &mut GlobalState,
        ctx: &TxContext
    ) {
        assert!(vault.owner == tx_context::sender(ctx), E_NOT_OWNER);

        // Ensure vault is empty before deletion
        assert!(vault.entry_count == 0, E_INVALID_PAGINATION);

        let vault_id = object::uid_to_inner(&vault.id);
        let owner = vault.owner;

        // Update registry to remove vault
        let key = UserRegistryKey { user: owner };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow_mut<UserRegistryKey, UserRegistryData>(&mut global_state.id, key);
            let (found, index) = vector::index_of(&registry.vaults, &vault_id);
            if (found) {
                vector::remove(&mut registry.vaults, index);
                registry.vault_count = registry.vault_count - 1;
            };

            // Update global stats
            let stats_key = GlobalStatsKey {};
            let stats = dynamic_field::borrow_mut<GlobalStatsKey, GlobalStats>(&mut global_state.id, stats_key);
            if (stats.total_vaults > 0) {
                stats.total_vaults = stats.total_vaults - 1;
            };
        };

        event::emit(VaultDeleted {
            vault_id,
            owner,
        });

        let Vault { id, owner: _, name: _, description: _, image_url: _, created_at: _, updated_at: _, entry_count: _ } = vault;
        object::delete(id);
    }

    /// Delete an entry (with registry cleanup)
    public fun delete_entry(
        entry: Entry,
        vault: &mut Vault,
        global_state: &mut GlobalState,
        ctx: &TxContext
    ) {
        assert!(entry.owner == tx_context::sender(ctx), E_NOT_OWNER);
        assert!(entry.vault_id == object::uid_to_inner(&vault.id), E_VAULT_NOT_FOUND);

        let entry_id = object::uid_to_inner(&entry.id);
        let vault_id = entry.vault_id;
        let owner = entry.owner;

        vault.entry_count = vault.entry_count - 1;

        // Update registry
        let key = UserRegistryKey { user: owner };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow_mut<UserRegistryKey, UserRegistryData>(&mut global_state.id, key);
            let (found, index) = vector::index_of(&registry.entries, &entry_id);
            if (found) {
                vector::remove(&mut registry.entries, index);
                registry.entry_count = registry.entry_count - 1;
            };

            // Update global stats
            let stats_key = GlobalStatsKey {};
            let stats = dynamic_field::borrow_mut<GlobalStatsKey, GlobalStats>(&mut global_state.id, stats_key);
            if (stats.total_entries > 0) {
                stats.total_entries = stats.total_entries - 1;
            };
        };

        event::emit(EntryDeleted {
            entry_id,
            vault_id,
            owner,
        });

        let Entry {
            id,
            owner: _,
            vault_id: _,
            name: _,
            hash: _,
            content: _,
            entry_type: _,
            description: _,
            tags: _,
            notes: _,
            image_url: _,
            link: _,
            created_at: _,
            updated_at: _
        } = entry;
        object::delete(id);
    }

    /// Update an existing entry
    public fun update_entry(
        entry: &mut Entry,
        name: Option<String>,
        hash: Option<String>,
        content: Option<String>,
        entry_type: Option<Option<String>>,
        description: Option<Option<String>>,
        tags: Option<vector<String>>,
        notes: Option<Option<String>>,
        image_url: Option<Option<String>>,
        link: Option<Option<String>>,
        global_state: &mut GlobalState,
        clock: &Clock,
        ctx: &TxContext
    ) {
        assert!(entry.owner == tx_context::sender(ctx), E_NOT_OWNER);

        if (option::is_some(&name)) {
            entry.name = option::destroy_some(name);
        };

        if (option::is_some(&hash)) {
            entry.hash = option::destroy_some(hash);
        };

        if (option::is_some(&content)) {
            entry.content = option::destroy_some(content);
        };

        if (option::is_some(&entry_type)) {
            entry.entry_type = option::destroy_some(entry_type);
        };

        if (option::is_some(&description)) {
            entry.description = option::destroy_some(description);
        };

        if (option::is_some(&tags)) {
            let new_tags = option::destroy_some(tags);
            entry.tags = new_tags;

            // Update registry tags
            let key = UserRegistryKey { user: entry.owner };
            if (dynamic_field::exists_(&global_state.id, key)) {
                let registry = dynamic_field::borrow_mut<UserRegistryKey, UserRegistryData>(&mut global_state.id, key);
                let mut i = 0;
                while (i < vector::length(&new_tags)) {
                    let tag = vector::borrow(&new_tags, i);
                    if (!vec_set::contains(&registry.unique_tags, tag)) {
                        vec_set::insert(&mut registry.unique_tags, *tag);
                    };
                    i = i + 1;
                };
            };
        };

        if (option::is_some(&notes)) {
            entry.notes = option::destroy_some(notes);
        };

        if (option::is_some(&image_url)) {
            entry.image_url = option::destroy_some(image_url);
        };

        if (option::is_some(&link)) {
            entry.link = option::destroy_some(link);
        };

        entry.updated_at = clock::timestamp_ms(clock);

        event::emit(EntryUpdated {
            entry_id: object::uid_to_inner(&entry.id),
            vault_id: entry.vault_id,
            owner: entry.owner,
            name: entry.name,
            updated_at: entry.updated_at,
        });
    }

    // ======== Read Functions ========

    /// Get vault information
    public fun get_vault_info(vault: &Vault): (ID, address, String, Option<String>, Option<String>, u64, u64, u64) {
        (
            object::uid_to_inner(&vault.id),
            vault.owner,
            vault.name,
            vault.description,
            vault.image_url,
            vault.created_at,
            vault.updated_at,
            vault.entry_count
        )
    }

    /// Get entry information
    public fun get_entry_info(entry: &Entry): (
        ID,
        address,
        ID,
        String,
        String,
        String,
        Option<String>,
        Option<String>,
        vector<String>,
        Option<String>,
        Option<String>,
        Option<String>,
        u64,
        u64
    ) {
        (
            object::uid_to_inner(&entry.id),
            entry.owner,
            entry.vault_id,
            entry.name,
            entry.hash,
            entry.content,
            entry.entry_type,
            entry.description,
            entry.tags,
            entry.notes,
            entry.image_url,
            entry.link,
            entry.created_at,
            entry.updated_at
        )
    }

    /// Get user registry info via dynamic fields
    public fun get_user_registry_info(global_state: &GlobalState, user: address): (u64, u64, u64) {
        let key = UserRegistryKey { user };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow<UserRegistryKey, UserRegistryData>(&global_state.id, key);
            (registry.vault_count, registry.entry_count, vec_set::size(&registry.unique_tags))
        } else {
            (0, 0, 0)
        }
    }

    /// Get global statistics
    public fun get_global_stats(global_state: &GlobalState): (u64, u64, u64) {
        let stats_key = GlobalStatsKey {};
        let stats = dynamic_field::borrow<GlobalStatsKey, GlobalStats>(&global_state.id, stats_key);
        (stats.total_users, stats.total_vaults, stats.total_entries)
    }

    /// Get user's vault IDs
    public fun get_user_vaults(global_state: &GlobalState, user: address): vector<ID> {
        let key = UserRegistryKey { user };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow<UserRegistryKey, UserRegistryData>(&global_state.id, key);
            registry.vaults
        } else {
            vector::empty<ID>()
        }
    }

    /// Get user's entry IDs
    public fun get_user_entries(global_state: &GlobalState, user: address): vector<ID> {
        let key = UserRegistryKey { user };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow<UserRegistryKey, UserRegistryData>(&global_state.id, key);
            registry.entries
        } else {
            vector::empty<ID>()
        }
    }

    /// Check if user owns vault
    public fun is_vault_owner(vault: &Vault, user: address): bool {
        vault.owner == user
    }

    /// Check if user owns entry
    public fun is_entry_owner(entry: &Entry, user: address): bool {
        entry.owner == user
    }

    /// Get vault entry count
    public fun get_vault_entry_count(vault: &Vault): u64 {
        vault.entry_count
    }

    // ======== Advanced Read & Listing Functions ========

    /// List user vaults with pagination
    public fun list_user_vaults(global_state: &GlobalState, user: address, start: u64, limit: u64): (vector<ID>, u64, bool) {
        assert!(limit > 0, E_INVALID_PAGINATION);

        let key = UserRegistryKey { user };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow<UserRegistryKey, UserRegistryData>(&global_state.id, key);
            let total_count = vector::length(&registry.vaults);

            if (start >= total_count) {
                return (vector::empty<ID>(), total_count, false)
            };

            let mut result = vector::empty<ID>();
            let mut i = start;
            let end = if (start + limit > total_count) total_count else start + limit;

            while (i < end) {
                vector::push_back(&mut result, *vector::borrow(&registry.vaults, i));
                i = i + 1;
            };

            let has_more = start + limit < total_count;
            (result, total_count, has_more)
        } else {
            (vector::empty<ID>(), 0, false)
        }
    }

    /// List user entries with pagination
    public fun list_user_entries(global_state: &GlobalState, user: address, start: u64, limit: u64): (vector<ID>, u64, bool) {
        assert!(limit > 0, E_INVALID_PAGINATION);

        let key = UserRegistryKey { user };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow<UserRegistryKey, UserRegistryData>(&global_state.id, key);
            let total_count = vector::length(&registry.entries);

            if (start >= total_count) {
                return (vector::empty<ID>(), total_count, false)
            };

            let mut result = vector::empty<ID>();
            let mut i = start;
            let end = if (start + limit > total_count) total_count else start + limit;

            while (i < end) {
                vector::push_back(&mut result, *vector::borrow(&registry.entries, i));
                i = i + 1;
            };

            let has_more = start + limit < total_count;
            (result, total_count, has_more)
        } else {
            (vector::empty<ID>(), 0, false)
        }
    }

    /// List user's unique tags with pagination
    public fun list_user_tags(global_state: &GlobalState, user: address, start: u64, limit: u64): (vector<String>, u64, bool) {
        assert!(limit > 0, E_INVALID_PAGINATION);

        let key = UserRegistryKey { user };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow<UserRegistryKey, UserRegistryData>(&global_state.id, key);
            let tags_vec = vec_set::into_keys(registry.unique_tags);
            let total_count = vector::length(&tags_vec);

            if (start >= total_count) {
                return (vector::empty<String>(), total_count, false)
            };

            let mut result = vector::empty<String>();
            let mut i = start;
            let end = if (start + limit > total_count) total_count else start + limit;

            while (i < end) {
                vector::push_back(&mut result, *vector::borrow(&tags_vec, i));
                i = i + 1;
            };

            let has_more = start + limit < total_count;
            (result, total_count, has_more)
        } else {
            (vector::empty<String>(), 0, false)
        }
    }

    /// Get user's unique tags as vector
    public fun get_user_unique_tags(global_state: &GlobalState, user: address): vector<String> {
        let key = UserRegistryKey { user };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow<UserRegistryKey, UserRegistryData>(&global_state.id, key);
            vec_set::into_keys(registry.unique_tags)
        } else {
            vector::empty<String>()
        }
    }

    /// Check if user has specific tag
    public fun user_has_tag(global_state: &GlobalState, user: address, tag: String): bool {
        let key = UserRegistryKey { user };
        if (dynamic_field::exists_(&global_state.id, key)) {
            let registry = dynamic_field::borrow<UserRegistryKey, UserRegistryData>(&global_state.id, key);
            vec_set::contains(&registry.unique_tags, &tag)
        } else {
            false
        }
    }

    /// Get total counts for user (convenience function)
    public fun get_user_counts(global_state: &GlobalState, user: address): (u64, u64, u64) {
        get_user_registry_info(global_state, user)
    }

    /// Check if entry belongs to specific vault
    public fun entry_belongs_to_vault(entry: &Entry, vault_id: ID): bool {
        entry.vault_id == vault_id
    }

    /// Get entry tags
    public fun get_entry_tags(entry: &Entry): vector<String> {
        entry.tags
    }

    /// Check if entry has specific tag
    public fun entry_has_tag(entry: &Entry, tag: String): bool {
        vector::contains(&entry.tags, &tag)
    }

    /// Check if entry has any of the provided tags
    public fun entry_has_any_tag(entry: &Entry, tags: vector<String>): bool {
        let mut i = 0;
        while (i < vector::length(&tags)) {
            if (vector::contains(&entry.tags, vector::borrow(&tags, i))) {
                return true
            };
            i = i + 1;
        };
        false
    }

    /// Check if entry has all of the provided tags
    public fun entry_has_all_tags(entry: &Entry, tags: vector<String>): bool {
        let mut i = 0;
        while (i < vector::length(&tags)) {
            if (!vector::contains(&entry.tags, vector::borrow(&tags, i))) {
                return false
            };
            i = i + 1;
        };
        true
    }

    /// Get entry content type
    public fun get_entry_type(entry: &Entry): Option<String> {
        entry.entry_type
    }

    /// Check if entry has specific content type
    public fun entry_has_type(entry: &Entry, entry_type: String): bool {
        if (option::is_some(&entry.entry_type)) {
            *option::borrow(&entry.entry_type) == entry_type
        } else {
            false
        }
    }

    /// Get entry creation timestamp
    public fun get_entry_created_at(entry: &Entry): u64 {
        entry.created_at
    }

    /// Get entry last update timestamp
    public fun get_entry_updated_at(entry: &Entry): u64 {
        entry.updated_at
    }

    /// Get vault creation timestamp
    public fun get_vault_created_at(vault: &Vault): u64 {
        vault.created_at
    }

    /// Get vault last update timestamp
    public fun get_vault_updated_at(vault: &Vault): u64 {
        vault.updated_at
    }

    /// Check if entry was created after specific time
    public fun entry_created_after(entry: &Entry, timestamp: u64): bool {
        entry.created_at > timestamp
    }

    /// Check if entry was created before specific time
    public fun entry_created_before(entry: &Entry, timestamp: u64): bool {
        entry.created_at < timestamp
    }

    /// Check if entry was updated after specific time
    public fun entry_updated_after(entry: &Entry, timestamp: u64): bool {
        entry.updated_at > timestamp
    }

    /// Check if vault was created after specific time
    public fun vault_created_after(vault: &Vault, timestamp: u64): bool {
        vault.created_at > timestamp
    }

    /// Check if vault was created before specific time
    public fun vault_created_before(vault: &Vault, timestamp: u64): bool {
        vault.created_at < timestamp
    }

    /// Check if vault was updated after specific time
    public fun vault_updated_after(vault: &Vault, timestamp: u64): bool {
        vault.updated_at > timestamp
    }

    /// Check if vault was updated before specific time
    public fun vault_updated_before(vault: &Vault, timestamp: u64): bool {
        vault.updated_at < timestamp
    }

    /// Get vault name
    public fun get_vault_name(vault: &Vault): String {
        vault.name
    }

    /// Get vault description
    public fun get_vault_description(vault: &Vault): Option<String> {
        vault.description
    }

    /// Get vault image URL
    public fun get_vault_image_url(vault: &Vault): Option<String> {
        vault.image_url
    }

    /// Get entry name
    public fun get_entry_name(entry: &Entry): String {
        entry.name
    }

    /// Get entry hash
    public fun get_entry_hash(entry: &Entry): String {
        entry.hash
    }

    /// Get entry content
    public fun get_entry_content(entry: &Entry): String {
        entry.content
    }

    /// Get entry description
    public fun get_entry_description(entry: &Entry): Option<String> {
        entry.description
    }

    /// Get entry notes
    public fun get_entry_notes(entry: &Entry): Option<String> {
        entry.notes
    }

    /// Get entry image URL
    public fun get_entry_image_url(entry: &Entry): Option<String> {
        entry.image_url
    }

    /// Get entry link
    public fun get_entry_link(entry: &Entry): Option<String> {
        entry.link
    }

    /// Check if vault has entries
    public fun vault_has_entries(vault: &Vault): bool {
        vault.entry_count > 0
    }

    /// Check if vault is empty
    public fun vault_is_empty(vault: &Vault): bool {
        vault.entry_count == 0
    }

    /// Get vault owner
    public fun get_vault_owner(vault: &Vault): address {
        vault.owner
    }

    /// Get entry owner
    public fun get_entry_owner(entry: &Entry): address {
        entry.owner
    }

    /// Get entry vault ID
    public fun get_entry_vault_id(entry: &Entry): ID {
        entry.vault_id
    }

    /// Get global state version
    public fun get_global_state_version(global_state: &GlobalState): u64 {
        global_state.version
    }

    // ======== Test-only Functions ========

    #[test_only]
    /// Initialize for testing - creates a GlobalState object with basic setup
    public fun init_for_testing(ctx: &mut TxContext) {
        // Create global state object with dynamic fields
        let mut global_state = GlobalState {
            id: object::new(ctx),
            version: 1,
        };

        // Initialize global statistics
        let stats = GlobalStats {
            total_users: 0,
            total_vaults: 0,
            total_entries: 0,
        };
        dynamic_field::add(&mut global_state.id, GlobalStatsKey {}, stats);

        let global_state_id = object::uid_to_inner(&global_state.id);

        event::emit(GlobalStateCreated {
            global_state_id,
        });

        transfer::share_object(global_state);
    }
}
