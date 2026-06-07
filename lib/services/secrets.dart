// ignore_for_file: constant_identifier_names

class Secrets {
  static const groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
}