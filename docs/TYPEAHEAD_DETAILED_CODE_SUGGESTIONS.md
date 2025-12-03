# Hướng Dẫn Chi Tiết Implement TypeAhead - Với Code Suggestions

## 📌 Tuân Thủ Rules.md

**Quy Tắc Áp Dụng:**
- ✅ Provider nằm ở `modules/metro_go/` → UI layer
- ✅ Provider import từ `domain/` & `app/` (AppProvider) → Đúng
- ✅ Provider quản lý UI state (search, marker, ActionSheet)
- ✅ Gọi repository từ AppProvider → Đúng (repository từ dependency injection)
- ✅ One class per file → Provider = 1 file
- ✅ Naming: `MetroMapProvider` & file `metro_map_provider.dart` → Đúng

---

## 🔴 Lỗi Hiện Tại Trong File

```dart
final 
bool _hasLocationPermission = false;
```

**Vấn đề:** Dòng `final` đứng một mình, syntax error

**Fix:** Xoá dòng `final` hoặc move lên dòng trên

---

## 📝 BƯỚC 1: Fix Syntax Error

**Location:** Line 12-13

**Current (Sai):**
```dart
final 
bool _hasLocationPermission = false;
```

**Suggestion (Đúng):**
```dart
bool _hasLocationPermission = false;
```

**Giải thích:**
- `_hasLocationPermission` là biến instance, không cần `final` vì sẽ thay đổi
- Nếu muốn `final`, phải khai báo và gán cùng dòng: `final bool _value = false;`

---

## 📝 BƯỚC 2: Thêm Search State Properties

**Location:** After existing properties (after line 20)

**Suggestion Code Structure:**

```dart
class MetroMapProvider extends ChangeNotifier {
  // ... existing properties ...
  bool _isOnMyLocation = false;
  bool get isOnMyLocation => _isOnMyLocation;

  // ========== NEW: Search & Autocomplete State ==========
  // Search query input
  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  // Suggestions list từ API
  List<PlaceEntity> _searchSuggestions = [];
  List<PlaceEntity> get searchSuggestions => _searchSuggestions;

  // Loading state khi gọi API search
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // ========== NEW: Selected Place State ==========
  // Place được user chọn từ suggestions
  PlaceEntity? _selectedPlace;
  PlaceEntity? get selectedPlace => _selectedPlace;

  // Chi tiết place từ API (chứa lat/lng)
  PlaceDetailEntity? _selectedPlaceDetails;
  PlaceDetailEntity? get selectedPlaceDetails => _selectedPlaceDetails;

  // ========== NEW: UI State ==========
  // Control ActionSheet show/hide
  bool _showPlaceDetails = false;
  bool get showPlaceDetails => _showPlaceDetails;

  // Marker reference để manage lifecycle
  Symbol? _currentMarker;

  // Error message để hiển thị user
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ========== Repository & Controller ==========
  // Lưu reference tới repository (từ AppProvider)
  late final MetroMapRepository _metroMapRepository;

  // TextEditingController cho search field (quản lý ở Screen, nhưng dùng ở Provider)
  // Không lưu ở đây, sẽ dùng callback từ Screen
}
```

**Naming Convention Check:**
- ✅ `_searchQuery` → private, camelCase
- ✅ `searchQuery` → getter, no underscore
- ✅ `_isSearching` → bool tập convention "is/has/show"
- ✅ `_selectedPlace` → nullable, clear intent
- ✅ `_showPlaceDetails` → bool, clear intent
- ✅ `_currentMarker` → track marker lifecycle

---

## 📝 BƯỚC 3: Update Constructor

**Location:** After properties definition

**Suggestion Code Structure:**

```dart
MetroMapProvider(this._appProvider) {
  // Initialize repository từ AppProvider's locator
  _metroMapRepository = locator<MetroMapRepository>();
}
```

**Alternative (Nếu AppProvider cung cấp repository):**

```dart
MetroMapProvider(this._appProvider) {
  // Nếu AppProvider có method/getter để lấy repository
  _metroMapRepository = _appProvider.metroMapRepository;
}
```

**Best Practice:**
- ✅ Dùng locator (dependency injection) từ GetIt
- ✅ Hoặc inject qua constructor parameter
- ✅ Tránh tạo repository directly

---

## 📝 BƯỚC 4: Implement Method 1 - onSearchChanged()

**Location:** After moveToMyLocation() method

**Suggestion Code Structure:**

