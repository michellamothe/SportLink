//
//  BarreDeRecherche.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-12.
//

import SwiftUI

struct BarreDeRecherche: View {
    @Binding var texteDeRecherche: String
    @Binding var afficherFiltreOverlay: Bool
    @Binding var dateAFiltree: Date
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                .padding(.trailing, 4)
            
            TextField("Search by title or parc...", text: $texteDeRecherche)
                .autocorrectionDisabled(true)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if afficherFiltreOverlay {
                            withAnimation { afficherFiltreOverlay = false }
                        }
                    }
                )
                .overlay(
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.systemGray2))
                        .padding()
                        .offset(x: 10)
                        .opacity(texteDeRecherche.isEmpty ? 0.0 : 1.0)
                        .onTapGesture {
                            UIApplication.shared.terminerEditage()
                            texteDeRecherche = ""
                        }
                    , alignment: .trailing
                )
            
            BoutonFiltrage(afficherFiltreOverlay: $afficherFiltreOverlay, dateAFiltree: $dateAFiltree)
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .strokeBorder(Color(.systemGray4), lineWidth: 2)
                .background(Color.white.cornerRadius(25))
        )

    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BarreDeRecherche(
        texteDeRecherche: .constant("dsdsd"),
        afficherFiltreOverlay: .constant(false),
        dateAFiltree: .constant(.now),
    )
}
