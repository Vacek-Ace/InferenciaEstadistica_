# ===============================================
# Script para generar ejercicios resueltos completos con portada personalizada
# Ejecutar desde la RAÍZ del proyecto  
# Uso: Rscript -e "source('ejercicios_resueltos/generar_soluciones.R'); crear_soluciones_completas()"
# ===============================================

crear_portada_soluciones <- function() {
  cat("Generando portada de soluciones...\n")
  
  setwd("ejercicios_resueltos")
  system("quarto render portada.qmd --to pdf")
  
  if (!file.exists("portada.pdf")) {
    setwd("..")  # Volver a la raíz antes del error
    stop("No se generó portada.pdf")
  }
  
  setwd("..")  # Volver a la raíz
  cat("Portada creada: ejercicios_resueltos/portada.pdf\n")
}

crear_soluciones <- function() {
  cat("Generando soluciones...\n")
  
  # Cambiar temporalmente al directorio de ejercicios resueltos
  setwd("ejercicios_resueltos")
  
  # Crear configuración temporal para el PDF sin portada
  config_temp <- '
project:
  type: book
  output-dir: soluciones_pdf

book:
  title: "Problemas de Modelos Estadísticos para la Predicción"
  subtitle: "Ejercicios resueltos paso a paso"
  author: 
    - name: "Víctor Aceña Gil"
    - name: "Isaac Martín de Diego"
  chapters:
    - index.qmd
    - tema0_intro_solucion.qmd
    - tema1_EDA1_solucion.qmd
    - tema1_EDA2_solucion.qmd


format:
  pdf:
    documentclass: scrreprt
    title-block-banner: false 
    toc: true
    toc-depth: 3
    toc-title: "Índice de Soluciones"
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
  cat("Soluciones creadas en ejercicios_resueltos/soluciones_pdf/\n")
}

unir_pdfs_soluciones <- function() {
  cat("Procesando PDFs de soluciones...\n")
  
  setwd("ejercicios_resueltos")
  
  # Buscar el archivo de soluciones
  pdf_files <- list.files("soluciones_pdf", pattern = "\\.pdf$", full.names = FALSE)
  soluciones_pdf <- pdf_files[1]
  
  setwd("soluciones_pdf")
  
  # Quitar primera página del libro de soluciones
  system(paste0("pdftk ", soluciones_pdf, " cat 2-end output soluciones_sin_primera.pdf"))
  
  # Unir portada + soluciones sin primera página  
  system("pdftk ../portada.pdf soluciones_sin_primera.pdf cat output SolucionesModelosEstadisticosPrediccion.pdf")
  
  # Limpiar temporales
  file.remove(c(soluciones_pdf, "soluciones_sin_primera.pdf"))
  
  setwd("..")
  
  # Borrar portada original
  file.remove("portada.pdf")
  
  setwd("..")
  
  cat("Libro completo: ejercicios_resueltos/soluciones_pdf/SolucionesModelosEstadisticosPrediccion.pdf\n")
}

crear_soluciones_completas <- function() {
  cat("=== GENERANDO SOLUCIONES COMPLETAS ===\n")
  
  # Verificar que estamos en la raíz del proyecto
  if (!file.exists("_quarto.yml")) {
    stop("Este script debe ejecutarse desde la raíz del proyecto")
  }
  
  tryCatch({
    crear_portada_soluciones()
    crear_soluciones()
    unir_pdfs_soluciones()
    
    cat("✅ PROCESO COMPLETADO\n")
    cat("📁 Archivo final: ejercicios_resueltos/soluciones_pdf/SolucionesModelosEstadisticosPrediccion.pdf\n")
    cat("¡Proceso completado!\n")
    
  }, error = function(e) {
    cat("❌ Error:", e$message, "\n")
    # Asegurar que volvemos al directorio raíz
    if (basename(getwd()) == "ejercicios_resueltos" || basename(getwd()) == "soluciones_pdf") {
      setwd("..")
      if (basename(getwd()) == "ejercicios_resueltos") {
        setwd("..")
      }
    }
    stop(e)
  })
}

# ===============================================
# FUNCIONES PARA HTML (MANTENIENDO COMPATIBILIDAD)
# ===============================================

