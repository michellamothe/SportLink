//
//  GoingVue.swift
//  SportLink
//
//  Created by Michel Lamothe on 2025-07-08.
//

import SwiftUI

struct ActivitesInscritesVue: View {
    @EnvironmentObject var activitesVM: ActivitesVM
    @StateObject private var vm: ActivitesInscritesVM
    @State private var activiteAffichantInfo: Activite.ID? = nil
    
    init(serviceEmplacements: DonneesEmplacementService) {
        self._vm = StateObject(wrappedValue: ActivitesInscritesVM(
            serviceActivites: ServiceActivites(),
            serviceEmplacements: serviceEmplacements
        ))
    }
    
    var body: some View {
        ScrollView { sectionActivites }
            .task {
                if vm.activites.isEmpty {
                    await vm.fetchActivitesInscrites()
                }
            }
            .refreshable { await vm.fetchActivitesInscrites() }
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
                        let texte = "you are not attending any \n activities yet"
                        MessageAucuneActivite(texte: texte, symbole: "calendar.badge.checkmark")
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
    ActivitesInscritesVue(serviceEmplacements: DonneesEmplacementService())
        .environmentObject(DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
        .environmentObject(ActivitesInscritesVM(serviceActivites: ServiceActivites(), serviceEmplacements: DonneesEmplacementService()))
}
