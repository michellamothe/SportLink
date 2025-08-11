//
//  VueExplorer.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-15.
//

import SwiftUI

struct ExplorerVue: View {
    @EnvironmentObject var serviceEmplacements: DonneesEmplacementService
    @EnvironmentObject var activitesVM: ActivitesVM
    @State private var modeAffichage: ModeAffichage = .liste
    @Binding var utilisateur: Utilisateur

    var body: some View {
        ZStack {
            Group {
                if modeAffichage == .liste {
                    ExplorerListeVue(
                        utilisateur: $utilisateur,
                        serviceEmplacements: serviceEmplacements
                    )
                    .environmentObject(serviceEmplacements)
                    .environmentObject(activitesVM)
                    .transition(.move(edge: .leading))
                } else {
                    ExplorerCarteVue(utilisateur: $utilisateur)
                        .environmentObject(serviceEmplacements)
                        .transition(.move(edge: .trailing))
                }
            }
            
            VStack {
                Spacer()
                BoutonSwitchExplorer(modeAffichage: $modeAffichage)
                    .padding(.bottom, 70)
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut, value: modeAffichage)
    }
}

#Preview {
    let mockUtilisateur = Utilisateur(
        nomUtilisateur: "mathias13",
        courriel: "",
        photoProfil: "",
        disponibilites: [:],
        sportsFavoris: [],
        activitesFavoris: [],
        partenairesRecents: []
    )
    
    ExplorerVue(utilisateur: .constant(mockUtilisateur))
        .environmentObject(DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
}
