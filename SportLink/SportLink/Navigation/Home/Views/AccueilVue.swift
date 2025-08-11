//
//  VueAccueil.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-12.
//

import SwiftUI
import Firebase

struct AccueilVue: View {
    @EnvironmentObject var serviceEmplacements: DonneesEmplacementService
    @EnvironmentObject var session: Session
    @State private var nombreDePoints: Double = 70.0
    @State private var seuilDuNiveau: Double = 100.0
    
    var body: some View {
        ZStack {
            barreDeNavigation
            
            // Hardcoded
            ScrollView {
                zoneStatistiques
                    .padding(.top, 90)
                
                Group {
                    ActivitesRecommandees()
                        .padding(.bottom)
                    
                    TopCoequipiers()
                        .padding(.bottom, 70) // faire de l'espace a cause de la tabbar
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color(.systemGray6))
    }
    
    @ViewBuilder
    private var barreDeNavigation: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                HStack {}
                    .frame(width: 20, height: 20)
                Spacer()
                Text("Home")
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                Spacer()
                NavigationLink {
                    NotificationsVue()
                } label: {
                    Image(systemName: "bell")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
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
    private var zoneStatistiques: some View {
        VStack {
            ZStack {
                NavigationLink {
                    StatistiquesVue()
                } label: {
                    session.avatar
                        .resizable()
                        .scaledToFit()
                        .frame(height: 175)
                        .clipShape(.circle)
                        .foregroundStyle(Color.red.gradient)
                }
                .buttonStyle(.plain)
                
                let hauteur: CGFloat = 220
                BarreDeProgres(
                    nombreDePoints: $nombreDePoints,
                    seuilDuNiveau: $seuilDuNiveau,
                    sport: .tennis,
                    epaisseurBarreGrise: 6,
                    longueurDash: 2,
                    dashGap: 11,
                    hauteurRectangleOverlay: hauteur + 32
                )
                .frame(height: hauteur)
                .shadow(color: Color.gray.opacity(0.4), radius: 10)
            }
            .padding(.bottom)
            
            
            VStack(spacing: 6) {
                Text("level 5: tennis".localizedCapitalized)
                    .font(.title2.weight(.bold))
                (
                    Text("this is your most played sport. ".localizedFirstCapitalized) +
                    Text("click on the image to see more.".localizedFirstCapitalized)
                )
                .font(.system(size: 15, weight: .light))
                .multilineTextAlignment(.center)
            }
            .frame(width: UIScreen.main.bounds.width * 0.7)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    AccueilVue()
        .environmentObject(ActivitesVM(serviceEmplacements: DonneesEmplacementService(), serviceUtilisateurConnecte: UtilisateurConnecteVM()))
        .environmentObject(DonneesEmplacementService())
        .environmentObject(Session(serviceEmplacements: DonneesEmplacementService(), utilisateurConnecteVM: UtilisateurConnecteVM()))
}
