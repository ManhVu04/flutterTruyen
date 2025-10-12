# Tính Năng Quản Trị (Admin Features)

## Tổng Quan
Hệ thống quản trị cho phép admin chỉnh sửa toàn bộ chi tiết truyện và quản lý chapters một cách dễ dàng.

## Các Tính Năng Chính

### 1. Chỉnh Sửa Chi Tiết Truyện
**Màn hình:** `AdminEditComicScreen`

Admin có thể chỉnh sửa mọi thông tin của truyện:

#### Thông tin cơ bản:
- ✏️ **Tiêu đề**: Tên truyện
- 📝 **Mô tả**: Giới thiệu chi tiết về truyện
- 🖼️ **Ảnh bìa**: URL ảnh bìa (có preview trực tiếp)

#### Thể loại:
Chọn nhiều thể loại từ danh sách có sẵn:
- Cổ Đại, Hiện đại
- Huyền Huyễn, Hai Hước
- Hàn Quốc, Hậu Cung
- Hệ Thống, Kinh Dị
- Lịch Sử, Mạt Thế
- Ngôn Tình, Thanh xuân - Vườn trường
- Trùng Sinh, Trong sinh
- Truyện Sáng Tác, Tu Tiên
- Xuyên Không, Đô Thị

#### Trạng thái & Thống kê:
- 📊 **Trạng thái**: ongoing/completed/hiatus
- ⭐ **VIP Tier**: Mức VIP cần thiết
- 👁️ **Lượt xem**: Số lượt xem
- 🌟 **Đánh giá**: Rating (0.0 - 5.0)

**Cách sử dụng:**
1. Vào trang chi tiết truyện
2. Nhấn nút **Edit** (biểu tượng bút) trên thanh AppBar
3. Chỉnh sửa thông tin
4. Nhấn **Lưu thay đổi**

---

### 2. Quản Lý Chapters
**Màn hình:** `AdminManageChaptersScreen`

Quản lý toàn bộ chapters của truyện với giao diện trực quan.

#### Tính năng:
- 📋 **Danh sách chapters**: Hiển thị tất cả chapters theo thứ tự
- ➕ **Thêm chapter mới**: Tạo chapter với đầy đủ thông tin
- ✏️ **Chỉnh sửa chapter**: Sửa tiêu đề, thứ tự, VIP level, trang
- 🗑️ **Xóa chapter**: Xóa chapter (có xác nhận)

#### Thông tin hiển thị:
- Thứ tự chapter
- Badge FREE/VIP
- Tiêu đề
- Ngày phát hành
- Số lượng trang

**Cách sử dụng:**
1. Vào trang chi tiết truyện
2. Chuyển sang tab **Danh sách chương**
3. Nhấn nút **Quản lý Chapter**
4. Chọn hành động:
   - Nhấn **+** để thêm mới
   - Nhấn menu **⋮** trên mỗi chapter để chỉnh sửa/xóa

---

### 3. Thêm/Chỉnh Sửa Chapter
**Màn hình:** `AdminEditChapterScreen`

Màn hình chi tiết để thêm hoặc chỉnh sửa chapter.

#### Các trường thông tin:
- 📖 **Tiêu đề chapter**: Tên chapter (bắt buộc)
- 🔢 **Thứ tự**: Số thứ tự chapter (bắt buộc)
- ⭐ **VIP Required**: Mức VIP cần thiết (0 = Free)
- 🖼️ **Danh sách trang**: URL các trang (mỗi URL 1 dòng)

**Ví dụ danh sách trang:**
```
https://example.com/manga/page1.jpg
https://example.com/manga/page2.jpg
https://example.com/manga/page3.jpg
```

**Cách sử dụng:**
1. Từ màn hình **Quản lý Chapter**
2. Nhấn **Thêm Chapter** hoặc **Edit** trên chapter
3. Điền đầy đủ thông tin
4. Nhấn **Lưu Chapter**

---

## Firestore Service Updates

Đã thêm các phương thức mới trong `FirestoreService`:

### Comic Management:
```dart
// Cập nhật thông tin truyện
Future<void> updateComic(Comic comic)

// Xóa truyện
Future<void> deleteComic(String comicId)
```

### Chapter Management:
```dart
// Cập nhật chapter
Future<void> updateChapter({
  required String comicId,
  required String chapterId,
  required ChapterMeta chapter,
})

// Xóa chapter
Future<void> deleteChapter({
  required String comicId,
  required String chapterId,
})
```

---

## Bảo Mật

- ✅ Chỉ user có `isAdmin = true` mới thấy và sử dụng được các tính năng admin
- ✅ Nút chỉnh sửa chỉ hiển thị cho admin
- ✅ Xác nhận trước khi xóa để tránh xóa nhầm

---

## Giao Diện

### Màn hình Chỉnh Sửa Truyện:
- 📱 Layout phân section rõ ràng
- 🎨 Form đẹp với icons và helper text
- 👁️ Preview ảnh bìa ngay trong form
- 🏷️ Chọn thể loại bằng FilterChip
- 💾 Floating Action Button để lưu nhanh

### Màn hình Quản Lý Chapter:
- 📋 ListView với Card cho mỗi chapter
- 🎯 Badge màu sắc phân biệt FREE/VIP
- ⚙️ Menu context cho từng chapter
- ➕ FAB để thêm chapter mới

### Màn hình Thêm/Sửa Chapter:
- 📝 Form validation đầy đủ
- 🔢 Input type phù hợp cho từng trường
- ℹ️ Helper text hướng dẫn rõ ràng
- ✅ Nút lưu với loading state

---

## Workflow Hoàn Chỉnh

### Thêm Truyện Mới (Quy trình cũ):
1. Vào màn hình **Admin Upload**
2. Điền thông tin truyện + chapter đầu tiên
3. Nhấn **Lưu truyện**

### Chỉnh Sửa Truyện (Quy trình mới):
1. Tìm truyện trong danh sách
2. Vào trang **Chi tiết truyện**
3. Nhấn nút **Edit** (icon bút)
4. Chỉnh sửa bất kỳ thông tin nào
5. Nhấn **Lưu thay đổi**

### Quản Lý Chapters (Quy trình mới):
1. Vào trang **Chi tiết truyện**
2. Tab **Danh sách chương**
3. Nhấn **Quản lý Chapter**
4. Thêm/Sửa/Xóa chapters tùy ý

---

## Screenshots Location

Các màn hình mới:
- `lib/screens/admin_edit_comic_screen.dart`
- `lib/screens/admin_manage_chapters_screen.dart`
- `lib/screens/admin_edit_chapter_screen.dart`

---

## Testing

Để test các tính năng admin:

1. Đảm bảo user có `isAdmin = true` trong Firestore:
```json
{
  "users": {
    "userId": {
      "isAdmin": true,
      "displayName": "Admin",
      ...
    }
  }
}
```

2. Đăng nhập với tài khoản admin
3. Vào bất kỳ truyện nào để thấy các nút admin
4. Test đầy đủ các chức năng: thêm, sửa, xóa

---

## Future Enhancements

Có thể mở rộng thêm:
- 📊 Dashboard thống kê cho admin
- 👥 Quản lý users
- 💬 Quản lý comments/reviews
- 📈 Analytics chi tiết
- 🔔 Push notifications
- 🖼️ Upload ảnh trực tiếp thay vì URL
- 📤 Bulk upload chapters
