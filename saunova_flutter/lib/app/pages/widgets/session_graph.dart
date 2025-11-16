import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:saunova/app/models/session.dart';
import 'package:saunova/app/theme/app_colors.dart';

class ChartDataPoint {
  final double x;
  final double y;

  ChartDataPoint(this.x, this.y);
}

class SessionGraph extends StatelessWidget {
  final Session session;

  const SessionGraph({super.key, required this.session});

  List<ChartDataPoint> _createDataPoints(
    List<dynamic>? xData,
    List<dynamic>? yData,
  ) {
    if (xData == null || yData == null || xData.isEmpty || yData.isEmpty) {
      return [];
    }

    final length = xData.length < yData.length ? xData.length : yData.length;

    return List.generate(length, (i) {
      final x = _toDouble(xData[i]);
      final y = _toDouble(yData[i]);
      return ChartDataPoint(x, y);
    });
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double _getAxisLimit(List<dynamic>? limits, int index, double fallback) {
    if (limits != null && limits.length > index) {
      return _toDouble(limits[index]);
    }
    return fallback;
  }

  double _calculateMin(List<ChartDataPoint> data, double padding) {
    if (data.isEmpty) return 0;
    return data.map((d) => d.y).reduce((a, b) => a < b ? a : b) - padding;
  }

  double _calculateMax(List<ChartDataPoint> data, double padding) {
    if (data.isEmpty) return 100;
    return data.map((d) => d.y).reduce((a, b) => a > b ? a : b) + padding;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final axisData = session.axisData;
    // Extract axis configurations
    final xAxis = axisData['x_axis'] as Map<String, dynamic>?;
    final yAxisLeft = axisData['y_axis_left'] as Map<String, dynamic>?;
    final yAxisRight = axisData['y_axis_right'] as Map<String, dynamic>?;

    if (xAxis == null) {
      return _buildErrorCard(theme, 'Invalid graph configuration');
    }

    // Create data points
    final temperatureData = _createDataPoints(
      xAxis['data'] as List<dynamic>?,
      yAxisLeft?['data'] as List<dynamic>?,
    );

    final humidityData = _createDataPoints(
      xAxis['data'] as List<dynamic>?,
      yAxisRight?['data'] as List<dynamic>?,
    );

    if (temperatureData.isEmpty && humidityData.isEmpty) {
      return _buildErrorCard(theme, 'No data points available');
    }

    // Calculate axis ranges
    final tempLimits = yAxisLeft?['limits'] as List<dynamic>?;
    final tempMin = temperatureData.isNotEmpty
        ? _getAxisLimit(tempLimits, 0, _calculateMin(temperatureData, 5))
        : 0.0;
    final tempMax = temperatureData.isNotEmpty
        ? _getAxisLimit(tempLimits, 1, _calculateMax(temperatureData, 5))
        : 100.0;

    final humidityLimits = yAxisRight?['limits'] as List<dynamic>?;
    final humidityMin = humidityData.isNotEmpty
        ? _getAxisLimit(humidityLimits, 0, _calculateMin(humidityData, 2))
        : 0.0;
    final humidityMax = humidityData.isNotEmpty
        ? _getAxisLimit(humidityLimits, 1, _calculateMax(humidityData, 2))
        : 30.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacityValue(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacityValue(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: _buildChart(
              temperatureData,
              humidityData,
              tempMin,
              tempMax,
              humidityMin,
              humidityMax,
              xAxis['label'] as String? ?? 'Time (s)',
              yAxisLeft?['label'] as String? ?? 'Temperature (°C)',
              yAxisRight?['label'] as String? ?? 'Humidity (%)',
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(
            temperatureData.isNotEmpty,
            humidityData.isNotEmpty,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    List<ChartDataPoint> temperatureData,
    List<ChartDataPoint> humidityData,
    double tempMin,
    double tempMax,
    double humidityMin,
    double humidityMax,
    String xAxisLabel,
    String tempAxisLabel,
    String humidityAxisLabel,
  ) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.all(0),
      primaryXAxis: NumericAxis(
        labelStyle: TextStyle(
          color: Colors.white.withOpacityValue(0.6),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        axisLine: AxisLine(color: Colors.white.withOpacityValue(0.2), width: 1),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: const MajorGridLines(width: 0),
        title: AxisTitle(
          text: xAxisLabel,
          textStyle: TextStyle(
            color: Colors.white.withOpacityValue(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      primaryYAxis: NumericAxis(
        name: 'temperatureAxis',
        minimum: tempMin,
        maximum: tempMax,
        labelStyle: TextStyle(
          color: AppColors.primary.withOpacityValue(0.9),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        axisLine: AxisLine(color: Colors.white.withOpacityValue(0.2), width: 1),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
          color: Colors.white.withOpacityValue(0.1),
          width: 1,
          dashArray: const [5, 5],
        ),
        title: AxisTitle(
          text: tempAxisLabel,
          textStyle: TextStyle(
            color: AppColors.primary.withOpacityValue(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      axes: <ChartAxis>[
        NumericAxis(
          name: 'humidityAxis',
          opposedPosition: true,
          minimum: humidityMin,
          maximum: humidityMax,
          labelStyle: TextStyle(
            color: AppColors.accent.withOpacityValue(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          axisLine: AxisLine(
            color: Colors.white.withOpacityValue(0.2),
            width: 1,
          ),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: const MajorGridLines(width: 0),
          title: AxisTitle(
            text: humidityAxisLabel,
            textStyle: TextStyle(
              color: AppColors.accent.withOpacityValue(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      series: <CartesianSeries>[
        if (temperatureData.isNotEmpty)
          SplineAreaSeries<ChartDataPoint, double>(
            name: 'Temperature',
            dataSource: temperatureData,
            xValueMapper: (ChartDataPoint data, _) => data.x,
            yValueMapper: (ChartDataPoint data, _) => data.y,
            color: AppColors.primary.withOpacityValue(0.3),
            borderColor: AppColors.primary,
            borderWidth: 3,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacityValue(0.4),
                AppColors.primary.withOpacityValue(0.0),
              ],
            ),
            splineType: SplineType.natural,
          ),
        if (humidityData.isNotEmpty)
          SplineAreaSeries<ChartDataPoint, double>(
            name: 'Humidity',
            dataSource: humidityData,
            xValueMapper: (ChartDataPoint data, _) => data.x,
            yValueMapper: (ChartDataPoint data, _) => data.y,
            yAxisName: 'humidityAxis',
            color: AppColors.accent.withOpacityValue(0.2),
            borderColor: AppColors.accent,
            borderWidth: 3,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accent.withOpacityValue(0.3),
                AppColors.accent.withOpacityValue(0.0),
              ],
            ),
            splineType: SplineType.natural,
          ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: const Color(0xFF1A1A1A).withOpacityValue(0.95),
        textStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        borderColor: Colors.white.withOpacityValue(0.3),
        borderWidth: 1,
        animationDuration: 200,
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineColor: Colors.white.withOpacityValue(0.5),
        lineWidth: 1,
        lineDashArray: const [5, 5],
        tooltipSettings: InteractiveTooltip(
          enable: true,
          color: const Color(0xFF1A1A1A).withOpacityValue(0.95),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          borderColor: Colors.white.withOpacityValue(0.3),
          borderWidth: 1,
        ),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enableDoubleTapZooming: true,
        enablePanning: true,
        zoomMode: ZoomMode.x,
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacityValue(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.show_chart, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Session Analytics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(bool hasTemp, bool hasHumidity, ThemeData theme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: [
        if (hasTemp)
          _buildLegendItem(
            color: AppColors.primary,
            label: 'Temperature',
            theme: theme,
          ),
        if (hasHumidity)
          _buildLegendItem(
            color: AppColors.accent,
            label: 'Humidity',
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withOpacityValue(0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacityValue(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacityValue(0.3), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withOpacityValue(0.7),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacityValue(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
