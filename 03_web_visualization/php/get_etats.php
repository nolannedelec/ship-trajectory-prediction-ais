<?php
// Active l'affichage des erreurs pour le débogage (utile en développement)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Indique que la réponse sera en JSON
header('Content-Type: application/json');

try {
    // Connexion à la base de données avec PDO
    $pdo = new PDO("mysql:host=localhost;dbname=etu0209;charset=utf8", "etu0209", "xxcthgkd");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Requête SQL pour récupérer les statuts avec alias pour correspondre à un format frontend
    $stmt = $pdo->query("SELECT id_statut AS id, nom FROM Statut ORDER BY id_statut ASC");

    // Récupération des résultats sous forme de tableau associatif
    $etats = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Envoi des résultats au format JSON
    echo json_encode($etats);

} catch (PDOException $e) {
    // Gestion d'erreur avec code HTTP 500 et message lisible côté client
    http_response_code(500);
    echo json_encode(['error' => 'Erreur serveur : ' . $e->getMessage()]);
}
?>
