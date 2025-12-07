<?php
// ------------------------
// GESTION DES REQUÊTES OPTIONS POUR LE CORS (prévol)
// ------------------------
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    // Autoriser les appels CORS
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    http_response_code(200); // Réponse immédiate pour les OPTIONS
    exit();
}

// ------------------------
// EN-TÊTES HTTP (CORS + JSON)
// ------------------------
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// ------------------------
// AFFICHAGE DES ERREURS POUR LE DÉBOGAGE
// ------------------------
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

try {
    // ------------------------
    // DÉBOGAGE : JOURNALISATION DES DONNÉES REÇUES
    // ------------------------
    $raw_input = file_get_contents('php://input'); // Lecture brute du corps de la requête
    error_log("Raw input reçu : " . $raw_input);
    error_log("Content-Type : " . ($_SERVER['CONTENT_TYPE'] ?? 'non défini'));
    error_log("Request method : " . $_SERVER['REQUEST_METHOD']);
    error_log("Paramètres POST reçus : " . print_r($_POST, true));
    error_log("Paramètres GET reçus : " . print_r($_GET, true));

    // Initialisation des variables
    $mmsi = null;
    $horizon = 5; // Valeur par défaut

    // ------------------------
    // 1. PRIORITÉ AUX DONNÉES EN POST
    // ------------------------
    if (!empty($_POST['mmsi'])) {
        $mmsi = $_POST['mmsi'];
        $horizon = $_POST['horizon'] ?? 5;
        error_log("Données récupérées via POST");
    }
    // ------------------------
    // 2. SINON ESSAYER EN GET
    // ------------------------
    elseif (!empty($_GET['mmsi'])) {
        $mmsi = $_GET['mmsi'];
        $horizon = $_GET['horizon'] ?? 5;
        error_log("Données récupérées via GET");
    }
    // ------------------------
    // 3. SI TOUT ÉCHOUE, PARSER MANUELLEMENT L'INPUT BRUT (cas des requêtes `fetch`)
    // ------------------------
    elseif (!empty($raw_input)) {
        parse_str($raw_input, $parsed_data); // Transforme key1=value1&key2=value2 en tableau associatif
        error_log("Données parsées du raw input : " . print_r($parsed_data, true));
        
        if (!empty($parsed_data['mmsi'])) {
            $mmsi = $parsed_data['mmsi'];
            $horizon = $parsed_data['horizon'] ?? 5;
            error_log("Données récupérées via parsing du raw input");
        }
    }

    // ------------------------
    // VÉRIFICATION DES DONNÉES REQUISES
    // ------------------------
    if ($mmsi === null || empty($mmsi)) {
        throw new Exception("MMSI manquant. Méthode: " . $_SERVER['REQUEST_METHOD'] . 
            ", Content-Type: " . ($_SERVER['CONTENT_TYPE'] ?? 'non défini') . 
            ", Raw input: " . substr($raw_input, 0, 100) . 
            ", POST: " . print_r($_POST, true) . 
            ", GET: " . print_r($_GET, true));
    }

    // Log des paramètres finaux analysés
    error_log("Paramètres finaux analysés : mmsi=" . var_export($mmsi, true) . ", horizon=" . var_export($horizon, true));

    // ------------------------
    // VALIDATION DES PARAMÈTRES
    // ------------------------
    if (!is_numeric($mmsi)) {
        throw new Exception('MMSI invalide. Doit être un nombre. Valeur reçue : ' . var_export($mmsi, true));
    }
    
    if (!is_numeric($horizon) || !in_array((int)$horizon, [5, 10, 15])) {
        throw new Exception('Horizon invalide. Doit être 5, 10 ou 15 minutes. Valeur reçue : ' . var_export($horizon, true));
    }

    $mmsi = (int)$mmsi;
    $horizon = (int)$horizon;

    // ------------------------
    // CHEMIN DU SCRIPT PYTHON
    // ------------------------
    $script_dir = dirname(__FILE__); // Répertoire du script PHP actuel
    $python_script = $script_dir . '/predict_trajectory.py';

    // Vérification d'existence et de permission du script Python
    if (!file_exists($python_script)) {
        throw new Exception("Script Python non trouvé à l'emplacement : $python_script");
    }

    if (!is_readable($python_script)) {
        throw new Exception("Script Python non lisible. Permissions : " . substr(sprintf('%o', fileperms($python_script)), -4));
    }

    // ------------------------
    // CONSTRUCTION ET EXÉCUTION DE LA COMMANDE
    // ------------------------
    $python_executable = 'python3'; // Nom de l'exécutable Python
    $command = sprintf(
        '%s %s %d %d 2>&1',
        escapeshellcmd($python_executable),
        escapeshellarg($python_script),
        $mmsi,
        $horizon
    );

    error_log("Exécution de la commande : $command");

    // Exécution de la commande
    $output = shell_exec($command);

    if ($output === null) {
        throw new Exception("Échec de l'exécution du script Python. Vérifiez : 1. Python est-il installé ? 2. Permissions suffisantes ? 3. Dépendances ? Commande : $command");
    }

    error_log("Sortie du script Python : " . $output);

    $output = trim($output); // Nettoyage de la sortie

    if (empty($output)) {
        throw new Exception("Le script Python n'a produit aucune sortie.");
    }

    // ------------------------
    // PARSING JSON DU RÉSULTAT
    // ------------------------
    $result = json_decode($output, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        $json_error = json_last_error_msg();
        throw new Exception("Format JSON invalide. Erreur : $json_error. Sortie brute : " . substr($output, 0, 500));
    }

    // ------------------------
    // VALIDATION DE LA STRUCTURE JSON
    // ------------------------
    if (!is_array($result) || !isset($result['success'])) {
        throw new Exception("Structure de réponse invalide. Réponse : " . substr($output, 0, 200));
    }

    if (!$result['success']) {
        $python_error = $result['error'] ?? 'Erreur inconnue du script Python';
        throw new Exception("Erreur du script de prédiction : " . $python_error);
    }

    if (!isset($result['data']) || 
        !isset($result['data']['predicted_position']) ||
        !isset($result['data']['current_position'])) {
        throw new Exception("Données de prédiction incomplètes.");
    }

    // ------------------------
    // TOUT EST OK : ENVOI DE LA RÉPONSE
    // ------------------------
    echo json_encode($result);

} catch (Exception $e) {
    // ------------------------
    // EN CAS D'ERREUR : LOG ET RÉPONSE JSON DÉTAILLÉE
    // ------------------------
    error_log("Erreur dans predict_traj.php : " . $e->getMessage());
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'debug_info' => [
            'mmsi' => $mmsi ?? 'non défini',
            'horizon' => $horizon ?? 'non défini',
            'timestamp' => date('Y-m-d H:i:s'),
            'request_method' => $_SERVER['REQUEST_METHOD'],
            'content_type' => $_SERVER['CONTENT_TYPE'] ?? 'non défini',
            'raw_input_length' => strlen($raw_input ?? ''),
            'post_data' => $_POST,
            'get_data' => $_GET,
            'output' => isset($output) ? substr($output, 0, 500) : 'aucune sortie'
        ]
    ]);
}
?>
