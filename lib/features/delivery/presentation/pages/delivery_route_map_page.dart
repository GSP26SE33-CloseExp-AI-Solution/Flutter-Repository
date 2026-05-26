import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/constants/mapbox_config.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/polyline6_decoder.dart';
import '../../../../injection_container.dart' show sl;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/delivery_group.dart';
import '../../domain/entities/delivery_order.dart';
import '../../domain/entities/delivery_route_plan.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../domain/services/shipper_location_service.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';

/// Map view with backend-optimized route (Mapbox Matrix + Directions via BE).
class DeliveryRouteMapPage extends StatefulWidget {
  const DeliveryRouteMapPage({super.key, this.groupId});

  /// Delivery group id (UUID string) for route context.
  final String? groupId;

  @override
  State<DeliveryRouteMapPage> createState() => _DeliveryRouteMapPageState();
}

class _DeliveryRouteMapPageState extends State<DeliveryRouteMapPage> {
  final DeliveryRepository _repository = sl<DeliveryRepository>();
  final ShipperLocationService _shipperLocationService =
      sl<ShipperLocationService>();

  static const bool _useMockRoute = bool.fromEnvironment(
    'USE_MOCK_ROUTE',
    defaultValue: false,
  );
  static const int _mockRoutePoints = int.fromEnvironment(
    'MOCK_ROUTE_POINTS',
    defaultValue: 3,
  );
  static const bool _useRealShipperLocation = bool.fromEnvironment(
    'USE_REAL_SHIPPER_LOCATION',
    defaultValue: true,
  );

  MapboxMap? _map;
  PolylineAnnotationManager? _polylineManager;
  CircleAnnotationManager? _circleManager;
  PointAnnotationManager? _pointManager;

  DeliveryGroup? _group;
  DeliveryRoutePlan? _plan;
  String _metric = 'duration';
  bool _loading = false;
  String? _loadError;

  /// Đánh dấu đã pickup để BE bỏ Leg A; FE ẩn chấm siêu thị và panel Chặng A.
  bool _pickedUp = false;

  /// Guard to prevent concurrent annotation application (reduce rebuild churn).
  bool _annotationApplyInProgress = false;
  int _annotationRetryCount = 0;
  bool _pendingAnnotationRefresh = false;
  bool _mapStyleReady = false;
  Timer? _annotationDebounceTimer;

  /// Debug-only: which [_buildMapLayer] branch is active (white area ≠ always MapWidget).
  bool _debugMapFullyLoaded = false;
  String? _debugLastMapLoadError;
  bool _controlsExpanded = false;
  int _fullRenderFrameCount = 0;
  bool _mapRenderStalled = false;
  bool _didTryFallbackStyle = false;
  Timer? _mapHealthTimer;
  ({double latitude, double longitude})? _currentShipperLocation;
  ({double latitude, double longitude})? _lastComputedRouteStartLocation;
  String? _shipperLocationFallbackReason;
  bool _resolvingShipperLocation = false;
  DateTime? _lastManualRefreshAt;

  static const Duration _manualRefreshCooldown = Duration(seconds: 2);
  static const double _recomputeDistanceThresholdMeters = 50;

  static const ({double latitude, double longitude}) _fallbackShipperLocation =
      (latitude: 10.776889, longitude: 106.700806);

