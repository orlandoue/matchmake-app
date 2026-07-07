// Supabase table names - Update these according to your database schema
class SupabaseTables {
  // User tables
  static const String usersTable = 'users'; // Updated from business_owner_users
  // static const String consumerUserTable = 'consumer_users';
  static const String userProfilesTable = 'user_profiles';

  // Court tables
  static const String courtsTable = 'courts';
  static const String courtAssignmentsTable = 'court_assignments';
  static const String sportsTable = 'sports';
  static const String courtSportsTable = 'court_sports';

  // Identity Verification table
  static const String identityVerificationsTable = 'identity_verifications';

  // Match tables
  static const String matchesTable = 'matches';

  // Ticket tables
  static const String ticketsTable = 'tickets';
  static const String ticketTransactionsTable = 'ticket_transactions';

  // FAQ tables
  static const String faqsTable = 'faq';

  // Policy tables
  static const String policyTable = 'policy';

  // Authentication related tables
  static const String userSessionsTable = 'user_sessions';
  static const String userPreferencesTable = 'user_preferences';

  // Business related tables
  static const String businessTable = 'businesses';
  static const String businessUsersTable =
      'business_users'; // Junction table for business-user relationship
  static const String businessMembersTable = 'business_members';
  static const String businessPermissionsTable = 'business_permissions';

  // Compliance related tables
  static const String complianceRecordsTable = 'compliance_records';
  static const String auditLogsTable = 'audit_logs';
  static const String certificatesTable = 'certificates';

  // Logs related tables
  static const String auditCheckLogsTable = 'audit_check_logs';
  static const String serverAcknowledgmentsTable = 'server_acknowledgments';

  // Notification tables
  static const String notificationsTable = 'notifications';
  static const String notificationPreferencesTable = 'notification_preferences';

  // File storage tables
  static const String documentsTable = 'documents';
  static const String imagesTable = 'images';

  // Training module tables
  static const String coursesTable = 'courses';
  static const String modulesTable = 'modules';
  static const String quizTable = 'quiz';
  static const String questionsTable = 'questions';
  static const String optionsTable = 'options';
  static const String quizResultsTable = 'quiz_results';

  // System tables
  static const String settingsTable = 'app_settings';
  static const String logsTable = 'system_logs';

  // Forum tables
  static const String forumPostsTable = 'forum_posts';
  static const String forumCommentsTable = 'forum_comments';
  static const String forumLikesTable = 'forum_likes';
}

// Storage bucket names - Update these according to your Supabase storage setup
class SupabaseStorageBuckets {
  static const String profileImages = 'profile-images';
  static const String businessDocuments = 'business-documents';
  static const String certificates = 'certificates';
  static const String complianceDocuments = 'compliance-documents';
  static const String publicAssets = 'public-assets';

  // Using public bucket with folders for audit logs and server acknowledgments
  static const String auditCheckLogsDocuments = 'publicbucket';
  static const String serverAcknowledgmentDocuments = 'publicbucket';
}

// Database policies and RLS configurations
class SupabasePolicies {
  // User access policies
  static const String userOwnDataPolicy = 'user_own_data_policy';
  static const String businessMemberPolicy = 'business_member_policy';
  static const String adminAccessPolicy = 'admin_access_policy';

  // Storage policies
  static const String userOwnFilesPolicy = 'user_own_files_policy';
  static const String businessFilesPolicy = 'business_files_policy';
  static const String publicReadPolicy = 'public_read_policy';
}
