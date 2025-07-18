//
//  ServiceActivite.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-02.
//

import Foundation

import FirebaseCore
import FirebaseFirestore

@MainActor
class ServiceActivites: ObservableObject {
    @Published var activites: [Activite] = []
    let timestampMinuit: Timestamp
    
    init() {
        let calendrier = Calendar.current
        let maintenant = Date()

        let minuitAujourdHui = calendrier.startOfDay(for: maintenant)
        self.timestampMinuit = Timestamp(date: minuitAujourdHui)
    }
    
    func fetchTousActivites() async {
        do {
            let requeteSnapshot = try await Firestore.firestore()
                .collection("activites")
                .whereField("date.debut", isGreaterThanOrEqualTo: timestampMinuit) // éviter de fetch les activiteé passées
                .getDocuments()
            
            let dtos = try requeteSnapshot.documents.map { document in
                try document.data(as: ActiviteDTO.self)
            }

            let activitesConverties = dtos.map { $0.versActivite() }
            
            // Assigner un ID localement
            let activites = activitesConverties.map { activite in
                var activiteMutable = activite
                activiteMutable.id = UUID().uuidString
                return activiteMutable
            }
            
            self.activites = activites
        } catch {
            print("Erreur lors de la récupération des activités : \(error)")
        }
    }
    
    func fetchActivitesParInfrastructureEtDateAsync(infraId: String, date: Date) async {
        let activitesConverties = await fetchActivitesParInfrastructure(infraId: infraId)
        
        // Filtrer par date
        let calendrier = Calendar.current
        let activitesFiltrees = activitesConverties
            .filter { calendrier.isDate($0.date.debut, inSameDayAs: date) }
            .sorted { $0.date.debut < $1.date.debut }
        
        // Assigner un ID localement
        let activites = activitesFiltrees.map { activite in
            var activiteMutable = activite
            activiteMutable.id = UUID().uuidString
            return activiteMutable
        }

        self.activites = activites
    }
    
    func fetchActivitesParInfrastructure(infraId: String) async -> [Activite] {
        do {
            let requeteSnapshot = try await Firestore.firestore()
                .collection("activites")
                .whereField("infraId", isEqualTo: infraId)
                .whereField("date.debut", isGreaterThanOrEqualTo: timestampMinuit)
                .getDocuments()

            let dtos = try requeteSnapshot.documents.map { document in
                try document.data(as: ActiviteDTO.self)
            }

            let activitesConverties = dtos.map { $0.versActivite() }
            
            return activitesConverties
        } catch {
            print("Erreur lors de la récupération des activités : \(error)")
            return []
        }
    }
    
    func fetchActivitesParOrganisateur(organisateurId: String) async {
        do {
            let requeteSnapshot = try await Firestore.firestore()
                .collection("activites")
                .whereField("organisateurId", isEqualTo: organisateurId)
                .whereField("date.debut", isGreaterThanOrEqualTo: timestampMinuit) // on peut instorer une archive plus tard
                .getDocuments()

            let dtos = try requeteSnapshot.documents.map { doc in
                try doc.data(as: ActiviteDTO.self)
            }

            let activitesConverties = dtos.map { $0.versActivite() }
            print("Number of activites fetched: \(activitesConverties.count)")
            
            let activites = activitesConverties.map { activite in
                var activiteMutable = activite
                activiteMutable.id = UUID().uuidString
                return activiteMutable
            }
            
            self.activites = activites
        } catch {
            print("Erreur Hosted : \(error)")
        }
    }
    
    func sauvegarderActiviteAsync(activite: Activite) async {
        let dto = activite.versDTO()
        do {
            let ref = try Firestore.firestore()
                .collection("activites")
                .addDocument(from: dto)
            print("Activité sauvegardée avec l’ID :", ref.documentID)
        } catch {
            print("Erreur lors de la sauvegarde de l’activité :", error)
        }
    }
    
    // Modifier le titre de l'activité
    func modifierTitreActivite(idActivite: String, nouveauTitre: String, completion: @escaping (Error?) -> Void) {
        let reference = Firestore.firestore().collection("activites").document(idActivite)
        
        reference.updateData([
            "titre": nouveauTitre
        ]) { error in
            completion(error)
        }
    }
    
    func recupererIdActiviteParInfraId(_ infraId: String, completion: @escaping (String?, Error?) -> Void) {
        Firestore.firestore().collection("activites")
            .whereField("infraId", isEqualTo: infraId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }

                guard let doc = snapshot?.documents.first else {
                    completion(nil, nil) // Aucun document trouvé
                    return
                }

                completion(doc.documentID, nil)
            }
    }
}
