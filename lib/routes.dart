import 'package:flutter/material.dart';

import 'package:myakieburger/views/manage_daily_sales/franchisee_homepage.dart';
import 'package:myakieburger/views/manage_daily_sales/sales_order.dart';
import 'package:myakieburger/views/manage_ingredients_orders/ingredient_order_page.dart';
import 'package:myakieburger/views/manage_ingredients_orders/list_of_ingredients.dart';
import 'package:myakieburger/views/manage_ingredients_orders/order_history.dart';
import 'package:myakieburger/views/manage_ingredients_tracking/balanced_ingredients.dart';
import 'package:myakieburger/views/manage_ingredients_tracking/edit_ingredients.dart';
import 'package:myakieburger/views/manage_report/add_report.dart';
import 'package:myakieburger/views/manage_report/franchisee_reports.dart';
import 'package:myakieburger/views/manage_report/report_page.dart';
import 'package:myakieburger/views/manage_user/dashboard_page.dart';
import 'package:myakieburger/views/manage_user/login_page.dart';
import 'package:myakieburger/views/manage_user/register_page.dart';

class Routes {
  static const String login = '/';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String franchiseeHomepage = '/franchisee_homepage';
  static const String salesOrder = '/sales_order';
  static const String ingredientOrderPage = '/ingredient_order_page';
  static const String listOfIngredients = '/list_of_ingredients';
  static const String orderHistory = '/order_history';
  static const String balancedIngredients = '/balanced_ingredients';
  static const String editIngredients = '/edit_ingredients';
  static const String reportPage = '/report_page';
  static const String addReport = '/add_report';
  static const String franchiseeReports = '/franchisee_reports';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case franchiseeHomepage:
        return MaterialPageRoute(builder: (_) => const FranchiseeHomepage());
      case salesOrder:
        return MaterialPageRoute(builder: (_) => const SalesOrder());
      case ingredientOrderPage:
        return MaterialPageRoute(builder: (_) => const IngredientOrderPage());
      case listOfIngredients:
        return MaterialPageRoute(builder: (_) => const ListOfIngredients());
      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistory());
      case balancedIngredients:
        return MaterialPageRoute(builder: (_) => const BalancedIngredients());
      case editIngredients:
        return MaterialPageRoute(builder: (_) => const EditIngredients());
      case reportPage:
        return MaterialPageRoute(builder: (_) => const ReportPage());
      case addReport:
        return MaterialPageRoute(builder: (_) => const AddReport());
      case franchiseeReports:
        return MaterialPageRoute(builder: (_) => const FranchiseeReports());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
