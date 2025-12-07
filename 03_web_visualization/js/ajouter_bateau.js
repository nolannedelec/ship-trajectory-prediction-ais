document.addEventListener("DOMContentLoaded", function () {
  // Récupère l'élément <select> contenant les états des navires
  const select = document.getElementById("fnavire_state");
  // Récupère le formulaire d'ajout de bateau
  const form = document.getElementById("boatForm");
  // Récupère l'élément où afficher les messages (succès/erreur)
  const messageDiv = document.getElementById("message");

  // Vérifie que les éléments HTML attendus existent
  if (!select) {
    console.error("Élément select (fnavire_state) non trouvé");
    return;
  }
  if (!form) {
    console.error("Élément form (boatForm) non trouvé");
    return;
  }
  if (!messageDiv) {
    console.error("Élément messageDiv non trouvé");
    return;
  }

  // Envoie une requête pour charger dynamiquement les états depuis le serveur
  fetch("php/get_etats.php")
    .then(response => response.json()) // Convertit la réponse en JSON
    .then(data => {
      // Ajoute un premier choix désactivé par défaut
      select.innerHTML = '<option value="" disabled selected>Choisissez un état</option>';
      // Pour chaque état reçu, créer une option dans le menu déroulant
      data.forEach(etat => {
        const option = document.createElement("option");
        option.value = etat.id; // valeur de l'option = id de l'état
        option.textContent = `${etat.nom} [${etat.id}]`; // texte affiché dans l'option
        select.appendChild(option); // ajoute l'option au <select>
      });
    })
    .catch(error => {
      // En cas d’erreur lors du chargement, affiche un message d'erreur dans le select
      console.error("Erreur lors du chargement des états :", error);
      select.innerHTML = '<option value="" disabled selected>⚠ Impossible de charger les états</option>';
    });

  // Ajoute un écouteur d'événement sur la soumission du formulaire
  form.addEventListener("submit", function (event) {
    event.preventDefault(); // Empêche le rechargement de la page

    const formData = new FormData(form); // Récupère les données du formulaire
    console.log("Données envoyées :", Object.fromEntries(formData)); // Affiche les données pour débogage

    // Envoie les données du formulaire au serveur via une requête POST
    fetch("php/traitement.php", {
      method: "POST",
      body: formData
    })
    .then(response => {
      // Vérifie si la réponse HTTP est correcte
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json(); // Convertit la réponse en JSON
    })
    .then(data => {
      // Si la réponse indique un succès, affiche un message vert et réinitialise le formulaire
      if (data.success) {
        messageDiv.innerHTML = '<p style="color: green;">Bateau ajouté avec succès !</p>';
        form.reset(); // Réinitialise les champs du formulaire
      } else {
        // Sinon, affiche une erreur personnalisée
        throw new Error(data.error || "Erreur inconnue");
      }
    })
    .catch(error => {
      // En cas d’erreur (réseau ou application), affiche un message rouge
      console.error("Erreur lors de l'ajout :", error);
      messageDiv.innerHTML = '<p style="color: red;"> ' + (error.message || 'Erreur lors de l\'ajout du bateau') + '</p>';
    });
  });
});
