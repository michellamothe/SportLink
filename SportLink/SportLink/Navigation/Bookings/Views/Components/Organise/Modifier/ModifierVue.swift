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
    var onSauvegarde: () -> Void = {}
    @FocusState private var titreEstEnEdition: Bool

    @EnvironmentObject var vm: ActivitesOrganiseesVM
    @EnvironmentObject var activitesVM: ActivitesVM
    @Environment(\.dismiss) var dismiss

    @State private var sauvegardeReussie: Bool = false
    @State private var heureSelectionnee: Date = Date()
    @State private var modaleHeureActive: Bool = false
    @State private var heureDebutTemporaire: Date = Date()
    @State private var heureFinTemporaire: Date = Date()
    @State private var overlayActif: ActiveOverlay = .none
    @State private var invitationsOuvertesTemporaire: Bool = true
    @State private var descriptionTemporaire: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            barreSuperieure

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    champTitreModifiable

                    HStack {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    sectionHeure

                    HStack {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    sectionPlaces

                    HStack {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    sectionInvitations

                    HStack {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    sectionDescription
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay(overlaySauvegarde)
        .overlay(vueOverlayParticipants)
        .overlay(vueOverlayInvitations)
        .overlay(overlayModaleHeure)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            heureDebutTemporaire = activite.date.debut
            heureFinTemporaire = activite.date.fin
            descriptionTemporaire = activite.description
        }
        .onChange(of: activite.id) { _ in
            heureDebutTemporaire = activite.date.debut
            heureFinTemporaire = activite.date.fin
            descriptionTemporaire = activite.description
        }
    }

    // MARK: - Sous-vues

    private var barreSuperieure: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .padding()
                .foregroundColor(.blue)
                .font(.headline)

            Spacer()
            
            Text("Edit")
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            Button("Save") {
                let nouvelleDate = PlageHoraire(debut: heureDebutTemporaire, fin: heureFinTemporaire)
                activite.date = nouvelleDate
                activite.description = descriptionTemporaire

                sauvegarderTitre(titre: activite.titre, activite: activite, vm: vm) {
                    sauvegarderDate(activite: activite, vm: vm) {
                        sauvegarderParticipants(activite: activite, vm: vm) {
                            sauvegarderDescription(activite: activite, vm: vm) {
                                sauvegarderAutorisationInvitations(activite: activite, vm: vm) {
                                    withAnimation { sauvegardeReussie = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        onSauvegarde()                      
                                        vm.objectWillChange.send()
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .foregroundColor(.blue)
            .font(.headline)
        }
    }

    private var champTitreModifiable: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("title of the activity".localizedUppercase)
                .font(.subheadline)
                .foregroundColor(.gray)
                .fontWeight(.bold)

            HStack {
                TextField("name of the activity".localizedFirstCapitalized, text: $activite.titre)
                    .focused($titreEstEnEdition)
                    .submitLabel(.done)
                    .font(.headline)
                    .foregroundColor(.black)
                    .fontWeight(.regular)
                
                Spacer()
                Image(systemName: "pencil")
                    .foregroundColor(.gray)
            }
            .frame(height: 50)
            .padding(.horizontal)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture { titreEstEnEdition = true }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    
    private var sectionHeure: some View {
        VStack(spacing: 8) {
            Button(action: { modaleHeureActive = true }) {
                BoiteAvecChevron { // on ne met pas `showChevron: true`
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color("CouleurParDefaut"))

                        Text("\(formatter.string(from: heureDebutTemporaire)) to \(formatter.string(from: heureFinTemporaire))")
                            .foregroundColor(.black)
                            .font(.body)

                        Spacer()

                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                    }
                }
            }
            .buttonStyle(.plain)
            
        }
      
    }
    

    private var sectionPlaces: some View {
        Button {
            overlayActif = .participants
        } label: {
            BoiteAvecChevron(showChevron: false) {
                HStack {
                    Image(systemName: "person.2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("CouleurParDefaut"))

                    Text("\(activite.nbJoueursRecherches) players")

                    Spacer()

                    Image(systemName: "pencil")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private var sectionInvitations: some View {
        Button {
            invitationsOuvertesTemporaire = activite.invitationsOuvertes
            overlayActif = .invitations
        } label: {
            BoiteAvecChevron(showChevron: false) {
                HStack {
                    Image(systemName: "envelope.open")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("CouleurParDefaut"))

                    Text(activite.invitationsOuvertes ? "Open to guest invitations" : "Closed to guest invitations")
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer()

                    Image(systemName: "pencil")
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    private var overlaySauvegarde: some View {
        Group {
            if sauvegardeReussie {
                OverlaySauvegarde()
            }
        }
    }
    
    private var overlayModaleHeure: some View {
        Group {
            if modaleHeureActive {
                FenetreModaleFlottante(estPresente: $modaleHeureActive) {
                    VStack(spacing: 20) {
                        Text("Modifier l'heure")
                            .font(.headline)
                            .padding(.top)

                        DatePicker("Début", selection: $heureDebutTemporaire, displayedComponents: .hourAndMinute)
                            .onChange(of: heureDebutTemporaire) { nouvelleHeureDebut in
                                if heureFinTemporaire < nouvelleHeureDebut {
                                    heureFinTemporaire = nouvelleHeureDebut.addingTimeInterval(3600) // +1h
                                }
                            }
                            .datePickerStyle(.wheel)
                            .labelsHidden()

                        DatePicker("Fin", selection: $heureFinTemporaire, in: heureDebutTemporaire..., displayedComponents: .hourAndMinute)
                            .id(heureDebutTemporaire)
                            .datePickerStyle(.wheel)
                            .labelsHidden()

                        Divider()

                        HStack(spacing: 0) {
                            Button("Fermer") {
                                modaleHeureActive = false
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.primary)

                            Divider()

                            Button("OK") {
                                activite.date = PlageHoraire(
                                    debut: heureDebutTemporaire,
                                    fin: max(heureDebutTemporaire, heureFinTemporaire)
                                )
                                modaleHeureActive = false
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color("CouleurParDefaut"))
                        }
                        .frame(height: 44)
                    }
                    .padding()
                }
            }
        }
    }
    private var vueOverlayParticipants: some View {
        FenetreModaleFlottante(estPresente: Binding(
            get: { overlayActif == .participants },
            set: { if !$0 { overlayActif = .none } }
        )) {
            VStack(spacing: 0) {
                Text("Nombre de joueurs recherchés")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 20)

                Picker("Joueurs", selection: $activite.nbJoueursRecherches) {
                    ForEach(1..<21, id: \.self) { Text("\($0)") }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)

                Divider()

                HStack(spacing: 0) {
                    Button("Fermer") {
                        overlayActif = .none
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)

                    Divider().frame(width: 1, height: 60)

                    Button("OK") {
                        overlayActif = .none
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .foregroundColor(Color("CouleurParDefaut"))
                }
            }
            .frame(width: 300)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private var vueOverlayInvitations: some View {
        FenetreModaleFlottante(estPresente: Binding(
            get: { overlayActif == .invitations },
            set: { if !$0 { overlayActif = .none } }
        )) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("Guests invitations")
                        .font(.title3)
                        .fontWeight(.semibold)

                    VStack(spacing: 10) {
                        Button {
                            activite.invitationsOuvertes = true
                        } label: {
                            Label("Open to guests invitations", systemImage: "figure.child.and.lock.open.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(activite.invitationsOuvertes ? Color("CouleurParDefaut") : .black)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button {
                            activite.invitationsOuvertes = false
                        } label: {
                            Label("Close to guests invitations", systemImage: "figure.child.and.lock.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(!activite.invitationsOuvertes ? Color("CouleurParDefaut") : .black)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 20)
                }
                .padding([.top, .leading, .trailing], 20)
                .padding(.bottom, 25)

                Divider()
                HStack(spacing: 0) {
                    Button("Close") {
                        overlayActif = .none
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)

                    Divider().frame(width: 1, height: 60)

                    Button("OK") {
                        overlayActif = .none
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .foregroundColor(Color("CouleurParDefaut"))
                    .fontWeight(.semibold)
                }
            }
            .frame(width: 300)
        }
    }
    
    private var sectionDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION")
                .padding(.horizontal)
                .font(.subheadline)
                .foregroundColor(.gray)
                .fontWeight(.bold)

            TextEditor(text: $descriptionTemporaire)
                .frame(minHeight: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
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
        f.timeZone = TimeZone(identifier: "America/Toronto")
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
    enum ActiveOverlay {
        case none
        case participants
        case invitations
    }
}
