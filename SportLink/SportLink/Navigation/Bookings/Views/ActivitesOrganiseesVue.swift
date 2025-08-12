//
//  ActivitesOrganiseesVue.swift
//  SportLink
//
//  Created by Michel Lamothe on 2025-07-09.
//

import SwiftUI

struct ActivitesOrganiseesVue: View {
    @EnvironmentObject var activitesVM: ActivitesVM
    @StateObject private var vm: ActivitesOrganiseesVM
    @EnvironmentObject var appVM: AppVM
    @State private var activiteAffichantInfo: Activite.ID? = nil
    @State private var activiteSelectionnee: Activite? = nil
    
    init(serviceEmplacements: DonneesEmplacementService) {
        self._vm = StateObject(wrappedValue: ActivitesOrganiseesVM(
            serviceActivites: ServiceActivites(),
            serviceEmplacements: serviceEmplacements
        ))
    }

    var body: some View {
        ScrollView { sectionActivites }
            .task { await vm.fetchActivitesParOrganisateur() }
            .refreshable { await vm.fetchActivitesParOrganisateur() }
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
                        .environmentObject(appVM)
                        .cacherBoutonEditable(false)
                        .cacherBoutonJoin()
                }
            }
    }
    
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
                        let texte = "you have not planned any \n activities yet"
                        MessageAucuneActivite(texte: texte, symbole: "calendar.badge.plus")
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
    ActivitesOrganiseesVue(serviceEmplacements: DonneesEmplacementService())
        .environmentObject(DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
}
