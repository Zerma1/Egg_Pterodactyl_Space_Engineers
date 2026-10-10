#!/bin/bash
# -----------------------------------------------------------------------------
# Script d'installation Pterodactyl - Space Engineers + Torch
# -----------------------------------------------------------------------------

repertoire_installation="/mnt/server"
cd ${repertoire_installation} || exit 1

exec > >(tee -a ${repertoire_installation}/log_instal.txt) 2>&1
echo "=== Début de l'installation ==="

echo "Téléchargement de SteamCMD..."
mkdir -p steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C steamcmd
rm steamcmd.tar.gz

echo "Installation des fichiers du serveur Space Engineers..."
# Utilisation de /tmp pour contourner l'erreur "Missing file permissions"
mkdir -p /tmp/se_install
./steamcmd/steamcmd.sh +force_install_dir /tmp/se_install +login anonymous +app_update 298740 validate +quit
# Déplacement des fichiers vers le répertoire final
cp -r /tmp/se_install/* ${repertoire_installation}/
rm -rf /tmp/se_install

echo "Téléchargement de Torch..."
URL_TORCH="https://build.torchapi.com/job/Torch/job/master/lastSuccessfulBuild/artifact/bin/torch-server.zip"
curl -sSL -o torch-server.zip "$URL_TORCH"

echo "Extraction de Torch..."
# Utilisation de Python (inclus par défaut) pour décompresser, évitant ainsi d'avoir à installer 'unzip'
python3 -c "import zipfile; zipfile.ZipFile('torch-server.zip').extractall('${repertoire_installation}')"
rm torch-server.zip

echo "Création du script de démarrage (startup.sh)..."
cat << 'EOF' > startup.sh
#!/bin/bash
cd /home/container || exit 1

# Création des fichiers de log au démarrage
exec > >(tee -a /home/container/log_starting.txt) 2>&1
echo "=== Démarrage du serveur $(date) ==="

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
# Redirection des logs d'exécution
wine Torch.Server.exe -nogui > log_running.txt 2>&1

echo "Arrêt du serveur. Nettoyage des processus..."
kill $pid_serveur_X
exit 0
EOF

chmod +x startup.sh
mkdir -p Instance
echo "=== Installation terminée avec succès ==="