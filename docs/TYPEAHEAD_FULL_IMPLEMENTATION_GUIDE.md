# Hướng Dẫn Implement TypeAhead Với Marker & ActionSheet - Chi Tiết

## 📋 Tổng Quan Flow Hoàn Chỉnh

```
1️⃣ User nhập ký tự "Trần"
   ↓
2️⃣ TypeAheadField.suggestionsCallback() trigger
   ├─ Provider.onSearchChanged("Trần")
   ├─ Call repository.searchPlaces("Trần")
   └─ Return List<PlaceEntity> gợi ý
   ↓
3️⃣ TypeAheadField hiển thị dropdown với 10 suggestions
   (display + address + distance)
   ↓
4️⃣ User click 1 item trong dropdown
   └─ TypeAheadField.onSuggestionSelected(place)
   ↓
5️⃣ Provider.onSuggestionSelected(place)
   ├─ Call repository.getPlaceDetails(place.refId)
   ├─ Nhận PlaceDetailEntity (chứa lat, lng)
   ├─ Pan map camera tới (lat, lng)
   ├─ Add marker tại vị trí
   └─ Update state để show ActionSheet
   ↓
6️⃣ ActionSheet hiển thị chi tiết place
   ├─ Title: place.name
   ├─ Address: place.address
   ├─ Distance: place.distance km
   ├─ Buttons: Directions, Close, Share
   └─ Auto dismiss khi click ngoài hoặc close button
```

---

## 🏗️ Cấu Trúc Code Cần Implement

### **Phần 1: Provider State & Methods**

**File:** `metro_map_provider.dart`

**A. State Properties Cần Thêm:**

```
// Search & Autocomplete
- String _searchQuery = ""
- List<PlaceEntity> _searchSuggestions = []
- bool _isSearching = false

// Selected Place
- PlaceEntity? _selectedPlace
- PlaceDetailEntity? _selectedPlaceDetails

// Marker & Map
- Symbol? _currentMarker  (để track marker hiện tại)

// ActionSheet
- bool _showPlaceDetails = false
- String? _errorMessage

// Controller
- TextEditingController _searchController = TextEditingController()
```

**Pseudo-code structure:**
```dart
class MetroMapProvider extends ChangeNotifier {
  // ... existing code ...
  
  // NEW: Search properties
  String _searchQuery = "";
  List<PlaceEntity> _searchSuggestions = [];
  bool _isSearching = false;
  
  // NEW: Selected place properties
  PlaceEntity? _selectedPlace;
  PlaceDetailEntity? _selectedPlaceDetails;
  
  // NEW: UI state
  bool _showPlaceDetails = false;
  Symbol? _currentMarker;
  String? _errorMessage;
  
  // Getters
  String get searchQuery => _searchQuery;
  List<PlaceEntity> get searchSuggestions => _searchSuggestions;
  bool get isSearching => _isSearching;
  PlaceEntity? get selectedPlace => _selectedPlace;
  PlaceDetailEntity? get selectedPlaceDetails => _selectedPlaceDetails;
  bool get showPlaceDetails => _showPlaceDetails;
  String? get errorMessage => _errorMessage;
  
  // Methods
  Future<void> onSearchChanged(String query) async { }
  Future<void> onSuggestionSelected(PlaceEntity place) async { }
  void clearSearch() { }
  void closeActionSheet() { }
  void clearMarker() { }
}
```

---

**B. Method 1: onSearchChanged(String query)**

**Purpose:** Gọi khi user nhập ký tự vào TypeAheadField

**Logic:**
```
1. Update _searchQuery = query
2. If query.isEmpty → Clear suggestions & return
3. Set _isSearching = true
4. Call repository.searchPlaces(PlaceRequest(text: query))
5. Update _searchSuggestions với response
6. Set _isSearching = false
7. notifyListeners()
```

**Error handling:**
```
- Nếu network error → Set _errorMessage & clear suggestions
- Nếu API return error → Show error message
- Nếu empty result → _searchSuggestions = [] (framework sẽ show noItemsFoundBuilder)
```

