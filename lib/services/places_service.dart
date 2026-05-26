import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/places_config.dart';
import 'address_service.dart';

class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  final AddressService _mockAddressService = AddressService();
  bool get _usePlaces => PlacesConfig.isConfigured;

  Future<List<AddressSuggestion>> searchAddresses(String query) async {
    if (!_usePlaces) {
      return _mockAddressService.searchAddresses(query);
    }

    if (query.length < 2) return [];

    try {
      final url = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': query,
          'components': 'country:us',
          'types': 'address',
          'key': PlacesConfig.apiKey,
        },
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        return _mockAddressService.searchAddresses(query);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List<dynamic>? ?? [];

      final results = <AddressSuggestion>[];
      for (final prediction in predictions) {
        final description = prediction['description'] as String? ?? '';
        final parts = description.split(',').map((s) => s.trim()).toList();

        final street = parts.isNotEmpty ? parts[0] : description;
        final city = parts.length > 1 ? parts[1] : '';
        final stateZip = parts.length > 2 ? parts[2] : '';
        final stateParts = stateZip.split(' ');
        final state = stateParts.isNotEmpty ? stateParts[0] : 'TX';
        final zip = stateParts.length > 1 ? stateParts[1] : '';

        results.add(AddressSuggestion(
          fullAddress: description,
          street: street,
          city: city,
          state: state,
          zip: zip,
        ));
      }
      return results;
    } catch (_) {
      return _mockAddressService.searchAddresses(query);
    }
  }

  String? getCityFromAddress(String address) {
    if (!_usePlaces) {
      return _mockAddressService.getCityFromAddress(address);
    }
    final parts = address.split(',').map((s) => s.trim()).toList();
    return parts.length > 1 ? parts[1] : null;
  }
}
