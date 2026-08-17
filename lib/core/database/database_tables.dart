abstract final class DatabaseTables {
  static const String categories = 'categories';
  static const String wallets = 'wallets';
  static const String transactions = 'transactions';
  static const String budgets = 'budgets';
  static const String settings = 'settings';

  static const int dbVersion = 1;

  static const String createCategories = '''
    CREATE TABLE $categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      icon TEXT NOT NULL,
      color TEXT NOT NULL
    )
  ''';

  static const String createWallets = '''
    CREATE TABLE $wallets (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      balance REAL NOT NULL DEFAULT 0
    )
  ''';

  static const String createTransactions = '''
    CREATE TABLE $transactions (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category_id TEXT NOT NULL,
      wallet_id TEXT NOT NULL,
      date TEXT NOT NULL,
      note TEXT,
      FOREIGN KEY (category_id) REFERENCES $categories(id),
      FOREIGN KEY (wallet_id) REFERENCES $wallets(id)
    )
  ''';

  static const String createBudgets = '''
    CREATE TABLE $budgets (
      id TEXT PRIMARY KEY,
      category_id TEXT NOT NULL,
      amount REAL NOT NULL,
      month_year TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES $categories(id)
    )
  ''';

  static const String createSettings = '''
    CREATE TABLE $settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';

  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Salary', 'type': 'income', 'icon': 'work', 'color': '#10B981'},
    {'name': 'Freelance', 'type': 'income', 'icon': 'laptop', 'color': '#34D399'},
    {'name': 'Food', 'type': 'expense', 'icon': 'restaurant', 'color': '#EF4444'},
    {'name': 'Transport', 'type': 'expense', 'icon': 'directions_car', 'color': '#F59E0B'},
    {'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '#8B5CF6'},
    {'name': 'Bills', 'type': 'expense', 'icon': 'receipt', 'color': '#3B82F6'},
    {'name': 'Entertainment', 'type': 'expense', 'icon': 'movie', 'color': '#EC4899'},
    {'name': 'Health', 'type': 'expense', 'icon': 'favorite', 'color': '#14B8A6'},
  ];
}