**Debounce:**
```
- Timer duration: 300-400ms
- Cancel trước timer nếu user tiếp tục nhập
- Tránh gọi API quá nhiều lần
```

---

**C. Method 2: onSuggestionSelected(PlaceEntity place)**

**Purpose:** Gọi khi user click 1 item trong dropdown suggestions

**Logic:**
```
1. Update _selectedPlace = place
2. Update _searchController.text = place.display
3. Set _isSearching = true
4. Call repository.getPlaceDetails(PlaceDetailsRequest(refid: place.refId))
5. Nhận PlaceDetailEntity chứa lat, lng
6. Update _selectedPlaceDetails = response
7. Pan map camera:
   - _vietmapController.moveCamera(
       CameraUpdate.newLatLngZoom(
         LatLng(lat, lng),
         16.0
       )
     )
8. Add marker tại (lat, lng):
   - Xoá marker cũ nếu có: _currentMarker?.remove()
   - Thêm marker mới: _currentMarker = addSymbol(...)
   - Marker config:
     * geometry: LatLng(lat, lng)
     * title: place.name
     * icon: custom icon hoặc pin icon
     * color: red hoặc primary color
9. Set _showPlaceDetails = true (trigger ActionSheet show)
10. Set _isSearching = false
11. notifyListeners()
```

**Error handling:**
```
- Nếu getPlaceDetails API fail → Show error & keep current state
- Nếu moveCamera fail → Log error nhưng vẫn show ActionSheet
- Nếu addMarker fail → Show error message
```

---

**D. Method 3: clearSearch()**

**Purpose:** Clear toàn bộ search state khi user click clear button hoặc close ActionSheet

**Logic:**
```
1. _searchQuery = ""
2. _searchSuggestions = []
3. _selectedPlace = null
4. _selectedPlaceDetails = null
5. _searchController.clear()
6. _showPlaceDetails = false
7. Clear marker: _currentMarker?.remove()
8. _currentMarker = null
9. _errorMessage = null
10. notifyListeners()
```

---

**E. Method 4: closeActionSheet()**

**Purpose:** Đóng ActionSheet khi user click close button

**Logic:**
```
1. _showPlaceDetails = false
2. notifyListeners()
3. (Không clear marker, vẫn giữ marker ở map)
4. (Nếu muốn, user có thể click clear search để xoá marker)
```

---

**F. Method 5: clearMarker() [Optional]**

**Purpose:** Xoá marker từ map

**Logic:**
```
1. If _currentMarker != null:
   _currentMarker?.remove()
   _currentMarker = null
2. notifyListeners()
```

---

### **Phần 2: UI Screen Implementation**

**File:** `metro_map_screen.dart`

**A. Screen Architecture**

```dart
// Change from StatelessWidget → StatefulWidget
// để manage TextEditingController lifecycle

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
    // ... UI code ...
  }
}
```

**Lý do StatefulWidget:**
- TypeAheadField cần TextEditingController
- Controller cần lifecycle management (dispose)
- Provider có thể access controller through context

---

**B. Layout Structure**

**Current (Sai):**
```dart
body: Stack(
  children: [
    TypeAheadField(...),      // ← Suggestions overlay có thể bị map che
    _VietmapWidget(...),      // ← Map expand đầy
    UserLocationLayer(...),
  ],
)
```

**Khuyên làm (Đúng):**
```dart
body: Column(
  children: [
    // TypeAheadField ở top
    Padding(
      padding: EdgeInsets.all(8),
      child: TypeAheadField<PlaceEntity>(
        // Configuration
      ),
    ),
    
    // Map expand chiếm phần còn lại
    Expanded(
      child: Stack(
        children: [
          _VietmapWidget(onMapCreated: provider.onMapCreated),
          if (provider.isOnMyLocation)
            UserLocationLayer(...),
        ],
      ),
    ),
  ],
)
```

**Lợi ích:**
- TypeAheadField luôn ở trên, dễ access
- Suggestions dropdown không bị map che
- Map chiếm proper responsive space
- Layout clean & maintainable

