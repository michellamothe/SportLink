//
//  VueActivites.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-15.
//

import SwiftUI

enum SousOnglets: String, CaseIterable {
    case organise = "Hosting"
    case participe = "Going"
    case favoris = "Bookmarked"
}

struct ActivitesVue: View {
    @EnvironmentObject var serviceEmplacements: DonneesEmplacementService
    @EnvironmentObject var activitesVM: ActivitesVM
    @EnvironmentObject var appVM: AppVM
    @EnvironmentObject var utilisateurConnecteVM: UtilisateurConnecteVM
    
    @Namespace var line

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .center) {
                    Text("Your dashboard")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.top, 10)
                    
                    HStack {
                        ForEach(SousOnglets.allCases, id: \.self) { tab in
                            VStack {
                                Button {
                                    withAnimation {
                                        appVM.sousOngletSelectionne = tab
                                    }
                                } label: {
                                    Text(tab.rawValue)
                                        .font(.headline)
                                        .foregroundColor(appVM.sousOngletSelectionne == tab ? .primary : .gray)
                                }
                                .frame(maxWidth: .infinity)
                                
                                ZStack {
                                    Rectangle().fill(Color("CouleurParDefaut"))
                                        .frame(height: 1)
                                        .opacity(0)
                                    
                                    if appVM.sousOngletSelectionne == tab {
                                        Rectangle().fill(Color("CouleurParDefaut"))
                                            .frame(height: 1)
                                            .matchedGeometryEffect(id: "tab", in: line)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                ZStack {
                    if appVM.trigger == .organise {
                        ActivitesOrganiseesVue(serviceEmplacements: serviceEmplacements)
                            .environmentObject(activitesVM)
                            .transition(.asymmetric(
                                insertion: appVM.aInserer,
                                removal: appVM.aDegager
                            ))
                    }
                    if appVM.trigger == .participe  {
                        ActivitesInscritesVue(serviceEmplacements: serviceEmplacements)
                            .environmentObject(activitesVM)
                            .transition(.asymmetric(
                                insertion: appVM.aInserer,
                                removal: appVM.aDegager
                            ))
                    }
                    if appVM.trigger == .favoris {
                        ActivitesFavoritesVue(serviceEmplacements: serviceEmplacements, utilisateurConnecteVM: utilisateurConnecteVM)
                            .transition(.asymmetric(
                                insertion: appVM.aInserer,
                                removal: appVM.aDegager
                            ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemGray6))
        }
    }
}

#Preview {
    ActivitesVue()
        .environmentObject(DonneesEmplacementService())
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
        .environmentObject(UtilisateurConnecteVM())
}



