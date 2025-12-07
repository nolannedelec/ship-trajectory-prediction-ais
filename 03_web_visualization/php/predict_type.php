<?php
// Spécifie que la réponse sera en JSON
header('Content-Type: application/json');
// Autorise toutes les origines (CORS)
header('Access-Control-Allow-Origin: *');
// Autorise uniquement les requêtes POST
header('Access-Control-Allow-Methods: POST');
// Autorise les en-têtes de type Content-Type
header('Access-Control-Allow-Headers: Content-Type');

// Vérifie que la méthode HTTP utilisée est POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); // Code HTTP 405 : méthode non autorisée
    echo json_encode(['success' => false, 'error' => 'Méthode non autorisée']);
    exit; // Termine le script
}

// Récupère les données JSON envoyées dans le corps de la requête
$input = file_get_contents('php://input');
// Décode les données JSON en tableau associatif PHP
$data = json_decode($input, true);

// Vérifie que toutes les données requises sont présentes
if (!$data || !isset($data['status_label']) || !isset($data['length']) ||
    !isset($data['width']) || !isset($data['draft'])) {
    http_response_code(400); // Code HTTP 400 : requête invalide
    echo json_encode(['success' => false, 'error' => 'Données manquantes']);
    exit;
}

try {
    // Prépare les variables à passer au script Python
    // Remplace "N/A" ou null par des valeurs par défaut (0 ou 0.0)
    $status = ($data['status_label'] === 'N/A' || $data['status_label'] === null) ? 0 : (int)$data['status_label'];
    $length = ($data['length'] === 'N/A' || $data['length'] === null) ? 0.0 : (float)$data['length'];
    $width = ($data['width'] === 'N/A' || $data['width'] === null) ? 0.0 : (float)$data['width'];
    $draft = ($data['draft'] === 'N/A' || $data['draft'] === null) ? 0.0 : (float)$data['draft'];

    // Définit le chemin vers le script Python
    $python_script = __DIR__ . '/predict_type.py'; // __DIR__ donne le répertoire courant

    // Vérifie si le script Python existe
    if (!file_exists($python_script)) {
        throw new Exception("Script Python non trouvé: $python_script");
    }

    // Crée la commande shell pour exécuter le script Python avec les arguments
    // `escapeshellarg()` sécurise le nom de fichier
    // `sprintf()` insère les valeurs dans la chaîne
    // `2>&1` redirige les erreurs vers la sortie standard
    $command = sprintf(
        'python3 %s --status %d --length %.2f --width %.2f --draft %.2f --model all 2>&1',
        escapeshellarg($python_script),
        $status,
        $length,
        $width,
        $draft
    );

    // Écrit la commande dans les logs pour le débogage
    error_log("Commande exécutée: " . $command);

    // Exécute la commande shell et récupère la sortie
    $output = shell_exec($command);

    // Si aucune sortie, une erreur s'est produite
    if ($output === null) {
        throw new Exception('Erreur lors de l\'exécution du script Python');
    }

    // Découpe la sortie du script en lignes
    $lines = explode("\n", trim($output));
    $predictions = []; // Tableau pour stocker les prédictions
    $parsing_results = false; // Flag pour savoir si on est dans la zone de résultats

    // Boucle sur chaque ligne de sortie
    foreach ($lines as $line) {
        $line = trim($line); // Supprime les espaces

        // Début de la section de résultats
        if ($line === "=== RÉSULTATS DE PRÉDICTION ===") {
            $parsing_results = true;
            continue;
        }

        // Fin de la section de résultats
        if ($line === "=== FIN RÉSULTATS ===") {
            $parsing_results = false;
            continue;
        }

        // Si on est dans la section des résultats et que la ligne contient ":"
        if ($parsing_results && strpos($line, ':') !== false) {
            $parts = explode(':', $line, 2); // Sépare la ligne en deux parties
            if (count($parts) === 2) {
                $model = trim($parts[0]); // Nom du modèle
                $prediction = trim($parts[1]); // Résultat de la prédiction
                $predictions[$model] = $prediction;
            }
        }
    }

    // Si aucune prédiction n’a été trouvée avec la méthode précédente
    if (empty($predictions)) {
        foreach ($lines as $line) {
            // Cherche une ligne simple de type "Type de navire prédit: ..."
            if (strpos($line, 'Type de navire prédit:') !== false) {
                $parts = explode(':', $line, 2);
                if (count($parts) === 2) {
                    $predictions['Prediction'] = trim($parts[1]);
                }
                break;
            }
        }
    }

    // Si aucune prédiction n’a été trouvée du tout
    if (empty($predictions)) {
        throw new Exception('Aucune prédiction trouvée dans la sortie');
    }

    // Envoie une réponse JSON avec les prédictions, les données reçues, et la sortie brute du script
    echo json_encode([
        'success' => true,
        'predictions' => $predictions,
        'input_data' => $data,
        'raw_output' => $output
    ]);

} catch (Exception $e) {
    // En cas d'erreur, envoie une réponse d'erreur avec les détails
    http_response_code(500); // Code HTTP 500 : erreur serveur
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'input_data' => $data ?? null,
        'raw_output' => $output ?? null
    ]);
}
?>
