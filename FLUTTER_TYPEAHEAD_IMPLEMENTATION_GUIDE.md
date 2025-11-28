# Hướng Dẫn Ứng Dụng Flutter TypeAhead Cho Metro Map Screen

## 📋 Tổng Quan Package Flutter TypeAhead

**Package:** flutter_typeahead  
**Link:** https://pub.dev/packages/flutter_typeahead  
**Latest Version:** 4.8.0+ (hoặc mới hơn)  
**Compatibility:** ✅ Flutter 3.0+, ✅ Null Safety, ✅ Active Maintenance

### **Tính Năng Chính:**
- ✅ Lightweight & fast suggestions
- ✅ Customizable UI cho suggestions
- ✅ Built-in keyboard dismissal
- ✅ Support both `TypeAheadField` (TextField mode) & `RawTypeAheadField` (Custom mode)
- ✅ Debounce support (tránh gọi API nhiều lần)
- ✅ Flexible positioning của suggestions overlay
- ✅ Loading indicator support
- ✅ Empty results handling
- ✅ Both StatefulWidget & Provider compatible

---

## 🔄 So Sánh Các Widget Autocomplete

| Widget | Best For | Floating | Mobile | Complexity |
|--------|----------|----------|--------|-----------|
| **SearchAnchor** | Standard Material | ❌ Fixed | ✅ Good | Low |
| **TypeAheadFormField** | TextField with suggestions | ⚠️ Default | ✅ Good | Medium |
| **TypeAheadField** (v5.0+) | Modern, flexible | ⚠️ Customizable | ✅ Good | Medium |
| **RawTypeAheadField** | Full custom control | ✅ Yes | ✅ Best | High |
| **FloatingSearchBar** | Floating on map | ✅ Yes | ✅ Best | High |

---

## 🏗️ Cấu Trúc Code Hiện Tại (Metro Map Screen)

```dart
Stack(
  children: [
    TypeAheadFormField(          // ← Package cũ, cách viết cũ
      textFieldConfiguration: ...,
      suggestionsCallback: (pattern) => [],
      itemBuilder: (context, suggestion) => ListTile(...),
      onSuggestionSelected: (suggestion) => {},
    ),
    _VietmapWidget(...),         // ← Map có thể cover search field
    UserLocationLayer(...),
  ],
)
```

**Vấn đề:**
1. `TypeAheadFormField` là deprecated API cũ (v3.x hoặc v4.x)
2. Suggestions callback trống → không gọi API
3. Widget nằm trong Stack → có thể bị map che phủ
4. Không có provider binding

---

## ✅ GIẢI PHÁP: Sử Dụng Flutter TypeAhead v4.8.0+

### **BƯỚC 1: Chuẩn Bị Package & Provider**

**A. Kiểm Tra Dependency**

```yaml
dependencies:
  flutter_typeahead: ^4.8.0  (hoặc 5.0.0+ nếu available)
```

**Version considerations:**
```
v4.8.x    → Stable, proven, good for Flutter 3.x
v5.0+     → Newer API, more flexible (check compatibility)
```

---

**B. Chuẩn Bị MetroMapProvider State**

```dart
class MetroMapProvider extends ChangeNotifier {
  // Existing properties
  VietmapController? _vietmapController;
  bool _isOnMyLocation = false;
  
  // NEW: Search properties
  String _searchQuery = "";
  List<PlaceEntity> _searchSuggestions = [];
  bool _isSearching = false;
  PlaceEntity? _selectedPlace;
  PlaceDetailEntity? _selectedPlaceDetails;
  
  // Getters
  String get searchQuery => _searchQuery;
  List<PlaceEntity> get searchSuggestions => _searchSuggestions;
  bool get isSearching => _isSearching;
  PlaceEntity? get selectedPlace => _selectedPlace;
  PlaceDetailEntity? get selectedPlaceDetails => _selectedPlaceDetails;
  
  // Methods (tùy theo yêu cầu)
  // - onSearchChanged(String query)
  // - onSuggestionSelected(PlaceEntity place)
  // - clearSearch()
}
```

---

### **BƯỚC 2: Hiểu Cấu Trúc TypeAheadField (v4.8.0+)**

**TypeAheadField Constructor:**

