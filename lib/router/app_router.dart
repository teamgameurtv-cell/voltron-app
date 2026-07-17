import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/home/accueil_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/shop/product_detail_screen.dart';
import '../screens/shop/cart_screen.dart';
import '../screens/repairs/repairs_screen.dart';
import '../screens/repairs/booking_screen.dart';
import '../screens/repairs/quote_screen.dart';
import '../screens/loyalty/loyalty_screen.dart';
import '../screens/loyalty/voltron_care_screen.dart';
import '../screens/loyalty/care_payment_screen.dart';
import '../screens/loyalty/qr_code_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/garage_screen.dart';
import '../screens/account/info_screen.dart';
import '../screens/account/addresses_screen.dart';
import '../screens/account/payment_methods_screen.dart';
import '../screens/account/notification_settings_screen.dart';
import '../screens/account/repairs_history_screen.dart';
import '../screens/account/invoices_screen.dart';
import '../screens/account/warranty_screen.dart';
import '../screens/account/help_screen.dart';
import '../screens/account/about_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/admin/admin_stock_screen.dart';
import '../screens/admin/admin_rewards_screen.dart';
import '../screens/admin/admin_bookings_screen.dart';
import '../screens/admin/admin_repairs_screen.dart';
import '../screens/admin/admin_clients_screen.dart';
import '../screens/admin/admin_announcements_screen.dart';
import '../screens/admin/admin_repairs_board_screen.dart';
import '../screens/notifications/notifications_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const AccueilScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/shop',
            builder: (context, state) => const ShopScreen(),
            routes: [
              GoRoute(
                path: 'product/:id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => ProductDetailScreen(
                  productId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'cart',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/repairs',
            builder: (context, state) => const RepairsScreen(),
            routes: [
              GoRoute(
                path: 'book',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const BookingScreen(),
              ),
              GoRoute(
                path: 'quote/:orderId',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => QuoteScreen(
                  orderId: state.pathParameters['orderId']!,
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/loyalty',
            builder: (context, state) => const LoyaltyScreen(),
            routes: [
              GoRoute(
                path: 'care',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const VoltronCareScreen(),
                routes: [
                  GoRoute(
                    path: 'payment/:planId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => CarePaymentScreen(
                      planId: state.pathParameters['planId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'qr',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const QrCodeScreen(),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
            routes: [
              GoRoute(
                path: 'garage',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const GarageScreen(),
              ),
              GoRoute(
                path: 'info',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const InfoScreen(),
              ),
              GoRoute(
                path: 'addresses',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const AddressesScreen(),
              ),
              GoRoute(
                path: 'payment-methods',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const PaymentMethodsScreen(),
              ),
              GoRoute(
                path: 'notification-settings',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'repairs-history',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const RepairsHistoryScreen(),
              ),
              GoRoute(
                path: 'invoices',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const InvoicesScreen(),
              ),
              GoRoute(
                path: 'warranty',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const WarrantyScreen(),
              ),
              GoRoute(
                path: 'help',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const HelpScreen(),
              ),
              GoRoute(
                path: 'about',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const AboutScreen(),
              ),
            ],
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/products',
      builder: (context, state) => const AdminProductsScreen(),
    ),
    GoRoute(
      path: '/admin/stock',
      builder: (context, state) => const AdminStockScreen(),
    ),
    GoRoute(
      path: '/admin/rewards',
      builder: (context, state) => const AdminRewardsScreen(),
    ),
    GoRoute(
      path: '/admin/bookings',
      builder: (context, state) => const AdminBookingsScreen(),
    ),
    GoRoute(
      path: '/admin/repairs',
      builder: (context, state) => const AdminRepairsScreen(),
    ),
    GoRoute(
      path: '/admin/clients',
      builder: (context, state) => const AdminClientsScreen(),
    ),
    GoRoute(
      path: '/admin/announcements',
      builder: (context, state) => const AdminAnnouncementsScreen(),
    ),
    GoRoute(
      path: '/admin/repairs-board',
      builder: (context, state) => const AdminRepairsBoardScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);
