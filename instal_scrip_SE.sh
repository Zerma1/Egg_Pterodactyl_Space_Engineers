#!/bin/bash
# -----------------------------------------------------------------------------
# Script d'installation Pterodactyl - Space Engineers + Torch
# -----------------------------------------------------------------------------
apt-get update -y
apt-get install -y curl unzip wine xvfb winbind

# Définition du répertoire cible
repertoire_installation="/mnt/server"
cd ${repertoire_installation} || exit 1

echo "Téléchargement de SteamCMD..."
mkdir -p steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C steamcmd
rm steamcmd.tar.gz

echo "Installation des fichiers du serveur Space Engineers..."
# Attention : Le téléchargement initial peut être long.
./steamcmd/steamcmd.sh +force_install_dir ${repertoire_installation} +login anonymous +app_update 298740 validate +quit

echo "Téléchargement de Torch..."
# Récupération de la dernière version stable de Torch depuis leur API officielle
lien_telechargement_torch=$(curl -s https://build.torchapi.net/job/Torch/job/Torch/job/master/api/json | grep -oP '"url":"\K[^"]+bin/torch-server.zip' | head -n 1)

if [ -z "$lien_telechargement_torch" ]; then
    echo "Erreur critique : Impossible de récupérer l'URL de Torch."
    exit 1
fi

curl -sSL -o torch.zip "$lien_telechargement_torch"
unzip -o torch.zip
rm torch.zip

# Création du dossier d'instance par défaut pour Torch
mkdir -p Instance
echo "Installation terminée avec succès."