```dart
/// Xử lý khi user nhập text vào search field
/// 
/// [query]: Giá trị text hiện tại từ TypeAheadField
/// 
/// Logic:
/// 1. Update search query state
/// 2. Nếu query trống → Clear suggestions
/// 3. Nếu có content → Gọi API autocomplete
/// 4. Debounce 300-400ms để tránh API spam
Future<void> onSearchChanged(String query) async {
  // 1. Update query state
  _searchQuery = query;
  
  // 2. Nếu trống → Clear suggestions & return
  if (query.isEmpty) {
    _searchSuggestions = [];
    _errorMessage = null;
    notifyListeners();
    return;
  }
  
  // 3. Set loading state
  _isSearching = true;
  _errorMessage = null;
  notifyListeners();
  
  // 4. Debounce timer (tránh gọi API quá nhiều)
  // Note: Cần thêm property: `Timer? _searchDebounce;` ở trên
  _searchDebounce?.cancel();
  _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
    try {
      // 5. Gọi repository.searchPlaces()
      final request = PlaceRequest(text: query);
      final suggestions = await _metroMapRepository.searchPlaces(request);
      
      // 6. Update suggestions state
      _searchSuggestions = suggestions;
      _errorMessage = null;
      
    } catch (e) {
      // 7. Error handling
      debugPrint('Search error: $e');
      _searchSuggestions = [];
      _errorMessage = 'Lỗi tìm kiếm: ${e.toString()}';
      
    } finally {
      // 8. Clear loading state
      _isSearching = false;
      notifyListeners();
    }
  });
}
```

**Code Explanation:**
```
Line 1-9:   Documentation với /// syntax (Dart best practice)
Line 12-13: Update query state
Line 15-19: Clear nếu empty
Line 21-23: Set loading state
Line 25-27: Cancel timer cũ nếu có
Line 28-39: Debounce timer mới (400ms)
Line 32-33: Create PlaceRequest (domain layer model)
Line 34:    Call repository method
Line 37-38: Update suggestions list
Line 40-44: Error handling - clear suggestions & set error message
Line 46-48: Finally block - clear loading, notify listeners
```

**Important Notes:**
- ✅ `PlaceRequest` là domain model (không DTO)
- ✅ Repository trả về `List<PlaceEntity>` (domain model)
- ✅ Debounce tránh gọi API quá nhiều
- ✅ Error handling graceful - show message, clear suggestions
- ✅ notifyListeners() ở 2 nơi: clear query + after async complete

---

## 📝 BƯỚC 5: Implement Method 2 - onSuggestionSelected()

**Location:** After onSearchChanged() method

**Suggestion Code Structure:**

```dart
/// Xử lý khi user click vào 1 suggestion item
/// 
/// [place]: PlaceEntity được user chọn từ dropdown suggestions
/// 
/// Logic:
/// 1. Lưu selected place
/// 2. Gọi API getPlaceDetails() để lấy lat/lng
/// 3. Pan map camera tới vị trí
/// 4. Vẽ marker trên map
/// 5. Show ActionSheet với chi tiết place
Future<void> onSuggestionSelected(PlaceEntity place) async {
  // 1. Store selected place
  _selectedPlace = place;
  
  // 2. Set loading state
  _isSearching = true;
  notifyListeners();
  
  try {
    // 3. Gọi repository.getPlaceDetails()
    final request = PlaceDetailsRequest(refid: place.refId);
    final placeDetails = await _metroMapRepository.getPlaceDetails(request);
    
    // 4. Update selected place details
    _selectedPlaceDetails = placeDetails;
    
    // 5. Pan map camera tới vị trí
    if (_vietmapController != null) {
      await _vietmapController!.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(placeDetails.latitude, placeDetails.longitude),
          16.0, // Zoom level
        ),
      );
    }
    
    // 6. Remove marker cũ (nếu có)
    if (_currentMarker != null) {
      // Note: Cần verify exact method name từ VietmapController API
      // Có thể là: _currentMarker?.remove() hoặc removeSymbol()
      try {
        _currentMarker?.remove();
      } catch (e) {
        debugPrint('Error removing old marker: $e');
      }
      _currentMarker = null;
    }
    
    // 7. Add marker mới tại vị trí
    // Note: Exact implementation phụ thuộc VietmapGL package API
    try {
      _currentMarker = await _vietmapController!.addSymbol(
        // SymbolOptions config
        // Check VietmapGL documentation cho exact parameters
        // Expected fields:
        // - geometry: LatLng
        // - iconImage: String (icon name)
        // - iconColor: Color
        // - textField: String (show text)
        // - textSize: double
      );
    } catch (e) {
      debugPrint('Error adding marker: $e');
      _errorMessage = 'Lỗi thêm marker: ${e.toString()}';
    }
    
    // 8. Show ActionSheet
    _showPlaceDetails = true;
    _errorMessage = null;
    
  } catch (e) {
    // 9. Error handling
    debugPrint('Get place details error: $e');
    _selectedPlace = null;
    _selectedPlaceDetails = null;
    _errorMessage = 'Lỗi lấy chi tiết địa điểm: ${e.toString()}';
    
  } finally {
    // 10. Clear loading state
    _isSearching = false;
    notifyListeners();
  }
}
```

