import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mes informations'**
  String get editProfile;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue de l\'application'**
  String get changeLanguage;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get notifications;

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Camelia Logistics'**
  String get appName;

  /// No description provided for @userNotConnected.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur non connecté'**
  String get userNotConnected;

  /// No description provided for @logoutFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la déconnexion'**
  String get logoutFailed;

  /// No description provided for @profileLoadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement du profil'**
  String get profileLoadingError;

  /// No description provided for @memberSince.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis le Cameroun'**
  String get memberSince;

  /// No description provided for @deliveries.
  ///
  /// In fr, this message translates to:
  /// **'Livraisons'**
  String get deliveries;

  /// No description provided for @level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get level;

  /// No description provided for @successRate.
  ///
  /// In fr, this message translates to:
  /// **'Réussite'**
  String get successRate;

  /// No description provided for @beginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get beginner;

  /// No description provided for @mainEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email principal'**
  String get mainEmail;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (joignable)'**
  String get phone;

  /// No description provided for @updateYourProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour votre profil'**
  String get updateYourProfile;

  /// No description provided for @yourPerformances.
  ///
  /// In fr, this message translates to:
  /// **'Vos performances'**
  String get yourPerformances;

  /// No description provided for @averageRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get averageRating;

  /// No description provided for @successRateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Taux de réussite'**
  String get successRateLabel;

  /// No description provided for @totalDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Total des livraisons'**
  String get totalDeliveries;

  /// No description provided for @toggleNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Activer/Désactiver les notifications'**
  String get toggleNotifications;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @logoutDescription.
  ///
  /// In fr, this message translates to:
  /// **'Déconnectez-vous de votre compte'**
  String get logoutDescription;

  /// No description provided for @errorMissingOrderId.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: L\'ID de la commande est manquant.'**
  String get errorMissingOrderId;

  /// No description provided for @orderNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Commande introuvable.'**
  String get orderNotFound;

  /// No description provided for @confirmYourOrder.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer votre commande'**
  String get confirmYourOrder;

  /// No description provided for @manageOrder.
  ///
  /// In fr, this message translates to:
  /// **'Gérer la commande'**
  String get manageOrder;

  /// No description provided for @cancelOrderConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler la commande ?'**
  String get cancelOrderConfirmation;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @orderValidated.
  ///
  /// In fr, this message translates to:
  /// **'Commande Validée !'**
  String get orderValidated;

  /// No description provided for @orderValidationSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre commande a été validée et payée avec succès'**
  String get orderValidationSuccessMessage;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @quoteDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du Devis'**
  String get quoteDetails;

  /// No description provided for @finalPriceWithoutTax.
  ///
  /// In fr, this message translates to:
  /// **'Prix Final (Hors Taxes) :'**
  String get finalPriceWithoutTax;

  /// No description provided for @confirmAndReceiveCall.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et recevoir un appel'**
  String get confirmAndReceiveCall;

  /// No description provided for @refuse.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get refuse;

  /// No description provided for @newEvent.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel événement'**
  String get newEvent;

  /// No description provided for @view.
  ///
  /// In fr, this message translates to:
  /// **'VOIR'**
  String get view;

  /// No description provided for @searchingDriver.
  ///
  /// In fr, this message translates to:
  /// **'Recherche d\'un chauffeur en cours...'**
  String get searchingDriver;

  /// No description provided for @searchingDriverDesc.
  ///
  /// In fr, this message translates to:
  /// **'Cela ne devrait pas prendre plus de quelques minutes'**
  String get searchingDriverDesc;

  /// No description provided for @driverNotification.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevrez une notification dès qu\'un chauffeur acceptera votre commande'**
  String get driverNotification;

  /// No description provided for @driverContactSoon.
  ///
  /// In fr, this message translates to:
  /// **'Un chauffeur va vous contacter très bientôt !'**
  String get driverContactSoon;

  /// No description provided for @orderSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de votre commande'**
  String get orderSummary;

  /// No description provided for @departure.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get departure;

  /// No description provided for @destination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @vehicle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get vehicle;

  /// No description provided for @packageType.
  ///
  /// In fr, this message translates to:
  /// **'Type de colis'**
  String get packageType;

  /// No description provided for @activeDrivers.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeurs actifs'**
  String get activeDrivers;

  /// No description provided for @driversAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Plus de 100 chauffeurs disponibles dans votre zone'**
  String get driversAvailable;

  /// No description provided for @emergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence'**
  String get emergency;

  /// No description provided for @support.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @waitingForDriver.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'un chauffeur...'**
  String get waitingForDriver;

  /// No description provided for @welcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour !'**
  String get welcomeBack;

  /// No description provided for @gladToSeeYou.
  ///
  /// In fr, this message translates to:
  /// **'Content de vous revoir'**
  String get gladToSeeYou;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'votre.email@exemple.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Format d\'email invalide'**
  String get invalidEmail;

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get passwordMinLength;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @continueWith.
  ///
  /// In fr, this message translates to:
  /// **'Ou continuer avec'**
  String get continueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @invalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants invalides'**
  String get invalidCredentials;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez notre communauté'**
  String get joinCommunity;

  /// No description provided for @nameHint.
  ///
  /// In fr, this message translates to:
  /// **'Jean Pierre'**
  String get nameHint;

  /// No description provided for @nameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get nameRequired;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre mot de passe'**
  String get confirmPasswordHint;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre mot de passe'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'6 XX XX XX XX'**
  String get phoneHint;

  /// No description provided for @phoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone est requis'**
  String get phoneRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide'**
  String get invalidPhone;

  /// No description provided for @createMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get createMyAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? '**
  String get alreadyHaveAccount;

  /// No description provided for @registrationSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Inscription réussie !'**
  String get registrationSuccess;

  /// No description provided for @loginTab.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTab;

  /// No description provided for @signupTab.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get signupTab;

  /// No description provided for @expressDeliveryService.
  ///
  /// In fr, this message translates to:
  /// **'Livraison express à votre service'**
  String get expressDeliveryService;

  /// No description provided for @confirmLogout.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la Déconnexion'**
  String get confirmLogout;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir quitter ?'**
  String get confirmLogoutMessage;

  /// No description provided for @quit.
  ///
  /// In fr, this message translates to:
  /// **'QUITTER'**
  String get quit;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @offlineMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne ou profil introuvable'**
  String get offlineMode;

  /// No description provided for @whatToDoToday.
  ///
  /// In fr, this message translates to:
  /// **'Que souhaitez-vous aujourd\'hui?'**
  String get whatToDoToday;

  /// No description provided for @newTransport.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau transport'**
  String get newTransport;

  /// No description provided for @checkConnection.
  ///
  /// In fr, this message translates to:
  /// **'Verifier votre connexion internet et ressayer'**
  String get checkConnection;

  /// No description provided for @sentPackages.
  ///
  /// In fr, this message translates to:
  /// **'Colis envoyés'**
  String get sentPackages;

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'en cours '**
  String get inProgress;

  /// No description provided for @thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get thisMonth;

  /// No description provided for @recentDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Livraisons récentes'**
  String get recentDeliveries;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// No description provided for @noOrdersFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande trouvée.'**
  String get noOrdersFound;

  /// No description provided for @hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String hello(Object name);

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En Attente'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
  String get statusAccepted;

  /// No description provided for @statusAssigned.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get statusAssigned;

  /// No description provided for @statusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get statusCancelled;

  /// No description provided for @pointAtoB.
  ///
  /// In fr, this message translates to:
  /// **'De point A à point B'**
  String get pointAtoB;

  /// No description provided for @simplifiedDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison simplifiée'**
  String get simplifiedDelivery;

  /// No description provided for @pointAtoBDesc.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez simplement votre départ et destination pour une livraison rapide et efficace'**
  String get pointAtoBDesc;

  /// No description provided for @chooseVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre véhicule'**
  String get chooseVehicle;

  /// No description provided for @adaptedToNeeds.
  ///
  /// In fr, this message translates to:
  /// **'Adapté à vos besoins'**
  String get adaptedToNeeds;

  /// No description provided for @chooseVehicleDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tricycle, camionnette, camion-benne... Sélectionnez le véhicule idéal pour votre colis'**
  String get chooseVehicleDesc;

  /// No description provided for @describePackage.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez votre colis'**
  String get describePackage;

  /// No description provided for @preciseInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations précises'**
  String get preciseInfo;

  /// No description provided for @describePackageDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nature, dimensions et caractéristiques pour une prise en charge optimale'**
  String get describePackageDesc;

  /// No description provided for @driverOnWay.
  ///
  /// In fr, this message translates to:
  /// **'Un chauffeur en route'**
  String get driverOnWay;

  /// No description provided for @fastService.
  ///
  /// In fr, this message translates to:
  /// **'Service rapide'**
  String get fastService;

  /// No description provided for @driverOnWayDesc.
  ///
  /// In fr, this message translates to:
  /// **'Un chauffeur expérimenté est dépêché immédiatement pour votre transport'**
  String get driverOnWayDesc;

  /// No description provided for @transportSimply.
  ///
  /// In fr, this message translates to:
  /// **'Transportez en toute simplicité'**
  String get transportSimply;

  /// No description provided for @service.
  ///
  /// In fr, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @startNow.
  ///
  /// In fr, this message translates to:
  /// **'Commencer maintenant'**
  String get startNow;

  /// No description provided for @changeProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get changeProfileTitle;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour: {error}'**
  String profileUpdateError(Object error);

  /// No description provided for @editYourInfo.
  ///
  /// In fr, this message translates to:
  /// **'Modifier vos informations'**
  String get editYourInfo;

  /// No description provided for @updateYourPersonalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Mettez à jour vos informations personnelles'**
  String get updateYourPersonalInfo;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre nom'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre numéro de téléphone'**
  String get pleaseEnterPhone;

  /// No description provided for @pleaseEnterValidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un numéro valide'**
  String get pleaseEnterValidPhone;

  /// No description provided for @emailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get emailAddress;

  /// No description provided for @emailIsRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est obligatoire'**
  String get emailIsRequired;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get saveChanges;

  /// No description provided for @packagesDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Colis livrés'**
  String get packagesDelivered;

  /// No description provided for @totalSpent.
  ///
  /// In fr, this message translates to:
  /// **'Total Dépensé'**
  String get totalSpent;

  /// No description provided for @historyError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String historyError(Object error);

  /// No description provided for @expressDeliveryCameroon.
  ///
  /// In fr, this message translates to:
  /// **'Livraison express au Cameroun'**
  String get expressDeliveryCameroon;

  /// No description provided for @ultraFastDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison ultra-rapide'**
  String get ultraFastDelivery;

  /// No description provided for @ultraFastDeliveryDesc.
  ///
  /// In fr, this message translates to:
  /// **'Votre colis livré en moins de 24h'**
  String get ultraFastDeliveryDesc;

  /// No description provided for @nationalCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Couverture nationale'**
  String get nationalCoverage;

  /// No description provided for @nationalCoverageDesc.
  ///
  /// In fr, this message translates to:
  /// **'Service disponible dans toutes les villes'**
  String get nationalCoverageDesc;

  /// No description provided for @securityGuaranteed.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité garantie'**
  String get securityGuaranteed;

  /// No description provided for @securityGuaranteedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Vos colis assurés jusqu\'à destination'**
  String get securityGuaranteedDesc;

  /// No description provided for @support247.
  ///
  /// In fr, this message translates to:
  /// **'Support 24/7'**
  String get support247;

  /// No description provided for @support247Desc.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe à votre écoute'**
  String get support247Desc;

  /// No description provided for @getStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get getStarted;

  /// No description provided for @alreadyHaveAnAccountPrompt.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get alreadyHaveAnAccountPrompt;

  /// No description provided for @chooseVehicleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un véhicule'**
  String get chooseVehicleTitle;

  /// No description provided for @selectTransportMode.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre mode de transport'**
  String get selectTransportMode;

  /// No description provided for @serviceComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Service Bientôt disponible à Yaoundé, Bafoussam, Garoua et Kribi'**
  String get serviceComingSoon;

  /// No description provided for @dumpTruck.
  ///
  /// In fr, this message translates to:
  /// **'Camion Bennes'**
  String get dumpTruck;

  /// No description provided for @van.
  ///
  /// In fr, this message translates to:
  /// **'Camionnette'**
  String get van;

  /// No description provided for @tricycle.
  ///
  /// In fr, this message translates to:
  /// **'Tricycle'**
  String get tricycle;

  /// No description provided for @minivan.
  ///
  /// In fr, this message translates to:
  /// **'Fourgonnette'**
  String get minivan;

  /// No description provided for @fastAndEconomic.
  ///
  /// In fr, this message translates to:
  /// **'Rapide et économique'**
  String get fastAndEconomic;

  /// No description provided for @secureTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport sécurisé'**
  String get secureTransport;

  /// No description provided for @mediumCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Capacité moyenne'**
  String get mediumCapacity;

  /// No description provided for @trackPackage.
  ///
  /// In fr, this message translates to:
  /// **'Suivi colis'**
  String get trackPackage;

  /// No description provided for @contactSupportCta.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez suivre vos commandes ou contacter le support à tout moment'**
  String get contactSupportCta;

  /// No description provided for @newOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande'**
  String get newOrderTitle;

  /// No description provided for @step2of4.
  ///
  /// In fr, this message translates to:
  /// **'Étape 2 sur 4'**
  String get step2of4;

  /// No description provided for @packagePhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo du colis'**
  String get packagePhotoTitle;

  /// No description provided for @packagePhotoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Prenez une photo pour faciliter la livraison'**
  String get packagePhotoSubtitle;

  /// No description provided for @addAPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get addAPhoto;

  /// No description provided for @touchToChoosePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour prendre ou choisir une photo'**
  String get touchToChoosePhoto;

  /// No description provided for @takeOrChoosePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre ou choisir une photo'**
  String get takeOrChoosePhoto;

  /// No description provided for @goods.
  ///
  /// In fr, this message translates to:
  /// **'Marchandises'**
  String get goods;

  /// No description provided for @electronics.
  ///
  /// In fr, this message translates to:
  /// **'Électronique'**
  String get electronics;

  /// No description provided for @furniture.
  ///
  /// In fr, this message translates to:
  /// **'Meubles'**
  String get furniture;

  /// No description provided for @food.
  ///
  /// In fr, this message translates to:
  /// **'Nourriture'**
  String get food;

  /// No description provided for @fragile.
  ///
  /// In fr, this message translates to:
  /// **'Fragile'**
  String get fragile;

  /// No description provided for @other.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get other;

  /// No description provided for @descriptionOptional.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get descriptionOptional;

  /// No description provided for @describeYourPackageHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez votre colis...'**
  String get describeYourPackageHint;

  /// No description provided for @pleaseCompleteSelection.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez terminer la sélection'**
  String get pleaseCompleteSelection;

  /// No description provided for @continueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// No description provided for @deliveryPointsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Points de livraison'**
  String get deliveryPointsTitle;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'veuillez activer la localisation et  les permissions dans les paramètres de votre téléphone.'**
  String get locationPermissionDenied;

  /// No description provided for @locationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de localisation: {error}'**
  String locationError(Object error);

  /// No description provided for @step3of4.
  ///
  /// In fr, this message translates to:
  /// **'Étape 3 sur 4'**
  String get step3of4;

  /// No description provided for @setDepartureAndDestination.
  ///
  /// In fr, this message translates to:
  /// **'Définissez le départ et la destination'**
  String get setDepartureAndDestination;

  /// No description provided for @startingPoint.
  ///
  /// In fr, this message translates to:
  /// **'Point de départ'**
  String get startingPoint;

  /// No description provided for @departureAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de départ'**
  String get departureAddressHint;

  /// No description provided for @useMyPosition.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position'**
  String get useMyPosition;

  /// No description provided for @destinationPoint.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get destinationPoint;

  /// No description provided for @deliveryAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get deliveryAddressHint;

  /// No description provided for @chooseOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Choisir sur la carte'**
  String get chooseOnMap;

  /// No description provided for @mapAndDistance.
  ///
  /// In fr, this message translates to:
  /// **'Carte et distance'**
  String get mapAndDistance;

  /// No description provided for @interactiveMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte interactive'**
  String get interactiveMap;

  /// No description provided for @selectAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez les adresses'**
  String get selectAddresses;

  /// No description provided for @orderSubmissionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi de la commande.'**
  String get orderSubmissionError;

  /// No description provided for @orderSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de commande'**
  String get orderSummaryTitle;

  /// No description provided for @step4of4.
  ///
  /// In fr, this message translates to:
  /// **'Étape 4 sur 4'**
  String get step4of4;

  /// No description provided for @reviewDetailsBeforeConfirming.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les détails avant confirmation'**
  String get reviewDetailsBeforeConfirming;

  /// No description provided for @transport.
  ///
  /// In fr, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @notSpecified.
  ///
  /// In fr, this message translates to:
  /// **'Non spécifié'**
  String get notSpecified;

  /// No description provided for @confirmOrder.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la commande'**
  String get confirmOrder;

  /// No description provided for @searchingForAddress.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de l\'adresse...'**
  String get searchingForAddress;

  /// No description provided for @unknownLocation.
  ///
  /// In fr, this message translates to:
  /// **'Lieu inconnu'**
  String get unknownLocation;

  /// No description provided for @chooseDestinationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la destination'**
  String get chooseDestinationTitle;

  /// No description provided for @confirmThisPoint.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer ce point'**
  String get confirmThisPoint;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTitle;

  /// No description provided for @helloAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String helloAdmin(Object name);

  /// No description provided for @administrator.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get administrator;

  /// No description provided for @managePlatform.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre plateforme'**
  String get managePlatform;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get users;

  /// No description provided for @drivers.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeurs'**
  String get drivers;

  /// No description provided for @deliveriesToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get deliveriesToday;

  /// No description provided for @revenue.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires'**
  String get revenue;

  /// No description provided for @analysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyses'**
  String get analysis;

  /// No description provided for @orderDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Distribution des commandes'**
  String get orderDistribution;

  /// No description provided for @loadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadingError;

  /// No description provided for @noDataAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get noDataAvailable;

  /// No description provided for @monthlyRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires mensuel'**
  String get monthlyRevenue;

  /// No description provided for @noRevenueData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de CA'**
  String get noRevenueData;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @searchAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrer votre adresse'**
  String get searchAddressHint;

  /// No description provided for @statusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'CONFIRME'**
  String get statusConfirmed;

  /// No description provided for @deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Toutes vos données seront effacées.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la suppression du compte'**
  String get deleteAccountFailed;

  /// No description provided for @confirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDelete;

  /// No description provided for @help.
  ///
  /// In fr, this message translates to:
  /// **'Centre d/\'aide'**
  String get help;

  /// No description provided for @faq.
  ///
  /// In fr, this message translates to:
  /// **'FAQ et guides'**
  String get faq;

  /// No description provided for @contactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get contactSupport;

  /// No description provided for @avis.
  ///
  /// In fr, this message translates to:
  /// **'Donner votre avis'**
  String get avis;

  /// No description provided for @colis.
  ///
  /// In fr, this message translates to:
  /// **'Comment suivre mon colis ?'**
  String get colis;

  /// No description provided for @colisAns.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez suivre votre colis en temps réel via l\'application. Allez dans \'Mes commandes\', sélectionnez la commande en cours, et cliquez sur \'Suivre le colis\' pour voir sa position actuelle sur la carte.'**
  String get colisAns;

  /// No description provided for @modifyAddress.
  ///
  /// In fr, this message translates to:
  /// **'Comment modifier l\'adresse de livraison ?'**
  String get modifyAddress;

  /// No description provided for @modifyAddressAns.
  ///
  /// In fr, this message translates to:
  /// **'Si vous souhaitez modifier l\'adresse de livraison, veuillez contacter notre support via le chat ou par téléphone avant que le livreur ne récupère le colis. Nous ferons de notre mieux pour répondre à votre demande.'**
  String get modifyAddressAns;

  /// No description provided for @setupAddress.
  ///
  /// In fr, this message translates to:
  /// **'Comment choisir les points de livraisons ?'**
  String get setupAddress;

  /// No description provided for @setupAddressAns.
  ///
  /// In fr, this message translates to:
  /// **'ecrivez vos adresses ou utiliser la localisation et la carte ,nous demandrons plus de detail lors de commande'**
  String get setupAddressAns;

  /// No description provided for @suggestions.
  ///
  /// In fr, this message translates to:
  /// **'Partagez vos suggestions pour améliorer notre service'**
  String get suggestions;

  /// No description provided for @faqGetDeliverers.
  ///
  /// In fr, this message translates to:
  /// **'Espace Livreurs'**
  String get faqGetDeliverers;

  /// No description provided for @faqGetDeliverersAns.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes intéressé pour devenir livreur ? Rejoignez notre équipe de chauffeurs et commencez à gagner de l\'argent en livrant avec Camelia Logistics !'**
  String get faqGetDeliverersAns;

  /// No description provided for @faqClientAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Client absent ou injoignable'**
  String get faqClientAbsent;

  /// No description provided for @faqClientAbsentAns.
  ///
  /// In fr, this message translates to:
  /// **'Tentez d/\'appeler le client 3 fois via l/\'app. Après 10 min d/\'attente sans réponse, contactez le support pour valider le retour du colis.'**
  String get faqClientAbsentAns;

  /// No description provided for @faqTechSupportTitle.
  ///
  /// In fr, this message translates to:
  /// **'🛠 Support technique'**
  String get faqTechSupportTitle;

  /// No description provided for @faqAppBug.
  ///
  /// In fr, this message translates to:
  /// **'L\'application est lente ou bugue'**
  String get faqAppBug;

  /// No description provided for @faqAppBugAns.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion internet et assurez-vous d\'avoir la dernière mise à jour. Si le problème persiste, essayez de vider le cache de l\'application.'**
  String get faqAppBugAns;

  /// No description provided for @faqNoNotif.
  ///
  /// In fr, this message translates to:
  /// **'Je ne reçois pas les notifications'**
  String get faqNoNotif;

  /// No description provided for @faqNoNotifAns.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans les paramètres de votre téléphone > Applications > Camelia Logistics et vérifiez que les notifications sont autorisées.'**
  String get faqNoNotifAns;

  /// No description provided for @policy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get policy;

  /// No description provided for @conditions.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get conditions;

  /// No description provided for @policyContent.
  ///
  /// In fr, this message translates to:
  /// **'Votre politique de confidentialité ici...'**
  String get policyContent;

  /// No description provided for @conditionsContent.
  ///
  /// In fr, this message translates to:
  /// **'Vos conditions d\'utilisation ici...'**
  String get conditionsContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
