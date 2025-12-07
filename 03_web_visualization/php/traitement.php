<?php
// Indique que la réponse sera en JSON
header('Content-Type: application/json');

// Active l'affichage des erreurs pour le débogage
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

try {
    // Connexion à la base de données avec PDO
    $pdo = new PDO("mysql:host=localhost;dbname=etu0209;charset=utf8", "etu0209", "xxcthgkd");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Log des données reçues (POST) pour débogage serveur
    error_log("Données reçues : " . print_r($_POST, true));

    // Récupération des données du formulaire, avec valeur par défaut null
    $data = [
        'nom' => $_POST['fnavire_name'] ?? null,
        'etat' => $_POST['fnavire_state'] ?? null,
        'mmsi' => $_POST['fnavire_mmsi'] ?? null,
        'length' => $_POST['fnavire_length'] ?? null,
        'width' => $_POST['fnavire_width'] ?? null,
        'draft' => $_POST['fnavire_draft'] ?? null,
        'horodatage' => $_POST['fnavire_hour'] ?? null,
        'lat' => $_POST['fnavire_lat'] ?? null,
        'lon' => $_POST['fnavire_lon'] ?? null,
        'cog' => $_POST['fnavire_COG'] ?? null,
        'cap_reel' => $_POST['fnavire_heading'] ?? null,
        'sog' => $_POST['fnavire_sog'] ?? null,
    ];

    // Log des données préparées avant insertion
    error_log("Données préparées : " . print_r($data, true));

    // Liste des champs obligatoires
    $required_fields = ['nom', 'etat', 'mmsi', 'length', 'width', 'draft', 'horodatage', 'lat', 'lon', 'sog', 'cog', 'cap_reel'];
    $missing_fields = [];

    // Vérifie que tous les champs requis sont bien renseignés
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || trim($data[$field]) === '') {
            $missing_fields[] = $field;
        }
    }

    // Vérifie que l’état est bien un ID numérique valide entre 1 et 15
    if (!isset($data['etat']) || !is_numeric($data['etat']) || $data['etat'] < 1 || $data['etat'] > 15) {
        if (!in_array('etat', $missing_fields)) {
            $missing_fields[] = 'etat';
        }
    }

    // Vérifie que le MMSI est exactement un nombre à 9 chiffres
    if (!preg_match('/^\d{9}$/', $data['mmsi'])) {
        $missing_fields[] = 'mmsi';
    }

    // S’il manque des champs, une erreur est renvoyée
    if (!empty($missing_fields)) {
        throw new Exception("Les champs suivants sont requis ou invalides : " . implode(', ', $missing_fields));
    }

    // Requête SQL d’insertion dans la table Bateaux
    $sql = "INSERT INTO Bateaux (mmsi, nom, id_statut, longueur, largeur, tirant_eau, horodatage, latitude, longitude, sog, cog, cap_reel)
            VALUES (:mmsi, :nom, :etat, :length, :width, :draft, :horodatage, :lat, :lon, :sog, :cog, :cap_reel)";
    $stmt = $pdo->prepare($sql);

    // Log de la requête SQL (pour vérification dans les logs)
    error_log("Requête SQL : " . $sql);

    // Démarre une transaction (meilleure sécurité)
    $pdo->beginTransaction();
    $stmt->execute($data); // Exécute la requête préparée avec les données
    $pdo->commit(); // Valide la transaction

    // Réponse JSON de succès
    echo json_encode(['success' => true, 'message' => 'Bateau ajouté avec succès']);

} catch (PDOException $e) {
    // En cas d'erreur PDO (base de données), annule la transaction
    $pdo->rollBack();
    http_response_code(500); // Erreur serveur
    error_log("PDOException : " . $e->getMessage()); // Log de l’erreur technique
    echo json_encode(['success' => false, 'error' => 'Erreur serveur : ' . $e->getMessage()]);

} catch (Exception $e) {
    // Autres erreurs (validation, champs manquants, etc.)
    http_response_code(400); // Erreur côté client
    error_log("Exception : " . $e->getMessage()); // Log de l’erreur
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
