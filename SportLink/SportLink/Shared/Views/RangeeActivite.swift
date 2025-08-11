//
//  ActiviteRangeeVue.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-02.
//

import SwiftUI
import MapKit

struct RangeeActivite: View {
    // MARK: Variables et propriétés calculées
    @EnvironmentObject var vm: ExplorerListeVM
    @EnvironmentObject var activitesVM: ActivitesVM
    @EnvironmentObject var appVM: AppVM
    @Environment(\.cacherBoutonJoin) private var cacherBoutonJoin
    @Environment(\.dateEtendue) private var dateEtendue
    @StateObject private var serviceActivites = ServiceActivites()
    @State private var estFavoris = false
    @Binding var afficherInfo: Bool

    let activite: Activite
    let couleur = Color(red: 0.784, green: 0.231, blue: 0.216)
    
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
    
    private var composantesDate: String {
        let (date, tempsDebut, tempsFin) = activite.date.affichage
        let temps = "\(tempsDebut) - \(tempsFin)"
        return dateEtendue ? "\(date), " + temps : temps
    }
    
    var body: some View {
        VStack {
            VStack {
                ZStack {
                    Image(Sport.depuisNom(activite.sport).arriereplan)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: afficherInfo ? 6 : 0)
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                        .onTapGesture {
                            withAnimation {
                                afficherInfo.toggle()
                            }
                        }

                    if afficherInfo {
                        // Info bulle au centre de l'image
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
                .frame(height: 150)
                .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, topTrailing: 20), style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Label("\(activitesVM.obtenirDistanceDeUtilisateur(pour: activite)) away", systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(couleur.opacity(0.9))
                        )
                        .padding([.trailing, .top], 10)
                        .blur(radius: afficherInfo ? 6 : 0)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: estFavoris ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 19))
                        .foregroundStyle(estFavoris ? couleur : .white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        .padding([.bottom, .trailing], 8)
                        .disabled(afficherInfo)
                        .blur(radius: afficherInfo ? 6 : 0)
                        .onAppear { estFavoris = activitesVM.estFavori(activite) }
                        .onTapGesture {
                            Task {
                                // optimistic UI
                                estFavoris.toggle()
                                
                                await activitesVM.toggleFavori(pour: activite, nouvelEtat: estFavoris)
                                //estFavoris = activitesVM.estFavori(activite) // resync
                              
                            }
                        }
                }
               
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .frame(width: 7, height: 7)
                        Text("\(nbPlacesRestantes)")
                            .font(.system(size: 16))
                            .fontWeight(.light)
                    }
                    .foregroundStyle(Color(uiColor: activite.statut.couleur))
                    
                    HStack(alignment: .top) {
                        Image(systemName: Sport.depuisNom(activite.sport).icone)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28)
                            .padding(.trailing, 4)
                            .padding(.top, 10)
                        
                        HStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                Text(activite.titre)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(nomDuParc)
                                        .lineLimit(1)
                                        .font(.callout)
                                        .fontWeight(.light)
                                        .foregroundStyle(Color(.systemGray))
                                    
                                    Text(composantesDate)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .padding(.bottom, 10)
            
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 0) {
                    NavigationLink(value: activite) {
                        Text("See more")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.primary)
                    }
                   
                    if !cacherBoutonJoin {
                        Divider()
                            .frame(width: 1, height: 50)

                        Button {
                            Task {
                                do {
                                    let utilisateur = try GestionnaireAuthentification.partage.obtenirUtilisateurAuthentifier()
                                    try await serviceActivites.updateParticipants(
                                        dans: activite.id!,
                                        pour: utilisateur.uid,
                                        ajouter: true
                                    )
                        
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        appVM.ongletSelectionne = .activites
                                        appVM.trigger = .participe
                                        appVM.sousOngletSelectionne = .participe
                                    }
                                } catch {
                                    print("Erreur lors de la mise à jour \(error)")
                                }
                            }
                        } label: {
                            Text("Join")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(couleur)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .frame(height: 50)
            }
            
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    let mockActivite =
    Activite(
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
    
    RangeeActivite(
        afficherInfo: .constant(false),
        activite: mockActivite
    )
    .environmentObject({
        let service = DonneesEmplacementService()
        service.chargerDonnees()
        return ExplorerListeVM(
            serviceEmplacements: DonneesEmplacementService(), serviceActivites: ServiceActivites()
        )
    }())
    .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
    .environmentObject(AppVM())
}
