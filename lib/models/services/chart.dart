import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyRevenueChart extends StatelessWidget {
  final Map<int, double> monthlyData; // Données formatées {1: 1500.0, 2: 2200.0, ...}

  const MonthlyRevenueChart({super.key, required this.monthlyData});

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.blueAccent,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxY = monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.1;

    final barGroups = monthlyData.entries.map((entry) {
      return makeGroupData(entry.key, entry.value);
    }).toList();

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      // axisSide: meta.axisSide,
                      space: 4.0,
                      meta: meta,
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 20,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    // Simplifier l'affichage des milliers
                    String text;
                    if (value == 0) {
                      text = '0';
                    } else if (value >= 1000) {
                      text = '${(value / 1000).toStringAsFixed(0)}k';
                    } else {
                      text = value.toStringAsFixed(0);
                    }
                    return Text(
                      text,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.left,
                    );
                  },
                ),
              ),
            ),
            alignment: BarChartAlignment.spaceAround,
            groupsSpace: 12,
          ),
        ),
      ),
    );
  }
}

class OrderDistributionChart extends StatelessWidget {
  final Map<String, int> statusData;

  const OrderDistributionChart({super.key, required this.statusData});

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'ACCEPTED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalOrders = statusData.values.fold<int>(
      0,
      (prev, count) => prev + count,
    );

    final sections = statusData.entries.map((entry) {
      final percentage = (entry.value / totalOrders) * 100;
      return PieChartSectionData(
        color: _getColorForStatus(entry.key),
        value: entry.value.toDouble(), // Valeur pour la section
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              centerSpaceRadius: 25, // Taille du trou central
            ),
          ),
        ),

        // Légende
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: statusData.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    color: _getColorForStatus(entry.key),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key} (${entry.value})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
