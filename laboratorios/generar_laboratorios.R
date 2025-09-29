# ===============================================
# Script para generar laboratorios completos con portada personalizada
# Ejecutar desde la RAÍZ del proyecto  
# Uso: Rscript -e "source('laboratorios/generar_laboratorios.R'); crear_laboratorios_completos()"
# ===============================================

# ===============================================
# Script para generar laboratorios completos con portada personalizada
# Ejecutar desde la RAÍZ del proyecto  
# Uso: Rscript -e "source('laboratorios/generar_laboratorios.R'); crear_laboratorios_completos()"
# ===============================================

# ===============================================
# Script CORREGIDO para generar laboratorios
# ===============================================

crear_portada_laboratorios <- function() {
  cat("Generando portada de laboratorios...\n")
  dir_original <- getwd()
  
  if (!dir.exists("laboratorios")) {
    stop("Error: Este script debe ejecutarse desde la raíz del proyecto")
  }
  
  setwd("laboratorios")
  
  if (!file.exists("portada.qmd")) {
    setwd(dir_original)
    stop("Error: No se encuentra laboratorios/portada.qmd")
  }
  
  system("quarto render portada.qmd --to pdf")
  
  if (!file.exists("portada.pdf")) {
    setwd(dir_original)
    stop("Error: No se generó portada.pdf")
  }
  
  setwd(dir_original)
  cat("✓ Portada creada\n")
}

crear_laboratorios <- function() {
  cat("Generando laboratorios...\n")
  dir_original <- getwd()
  setwd("laboratorios")
  
  # Configuración con correcciones para LaTeX
  config_temp <- '
project:
  type: book
  output-dir: laboratorios_pdf

book:
  title: "Laboratorios de Inferencia Estadística"
  author: 
    - "Víctor Aceña Gil"
    - "Isaac Martín de Diego"
    - "Carmen Lancho Martín"
  chapters:
    - index.qmd
    - laboratorio_descriptiva.qmd
    - laboratorio_VVAA.qmd
    - laboratorio_muestreo.qmd
    - laboratorio_estimacion_contraste.qmd

format:
  pdf:
    documentclass: scrreprt
    title-block-banner: false 
    toc: true
    toc-depth: 3
    toc-title: "Índice de Laboratorios"
    number-sections: false
    keep-tex: false
    include-in-header:
      text: |
        \\usepackage{xcolor}
        \\usepackage{tcolorbox}
        \\usepackage{framed}
        
        % Entorno rmdpractica
        \\definecolor{practicabg}{RGB}{255, 250, 240}
        \\definecolor{practicaborder}{RGB}{255, 165, 0}
        \\newtcolorbox{rmdpractica}{
          colback=practicabg,
          colframe=practicaborder,
          boxrule=1pt,
          arc=3pt,
          left=6pt,
          right=6pt,
          top=6pt,
          bottom=6pt,
          title={\\textbf{Práctica:}},
          fonttitle=\\bfseries
        }
        
        % Entorno rmdinfo
        \\definecolor{infobg}{RGB}{240, 248, 255}
        \\definecolor{infoborder}{RGB}{70, 130, 180}
        \\newtcolorbox{rmdinfo}{
          colback=infobg,
          colframe=infoborder,
          boxrule=1pt,
          arc=3pt,
          left=6pt,
          right=6pt,
          top=6pt,
          bottom=6pt,
          title={\\textbf{Información:}},
          fonttitle=\\bfseries
        }
        
        % Entorno rmdnote
        \\definecolor{notebg}{RGB}{255, 255, 224}
        \\definecolor{noteborder}{RGB}{218, 165, 32}
        \\newtcolorbox{rmdnote}{
          colback=notebg,
          colframe=noteborder,
          boxrule=1pt,
          arc=3pt,
          left=6pt,
          right=6pt,
          top=6pt,
          bottom=6pt,
          title={\\textbf{Nota:}},
          fonttitle=\\bfseries
        }
        
        % Entorno rmdwarning
        \\definecolor{warningbg}{RGB}{255, 240, 240}
        \\definecolor{warningborder}{RGB}{220, 20, 60}
        \\newtcolorbox{rmdwarning}{
          colback=warningbg,
          colframe=warningborder,
          boxrule=1pt,
          arc=3pt,
          left=6pt,
          right=6pt,
          top=6pt,
          bottom=6pt,
          title={\\textbf{Advertencia:}},
          fonttitle=\\bfseries
        }
'
  
  if (file.exists("_quarto.yml")) {
    file.copy("_quarto.yml", "_quarto_original.yml", overwrite = TRUE)
  }
  
  writeLines(config_temp, "_quarto_temp.yml")
  file.copy("_quarto_temp.yml", "_quarto.yml", overwrite = TRUE)
  
  cat("Renderizando con Quarto...\n")
  resultado <- system("quarto render", intern = FALSE, ignore.stderr = FALSE)
  
  if (file.exists("_quarto_original.yml")) {
    file.copy("_quarto_original.yml", "_quarto.yml", overwrite = TRUE)
    file.remove("_quarto_original.yml")
  }
  
  if (file.exists("_quarto_temp.yml")) {
    file.remove("_quarto_temp.yml")
  }
  
  setwd(dir_original)
  
  if (resultado != 0) {
    stop("Error: Quarto render falló")
  }
  
  cat("✓ Laboratorios renderizados\n")
}

