<?php
// Indique que la réponse du script sera au format JSON
header('Content-Type: application/json');

// ---------- Connexion à la base de données ----------

// Définition des paramètres de connexion
$host = 'localhost';
$dbname = 'etu0209';
$user = 'etu0209';
$password = 'xxcthgkd';

try {
    // Création de la connexion PDO à la base de données
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $password);
} catch (PDOException $e) {
    // En cas d'erreur de connexion, retour d'un message d'erreur JSON
    echo json_encode(['error' => 'Connexion échouée : ' . $e->getMessage()]);
    exit(); // On arrête le script
}

// ---------- Vérification du paramètre MMSI ----------

// Vérifie si un MMSI est bien passé en paramètre dans l'URL (via GET)
if (!isset($_GET['mmsi']) || empty($_GET['mmsi'])) {
    // Si absent ou vide, renvoie une erreur JSON
    echo json_encode(['error' => 'MMSI manquant']);
    exit(); // On arrête le script
}

// Récupère le MMSI depuis les paramètres GET
$mmsi = $_GET['mmsi'];

// ---------- Requête SQL pour récupérer la trajectoire ----------

// Préparation de la requête SQL pour récupérer toutes les positions d’un bateau donné (MMSI)
// Les données sont triées par ordre chronologique (ASC)
$sql = "SELECT MMSI, nom, longueur, largeur, tirant_eau, latitude, longitude, SOG, COG, cap_reel, horodatage
        FROM Bateaux 
        WHERE MMSI = :mmsi 
        ORDER BY horodatage ASC";

// Préparation de la requête avec un paramètre sécurisé (évite les injections SQL)
$stmt = $pdo->prepare($sql);

// Association du paramètre :mmsi à la valeur du MMSI passée dans l’URL
$stmt->bindParam(':mmsi', $mmsi, PDO::PARAM_STR);

// Exécution de la requête
$stmt->execute();

// Récupération de toutes les lignes de résultat sous forme de tableau associatif
$trajectoire = $stmt->fetchAll(PDO::FETCH_ASSOC);

// ---------- Vérification de la présence de données ----------

// Si aucune position n'est trouvée, on retourne une erreur
if (empty($trajectoire)) {
    echo json_encode(['error' => 'Aucune trajectoire trouvée pour ce MMSI']);
    exit(); // On arrête le script
}

// ---------- Formatage des données ----------

// Pour chaque point de la trajectoire, on formate les données numériques
foreach ($trajectoire as &$point) {
    // Latitude et longitude : 6 décimales
    $point['latitude'] = number_format((float)$point['latitude'], 6, '.', '');
    $point['longitude'] = number_format((float)$point['longitude'], 6, '.', '');
    
    // Vitesse (SOG), Cap (COG), Cap réel : 1 décimale
    $point['SOG'] = number_format((float)$point['SOG'], 1, '.', '');
    $point['COG'] = number_format((float)$point['COG'], 1, '.', '');
    $point['cap_reel'] = number_format((float)$point['cap_reel'], 1, '.', '');
}

// ---------- Envoi de la réponse JSON ----------

// Encode les données de la trajectoire en JSON et les envoie au client
echo json_encode($trajectoire);
?>
