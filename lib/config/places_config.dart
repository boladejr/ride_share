class PlacesConfig {
  // TODO: Replace with your Google Places API key from
  // https://console.cloud.google.com/apis/credentials
  // Make sure "Places API" is enabled in your Google Cloud project.
  static const String apiKey = 'AIzaSyAUFOfdzgMmt5dz7GqkxJmvlNvW1fydLX4';

  static bool get isConfigured =>
      apiKey != 'YOUR_GOOGLE_PLACES_API_KEY';
}
