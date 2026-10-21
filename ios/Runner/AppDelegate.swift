import UIKit
import Flutter
import FirebaseCore   
import FirebaseAuth   
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // Clé du SDK Google Maps (carte de l'écran A4, T2.9), lue depuis
    // `Info.plist`, qui la reçoit de `ios/Flutter/Secrets.xcconfig` — aucune
    // clé dans le code (règle n°10). Doit précéder `GeneratedPluginRegistrant`,
    // qui instancie le plugin de carte.
    //
    // Clé absente (fichier de secrets non recopié) : on n'appelle pas le SDK —
    // `provideAPIKey("")` le fait échouer bruyamment. La carte reste grise, le
    // reste de l'app fonctionne, et la sélection d'adresse se fait par
    // recherche ou géolocalisation.
    if let key = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
       !key.isEmpty,
       !key.hasPrefix("$(") {
      GMSServices.provideAPIKey(key)
    } else {
      NSLog("[Camelia] Cle Google Maps absente : la carte de l'ecran A4 restera grise.")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    if Auth.auth().canHandleNotification(userInfo) {
        completionHandler(.noData)
        return
    }
    
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}