**Code Flow Explanation:**
```
Line 1-10:  Documentation
Line 13-14: Store selected place
Line 16-17: Set loading state
Line 19-25: Call API getPlaceDetails
Line 27-28: Store result
Line 30-38: Move camera (pan map)
Line 40-48: Remove old marker with error handling
Line 50-60: Add new marker (exact implementation depends on VietmapGL API)
Line 62-63: Set ActionSheet visible
Line 65-72: Error handling - clear state & set error message
Line 74-77: Finally - clear loading & notify
```

**Critical Notes:**
- ✅ `PlaceDetailsRequest` & `getPlaceDetails()` must match repository interface
- ✅ Check VietmapGL documentation para sa exact marker API
- ✅ Nested try-catch para sa marker operations (remove + add)
- ✅ Error handling doesn't crash app - set error message instead
- ✅ notifyListeners() ở finally để update UI after async complete

---

## 📝 BƯỚC 6: Implement Method 3 - clearSearch()

**Location:** After onSuggestionSelected() method

**Suggestion Code Structure:**

```dart
/// Clear semua search state
/// Dipanggil khi:
/// - User click clear button
/// - User close ActionSheet dan ingin search ulang
void clearSearch() {
  // 1. Clear search properties
  _searchQuery = "";
  _searchSuggestions = [];
  _selectedPlace = null;
  _selectedPlaceDetails = null;
  
  // 2. Clear UI state
  _showPlaceDetails = false;
  _errorMessage = null;
  
  // 3. Remove marker dari map
  if (_currentMarker != null) {
    try {
      _currentMarker?.remove();
    } catch (e) {
      debugPrint('Error removing marker: $e');
    }
    _currentMarker = null;
  }
  
  // 4. Cancel pending debounce timer
  _searchDebounce?.cancel();
  _searchDebounce = null;
  
  // 5. Notify UI
  notifyListeners();
}
```

**Code Logic:**
```
Line 1-5:   Documentation
Line 8-12:  Clear all search properties
Line 14-16: Clear UI state
Line 18-24: Remove marker safely
Line 26-28: Cancel debounce timer
Line 30-31: Notify listeners
```

**Timing:** Gọi method này khi:
- User click clear button trong TypeAheadField
- User click clear search button ở UI
- Screen dispose/cleanup

---

## 📝 BƯỚC 7: Implement Method 4 - closeActionSheet()

**Location:** After clearSearch() method

**Suggestion Code Structure:**

```dart
/// Đóng ActionSheet (giữ marker ở map)
/// Khác với clearSearch() - chỉ hide ActionSheet, không xoá marker
void closeActionSheet() {
  _showPlaceDetails = false;
  notifyListeners();
}
```

**Difference vs clearSearch():**
```
closeActionSheet() - Đóng ActionSheet nhưng giữ:
  - selectedPlace
  - selectedPlaceDetails
  - marker ở map
  
clearSearch() - Clear tất cả:
  - Clear search query
  - Clear suggestions
  - Remove marker
  - Hide ActionSheet
```

---

## 📝 BƯỚC 8: Update dispose() Method [IMPORTANT]

**Location:** Add new override method

**Suggestion Code Structure:**

```dart
/// Cleanup resources khi Provider dispose
@override
void dispose() {
  // Cancel debounce timer
  _searchDebounce?.cancel();
  
  // Clean up other resources if needed
  
  super.dispose();
}
```

**Important:**
- ✅ Dispose timer để tránh memory leak
- ✅ Call super.dispose() ở cuối
- ✅ Clean up other resources (streams, subscriptions, etc.)

---

## 📝 BƯỚC 9: Add Missing Property - Timer

**Location:** After repository property

**Suggestion Code Structure:**

```dart
// ...existing code...

// TextEditingController - không lưu ở đây, dùng callback từ Screen
// Debounce timer cho search
Timer? _searchDebounce;
```

---

## 📝 BƯỚC 10: Complete Provider Code Template

**Full structure (pseudo-code):**

