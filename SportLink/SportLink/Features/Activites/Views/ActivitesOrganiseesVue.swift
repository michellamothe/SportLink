//
//  TestParentView.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-18.
//

import SwiftUI

struct ActivitesOrganiseesVue: View {
    @EnvironmentObject var activitesVM: ActivitesVM
    @EnvironmentObject var activitesOrganiseesVM: ActivitesOrganiseesVM
    
    @StateObject private var contexte = ContexteControleurTab()
    @State private var activiteAffichantMessageImage: Activite.ID? = nil
    
    // Tracking de l'état des animations
    @State private var animationTimer: Timer?
    @State private var dernierActiviteSelectionnee: Activite.ID?
    
    var namespace: Namespace.ID
    @Binding var activiteSelectionnee: Activite?
    @Binding var animationEnCours: Bool
    
    var body: some View {
        contenuPrincipal
            .task {
                await activitesOrganiseesVM.chargerActivitesParOrganisateur(organisateurId: "mockID")
            }
            .refreshable {
                await activitesOrganiseesVM.chargerActivitesParOrganisateur(organisateurId: "mockID")
            }
            .onTapGesture {
                gererTapGlobal()
            }
            .onChange(of: activiteSelectionnee) { oldValue, newValue in
                gererChangementActivite(ancienne: oldValue, nouvelle: newValue)
            }
    }
    
    // MARK: - Vues extraites
    @ViewBuilder
    private var contenuPrincipal: some View {
        activitesScroll
    }
    
    @ViewBuilder
    private var activitesScroll: some View {
        ScrollView {
            listeActivites
                .allowsHitTesting(!animationEnCours)
        }
    }
    
    @ViewBuilder
    private var listeActivites: some View {
        LazyVStack(spacing: 0) {
            ForEach(activitesOrganiseesVM.activites, id: \.id) { activite in
                carteActivite(pour: activite)
                    .padding(.top, 20)
            }
        }
    }
    
    @ViewBuilder
    private func carteActivite(pour activite: Activite) -> some View {
        TestCardItem(
            namespace: namespace,
            activite: activite,
            activiteSelectionnee: $activiteSelectionnee,
            animationEnCours: $animationEnCours,
            afficherMessageImage: bindingMessageImage(pour: activite)
        )
        .cacherBoutonJoin()
        .environmentObject(activitesOrganiseesVM)
        .environmentObject(activitesVM)
    }
    
    // MARK: - Fonctions utilitaires
    private func bindingMessageImage(pour activite: Activite) -> Binding<Bool> {
        Binding(
            get: { activiteAffichantMessageImage == activite.id },
            set: { newValue in
                activiteAffichantMessageImage = newValue ? activite.id : nil
            }
        )
    }
    
    private func gererTapGlobal() {
        if activiteAffichantMessageImage != nil {
            withAnimation {
                activiteAffichantMessageImage = nil
            }
        }
    }
    
    private func gererChangementActivite(ancienne: Activite?, nouvelle: Activite?) {
        // Nettoyer le timer existant
        nettoyerTimer()
        
        // Vérifier si l'activité a réellement changé
        guard ancienne?.id != nouvelle?.id else { return }
        
        // Démarrer la nouvelle animation
        demarrerAnimationChangement(nouvelle: nouvelle)
    }
    
    private func nettoyerTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func demarrerAnimationChangement(nouvelle: Activite?) {
        animationEnCours = true
        dernierActiviteSelectionnee = nouvelle?.id
        
        // Timer ajusté pour correspondre aux autres (fermerActiviteDetails() et ouvrirActiviteDetails())
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
            DispatchQueue.main.async {
                terminerAnimation()
            }
        }
    }
    
    private func terminerAnimation() {
        animationEnCours = false
        nettoyerTimer()
    }
}

// MARK: - Preview
struct ActivitesOrganiseesVue_Previews: PreviewProvider {
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
        
        ActivitesOrganiseesVue(
            namespace: namespace,
            activiteSelectionnee: .constant(mockActivite),
            animationEnCours: .constant(false)
        )
        .environmentObject(DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService()))
        .environmentObject(ActivitesOrganiseesVM(serviceActivites: ServiceActivites(), serviceEmplacements: DonneesEmplacementService()))
    }
}