```dart
TypeAheadField<PlaceEntity>(
  // 1. Text input configuration
  textFieldConfiguration: TextFieldConfiguration(
    controller: _controller,
    decoration: InputDecoration(...),
  ),
  
  // 2. Suggestions async callback
  suggestionsCallback: (pattern) async {
    // Gọi API dựa trên pattern (query text)
    // Return List<PlaceEntity>
  },
  
  // 3. Suggestions UI builder
  itemBuilder: (context, PlaceEntity suggestion) {
    return ListTile(
      title: Text(suggestion.display),
      subtitle: Text(suggestion.address),
    );
  },
  
  // 4. When suggestion selected
  onSuggestionSelected: (PlaceEntity suggestion) {
    // Xử lý click suggestion
    // Update controller text
    // Call provider method
    // Pan map & add marker
  },
  
  // 5. Optional configs
  debounceDuration: Duration(milliseconds: 400),  // Debounce
  loadingBuilder: (context) => CircularProgressIndicator(),
  noItemsFoundBuilder: (context) => Text("No results"),
  hideOnEmpty: true,
  hideOnLoading: false,
  hideOnSelect: true,
  
  // 6. Positioning (important for map)
  hideKeyboardOnDrag: true,
  autoFlipDirection: true,  // Auto flip suggestions if near bottom
)
```

---

### **BƯỚC 3: Key Configurations Cho Metro Map Screen**

#### **A. TextFieldConfiguration**

```dart
textFieldConfiguration: TextFieldConfiguration(
  // Controller để manage text
  controller: _searchController,
  
  // Input decoration
  decoration: InputDecoration(
    hintText: 'Tìm kiếm địa điểm...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    prefixIcon: Icon(Icons.location_on),
    
    // Suffix icons (clear button, loading)
    suffixIcon: provider.isSearching
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(),
          )
        : (provider.searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearch();
                },
              )
            : null),
  ),
  
  // Styling
  style: TextStyle(fontSize: 16),
)
```

---

#### **B. SuggestionsCallback (Gọi API)**

```dart
suggestionsCallback: (pattern) async {
  // pattern = giá trị hiện tại trong text field
  
  if (pattern.isEmpty) {
    return [];  // Không gợi ý nếu search trống
  }
  
  try {
    // Gọi provider method để get suggestions
    await provider.onSearchChanged(pattern);
    
    // Return suggestions từ provider
    return provider.searchSuggestions;
    
  } catch (e) {
    debugPrint('Search error: $e');
    return [];
  }
}
```

---

#### **C. ItemBuilder (Suggestions UI)**

```dart
itemBuilder: (context, PlaceEntity suggestion) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: ListTile(
      // Tile layout
      leading: Icon(Icons.location_on, color: Colors.grey),
      
      title: Text(
        suggestion.display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      
      subtitle: Text(
        suggestion.address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      
      // Trailing distance indicator
      trailing: Text(
        '${suggestion.distance.toStringAsFixed(1)} km',
        style: TextStyle(fontSize: 12),
      ),
    ),
  );
}
```

---

#### **D. OnSuggestionSelected (Click Handling)**

```dart
onSuggestionSelected: (PlaceEntity suggestion) async {
  // 1. Update controller text
  _searchController.text = suggestion.display;
  
  // 2. Store selected place
  // provider.selectPlace(suggestion);
  
  // 3. Call provider để get place detail
  await provider.onSuggestionSelected(suggestion);
  
  // 4. Map sẽ auto pan + marker sẽ vẽ
  // (handled in provider logic)
}
```

---

#### **E. Loading & Empty States**

```dart
// Show loading indicator khi đang fetch suggestions
loadingBuilder: (context) {
  return Container(
    padding: EdgeInsets.all(8),
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

// Show message khi không tìm thấy
noItemsFoundBuilder: (context) {
  return Container(
    padding: EdgeInsets.all(8),
    child: Text('Không tìm thấy địa điểm nào'),
  );
}

// Loading indicator khi gọi API
hideOnLoading: false,  // ✅ Keep visible khi loading

// Hide suggestions khi không có kết quả
hideOnEmpty: true,

// Hide suggestions khi click 1 item
hideOnSelect: true,

// Debounce để tránh gọi API quá nhiều
debounceDuration: Duration(milliseconds: 400),
```

---

### **BƯỚC 4: Positioning & Layout**

#### **Vấn Đề: TypeAheadField Nằm Trong Stack Có Thể Bị Ẩn**

```dart
Stack(
  children: [
    TypeAheadField(...),        // ← Suggestions overlay có thể bị map che
    _VietmapWidget(...),        // ← Map widget
    UserLocationLayer(...),
  ],
)
```

**Giải Pháp A: Wrap TypeAheadField Bằng Positioned**

```dart
Stack(
  children: [
    // Positioned search field ở top
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: TypeAheadField(...),
    ),
    
    // Map ở background
    _VietmapWidget(...),
    UserLocationLayer(...),
  ],
)
```

**Giải Pháp B: Dùng Column (Khuyên Dùng)**

