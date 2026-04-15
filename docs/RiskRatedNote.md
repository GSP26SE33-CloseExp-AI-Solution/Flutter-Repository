# Session Recovery Notes - 2026-04-15

Mục tiêu của note này là ghi lại các risk/điểm cần kiểm tra lại sau khi làm việc với luồng Delivery, để lần sau chỉ cần mở file này là biết phải nhìn vào đâu.

## Risk đã xác nhận

1. Confirm/Report delivery trả về sai kiểu model nếu map nhầm sang `DeliveryRecord`.

   - Backend trả `DeliveryOrderResponseDto` cho 2 API:
     - [lib/features/delivery/data/datasources/delivery_remote_datasource.dart](../lib/features/delivery/data/datasources/delivery_remote_datasource.dart)
     - [lib/features/delivery/data/repositories/delivery_repository_impl.dart](../lib/features/delivery/data/repositories/delivery_repository_impl.dart)
   - Cần giữ model đích là `DeliveryOrderModel`, không dùng `DeliveryRecordModel` cho 2 flow này.
   - Constants endpoint nằm ở [lib/core/constants/api_constants.dart](../lib/core/constants/api_constants.dart).

2. Delivery group mapping có risk lệch tên field `deliveryTimeSlotId` / `timeSlotId`.

   - File đang có fallback đúng: [lib/features/delivery/data/models/delivery_group_model.dart](../lib/features/delivery/data/models/delivery_group_model.dart)
   - Nếu BE đổi payload hoặc FE chỗ khác parse group summary, phải kiểm tra thêm các consumer của delivery group.

3. Delivery history phải đi qua `DeliveryRecord`/`DeliveryRecordModel` riêng, không trộn với order detail.

   - Entity gốc: [lib/features/delivery/domain/entities/delivery_order.dart](../lib/features/delivery/domain/entities/delivery_order.dart)
   - Model parse history: [lib/features/delivery/data/models/delivery_order_model.dart](../lib/features/delivery/data/models/delivery_order_model.dart)
   - State/UI nhận history: [lib/features/delivery/presentation/bloc/delivery_state.dart](../lib/features/delivery/presentation/bloc/delivery_state.dart) và [lib/features/delivery/presentation/pages/delivery_history_page.dart](../lib/features/delivery/presentation/pages/delivery_history_page.dart)

## Luồng nên kiểm tra lại khi quay lại

- Xác minh response shape thật của 2 API confirm/report trong BE.
- Soát lại `fromJson` của `DeliveryOrderModel` và `DeliveryRecordModel` để chắc chắn field names khớp.
- Nếu có lỗi UI sau khi confirm/report, ưu tiên kiểm tra [lib/features/delivery/presentation/bloc/delivery_bloc.dart](../lib/features/delivery/presentation/bloc/delivery_bloc.dart) và repository/model chain phía dưới.

## Ghi chú ngắn

- File constants hiện tại đang là nguồn endpoint chuẩn cho app delivery staff.
- Nếu về sau thêm risk mới, hãy cập nhật ngay vào note này và thêm link tới đúng file nguồn thay vì chỉ mô tả bằng text.