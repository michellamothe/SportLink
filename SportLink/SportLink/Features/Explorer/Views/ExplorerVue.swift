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
    
    var namespace: Namespace.ID
    @Binding var activiteSelectionnee: Activite?
    @Binding var animationEnCours: Bool
    @Binding var utilisateur: Utilisateur

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if modeAffichage == .liste {
                        ExplorerListeVue(
                            namespace: namespace,
                            activiteSelectionnee: $activiteSelectionnee,
                            animationEnCours: $animationEnCours,
                            utilisateur: $utilisateur,
                            serviceEmplacements: serviceEmplacements
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.move(edge: .leading))
                        .environmentObject(serviceEmplacements)
                        .environmentObject(activitesVM)
                      
                    } else {
                        ExplorerCarteVue(utilisateur: $utilisateur)
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // <— plein écran
                            .transition(.move(edge: .trailing))
                            .environmentObject(serviceEmplacements)
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
}

// MARK: - Preview
struct ExplorerVue_Previews: PreviewProvider {
    @Namespace static var namespace
    
    static var previews: some View {
        let mockActivite = Activite(
            titre: "Soccer for amateurs",
            organisateurId: UtilisateurID(valeur: "demo"),
            infraId: "081-0090",
            sport: .soccer,
            date: DateInterval(start: .now, duration: 3600),
            nbJoueursRecherches: 4,
            participants: [],
            description: "Venez vous amuser !",
            statut: .ouvert,
            invitationsOuvertes: true,
            messages: []
        )
        
        let mockUtilisateur = Utilisateur(
            nomUtilisateur: "mathias13",
            courriel: "",
            photoProfil: "",
            disponibilites: [:],
            sportsFavoris: [],
            activitesFavoris: [],
            partenairesRecents: []
        )
        
        ExplorerVue(
            namespace: namespace,
            activiteSelectionnee: .constant(mockActivite),
            animationEnCours: .constant(false),
            utilisateur: .constant(mockUtilisateur)
        )
        .environmentObject(DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService()))
    }
}