```dart
Column(
  children: [
    // Search field ở top
    Padding(
      padding: EdgeInsets.all(8),
      child: TypeAheadField(...),
    ),
    
    // Map expand chiếm phần còn lại
    Expanded(
      child: Stack(
        children: [
          _VietmapWidget(...),
          UserLocationLayer(...),
        ],
      ),
    ),
  ],
)
```

**Lợi ích Giải Pháp B:**
- TypeAheadField luôn ở trên
- Suggestions overlay không bị clip
- Map chiếm proper space
- Layout clean & maintainable

---

#### **Suggestions Overlay Positioning**

```dart
TypeAheadField(
  // Auto adjust position nếu suggestions overlay quá bottom
  autoFlipDirection: true,
  
  // Hide keyboard khi drag map
  hideKeyboardOnDrag: true,
  
  // Offset suggestions từ input field
  // dieu chinh neu can
  // (config tùy package version)
)
```

---

### **BƯỚC 5: Provider Integration Pattern**

**MetroMapProvider Methods:**

```dart
// 1. Search suggestions
Future<void> onSearchChanged(String query) async {
  _searchQuery = query;
  
  if (query.isEmpty) {
    _searchSuggestions = [];
    notifyListeners();
    return;
  }
  
  _isSearching = true;
  notifyListeners();
  
  try {
    // Call repository.searchPlaces()
    // _searchSuggestions = await _repository.searchPlaces(...)
    notifyListeners();
  } catch (e) {
    debugPrint('Search error: $e');
    _searchSuggestions = [];
  } finally {
    _isSearching = false;
    notifyListeners();
  }
}

// 2. Selected suggestion handling
Future<void> onSuggestionSelected(PlaceEntity place) async {
  _selectedPlace = place;
  _isSearching = true;
  notifyListeners();
  
  try {
    // Get place detail
    // _selectedPlaceDetails = await _repository.getPlaceDetails(...)
    
    // Pan map
    // await _vietmapController.moveCamera(...)
    
    // Add marker
    // ...
    
  } catch (e) {
    debugPrint('Select error: $e');
  } finally {
    _isSearching = false;
    notifyListeners();
  }
}

// 3. Clear search
void clearSearch() {
  _searchQuery = "";
  _searchSuggestions = [];
  _selectedPlace = null;
  notifyListeners();
}
```

---

## 📊 Flow Diagram: TypeAheadField + Provider

```
User types "Trần"
    ↓
TypeAheadField.suggestionsCallback(pattern: "Trần")
    ↓
Provider.onSearchChanged("Trần")
    ├─ _isSearching = true
    ├─ Call repository.searchPlaces("Trần")
    │
    └─ Update _searchSuggestions
        ├─ notifyListeners()
        │
        └─ suggestionsCallback returns provider.searchSuggestions
            │
            └─ TypeAheadField rebuilds suggestions list
                ├─ itemBuilder renders ListTile for each item
                │
                └─ User sees suggestions dropdown
                    │
                    └─ User clicks suggestion
                        │
                        └─ TypeAheadField.onSuggestionSelected()
                            │
                            └─ Provider.onSuggestionSelected(place)
                                ├─ Call repository.getPlaceDetails()
                                ├─ Pan map to lat/lng
                                ├─ Add marker
                                │
                                └─ notifyListeners()
                                    │
                                    └─ UI updates (map pan + marker)
```

---

## 🔧 Implementation Checklist

### **Setup Phase:**
- [ ] Add `flutter_typeahead: ^4.8.0` to pubspec.yaml
- [ ] Run `fvm flutter pub get`
- [ ] Import: `import 'package:flutter_typeahead/flutter_typeahead.dart';`

### **Provider Updates:**
- [ ] Add 5 search properties: `_searchQuery`, `_searchSuggestions`, `_isSearching`, `_selectedPlace`, `_selectedPlaceDetails`
- [ ] Add getters for all 5 properties
- [ ] Implement `onSearchChanged(String query)` method
- [ ] Implement `onSuggestionSelected(PlaceEntity place)` method
- [ ] Implement `clearSearch()` method

### **UI Updates:**
- [ ] Create TextEditingController `_searchController`
- [ ] Replace old TypeAheadFormField with new TypeAheadField
- [ ] Configure textFieldConfiguration (hint, decoration, prefix/suffix icons)
- [ ] Implement suggestionsCallback → call provider.onSearchChanged()
- [ ] Implement itemBuilder → render suggestion ListTile
- [ ] Implement onSuggestionSelected → call provider method
- [ ] Configure loading states: loadingBuilder, noItemsFoundBuilder
- [ ] Configure debounce: 300-400ms

