#!/bin/bash
# -----------------------------------------------------------------------------
# Script de démarrage pour Space Engineers avec Torch sous Wine
# -----------------------------------------------------------------------------

# Étape 1 : Se positionner dans le répertoire racine du serveur Pterodactyl
cd /home/container || exit 1

# Étape 2 : Vérification de la présence de Torch
# Torch est nécessaire pour charger de nombreux mods de manière stable.
if [ ! -f "Torch.Server.exe" ]; then
    echo "Erreur : Torch.Server.exe est introuvable. Veuillez réinstaller le serveur."
    exit 1
fi

# Étape 3 : Mise à jour de Space Engineers via SteamCMD (si configuré)
# Utilise la variable d'environnement AUTO_UPDATE définie dans le panel Pterodactyl
if [ "${AUTO_UPDATE}" == "1" ]; then
    echo "Mise à jour de Space Engineers initiée..."
    # Lancement de SteamCMD pour télécharger/mettre à jour l'app 298740 (Space Engineers Dedicated Server)
    ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update 298740 +quit
fi

# Étape 4 : Configuration de l'affichage virtuel (Xvfb)
# Space Engineers et Torch nécessitent une interface graphique minimale (GUI) même en mode console.
# Xvfb simule un écran virtuel.
echo "Démarrage de l'affichage virtuel Xvfb..."
export DISPLAY=:0
rm -tmp/.X0-lock 2>/dev/null
Xvfb :0 -screen 0 1024x768x16 &
pid_serveur_X=$!

# Étape 5 : Lancement du serveur via Torch sous Wine
echo "Démarrage du serveur Space Engineers via Torch..."
# L'utilisation de 'wine' exécute le binaire Windows. 
# -nogui permet de lancer Torch sans son interface WPF complexe qui crasherait sous Linux.
wine Torch.Server.exe -nogui

# Étape 6 : Nettoyage en cas de fermeture du serveur
echo "Arrêt du serveur. Nettoyage des processus..."
kill $pid_serveur_X
exit 0