  bool get _hasValidGroupId {
    final id = widget.groupId?.trim();
    if (id == null || id.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }

  /// Override via `--dart-define=MAPBOX_ANDROID_HOSTING=...`; mặc định VD giống SDK, TLHC_VD có thể trắng map.
  AndroidPlatformViewHostingMode get _androidHostingMode {
    const raw = String.fromEnvironment(
      'MAPBOX_ANDROID_HOSTING',
      defaultValue: 'VD',
    );
    switch (raw) {
      case 'VD':
        return AndroidPlatformViewHostingMode.VD;
      case 'HC':
        return AndroidPlatformViewHostingMode.HC;
      case 'TLHC_HC':
        return AndroidPlatformViewHostingMode.TLHC_HC;
      case 'TLHC_VD':
        return AndroidPlatformViewHostingMode.TLHC_VD;
      default:
        return AndroidPlatformViewHostingMode.VD;
    }
  }

  /// Bật `--dart-define=MAPBOX_TEXTURE_VIEW=true|false` theo thiết bị; một số GPU trắng map khi true.
  bool get _useTextureView {
    return const bool.fromEnvironment(
      'MAPBOX_TEXTURE_VIEW',
      defaultValue: false,
    );
  }

  /// Raw compile-time value (compare with `MAPBOX_ANDROID_HOSTING` in mapbox.dev.json).
  static const String _kMapboxAndroidHostingDefine = String.fromEnvironment(
    'MAPBOX_ANDROID_HOSTING',
    defaultValue: '',
  );

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final defineHint = _kMapboxAndroidHostingDefine.isEmpty
            ? '(not set, code defaults to VD)'
            : _kMapboxAndroidHostingDefine;
        debugPrint(
          'DeliveryRouteMapPage: groupId=${widget.groupId ?? "(null)"} '
          'validUuid=$_hasValidGroupId configured=${MapboxConfig.isConfigured} '
          'mapWidgetSupported=${MapboxConfig.isMapWidgetSupported} '
          'MAPBOX_ANDROID_HOSTING="$defineHint" resolved=$_androidHostingMode '
          'MAPBOX_TEXTURE_VIEW=$_useTextureView '
          'USE_MOCK_ROUTE=$_useMockRoute MOCK_ROUTE_POINTS=$_mockRoutePoints',
        );
      });
    }
    if (_hasValidGroupId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
  }

  @override
  void didUpdateWidget(covariant DeliveryRouteMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _mapHealthTimer?.cancel();
      _debugMapFullyLoaded = false;
      _debugLastMapLoadError = null;
      _fullRenderFrameCount = 0;
      _mapRenderStalled = false;
      _didTryFallbackStyle = false;
    }
  }

  @override
  void dispose() {
    _mapHealthTimer?.cancel();
    _annotationDebounceTimer?.cancel();
    super.dispose();
  }

  void _startMapHealthCheck() {
    _mapHealthTimer?.cancel();
    _mapHealthTimer = Timer(const Duration(seconds: 4), () async {
      if (!mounted) return;

      // If map loaded but still has no full frame, try a stronger fallback style once.
      if (_debugMapFullyLoaded &&
          _fullRenderFrameCount == 0 &&
          !_didTryFallbackStyle) {
        _didTryFallbackStyle = true;
        _mapRenderStalled = true;
        if (kDebugMode) {
          debugPrint(
            'Map health: no FULL frame after onMapLoaded, switching to satellite streets fallback style.',
          );
        }
        await _map?.loadStyleURI(MapboxStyles.SATELLITE_STREETS);
        return;
      }

      // If still no full frame after fallback attempt, surface a clear warning on UI.
      if (_debugMapFullyLoaded && _fullRenderFrameCount == 0 && mounted) {
        setState(() {
          _mapRenderStalled = true;
          _debugLastMapLoadError ??=
              'Map loaded but no render frame reached FULL state';
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (!_hasValidGroupId) return;
    final gid = widget.groupId!.trim();
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final groupResult = await _repository.getDeliveryGroupById(gid);
    await groupResult.fold(
      (failure) async {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _loadError = failure.message;
        });
      },
      (group) async {
        if (!mounted) return;
        setState(() => _group = group);
        await _fetchRoutePlanOnly();
      },
    );
  }

  Future<void> _fetchRoutePlanOnly({
    ({double latitude, double longitude})? forcedStartLocation,
  }) async {
    if (_useMockRoute) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _plan = _createMockRoutePlan();
        _loadError = null;
      });
      _requestMapAnnotationRefresh();
      return;
    }

    if (!_hasValidGroupId) return;
    final gid = widget.groupId!.trim();
    final shipperStart =
        forcedStartLocation ?? await _resolveShipperStartLocation();
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final planResult = await _repository.computeDeliveryRoutePlan(
      gid,
      metric: _metric,
      startLatitude: shipperStart.latitude,
      startLongitude: shipperStart.longitude,
      skipPickupLeg: _pickedUp,
    );

    if (!mounted) return;

    planResult.fold(
      (failure) {
        setState(() {
          _loading = false;
          _plan = null;
          _loadError = failure.message;
        });
        _requestMapAnnotationRefresh();
      },
      (plan) {
        setState(() {
          _loading = false;
          _plan = plan;
          _loadError = null;
          _lastComputedRouteStartLocation = shipperStart;
        });
        _requestMapAnnotationRefresh();
      },
    );
  }

  Future<void> _onMetricSelected(String metric) async {
    if (_metric == metric || _loading) return;
    setState(() => _metric = metric);
    if (_hasValidGroupId) await _fetchRoutePlanOnly();
  }

  /// Nút \"Đã lấy hàng\" đánh dấu pickup và gọi route-plan với skipPickupLeg=true để bỏ Leg A.
  Future<void> _onPickedUpPressed() async {
    if (_pickedUp || _loading) return;
    setState(() => _pickedUp = true);
    if (_hasValidGroupId) {
      await _fetchRoutePlanOnly();
    } else {
      _requestMapAnnotationRefresh();
    }
  }

  void _handleBackNavigation(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }

    // Prefer returning to the current group's detail page when the stack was replaced.
    if (_hasValidGroupId) {
      context.go(Routes.deliveryGroupDetails(widget.groupId!.trim()));
      return;
    }

    context.go(Routes.deliveryAvailable);
  }

  /// Apply annotations with guard to prevent concurrent calls during map lifecycle churn.
  Future<void> _applyMapAnnotationsIfNecessary() async {
    if (_annotationApplyInProgress) return;
    _annotationApplyInProgress = true;
    try {
      await _applyMapAnnotations();
      _annotationRetryCount = 0;
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('Route render failed: $e');
      }

      if (_annotationRetryCount < 3) {
        _annotationRetryCount++;
        Future<void>.delayed(const Duration(milliseconds: 450), () {
          if (mounted) {
            _applyMapAnnotationsIfNecessary();
          }
        });
      } else {
        setState(() {
          _loadError =
              'Không thể hiển thị lộ trình trên bản đồ. Vui lòng thử lại.';
        });
      }
    } finally {
      _annotationApplyInProgress = false;
    }
  }

  void _requestMapAnnotationRefresh({
    Duration delay = const Duration(milliseconds: 180),
  }) {
    _pendingAnnotationRefresh = true;
    _annotationDebounceTimer?.cancel();
    _annotationDebounceTimer = Timer(delay, () {
      if (!mounted) return;
      if (!_debugMapFullyLoaded || !_mapStyleReady) {
        if (kDebugMode) {
          debugPrint(
            'Route render queued: mapLoaded=$_debugMapFullyLoaded styleReady=$_mapStyleReady pending=$_pendingAnnotationRefresh',
          );
        }
        if (_pendingAnnotationRefresh) {
          _requestMapAnnotationRefresh(
            delay: const Duration(milliseconds: 220),
          );
        }
        return;
      }
      if (!_pendingAnnotationRefresh) return;
      _pendingAnnotationRefresh = false;
      _applyMapAnnotationsIfNecessary();
    });
  }

  Future<void> _applyMapAnnotations() async {
    final map = _map;
    if (map == null || !MapboxConfig.isConfigured) return;

    _polylineManager ??= await map.annotations
        .createPolylineAnnotationManager();
    _circleManager ??= await map.annotations.createCircleAnnotationManager();
    _pointManager ??= await map.annotations.createPointAnnotationManager();

    await _polylineManager!.deleteAll();
    await _circleManager!.deleteAll();
    await _pointManager!.deleteAll();

    final shipperLocation =
        _currentShipperLocation ?? _resolveFallbackShipperLocation();

    final plan = _plan;
    if (plan == null || plan.preferredDeliveryPolyline.isEmpty) {
      await _fitToOrdersIfPossible();
      return;
    }

    final decoded = _decodeRoutePoints(plan);
    final sanitizedRoutePoints = _sanitizeRoutePoints(decoded);
    if (sanitizedRoutePoints.length < 2) {
      if (kDebugMode) {
        debugPrint(
          'Route render skipped: decoded=${decoded.length}, sanitized=${sanitizedRoutePoints.length}, encoding=${plan.preferredDeliveryPolylineEncoding}',
        );
      }
      await _fitToOrdersIfPossible();
      return;
    }

    final routePoints = _downsampleRoutePoints(sanitizedRoutePoints);

    final stopPointsForRoute = <({double latitude, double longitude})>[];

    await _createCircleMarker(
      point: shipperLocation,
      fillColor: AppColors.mapShipperMarker,
      radius: 7,
      strokeColor: AppColors.onPrimary,
      strokeWidth: 2,
    );

    if (_useMockRoute) {
      for (final p in routePoints) {
        stopPointsForRoute.add(p);
      }

      final adjustedStopPoints = _spreadOverlappingStopPoints(
        stopPointsForRoute,
      );
      for (var i = 0; i < adjustedStopPoints.length; i++) {
        await _createStopMarker(
          point: adjustedStopPoints[i],
          sequenceNumber: i + 1,
        );
      }
    } else {
      final group = _group;
      if (group != null && plan.orderedOrderIds.isNotEmpty) {
        var createdStopMarkers = 0;
        var fallbackStopMarkers = 0;
        final stopSequenceNumbers = <int>[];
        final fallbackPositions = _buildFallbackStopPositions(
          routePoints,
          plan.orderedOrderIds.length,
        );

        for (var i = 0; i < plan.orderedOrderIds.length; i++) {
          final orderId = plan.orderedOrderIds[i];
          final orderPoint = _resolveOrderPoint(orderId, group.orders);
          final fallbackPoint = i < fallbackPositions.length
              ? fallbackPositions[i]
              : null;
          final point = orderPoint ?? fallbackPoint;
          if (point == null) {
            continue;
          }

          if (orderPoint == null) {
            fallbackStopMarkers++;
          }

          stopPointsForRoute.add(point);
          stopSequenceNumbers.add(i + 1);
          createdStopMarkers++;
        }

        final adjustedStopPoints = _spreadOverlappingStopPoints(
          stopPointsForRoute,
        );
        for (var i = 0; i < adjustedStopPoints.length; i++) {
          await _createStopMarker(
            point: adjustedStopPoints[i],
            sequenceNumber: stopSequenceNumbers[i],
          );
        }

        if (kDebugMode) {
          debugPrint(
            'Route stop markers: created=$createdStopMarkers fallback=$fallbackStopMarkers total=${plan.orderedOrderIds.length}',
          );
        }

        if (createdStopMarkers == 0 && mounted) {
          setState(() {
            _loadError =
                'Không thể hiển thị điểm dừng trên bản đồ. Dữ liệu tọa độ điểm giao không hợp lệ.';
          });
        }
      }
    }

    final pickupLegPoints = await _renderPickupLegIfAvailable(plan);

    // Pickup leg phủ shipper → siêu thị thì không prepend shipperLocation vào chặng B.
    // Khi shipper đã bấm "Đã lấy hàng" cũng không nối thẳng tới siêu thị nữa.
    final routePointsForDisplay = _buildDisplayRoutePoints(
      shipperLocation: shipperLocation,
      routePoints: routePoints,
      stopPoints: stopPointsForRoute,
      prependShipperLocation: pickupLegPoints.isEmpty && !_pickedUp,
    );

    await _polylineManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString.fromPoints(
          points: routePointsForDisplay
              .map((p) => Point(coordinates: Position(p.longitude, p.latitude)))
              .toList(),
        ),
        lineColor: AppColors.mapDeliveryLegLine.toARGB32(),
        lineWidth: 4,
        lineOpacity: 0.9,
      ),
    );

    if (kDebugMode) {
      debugPrint(
        'Route rendered: routePoints=${routePoints.length}, displayRoutePoints=${routePointsForDisplay.length}, orderIds=${plan.orderedOrderIds.length}, skipped=${plan.skippedOrderIds.length}, encoding=${plan.preferredDeliveryPolylineEncoding}, pickupLegPoints=${pickupLegPoints.length}',
      );
    }

    await _fitCameraToPoints([
      ...routePointsForDisplay,
      ...pickupLegPoints,
      shipperLocation,
    ]);
  }

  /// Vẽ Leg A (shipper → siêu thị) theo [DeliveryRoutePlan.pickupLeg] và trả về điểm đã decode.
  Future<List<({double latitude, double longitude})>>
  _renderPickupLegIfAvailable(DeliveryRoutePlan plan) async {
    final leg = plan.pickupLeg;
    if (leg == null || leg.encodedPolyline.isEmpty) {
      return const [];
    }

    final decoded = Polyline6Decoder.decodeByEncoding(
      leg.encodedPolyline,
      leg.polylineEncoding,
    );
    final sanitized = _sanitizeRoutePoints(decoded);
    if (sanitized.length < 2) {
      if (kDebugMode) {
        debugPrint(
          'Pickup leg skipped: decoded=${decoded.length} sanitized=${sanitized.length} encoding=${leg.polylineEncoding}',
        );
      }
      return const [];
    }

    final points = _downsampleRoutePoints(sanitized);
    final manager = _polylineManager;
    if (manager == null) return points;

    await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString.fromPoints(
          points: points
              .map((p) => Point(coordinates: Position(p.longitude, p.latitude)))
              .toList(),
        ),
        lineColor: AppColors.mapPickupLegLine.toARGB32(),
        lineWidth: 4,
        lineOpacity: 0.85,
      ),
    );

    final pickupPoint = leg.to;
    if (pickupPoint != null) {
      await _createCircleMarker(
        point: (
          latitude: pickupPoint.latitude,
          longitude: pickupPoint.longitude,
        ),
        fillColor: AppColors.mapPickupMarker,
        radius: 8,
        strokeColor: AppColors.onPrimary,
        strokeWidth: 2,
      );
    }

    return points;
  }

  Future<void> _createCircleMarker({
    required ({double latitude, double longitude}) point,
    required Color fillColor,
    required double radius,
    required Color strokeColor,
    required double strokeWidth,
  }) async {
    final circleManager = _circleManager;
    if (circleManager == null) return;

    await circleManager.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(point.longitude, point.latitude)),
        circleColor: fillColor.toARGB32(),
        circleRadius: radius,
        circleStrokeColor: strokeColor.toARGB32(),
        circleStrokeWidth: strokeWidth,
      ),
    );
  }

  Future<void> _createStopMarker({
    required ({double latitude, double longitude}) point,
    required int sequenceNumber,
  }) async {
    await _createCircleMarker(
      point: point,
      fillColor: AppColors.mapStopMarker,
      radius: 9,
      strokeColor: AppColors.onPrimary,
      strokeWidth: 2,
    );

    final pointManager = _pointManager;
    if (pointManager == null) return;

    await pointManager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(point.longitude, point.latitude)),
        textField: '$sequenceNumber',
        textSize: 14,
        textColor: AppColors.mapStopText.toARGB32(),
        textHaloColor: AppColors.mapStopTextHalo.toARGB32(),
        textHaloWidth: 1.5,
      ),
    );
  }

  List<({double latitude, double longitude})> _spreadOverlappingStopPoints(
    List<({double latitude, double longitude})> points,
  ) {
    if (points.length <= 1) return points;

    final adjusted = List<({double latitude, double longitude})>.from(points);
    final groupedIndexes = <String, List<int>>{};
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final key =
          '${p.latitude.toStringAsFixed(6)}:${p.longitude.toStringAsFixed(6)}';
      groupedIndexes.putIfAbsent(key, () => <int>[]).add(i);
    }

    for (final indexes in groupedIndexes.values) {
      if (indexes.length <= 1) continue;

      for (var i = 0; i < indexes.length; i++) {
        final index = indexes[i];
        final base = points[index];

        // Spread markers in a small ring (~8m) so stacked stops remain visible.
        final angle = (2 * math.pi * i) / indexes.length;
        const radiusMeters = 8.0;
        final latOffset = (radiusMeters * math.sin(angle)) / 111320.0;
        final lngOffset =
            (radiusMeters * math.cos(angle)) /
            (111320.0 * math.cos(base.latitude * math.pi / 180.0));

        adjusted[index] = (
          latitude: base.latitude + latOffset,
          longitude: base.longitude + lngOffset,
        );
      }
    }

    return adjusted;
  }

  List<({double latitude, double longitude})> _buildDisplayRoutePoints({
    required ({double latitude, double longitude}) shipperLocation,
    required List<({double latitude, double longitude})> routePoints,
    required List<({double latitude, double longitude})> stopPoints,
    bool prependShipperLocation = true,
  }) {
    final hasMultipleDistinctStops = _countDistinctPoints(stopPoints) >= 2;
    final basePoints =
        hasMultipleDistinctStops && routePoints.length < stopPoints.length
        ? stopPoints
        : routePoints;

    final result = <({double latitude, double longitude})>[];
    if (prependShipperLocation) {
      result.add(shipperLocation);
    }

    for (final p in basePoints) {
      if (result.isEmpty || !_arePointsNear(result.last, p)) {
        result.add(p);
      }
    }

    if (result.length < 2 && basePoints.isNotEmpty) {
      result.add(basePoints.first);
    }

    return result;
  }

  int _countDistinctPoints(List<({double latitude, double longitude})> points) {
    final keys = <String>{};
    for (final p in points) {
      keys.add(
        '${p.latitude.toStringAsFixed(6)}:${p.longitude.toStringAsFixed(6)}',
      );
    }
    return keys.length;
  }

  bool _arePointsNear(
    ({double latitude, double longitude}) a,
    ({double latitude, double longitude}) b,
  ) {
    return (a.latitude - b.latitude).abs() < 0.00001 &&
        (a.longitude - b.longitude).abs() < 0.00001;
  }

  ({double latitude, double longitude})? _resolveOrderPoint(
    String orderId,
    List<DeliveryOrder> orders,
  ) {
    for (final order in orders) {
      if (order.orderId != orderId) continue;
      final lat = order.latitude;
      final lng = order.longitude;
      if (lat == null || lng == null) {
        return null;
      }
      return (latitude: lat, longitude: lng);
    }

    return null;
  }

  List<({double latitude, double longitude})?> _buildFallbackStopPositions(
    List<({double latitude, double longitude})> routePoints,
    int stopCount,
  ) {
    if (stopCount <= 0) return const [];
    if (routePoints.isEmpty) {
      return List<({double latitude, double longitude})?>.filled(
        stopCount,
        null,
      );
    }

    if (routePoints.length == 1) {
      return List<({double latitude, double longitude})?>.filled(
        stopCount,
        routePoints.first,
      );
    }

    if (stopCount == 1) {
      return [routePoints.first];
    }

    final result = <({double latitude, double longitude})?>[];
    final lastIndex = routePoints.length - 1;
    final denominator = stopCount - 1;
    for (var i = 0; i < stopCount; i++) {
      final idx = ((i * lastIndex) / denominator).round();
      result.add(routePoints[idx]);
    }

    return result;
  }

  List<({double latitude, double longitude})> _decodeRoutePoints(
    DeliveryRoutePlan plan,
  ) {
    final encoded = plan.preferredDeliveryPolyline;
    final encoding = plan.preferredDeliveryPolylineEncoding;
    final primary = Polyline6Decoder.decodeByEncoding(encoded, encoding);
    if (!_shouldTryAlternativeDecode(primary)) {
      return primary;
    }

    final alt = encoding.toLowerCase().contains('6')
        ? Polyline6Decoder.decodeWithPrecision(encoded, 5)
        : Polyline6Decoder.decodeWithPrecision(encoded, 6);

    if (kDebugMode) {
      debugPrint(
        'Route decode fallback applied: primary=${primary.length} alt=${alt.length} encoding=$encoding',
      );
    }

    return alt;
  }

  bool _shouldTryAlternativeDecode(
    List<({double latitude, double longitude})> decoded,
  ) {
    if (decoded.length < 2) return true;

    final group = _group;
    final centerLat = group?.centerLatitude;
    final centerLng = group?.centerLongitude;
    if (centerLat == null || centerLng == null) return false;

    final first = decoded.first;
    final latDelta = (first.latitude - centerLat).abs();
    final lngDelta = (first.longitude - centerLng).abs();

    // Nếu route bắt đầu quá xa tâm nhóm giao, khả năng sai precision tọa độ.
    return latDelta > 1.5 || lngDelta > 1.5;
  }

  List<({double latitude, double longitude})> _sanitizeRoutePoints(
    List<({double latitude, double longitude})> points,
  ) {
    return points.where((p) {
      final validLat = p.latitude >= -90 && p.latitude <= 90;
      final validLng = p.longitude >= -180 && p.longitude <= 180;
      return validLat && validLng;
    }).toList();
  }

  List<({double latitude, double longitude})> _downsampleRoutePoints(
    List<({double latitude, double longitude})> points,
  ) {
    const maxPoints = 1200;
    if (points.length <= maxPoints) return points;

    final step = (points.length / maxPoints).ceil();
    final sampled = <({double latitude, double longitude})>[];
    for (var i = 0; i < points.length; i += step) {
      sampled.add(points[i]);
    }

    final last = points.last;
    if (sampled.isEmpty || sampled.last != last) {
      sampled.add(last);
    }

    if (kDebugMode) {
      debugPrint(
        'Route downsampled from ${points.length} to ${sampled.length} points for render stability.',
      );
    }
    return sampled;
  }

  Future<void> _fitToOrdersIfPossible() async {
    if (_useMockRoute) {
      await _fitCameraToPoints([
        ..._mockPointsForRoute(),
        _currentShipperLocation ?? _resolveFallbackShipperLocation(),
      ]);
      return;
    }

    final group = _group;
    final map = _map;
    if (map == null || group == null) return;
    final pts = group.orders
        .where((o) => o.latitude != null && o.longitude != null)
        .map((o) => (latitude: o.latitude!, longitude: o.longitude!))
        .toList();
    await _fitCameraToPoints([
      ...pts,
      _currentShipperLocation ?? _resolveFallbackShipperLocation(),
    ]);
  }

  Future<({double latitude, double longitude})>
  _resolveShipperStartLocation() async {
    if (_useMockRoute || !_useRealShipperLocation) {
      final fallback = _resolveFallbackShipperLocation();
      if (!mounted) return fallback;
      setState(() {
        _currentShipperLocation = fallback;
        _shipperLocationFallbackReason = _useMockRoute
            ? 'Đang dùng mock location cho chế độ test route.'
            : 'Đang dùng fallback location theo cấu hình build.';
      });
      return fallback;
    }

    final result = await _resolveShipperLocationResult();
    if (result.hasLocation) {
      return result.location!;
    }

    return _setFallbackShipperLocation(_fallbackReasonByStatus(result.status));
  }

  Future<ShipperLocationResult> _resolveShipperLocationResult() async {
    if (mounted) {
      setState(() {
        _resolvingShipperLocation = true;
      });
    }

    try {
      final result = await _shipperLocationService.resolveCurrentLocation();
      if (result.hasLocation) {
        final real = result.location!;
        if (mounted) {
          setState(() {
            _currentShipperLocation = real;
            _shipperLocationFallbackReason = null;
          });
        }
        return result;
      }

      if (mounted) {
        setState(() {
          _shipperLocationFallbackReason = _fallbackReasonByStatus(
            result.status,
          );
        });
      }
      return result;
    } catch (_) {
      const fallbackResult = ShipperLocationResult(
        status: ShipperLocationStatus.failed,
      );
      if (mounted) {
        setState(() {
          _shipperLocationFallbackReason = _fallbackReasonByStatus(
            fallbackResult.status,
          );
        });
      }
      return fallbackResult;
    } finally {
      if (mounted) {
        setState(() {
          _resolvingShipperLocation = false;
        });
      }
    }
  }

  String _fallbackReasonByStatus(ShipperLocationStatus status) {
    switch (status) {
      case ShipperLocationStatus.serviceDisabled:
        return 'GPS đang tắt, đã chuyển sang vị trí dự phòng.';
      case ShipperLocationStatus.denied:
        return 'Chưa có quyền vị trí, đã chuyển sang vị trí dự phòng.';
      case ShipperLocationStatus.deniedForever:
        return 'Quyền vị trí đã bị từ chối vĩnh viễn, đang dùng vị trí dự phòng.';
      case ShipperLocationStatus.failed:
        return 'Không lấy được GPS hiện tại, đã chuyển sang vị trí dự phòng.';
      case ShipperLocationStatus.success:
        return 'Đang dùng vị trí hiện tại của shipper.';
    }
  }

  double _distanceMeters(
    ({double latitude, double longitude}) a,
    ({double latitude, double longitude}) b,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return 2 * earthRadiusMeters * math.asin(math.sqrt(h));
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;

  Future<void> _showLocationPermissionForeverDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Quyền vị trí bị từ chối vĩnh viễn'),
          content: const Text(
            'Ứng dụng không thể hiện lại popup cấp quyền vị trí trên thiết bị này. Bạn cần tự bật lại quyền vị trí trong phần cài đặt hệ thống khi thuận tiện.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _refreshShipperLocation() async {
    if (_loading || _resolvingShipperLocation || !_hasValidGroupId) {
      return;
    }

    final now = DateTime.now();
    final lastRefresh = _lastManualRefreshAt;
    if (lastRefresh != null) {
      final elapsed = now.difference(lastRefresh);
      if (elapsed < _manualRefreshCooldown) {
        final secondsLeft = (_manualRefreshCooldown - elapsed).inSeconds.clamp(
          1,
          999,
        );
        _showInfoSnackBar(
          'Vui lòng thử lại sau $secondsLeft giây để tránh làm mới quá nhanh.',
        );
        return;
      }
    }

    _lastManualRefreshAt = now;

    final resolvedResult = await _resolveShipperLocationResult();
    if (!resolvedResult.hasLocation) {
      final reason = _fallbackReasonByStatus(resolvedResult.status);
      _setFallbackShipperLocation(reason);

      if (resolvedResult.status == ShipperLocationStatus.deniedForever) {
        await _showLocationPermissionForeverDialog();
      } else {
        _showInfoSnackBar(reason);
      }
      _requestMapAnnotationRefresh();
      return;
    }

    final currentStart = resolvedResult.location!;
    final previousStart = _lastComputedRouteStartLocation;
    if (previousStart != null) {
      final movedMeters = _distanceMeters(previousStart, currentStart);
      if (movedMeters < _recomputeDistanceThresholdMeters) {
        _showInfoSnackBar(
          'Shipper chỉ di chuyển ${movedMeters.toStringAsFixed(0)}m, chưa cần tính lại lộ trình.',
        );
        _requestMapAnnotationRefresh();
        return;
      }
    }

    await _fetchRoutePlanOnly(forcedStartLocation: currentStart);
  }

  ({double latitude, double longitude}) _setFallbackShipperLocation(
    String reason,
  ) {
    final fallback = _resolveFallbackShipperLocation();
    if (!mounted) return fallback;
    setState(() {
      _currentShipperLocation = fallback;
      _shipperLocationFallbackReason = reason;
    });
    return fallback;
  }

  ({double latitude, double longitude}) _resolveFallbackShipperLocation() {
    final group = _group;
    final groupLat = group?.centerLatitude;
    final groupLng = group?.centerLongitude;
    if (groupLat != null && groupLng != null) {
      return (latitude: groupLat + 0.0012, longitude: groupLng - 0.0010);
    }

    final points = _useMockRoute
        ? _mockPointsForRoute()
        : <({double latitude, double longitude})>[];
    if (points.isNotEmpty) {
      final first = points.first;
      return (
        latitude: first.latitude + 0.0010,
        longitude: first.longitude - 0.0010,
      );
    }

    return _fallbackShipperLocation;
  }

  DeliveryRoutePlan _createMockRoutePlan() {
    final points = _mockPointsForRoute();
    final orderedIds = <String>[];
    for (var i = 0; i < points.length; i++) {
      orderedIds.add('mock-order-${i + 1}');
    }

    return DeliveryRoutePlan(
      orderedOrderIds: orderedIds,
      totalDistanceKm: points.length == 2 ? 3.6 : 6.2,
      totalDurationMinutes: points.length == 2 ? 12 : 22,
      encodedPolyline: _encodePolyline6(points),
      polylineEncoding: 'polyline6',
      metric: _metric,
      skippedOrderIds: const [],
    );
  }

  List<({double latitude, double longitude})> _mockPointsForRoute() {
    if (_mockRoutePoints <= 2) {
      return const [
        (latitude: 10.776889, longitude: 106.700806),
        (latitude: 10.769425, longitude: 106.690102),
      ];
    }

    return const [
      (latitude: 10.776889, longitude: 106.700806),
      (latitude: 10.769425, longitude: 106.690102),
      (latitude: 10.762128, longitude: 106.682640),
    ];
  }

  String _encodePolyline6(List<({double latitude, double longitude})> points) {
    final sb = StringBuffer();
    var lastLat = 0;
    var lastLng = 0;

    for (final p in points) {
      final lat = (p.latitude * 1e6).round();
      final lng = (p.longitude * 1e6).round();
      _encodeSigned(lat - lastLat, sb);
      _encodeSigned(lng - lastLng, sb);
      lastLat = lat;
      lastLng = lng;
    }

    return sb.toString();
  }

  void _encodeSigned(int value, StringBuffer sb) {
    var v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      sb.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    sb.writeCharCode(v + 63);
  }

  Future<void> _fitCameraToPoints(
    List<({double latitude, double longitude})> pts,
  ) async {
    final map = _map;
    if (map == null || pts.isEmpty) return;
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    final cLat = (minLat + maxLat) / 2;
    final cLng = (minLng + maxLng) / 2;
    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    final span = latSpan > lngSpan ? latSpan : lngSpan;
    double zoom = 13;
    if (span > 0.5) zoom = 10;
    if (span > 0.15) zoom = 11;
    if (span > 0.05) zoom = 12;
    if (span < 0.01) zoom = 14;

    try {
      await map.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(cLng, cLat)),
          zoom: zoom,
        ),
        MapAnimationOptions(duration: 600),
      );
    } catch (_) {
      // Map may not be ready yet; ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final actionableRouteOrderIds = _resolveActionableRouteOrderIds();
    final routeOrderIdsForDisplay =
        (plan != null && plan.orderedOrderIds.isNotEmpty)
        ? plan.orderedOrderIds
        : actionableRouteOrderIds;
    final hasRoutePlanData = routeOrderIdsForDisplay.isNotEmpty;
    final hasActionableStops = actionableRouteOrderIds.isNotEmpty;
    final isGroupFinalized = _isGroupFinalized();
    final distanceSubtitle = plan != null && plan.metric == 'distance'
        ? plan.summaryLabel
        : (plan != null
              ? '${plan.totalDistanceKm.toStringAsFixed(1)} km (ước lượng)'
              : '— km • — phút');
    final durationSubtitle = plan != null && plan.metric == 'duration'
        ? plan.summaryLabel
        : (plan != null
              ? '${plan.totalDurationMinutes.toStringAsFixed(0)} phút (ước lượng)'
              : '— km • — phút');

    return BlocListener<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DeliverySessionExpired) {
          context.read<AuthBloc>().add(const LogoutEvent());
          return;
        }
        if (state is GroupDetailsLoaded) {
          // Group was refreshed (after order confirm/fail), trigger rebuild
          // to update button and map display
          setState(() {
            _group = state.group;
          });
        } else if (state is DeliveryGroupCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nhóm giao hàng đã hoàn thành'),
              backgroundColor: AppColors.successGradientEnd,
            ),
          );
          // Navigate back to available groups or delivery history
          context.go(Routes.home);
        } else if (state is DeliveryActionError &&
            state.message.contains('hoàn thành')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.headerGradientStart,
                  AppColors.headerGradientEnd,
                ],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackNavigation(context),
          ),
          title: Text(
            'Lộ trình giao hàng',
            style: AppTypography.header1.copyWith(
              fontSize: 20,
              color: AppColors.onPrimary,
              letterSpacing: -0.60,
            ),
          ),
          actions: [
            if (_hasValidGroupId)
              TextButton.icon(
                onPressed: () {
                  final groupRoute = Routes.deliveryGroupDetails(
                    widget.groupId!.trim(),
                  );
                  final router = GoRouter.of(context);

                  // Keep back stack: if map was opened from details, pop back.
                  if (router.canPop()) {
                    context.pop();
                    return;
                  }

                  // Fallback for direct-entry map (deep link/debug launch).
                  context.push(groupRoute);
                },
                icon: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.onPrimary,
                ),
                label: Text(
                  'Nhóm giao',
                  style: AppTypography.bodyRegular1.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _buildMapLayer()),
            if (kDebugMode && _mapRenderStalled)
              Positioned(
                left: 16,
                right: 16,
                top: 16,
                child: Material(
                  color: AppColors.mapWarningBackground,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      'Ban do dang gap su co hien thi tren thiet bi nay. Thu chuyen che do hosting/texture trong launch config.',
                      style: AppTypography.bodyRegular1.copyWith(
                        color: AppColors.neutralDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            if (_loading)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        bottomSheet: SafeArea(
          top: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: _controlsExpanded ? 330 : 125,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: ClipRect(
              child: SingleChildScrollView(
                physics: _controlsExpanded
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Chọn lộ trình',
                            style: AppTypography.header3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Làm mới vị trí shipper',
                          onPressed:
                              (!_hasValidGroupId ||
                                  _loading ||
                                  _resolvingShipperLocation)
                              ? null
                              : _refreshShipperLocation,
                          icon: _resolvingShipperLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(
                              () => _controlsExpanded = !_controlsExpanded,
                            );
                          },
                          icon: Icon(
                            _controlsExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _metric == 'distance'
                          ? distanceSubtitle
                          : durationSubtitle,
                      style: AppTypography.bodyRegular1.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_resolvingShipperLocation) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đang lấy vị trí hiện tại của shipper...',
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        _shipperLocationFallbackReason == null
                            ? 'Điểm xuất phát: GPS hiện tại của shipper'
                            : 'Điểm xuất phát: vị trí dự phòng',
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 11,
                          color: _shipperLocationFallbackReason == null
                              ? AppColors.textSecondary
                              : AppColors.mapWarningText,
                        ),
                      ),
                      if (_shipperLocationFallbackReason != null)
                        Text(
                          _shipperLocationFallbackReason!,
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 11,
                            color: AppColors.mapWarningText,
                          ),
                        ),
                    ],
                    if (hasRoutePlanData) ...[
                      const SizedBox(height: 6),
                      Text(
                        hasActionableStops
                            ? 'Điểm tiếp theo: ${_resolveOrderAddressLabel(actionableRouteOrderIds.first)}'
                            : 'Lộ trình đã tối ưu xong (không còn item cần giao)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_controlsExpanded) ...[
                      if (widget.groupId != null &&
                          widget.groupId!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Nhóm: ${widget.groupId!.trim()}',
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (_loadError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _loadError!,
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      if (_plan != null &&
                          _plan!.skippedOrderIds.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Bỏ qua ${_plan!.skippedOrderIds.length} đơn thiếu tọa độ',
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (_plan != null &&
                          _plan!.orderedOrderIds.isNotEmpty &&
                          _countUnresolvedRouteStops() > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Không map được ${_countUnresolvedRouteStops()} điểm sang dữ liệu địa chỉ của nhóm.',
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 11,
                            color: AppColors.mapWarningTextStrong,
                          ),
                        ),
                      ],
                      if (plan != null &&
                          (plan.pickupLeg != null ||
                              plan.deliveryLeg != null)) ...[
                        const SizedBox(height: 12),
                        _RouteLegsSummary(
                          pickupLeg: plan.pickupLeg,
                          deliveryLeg: plan.deliveryLeg,
                          pickedUp: _pickedUp,
                          onPickedUp: _loading ? null : _onPickedUpPressed,
                        ),
                      ],
                      if (hasRoutePlanData) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Thứ tự điểm trên lộ trình',
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (
                              var index = 0;
                              index < routeOrderIdsForDisplay.length;
                              index++
                            )
                              _RouteStopChip(
                                index: index + 1,
                                label: _resolveOrderAddressLabel(
                                  routeOrderIdsForDisplay[index],
                                ),
                                pendingItems: _countPendingGroupItemsForOrder(
                                  routeOrderIdsForDisplay[index],
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _RouteOption(
                              title: 'Tối ưu',
                              subtitle: _metric == 'distance'
                                  ? distanceSubtitle
                                  : 'Chạm để tối thiểu km',
                              isActive: _metric == 'distance',
                              onTap:
                                  MapboxConfig.isConfigured && _hasValidGroupId
                                  ? () => _onMetricSelected('distance')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RouteOption(
                              title: 'Nhanh nhất',
                              subtitle: _metric == 'duration'
                                  ? durationSubtitle
                                  : 'Chạm để tối thiểu phút',
                              isActive: _metric == 'duration',
                              onTap:
                                  MapboxConfig.isConfigured && _hasValidGroupId
                                  ? () => _onMetricSelected('duration')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isGroupFinalized)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            'Nhóm giao đã ở trạng thái kết thúc, không còn thao tác khả dụng.',
                            style: AppTypography.bodyRegular1.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isGroupComplete()
                                    ? [
                                        AppColors.successGradientStart,
                                        AppColors.successGradientEnd,
                                      ]
                                    : [
                                        AppColors.headerGradientStart,
                                        AppColors.headerGradientEnd,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: BlocBuilder<DeliveryBloc, DeliveryState>(
                              builder: (context, state) {
                                final isLoadingComplete =
                                    state is DeliveryLoading &&
                                    (state.message?.contains(
                                          'hoàn thành nhóm',
                                        ) ??
                                        false);
                                return TextButton.icon(
                                  onPressed: (_loading || isLoadingComplete)
                                      ? null
                                      : () {
                                          if (_isGroupComplete()) {
                                            _onCompleteGroupPressed(context);
                                          } else {
                                            _onStartDeliveryPressed(context);
                                          }
                                        },
                                  icon: Icon(
                                    _isGroupComplete()
                                        ? Icons.check_circle
                                        : Icons.play_arrow,
                                    color: AppColors.onPrimary,
                                  ),
                                  label: Text(
                                    _isGroupComplete()
                                        ? 'Hoàn thành nhóm giao'
                                        : 'Bắt đầu giao hàng',
                                    style: AppTypography.subHeader.copyWith(
                                      color: AppColors.onPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shared layout for token / unsupported-platform messages (distinct from blank MapWidget).
  Widget _buildMapMessagePlaceholder({
    required String title,
    required String description,
  }) {
    return Container(
      color: AppColors.dividerStrong,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.subHeader.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTypography.bodyRegular1.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLayer() {
    if (!MapboxConfig.isConfigured) {
      return _buildMapMessagePlaceholder(
        title: 'Mapbox chưa được cấu hình',
        description:
            'Thêm token bằng --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxx rồi chạy lại app.',
      );
    }
    if (!MapboxConfig.isMapWidgetSupported) {
      return _buildMapMessagePlaceholder(
        title: 'Bản đồ không khả dụng trên nền tảng này',
        description:
            'mapbox_maps_flutter chỉ hỗ trợ Android và iOS. Chạy app trên thiết bị hoặc emulator Android/iOS để xem bản đồ.',
      );
    }

    return MapWidget(
      key: ValueKey('delivery-map-${widget.groupId ?? 'none'}'),
      textureView: _useTextureView,
      styleUri: MapboxStyles.MAPBOX_STREETS,
      androidHostingMode: _androidHostingMode,
      onMapLoadErrorListener: (event) {
        if (kDebugMode) {
          debugPrint(
            'Mapbox load error: type=${event.type} message=${event.message} '
            '(verify MAPBOX_ACCESS_TOKEN, URL restrictions on mapbox.com, device network)',
          );
        }
        if (mounted) {
          setState(
            () => _debugLastMapLoadError = '${event.type}: ${event.message}',
          );
        }
      },
      onMapCreated: (map) {
        _map = map;
        if (mounted) {
          setState(() => _debugLastMapLoadError = null);
        }
      },
      onStyleLoadedListener: (_) {
        if (mounted) {
          setState(() => _mapStyleReady = true);
        }
        _requestMapAnnotationRefresh();
      },
      onRenderFrameFinishedListener: (eventData) {
        if (eventData.renderMode == RenderMode.FULL) {
          if (_fullRenderFrameCount == 0 && mounted) {
            setState(() {
              _mapRenderStalled = false;
              _debugLastMapLoadError = null;
            });
          }
          _fullRenderFrameCount++;
        }
      },
      onResourceRequestListener: (resourceEventData) {
        if (!kDebugMode) return;
        final response = resourceEventData.response;
        final error = response?.error;
        final isStyleOrTile =
            resourceEventData.request.kind == RequestType.STYLE ||
            resourceEventData.request.kind == RequestType.TILE;
        final isOfflineMiss =
            error?.reason == ResponseErrorReason.NOT_FOUND &&
            (error?.message.toLowerCase().contains('offline database') ??
                false);

        if (error != null && isStyleOrTile && !isOfflineMiss) {
          debugPrint(
            'Map resource error: kind=${resourceEventData.request.kind} '
            'source=${resourceEventData.dataSource} '
            'url=${resourceEventData.request.url} '
            'reason=${error.reason} message=${error.message}',
          );
        }
      },
      onMapLoadedListener: (_) {
        if (kDebugMode) {
          debugPrint('Mapbox: onMapLoaded (native map reported ready)');
        }
        if (mounted) {
          setState(() {
            _debugMapFullyLoaded = true;
            _debugLastMapLoadError = null;
          });
        }
        _startMapHealthCheck();
        // Apply annotations only after map is fully loaded to avoid blocking render thread.
        _requestMapAnnotationRefresh(delay: const Duration(milliseconds: 80));
      },
    );
  }

  void _showMissingTokenHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chưa có MAPBOX_ACCESS_TOKEN. Vui lòng cấu hình token để dùng bản đồ.',
        ),
      ),
    );
  }

  String _resolveOrderAddressLabel(String orderId) {
    final group = _group;
    if (group == null) return orderId;

    for (final order in group.orders) {
      if (order.orderId == orderId) {
        final address = order.destinationAddress.trim();
        if (address.isNotEmpty) {
          return '${order.orderCode} - $address';
        }
        if (order.orderCode.isNotEmpty) {
          return order.orderCode;
        }
        return orderId;
      }
    }

    return orderId;
  }

  int _countUnresolvedRouteStops() {
    final plan = _plan;
    final group = _group;
    if (plan == null || group == null) return 0;

    final orderIds = group.orders.map((e) => e.orderId).toSet();
    var unresolved = 0;
    for (final id in plan.orderedOrderIds) {
      if (!orderIds.contains(id)) {
        unresolved++;
      }
    }
    return unresolved;
  }

  Future<void> _onStartDeliveryPressed(BuildContext context) async {
    if (!MapboxConfig.isConfigured) {
      _showMissingTokenHint(context);
      return;
    }

    final nextOrderId = _resolveNextOrderIdForExecution();
    if (nextOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa có đơn hợp lệ để bắt đầu giao. Vui lòng tải lại lộ trình.',
          ),
        ),
      );
      return;
    }

    final groupId = widget.groupId?.trim();
    if (kDebugMode) {
      debugPrint(
        'Start delivery flow: orderId=$nextOrderId groupId=${groupId ?? "(none)"}',
      );
    }

    final planIds = _plan?.orderedOrderIds;
    await context.push(
      Routes.deliveryOrderDetails(
        nextOrderId,
        groupId: groupId,
        routeOrderedOrderIds: (planIds != null && planIds.isNotEmpty)
            ? List<String>.from(planIds)
            : null,
      ),
    );

    // When returning from order flow, reload group + route-plan to keep
    // route panel/markers in sync with latest statuses.
    if (mounted && _hasValidGroupId) {
      await _loadData();
    }
  }

  String? _resolveNextOrderIdForExecution() {
    final actionableRouteOrderIds = _resolveActionableRouteOrderIds();
    if (actionableRouteOrderIds.isNotEmpty) {
      return actionableRouteOrderIds.first;
    }

    final plan = _plan;
    final group = _group;
    if (plan == null || group == null) {
      return null;
    }

    for (final orderedId in plan.orderedOrderIds) {
      for (final order in group.orders) {
        if (order.orderId == orderedId && _isOrderActionable(order)) {
          return order.orderId;
        }
      }
    }

    for (final order in group.orders) {
      if (_isOrderActionable(order)) {
        return order.orderId;
      }
    }

    return null;
  }

  List<String> _resolveActionableRouteOrderIds() {
    final plan = _plan;
    final group = _group;
    if (plan == null || group == null || group.orders.isEmpty) {
      return const [];
    }

    final orderById = <String, DeliveryOrder>{
      for (final order in group.orders) order.orderId: order,
    };

    final result = <String>[];
    final added = <String>{};

    for (final orderedId in plan.orderedOrderIds) {
      final order = orderById[orderedId];
      if (order == null || !_isOrderActionable(order)) {
        continue;
      }
      if (added.add(order.orderId)) {
        result.add(order.orderId);
      }
    }

    // Keep backward compatibility when BE route payload is stale or partial.
    for (final order in group.orders) {
      if (!_isOrderActionable(order)) {
        continue;
      }
      if (added.add(order.orderId)) {
        result.add(order.orderId);
      }
    }

    return result;
  }

  int _countPendingGroupItemsForOrder(String orderId) {
    final group = _group;
    final groupId = widget.groupId?.trim();
    if (group == null || groupId == null || groupId.isEmpty) {
      return 0;
    }

    for (final order in group.orders) {
      if (order.orderId != orderId) {
        continue;
      }

      return order.items
          .where((item) => _isActionableGroupItem(item, groupId))
          .length;
    }

    return 0;
  }

  bool _isOrderActionable(DeliveryOrder order) {
    final groupId = widget.groupId?.trim();
    if (groupId != null && groupId.isNotEmpty && order.items.isNotEmpty) {
      return order.items.any((item) => _isActionableGroupItem(item, groupId));
    }

    // Backward-compatible fallback when item-level payload is unavailable.
    return !order.isCompleted &&
        !order.isFailed &&
        order.status != DeliveryOrderStatus.deliveredWaitConfirm &&
        order.status != DeliveryOrderStatus.canceled &&
        order.status != DeliveryOrderStatus.refunded;
  }

  bool _isGroupFinalized() {
    final group = _group;
    if (group == null) {
      return false;
    }

    return group.status == DeliveryGroupStatus.completed ||
        group.status == DeliveryGroupStatus.failed;
  }

  bool _isGroupComplete() {
    final group = _group;
    if (group == null || group.orders.isEmpty) {
      return false;
    }

    final groupId = widget.groupId?.trim();
    if (groupId != null && groupId.isNotEmpty) {
      final groupedItems = group.orders
          .expand((order) => order.items)
          .where((item) => _isItemBelongsToGroup(item, groupId))
          .where((item) => item.isPackagingCompleted)
          .toList();

      if (groupedItems.isNotEmpty) {
        return groupedItems.every(_isTerminalGroupItem);
      }
    }

    // Backward-compatible fallback when item-level payload is unavailable.
    return group.orders.every(
      (order) =>
          order.isCompleted ||
          order.isFailed ||
          order.status == DeliveryOrderStatus.deliveredWaitConfirm ||
          order.status == DeliveryOrderStatus.canceled ||
          order.status == DeliveryOrderStatus.refunded,
    );
  }

  bool _isActionableGroupItem(DeliveryOrderItem item, String groupId) {
    if (!_isItemBelongsToGroup(item, groupId)) {
      return false;
    }
    if (!item.isPackagingCompleted) {
      return false;
    }
    return !_isTerminalGroupItem(item);
  }

  bool _isTerminalGroupItem(DeliveryOrderItem item) {
    final status = _normalizeItemDeliveryStatus(item.deliveryStatus);
    return status == 'completed' ||
        status == 'failed' ||
        status == 'deliveredwaitconfirm';
  }

  bool _isItemBelongsToGroup(DeliveryOrderItem item, String groupId) {
    final itemGroupId = item.deliveryGroupId?.trim();
    if (itemGroupId == null || itemGroupId.isEmpty) {
      return false;
    }
    return itemGroupId.toLowerCase() == groupId.toLowerCase();
  }

  String _normalizeItemDeliveryStatus(String? status) {
    return (status ?? '').trim().toLowerCase().replaceAll('_', '');
  }

  void _onCompleteGroupPressed(BuildContext context) {
    if (_isGroupFinalized()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhóm giao đã kết thúc, không thể hoàn thành lại'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    final groupId = widget.groupId?.trim();
    if (groupId == null || groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác định nhóm giao hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('Complete delivery group: groupId=$groupId');
    }

    // Dispatch CompleteDeliveryGroup event
    context.read<DeliveryBloc>().add(CompleteDeliveryGroup(groupId: groupId));
  }
}

class _RouteLegsSummary extends StatelessWidget {
  final RouteLeg? pickupLeg;
  final RouteLeg? deliveryLeg;
  final bool pickedUp;
  final VoidCallback? onPickedUp;

  const _RouteLegsSummary({
    this.pickupLeg,
    this.deliveryLeg,
    this.pickedUp = false,
    this.onPickedUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phân chặng lộ trình',
          style: AppTypography.bodyRegular1.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (pickupLeg != null)
          _LegRow(
            color: AppColors.mapPickupLegLine,
            title: 'Chặng A • Shipper → Siêu thị',
            summary: pickupLeg!.summaryLabel,
          ),
        if (pickupLeg != null && deliveryLeg != null) const SizedBox(height: 6),
        if (deliveryLeg != null)
          _LegRow(
            color: AppColors.mapDeliveryLegLine,
            title: pickedUp
                ? 'Chặng B • Shipper → Khách'
                : 'Chặng B • Siêu thị → Khách',
            summary: deliveryLeg!.summaryLabel,
          ),
        if (pickupLeg != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPickedUp,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Đã lấy hàng - ẩn Chặng A'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                foregroundColor: AppColors.mapPickupLegLine,
                side: const BorderSide(color: AppColors.mapPickupLegLine),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else if (pickedUp) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.mapSuccessStrong,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Đã lấy hàng tại siêu thị — chỉ còn chặng giao khách.',
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mapSuccessStrong,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegRow extends StatelessWidget {
  final Color color;
  final String title;
  final String summary;

  const _LegRow({
    required this.color,
    required this.title,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodyRegular1.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          summary,
          style: AppTypography.bodyRegular1.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RouteStopChip extends StatelessWidget {
  final int index;
  final String label;
  final int pendingItems;

  const _RouteStopChip({
    required this.index,
    required this.label,
    this.pendingItems = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.routeOptionActiveBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.headerGradientEnd.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        pendingItems > 0
            ? '$index. $label (còn $pendingItems item)'
            : '$index. $label',
        style: AppTypography.bodyRegular1.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _RouteOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onTap;

  const _RouteOption({
    required this.title,
    required this.subtitle,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? AppColors.headerGradientEnd
        : AppColors.dividerStrong;
    final bgColor = isActive
        ? AppColors.routeOptionActiveBackground
        : AppColors.surfaceWhite;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.alt_route,
                size: 16,
                color: isActive
                    ? AppColors.headerGradientEnd
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.header3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodyRegular1.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
