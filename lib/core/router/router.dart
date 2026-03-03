import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../widgets/shell_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/create_event_screen.dart';
import '../../features/expenses/presentation/create_expense_screen.dart';
import '../../features/expenses/presentation/expense_detail_screen.dart';
import '../../features/expenses/presentation/share_bill_screen.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/friends/presentation/friend_detail_screen.dart';
import '../../features/friends/presentation/add_friend_screen.dart';
import '../../features/personal_expenses/presentation/personal_expenses_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/settlements/presentation/payment_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isPayment = state.matchedLocation.startsWith('/payments');

      // Allow payment pages without auth
      if (isPayment) return null;

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Login route (no shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Public payment route (no shell)
      GoRoute(
        path: '/payments/:id',
        builder: (context, state) => PaymentScreen(
          paymentId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Authenticated routes with shell (nav bars)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/events',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EventsScreen(),
            ),
          ),
          GoRoute(
            path: '/event/:eventId',
            builder: (context, state) => EventDetailScreen(
              eventId: state.pathParameters['eventId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/event/:eventId/edit',
            builder: (context, state) => CreateEventScreen(
              eventId: state.pathParameters['eventId'],
            ),
          ),
          GoRoute(
            path: '/create-event',
            builder: (context, state) => const CreateEventScreen(),
          ),
          GoRoute(
            path: '/friends',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FriendsScreen(),
            ),
          ),
          GoRoute(
            path: '/friend/:friendId',
            builder: (context, state) => FriendDetailScreen(
              friendId: state.pathParameters['friendId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/add-friend/:friendId',
            builder: (context, state) => AddFriendScreen(
              friendCode: state.pathParameters['friendId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/personal-expenses',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PersonalExpensesScreen(),
            ),
          ),
          GoRoute(
            path: '/user-account',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountScreen(),
            ),
          ),
          GoRoute(
            path: '/createExpense/:type/:id',
            builder: (context, state) => CreateExpenseScreen(
              type: state.pathParameters['type'] ?? '',
              contextId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/expense/:expenseId',
            builder: (context, state) => ExpenseDetailScreen(
              expenseId: state.pathParameters['expenseId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/expense/:expenseId/edit',
            builder: (context, state) => CreateExpenseScreen(
              expenseId: state.pathParameters['expenseId'],
            ),
          ),
          GoRoute(
            path: '/shareBill/:expenseType',
            builder: (context, state) => ShareBillScreen(
              expenseType: state.pathParameters['expenseType'] ?? '',
            ),
          ),
        ],
      ),
    ],
  );
});
