<?php
// Inclusion du fichier contenant les constantes de connexion (DB_SERVER, DB_NAME, etc.)
require_once('constants.php');

/**
 * Fonction de connexion à la base de données via PDO.
 * Retourne un objet PDO si succès, false sinon.
 */
function dbConnect() {
    try {
        // Construction de la chaîne de connexion PDO
        $conn = 'mysql:host=' . DB_SERVER . ';dbname=' . DB_NAME . ';charset=utf8';

        // Création de l'objet PDO
        $db = new PDO($conn, DB_USER, DB_PASSWORD);

        // Activation du mode exception pour les erreurs
        $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        return $db; // Connexion réussie
    } catch (PDOException $exception) {
        // En cas d'échec, log de l’erreur et envoi d’un code HTTP 503
        error_log('Connection error: ' . $exception->getMessage());
        header('HTTP/1.1 503 Service Unavailable');
        return false;
    }
}

/**
 * Récupère toutes les positions de navires, triées par horodatage décroissant.
 */
function dbGetVessels($db) {
    try {
        $sql = "SELECT MMSI, Nom AS VesselName, Length, Width, Draft, Latitude AS LAT, Longitude AS LON,
                       SOG, COG, Heading, Statut AS Status, Horodatage
                FROM Bateaux
                ORDER BY Horodatage DESC";
        
        // Exécution directe car aucune variable externe n'est injectée
        $statement = $db->query($sql);

        // Retour des résultats sous forme de tableau associatif
        return $statement->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $exception) {
        error_log('Request error: ' . $exception->getMessage());
        return false;
    }
}

/**
 * Récupère les données nécessaires pour un clustering (positions les plus récentes).
 */
function dbGetClusters($db) {
    try {
        $sql = "SELECT MMSI, Length, Width, Draft, Latitude AS LAT, Longitude AS LON,
                       SOG, COG, Heading, Horodatage
                FROM Bateaux
                ORDER BY Horodatage DESC";

        $statement = $db->query($sql);
        return $statement->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $exception) {
        error_log('Request error: ' . $exception->getMessage());
        return false;
    }
}

/**
 * Ajoute un navire à la base ou met à jour ses données si le MMSI existe déjà.
 */
function dbAddVessel($mmsi, $basedatetime, $lat, $lon, $sog, $cog, $heading, $vesselname, $status, $length, $width, $draft) {
    $db = dbConnect(); // Connexion à la base

    if (!$db) {
        echo "Erreur de connexion à la base de données.";
        return;
    }

    try {
        // Vérifie si le navire est déjà présent via son MMSI
        $sqlCheck = "SELECT COUNT(*) FROM Bateaux WHERE MMSI = ?";
        $stmtCheck = $db->prepare($sqlCheck);
        $stmtCheck->execute([$mmsi]);
        $exists = $stmtCheck->fetchColumn();

        if ($exists) {
            // Mise à jour si le navire existe déjà
            $sqlUpdate = "UPDATE Bateaux
                          SET Latitude = ?, Longitude = ?, SOG = ?, COG = ?, Heading = ?, Statut = ?, Horodatage = ?
                          WHERE MMSI = ?";
            $stmtUpdate = $db->prepare($sqlUpdate);
            $stmtUpdate->execute([
                $lat, $lon, $sog, $cog, $heading, $status, $basedatetime, $mmsi
            ]);
            echo "Caractéristiques du navire mises à jour avec succès.";
        } else {
            // Insertion complète pour un nouveau navire
            $sqlInsert = "INSERT INTO Bateaux
                          (MMSI, Nom, Length, Width, Draft, Latitude, Longitude, SOG, COG, Heading, Statut, Horodatage)
                          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            $stmtInsert = $db->prepare($sqlInsert);
            $stmtInsert->execute([
                $mmsi, $vesselname, $length, $width, $draft,
                $lat, $lon, $sog, $cog, $heading, $status, $basedatetime
            ]);
            echo "Navire ajouté avec succès.";
        }

    } catch (PDOException $e) {
        error_log("Erreur lors de l'insertion : " . $e->getMessage());
        echo "Erreur lors de l'ajout des données.";
    }
}

/**
 * Récupère la dernière position connue d’un navire en fonction de son MMSI.
 */
function dbGetUniqueVessel($db, $mmsi) {
    try {
        $sql = "SELECT MMSI, Nom AS VesselName, Length, Width, Draft, Latitude AS LAT, Longitude AS LON,
                       SOG, COG, Heading, Statut AS Status, Horodatage
                FROM Bateaux
                WHERE MMSI = :mmsi
                ORDER BY Horodatage DESC
                LIMIT 1";

        $statement = $db->prepare($sql);
        $statement->bindParam(':mmsi', $mmsi, PDO::PARAM_STR);
        $statement->execute();

        return $statement->fetch(PDO::FETCH_ASSOC);
    } catch (PDOException $exception) {
        error_log('Request error: ' . $exception->getMessage());
        return false;
    }
}
?>
