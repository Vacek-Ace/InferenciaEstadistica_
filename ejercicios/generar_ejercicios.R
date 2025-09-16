# ===============================================
# Script para generar ejercicios completos con portada personalizada
# Ejecutar desde la RAÍZ del proyecto  
# Uso: Rscript -e "source('ejercicios/generar_ejercicios.R'); crear_ejercicios_completos()"
# ===============================================

crear_portada_ejercicios <- function() {
  cat("Generando portada de ejercicios...\n")
  
  setwd("ejercicios")
  system("quarto render portada.qmd --to pdf")
  
  if (!file.exists("portada.pdf")) {
    setwd("..")  # Volver a la raíz antes del error
    stop("No se generó portada.pdf")
  }
  
  setwd("..")  # Volver a la raíz
  cat("Portada creada: ejercicios/portada.pdf\n")
}

crear_ejercicios <- function() {
  cat("Generando ejercicios...\n")
  
  # Cambiar temporalmente el _quarto.yml para usar pdflatex sin portada
  setwd("ejercicios")
  
  # Crear configuración temporal para el PDF sin portada
  config_temp <- '
project:
  type: book
  output-dir: ejercicios_pdf

book:
  title: "Ejercicios de Modelos Estadísticos de Predicción"
  author: "Víctor Aceña Gil & Isaac Martín de Diego"
  chapters:
    - index.qmd
    - tema0_intro.qmd
    - tema1_EDA1.qmd
    - tema1_EDA2.qmd
    - tema1_EDA3.qmd

format:
  pdf:
    documentclass: scrreprt
    title-block-banner: false 
    toc: true
    toc-depth: 3
    toc-title: "Índice de Ejercicios"
    number-sections: false
'
  
  # Guardar configuración original
  file.copy("_quarto.yml", "_quarto_original.yml")
  
  # Escribir configuración temporal
  writeLines(config_temp, "_quarto_temp.yml")
  
  # Renderizar con configuración temporal (copiando el archivo)
  file.copy("_quarto_temp.yml", "_quarto.yml", overwrite = TRUE)
  system("quarto render")
  
  # Restaurar configuración original
  file.copy("_quarto_original.yml", "_quarto.yml", overwrite = TRUE)
  file.remove(c("_quarto_original.yml", "_quarto_temp.yml"))
  
  setwd("..")  # Volver a la raíz
  cat("Ejercicios creados en ejercicios/ejercicios_pdf/\n")
}

unir_pdfs_ejercicios <- function() {
  cat("Procesando PDFs de ejercicios...\n")
  
  setwd("ejercicios")
  
  # Buscar el archivo de ejercicios
  pdf_files <- list.files("ejercicios_pdf", pattern = "\\.pdf$", full.names = FALSE)
  ejercicios_pdf <- pdf_files[1]
  
  setwd("ejercicios_pdf")
  
  # Quitar primera página del libro de ejercicios
  system(paste0("pdftk ", ejercicios_pdf, " cat 2-end output ejercicios_sin_primera.pdf"))
  
  # Unir portada + ejercicios sin primera página  
  system("pdftk ../portada.pdf ejercicios_sin_primera.pdf cat output EjerciciosInferenciaEstadistica.pdf")
  
  # Limpiar temporales
  file.remove(c(ejercicios_pdf, "ejercicios_sin_primera.pdf"))
  
  setwd("..")
  
  # Borrar portada original
  file.remove("portada.pdf")
  
  setwd("..")
  
  cat("Ejercicios completos: ejercicios/ejercicios_pdf/EjerciciosInferenciaEstadistica.pdf\n")
}

crear_ejercicios_completos <- function() {
  crear_portada_ejercicios()
  crear_ejercicios()
  unir_pdfs_ejercicios()
  cat("¡Proceso de ejercicios completado!\n")
}
