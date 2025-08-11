//
//  ExplorerListeVue.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-20.
//

import SwiftUI

struct ExplorerListeVue: View {
    @EnvironmentObject var activitesVM: ActivitesVM
    @EnvironmentObject var appVM: AppVM
    @StateObject private var vm: ExplorerListeVM
    @FocusState private var estEnTrainDeChercher: Bool
    @State private var afficherFiltreOverlay = false
    @State private var activiteAffichantInfo: Activite.ID? = nil
    
    @Binding var utilisateur: Utilisateur
    
    init(
        utilisateur: Binding<Utilisateur>,
        serviceEmplacements: DonneesEmplacementService
    ) {
        self._utilisateur = utilisateur
        self._vm = StateObject(wrappedValue: ExplorerListeVM(
            serviceEmplacements: serviceEmplacements,
            serviceActivites: ServiceActivites()
        ))
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack {
                sectionFiltreEtTri
                    .padding(.top) // Not to close to Dynamic Island
                
                if afficherFiltreOverlay {
                    BoiteFiltrage()
                        .padding(.horizontal, 20)
                        .transition(.scale(scale: 1, anchor: .top).combined(with: .opacity))
                }
                
                VStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activitesVM.dateAAffichee(vm.dateAFiltree))
                            .font(.title3)
                            .foregroundStyle(Color(.black).opacity(0.8))
                        Divider()
                            .background(Color(.black).opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .contentShape(Rectangle())
                    
                    ScrollView { sectionActivites }
                        .animation(.easeInOut, value: afficherFiltreOverlay)
                        .task { await vm.chargerActivites() }
                        .refreshable { await vm.chargerActivites() }
                        .navigationDestination(for: Activite.self) { activite in
                            DetailsActivite(activite: .constant(activite))
                                .environmentObject(activitesVM) // navigationDestination brise la chaine des environemments donc on doit le redonner
                                .environmentObject(appVM)
                                .cacherBoutonEditable()
                        }
                }
                .onTapGesture {
                    if activiteAffichantInfo != nil {
                        withAnimation { activiteAffichantInfo = nil }
                    }
                    
                    if afficherFiltreOverlay { afficherFiltreOverlay = false }
                    
                    estEnTrainDeChercher = false
                }
            }
        }
        .environmentObject(vm)
    }
    
    private var sectionFiltreEtTri: some View {
        HStack(spacing: 8) {
            BarreDeRecherche(
                texteDeRecherche: $vm.texteDeRecherche,
                afficherFiltreOverlay: $afficherFiltreOverlay,
                dateAFiltree: $vm.dateAFiltree
            )
            .focused($estEnTrainDeChercher)
            
            BoutonTriage(optionTri: $vm.optionTri)
        }
        .padding([.leading, .trailing], 20)
        .padding(.bottom, afficherFiltreOverlay ? 10 : 20)
    }
    
    private var sectionActivites: some View {
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
                .frame(minHeight: 550)
            } else if !vm.activitesTriees.isEmpty {
                LazyVStack(spacing: 20) {
                    ForEach(vm.activitesTriees, id: \.id) { activite in
                        RangeeActivite(
                            afficherInfo: Binding(
                                get: { activiteAffichantInfo == activite.id },
                                set: { newValue in
                                    activiteAffichantInfo = newValue ? activite.id : nil
                                }
                            ),
                            activite: activite
                        )
                        .cacherBoutonJoin(false)
                        .dateEtendue(false)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 130) // faire de la place par rapport a le switch
            } else {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        let texte = "no activities are available for the selected settings"
                        MessageAucuneActivite(texte: texte)
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(minHeight: 550)
            }
        }
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
    
    ExplorerListeVue(
        utilisateur: .constant(mockUtilisateur),
        serviceEmplacements: DonneesEmplacementService()
    )
    .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
    .environmentObject(AppVM())
}
