<?php
// Spécifie que le contenu renvoyé est du JSON
header('Content-Type: application/json');

// === Informations de connexion à la base de données ===
$host = 'localhost';        // Hôte de la base de données (local dans ce cas)
$dbname = 'etu0209';        // Nom de la base de données
$user = 'etu0209';          // Nom d'utilisateur
$password = 'xxcthgkd';     // Mot de passe

// === Connexion à la base de données via PDO ===
try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $password);
} catch (PDOException $e) {
    // En cas d'erreur de connexion, on renvoie un message JSON et on arrête le script
    echo json_encode(['error' => 'Connexion échouée : ' . $e->getMessage()]);
    exit();
}

// === Requête SQL ===
// Objectif : récupérer la dernière position de chaque bateau identifié par son MMSI
$sql = "SELECT MMSI, nom, longueur, largeur, tirant_eau, latitude, longitude, SOG, COG, cap_reel, horodatage,
               (SELECT COUNT(*) FROM Bateaux b2 WHERE b2.MMSI = b1.MMSI) as nb_positions
        FROM Bateaux b1
        WHERE horodatage = (
            SELECT MAX(horodatage)
            FROM Bateaux b2
            WHERE b2.MMSI = b1.MMSI
        )
        ORDER BY MMSI";

// Exécution de la requête SQL
$stmt = $pdo->query($sql);

// Récupération des résultats sous forme de tableau associatif
$bateaux = $stmt->fetchAll(PDO::FETCH_ASSOC);

// === Formatage des données ===
// Objectif : arrondir les valeurs numériques à un format lisible
foreach ($bateaux as &$bateau) {
    $bateau['latitude'] = number_format((float)$bateau['latitude'], 6, '.', '');     // 6 décimales
    $bateau['longitude'] = number_format((float)$bateau['longitude'], 6, '.', '');   // 6 décimales
    $bateau['SOG'] = number_format((float)$bateau['SOG'], 1, '.', '');               // 1 décimale
    $bateau['COG'] = number_format((float)$bateau['COG'], 1, '.', '');               // 1 décimale
    $bateau['cap_reel'] = number_format((float)$bateau['cap_reel'], 1, '.', '');     // 1 décimale
}

// === Retour des données au format JSON ===
echo json_encode($bateaux);
?>