---

**C. TypeAheadField Configuration**

**1. TextFieldConfiguration:**

```
Cấu hình:
- controller: _searchController
- hint: 'Tìm kiếm địa điểm...'
- prefixIcon: Icons.location_on
- suffixIcon: Show loading + clear button
  
Dynamic suffixIcon:
  If provider.isSearching:
    Show CircularProgressIndicator (khi gọi API)
  Else if provider.searchQuery.isNotEmpty:
    Show IconButton clear
    onClick: _searchController.clear() + provider.clearSearch()
  Else:
    null
    
Styling:
- borderRadius: 10
- border: OutlineInputBorder
- fontSize: 16
- contentPadding: EdgeInsets.all(8)
```

---

**2. SuggestionsCallback:**

```
async callback với parameter pattern (search text):

if pattern.isEmpty:
  return []  // Không show suggestions

try:
  await provider.onSearchChanged(pattern)
  return provider.searchSuggestions
  
catch error:
  debugPrint(error)
  return []
```

---

**3. ItemBuilder (Suggestions UI):**

```
Return ListTile cho mỗi PlaceEntity:

Leading:
  Icon(Icons.location_on, color: Colors.grey)

Title:
  Text(suggestion.display)
  maxLines: 1, overflow: ellipsis

Subtitle:
  Text(suggestion.address)
  maxLines: 1, overflow: ellipsis
  fontSize: 12

Trailing:
  Text('${suggestion.distance.toStringAsFixed(1)} km')
  fontSize: 12

OnTap:
  provider.onSuggestionSelected(suggestion)
```

---

**4. OnSuggestionSelected:**

```
async callback với parameter suggestion (PlaceEntity):

_searchController.text = suggestion.display
await provider.onSuggestionSelected(suggestion)

// TypeAheadField sẽ auto hide suggestions & keyboard
// (handled by framework if hideOnSelect: true)
```

---

**5. Loading & Empty States:**

```
loadingBuilder:
  Return Container with CircularProgressIndicator(strokeWidth: 2)
  padding: EdgeInsets.all(8)

noItemsFoundBuilder:
  Return Container with Text('Không tìm thấy địa điểm nào')
  padding: EdgeInsets.all(8)

hideOnEmpty: true
hideOnLoading: false  // Keep visible khi loading
hideOnSelect: true

debounceDuration: Duration(milliseconds: 400)
autoFlipDirection: true
hideKeyboardOnDrag: true
```

---

### **Phần 3: Marker Implementation**

**File:** `metro_map_provider.dart` - onSuggestionSelected method

**A. Remove Old Marker:**

```
if (_currentMarker != null):
  _currentMarker.remove()
  _currentMarker = null
```

**Lý do:** Tránh multiple markers ở map

---

**B. Add New Marker:**

```
Dùng VietmapController.addSymbol() method:

SymbolOptions config:
  - geometry: LatLng(_selectedPlaceDetails.latitude, 
                     _selectedPlaceDetails.longitude)
  - iconImage: 'marker'  (hoặc custom icon name)
  - iconSize: 1.0 (hoặc tùy design)
  - iconColor: Colors.red  (hoặc Colors.blue)
  - textField: '{title}'  (show title từ place.name)
  - textOffset: [0, 1.5]  (offset text từ marker)
  - textSize: 14

_currentMarker = await _vietmapController.addSymbol(symbolOptions)
```

**Note:**
- VietmapController method có thể là addSymbol, addMarker, hoặc tương tự
- Check tài liệu VietmapGL package để xác minh exact method name & parameters

---

**C. Move Camera to Marker:**

```
_vietmapController.moveCamera(
  CameraUpdate.newLatLngZoom(
    LatLng(
      _selectedPlaceDetails.latitude,
      _selectedPlaceDetails.longitude
    ),
    16.0  // Zoom level
  )
)
```

---

### **Phần 4: ActionSheet Implementation**

**File:** `metro_map_screen.dart` - build method

**A. ActionSheet Trigger:**

