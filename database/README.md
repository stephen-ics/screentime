# 🏗️ ScreenTime Database Structure

This directory contains the complete, production-ready database structure for the ScreenTime app, organized in a modular and maintainable way.

## 📁 Directory Structure

```
database/
├── README.md                    # This file
├── deploy.sql                   # Main deployment script
├── migrations/                  # Database version control
│   └── 001_initial_setup.sql   # Initial migration
├── schemas/                     # Table definitions
│   ├── profiles.sql            # User profiles and auth
│   ├── time_banks.sql          # Time banking system tables  
│   └── tasks_and_apps.sql      # Tasks and approved apps
├── functions/                   # Stored procedures
│   ├── common_functions.sql    # Utility functions
│   ├── auth_functions.sql      # Authentication functions
│   └── time_bank_functions.sql # Time bank operations
├── policies/                    # Row Level Security
│   └── row_level_security.sql  # RLS policies for all tables
├── indexes/                     # Performance optimization
│   └── performance_indexes.sql # All database indexes
├── triggers/                    # Automated functionality
│   └── database_triggers.sql   # Database triggers
├── seeds/                       # Sample/test data
│   └── sample_data.sql         # Development sample data
└── maintenance/                 # Database maintenance
    └── cleanup_scripts.sql     # Maintenance and cleanup
```

## 🚀 Quick Start

### 1. Full Deployment (Recommended)

Run the main deployment script in your Supabase SQL Editor:

```sql
-- Copy and paste the entire contents of deploy.sql
\i database/deploy.sql
```

### 2. Manual Step-by-Step

If you prefer to run components individually:

```sql
-- 1. Migrations
\i database/migrations/001_initial_setup.sql

-- 2. Schemas
\i database/schemas/profiles.sql
\i database/schemas/time_banks.sql
\i database/schemas/tasks_and_apps.sql

-- 3. Functions
\i database/functions/common_functions.sql
\i database/functions/auth_functions.sql
\i database/functions/time_bank_functions.sql

-- 4. Indexes
\i database/indexes/performance_indexes.sql

-- 5. Triggers
\i database/triggers/database_triggers.sql

-- 6. Security
\i database/policies/row_level_security.sql
```

## 📊 Database Schema Overview

### Core Tables

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles linked to Supabase auth |
| `time_banks` | Central time balance for each user |
| `time_ledger_entries` | Immutable audit log of all transactions |
| `unlocked_sessions` | Active sessions with app access |
| `tasks` | Tasks users can complete to earn time |
| `approved_apps` | Apps accessible during unlocked sessions |
| `offline_transaction_queue` | Queue for offline sync |

### Key Functions

| Function | Purpose |
|----------|---------|
| `update_time_bank()` | Atomically update time bank balance |
| `start_unlocked_session()` | Start session and deduct time |
| `process_offline_transactions()` | Sync offline transactions |
| `handle_new_user()` | Auto-create profile on signup |

## 🔒 Security Features

- **Row Level Security (RLS)** enabled on all tables
- Users can only access their own data
- Service role has elevated permissions for system operations
- Audit trail for all time bank transactions
- Input validation and constraints

## 🛠️ Maintenance

### Daily Maintenance

Run the daily maintenance function:

```sql
SELECT run_daily_maintenance();
```

This will:
- Clean up expired sessions
- Remove old failed transactions
- Update database statistics

### Health Check

Check database health:

```sql
SELECT * FROM get_database_health_stats();
```

### Emergency Reset (Use with caution!)

Reset a user's time bank:

```sql
SELECT emergency_reset_user_time_bank(
    'user-uuid-here',
    120, -- new balance in minutes
    'Reason for reset'
);
```

## 📈 Performance Optimizations

- **Indexes** on all frequently queried columns
- **Composite indexes** for complex queries
- **Partial indexes** for filtered queries
- **Foreign key indexes** for join operations
- **Timestamp indexes** for time-series queries

## 🧪 Development

### Sample Data

For development environments, load sample data:

```sql
\i database/seeds/sample_data.sql
```

This creates:
- Sample approved apps (educational, games, social)
- Sample tasks (daily, weekly, one-time)
- Test data for development

### Migration Tracking

All changes are tracked in the `schema_migrations` table:

```sql
SELECT * FROM schema_migrations ORDER BY applied_at;
```

## 🔄 Deployment Best Practices

1. **Always backup** before running migrations
2. **Test in staging** environment first
3. **Run during low traffic** periods
4. **Monitor performance** after deployment
5. **Verify completion** using the deployment script's built-in checks

## 🚨 Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure you have the correct database permissions
2. **Function Not Found**: Check that functions are created before triggers
3. **RLS Blocking Queries**: Verify policies are correctly configured
4. **Migration Conflicts**: Check `schema_migrations` table for duplicates

### Debug Queries

```sql
-- Check table creation
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check function creation
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public';

-- Check RLS policies
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

## 📝 Version History

| Version | Date | Description |
|---------|------|-------------|
| 001 | 2024-01-01 | Initial database setup |
| DEPLOY_* | Various | Full deployment timestamps |

## 🤝 Contributing

When adding new database changes:

1. Create a new migration file with incremented version
2. Update appropriate schema/function files
3. Add necessary indexes and policies
4. Update this README
5. Test thoroughly before deployment

---

*This database structure follows PostgreSQL and Supabase best practices for scalability, security, and maintainability.* 