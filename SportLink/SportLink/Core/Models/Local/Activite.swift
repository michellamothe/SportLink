//
//  Activite.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-14.
//

import Foundation
import FirebaseFirestore

enum StatutActivite: Int, Codable {
    case ouvert = 0
    case complet = 1
    case annulee = 2
    
    var strVal: String {
        switch self {
        case .ouvert: return "open"
        case .complet: return "full"
        case .annulee: return "" // doesn't matter
        }
    }
    
    var couleur: UIColor {
        switch self {
        case .ouvert: return .systemGreen
        case .complet: return .systemRed
        case .annulee: return .black // doesn't matter
        }
    }
}

enum ActiviteErreur: Error {
    case titreTropLong
}

struct ActiviteID: Hashable, Codable {
    let valeur: String
}

struct PlageHoraire: Codable {
    let debut: Date
    let fin: Date

    var interval: DateInterval {
        let start = min(debut, fin)
        let end   = max(debut, fin)
        return DateInterval(start: start, end: end)
    }
    
    var affichage: (String, String, String) {
        struct Format {
            static let date: DateFormatter = {
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = "MMM d"
                f.timeZone = TimeZone(identifier: "America/Toronto")
                return f
            }()
            
            static let temps: DateFormatter = {
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = "h:mm a"   // ex. "9:05 PM"
                f.timeZone = TimeZone(identifier: "America/Toronto")
                return f
            }()
        }

        let dateStr = Format.date.string(from: debut)
        let debutStr = Format.temps.string(from: debut)
        let finStr = Format.temps.string(from: fin)
        return (dateStr, debutStr, finStr)
    }
}


struct Activite: Identifiable, Codable {
    @DocumentID var id: String?
    
    var titre: String
    let organisateurId: UtilisateurID
    let infraId: String
    let sport: String
    var date: PlageHoraire
    var nbJoueursRecherches: Int
    var participants: [UtilisateurID]
    var description: String
    var statut: StatutActivite
    var invitationsOuvertes: Bool
    var messages: [MessageID]
    
    init(

        titre: String,
        organisateurId: UtilisateurID,
        infraId: String,
        sport: Sport,
        date: DateInterval,
        nbJoueursRecherches: Int,
        participants: [UtilisateurID],
        description: String,
        statut: StatutActivite,
        invitationsOuvertes: Bool,
        messages: [MessageID]
    ) {

        self.titre = titre
        self.organisateurId = organisateurId
        self.infraId = infraId
        self.sport = sport.nomPourJSONDecoding
        self.date = PlageHoraire(debut: date.start, fin: date.end)
        self.nbJoueursRecherches = nbJoueursRecherches
        self.participants = participants
        self.description = description
        self.statut = statut
        self.invitationsOuvertes = invitationsOuvertes
        self.messages = messages
    }
}

extension Activite: Hashable {
    func versDTO() -> ActiviteDTO {
        ActiviteDTO(
            id: id,
            titre: titre,
            organisateurId: organisateurId.valeur,
            infraId: infraId,
            sport: sport,
            date: date,
            nbJoueursRecherches: nbJoueursRecherches,
            participants: participants.map { $0.valeur },
            description: description,
            statut: statut.rawValue,
            invitationsOuvertes: invitationsOuvertes,
            messages: messages.map { $0.valeur }
        )
    }
    
    func obtenirPlageHoraireStr() -> (String, String) {
        let format = DateFormatter()
        format.timeStyle = .short
        format.dateStyle = .none

        let heureDebut = format.string(from: date.debut)
        let heureFin = format.string(from: date.fin)
        
        return (heureDebut, heureFin)
    }
    
    static func ==(lhs: Activite, rhs: Activite) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension String {
    var enActiviteID: ActiviteID {
        ActiviteID(valeur: self)
    }
}
