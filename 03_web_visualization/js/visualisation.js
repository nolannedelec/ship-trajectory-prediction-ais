// Déclare un tableau pour stocker tous les bateaux
let allBateaux = [];

// Stocke le MMSI du bateau sélectionné
let selectedMmsi = null;

// Référence vers l'objet du graphique Plotly
let plotlyChart = null;

// Événement déclenché lorsque le DOM est entièrement chargé
document.addEventListener('DOMContentLoaded', function() {
    // Charge les données des bateaux
    chargerBateaux();
    // Ajoute un écouteur d'événement pour le bouton de suppression de sélection
    document.getElementById('clear_selection').addEventListener('click', function() {
        clearSelection();
    });
});

// Fonction pour charger les données des bateaux depuis un fichier PHP
function chargerBateaux() {
    fetch('./php/get_bateaux2.php') // Effectue une requête fetch vers le fichier PHP
        .then(response => response.json()) // Convertit la réponse en JSON
        .then(data => {
            allBateaux = data; // Stocke les données dans allBateaux
            remplirTableau(data); // Remplit le tableau HTML avec les données
            afficherCarteGenerale(data); // Affiche tous les bateaux sur la carte
            updateTotalBateaux(data.length); // Met à jour le nombre total de bateaux affiché
        })
        .catch(error => {
            console.error('Erreur lors du chargement des bateaux :', error); // Affiche une erreur dans la console
            showError('Erreur lors du chargement des données'); // Affiche une erreur à l'utilisateur
        });
}

// Fonction pour remplir le tableau HTML avec les données des bateaux
function remplirTableau(data) {
    const tbody = document.querySelector('#bateauTable tbody'); // Sélectionne le corps du tableau
    tbody.innerHTML = ''; // Vide le contenu précédent
    const bateauxUniques = {}; // Objet pour stocker les bateaux uniques par MMSI

    data.forEach(bateau => {
        // Conserve uniquement le bateau avec l'horodatage le plus récent pour chaque MMSI
        if (!bateauxUniques[bateau.MMSI] ||
            new Date(bateau.horodatage) > new Date(bateauxUniques[bateau.MMSI].horodatage)) {
            bateauxUniques[bateau.MMSI] = bateau;
        }
    });

    // Parcourt les bateaux uniques pour les ajouter au tableau HTML
    Object.values(bateauxUniques).forEach(bateau => {
        const tr = document.createElement('tr'); // Crée une ligne de tableau
        tr.innerHTML = `
            <td class="col-select">
                <div class="radio_container">
                    <input type="radio" name="bateauSelection" value="${bateau.MMSI}" onchange="selectionnerBateau('${bateau.MMSI}')">
                </div>
            </td>
            <td>${bateau.MMSI}</td>
            <td>${bateau.nom}</td>
            <td>${bateau.longueur}m</td>
            <td>${bateau.largeur}m</td>
            <td>${bateau.tirant_eau}m</td>
            <td>${parseFloat(bateau.latitude).toFixed(4)}</td>
            <td>${parseFloat(bateau.longitude).toFixed(4)}</td>
            <td>${bateau.SOG} kn</td>
            <td>${bateau.COG}°</td>
            <td>${bateau.cap_reel}°</td>
            <td>${formatTimestamp(bateau.horodatage)}</td>
        `;
        tbody.appendChild(tr); // Ajoute la ligne au tableau
    });
}

// Fonction appelée lorsqu’un bateau est sélectionné
function selectionnerBateau(MMSI) {
    selectedMmsi = MMSI; // Met à jour le MMSI sélectionné
    const rows = document.querySelectorAll('#bateauTable tbody tr'); // Sélectionne toutes les lignes du tableau

    rows.forEach(row => {
        const radio = row.querySelector('input[type="radio"]'); // Trouve le bouton radio dans la ligne
        if (radio && radio.value === MMSI) row.classList.add('selected'); // Ajoute la classe si sélectionné
        else row.classList.remove('selected'); // Sinon, retire la classe
    });

    chargerTrajectoire(MMSI); // Charge la trajectoire du bateau sélectionné
    afficherInfosBateau(MMSI); // Affiche les infos du bateau sélectionné
}

