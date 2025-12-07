<?php
// Indique que la réponse sera au format JSON
header('Content-Type: application/json');

try {
    // Connexion à la base de données avec PDO
    $pdo = new PDO("mysql:host=localhost;dbname=etu0209;charset=utf8", "etu0209", "xxcthgkd");
    
    // Active le mode d'affichage des erreurs sous forme d'exceptions
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Requête SQL : on sélectionne les champs nécessaires avec des alias pour correspondre aux noms attendus côté JS
    $stmt = $pdo->query("SELECT mmsi, nom, sog, longueur AS length, largeur AS width, tirant_eau AS draft FROM Bateaux ORDER BY nom");

    // Récupération des résultats sous forme de tableau associatif
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Encodage et envoi des données au format JSON
    echo json_encode($result);

} catch (PDOException $e) {
    // En cas d'erreur de connexion ou de requête : code 500 + message d'erreur JSON
    http_response_code(500);
    echo json_encode(["error" => "Erreur serveur : " . $e->getMessage()]);
}
?>
