//
//  TestCardView.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-18.
//

import SwiftUI
import MapKit

struct TestCardView: View {
    @EnvironmentObject var vm: ActivitesOrganiseesVM
    @EnvironmentObject var activitesVM: ActivitesVM
    @StateObject var recherchePOI = RecherchePOIVM()
    
    var namespace: Namespace.ID
    var activite: Activite
    @Binding var activiteSelectionnee: Activite?
    @Binding var animationEnCours: Bool
    
    @State private var afficherNouveauContenu = false
    @State private var estFavoris = false
    @State private var timerFermeture: Timer?
    @State private var afficherConfirmationRoute = false
    @State private var itemRouteMap: MKMapItem?

    let couleur = Color(red: 0.784, green: 0.231, blue: 0.216)
    
    var body: some View {
        ZStack {
            ScrollView { construireContenu() }
                .task {
                    if vm.imageApercu == nil {
                        _ = await vm.genererApercu(infraId: activite.infraId)
                    }
                }
                .onChange(of: animationEnCours) { oldValue, newValue in
                    if !newValue && activiteSelectionnee != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(duration: 0.5)) {
                                afficherNouveauContenu = true
                            }
                        }
                    } else if !oldValue && activiteSelectionnee == nil {
                        DispatchQueue.main.async {
                            withAnimation(.spring(duration: 0.3)) {
                                afficherNouveauContenu = false
                            }
                        }
                    }
                }
                .onDisappear {
                    timerFermeture?.invalidate()
                    timerFermeture = nil
                }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    fermerActiviteDetails()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.black)
                }
                .disabled(animationEnCours)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // EDIT HERE
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.black)
                }
            }
        }
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0), radius: 2)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-mask", in: namespace)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    @ViewBuilder
    private func construireContenu() -> some View {
        VStack(alignment: .center, spacing: 0) {
            construireImageArrierePlan()
            construireSectionPrincipale()
        }
    }
    
    @ViewBuilder
    private func construireImageArrierePlan() -> some View {
        VStack(alignment: .trailing) {
            distanceAPartirUtilisateur
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 12)
            Spacer()
            iconeBookmark
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 40)
        }
        .padding(.trailing, 12)
        .frame(height: 200)
        .background(
            Sport.depuisNom(activite.sport).arriereplan
                .resizable()
                .aspectRatio(contentMode: .fill)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-arriereplan", in: namespace)
        )
        .mask(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-arriereplanMask", in: namespace)
        )
    }
    
    @ViewBuilder
    private func construireSectionPrincipale() -> some View {
        VStack {
            construireBulleTitre()
                
            if afficherNouveauContenu {
                VStack {
                    construireBulleCarte()
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    
    @ViewBuilder
    private func construireBulleTitre() -> some View {
        HStack {
            Image(systemName: Sport.depuisNom(activite.sport).icone)
                .resizable()
                .scaledToFit()
                .frame(width: 28)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-icone", in: namespace)
                .padding(.trailing, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(activite.titre)
                    .font(.title3.weight(.semibold))
                    .matchedGeometryEffect(id: "\(String(describing: activite.id))-titre", in: namespace)
                
                Text(nomDuParc)
                    .font(.callout.weight(.light))
                    .foregroundStyle(Color.black.opacity(0.8))
                    .matchedGeometryEffect(id: "\(String(describing: activite.id))-parc", in: namespace)
            }
        }
        .padding([.bottom, .top, .leading], 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-titreBack", in: namespace)
        )
        .offset(y: -30)
        .padding(.horizontal, 14)
    }
    
    @ViewBuilder
    private func construireBulleCarte() -> some View {
        VStack(spacing: 0) {
            construireAperçuCarte()
            construireSectionRoute()
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 5)
        )
    }
    
    @ViewBuilder
    private func construireAperçuCarte() -> some View {
        ZStack {
            if let image = vm.imageApercu {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down.left.and.arrow.up.right")
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                        .padding(.trailing, 10)
                        .padding(.top, 24)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 180)
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, topTrailing: 16)))
    }
    
    @ViewBuilder
    private func construireSectionRoute() -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.ultraThickMaterial)
                .clipShape(UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 16, bottomTrailing: 16)))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Getting there")
                        .font(.headline)
                        .foregroundStyle(.black)
                    Spacer()
                    // Bouton ouvrir route
                    BoutonOuvrirMaps(
                        afficherConfirmation: $afficherConfirmationRoute,
                        itemMap: $itemRouteMap,
                        texte: "route",
                        fetchItemMap: { completion in
                            recherchePOI.ouvrirRouteDansMaps(
                                coordonneesDestination: infra!.coordonnees,
                                nomSport: activite.sport,
                            ) { item in
                                completion(item)
                            }
                        },
                        optionsLancement: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                        ]
                    )
                }
                Text("123 Vrbo Blvd,\nBanff, AB T3M 5J3")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
    }
    
    var distanceAPartirUtilisateur: some View {
        HStack {
            Image(systemName: "mappin.and.ellipse")
            Text("\(activitesVM.obtenirDistanceDeUtilisateur(pour: activite)) away")
        }
        .font(.system(size: 14))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(couleur.opacity(0.9))
        )
    }
    
    var iconeBookmark: some View {
        Image(systemName: estFavoris ? "bookmark.fill" : "bookmark")
            .font(.system(size: 22))
            .foregroundStyle(estFavoris ? couleur : .white)
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            .onTapGesture {
                estFavoris.toggle()
            }
            .disabled(animationEnCours)
    }
    
    private var nomDuParc: String {
        let (_, parcOpt) = activitesVM.obtenirInfraEtParc(infraId: activite.infraId)
        guard let parc = parcOpt else { return "" }
        
        return parc.nom!
    }
    
    private var nbPlacesRestantes: String {
        let diff = activite.nbJoueursRecherches - activite.participants.count
        
        if diff == 0 { return "No spot left" }
        return String(format: "%d spots left", diff)
    }
    
    private var infra: Infrastructure? {
        let (infraOpt, _) = activitesVM.obtenirInfraEtParc(infraId: activite.infraId)
        guard let infra = infraOpt else { return nil }
        
        return infra
    }
    
    private func fermerActiviteDetails() {
        guard !animationEnCours else { return }
        
        timerFermeture?.invalidate()
        animationEnCours = true
        
        withAnimation(.easeInOut(duration: 0.6)) {
            activiteSelectionnee = nil
        }
        
        timerFermeture = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
            DispatchQueue.main.async {
                animationEnCours = false
                timerFermeture = nil
            }
        }
    }
}

struct TestCardView_Previews: PreviewProvider {
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
        
        TestCardView(
            namespace: namespace,
            activite: mockActivite,
            activiteSelectionnee: .constant(mockActivite),
            animationEnCours: .constant(false)
        )
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService()))
        .environmentObject(ActivitesOrganiseesVM(serviceActivites: ServiceActivites(), serviceEmplacements: DonneesEmplacementService()))
    }
}
