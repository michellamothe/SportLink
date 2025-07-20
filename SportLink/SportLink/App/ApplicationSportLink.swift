//
//  SportLinkApp.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-01.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
      FirebaseApp.configure()

      return true
    }
}

@main
struct ApplicationSportLink: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var emplacementsVM = DonneesEmplacementService()
    
    var body: some Scene {
        WindowGroup {
            /*TestParentView(serviceEmplacements: emplacementsVM)
                .onAppear {
                    emplacementsVM.chargerDonnees()
                }*/
            VuePrincipale(serviceEmplacements: emplacementsVM)
                .environmentObject(emplacementsVM)
                .onAppear {
                    emplacementsVM.chargerDonnees()
                }
        }
    }
}