### **Layout Updates:**
- [ ] Decide: Column + Expanded vs Stack + Positioned
- [ ] Wrap TypeAheadField properly
- [ ] Test suggestions not hidden by map

### **Testing:**
- [ ] Type in search field → suggestions show
- [ ] Click suggestion → map pan + marker appears
- [ ] Clear button works
- [ ] Loading indicator shows during API call
- [ ] No network error → error message shows
- [ ] Debounce working (not too many API calls)
- [ ] Keyboard dismissed after select

---

## 💡 Key Differences: TypeAheadFormField vs TypeAheadField

| Feature | TypeAheadFormField (Old) | TypeAheadField (New v4.8+) |
|---------|------------------------|---------------------------|
| **Deprecated** | ❌ Yes (v3.x API) | ✅ No (Current) |
| **API** | textFieldConfiguration | textFieldConfiguration |
| **Debounce** | Manual | Built-in `debounceDuration` |
| **Loading** | Manual | loadingBuilder |
| **Empty State** | Manual | noItemsFoundBuilder |
| **Type Safe** | ⚠️ Generic support varies | ✅ Fully generic: TypeAheadField<T> |
| **Async Support** | ⚠️ Limited | ✅ Full async/await |
| **Positioning** | Limited | Better control |

---

## ⚠️ Common Pitfalls & Solutions

### **Pitfall 1: SuggestionsCallback Không Gọi API**

```dart
// ❌ WRONG
suggestionsCallback: (pattern) {
  return [];  // Always empty!
}

// ✅ CORRECT
suggestionsCallback: (pattern) async {
  if (pattern.isEmpty) return [];
  
  // Call provider/repository
  await provider.onSearchChanged(pattern);
  return provider.searchSuggestions;
}
```

---

### **Pitfall 2: Suggestions Bị Ẩn Bởi Map**

```dart
// ❌ WRONG
Stack(
  children: [
    TypeAheadField(...),  // Suggestions overlay bị map che
    _VietmapWidget(...),
  ],
)

// ✅ CORRECT
Column(
  children: [
    TypeAheadField(...),
    Expanded(child: _VietmapWidget(...)),
  ],
)
```

---

### **Pitfall 3: OnSuggestionSelected Không Update Marker**

```dart
// ❌ WRONG
onSuggestionSelected: (suggestion) {
  // Chỉ update text, không call provider
  _searchController.text = suggestion.display;
}

// ✅ CORRECT
onSuggestionSelected: (suggestion) async {
  _searchController.text = suggestion.display;
  
  // Call provider để pan map & add marker
  await provider.onSuggestionSelected(suggestion);
}
```

---

### **Pitfall 4: Forget To Dispose Controller**

```dart
class _MetroMapView extends StatefulWidget {
  @override
  State<_MetroMapView> createState() => _MetroMapViewState();
}

class _MetroMapViewState extends State<_MetroMapView> {
  late TextEditingController _searchController;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }
  
  @override
  void dispose() {
    _searchController.dispose();  // ✅ IMPORTANT!
    super.dispose();
  }
}
```

---

## 🎯 Tóm Tắt Implementation Steps

1. **Add dependency:** `flutter_typeahead: ^4.8.0`
2. **Update Provider:** Add 5 search properties + 3 methods
3. **Create Controller:** `TextEditingController` cho search field
4. **Replace Widget:** Old TypeAheadFormField → New TypeAheadField
5. **Configure:** textFieldConfiguration, suggestionsCallback, itemBuilder, onSuggestionSelected
6. **Add Loading:** loadingBuilder, noItemsFoundBuilder, hideOnLoading/Empty/Select
7. **Set Debounce:** 300-400ms để tránh gọi API quá nhiều
8. **Fix Layout:** Column + Expanded để suggestions không bị map che
9. **Bind Provider:** suggestionsCallback → provider.onSearchChanged()
10. **Test:** Type → suggestions show → click → map update

---

## 📌 Kết Luận

**Flutter TypeAhead v4.8.0+ là solution tốt vì:**

✅ Active maintenance & Flutter 3.0+ compatible  
✅ Built-in debounce & loading states  
✅ Lightweight & simple configuration  
✅ Customizable suggestions UI  
✅ Good keyboard handling  
✅ Type-safe with generics  

**Main advantage over FloatingSearchBar:**
- Simpler setup
- No custom positioning complexity
- Better keyboard integration

**Implementation pattern:**
- Provider manages state: search query, suggestions, selected place
- TypeAheadField UI binds to provider callbacks
- Suggestions callback async returns provider data
- Selection callback updates provider state which triggers map updates


