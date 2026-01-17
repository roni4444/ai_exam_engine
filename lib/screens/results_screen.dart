import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/summary_card_widget.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock results data
    final studentScores = [
      {'name': 'Student 1', 'score': 85, 'total': 100},
      {'name': 'Student 2', 'score': 72, 'total': 100},
      {'name': 'Student 3', 'score': 91, 'total': 100},
    ];

    final questionPerformance = [
      {'question': 'Q1', 'avgScore': 90.0},
      {'question': 'Q2', 'avgScore': 75.0},
      {'question': 'Q3', 'avgScore': 83.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Performance Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text('Comprehensive analytics for the entire class', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 32),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: SummaryCard(title: 'Class Average', value: '82.7%', icon: Icons.trending_up, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(title: 'Highest Score', value: '91%', icon: Icons.star, color: const Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(title: 'Pass Rate', value: '100%', icon: Icons.check_circle, color: const Color(0xFF059669)),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Charts Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 255 * 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Scores Distribution',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 100,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() < studentScores.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            studentScores[value.toInt()]['name'] as String,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}', style: const TextStyle(fontSize: 12));
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
                              borderData: FlBorderData(show: false),
                              barGroups: studentScores.asMap().entries.map((entry) {
                                final score = entry.value['score'] as int;
                                final color = score > 80
                                    ? const Color(0xFF059669)
                                    : score > 60
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444);

                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: score.toDouble(),
                                      color: color,
                                      width: 40,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 255 * 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Question Difficulty Analysis',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 24),
                        ...questionPerformance.map((q) {
                          final avgScore = q['avgScore'] as double;
                          final color = avgScore > 80
                              ? const Color(0xFF059669)
                              : avgScore > 60
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      q['question'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                    ),
                                    Text(
                                      '${avgScore.toStringAsFixed(1)}%',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: avgScore / 100,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Student Scorecards
            const Text(
              'Final Scorecards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: studentScores.length,
              itemBuilder: (context, index) {
                final student = studentScores[index];
                final score = student['score'] as int;
                final total = student['total'] as int;
                final percentage = (score / total * 100).round();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 255 * 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF2563EB),
                              child: Text(
                                (student['name'] as String)[0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$score',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            ),
                            Text('/$total', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          student['name'] as String,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        Text('ID: S${index + 1}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: percentage > 80
                                ? const Color(0xFF059669).withValues(alpha: 255 * 0.1)
                                : percentage > 60
                                ? const Color(0xFFF59E0B).withValues(alpha: 255 * 0.1)
                                : const Color(0xFFEF4444).withValues(alpha: 255 * 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            percentage > 80
                                ? 'Excellent'
                                : percentage > 60
                                ? 'Good'
                                : 'Needs Improvement',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: percentage > 80
                                  ? const Color(0xFF059669)
                                  : percentage > 60
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
