// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change application language';

  @override
  String get notifications => 'Push Notifications';

  @override
  String get appName => 'Camelia Logistics';

  @override
  String get userNotConnected => 'User not connected';

  @override
  String get logoutFailed => 'Logout failed';

  @override
  String get profileLoadingError => 'Error loading profile';

  @override
  String get memberSince => 'Member from Cameroon';

  @override
  String get deliveries => 'Deliveries';

  @override
  String get level => 'Level';

  @override
  String get successRate => 'Success';

  @override
  String get beginner => 'Beginner';

  @override
  String get mainEmail => 'Main Email';

  @override
  String get phone => 'Phone (joinable)';

  @override
  String get updateYourProfile => 'Update your profile';

  @override
  String get yourPerformances => 'Your performances';

  @override
  String get averageRating => 'Average rating';

  @override
  String get successRateLabel => 'Success rate';

  @override
  String get totalDeliveries => 'Total deliveries';

  @override
  String get toggleNotifications => 'Enable/Disable notifications';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get logoutDescription => 'Log out of your account';

  @override
  String get errorMissingOrderId => 'Error: Order ID is missing.';

  @override
  String get orderNotFound => 'Order not found.';

  @override
  String get confirmYourOrder => 'Confirm your order';

  @override
  String get manageOrder => 'Manage order';

  @override
  String get cancelOrderConfirmation =>
      'Are you sure you want to cancel the order?';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get orderValidated => 'Order Validated!';

  @override
  String get orderValidationSuccessMessage =>
      'Your order has been successfully validated and paid';

  @override
  String get backToHome => 'Back to home';

  @override
  String get quoteDetails => 'Quote Details';

  @override
  String get finalPriceWithoutTax => 'Final Price (Excluding Tax):';

  @override
  String get confirmAndReceiveCall => 'Confirm and receive a call';

  @override
  String get refuse => 'Refuse';

  @override
  String get newEvent => 'New event';

  @override
  String get view => 'VIEW';

  @override
  String get searchingDriver => 'Searching for a driver...';

  @override
  String get searchingDriverDesc =>
      'This should not take more than a few minutes';

  @override
  String get driverNotification =>
      'You will receive a notification as soon as a driver accepts your order';

  @override
  String get driverContactSoon => 'A driver will contact you very soon!';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get departure => 'Departure';

  @override
  String get destination => 'Destination';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get packageType => 'Package Type';

  @override
  String get activeDrivers => 'Active Drivers';

  @override
  String get driversAvailable => 'More than 100 drivers available in your area';

  @override
  String get emergency => 'Emergency';

  @override
  String get support => 'Support';

  @override
  String get waitingForDriver => 'Waiting for a driver...';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get gladToSeeYou => 'Glad to see you again';

  @override
  String get emailHint => 'your.email@example.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get passwordHint => 'Your password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Minimum 6 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get continueWith => 'Or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccount => 'No account yet? ';

  @override
  String get signUp => 'Sign up';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get createAccount => 'Create an account';

  @override
  String get joinCommunity => 'Join our community';

  @override
  String get nameHint => 'John Doe';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get confirmPasswordHint => 'Confirm your password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get phoneHint => '6 XX XX XX XX';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get invalidPhone => 'Invalid number';

  @override
  String get createMyAccount => 'Create my account';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get registrationSuccess => 'Registration successful!';

  @override
  String get loginTab => 'Login';

  @override
  String get signupTab => 'Sign up';

  @override
  String get expressDeliveryService => 'Express delivery at your service';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to quit?';

  @override
  String get quit => 'QUIT';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get profile => 'Profile';

  @override
  String get client => 'Client';

  @override
  String get offlineMode => 'Offline mode or profile not found';

  @override
  String get whatToDoToday => 'What would you like to do today?';

  @override
  String get newTransport => 'New transport';

  @override
  String get checkConnection => 'Check your internet connection and try again';

  @override
  String get sentPackages => 'Sent packages';

  @override
  String get inProgress => 'in progress ';

  @override
  String get thisMonth => 'This month';

  @override
  String get recentDeliveries => 'Recent deliveries';

  @override
  String get seeAll => 'See all';

  @override
  String get noOrdersFound => 'No orders found.';

  @override
  String hello(Object name) {
    return 'Hello, $name';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Validated';

  @override
  String get statusAssigned => 'In progress';

  @override
  String get statusCompleted => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get pointAtoB => 'From point A to point B';

  @override
  String get simplifiedDelivery => 'Simplified delivery';

  @override
  String get pointAtoBDesc =>
      'Simply indicate your departure and destination for fast and efficient delivery';

  @override
  String get chooseVehicle => 'Choose your vehicle';

  @override
  String get adaptedToNeeds => 'Adapted to your needs';

  @override
  String get chooseVehicleDesc =>
      'Tricycle, van, dump truck... Select the ideal vehicle for your package';

  @override
  String get describePackage => 'Describe your package';

  @override
  String get preciseInfo => 'Precise information';

  @override
  String get describePackageDesc =>
      'Nature, dimensions and characteristics for optimal handling';

  @override
  String get driverOnWay => 'A driver on the way';

  @override
  String get fastService => 'Fast service';

  @override
  String get driverOnWayDesc =>
      'An experienced driver is dispatched immediately for your transport';

  @override
  String get transportSimply => 'Transport with ease';

  @override
  String get service => 'Service';

  @override
  String get startNow => 'Start now';

  @override
  String get changeProfileTitle => 'Edit Profile';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String profileUpdateError(Object error) {
    return 'Update error: $error';
  }

  @override
  String get editYourInfo => 'Edit your information';

  @override
  String get updateYourPersonalInfo => 'Update your personal information';

  @override
  String get fullName => 'Full name';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get pleaseEnterPhone => 'Please enter your phone number';

  @override
  String get pleaseEnterValidPhone => 'Please enter a valid number';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailIsRequired => 'Email is required';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get packagesDelivered => 'Packages delivered';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String historyError(Object error) {
    return 'Error: $error';
  }

  @override
  String get expressDeliveryCameroon => 'Express delivery in Cameroon';

  @override
  String get ultraFastDelivery => 'Ultra-fast delivery';

  @override
  String get ultraFastDeliveryDesc =>
      'Your package delivered in less than 24 hours';

  @override
  String get nationalCoverage => 'National coverage';

  @override
  String get nationalCoverageDesc => 'Service available in all cities';

  @override
  String get securityGuaranteed => 'Security guaranteed';

  @override
  String get securityGuaranteedDesc =>
      'Your packages insured until destination';

  @override
  String get support247 => '24/7 Support';

  @override
  String get support247Desc => 'Our team is here to help';

  @override
  String get getStarted => 'Get Started';

  @override
  String get alreadyHaveAnAccountPrompt => 'I already have an account';

  @override
  String get chooseVehicleTitle => 'Choose a vehicle';

  @override
  String get selectTransportMode => 'Select your mode of transport';

  @override
  String get serviceComingSoon =>
      'Service coming soon to Yaoundé, Bafoussam, Garoua & Kribi';

  @override
  String get dumpTruck => 'Dump Truck';

  @override
  String get van => 'Van';

  @override
  String get tricycle => 'Tricycle';

  @override
  String get minivan => 'Minivan';

  @override
  String get fastAndEconomic => 'Fast and economical';

  @override
  String get secureTransport => 'Secure transport';

  @override
  String get mediumCapacity => 'Medium capacity';

  @override
  String get trackPackage => 'Track package';

  @override
  String get contactSupportCta =>
      'You can track your orders or contact support at any time';

  @override
  String get newOrderTitle => 'New Order';

  @override
  String get step2of4 => 'Step 2 of 4';

  @override
  String get packagePhotoTitle => 'Package Photo';

  @override
  String get packagePhotoSubtitle => 'Take a photo to facilitate delivery';

  @override
  String get addAPhoto => 'Add a photo';

  @override
  String get touchToChoosePhoto => 'Tap to take or choose a photo';

  @override
  String get takeOrChoosePhoto => 'Take or choose a photo';

  @override
  String get goods => 'Goods';

  @override
  String get electronics => 'Electronics';

  @override
  String get furniture => 'Furniture';

  @override
  String get food => 'Food';

  @override
  String get fragile => 'Fragile';

  @override
  String get other => 'Other';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get describeYourPackageHint => 'Describe your package...';

  @override
  String get pleaseCompleteSelection => 'Please complete the selection';

  @override
  String get continueButton => 'Continue';

  @override
  String get deliveryPointsTitle => 'Delivery Points';

  @override
  String get locationPermissionDenied =>
      'Activate or verify permissions of location';

  @override
  String locationError(Object error) {
    return 'Location error: $error';
  }

  @override
  String get step3of4 => 'Step 3 of 4';

  @override
  String get setDepartureAndDestination => 'Set the departure and destination';

  @override
  String get startingPoint => 'Starting Point';

  @override
  String get departureAddressHint => 'Departure address';

  @override
  String get useMyPosition => 'Use my position';

  @override
  String get destinationPoint => 'Destination';

  @override
  String get deliveryAddressHint => 'Delivery address';

  @override
  String get chooseOnMap => 'Choose on map';

  @override
  String get mapAndDistance => 'Map and distance';

  @override
  String get interactiveMap => 'Interactive map';

  @override
  String get selectAddresses => 'Select the addresses';

  @override
  String get orderSubmissionError => 'Error while submitting the order.';

  @override
  String get orderSummaryTitle => 'Order Summary';

  @override
  String get step4of4 => 'Step 4 of 4';

  @override
  String get reviewDetailsBeforeConfirming =>
      'Review details before confirming';

  @override
  String get transport => 'Transport';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get confirmOrder => 'Confirm order';

  @override
  String get searchingForAddress => 'Searching for address...';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get chooseDestinationTitle => 'Choose destination';

  @override
  String get confirmThisPoint => 'Confirm this point';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String helloAdmin(Object name) {
    return 'Hello, $name';
  }

  @override
  String get administrator => 'Administrator';

  @override
  String get managePlatform => 'Manage your platform';

  @override
  String get statistics => 'Statistics';

  @override
  String get users => 'Users';

  @override
  String get drivers => 'Drivers';

  @override
  String get deliveriesToday => 'Today';

  @override
  String get revenue => 'Revenue';

  @override
  String get analysis => 'Analysis';

  @override
  String get orderDistribution => 'Order Distribution';

  @override
  String get loadingError => 'Loading error';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get monthlyRevenue => 'Monthly Revenue';

  @override
  String get noRevenueData => 'No revenue data';

  @override
  String get error => 'Error';

  @override
  String get searchAddressHint => 'Enter your address';

  @override
  String get statusConfirmed => 'ACCEPTED';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountWarning =>
      'This action is irreversible. All your data will be deleted.';

  @override
  String get deleteAccountFailed => 'Delete account failed';

  @override
  String get confirmDelete => 'Confirm deletion';

  @override
  String get help => 'Help Center';

  @override
  String get faq => 'FAQ & Guides';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get avis => 'Give us your feedback';

  @override
  String get colis => 'How to track my package?';

  @override
  String get colisAns =>
      'Go to the \'My Orders\' section, select the order you want to track, and click on \'Track Package\' to see its real-time location.';

  @override
  String get modifyAddress => 'How to modify my delivery address?';

  @override
  String get modifyAddressAns =>
      'Contact support via chat or phone before the driver picks up the package for any modification.';

  @override
  String get setupAddress => 'How to set up delivery points?';

  @override
  String get setupAddressAns =>
      'Enter your addresses or use location and map, we will ask for more details during the order';

  @override
  String get suggestions => 'Share your suggestions to improve our service';

  @override
  String get faqGetDeliverers => '🚲 Drivers Area';

  @override
  String get faqGetDeliverersAns =>
      'Are you interested in becoming a driver? Join our team of drivers and start earning by delivering with Camelia Logistics!';

  @override
  String get faqClientAbsent => 'Client absent at delivery';

  @override
  String get faqClientAbsentAns =>
      'Wait a few minutes and try to contact the client. If you can\'t reach them, contact support to find a solution.';

  @override
  String get faqTechSupportTitle => '🛠 Technical Support';

  @override
  String get faqAppBug => 'App is slow or buggy';

  @override
  String get faqAppBugAns =>
      'Check your internet connection and ensure you have the latest update. If the problem persists, clear the app cache.';

  @override
  String get faqNoNotif => 'I am not receiving notifications';

  @override
  String get faqNoNotifAns =>
      'Go to your phone settings > Apps > Camelia Logistics and check that notifications are allowed.';

  @override
  String get policy => 'Privacy Policy';

  @override
  String get conditions => 'Terms of Service';

  @override
  String get policyContent => 'Your privacy policy here...';

  @override
  String get conditionsContent => 'Your terms of service here...';

  @override
  String get notificationsEnabled => 'notifications Enabled';

  @override
  String get notificationsDisabled => 'notifications Disabled';
}
