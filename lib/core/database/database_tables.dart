abstract final class DatabaseTables {
  static const String categories = 'categories';
  static const String wallets = 'wallets';
  static const String transactions = 'transactions';
  static const String budgets = 'budgets';
  static const String settings = 'settings';
  static const String notes = 'notes';
  static const String syncQueue = 'sync_queue';
  static const String subcategories = 'subcategories';

  static const int dbVersion = 11;

  static const String createCategories = '''
    CREATE TABLE $categories (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      wallet_id TEXT NOT NULL DEFAULT '',
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      icon TEXT NOT NULL,
      color TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      is_builtin INTEGER NOT NULL DEFAULT 0,
      is_hidden INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const String createWallets = '''
    CREATE TABLE $wallets (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      name TEXT NOT NULL,
      balance REAL NOT NULL DEFAULT 0,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String createTransactions = '''
    CREATE TABLE $transactions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category_id TEXT NOT NULL,
      wallet_id TEXT NOT NULL,
      date TEXT NOT NULL,
      note TEXT,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES $categories(id),
      FOREIGN KEY (wallet_id) REFERENCES $wallets(id)
    )
  ''';


  static const String createBudgets = '''
    CREATE TABLE $budgets (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      wallet_id TEXT NOT NULL DEFAULT '',
      category_id TEXT NOT NULL,
      amount REAL NOT NULL,
      month_year TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES $categories(id)
    )
  ''';

  static const String createSettings = '''
    CREATE TABLE $settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';

  static const String createNotes = '''
    CREATE TABLE $notes (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      wallet_id TEXT NOT NULL DEFAULT '',
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const String createSyncQueue = '''
    CREATE TABLE $syncQueue (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      wallet_id TEXT NOT NULL DEFAULT '',
      operation TEXT NOT NULL,
      user_id TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  // Used only when upgrading databases created before subcategories were removed.
  static const String createSubcategories = '''
    CREATE TABLE $subcategories (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      wallet_id TEXT NOT NULL DEFAULT '',
      category_id TEXT NOT NULL,
      name TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      UNIQUE(user_id, category_id, name),
      FOREIGN KEY (category_id) REFERENCES $categories(id) ON DELETE CASCADE
    )
  ''';

  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Salary', 'type': 'income', 'icon': 'work', 'color': '#10B981'},
    {'name': 'Freelance', 'type': 'income', 'icon': 'laptop', 'color': '#34D399'},
    {'name': 'Investments', 'type': 'income', 'icon': 'trending_up', 'color': '#06B6D4'},
    {'name': 'Rental income', 'type': 'income', 'icon': 'home', 'color': '#6366F1'},
    {'name': 'Business', 'type': 'income', 'icon': 'store', 'color': '#8B5CF6'},
    {'name': 'Pension', 'type': 'income', 'icon': 'account_balance', 'color': '#0EA5E9'},
    {'name': 'Interest', 'type': 'income', 'icon': 'percent', 'color': '#14B8A6'},
    {'name': 'Dividends', 'type': 'income', 'icon': 'savings', 'color': '#22C55E'},
    {'name': 'Gifts', 'type': 'income', 'icon': 'card_giftcard', 'color': '#EC4899'},
    {'name': 'Refunds', 'type': 'income', 'icon': 'currency_exchange', 'color': '#F59E0B'},
    {'name': 'Other income', 'type': 'income', 'icon': 'payments', 'color': '#6366F1'},
    {'name': 'Food', 'type': 'expense', 'icon': 'restaurant', 'color': '#EF4444'},
    {'name': 'Transport', 'type': 'expense', 'icon': 'directions_car', 'color': '#F59E0B'},
    {'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '#8B5CF6'},
    {'name': 'Bills', 'type': 'expense', 'icon': 'receipt', 'color': '#3B82F6'},
    {'name': 'Entertainment', 'type': 'expense', 'icon': 'movie', 'color': '#EC4899'},
    {'name': 'Health', 'type': 'expense', 'icon': 'favorite', 'color': '#14B8A6'},
    {'name': 'Housing', 'type': 'expense', 'icon': 'home', 'color': '#F97316'},
    {'name': 'Education', 'type': 'expense', 'icon': 'school', 'color': '#0EA5E9'},
    {'name': 'Insurance', 'type': 'expense', 'icon': 'shield', 'color': '#64748B'},
    {'name': 'Travel', 'type': 'expense', 'icon': 'flight', 'color': '#A855F7'},
    {'name': 'Personal care', 'type': 'expense', 'icon': 'spa', 'color': '#D946EF'},
    {'name': 'Groceries', 'type': 'expense', 'icon': 'groceries', 'color': '#84CC16'},
    {'name': 'Utilities', 'type': 'expense', 'icon': 'utilities', 'color': '#0EA5E9'},
    {'name': 'Clothing', 'type': 'expense', 'icon': 'clothing', 'color': '#D946EF'},
    {'name': 'Vehicle maintenance', 'type': 'expense', 'icon': 'car_repair', 'color': '#F97316'},
    {'name': 'Pets', 'type': 'expense', 'icon': 'pets', 'color': '#A16207'},
    {'name': 'Gifts & donations', 'type': 'expense', 'icon': 'card_giftcard', 'color': '#EC4899'},
    {'name': 'Subscriptions', 'type': 'expense', 'icon': 'subscriptions', 'color': '#8B5CF6'},
    {'name': 'Taxes', 'type': 'expense', 'icon': 'tax', 'color': '#64748B'},
    {'name': 'Childcare', 'type': 'expense', 'icon': 'childcare', 'color': '#F472B6'},
    {'name': 'Debt payments', 'type': 'expense', 'icon': 'payments', 'color': '#3B82F6'},
  ];

}
