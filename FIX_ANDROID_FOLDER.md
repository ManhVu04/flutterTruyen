# Fix Android Folder Hiển Thị Đỏ Trong VS Code

## Nguyên nhân:
Thư mục `android` hiển thị màu đỏ với số `2` thường do:
1. **Git tracking issues** - Có 2 files chưa được track hoặc có thay đổi
2. **Gradle cache cũ** - `.gradle` và `.kotlin` folders bị corrupt
3. **IntelliJ/Android Studio project files** - File `.iml` bị lỗi

## Giải pháp:

### Bước 1: Clean Flutter Project
```bash
flutter clean
flutter pub get
```

### Bước 2: Xóa Android Build Cache
```bash
# Trong thư mục android/
rm -rf .gradle
rm -rf .kotlin
rm -rf build
rm -rf app/build
```

### Bước 3: Xóa IntelliJ Project Files
```bash
rm android/*.iml
rm -rf .idea/
```

### Bước 4: Rebuild Project
```bash
flutter build apk --debug
# Hoặc
flutter run
```

### Bước 5: Kiểm Tra Git Status
```bash
git status android/
```

Nếu có files untracked, hãy:
- **Commit** nếu cần thiết
- Hoặc **add vào .gitignore** nếu là build artifacts

## Lưu ý:
- Màu đỏ với số `2` không ảnh hưởng đến functionality của app
- Chỉ là vấn đề hiển thị trong VS Code Source Control
- Nếu app vẫn chạy bình thường, có thể bỏ qua

## Quick Fix Command:
```powershell
# PowerShell - Chạy từ root folder
flutter clean
Remove-Item -Recurse -Force android\.gradle, android\.kotlin, android\build -ErrorAction SilentlyContinue
flutter pub get
flutter run
```

## Kiểm tra lại:
- Reload VS Code Window: `Ctrl+Shift+P` → "Developer: Reload Window"
- Kiểm tra `.gitignore` có đúng config không
- Đảm bảo `android/local.properties` được ignore