generar_todas_soluciones <- function() {
  cat("=== GENERANDO TODAS LAS SOLUCIONES EN HTML ===\n")
  
  # Verificar que estamos en la raíz del proyecto
  if (!file.exists("_quarto.yml")) {
    stop("Este script debe ejecutarse desde la raíz del proyecto")
  }
  
  tryCatch({
    cat("Generando todas las soluciones en HTML...\n")
    
    # Cambiar al directorio de ejercicios resueltos
    setwd("ejercicios_resueltos")
    
    # Renderizar todo el libro de soluciones en HTML
    cat("Renderizando libro completo de soluciones...\n")
    system("quarto render --to html")
    
    # Volver al directorio raíz
    setwd("..")
    
    cat("✅ PROCESO COMPLETADO\n")
    cat("📁 Libro de soluciones generado en: ejercicios_resueltos/soluciones_html/\n")
    cat("📁 Archivo principal: ejercicios_resueltos/soluciones_html/index.html\n")
    cat("¡Proceso completado!\n")
    
  }, error = function(e) {
    cat("❌ Error:", e$message, "\n")
    # Asegurar que volvemos al directorio raíz
    if (basename(getwd()) == "ejercicios_resueltos") {
      setwd("..")
    }
    stop(e)
  })
}

# Función para generar una solución específica
generar_solucion <- function(tema) {
  archivo <- paste0("tema", tema, "_soluciones.qmd")
  if (tema == 1) archivo <- "tema1_regresion_simple_soluciones.qmd"
  if (tema == 2) archivo <- "tema2_regresion_multiple_soluciones.qmd"
  if (tema == 3) archivo <- "tema3_ingenieria_caracteristicas_soluciones.qmd"
  if (tema == 4) archivo <- "tema4_seleccion_validacion_soluciones.qmd"
  if (tema == 5) archivo <- "tema5_glm_soluciones.qmd"
  if (tema == "avanzados") archivo <- "ejercicios_avanzados_soluciones.qmd"
  
  cat("Generando solución:", archivo, "\n")
  
  setwd("ejercicios_resueltos")
  system(paste("quarto render", archivo, "--to html"))
  setwd("..")
  
  cat("✓ Solución generada\n")
}

# Función para abrir las soluciones en el navegador
abrir_soluciones <- function() {
  # Detectar si estamos en el directorio de ejercicios_resueltos o en la raíz
  if (basename(getwd()) == "ejercicios_resueltos") {
    ruta_index <- file.path("soluciones_html", "index.html")
  } else {
    ruta_index <- file.path("ejercicios_resueltos", "soluciones_html", "index.html")
  }
  
  # Convertir a ruta absoluta
  ruta_index <- normalizePath(ruta_index, mustWork = FALSE)
  
  if (file.exists(ruta_index)) {
    # Abrir en el navegador predeterminado
    if (.Platform$OS.type == "windows") {
      shell.exec(ruta_index)
    } else if (Sys.info()["sysname"] == "Darwin") {
      system(paste("open", ruta_index))
    } else {
      system(paste("xdg-open", ruta_index))
    }
    cat("✓ Soluciones abiertas en el navegador\n")
    cat("📁 Ubicación:", ruta_index, "\n")
  } else {
    cat("✗ Archivo de soluciones no encontrado. Ejecuta primero generar_todas_soluciones()\n")
    cat("📁 Buscando en:", ruta_index, "\n")
    cat("📁 Directorio actual:", getwd(), "\n")
  }
}

# ===============================================
# FUNCIÓN DE AYUDA
# ===============================================

mostrar_ayuda_soluciones <- function() {
  cat("=== GENERADOR DE EJERCICIOS RESUELTOS ===\n")
  cat("Funciones disponibles:\n\n")
  cat("📘 crear_soluciones_completas() - Genera PDF unificado con portada profesional\n")
  cat("🌐 generar_todas_soluciones()   - Genera libro HTML completo\n") 
  cat("📄 generar_solucion(tema)       - Genera una solución específica\n")
  cat("🌍 abrir_soluciones()           - Abre las soluciones HTML en el navegador\n")
  cat("❓ mostrar_ayuda_soluciones()   - Muestra esta ayuda\n\n")
  cat("Ejemplos:\n")
  cat('Rscript -e "source(\'ejercicios_resueltos/generar_soluciones.R\'); crear_soluciones_completas()"\n')
  cat('Rscript -e "source(\'ejercicios_resueltos/generar_soluciones.R\'); generar_todas_soluciones()"\n')
  cat('Rscript -e "source(\'ejercicios_resueltos/generar_soluciones.R\'); generar_solucion(1)"\n')
  cat('Rscript -e "source(\'ejercicios_resueltos/generar_soluciones.R\'); abrir_soluciones()"\n')
}
