#!/usr/bin/env python3  # Spécifie l'interpréteur Python à utiliser

"""
Script de prédiction de trajectoire pour bateaux MySQL
Les données actuelles sont dans la table Bateaux
Les prédictions sont stockées dans la table Positions
Usage: python3 predict_trajectory.py <mmsi> <horizon_minutes>
"""

# Importation des modules nécessaires
import sys  # Pour lire les arguments passés en ligne de commande
import json  # Pour formater la sortie en JSON
import math  # Pour les fonctions trigonométriques utilisées dans le calcul de trajectoire
import warnings  # Pour désactiver les avertissements
from datetime import datetime, timedelta  # Pour la gestion du temps et des horodatages

warnings.filterwarnings('ignore')  # Supprime les warnings pour éviter d'encombrer la sortie

def debug_database():
    """
    Fonction de debug de la base de données : affiche un état des lieux des données disponibles
    """
    conn = None  # Connexion à la base
    cursor = None  # Curseur de requête

    try:
        import mysql.connector  # Importe le connecteur MySQL
        
        # Connexion à la base de données
        conn = mysql.connector.connect(
            host='localhost',
            database='etu0209',
            user='etu0209',
            password='xxcthgkd',
            autocommit=True
        )
        cursor = conn.cursor()  # Création du curseur

        print("=== DEBUG BASE DE DONNÉES ===")
        
        # Nombre de bateaux
        cursor.execute("SELECT COUNT(*) FROM Bateaux")
        boat_count = cursor.fetchone()[0]
        print(f"Nombre de bateaux dans la table Bateaux: {boat_count}")
        
        # Exemples de bateaux si présents
        if boat_count > 0:
            cursor.execute("SELECT mmsi, nom, latitude, longitude, sog, cog FROM Bateaux LIMIT 3")
            boats = cursor.fetchall()
            print("Exemples de bateaux avec positions:")
            for boat in boats:
                print(f"  - MMSI: {boat[0]}, Nom: {boat[1]}")
                print(f"    Position: {boat[2]}, {boat[3]} | Vitesse: {boat[4]} | Cap: {boat[5]}")
        
        # Nombre de prédictions
        cursor.execute("SELECT COUNT(*) FROM Positions")
        pos_count = cursor.fetchone()[0]
        print(f"\nNombre de prédictions dans la table Positions: {pos_count}")
        
        # Affiche les dernières prédictions
        if pos_count > 0:
            cursor.execute("SELECT mmsi, latitude, longitude, timestamp_donnees FROM Positions ORDER BY timestamp_donnees DESC LIMIT 3")
            predictions = cursor.fetchall()
            print("Dernières prédictions:")
            for pred in predictions:
                print(f"  - MMSI: {pred[0]}, Position: {pred[1]}, {pred[2]} | Temps: {pred[3]}")
        
        # Structure des tables
        cursor.execute("DESCRIBE Bateaux")
        boat_structure = cursor.fetchall()
        print("\nStructure table Bateaux:")
        for col in boat_structure:
            print(f"  - {col[0]} ({col[1]})")
            
        cursor.execute("DESCRIBE Positions")
        pos_structure = cursor.fetchall()
        print("\nStructure table Positions:")
        for col in pos_structure:
            print(f"  - {col[0]} ({col[1]})")

    except Exception as e:
        print(f"Erreur debug: {e}")  # En cas d’erreur de requête
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def predict_trajectory(mmsi, horizon_minutes):
    """
    Fonction principale de prédiction de trajectoire pour un bateau donné et un horizon temporel
    """
    conn = None
    cursor = None

    try:
        import mysql.connector  # Import du module MySQL
        
        # Connexion à la base
        conn = mysql.connector.connect(
            host='localhost',
            database='etu0209',
            user='etu0209',
            password='xxcthgkd',
            autocommit=True
        )
        cursor = conn.cursor()

        # Récupération des infos du bateau si données complètes
        query = """
        SELECT mmsi, nom, latitude, longitude, sog, cog, horodatage, id_bateau
        FROM Bateaux 
        WHERE mmsi = %s
        AND latitude IS NOT NULL 
        AND longitude IS NOT NULL
        AND sog IS NOT NULL
        AND cog IS NOT NULL
        """
        cursor.execute(query, (mmsi,))
        boat_data = cursor.fetchone()

        # Si aucune donnée trouvée pour ce bateau
        if not boat_data:
            cursor.execute("SELECT mmsi, nom FROM Bateaux WHERE mmsi = %s", (mmsi,))
            boat_exists = cursor.fetchone()

            if boat_exists:
                # MMSI trouvé mais données manquantes
                return {
                    'success': False,
                    'error': f'MMSI {mmsi} trouvé mais données de position incomplètes',
                    'debug': {
                        'boat_name': boat_exists[1],
                        'issue': 'Vérifiez que latitude, longitude, sog et cog ne sont pas NULL'
                    }
                }
            else:
                # MMSI non trouvé du tout
                cursor.execute("SELECT mmsi, nom FROM Bateaux WHERE latitude IS NOT NULL LIMIT 5")
                available_boats = cursor.fetchall()
                return {
                    'success': False,
                    'error': f'MMSI {mmsi} non trouvé dans la table Bateaux',
                    'debug': {
                        'available_boats': [{'mmsi': str(boat[0]), 'nom': boat[1]} for boat in available_boats]
                    }
                }

        # Extraction des données utiles
        boat_mmsi, boat_name, current_lat, current_lon, current_speed, current_course, current_timestamp, id_bateau = boat_data
        current_lat = float(current_lat)
        current_lon = float(current_lon)
        current_speed = float(current_speed) if current_speed else 0.0
        current_course = float(current_course) if current_course else 0.0

        # Conversion vitesse en m/s et calcul de distance
        speed_ms = current_speed * 0.514444
        time_seconds = horizon_minutes * 60
        distance_m = speed_ms * time_seconds

        # Calcul de la position prédite
        if distance_m > 0:
            distance_deg = distance_m / 111320  # Approximatif
            course_rad = math.radians(current_course)
            delta_lat = distance_deg * math.cos(course_rad)
            delta_lon = distance_deg * math.sin(course_rad) / math.cos(math.radians(current_lat))
            predicted_lat = current_lat + delta_lat
            predicted_lon = current_lon + delta_lon
        else:
            predicted_lat = current_lat
            predicted_lon = current_lon

        # Fonction Haversine pour la distance
        def calculate_distance(lat1, lon1, lat2, lon2):
            R = 6371
            dlat = math.radians(lat2 - lat1)
            dlon = math.radians(lon2 - lon1)
            a = (math.sin(dlat/2) ** 2 +
                 math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
                 math.sin(dlon/2) ** 2)
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
            return R * c

        distance_km = calculate_distance(current_lat, current_lon, predicted_lat, predicted_lon)

        # Création du timestamp futur
        if current_timestamp:
            if isinstance(current_timestamp, str):
                base_time = datetime.fromisoformat(current_timestamp.replace('Z', '+00:00'))
            else:
                base_time = current_timestamp
            predicted_time = base_time + timedelta(minutes=horizon_minutes)
        else:
            predicted_time = datetime.now() + timedelta(minutes=horizon_minutes)

        # Tentative de stockage de la prédiction
        prediction_stored = False
        storage_error = None
        try:
            cursor.execute("""
                INSERT INTO Positions (id_bateau, latitude, longitude, vitesse, cap, timestamp_donnees, mmsi)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (id_bateau, predicted_lat, predicted_lon, current_speed, current_course, predicted_time, mmsi))
            prediction_stored = True
        except Exception as e:
            storage_error = str(e)

        # Nombre de prédictions déjà enregistrées
        cursor.execute("SELECT COUNT(*) FROM Positions WHERE mmsi = %s", (mmsi,))
        total_predictions = cursor.fetchone()[0]

        # Retour d’un dictionnaire JSON complet
        return {
            'success': True,
            'data': {
                'mmsi': str(mmsi),
                'boat_name': boat_name or "Inconnu",
                'id_bateau': id_bateau,
                'horizon_minutes': horizon_minutes,
                'current_position': {
                    'latitude': round(current_lat, 6),
                    'longitude': round(current_lon, 6),
                    'speed': round(current_speed, 2),
                    'course': round(current_course, 1),
                    'timestamp': str(current_timestamp) if current_timestamp else None
                },
                'predicted_position': {
                    'latitude': round(predicted_lat, 6),
                    'longitude': round(predicted_lon, 6),
                    'estimated_speed': round(current_speed, 2),
                    'estimated_course': round(current_course, 1),
                    'predicted_time': predicted_time.isoformat()
                },
                'prediction_info': {
                    'method': 'Linear extrapolation from Bateaux table',
                    'distance_km': round(distance_km, 2),
                    'confidence': 'medium',
                    'data_source': 'table Bateaux',
                    'prediction_stored': prediction_stored,
                    'total_predictions_for_mmsi': total_predictions,
                    'storage_error': storage_error
                }
            }
        }

    except ImportError as e:
        # Gestion des modules manquants
        return {
            'success': False,
            'error': f'Module mysql.connector manquant: {str(e)}',
            'suggestion': 'Installez avec: pip install mysql-connector-python'
        }
    except Exception as e:
        # Autre erreur
        return {
            'success': False,
            'error': f'Erreur de prédiction: {str(e)}'
        }
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def list_predictions(mmsi=None):
    """
    Affiche les prédictions déjà enregistrées dans la base
    """
    conn = None
    cursor = None

    try:
        import mysql.connector

        conn = mysql.connector.connect(
            host='localhost',
            database='etu0209',
            user='etu0209',
            password='xxcthgkd',
            autocommit=True
        )
        cursor = conn.cursor()

        # Si MMSI est fourni → prédictions ciblées
        if mmsi:
            cursor.execute("""
                SELECT p.mmsi, b.nom, p.latitude, p.longitude, p.vitesse, p.cap, p.timestamp_donnees
                FROM Positions p
                LEFT JOIN Bateaux b ON p.id_bateau = b.id_bateau
                WHERE p.mmsi = %s
                ORDER BY p.timestamp_donnees DESC
            """, (mmsi,))
            title = f"Prédictions pour le MMSI {mmsi}:"
        else:
            # Sinon, affiche les dernières 10 prédictions
            cursor.execute("""
                SELECT p.mmsi, b.nom, p.latitude, p.longitude, p.vitesse, p.cap, p.timestamp_donnees
                FROM Positions p
                LEFT JOIN Bateaux b ON p.id_bateau = b.id_bateau
                ORDER BY p.timestamp_donnees DESC
                LIMIT 10
            """)
            title = "Dernières prédictions (toutes):"

        predictions = cursor.fetchall()

        print(title)
        if predictions:
            for pred in predictions:
                mmsi, nom, lat, lon, vitesse, cap, timestamp = pred
                print(f"  MMSI: {mmsi} ({nom or 'Inconnu'})")
                print(f"  Position prédite: {lat:.6f}, {lon:.6f}")
                print(f"  Vitesse: {vitesse} nœuds, Cap: {cap}°")
                print(f"  Temps de prédiction: {timestamp}")
                print("  " + "-"*50)
        else:
            print("  Aucune prédiction trouvée")

    except Exception as e:
        print(f"Erreur lors de l'affichage des prédictions: {e}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def main():
    """Point d’entrée principal du script"""
    try:
        # Aucun argument → mode debug
        if len(sys.argv) == 1:
            debug_database()
            return
        elif len(sys.argv) == 2:
            if sys.argv[1] == "list":
                list_predictions()
                return
            else:
                list_predictions(sys.argv[1])
                return
        elif len(sys.argv) != 3:
            result = {
                'success': False,
                'error': 'Usage: python3 predict_trajectory.py <mmsi> <horizon_minutes>',
                'help': {
                    'debug': 'python3 predict_trajectory.py (sans paramètres)',
                    'list_all': 'python3 predict_trajectory.py list',
                    'list_mmsi': 'python3 predict_trajectory.py <mmsi>',
                    'predict': 'python3 predict_trajectory.py <mmsi> <horizon_minutes>'
                }
            }
        else:
            # Lancement prédiction
            mmsi = sys.argv[1].strip()
            horizon_str = sys.argv[2].strip()

            try:
                horizon_minutes = int(float(horizon_str))
            except ValueError:
                result = {
                    'success': False,
                    'error': f'Impossible de convertir "{horizon_str}" en nombre entier'
                }
            else:
                if horizon_minutes <= 0 or horizon_minutes > 1440:
                    result = {
                        'success': False,
                        'error': 'L\'horizon doit être entre 1 et 1440 minutes (24h)'
                    }
                else:
                    result = predict_trajectory(mmsi, horizon_minutes)

    except Exception as e:
        result = {
            'success': False,
            'error': f'Erreur: {str(e)}'
        }

    if 'result' in locals():
        print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()  # Lance la fonction main uniquement si ce script est exécuté directement
