#[test_only]
module sui_locker::read_listing_tests {
    use std::string;
    use sui_locker::sui_locker::{
        Self,
        GlobalState,
        Vault,
        Entry,
        list_user_vaults,
        list_user_entries,
        list_user_tags,
        get_user_unique_tags,
        user_has_tag,
        get_user_counts,
        entry_belongs_to_vault,
        get_entry_tags,
        entry_has_tag,
        entry_has_any_tag,
        entry_has_all_tags,
        get_entry_type,
        entry_has_type,
        get_entry_created_at,
        get_entry_updated_at,
        get_vault_created_at,
        entry_created_after,
        entry_created_before,
        entry_updated_after,
        vault_created_after,
        vault_created_before,
        get_vault_name,
        get_vault_description,
        get_vault_image_url,
        get_entry_name,
        get_entry_hash,
        get_entry_content,
        get_entry_description,
        get_entry_notes,
        get_entry_image_url,
        get_entry_link,
        vault_has_entries,
        vault_is_empty,
        get_vault_owner,
        get_entry_owner,
        get_entry_vault_id,
        get_global_state_version
    };
    use sui::clock;
    use sui::test_scenario::{Self as ts, Scenario};

    const USER_1: address = @0x1;
    const USER_2: address = @0x2;

    /// Test pagination listing functions
    #[test]
    fun test_pagination_listing() {
        let mut scenario = ts::begin(USER_1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));

