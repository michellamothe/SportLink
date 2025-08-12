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
            
            let activitesConverties = try requeteSnapshot.documents.map { doc in
                let dto = try doc.data(as: ActiviteDTO.self)
                var activite = dto.versActivite()
                activite.id = doc.documentID
                return activite
            }
            
            self.activites = activitesConverties
        } catch {
            print("Erreur lors de la récupération des activités : \(error)")
        }
    }
    
    // MARK: Pour activites favoris de l'utilisateur connecté
    func fetchActivitesParIds(ids: [String]) async {
        guard !ids.isEmpty else {
            self.activites = []
            return
        }

        do {
            let requeteSnapshot = try await Firestore.firestore()
                .collection("activites")
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments()

            let activitesConverties = try requeteSnapshot.documents.map { doc in
                let dto = try doc.data(as: ActiviteDTO.self)
                var activite = dto.versActivite()
                activite.id = doc.documentID
                return activite
            }

            self.activites = activitesConverties
        } catch {
            print("Erreur lors de la récupération des activités favorites : \(error)")
            self.activites = []
        }
    }
    
    func fetchActivitesParInfrastructureEtDateAsync(infraId: String, date: Date) async {
        let activitesConverties = await fetchActivitesParInfrastructure(infraId: infraId)
        
        // Filtrer par date
        let calendrier = Calendar.current
        let activitesFiltrees = activitesConverties
            .filter { calendrier.isDate($0.date.debut, inSameDayAs: date) }
            .sorted { $0.date.debut < $1.date.debut }

        self.activites = activitesFiltrees
    }
    
    func fetchActivitesParInfrastructure(infraId: String) async -> [Activite] {
        do {
            let requeteSnapshot = try await Firestore.firestore()
                .collection("activites")
                .whereField("infraId", isEqualTo: infraId)
                .whereField("date.debut", isGreaterThanOrEqualTo: timestampMinuit)
                .getDocuments()

            let activitesConverties = try requeteSnapshot.documents.map { doc in
                let dto = try doc.data(as: ActiviteDTO.self)
                var activite = dto.versActivite()
                activite.id = doc.documentID
                return activite
            }
            
            
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

            self.activites = activitesConverties
        } catch {
            print("Erreur Hosted : \(error)")
        }
    }
    
    func fetchActivitesParParticpant(participantId: String) async {
        do {
            let requeteSnapshot = try await Firestore.firestore()
                .collection("activites")
                .whereField("participants", arrayContains: participantId)
                .whereField("date.debut", isGreaterThanOrEqualTo: timestampMinuit) // on peut instorer une archive plus tard
                .getDocuments()
            
            let activitesConverties = try requeteSnapshot.documents.map { doc in
                let dto = try doc.data(as: ActiviteDTO.self)
                var activite = dto.versActivite()
                activite.id = doc.documentID
                return activite
            }
            
            self.activites = activitesConverties
        } catch {
            print("Erreur Going : \(error)")
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
    
    func updateParticipants(dans aid: String, pour uid: String, ajouter: Bool) async throws {
        let requeteSnapshot = Firestore.firestore()
            .collection("activites")
            .document(aid)
        
        if ajouter {
            try await requeteSnapshot.updateData([
                "participants": FieldValue.arrayUnion([uid])
            ])
        } else {
            try await requeteSnapshot.updateData([
                "participants": FieldValue.arrayRemove([uid])
            ])
        }
    }
    
    // MARK: A UPDATE AVEC LE NOUVEAU ID FETCHED
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
