document.addEventListener("DOMContentLoaded", function () {
    // ================================
    // INITIALISATION DE LA CARTE
    // ================================

    // Layout prévu pour une carte Plotly (inutilisé ici avec Leaflet)
    const layout = {
        mapbox: {
            style: 'open-street-map',
            center: { lat: centerLat, lon: centerLon }, // Variables non définies ici (potentielle erreur)
            zoom: calculateZoom(lats, lons)             // Idem, dépendances absentes
        },
        margin: { t: 0, b: 0, l: 0, r: 0 },
        showlegend: true,
        legend: {
            x: 0, y: 1,
            bgcolor: 'rgba(255,255,255,0.8)',
            bordercolor: '#ccc',
            borderwidth: 1
        }
    };
    // Initialise la carte Leaflet centrée sur le Golfe du Mexique
    const map = L.map("mapid").setView([28.5, -90.0], 6);

    // Charge les tuiles cartographiques d’OpenStreetMap
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 18,
        attribution: "© OpenStreetMap contributors"
    }).addTo(map);

    // ============================================
    // AFFICHAGE DES BATEAUX EN FONCTION DU CLUSTER
    // ============================================

    function afficherBateauxParCluster(data) {
        // Tableau de couleurs pour différencier les clusters
        const clusterColors = [
            "red", "blue", "green", "orange", "purple", "cyan", "brown", "black"
        ];

        // Parcours des données des bateaux
        data.forEach(bateau => {
            const { lat, lon, cluster, mmsi } = bateau;

            // Ignore si coordonnées manquantes
            if (!lat || !lon) return;

            // Création d’un marqueur circulaire coloré en fonction du cluster
            const marker = L.circleMarker([parseFloat(lat), parseFloat(lon)], {
                radius: 6,
                color: clusterColors[cluster % clusterColors.length],
                fillOpacity: 0.8,
            }).addTo(map);

            // Affiche un popup au clic avec MMSI et numéro de cluster
            marker.bindPopup(`MMSI : ${mmsi}<br>Cluster : ${cluster}`);
        });
    }

    // =====================================
    // CHARGEMENT DES DONNÉES DE CLUSTER
    // =====================================

    fetch("./php/predictType.php") // Appelle le script PHP qui renvoie les données clusterisées
        .then(response => response.json()) // Conversion de la réponse en JSON
        .then(data => {
            console.log("Clusters reçus :", data); // Affichage pour débogage
            afficherBateauxParCluster(data); // Appelle la fonction d’affichage
        })
        .catch(error => {
            console.error("Erreur lors de l'affichage des clusters :", error); // Gestion des erreurs
        });
});
