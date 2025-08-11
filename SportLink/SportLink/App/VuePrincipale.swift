import SwiftUI
import MapKit

enum Onglets: Int {
    case accueil, explorer, creer, activites, profil
}

struct VuePrincipale: View {
    @EnvironmentObject var serviceEmplacements: DonneesEmplacementService
    @EnvironmentObject var utilisateurConnecteVM: UtilisateurConnecteVM
    @StateObject private var appVM = AppVM()
    @StateObject private var session: Session
    @StateObject private var activitesVM: ActivitesVM
    @State private var estPresente = false
    @State private var afficherTabBar = true
    @State private var montrerPageAuthentification = false
    
    let onDeconnexion: () -> Void
    
    init(serviceEmplacements: DonneesEmplacementService, utilisateurConnecteVM: UtilisateurConnecteVM, onDeconnexion: @escaping () -> Void) {
        self._activitesVM = StateObject(wrappedValue: ActivitesVM(serviceEmplacements: serviceEmplacements, serviceUtilisateurConnecte: utilisateurConnecteVM))
        self._session = StateObject(wrappedValue: Session(serviceEmplacements: serviceEmplacements, utilisateurConnecteVM: utilisateurConnecteVM))
        self.onDeconnexion = onDeconnexion
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if session.estPret {
                    contenuPrincipal
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .fullScreenCover(isPresented: $estPresente) {
                CreerActiviteVue(serviceEmplacements: serviceEmplacements)
                    .environmentObject(serviceEmplacements)
                    .environmentObject(appVM)
            }
        }
    }
    
    @ViewBuilder
    private var contenuPrincipal: some View {
        Group {
            switch appVM.ongletSelectionne {
            case .accueil:
                AccueilVue()
                    .environmentObject(activitesVM)
                    .environmentObject(session)
            case .explorer:
                ExplorerVue(utilisateur: .constant(mockUtilisateur))
                    .environmentObject(serviceEmplacements)
                    .environmentObject(activitesVM)
                    .environmentObject(appVM)
            case .creer:
                Color.clear // ne sera jamais directement visible
            case .activites:
                ActivitesVue()
                    .environmentObject(serviceEmplacements)
                    .environmentObject(activitesVM)
                    .environmentObject(appVM)
            case .profil:
                ProfilVue(onDeconnexion: onDeconnexion)
                    .environmentObject(session)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        TabBarPersonnalisee(
            ongletSelectionnee: $appVM.ongletSelectionne,
            estPresente: $estPresente
        )
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
    VuePrincipale(serviceEmplacements: DonneesEmplacementService(), utilisateurConnecteVM: UtilisateurConnecteVM(), onDeconnexion: { print("Non déconnecté") })
        .environmentObject(DonneesEmplacementService())
        .environmentObject(UtilisateurConnecteVM())
}
