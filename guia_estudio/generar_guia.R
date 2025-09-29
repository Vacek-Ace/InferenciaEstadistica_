# ===============================================
# Script para generar guía de estudio con portada
# Ejecutar desde la RAÍZ del proyecto  
# Uso: Rscript -e "source('guia_estudio/generar_guia.R'); crear_guia()"
# ===============================================

library(quarto)
library(pdftools)

#' Función para crear portada con WeasyPrint
crear_portada_guia <- function() {
  cat("1. Creando portada con WeasyPrint...\n")
  
  dir_original <- getwd()
  
  tryCatch({
    setwd("guia_estudio")
    
    # Crear portada.qmd temporal que usa portada.html
    portada_content <- '---
format:
  pdf:
    pdf-engine: weasyprint
    include-before-body: portada.html
    css: ../estilos.css
---
'
    
    writeLines(portada_content, "portada_temp.qmd")
    
    # Renderizar portada
    quarto_render("portada_temp.qmd", output_file = "portada_temp.pdf", quiet = TRUE)
    
    if (!file.exists("portada_temp.pdf")) {
      stop("No se generó la portada")
    }
    
    cat("   ✓ Portada creada\n")
    
  }, error = function(e) {
    cat("   ✗ Error creando portada:", e$message, "\n")
    stop(e)
  }, finally = {
    setwd(dir_original)
  })
}

#' Función para crear contenido de la guía con LaTeX
crear_contenido_guia <- function() {
  cat("2. Creando contenido de la guía con LaTeX...\n")
  
  dir_original <- getwd()
  
  tryCatch({
    setwd("guia_estudio")
    
    # Leer contenido original
    contenido_original <- readLines("guia_estudio.qmd")
    
    # Encontrar dónde termina el YAML
    yaml_end <- which(grepl("^---$", contenido_original))[2]
    contenido_sin_yaml <- contenido_original[(yaml_end + 1):length(contenido_original)]
    
    # Crear nuevo YAML para LaTeX (sin portada.html)
    yaml_latex <- '---
lang: es
format:
  pdf:
    documentclass: scrreprt
    pdf-engine: pdflatex
    title-block-banner: false 
    toc: true
    toc-title: "Índice de contenidos"
    number-sections: true
    geometry:
      - margin=2.5cm
    fontsize: 11pt
---
'
    
    # Crear archivo temporal
    writeLines(c(yaml_latex, "", contenido_sin_yaml), "contenido_temp.qmd")
    
    # Renderizar con LaTeX
    quarto_render("contenido_temp.qmd", output_file = "contenido_temp.pdf", quiet = FALSE)
    
    if (!file.exists("contenido_temp.pdf")) {
      stop("No se generó el contenido")
    }
    
    cat("   ✓ Contenido creado\n")
    
  }, error = function(e) {
    cat("   ✗ Error creando contenido:", e$message, "\n")
    stop(e)
  }, finally = {
    setwd(dir_original)
  })
}

#' Función para unir los PDFs
unir_pdfs_guia <- function(nombre_salida = "GuiaEstudioModelosEstadisticosPrediccion.pdf") {
  cat("3. Uniendo PDFs...\n")
  
  dir_original <- getwd()
  
  tryCatch({
    setwd("guia_estudio")
    
    if (!file.exists("portada_temp.pdf") || !file.exists("contenido_temp.pdf")) {
      stop("Faltan archivos PDF para unir")
    }
    
    # Unir con pdftools
    pdf_combine(
      input = c("portada_temp.pdf", "contenido_temp.pdf"),
      output = nombre_salida
    )
    
    if (!file.exists(nombre_salida)) {
      stop("No se pudo crear el PDF final")
    }
    
    # Limpiar archivos temporales
    archivos_temp <- c("portada_temp.qmd", "portada_temp.pdf", 
                       "contenido_temp.qmd", "contenido_temp.pdf")
    
    for (archivo in archivos_temp) {
      if (file.exists(archivo)) {
        file.remove(archivo)
      }
    }
    
    cat("   ✓ PDFs unidos correctamente\n")
    cat("   ✓ Archivos temporales eliminados\n")
    
  }, error = function(e) {
    cat("   ✗ Error uniendo PDFs:", e$message, "\n")
    stop(e)
  }, finally = {
    setwd(dir_original)
  })
}

