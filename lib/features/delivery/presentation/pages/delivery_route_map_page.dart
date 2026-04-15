import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/constants/mapbox_config.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/polyline6_decoder.dart';
import '../../../../injection_container.dart' show sl;
import '../../domain/entities/delivery_group.dart';
import '../../domain/entities/delivery_order.dart';
import '../../domain/entities/delivery_route_plan.dart';
import '../../domain/repositories/delivery_repository.dart';

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

  static const bool _useMockRoute = bool.fromEnvironment(
    'USE_MOCK_ROUTE',
    defaultValue: false,
  );
  static const int _mockRoutePoints = int.fromEnvironment(
    'MOCK_ROUTE_POINTS',
    defaultValue: 3,
  );

  MapboxMap? _map;
  PolylineAnnotationManager? _polylineManager;
  PointAnnotationManager? _pointManager;

  DeliveryGroup? _group;
  DeliveryRoutePlan? _plan;
  String _metric = 'distance';
  bool _loading = false;
  String? _loadError;

  /// Guard to prevent concurrent annotation application (reduce rebuild churn).
  bool _annotationApplyInProgress = false;

  /// Debug-only: which [_buildMapLayer] branch is active (white area ≠ always MapWidget).
  bool _debugMapSurfaceCreated = false;
  bool _debugMapStyleLoaded = false;
  bool _debugMapFullyLoaded = false;
  String? _debugLastMapLoadError;
  bool _controlsExpanded = false;
  int _fullRenderFrameCount = 0;
  bool _mapRenderStalled = false;
  bool _didTryFallbackStyle = false;
  Timer? _mapHealthTimer;

  bool get _hasValidGroupId {
    final id = widget.groupId?.trim();
    if (id == null || id.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }

  /// Override via `--dart-define=MAPBOX_ANDROID_HOSTING=...` if needed.
  /// Default [VD] matches mapbox_maps_flutter SDK; [TLHC_VD] can white-screen some GPUs.
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

  /// Toggle via `--dart-define=MAPBOX_TEXTURE_VIEW=true|false` for device-specific rendering.
  /// Some devices render blank with TextureView=true under certain hosting modes.
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
      _debugMapSurfaceCreated = false;
      _debugMapStyleLoaded = false;
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

  /// Label for the map layer branch (token placeholder / unsupported platform / native MapWidget).
  String _debugMapBranchLabel() {
    if (!MapboxConfig.isConfigured) return 'placeholder_token';
    if (!MapboxConfig.isMapWidgetSupported) return 'placeholder_platform';
    return 'map_widget';
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

  Future<void> _fetchRoutePlanOnly() async {
    if (_useMockRoute) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _plan = _createMockRoutePlan();
        _loadError = null;
      });
      _applyMapAnnotationsIfNecessary();
      return;
    }

    if (!_hasValidGroupId) return;
    final gid = widget.groupId!.trim();
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final planResult = await _repository.computeDeliveryRoutePlan(
      gid,
      metric: _metric,
    );

    if (!mounted) return;

    planResult.fold(
      (failure) {
        setState(() {
          _loading = false;
          _plan = null;
          _loadError = failure.message;
        });
        _applyMapAnnotationsIfNecessary();
      },
      (plan) {
        setState(() {
          _loading = false;
          _plan = plan;
          _loadError = null;
        });
        _applyMapAnnotationsIfNecessary();
      },
    );
  }

  Future<void> _onMetricSelected(String metric) async {
    if (_metric == metric || _loading) return;
    setState(() => _metric = metric);
    if (_hasValidGroupId) await _fetchRoutePlanOnly();
  }

  void _handleBackNavigation(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }

    // Fallback target when this page was opened via replacement and stack has no previous route.
    context.go(Routes.deliveryAvailable);
  }

  /// Apply annotations with guard to prevent concurrent calls during map lifecycle churn.
  Future<void> _applyMapAnnotationsIfNecessary() async {
    if (_annotationApplyInProgress) return;
    _annotationApplyInProgress = true;
    try {
      await _applyMapAnnotations();
    } finally {
      _annotationApplyInProgress = false;
    }
  }

  Future<void> _applyMapAnnotations() async {
    final map = _map;
    if (map == null || !MapboxConfig.isConfigured) return;

    _polylineManager ??= await map.annotations
        .createPolylineAnnotationManager();
    _pointManager ??= await map.annotations.createPointAnnotationManager();

    await _polylineManager!.deleteAll();
    await _pointManager!.deleteAll();

    final plan = _plan;
    if (plan == null || plan.encodedPolyline.isEmpty) {
      await _fitToOrdersIfPossible();
      return;
    }

    final decoded = Polyline6Decoder.decode(plan.encodedPolyline);
    if (decoded.length < 2) {
      await _fitToOrdersIfPossible();
      return;
    }

    final linePoints = decoded
        .map((p) => Point(coordinates: Position(p.longitude, p.latitude)))
        .toList();
    final line = LineString.fromPoints(points: linePoints);

    await _polylineManager!.create(
      PolylineAnnotationOptions(
        geometry: line,
        lineColor: const Color(0xFFE53935).toARGB32(),
        lineWidth: 4,
        lineOpacity: 0.9,
      ),
    );

    if (_useMockRoute) {
      var seq = 1;
      for (final p in decoded) {
        await _pointManager!.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(p.longitude, p.latitude)),
            textField: '$seq',
            textSize: 14,
            textColor: const Color(0xFFFFFFFF).toARGB32(),
            textHaloColor: const Color(0xFF000000).toARGB32(),
            textHaloWidth: 1,
          ),
        );
        seq++;
      }
    } else {
      final group = _group;
      if (group != null && plan.orderedOrderIds.isNotEmpty) {
        var seq = 1;
        for (final oid in plan.orderedOrderIds) {
          DeliveryOrder? match;
          for (final o in group.orders) {
            if (o.orderId == oid) {
              match = o;
              break;
            }
          }
          if (match?.latitude != null && match?.longitude != null) {
            await _pointManager!.create(
              PointAnnotationOptions(
                geometry: Point(
                  coordinates: Position(match!.longitude!, match.latitude!),
                ),
                textField: '$seq',
                textSize: 14,
                textColor: const Color(0xFFFFFFFF).toARGB32(),
                textHaloColor: const Color(0xFF000000).toARGB32(),
                textHaloWidth: 1,
              ),
            );
          }
          seq++;
        }
      }
    }

    await _fitCameraToPoints(decoded);
  }

  Future<void> _fitToOrdersIfPossible() async {
    if (_useMockRoute) {
      await _fitCameraToPoints(_mockPointsForRoute());
      return;
    }

    final group = _group;
    final map = _map;
    if (map == null || group == null) return;
    final pts = group.orders
        .where((o) => o.latitude != null && o.longitude != null)
        .map((o) => (latitude: o.latitude!, longitude: o.longitude!))
        .toList();
    if (pts.isEmpty) return;
    await _fitCameraToPoints(pts);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
            color: Colors.white,
            letterSpacing: -0.60,
          ),
        ),
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
                color: Colors.amber.shade100,
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
          if (kDebugMode) _buildDebugMapInspectorOverlay(context),
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
          height: _controlsExpanded ? 330 : 126,
          decoration: const BoxDecoration(
            color: Colors.white,
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
                    _metric == 'distance' ? distanceSubtitle : durationSubtitle,
                    style: AppTypography.bodyRegular1.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                    if (_plan != null && _plan!.skippedOrderIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Bỏ qua ${_plan!.skippedOrderIds.length} đơn thiếu tọa độ',
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
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
                            onTap: MapboxConfig.isConfigured && _hasValidGroupId
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
                            onTap: MapboxConfig.isConfigured && _hasValidGroupId
                                ? () => _onMetricSelected('duration')
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.headerGradientStart,
                              AppColors.headerGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            if (!MapboxConfig.isConfigured) {
                              _showMissingTokenHint(context);
                              return;
                            }
                            if (_plan?.orderedOrderIds.isNotEmpty == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Giao theo thứ tự đánh số trên bản đồ (mục Đơn hàng để xác nhận từng đơn).',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Bắt đầu giao hàng',
                            style: AppTypography.subHeader.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
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
    );
  }

  /// On-screen checklist for the "white map" investigation (debug builds only).
  Widget _buildDebugMapInspectorOverlay(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 52;
    final branch = _debugMapBranchLabel();
    final defineRaw = _kMapboxAndroidHostingDefine.isEmpty
        ? '(unset->VD)'
        : _kMapboxAndroidHostingDefine;
    final lines = <String>[
      'branch=$branch',
      if (branch == 'map_widget') ...[
        'define=$defineRaw',
        'hosting=$_androidHostingMode',
        'texture=$_useTextureView fullFrames=$_fullRenderFrameCount stalled=$_mapRenderStalled',
        'created=$_debugMapSurfaceCreated style=$_debugMapStyleLoaded mapLoaded=$_debugMapFullyLoaded',
        if (_debugLastMapLoadError != null)
          'mapLoadErr=$_debugLastMapLoadError',
      ],
      'compare: mapbox.dev.json MAPBOX_ANDROID_HOSTING',
      'Logcat: filter ThemeUtils AppCompat (expect none)',
      'still blank+mapLoaded? try launch HC then TLHC_HC',
      'or other device / emulator GLES (MediaTek quirks)',
    ];
    return Positioned(
      top: top,
      right: 8,
      child: Material(
        color: AppColors.neutralDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              height: 1.25,
              fontFamily: 'monospace',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: lines.map((s) => Text(s)).toList(),
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
          color: Colors.white,
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
          setState(() {
            _debugMapSurfaceCreated = true;
            _debugLastMapLoadError = null;
          });
        }
      },
      onStyleLoadedListener: (_) {
        if (mounted) {
          setState(() => _debugMapStyleLoaded = true);
        }
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
        _applyMapAnnotationsIfNecessary();
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
        : Colors.white;

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
