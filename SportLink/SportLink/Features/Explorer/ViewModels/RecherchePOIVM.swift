//
//  RecherchePOIVM.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-06-29.
//

import Foundation
import MapKit

class RecherchePOIVM: ObservableObject {
    private func trouverParc(entree: String, region: MKCoordinateRegion) -> MKLocalSearch {
        let requeteDeRecherche = MKLocalSearch.Request()
        
        requeteDeRecherche.naturalLanguageQuery = entree
        requeteDeRecherche.region = region
        
        return MKLocalSearch(request: requeteDeRecherche)
    }
    
    func ouvrirParcDansMaps(for parc: Parc, completion: @escaping (MKMapItem?) -> Void)  {
        let entree = parc.nom!
        let region = regionEnglobantPolygone(parc.limites)! // unwrappable
        let recherche = trouverParc(entree: entree, region: region)
        
        recherche.start { reponse, erreur in
            guard let reponse = reponse else {
                print("Erreur : \(erreur?.localizedDescription ?? "Erreur inconnue").")
                completion(nil)
                return
            }
            
            let item = reponse.mapItems.first
            completion(item)
        }
    }
    
    
    func ouvrirRouteDansMaps(coordonneesDestination: CLLocationCoordinate2D, nomSport: String, completion: @escaping (MKMapItem?) -> Void) {
        let repereDestination = MKPlacemark(coordinate: coordonneesDestination)
        let itemMapDestination = MKMapItem(placemark: repereDestination)
        itemMapDestination.name = "\(nomSport.capitalized) infrastructure"
        completion(itemMapDestination)
    }
}
