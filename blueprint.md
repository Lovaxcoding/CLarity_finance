# Expense Tracking Mobile Application Blueprint

## Overview

A clean, modern, and intelligent **Expense Tracking Mobile Application** designed with **Flutter** for a seamless cross-platform user experience. The application will help users track their expenses, set budgets, and gain insights into their spending habits.

## Key Features

1.  **Intuitive Dashboard:** A central view showing a **summary** of the month's spending, remaining budget, and **categorized expense charts** (pie and bar).
2.  **Smart Input:** A fast-entry screen allowing users to log an expense with the amount, date, and an **AI-powered categorization** (e.g., "Grocery," "Transport") based on keywords in the description.
3.  **Budget Management:** Users can set **monthly budget limits** for specific categories. The app should display **real-time progress bars** to show how close the user is to exceeding the limit.
4.  **Advanced Filtering:** Capability to filter expenses by date range, category, and payment method, with the option to **export data** as a CSV file.
5.  **Secure Backend:** The entire application leverages **Supabase** for secure user **Authentication** (e-mail/password and social login), **Realtime Database** (PostgreSQL) for storing transaction data, and **Row Level Security (RLS)** to ensure users can only access their own expenses.

## Visual Style

A **minimalist** design with a dark mode option. Use **vibrant, yet professional, accent colors** (e.g., teal, deep blue) to highlight data points and call-to-action buttons. The overall aesthetic should communicate **financial clarity and control**. Focus on **legible typography** and clean spacing.

## Project Structure

The project will follow a feature-first structure with a layered architecture:

*   **presentation:** UI (widgets, pages)
*   **domain:** Business logic (models, use cases)
*   **data:** Repositories, data sources (Supabase)
*   **core:** Shared utilities, common extensions

## Plan

1.  **Create Project Structure:** Set up the basic directory structure for the application.
2.  **Add Dependencies:** Add necessary packages to the `pubspec.yaml` file.
3.  **Create `main.dart`:** Set up the main application entry point with a `MaterialApp`.
4.  **Create `theme.dart`:** Define the application's theme, including colors and typography.
5.  **Create `router.dart`:** Set up the application's routing using `go_router`.
6.  **Create `HomePage`:** Create the main screen with a `BottomNavigationBar`.
7.  **Create `DashboardPage`:** Create the dashboard screen with charts and summaries.
8.  **Create `ExpenseEntryPage`:** Create the expense entry screen with AI categorization.
9.  **Create `BudgetPage`:** Create the budget management screen.
10. **Create `FilterPage`:** Create the expense filtering and export screen.
11. **Create `SettingsPage`:** Create the settings and user account management screen.
12. **Integrate Supabase:** Connect the application to a Supabase backend for authentication and data storage.