unir_pdfs_laboratorios <- function() {
  cat("Uniendo PDFs...\n")
  dir_original <- getwd()
  setwd("laboratorios")
  
  pdf_files <- list.files("laboratorios_pdf", pattern = "\\.pdf$", full.names = FALSE)
  
  if (length(pdf_files) == 0) {
    setwd(dir_original)
    stop("Error: No se encontraron PDFs")
  }
  
  laboratorios_pdf <- pdf_files[1]
  setwd("laboratorios_pdf")
  
  if (system("pdftk --version", ignore.stdout = TRUE, ignore.stderr = TRUE) != 0) {
    setwd(dir_original)
    cat("\n⚠ pdftk no disponible. Unir manualmente:\n")
    cat("  1. laboratorios/portada.pdf\n")
    cat("  2. laboratorios/laboratorios_pdf/", laboratorios_pdf, "\n")
    return(invisible(NULL))
  }
  
  system(paste0("pdftk ", laboratorios_pdf, " cat 2-end output lab_sin_portada.pdf"))
  system("pdftk ../portada.pdf lab_sin_portada.pdf cat output LaboratoriosInferenciaEstadistica.pdf")
  
  file.remove(c(laboratorios_pdf, "lab_sin_portada.pdf"))
  
  setwd("..")
  if (file.exists("portada.pdf")) file.remove("portada.pdf")
  
  setwd(dir_original)
  cat("✓ PDF final creado\n")
}

crear_laboratorios_completos <- function() {
  cat("\n=== GENERACIÓN DE LABORATORIOS ===\n\n")
  
  tryCatch({
    crear_portada_laboratorios()
    crear_laboratorios()
    unir_pdfs_laboratorios()
    cat("\n✓ ¡Proceso completado!\n")
    cat("Archivo: laboratorios/laboratorios_pdf/LaboratoriosInferenciaEstadistica.pdf\n")
  }, error = function(e) {
    cat("\n❌ Error:\n", conditionMessage(e), "\n")
  })
}

crear_laboratorios_completos <- function() {
  cat("\n=== GENERACIÓN DE LABORATORIOS COMPLETOS ===\n\n")
  
  tryCatch({
    crear_portada_laboratorios()
    crear_laboratorios()
    unir_pdfs_laboratorios()
    cat("\n¡Proceso de laboratorios completado con éxito!\n")
  }, error = function(e) {
    cat("\n❌ Error durante el proceso:\n")
    cat(conditionMessage(e), "\n")
  })
}

# Función de ayuda
verificar_entorno <- function() {
  cat("=== VERIFICACIÓN DEL ENTORNO ===\n")
  
  cat("\n1. Directorio actual:", getwd(), "\n")
  
  cat("\n2. Estructura de directorios:\n")
  if (dir.exists("laboratorios")) {
    cat("  ✓ laboratorios/ existe\n")
    if (file.exists("laboratorios/portada.qmd")) {
      cat("  ✓ laboratorios/portada.qmd existe\n")
    } else {
      cat("  ✗ laboratorios/portada.qmd NO existe\n")
    }
    if (file.exists("laboratorios/_quarto.yml")) {
      cat("  ✓ laboratorios/_quarto.yml existe\n")
    } else {
      cat("  ✗ laboratorios/_quarto.yml NO existe\n")
    }
  } else {
    cat("  ✗ laboratorios/ NO existe\n")
  }
  
  cat("\n3. Quarto:\n")
  if (system("quarto --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0) {
    cat("  ✓ Quarto disponible\n")
  } else {
    cat("  ✗ Quarto NO disponible\n")
  }
  
  cat("\n4. pdftk:\n")
  if (system("pdftk --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0) {
    cat("  ✓ pdftk disponible\n")
  } else {
    cat("  ⚠ pdftk NO disponible (opcional)\n")
  }
  
  cat("\n")
}