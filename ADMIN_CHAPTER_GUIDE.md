# Hướng Dẫn Quản Lý Chapter (Admin)

## 📚 Cách Thêm Chapter Cho Truyện

### Bước 1: Đăng nhập bằng tài khoản Admin
- Đảm bảo bạn đã đăng nhập với tài khoản có quyền admin
- Kiểm tra trong Firestore: collection `profiles` → document có field `isAdmin: true`

### Bước 2: Vào trang chi tiết truyện
- Từ trang chủ, chọn một truyện bất kỳ
- Hoặc vào tab "Truyện" và chọn truyện muốn thêm chapter

### Bước 3: Tìm nút "Quản lý Chapter"
Admin sẽ thấy **3 cách** để vào màn hình Quản lý Chapter:

#### Cách 1: Từ Header (Thanh trên cùng)
- Nhìn lên thanh tiêu đề ở trên cùng
- Bên cạnh nút "Chỉnh sửa" (biểu tượng bút), có nút **"Quản lý Chapter"** (biểu tượng danh sách 📋)
- Nhấn vào biểu tượng danh sách này

#### Cách 2: Từ Tab "Danh sách chương" 
- Chuyển sang tab **"Danh sách chương"** (tab thứ 2)
- Ngay đầu trang sẽ có nút **màu cam** rất nổi bật:
  ```
  🛡️ QUẢN LÝ CHAPTER (ADMIN) →
  ```
- Nhấn vào nút màu cam này

#### Cách 3: Khi chưa có chapter
- Nếu truyện chưa có chapter nào
- Tab "Danh sách chương" sẽ hiển thị:
  ```
  📖 Chưa có chapter nào
  Nhấn nút "+" bên dưới để thêm chapter mới
  [Thêm Chapter Đầu Tiên]
  ```
- Nhấn vào nút **"Thêm Chapter Đầu Tiên"**

### Bước 4: Thêm Chapter Mới
Trong màn hình "Quản lý Chapter", bạn sẽ thấy:

1. **Nút Floating (Nút tròn màu xanh) ở góc dưới bên phải:**
   ```
   ➕ Thêm Chapter
   ```
   - Nhấn vào đây để tạo chapter mới

2. **Hoặc nếu chưa có chapter:**
   - Màn hình sẽ hiển thị gợi ý thêm chapter đầu tiên
   - Nhấn vào nút lớn ở giữa màn hình

### Bước 5: Điền thông tin Chapter
Trong màn hình "Chỉnh sửa Chapter", điền các thông tin:

- **Tiêu đề Chapter**: Ví dụ "Chapter 1", "Chương 1"
- **Thứ tự**: Số thứ tự của chapter (1, 2, 3,...)
- **VIP Required**: Mức VIP cần thiết để đọc (0 = FREE, 1-3 = VIP)
- **Thêm trang ảnh**: URL của từng trang truyện

### Bước 6: Lưu Chapter
- Nhấn nút **"Lưu"** ở góc trên bên phải
- Chapter sẽ được thêm vào database
- Quay lại màn hình quản lý để kiểm tra

## 🔍 Kiểm Tra Quyền Admin

Nếu không thấy các nút admin, kiểm tra:

### Trong Firestore Console:
```
Collection: profiles
Document ID: <user_id>
Fields:
  ├── isAdmin: true  ← Phải có field này và = true
  ├── vipLevel: 3
  └── ...
```

### Trong Code:
```dart
// Trong UserProfile model
class UserProfile {
  final bool isAdmin;  // Phải có field này
  ...
}
```

## 📝 Các Tính Năng Quản Lý Chapter

### 1. Xem Danh Sách Chapter
- Hiển thị tất cả chapter theo thứ tự giảm dần
- Mỗi chapter hiển thị:
  - Nhãn FREE/VIP
  - Số thứ tự
  - Tiêu đề
  - Ngày phát hành
  - Số trang

### 2. Chỉnh Sửa Chapter
- Nhấn vào icon ⋮ (3 chấm) bên phải mỗi chapter
- Chọn "Chỉnh sửa"
- Cập nhật thông tin và lưu

### 3. Xóa Chapter
- Nhấn vào icon ⋮ (3 chấm) bên phải mỗi chapter
- Chọn "Xóa"
- Xác nhận xóa

## 🎯 Tips

1. **Thứ tự Chapter**: Nên đặt số thứ tự liên tục (1, 2, 3,...) để dễ quản lý
2. **VIP Level**: 
   - 0 = Miễn phí cho tất cả
   - 1-3 = Yêu cầu VIP tương ứng
3. **URL Ảnh**: Sử dụng Firebase Storage hoặc URL hợp lệ
4. **Release Date**: Có thể đặt ngày phát hành trong tương lai

## ❓ Troubleshooting

### Không thấy nút Admin?
✅ Kiểm tra field `isAdmin: true` trong Firestore
✅ Đăng xuất và đăng nhập lại
✅ Restart ứng dụng

### Không thêm được chapter?
✅ Kiểm tra quyền Firestore Rules
✅ Kiểm tra kết nối internet
✅ Xem log console để biết lỗi chi tiết

### Chapter không hiển thị?
✅ Kiểm tra field `order` đã điền chưa
✅ Kiểm tra `comicId` có đúng không
✅ Refresh lại trang chi tiết truyện
