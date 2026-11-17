import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../models/dashboard_stats_model.dart';
import 'guardian_card.dart';

class RiskDonutChart extends StatefulWidget {
  final RiskOverview riskOverview;

  const RiskDonutChart({super.key, required this.riskOverview});

  @override
  State<RiskDonutChart> createState() => _RiskDonutChartState();
}

class _RiskDonutChartState extends State<RiskDonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final risk = widget.riskOverview;
    final total = risk.totalAlerts;

    return GuardianCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Risk Overview', style: AppTypography.headingMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Live Security Posture',
                  style: AppTypography.label.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total == 0) ...[
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.success, size: 48),
                  const SizedBox(height: 8),
                  Text('Zero Active Alerts', style: AppTypography.sectionTitle),
                  Text('All scanned resources are optimal', style: AppTypography.caption),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex =
                                pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 58,
                      sections: _generateSections(risk),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Total Alerts',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Critical', risk.critical, AppColors.riskCritical),
                _buildLegendItem('High', risk.high, AppColors.riskHigh),
                _buildLegendItem('Medium', risk.medium, AppColors.riskMedium),
                _buildLegendItem('Low', risk.low, AppColors.riskLow),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(RiskOverview risk) {
    final sections = <PieChartSectionData>[];
    int sectionIndex = 0;

    void addSection(int value, Color color) {
      if (value > 0) {
        final isTouched = sectionIndex == touchedIndex;
        final radius = isTouched ? 22.0 : 16.0;
        sections.add(
          PieChartSectionData(
            color: color,
            value: value.toDouble(),
            title: '',
            radius: radius,
            badgeWidget: null,
          ),
        );
        sectionIndex++;
      }
    }

    addSection(risk.critical, AppColors.riskCritical);
    addSection(risk.high, AppColors.riskHigh);
    addSection(risk.medium, AppColors.riskMedium);
    addSection(risk.low, AppColors.riskLow);

    return sections;
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
