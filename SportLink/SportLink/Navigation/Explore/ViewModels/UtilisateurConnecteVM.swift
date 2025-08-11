//
//  UtilisateurConnecteVM.swift
//  SportLink
//
//  Created by Michel Lamothe on 2025-07-29.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class UtilisateurConnecteVM: ObservableObject {
    @Published var utilisateur: Utilisateur? = nil
    @Published var photoUIImage: UIImage? = nil

    func chargerInfosUtilisateur() async {
        do {
            let auth = try GestionnaireAuthentification.partage.obtenirUtilisateurAuthentifier()
            let docRef = Firestore.firestore().collection("utilisateurs").document(auth.uid)
            let snapshot = try await docRef.getDocument()

            guard let data = snapshot.data() else { return }

            let nomUtilisateur = data["nomUtilisateur"] as? String ?? ""
            let courriel = auth.courriel ?? ""
            let photoProfil = data["photoUrl"] as? String ?? ""

            // Charger disponibilités
            let disponibilitesData = data["disponibilites"] as? [String: [String]] ?? [:]
            let disponibilites = Dictionary(uniqueKeysWithValues: disponibilitesData.map { key, value in
                let intKey = Self.jourEnInt(key)
                return (intKey, value)
            })

            // Charger sportsFavoris
            let sportsFavoris = (data["sportsFavoris"] as? [String] ?? []).compactMap { Sport(rawValue: $0) }
            
            // Charger activitesFavorites
            let activitesFavorites = data["activitesFavorites"] as? [String] ?? []
            let activitesFavoris = activitesFavorites.compactMap { id in
                ActiviteID(valeur: id)
            }

            // Pour l’instant, on laisse les favoris et partenaires vides
            let utilisateur = Utilisateur(
                nomUtilisateur: nomUtilisateur,
                courriel: courriel,
                photoProfil: photoProfil,
                disponibilites: disponibilites,
                sportsFavoris: sportsFavoris,
                activitesFavoris: activitesFavoris,
                partenairesRecents: []
            )

            self.utilisateur = utilisateur

            // Charger l'image de profil
            if let url = URL(string: utilisateur.photoProfil) {
                let (donnees, _) = try await URLSession.shared.data(from: url)
                self.photoUIImage = UIImage(data: donnees)
            }
        } catch {
            print("Erreur chargement utilisateur : \(error.localizedDescription)")
        }
    }

    private static func jourEnInt(_ jour: String) -> Int {
        switch jour.lowercased() {
            case "monday", "mon": return 1
            case "tuesday", "tue": return 2
            case "wednesday", "wed": return 3
            case "thursday", "thu": return 4
            case "friday", "fri": return 5
            case "saturday", "sat": return 6
            case "sunday", "sun": return 7
            default: return 0
        }
    }
}
