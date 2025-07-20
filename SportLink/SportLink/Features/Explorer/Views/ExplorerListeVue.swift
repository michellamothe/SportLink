//
//  ExplorerListeVue.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-20.
//

import SwiftUI

struct ExplorerListeVue: View {
    @EnvironmentObject var activitesVM: ActivitesVM
    @EnvironmentObject var activitesOrganiseesVM: ActivitesOrganiseesVM
    
    @StateObject private var vm: ExplorerListeVM
    
    @FocusState private var estEnTrainDeChercher: Bool
    
    @State private var afficherFiltreOverlay = false
    @State private var activiteAffichantMessageImage: Activite.ID? = nil
    
    var namespace: Namespace.ID
    @Binding var activiteSelectionnee: Activite?
    @Binding var animationEnCours: Bool
    @Binding var utilisateur: Utilisateur
    
    init(
        namespace: Namespace.ID,
        activiteSelectionnee: Binding<Activite?>,
        animationEnCours: Binding<Bool>,
        utilisateur: Binding<Utilisateur>,
        serviceEmplacements: DonneesEmplacementService
    ) {
        self.namespace = namespace
        self._activiteSelectionnee = activiteSelectionnee
        self._animationEnCours = animationEnCours
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
            
            contenuPrincipal
        }
        .environmentObject(vm)
    }
    
    // MARK: - Vues extraites
    @ViewBuilder
    private var contenuPrincipal: some View {
        VStack {
            sectionFiltreEtTri
            
            if afficherFiltreOverlay {
                overlayFiltrage
            }
            
            contenuActivites
        }
        .onTapGesture {
            gererTapGlobal()
        }
    }
    
    @ViewBuilder
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
        .padding([.leading, .trailing, .top], 20)
        .padding(.bottom, afficherFiltreOverlay ? 10 : 20)
    }
    
    @ViewBuilder
    private var overlayFiltrage: some View {
        BoiteFiltrage()
            .padding(.horizontal, 20)
            .transition(.scale(scale: 1, anchor: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var contenuActivites: some View {
        VStack(spacing: 8) {
            enTeteDate
            
            ScrollView { sectionActivites }
                .animation(.easeInOut, value: afficherFiltreOverlay)
                .task { await vm.chargerActivites() }
                .refreshable { await vm.chargerActivites() }
        }
    }
    
    @ViewBuilder
    private var enTeteDate: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vm.dateAAffichee(vm.dateAFiltree))
                .font(.title3)
                .foregroundStyle(Color(.black).opacity(0.8))
            Divider()
                .background(Color(.black).opacity(0.8))
        }
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var sectionActivites: some View {
        Group {
            if vm.estEnChargement {
                vueChargement
            } else if !vm.activitesTriees.isEmpty {
                listeActivites
            } else {
                vueAucuneActivite
            }
        }
    }
    
    @ViewBuilder
    private var vueChargement: some View {
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
    }
    
    @ViewBuilder
    private var listeActivites: some View {
        LazyVStack(spacing: 20) {
            ForEach(vm.activitesTriees, id: \.id) { activite in
                TestCardItem(
                    namespace: namespace,
                    activite: activite,
                    activiteSelectionnee: $activiteSelectionnee,
                    animationEnCours: $animationEnCours,
                    afficherMessageImage: bindingMessageImage(pour: activite)
                )
                .cacherBoutonJoin(false)
                .environmentObject(activitesOrganiseesVM)
                .environmentObject(activitesVM)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 130)
    }
    
    @ViewBuilder
    private var vueAucuneActivite: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                MessageAucuneActivite()
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(minHeight: 550)
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
        
        if afficherFiltreOverlay {
            afficherFiltreOverlay = false
        }
        
        estEnTrainDeChercher = false
    }
}

// MARK: - Preview
struct ExplorerListeVue_Previews: PreviewProvider {
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
        
        ExplorerListeVue(
            namespace: namespace,
            activiteSelectionnee: .constant(mockActivite),
            animationEnCours: .constant(false),
            utilisateur: .constant(mockUtilisateur),
            serviceEmplacements: DonneesEmplacementService()
        )
        .environmentObject(DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService()))
        .environmentObject(ActivitesOrganiseesVM(serviceActivites: ServiceActivites(), serviceEmplacements: DonneesEmplacementService()))
    }
}
