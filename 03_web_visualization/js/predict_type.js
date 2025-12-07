let selectedBoatData = null;

// Chargement des données des bateaux au démarrage
document.addEventListener('DOMContentLoaded', function() {
  loadBoats();
});

// Fonction pour charger les bateaux depuis la base de données
async function loadBoats() {
  try {
    const response = await fetch('php/get_bateaux2.php');
    const boats = await response.json();
   
    displayBoats(boats);
    document.getElementById('boat_count').textContent = boats.length;
  } catch (error) {
    console.error('Erreur lors du chargement des bateaux:', error);
    document.getElementById('boat_count').textContent = '0';
  }
}

// Fonction pour afficher les bateaux dans le tableau
function displayBoats(boats) {
  const tbody = document.getElementById('bateau_tbody');
  tbody.innerHTML = '';

  boats.forEach((boat, index) => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td class="col-select">
        <div class="radio_container">
          <input type="radio" name="boat_selection" value="${index}" onchange="selectBoat(${index}, this)">
        </div>
      </td>
      <td class="col-mmsi">${boat.MMSI || 'N/A'}</td>
      <td class="col-nom">${boat.nom || 'N/A'}</td>
      <td class="col-dimension">${boat.longueur || 'N/A'}m</td>
      <td class="col-dimension">${boat.largeur || 'N/A'}m</td>
      <td class="col-dimension">${boat.tirant_eau || 'N/A'}m</td>
      <td class="col-timestamp">${boat.horodatage || 'N/A'}</td>
    `;
    tbody.appendChild(row);
  });

  // Stocker les données des bateaux globalement
  window.boatsData = boats;
}

// Fonction appelée lors de la sélection d'un bateau
function selectBoat(index, radioElement) {
  if (window.boatsData && window.boatsData[index]) {
    selectedBoatData = window.boatsData[index];
   
    // Mettre à jour l'affichage des informations du bateau avec MMSI
    const infoDiv = document.getElementById('selected_boat_info');
    infoDiv.innerHTML = `
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
        <div><strong>MMSI:</strong> ${selectedBoatData.MMSI || 'N/A'}</div>
        <div><strong>Nom:</strong> ${selectedBoatData.nom || 'N/A'}</div>
        <div><strong>Longueur:</strong> ${selectedBoatData.longueur || 'N/A'}m</div>
        <div><strong>Largeur:</strong> ${selectedBoatData.largeur || 'N/A'}m</div>
        <div><strong>Tirant d'eau:</strong> ${selectedBoatData.tirant_eau || 'N/A'}m</div>

      </div>
    `;

    // Afficher la section d'informations
    document.getElementById('bateau_info').style.display = 'block';
   
    // Masquer les résultats de prédiction précédents
    document.getElementById('prediction_results').style.display = 'none';

    // Mettre en évidence la ligne sélectionnée
    document.querySelectorAll('#bateauTable tbody tr').forEach(row => {
      row.classList.remove('selected');
    });
    radioElement.closest('tr').classList.add('selected');
  }
}

// Fonction pour effacer la sélection
document.getElementById('clear_btn').addEventListener('click', function() {
  selectedBoatData = null;
  document.getElementById('bateau_info').style.display = 'none';
  document.getElementById('prediction_results').style.display = 'none';
 
  // Décocher tous les boutons radio
  document.querySelectorAll('input[name="boat_selection"]').forEach(radio => {
    radio.checked = false;
  });
 
  // Enlever la mise en évidence
  document.querySelectorAll('#bateauTable tbody tr').forEach(row => {
    row.classList.remove('selected');
  });
});

// Fonction pour prédire le type
document.getElementById('predict_btn').addEventListener('click', async function() {
  if (!selectedBoatData) {
    alert('Veuillez sélectionner un bateau d\'abord.');
    return;
  }

  // Afficher un indicateur de chargement
  const resultsDiv = document.getElementById('prediction_results');
  const contentDiv = document.getElementById('prediction_content');
 
  resultsDiv.style.display = 'block';
  contentDiv.innerHTML = '<div style="text-align: center; padding: 20px;">Prédiction en cours...</div>';

  try {
    // Préparer les données pour la prédiction
    const predictionData = {
      status_label: selectedBoatData.id_statut || 0,
      length: parseFloat(selectedBoatData.longueur) || 0,
      width: parseFloat(selectedBoatData.largeur) || 0,
      draft: parseFloat(selectedBoatData.tirant_eau) || 0
    };

    console.log('Données envoyées:', predictionData); // Debug

    // Appel à votre script PHP qui exécute le script Python
    const response = await fetch('php/predict_type.php', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(predictionData)
    });

    const result = await response.json();
    console.log('Résultat reçu:', result); // Debug

    // Afficher les résultats
    if (result.success) {
      let resultHtml = '';
     
      if (result.predictions && Object.keys(result.predictions).length > 0) {
        resultHtml = `
          <div style="background-color: #e8f5e8; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 15px 0; color: #2e7d32;">Résultats des prédictions par modèle</h4>
        `;
       
        // Afficher les prédictions de chaque modèle
        for (const [model, prediction] of Object.entries(result.predictions)) {
          resultHtml += `
            <div style="margin: 8px 0; padding: 12px; background-color: #f8f9fa; border-radius: 6px; border-left: 4px solid #1e88e5;">
              <strong>${model}:</strong> <span style="color: #1e88e5; font-weight: 600;">${prediction}</span>
            </div>
          `;
        }
       
        resultHtml += `</div>`;
      } else if (result.prediction) {
        resultHtml = `
          <div style="background-color: #e8f5e8; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 10px 0; color: #2e7d32;">Résultat de la prédiction</h4>
            <div style="font-size: 16px; font-weight: 600;">
              Type prédit: <span style="color: #1e88e5;">${result.prediction}</span>
            </div>
          </div>
        `;
      } else {
        resultHtml = `
          <div style="background-color: #fff3cd; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 10px 0; color: #856404;">Aucune prédiction disponible</h4>
            <div>Le script a été exécuté mais aucune prédiction n'a été trouvée.</div>
            <details style="margin-top: 10px;">
              <summary>Sortie brute du script</summary>
              <pre style="background: #f8f9fa; padding: 10px; border-radius: 4px; font-size: 12px; overflow-x: auto;">${result.raw_output || 'Aucune sortie'}</pre>
            </details>
          </div>
        `;
      }
     
      resultHtml += `
        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px;">
          <h4 style="margin: 0 0 15px 0;">Données utilisées pour la prédiction</h4>
          <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px;">
            <div><strong>MMSI:</strong> ${selectedBoatData.MMSI || 'N/A'}</div>
            <div><strong>Statut AIS:</strong> ${predictionData.status_label}</div>
            <div><strong>Longueur:</strong> ${predictionData.length}m</div>
            <div><strong>Largeur:</strong> ${predictionData.width}m</div>
            <div><strong>Tirant d'eau:</strong> ${predictionData.draft}m</div>
          </div>
        </div>
      `;
     
      contentDiv.innerHTML = resultHtml;
    } else {
      contentDiv.innerHTML = `
        <div style="background-color: #ffebee; padding: 20px; border-radius: 8px; color: #c62828;">
          <h4 style="margin: 0 0 10px 0;">Erreur lors de la prédiction</h4>
          <p>${result.error || 'Erreur inconnue'}</p>
          ${result.raw_output ? `
            <details style="margin-top: 10px;">
              <summary>Sortie brute du script</summary>
              <pre style="background: #f8f9fa; padding: 10px; border-radius: 4px; font-size: 12px; overflow-x: auto;">${result.raw_output}</pre>
            </details>
          ` : ''}
        </div>
      `;
    }
  } catch (error) {
    console.error('Erreur lors de la prédiction:', error);
    contentDiv.innerHTML = `
      <div style="background-color: #ffebee; padding: 20px; border-radius: 8px; color: #c62828;">
        <h4 style="margin: 0 0 10px 0;">Erreur de communication</h4>
        <p>Impossible de contacter le serveur pour la prédiction.</p>
        <p><strong>Détails:</strong> ${error.message}</p>
      </div>
    `;
  }
});