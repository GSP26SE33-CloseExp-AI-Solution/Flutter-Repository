import 'package:equatable/equatable.dart';

/// Delivery Events - Presentation Layer
///
/// Events dispatched to the DeliveryBloc.
abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

// ============== LOAD EVENTS ==============

/// Load available delivery groups
class LoadAvailableGroups extends DeliveryEvent {
  final DateTime? deliveryDate;

  const LoadAvailableGroups({this.deliveryDate});

  @override
  List<Object?> get props => [deliveryDate];
}

/// Load my delivery groups (assigned to current staff)
class LoadMyGroups extends DeliveryEvent {
  final int page;
  final int pageSize;
  final String? status;
  final DateTime? deliveryDate;
  final bool refresh;

  const LoadMyGroups({
    this.page = 1,
    this.pageSize = 10,
    this.status,
    this.deliveryDate,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, pageSize, status, deliveryDate, refresh];
}

/// Load delivery group details
class LoadGroupDetails extends DeliveryEvent {
  final String groupId;

  const LoadGroupDetails({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

/// Load order details
class LoadOrderDetails extends DeliveryEvent {
  final String orderId;

  const LoadOrderDetails({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// Load delivery stats
class LoadDeliveryStats extends DeliveryEvent {
  const LoadDeliveryStats();
}

/// Load delivery history
class LoadDeliveryHistory extends DeliveryEvent {
  final int page;
  final int pageSize;
  final bool refresh;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? status;

  const LoadDeliveryHistory({
    this.page = 1,
    this.pageSize = 20,
    this.refresh = false,
    this.fromDate,
    this.toDate,
    this.status,
  });

  @override
  List<Object?> get props => [
    page,
    pageSize,
    refresh,
    fromDate,
    toDate,
    status,
  ];
}

// ============== ACTION EVENTS ==============

/// Accept a delivery group
class AcceptDeliveryGroup extends DeliveryEvent {
  final String groupId;
  final String? notes;

  const AcceptDeliveryGroup({required this.groupId, this.notes});

  @override
  List<Object?> get props => [groupId, notes];
}

/// Start delivery for a group
class StartDelivery extends DeliveryEvent {
  final String groupId;
  final String? notes;

  const StartDelivery({required this.groupId, this.notes});

  @override
  List<Object?> get props => [groupId, notes];
}

/// Complete a delivery group
class CompleteDeliveryGroup extends DeliveryEvent {
  final String groupId;

  const CompleteDeliveryGroup({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

/// Confirm delivery for an order
class ConfirmDelivery extends DeliveryEvent {
  final String orderId;
  final String? proofImagePath;
  final String? proofImageUrl;
  final String? notes;

  const ConfirmDelivery({
    required this.orderId,
    this.proofImagePath,
    this.proofImageUrl,
    this.notes,
  });

  @override
  List<Object?> get props => [orderId, proofImagePath, proofImageUrl, notes];
}

/// Report delivery failure
class ReportDeliveryFailure extends DeliveryEvent {
  final String orderId;
  final String failureReason;
  final String? notes;

  const ReportDeliveryFailure({
    required this.orderId,
    required this.failureReason,
    this.notes,
  });

  @override
  List<Object?> get props => [orderId, failureReason, notes];
}

// ============== UI EVENTS ==============

/// Reset error state
class ClearDeliveryError extends DeliveryEvent {
  const ClearDeliveryError();
}

/// Reset to initial state
class ResetDeliveryState extends DeliveryEvent {
  const ResetDeliveryState();
}
