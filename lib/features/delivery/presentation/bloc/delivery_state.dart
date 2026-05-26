import 'package:equatable/equatable.dart';
import '../../domain/entities/delivery_group.dart';
import '../../domain/entities/delivery_order.dart';
import '../../domain/entities/delivery_stats.dart';

/// Delivery states do DeliveryBloc phát ra.
abstract class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DeliveryInitial extends DeliveryState {
  const DeliveryInitial();
}

/// Loading state
class DeliveryLoading extends DeliveryState {
  final String? message;

  const DeliveryLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Error state for loading failures (shows full error screen)
class DeliveryError extends DeliveryState {
  final String message;

  const DeliveryError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Lỗi thao tác (snackbar): accept, start, complete, confirm, báo thất bại.
class DeliveryActionError extends DeliveryState {
  final String message;

  const DeliveryActionError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Session expired state used to force logout on 401 responses.
class DeliverySessionExpired extends DeliveryState {
  const DeliverySessionExpired();
}

// ============== GROUPS STATES ==============

/// Available groups loaded
class AvailableGroupsLoaded extends DeliveryState {
  final List<DeliveryGroupSummary> groups;

  const AvailableGroupsLoaded({required this.groups});

  bool get isEmpty => groups.isEmpty;
  bool get isNotEmpty => groups.isNotEmpty;

  @override
  List<Object?> get props => [groups];
}

/// My groups loaded (paginated)
class MyGroupsLoaded extends DeliveryState {
  final List<DeliveryGroupSummary> groups;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool isLoadingMore;
  final bool isWorkQueue;

  const MyGroupsLoaded({
    required this.groups,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.isWorkQueue = false,
  });

  bool get isEmpty => groups.isEmpty;
  bool get isNotEmpty => groups.isNotEmpty;

  MyGroupsLoaded copyWith({
    List<DeliveryGroupSummary>? groups,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? hasNextPage,
    bool? isLoadingMore,
    bool? isWorkQueue,
  }) {
    return MyGroupsLoaded(
      groups: groups ?? this.groups,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isWorkQueue: isWorkQueue ?? this.isWorkQueue,
    );
  }

  @override
  List<Object?> get props => [
    groups,
    currentPage,
    totalPages,
    totalCount,
    hasNextPage,
    isLoadingMore,
    isWorkQueue,
  ];
}

/// Group details loaded
class GroupDetailsLoaded extends DeliveryState {
  final DeliveryGroup group;

  const GroupDetailsLoaded({required this.group});

  @override
  List<Object?> get props => [group];
}

// ============== ORDER STATES ==============

/// Order details loaded
class OrderDetailsLoaded extends DeliveryState {
  final DeliveryOrder order;

  const OrderDetailsLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

// ============== ACTION STATES ==============

/// Group accepted successfully
class DeliveryGroupAccepted extends DeliveryState {
  final DeliveryGroup group;

  const DeliveryGroupAccepted({required this.group});

  @override
  List<Object?> get props => [group];
}

/// Delivery started
class DeliveryStarted extends DeliveryState {
  final DeliveryGroup group;

  const DeliveryStarted({required this.group});

  @override
  List<Object?> get props => [group];
}

/// Group completed
class DeliveryGroupCompleted extends DeliveryState {
  final DeliveryGroup group;

  const DeliveryGroupCompleted({required this.group});

  @override
  List<Object?> get props => [group];
}

/// Delivery confirmed for an order
class DeliveryConfirmed extends DeliveryState {
  final DeliveryOrder order;

  const DeliveryConfirmed({required this.order});

  @override
  List<Object?> get props => [order];
}

/// Delivery failure reported
class DeliveryFailureReported extends DeliveryState {
  final DeliveryOrder order;

  const DeliveryFailureReported({required this.order});

  @override
  List<Object?> get props => [order];
}

// ============== STATS & HISTORY STATES ==============

/// Stats loaded
class DeliveryStatsLoaded extends DeliveryState {
  final DeliveryStats stats;

  const DeliveryStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

/// History loaded
class DeliveryHistoryLoaded extends DeliveryState {
  final List<DeliveryRecord> records;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool isLoadingMore;

  const DeliveryHistoryLoaded({
    required this.records,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  bool get isEmpty => records.isEmpty;
  bool get isNotEmpty => records.isNotEmpty;

  DeliveryHistoryLoaded copyWith({
    List<DeliveryRecord>? records,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) {
    return DeliveryHistoryLoaded(
      records: records ?? this.records,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    records,
    currentPage,
    totalPages,
    totalCount,
    hasNextPage,
    isLoadingMore,
  ];
}

// ============== COMBINED STATE ==============

/// Dashboard state combining stats and groups
class DashboardLoaded extends DeliveryState {
  final DeliveryStats stats;
  final List<DeliveryGroupSummary> availableGroups;
  final List<DeliveryGroupSummary> myGroups;

  const DashboardLoaded({
    required this.stats,
    required this.availableGroups,
    required this.myGroups,
  });

  @override
  List<Object?> get props => [stats, availableGroups, myGroups];
}