```
Kiểm tra provider.showPlaceDetails:

if (provider.showPlaceDetails && provider.selectedPlaceDetails != null):
  Show ActionSheet (dùng showModalBottomSheet)
else:
  ActionSheet ẩn
```

---

**B. ActionSheet UI Structure:**

```
showModalBottomSheet(
  context: context,
  isDismissible: true,  // Click ngoài để đóng
  builder: (context) {
    return Container(
      // ===== HEADER =====
      Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Chi tiết địa điểm', fontSize: 18, fontWeight: bold),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                provider.closeActionSheet()
                Navigator.pop(context)
              },
            ),
          ],
        ),
      ),
      
      Divider(),
      
      // ===== CONTENT =====
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(
              provider.selectedPlace.name,
              fontSize: 20,
              fontWeight: bold,
            ),
            SizedBox(height: 8),
            
            // Address
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.selectedPlace.address,
                    maxLines: 2,
                    overflow: ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Distance
            Row(
              children: [
                Icon(Icons.straighten, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  '${provider.selectedPlace.distance.toStringAsFixed(1)} km',
                  fontSize: 16,
                ),
              ],
            ),
          ],
        ),
      ),
      
      Divider(),
      
      // ===== ACTIONS =====
      Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Directions Button
            ElevatedButton.icon(
              icon: Icon(Icons.directions),
              label: Text('Chỉ đường'),
              onPressed: () {
                // TODO: Open Google Maps / Apple Maps
                // hoặc show directions UI
              },
            ),
            
            // Share Button
            ElevatedButton.icon(
              icon: Icon(Icons.share),
              label: Text('Chia sẻ'),
              onPressed: () {
                // TODO: Share place details via social/messaging
              },
            ),
            
            // Close Button
            ElevatedButton(
              onPressed: () {
                provider.closeActionSheet()
                Navigator.pop(context)
              },
              child: Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  },
)
```

---

**C. Auto Show/Dismiss Logic:**

```
Location: _MetroMapViewState.build() method

// Watch provider state
final provider = context.watch<MetroMapProvider>();

// Auto show ActionSheet khi showPlaceDetails = true
// Dùng WidgetsBinding.instance.addPostFrameCallback()
// để show sau build complete

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (provider.showPlaceDetails && 
      provider.selectedPlaceDetails != null &&
      !isActionSheetOpen) {
    showModalBottomSheet(...);
    isActionSheetOpen = true;  // Track state
  }
});

// Hoặc đơn giản hơn:
// Dùng Future.delayed() để show sau 100ms
Future.delayed(Duration(milliseconds: 100), () {
  if (provider.showPlaceDetails) {
    showModalBottomSheet(...);
  }
});
```

**Alternative:** Dùng showDialog thay showModalBottomSheet nếu muốn dialog instead of bottom sheet.

---

## 🔄 Chi Tiết Flow Từng Bước

### **BƯỚC 1: User Nhập "Trần"**

```
Action: User types "Trần" in TypeAheadField
  ↓
TypeAheadField.onChanged("Trần")
  ├─ Trigger suggestionsCallback("Trần")
  │
  └─ suggestionsCallback:
      if pattern.isEmpty: return []
      
      await provider.onSearchChanged("Trần")
        ├─ _searchQuery = "Trần"
        ├─ _isSearching = true
        ├─ notifyListeners() ← UI rebuild
        │  └─ suffixIcon shows CircularProgressIndicator
        │
        ├─ Call repository.searchPlaces("Trần")
        │  └─ API call: GET /api/search/v4?text=Trần&apikey=...
        │     Response: List<PlaceDtoResponse>
        │
        ├─ _searchSuggestions = result.map(toEntity()).toList()
        ├─ _isSearching = false
        └─ notifyListeners() ← UI rebuild
           └─ Suggestions dropdown appears with items
```

**UI Changes:**
```
Before typing: Empty TypeAheadField
During typing: Loading indicator in suffix
After API response: Dropdown list with 10 suggestions
```

---

### **BƯỚC 2: API Return Suggestions**

