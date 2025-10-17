# Tính năng Diễn đàn / Mạng xã hội (Forum)

## 📋 Tổng quan

Đã hoàn thành việc xây dựng tính năng diễn đàn/mạng xã hội tại tab **"Thế Giới"** với các chức năng:

- ✅ Đăng bài viết với nhiều ảnh
- ✅ Thích bài viết (like/unlike)
- ✅ Bình luận bài viết
- ✅ Hiển thị tên và avatar người dùng realtime
- ✅ Upload ảnh lên Firebase Storage
- ✅ Firestore security rules

## 🏗️ Cấu trúc code

### Models

- **`lib/models/forum_post.dart`**
  - Class `ForumPost`: Model cho bài viết
    - `id`, `authorId`, `content`
    - `imageUrls` (List<String>): Danh sách URL ảnh
    - `likedBy` (List<String>): Danh sách userId đã thích
    - `commentCount`: Số lượng bình luận
    - `comicId` (optional): ID truyện được gắn thẻ
    - Getter `likeCount`: Tính số like
  - Class `ForumComment`: Model cho bình luận
    - `id`, `postId`, `userId`, `content`, `createdAt`

### Services

- **`lib/services/forum_service.dart`**
  - `getPosts()`: Stream danh sách posts (mới nhất)
  - `getUserPosts(userId)`: Lấy posts của một user
  - `createPost()`: Tạo post mới
  - `toggleLike()`: Like/unlike post
  - `deletePost()`: Xóa post và tất cả comments
  - `getComments(postId)`: Stream comments của post
  - `addComment()`: Thêm comment và tăng commentCount
  - `deleteComment()`: Xóa comment và giảm commentCount

### Screens

- **`lib/screens/tabs/forum_tab.dart`** (Tab chính)

  - Hiển thị feed các bài viết mới nhất
  - Pull-to-refresh
  - Nút FAB "Đăng bài"
  - Post card với:
    - Avatar + tên tác giả (realtime)
    - Thời gian đăng
    - Nội dung
    - Grid ảnh (1-9 ảnh)
    - Nút Like + Comment với số lượng
  - Xử lý hiển thị ảnh:
    - 1 ảnh: Full width
    - 2 ảnh: 2 cột
    - 3+ ảnh: Grid 2x2, có "+N" nếu >4 ảnh

- **`lib/screens/create_post_screen.dart`**

  - TextField nhập nội dung (max 1000 ký tự)
  - Nút chọn ảnh (tối đa 9 ảnh)
  - Preview ảnh dạng grid với nút xóa
  - Upload ảnh lên Firebase Storage
  - Tạo post với `ForumService.createPost()`

- **`lib/screens/post_detail_screen.dart`**
  - Hiển thị chi tiết bài viết
  - Nút Like (realtime update)
  - Section bình luận với StreamBuilder
  - Input bình luận ở bottom
  - Comment card:
    - Avatar + tên (realtime)
    - Nội dung bình luận
    - Thời gian

### Widgets

- **`lib/widgets/user_name_display.dart`** (đã có từ trước)
  - Hiển thị tên người dùng realtime từ Firestore
  - Tự động cập nhật khi user đổi tên

### Updates

- **`lib/screens/home_screen.dart`**

  - Đã thay `SimpleTab` → `ForumTab(profile: currentProfile)`
  - Tab "Thế Giới" (index 3) giờ hiển thị forum

- **`lib/models/user_profile.dart`**
  - Đã thêm static method `getProfile(userId)` để fetch profile

## 🔥 Firebase Configuration

### Firestore Collections

```
forumPosts/
  {postId}/
    - authorId: string
    - content: string (max 1000 chars)
    - imageUrls: array<string>
    - comicId: string? (optional)
    - likedBy: array<string> (userIds)
    - commentCount: number
    - createdAt: timestamp
    - updatedAt: timestamp

forumComments/
  {commentId}/
    - postId: string
    - userId: string
    - content: string (max 500 chars)
    - createdAt: timestamp
```

### Firestore Security Rules (✅ Deployed)

```javascript
// forumPosts
- Read: Public
- Create: Authenticated, own post, content valid
- Update: Own post OR only updating likedBy
- Delete: Own post only

// forumComments
- Read: Public
- Create: Authenticated, content valid
- Delete: Own comment only
```

### Storage Rules (✅ Deployed)

```javascript
match /users/{userId}/posts/{fileName} {
  allow write: if authenticated && uid == userId
               && size < 5MB
               && contentType matches 'image/.*';
  allow delete: if authenticated && uid == userId;
}
```

## 🎨 Giao diện

### Forum Feed (ForumTab)

- AppBar: "Thế Giới"
- ListView posts
- Post card:

  ```
  [Avatar] [Tên người dùng]
           [Thời gian]

  [Nội dung bài viết]

  [Grid ảnh nếu có]

  [❤️ Like] [💬 Bình luận]
  ```

- FAB: "Đăng bài"

### Create Post

- AppBar: "Tạo bài viết" + nút "Đăng"
- TextField (8 lines, max 1000)
- Nút "Thêm ảnh"
- Grid preview ảnh (3 cột) với nút X để xóa

### Post Detail

- Scrollable:
  - Header (avatar + tên + thời gian)
  - Nội dung
  - Grid ảnh (2 cột)
  - Like + Comment count
  - Divider
  - "Bình luận" header
  - ListView comments
- Bottom: Input bình luận + nút Send

## 📱 Luồng sử dụng

1. **Xem feed**

   - Vào tab "Thế Giới"
   - Scroll xem posts
   - Tap vào post → xem chi tiết

2. **Đăng bài**

   - Tap FAB "Đăng bài"
   - Nhập nội dung
   - (Optional) Thêm ảnh
   - Tap "Đăng"
   - Ảnh upload lên Storage
   - Post tạo trong Firestore
   - Quay về feed

3. **Thích bài**

   - Tap nút ❤️
   - Toggle like/unlike
   - Realtime update số lượng
   - `likedBy` array update

4. **Bình luận**
   - Tap post → vào detail
   - Scroll xuống input
   - Nhập comment
   - Tap Send
   - Comment thêm vào Firestore
   - `commentCount` tăng
   - Comment hiển thị realtime

## 🔄 Realtime Features

- **Tên người dùng**: StreamBuilder → Firestore users/{userId}
- **Danh sách posts**: StreamBuilder → forumPosts (orderBy createdAt)
- **Like count**: StreamBuilder → post document
- **Comments**: StreamBuilder → forumComments where postId

## 🚀 Hoàn tất

Tất cả tính năng đã được implement theo yêu cầu từ screenshots:

- ✅ Feed với posts, likes, comments
- ✅ Create post với text + images
- ✅ Post detail với full interactions
- ✅ Realtime updates
- ✅ Firebase integration (Firestore + Storage)
- ✅ Security rules deployed

Đã sẵn sàng sử dụng! 🎉
