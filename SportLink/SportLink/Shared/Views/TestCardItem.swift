//
//  TestCardItem.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-18.
//

import SwiftUI

struct TestCardItem: View {
    @Environment(\.cacherBoutonJoin) private var cacherBoutonJoin
    @EnvironmentObject var vm: ActivitesOrganiseesVM
    @EnvironmentObject var activitesVM: ActivitesVM
    
    @State private var estFavoris = false
    @State private var timerAnimation: Timer?
    
    var namespace: Namespace.ID
    var activite: Activite
    @Binding var activiteSelectionnee: Activite?
    @Binding var animationEnCours: Bool
    @Binding var afficherMessageImage: Bool
    
    let couleur = Color(red: 0.784, green: 0.231, blue: 0.216)
    
    var body: some View {
        VStack {
            VStack(spacing: 12) {
                construireImageArrierePlan()
    
                VStack(alignment: .trailing, spacing: 0) {
                    placesRestantes
                    construireDetailsActivite()
                }
            }
            .padding([.top, .trailing, .leading])
            .padding(.bottom, 10)

            // MARK: Actions avec transition
            construireSectionActions()
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 2)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-mask", in: namespace)
        )
        .padding(.horizontal, 20)
        .onDisappear {
            timerAnimation?.invalidate()
            timerAnimation = nil
        }
    }

    @ViewBuilder
    private func construireImageArrierePlan() -> some View {
        VStack(alignment: .trailing) {
            distanceAPartirUtilisateur
                .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer()
            iconeBookmark
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 120)
        .background(
            Sport.depuisNom(activite.sport).arriereplan
                .resizable()
                .aspectRatio(contentMode: .fill)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-arriereplan", in: namespace)
        )
        .blur(radius: afficherMessageImage ? 6 : 0)
        .mask(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-arriereplanMask", in: namespace)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            withAnimation { afficherMessageImage.toggle() }
        }
        .overlay(
            Group {
                if afficherMessageImage {
                    Text("Image for illustration only, not actual representation of the \(activite.sport) infrastructure.")
                        .multilineTextAlignment(.center)
                        .frame(width: 260)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                        .padding(.horizontal, 14)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        )
    }
    
    @ViewBuilder
    private func construireDetailsActivite() -> some View {
        HStack(alignment: .top) {
            Image(systemName: Sport.depuisNom(activite.sport).icone)
                .resizable()
                .scaledToFit()
                .frame(width: 28)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-icone", in: namespace)
                .padding(.trailing, 4)
                .padding(.top, 10)
            
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(activite.titre)
                        .font(.title3.weight(.semibold))
                        .matchedGeometryEffect(id: "\(String(describing: activite.id))-titre", in: namespace)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(nomDuParc)
                            .font(.callout.weight(.light))
                            .foregroundStyle(Color(.systemGray))
                            .matchedGeometryEffect(id: "\(String(describing: activite.id))-parc", in: namespace)
                            .lineLimit(1)
                        
                        Text(composantesDate)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .matchedGeometryEffect(id: "\(String(describing: activite.id))-titreBack", in: namespace)
        )
    }
    
    @ViewBuilder
    private func construireSectionActions() -> some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 0) {
                Text("See more")
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        ouvrirActiviteDetails()
                    }
               
                if !cacherBoutonJoin {
                    Divider()
                        .frame(width: 1, height: 50)
                    Button {
                        // Logique ici
                    } label: {
                        Text("Join Game")
                            .foregroundColor(Color("CouleurParDefaut"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(animationEnCours)
                }
            }
            .frame(height: 50)
        }
        // Transition vers le bas quand l'animation est en cours
        .offset(y: activiteSelectionnee != nil ? 100 : 0)
        .opacity(activiteSelectionnee != nil ? 0 : 1)
        .animation(.easeInOut(duration: 0.6), value: activiteSelectionnee)
    }
    
    var distanceAPartirUtilisateur: some View {
        HStack {
            Image(systemName: "mappin.and.ellipse")
            Text("\(activitesVM.obtenirDistanceDeUtilisateur(pour: activite)) away")
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(couleur.opacity(0.9))
        )
        .padding([.trailing, .top], 10)
        .zIndex(1)
    }
    
    var iconeBookmark: some View {
        Image(systemName: estFavoris ? "bookmark.fill" : "bookmark")
            .font(.system(size: 19))
            .foregroundStyle(estFavoris ? couleur : .white)
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            .padding([.bottom, .trailing], 10)
            .onTapGesture {
                estFavoris.toggle()
            }
            .disabled(afficherMessageImage)
    }
    
    var placesRestantes: some View {
        HStack(spacing: 6) {
            Circle()
                .frame(width: 7, height: 7)
            Text("\(nbPlacesRestantes)")
                .font(.system(size: 16))
                .fontWeight(.light)
        }
        .foregroundStyle(Color(uiColor: activite.statut.couleur))
    }
    
    private var composantesDate: String {
        let (jourDuMois, tempsDebut, tempsFin) = activite.date.affichage
        return "\(jourDuMois), \(tempsDebut) - \(tempsFin)"
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
    
    private func ouvrirActiviteDetails() {
        
        timerAnimation?.invalidate()
        animationEnCours = true
        
        // Durée explicite
        withAnimation(.easeInOut(duration: 0.6)) {
            activiteSelectionnee = activite
        }
        
        // Timer ajusté : durée + petit buffer
        timerAnimation = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
            DispatchQueue.main.async {
                animationEnCours = false
                timerAnimation = nil
            }
        }
    }
}

struct TestCardItem_Previews: PreviewProvider {
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
        
        TestCardItem(
            namespace: namespace,
            activite: mockActivite,
            activiteSelectionnee: .constant(mockActivite),
            animationEnCours: .constant(false),
            afficherMessageImage: .constant(false)
        )
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService()))
        .environmentObject(ActivitesOrganiseesVM(serviceActivites: ServiceActivites(), serviceEmplacements: DonneesEmplacementService()))
    }
}
