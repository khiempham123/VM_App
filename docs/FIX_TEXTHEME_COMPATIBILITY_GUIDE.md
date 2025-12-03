# Hướng Dẫn Khắc Phục Lỗi "subtitle1 Isn't Defined for TextTheme"

## 🔴 Lỗi Được Báo Cáo

```
Error: The getter 'subtitle1' isn't defined for the type 'TextTheme'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'subtitle1'.
```

**Vị trí lỗi:**
```
floating_search_app_bar.dart:645:45
? style.queryStyle ?? textTheme.subtitle1
                                ^^^^^^^^^
```

---

## 🔍 Nguyên Nhân Lỗi

### **1. Thay Đổi TextTheme Giữa Phiên Bản Flutter**

**Flutter 3.0 trở về trước:**
- TextTheme có các properties: `headline1`, `headline2`, `headline3`, `headline4`, `headline5`, `headline6`, `subtitle1`, `subtitle2`, `body1`, `body2`, v.v.

**Flutter 3.0 trở đi:**
- TextTheme đã **loại bỏ** các properties này
- Thay thế bằng: `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`

**Mapping Chính:**
```
Old Name         → New Name
headline6        → titleLarge
subtitle1        → bodyMedium
subtitle2        → bodySmall
body1            → bodyLarge
body2            → bodyMedium
```

---

### **2. Phiên Bản Flutter & Package Material Floating Search Bar Không Tương Thích**

**Project của bạn đang dùng:**
- FVM version: **3.19.0** (theo error message)
- Package: `material_floating_search_bar-0.3.7` (package này cũ, support Flutter < 3.0)

**Kết quả:**
- Package `material_floating_search_bar-0.3.7` được viết cho Flutter < 3.0
- Nó vẫn dùng deprecated TextTheme properties (`subtitle1`, `headline6`)
- Flutter 3.19.0 không có properties này nữa
- → **Compile error**

---

### **3. Các Lỗi Khác Cũng Liên Quan**

```
Error 1: headline6 isn't defined
floating_search_app_bar.dart:635:45
Theme.of(context).textTheme.headline6 ??

Error 2: subtitle1 isn't defined (x2)
floating_search_app_bar.dart:645:45
floating_search_app_bar.dart:647:27
? style.queryStyle ?? textTheme.subtitle1
textTheme.subtitle1?.copyWith(color: theme.hintColor)

Error 3: FixedScrollMetrics requires devicePixelRatio
floating_search_bar_scroll_notifier.dart:38:41
metrics = FixedScrollMetrics(
```

**Tất cả lỗi đều gốc từ: Package quá cũ vs Flutter version mới**

---

## ✅ Giải Pháp

### **GIẢI PHÁP 1: Cập Nhật Material Floating Search Bar Lên Version Mới (Khuyên Dùng)**

**Vấn đề với 0.3.7:**
- Quá cũ, không support Flutter 3.0+
- Có nhiều lỗi compatibility

**Cách làm:**
1. Mở `pubspec.yaml`
2. Tìm dependency: `material_floating_search_bar: ^0.3.7`
3. Thay thế bằng version mới hơn

**Các options:**
```
Option A: Latest version
  material_floating_search_bar: ^0.3.8
  hoặc
  material_floating_search_bar: latest

Option B: Specific compatible version
  material_floating_search_bar: ^0.3.7+8  (hoặc cao hơn)

Option C: Find alternative package
  Nếu 0.3.8 vẫn có vấn đề, xét các package khác:
  - flutter_typeahead (search suggestions)
  - typeahead (autocomplete)
  - search_page (Material search UI)
```

**Sau cập nhật:**
```bash
fvm flutter pub get
fvm flutter pub upgrade material_floating_search_bar
```

---

### **GIẢI PHÁP 2: Kiểm Tra Package Changelog**

**Trước cập nhật, kiểm tra:**
1. Truy cập: https://pub.dev/packages/material_floating_search_bar/versions
2. Xem **"Versions"** tab
3. Chọn version mới hơn (vd: 0.3.8+)
4. Đọc **Changelog** xem có fix lỗi TextTheme không
5. Kiểm tra **"Null Safety"** & **"Flutter"** compatibility badge

**Dấu hiệu version tốt:**
- ✅ Có "Null Safety" badge
- ✅ Support Flutter 3.0+
- ✅ Recent update (tháng gần đây)
- ✅ Changelog mention TextTheme fixes

---

### **GIẢI PHÁP 3: Nếu Không Có Version Mới (Fallback)**

**Tình huống:** Tất cả versions của `material_floating_search_bar` đều cũ

**Lựa chọn thay thế:**

#### **Option A: Dùng SearchAnchor (Built-in Material)**
```
Ưu điểm:
  ✅ Part of Flutter Material
  ✅ Always compatible
  ✅ Maintained officially
  
Nhược điểm:
  ❌ Không floating (fixed ở top body)
  ❌ Cần adjust layout (Column + Expanded)
```

**Solution:** Sử dụng hướng dẫn **FIX_SEARCHANCHOR_DISPLAY_GUIDE.md** đã tạo trước

---

