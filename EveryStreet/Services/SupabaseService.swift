import Foundation

// TODO Phase 2: Add Supabase Swift SDK via SPM.
//   In Xcode: File › Add Package Dependencies
//   URL: https://github.com/supabase/supabase-swift
//   Then replace this stub with a real SupabaseClient.

struct SupabaseService {
    // TODO Phase 2: let client = SupabaseClient(supabaseURL: URL(string: AppConstants.Supabase.projectURL)!, supabaseKey: AppConstants.Supabase.anonKey)

    func uploadWalk(_ walk: Walk, userID: String) async throws {
        // TODO Phase 2: INSERT into walks table; RLS policy ensures users only write own rows.
        throw ServiceError.notImplemented
    }

    func updateStreetProgress(userID: String, walkedStreetIDs: Set<String>) async throws {
        // TODO Phase 2: UPSERT walked street IDs; leaderboard view aggregates per-user counts.
        throw ServiceError.notImplemented
    }

    func fetchLeaderboard(scope: LeaderboardScope, zipCode: String) async throws -> [LeaderboardEntry] {
        // TODO Phase 2: Query leaderboard view filtered by zip code.
        // Global scope: anonymous usernames. Friends scope: real usernames via friends table.
        throw ServiceError.notImplemented
    }

    func addFriend(userID: String, friendCode: String) async throws {
        // TODO Phase 2: Look up friend by code; insert into friends table (bidirectional).
        throw ServiceError.notImplemented
    }
}
