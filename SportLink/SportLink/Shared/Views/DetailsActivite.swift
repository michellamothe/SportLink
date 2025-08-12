//
//  SwiftUIView.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-20.
//

import SwiftUI
import MapKit

struct DetailsActivite: View {
    // MARK: Variables
    @EnvironmentObject var activitesVM: ActivitesVM
    @Environment(\.dismiss) var dismiss
    @StateObject private var serviceUtilisateurs = ServiceUtilisateurs()
    @State private var opaciteEnTete: CGFloat = 0
    @State private var montrerDialogueParametres = false
    @State private var montrerVueEdition = false
    @State private var estFavoris = false // Temporaire
    @State private var refreshID = UUID()
    @Binding var activite: Activite
    
    // MARK: Body
    var body: some View {
        ZStack {
            BarreDeNavigation(opaciteEnTete: $opaciteEnTete, titre: activite.sport.capitalized) {
                montrerDialogueParametres = true
            } fermerDetails: { dismiss() }
            
            ScrollView {
                EffetParallax(opaciteEnTete: $opaciteEnTete, sportDeActivite: Sport.depuisNom(activite.sport))
                Details(serviceUtilisateurs: serviceUtilisateurs, estFavoris: $estFavoris, activite: activite)
            }
            .id(refreshID)
            .ignoresSafeArea()
        }
        .task { _ = await activitesVM.genererApercu(infraId: activite.infraId) }
        .confirmationDialog("Settings", isPresented: $montrerDialogueParametres, titleVisibility: .hidden) {
            Button("Edit activity") { montrerVueEdition = true }
            Button("Delete activity", role: .destructive) { /* EffacerActivite() */ }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $montrerVueEdition) {
            ModifierVue(activite: $activite) {
                refreshID = UUID() 
            }
        }
        .onChange(of: activite) { _, _ in
            refreshID = UUID()
        }
        .onChange(of: estFavoris) { _, nvValeur in
            if nvValeur == false {
                dismiss()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

struct BarreDeNavigation: View {
    // MARK: Variables
    @EnvironmentObject var activitesVM: ActivitesVM
    @Environment(\.cacherBoutonEditable) private var cacherBoutonEditable
    @Binding var opaciteEnTete: CGFloat
    let titre: String
    let apresTaperParametres: () -> Void
    let fermerDetails: () -> Void
    
    // MARK: Body et viewbuilders
    var body: some View {
        VStack {
            HStack {
                boutonRetourArriere
                Spacer()
                Text(titre)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .opacity(opaciteEnTete)
                Spacer()
                if !cacherBoutonEditable {
                    boutonParametres
                } else { // Pour balancer le titre
                    HStack { EmptyView() }
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(
                Color.white
                    .overlay(Rectangle().stroke(Color(.systemGray2), lineWidth: 1))
                    .ignoresSafeArea(edges: .top)
                    .opacity(opaciteEnTete)
            )
            
            Spacer()
        }
        .zIndex(1)
    }
    
    @ViewBuilder
    private var boutonRetourArriere: some View {
        Button {
            fermerDetails()
            activitesVM.imageApercu = nil // Remettre l'image à nil pour éviter de la voir au chargement de la prochaine activité
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(width: 36, height: 36)
        .background(
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 4)
                .opacity(1 - opaciteEnTete)
        )
        .contentShape(Circle())
    }
    
    @ViewBuilder
    private var boutonParametres: some View {
        Button {
            apresTaperParametres()
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(width: 36, height: 36)
        .background(
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 4)
                .opacity(1 - opaciteEnTete)
        )
        .contentShape(Circle())
    }
}

extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}

struct EffetParallax: View {
    // MARK: Variables et propriétés calculées
    @Binding var opaciteEnTete: CGFloat
    let sportDeActivite: Sport
    
    // MARK: Body
    var body: some View {
        GeometryReader { geometrie in
            let decalageY = geometrie.frame(in: .global).minY
            let estDefile = decalageY > 0
            
            // Logique pour calculer l'opacité basée sur le scroll
            let seuil: CGFloat = 200 // Distance de scroll pour atteindre opacité maximale
            let opaciteCalculee = max(0, min(1, -decalageY / seuil))
            
            Spacer()
                .frame(height: estDefile ? 400 + decalageY : 400)
                .background(
                    Image(sportDeActivite.arriereplan)
                        .resizable()
                        .scaledToFill()
                        .offset(y: estDefile ? -decalageY : 0)
                )
                .onChange(of: decalageY) { _, _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        opaciteEnTete = opaciteCalculee
                    }
                }
        }
        .frame(height: 300)
    }
}

struct Details: View {
    // MARK: Variables et propriétés calculées
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var activitesVM: ActivitesVM
    @EnvironmentObject var activitesOrganiseesVM: ActivitesOrganiseesVM
    @EnvironmentObject var appVM: AppVM
    @StateObject private var serviceActivites = ServiceActivites()
    @Environment(\.cacherBoutonJoin) var cacherBoutonJoin
    @Environment(\.cacherBoutonEditable) var cacherBoutonEditable
    @StateObject private var recherchePOI = RecherchePOIVM()
    @ObservedObject var serviceUtilisateurs: ServiceUtilisateurs
    @State private var montrerDialogueAjouterCalendrier = false
    @State private var montrerConfirmationRoute = false
    @State private var itemRouteMap: MKMapItem?
    @State private var nomOrganisateur: String?
    @State private var photoOrganisateur: UIImage?
    @State private var montrerDialogueFavoris = false
    @State private var montrerDialogueSortir = false
    @Binding var estFavoris: Bool
    var activite: Activite
    let couleurDeFondDistance = Color(red: 0.784, green: 0.231, blue: 0.216)
    
    private var nomDuParc: String {
        let (_, parcOpt) = activitesVM.obtenirInfraEtParc(infraId: activite.infraId)
        guard let parc = parcOpt else { return "" }
        return parc.nom!
    }
    
    private var coordsInfrastructure: CLLocationCoordinate2D? {
        let (infraOpt, _) = activitesVM.obtenirInfraEtParc(infraId: activite.infraId)
        guard let infra = infraOpt else { return nil }
        
        return infra.coordonnees
    }
    
    private var composantesDate: (String, String) {
        let date = activitesVM.dateAAffichee(activite.date.debut)
        let (_, tempsDebut, tempsFin) = activite.date.affichage
        return (date, "\(tempsDebut) - \(tempsFin)")
    }

    // MARK: Body et viewbuilders
    var body: some View {
        VStack(alignment: .leading) {
            // VStack permet de masquer le rectangle transparant qui apparaît entre le top du sheet et le bas
            VStack {
                // Entête
                enTeteFeuilleModale
                VStack(spacing: 20) {
                    calendrierEtDescriptionEtUtilisateurs
                    carteInteractive
                    boutonOuvrirRouteDansMaps
                    boutonRejoindre
                    boutonSortir
                }
                .padding(.vertical)
                .padding(.horizontal, 20)
                Spacer()
            }
            .frame(minHeight: 600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.top, 30)
        .background(.white)
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 30, topTrailing: 30), style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: -18)
        .confirmationDialog("Calendar", isPresented: $montrerDialogueAjouterCalendrier, titleVisibility: .hidden) {
            Button("Add to calendar") { }
            Button("Cancel", role: .cancel) { }
        }
        .alert("remove bookmark?".localizedFirstCapitalized,
               isPresented: $montrerDialogueFavoris) {
            Button("cancel".localizedCapitalized, role: .cancel) { }
            Button("remove".localizedCapitalized, role: .destructive) {
                Task {
                    estFavoris = false
                    await activitesVM.toggleFavori(pour: activite, nouvelEtat: estFavoris)
                    dismiss()
                }
            }
        } message: {
            Text("this view will be discard.".localizedFirstCapitalized)
        }
        .alert("leave activity?".localizedFirstCapitalized, isPresented: $montrerDialogueSortir) {
            Button("cancel".localizedCapitalized, role: .cancel) { }
            Button("leave".localizedCapitalized, role: .destructive) {
                Task {
                    do {
                        let utilisateur = try GestionnaireAuthentification.partage.obtenirUtilisateurAuthentifier()
                        try await serviceActivites.updateParticipants(
                            dans: activite.id!,
                            pour: utilisateur.uid,
                            ajouter: false
                        )

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    } catch {
                        print("Erreur lors de la mise à jour \(error)")
                    }
                }
            }
        } message: {
            Text("leaving this activity will remove you from receiving notifications and messages about it.".localizedFirstCapitalized)
        }
    }
    
    @ViewBuilder
    private var enTeteFeuilleModale: some View {
        HStack {
            VStack(alignment: .leading) {
                // Titre de l'activité
                Text(activite.titre)
                    .font(.system(size: 24).weight(.semibold))
                // Parc de l'activité
                Text(nomDuParc)
                    .font(.callout.weight(.light))
                    .foregroundStyle(Color.black.opacity(0.8))
            }
            Spacer()
            // MARK: Bouton favoris
            if !cacherBoutonJoin {
                Image(systemName: estFavoris ? "bookmark.fill" : "bookmark")
                    .font(.title2)
                    .foregroundStyle(estFavoris ? Color("CouleurParDefaut") : .black.opacity(0.9))
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                    .onAppear { estFavoris = activitesVM.estFavori(activite) }
                    .onTapGesture {
                        if estFavoris {
                            montrerDialogueFavoris = true
                        } else {
                            Task {
                                estFavoris = true
                                await activitesVM.toggleFavori(pour: activite, nouvelEtat: estFavoris)
                            }
                        }
                    }
                
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var calendrierEtDescriptionEtUtilisateurs: some View {
        Divider()
        // Date
        HStack(alignment: .center) {
            Image(systemName: "calendar")
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(composantesDate.0)
                    .font(.headline.weight(.semibold))
                Text(composantesDate.1)
                    .font(.subheadline.weight(.light))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }.padding(.top, -6)
        .onTapGesture { montrerDialogueAjouterCalendrier = true }
        Divider().padding(.top, -6)
        // Messages
        if !cacherBoutonEditable {
            HStack(alignment: .center) {
                Image(systemName: "bubble.left.and.bubble.right")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Open the conversation")
                        .font(.headline.weight(.semibold))
                    Text(activite.messages.isEmpty ? "No messages yet" : "") // Ajouter logique pour les messages
                        .font(.subheadline.weight(.light))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }.padding(.top, -10)
            Divider().padding(.top, -6)
        }
        
        // Utilisateurs
        utilisateurs
        
        // Description
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.primary)
            
            TexteJustifieeVue(
                texte: activite.description.isEmpty ? "No description available." : activite.description,
                font: UIFont.systemFont(ofSize: 16, weight: .regular),
                textColor: .gray,
                bgColor: .systemGray6,
                cornerRadius: 12
            )
            .frame(minHeight: 100, maxHeight: 500) // ne pas changer la largeur
        }
    }
    
    @State private var etendre = false
    @State private var angleRotationChevron: Double = 0
    @State private var participantsInfo: [(Image, String)] = []
    @Namespace private var animationNamespace
    @ViewBuilder
    private var utilisateurs: some View {
        // Organisateur
        HStack {
            Text("Organizer:")
                .font(.headline)
                .foregroundColor(.primary)
            if let photo = photoOrganisateur {
                Image(uiImage: photo)
                    .resizable()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(Color.gray)
            }
            if let nom = nomOrganisateur {
                Text(nom)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            let (nom, image) = await serviceUtilisateurs.fetchInfoUtilisateur(pour: activite.organisateurId.valeur)
            nomOrganisateur = nom
            photoOrganisateur = image
        }
        let colonne = [GridItem(.adaptive(minimum: 80, maximum: 130), spacing: 8)]
        VStack(alignment: .leading) {
            Text("Participants: ")
                .font(.headline)
                .foregroundColor(.primary)
            VStack {
                LazyVGrid(columns: colonne, alignment: .leading, spacing: 8) {
                    ForEach(participantsInfo, id: \.1) { participant in // les usernames sont uniques
                        HStack {
                            participant.0
                                .resizable()
                                .frame(width: 34, height: 34)
                                .foregroundStyle(Color.gray)
                                .clipShape(Circle())
                            Text(participant.1)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    }
                }
                .frame(height: etendre ? nil : 50, alignment: .top)
                .clipped()
                
                Spacer()
                HStack {
                    Spacer()
                    HStack {
                        Image(systemName: "chevron.up")
                            .rotationEffect(Angle(degrees: etendre ? 180 : 0))
                        
                        Text(!etendre ? "see more".localizedFirstCapitalized : "see less".localizedFirstCapitalized)
                    }
                    .font(.subheadline)
                    .onTapGesture { etendre.toggle() }
                    Spacer()
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.gray, lineWidth: 1)
            )
            .task {
                self.participantsInfo = await activitesVM.obtenirPhotoEtNomParticipants(participantIds: activite.participants, serviceUtilisateurs: serviceUtilisateurs)
            }
        }
    }
    
    @ViewBuilder
    private var carteInteractive: some View {
        // Aperçu
        VStack {
            if let image = activitesVM.imageApercu {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(ProgressView())
            }
        }
        .mask(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            // Bouton ouvrir fullscreen
            Image(systemName: "arrow.down.left.and.arrow.up.right")
                .font(.system(size: 18))
                .foregroundStyle(.black)
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                .padding([.trailing, .top], 10)
        }
        .overlay(alignment: .topLeading) {
            Label("\(activitesVM.obtenirDistanceDeUtilisateur(pour: activite)) away", systemImage: "mappin.and.ellipse")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(couleurDeFondDistance.opacity(0.9))
                )
                .padding([.leading, .top], 10)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
    
    @ViewBuilder
    private var boutonOuvrirRouteDansMaps: some View {
        ZStack {
            if let coords = coordsInfrastructure {
                BoutonOuvrirMaps(
                    afficherConfirmation: $montrerConfirmationRoute,
                    itemMap: $itemRouteMap,
                    etiquette: Label("Get directions", systemImage: "car.fill"),
                    texteAlerte: "route",
                    fetchItemMap: { completion in
                        recherchePOI.ouvrirRouteDansMaps(
                            coordonneesDestination: coords,
                            nomSport: activite.sport,
                        ) { item in
                            completion(item)
                        }
                    },
                    optionsLancement: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ]
                )
                .foregroundStyle(.primary)
            } else {
                Text("Route indisponible")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
    
    @ViewBuilder
    private var boutonRejoindre: some View {
        if !cacherBoutonJoin {
            Button {
                Task {
                    do {
                        let utilisateur = try GestionnaireAuthentification.partage.obtenirUtilisateurAuthentifier()
                        try await serviceActivites.updateParticipants(
                            dans: activite.id!,
                            pour: utilisateur.uid,
                            ajouter: true
                        )
                        
                        if activitesVM.estFavori(activite) {
                            Task {
                                estFavoris = false
                                await activitesVM.toggleFavori(pour: activite, nouvelEtat: estFavoris)
                            }
                        }
            
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                            appVM.ongletSelectionne = .activites
                            appVM.trigger = .participe
                            appVM.sousOngletSelectionne = .participe
                        }
                    } catch {
                        print("Erreur lors de la mise à jour \(error)")
                    }
                }
            } label: {
                Text("join activity".localizedFirstCapitalized)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("CouleurParDefaut"))
            )
        }
    }
    
    @ViewBuilder
    private var boutonSortir: some View {
        if cacherBoutonJoin && cacherBoutonEditable {
            Text("leave activity".localizedFirstCapitalized)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color("CouleurParDefaut"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .onTapGesture { montrerDialogueSortir = true }
        }
    }
}

// MARK: Misc
struct TexteJustifieeVue: UIViewRepresentable {
    var texte: String
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var textColor: UIColor = .label
    var bgColor: UIColor = .clear
    var cornerRadius: CGFloat = 0
    var innerPadding: UIEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)


    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = true
        tv.textAlignment = .justified
        tv.backgroundColor = bgColor
        tv.font = font
        tv.textColor = textColor
        tv.layer.cornerRadius = cornerRadius
        tv.textContainerInset = innerPadding
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = texte
    }
}


// MARK: Preview
#Preview {
    let mockActivite = Activite(
        titre: "Soccer for amateurs",
        organisateurId: UtilisateurID(valeur: "demo"),
        infraId: "081-0090",
        sport: .soccer,
        date: DateInterval(start: .now, duration: 3600),
        nbJoueursRecherches: 4,
        participants: [],
        description: "Rejoignez-nous pour un match de soccer amical dans une ambiance conviviale et sportive. Perfect pour tous les niveaux, venez jouer et vous amuser en équipe sur le terrain.",
        statut: .ouvert,
        invitationsOuvertes: true,
        messages: []
    )
    
    DetailsActivite(activite: .constant(mockActivite))
        .environmentObject({
            let s = DonneesEmplacementService()
            s.chargerDonnees()
            return ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM())
        }())
        .environmentObject(ActivitesOrganiseesVM(serviceActivites: ServiceActivites(), serviceEmplacements: DonneesEmplacementService()))
}
