# RecipeBox - PRM393 Practical Exam (FALL 2026)

Ứng dụng quản lý công thức nấu ăn cá nhân **RecipeBox** được xây dựng bằng **Flutter & Android Studio**, tích hợp **Firebase Authentication** và **Cloud Firestore** theo đúng 100% yêu cầu đề thi PRM393.

---

## 1. Cấu trúc thư mục mã nguồn

```
PE_PRM393_FA26/
├── android/                   # Cấu hình Android native (minSdk 23, permissions)
├── lib/
│   ├── firebase_options.dart  # Client-side Firebase configuration
│   ├── main.dart              # Entry point, AuthGate (auto check login), Theme
│   ├── models/
│   │   └── recipe.dart        # Model Recipe với validation và Firestore mapping
│   ├── screens/
│   │   ├── home_screen.dart   # Màn hình Home (public): 3 feature cards, Login, Register
│   │   ├── login_screen.dart  # Màn hình Login: validation rules, Firebase error handling
│   │   ├── register_screen.dart # Màn hình Register: validation rules, "Registration successful"
│   │   ├── list_screen.dart   # Màn hình List (protected): Add recipe, Filter, Search, Summary, List
│   │   └── detail_screen.dart # Màn hình Detail: View mode, Edit mode (Save/Cancel), Delete dialog
│   ├── services/
│   │   ├── auth_service.dart  # Firebase Auth service (Sign in, Sign up, Sign out)
│   │   └── recipe_service.dart# Firestore CRUD, sort cookTime & name, unique name per user
│   └── widgets/
│       ├── custom_text_field.dart # Component TextField tái sử dụng với error text
│       ├── recipe_card.dart       # Card hiển thị công thức với star toggle
│       └── summary_card.dart      # Thống kê Recipes, Favorites, Total time, Category breakdown
├── firestore.rules            # Security Rules kiểm soát quyền và từ chối bad data
├── pubspec.yaml               # Cấu hình dependencies
├── StudentReport_Template.docx# File mẫu Word báo cáo có sẵn khung 16 ảnh chụp
└── package_submission.py      # Script tự động đóng gói file nộp bài <StudentCode>.zip
```

---

## 2. Hướng dẫn thiết lập Firebase

### Bước 2.1: Tạo Firebase Project
1. Truy cập [Firebase Console](https://console.firebase.google.com/) và tạo một project mới (ví dụ: `recipebox-qe200012`).
2. Tắt Google Analytics (không bắt buộc).

### Bước 2.2: Bật Email/Password Authentication
1. Vào **Build → Authentication → Get started**.
2. Chọn tab **Sign-in method** → Bật **Email/Password** (Email link để tắt).
3. Chuyển sang tab **Users** → Bấm **Add user** để tạo tài khoản test cho giám khảo (ví dụ: `grader.qe200012@example.com` / `Test1234!`).

### Bước 2.3: Tạo Cloud Firestore Database
1. Vào **Build → Firestore Database → Create database**.
2. Chọn location (ví dụ `asia-southeast1` hoặc `nam5`), chọn chế độ **Start in production mode**.
3. Chuyển sang tab **Rules**, dán toàn bộ nội dung từ file [firestore.rules](file:///d:/PE_PRM393_FA26/firestore.rules) vào và bấm **Publish**.

### Bước 2.4: Kết nối ứng dụng với Firebase
Có 2 cách:
- **Cách 1 (Khuyến nghị - FlutterFire CLI):** Chạy lệnh:
  ```bash
  flutterfire configure
  ```
  Lệnh sẽ tự động cập nhật file `lib/firebase_options.dart` và tải cấu hình cho Android.
- **Cách 2 (Thủ công):** Thêm Android App vào Firebase Console với package name `com.example.recipe_box`, tải file `google-services.json` đặt vào thư mục `android/app/`, đồng thời cập nhật các thông số API Key trong `lib/firebase_options.dart`.

---

## 3. Chạy ứng dụng trên Android Studio hoặc Terminal

1. **Mở dự án:**
   - Khởi động Android Studio → Chọn **Open** → Chọn thư mục `D:\PE_PRM393_FA26`.
2. **Cài đặt thư viện:**
   ```bash
   flutter pub get
   ```
3. **Khởi chạy thiết bị / Emulator:**
   - Chọn thiết bị Pixel Emulator hoặc điện thoại Android thật cắm cáp USB.
4. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

---

## 4. Danh sách 16 ảnh chụp màn hình cần nộp (Bắt buộc)

Chụp từ thiết bị thật hoặc máy ảo đăng nhập bằng tài khoản test của bạn:

1. **Firebase console — Authentication**: Danh sách Users hiển thị tài khoản test của giám khảo.
2. **Firebase console — Firestore data**: Collection `recipes` có ít nhất 3 documents thuộc tài khoản test.
3. **Firebase console — Security Rules**: Tab Rules trên Firebase Console hiển thị các rules đã Publish.
4. **Register screen — validation**: Bấm Register khi form rỗng hiển thị đủ các lỗi đỏ dưới từng ô.
5. **Register screen — success**: Ngay sau khi đăng ký thành công hiển thị chữ `Registration successful`.
6. **Login screen**: Form đăng nhập rỗng.
7. **List screen — after login**: Hiển thị email của user, nút Logout và ít nhất 3 công thức đã có trong list.
8. **Add Recipe form — validation**: Submit form thêm công thức khi rỗng hoặc nhập sai, hiển thị các câu thông báo lỗi.
9. **Add Recipe form — success**: Ngay sau khi thêm thành công, hiển thị `Recipe added` và công thức mới xuất hiện trong list.
10. **Filters and search**: Các bộ lọc Category, Difficulty, Favorites only và Search box hoạt động lọc tức thì.
11. **Summary**: Thống kê Recipes: N, Favorites: N, Total time: N min và Category breakdown.
12. **Detail screen — view mode**: Xem chi tiết 1 công thức (name, category, difficulty, cook time, servings, notes).
13. **Detail screen — edit mode, validation**: Sửa công thức và submit thông tin sai hiển thị lỗi.
14. **Detail screen — after Save**: Công thức sau khi Save lưu thành công giá trị mới.
15. **Favorite toggle and Delete**: Cặp ảnh trước/sau khi đổi ngôi sao Favorite, và xóa công thức (sau xác nhận Delete) biến mất khỏi list.
16. **Empty state**: List screen hiển thị chữ `No recipes found` (dùng tài khoản mới tinh chưa thêm công thức).

---

## 5. Hướng dẫn đóng gói và nộp bài

### Bước 1: Build file APK Release
Chạy lệnh:
```bash
flutter build apk --release
```
File APK sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`.
Tải file này lên GitHub Release hoặc Google Drive (để chế độ công khai bất kỳ ai có link đều tải được).

### Bước 2: Điền thông tin vào báo cáo
Mở file `StudentReport_Template.docx`, điền thông tin MSSV, họ tên, link GitHub, link APK, thông tin Firebase test account và chèn 16 ảnh đã chụp vào các khung tương ứng. Đổi tên thành `<StudentCode>.docx` (Ví dụ: `QE200012.docx`).

### Bước 3: Đóng gói source code
Chạy lệnh Python:
```bash
python package_submission.py <MSSV_CỦA_BẠN>
# Ví dụ: python package_submission.py QE200012
```
Script sẽ tự động tạo file `<StudentCode>.zip` chứa đầy đủ mã nguồn chuẩn, loại bỏ các file rác build/.
Đặt cả 2 file `<StudentCode>.docx` và `<StudentCode>.zip` vào cùng 1 thư mục để nộp.
