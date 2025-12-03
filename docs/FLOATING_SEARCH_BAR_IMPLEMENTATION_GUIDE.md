# Hướng Dẫn Ứng Dụng Material Floating Search Bar Cho Metro Map Screen

## 📋 Tổng Quan Package

**Material Floating Search Bar** là một widget search bar nổi trên map hoặc UI khác, có tính năng:
- ✅ Floating position (có thể tùy chỉnh vị trí)
- ✅ Built-in search suggestions
- ✅ Smooth animations khi open/close
- ✅ Customizable styling
- ✅ Hỗ trợ leading & trailing icons
- ✅ Responsive design

**Link:** https://pub.dev/packages/material_floating_search_bar

---

## 🔄 So Sánh SearchAnchor vs FloatingSearchBar

| Feature | SearchAnchor | FloatingSearchBar |
|---------|--------------|------------------|
| **Position** | Fixed ở top body | Floating (có thể customize) |
| **Suggestions Display** | Dropdown ở dưới | Modal/Overlay ở trên map |
| **Layout Conflict** | Dễ bị ẩn bởi widgets khác | Floating trên map, không bị ẩn |
| **Mobile UX** | Standard material | Modern, giống Google Maps |
| **Map Integration** | Cần tách riêng layout | Hoàn hảo cho map screens |
| **Animations** | Default | Smooth & custom |
| **Complexity** | Simpler | Slightly more complex |

---

## 💡 Tại Sao FloatingSearchBar Tốt Hơn Cho Metro Map Screen?

1. **Floating trên map** → Không bị ẩn bởi `_VietmapWidget`
2. **Không cần thay đổi layout** → Stack structure vẫn giữ nguyên
3. **UX tốt hơn** → Giống Google Maps, user quen thuộc
4. **Flexible positioning** → Có thể set offset từ top/left/right
5. **Suggestions overlay** → Hiển thị ngoài bounds của parent widget
6. **Keyboard handling** → Tự động quản lý keyboard show/hide

---

## 🛠️ Cách Ứng Dụng Material Floating Search Bar

### **BƯỚC 1: Cấu Trúc Widget Hierarchy**

**Thay vì:**
```dart
Stack(
  children: [
    SearchAnchor(...),        // ← Ở trong Stack
    _VietmapWidget(...),      // ← Ở trong Stack
    UserLocationLayer(...),
  ],
)
```

**Nên là:**
```dart
Stack(
  children: [
    // Map & overlays ở background
    _VietmapWidget(...),
    if (provider.isOnMyLocation)
      UserLocationLayer(...),
    
    // FloatingSearchBar floating ở top
    FloatingSearchBar(
      // Configuration
      ...
    ),
    
    // FloatingActionButtons vẫn ở dưới
  ],
)
```

**Lợi ích:**
- FloatingSearchBar nằm ở `children` cuối cùng → Render ở layer top
- Floating position → không bị map che phủ
- Stack `overflow: Overflow.clip` (default) sẽ **NOT clip** floating elements khi positioned properly

---

### **BƯỚC 2: Cấu Hình FloatingSearchBar**

**Main Properties Cần Thiết:**

```dart
FloatingSearchBar(
  // 1. Positioning
  margins: EdgeInsets.fromLTRB(16, 16, 16, 0),  // Space từ edges
  axisAlignment: -1.0,                          // -1.0 = top, 0.0 = center
  openAxisAlignment: 0.0,                       // Khi mở suggestions
  
  // 2. Appearance
  hint: 'Tìm kiếm địa điểm...',
  borderRadius: BorderRadius.circular(8),
  elevation: 8,                                 // Shadow
  
  // 3. Input & Controller
  controller: _searchController,                // Manage search text
  onChanged: (query) {
    provider.onSearchChanged(query);             // Gọi provider
  },
  
  // 4. Leading Icon
  leading: Icon(Icons.location_on),
  
  // 5. Trailing Icons
  trailing: [
    if (provider.isSearching)
      SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(),
      ),
    if (provider.searchQuery.isNotEmpty)
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => provider.clearSearch(),
      ),
  ],
  
  // 6. Suggestions (Most Important!)
  builder: (context, transition) {
    return Container(
      // Builder content - typically a ListView of suggestions
      child: ListView(
        shrinkWrap: true,
        children: provider.searchSuggestions
            .take(10)
            .map((place) => ListTile(
              title: Text(place.display),
              subtitle: Text(place.address),
              onTap: () => provider.onSuggestionSelected(place),
            ))
            .toList(),
      ),
    );
  },
)
```

---

### **BƯỚC 3: Key Features Của FloatingSearchBar**

#### **A. Transitions (Open/Close Animations)**

