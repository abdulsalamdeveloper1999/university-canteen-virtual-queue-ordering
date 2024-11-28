import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedPeriod = 'Daily';
  late Stream<List<Order>> _ordersStream;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _ordersStream = Provider.of<OrderProvider>(context, listen: false)
        .streamCafeOrders(authProvider.userId!);
  }

  List<Order> _filterOrdersByPeriod(List<Order> orders) {
    final now = DateTime.now();
    return orders.where((order) {
      if (order.status != OrderStatus.completed) return false;

      final orderDate = order.createdAt;
      switch (_selectedPeriod) {
        case 'Daily':
          return orderDate.year == now.year &&
              orderDate.month == now.month &&
              orderDate.day == now.day;
        case 'Weekly':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return orderDate.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'Monthly':
          return orderDate.year == now.year && orderDate.month == now.month;
        default:
          return false;
      }
    }).toList();
  }

  Map<String, double> _calculateDailySales(List<Order> orders) {
    final salesMap = <String, double>{};
    for (var order in orders) {
      final dateKey = DateFormat('MMM d').format(order.createdAt);
      salesMap[dateKey] = (salesMap[dateKey] ?? 0) + order.totalAmount;
    }
    return salesMap;
  }

  List<FlSpot> _getSalesSpots(Map<String, double> salesMap) {
    final spots = <FlSpot>[];
    var index = 0.0;
    salesMap.forEach((date, amount) {
      spots.add(FlSpot(index, amount));
      index += 1;
    });
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allOrders = snapshot.data ?? [];
        final filteredOrders = _filterOrdersByPeriod(allOrders);
        final salesData = _calculateDailySales(filteredOrders);
        final totalSales = salesData.values.fold<double>(
          0.0,
          (sum, amount) => sum + amount,
        );
        final totalOrders = filteredOrders.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Sales Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    items: ['Daily', 'Weekly', 'Monthly']
                        .map((period) => DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPeriod = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSalesChart(salesData),
                    const SizedBox(height: 20),
                    _buildSalesStats(totalSales, totalOrders),
                    const SizedBox(height: 20),
                    _buildTopSellingItems(filteredOrders),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalesChart(Map<String, double> salesData) {
    final spots = _getSalesSpots(salesData);
    if (spots.isEmpty) {
      return const Center(child: Text('No sales data available'));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= salesData.keys.length)
                    return const Text('');
                  return Text(
                    salesData.keys.elementAt(value.toInt()),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesStats(double totalSales, int totalOrders) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            'Total Sales',
            '\$${totalSales.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Orders',
            totalOrders.toString(),
            Icons.shopping_bag,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingItems(List<Order> orders) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Selling Items',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text('${index + 1}'),
                ),
                title: Text('Item ${index + 1}'),
                trailing: Text('\$${(index + 1) * 10}'),
              );
            },
          ),
        ],
      ),
    );
  }
}
