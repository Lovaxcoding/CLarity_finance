
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/presentation/pages/dashboard_page.dart';
import 'package:myapp/presentation/pages/expense_entry_page.dart';
import 'package:myapp/presentation/pages/budget_page.dart';
import 'package:myapp/presentation/pages/filter_page.dart';
import 'package:myapp/presentation/pages/settings_page.dart';
import 'package:myapp/presentation/pages/home_page.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomePage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'dashboard',
          builder: (BuildContext context, GoRouterState state) {
            return const DashboardPage();
          },
        ),
        GoRoute(
          path: 'expense_entry',
          builder: (BuildContext context, GoRouterState state) {
            return const ExpenseEntryPage();
          },
        ),
        GoRoute(
          path: 'budget',
          builder: (BuildContext context, GoRouterState state) {
            return const BudgetPage();
          },
        ),
        GoRoute(
          path: 'filter',
          builder: (BuildContext context, GoRouterState state) {
            return const FilterPage();
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsPage();
          },
        ),
      ],
    ),
  ],
);