```dart
builder: (context, transition) {
  // `transition` là 0.0 (closed) - 1.0 (fully open)
  // Dùng để animate suggestions opacity, scale, position
  
  return ScaleTransition(
    scale: Tween<double>(begin: 0.0, end: 1.0).animate(transition),
    child: ListView(
      // suggestions
    ),
  );
}
```

**Pseudo-code:**
```
transition = 0.0 → Suggestions ẩn
transition = 0.5 → Suggestions đang show/hide
transition = 1.0 → Suggestions hiện toàn bộ
```

---

#### **B. Body (Content Khi Suggestions Terbuka)**

```dart
body: Column(
  // Nội dung khi FloatingSearchBar mở rộng
  // VD: Recent searches, Popular places, etc.
  children: [
    ListTile(title: Text('Recent Search 1')),
    ListTile(title: Text('Recent Search 2')),
  ],
)
```

---

#### **C. onFocusChanged (Detect When Search Active)**

```dart
FloatingSearchBar(
  onFocusChanged: (isFocused) {
    if (isFocused) {
      // User bắt đầu search
      print("Searching...");
    } else {
      // User thoát search (blur)
      print("Search closed");
      // Có thể clear suggestions nếu muốn
    }
  },
)
```

---

### **BƯỚC 4: Integration Với MetroMapProvider**

**Provider cần có:**

```dart
class MetroMapProvider extends ChangeNotifier {
  // ... existing code ...
  
  String _searchQuery = "";
  List<PlaceEntity> _searchSuggestions = [];
  bool _isSearching = false;
  PlaceEntity? _selectedPlace;
  PlaceDetailEntity? _selectedPlaceDetails;
  String? _errorMessage;
  
  // Getters
  String get searchQuery => _searchQuery;
  List<PlaceEntity> get searchSuggestions => _searchSuggestions;
  bool get isSearching => _isSearching;
  PlaceEntity? get selectedPlace => _selectedPlace;
  PlaceDetailEntity? get selectedPlaceDetails => _selectedPlaceDetails;
  String? get errorMessage => _errorMessage;
  
  // Methods
  Future<void> onSearchChanged(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();
    
    // Debounce with Timer
    // Call repository.searchPlaces()
    // Update _searchSuggestions
  }
  
  Future<void> onSuggestionSelected(PlaceEntity place) async {
    _selectedPlace = place;
    _isSearching = true;
    notifyListeners();
    
    // Call repository.getPlaceDetails()
    // Pan map & add marker
  }
  
  void clearSearch() {
    _searchQuery = "";
    _searchSuggestions = [];
    _selectedPlace = null;
    notifyListeners();
  }
}
```

---

## 📐 Layout Structure Để Implement

### **Current (SearchAnchor in Stack):**
```
Stack
├─ SearchAnchor        ← Bị ẩn
├─ _VietmapWidget      ← Expand & che phủ SearchAnchor
├─ UserLocationLayer
└─ FloatingActionButton
```

### **New (FloatingSearchBar):**
```
Stack
├─ _VietmapWidget          ← Background (no conflict)
├─ UserLocationLayer       ← Overlay
├─ FloatingSearchBar       ← Floating (rendered last, topmost)
│  └─ Suggestions overlay
└─ FloatingActionButton    ← Bottom-right (no conflict)
```

---

## ✅ Điểm Cần Lưu Ý Khi Implement

### **1. SearchController Management**

