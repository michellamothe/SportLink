//
//  VueAccueil.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-12.
//

import SwiftUI

struct AccueilVue: View {
    @State private var nombreDePoints: Double = 70.0
    @State private var seuilDuNiveau: Double = 100.0
    @State private var imageAvatar: UIImage?
    
    var body: some View {
        ZStack {
            barreDeNavigation
            
            // Hardcoded
            ScrollView {
                zoneStatistiques
                    .padding(.top, 90)
                
                CoequipiersRecents()
                    .padding(.bottom, 70) // faire de l'espace a cause de la tabbar
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
        ZStack {
            VStack(spacing: 10) {
                NavigationLink {
                    StatistiquesVue()
                } label: {
                    Image(uiImage: imageAvatar ?? UIImage(resource: .hybride))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 165)
                        .clipShape(.circle)
                }
                .buttonStyle(.plain)
                
                Text("Level 5: Intermediate")
                    .font(.subheadline.weight(.light))
            }
            
            BarreDeProgres(
                nombreDePoints: $nombreDePoints,
                seuilDuNiveau: $seuilDuNiveau,
                sport: .soccer,
                epaisseurBarre: 16,
                ajustement: (x: -5, y: 27)
            )
            .frame(height: 200)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    AccueilVue()
}
