//
//  Session.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-08-10.
//

import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class Session: ObservableObject {
    private let serviceEmplacements: DonneesEmplacementService
    private let serviceUtilisateurConnecte: UtilisateurConnecteVM
    private let gestionnaireLocalisation = GestionnaireLocalisation.instance
    private let nombreActivitesRecommandeesAAfficheer = 3
    
    @Published var avatar: Image = Image(systemName: "person.crop.circle.fill")
    @Published var activitesRecommandees: [Activite] = []
    @Published var estPret: Bool = false
    
    private var listener: ListenerRegistration?
    private let timestampMinuit: Timestamp

    init(serviceEmplacements: DonneesEmplacementService, utilisateurConnecteVM: UtilisateurConnecteVM) {
        self.serviceEmplacements = serviceEmplacements
        self.serviceUtilisateurConnecte = utilisateurConnecteVM
        
        let calendrier = Calendar.current
        let maintenant = Date()
        let minuitAujourdHui = calendrier.startOfDay(for: maintenant)
        self.timestampMinuit = Timestamp(date: minuitAujourdHui)

        Task {
            if let avatarUIImage = try? await GestionnaireAuthentification.partage.telechargerPhoto() {
                self.avatar = Image(uiImage: avatarUIImage)
            }

            listener = Firestore.firestore()
                .collection("activites")
                .whereField("date.debut", isGreaterThanOrEqualTo: timestampMinuit) // éviter de fetch les activiteé passées
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let docs = snapshot?.documents {
                        do {
                            let dtos = try docs.map { try $0.data(as: ActiviteDTO.self) }
                            let activites = dtos.map { $0.versActivite() }
                            let filtrees = self.filtrerLesRecommandations(activites: activites)
                            self.activitesRecommandees = Array(filtrees.prefix(self.nombreActivitesRecommandeesAAfficheer))
                            self.estPret = true
                        } catch {
                            print("Map DTO -> Activite error: \(error)")
                        }
                    }
                }
        }
    }
    
    deinit { listener?.remove() }
    
    private func filtrerLesRecommandations(activites: [Activite]) -> [Activite] {
        var resultat = activites
        
        // Filtrage par implicaiton (participant ou organisateur)
        do {
            let utilisateur = try GestionnaireAuthentification.partage.obtenirUtilisateurAuthentifier()
            let uid = UtilisateurID(valeur: utilisateur.uid)
            resultat = resultat.filter {
                $0.organisateurId != uid && !$0.participants.contains(uid)
            }
        } catch {
            print("Impossible de filtrer par l'utilisateur courant : \(error)")
        }
        
        // Filtrage par sports
        if let u = self.serviceUtilisateurConnecte.utilisateur, !u.sportsFavoris.isEmpty {
            let favoris = Set(u.sportsFavoris.map { $0.nomPourJSONDecoding })
            resultat = resultat.filter { favoris.contains($0.sport) }
        }
        
        // Filtrage par dispos
        if let u = self.serviceUtilisateurConnecte.utilisateur, !u.disponibilites.isEmpty {
            resultat = resultat.filter { a in
                let jour = jourDeSemaineIndexApp(from: a.date.debut) // 1=lundi…7=dimanche
                guard let creneaux = u.disponibilites[jour], !creneaux.isEmpty else {
                    return false // pas dispo ce jour-là
                }

                // Plage activité en minutes
                let act = (minutesDepuisMinuit(a.date.debut), minutesDepuisMinuit(a.date.fin))

                // Au moins un créneau dispo chevauche la plage de l’activité
                for s in creneaux {
                    if let c = parseCreneau(s) {
                        if chevauche(act, c) { return true }
                    }
                }
                return false
            }
        }
        
        // Triage par distance
        var avecDistances: [(activite: Activite, distance: Double)] = resultat.map { a in
            let d = obtenirDistanceDeUtilisateur(pour: a) ?? Double.infinity
            return (a, d)
        }

        avecDistances.sort { $0.distance < $1.distance }

        return avecDistances.map { $0.activite }
    }
    
    func obtenirDistanceDeUtilisateur(pour activite: Activite) -> Double? {
        guard
            let userLoc = gestionnaireLocalisation.location?.coordinate,
            let infraCoords = serviceEmplacements.obtenirObjetInfrastructure(pour: activite.infraId)?.coordonnees
        else {
            return nil
        }
        
        return calculerDistanceEntreCoordonnees(position1: userLoc, position2: infraCoords) // en mètres
    }
    
    private func jourDeSemaineIndexApp(from date: Date) -> Int {
        // Swift: .weekday (1=dimanche … 7=samedi). On remappe vers 1=lundi … 7=dimanche.
        let w = Calendar.current.component(.weekday, from: date) // 1..7
        return (w == 1) ? 7 : (w - 1) // 1..7 avec 1=lundi
    }

    private func minutesDepuisMinuit(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func parseCreneau(_ s: String) -> (debut: Int, fin: Int)? {
        let trimme = s.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimme == "AM" { return (0, 12*60) }           // 00:00-12:00
        if trimme == "PM" { return (12*60, 24*60 - 1) }   // 12:00-23:59

        // Format "HH:mm-HH:mm"
        let parties = trimme.split(separator: "-").map { String($0) }
        guard parties.count == 2,
              let d = parseHHmm(parties[0]),
              let f = parseHHmm(parties[1])
        else { return nil }
        return (d, f)
    }

    private func parseHHmm(_ s: String) -> Int? {
        let comps = s.split(separator: ":")
        guard comps.count == 2,
              let h = Int(comps[0]), let m = Int(comps[1]),
              (0...23).contains(h), (0...59).contains(m)
        else { return nil }
        return h*60 + m
    }

    private func chevauche(_ a: (Int, Int), _ b: (Int, Int)) -> Bool {
        // [a0,a1) overlap [b0,b1) — on tolère b1==1440 en fin de journée
        return max(a.0, b.0) < min(a.1, b.1)
    }
}
