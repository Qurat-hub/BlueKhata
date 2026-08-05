import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/supabase_service.dart';

import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/language_selection_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/forget_password_screen.dart';

import '../../features/business/presentation/screens/business_selection_screen.dart';
import '../../features/business/presentation/screens/create_business_screen.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/add_edit_customer_screen.dart';

import '../../features/ledger/presentation/screens/ledger_entry_screen.dart';

import '../../features/cashbook/presentation/screens/cashbook_screen.dart';
import '../../features/cashbook/presentation/screens/cash_entry_screen.dart';
import '../../features/cashbook/presentation/screens/cash_report_screen.dart';

import '../../features/expense/presentation/screens/expense_screen.dart';
import '../../features/expense/presentation/screens/expense_entry_screen.dart';
import '../../features/expense/presentation/screens/expense_report_screen.dart';

import '../../features/stock/presentation/screens/stock_list_screen.dart';
import '../../features/stock/presentation/screens/add_edit_product_screen.dart';
import '../../features/stock/presentation/screens/product_detail_screen.dart';

import '../../features/billing/presentation/screens/bill_list_screen.dart';
import '../../features/billing/presentation/screens/create_invoice_screen.dart';
import '../../features/billing/presentation/screens/invoice_detail_screen.dart';

import '../../features/staff/presentation/screens/staff_list_screen.dart';
import '../../features/staff/presentation/screens/add_edit_staff_screen.dart';
import '../../features/staff/presentation/screens/staff_detail_screen.dart';
import '../../features/staff/presentation/screens/attendance_screen.dart';

import '../shared/widgets/coming_soon_screen.dart';
import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/qr/presentation/screens/qr_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const language = '/language';

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const businessSelection = '/businesses';
  static const createBusiness = '/businesses/create';

  static const dashboard = '/dashboard';

  static const customers = '/customers';
  static const customerDetail = '/customers/:customerId';
  static const addEditCustomer = '/customers/edit';
  static const ledgerEntry = '/customers/:customerId/entry';

  static const cashbook = '/cashbook';
  static const cashEntry = '/cashbook/entry';
  static const cashReport = '/cashbook/report';

  static const expenseBook = '/expense';
  static const expenseEntry = '/expense/entry';
  static const expenseReport = '/expense/report';

  static const stock = '/stock';
  static const stockDetail = '/stock/:productId';
  static const addEditProduct = '/stock/edit';

  static const billBook = '/bills';
  static const createInvoice = '/bills/create';
  static const billDetail = '/bills/:invoiceId';

  static const staffBook = '/staff';
  static const addEditStaff = '/staff/edit';
  static const staffDetail = '/staff/:staffId';
  static const attendance = '/staff/attendance';

  static const calculator = '/calculator';

  static const settings = '/settings';

  static const qr = '/qr';
  /// Generic destination for KHATA/PAYMENTS/MORE tiles whose module isn't
  /// implemented yet. Pass a [ComingSoonScreen] via `extra`. Swap the tile's
  /// `context.push(...)` call to the real feature route as each module is
  /// built — this route stays reserved for whatever is still unbuilt.
  static const comingSoon = '/coming-soon';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,

    redirect: (context, state) {
      final loggedIn = SupabaseService.isLoggedIn;

      final authRoutes = {
        AppRoutes.splash,
        AppRoutes.language,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      };

      final isAuthPage = authRoutes.contains(state.matchedLocation);

      if (!loggedIn && !isAuthPage) {
        return AppRoutes.login;
      }

      if (loggedIn &&
          (state.matchedLocation == AppRoutes.login ||
              state.matchedLocation == AppRoutes.register)) {
        return AppRoutes.dashboard;
      }

      return null;
    },

    routes: [

      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      GoRoute(
        path: AppRoutes.language,
        builder: (_, __) => const LanguageSelectionScreen(),
      ),

      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: AppRoutes.businessSelection,
        builder: (_, __) => const BusinessSelectionScreen(),
      ),

      GoRoute(
        path: AppRoutes.createBusiness,
        builder: (_, __) => const CreateBusinessScreen(),
      ),

      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.customers,
        builder: (_, __) => const CustomerListScreen(),
      ),

      GoRoute(
        path: AppRoutes.addEditCustomer,
        builder: (context, state) {
          final id = state.extra as String?;
          return AddEditCustomerScreen(customerId: id);
        },
      ),

      GoRoute(
        path: AppRoutes.customerDetail,
        builder: (context, state) {
          final id = state.pathParameters['customerId']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),

      GoRoute(
        path: AppRoutes.ledgerEntry,
        builder: (context, state) {
          final id = state.pathParameters['customerId']!;
          final isCredit = state.extra as bool? ?? true;

          return LedgerEntryScreen(
            customerId: id,
            isCredit: isCredit,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.comingSoon,
        builder: (context, state) => state.extra as ComingSoonScreen,
      ),

      GoRoute(
        path: AppRoutes.cashbook,
        builder: (_, __) => const CashbookScreen(),
      ),

      GoRoute(
        path: AppRoutes.cashEntry,
        builder: (context, state) {
          final isCashIn = state.extra as bool? ?? true;
          return CashEntryScreen(isCashIn: isCashIn);
        },
      ),

      GoRoute(
        path: AppRoutes.cashReport,
        builder: (_, __) => const CashReportScreen(),
      ),

      GoRoute(
        path: AppRoutes.expenseBook,
        builder: (_, __) => const ExpenseScreen(),
      ),

      GoRoute(
        path: AppRoutes.expenseEntry,
        builder: (_, __) => const ExpenseEntryScreen(),
      ),

      GoRoute(
        path: AppRoutes.expenseReport,
        builder: (_, __) => const ExpenseReportScreen(),
      ),

      GoRoute(
        path: AppRoutes.stock,
        builder: (_, __) => const StockListScreen(),
      ),

      GoRoute(
        path: AppRoutes.addEditProduct,
        builder: (context, state) {
          final productId = state.extra as String?;
          return AddEditProductScreen(productId: productId);
        },
      ),

      GoRoute(
        path: AppRoutes.stockDetail,
        builder: (context, state) {
          final id = state.pathParameters['productId']!;
          return ProductDetailScreen(productId: id);
        },
      ),

      GoRoute(
        path: AppRoutes.billBook,
        builder: (_, __) => const BillListScreen(),
      ),

      GoRoute(
        path: AppRoutes.createInvoice,
        builder: (_, __) => const CreateInvoiceScreen(),
      ),

      GoRoute(
        path: AppRoutes.billDetail,
        builder: (context, state) {
          final id = state.pathParameters['invoiceId']!;
          return InvoiceDetailScreen(invoiceId: id);
        },
      ),

      GoRoute(
        path: AppRoutes.staffBook,
        builder: (_, __) => const StaffListScreen(),
      ),

      GoRoute(
        path: AppRoutes.addEditStaff,
        builder: (context, state) {
          final staffId = state.extra as String?;
          return AddEditStaffScreen(staffId: staffId);
        },
      ),

      GoRoute(
        path: AppRoutes.attendance,
        builder: (_, __) => const AttendanceScreen(),
      ),

      GoRoute(
        path: AppRoutes.staffDetail,
        builder: (context, state) {
          final id = state.pathParameters['staffId']!;
          return StaffDetailScreen(staffId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.calculator,
        builder: (_, __) => const CalculatorScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.qr,
        builder: (_, __) => const QRScreen(),
      ),
    ],
  );
});