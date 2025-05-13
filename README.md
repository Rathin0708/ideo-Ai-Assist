# Voice Assistant App

A Flutter voice assistant application with press-and-hold microphone recording, Gemini AI
integration, and structured JSON output processing.

## Features

- Press-and-hold microphone button for voice recording
- Speech-to-text conversion
- Integration with Google's Gemini AI
- Structured JSON output for server communication
- Text-to-speech response feedback

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter extensions
- An API key for Google Gemini AI

### Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Setup API key:
    - Get your Gemini API key from [Google AI Studio](https://ai.google.dev/)
    - Open `lib/api_keys.dart` and replace `YOUR_GEMINI_API_KEY` with your actual API key

### Running the App

## Libraries Used

- `speech_to_text`: ^7.0.0
- `google_generative_ai`: ^0.3.2
- `flutter_tts`: ^3.6.3
- `provider`: ^6.1.2

## Architecture

This project follows Clean Architecture principles with the following layers:

### Domain Layer

- **Entities**: Core business models
- **Repositories**: Abstract definitions of data operations
- **Use Cases**: Application-specific business rules

### Data Layer

- **Models**: Implementation of entities with data conversion logic
- **Data Sources**: External API integrations (Speech, AI)
- **Repositories**: Concrete implementations of domain repositories

### Presentation Layer

- **Screens**: UI containers and composition
- **Widgets**: Reusable UI components
- **State**: Application state management using Provider

### Core

- **Util**: Shared utilities
- **Injection**: Dependency injection