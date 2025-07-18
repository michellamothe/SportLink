//
//  ModifierVue.swift
//  SportLink
//
//  Created by Michel Lamothe on 2025-07-17.
//

import SwiftUI
import MapKit

struct ModifierVue: View {
    @Binding var activite: Activite
    @FocusState private var titreEstEnEdition: Bool

    @EnvironmentObject var vm: ActivitesOrganiseesVM
    @EnvironmentObject var activitesVM: ActivitesVM
    @Environment(\.dismiss) var dismiss

    @State private var sauvegardeReussie: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            barreSuperieure

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    champTitreModifiable
                    sectionSport
                    sectionDate
                    sectionHeure
                    sectionCarte
                    sectionPlaces
                    sectionInvitations
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay(overlaySauvegarde)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // MARK: - Sous-vues

    private var barreSuperieure: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .padding()
                .foregroundColor(.blue)
                .font(.headline)

            Spacer()

            Button("Save") {
                sauvegarderTitre(titre: activite.titre, activite: activite, vm: vm) {
                    withAnimation { sauvegardeReussie = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        vm.objectWillChange.send()
                        dismiss()
                    }
                }
            }
            .padding()
            .foregroundColor(.blue)
            .font(.headline)
        }
    }

    private var champTitreModifiable: some View {
        HStack {
            TextField("Nom de l'activité", text: $activite.titre)
                .focused($titreEstEnEdition)
                .submitLabel(.done)
                .font(.title3)
                .foregroundColor(.black)
                .padding(.leading)

            Image(systemName: "pencil")
                .foregroundColor(.gray)
                .padding(.trailing)
        }
        .frame(height: 50)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { titreEstEnEdition = true }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var sectionSport: some View {
        let sport = Sport.depuisNom(activite.sport)
        return HStack(spacing: 8) {
            Image(systemName: sport.icone)
                .foregroundColor(.red)
                .font(.title2)
            Text(sport.nom.capitalized)
                .font(.title2)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var sectionDate: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundColor(Color("CouleurParDefaut"))
                .font(.title3)
            Text(dateFormatter.string(from: activite.date.debut).capitalized)
                .font(.title3)
                .foregroundColor(.black)
        }
        .padding(.horizontal)
    }

    private var sectionHeure: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .foregroundColor(Color("CouleurParDefaut"))
                .font(.title3)
            Text("\(formatter.string(from: activite.date.debut)) - \(formatter.string(from: activite.date.debut))")
                .font(.title3)
                .foregroundColor(.black)
        }
        .padding(.horizontal)
    }

    private var sectionCarte: some View {
        Group {
            Text(nomDuParc)
                .font(.title3)
                .padding(.horizontal)
                .padding(.bottom, -12)

            if let infra = infra {
                CarteParcSeeMore(infrastructure: infra)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }

    private var sectionPlaces: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2")
                .foregroundColor(Color("CouleurParDefaut"))
                .font(.headline)
            Text("Places disponibles : \(nbPlacesRestantes)")
                .foregroundColor(.black)
                .font(.title3)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var sectionInvitations: some View {
        HStack(spacing: 8) {
            Image(systemName: activite.invitationsOuvertes ? "envelope.open" : "figure.child.and.lock.fill")
                .foregroundColor(Color("CouleurParDefaut"))
            Text(activite.invitationsOuvertes ? "Open to guests invitations" : "Close to guests invitations")
                .foregroundColor(.black)
        }
        .font(.title3)
        .padding(.horizontal)
    }

    private var overlaySauvegarde: some View {
        Group {
            if sauvegardeReussie {
                OverlaySauvegarde()
            }
        }
    }

    // MARK: - Utils

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_CA")
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }

    private var formatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    private var nbPlacesRestantes: String {
        let diff = activite.nbJoueursRecherches - activite.participants.count
        return diff == 0 ? "No spot left" : "\(diff) spots left"
    }

    private var nomDuParc: String {
        let (_, parcOpt) = activitesVM.obtenirInfraEtParc(infraId: activite.infraId)
        return parcOpt?.nom ?? ""
    }

    private var infra: Infrastructure? {
        let (infraOpt, _) = activitesVM.obtenirInfraEtParc(infraId: activite.infraId)
        return infraOpt
    }
}