// Fonction pour charger la trajectoire d’un bateau
function chargerTrajectoire(MMSI) {
    fetch(`./php/get_trajectoire.php?mmsi=${encodeURIComponent(MMSI)}`) // Requête fetch avec le MMSI
        .then(response => response.json()) // Convertit la réponse en JSON
        .then(trajectoire => {
            if (trajectoire.error) { // Vérifie s’il y a une erreur
                console.error('Erreur trajectoire:', trajectoire.error); // Affiche une erreur
                showError('Erreur lors du chargement de la trajectoire'); // Message utilisateur
                return;
            }
            afficherTrajectoire(trajectoire); // Affiche la trajectoire
        })
        .catch(error => {
            console.error('Erreur lors du chargement de la trajectoire:', error); // Erreur réseau ou parsing
            showError('Erreur lors du chargement de la trajectoire'); // Message utilisateur
        });
}

// Fonction pour afficher la trajectoire d’un bateau sur la carte
function afficherTrajectoire(trajectoire) {
    if (!trajectoire || trajectoire.length === 0) {
        showError('Aucune donnée de trajectoire disponible'); // Alerte si aucune donnée
        return;
    }

    // Filtre les points valides (coordonnées non nulles et valides)
    const trajectoireValide = trajectoire.filter(point => {
        const valid = point.latitude !== null && point.longitude !== null &&
                      !isNaN(parseFloat(point.latitude)) && !isNaN(parseFloat(point.longitude));
        if (!valid) console.warn("Point invalide ignoré:", point); // Avertit si invalide
        return valid;
    });

    if (trajectoireValide.length === 0) {
        showError('Données de trajectoire invalides'); // Message si aucun point valide
        return;
    }

    // Trace principale de la trajectoire
    const traceTrajectoire = {
        type: 'scattermapbox',
        mode: 'lines+markers',
        name: `Trajectoire ${trajectoireValide[0].nom}`,
        lat: trajectoireValide.map(p => parseFloat(p.latitude)),
        lon: trajectoireValide.map(p => parseFloat(p.longitude)),
        text: trajectoireValide.map(p => `<b>${p.nom}</b><br>MMSI: ${p.MMSI}<br>Vitesse: ${p.SOG} kn<br>Cap: ${p.COG}°<br>Heure: ${formatTimestamp(p.horodatage)}`),
        hovertemplate: '%{text}<extra></extra>',
        line: { width: 3, color: '#1e88e5' },
        marker: { size: 8, color: '#1e88e5', symbol: 'circle' }
    };

    // Marqueur de départ
    const debut = trajectoireValide[0];
    const traceDebut = {
        type: 'scattermapbox',
        mode: 'markers',
        name: 'Départ',
        lat: [parseFloat(debut.latitude)],
        lon: [parseFloat(debut.longitude)],
        text: [`<b>${debut.nom}</b><br>MMSI: ${debut.MMSI}<br>Vitesse: ${debut.SOG} kn<br>Cap: ${debut.COG}°<br>Heure: ${formatTimestamp(debut.horodatage)}`],
        hovertemplate: '%{text}<extra></extra>',
        marker: { size: 12, color: '#4caf50', symbol: 'circle' }
    };

    // Marqueur d’arrivée
    const fin = trajectoireValide[trajectoireValide.length - 1];
    const traceFin = {
        type: 'scattermapbox',
        mode: 'markers',
        name: 'Arrivée',
        lat: [parseFloat(fin.latitude)],
        lon: [parseFloat(fin.longitude)],
        text: [`<b>${fin.nom}</b><br>MMSI: ${fin.MMSI}<br>Vitesse: ${fin.SOG} kn<br>Cap: ${fin.COG}°<br>Heure: ${formatTimestamp(fin.horodatage)}`],
        hovertemplate: '%{text}<extra></extra>',
        marker: { size: 12, color: '#f44336', symbol: 'circle' }
    };

    // Calcule le centre de la carte
    const lats = trajectoireValide.map(p => parseFloat(p.latitude));
    const lons = trajectoireValide.map(p => parseFloat(p.longitude));
    const centerLat = (Math.min(...lats) + Math.max(...lats)) / 2;
    const centerLon = (Math.min(...lons) + Math.max(...lons)) / 2;

    // Définition du layout de la carte
    const layout = {
        mapbox: {
            style: 'open-street-map',
            center: { lat: centerLat, lon: centerLon },
            zoom: calculateZoom(lats, lons)
        },
        margin: { t: 0, b: 0, l: 0, r: 0 },
        showlegend: true,
        legend: { x: 0, y: 1, bgcolor: 'rgba(255,255,255,0.8)', bordercolor: '#ccc', borderwidth: 1 }
    };

    // Affiche les traces sur la carte avec Plotly
    const traces = [traceTrajectoire, traceDebut, traceFin];
    if (plotlyChart) Plotly.react('map', traces, layout); // Met à jour si déjà existant
    else plotlyChart = Plotly.newPlot('map', traces, layout); // Sinon crée le graphique
}

