#!/bin/bash
# -----------------------------------------------------------------------------
# Script d'installation Pterodactyl - Space Engineers + Torch
# -----------------------------------------------------------------------------

repertoire_installation="/mnt/server"
cd ${repertoire_installation} || exit 1

# Redirection vers le log
exec > >(tee -a ${repertoire_installation}/log_instal.txt) 2>&1
echo "=== Début de l'installation ==="

echo "Installation des dépendances d'installation..."
# Activation de l'architecture 32 bits requise par SteamCMD
dpkg --add-architecture i386
apt-get update -y
apt-get install -y curl unzip lib32gcc-s1

echo "Téléchargement de SteamCMD..."
mkdir -p steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C steamcmd
rm steamcmd.tar.gz

echo "Installation des fichiers du serveur Space Engineers..."
./steamcmd/steamcmd.sh +force_install_dir ${repertoire_installation} +login anonymous +app_update 298740 validate +quit

echo "Téléchargement de Torch..."
URL_TORCH="https://build.torchapi.com/job/Torch/job/master/lastSuccessfulBuild/artifact/bin/torch-server.zip"
curl -sSL -o torch-server.zip "$URL_TORCH"
unzip -o torch-server.zip
rm torch-server.zip

echo "Création du script de démarrage (startup.sh)..."
cat << 'EOF' > startup.sh
#!/bin/bash
cd /home/container || exit 1

if [ ! -f "Torch.Server.exe" ]; then
    echo "Erreur : Torch.Server.exe est introuvable."
    exit 1
fi

if [ "${AUTO_UPDATE}" == "1" ]; then
    echo "Mise à jour de Space Engineers initiée..."
    ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update 298740 +quit
fi

echo "Démarrage de l'affichage virtuel Xvfb..."
export DISPLAY=:0
rm -tmp/.X0-lock 2>/dev/null
Xvfb :0 -screen 0 1024x768x16 &
pid_serveur_X=$!

echo "Démarrage de Torch sous Wine..."
wine Torch.Server.exe -nogui

echo "Arrêt du serveur. Nettoyage des processus..."
kill $pid_serveur_X
exit 0
EOF

chmod +x startup.sh
mkdir -p Instance
echo "=== Installation terminée avec succès ==="