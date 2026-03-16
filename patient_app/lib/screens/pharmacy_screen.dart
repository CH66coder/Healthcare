import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final _svc = FirebaseService();
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _cart = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  static const Color _primary = Color(0xFF00C896);
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B27);
  static const Color _border = Color(0xFF1E2A42);
  static const Color _text2 = Color(0xFF8B9EC7);

  final _categories = [
    'All', 'Analgesic', 'Antibiotic', 'Antifungal',
    'Antiviral', 'Antipyretic', 'Antidepressant',
    'Antidiabetic', 'Antiseptic',
  ];

  final _pharmacies = [
    'Apollo Pharmacy', 'MedPlus', 'Netmeds',
    '1mg', 'PharmEasy', 'Wellness Forever',
  ];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Safely get medicine name — handles 'Name', 'name', 'medicine_name'
  String _getName(Map<String, dynamic> med) {
    return (med['Name'] ?? med['name'] ?? med['medicine_name'] ?? '').toString().trim();
  }

  double _getPrice(Map<String, dynamic> med) {
    final p = med['price'] ?? med['Price'];
    if (p == null) return 120.0;
    return (p as num).toDouble();
  }

  Future<void> _loadMedicines() async {
    setState(() => _loading = true);
    final meds = await _svc.getMedicines(
        category: _selectedCategory == 'All' ? null : _selectedCategory);
    setState(() {
      _medicines = meds;
      _loading = false;
    });
  }

  void _addToCart(Map<String, dynamic> med) {
    final existing = _cart.indexWhere((m) => m['id'] == med['id']);
    setState(() {
      if (existing >= 0) {
        _cart[existing]['qty'] = (_cart[existing]['qty'] ?? 1) + 1;
      } else {
        _cart.add({...med, 'qty': 1, 'price': _getPrice(med)});
      }
    });
  }

  void _removeFromCart(String id) {
    setState(() => _cart.removeWhere((m) => m['id'] == id));
  }

  bool _inCart(String id) => _cart.any((m) => m['id'] == id);

  double get _cartTotal =>
      _cart.fold(0, (sum, m) => sum + _getPrice(m) * (m['qty'] as int));

  void _showCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('My Cart',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${_cart.length} items',
                      style: GoogleFonts.poppins(
                          color: _text2, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              if (_cart.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Your cart is empty',
                        style: GoogleFonts.poppins(
                            color: _text2, fontSize: 14)),
                  ),
                )
              else ...[
                ..._cart.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        const Text('💊', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getName(m),
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text('₹${_getPrice(m).toStringAsFixed(0)} each',
                                  style: GoogleFonts.poppins(
                                      color: _text2, fontSize: 11)),
                            ],
                          ),
                        ),
                        // Qty controls
                        Row(children: [
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                final idx = _cart.indexWhere(
                                    (c) => c['id'] == m['id']);
                                if (idx >= 0) {
                                  if ((_cart[idx]['qty'] as int) > 1) {
                                    _cart[idx]['qty'] =
                                        (_cart[idx]['qty'] as int) - 1;
                                  } else {
                                    _cart.removeAt(idx);
                                  }
                                }
                              });
                              setState(() {});
                            },
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2A42),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.remove,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('${m['qty']}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                final idx = _cart.indexWhere(
                                    (c) => c['id'] == m['id']);
                                if (idx >= 0) {
                                  _cart[idx]['qty'] =
                                      (_cart[idx]['qty'] as int) + 1;
                                }
                              });
                              setState(() {});
                            },
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.add,
                                  color: _primary, size: 14),
                            ),
                          ),
                        ]),
                        const SizedBox(width: 8),
                        Text(
                          '₹${(_getPrice(m) * (m['qty'] as int)).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              color: _primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    )),
                const Divider(color: Color(0xFF1E2A42)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text('₹${_cartTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            color: _primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                _PharmacySelector(
                  pharmacies: _pharmacies,
                  cart: _cart,
                  total: _cartTotal,
                  getName: _getName,
                  svc: _svc,
                  onOrderPlaced: () {
                    setState(() => _cart.clear());
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Pharmacy'),
        actions: [
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: _showCart,
            ),
            if (_cart.isNotEmpty)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B), shape: BoxShape.circle),
                  child: Center(
                    child: Text('${_cart.length}',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ]),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '🔍 Search medicines...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Color(0xFF8B9EC7)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF8B9EC7)),
                      onPressed: () {
                        _searchCtrl.clear();
                        _loadMedicines();
                        setState(() {});
                      })
                  : null,
            ),
            onChanged: (val) async {
  if (val.isEmpty) { _loadMedicines(); return; }
  setState(() => _loading = true);
  final r = await _svc.searchMedicines(val);
  setState(() { _medicines = r; _loading = false; });
},
onSubmitted: (q) async {
  if (q.isEmpty) { _loadMedicines(); return; }
  setState(() => _loading = true);
  final r = await _svc.searchMedicines(q);
  setState(() { _medicines = r; _loading = false; });
},
          ),
        ),
        // Category tabs
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: _categories.map((cat) {
              final sel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                  _loadMedicines();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _primary : _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? _primary : _border),
                  ),
                  child: Text(cat,
                      style: GoogleFonts.poppins(
                          color: sel ? Colors.white : _text2,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ),
        // Medicines grid
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _medicines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💊', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text('No medicines found',
                              style: GoogleFonts.poppins(
                                  color: _text2, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            'Run upload_medicines.js to upload\nyour medicine CSV to Firestore',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF4A5568), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: _medicines.length,
                      itemBuilder: (context, i) {
                        final med = _medicines[i];
                        final name = _getName(med);
                        final inCart = _inCart(med['id'] ?? '');
                        final price = _getPrice(med);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: inCart
                                    ? _primary.withOpacity(0.5)
                                    : _border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                    child: Text('💊',
                                        style: TextStyle(fontSize: 22))),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                name.isNotEmpty ? name : '—',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                med['Category'] ?? med['category'] ?? '',
                                style: GoogleFonts.poppins(
                                    color: _primary, fontSize: 11),
                              ),
                              Text(
                                '${med['Dosage Form'] ?? ''} • ${med['Strength'] ?? ''}',
                                style: GoogleFonts.poppins(
                                    color: _text2, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${price.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    color: const Color(0xFFFFB347),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      inCart ? _primary.withOpacity(0.3) : _primary,
                                  minimumSize: const Size(double.infinity, 34),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.zero,
                                  textStyle: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                onPressed: inCart ? null : () => _addToCart(med),
                                child: Text(inCart ? '✓ Added' : '+ Add'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ]),
      // Cart bottom bar
      bottomNavigationBar: _cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: _card,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_cart.length} items',
                        style: GoogleFonts.poppins(color: _text2, fontSize: 12)),
                    Text('₹${_cartTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showCart,
                    child: const Text('View Cart →'),
                  ),
                ),
              ]),
            )
          : null,
    );
  }
}