```
TypeAheadField.itemBuilder() được gọi cho mỗi suggestion:
  ├─ itemBuilder(context, PlaceEntity)
  │  └─ Return ListTile(
  │       leading: location_on icon
  │       title: place.display ("197 Đường Trần...")
  │       subtitle: place.address ("Phường...")
  │       trailing: distance ("5.2 km")
  │     )
  │
  └─ TypeAheadField render dropdown với 10 items
```

**UI:** Dropdown list hiển thị dưới TypeAheadField

---

### **BƯỚC 3: User Click 1 Suggestion**

```
Action: User clicks ListTile trong dropdown
  ↓
TypeAheadField.onSuggestionSelected(PlaceEntity place)
  ├─ _searchController.text = place.display
  ├─ await provider.onSuggestionSelected(place)
  │
  └─ Provider logic:
      ├─ _selectedPlace = place
      ├─ _isSearching = true
      ├─ notifyListeners()
      │
      ├─ Call repository.getPlaceDetails(place.refId)
      │  └─ API call: GET /api/place/v4?refid=...&apikey=...
      │     Response: PlaceDetailsDtoResponse (chứa lat, lng)
      │
      ├─ _selectedPlaceDetails = response.toEntity()
      │
      ├─ Pan map camera:
      │  await _vietmapController.moveCamera(
      │    CameraUpdate.newLatLngZoom(
      │      LatLng(response.latitude, response.longitude),
      │      16.0
      │    )
      │  )
      │
      ├─ Remove old marker (nếu có)
      │  _currentMarker?.remove()
      │
      ├─ Add new marker:
      │  _currentMarker = _vietmapController.addSymbol(
      │    SymbolOptions(
      │      geometry: LatLng(lat, lng),
      │      iconImage: 'marker_icon',
      │      title: place.name,
      │      ...
      │    )
      │  )
      │
      ├─ _showPlaceDetails = true
      ├─ _isSearching = false
      └─ notifyListeners() ← Trigger ActionSheet show
```

**UI Changes:**
```
1. Dropdown suggestions auto disappear (hideOnSelect: true)
2. Keyboard dismiss
3. Map pan/zoom tới location
4. Marker appears trên map
5. ActionSheet slide up từ bottom
```

---

### **BƯỚC 4: ActionSheet Hiển Thị**

```
Provider.showPlaceDetails = true
  ↓
build() method detect showPlaceDetails == true
  ├─ showModalBottomSheet(
  │   builder: (context) {
  │     return ActionSheet UI
  │   }
  │ )
  │
  └─ ActionSheet shows:
      ├─ Title: "Chi tiết địa điểm"
      ├─ Place name: provider.selectedPlace.name
      ├─ Address: provider.selectedPlace.address
      ├─ Distance: provider.selectedPlace.distance km
      └─ Action buttons:
          ├─ Chỉ đường (Directions)
          ├─ Chia sẻ (Share)
          └─ Đóng (Close)
```

---

### **BƯỚC 5: Close ActionSheet**

```
Action 1: User clicks Close button
  ├─ provider.closeActionSheet()
  │  ├─ _showPlaceDetails = false
  │  ├─ notifyListeners()
  │  └─ ActionSheet auto dismiss
  │
  └─ Marker stays ở map

Action 2: User clicks ngoài ActionSheet (isDismissible: true)
  └─ ActionSheet dismiss
     Marker stays ở map

Action 3: User clicks clear search button
  ├─ _searchController.clear()
  ├─ provider.clearSearch()
  │  ├─ _searchQuery = ""
  │  ├─ _searchSuggestions = []
  │  ├─ _selectedPlace = null
  │  ├─ _showPlaceDetails = false
  │  ├─ Remove marker: _currentMarker?.remove()
  │  └─ notifyListeners()
  │
  └─ ActionSheet dismiss
     Marker disappear từ map
     Search field trở về trống
```

---

## 📋 Implementation Checklist Chi Tiết

### **Phase 1: Setup Dependencies**
- [ ] Verify `flutter_typeahead: ^4.8.0` trong pubspec.yaml
- [ ] Run `fvm flutter pub get`
- [ ] Import `flutter_typeahead` package trong metro_map_screen.dart

