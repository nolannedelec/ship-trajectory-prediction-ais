<?php
// Spécifie que la réponse sera au format JSON
header('Content-Type: application/json');

// Autorise toutes les origines (utile si appel depuis un autre domaine)
header('Access-Control-Allow-Origin: *');

// Chemin vers le script Python à exécuter
$script_path = 'cluster_all.py';

// Vérifie si le fichier Python existe
if (!file_exists($script_path)) {
    echo json_encode([
        'error' => 'Script Python introuvable',       // Message d'erreur
        'path' => realpath($script_path),             // Chemin absolu pour debug
        'cwd' => getcwd()                             // Répertoire courant pour debug
    ]);
    exit; // Arrête l'exécution
}

// Sécurise la commande pour éviter les injections et prépare l'appel
$command = escapeshellcmd("python3 $script_path");

// Exécute le script Python en ligne de commande
$output = shell_exec($command);

// Vérifie si le script a renvoyé quelque chose
if ($output === null || trim($output) === '') {
    echo json_encode([
        'error' => 'Aucune sortie du script Python' // Message d'erreur si sortie vide
    ]);
    exit;
}

// Tente de décoder la sortie JSON du script Python
$result = json_decode($output, true);

// Vérifie si le JSON est valide
if (json_last_error() !== JSON_ERROR_NONE) {
    echo json_encode([
        'error' => 'Erreur JSON',                     // Message si le JSON est invalide
        'details' => json_last_error_msg(),          // Description de l'erreur
        'raw_output' => $output                      // Contenu brut retourné par Python pour debug
    ]);
    exit;
}

// Si tout est correct, retourne la réponse JSON au client
echo json_encode($result);
?>
