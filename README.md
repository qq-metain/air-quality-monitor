# Air Quality Monitor

## Problem Statement
Urban users often make daily decisions about going outside, exercising, commuting, or opening windows without knowing the current air quality around them. Air Quality Monitor helps users check local air quality and receive practical advice based on real environmental data.

## Connected Environment Theme
This app connects the mobile device, location sensing, real-time air quality data, local history storage, weekly trend visualisation, and AI-generated health advice. It turns environmental data into everyday decisions.

## Main Features
- Splash screen and login/register system
- Current location detection
- Real-time air quality data
- AQI and pollutant detail cards
- AI health advice
- Local history records
- Weekly trend chart
- Chinese/English language switch

## APIs and Services
- Geolocator for location detection
- Open-Meteo Air Quality API for environmental data
- DeepSeek API for AI health advice
- SQLite for local data storage

## Data Handling
The app uses the device location only when the user requests air quality data. Air quality records are stored locally using SQLite. The real AI API key is not committed to GitHub. A template file `apikey.env.example` is provided.

## API Key Configuration
Create a local file named `apikey.env` in the project root:

DEEPSEEK_API_KEY=your_real_api_key_here

The real `apikey.env` file is ignored by Git and should not be uploaded.

## User Journey
A user opens the app, logs in, checks the current air quality, reads pollutant details and AI advice, saves the record, and later reviews historical records and weekly trends. This supports repeated environmental awareness and healthier daily decisions.

## Testing
The app was tested on an iPhone simulator. Tested functions include login, location permission, air quality fetching, AI advice, history storage, weekly trend display, detail bottom sheet, and language switching.

## Future Improvements
- Push notifications for poor air quality
- Map view
- Cloud sync
- More detailed onboarding
- Secure backend proxy for AI requests