---

### **Phase 2: Update MetroMapProvider**

**State Properties:**
- [ ] Add `String _searchQuery`
- [ ] Add `List<PlaceEntity> _searchSuggestions`
- [ ] Add `bool _isSearching`
- [ ] Add `PlaceEntity? _selectedPlace`
- [ ] Add `PlaceDetailEntity? _selectedPlaceDetails`
- [ ] Add `bool _showPlaceDetails`
- [ ] Add `Symbol? _currentMarker`
- [ ] Add `String? _errorMessage`

**Getters:**
- [ ] Add getter cho mỗi property

**Methods:**
- [ ] Implement `Future<void> onSearchChanged(String query)`
  - [ ] Update _searchQuery
  - [ ] Clear suggestions nếu empty
  - [ ] Implement debounce (Timer 300-400ms)
  - [ ] Call repository.searchPlaces()
  - [ ] Update _searchSuggestions
  - [ ] Error handling
  
- [ ] Implement `Future<void> onSuggestionSelected(PlaceEntity place)`
  - [ ] Update _selectedPlace
  - [ ] Set _isSearching = true
  - [ ] Call repository.getPlaceDetails()
  - [ ] Update _selectedPlaceDetails
  - [ ] Pan map: moveCamera()
  - [ ] Remove old marker
  - [ ] Add new marker
  - [ ] Set _showPlaceDetails = true
  - [ ] notifyListeners()
  - [ ] Error handling
  
- [ ] Implement `void clearSearch()`
  - [ ] Clear all search properties
  - [ ] Remove marker
  - [ ] Clear controller text
  - [ ] notifyListeners()
  
- [ ] Implement `void closeActionSheet()`
  - [ ] Set _showPlaceDetails = false
  - [ ] notifyListeners()

---

### **Phase 3: Update Metro Map Screen**

**Structural Changes:**
- [ ] Change `_MetroMapView` từ StatelessWidget → StatefulWidget
- [ ] Change `body: Stack()` → `body: Column()`

**TextEditingController:**
- [ ] Create late TextEditingController `_searchController`
- [ ] Initialize in initState()
- [ ] Dispose in dispose()

**TypeAheadField Configuration:**
- [ ] Add TypeAheadField<PlaceEntity> widget
- [ ] Configure textFieldConfiguration
  - [ ] Set controller: _searchController
  - [ ] Set hint text: "Tìm kiếm địa điểm..."
  - [ ] Set prefixIcon: Icons.location_on
  - [ ] Dynamic suffixIcon (loading + clear)
  - [ ] Set styling (border, radius, fontSize)
  
- [ ] Configure suggestionsCallback
  - [ ] Check pattern.isEmpty
  - [ ] Call provider.onSearchChanged(pattern)
  - [ ] Return provider.searchSuggestions
  - [ ] Error handling
  
- [ ] Configure itemBuilder
  - [ ] Return ListTile with place info
  - [ ] Show leading icon
  - [ ] Show title: display
  - [ ] Show subtitle: address
  - [ ] Show trailing: distance
  
- [ ] Configure onSuggestionSelected
  - [ ] Update controller text
  - [ ] Call provider.onSuggestionSelected(place)
  
- [ ] Configure loading/empty states
  - [ ] loadingBuilder: show CircularProgressIndicator
  - [ ] noItemsFoundBuilder: show "No results" message
  - [ ] Set hideOnEmpty: true
  - [ ] Set hideOnLoading: false
  - [ ] Set hideOnSelect: true
  - [ ] Set debounceDuration: 400ms
  - [ ] Set autoFlipDirection: true
  - [ ] Set hideKeyboardOnDrag: true

**Map Layout:**
- [ ] Wrap _VietmapWidget & UserLocationLayer trong Expanded
- [ ] Ensure TypeAheadField ở top của Column

