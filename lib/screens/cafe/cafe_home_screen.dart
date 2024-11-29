import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_type.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart' as app_order;

import '../profile/profile_screen.dart';
import 'menu_management_screen.dart';
import 'order_management_screen.dart';
import 'sales_screen.dart';
// import 'order_provider.dart';
// import 'auth_provider.dart';
// import 'badge.dart';

class CafeHomeScreen extends StatefulWidget {
  const CafeHomeScreen({super.key});

  @override
  State<CafeHomeScreen> createState() => _CafeHomeScreenState();
}

class _CafeHomeScreenState extends State<CafeHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const MenuManagementScreen(),
      const OrderManagementScreen(),
      const SalesScreen(),
      const ProfileScreen(userType: UserType.cafe),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          return Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              color: Colors.black,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Menu',
                ),
                BottomNavigationBarItem(
                  icon: StreamBuilder<List<app_order.Order>>(
                    stream: orderProvider.streamPendingOrders(
                      Provider.of<AuthProvider>(context, listen: false)
                          .user!
                          .uid,
                    ),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.data?.length ?? 0;
                      return Badge(
                        backgroundColor: Theme.of(context).primaryColor,
                        isLabelVisible: pendingCount > 0,
                        label: Text(pendingCount.toString()),
                        child: const Icon(Icons.receipt_long),
                      );
                    },
                  ),
                  label: 'Orders',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Sales',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
