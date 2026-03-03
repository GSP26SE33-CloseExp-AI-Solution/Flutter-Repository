import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/delivery_repository.dart';
import 'delivery_event.dart';
import 'delivery_state.dart';

/// Delivery BLoC - Presentation Layer
///
/// Manages delivery feature state and business logic.
class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryRepository _repository;

  DeliveryBloc({required DeliveryRepository repository})
      : _repository = repository,
        super(const DeliveryInitial()) {
    // Load events
    on<LoadAvailableGroups>(_onLoadAvailableGroups);
    on<LoadMyGroups>(_onLoadMyGroups);
    on<LoadGroupDetails>(_onLoadGroupDetails);
    on<LoadOrderDetails>(_onLoadOrderDetails);
    on<LoadDeliveryStats>(_onLoadDeliveryStats);
    on<LoadDeliveryHistory>(_onLoadDeliveryHistory);

    // Action events
    on<AcceptDeliveryGroup>(_onAcceptDeliveryGroup);
    on<StartDelivery>(_onStartDelivery);
    on<CompleteDeliveryGroup>(_onCompleteDeliveryGroup);
    on<ConfirmDelivery>(_onConfirmDelivery);
    on<ReportDeliveryFailure>(_onReportDeliveryFailure);

    // UI events
    on<ClearDeliveryError>(_onClearError);
    on<ResetDeliveryState>(_onReset);
  }

  // ============== LOAD HANDLERS ==============

  Future<void> _onLoadAvailableGroups(
    LoadAvailableGroups event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang tải đơn hàng có sẵn...'));

    final result = await _repository.getAvailableGroups();

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (groups) => emit(AvailableGroupsLoaded(groups: groups)),
    );
  }

  Future<void> _onLoadMyGroups(
    LoadMyGroups event,
    Emitter<DeliveryState> emit,
  ) async {
    final currentState = state;

    // Handle pagination (load more)
    if (!event.refresh && currentState is MyGroupsLoaded && event.page > 1) {
      emit(currentState.copyWith(isLoadingMore: true));

      final result = await _repository.getMyGroups(
        page: event.page,
        pageSize: event.pageSize,
        status: event.status,
      );

      result.fold(
        (failure) => emit(DeliveryError(message: failure.message)),
        (paginated) => emit(currentState.copyWith(
          groups: [...currentState.groups, ...paginated.groups],
          currentPage: paginated.currentPage,
          totalPages: paginated.totalPages,
          totalCount: paginated.totalCount,
          hasNextPage: paginated.hasNextPage,
          isLoadingMore: false,
        )),
      );
    } else {
      // Fresh load or refresh
      emit(const DeliveryLoading(message: 'Đang tải đơn hàng của bạn...'));

      final result = await _repository.getMyGroups(
        page: 1,
        pageSize: event.pageSize,
        status: event.status,
      );

      result.fold(
        (failure) => emit(DeliveryError(message: failure.message)),
        (paginated) => emit(MyGroupsLoaded(
          groups: paginated.groups,
          currentPage: paginated.currentPage,
          totalPages: paginated.totalPages,
          totalCount: paginated.totalCount,
          hasNextPage: paginated.hasNextPage,
        )),
      );
    }
  }

  Future<void> _onLoadGroupDetails(
    LoadGroupDetails event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang tải thông tin nhóm giao...'));

    final result = await _repository.getDeliveryGroupById(event.groupId);

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (group) => emit(GroupDetailsLoaded(group: group)),
    );
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetails event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang tải thông tin đơn hàng...'));

    final result = await _repository.getOrderDetails(event.orderId);

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (order) => emit(OrderDetailsLoaded(order: order)),
    );
  }

  Future<void> _onLoadDeliveryStats(
    LoadDeliveryStats event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang tải thống kê...'));

    final result = await _repository.getDeliveryStats();

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (stats) => emit(DeliveryStatsLoaded(stats: stats)),
    );
  }

  Future<void> _onLoadDeliveryHistory(
    LoadDeliveryHistory event,
    Emitter<DeliveryState> emit,
  ) async {
    final currentState = state;

    // Handle pagination
    if (!event.refresh &&
        currentState is DeliveryHistoryLoaded &&
        event.page > 1) {
      emit(currentState.copyWith(isLoadingMore: true));

      final result = await _repository.getDeliveryHistory(
        page: event.page,
        pageSize: event.pageSize,
        fromDate: event.fromDate,
        toDate: event.toDate,
        status: event.status,
      );

      result.fold(
        (failure) => emit(DeliveryError(message: failure.message)),
        (paginated) => emit(currentState.copyWith(
          records: [...currentState.records, ...paginated.records],
          currentPage: paginated.currentPage,
          totalPages: paginated.totalPages,
          totalCount: paginated.totalCount,
          hasNextPage: paginated.hasNextPage,
          isLoadingMore: false,
        )),
      );
    } else {
      emit(const DeliveryLoading(message: 'Đang tải lịch sử giao hàng...'));

      final result = await _repository.getDeliveryHistory(
        page: 1,
        pageSize: event.pageSize,
        fromDate: event.fromDate,
        toDate: event.toDate,
        status: event.status,
      );

      result.fold(
        (failure) => emit(DeliveryError(message: failure.message)),
        (paginated) => emit(DeliveryHistoryLoaded(
          records: paginated.records,
          currentPage: paginated.currentPage,
          totalPages: paginated.totalPages,
          totalCount: paginated.totalCount,
          hasNextPage: paginated.hasNextPage,
        )),
      );
    }
  }

  // ============== ACTION HANDLERS ==============

  Future<void> _onAcceptDeliveryGroup(
    AcceptDeliveryGroup event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang nhận đơn...'));

    final result = await _repository.acceptDeliveryGroup(
      event.groupId,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (group) => emit(DeliveryGroupAccepted(group: group)),
    );
  }

  Future<void> _onStartDelivery(
    StartDelivery event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang bắt đầu giao hàng...'));

    final result = await _repository.startDelivery(
      event.groupId,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (group) => emit(DeliveryStarted(group: group)),
    );
  }

  Future<void> _onCompleteDeliveryGroup(
    CompleteDeliveryGroup event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang hoàn thành nhóm giao...'));

    final result = await _repository.completeDeliveryGroup(event.groupId);

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (group) => emit(DeliveryGroupCompleted(group: group)),
    );
  }

  Future<void> _onConfirmDelivery(
    ConfirmDelivery event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang xác nhận giao hàng...'));

    final result = await _repository.confirmDelivery(
      event.orderId,
      proofImageUrl: event.proofImageUrl,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (record) => emit(DeliveryConfirmed(record: record)),
    );
  }

  Future<void> _onReportDeliveryFailure(
    ReportDeliveryFailure event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading(message: 'Đang báo cáo thất bại...'));

    final result = await _repository.reportDeliveryFailure(
      event.orderId,
      failureReason: event.failureReason,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(DeliveryError(message: failure.message)),
      (record) => emit(DeliveryFailureReported(record: record)),
    );
  }

  // ============== UI HANDLERS ==============

  void _onClearError(
    ClearDeliveryError event,
    Emitter<DeliveryState> emit,
  ) {
    emit(const DeliveryInitial());
  }

  void _onReset(
    ResetDeliveryState event,
    Emitter<DeliveryState> emit,
  ) {
    emit(const DeliveryInitial());
  }
}
