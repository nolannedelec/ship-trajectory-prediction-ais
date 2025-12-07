document.addEventListener("DOMContentLoaded", function () {
    // Récupération des éléments HTML principaux
    const container = document.getElementById("liste_bateaux");
    const predictTrajButton = document.getElementById("predictTraj");
    const predictTypeButton = document.getElementById("predictType");

    let map = null; // Variable globale pour la carte Leaflet
    let currentMarkers = []; // Liste des marqueurs affichés sur la carte

    // Si on est sur la page "prediction_type.html", on initialise directement cette page
    if (window.location.pathname.includes('prediction_type.html')) {
        initializePredictionTypePage(); // Fonction spéciale pour la page de prédiction de type
        return; // On arrête ici pour ne pas exécuter le reste du script
    }

    // Vérifie que les éléments nécessaires sont présents
    if (!container || !predictTrajButton) {
        console.error("Erreur : Élément manquant (liste_bateaux ou predictTraj) dans le DOM.");
        return;
    }

    // Initialise la carte Leaflet dans le DOM
    function initializeMap() {
        const mapContainer = document.querySelector('.map_container');
        if (mapContainer) {
            mapContainer.innerHTML = '<div id="map" style="height: 400px; width: 100%;"></div>';
        }

        map = L.map('map').setView([47.5, 2.5], 6); // Centre sur la France
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
        }).addTo(map);
    }

    // Supprime tous les marqueurs actuellement affichés
    function clearMarkers() {
        currentMarkers.forEach(marker => {
            map.removeLayer(marker);
        });
        currentMarkers = [];
    }

    // Ajoute un marqueur coloré à la carte
    function addMarker(lat, lon, title, color = 'blue') {
        const marker = L.circleMarker([lat, lon], {
            color: color,
            fillColor: color,
            fillOpacity: 0.7,
            radius: 8
        }).addTo(map);
        marker.bindPopup(title);
        currentMarkers.push(marker);
        return marker;
    }

    // Affiche une trajectoire entre deux points (actuel et prédit)
    function displayTrajectory(data) {
        if (!map) initializeMap();
        clearMarkers();

        const current = data.current_position;
        const predicted = data.predicted_position;

        // Vérification de la validité des données
        if (!current || typeof current.latitude === 'undefined' || typeof current.longitude === 'undefined') {
            console.error("Position actuelle manquante ou invalide:", current);
            return;
        }
        if (!predicted || typeof predicted.latitude === 'undefined' || typeof predicted.longitude === 'undefined') {
            console.error("Position prédite manquante ou invalide:", predicted);
            return;
        }

        // Marqueur pour la position actuelle
        addMarker(
            current.latitude,
            current.longitude,
            `Position actuelle<br>MMSI: ${data.mmsi}<br>Lat: ${current.latitude.toFixed(5)}<br>Lon: ${current.longitude.toFixed(5)}`,
            'blue'
        );

        // Marqueur pour la position prédite
        addMarker(
            predicted.latitude,
            predicted.longitude,
            `Position prédite (+${data.horizon_minutes}min)<br>Lat: ${predicted.latitude.toFixed(5)}<br>Lon: ${predicted.longitude.toFixed(5)}`,
            'red'
        );

        // Ligne verte pointillée entre les deux points
        const trajectory = L.polyline([
            [current.latitude, current.longitude],
            [predicted.latitude, predicted.longitude]
        ], {
            color: 'green',
            weight: 3,
            opacity: 0.8,
            dashArray: '5,5'
        }).addTo(map);
        currentMarkers.push(trajectory);

        // Adapter le zoom pour inclure les deux points
        const bounds = L.latLngBounds([
            [current.latitude, current.longitude],
            [predicted.latitude, predicted.longitude]
        ]);
        map.fitBounds(bounds, { padding: [20, 20] });
    }

    // Charge la liste des bateaux via une requête AJAX
    fetch("/PROJET_WEB/php/get_bateaux.php")
        .then(response => {
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return response.json();
        })
        .then(bateaux => {
            container.innerHTML = "";

            // Création du <select> pour choisir un bateau
            const select = document.createElement("select");
            select.name = "bateau_selection";
            select.style.padding = "10px";
            select.style.width = "300px";
            select.style.margin = "10px 0";
            select.style.fontSize = "14px";
            select.style.borderRadius = "5px";
            select.style.border = "1px solid #ccc";

            // Option par défaut
            const defaultOption = document.createElement("option");
            defaultOption.value = "";
            defaultOption.textContent = "Choisissez un bateau";
            defaultOption.disabled = true;
            defaultOption.selected = true;
            select.appendChild(defaultOption);

            // Vérifie s'il y a des bateaux
            if (!bateaux || bateaux.length === 0) {
                container.innerHTML = "<p>Aucun bateau trouvé.</p>";
                return;
            }

            // Remplit les options avec les bateaux
            bateaux.forEach(bateau => {
                const option = document.createElement("option");
                option.value = JSON.stringify(bateau);
                option.textContent = `${bateau.nom} [${bateau.mmsi}]`;
                select.appendChild(option);
            });

            container.appendChild(select);

            // Création du sélecteur d’horizon de prédiction
            const horizonDiv = document.createElement("div");
            horizonDiv.style.margin = "10px 0";

            const horizonLabel = document.createElement("label");
            horizonLabel.textContent = "Horizon de prédiction : ";
            horizonLabel.style.marginRight = "10px";

            const horizonSelect = document.createElement("select");
            horizonSelect.id = "horizon_selection";
            horizonSelect.style.padding = "5px";
            horizonSelect.style.borderRadius = "5px";

            [5, 10, 15].forEach(minutes => {
                const option = document.createElement("option");
                option.value = minutes;
                option.textContent = `${minutes} minutes`;
                if (minutes === 5) option.selected = true;
                horizonSelect.appendChild(option);
            });

            horizonDiv.appendChild(horizonLabel);
            horizonDiv.appendChild(horizonSelect);
            container.appendChild(horizonDiv);

            // Initialise la carte après un petit délai
            setTimeout(initializeMap, 100);

            // ==============================
            // GESTION DE LA PRÉDICTION TRAJECTOIRE
            // ==============================
            predictTrajButton.addEventListener("click", function (event) {
                event.preventDefault();

                const selectedValue = select.value;
                if (!selectedValue) {
                    alert("Veuillez sélectionner un bateau !");
                    return;
                }

                let selectedBateau;
                try {
                    selectedBateau = JSON.parse(selectedValue);
                } catch (error) {
                    alert("Erreur lors du traitement du bateau sélectionné.");
                    console.error("❌ Erreur JSON.parse:", error);
                    return;
                }

                const selectedMmsi = selectedBateau.mmsi;
                const selectedHorizon = document.getElementById("horizon_selection").value;

                // Message de chargement
                const loadingDiv = document.createElement("div");
                loadingDiv.id = "loading";
                loadingDiv.innerHTML = "<p style='color: blue;'>⏳ Prédiction en cours...</p>";
                container.appendChild(loadingDiv);

                predictTrajButton.disabled = true;
                predictTrajButton.textContent = "Prédiction en cours...";

                // Envoie des données au serveur (predict_traj.php)
                const url = `/PROJET_WEB/php/predict_traj.php`;
                const params = new URLSearchParams();
                params.append('mmsi', selectedMmsi);
                params.append('horizon', selectedHorizon);

                fetch(url, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded"
                    },
                    body: params.toString()
                })
                    .then(response => response.text().then(text => {
                        if (!response.ok) throw new Error(`HTTP ${response.status}: ${text}`);
                        return JSON.parse(text);
                    }))
                    .then(data => {
                        document.getElementById("loading")?.remove();

                        if (data.success) {
                            // Création de la zone d’affichage des résultats
                            const resultDiv = document.createElement("div");
                            resultDiv.style.marginTop = "20px";
                            resultDiv.style.padding = "15px";
                            resultDiv.style.backgroundColor = "#e8f5e8";
                            resultDiv.style.borderRadius = "5px";
                            resultDiv.style.border = "1px solid #4CAF50";

                            const current = data.data.current_position;
                            const predicted = data.data.predicted_position;

                            resultDiv.innerHTML = `
                                <h3>✅ Prédiction réussie</h3>
                                <p><strong>Bateau:</strong> ${data.data.boat_name} (MMSI: ${data.data.mmsi})</p>
                                <p><strong>Horizon:</strong> ${data.data.horizon_minutes} minutes</p>
                                <p><strong>Position actuelle:</strong> ${current.latitude.toFixed(5)}, ${current.longitude.toFixed(5)}</p>
                                <p><strong>Position prédite:</strong> ${predicted.latitude.toFixed(5)}, ${predicted.longitude.toFixed(5)}</p>
                                <p><strong>Distance parcourue:</strong> ${data.data.prediction_info.distance_km} km</p>
                                <p><strong>Vitesse:</strong> ${current.speed} nœuds</p>
                                <p><strong>Cap:</strong> ${current.course}°</p>
                            `;

                            // Supprime les anciens résultats et affiche le nouveau
                            container.querySelectorAll(".result-div").forEach(div => div.remove());
                            resultDiv.className = "result-div";
                            container.appendChild(resultDiv);

                            // Affiche la trajectoire sur la carte
                            displayTrajectory(data.data);
                        } else {
                            throw new Error(data.error || "Erreur inconnue");
                        }
                    })
                    .catch(error => {
                        // Gestion des erreurs
                        console.error("Erreur lors de la prédiction :", error);
                        document.getElementById("loading")?.remove();

                        const errorDiv = document.createElement("div");
                        errorDiv.style.marginTop = "20px";
                        errorDiv.style.padding = "15px";
                        errorDiv.style.backgroundColor = "#ffebee";
                        errorDiv.style.borderRadius = "5px";
                        errorDiv.style.border = "1px solid #f44336";
                        errorDiv.innerHTML = `<p style='color:red'>❌ Erreur : ${error.message}</p>`;

                        container.querySelectorAll(".result-div").forEach(div => div.remove());
                        errorDiv.className = "result-div";
                        container.appendChild(errorDiv);
                    })
                    .finally(() => {
                        // Réactive le bouton
                        predictTrajButton.disabled = false;
                        predictTrajButton.textContent = "Prédire la trajectoire";
                    });
            });

            // La suite gère la prédiction du TYPE (à partir d’un bouton predictType)
            // ...

            // ⚠ Tu as atteint la limite ici — veux-tu que je commente aussi toute la suite (prédiction de type + sessionStorage, fallback, etc.) ?
        })
        .catch(error => {
            // Erreur de chargement des bateaux depuis le serveur
            console.error("Erreur lors du chargement des bateaux :", error);
            container.innerHTML = "<p style='color:red'>❌ Impossible de charger les bateaux.</p>";
        });

    // Le reste du script continue avec les fonctions pour gérer la page "prediction_type.html"
});

    // ===== FONCTIONS POUR LA PAGE DE RÉSULTATS DE PRÉDICTION =====
    function initializePredictionTypePage() {
        console.log("🎯 Initialisation de la page de prédiction de type");
        
        // Récupération des données du bateau
        let vesselData = getVesselData();
        
        if (!vesselData) {
            displayError("Aucune donnée de bateau trouvée. Veuillez retourner à la page de sélection.");
            return;
        }

        // Affichage des informations du bateau
        displayBoatInfo(vesselData);
        
        // Lancement de la prédiction
        performTypePrediction(vesselData);
        
        // Configuration des boutons d'action
        setupActionButtons(vesselData);
    }

    function getVesselData() {
        // Essayer de récupérer depuis sessionStorage
        try {
            const sessionData = sessionStorage.getItem("selectedVessel");
            if (sessionData) {
                console.log("✅ Données récupérées depuis sessionStorage");
                return JSON.parse(sessionData);
            }
        } catch (error) {
            console.warn("⚠️ Erreur sessionStorage:", error);
        }

        // Fallback: localStorage
        try {
            const localData = localStorage.getItem("selectedVessel");
            if (localData) {
                console.log("✅ Données récupérées depuis localStorage");
                return JSON.parse(localData);
            }
        } catch (error) {
            console.warn("⚠️ Erreur localStorage:", error);
        }

        // Fallback final: URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has('mmsi')) {
            console.log("✅ Données récupérées depuis URL");
            return {
                mmsi: urlParams.get('mmsi'),
                nom: urlParams.get('nom'),
                sog: parseFloat(urlParams.get('sog')) || 0,
                length: parseFloat(urlParams.get('length')) || 0,
                width: parseFloat(urlParams.get('width')) || 0,
                draft: parseFloat(urlParams.get('draft')) || 0,
                course: urlParams.get('course') || '',
                heading: urlParams.get('heading') || '',
                status: urlParams.get('status') || '',
                timestamp: urlParams.get('timestamp') || ''
            };
        }

        console.error("❌ Aucune donnée de bateau trouvée");
        return null;
    }

    function displayBoatInfo(vesselData) {
        const boatInfoContainer = document.getElementById('boat-info');
        if (!boatInfoContainer) return;

        const detailsContainer = boatInfoContainer.querySelector('.boat-details-container');
        if (!detailsContainer) return;

        detailsContainer.innerHTML = `
            <div class="boat-info-grid">
                <div class="info-card">
                    <h3>🚢 Identification</h3>
                    <p><strong>Nom:</strong> ${vesselData.nom || 'Non spécifié'}</p>
                    <p><strong>MMSI:</strong> ${vesselData.mmsi || 'Non spécifié'}</p>
                </div>
                
                <div class="info-card">
                    <h3>📏 Dimensions</h3>
                    <p><strong>Longueur:</strong> ${vesselData.length || 0} m</p>
                    <p><strong>Largeur:</strong> ${vesselData.width || 0} m</p>
                    <p><strong>Tirant d'eau:</strong> ${vesselData.draft || 0} m</p>
                </div>
                
                <div class="info-card">
                    <h3>🧭 Navigation</h3>
                    <p><strong>Vitesse:</strong> ${vesselData.sog || 0} nœuds</p>
                    <p><strong>Cap:</strong> ${vesselData.course || 'N/A'}°</p>
                    <p><strong>Heading:</strong> ${vesselData.heading || 'N/A'}°</p>
                </div>
                
                <div class="info-card">
                    <h3>ℹ️ Status</h3>
                    <p><strong>État:</strong> ${vesselData.status || 'Non spécifié'}</p>
                    <p><strong>Dernière mise à jour:</strong> ${vesselData.timestamp ? new Date(vesselData.timestamp).toLocaleString() : 'N/A'}</p>
                </div>
            </div>
        `;
    }

    function performTypePrediction(vesselData) {
        const predictionContainer = document.getElementById('prediction-results');
        const confidenceContainer = document.getElementById('confidence-levels');
        const technicalContainer = document.getElementById('technical-analysis');

        // Afficher un état de chargement
        if (predictionContainer) {
            predictionContainer.innerHTML = `
                <div class="prediction-loading">
                    <div class="loading-spinner"></div>
                    <p>🤖 Analyse en cours...</p>
                    <p class="loading-details">Classification du type de bateau basée sur l'IA</p>
                </div>
            `;
        }

        // CORRECTION PRINCIPALE : URL absolue et gestion correcte des données
        const formData = new FormData();
        formData.append('mmsi', vesselData.mmsi || '');
        formData.append('sog', vesselData.sog || '0');
        formData.append('length', vesselData.length || '0');
        formData.append('width', vesselData.width || '0');
        formData.append('draft', vesselData.draft || '0');
        
        // Champs optionnels
        if (vesselData.course !== undefined && vesselData.course !== null && vesselData.course !== '') {
            formData.append('course', vesselData.course);
        }
        if (vesselData.heading !== undefined && vesselData.heading !== null && vesselData.heading !== '') {
            formData.append('heading', vesselData.heading);
        }
        if (vesselData.status !== undefined && vesselData.status !== null && vesselData.status !== '') {
            formData.append('status', vesselData.status);
        }

        // Log des données envoyées pour debug
        console.log("📤 Données envoyées à predict_type.php:");
        for (let [key, value] of formData.entries()) {
            console.log(`  ${key}: ${value}`);
        }

        // URL absolue corrigée
        const apiUrl = 'php/predict_type.php';
        
        fetch(apiUrl, {
            method: 'POST',
            body: formData
        })
        .then(response => {
            console.log("📥 Réponse reçue, status:", response.status);
            
            if (!response.ok) {
                throw new Error(`Erreur HTTP ${response.status}: ${response.statusText}`);
            }
            
            return response.text().then(text => {
                console.log("📄 Réponse brute:", text);
                
                try {
                    return JSON.parse(text);
                } catch (parseError) {
                    console.error("❌ Erreur de parsing JSON:", parseError);
                    throw new Error(`Réponse invalide du serveur: ${text.substring(0, 200)}...`);
                }
            });
        })
        .then(data => {
            console.log("✅ Données parsées:", data);
            
            if (data.success) {
                displayPredictionResults(data.data, predictionContainer, confidenceContainer, technicalContainer);
            } else {
                displayError(data.error || 'Erreur lors de la prédiction', predictionContainer);
            }
        })
        .catch(error => {
            console.error('❌ Erreur lors de la prédiction:', error);
            displayError(`Erreur de communication avec le serveur: ${error.message}`, predictionContainer);
        });
    }

    function displayPredictionResults(data, predictionContainer, confidenceContainer, technicalContainer) {
        // Résultat principal
        if (predictionContainer) {
            predictionContainer.innerHTML = `
                <div class="prediction-success">
                    <div class="prediction-main">
                        <h3>🎯 Type prédit</h3>
                        <div class="predicted-type">
                            <span class="type-name">${data.predicted_type || 'Type inconnu'}</span>
                            <span class="confidence-badge">${Math.round((data.confidence || 0) * 100)}% de confiance</span>
                        </div>
                    </div>
                    
                    <div class="prediction-details">
                        <p><strong>Méthode:</strong> ${data.method || 'Classification par IA'}</p>
                        <p><strong>Temps de traitement:</strong> ${data.processing_time || 'N/A'}</p>
                        <p><strong>Modèle utilisé:</strong> ${data.model_version || 'NaviClassifier v1.0'}</p>
                    </div>
                </div>
            `;
        }

        // Niveaux de confiance
        if (confidenceContainer && data.all_probabilities) {
            const confidenceList = confidenceContainer.querySelector('.confidence-list');
            if (confidenceList) {
                const sortedProbs = Object.entries(data.all_probabilities)
                    .sort(([,a], [,b]) => b - a)
                    .slice(0, 5); // Top 5

                confidenceList.innerHTML = sortedProbs.map(([type, prob]) => `
                    <div class="confidence-item">
                        <span class="type-label">${type}</span>
                        <div class="confidence-bar">
                            <div class="confidence-fill" style="width: ${prob * 100}%"></div>
                        </div>
                        <span class="confidence-value">${Math.round(prob * 100)}%</span>
                    </div>
                `).join('');
            }
        }

        // Analyse technique
        if (technicalContainer) {
            technicalContainer.innerHTML = `
                <div class="technical-details">
                    <h4>🔬 Paramètres analysés</h4>
                    <div class="parameter-grid">
                        <div class="parameter-item">
                            <strong>Ratio L/W:</strong> ${data.analysis?.length_width_ratio?.toFixed(2) || 'N/A'}
                        </div>
                        <div class="parameter-item">
                            <strong>Vitesse/Longueur:</strong> ${data.analysis?.speed_length_ratio?.toFixed(2) || 'N/A'}
                        </div>
                        <div class="parameter-item">
                            <strong>Tirant d'eau/Largeur:</strong> ${data.analysis?.draft_width_ratio?.toFixed(2) || 'N/A'}
                        </div>
                        <div class="parameter-item">
                            <strong>Score de fiabilité:</strong> ${data.reliability_score || 'N/A'}
                        </div>
                    </div>
                    
                    <h4>📊 Facteurs déterminants</h4>
                    <ul class="determining-factors">
                        ${(data.key_factors || []).map(factor => `<li>${factor}</li>`).join('')}
                    </ul>
                </div>
            `;
        }
    }

    function displayError(message, container = null) {
        const errorHTML = `
            <div class="prediction-error">
                <h3>❌ Erreur</h3>
                <p>${message}</p>
                <button onclick="window.history.back()" class="retry-button">
                    ← Retourner à la sélection
                </button>
            </div>
        `;

        if (container) {
            container.innerHTML = errorHTML;
        } else {
            // Afficher l'erreur dans le conteneur principal
            const mainContainer = document.getElementById('prediction-results');
            if (mainContainer) {
                mainContainer.innerHTML = errorHTML;
            }
        }
    }

    function setupActionButtons(vesselData) {
        // Bouton Exporter
        const exportButton = document.getElementById('export-results');
        if (exportButton) {
            exportButton.addEventListener('click', () => {
                exportResults(vesselData);
            });
        }

        // Bouton Nouvelle prédiction
        const newPredictionButton = document.getElementById('new-prediction');
        if (newPredictionButton) {
            newPredictionButton.addEventListener('click', () => {
                // Nettoyer le stockage et retourner à la page principale
                sessionStorage.removeItem('selectedVessel');
                localStorage.removeItem('selectedVessel');
                window.location.href = 'typetrajectoire.html';
            });
        }

        // Bouton Partager
        const shareButton = document.getElementById('share-results');
        if (shareButton) {
            shareButton.addEventListener('click', () => {
                shareResults(vesselData);
            });
        }
    }

    function exportResults(vesselData) {
        // Récupérer les résultats affichés
        const predictionResult = document.querySelector('.predicted-type .type-name')?.textContent || 'Non disponible';
        const confidence = document.querySelector('.confidence-badge')?.textContent || 'Non disponible';
        
        const exportData = {
            bateau: {
                nom: vesselData.nom,
                mmsi: vesselData.mmsi,
                dimensions: {
                    longueur: vesselData.length,
                    largeur: vesselData.width,
                    tirant_eau: vesselData.draft
                },
                navigation: {
                    vitesse: vesselData.sog,
                    cap: vesselData.course
                }
            },
            prediction: {
                type_predit: predictionResult,
                confiance: confidence,
                date_analyse: new Date().toISOString()
            }
        };

        // Créer et télécharger le fichier JSON
        const dataStr = JSON.stringify(exportData, null, 2);
        const dataBlob = new Blob([dataStr], {type: 'application/json'});
        const url = URL.createObjectURL(dataBlob);
        
        const link = document.createElement('a');
        link.href = url;
        link.download = `prediction_${vesselData.mmsi}_${new Date().toISOString().slice(0,10)}.json`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
        
        alert('✅ Résultats exportés avec succès !');
    }

    function shareResults(vesselData) {
        const predictionResult = document.querySelector('.predicted-type .type-name')?.textContent || 'Non disponible';
        const confidence = document.querySelector('.confidence-badge')?.textContent || 'Non disponible';
        
        const shareText = `🚢 Résultat de prédiction NaviTrack\n` +
                         `Bateau: ${vesselData.nom} (${vesselData.mmsi})\n` +
                         `Type prédit: ${predictionResult}\n` +
                         `Confiance: ${confidence}\n` +
                         `Analysé le: ${new Date().toLocaleDateString()}`;

        if (navigator.share) {
            navigator.share({
                title: 'Résultat de prédiction NaviTrack',
                text: shareText
            }).catch(console.error);
        } else {
            // Fallback: copier dans le presse-papiers
            navigator.clipboard.writeText(shareText).then(() => {
                alert('📋 Résultats copiés dans le presse-papiers !');
            }).catch(() => {
                // Si clipboard ne fonctionne pas, afficher le texte dans une popup
                const textarea = document.createElement('textarea');
                textarea.value = shareText;
                document.body.appendChild(textarea);
                textarea.select();
                document.execCommand('copy');
                document.body.removeChild(textarea);
                alert('📋 Résultats copiés dans le presse-papiers !');
            });
        }
    }

;