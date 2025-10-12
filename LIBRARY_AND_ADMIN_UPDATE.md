# Cập nhật Giao diện Tủ sách và Quản lý Truyện

## 📚 Tủ sách (Library Tab)

### Tính năng mới:
- **3 Tab phân loại:**
  - **Theo dõi**: Hiển thị truyện đã follow/yêu thích
  - **Vừa xem**: Lịch sử đọc truyện gần đây
  - **Đã tải**: Truyện đã tải về (chưa implement đầy đủ)

- **Nút Đồng bộ**: Ở mỗi tab để đồng bộ dữ liệu
- **Nút Xóa**: Ở tab "Đã tải" để xóa truyện đã tải (floating action button màu đỏ)
- **Hiển thị dạng Grid**: Truyện được hiển thị dạng lưới 2 cột
- **Thông tin chapter**: Hiển thị chapter vừa đọc

### Giao diện:
```
┌─────────────────────────────────────┐
│ [Theo dõi] [Vừa xem] [Đã tải]      │
├─────────────────────────────────────┤
│ [🔄 Đồng bộ]                    [🗑️] │
│                                      │
│  ┌────┐  ┌────┐                     │
│  │img │  │img │                     │
│  │    │  │    │                     │
│  └────┘  └────┘                     │
│  Truyện 1  Truyện 2                 │
│  Ch 5      Ch 10                    │
└─────────────────────────────────────┘
```

## 🎮 Quản lý Truyện (Admin)

### Tính năng:
1. **Tìm kiếm truyện**: Tìm theo tên
2. **Lọc theo trạng thái**:
   - Tất cả
   - Ongoing
   - Completed
   - Hiatus
3. **Hiển thị danh sách**: 
   - Ảnh bìa
   - Tên truyện
   - Lượt xem
   - Đánh giá
   - Trạng thái
4. **Menu hành động**:
   - Chỉnh sửa truyện
   - Xóa truyện

### Truy cập:
Admin có thể truy cập qua tab **Tôi** (Profile):
- **Nút "Thêm truyện mới"** (màu xanh lá): Tạo truyện mới
- **Nút "Quản lý truyện"** (màu xanh dương): Quản lý tất cả truyện

### Giao diện:
```
┌─────────────────────────────────────┐
│ ← Quản lý truyện                [+] │
├─────────────────────────────────────┤
│ 🔍 [Tìm kiếm truyện...        ] ❌  │
│ [Tất cả] [Ongoing] [Completed]     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────┐    │
│ │ 📷  Tên truyện              ⋮ │    │
│ │     👁 1000  ⭐ 4.5           │    │
│ │     [ongoing]                 │    │
│ └─────────────────────────────┘    │
│ ┌─────────────────────────────┐    │
│ │ 📷  Tên truyện khác         ⋮ │    │
│ │     👁 2000  ⭐ 4.8           │    │
│ │     [completed]               │    │
│ └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

## 📱 Cách sử dụng

### Đối với người dùng thường:
1. Vào tab **Tủ sách** (biểu tượng sách)
2. Chọn tab phù hợp:
   - **Theo dõi**: Xem truyện đang follow
   - **Vừa xem**: Xem lịch sử đọc
   - **Đã tải**: Xem truyện đã tải về
3. Nhấn **Đồng bộ** để cập nhật dữ liệu
4. Ở tab "Đã tải", nhấn nút **🗑️** để xóa truyện

### Đối với Admin:
1. Đăng nhập bằng tài khoản admin
2. Vào tab **Tôi**
3. Chọn:
   - **Thêm truyện mới**: Để upload truyện mới
   - **Quản lý truyện**: Để quản lý tất cả truyện
4. Trong màn hình Quản lý truyện:
   - Tìm kiếm truyện bằng ô tìm kiếm
   - Lọc theo trạng thái bằng các chip filter
   - Nhấn vào truyện để chỉnh sửa
   - Nhấn menu ⋮ để xem thêm tùy chọn

## 🔧 Files đã thay đổi

### Mới tạo:
- `lib/screens/admin_manage_comics_screen.dart` - Màn hình quản lý truyện

### Đã chỉnh sửa:
- `lib/screens/tabs/library_tab.dart` - Thêm tab và nút đồng bộ/xóa
- `lib/screens/home_screen.dart` - Thêm nút quản lý truyện cho admin

## ✨ Tính năng cần hoàn thiện

### Tủ sách:
- [ ] Kết nối với dữ liệu thực từ Firebase
- [ ] Hiển thị ảnh bìa truyện thực
- [ ] Implement chức năng đồng bộ thực tế
- [ ] Implement chức năng tải truyện
- [ ] Implement chức năng xóa truyện đã tải

### Quản lý truyện:
- [x] Tìm kiếm truyện
- [x] Lọc theo trạng thái
- [x] Chỉnh sửa truyện
- [x] Xóa truyện
- [ ] Thêm lọc theo thể loại
- [ ] Thêm sắp xếp (theo tên, ngày, lượt xem)
- [ ] Thêm xuất báo cáo

## 🎨 Design Pattern

### Tủ sách:
- Sử dụng `TabController` để quản lý 3 tab
- Grid layout 2 cột cho danh sách truyện
- Floating action button cho nút xóa

### Quản lý truyện:
- StreamBuilder để real-time update từ Firestore
- Filter và search local để tối ưu performance
- Card layout cho mỗi truyện
- PopupMenu cho các action

## 📝 Notes

- Giao diện đã được tối ưu cho mobile
- Tất cả text đã được Việt hóa
- Màu sắc tuân theo Material Design 3
- Responsive với các kích thước màn hình khác nhau
