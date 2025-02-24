#!/bin/bash

# Función para obtener el Project ID a partir de la URL y el namespace
get_project_id() {
  local PIPELINE_URL="$1"
  local NAMESPACE_CRITERIA="$2"

  # Extraer el nombre del proyecto (cs-sportbook, en este caso)
  PROJECT_NAME=$(echo "$PIPELINE_URL" | awk -F'/' '{print $(NF-3)}')

  # Extraer el ID del pipeline (234006, al final de la URL)
  PIPELINE_ID=$(echo "$PIPELINE_URL" | awk -F'/' '{print $NF}')

  # Verificar si se extrajo correctamente
  if [ -z "$PROJECT_NAME" ] || [ -z "$PIPELINE_ID" ]; then
    echo "Error al extraer el nombre del proyecto o el ID del pipeline."
    exit 1
  fi

  echo -e "📌 \033[1mProyecto:\033[0m $PROJECT_NAME"
  echo -e "📌 \033[1mPipeline ID:\033[0m $PIPELINE_ID"

  # Obtener el PROJECT_ID desde la API
  PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
    "$GITLAB_URL/api/v4/projects?search=$PROJECT_NAME" | jq ".[] | select(.path_with_namespace | $NAMESPACE_CRITERIA) | .id")

  if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "null" ]; then
    echo -e "⚠️ No se encontró el Project ID para $PROJECT_NAME"
    exit 1
  fi

  echo -e "✅ \033[1mProject ID:\033[0m $PROJECT_ID"
}

# Función para obtener detalles del pipeline, incluyendo fecha de inicio y usuario
get_pipeline_details() {
  local PROJECT_ID="$1"
  local PIPELINE_ID="$2"

  echo -e "🔍 Consultando detalles del pipeline..."

  # Obtener información del pipeline
  PIPELINE_INFO=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID")

  # Extraer la fecha de inicio y el usuario
  PIPELINE_CREATED_AT=$(echo "$PIPELINE_INFO" | jq -r '.created_at')
  PIPELINE_USER=$(echo "$PIPELINE_INFO" | jq -r '.user.name')

  if [ -z "$PIPELINE_CREATED_AT" ] || [ "$PIPELINE_CREATED_AT" == "null" ]; then
    echo -e "⚠️ N\u001b[31mNo se pudo obtener la fecha de inicio del pipeline.\u001b[0m"
  else
    echo -e "🕒 \033[1mFecha de inicio del pipeline:\033[0m $PIPELINE_CREATED_AT"
  fi

  if [ -z "$PIPELINE_USER" ] || [ "$PIPELINE_USER" == "null" ]; then
    echo -e "⚠️ \u001b[31mNo se pudo obtener el usuario que lanzó el pipeline.\u001b[0m"
  else
    echo -e "👤 \033[1mPipeline lanzado por:\033[0m $PIPELINE_USER"
  fi

  # Obtener variables del pipeline
  echo "🔍 Consultando variables del pipeline..."
  PIPELINE_VARS=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/variables" | jq)

  echo "🔹 Variables del pipeline:"
  echo "$PIPELINE_VARS" | jq -r '.[] | "➡️ \u001b[1m\(.key)\u001b[0m: \(.value | if . == "" then "\u001b[31mNONE\u001b[0m" else "\u001b[32m" + . + "\u001b[0m" end)"'
}

# Función para manejar la fase 2
run_fase2() {
  get_project_id "$1" 'contains("application-infrastructure/customers")'
  get_pipeline_details "$PROJECT_ID" "$PIPELINE_ID"
}

# Función para manejar la fase 3
run_fase3() {
  get_project_id "$1" 'endswith("'$PROJECT_NAME'")'
  get_pipeline_details "$PROJECT_ID" "$PIPELINE_ID"
}

# Preguntar por la fase
echo "Seleccione la fase (2 o 3):"
read FASE

# Validar la entrada de la fase
if [ "$FASE" != "2" ] && [ "$FASE" != "3" ]; then
  echo "Fase inválida. Debes elegir '2' o '3'."
  exit 1
fi

# Preguntar por la URL
echo "Ingrese la URL del pipeline:"
read PIPELINE_URL

# Configuración
GITLAB_URL="https://gitlab.optimahq.com"
PRIVATE_TOKEN="5RQE5xn5exvVEPFpWZbe"  # Reemplázalo con tu token

# Ejecutar el script correspondiente según la fase seleccionada
if [ "$FASE" == "2" ]; then
  run_fase2 "$PIPELINE_URL"
else
  run_fase3 "$PIPELINE_URL"
fi