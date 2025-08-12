//
//  VueExplorer.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-15.
//

import SwiftUI

struct ExplorerVue: View {
    let serviceEmplacements: DonneesEmplacementService
    @State private var modeAffichage: ModeAffichage = .liste
    @Binding var utilisateur: Utilisateur
    
    init(utilisateur: Binding<Utilisateur>, serviceEmplacements: DonneesEmplacementService) {
        self._utilisateur = utilisateur
        self.serviceEmplacements = serviceEmplacements
    }

    var body: some View {
        ZStack {
            Group {
                if modeAffichage == .liste {
                    ExplorerListeVue(utilisateur: $utilisateur)
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
    
    ExplorerVue(utilisateur: .constant(mockUtilisateur), serviceEmplacements: DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
            .environmentObject(AppVM())
            .environmentObject(ExplorerListeVM(
                serviceEmplacements: DonneesEmplacementService(),
                serviceActivites: ServiceActivites()
            ))
}