**ActionSheet Implementation:**
- [ ] Setup: Detect provider.showPlaceDetails in build()
- [ ] Show ActionSheet khi showPlaceDetails == true
  - [ ] Use showModalBottomSheet()
  - [ ] isDismissible: true
  - [ ] Create ActionSheet UI:
    * Header: "Chi tiết địa điểm" + close button
    * Content: name, address, distance
    * Actions: Directions, Share, Close buttons
  
- [ ] Auto dismiss when:
  - [ ] Close button clicked
  - [ ] User click ngoài ActionSheet
  - [ ] Clear search button clicked

---

### **Phase 4: Marker Implementation**

- [ ] Check VietmapGL package documentation để xác minh:
  - [ ] Exact method name: addSymbol() hoặc addMarker()
  - [ ] SymbolOptions/MarkerOptions parameters
  - [ ] Geometry format: LatLng()
  - [ ] Icon name/color format
  
- [ ] Implement marker lifecycle:
  - [ ] Remove old marker: _currentMarker?.remove()
  - [ ] Add new marker: _currentMarker = controller.addSymbol()
  - [ ] Store reference để remove sau

---

### **Phase 5: Repository & API Integration**

- [ ] Verify MetroMapRepository has:
  - [ ] `searchPlaces(PlaceRequest request)` method
  - [ ] `getPlaceDetails(PlaceDetailsRequest request)` method
  
- [ ] Verify DTOs have proper fromJson() → Entity mapping

---

### **Phase 6: Testing**

**Functional Tests:**
- [ ] Type text → suggestions appear
- [ ] Suggestions show correct data (display, address, distance)
- [ ] Click suggestion → marker appears ✅
- [ ] Click suggestion → map pan/zoom ✅
- [ ] Click suggestion → ActionSheet show ✅
- [ ] Click close button → ActionSheet dismiss
- [ ] Click clear button → search clears + marker disappears
- [ ] Network error → error message shows

**UI Tests:**
- [ ] Suggestions dropdown not hidden by map ✅
- [ ] Loading indicator visible during API call ✅
- [ ] "No results" message shows when empty ✅
- [ ] Debounce working (API calls reduced) ✅
- [ ] Keyboard dismiss after select ✅
- [ ] ActionSheet modal overlay works ✅

**Edge Cases:**
- [ ] Type empty string → no suggestions
- [ ] Very long address → ellipsis ✅
- [ ] Quick selection → debounce still works
- [ ] Network timeout → handle gracefully
- [ ] Invalid ref_id → show error message

---

## 🔗 Dependencies & Data Flow

```
Screen (_MetroMapScreen)
  ├─ TypeAheadField<PlaceEntity>
  │  ├─ suggestionsCallback → provider.onSearchChanged()
  │  └─ onSuggestionSelected → provider.onSuggestionSelected()
  │
  ├─ Provider (MetroMapProvider)
  │  ├─ onSearchChanged()
  │  │  ├─ repository.searchPlaces()
  │  │  └─ Update _searchSuggestions
  │  │
  │  └─ onSuggestionSelected()
  │     ├─ repository.getPlaceDetails()
  │     ├─ moveCamera()
  │     ├─ addMarker()
  │     └─ showActionSheet()
  │
  ├─ Repository (MetroMapRepository)
  │  ├─ searchPlaces() → API call
  │  └─ getPlaceDetails() → API call
  │
  └─ VietmapController
     ├─ moveCamera()
     └─ addSymbol()
```

---

## 🎯 Kết Luận

**Implementation Flow Summary:**

1. **Setup:** TypeAheadField + Provider state
2. **Type:** suggestionsCallback → API search
3. **Select:** onSuggestionSelected → API detail → Marker
4. **Show:** Marker appears + ActionSheet shows
5. **Close:** ActionSheet dismiss, Marker stays
6. **Clear:** Search clear → all state reset

**Key Points:**
- ✅ Debounce để tránh API spam
- ✅ Marker lifecycle: remove old → add new
- ✅ ActionSheet auto show khi showPlaceDetails=true
- ✅ Layout: Column (TypeAhead) + Expanded (Map)
- ✅ Error handling ở mỗi API call