```dart
class MetroMapProvider extends ChangeNotifier {
  // ========== Dependencies ==========
  final AppProvider _appProvider;
  late final MetroMapRepository _metroMapRepository;
  
  // ========== Map Controller ==========
  VietmapController? _vietmapController;
  VietmapController get vietmapController => _vietmapController!;
  
  // ========== Location Permission ==========
  bool _hasLocationPermission = false;
  bool _isRequestingPermission = false;
  bool _isOnMyLocation = false;
  
  // ========== Search State ==========
  String _searchQuery = "";
  List<PlaceEntity> _searchSuggestions = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  
  // ========== Selected Place State ==========
  PlaceEntity? _selectedPlace;
  PlaceDetailEntity? _selectedPlaceDetails;
  
  // ========== UI State ==========
  bool _showPlaceDetails = false;
  Symbol? _currentMarker;
  String? _errorMessage;
  
  // ========== Constructor ==========
  MetroMapProvider(this._appProvider) {
    _metroMapRepository = locator<MetroMapRepository>();
  }
  
  // ========== Lifecycle ==========
  void onMapCreated(VietmapController controller) { }
  
  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
  
  // ========== Location Methods ==========
  Future<void> moveToMyLocation() async { }
  
  // ========== Search Methods ==========
  Future<void> onSearchChanged(String query) async { }
  Future<void> onSuggestionSelected(PlaceEntity place) async { }
  void clearSearch() { }
  void closeActionSheet() { }
  
  // ========== Getters ==========
  String get searchQuery => _searchQuery;
  // ... other getters ...
}
```

---

## 🎯 Screen Implementation - TypeAheadField Configuration

**Location:** metro_map_screen.dart

**Suggestion Code Structure:**

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
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();
    
    return Scaffold(
      body: Column(
        children: [
          // ========== Search Field ==========
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TypeAheadField<PlaceEntity>(
              // --- 1. TextFieldConfiguration ---
              textFieldConfiguration: TextFieldConfiguration(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm địa điểm...',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  
                  // Dynamic suffix icon
                  suffixIcon: _buildSuffixIcon(provider),
                ),
              ),
              
              // --- 2. SuggestionsCallback ---
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) return [];
                
                try {
                  await provider.onSearchChanged(pattern);
                  return provider.searchSuggestions;
                } catch (e) {
                  debugPrint('Suggestions error: $e');
                  return [];
                }
              },
              
              // --- 3. ItemBuilder ---
              itemBuilder: (context, PlaceEntity suggestion) {
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(
                    suggestion.display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    suggestion.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Text(
                    '${suggestion.distance.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
              
              // --- 4. OnSuggestionSelected ---
              onSuggestionSelected: (PlaceEntity suggestion) async {
                _searchController.text = suggestion.display;
                await provider.onSuggestionSelected(suggestion);
              },
              
              // --- 5. Loading & Empty States ---
              loadingBuilder: (context) {
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
              
              noItemsFoundBuilder: (context) {
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Không tìm thấy địa điểm nào'),
                );
              },
              
              // --- 6. Config Options ---
              hideOnEmpty: true,
              hideOnLoading: false,
              hideOnSelect: true,
              debounceDuration: const Duration(milliseconds: 400),
              autoFlipDirection: true,
              hideKeyboardOnDrag: true,
            ),
          ),
          
          // ========== Map Area ==========
          Expanded(
            child: Stack(
              children: [
                _VietmapWidget(onMapCreated: provider.onMapCreated),
                if (provider.isOnMyLocation)
                  UserLocationLayer(
                    mapController: provider.vietmapController,
                    // ... other config
                  ),
              ],
            ),
          ),
        ],
      ),
      
      // ========== ActionSheet ==========
      // Auto show when provider.showPlaceDetails == true
      // Using Future.delayed() or WidgetsBinding
      floatingActionButton: _buildFloatingActionButtons(provider),
    );
  }
  
  // Helper method để build suffix icon động
  Widget? _buildSuffixIcon(MetroMapProvider provider) {
    if (provider.isSearching) {
      return SizedBox(
        width: 20,
        height: 20,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    if (provider.searchQuery.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          _searchController.clear();
          provider.clearSearch();
        },
      );
    }
    
    return null;
  }
  
  // Helper method để build FABs
  Widget _buildFloatingActionButtons(MetroMapProvider provider) {
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            mini: true,
            onPressed: provider.moveToMyLocation,
            child: const Icon(Icons.location_pin),
          ),
        ),
      ],
    );
  }
}
```

---

## 📋 Implementation Checklist Với Code Locations

### **Phase 1: Fix Syntax & Add Properties**
- [ ] **Line 12-13:** Fix `final` keyword error
- [ ] **After Line 20:** Add 8 search properties (10 lines)
- [ ] **After properties:** Add getters (15 lines)
- [ ] **After getters:** Add late final repository (1 line)
- [ ] **After repository:** Add Timer debounce (1 line)

### **Phase 2: Update Constructor & Lifecycle**
- [ ] **Constructor:** Add repository initialization (2 lines)
- [ ] **Add dispose():** Cancel timer + super.dispose() (5 lines)

### **Phase 3: Implement Methods**
- [ ] **onSearchChanged():** 50 lines dengan debounce
- [ ] **onSuggestionSelected():** 70 lines với marker logic
- [ ] **clearSearch():** 20 lines
- [ ] **closeActionSheet():** 3 lines

### **Phase 4: Screen Changes**
- [ ] Change `_MetroMapView` to StatefulWidget (1 line)
- [ ] Add `initState()` & `dispose()` (6 lines)
- [ ] Change `body: Stack` to `body: Column` (1 line)
- [ ] Add TypeAheadField configuration (60+ lines)
- [ ] Wrap map in Expanded (2 lines)
- [ ] Add ActionSheet logic (20+ lines)
- [ ] Add helper methods: `_buildSuffixIcon()`, `_buildFloatingActionButtons()` (20+ lines)

---

## 🔍 Code Quality Checklist

**Naming Conventions:**
- ✅ `_searchQuery` → Private, camelCase, clear intent
- ✅ `searchQuery` → Getter, no underscore
- ✅ `MetroMapProvider` → PascalCase, class name
- ✅ `onSearchChanged()` → camelCase, verb+past participle

**Architecture Compliance:**
- ✅ Provider ở `modules/` layer → Presentation
- ✅ Không import `data/` directly → Use repository interface
- ✅ Repository từ `domain/` interface → Implement separation
- ✅ Controller từ `vietmap_flutter_gl` → External library OK

**Error Handling:**
- ✅ Try-catch cho API calls
- ✅ Set `_errorMessage` cho user feedback
- ✅ Finally block để clear loading state
- ✅ Graceful degradation (show message, continue app)

**Lifecycle Management:**
- ✅ Dispose timer ở `dispose()`
- ✅ Initialize controller ở `initState()`
- ✅ notifyListeners() ở tất cả state changes
- ✅ Check null before using controllers

**Performance:**
- ✅ Debounce search (400ms) → Tránh API spam
- ✅ Cancel timer trước tạo mới
- ✅ Remove marker cũ trước add mới
- ✅ Single notifyListeners() per async operation

---

## 📌 Key Implementation Notes

### **Debounce Pattern:**
```
Pattern: _searchDebounce?.cancel()
         _searchDebounce = Timer(duration, () async { 
           // API call
         });

