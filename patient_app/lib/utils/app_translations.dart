// lib/utils/app_translations.dart
// All English and Tamil strings in one place

class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // General
      'app_name': 'HealthCare Pro',
      'hello': 'Hello',
      'how_feeling': 'How are you feeling today?',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'done': 'Done',
      'back': 'Back',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'retry': 'Retry',
      'search': 'Search',
      'no_data': 'No data found',

      // Home
      'quick_actions': 'Quick Actions',
      'my_appointments': 'My Appointments',
      'view_all': 'View All',
      'no_appointments': 'No appointments yet',

      // Quick action tiles
      'medibot': 'MediBot',
      'medibot_sub': 'AI Symptom Checker',
      'find_doctor': 'Find Doctor',
      'find_doctor_sub': 'Book appointment',
      'pharmacy': 'Pharmacy',
      'pharmacy_sub': 'Order medicines',
      'lab_tests': 'Lab Tests',
      'lab_tests_sub': 'Book a test',
      'appointments': 'Appointments',
      'appointments_sub': 'My bookings',
      'records': 'Records',
      'records_sub': 'Health history',

      // Doctors
      'find_a_doctor': 'Find a Doctor',
      'search_doctor': 'Search doctor by name or specialty...',
      'book': 'Book',
      'no_doctors': 'No doctors found',
      'consultation_fee': 'consultation',
      'experience': 'yrs',

      // Appointments
      'book_appointment': 'Book Appointment',
      'select_doctor': 'Select Doctor',
      'appointment_type': 'Appointment Type',
      'video_call': 'Video Call',
      'in_person': 'In-Person',
      'select_time': 'Select Time',
      'confirm_booking': 'Confirm Booking',
      'appointment_confirmed': 'Appointment Confirmed!',
      'booked_successfully': 'Your appointment has been booked successfully',
      'doctor_available': 'Doctor is available now',
      'doctor_unavailable': 'Doctor is currently unavailable',
      'start_video_call': 'Start Video Call',
      'doctor_unavailable_btn': 'Doctor Unavailable',
      'waiting_doctor': 'Waiting for doctor to accept...',
      'cancel_request': 'Cancel Request',

      // Pharmacy
      'search_medicines': 'Search medicines...',
      'add': '+ Add',
      'added': '✓ Added',
      'my_cart': 'My Cart',
      'items': 'items',
      'select_pharmacy': 'Select Pharmacy',
      'place_order': 'Place Order',
      'checkout': 'Checkout →',
      'no_medicines': 'No medicines found',
      'order_placed': 'Order placed successfully!',

      // SOS
      'sos_sending': 'Sending SOS...',
      'sos_finding': 'Finding Ambulance...',
      'sos_tracking': 'Ambulance Tracking',
      'sos_sent': 'SOS Sent — Finding ambulance...',
      'cancel_sos': 'Cancel SOS',
      'ambulance_accepted': '🚑 Ambulance Accepted!',
      'help_on_way': 'Help is on the way',
      'driver': 'Driver',
      'phone': 'Phone',
      'vehicle': 'Vehicle',
      'ok_got_it': 'OK, Got It!',

      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'tamil': 'தமிழ்',
      'select_language': 'Select Language',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'full_name': 'Full Name',
      'sign_in': 'Sign In',
      'create_account': 'Create Account',
      'login_failed': 'Login failed. Check credentials.',
      'register_failed': 'Registration failed.',
      'fill_all': 'Please fill all fields',
    },

    'ta': {
      // General
      'app_name': 'HealthCare Pro',
      'hello': 'வணக்கம்',
      'how_feeling': 'இன்று உங்களுக்கு எப்படி இருக்கிறது?',
      'logout': 'வெளியேறு',
      'cancel': 'ரத்து செய்',
      'confirm': 'உறுதிப்படுத்து',
      'save': 'சேமி',
      'done': 'முடிந்தது',
      'back': 'திரும்பு',
      'loading': 'ஏற்றுகிறது...',
      'error': 'ஏதோ தவறு நடந்தது',
      'retry': 'மீண்டும் முயற்சி',
      'search': 'தேடு',
      'no_data': 'தரவு இல்லை',

      // Home
      'quick_actions': 'விரைவு செயல்கள்',
      'my_appointments': 'என் சந்திப்புகள்',
      'view_all': 'அனைத்தும் காண்க',
      'no_appointments': 'இன்னும் சந்திப்புகள் இல்லை',

      // Quick action tiles
      'medibot': 'மெடிபாட்',
      'medibot_sub': 'AI அறிகுறி சரிபார்ப்பு',
      'find_doctor': 'மருத்துவர் தேடு',
      'find_doctor_sub': 'சந்திப்பு பதிவு செய்',
      'pharmacy': 'மருந்தகம்',
      'pharmacy_sub': 'மருந்துகள் ஆர்டர் செய்',
      'lab_tests': 'ஆய்வக சோதனைகள்',
      'lab_tests_sub': 'சோதனை பதிவு செய்',
      'appointments': 'சந்திப்புகள்',
      'appointments_sub': 'என் பதிவுகள்',
      'records': 'பதிவுகள்',
      'records_sub': 'சுகாதார வரலாறு',

      // Doctors
      'find_a_doctor': 'மருத்துவர் தேடு',
      'search_doctor': 'பெயர் அல்லது சிறப்பால் தேடுங்கள்...',
      'book': 'பதிவு செய்',
      'no_doctors': 'மருத்துவர்கள் இல்லை',
      'consultation_fee': 'ஆலோசனை',
      'experience': 'ஆண்டுகள்',

      // Appointments
      'book_appointment': 'சந்திப்பு பதிவு செய்',
      'select_doctor': 'மருத்துவர் தேர்ந்தெடு',
      'appointment_type': 'சந்திப்பு வகை',
      'video_call': 'வீடியோ அழைப்பு',
      'in_person': 'நேரில்',
      'select_time': 'நேரம் தேர்ந்தெடு',
      'confirm_booking': 'பதிவை உறுதிப்படுத்து',
      'appointment_confirmed': 'சந்திப்பு உறுதிப்படுத்தப்பட்டது!',
      'booked_successfully': 'உங்கள் சந்திப்பு வெற்றிகரமாக பதிவு செய்யப்பட்டது',
      'doctor_available': 'மருத்துவர் இப்போது கிடைக்கிறார்',
      'doctor_unavailable': 'மருத்துவர் தற்போது கிடைக்கவில்லை',
      'start_video_call': 'வீடியோ அழைப்பை தொடங்கு',
      'doctor_unavailable_btn': 'மருத்துவர் கிடைக்கவில்லை',
      'waiting_doctor': 'மருத்துவர் ஏற்கும் வரை காத்திருக்கிறோம்...',
      'cancel_request': 'கோரிக்கையை ரத்து செய்',

      // Pharmacy
      'search_medicines': 'மருந்துகளை தேடுங்கள்...',
      'add': '+ சேர்',
      'added': '✓ சேர்க்கப்பட்டது',
      'my_cart': 'என் கார்ட்',
      'items': 'பொருட்கள்',
      'select_pharmacy': 'மருந்தகம் தேர்ந்தெடு',
      'place_order': 'ஆர்டர் செய்',
      'checkout': 'செக்அவுட் →',
      'no_medicines': 'மருந்துகள் இல்லை',
      'order_placed': 'ஆர்டர் வெற்றிகரமாக வைக்கப்பட்டது!',

      // SOS
      'sos_sending': 'SOS அனுப்புகிறோம்...',
      'sos_finding': 'ஆம்புலன்ஸ் தேடுகிறோம்...',
      'sos_tracking': 'ஆம்புலன்ஸ் கண்காணிப்பு',
      'sos_sent': 'SOS அனுப்பப்பட்டது — ஆம்புலன்ஸ் தேடுகிறோம்...',
      'cancel_sos': 'SOS ரத்து செய்',
      'ambulance_accepted': '🚑 ஆம்புலன்ஸ் ஏற்றுக்கொண்டது!',
      'help_on_way': 'உதவி வருகிறது',
      'driver': 'ஓட்டுநர்',
      'phone': 'தொலைபேசி',
      'vehicle': 'வாகனம்',
      'ok_got_it': 'சரி, புரிந்தது!',

      // Settings
      'settings': 'அமைப்புகள்',
      'language': 'மொழி',
      'english': 'English',
      'tamil': 'தமிழ்',
      'select_language': 'மொழியை தேர்ந்தெடுக்கவும்',

      // Auth
      'login': 'உள்நுழை',
      'register': 'பதிவு செய்',
      'email': 'மின்னஞ்சல்',
      'password': 'கடவுச்சொல்',
      'full_name': 'முழு பெயர்',
      'sign_in': 'உள்நுழை',
      'create_account': 'கணக்கை உருவாக்கு',
      'login_failed': 'உள்நுழைவு தோல்வியடைந்தது.',
      'register_failed': 'பதிவு தோல்வியடைந்தது.',
      'fill_all': 'அனைத்து புலங்களையும் நிரப்பவும்',
    },
  };

  static String translate(String key, String languageCode) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }
}