```dart
// Ở StatefulWidget level (nếu cần)
late SearchController _searchController;

@override
void initState() {
  super.initState();
  _searchController = SearchController();
}

@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

**Hoặc** dùng Provider để manage controller state.

---

### **2. Suggestions Overlay Positioning**

```dart
FloatingSearchBar(
  axisAlignment: -1.0,          // -1.0 = top
  openAxisAlignment: 0.0,       // Center khi open
  margins: EdgeInsets.all(16),  // Padding from edges
  // Suggestions sẽ show dưới search bar, tự động overflow container
)
```

---

### **3. Keyboard Handling**

```dart
FloatingSearchBar(
  // Tự động show/hide keyboard
  // Không cần handle manually
  // onFocusChanged callback để detect focus state
)
```

---

### **4. Clearing Suggestions Khi Close**

```dart
FloatingSearchBar(
  onFocusChanged: (isFocused) {
    if (!isFocused) {
      // Clear suggestions khi blur
      provider.clearSearch();
    }
  },
)
```

---

### **5. Custom Colors & Styling**

```dart
FloatingSearchBar(
  backgroundColor: Colors.white,
  iconColor: Colors.grey,
  shadowColor: Colors.black.withOpacity(0.2),
  
  // Search input text style
  accentColor: AppColors.primary,
  
  // Builder for suggestions can customize list styling
  builder: (context, transition) {
    return Container(
      color: Colors.white,
      child: ListView(...),
    );
  },
)
```

---

## 🎯 Comparison: Trước vs Sau

### **Trước (SearchAnchor in Stack):**
```
❌ SearchAnchor bị ẩn dưới map
❌ Cần thay đổi layout (Column + Expanded)
❌ Suggestions dropdown bị clip
❌ Layout complex & hard to maintain
```

### **Sau (FloatingSearchBar):**
```
✅ FloatingSearchBar floating trên map, không bị ẩn
✅ Stack structure không đổi
✅ Suggestions overlay không bị clip
✅ Layout clean & maintainable
✅ UX modern, giống Google Maps
```

---

## 🔧 Implementation Checklist

### **Step 1: Add Dependency**
- [ ] Add `material_floating_search_bar` to `pubspec.yaml`
- [ ] Run `flutter pub get` hoặc `fvm flutter pub get`

### **Step 2: Remove SearchAnchor**
- [ ] Comment out hoặc xoá toàn bộ `SearchAnchor` widget từ Stack

### **Step 3: Add FloatingSearchBar**
- [ ] Import package
- [ ] Tạo FloatingSearchBar widget
- [ ] Configure: margins, border, colors, etc.

### **Step 4: Connect Provider**
- [ ] Bind `onChanged` → `provider.onSearchChanged()`
- [ ] Bind `builder` → hiển thị `provider.searchSuggestions`
- [ ] Bind `onTap` → `provider.onSuggestionSelected()`
- [ ] Bind `trailing icons` → clear button + loading indicator
- [ ] Bind `onFocusChanged` → clear suggestions khi blur

### **Step 5: Test**
- [ ] Type vào search → suggestions hiển thị
- [ ] Click suggestion → map pan + marker vẽ
- [ ] Clear button → search clear
- [ ] Suggestions không bị ẩn bởi map
- [ ] Keyboard open/close properly
- [ ] FloatingActionButtons không overlap

---

## 📝 Pseudo-code Template

```dart
class _MetroMapView extends StatelessWidget {
  const _MetroMapView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map & overlays
          _VietmapWidget(onMapCreated: provider.onMapCreated),
          if (provider.isOnMyLocation)
            UserLocationLayer(...),
          
          // FloatingSearchBar (Floating on top)
          FloatingSearchBar(
            margins: EdgeInsets.fromLTRB(16, 16, 16, 0),
            axisAlignment: -1.0,
            hint: 'Tìm kiếm địa điểm...',
            onChanged: (query) => provider.onSearchChanged(query),
            trailing: [
              if (provider.isSearching) CircularProgressIndicator(...),
              if (provider.searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => provider.clearSearch(),
                ),
            ],
            builder: (context, transition) {
              return Container(
                child: ListView(
                  shrinkWrap: true,
                  children: provider.searchSuggestions
                      .take(10)
                      .map((place) => ListTile(
                        title: Text(place.display),
                        subtitle: Text(place.address),
                        onTap: () => provider.onSuggestionSelected(place),
                      ))
                      .toList(),
                ),
              );
            },
            onFocusChanged: (isFocused) {
              if (!isFocused) {
                provider.clearSearch();
              }
            },
          ),
        ],
      ),
      floatingActionButton: Stack(...),  // Giữ nguyên
    );
  }
}
```

---

## 🌟 Lợi Ích Material Floating Search Bar

| Lợi Ích | Chi Tiết |
|--------|---------|
| **Floating Position** | Nổi trên map, không bị ẩn |
| **Smooth Animations** | Open/close với transition smooth |
| **Responsive** | Tự động handle keyboard |
| **Customizable** | Colors, margins, styles dễ tùy chỉnh |
| **Modern UX** | Giống Google Maps, user familiar |
| **No Layout Changes** | Stack structure giữ nguyên |
| **Built-in Suggestions** | `builder` callback dễ implement |
| **Focus Management** | `onFocusChanged` callback |

---

## 📌 Kết Luận

**Material Floating Search Bar** là giải pháp tốt hơn SearchAnchor cho Metro Map Screen vì:

1. ✅ **Không bị ẩn** bởi map widget (floating position)
2. ✅ **Không cần thay layout** (Stack structure giữ nguyên)
3. ✅ **UX hiện đại** (giống Google Maps)
4. ✅ **Dễ implement** (simple configuration)
5. ✅ **Flexible** (customizable positioning & styling)
6. ✅ **Better animations** (smooth open/close)

**Tóm tắt implementation:**
- Remove SearchAnchor từ Stack
- Add FloatingSearchBar widget
- Configure: margins, colors, styling
- Connect provider methods: `onChanged`, `onTap`, `onFocusChanged`
- Bind suggestions từ `provider.searchSuggestions`
- Test: type → suggestions show → click → map update


