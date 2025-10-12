# Hướng dẫn sử dụng giao diện Truyện

## Các tính năng đã được thêm vào

### 1. Trang chủ Truyện (HomeComicsTab)
- **Banner lớn**: Hiển thị truyện nổi bật với hình ảnh đẹp
- **4 nút danh mục**: Thể Loại, Top User, Mới nhất, Sáng Tác (với gradient màu sắc đẹp)
- **2 phần truyện**:
  - Khuyến khích đọc 🔥 (sắp xếp theo rating)
  - Truyện mới cập nhật (sắp xếp theo thời gian)
- Cuộn ngang để xem danh sách truyện

### 2. Trang danh sách truyện (ComicListScreen)
- **3 tabs**: Tất cả, Đang ra, Hoàn thành
- **Sắp xếp theo**: Ngày cập nhật, Lượt xem, Đánh giá
- **Lọc theo thể loại**: Nhiều thể loại như Cổ Đại, Hiện đại, Huyền Huyễn, v.v.
- **Hiển thị dạng lưới**: 3 cột với hình ảnh bìa, tiêu đề, lượt xem
- **Badge VIP**: Hiển thị truyện cần VIP để đọc

### 3. Trang chi tiết truyện (ComicDetailScreen)
- **Header**:
  - Ảnh bìa lớn
  - Tiêu đề, tags
  - Lượt xem và lượt thích
  - Nút Lưu và Chia sẻ
- **2 tabs**:
  - **Giới thiệu**: Mô tả truyện, đánh giá chi tiết
  - **Danh sách chương**: Tất cả các chapter
- **Đánh giá**:
  - Điểm trung bình với sao
  - Biểu đồ phân bố đánh giá (5 sao -> 1 sao)
  - Các tag đánh giá (Cực phẩm, Đáng đọc, v.v.)
- **Danh sách chapter**:
  - Badge FREE hoặc VIP cho mỗi chapter
  - Thời gian cập nhật
  - Lock icon nếu cần VIP cao hơn
  - Nút lọc theo khoảng chapter (0-50, 50-100, v.v.)
- **Nút đọc chapter**: Ở cuối trang, dẫn đến chapter đầu tiên

### 4. Trang đọc truyện (ChapterReaderScreen)
- **Nền đen**: Dễ đọc cho mắt
- **Cuộn dọc**: Xem tất cả trang trong chapter
- **Ẩn/hiện thanh điều hướng**: Tap vào màn hình để toggle
- **Nút Previous/Next**: Chuyển sang chapter trước/sau
- **Nút danh sách chapter**: Mở modal để chọn chapter khác
- **Loading indicator**: Hiển thị khi đang tải hình
- **Error handling**: Hiển thị icon khi không tải được hình

## Cách sử dụng

### Xem danh sách truyện
1. Mở app và đăng nhập
2. Nhấn vào tab "Truyện" ở bottom navigation
3. Cuộn xuống để xem các phần khác nhau
4. Nhấn vào bất kỳ truyện nào để xem chi tiết

### Xem chi tiết truyện
1. Từ trang danh sách, nhấn vào một truyện
2. Xem thông tin, đánh giá trong tab "Giới thiệu"
3. Chuyển sang tab "Danh sách chương" để xem các chapter
4. Nhấn vào chapter để đọc (nếu có quyền)
5. Nhấn nút "ĐỌC CHAPTER X" ở cuối trang để bắt đầu đọc

### Đọc truyện
1. Cuộn xuống để xem các trang tiếp theo
2. Tap vào màn hình để ẩn/hiện thanh điều hướng
3. Nhấn "Tiếp" để sang chapter tiếp theo
4. Nhấn "Trước" để quay lại chapter trước
5. Nhấn icon danh sách để chọn chapter khác

### Lọc và sắp xếp
1. Trong trang danh sách, nhấn icon filter ở góc trên
2. Chọn các thể loại muốn lọc
3. Nhấn OK để áp dụng
4. Sử dụng các chip "Ngày cập nhật", "Lượt xem", "Đánh giá" để sắp xếp

## Yêu cầu VIP

- Một số chapter có badge "VIP" và yêu cầu VIP level nhất định
- Nếu VIP level của bạn không đủ, sẽ hiện thông báo khi cố đọc
- Badge "FREE" cho các chapter miễn phí

## Ghi chú kỹ thuật

### Các file đã tạo/sửa:
1. `lib/screens/comic_list_screen.dart` - Trang danh sách truyện
2. `lib/screens/comic_detail_screen.dart` - Trang chi tiết truyện
3. `lib/screens/chapter_reader_screen.dart` - Trang đọc truyện
4. `lib/screens/tabs/home_comics_tab.dart` - Tab trang chủ với banner
5. `lib/screens/tabs/comics_tab.dart` - Wrapper cho comics tab
6. `pubspec.yaml` - Thêm package `intl` cho định dạng ngày tháng

### Packages mới:
- `intl: ^0.19.0` - Định dạng ngày tháng (DD/MM/YYYY HH:mm)

### Tính năng nổi bật:
- Responsive UI với GridView và ListView
- Stream realtime từ Firestore
- Image loading với placeholder và error handling
- VIP system integration
- Filter và sort functionality
- Tab navigation
- Modal bottom sheets
- Navigation giữa các màn hình
- Gradient backgrounds và styled buttons