#' Función principal para crear la guía completa
crear_guia <- function(nombre_salida = "GuiaEstudioModelosEstadisticosPrediccion.pdf") {
  
  cat("=== CREANDO GUÍA DE ESTUDIO ===\n\n")
  
  # Verificar que estamos en la raíz del proyecto
  if (!file.exists("_quarto.yml")) {
    stop("Error: Este script debe ejecutarse desde la raíz del proyecto")
  }
  
  # Verificar archivos necesarios
  archivos_necesarios <- c(
    "guia_estudio/guia_estudio.qmd",
    "guia_estudio/portada.html",
    "estilos.css"
  )
  
  for (archivo in archivos_necesarios) {
    if (!file.exists(archivo)) {
      stop(paste("Error: No se encontró", archivo))
    }
  }
  
  # Proceso de creación
  crear_portada_guia()
  crear_contenido_guia()
  unir_pdfs_guia(nombre_salida)
  
  # Mostrar información del resultado
  cat("\n=== INFORMACIÓN DEL RESULTADO ===\n")
  ruta_completa <- file.path("guia_estudio", nombre_salida)
  
  if (file.exists(ruta_completa)) {
    info <- file.info(ruta_completa)
    cat("Archivo:", ruta_completa, "\n")
    cat("Tamaño:", round(info$size / 1024 / 1024, 2), "MB\n")
    
    tryCatch({
      num_paginas <- pdf_length(ruta_completa)
      cat("Páginas totales:", num_paginas, "\n")
    }, error = function(e) {
      cat("Páginas: (no se pudo determinar)\n")
    })
  }
  
  cat("\n=== PROCESO COMPLETADO ===\n")
  cat("✓ Portada (WeasyPrint con HTML)\n")
  cat("✓ Contenido (LaTeX para calidad tipográfica)\n")
  cat("✓ PDFs unidos correctamente\n")
  cat("Archivo final:", ruta_completa, "\n")
  
  return(ruta_completa)
}

#' Función de verificación
check_guia <- function() {
  cat("=== VERIFICACIÓN DEL ENTORNO ===\n")
  
  # Verificar raíz del proyecto
  if (!file.exists("_quarto.yml")) {
    cat("✗ No se encontró _quarto.yml\n")
    return(FALSE)
  } else {
    cat("✓ Ejecutando desde la raíz del proyecto\n")
  }
  
  # Verificar paquetes R
  paquetes <- c("pdftools", "quarto")
  for (pkg in paquetes) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat("✓", pkg, "instalado\n")
    } else {
      cat("✗", pkg, "NO instalado\n")
    }
  }
  
  # Verificar archivos necesarios
  archivos <- c(
    "guia_estudio/guia_estudio.qmd",
    "guia_estudio/portada.html",
    "estilos.css"
  )
  
  for (archivo in archivos) {
    if (file.exists(archivo)) {
      cat("✓", archivo, "\n")
    } else {
      cat("✗", archivo, "NO encontrado\n")
    }
  }
  
  # Verificar logo
  logos_posibles <- c(
    "images/urjc_logo.png",
    "images/URJClogo.jpg"
  )
  
  logo_encontrado <- FALSE
  for (logo in logos_posibles) {
    if (file.exists(logo)) {
      cat("✓ Logo encontrado en:", logo, "\n")
      logo_encontrado <- TRUE
      break
    }
  }
  
  if (!logo_encontrado) {
    cat("⚠ Logo NO encontrado\n")
  }
  
  cat("\n")
}

# Mensaje de bienvenida
cat("=== GENERADOR DE GUÍA DE ESTUDIO ===\n")
cat("Funciones disponibles:\n")
cat("  check_guia()  - Verificar entorno\n")
cat("  crear_guia()  - Crear guía completa\n")
cat("\nCaracterísticas:\n")
cat("✓ Portada HTML con WeasyPrint\n")
cat("✓ Contenido con LaTeX (mejor tipografía)\n")
cat("✓ Unión automática de PDFs\n")
cat("\nEjemplo: crear_guia()\n\n")