#### **Option B: Dùng Package Flutter Typeahead**
```
Package: flutter_typeahead

Ưu điểm:
  ✅ Lightweight, maintained
  ✅ Support Flutter 3.0+
  ✅ Flexible positioning
  ✅ Custom suggestions UI
  
Nhược điểm:
  ⚠️ Cần setup positioning để floating
  ⚠️ Cần custom styling
```

**Setup:**
```yaml
dependencies:
  flutter_typeahead: ^4.8.0  (hoặc latest)
```

---

#### **Option C: Dùng Typeahead (Google's Autocomplete UI)**
```
Package: typeahead

Ưu điểm:
  ✅ Google-backed
  ✅ Modern API
  ✅ Responsive design
  
Nhược điểm:
  ⚠️ Cần custom styling để match app design
```

---

### **GIẢI PHÁP 4: Nếu Phải Giữ Material Floating Search Bar**

**Nếu bắt buộc phải dùng package này:**

**Cách 1: Override TextTheme (Workaround)**
- Tạo custom TextTheme extension trong app
- Thêm deprecated properties quay về

**Cách 2: Fork Package**
- Clone source code từ GitHub
- Fix lỗi TextTheme tại local
- Sử dụng path dependency

**Cách 3: Downgrade Flutter Version**
- Downgrade FVM từ 3.19.0 → 2.13.x
- ⚠️ **NOT RECOMMENDED** - Mất các features & fixes của Flutter 3.0+

---

## 📋 Checklist Khắc Phục

### **Step 1: Kiểm Tra Package Availability**
- [ ] Truy cập https://pub.dev/packages/material_floating_search_bar/versions
- [ ] Xem có version nào >= 0.3.8 không
- [ ] Đọc changelog xem có fix TextTheme không

### **Step 2: Quyết Định Giải Pháp**
- [ ] **Option A (Recommended):** Cập nhật material_floating_search_bar lên version mới
- [ ] **Option B:** Switch sang flutter_typeahead
- [ ] **Option C:** Quay về SearchAnchor + fix layout

### **Step 3: Thực Hiện**
Nếu chọn Option A:
- [ ] Update `pubspec.yaml`: `material_floating_search_bar: ^0.3.8`
- [ ] Run: `fvm flutter pub get`
- [ ] Run: `fvm flutter pub upgrade material_floating_search_bar`
- [ ] Run: `fvm flutter clean` (nếu vẫn lỗi)
- [ ] Rebuild project

Nếu chọn Option B:
- [ ] Thay thế dependency: `flutter_typeahead: ^4.8.0`
- [ ] Setup positioning & styling tương tự
- [ ] Update code dùng TypeAheadField thay SearchAnchor

Nếu chọn Option C:
- [ ] Remove: `material_floating_search_bar` dependency
- [ ] Keep: SearchAnchor widget
- [ ] Apply: Fixes từ **FIX_SEARCHANCHOR_DISPLAY_GUIDE.md**

### **Step 4: Verify**
- [ ] `fvm flutter pub get` thành công
- [ ] Build không có TextTheme errors
- [ ] App compile & run successfully
- [ ] Search functionality hoạt động

---

## 🎯 Giải Pháp Khuyên Dùng (Tóm Tắt)

**Vì sao chọn Option A (Cập nhật package):**
1. ✅ Giải quyết tất cả 3 errors cùng lúc
2. ✅ Không thay đổi nhiều code
3. ✅ Giữ được UX floating search bar
4. ✅ Dễ nhất & nhanh nhất

**Nếu Option A không hoạt động:**
→ Chuyển sang Option C (SearchAnchor) vì đã có full hướng dẫn sẵn

---

## 🔗 Tài Liệu Tham Khảo

### **TextTheme Migration (Flutter 3.0):**
https://docs.flutter.dev/release/breaking-changes/typography-migration

**Old → New Mapping:**
```
headline1     → displayLarge
headline2     → displayMedium
headline3     → displaySmall
headline4     → headlineLarge
headline5     → headlineMedium
headline6     → titleLarge
subtitle1     → titleMedium
subtitle2     → titleSmall
body1         → bodyLarge
body2         → bodyMedium
caption       → labelSmall
```

### **Package Comparison:**
| Package | Version | Floating | Maintenance | Status |
|---------|---------|----------|-------------|--------|
| material_floating_search_bar | 0.3.7 | ✅ | ⚠️ Old | Deprecated for Flutter 3.0+ |
| material_floating_search_bar | 0.3.8+ | ✅ | ✅ Better | (If available) |
| flutter_typeahead | 4.8.0+ | ⚠️ Need setup | ✅ Active | Recommended alternative |
| SearchAnchor | Built-in | ❌ Fixed top | ✅ Official | Good fallback |

---

## 📌 Kết Luận

**Lỗi TextTheme là do:**
1. Package quá cũ (0.3.7)
2. Flutter version mới (3.19.0) loại bỏ deprecated TextTheme properties
3. Không tương thích

**Cách sửa:**
1. **Cách 1 (Best):** Cập nhật package lên 0.3.8+
2. **Cách 2 (Good):** Switch sang flutter_typeahead
3. **Cách 3 (Fallback):** Quay về SearchAnchor + fix layout

**Action ngay:**
→ Cập nhật `pubspec.yaml` & run `fvm flutter pub get`


