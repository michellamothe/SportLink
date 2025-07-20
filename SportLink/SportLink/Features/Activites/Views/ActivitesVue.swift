//
//  VueActivites.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-15.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case organise = "Hosting"
    case participe = "Going"
    case favoris = "Bookmarked"
}

struct ActivitesVue: View {
    @EnvironmentObject var activitesVM: ActivitesVM
    @EnvironmentObject var activitesOrganiseesVM: ActivitesOrganiseesVM
    @EnvironmentObject var serviceEmplacements: DonneesEmplacementService
    
    @StateObject private var contexte = ContexteControleurTab()
    @Namespace var line
    
    var namespace: Namespace.ID
    @Binding var activiteSelectionnee: Activite?
    @Binding var animationEnCours: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                contenuPrincipal
            }
            .navigationTitle(activiteSelectionnee != nil ? "Details" : "Your dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(activiteSelectionnee == nil ? .hidden : .visible, for: .navigationBar)
            .background(Color(.systemGray6))
        }
    }
    
    // MARK: - Vues extraites
    @ViewBuilder
    private var contenuPrincipal: some View {
        VStack(spacing: 0) {
            barreOnglets
            contenuOnglets
        }
    }
    
    @ViewBuilder
    private var barreOnglets: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                boutonOnglet(pour: tab)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private func boutonOnglet(pour tab: Tab) -> some View {
        VStack {
            Button {
                withAnimation {
                    contexte.selectionnee = tab
                }
            } label: {
                Text(tab.rawValue)
                    .font(.headline)
                    .foregroundColor(contexte.selectionnee == tab ? .primary : .gray)
            }
            .frame(maxWidth: .infinity)
            
            indicateurOnglet(pour: tab)
        }
    }
    
    @ViewBuilder
    private func indicateurOnglet(pour tab: Tab) -> some View {
        ZStack {
            Rectangle()
                .fill(Color("CouleurParDefaut"))
                .frame(height: 1)
                .opacity(0)
            
            if contexte.selectionnee == tab {
                Rectangle()
                    .fill(Color("CouleurParDefaut"))
                    .frame(height: 1)
                    .matchedGeometryEffect(id: "tab", in: line)
            }
        }
    }
    
    @ViewBuilder
    private var contenuOnglets: some View {
        ZStack {
            if contexte.trigger == .organise {
                vueActivitesOrganisees
            }
            if contexte.trigger == .participe {
                vueActivitesInscrites
            }
            if contexte.trigger == .favoris {
                vueActivitesFavorites
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var vueActivitesOrganisees: some View {
        ActivitesOrganiseesVue(
            namespace: namespace,
            activiteSelectionnee: $activiteSelectionnee,
            animationEnCours: $animationEnCours
        )
        .environmentObject(activitesVM)
        .environmentObject(activitesOrganiseesVM)
        .transition(.asymmetric(
            insertion: contexte.aInserer,
            removal: contexte.aDegager
        ))
    }
    
    @ViewBuilder
    private var vueActivitesInscrites: some View {
        ActivitesInscritesVue()
            .transition(.asymmetric(
                insertion: contexte.aInserer,
                removal: contexte.aDegager
            ))
    }
    
    @ViewBuilder
    private var vueActivitesFavorites: some View {
        ActivitesFavoritesVue()
            .transition(.asymmetric(
                insertion: contexte.aInserer,
                removal: contexte.aDegager
            ))
    }
}

final class ContexteControleurTab: ObservableObject {
    @Published var selectionnee: Tab = .organise {
        didSet {
            guard selectionnee != antecedent else { return }
            // decide insertion/removal based on rawValue
            aInserer = selectionnee.rawValue > antecedent.rawValue
                ? .move(edge: .leading)
                : .move(edge: .trailing)
            aDegager = selectionnee.rawValue > antecedent.rawValue
                ? .move(edge: .trailing)
                : .move(edge: .leading)
            
            // animate trigger change
            withAnimation {
                trigger = selectionnee
                antecedent = selectionnee
            }
        }
    }
    
    @Published var trigger: Tab = .organise
    private(set) var antecedent: Tab = .organise
    
    var aInserer: AnyTransition = .move(edge: .leading)
    var aDegager: AnyTransition = .move(edge: .trailing)
}

struct ActivitesVue_Previews: PreviewProvider {
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
        
        ActivitesVue(
            namespace: namespace,
            activiteSelectionnee: .constant(mockActivite),
            animationEnCours: .constant(false)
        )
        .environmentObject(DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService()))
        .environmentObject(ContexteControleurTab())
    }
}
