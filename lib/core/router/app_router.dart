import 'package:go_router/go_router.dart';

import '../../features/app_lock/screens/auth_screen.dart';
import '../../app/app_startup.dart';
import '../../models/note_model.dart';
import '../../models/transaction_model.dart';
import '../../views/app_shell.dart';
import '../../views/categories/category_management_screen.dart';
import '../../views/notes/note_editor_screen.dart';
import '../../views/notes/notes_screen.dart';
import '../../views/profile/profile_view_screen.dart';
import '../../views/settings/settings_screen.dart';
import '../../views/transactions/add_transaction_screen.dart';

/// Named locations keep navigation independent of feature file locations.
abstract final class AppRoutes {
  static const bootstrap = '/';
  static const pinSetup = '/pin-setup';
  static const pinVerify = '/pin-verify';
  static const logoutVerify = '/logout-verify';
  static const shell = '/app';
  static const profile = '/profile';
  static const categories = '/categories';
  static const notes = '/notes';
  static const noteEditor = '/note-editor';
  static const settings = '/settings';
  static const transactionEditor = '/transaction-editor';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.bootstrap,
  routes: [
    GoRoute(path: AppRoutes.bootstrap, builder: (_, _) => const AppStartupScreen()),
    GoRoute(path: AppRoutes.pinSetup, builder: (_, _) => const AuthScreen(isSetup: true, offerBiometricAfterSetup: true)),
    GoRoute(path: AppRoutes.pinVerify, builder: (_, _) => const AuthScreen(verifyOnly: true)),
    GoRoute(path: AppRoutes.logoutVerify, builder: (_, _) => const AuthScreen(verifyOnly: true, isLogoutConfirmation: true)),
    GoRoute(path: AppRoutes.shell, builder: (_, _) => const AppShell()),
    GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileViewScreen()),
    GoRoute(path: AppRoutes.categories, builder: (_, _) => const CategoryManagementScreen()),
    GoRoute(path: AppRoutes.notes, builder: (_, _) => const NotesScreen()),
    GoRoute(path: AppRoutes.noteEditor, builder: (_, state) => NoteEditorScreen(note: state.extra as NoteModel?)),
    GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: AppRoutes.transactionEditor,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is TransactionModel) return AddTransactionScreen(transaction: extra);
        return AddTransactionScreen(initialType: extra as String?);
      },
    ),
  ],
);