// ─── Pharmacy selector inside cart sheet ─────────────────────
class _PharmacySelector extends StatefulWidget {
  final List<String> pharmacies;
  final List<Map<String, dynamic>> cart;
  final double total;
  final String Function(Map<String, dynamic>) getName;
  final FirebaseService svc;
  final VoidCallback onOrderPlaced;

  const _PharmacySelector({
    required this.pharmacies,
    required this.cart,
    required this.total,
    required this.getName,
    required this.svc,
    required this.onOrderPlaced,
  });

  @override
  State<_PharmacySelector> createState() => _PharmacySelectorState();
}

class _PharmacySelectorState extends State<_PharmacySelector> {
  String? _selected;
  bool _loading = false;

  static const Color _primary = Color(0xFF00C896);
  static const Color _text2 = Color(0xFF8B9EC7);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Pharmacy',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: widget.pharmacies.map((p) {
            final sel = _selected == p;
            return GestureDetector(
              onTap: () => setState(() => _selected = p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? _primary.withOpacity(0.15)
                      : const Color(0xFF1E2535),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? _primary : const Color(0xFF1E2A42)),
                ),
                child: Text(p,
                    style: GoogleFonts.poppins(
                        color: sel ? _primary : _text2,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selected == null || _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    final id = await widget.svc
                        .placeOrder(widget.cart, _selected!, widget.total);
                    setState(() => _loading = false);
                    if (id.isNotEmpty && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('✅ Order placed at $_selected!'),
                        backgroundColor: _primary,
                      ));
                      widget.onOrderPlaced();
                    }
                  },
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Place Order — ₹${widget.total.toStringAsFixed(2)}'),
          ),
        ),
      ],
    );
  }
}