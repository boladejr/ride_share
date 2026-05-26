import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/address_service.dart';
import '../theme.dart';
import 'route_search_page.dart';

class RidePage extends StatefulWidget {
  const RidePage({super.key});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  final _addressService = AddressService();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String? _selectedPickupAddress;
  String? _selectedDropoffAddress;
  List<AddressSuggestion> _pickupSuggestions = [];
  List<AddressSuggestion> _dropoffSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropoffSuggestions = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _onPickupChanged(String value) {
    setState(() {
      _selectedPickupAddress = null;
      _pickupSuggestions = _addressService.searchAddresses(value);
      _showPickupSuggestions = _pickupSuggestions.isNotEmpty;
    });
  }

  void _onDropoffChanged(String value) {
    setState(() {
      _selectedDropoffAddress = null;
      _dropoffSuggestions = _addressService.searchAddresses(value);
      _showDropoffSuggestions = _dropoffSuggestions.isNotEmpty;
    });
  }

  void _selectPickup(AddressSuggestion suggestion) {
    setState(() {
      _pickupController.text = suggestion.fullAddress;
      _selectedPickupAddress = suggestion.fullAddress;
      _showPickupSuggestions = false;
      _pickupSuggestions = [];
    });
  }

  void _selectDropoff(AddressSuggestion suggestion) {
    setState(() {
      _dropoffController.text = suggestion.fullAddress;
      _selectedDropoffAddress = suggestion.fullAddress;
      _showDropoffSuggestions = false;
      _dropoffSuggestions = [];
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _search() {
    if (_selectedPickupAddress == null || _selectedDropoffAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and drop-off addresses from suggestions')),
      );
      return;
    }

    final originCity = _addressService.getCityFromAddress(_selectedPickupAddress!);
    final destCity = _addressService.getCityFromAddress(_selectedDropoffAddress!);

    if (originCity.isEmpty || destCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine cities. Please select valid Texas addresses.')),
      );
      return;
    }

    if (originCity == destCity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and drop-off must be in different cities')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteSearchPage(
          origin: originCity,
          destination: destCity,
          date: _selectedDate,
          pickupAddress: _selectedPickupAddress,
          dropoffAddress: _selectedDropoffAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                Text(
                  'Book a ride',
                  style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your address for door-to-door pickup within Texas',
                  style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Search Form
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find your route', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                    const SizedBox(height: 20),

                    // Pickup Address
                    _buildAddressField(
                      controller: _pickupController,
                      label: 'Pickup address',
                      hint: 'e.g. 1100 Congress Ave, Austin',
                      icon: Icons.circle_outlined,
                      suggestions: _pickupSuggestions,
                      showSuggestions: _showPickupSuggestions,
                      onChanged: _onPickupChanged,
                      onSelect: _selectPickup,
                      isSelected: _selectedPickupAddress != null,
                    ),

                    const SizedBox(height: 14),

                    // Drop-off Address
                    _buildAddressField(
                      controller: _dropoffController,
                      label: 'Drop-off address',
                      hint: 'e.g. 300 Alamo Plaza, San Antonio',
                      icon: Icons.location_on_outlined,
                      suggestions: _dropoffSuggestions,
                      showSuggestions: _showDropoffSuggestions,
                      onChanged: _onDropoffChanged,
                      onSelect: _selectDropoff,
                      isSelected: _selectedDropoffAddress != null,
                    ),

                    const SizedBox(height: 14),

                    // Date Picker
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Travel date',
                          prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor, size: 16),
                          filled: true,
                          fillColor: AppTheme.surfaceColor,
                        ),
                        child: Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate), style: GoogleFonts.inter(fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _search,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text('Search rides'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text('500+ seats booked and counting', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary, fontWeight: FontWeight.w500)),

          const SizedBox(height: 48),

          // Quick routes section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Popular routes', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                const SizedBox(height: 6),
                Text('Tap to quick-search', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 18),
                _quickRouteChip('Austin', 'San Antonio'),
                const SizedBox(height: 8),
                _quickRouteChip('Austin', 'Houston'),
                const SizedBox(height: 8),
                _quickRouteChip('Dallas', 'Austin'),
                const SizedBox(height: 8),
                _quickRouteChip('San Antonio', 'Houston'),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 12),
                Text('\u00a9 2026 RideShare. All rights reserved.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required List<AddressSuggestion> suggestions,
    required bool showSuggestions,
    required ValueChanged<String> onChanged,
    required ValueChanged<AddressSuggestion> onSelect,
    required bool isSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 16),
            suffixIcon: isSelected
                ? const Icon(Icons.check_circle, color: AppTheme.successColor, size: 18)
                : null,
            filled: true,
            fillColor: AppTheme.surfaceColor,
          ),
        ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return InkWell(
                  onTap: () => onSelect(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textTertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.street, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                              Text('${s.city}, ${s.state} ${s.zip}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _quickRouteChip(String from, String to) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteSearchPage(
              origin: from,
              destination: to,
              date: DateTime.now(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_outlined, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(from, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 14, color: AppTheme.textTertiary),
            const SizedBox(width: 8),
            Text(to, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
