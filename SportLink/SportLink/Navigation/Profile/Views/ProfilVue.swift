//
//  ProfilVue.swift
//  SportLink
//
//  Created by Michel Lamothe on 2025-06-27.
//

import SwiftUI

struct ProfilVue: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var utilisateurVM: UtilisateurConnecteVM
    @State private var montrerImagePicker = false
    
    let onDeconnexion: () -> Void
    
    var body: some View {
        ZStack {
            /*Text("Your profile")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))*/
            barreDeNavigation
            
            ScrollView {
                VStack(spacing: 20) {
                    // Photo
                    photoProfil
                        .padding(.top, 90)

                    // Nom d'utilisateur
                    Text(utilisateurVM.utilisateur?.nomUtilisateur ?? "Utilisateur")
                        .font(.title2)
                    
                    // Dispos
                    disponibilites
                    
                    Divider()
                        .background(Color.gray.opacity(0.4))
                        .padding(.horizontal)
                    
                    // Sports favoris
                    sportsFavoris
     
                    // Log Out
                    boutonDeconnexion
                    
                    Spacer()
                }
                .padding()
            }
            .task { await utilisateurVM.chargerInfosUtilisateur() }
        }
        .background(Color(.systemGray6))
    }
    
    @ViewBuilder
    private var barreDeNavigation: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Spacer()
                Text("You")
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                Color(.systemGray6)
                    .ignoresSafeArea()
                    .shadow(color: .black.opacity(0.15), radius: 5)
            )
            
            Spacer()
        }
        .zIndex(1)
    }
    
    @ViewBuilder
    private var boutonDeconnexion: some View {
        Button {
            Task {
                do {
                    try GestionnaireAuthentification.partage.deconnexion()
                    onDeconnexion()
                } catch {
                    print("Erreur déconnexion: \(error.localizedDescription)")
                }
            }
        } label: {
            Text("Sign Out")
                .foregroundColor(.red)
                .bold()
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private var photoProfil: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: {
                montrerImagePicker = true
            }) {
                session.avatar
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .foregroundStyle(Color.gray)
            }
            .sheet(isPresented: $montrerImagePicker) {
                // Tu peux ajouter l'ImagePicker ici plus tard si tu veux modifier la photo
            }
            
            Image(systemName: "pencil.circle.fill")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundColor(.blue)
                .background(Color.white.clipShape(Circle()))
                .offset(x: -4, y: -4)
        }
        .frame(width: 130, height: 130)
    }
    
    @ViewBuilder
    private var disponibilites: some View {
        if let disponibilites = utilisateurVM.utilisateur?.disponibilites {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weekly Availabilities")
                        .font(.headline)
                    Spacer()
                    Button(action: {}) {
                        Text("Modify")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
                .padding(.top)
                
                ForEach(JourDeLaSemaine.allCases) { jour in
                    let creneaux = disponibilites[jour.numeroDansLaSemaine] ?? []
                    
                    if !creneaux.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(jour.rawValue.capitalized(with: .current))
                                .font(.subheadline)
                                .bold()
                            
                            ForEach(creneaux, id: \.self) { range in
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.red)
                                    Text(range)
                                        .font(.body)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var sportsFavoris: some View {
        if let sportsFavoris = utilisateurVM.utilisateur?.sportsFavoris {
            let tousLesSports = Sport.allCases
            let sportsNonFavoris = tousLesSports.filter { sport in
                !sportsFavoris.contains(where: { $0.nomPourAffichage == sport.nomPourAffichage })
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("My Favorite Sports")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(sportsFavoris, id: \.self) { sport in
                            CelluleSportVue(sport: sport, style: Color.red, estContour: false)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if !sportsNonFavoris.isEmpty {
                    Text("Other Sports")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(sportsNonFavoris, id: \.self) { sport in
                                CelluleSportVue(sport: sport, style: Color.gray.opacity(0.4), estContour: true)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Capsule sport statique

struct CelluleSportVue<C: ShapeStyle>: View {
    let sport: Sport
    let style: C
    let estContour: Bool

    var body: some View {
        Label {
            Text(sport.nomPourAffichage.capitalized)
        } icon: {
            Image(systemName: sport.icone)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .modifier(StyleCellule(style: style, bordure: estContour))
        .foregroundColor(estContour ? .gray : .white)
    }
}

struct StyleCellule<C: ShapeStyle>: ViewModifier {
    let style: C
    let bordure: Bool
    
    func body(content: Content) -> some View {
        if bordure {
            content.background(Capsule().stroke(style, lineWidth: 1))
        } else {
            content.background(Capsule().fill(style))
        }
    }
}

// MARK: - Regroupe les sports par ligne de 3

func grouperSports(_ sports: [Sport], maxParLigne: Int = 3) -> [[Sport]] {
    var lignes: [[Sport]] = []
    var ligneActuelle: [Sport] = []

    for sport in sports {
        ligneActuelle.append(sport)
        if ligneActuelle.count == maxParLigne {
            lignes.append(ligneActuelle)
            ligneActuelle = []
        }
    }

    if !ligneActuelle.isEmpty {
        lignes.append(ligneActuelle)
    }

    return lignes
}

extension JourDeLaSemaine {
    var numeroDansLaSemaine: Int {
        switch self {
        case .lundi: return 1
        case .mardi: return 2
        case .mercredi: return 3
        case .jeudi: return 4
        case .vendredi: return 5
        case .samedi: return 6
        case .dimanche: return 7
        }
    }
}

/*
#Preview {
    ProfilVue(onDeconnexion: { print("Non déconnecté") })
        .environmentObject(UtilisateurConnecteVM())
}
*/
