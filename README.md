# Mobile App – Ứng Dụng Giao Hàng CloseExp

## 1. Giới Thiệu

**Ứng dụng di động dành riêng cho nhân viên giao hàng** trong hệ thống CloseExp - Nền tảng mua bán sản phẩm cận hạn sử dụng.

Ứng dụng chịu trách nhiệm:
- Đăng nhập/xác thực nhân viên giao hàng
- Xem danh sách đơn hàng cần giao
- Cập nhật trạng thái giao hàng
- Theo dõi lộ trình giao hàng

---

## 2. Mục Tiêu

- Xây dựng ứng dụng mobile ổn định, dễ sử dụng
- Áp dụng **Clean Architecture** và **BLoC Pattern**
- Kết nối với Backend BE-CloseExp qua RESTful API
- Đảm bảo bảo mật với JWT Authentication
- Phân quyền chỉ cho phép vai trò DeliveryStaff

---

## 3. Phạm Vi Chức Năng

### 3.1 Xác thực người dùng
- Đăng nhập với email/mật khẩu
- Kiểm tra vai trò DeliveryStaff
- Lưu token bảo mật
- Tự động đăng nhập khi mở app
- Đăng xuất

### 3.2 Quản lý đơn hàng (Đang phát triển)
- Xem danh sách đơn hàng được phân công
- Xem chi tiết đơn hàng
- Cập nhật trạng thái:
  - Đã nhận đơn
  - Đang giao
  - Hoàn thành / Thất bại

### 3.3 Theo dõi giao hàng (Đang phát triển)
- Xem bản đồ
- Điều hướng đến địa chỉ giao hàng
- Chụp ảnh xác nhận giao hàng

---

## 4. Kiến Trúc Ứng Dụng

### 4.1 Clean Architecture

Ứng dụng được xây dựng theo **Clean Architecture** của Robert C. Martin:

```
┌─────────────────────────────────────────┐
│           PRESENTATION                   │
│    (BLoC, Pages, Widgets)               │
├─────────────────────────────────────────┤
│              DOMAIN                      │
│    (Entities, UseCases, Repositories)   │
├─────────────────────────────────────────┤
│               DATA                       │
│  (Models, DataSources, Repo Impl)       │
└─────────────────────────────────────────┘
```

### 4.2 Cấu Trúc Thư Mục

```
lib/
├── core/                    # Thành phần dùng chung
│   ├── constants/           # Hằng số (API URL, keys)
│   ├── error/               # Xử lý lỗi (Failures, Exceptions)
│   ├── network/             # HTTP Client (Dio)
│   ├── router/              # Điều hướng (GoRouter)
│   └── usecases/            # Base UseCase
│
├── features/                # Các tính năng
│   ├── auth/                # Xác thực
│   │   ├── data/            # Models, DataSources, Repository
│   │   ├── domain/          # Entities, UseCases, Repository Interface
│   │   └── presentation/    # BLoC, Pages
│   │
│   └── home/                # Trang chủ
│
├── injection_container.dart # Dependency Injection
└── main.dart                # Entry point
```

### 4.3 Mô Tả Các Layer

| Layer | Chức năng | Phụ thuộc |
|-------|-----------|-----------|
| **Presentation** | UI, State Management | Domain |
| **Domain** | Business Logic | Không phụ thuộc |
| **Data** | API, Cache, Models | Domain |

---

## 5. Công Nghệ Sử Dụng

### Framework & Language
| Công nghệ | Phiên bản | Mục đích |
|-----------|-----------|----------|
| Flutter | ^3.9.2 | Framework |
| Dart | ^3.9.2 | Ngôn ngữ |

### State Management
| Package | Mục đích |
|---------|----------|
| `flutter_bloc` | BLoC Pattern |
| `equatable` | So sánh State/Event |

### Networking
| Package | Mục đích |
|---------|----------|
| `dio` | HTTP Client |
| `pretty_dio_logger` | Debug API |

### Navigation
| Package | Mục đích |
|---------|----------|
| `go_router` | Declarative routing |

### Storage
| Package | Mục đích |
|---------|----------|
| `flutter_secure_storage` | Lưu token bảo mật |
| `shared_preferences` | Lưu cài đặt |

### Dependency Injection
| Package | Mục đích |
|---------|----------|
| `get_it` | Service Locator |
| `injectable` | Auto-generate DI |

