import SwiftUI
import MapKit

enum Onglets: Int {
    case accueil, explorer, creer, activites, profil
}

struct VuePrincipale: View {
    @EnvironmentObject var serviceEmplacements: DonneesEmplacementService
    @StateObject private var activitesVM: ActivitesVM
    @StateObject private var activitesOrganiseesVM: ActivitesOrganiseesVM
    @State private var ongletSelectionne: Onglets = .accueil
    @State private var estPresente = false
    @State private var afficherTabBar = true
    
    @Namespace var namespace
    @State private var activiteSelectionnee: Activite? = nil
    @State private var animationEnCours = false
    
    init(serviceEmplacements: DonneesEmplacementService) {
        self._activitesVM = StateObject(wrappedValue: ActivitesVM(serviceEmplacements: serviceEmplacements))
        self._activitesOrganiseesVM = StateObject(wrappedValue: ActivitesOrganiseesVM(serviceActivites: ServiceActivites(), serviceEmplacements: serviceEmplacements))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Group {
                    switch ongletSelectionne {
                    case .accueil:
                        AccueilVue()
                    case .explorer:
                        ExplorerVue(
                            namespace: namespace,
                            activiteSelectionnee: $activiteSelectionnee,
                            animationEnCours: $animationEnCours,
                            utilisateur: .constant(mockUtilisateur)
                        )
                        .environmentObject(serviceEmplacements)
                        .environmentObject(activitesVM)
                        .environmentObject(activitesOrganiseesVM)
                    case .creer:
                        Color.clear // ne sera jamais directement visible
                    case .activites:
                        ActivitesVue(
                            namespace: namespace,
                            activiteSelectionnee: $activiteSelectionnee,
                            animationEnCours: $animationEnCours,
                        )
                        .environmentObject(serviceEmplacements)
                        .environmentObject(activitesVM)
                        .environmentObject(activitesOrganiseesVM)
                    case .profil:
                        ProfilVue()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                TabBarPersonnalisee(
                    ongletSelectionnee: $ongletSelectionne,
                    estPresente: $estPresente
                )
                
                if let activite = activiteSelectionnee {
                    TestCardView(
                        namespace: namespace,
                        activite: activite,
                        activiteSelectionnee: $activiteSelectionnee,
                        animationEnCours: $animationEnCours
                    )
                    .environmentObject(activitesOrganiseesVM)
                    .environmentObject(activitesVM)
                    .zIndex(1)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .fullScreenCover(isPresented: $estPresente) {
                CreerActiviteVue(serviceEmplacements: serviceEmplacements)
                    .environmentObject(serviceEmplacements)
            }
        }
    }

    private var mockUtilisateur: Utilisateur {
        Utilisateur(
            nomUtilisateur: "mathias13",
            courriel: "",
            photoProfil: "",
            disponibilites: [:],
            sportsFavoris: [],
            activitesFavoris: [],
            partenairesRecents: []
        )
    }
}


#Preview {
    VuePrincipale(serviceEmplacements: DonneesEmplacementService())
        .environmentObject(DonneesEmplacementService())
}