        // Initialize the system
        sui_locker::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);

        let mut global_state = ts::take_shared<GlobalState>(&scenario);

        // Create multiple vaults (5 vaults)
        let vault_names = vector[
            b"Personal Vault",
            b"Work Vault",
            b"Finance Vault",
            b"Social Vault",
            b"Gaming Vault"
        ];

        let mut vault_objects = vector::empty<Vault>();
        let mut i = 0;
        while (i < vector::length(&vault_names)) {
            sui_locker::create_vault(
                *vector::borrow(&vault_names, i),
                b"Test description",
                b"https://example.com/image.png",
                &mut global_state,
                &clock,
                ts::ctx(&mut scenario)
            );

            ts::next_tx(&mut scenario, USER_1);
            let vault = ts::take_from_sender<Vault>(&scenario);
            vector::push_back(&mut vault_objects, vault);
            i = i + 1;
        };

        // Test vault pagination
        let (vault_ids_page_1, total_vaults, has_more) = list_user_vaults(&global_state, USER_1, 0, 3);
        assert!(vector::length(&vault_ids_page_1) == 3, 1); // First page has 3 items
        assert!(total_vaults == 5, 2); // Total is 5 vaults
        assert!(has_more == true, 3); // More items available

        let (vault_ids_page_2, total_vaults_2, has_more_2) = list_user_vaults(&global_state, USER_1, 3, 3);
        assert!(vector::length(&vault_ids_page_2) == 2, 4); // Second page has 2 remaining items
        assert!(total_vaults_2 == 5, 5); // Total is still 5
        assert!(has_more_2 == false, 6); // No more items

        // Test pagination alternative functions
        let (paginated_vaults, _, _) = list_user_vaults(&global_state, USER_1, 0, 2);
        assert!(vector::length(&paginated_vaults) == 2, 7);

        // Create entries in first vault
        let mut first_vault = vector::pop_back(&mut vault_objects);
        let entry_names = vector[
            b"Gmail Password",
            b"Facebook Login",
            b"Bank PIN",
            b"WiFi Password"
        ];

        let mut j = 0;
        while (j < vector::length(&entry_names)) {
            sui_locker::create_entry(
                &mut first_vault,
                *vector::borrow(&entry_names, j),
                b"hash123",
                b"encrypted_content",
                b"password",
                b"Test entry description",
                vector[b"personal", b"important"],
                b"Test notes",
                b"https://example.com/entry.png",
                b"https://example.com",
                &mut global_state,
                &clock,
                ts::ctx(&mut scenario)
            );

            ts::next_tx(&mut scenario, USER_1);
            let entry = ts::take_from_sender<Entry>(&scenario);
            ts::return_to_sender(&scenario, entry);
            j = j + 1;
        };

        // Test entry pagination
        let (entry_ids_page_1, total_entries, has_more_entries) = list_user_entries(&global_state, USER_1, 0, 2);
        assert!(vector::length(&entry_ids_page_1) == 2, 8);
        assert!(total_entries == 4, 9);
        assert!(has_more_entries == true, 10);

        // Test tag pagination
        let (tags_page_1, total_tags, has_more_tags) = list_user_tags(&global_state, USER_1, 0, 10);
        assert!(vector::length(&tags_page_1) == 2, 11); // Should have "personal" and "important"
        assert!(total_tags == 2, 12);
        assert!(has_more_tags == false, 13);

        // Test get user counts
        let (vault_count, entry_count, tag_count) = get_user_counts(&global_state, USER_1);
        assert!(vault_count == 5, 14);
        assert!(entry_count == 4, 15);
        assert!(tag_count == 2, 16);

        // Cleanup - return all vault objects
        ts::return_to_sender(&scenario, first_vault);
        while (!vector::is_empty(&vault_objects)) {
            ts::return_to_sender(&scenario, vector::pop_back(&mut vault_objects));
        };
        vector::destroy_empty(vault_objects);

        ts::return_shared(global_state);
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    /// Test tag and filtering functions
    #[test]
    fun test_tag_and_filtering_functions() {
        let mut scenario = ts::begin(USER_1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));

        sui_locker::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);

        let mut global_state = ts::take_shared<GlobalState>(&scenario);

        // Set clock to ensure non-zero timestamp
        clock::set_for_testing(&mut clock, 1000);

        // Create vault
        sui_locker::create_vault(
            b"Test Vault",
            b"Description",
            b"",
            &mut global_state,
            &clock,
            ts::ctx(&mut scenario)
        );

        ts::next_tx(&mut scenario, USER_1);
        let mut vault = ts::take_from_sender<Vault>(&scenario);

        // Create entry with multiple tags
        sui_locker::create_entry(
            &mut vault,
            b"Test Entry",
            b"hash123",
            b"content",
            b"password",
            b"Description",
            vector[b"work", b"important", b"daily"],
            b"Notes",
            b"",
            b"",
            &mut global_state,
            &clock,
            ts::ctx(&mut scenario)
        );

        ts::next_tx(&mut scenario, USER_1);
        let entry = ts::take_from_sender<Entry>(&scenario);

        // Test tag functions
        let tags = get_entry_tags(&entry);
        assert!(vector::length(&tags) == 3, 1);

        assert!(entry_has_tag(&entry, string::utf8(b"work")), 2);
        assert!(entry_has_tag(&entry, string::utf8(b"important")), 3);
        assert!(!entry_has_tag(&entry, string::utf8(b"nonexistent")), 4);

        // Test any tag matching
        let search_tags = vector[string::utf8(b"personal"), string::utf8(b"work")];
        assert!(entry_has_any_tag(&entry, search_tags), 5);

        let no_match_tags = vector[string::utf8(b"personal"), string::utf8(b"social")];
        assert!(!entry_has_any_tag(&entry, no_match_tags), 6);

        // Test all tags matching
        let all_present_tags = vector[string::utf8(b"work"), string::utf8(b"important")];
        assert!(entry_has_all_tags(&entry, all_present_tags), 7);

        let mixed_tags = vector[string::utf8(b"work"), string::utf8(b"nonexistent")];
        assert!(!entry_has_all_tags(&entry, mixed_tags), 8);

        // Test user tag functions
        let user_tags = get_user_unique_tags(&global_state, USER_1);
        assert!(vector::length(&user_tags) == 3, 9);

        assert!(user_has_tag(&global_state, USER_1, string::utf8(b"work")), 10);
        assert!(!user_has_tag(&global_state, USER_1, string::utf8(b"nonexistent")), 11);

        // Test entry type
        let entry_type = get_entry_type(&entry);
        assert!(option::is_some(&entry_type), 12);
        assert!(entry_has_type(&entry, string::utf8(b"password")), 13);
        assert!(!entry_has_type(&entry, string::utf8(b"note")), 14);

        ts::return_to_sender(&scenario, entry);
        ts::return_to_sender(&scenario, vault);
        ts::return_shared(global_state);
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    /// Test entry and vault property accessors
    #[test]
    fun test_property_accessors() {
        let mut scenario = ts::begin(USER_1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));

        sui_locker::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);

        let mut global_state = ts::take_shared<GlobalState>(&scenario);

        // Set clock to ensure non-zero timestamp
        clock::set_for_testing(&mut clock, 1000);

        // Create vault with detailed info
        sui_locker::create_vault(
            b"My Personal Vault",
            b"This is my personal password vault",
            b"https://example.com/vault-image.png",
            &mut global_state,
            &clock,
            ts::ctx(&mut scenario)
        );

        ts::next_tx(&mut scenario, USER_1);
        let mut vault = ts::take_from_sender<Vault>(&scenario);

        // Test vault accessors
        assert!(get_vault_name(&vault) == string::utf8(b"My Personal Vault"), 1);
        assert!(option::is_some(&get_vault_description(&vault)), 2);
        assert!(option::is_some(&get_vault_image_url(&vault)), 3);
        assert!(get_vault_owner(&vault) == USER_1, 4);
        assert!(vault_is_empty(&vault), 5);
        assert!(!vault_has_entries(&vault), 6);

        let vault_created_time = get_vault_created_at(&vault);
        assert!(vault_created_time > 0, 7);

        // Create entry with detailed info
        sui_locker::create_entry(
            &mut vault,
            b"Gmail Account",
            b"abc123hash456",
            b"encrypted_password_content",
            b"application/password",
            b"My primary Gmail account",
            vector[b"email", b"google", b"primary"],
            b"Remember to update every 3 months",
            b"https://gmail.com/favicon.ico",
            b"https://gmail.com",
            &mut global_state,
            &clock,
            ts::ctx(&mut scenario)
        );

        ts::next_tx(&mut scenario, USER_1);
        let entry = ts::take_from_sender<Entry>(&scenario);

        // Test entry accessors
        assert!(get_entry_name(&entry) == string::utf8(b"Gmail Account"), 8);
        assert!(get_entry_hash(&entry) == string::utf8(b"abc123hash456"), 9);
        assert!(get_entry_content(&entry) == string::utf8(b"encrypted_password_content"), 10);
        assert!(get_entry_owner(&entry) == USER_1, 11);

        assert!(option::is_some(&get_entry_description(&entry)), 12);
        assert!(option::is_some(&get_entry_notes(&entry)), 13);
        assert!(option::is_some(&get_entry_image_url(&entry)), 14);
        assert!(option::is_some(&get_entry_link(&entry)), 15);

        let entry_created_time = get_entry_created_at(&entry);
        let entry_updated_time = get_entry_updated_at(&entry);
        assert!(entry_created_time > 0, 16);
        assert!(entry_updated_time == entry_created_time, 17); // Should be same on creation

        // Test vault entry relationship
        let (vault_object_id, _, _, _, _, _, _, _) = sui_locker::get_vault_info(&vault);
        assert!(entry_belongs_to_vault(&entry, vault_object_id), 18);
        assert!(get_entry_vault_id(&entry) == vault_object_id, 19);

        // Test vault state after adding entry
        assert!(!vault_is_empty(&vault), 20);
        assert!(vault_has_entries(&vault), 21);
        assert!(sui_locker::get_vault_entry_count(&vault) == 1, 22);

        ts::return_to_sender(&scenario, entry);
        ts::return_to_sender(&scenario, vault);
        ts::return_shared(global_state);
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    /// Test time-based filtering functions
    #[test]
    fun test_time_based_filtering() {
        let mut scenario = ts::begin(USER_1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));

        sui_locker::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);

        let mut global_state = ts::take_shared<GlobalState>(&scenario);

        // Set clock to ensure non-zero timestamp
        clock::set_for_testing(&mut clock, 1000);

        // Create vault at time 1000
        clock::set_for_testing(&mut clock, 1000);
        sui_locker::create_vault(
            b"Time Test Vault",
            b"",
            b"",
            &mut global_state,
            &clock,
            ts::ctx(&mut scenario)
        );

        ts::next_tx(&mut scenario, USER_1);
        let mut vault = ts::take_from_sender<Vault>(&scenario);

        // Create entry at time 2000
        clock::set_for_testing(&mut clock, 2000);
        sui_locker::create_entry(
            &mut vault,
            b"Time Test Entry",
            b"hash",
            b"content",
            b"",
            b"",
            vector::empty(),
            b"",
            b"",
            b"",
            &mut global_state,
            &clock,
            ts::ctx(&mut scenario)
        );

        ts::next_tx(&mut scenario, USER_1);
        let entry = ts::take_from_sender<Entry>(&scenario);

        // Test time-based checks
        assert!(vault_created_after(&vault, 500), 1);   // Vault created after 500
        assert!(!vault_created_after(&vault, 1500), 2); // Vault not created after 1500
        assert!(vault_created_before(&vault, 1500), 3); // Vault created before 1500
        assert!(!vault_created_before(&vault, 500), 4); // Vault not created before 500

        assert!(entry_created_after(&entry, 1500), 5);  // Entry created after 1500
        assert!(!entry_created_after(&entry, 2500), 6); // Entry not created after 2500
        assert!(entry_created_before(&entry, 2500), 7); // Entry created before 2500
        assert!(!entry_created_before(&entry, 1500), 8); // Entry not created before 1500

        // Test update time (should be same as creation initially)
        assert!(entry_updated_after(&entry, 1500), 9);  // Entry updated after 1500
        assert!(!entry_updated_after(&entry, 2500), 10); // Entry not updated after 2500

        ts::return_to_sender(&scenario, entry);
        ts::return_to_sender(&scenario, vault);
        ts::return_shared(global_state);
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    /// Test global state and version functions
    #[test]
    fun test_global_state_functions() {
        let mut scenario = ts::begin(USER_1);

        sui_locker::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);

        let global_state = ts::take_shared<GlobalState>(&scenario);

        // Test global state version
        let version = get_global_state_version(&global_state);
        assert!(version == 1, 1); // Should start at version 1

        // Test global stats
        let (total_users, total_vaults, total_entries) = sui_locker::get_global_stats(&global_state);
        assert!(total_users == 0, 2); // No users yet
        assert!(total_vaults == 0, 3); // No vaults yet
        assert!(total_entries == 0, 4); // No entries yet

        ts::return_shared(global_state);
        ts::end(scenario);
    }

    /// Test edge cases and error conditions
    #[test]
    fun test_edge_cases() {
        let mut scenario = ts::begin(USER_1);

        sui_locker::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);

        let global_state = ts::take_shared<GlobalState>(&scenario);

        // Test pagination with non-existent user
        let (empty_vaults, total, has_more) = list_user_vaults(&global_state, USER_2, 0, 10);
        assert!(vector::length(&empty_vaults) == 0, 1);
        assert!(total == 0, 2);
        assert!(has_more == false, 3);

        // Test tag functions with non-existent user
        let empty_tags = get_user_unique_tags(&global_state, USER_2);
        assert!(vector::length(&empty_tags) == 0, 4);
        assert!(!user_has_tag(&global_state, USER_2, string::utf8(b"any")), 5);

        // Test user counts for non-existent user
        let (vault_count, entry_count, tag_count) = get_user_counts(&global_state, USER_2);
        assert!(vault_count == 0, 6);
        assert!(entry_count == 0, 7);
        assert!(tag_count == 0, 8);

        ts::return_shared(global_state);
        ts::end(scenario);
    }

    /// Test pagination boundary conditions
    #[test]
    #[expected_failure(abort_code = 4)] // E_INVALID_PAGINATION
    fun test_invalid_pagination_zero_limit() {
        let mut scenario = ts::begin(USER_1);

        sui_locker::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);

        let global_state = ts::take_shared<GlobalState>(&scenario);

        // This should fail with E_INVALID_PAGINATION
        let (_vaults, _total, _has_more) = list_user_vaults(&global_state, USER_1, 0, 0);

        ts::return_shared(global_state);
        ts::end(scenario);
    }

    /// Test pagination with start beyond available data
    #[test]
    fun test_pagination_beyond_data() {
        let mut scenario = ts::begin(USER_1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));

        sui_locker::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);

        let mut global_state = ts::take_shared<GlobalState>(&scenario);

        // Set clock to ensure non-zero timestamp
        clock::set_for_testing(&mut clock, 1000);

        // Create only 2 vaults
        sui_locker::create_vault(b"Vault 1", b"", b"", &mut global_state, &clock, ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);
        let vault1 = ts::take_from_sender<Vault>(&scenario);

        sui_locker::create_vault(b"Vault 2", b"", b"", &mut global_state, &clock, ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, USER_1);
        let vault2 = ts::take_from_sender<Vault>(&scenario);

        // Try to get page starting at index 5 (beyond available data)
        let (vaults, total, has_more) = list_user_vaults(&global_state, USER_1, 5, 10);
        assert!(vector::length(&vaults) == 0, 1); // Should be empty
        assert!(total == 2, 2); // Total should still be 2
        assert!(has_more == false, 3); // No more data

        ts::return_to_sender(&scenario, vault1);
        ts::return_to_sender(&scenario, vault2);
        ts::return_shared(global_state);
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }
}