### Utilities
| Package | Mục đích |
|---------|----------|
| `dartz` | Functional (Either) |
| `freezed` | Code generation |
| `json_serializable` | JSON parsing |

---

## 6. Tích Hợp Backend

### 6.1 API Endpoints

Ứng dụng kết nối với **BE-CloseExp** qua các endpoint:

| Endpoint | Method | Mô tả |
|----------|--------|-------|
| `/api/auth/login` | POST | Đăng nhập |
| `/api/auth/logout` | POST | Đăng xuất |
| `/api/orders` | GET | Lấy danh sách đơn hàng |
| `/api/orders/{id}` | GET | Chi tiết đơn hàng |
| `/api/orders/{id}/status` | PUT | Cập nhật trạng thái |

### 6.2 Request Format

```json
// POST /api/auth/login
{
  "email": "delivery@example.com",
  "password": "password123"
}
```

### 6.3 Response Format

```json
{
  "success": true,
  "message": "Đăng nhập thành công",
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "...",
    "expiresAt": "2026-01-30T12:00:00Z",
    "user": {
      "userId": "...",
      "fullName": "Nhân viên giao hàng",
      "roleName": "DeliveryStaff"
    }
  }
}
```

---

## 7. Bảo Mật

### 7.1 Authentication
- JWT Token-based authentication
- Token lưu trong Secure Storage (mã hóa)
- Tự động refresh token khi hết hạn

### 7.2 Authorization
- Kiểm tra vai trò DeliveryStaff khi đăng nhập
- Từ chối các vai trò khác với thông báo phù hợp

### 7.3 Network Security
- HTTPS cho production
- Certificate pinning (khuyến nghị)

---

## 8. Hướng Dẫn Cài Đặt

### 8.1 Yêu Cầu

- Flutter SDK ^3.9.2
- Dart SDK ^3.9.2
- Android Studio / VS Code
- Thiết bị Android/iOS hoặc Emulator

### 8.2 Cài Đặt

```bash
# Clone repository
git clone <repository-url>
cd App-CloseExp

# Cài đặt dependencies
flutter pub get

# Chạy code generation (nếu có)
flutter pub run build_runner build --delete-conflicting-outputs

# Chạy ứng dụng
flutter run
```

### 8.3 Cấu Hình API

Sửa file `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // iOS Simulator
  // static const String baseUrl = 'http://localhost:5000/api';
  
  // Thiết bị thật (dùng IP máy tính)
  // static const String baseUrl = 'http://192.168.x.x:5000/api';
}
```

---

## 9. Yêu Cầu Phi Chức Năng

| Yêu cầu | Mô tả |
|---------|-------|
| **Hiệu năng** | Khởi động < 3 giây, API response < 5 giây |
| **Độ tin cậy** | Xử lý offline, retry khi mất mạng |
| **Bảo mật** | Mã hóa token, validate input |
| **UX** | Loading indicator, error messages rõ ràng |
| **Khả năng bảo trì** | Clean Architecture, code có tài liệu |

---

## 10. Kế Hoạch Phát Triển

| Sprint | Nội dung |
|--------|----------|
| Sprint 1 | ✅ Setup kiến trúc, Đăng nhập/Đăng xuất |
| Sprint 2 | 🔄 Danh sách đơn hàng, Chi tiết đơn hàng |
| Sprint 3 | ⏳ Cập nhật trạng thái, Bản đồ |
| Sprint 4 | ⏳ Chụp ảnh xác nhận, Push notification |
| Sprint 5 | ⏳ Kiểm thử, Tối ưu, Hoàn thiện |

**Chú thích:** ✅ Hoàn thành | 🔄 Đang làm | ⏳ Chưa bắt đầu

---

## 11. Tài Liệu Liên Quan

- [Hướng dẫn kiến trúc chi tiết](HUONG_DAN_KIEN_TRUC.md)
- [Backend API Documentation](../BE-CloseExp/README.md)
- [Clean Architecture Guide](CLEAN_ARCHITECTURE.md)

---

## 12. Thành Viên Phát Triển

| Vai trò | Trách nhiệm |
|---------|-------------|
| Mobile Developer | Phát triển ứng dụng Flutter |
| Backend Developer | Cung cấp API endpoints |
| QA Engineer | Kiểm thử chức năng |

---

## License

MIT License - Xem file [LICENSE](LICENSE) để biết thêm chi tiết.