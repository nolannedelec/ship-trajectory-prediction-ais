<?php
// Active l'affichage des erreurs pour le développement (à désactiver en production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Indique que la réponse sera du type JSON
header('Content-Type: application/json');

// Autorise les requêtes CORS depuis n'importe quelle origine (utile pour les appels front-end)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Vérifie si la méthode HTTP utilisée est POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    // Récupère les données JSON brutes envoyées dans le corps de la requête
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Vérifie que les paramètres essentiels sont bien présents
    if (!$input || !isset($input['latitude']) || !isset($input['longitude']) || !isset($input['sog']) || !isset($input['cog'])) {
        http_response_code(400); // Mauvaise requête
        echo json_encode([
            'error' => 'Paramètres manquants (latitude, longitude, sog, cog requis)',
            'received' => $input // Retourne les données reçues pour aider au debug
        ]);
        exit;
    }

    // Convertit les valeurs reçues en nombres flottants
    $latitude = floatval($input['latitude']);
    $longitude = floatval($input['longitude']);
    $sog = floatval($input['sog']);
    $cog = floatval($input['cog']);

    // ---------- Validations des valeurs reçues ----------

    if ($latitude < -90 || $latitude > 90) {
        http_response_code(400);
        echo json_encode(['error' => 'Latitude invalide: ' . $latitude]);
        exit;
    }

    if ($longitude < -180 || $longitude > 180) {
        http_response_code(400);
        echo json_encode(['error' => 'Longitude invalide: ' . $longitude]);
        exit;
    }

    if ($sog < 0 || $sog > 50) {
        http_response_code(400);
        echo json_encode(['error' => 'SOG invalide: ' . $sog]);
        exit;
    }

    if ($cog < 0 || $cog >= 360) {
        http_response_code(400);
        echo json_encode(['error' => 'COG invalide: ' . $cog]);
        exit;
    }

    // ---------- Exécution du script Python ----------

    // Définir le chemin du script Python à exécuter
    $script_path = 'script_interactif.py';

    // Vérifie que le fichier Python existe
    if (!file_exists($script_path)) {
        echo json_encode([
            'error' => 'Script Python non trouvé',
            'path' => $script_path
        ]);
        exit;
    }

    // Prépare la commande shell avec échappement sécurisé des arguments
    $command = "python3 " . escapeshellarg($script_path) . " " .
               escapeshellarg(strval($latitude)) . " " .
               escapeshellarg(strval($longitude)) . " " .
               escapeshellarg(strval($sog)) . " " .
               escapeshellarg(strval($cog)) . " 2>&1";

    // Écrit la commande dans les logs PHP pour déboguer
    error_log("Commande exécutée: " . $command);

    // Exécute la commande et stocke la sortie
    $output = shell_exec($command);

    // Logue la sortie brute du script Python
    error_log("Sortie Python: " . $output);

    // Vérifie si la sortie est vide ou nulle
    if ($output === null || trim($output) === '') {
        echo json_encode([
            'error' => 'Aucune sortie du script Python',
            'command' => $command
        ]);
        exit;
    }

    // Essaie de décoder la sortie JSON du script Python
    $result = json_decode(trim($output), true);

    // Vérifie si le JSON est valide
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo json_encode([
            'error' => 'Erreur de décodage JSON du script Python',
            'json_error' => json_last_error_msg(),
            'raw_output' => $output
        ]);
        exit;
    }

    // Retourne le résultat JSON au client
    echo json_encode($result);

// ---------- Mode GET : diagnostic de test ----------

} else if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Commande pour obtenir la version de Python (vérifie si Python fonctionne)
    $test_command = "python3 --version 2>&1";
    $python_version = shell_exec($test_command);

    // Chemin attendu du script (test pour les étudiants ou en production)
    $script_path = '/var/www/etu0403/projet_web_a3/script_interactif.py';
    $script_exists = file_exists($script_path);

    // Retourne des infos de diagnostic
    echo json_encode([
        'status' => 'PHP fonctionne',
        'python_version' => $python_version,
        'script_exists' => $script_exists,
        'script_path' => $script_path,
        'current_dir' => __DIR__ // Affiche le répertoire courant pour debug
    ]);

// ---------- Autres méthodes HTTP non autorisées ----------
} else {
    http_response_code(405); // Méthode non autorisée
    echo json_encode(['error' => 'Méthode non autorisée']);
}
?>
