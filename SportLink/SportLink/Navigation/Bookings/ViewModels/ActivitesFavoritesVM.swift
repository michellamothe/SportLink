//
//  ActivitesFavoritesVM.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-08-10.
//

import SwiftUI

@MainActor
class ActivitesFavoritesVM: ObservableObject {
    let serviceActivites: ServiceActivites
    private let serviceEmplacements: DonneesEmplacementService
    private let serviceUtilisateurConnecte: UtilisateurConnecteVM
    
    @Published var estEnChargement = false
    @Published var activiteSelectionnee: Activite?
    @Published private(set) var activites: [Activite] = []
    
    init(serviceActivites: ServiceActivites, serviceEmplacements: DonneesEmplacementService, serviceUtilisateurConnecte: UtilisateurConnecteVM) {
        self.serviceActivites = serviceActivites
        self.serviceEmplacements = serviceEmplacements
        self.serviceUtilisateurConnecte = serviceUtilisateurConnecte
    }
    
    func fetchActivitesFavorites() async {
        estEnChargement = true
        guard let favoris = serviceUtilisateurConnecte.utilisateur?.activitesFavoris else {
            activites = []
            estEnChargement = false
            return
        }
        let ids = favoris.map { $0.valeur }
        await serviceActivites.fetchActivitesParIds(ids: ids)
        self.activites = serviceActivites.activites
        estEnChargement = false
    }
    
    func syncWithFavoris(_ ids: Set<String>) async {
        // remove the ones no longer in favoris
        let idSet = Set(activites.compactMap(\.id))
        let toRemove = idSet.subtracting(ids)
        if !toRemove.isEmpty {
            activites.removeAll { a in toRemove.contains(a.id ?? "") }
        }

        // fetch the new ones
        let toAdd = ids.subtracting(idSet)
        if !toAdd.isEmpty {
            await serviceActivites.fetchActivitesParIds(ids: Array(toAdd))
            let fetched = serviceActivites.activites
            let existing = Set(activites.compactMap(\.id))
            for a in fetched {
                if let id = a.id, !existing.contains(id) {
                    activites.append(a)
                }
            }
        }
    }
    
    func bindingActivite(id: String) -> Binding<Activite>? {
        guard let index = activites.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.activites[index] },
            set: { self.activites[index] = $0 }
        )
    }
}
