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
  /// **'Membre depuis 2026'**
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
  /// **'statut'**
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
  /// **'Cela ne devrait pas prendre plus de quelques instants.'**
  String get searchingDriverDesc;

  /// No description provided for @driverNotification.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevrez une notification dès que le devis sera prêt'**
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
  /// **'En attente d\'un devis...'**
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

  /// No description provided for @inventoryOptional.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire (optionnel)'**
  String get inventoryOptional;

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
  /// **'En cours'**
  String get statusAccepted;

  /// No description provided for @statusAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
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

  /// No description provided for @notificationsEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Notifications activées'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Notifications désactivées'**
  String get notificationsDisabled;

  /// No description provided for @estimatedPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix estimé'**
  String get estimatedPrice;

  /// No description provided for @priceBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Détail du tarif'**
  String get priceBreakdown;

  /// No description provided for @train.
  ///
  /// In fr, this message translates to:
  /// **'train'**
  String get train;

  /// No description provided for @trainDesc.
  ///
  /// In fr, this message translates to:
  /// **'Idéal pour les colis volumineux sur de longues distances'**
  String get trainDesc;

  /// No description provided for @needed.
  ///
  /// In fr, this message translates to:
  /// **'De quoi avez vous besoin ?'**
  String get needed;

  /// No description provided for @moto.
  ///
  /// In fr, this message translates to:
  /// **'Moto'**
  String get moto;

  /// No description provided for @selectServiceType.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner le type de service'**
  String get selectServiceType;

  /// No description provided for @chooseYourServiceType.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre type de service'**
  String get chooseYourServiceType;

  /// No description provided for @selectServiceTypeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez le service qui correspond à vos besoins'**
  String get selectServiceTypeDescription;

  /// No description provided for @deliveryService.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get deliveryService;

  /// No description provided for @deliveryServiceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Livraison rapide et à prix fixe du point A au point B'**
  String get deliveryServiceDescription;

  /// No description provided for @movingService.
  ///
  /// In fr, this message translates to:
  /// **'Déménagement'**
  String get movingService;

  /// No description provided for @movingServiceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Service complet de déménagement et de relocalisation avec devis'**
  String get movingServiceDescription;

  /// No description provided for @shipmentService.
  ///
  /// In fr, this message translates to:
  /// **'Expédition'**
  String get shipmentService;

  /// No description provided for @shipmentServiceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez des colis à l\'échelle nationale avec suivi'**
  String get shipmentServiceDescription;

  /// No description provided for @storageService.
  ///
  /// In fr, this message translates to:
  /// **'Stockage'**
  String get storageService;

  /// No description provided for @storageServiceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Solutions de stockage à court et long terme'**
  String get storageServiceDescription;

  /// No description provided for @photosRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Photos recommandées'**
  String get photosRecommended;

  /// No description provided for @photosHelpsEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Les photos nous aident à vous fournir un devis précis'**
  String get photosHelpsEstimate;

  /// No description provided for @delivererDescription.
  ///
  /// In fr, this message translates to:
  /// **'Nb:ce service est pour la livraions des objets de petite taille et de poids léger, pour les colis plus volumineux ou lourds veuillez utiliser le service de déménagement ou d\'expédition'**
  String get delivererDescription;

  /// No description provided for @addPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get addPhotos;

  /// No description provided for @estimatedVolume.
  ///
  /// In fr, this message translates to:
  /// **'Volume estimé'**
  String get estimatedVolume;

  /// No description provided for @volumeInCubicMetersHint.
  ///
  /// In fr, this message translates to:
  /// **'Volume en m³'**
  String get volumeInCubicMetersHint;

  /// No description provided for @departureFloors.
  ///
  /// In fr, this message translates to:
  /// **'Étages au départ'**
  String get departureFloors;

  /// No description provided for @destinationFloors.
  ///
  /// In fr, this message translates to:
  /// **'Étages à la destination'**
  String get destinationFloors;

  /// No description provided for @elevatorAtDeparture.
  ///
  /// In fr, this message translates to:
  /// **'Ascenseur au départ'**
  String get elevatorAtDeparture;

  /// No description provided for @elevatorAtDestination.
  ///
  /// In fr, this message translates to:
  /// **'Ascenseur à la destination'**
  String get elevatorAtDestination;

  /// No description provided for @inventoryDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description de l\'inventaire'**
  String get inventoryDescription;

  /// No description provided for @inventoryHint.
  ///
  /// In fr, this message translates to:
  /// **'Listez les articles que vous souhaitez déplacer...'**
  String get inventoryHint;

  /// No description provided for @shipmentDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de l\'expédition'**
  String get shipmentDetails;

  /// No description provided for @provideShipmentInfo.
  ///
  /// In fr, this message translates to:
  /// **'Fournissez des informations détaillées sur votre expédition'**
  String get provideShipmentInfo;

  /// No description provided for @recipientName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du destinataire'**
  String get recipientName;

  /// No description provided for @fullNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Jean Dupont'**
  String get fullNameHint;

  /// No description provided for @recipientPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du destinataire'**
  String get recipientPhone;

  /// No description provided for @estimatedWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids estimé'**
  String get estimatedWeight;

  /// No description provided for @weightInKgHint.
  ///
  /// In fr, this message translates to:
  /// **'Poids en kg'**
  String get weightInKgHint;

  /// No description provided for @packageNatureOfItem.
  ///
  /// In fr, this message translates to:
  /// **'Nature de l\'article'**
  String get packageNatureOfItem;

  /// No description provided for @describeWhat.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez ce que vous envoyez'**
  String get describeWhat;

  /// No description provided for @photosOptional.
  ///
  /// In fr, this message translates to:
  /// **'Photos (Facultatif)'**
  String get photosOptional;

  /// No description provided for @addPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get addPhoto;

  /// No description provided for @additionalNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes supplémentaires'**
  String get additionalNotes;

  /// No description provided for @addAnySpecialInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des instructions spéciales...'**
  String get addAnySpecialInstructions;

  /// No description provided for @storageDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du stockage'**
  String get storageDetails;

  /// No description provided for @provideStorageInfo.
  ///
  /// In fr, this message translates to:
  /// **'Ce service est pour tout les commerçants qui veulent bénéficier de solutions de stockage à court et long terme.et de livraison à la demande pour leurs clients. Fournissez des informations détaillées sur vos besoins de stockage et de livraison'**
  String get provideStorageInfo;

  /// No description provided for @startDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get startDate;

  /// No description provided for @selectADate.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une date'**
  String get selectADate;

  /// No description provided for @dateSelected.
  ///
  /// In fr, this message translates to:
  /// **'{day}/{month}/{year}'**
  String dateSelected(Object day, Object month, Object year);

  /// No description provided for @estimatedDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée'**
  String get estimatedDuration;

  /// No description provided for @months.
  ///
  /// In fr, this message translates to:
  /// **'mois'**
  String get months;

  /// No description provided for @spaceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Espace requis'**
  String get spaceRequired;

  /// No description provided for @spaceInSquareMetersHint.
  ///
  /// In fr, this message translates to:
  /// **'Espace en m²'**
  String get spaceInSquareMetersHint;

  /// No description provided for @quoteRequestSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Demande de devis soumise avec succès !'**
  String get quoteRequestSubmitted;

  /// No description provided for @inventoryPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Exemple : 1 canapé, 2 chaises, 1 table basse...'**
  String get inventoryPlaceholder;

  /// No description provided for @movingDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du déménagement'**
  String get movingDetails;

  /// No description provided for @provideMovingInfo.
  ///
  /// In fr, this message translates to:
  /// **'Ce service est pour les particuliers ou les entreprises qui souhaitent déménager ou relocaliser leurs biens.et aussi le transport de leurs biens d\'un point A à un point B. Fournissez des informations détaillées sur votre déménagement ou transport pour obtenir un devis précis'**
  String get provideMovingInfo;

  /// No description provided for @selectPackageTypeHint.
  ///
  /// In fr, this message translates to:
  /// **'Type de colis'**
  String get selectPackageTypeHint;

  /// No description provided for @specialInstructionsHint.
  ///
  /// In fr, this message translates to:
  /// **'Instructions spéciales'**
  String get specialInstructionsHint;

  /// No description provided for @packagePhotoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Une photo claire de votre colis nous aide à estimer le prix et à assurer une livraison en toute sécurité.'**
  String get packagePhotoDescription;

  /// No description provided for @photosRequired.
  ///
  /// In fr, this message translates to:
  /// **'Photos requises'**
  String get photosRequired;

  /// No description provided for @photosHelpsStorage.
  ///
  /// In fr, this message translates to:
  /// **'Des photos de vos biens à stocker nous aident à évaluer l\'espace nécessaire et à fournir un devis précis.'**
  String get photosHelpsStorage;

  /// No description provided for @photosHelpsIdentify.
  ///
  /// In fr, this message translates to:
  /// **'Des photos claires de votre colis nous aident à identifier les articles et à assurer une livraison en toute sécurité.'**
  String get photosHelpsIdentify;

  /// No description provided for @photosRequiredHint.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter au moins une photo de votre colis pour continuer.'**
  String get photosRequiredHint;

  /// No description provided for @verifyPhone.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le numéro'**
  String get verifyPhone;

  /// No description provided for @enterOtp.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code OTP'**
  String get enterOtp;

  /// No description provided for @resendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer dans'**
  String get resendIn;

  /// No description provided for @resend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer'**
  String get resend;

  /// No description provided for @verifyPhoneFirst.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vérifier votre numéro de téléphone d\'abord'**
  String get verifyPhoneFirst;

  /// No description provided for @phoneVerified.
  ///
  /// In fr, this message translates to:
  /// **'Numéro vérifié'**
  String get phoneVerified;

  /// No description provided for @sendingCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoi du code...'**
  String get sendingCode;

  /// No description provided for @invalidOtp.
  ///
  /// In fr, this message translates to:
  /// **'Code OTP invalide'**
  String get invalidOtp;

  /// No description provided for @resendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// No description provided for @packageTypeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un type de colis pour continuer.'**
  String get packageTypeRequired;

  /// No description provided for @internationalTransportService.
  ///
  /// In fr, this message translates to:
  /// **'Transport international'**
  String get internationalTransportService;

  /// No description provided for @internationalTransportServiceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez vos colis à l\'international avec notre service de transport fiable et sécurisé. Contactez sur ce numero 237 657519744'**
  String get internationalTransportServiceDescription;

  /// No description provided for @apiErrorOtpRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de demandes de code. Réessayez dans une heure.'**
  String get apiErrorOtpRateLimited;

  /// No description provided for @apiErrorInvalidOtp.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. Vérifiez les 6 chiffres reçus par email.'**
  String get apiErrorInvalidOtp;

  /// No description provided for @apiErrorOtpExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré. Demandez-en un nouveau.'**
  String get apiErrorOtpExpired;

  /// No description provided for @apiErrorOtpMaxAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives sur ce code. Demandez-en un nouveau.'**
  String get apiErrorOtpMaxAttempts;

  /// No description provided for @apiErrorInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get apiErrorInvalidCredentials;

  /// No description provided for @apiErrorAccountInactive.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est désactivé. Contactez le support.'**
  String get apiErrorAccountInactive;

  /// No description provided for @apiErrorEmailNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre email avant de vous connecter.'**
  String get apiErrorEmailNotVerified;

  /// No description provided for @apiErrorInvalidToken.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Reconnectez-vous.'**
  String get apiErrorInvalidToken;

  /// No description provided for @apiErrorDriverProfileRequired.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est réservée aux comptes chauffeur.'**
  String get apiErrorDriverProfileRequired;

  /// No description provided for @apiErrorDriverNotApproved.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte chauffeur n\'est pas encore validé.'**
  String get apiErrorDriverNotApproved;

  /// No description provided for @apiErrorInvalidDriverStatusTransition.
  ///
  /// In fr, this message translates to:
  /// **'Ce changement de statut n\'est pas autorisé.'**
  String get apiErrorInvalidDriverStatusTransition;

  /// No description provided for @apiErrorDocumentRejectionReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Un motif de rejet est obligatoire.'**
  String get apiErrorDocumentRejectionReasonRequired;

  /// No description provided for @apiErrorDriverDocumentsLocked.
  ///
  /// In fr, this message translates to:
  /// **'Vos documents ne peuvent plus être modifiés.'**
  String get apiErrorDriverDocumentsLocked;

  /// No description provided for @apiErrorAccountDeletionBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte ne peut pas être supprimé pour le moment.'**
  String get apiErrorAccountDeletionBlocked;

  /// No description provided for @apiErrorVehicleNotAllowedForHousingType.
  ///
  /// In fr, this message translates to:
  /// **'Ce véhicule n\'est pas proposé pour ce type de logement.'**
  String get apiErrorVehicleNotAllowedForHousingType;

  /// No description provided for @apiErrorNoVehicleForDeclaredWeight.
  ///
  /// In fr, this message translates to:
  /// **'Aucun véhicule ne convient au poids déclaré.'**
  String get apiErrorNoVehicleForDeclaredWeight;

  /// No description provided for @apiErrorDistanceExceedsMaximum.
  ///
  /// In fr, this message translates to:
  /// **'La distance dépasse la limite de nos services.'**
  String get apiErrorDistanceExceedsMaximum;

  /// No description provided for @apiErrorInvalidOrderTransition.
  ///
  /// In fr, this message translates to:
  /// **'Cette action n\'est pas possible à ce stade de la commande.'**
  String get apiErrorInvalidOrderTransition;

  /// No description provided for @apiErrorDriverNotAssignedToOrder.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'êtes pas assigné à cette course.'**
  String get apiErrorDriverNotAssignedToOrder;

  /// No description provided for @apiErrorOrderNotCancellable.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande ne peut plus être annulée.'**
  String get apiErrorOrderNotCancellable;

  /// No description provided for @apiErrorReturnNotRequired.
  ///
  /// In fr, this message translates to:
  /// **'Aucun retour n\'est attendu pour cette commande.'**
  String get apiErrorReturnNotRequired;

  /// No description provided for @apiErrorReturnAlreadyConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Le retour a déjà été confirmé.'**
  String get apiErrorReturnAlreadyConfirmed;

  /// No description provided for @apiErrorWhatsappContactNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Service indisponible : aucun contact n\'est configuré.'**
  String get apiErrorWhatsappContactNotConfigured;

  /// No description provided for @apiErrorUniqueValueGenerationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur technique. Merci de réessayer.'**
  String get apiErrorUniqueValueGenerationFailed;

  /// No description provided for @apiErrorUnknownVehicleType.
  ///
  /// In fr, this message translates to:
  /// **'Ce type de véhicule n\'existe pas.'**
  String get apiErrorUnknownVehicleType;

  /// No description provided for @apiErrorVehicleTypeNotAvailableForDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Ce véhicule n\'est pas proposé en livraison.'**
  String get apiErrorVehicleTypeNotAvailableForDelivery;

  /// No description provided for @apiErrorPricingConfigurationMissing.
  ///
  /// In fr, this message translates to:
  /// **'Tarif indisponible pour cette demande. Contactez le support.'**
  String get apiErrorPricingConfigurationMissing;

  /// No description provided for @apiErrorPromoCodeNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo n\'existe pas.'**
  String get apiErrorPromoCodeNotFound;

  /// No description provided for @apiErrorPromoCodeExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo a expiré.'**
  String get apiErrorPromoCodeExpired;

  /// No description provided for @apiErrorPromoCodeMinOrderAmountNotMet.
  ///
  /// In fr, this message translates to:
  /// **'Le montant de la commande est trop faible pour ce code.'**
  String get apiErrorPromoCodeMinOrderAmountNotMet;

  /// No description provided for @apiErrorPromoCodeGlobalQuotaExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo a atteint sa limite d\'utilisation.'**
  String get apiErrorPromoCodeGlobalQuotaExceeded;

  /// No description provided for @apiErrorPromoCodeUserQuotaExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà utilisé ce code promo.'**
  String get apiErrorPromoCodeUserQuotaExceeded;

  /// No description provided for @apiErrorOfferNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette proposition n\'existe plus.'**
  String get apiErrorOfferNotFound;

  /// No description provided for @apiErrorOfferNoLongerAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Cette proposition n\'est plus disponible.'**
  String get apiErrorOfferNoLongerAvailable;

  /// No description provided for @apiErrorOrderAlreadyAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Cette course a déjà été attribuée.'**
  String get apiErrorOrderAlreadyAssigned;

  /// No description provided for @apiErrorOrderNotDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n\'est possible qu\'après la livraison.'**
  String get apiErrorOrderNotDelivered;

  /// No description provided for @apiErrorOrderManagedByPartner.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande est gérée par un partenaire.'**
  String get apiErrorOrderManagedByPartner;

  /// No description provided for @apiErrorCancellationFeeConfigurationMissing.
  ///
  /// In fr, this message translates to:
  /// **'Frais d\'annulation indisponibles. Contactez le support.'**
  String get apiErrorCancellationFeeConfigurationMissing;

  /// No description provided for @apiErrorWithdrawalConfigurationMissing.
  ///
  /// In fr, this message translates to:
  /// **'Les retraits sont indisponibles pour le moment.'**
  String get apiErrorWithdrawalConfigurationMissing;

  /// No description provided for @apiErrorWithdrawalAmountBelowMinimum.
  ///
  /// In fr, this message translates to:
  /// **'Montant inférieur au minimum de retrait.'**
  String get apiErrorWithdrawalAmountBelowMinimum;

  /// No description provided for @apiErrorWithdrawalAmountExceedsBalance.
  ///
  /// In fr, this message translates to:
  /// **'Montant supérieur à votre solde disponible.'**
  String get apiErrorWithdrawalAmountExceedsBalance;

  /// No description provided for @apiErrorWithdrawalTransferFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le transfert a échoué. Réessayez ou contactez le support.'**
  String get apiErrorWithdrawalTransferFailed;

  /// No description provided for @apiErrorAmbassadorCodeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Un code ambassadeur est requis.'**
  String get apiErrorAmbassadorCodeRequired;

  /// No description provided for @apiErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Merci de réessayer.'**
  String get apiErrorGeneric;

  /// No description provided for @apiErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifiez votre réseau.'**
  String get apiErrorNetwork;

  /// No description provided for @apiErrorThrottled.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez un instant.'**
  String get apiErrorThrottled;

  /// No description provided for @authBrandName.
  ///
  /// In fr, this message translates to:
  /// **'Camelia'**
  String get authBrandName;

  /// No description provided for @authBrandTagline.
  ///
  /// In fr, this message translates to:
  /// **'Logistics'**
  String get authBrandTagline;

  /// No description provided for @authContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get authContinue;

  /// No description provided for @authBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get authBack;

  /// No description provided for @authSignInTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour suivre vos commandes et en créer de nouvelles.'**
  String get authSignInSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.cm'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères'**
  String get authPasswordHint;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit faire au moins 8 caractères.'**
  String get authPasswordTooShort;

  /// No description provided for @authSignInAction.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignInAction;

  /// No description provided for @authTermsPrefix.
  ///
  /// In fr, this message translates to:
  /// **'En continuant, vous acceptez les '**
  String get authTermsPrefix;

  /// No description provided for @authTermsLink.
  ///
  /// In fr, this message translates to:
  /// **'CGU'**
  String get authTermsLink;

  /// No description provided for @authOtherMethod.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser un autre moyen de connexion'**
  String get authOtherMethod;

  /// No description provided for @authNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get authNoAccount;

  /// No description provided for @authCreateAccountLink.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authCreateAccountLink;

  /// No description provided for @authMethodTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment vous connecter ?'**
  String get authMethodTitle;

  /// No description provided for @authMethodSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la méthode de vérification.'**
  String get authMethodSubtitle;

  /// No description provided for @authMethodPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authMethodPasswordTitle;

  /// No description provided for @authMethodPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le mot de passe de votre compte'**
  String get authMethodPasswordSubtitle;

  /// No description provided for @authMethodCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code par email'**
  String get authMethodCodeTitle;

  /// No description provided for @authMethodCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un code à 6 chiffres par email'**
  String get authMethodCodeSubtitle;

  /// No description provided for @authOtpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get authOtpTitle;

  /// No description provided for @authOtpSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé à'**
  String get authOtpSentTo;

  /// No description provided for @authOtpVerifyAction.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get authOtpVerifyAction;

  /// No description provided for @authOtpResendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans'**
  String get authOtpResendIn;

  /// No description provided for @authOtpResendAction.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get authOtpResendAction;

  /// No description provided for @authOtpResent.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau code vient d\'être envoyé.'**
  String get authOtpResent;

  /// No description provided for @authOtpIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez les 6 chiffres du code.'**
  String get authOtpIncomplete;

  /// No description provided for @authRegisterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre compte'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un code de vérification vous sera envoyé par email.'**
  String get authRegisterSubtitle;

  /// No description provided for @authFirstNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get authFirstNameLabel;

  /// No description provided for @authFirstNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Aïcha'**
  String get authFirstNameHint;

  /// No description provided for @authLastNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get authLastNameLabel;

  /// No description provided for @authLastNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ngo Bell'**
  String get authLastNameHint;

  /// No description provided for @authPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In fr, this message translates to:
  /// **'+237 6 XX XX XX XX'**
  String get authPhoneHint;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro au format international requis, ex. +237690000000.'**
  String get authPhoneInvalid;

  /// No description provided for @authRequiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire.'**
  String get authRequiredField;

  /// No description provided for @authRegisterAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authRegisterAction;

  /// No description provided for @authRegisterAsDriver.
  ///
  /// In fr, this message translates to:
  /// **'Je veux devenir chauffeur'**
  String get authRegisterAsDriver;

  /// No description provided for @authRegisterDriverNotice.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte chauffeur devra être validé par Camelia avant de recevoir des courses.'**
  String get authRegisterDriverNotice;

  /// No description provided for @authHasAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ?'**
  String get authHasAccount;

  /// No description provided for @authSignInLink.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignInLink;

  /// No description provided for @authUnsupportedRoleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte administrateur'**
  String get authUnsupportedRoleTitle;

  /// No description provided for @authUnsupportedRoleBody.
  ///
  /// In fr, this message translates to:
  /// **'Les comptes administrateur se gèrent depuis le back-office web, pas depuis l\'application mobile.'**
  String get authUnsupportedRoleBody;

  /// No description provided for @authSignOutAction.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get authSignOutAction;

  /// No description provided for @authLoadingSession.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à Camelia…'**
  String get authLoadingSession;

  /// No description provided for @authRetryAction.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get authRetryAction;

  /// No description provided for @homeClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace client'**
  String get homeClientTitle;

  /// No description provided for @homeDriverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace chauffeur'**
  String get homeDriverTitle;

  /// No description provided for @homeSignedInAs.
  ///
  /// In fr, this message translates to:
  /// **'CONNECTÉ EN TANT QUE'**
  String get homeSignedInAs;

  /// No description provided for @homeRoleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get homeRoleLabel;

  /// No description provided for @homeChangeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'interface'**
  String get homeChangeLanguage;

  /// No description provided for @homeLanguageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get homeLanguageFrench;

  /// No description provided for @homeLanguageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get homeLanguageEnglish;

  /// No description provided for @homeUnderConstructionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Écrans en construction'**
  String get homeUnderConstructionTitle;

  /// No description provided for @homeUnderConstructionBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'authentification est connectée au backend. Les écrans de cette expérience arrivent dans l\'ordre suivant :'**
  String get homeUnderConstructionBody;

  /// No description provided for @homeStepClientOrder.
  ///
  /// In fr, this message translates to:
  /// **'Commande : accueil, adresses, détails du colis'**
  String get homeStepClientOrder;

  /// No description provided for @homeStepClientQuote.
  ///
  /// In fr, this message translates to:
  /// **'Estimation tarifaire (total renvoyé par le serveur)'**
  String get homeStepClientQuote;

  /// No description provided for @homeStepClientTracking.
  ///
  /// In fr, this message translates to:
  /// **'Suivi avec le ruban de statut à 5 étapes'**
  String get homeStepClientTracking;

  /// No description provided for @homeStepClientPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement à la livraison, sur action explicite'**
  String get homeStepClientPayment;

  /// No description provided for @homeStepDriverStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut de validation et bascule en ligne'**
  String get homeStepDriverStatus;

  /// No description provided for @homeStepDriverOffers.
  ///
  /// In fr, this message translates to:
  /// **'Propositions de course, acceptation et refus'**
  String get homeStepDriverOffers;

  /// No description provided for @homeStepDriverProofs.
  ///
  /// In fr, this message translates to:
  /// **'Preuves de collecte et de livraison'**
  String get homeStepDriverProofs;

  /// No description provided for @homeStepDriverWallet.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille et demande de retrait'**
  String get homeStepDriverWallet;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get navOrders;

  /// No description provided for @navWallet.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille'**
  String get navWallet;

  /// No description provided for @navAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get navAccount;

  /// No description provided for @navJobs.
  ///
  /// In fr, this message translates to:
  /// **'Courses'**
  String get navJobs;

  /// No description provided for @navEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains'**
  String get navEarnings;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get homeGreeting;

  /// No description provided for @homeServicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nos services'**
  String get homeServicesTitle;

  /// No description provided for @homeServicesSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get homeServicesSeeAll;

  /// No description provided for @serviceDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Colis'**
  String get serviceDelivery;

  /// No description provided for @serviceMoving.
  ///
  /// In fr, this message translates to:
  /// **'Déménagement'**
  String get serviceMoving;

  /// No description provided for @serviceShipping.
  ///
  /// In fr, this message translates to:
  /// **'Expédition'**
  String get serviceShipping;

  /// No description provided for @serviceStorage.
  ///
  /// In fr, this message translates to:
  /// **'Stockage'**
  String get serviceStorage;

  /// No description provided for @serviceDeliveryHint.
  ///
  /// In fr, this message translates to:
  /// **'Livraison en ville'**
  String get serviceDeliveryHint;

  /// No description provided for @serviceMovingHint.
  ///
  /// In fr, this message translates to:
  /// **'Camion et manutention'**
  String get serviceMovingHint;

  /// No description provided for @serviceShippingHint.
  ///
  /// In fr, this message translates to:
  /// **'Devis manuel'**
  String get serviceShippingHint;

  /// No description provided for @serviceStorageHint.
  ///
  /// In fr, this message translates to:
  /// **'Devis manuel'**
  String get serviceStorageHint;

  /// No description provided for @backendMissingTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente du backend'**
  String get backendMissingTitle;

  /// No description provided for @backendMissingBody.
  ///
  /// In fr, this message translates to:
  /// **'Cet écran a besoin d\'un endpoint que le serveur n\'expose pas encore. Rien n\'est simulé ici pour ne pas laisser croire que la fonctionnalité existe.'**
  String get backendMissingBody;

  /// No description provided for @backendMissingEndpointLabel.
  ///
  /// In fr, this message translates to:
  /// **'Endpoint attendu'**
  String get backendMissingEndpointLabel;

  /// No description provided for @screenComingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Écran à construire'**
  String get screenComingTitle;

  /// No description provided for @screenComingBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'endpoint existe et répond. L\'écran de la maquette arrive dans la prochaine tranche.'**
  String get screenComingBody;

  /// No description provided for @backendMissingJobsNote.
  ///
  /// In fr, this message translates to:
  /// **'Les propositions de course arrivent par notification push, puis par rafraîchissement REST — jamais par une connexion ouverte.'**
  String get backendMissingJobsNote;

  /// No description provided for @driverStatusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Compte validé'**
  String get driverStatusApproved;

  /// No description provided for @driverStatusPendingDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents à fournir'**
  String get driverStatusPendingDocuments;

  /// No description provided for @driverStatusPendingReview.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get driverStatusPendingReview;

  /// No description provided for @driverStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Compte refusé'**
  String get driverStatusRejected;

  /// No description provided for @driverStatusSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu'**
  String get driverStatusSuspended;

  /// No description provided for @driverDocsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes documents'**
  String get driverDocsTitle;

  /// No description provided for @driverDocsHintPending.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez ces trois pièces en photo : Camelia les vérifie avant d\'activer votre compte.'**
  String get driverDocsHintPending;

  /// No description provided for @driverDocsHintReview.
  ///
  /// In fr, this message translates to:
  /// **'Vos pièces sont en cours de vérification. Vous serez prévenu dès qu\'elles sont validées.'**
  String get driverDocsHintReview;

  /// No description provided for @driverDocsHintRejected.
  ///
  /// In fr, this message translates to:
  /// **'Une pièce a été refusée. Remplacez-la pour relancer la vérification.'**
  String get driverDocsHintRejected;

  /// No description provided for @driverDocIdCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte nationale d\'identité'**
  String get driverDocIdCard;

  /// No description provided for @driverDocDrivingLicence.
  ///
  /// In fr, this message translates to:
  /// **'Permis de conduire'**
  String get driverDocDrivingLicence;

  /// No description provided for @driverDocVehicleRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Carte grise'**
  String get driverDocVehicleRegistration;

  /// No description provided for @driverDocStateMissing.
  ///
  /// In fr, this message translates to:
  /// **'À fournir'**
  String get driverDocStateMissing;

  /// No description provided for @driverDocStatePending.
  ///
  /// In fr, this message translates to:
  /// **'En vérification'**
  String get driverDocStatePending;

  /// No description provided for @driverDocStateApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get driverDocStateApproved;

  /// No description provided for @driverDocStateRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusé'**
  String get driverDocStateRejected;

  /// No description provided for @driverDocRejectionReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String driverDocRejectionReason(String reason);

  /// No description provided for @driverDocUpload.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get driverDocUpload;

  /// No description provided for @driverDocReplace.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get driverDocReplace;

  /// No description provided for @driverDocSent.
  ///
  /// In fr, this message translates to:
  /// **'Document envoyé.'**
  String get driverDocSent;

  /// No description provided for @driverOnlineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get driverOnlineLabel;

  /// No description provided for @driverOfflineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get driverOfflineLabel;

  /// No description provided for @driverOnlineHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez des propositions de course.'**
  String get driverOnlineHint;

  /// No description provided for @driverOfflineHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition ne vous sera envoyée.'**
  String get driverOfflineHint;

  /// No description provided for @driverCannotGoOnline.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte doit être validé avant de passer en ligne.'**
  String get driverCannotGoOnline;

  /// No description provided for @driverVehicleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get driverVehicleLabel;

  /// No description provided for @driverRatingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get driverRatingLabel;

  /// No description provided for @driverDocumentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pièces justificatives'**
  String get driverDocumentsTitle;

  /// No description provided for @driverDocPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get driverDocPending;

  /// No description provided for @driverDocApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
  String get driverDocApproved;

  /// No description provided for @driverDocRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get driverDocRejected;

  /// No description provided for @driverOffersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Propositions'**
  String get driverOffersTitle;

  /// No description provided for @driverOffersEmptyOnline.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition pour le moment. Elles arrivent par notification.'**
  String get driverOffersEmptyOnline;

  /// No description provided for @driverOffersEmptyOffline.
  ///
  /// In fr, this message translates to:
  /// **'Passez en ligne pour recevoir des propositions.'**
  String get driverOffersEmptyOffline;

  /// No description provided for @driverLocationPermissionNeeded.
  ///
  /// In fr, this message translates to:
  /// **'Localisation refusée : aucune course ne peut vous être proposée. Autorisez la localisation pour Camelia dans les réglages du téléphone.'**
  String get driverLocationPermissionNeeded;

  /// No description provided for @driverLocationServiceOff.
  ///
  /// In fr, this message translates to:
  /// **'GPS désactivé : aucune course ne peut vous être proposée. Activez la localisation du téléphone.'**
  String get driverLocationServiceOff;

  /// No description provided for @driverOfferAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get driverOfferAccept;

  /// No description provided for @driverOfferDecline.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get driverOfferDecline;

  /// No description provided for @driverOfferAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Course acceptée'**
  String get driverOfferAccepted;

  /// No description provided for @driverOfferDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Proposition refusée'**
  String get driverOfferDeclined;

  /// No description provided for @driverOfferStatusSent.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle'**
  String get driverOfferStatusSent;

  /// No description provided for @driverOfferStatusAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get driverOfferStatusAccepted;

  /// No description provided for @driverOfferStatusDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get driverOfferStatusDeclined;

  /// No description provided for @driverOfferStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get driverOfferStatusExpired;

  /// No description provided for @driverOfferDistance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get driverOfferDistance;

  /// No description provided for @driverOfferPickup.
  ///
  /// In fr, this message translates to:
  /// **'Collecte'**
  String get driverOfferPickup;

  /// No description provided for @driverOfferDropoff.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get driverOfferDropoff;

  /// No description provided for @walletBalanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Solde disponible'**
  String get walletBalanceLabel;

  /// No description provided for @walletTotalEarnedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total gagné'**
  String get walletTotalEarnedLabel;

  /// No description provided for @walletHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get walletHistoryTitle;

  /// No description provided for @walletHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune écriture pour le moment.'**
  String get walletHistoryEmpty;

  /// No description provided for @walletWithdrawAction.
  ///
  /// In fr, this message translates to:
  /// **'Demander un retrait'**
  String get walletWithdrawAction;

  /// No description provided for @walletWithdrawTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retrait mobile money'**
  String get walletWithdrawTitle;

  /// No description provided for @walletWithdrawAmountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get walletWithdrawAmountLabel;

  /// No description provided for @walletWithdrawHint.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 2 000 FCFA'**
  String get walletWithdrawHint;

  /// No description provided for @walletWithdrawConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le retrait'**
  String get walletWithdrawConfirm;

  /// No description provided for @walletWithdrawPending.
  ///
  /// In fr, this message translates to:
  /// **'Demande enregistrée. Le virement sera confirmé sous peu.'**
  String get walletWithdrawPending;

  /// No description provided for @walletWithdrawAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un montant.'**
  String get walletWithdrawAmountRequired;

  /// No description provided for @ambassadorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Parrainage'**
  String get ambassadorTitle;

  /// No description provided for @ambassadorUsageCount.
  ///
  /// In fr, this message translates to:
  /// **'Utilisations'**
  String get ambassadorUsageCount;

  /// No description provided for @ambassadorConversionCount.
  ///
  /// In fr, this message translates to:
  /// **'Conversions'**
  String get ambassadorConversionCount;

  /// No description provided for @ambassadorRecentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernières commissions'**
  String get ambassadorRecentTitle;

  /// No description provided for @ledgerPaymentIn.
  ///
  /// In fr, this message translates to:
  /// **'Encaissement client'**
  String get ledgerPaymentIn;

  /// No description provided for @ledgerCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission Camelia'**
  String get ledgerCommission;

  /// No description provided for @ledgerDriverCredit.
  ///
  /// In fr, this message translates to:
  /// **'Crédit de course'**
  String get ledgerDriverCredit;

  /// No description provided for @ledgerWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait'**
  String get ledgerWithdrawal;

  /// No description provided for @ledgerRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get ledgerRefund;

  /// No description provided for @ledgerBonusReferral.
  ///
  /// In fr, this message translates to:
  /// **'Bonus parrainage'**
  String get ledgerBonusReferral;

  /// No description provided for @ledgerAmbassadorCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission ambassadeur'**
  String get ledgerAmbassadorCommission;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir'**
  String get commonRefresh;

  /// No description provided for @ribbonOrderReceived.
  ///
  /// In fr, this message translates to:
  /// **'Commande reçue'**
  String get ribbonOrderReceived;

  /// No description provided for @ribbonDriverAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeur assigné'**
  String get ribbonDriverAssigned;

  /// No description provided for @ribbonPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Colis récupéré'**
  String get ribbonPickedUp;

  /// No description provided for @ribbonEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'En route vers la livraison'**
  String get ribbonEnRoute;

  /// No description provided for @ribbonDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livré'**
  String get ribbonDelivered;

  /// No description provided for @ribbonShortReceived.
  ///
  /// In fr, this message translates to:
  /// **'Reçue'**
  String get ribbonShortReceived;

  /// No description provided for @ribbonShortAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Assignée'**
  String get ribbonShortAssigned;

  /// No description provided for @ribbonShortPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Collectée'**
  String get ribbonShortPickedUp;

  /// No description provided for @ribbonShortEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get ribbonShortEnRoute;

  /// No description provided for @ribbonShortDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get ribbonShortDelivered;

  /// No description provided for @ribbonPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get ribbonPending;

  /// No description provided for @orderStatusDraft.
  ///
  /// In fr, this message translates to:
  /// **'Devis en préparation'**
  String get orderStatusDraft;

  /// No description provided for @orderStatusSearchingDriver.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get orderStatusSearchingDriver;

  /// No description provided for @orderStatusDriverAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Assignée'**
  String get orderStatusDriverAssigned;

  /// No description provided for @orderStatusEnRoutePickup.
  ///
  /// In fr, this message translates to:
  /// **'Vers la collecte'**
  String get orderStatusEnRoutePickup;

  /// No description provided for @orderStatusPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Collectée'**
  String get orderStatusPickedUp;

  /// No description provided for @orderStatusInTransit.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get orderStatusInTransit;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelledByClient.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get orderStatusCancelledByClient;

  /// No description provided for @orderStatusCancelledBySystem.
  ///
  /// In fr, this message translates to:
  /// **'Sans chauffeur'**
  String get orderStatusCancelledBySystem;

  /// No description provided for @orderStatusDisputed.
  ///
  /// In fr, this message translates to:
  /// **'Litige'**
  String get orderStatusDisputed;

  /// No description provided for @commonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonBackHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get commonBackHome;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get fieldRequired;

  /// No description provided for @fieldTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Ce texte est trop long.'**
  String get fieldTooLong;

  /// No description provided for @fieldInvalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide. Exemple : +237 6 90 00 00 00.'**
  String get fieldInvalidPhone;

  /// No description provided for @photoTake.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get photoTake;

  /// No description provided for @photoChooseGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get photoChooseGallery;

  /// No description provided for @photoRetake.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get photoRetake;

  /// No description provided for @photoRequired.
  ///
  /// In fr, this message translates to:
  /// **'Une photo est obligatoire.'**
  String get photoRequired;

  /// No description provided for @photoFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire la photo. Réessayez.'**
  String get photoFailed;

  /// No description provided for @externalOpenFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'application correspondante.'**
  String get externalOpenFailed;

  /// No description provided for @orderAddressesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Adresses'**
  String get orderAddressesTitle;

  /// No description provided for @orderPickupLabel.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get orderPickupLabel;

  /// No description provided for @orderDropoffLabel.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get orderDropoffLabel;

  /// No description provided for @orderAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Quartier, rue, repère connu'**
  String get orderAddressHint;

  /// No description provided for @orderAddressesTip.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un repère connu (immeuble, carrefour) : nos serveurs localisent l\'adresse et calculent la distance.'**
  String get orderAddressesTip;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détails du colis'**
  String get orderDetailsTitle;

  /// No description provided for @orderManualDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre besoin'**
  String get orderManualDetailsTitle;

  /// No description provided for @orderPhotoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photo du colis'**
  String get orderPhotoLabel;

  /// No description provided for @orderPhotoEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une photo du colis'**
  String get orderPhotoEmpty;

  /// No description provided for @orderParcelKindLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de colis'**
  String get orderParcelKindLabel;

  /// No description provided for @parcelKindDocument.
  ///
  /// In fr, this message translates to:
  /// **'Document'**
  String get parcelKindDocument;

  /// No description provided for @parcelKindStandard.
  ///
  /// In fr, this message translates to:
  /// **'Colis standard'**
  String get parcelKindStandard;

  /// No description provided for @parcelKindFragile.
  ///
  /// In fr, this message translates to:
  /// **'Fragile'**
  String get parcelKindFragile;

  /// No description provided for @parcelKindBulky.
  ///
  /// In fr, this message translates to:
  /// **'Volumineux'**
  String get parcelKindBulky;

  /// No description provided for @orderWeightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poids estimé'**
  String get orderWeightLabel;

  /// No description provided for @orderWeightValue.
  ///
  /// In fr, this message translates to:
  /// **'{weight} kg'**
  String orderWeightValue(Object weight);

  /// No description provided for @orderInstructionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Instructions (optionnel)'**
  String get orderInstructionsLabel;

  /// No description provided for @orderInstructionsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Sonner à l\'interphone, 2e étage…'**
  String get orderInstructionsHint;

  /// No description provided for @orderDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description du besoin'**
  String get orderDescriptionLabel;

  /// No description provided for @orderShippingDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : deux cartons de documents vers Yaoundé'**
  String get orderShippingDescriptionHint;

  /// No description provided for @orderStorageDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : six cartons pendant deux semaines'**
  String get orderStorageDescriptionHint;

  /// No description provided for @orderRecipientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Destinataire'**
  String get orderRecipientTitle;

  /// No description provided for @orderRecipientName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du destinataire'**
  String get orderRecipientName;

  /// No description provided for @orderRecipientPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du destinataire'**
  String get orderRecipientPhone;

  /// No description provided for @orderRecipientIsMe.
  ///
  /// In fr, this message translates to:
  /// **'C\'est moi'**
  String get orderRecipientIsMe;

  /// No description provided for @orderReviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get orderReviewTitle;

  /// No description provided for @orderReviewService.
  ///
  /// In fr, this message translates to:
  /// **'Service'**
  String get orderReviewService;

  /// No description provided for @orderReviewParcel.
  ///
  /// In fr, this message translates to:
  /// **'Colis'**
  String get orderReviewParcel;

  /// No description provided for @orderPromoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code promo'**
  String get orderPromoLabel;

  /// No description provided for @orderPromoHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : BIENVENUE10'**
  String get orderPromoHint;

  /// No description provided for @orderPromoNote.
  ///
  /// In fr, this message translates to:
  /// **'Le code est vérifié par nos serveurs à la validation.'**
  String get orderPromoNote;

  /// No description provided for @orderPriceNoticeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prix confirmé à la validation'**
  String get orderPriceNoticeTitle;

  /// No description provided for @orderPriceNoticeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le total affiché est le devis calculé par nos serveurs. Il est recalculé à la validation, code promo compris : le montant facturé peut être inférieur, jamais supérieur. L\'annulation est gratuite tant qu\'aucun chauffeur n\'a accepté.'**
  String get orderPriceNoticeBody;

  /// No description provided for @orderManualNoticeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Devis personnalisé'**
  String get orderManualNoticeTitle;

  /// No description provided for @orderManualNoticeBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce service fait l\'objet d\'un devis établi par notre équipe. Aucun montant ne vous est demandé maintenant.'**
  String get orderManualNoticeBody;

  /// No description provided for @orderPaymentNoticeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement à la livraison'**
  String get orderPaymentNoticeTitle;

  /// No description provided for @orderPaymentNoticeBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous payez par Mobile Money une fois le colis livré, depuis l\'écran de suivi.'**
  String get orderPaymentNoticeBody;

  /// No description provided for @orderSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la commande'**
  String get orderSubmit;

  /// No description provided for @orderFixErrors.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez les champs signalés.'**
  String get orderFixErrors;

  /// No description provided for @orderConfirmedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commande confirmée'**
  String get orderConfirmedTitle;

  /// No description provided for @orderManualConfirmedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande enregistrée'**
  String get orderManualConfirmedTitle;

  /// No description provided for @orderReference.
  ///
  /// In fr, this message translates to:
  /// **'Commande #{reference}'**
  String orderReference(Object reference);

  /// No description provided for @orderConfirmRoute.
  ///
  /// In fr, this message translates to:
  /// **'Trajet'**
  String get orderConfirmRoute;

  /// No description provided for @orderConfirmType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get orderConfirmType;

  /// No description provided for @orderConfirmPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get orderConfirmPayment;

  /// No description provided for @orderConfirmPaymentValue.
  ///
  /// In fr, this message translates to:
  /// **'À la livraison · Mobile Money'**
  String get orderConfirmPaymentValue;

  /// No description provided for @orderConfirmTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get orderConfirmTotal;

  /// No description provided for @orderConfirmQuote.
  ///
  /// In fr, this message translates to:
  /// **'Sur devis'**
  String get orderConfirmQuote;

  /// No description provided for @orderTrack.
  ///
  /// In fr, this message translates to:
  /// **'Suivre ma commande'**
  String get orderTrack;

  /// No description provided for @orderOpenWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sur WhatsApp'**
  String get orderOpenWhatsApp;

  /// No description provided for @orderWhatsAppNote.
  ///
  /// In fr, this message translates to:
  /// **'Un conseiller finalise votre devis sur WhatsApp.'**
  String get orderWhatsAppNote;

  /// No description provided for @trackingProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get trackingProgress;

  /// No description provided for @trackingSearchingHeader.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en cours'**
  String get trackingSearchingHeader;

  /// No description provided for @trackingSearchingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche d\'un chauffeur…'**
  String get trackingSearchingTitle;

  /// No description provided for @trackingSearchingBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous contactons les chauffeurs disponibles près de votre point de départ.'**
  String get trackingSearchingBody;

  /// No description provided for @trackingOrderRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Commande enregistrée'**
  String get trackingOrderRegistered;

  /// No description provided for @trackingPullToRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Tirez vers le bas pour actualiser.'**
  String get trackingPullToRefresh;

  /// No description provided for @trackingCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get trackingCancel;

  /// No description provided for @trackingCancelConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande ?'**
  String get trackingCancelConfirmTitle;

  /// No description provided for @trackingCancelConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Des frais peuvent s\'appliquer si un chauffeur a déjà accepté la course. C\'est notre serveur qui le détermine.'**
  String get trackingCancelConfirmBody;

  /// No description provided for @trackingCancelConfirmYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get trackingCancelConfirmYes;

  /// No description provided for @trackingCancelKeep.
  ///
  /// In fr, this message translates to:
  /// **'Garder la commande'**
  String get trackingCancelKeep;

  /// No description provided for @trackingCancelledTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée'**
  String get trackingCancelledTitle;

  /// No description provided for @trackingCancelledBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande a été annulée.'**
  String get trackingCancelledBody;

  /// No description provided for @trackingCancelledFeeBody.
  ///
  /// In fr, this message translates to:
  /// **'Des frais d\'annulation s\'appliquent. Réglez-les par Mobile Money.'**
  String get trackingCancelledFeeBody;

  /// No description provided for @trackingPayFee.
  ///
  /// In fr, this message translates to:
  /// **'Régler les frais'**
  String get trackingPayFee;

  /// No description provided for @trackingNoDriverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chauffeur disponible dans votre zone'**
  String get trackingNoDriverTitle;

  /// No description provided for @trackingNoDriverBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chauffeur n\'a accepté votre commande à temps. Vous n\'avez rien payé.'**
  String get trackingNoDriverBody;

  /// No description provided for @trackingNoDriverRetry.
  ///
  /// In fr, this message translates to:
  /// **'Passer une nouvelle commande'**
  String get trackingNoDriverRetry;

  /// No description provided for @trackingDisputedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commande en litige'**
  String get trackingDisputedTitle;

  /// No description provided for @trackingDisputedBody.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe examine cette commande et reviendra vers vous.'**
  String get trackingDisputedBody;

  /// No description provided for @trackingDraftTitle.
  ///
  /// In fr, this message translates to:
  /// **'Devis en préparation'**
  String get trackingDraftTitle;

  /// No description provided for @trackingDraftBody.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe prépare votre devis. Vous serez contacté.'**
  String get trackingDraftBody;

  /// No description provided for @trackingPickupLabel.
  ///
  /// In fr, this message translates to:
  /// **'Collecte'**
  String get trackingPickupLabel;

  /// No description provided for @trackingDropoffLabel.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get trackingDropoffLabel;

  /// No description provided for @trackingParcel.
  ///
  /// In fr, this message translates to:
  /// **'Colis'**
  String get trackingParcel;

  /// No description provided for @trackingToPayOnDelivery.
  ///
  /// In fr, this message translates to:
  /// **'À payer à la livraison'**
  String get trackingToPayOnDelivery;

  /// No description provided for @trackingTotalPaid.
  ///
  /// In fr, this message translates to:
  /// **'Total payé'**
  String get trackingTotalPaid;

  /// No description provided for @trackingPayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Colis livré — il reste à payer'**
  String get trackingPayTitle;

  /// No description provided for @trackingPayBody.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur le bouton : une demande de paiement arrivera sur votre téléphone. Validez-la avec votre code secret Mobile Money.'**
  String get trackingPayBody;

  /// No description provided for @trackingPayButton.
  ///
  /// In fr, this message translates to:
  /// **'Payer {amount}'**
  String trackingPayButton(Object amount);

  /// No description provided for @trackingPayPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours de validation'**
  String get trackingPayPendingTitle;

  /// No description provided for @trackingPayPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'Validez l\'opération sur votre téléphone, puis actualisez. La confirmation peut prendre quelques instants.'**
  String get trackingPayPendingBody;

  /// No description provided for @trackingPayOpenAgain.
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir l\'invite de paiement'**
  String get trackingPayOpenAgain;

  /// No description provided for @trackingCompletedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Colis livré'**
  String get trackingCompletedTitle;

  /// No description provided for @trackingCompletedBody.
  ///
  /// In fr, this message translates to:
  /// **'Livraison terminée et paiement confirmé. Merci d\'avoir choisi Camelia.'**
  String get trackingCompletedBody;

  /// No description provided for @trackingRecipient.
  ///
  /// In fr, this message translates to:
  /// **'Destinataire'**
  String get trackingRecipient;

  /// No description provided for @homeActiveOrderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commande en cours'**
  String get homeActiveOrderTitle;

  /// No description provided for @homeActiveOrdersError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'actualiser vos commandes en cours.'**
  String get homeActiveOrdersError;

  /// No description provided for @driverOfferNewCourse.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle course'**
  String get driverOfferNewCourse;

  /// No description provided for @driverCurrentCourseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Course en cours'**
  String get driverCurrentCourseTitle;

  /// No description provided for @driverCurrentCourseOpen.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la course'**
  String get driverCurrentCourseOpen;

  /// No description provided for @driverCourseToPickup.
  ///
  /// In fr, this message translates to:
  /// **'En route vers la collecte'**
  String get driverCourseToPickup;

  /// No description provided for @driverCourseToDropoff.
  ///
  /// In fr, this message translates to:
  /// **'En route vers la livraison'**
  String get driverCourseToDropoff;

  /// No description provided for @driverCourseAcceptedAt.
  ///
  /// In fr, this message translates to:
  /// **'Acceptée à {time}'**
  String driverCourseAcceptedAt(Object time);

  /// No description provided for @driverOpenInMaps.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans Maps'**
  String get driverOpenInMaps;

  /// No description provided for @driverArrivedPickup.
  ///
  /// In fr, this message translates to:
  /// **'Je suis arrivé à la collecte'**
  String get driverArrivedPickup;

  /// No description provided for @driverArrivedDropoff.
  ///
  /// In fr, this message translates to:
  /// **'Je suis arrivé'**
  String get driverArrivedDropoff;

  /// No description provided for @driverCallRecipient.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get driverCallRecipient;

  /// No description provided for @driverPickupProofTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récupération du colis'**
  String get driverPickupProofTitle;

  /// No description provided for @driverPickupProofHint.
  ///
  /// In fr, this message translates to:
  /// **'Photographiez le colis entier et son état à la remise. Votre position est jointe à la preuve.'**
  String get driverPickupProofHint;

  /// No description provided for @driverChecklistTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle du colis'**
  String get driverChecklistTitle;

  /// No description provided for @driverCheckPackaging.
  ///
  /// In fr, this message translates to:
  /// **'Emballage intact'**
  String get driverCheckPackaging;

  /// No description provided for @driverCheckWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids conforme'**
  String get driverCheckWeight;

  /// No description provided for @driverCheckLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étiquette destinataire vérifiée'**
  String get driverCheckLabel;

  /// No description provided for @driverChecklistNote.
  ///
  /// In fr, this message translates to:
  /// **'Aide-mémoire personnel : ces cases ne sont pas transmises.'**
  String get driverChecklistNote;

  /// No description provided for @driverConfirmPickup.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la récupération'**
  String get driverConfirmPickup;

  /// No description provided for @driverDeliveryProofTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la livraison'**
  String get driverDeliveryProofTitle;

  /// No description provided for @driverDeliveryProofHint.
  ///
  /// In fr, this message translates to:
  /// **'Photographiez le colis remis au réceptionnaire.'**
  String get driverDeliveryProofHint;

  /// No description provided for @driverProofPhotoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Preuve de livraison'**
  String get driverProofPhotoLabel;

  /// No description provided for @driverRecipientNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réceptionnaire'**
  String get driverRecipientNameLabel;

  /// No description provided for @driverRecipientNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la personne qui reçoit le colis'**
  String get driverRecipientNameHint;

  /// No description provided for @driverConfirmDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Valider la livraison'**
  String get driverConfirmDelivery;

  /// No description provided for @driverFinishedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Course terminée'**
  String get driverFinishedTitle;

  /// No description provided for @driverFinishedBody.
  ///
  /// In fr, this message translates to:
  /// **'Le client est invité à payer par Mobile Money. Votre gain est crédité sur votre portefeuille dès le paiement confirmé.'**
  String get driverFinishedBody;

  /// No description provided for @driverFinishedContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer à recevoir des courses'**
  String get driverFinishedContinue;

  /// No description provided for @driverCourseStaleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette course n\'est plus active'**
  String get driverCourseStaleTitle;

  /// No description provided for @driverCourseStaleBody.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur a refusé l\'action : la commande a peut-être été annulée ou réassignée.'**
  String get driverCourseStaleBody;

  /// No description provided for @driverCourseRelease.
  ///
  /// In fr, this message translates to:
  /// **'Libérer la course'**
  String get driverCourseRelease;

  /// No description provided for @driverDistanceKm.
  ///
  /// In fr, this message translates to:
  /// **'{km} km'**
  String driverDistanceKm(Object km);

  /// No description provided for @driverParcelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Colis'**
  String get driverParcelLabel;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @addressPickerSingleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Placer l\'adresse'**
  String get addressPickerSingleTitle;

  /// No description provided for @addressPickerHint.
  ///
  /// In fr, this message translates to:
  /// **'Déplacez la carte pour placer le repère'**
  String get addressPickerHint;

  /// No description provided for @addressPickerPendingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Validez ce point pour obtenir son adresse.'**
  String get addressPickerPendingLabel;

  /// No description provided for @addressPickerResolvePoint.
  ///
  /// In fr, this message translates to:
  /// **'Valider ce point'**
  String get addressPickerResolvePoint;

  /// No description provided for @addressPickerLocating.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de l\'adresse…'**
  String get addressPickerLocating;

  /// No description provided for @addressPickerLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'Adresse ou repère (quartier, immeuble…)'**
  String get addressPickerLabelHint;

  /// No description provided for @addressPickerNoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse connue ici : saisissez un repère (immeuble, carrefour).'**
  String get addressPickerNoLabel;

  /// No description provided for @addressPickerNotPlaced.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour placer sur la carte'**
  String get addressPickerNotPlaced;

  /// No description provided for @addressPickerMyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get addressPickerMyLocation;

  /// No description provided for @addressPickerLocatingDevice.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de votre position…'**
  String get addressPickerLocatingDevice;

  /// No description provided for @addressPickerLocationServiceOff.
  ///
  /// In fr, this message translates to:
  /// **'La localisation est désactivée sur votre téléphone.'**
  String get addressPickerLocationServiceOff;

  /// No description provided for @addressPickerLocationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès à la position refusé : placez le repère sur la carte ou cherchez une adresse.'**
  String get addressPickerLocationDenied;

  /// No description provided for @addressPickerLocationBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Accès à la position bloqué. Autorisez-le dans les réglages du téléphone.'**
  String get addressPickerLocationBlocked;

  /// No description provided for @addressPickerLocationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position introuvable pour le moment. Réessayez, ou placez le repère à la main.'**
  String get addressPickerLocationUnavailable;

  /// No description provided for @addressPickerLocationOutside.
  ///
  /// In fr, this message translates to:
  /// **'Votre position est hors de la zone desservie : placez le repère au Cameroun.'**
  String get addressPickerLocationOutside;

  /// No description provided for @addressPickerLocationEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get addressPickerLocationEnable;

  /// No description provided for @commonSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get commonSettings;

  /// No description provided for @addressPickerSaveFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get addressPickerSaveFavorite;

  /// No description provided for @addressPickerSaveFavoriteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer cette adresse'**
  String get addressPickerSaveFavoriteTitle;

  /// No description provided for @addressPickerFavoriteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom (Maison, Travail…)'**
  String get addressPickerFavoriteLabel;

  /// No description provided for @addressPickerFavoriteSaved.
  ///
  /// In fr, this message translates to:
  /// **'Adresse enregistrée.'**
  String get addressPickerFavoriteSaved;

  /// No description provided for @addressPickerConfirmRoute.
  ///
  /// In fr, this message translates to:
  /// **'Valider les adresses'**
  String get addressPickerConfirmRoute;

  /// No description provided for @addressPickerConfirmPoint.
  ///
  /// In fr, this message translates to:
  /// **'Choisir ce point'**
  String get addressPickerConfirmPoint;

  /// No description provided for @addressPickerSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get addressPickerSearch;

  /// No description provided for @addressPickerNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu trouvé. Déplacez la carte pour placer le repère, puis nommez l\'adresse.'**
  String get addressPickerNoResult;

  /// No description provided for @addressLabelsAttribution.
  ///
  /// In fr, this message translates to:
  /// **'Adresses © les contributeurs d\'OpenStreetMap'**
  String get addressLabelsAttribution;

  /// No description provided for @orderPhotosLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photos du colis ({count}/{max})'**
  String orderPhotosLabel(Object count, Object max);

  /// No description provided for @orderPhotoAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get orderPhotoAdd;

  /// No description provided for @orderPhotoRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get orderPhotoRemove;

  /// No description provided for @orderPhotosHint.
  ///
  /// In fr, this message translates to:
  /// **'De une à trois photos : le colis entier, l\'emballage, l\'étiquette.'**
  String get orderPhotosHint;

  /// No description provided for @accountPersonalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get accountPersonalInfo;

  /// No description provided for @accountSavedAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Adresses favorites'**
  String get accountSavedAddresses;

  /// No description provided for @accountReferral.
  ///
  /// In fr, this message translates to:
  /// **'Parrainage'**
  String get accountReferral;

  /// No description provided for @accountMemberSince.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis {date}'**
  String accountMemberSince(Object date);

  /// No description provided for @accountLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get accountLanguage;

  /// No description provided for @profileSaveName.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get profileSaveName;

  /// No description provided for @profileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour.'**
  String get profileSaved;

  /// No description provided for @profileEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est votre identifiant de connexion : il ne se modifie pas ici.'**
  String get profileEmailReadOnly;

  /// No description provided for @profilePhoneSection.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get profilePhoneSection;

  /// No description provided for @profilePhoneCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Numéro actuel'**
  String get profilePhoneCurrent;

  /// No description provided for @profilePhoneChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer de numéro'**
  String get profilePhoneChange;

  /// No description provided for @profilePhoneNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau numéro'**
  String get profilePhoneNew;

  /// No description provided for @profilePhoneSendCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un code'**
  String get profilePhoneSendCode;

  /// No description provided for @profilePhoneCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé au {phone}.'**
  String profilePhoneCodeSent(Object phone);

  /// No description provided for @profilePhoneCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code reçu'**
  String get profilePhoneCodeLabel;

  /// No description provided for @profilePhoneVerify.
  ///
  /// In fr, this message translates to:
  /// **'Valider le numéro'**
  String get profilePhoneVerify;

  /// No description provided for @profilePhoneUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Numéro mis à jour.'**
  String get profilePhoneUpdated;

  /// No description provided for @profilePhoneWhy.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro sert au chauffeur et au paiement Mobile Money : il est vérifié par un code avant d\'être changé.'**
  String get profilePhoneWhy;

  /// No description provided for @profileCodeInvalidLength.
  ///
  /// In fr, this message translates to:
  /// **'Le code comporte 6 chiffres.'**
  String get profileCodeInvalidLength;

  /// No description provided for @addressesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Adresses favorites'**
  String get addressesTitle;

  /// No description provided for @addressesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse enregistrée. Ajoutez votre maison ou votre travail pour commander plus vite.'**
  String get addressesEmpty;

  /// No description provided for @addressesAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une adresse'**
  String get addressesAdd;

  /// No description provided for @addressesDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {label} » ?'**
  String addressesDeleteConfirm(Object label);

  /// No description provided for @addressesRename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get addressesRename;

  /// No description provided for @addressesMovePoint.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer sur la carte'**
  String get addressesMovePoint;

  /// No description provided for @apiErrorPhoneAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est déjà utilisé par un autre compte.'**
  String get apiErrorPhoneAlreadyUsed;

  /// No description provided for @apiErrorGeocodingUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Recherche d\'adresse momentanément indisponible. Déplacez la carte pour placer le repère.'**
  String get apiErrorGeocodingUnavailable;

  /// No description provided for @apiErrorGeocodeBusy.
  ///
  /// In fr, this message translates to:
  /// **'Trop de recherches d\'adresse en même temps. Réessayez dans un instant ou placez le repère sur la carte.'**
  String get apiErrorGeocodeBusy;

  /// No description provided for @apiErrorMediaUploadUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'envoi de la photo a échoué. Réessayez dans un instant.'**
  String get apiErrorMediaUploadUnavailable;

  /// No description provided for @apiErrorDocumentUploadUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'envoi du document a échoué. Réessayez dans un instant.'**
  String get apiErrorDocumentUploadUnavailable;

  /// No description provided for @apiErrorDistanceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le calcul de la distance est momentanément indisponible. Réessayez dans un instant.'**
  String get apiErrorDistanceUnavailable;

  /// No description provided for @apiErrorCoordinatesOutsideServiceArea.
  ///
  /// In fr, this message translates to:
  /// **'Ce point est en dehors de la zone desservie. Choisissez une adresse au Cameroun.'**
  String get apiErrorCoordinatesOutsideServiceArea;

  /// No description provided for @apiErrorInvalidDeliveryCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de remise incorrect. Demandez au destinataire de relire le code sur son écran de suivi.'**
  String get apiErrorInvalidDeliveryCode;

  /// No description provided for @apiErrorDeliveryCodeAttemptsExhausted.
  ///
  /// In fr, this message translates to:
  /// **'Trois codes erronés : un nouveau code a été envoyé au client et le support est prévenu. Demandez-lui de relire son écran.'**
  String get apiErrorDeliveryCodeAttemptsExhausted;

  /// No description provided for @apiErrorOrderNotRatable.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande ne peut pas encore être notée.'**
  String get apiErrorOrderNotRatable;

  /// No description provided for @apiErrorOrderAlreadyRated.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà noté cette commande.'**
  String get apiErrorOrderAlreadyRated;

  /// No description provided for @apiErrorOrderHasNoDriverToRate.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chauffeur n\'a effectué cette commande.'**
  String get apiErrorOrderHasNoDriverToRate;

  /// No description provided for @apiErrorOrderNotRelaunchable.
  ///
  /// In fr, this message translates to:
  /// **'La recherche ne peut pas être relancée pour cette commande.'**
  String get apiErrorOrderNotRelaunchable;

  /// No description provided for @apiErrorSearchRelaunchLimitReached.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint le nombre maximal de relances. Passez une nouvelle commande.'**
  String get apiErrorSearchRelaunchLimitReached;

  /// No description provided for @apiErrorEmergencyContactNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Aucun numéro d\'urgence n\'est disponible pour le moment.'**
  String get apiErrorEmergencyContactNotConfigured;

  /// No description provided for @driverDeliveryCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code de remise'**
  String get driverDeliveryCodeLabel;

  /// No description provided for @driverDeliveryCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'4 chiffres'**
  String get driverDeliveryCodeHint;

  /// No description provided for @driverDeliveryCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Demandez le code au destinataire : il s\'affiche sur l\'écran de suivi du client. Trois erreurs annulent le code et préviennent le support.'**
  String get driverDeliveryCodeHelp;

  /// No description provided for @driverDeliveryCodeMalformed.
  ///
  /// In fr, this message translates to:
  /// **'Le code comporte exactement 4 chiffres.'**
  String get driverDeliveryCodeMalformed;

  /// No description provided for @driverCodeUnavailableAction.
  ///
  /// In fr, this message translates to:
  /// **'Le destinataire n\'a pas le code'**
  String get driverCodeUnavailableAction;

  /// No description provided for @driverCodeUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un code indisponible'**
  String get driverCodeUnavailableTitle;

  /// No description provided for @driverCodeUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Le support sera prévenu. La livraison ne peut pas être confirmée sans un code valide : demandez au client de relire son écran de suivi.'**
  String get driverCodeUnavailableBody;

  /// No description provided for @driverCodeUnavailableConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Prévenir le support'**
  String get driverCodeUnavailableConfirm;

  /// No description provided for @driverCodeUnavailableReported.
  ///
  /// In fr, this message translates to:
  /// **'Le support est prévenu. La livraison reste à confirmer avec un code valide.'**
  String get driverCodeUnavailableReported;

  /// No description provided for @driverCourseEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gain de la course'**
  String get driverCourseEarnings;

  /// No description provided for @driverCourseEarningsEstimated.
  ///
  /// In fr, this message translates to:
  /// **'Estimation. Le montant crédité s\'affiche à votre portefeuille après le paiement du client.'**
  String get driverCourseEarningsEstimated;

  /// No description provided for @driverCourseEarningsCredited.
  ///
  /// In fr, this message translates to:
  /// **'Crédité à votre portefeuille.'**
  String get driverCourseEarningsCredited;

  /// No description provided for @driverCourseEarningsUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Montant fixé après le devis.'**
  String get driverCourseEarningsUnknown;

  /// No description provided for @driverCallClient.
  ///
  /// In fr, this message translates to:
  /// **'Appeler l\'expéditeur'**
  String get driverCallClient;

  /// No description provided for @driverOfferSearchUntil.
  ///
  /// In fr, this message translates to:
  /// **'Recherche jusqu\'à {time}'**
  String driverOfferSearchUntil(Object time);

  /// No description provided for @driverOfferSearchEnded.
  ///
  /// In fr, this message translates to:
  /// **'Recherche terminée'**
  String get driverOfferSearchEnded;

  /// No description provided for @driverCourseRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get driverCourseRefresh;

  /// No description provided for @driverReturnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retour du colis'**
  String get driverReturnTitle;

  /// No description provided for @driverReturnBody.
  ///
  /// In fr, this message translates to:
  /// **'Le client a annulé après la collecte : rapportez le colis au point de collecte, puis confirmez avec une photo.'**
  String get driverReturnBody;

  /// No description provided for @driverConfirmReturn.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le retour'**
  String get driverConfirmReturn;

  /// No description provided for @driverReturnProofTitle.
  ///
  /// In fr, this message translates to:
  /// **'Preuve de retour'**
  String get driverReturnProofTitle;

  /// No description provided for @driverEarningsWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get driverEarningsWeek;

  /// No description provided for @driverEarningsMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get driverEarningsMonth;

  /// No description provided for @driverEarningsTrips.
  ///
  /// In fr, this message translates to:
  /// **'{count} course(s)'**
  String driverEarningsTrips(Object count);

  /// No description provided for @driverEarningsSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get driverEarningsSummaryTitle;

  /// No description provided for @driverHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes courses passées'**
  String get driverHistoryTitle;

  /// No description provided for @driverHistorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Terminées, annulées ou en litige'**
  String get driverHistorySubtitle;

  /// No description provided for @driverHistoryFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get driverHistoryFilterAll;

  /// No description provided for @driverHistoryFilterCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get driverHistoryFilterCompleted;

  /// No description provided for @driverHistoryFilterCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get driverHistoryFilterCancelled;

  /// No description provided for @driverHistoryFilterDisputed.
  ///
  /// In fr, this message translates to:
  /// **'Litiges'**
  String get driverHistoryFilterDisputed;

  /// No description provided for @driverHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune course passée pour l\'instant. Vos courses terminées apparaîtront ici.'**
  String get driverHistoryEmpty;

  /// No description provided for @driverHistoryEmptyFiltered.
  ///
  /// In fr, this message translates to:
  /// **'Aucune course dans cette catégorie.'**
  String get driverHistoryEmptyFiltered;

  /// No description provided for @driverHistoryEarned.
  ///
  /// In fr, this message translates to:
  /// **'Gain crédité'**
  String get driverHistoryEarned;

  /// No description provided for @driverHistoryNotCredited.
  ///
  /// In fr, this message translates to:
  /// **'Aucun gain crédité'**
  String get driverHistoryNotCredited;

  /// No description provided for @driverHistoryLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Historique indisponible'**
  String get driverHistoryLoadError;

  /// No description provided for @driverOfferPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos du colis'**
  String get driverOfferPhotos;

  /// No description provided for @ordersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes commandes'**
  String get ordersTitle;

  /// No description provided for @ordersFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get ordersFilterAll;

  /// No description provided for @ordersFilterOngoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get ordersFilterOngoing;

  /// No description provided for @ordersFilterFinished.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get ordersFilterFinished;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos commandes apparaîtront ici dès que vous en aurez passé une.'**
  String get ordersEmptyBody;

  /// No description provided for @ordersEmptyOngoing.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande en cours.'**
  String get ordersEmptyOngoing;

  /// No description provided for @ordersEmptyFinished.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande terminée.'**
  String get ordersEmptyFinished;

  /// No description provided for @ordersLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Charger la suite'**
  String get ordersLoadMore;

  /// No description provided for @ordersLoadErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique indisponible'**
  String get ordersLoadErrorTitle;

  /// No description provided for @orderOptionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule et options'**
  String get orderOptionsTitle;

  /// No description provided for @orderOptionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le prix dépend du véhicule : choisissez-le pour voir le total avant de commander.'**
  String get orderOptionsSubtitle;

  /// No description provided for @orderHousingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de logement'**
  String get orderHousingLabel;

  /// No description provided for @orderHandlingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Manutention'**
  String get orderHandlingLabel;

  /// No description provided for @orderFloorsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étages'**
  String get orderFloorsLabel;

  /// No description provided for @orderFloorsHint.
  ///
  /// In fr, this message translates to:
  /// **'0 = rez-de-chaussée. Les étages ne comptent dans le prix que si vous demandez la manutention, mais le chauffeur en a toujours besoin.'**
  String get orderFloorsHint;

  /// No description provided for @orderFloorPickup.
  ///
  /// In fr, this message translates to:
  /// **'Au départ'**
  String get orderFloorPickup;

  /// No description provided for @orderFloorDropoff.
  ///
  /// In fr, this message translates to:
  /// **'À l\'arrivée'**
  String get orderFloorDropoff;

  /// No description provided for @floorValue.
  ///
  /// In fr, this message translates to:
  /// **'{floor, plural, =0{Rez-de-chaussée} =1{1er étage} other{{floor}e étage}}'**
  String floorValue(int floor);

  /// No description provided for @orderFloorDown.
  ///
  /// In fr, this message translates to:
  /// **'Un étage de moins'**
  String get orderFloorDown;

  /// No description provided for @orderFloorUp.
  ///
  /// In fr, this message translates to:
  /// **'Un étage de plus'**
  String get orderFloorUp;

  /// No description provided for @orderFloorsSummary.
  ///
  /// In fr, this message translates to:
  /// **'Départ : {pickup} · Arrivée : {dropoff}'**
  String orderFloorsSummary(Object pickup, Object dropoff);

  /// No description provided for @orderVehicleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get orderVehicleLabel;

  /// No description provided for @orderVehicleCapacity.
  ///
  /// In fr, this message translates to:
  /// **'jusqu\'à {weight} kg'**
  String orderVehicleCapacity(Object weight);

  /// No description provided for @orderVehicleNoLimit.
  ///
  /// In fr, this message translates to:
  /// **'Sans limite de poids'**
  String get orderVehicleNoLimit;

  /// No description provided for @orderVehiclePickHousingFirst.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d\'abord un type de logement.'**
  String get orderVehiclePickHousingFirst;

  /// No description provided for @orderVehicleNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun véhicule disponible pour ce choix.'**
  String get orderVehicleNone;

  /// No description provided for @orderQuoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prix estimé'**
  String get orderQuoteTitle;

  /// No description provided for @orderQuoteDistance.
  ///
  /// In fr, this message translates to:
  /// **'Distance retenue : {km} km'**
  String orderQuoteDistance(Object km);

  /// No description provided for @orderQuoteRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Calculer le prix'**
  String get orderQuoteRefresh;

  /// No description provided for @orderQuotePromoNote.
  ///
  /// In fr, this message translates to:
  /// **'Un code promo n\'est pas appliqué au devis : il est déduit à la commande. Le montant facturé peut donc être inférieur, jamais supérieur.'**
  String get orderQuotePromoNote;

  /// No description provided for @orderWeightTooHeavy.
  ///
  /// In fr, this message translates to:
  /// **'Au-delà de {weight} kg, c\'est un déménagement qu\'il faut commander, pas une livraison.'**
  String orderWeightTooHeavy(Object weight);

  /// No description provided for @catalogueErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue indisponible'**
  String get catalogueErrorTitle;

  /// No description provided for @orderOptionsContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get orderOptionsContinue;

  /// No description provided for @trackingDriverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre chauffeur'**
  String get trackingDriverTitle;

  /// No description provided for @trackingDriverRating.
  ///
  /// In fr, this message translates to:
  /// **'{average} ★ · {count} note(s)'**
  String trackingDriverRating(Object average, Object count);

  /// No description provided for @trackingDriverNoRating.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore noté'**
  String get trackingDriverNoRating;

  /// No description provided for @trackingCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get trackingCall;

  /// No description provided for @trackingEta.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée estimée dans environ {minutes} min'**
  String trackingEta(Object minutes);

  /// No description provided for @trackingRemainingKm.
  ///
  /// In fr, this message translates to:
  /// **'≈ {km} km restants, à vol d\'oiseau'**
  String trackingRemainingKm(Object km);

  /// No description provided for @trackingDeliveryCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de remise'**
  String get trackingDeliveryCodeTitle;

  /// No description provided for @trackingDeliveryCodeBody.
  ///
  /// In fr, this message translates to:
  /// **'Donnez ce code au chauffeur au moment de la remise, et à personne d\'autre. Après trois erreurs, un nouveau code s\'affiche ici.'**
  String get trackingDeliveryCodeBody;

  /// No description provided for @trackingProofsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Preuves'**
  String get trackingProofsTitle;

  /// No description provided for @trackingProofPickup.
  ///
  /// In fr, this message translates to:
  /// **'Collecte'**
  String get trackingProofPickup;

  /// No description provided for @trackingProofDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get trackingProofDelivery;

  /// No description provided for @trackingProofReceivedBy.
  ///
  /// In fr, this message translates to:
  /// **'Remis à {name}'**
  String trackingProofReceivedBy(Object name);

  /// No description provided for @trackingProofNoPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo non disponible'**
  String get trackingProofNoPhoto;

  /// No description provided for @trackingRateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Noter le chauffeur'**
  String get trackingRateTitle;

  /// No description provided for @trackingRateBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre note reste anonyme pour le chauffeur.'**
  String get trackingRateBody;

  /// No description provided for @trackingRateSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer ma note'**
  String get trackingRateSubmit;

  /// No description provided for @trackingRateCommentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (facultatif)'**
  String get trackingRateCommentLabel;

  /// No description provided for @trackingRateThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci, votre note est enregistrée.'**
  String get trackingRateThanks;

  /// No description provided for @trackingRateAverage.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle moyenne du chauffeur : {average} ★'**
  String trackingRateAverage(Object average);

  /// No description provided for @trackingRelaunch.
  ///
  /// In fr, this message translates to:
  /// **'Relancer la recherche'**
  String get trackingRelaunch;

  /// No description provided for @trackingRelaunchRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{count} relance(s) restante(s)'**
  String trackingRelaunchRemaining(Object count);

  /// No description provided for @trackingRelaunchPriceChanged.
  ///
  /// In fr, this message translates to:
  /// **'Le tarif a changé depuis votre commande : vérifiez le nouveau total avant de continuer.'**
  String get trackingRelaunchPriceChanged;

  /// No description provided for @trackingEmergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence'**
  String get trackingEmergency;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get homeGreetingEvening;

  /// No description provided for @homeHeroQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qu\'on transporte aujourd\'hui ?'**
  String get homeHeroQuestion;

  /// No description provided for @homeSearchPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Où livrer votre colis ?'**
  String get homeSearchPlaceholder;

  /// No description provided for @homeShortcutsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Livrer vers'**
  String get homeShortcutsTitle;

  /// No description provided for @homeShortcutAdd.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une adresse'**
  String get homeShortcutAdd;

  /// No description provided for @homeActiveOrdersSection.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get homeActiveOrdersSection;

  /// No description provided for @homeServiceInstant.
  ///
  /// In fr, this message translates to:
  /// **'Prix immédiat'**
  String get homeServiceInstant;

  /// No description provided for @homeServiceOnQuote.
  ///
  /// In fr, this message translates to:
  /// **'Sur devis'**
  String get homeServiceOnQuote;

  /// No description provided for @homeHowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche'**
  String get homeHowTitle;

  /// No description provided for @homeHowStepRoute.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le trajet'**
  String get homeHowStepRoute;

  /// No description provided for @homeHowStepPrice.
  ///
  /// In fr, this message translates to:
  /// **'Recevez votre prix'**
  String get homeHowStepPrice;

  /// No description provided for @homeHowStepTrack.
  ///
  /// In fr, this message translates to:
  /// **'Suivez chaque étape'**
  String get homeHowStepTrack;

  /// No description provided for @ordersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune commande} =1{1 commande} other{{count} commandes}}'**
  String ordersCount(int count);

  /// No description provided for @ordersGroupToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get ordersGroupToday;

  /// No description provided for @ordersGroupYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get ordersGroupYesterday;

  /// No description provided for @ordersEmptyCta.
  ///
  /// In fr, this message translates to:
  /// **'Passer une commande'**
  String get ordersEmptyCta;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get accountTitle;

  /// No description provided for @accountEditProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get accountEditProfile;

  /// No description provided for @accountStatOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get accountStatOrders;

  /// No description provided for @accountStatCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get accountStatCompleted;

  /// No description provided for @accountStatAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Adresses'**
  String get accountStatAddresses;

  /// No description provided for @accountSectionProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get accountSectionProfile;

  /// No description provided for @accountSectionPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get accountSectionPreferences;

  /// No description provided for @accountReferralHint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre code et suivez vos commissions'**
  String get accountReferralHint;

  /// No description provided for @accountSavedAddressesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune adresse enregistrée} =1{1 adresse} other{{count} adresses}}'**
  String accountSavedAddressesCount(int count);

  /// No description provided for @accountLanguageHint.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'app et des notifications'**
  String get accountLanguageHint;

  /// No description provided for @driverSwipeOnline.
  ///
  /// In fr, this message translates to:
  /// **'Glisser pour passer en ligne'**
  String get driverSwipeOnline;

  /// No description provided for @driverGoOffline.
  ///
  /// In fr, this message translates to:
  /// **'Passer hors ligne'**
  String get driverGoOffline;

  /// No description provided for @driverSwipeAccept.
  ///
  /// In fr, this message translates to:
  /// **'Glisser pour accepter'**
  String get driverSwipeAccept;

  /// No description provided for @driverPlateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plaque'**
  String get driverPlateLabel;

  /// No description provided for @driverRatingCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun avis} =1{1 avis} other{{count} avis}}'**
  String driverRatingCount(int count);

  /// No description provided for @driverProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get driverProfileTitle;

  /// No description provided for @driverSectionVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Mon véhicule'**
  String get driverSectionVehicle;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @onboardingEyebrow1.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue chez Camelia'**
  String get onboardingEyebrow1;

  /// No description provided for @onboardingTitle1.
  ///
  /// In fr, this message translates to:
  /// **'Tout ce qui se transporte, au même endroit'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In fr, this message translates to:
  /// **'Colis en ville, déménagement, expédition ou stockage : choisissez le service, on s\'occupe du trajet.'**
  String get onboardingBody1;

  /// No description provided for @onboardingEyebrow2.
  ///
  /// In fr, this message translates to:
  /// **'Votre trajet'**
  String get onboardingEyebrow2;

  /// No description provided for @onboardingTitle2.
  ///
  /// In fr, this message translates to:
  /// **'Deux adresses, et c\'est parti'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez l\'enlèvement et la livraison. Pour un colis ou un déménagement, le prix s\'affiche avant de commander.'**
  String get onboardingBody2;

  /// No description provided for @onboardingPickupChip.
  ///
  /// In fr, this message translates to:
  /// **'Enlèvement'**
  String get onboardingPickupChip;

  /// No description provided for @onboardingDropoffChip.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get onboardingDropoffChip;

  /// No description provided for @onboardingInstantChip.
  ///
  /// In fr, this message translates to:
  /// **'Prix immédiat'**
  String get onboardingInstantChip;

  /// No description provided for @onboardingEyebrow3.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get onboardingEyebrow3;

  /// No description provided for @onboardingTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Chaque étape, sans avoir à demander'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In fr, this message translates to:
  /// **'Une notification à chaque changement : chauffeur assigné, colis collecté, en route, livré.'**
  String get onboardingBody3;

  /// No description provided for @onboardingEyebrow4.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeurs'**
  String get onboardingEyebrow4;

  /// No description provided for @onboardingTitle4.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez un véhicule ? Roulez avec Camelia'**
  String get onboardingTitle4;

  /// No description provided for @onboardingBody4.
  ///
  /// In fr, this message translates to:
  /// **'Inscrivez-vous comme chauffeur. Une fois votre compte validé par Camelia, les courses arrivent directement dans l\'app.'**
  String get onboardingBody4;

  /// No description provided for @onboardingVerifiedChip.
  ///
  /// In fr, this message translates to:
  /// **'Compte validé'**
  String get onboardingVerifiedChip;

  /// No description provided for @authWelcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour'**
  String get authWelcomeBack;

  /// No description provided for @authHeroTagline.
  ///
  /// In fr, this message translates to:
  /// **'Livraison, déménagement, expédition et stockage au Cameroun.'**
  String get authHeroTagline;

  /// No description provided for @authOrDivider.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get authOrDivider;

  /// No description provided for @authShowPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get authHidePassword;

  /// No description provided for @authStepAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get authStepAccount;

  /// No description provided for @authStepVerify.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get authStepVerify;

  /// No description provided for @authStepReady.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti'**
  String get authStepReady;

  /// No description provided for @onboardingProgress.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String onboardingProgress(int current, int total);

  /// No description provided for @apiErrorPayerPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le numéro Mobile Money à débiter.'**
  String get apiErrorPayerPhoneRequired;

  /// No description provided for @apiErrorPayerPhoneUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro n\'est pas un compte Mobile Money pris en charge. Essayez un numéro MTN ou Orange.'**
  String get apiErrorPayerPhoneUnsupported;

  /// No description provided for @apiErrorPaymentAlreadyPending.
  ///
  /// In fr, this message translates to:
  /// **'Une demande de paiement attend déjà votre validation sur votre téléphone.'**
  String get apiErrorPaymentAlreadyPending;

  /// No description provided for @apiErrorPaymentProviderUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le service de paiement est momentanément indisponible. Réessayez dans quelques instants.'**
  String get apiErrorPaymentProviderUnavailable;

  /// No description provided for @trackingPayPromptSentBody.
  ///
  /// In fr, this message translates to:
  /// **'Une demande de paiement a été envoyée au {phone}. Validez-la sur votre téléphone avec votre code secret Mobile Money, puis actualisez.'**
  String trackingPayPromptSentBody(Object phone);

  /// No description provided for @trackingPaySendAgain.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer la demande'**
  String get trackingPaySendAgain;

  /// No description provided for @payerSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Numéro Mobile Money'**
  String get payerSheetTitle;

  /// No description provided for @payerSheetBody.
  ///
  /// In fr, this message translates to:
  /// **'La demande de paiement sera envoyée sur ce numéro. L\'opérateur est reconnu automatiquement.'**
  String get payerSheetBody;

  /// No description provided for @payerSheetPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro à débiter'**
  String get payerSheetPhoneLabel;

  /// No description provided for @payerSheetSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande de paiement'**
  String get payerSheetSend;

  /// No description provided for @trackingCancelFeePromptSent.
  ///
  /// In fr, this message translates to:
  /// **'Une demande de paiement des frais a été envoyée sur votre téléphone. Validez-la avec votre code secret Mobile Money.'**
  String get trackingCancelFeePromptSent;

  /// No description provided for @trackingCancelFeePromptFailed.
  ///
  /// In fr, this message translates to:
  /// **'La commande est bien annulée, mais la demande de paiement des frais n\'a pas pu être envoyée pour le moment.'**
  String get trackingCancelFeePromptFailed;

  /// No description provided for @walletWithdrawFeeNotice.
  ///
  /// In fr, this message translates to:
  /// **'L\'opérateur de paiement prélève sa commission sur le montant envoyé : vous recevrez un peu moins que le montant demandé.'**
  String get walletWithdrawFeeNotice;
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