Why: Tránh gọi API 5 lần khi user nhập "hello" (h→he→hel→hell→hello)
With debounce: Chỉ gọi API 1 lần sau user dừng nhập 400ms
```

### **Marker Lifecycle:**
```
Pattern: Remove old → Add new

Why: Tránh multiple markers ở map, clear visual confusion

Code:
_currentMarker?.remove();  // Remove old if exists
_currentMarker = controller.addSymbol(...);  // Add new
```

### **Error Handling Pattern:**
```
Pattern: try { 
           API call
           Update state
         } catch (e) {
           Set _errorMessage
           Clear suggestions
         } finally {
           Clear _isSearching
           notifyListeners()
         }

Why: Always clear loading state even on error, show user message
```

### **State Notification Pattern:**
```
Pattern: notifyListeners() ở 2 nơi:
1. Immediate clear: clearSearch() → notifyListeners()
2. After async: finally block → notifyListeners()

Why: Update UI immediately + after async complete
```

---

## 🎯 Testing Checklist

**Manual Testing (Per Feature):**
- [ ] Type "Trần" → Wait 400ms → Suggestions appear
- [ ] Suggestions show correct data (display, address, distance)
- [ ] Click suggestion → Map pan to location + Marker appear
- [ ] ActionSheet slide up with place details
- [ ] Click close button → ActionSheet dismiss
- [ ] Click clear button → Search clear + Marker disappear
- [ ] Network error → Error message shows
- [ ] Type very fast → Only 1 API call (debounce working)

**Code Quality Tests:**
- [ ] No syntax errors: `fvm flutter analyze`
- [ ] No warnings: Check console output
- [ ] No memory leaks: Timer disposed properly
- [ ] Provider rebuilds only when needed: Watch context


