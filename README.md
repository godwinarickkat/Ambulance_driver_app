Ambulance Driver App (Flutter)
This is a comprehensive, real-time mobile application for ambulance drivers, built with Flutter and Firebase. The app is designed to connect drivers with ride requests, manage the entire trip lifecycle, and provide drivers with essential tools for tracking their performance and earnings.

The system features a modern, clean UI focused on usability and efficiency, ensuring drivers can respond to emergencies quickly and effectively.

✨ Features
The application is packed with features to cover the full lifecycle of an emergency medical response service.

Secure Driver Authentication:

Phone number registration and login using Firebase OTP verification.

Real-time Ride Management:

Live listening for new ride requests from Firestore.

An incoming ride request pop-up with a 30-second countdown timer.

Ability to Accept or Decline new rides.

Automated WhatsApp notifications sent to the patient upon ride acceptance.

Interactive Dashboard:

A live map showing the driver's current location.

Online/Offline status toggle to control availability.

A modern floating bottom panel displaying key driver analytics:

Total Rides Completed

Total Kilometers Driven

Total Earnings

Live Trip Navigation (OnTripPage):

Displays the optimal route to the patient's pickup and dropoff locations using the OSRM routing engine.

Full trip lifecycle management with buttons for "Arrived," "Start Trip," and "Complete Trip."

Accurate, real-time calculation of the actual distance traveled during a trip.

A Trip Cancellation feature with a confirmation dialog.

Driver Administration & Performance:

Profile & KYC: A dedicated screen for drivers to upload their license and vehicle registration documents to Firebase Storage for verification.

Ride History: A detailed list of all completed trips, showing patient details, date, distance, and fare for each.

Earnings Screen: A summary of today's and total earnings, with a complete transaction history.

Modern User Interface:

A clean, professional UI with a fast and intuitive Bottom Navigation Bar.

A centralized theme for consistent styling of colors, fonts, and widgets across the app.

<br/>

🛠️ Technology Stack
Frontend: Flutter (Cross-platform for Android & iOS)

Backend & Database: Google Firebase

Firestore: Real-time NoSQL database for all application data.

Firebase Authentication: For secure phone OTP login.

Firebase Storage: For KYC document uploads.

Mapping:

Map Tiles: OpenStreetMap with custom professional styles.

Routing: OSRM API for route calculation and distance estimation.

State Management: StatefulWidget (setState)

<br/>

🚀 How to Set Up and Run the Project
To clone and run this application, you'll need to set up your own Firebase project.

1. Firebase Project Setup
Go to the Firebase Console and create a new project.

Add a new Android app to the project.

Package Name: com.example.devsecit_ambulance_driver (or your own package name, but you'll need to update it in the app).

Follow the instructions to download the google-services.json file and place it in the android/app/ directory of this project.

Enable the following Firebase services in the console:

Authentication: Enable the "Phone Number" sign-in provider. You will also need to add your device's SHA-1 and SHA-256 fingerprints to your Firebase project settings for OTP to work on a real device.

Firestore: Create a new database in Test Mode.

Storage: Create a new storage bucket.

2. Firestore Database Structure
You will need to create two collections in Firestore:

drivers: This stores driver information. The document ID should be the Firebase uid of the user.

ride_requests: This stores information about each ride.

For the required fields in each collection, please refer to the Project Report documentation.

3. Running the App
Clone the repository:

Bash

git clone https://github.com/your-username/ambulance-driver-app.git
Navigate to the project directory:

Bash

cd ambulance-driver-app
Install the dependencies:

Bash

flutter pub get
Run the app on your connected device or emulator:

Bash

flutter run