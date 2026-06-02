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
    if (query.trim().length < 2) return [];

    if (!_usePlaces) {
      return _mockAddressService.searchAddresses(query);
    }

    try {
      // Places API (New) Autocomplete — supports CORS so it can be called
      // directly from the web app with an HTTP-referrer-restricted key.
      final url = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': PlacesConfig.apiKey,
        },
        body: jsonEncode({
          'input': query,
          'includedRegionCodes': ['us'],
        }),
      );

      if (response.statusCode != 200) {
        return _mockAddressService.searchAddresses(query);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];

      final results = <AddressSuggestion>[];
      for (final suggestion in suggestions) {
        final prediction =
            (suggestion as Map<String, dynamic>)['placePrediction']
                as Map<String, dynamic>?;
        if (prediction == null) continue;

        final fullText =
            (prediction['text'] as Map<String, dynamic>?)?['text'] as String? ??
                '';
        final structured =
            prediction['structuredFormat'] as Map<String, dynamic>?;
        final mainText = (structured?['mainText']
            as Map<String, dynamic>?)?['text'] as String?;
        final secondaryText = (structured?['secondaryText']
            as Map<String, dynamic>?)?['text'] as String?;

        final street = mainText ?? fullText.split(',').first.trim();
        final secondaryParts = (secondaryText ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final city = secondaryParts.isNotEmpty ? secondaryParts[0] : '';
        final stateZip = secondaryParts.length > 1 ? secondaryParts[1] : '';
        final stateParts = stateZip.split(' ');
        final state = stateParts.isNotEmpty && stateParts[0].isNotEmpty
            ? stateParts[0]
            : 'TX';
        final zip = stateParts.length > 1 ? stateParts[1] : '';

        results.add(AddressSuggestion(
          fullAddress: fullText.isNotEmpty
              ? fullText
              : [street, city, '$state $zip'.trim()]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
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
