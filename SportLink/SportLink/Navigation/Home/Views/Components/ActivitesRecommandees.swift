//
//  ActivitesRecommandees.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-25.
//

import SwiftUI

struct ActivitesRecommandees: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var appVM: AppVM
    @EnvironmentObject var activitesVM: ActivitesVM
    @State private var montrerPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            titre
            VStack(spacing: 14) {
                if session.activites.isEmpty {
                    ContentUnavailableView(
                        "No recommanded activites",
                        systemImage: "star.slash",
                        description: Text("Add favorite sports or adjust your disponibilities.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(session.activites) { activite in
                        ActiviteRangee(activite: activite)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .mask(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 2)
        }
    }
    
    @ViewBuilder
    private var titre: some View {
        HStack {
            Text("recommanded activites".localizedFirstCapitalized)
                .font(.title2.weight(.semibold))
            Spacer()
            Button {
                self.montrerPopover = true
            } label: {
                Image(systemName: "info.circle")
                    .padding(.top, 3)
            }
            .foregroundStyle(.secondary)
            .popover(isPresented: $montrerPopover, attachmentAnchor: .point(.bottomTrailing), arrowEdge: .top) {
                Text("Your recommended activites are based on your region, your favourite sports and your availabilities.")
                    .font(.subheadline)
                    .frame(width: 350)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}

struct ActiviteRangee: View {
    @EnvironmentObject var session: Session          // ← pour récupérer le binding
    @EnvironmentObject var appVM: AppVM              // (si besoin dans Details)
    @EnvironmentObject var activitesVM: ActivitesVM
    let activite: Activite

    @State private var estFavoris = false
    @State private var estAppuyee = false
    @State private var allerAuxDetails = false       // ← déclencheur de nav
    @State private var bloquerNav = false            // ← pour ne pas naviguer quand on tape Favori

    private var nomDuParc: String {
        let (_, parcOpt) = activitesVM.obtenirInfraEtParc(infraId: activite.infraId)
        return parcOpt?.nom ?? ""
    }

    private var composantesDate: String {
        let (date, t1, t2) = activite.date.affichage
        return "\(date), \(t1) - \(t2)"
    }

    var body: some View {
        ZStack {
            // 1) Lien de navigation caché, piloté par `allerAuxDetails`
            NavigationLink(isActive: $allerAuxDetails) {
                if let binding = session.bindingActivite(id: activite.id!) {
                    DetailsActivite(activite: binding)
                        .environmentObject(activitesVM)
                        .environmentObject(appVM)
                        .cacherBoutonEditable()
                } else {
                    // Fallback (ne devrait pas arriver si l'id existe)
                    EmptyView()
                }
            } label: {
                EmptyView()
            }
            .hidden()

            // 2) Ta rangée “tapable” enveloppée par BoutonGestureScrollView
            BoutonGestureScrollView(
                actionAppui: { withAnimation { estAppuyee = true } },
                tempsAppuiLong: 0,
                actionAppuiLong: {},
                actionFin: { withAnimation { estAppuyee = false } },
                actionRelachement: {
                    // On ne navigue pas si l'utilisateur a tapé le bouton Favori
                    if bloquerNav {
                        bloquerNav = false
                        return
                    }
                    allerAuxDetails = true
                }
            ) {
                HStack(spacing: 12) {
                    Image(systemName: Sport.depuisNom(activite.sport).icone)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28)

                    VStack(spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activite.sport.capitalized)
                                    .font(.system(size: 18)).fontWeight(.bold)
                                Text(nomDuParc)
                                    .lineLimit(1).truncationMode(.tail)
                                    .font(.caption)
                            }
                            Spacer()

                            // Bouton Favori séparé, n’ouvre pas la nav
                            Image(systemName: "bookmark")
                                .symbolVariant(estFavoris ? .fill : .none)
                                .font(.system(size: 17))
                                .foregroundStyle(estFavoris ? .red : .black)
                                .padding(8)
                                .background(.ultraThickMaterial)
                                .clipShape(Circle())
                                .contentShape(Circle())
                                .onAppear { estFavoris = activitesVM.estFavori(activite) }
                                .onChange(of: activitesVM.estFavori(activite)) { _, nvValeur in
                                    if nvValeur == false {
                                        estFavoris = false
                                    }
                                }
                                .onTapGesture {
                                    bloquerNav = true    // empêche la nav sur ce tap
                                    Task {
                                        estFavoris.toggle()
                                        await activitesVM.toggleFavori(pour: activite, nouvelEtat: estFavoris)
                                    }
                                }
                        }

                        HStack(alignment: .top) {
                            Text(activitesVM.obtenirDistanceDeUtilisateur(pour: activite))
                                .font(.caption2)
                            Spacer()
                            Text(composantesDate)
                                .font(.system(size: 11)).fontWeight(.semibold)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .foregroundStyle(.black)
                .background(
                    RoundedRectangle(cornerRadius: 13.52371)
                        .fill(estAppuyee ? Color(.systemGray6) : .white)
                        .stroke(Color(red: 0.89, green: 0.89, blue: 0.89), lineWidth: 0.7)
                )
                .contentShape(Rectangle())
            }
        }
    }
}


#Preview {
    ActivitesRecommandees()
        .environmentObject(Session(serviceEmplacements: DonneesEmplacementService(), utilisateurConnecteVM: UtilisateurConnecteVM()))
}
