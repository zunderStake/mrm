#!/bin/bash

# Verifica si se proporcionó un argumento
if [ -z "$1" ]; then
    echo "Uso: $0 <ruta_del_directorio_principal>"
    exit 1
fi

# Asigna la ruta proporcionada a la variable
DIRECTORIO_PRINCIPAL="$1"

# Cambia al directorio principal
cd "$DIRECTORIO_PRINCIPAL" || exit

# Recorre todas las carpetas
for repo in */; do
    # Comprueba si es un repositorio git
    if [ -d "$repo/.git" ]; then
        echo "Actualizando repositorio en $repo"
        cd "$repo" || continue
        git pull
        cd ..
    else
        echo "$repo no es un repositorio git, se omite."
    fi
done