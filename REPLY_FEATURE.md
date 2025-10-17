# Tính năng Reply (Trả lời) Comments

## ✅ Đã thêm

Hệ thống reply cho phép người dùng trả lời các bình luận trong bài viết forum.

## 🔧 Thay đổi

### 1. Model - ForumComment

**File:** `lib/models/forum_post.dart`

Thêm fields mới:

```dart
class ForumComment {
  final String? parentCommentId;  // ID comment cha (null = root comment)
  final String? replyToUserId;    // ID user được reply
  final int replyCount;            // Số lượng replies

  bool get isReply => parentCommentId != null;
}
```

### 2. Service - ForumService

**File:** `lib/services/forum_service.dart`

#### addComment() - Updated

```dart
static Future<void> addComment({
  required String postId,
  required String userId,
  required String content,
  String? parentCommentId,  // NEW: null = root comment
  String? replyToUserId,    // NEW: user được reply
})
```

#### getReplies() - New method

```dart
static Stream<List<ForumComment>> getReplies(String parentCommentId)
// Lấy tất cả replies của một comment
```

#### deleteComment() - Updated

```dart
// Xóa comment + tất cả replies
// Update replyCount của parent nếu là reply
// Update commentCount của post
```

### 3. UI - PostDetailScreen

**File:** `lib/screens/post_detail_screen.dart`

#### State variables

```dart
String? _replyToCommentId;
String? _replyToUserId;
String? _replyToUserName;
```

#### New methods

```dart
void _setReplyMode({...})  // Bật chế độ reply
void _cancelReply()         // Hủy reply mode
```

#### Comment filtering

```dart
// Chỉ hiển thị root comments (không có parentCommentId)
final rootComments = allComments
    .where((c) => c.parentCommentId == null)
    .toList();
```

#### Reply indicator UI

```dart
// Hiển thị banner "Trả lời [UserName]" khi reply mode
if (_replyToUserName != null)
  Container(
    color: Colors.blue.shade50,
    child: Row([Icon(reply), Text("Trả lời..."), IconButton(close)])
  )
```

### 4. Components

#### \_CommentCard - Updated to StatefulWidget

```dart
class _CommentCard extends StatefulWidget {
  final VoidCallback onReply;     // Callback khi tap "Trả lời"
  final String currentUserId;

  bool _showReplies = false;      // Toggle hiển thị replies
}
```

**Features:**

- Nút "Trả lời" dưới mỗi comment
- Nút "Xem N trả lời" / "Ẩn N trả lời" nếu có replies
- StreamBuilder để load replies realtime

#### \_ReplyCard - New component

```dart
class _ReplyCard extends StatelessWidget {
  // Hiển thị reply với:
  // - Avatar nhỏ hơn (radius: 14)
  // - Background nhạt hơn (grey[100])
  // - Indent từ bên trái (padding left: 46)
  // - Font size nhỏ hơn
}
```

### 5. Firestore Rules

**File:** `firestore.rules`

```javascript
match /forumComments/{commentId} {
  allow read: if true;

  allow create: if request.auth != null
                && request.resource.data.userId == request.auth.uid
                && content valid;

  // NEW: Allow updating replyCount
  allow update: if request.auth != null
                && request.resource.data.diff(resource.data)
                   .affectedKeys().hasOnly(['replyCount']);

  allow delete: if own comment;
}
```

## 📊 Data Structure

### Root Comment

```json
{
  "id": "comment123",
  "postId": "post456",
  "userId": "user789",
  "content": "Bình luận gốc",
  "parentCommentId": null,        // NULL = root
  "replyToUserId": null,
  "replyCount": 2,                // Có 2 replies
  "createdAt": timestamp
}
```

### Reply

```json
{
  "id": "reply123",
  "postId": "post456",
  "userId": "user111",
  "content": "Trả lời comment",
  "parentCommentId": "comment123", // ID của comment cha
  "replyToUserId": "user789",      // User được reply
  "replyCount": 0,                 // Replies không có sub-replies
  "createdAt": timestamp
}
```

## 🎯 Luồng hoạt động

### 1. Bình luận thường (Root comment)

```
User nhập text → Tap Send
→ addComment(postId, userId, content)
→ Firestore: forumComments.add({
    parentCommentId: null,
    replyCount: 0
  })
→ post.commentCount++
```

### 2. Trả lời comment

```
User tap "Trả lời" trên comment
→ _setReplyMode(commentId, userId, userName)
→ Hiển thị banner "Trả lời [UserName]"
→ User nhập text → Tap Send
→ addComment(postId, userId, content,
    parentCommentId: commentId,
    replyToUserId: userId)
→ Firestore: forumComments.add({
    parentCommentId: commentId,
    replyToUserId: userId
  })
→ parent.replyCount++
→ post.commentCount++
→ _cancelReply()
```

### 3. Xem replies

```
User tap "Xem N trả lời"
→ _showReplies = true
→ StreamBuilder: getReplies(commentId)
→ Query: where('parentCommentId', '==', commentId)
→ Hiển thị list replies với indent
```

### 4. Xóa comment có replies

```
User xóa comment
→ deleteComment(commentId, postId, parentCommentId)
→ Query all replies: where('parentCommentId', '==', commentId)
→ Delete all replies
→ Delete comment
→ parent.replyCount-- (nếu là reply)
→ post.commentCount -= (1 + replyCount)
```

## 🎨 UI/UX Features

### Comment Card

- ✅ Avatar (18px radius)
- ✅ Username (bold)
- ✅ Content
- ✅ Timestamp (bodySmall)
- ✅ "Trả lời" button (primary color)
- ✅ "Xem N trả lời" button (nếu replyCount > 0)

### Reply Card

- ✅ Indent left 46px
- ✅ Smaller avatar (14px radius)
- ✅ Lighter background (grey[100])
- ✅ Smaller font (fontSize: 14)
- ✅ Smaller timestamp (fontSize: 11)

### Reply Indicator (Input bar)

- ✅ Blue background (blue.shade50)
- ✅ Reply icon
- ✅ Text "Trả lời [UserName]"
- ✅ Close button (X)
- ✅ Placeholder text: "Viết câu trả lời..."

## 🔍 Debug logs

```dart
print('💬 Adding comment to postId: $postId');
print('   parentCommentId: $parentCommentId');  // null hoặc ID
print('✅ Comment added with ID: ${docRef.id}');
print('✅ Reply count updated for parent comment: $parentCommentId');
```

## ✅ Hoàn thành

Tất cả tính năng reply đã được implement:

- ✅ Reply comments
- ✅ Hiển thị replies dưới comment gốc
- ✅ Đếm số replies
- ✅ Toggle show/hide replies
- ✅ Reply indicator UI
- ✅ Nested display (indent)
- ✅ Xóa comment cascade (xóa cả replies)
- ✅ Firestore rules updated
- ✅ No compile errors

Sẵn sàng test! 🚀
