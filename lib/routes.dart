import 'package:flutter/material.dart';

import 'package:myakieburger/views/manage_sales/franchisee_homepage.dart';
import 'package:myakieburger/views/manage_sales/add_meal_order.dart';
import 'package:myakieburger/views/manage_ingredients_orders/ingredient_order_page.dart';
import 'package:myakieburger/views/manage_ingredients_orders/list_of_ingredients.dart';
import 'package:myakieburger/views/manage_ingredients_orders/order_history.dart';
import 'package:myakieburger/views/manage_ingredients_tracking/balanced_ingredients.dart';
import 'package:myakieburger/views/manage_ingredients_tracking/edit_ingredients.dart';
import 'package:myakieburger/views/manage_report/add_report.dart';
import 'package:myakieburger/views/manage_report/franchisee_reports.dart';
import 'package:myakieburger/views/manage_report/report_page.dart';
import 'package:myakieburger/views/manage_user/login_page.dart';
import 'package:myakieburger/views/manage_user/register_page.dart';

import 'package:myakieburger/views/manage_user/franchisee_main_container.dart';
import 'package:myakieburger/views/manage_sales/analysis_page.dart';

import 'package:myakieburger/views/manage_sales/admin_homepage.dart';
import 'package:myakieburger/views/manage_user/admin_main_container.dart';
import 'package:myakieburger/views/manage_user/fadmin_main_container.dart';

import 'package:myakieburger/views/manage_sales/admin_sales_leaderboard.dart';
import 'package:myakieburger/views/manage_sales/franchisees_sales_leaderboard.dart';

import 'package:myakieburger/views/manage_user/admin_profile.dart';
import 'package:myakieburger/views/manage_user/franchisee_profile.dart';

import 'package:myakieburger/views/manage_report/report_details_page.dart';
import 'package:myakieburger/views/manage_sales/admin_analysis_page.dart';

import 'package:myakieburger/views/manage_user/dagent_main_container.dart';
import 'package:myakieburger/views/manage_user/dagent_profile.dart';

import 'package:myakieburger/views/manage_user/franchisees_list.dart';

class Routes {
  static const String login = '/';
  static const String register = '/register';
  static const String franchiseeHomepage = '/franchisee_homepage';
  static const franchiseeMainContainer = '/franchiseeMainContainer';
  static const String fad = '/FAdminMainContainer';
  static const String addMealOrder = '/add_meal_order';
  static const String ingredientOrderPage = '/ingredient_order_page';
  static const String listOfIngredients = '/list_of_ingredients';
  static const String orderHistory = '/order_history';
  static const String balancedIngredients = '/balanced_ingredients';
  static const String editIngredients = '/edit_ingredients';
  static const String reportPage = '/report_page';
  static const String addReport = '/add_report';
  static const String franchiseeReports = '/franchisee_reports';
  static const String analysisPage = '/analysis_page';
  static const String franchiseesList = '/franchisees_list';

  static const String adminMainContainer = '/adminMainContainer';
  static const String adminHomepage = '/admin_homepage';

  static const String adminSalesLeaderboard = '/admin_sales_leaderboard';
  static const String franchiseesSalesLeaderboard =
      '/franchisees_sales_leaderboard';

  static const String adminProfile = '/admin_profile';
  static const String franchiseeProfile = '/franchisee_profile';

  static const String reportDetailsPage = '/report_details_page';
  static const String adminAnalysisPage = '/admin_analysis_page';

  static const String DAMainContainer = '/DAMainContainer';
  static const String DAProfile = '/DAProfile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case franchiseeHomepage:
        return MaterialPageRoute(builder: (_) => const FranchiseeHomepage());
      case franchiseeMainContainer:
        return MaterialPageRoute(
          builder: (_) => const FranchiseeMainContainer(),
        );
      case fad:
        return MaterialPageRoute(
          builder: (_) => const FAdminMainContainer(),
        );
      case adminMainContainer:
        return MaterialPageRoute(builder: (_) => const AdminMainContainer());
      case adminHomepage:
        return MaterialPageRoute(builder: (_) => const AdminHomepage());
      case addMealOrder:
        return MaterialPageRoute(builder: (_) => const AddMealOrder());
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
      case analysisPage:
        return MaterialPageRoute(builder: (_) => const AnalysisPage());
      case adminSalesLeaderboard:
        return MaterialPageRoute(builder: (_) => const AdminSalesLeaderboard());
      case franchiseesSalesLeaderboard:
        return MaterialPageRoute(
          builder: (_) => const FranchiseesSalesLeaderboard(),
        );
      case franchiseesList:
        return MaterialPageRoute(builder: (_) => const FranchiseesList());
      case adminProfile:
        return MaterialPageRoute(builder: (_) => const AdminProfile());
      case franchiseeProfile:
        return MaterialPageRoute(builder: (_) => const FranchiseeProfile());
      case reportDetailsPage:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ReportDetailsPage(report: args),
        );
      case adminAnalysisPage:
        return MaterialPageRoute(builder: (_) => const AdminAnalysisPage());
      case DAMainContainer:
        return MaterialPageRoute(builder: (_) => const DeliveryAgentMainContainer());
      case DAProfile:
        return MaterialPageRoute(builder: (_) => const DAgentProfile());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
