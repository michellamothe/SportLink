//
//  BookmarkedVue.swift
//  SportLink
//
//  Created by Michel Lamothe on 2025-07-08.
//


import SwiftUI

struct ActivitesFavoritesVue: View {
    @EnvironmentObject var activitesVM: ActivitesVM
    @StateObject private var vm: ActivitesFavoritesVM
    @State private var activiteAffichantInfo: Activite.ID? = nil
    
    init(serviceEmplacements: DonneesEmplacementService, utilisateurConnecteVM: UtilisateurConnecteVM) {
        self._vm = StateObject(wrappedValue: ActivitesFavoritesVM(
            serviceActivites: ServiceActivites(),
            serviceEmplacements: serviceEmplacements,
            serviceUtilisateurConnecte: utilisateurConnecteVM
        ))
    }
    
    var body: some View {
        ScrollView { sectionActivites }
            .task {
                if vm.activites.isEmpty {
                    await vm.fetchActivitesFavorites()
                }
            }
            .refreshable { await vm.fetchActivitesFavorites() }
            .onTapGesture {
                if activiteAffichantInfo != nil {
                    withAnimation { activiteAffichantInfo = nil }
                }
            }
            .navigationDestination(for: Activite.self) { activite in
                if let binding = vm.bindingActivite(id: activite.id!) {
                    DetailsActivite(activite: binding)
                        .environmentObject(activitesVM)
                        .environmentObject(vm)
                        .cacherBoutonEditable()
                        .cacherBoutonJoin()
                }
            }
    }
    
    @ViewBuilder
    var sectionActivites: some View {
        Group {
            if vm.estEnChargement {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(minHeight: 650)
            } else if !vm.activites.isEmpty {
                LazyVStack(spacing: 20) {
                    ForEach(vm.activites) { activite in
                        RangeeActivite(
                            afficherInfo: Binding(
                                get: { activiteAffichantInfo == activite.id },
                                set: { newValue in
                                    activiteAffichantInfo = newValue ? activite.id : nil
                                }
                            ),
                            activite: activite
                        )
                        .cacherBoutonJoin()
                        .dateEtendue()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 70) // faire de la place par rapport a le tabbar
                .padding(.top, 20) // faire de la place par rapport a l'onglet
            } else {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        let texte = "you have no activites \n bookmarked yet"
                        MessageAucuneActivite(texte: texte, symbole: "bookmark.slash")
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(minHeight: 650)
            }
        }
    }
}

#Preview {
    ActivitesFavoritesVue(serviceEmplacements: DonneesEmplacementService(), utilisateurConnecteVM: UtilisateurConnecteVM())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
}