// Affiche tous les bateaux sur une carte générale
function afficherCarteGenerale(data) {
    if (!data || data.length === 0) return; // Ne fait rien si pas de données

    const bateauxUniques = {}; // Unicité par MMSI
    data.forEach(bateau => {
        if (!bateauxUniques[bateau.MMSI] || new Date(bateau.horodatage) > new Date(bateauxUniques[bateau.MMSI].horodatage)) {
            bateauxUniques[bateau.MMSI] = bateau;
        }
    });

    const bateaux = Object.values(bateauxUniques); // Liste des bateaux uniques
    const trace = {
        type: 'scattermapbox',
        mode: 'markers',
        name: 'Bateaux',
        text: bateaux.map(bateau => `<b>${bateau.nom}</b><br>MMSI: ${bateau.MMSI}<br>Vitesse: ${bateau.SOG} kn<br>Dernière position: ${formatTimestamp(bateau.horodatage)}`),
        hovertemplate: '%{text}<extra></extra>',
        lat: bateaux.map(bateau => parseFloat(bateau.latitude)),
        lon: bateaux.map(bateau => parseFloat(bateau.longitude)),
        marker: { size: 8, color: '#2196f3', opacity: 0.7 }
    };

    const layout = {
        mapbox: { style: 'open-street-map', center: { lat: 25, lon: -90 }, zoom: 4 },
        margin: { t: 0, b: 0, l: 0, r: 0 },
        showlegend: false
    };

    if (plotlyChart) Plotly.react('map', [trace], layout); // Met à jour si existant
    else plotlyChart = Plotly.newPlot('map', [trace], layout); // Sinon crée la carte
}

// Affiche les infos du bateau sélectionné dans un div
function afficherInfosBateau(MMSI) {
    const bateau = allBateaux.find(b => b.MMSI === MMSI); // Recherche le bateau
    if (!bateau) return; // Ne fait rien si non trouvé

    const infoDiv = document.getElementById('bateau_info'); // Sélectionne le conteneur d’info
    const detailsSpan = document.getElementById('bateau_details'); // Sélectionne l’élément texte
    detailsSpan.innerHTML = `<strong>${bateau.nom}</strong> (MMSI: ${bateau.MMSI}) - Dernière position: ${formatTimestamp(bateau.horodatage)}`; // Affiche les infos
    infoDiv.style.display = 'block'; // Rend visible le div
}

// Réinitialise la sélection de bateau
function clearSelection() {
    selectedMmsi = null; // Réinitialise le MMSI sélectionné
    document.querySelectorAll('input[name="bateauSelection"]').forEach(radio => radio.checked = false); // Déselectionne les radios
    document.querySelectorAll('#bateauTable tbody tr').forEach(row => row.classList.remove('selected')); // Retire la classe sélectionnée
    document.getElementById('bateau_info').style.display = 'none'; // Cache la div d’info
    afficherCarteGenerale(allBateaux); // Réaffiche la carte générale
}

// Calcule un niveau de zoom approximatif en fonction de l'étendue des coordonnées
function calculateZoom(lats, lons) {
    const latRange = Math.max(...lats) - Math.min(...lats); // Étendue latitude
    const lonRange = Math.max(...lons) - Math.min(...lons); // Étendue longitude
    const maxRange = Math.max(latRange, lonRange); // Plus grande des deux
    if (maxRange > 10) return 3;
    if (maxRange > 5) return 4;
    if (maxRange > 2) return 5;
    if (maxRange > 1) return 6;
    if (maxRange > 0.5) return 7;
    if (maxRange > 0.1) return 8;
    return 9; // Zoom maximum si très rapproché
}

// Formate un timestamp en date locale française
function formatTimestamp(timestamp) {
    const date = new Date(timestamp); // Convertit le timestamp en Date
    return date.toLocaleDateString('fr-FR', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }); // Formate
}

// Met à jour le compteur de bateaux affiché
function updateTotalBateaux(count) {
    document.getElementById('total_bateaux').textContent = `${count} bateaux trouvés`; // Met à jour le texte
}

// Affiche un message d’erreur à l’utilisateur
function showError(message) {
    console.error(message); // Affiche dans la console
    alert(message); // Alerte utilisateur
}
