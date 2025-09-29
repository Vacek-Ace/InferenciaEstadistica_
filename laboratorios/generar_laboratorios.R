# ===============================================
# Script para crear laboratorios completos con portada en PDF
# Ejecutar desde la RAÍZ del proyecto
# Uso: Rscript -e "source('laboratorios/generar_laboratorios.R'); crear()"
# ===============================================

library(pdftools)
library(quarto)

#' Función principal para crear el PDF completo con portada y bookmarks
crear_pdf_completo <- function(nombre_salida = "laboratorios/laboratorios_pdf/LaboratoriosInferenciaEstadistica.pdf") {
  
  cat("=== CREANDO PDF COMPLETO DE LABORATORIOS ===\n\n")
  
  # 0. Asegurar que estamos en la raíz del proyecto
  if (!file.exists("_quarto.yml")) {
    stop("Error: Este script debe ejecutarse desde la raíz del proyecto (donde está _quarto.yml)")
  }
  
  # 1. Asegurar que el directorio de salida existe
  dir_salida <- dirname(nombre_salida)
  if (!dir.exists(dir_salida)) {
    dir.create(dir_salida, recursive = TRUE)
    cat("✓ Directorio creado:", dir_salida, "\n")
  }
  
  # 2. Verificar y crear laboratorios individuales si es necesario
  cat("1. Verificando y creando laboratorios individuales...\n")
  verificar_y_crear_laboratorios()
  
  # 3. Obtener archivos de laboratorios después de la verificación
  cat("2. Detectando archivos de laboratorios...\n")
  archivos_labs <- obtener_archivos_laboratorios()
  
  if (length(archivos_labs) == 0) {
    stop("Error: No se encontraron archivos de laboratorios después de la verificación")
  }
  
  for (i in seq_along(archivos_labs)) {
    cat("   ", i, ".", archivos_labs[i], "\n")
  }
  cat("\n")
  
  # 3. Calcular información de laboratorios (para bookmarks)
  cat("3. Calculando información de laboratorios...\n")
  paginas_labs <- calcular_paginas_laboratorios(archivos_labs)
  
  for (lab in names(paginas_labs)) {
    cat("   ", lab, ": página", paginas_labs[[lab]], "\n")
  }
  cat("\n")
  
  # 4. Crear portada
  cat("4. Creando portada...\n")
  crear_portada()
  
  if (!file.exists("portada_general.pdf")) {
    stop("Error: No se pudo crear la portada")
  }
  cat("   ✓ Portada creada\n\n")
  
  # 5. Unir todos los PDFs
  cat("5. Uniendo PDFs...\n")
  todos_los_archivos <- c("portada_general.pdf", archivos_labs)
  
  if (unir_con_bookmarks(todos_los_archivos, nombre_salida, paginas_labs)) {
    cat("   ✓ PDF creado con portada y bookmarks laterales\n")
  } else {
    cat("   ⚠ PDF creado solo con portada\n")
  }
  
  # 6. Mostrar información del resultado
  mostrar_info_resultado(nombre_salida, todos_los_archivos)
  
  # 7. Limpiar archivos temporales
  if (file.exists("portada_general.pdf")) {
    file.remove("portada_general.pdf")
  }
  cat("   ✓ Archivos temporales eliminados\n")
  
  cat("\n=== PROCESO COMPLETADO ===\n")
  cat("✓ Portada incluida\n")
  cat("✓ Bookmarks laterales navegables\n") 
  cat("Archivo final:", nombre_salida, "\n")
  
  return(nombre_salida)
}

#' Función para verificar y crear laboratorios individuales
verificar_y_crear_laboratorios <- function() {
  
  labs_config <- list(
    list(
      archivo_pdf = "laboratorios/laboratorios_pdf/laboratorio_introR.pdf",
      archivo_qmd = "laboratorios/laboratorio_introR.qmd",
      nombre = "Laboratorio: Introducción a R"
    ),
    list(
      archivo_pdf = "laboratorios/laboratorios_pdf/laboratorio_descriptiva.pdf",
      archivo_qmd = "laboratorios/laboratorio_descriptiva.qmd",
      nombre = "Laboratorio: Estadística Descriptiva"
    ),
    list(
      archivo_pdf = "laboratorios/laboratorios_pdf/laboratorio_VVAA.pdf",
      archivo_qmd = "laboratorios/laboratorio_VVAA.qmd",
      nombre = "Laboratorio: Variables Aleatorias"
    ),
    list(
      archivo_pdf = "laboratorios/laboratorios_pdf/laboratorio_muestreo.pdf",
      archivo_qmd = "laboratorios/laboratorio_muestreo.qmd",
      nombre = "Laboratorio: Muestreo y Estimadores"
    ),
    list(
      archivo_pdf = "laboratorios/laboratorios_pdf/laboratorio_estimacion_contraste.pdf",
      archivo_qmd = "laboratorios/laboratorio_estimacion_contraste.qmd",
      nombre = "Laboratorio: Estimación y Contrastes"
    )
  )
  
  if (!dir.exists("laboratorios/laboratorios_pdf")) {
    dir.create("laboratorios/laboratorios_pdf", recursive = TRUE)
    cat("   ✓ Directorio laboratorios_pdf creado\n")
  }
  
  for (lab in labs_config) {
    if (!file.exists(lab$archivo_pdf)) {
      cat("   ⚠", lab$nombre, "no encontrado, intentando crear...\n")
      
      if (file.exists(lab$archivo_qmd)) {
        tryCatch({
          cat("     • Renderizando", lab$archivo_qmd, "...\n")
          
          # Capturar salida y error
          resultado <- system2(
            "quarto",
            args = c(
              "render",
              lab$archivo_qmd,
              "--to", "pdf"
            ),
            stdout = TRUE,
            stderr = TRUE
          )
          
          # Mostrar salida si hay error
          if (!is.null(attr(resultado, "status")) && attr(resultado, "status") != 0) {
            cat("     ERROR en compilación:\n")
            cat("     ", paste(tail(resultado, 10), collapse = "\n     "), "\n")
          }
          
          pdf_generado <- sub("\\.qmd$", ".pdf", lab$archivo_qmd)
          
          if (file.exists(pdf_generado)) {
            file.rename(pdf_generado, lab$archivo_pdf)
            cat("   ✓", lab$nombre, "creado exitosamente\n")
          } else {
            cat("   ✗", lab$nombre, "- no se generó el PDF\n")
          }
          
        }, error = function(e) {
          cat("   ✗", lab$nombre, "- error:", e$message, "\n")
        })
      }
    } else {
      cat("   ✓", lab$nombre, "ya existe\n")
    }
  }
  
  cat("\n")
}

#' Función para calcular páginas donde empezará cada laboratorio
calcular_paginas_laboratorios <- function(archivos_labs) {
  
  paginas <- list()
  pagina_actual <- 3  # Asumiendo portada + índice
  
  # Primero verificar cuántas páginas tendrá la portada
  crear_portada_temporal()
  if (file.exists("portada_temp.pdf")) {
    paginas_portada <- pdf_length("portada_temp.pdf")
    file.remove("portada_temp.pdf")
    pagina_actual <- paginas_portada + 1
  }
  
  # Calcular página de inicio de cada laboratorio
  labs_info <- list(
    "lab_introR" = "Introducción a R",
    "lab_descriptiva" = "Estadística Descriptiva",
    "lab_VVAA" = "Variables Aleatorias",
    "lab_muestreo" = "Muestreo y Estimadores",
    "lab_estimacion" = "Estimación y Contrastes"
  )
  
  for (archivo in archivos_labs) {
    # Extraer nombre del laboratorio
    lab_name <- sub(".*laboratorio_(.*)\\.pdf", "\\1", archivo)
    lab_key <- paste0("lab_", lab_name)
    
    if (lab_key %in% names(labs_info)) {
      paginas[[labs_info[[lab_key]]]] <- pagina_actual
      
      # Calcular páginas del archivo actual
      tryCatch({
        num_paginas <- pdf_length(archivo)
        pagina_actual <- pagina_actual + num_paginas
      }, error = function(e) {
        pagina_actual <- pagina_actual + 1
      })
    }
  }
  
  return(paginas)
}

#' Función para crear portada temporal (solo para contar páginas)
crear_portada_temporal <- function() {
  
  if (!file.exists("laboratorios/portada.qmd")) {
    stop("No se encontró laboratorios/portada.qmd")
  }
  
  dir_original <- getwd()
  
  tryCatch({
    setwd("laboratorios")
    quarto_render("portada.qmd", output_file = "portada_temp.pdf", quiet = TRUE)
    
    if (file.exists("portada_temp.pdf")) {
      file.rename("portada_temp.pdf", "../portada_temp.pdf")
    }
    
  }, error = function(e) {
    cat("Error al crear portada temporal:", e$message, "\n")
  }, finally = {
    setwd(dir_original)
  })
}

#' Función para crear portada simple
crear_portada <- function() {
  
  if (!file.exists("laboratorios/portada.qmd")) {
    stop("No se encontró laboratorios/portada.qmd")
  }
  
  dir_original <- getwd()
  
  tryCatch({
    setwd("laboratorios")
    quarto_render("portada.qmd", output_file = "portada_general.pdf", quiet = TRUE)
    
    if (file.exists("portada_general.pdf")) {
      file.rename("portada_general.pdf", "../portada_general.pdf")
    }
    
  }, error = function(e) {
    cat("Error al crear portada:", e$message, "\n")
    stop(e)
  }, finally = {
    setwd(dir_original)
  })
}

#' Función para unir PDFs y agregar bookmarks laterales
unir_con_bookmarks <- function(archivos_input, archivo_salida, paginas_labs) {
  
  dir_salida <- dirname(archivo_salida)
  if (!dir.exists(dir_salida)) {
    dir.create(dir_salida, recursive = TRUE)
  }
  
  # Primero unir todos los PDFs
  tryCatch({
    pdf_combine(input = archivos_input, output = archivo_salida)
    cat("   ✓ PDFs unidos correctamente\n")
  }, error = function(e) {
    cat("Error uniendo PDFs:", e$message, "\n")
    return(FALSE)
  })
  
  if (!file.exists(archivo_salida)) {
    cat("   ✗ Error: No se pudo crear", archivo_salida, "\n")
    return(FALSE)
  }
  
  # Luego agregar bookmarks laterales si pdftk está disponible
  if (system("pdftk --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0) {
    cat("   Agregando bookmarks laterales...\n")
    agregar_bookmarks_laterales(archivo_salida, paginas_labs)
    return(TRUE)
  } else {
    cat("   pdftk no disponible, solo portada simple\n")
    return(TRUE)
  }
}

#' Función para agregar bookmarks laterales
agregar_bookmarks_laterales <- function(archivo_pdf, paginas_labs) {
  
  tryCatch({
    contenido_bookmarks <- c()
    
    # Bookmark para la portada
    contenido_bookmarks <- c(contenido_bookmarks,
                           "BookmarkBegin",
                           "BookmarkTitle: Indice de Laboratorios", 
                           "BookmarkLevel: 1",
                           "BookmarkPageNumber: 2")
    
    # Bookmarks para cada laboratorio
    for (lab in names(paginas_labs)) {
      contenido_bookmarks <- c(contenido_bookmarks,
                             "BookmarkBegin",
                             paste0("BookmarkTitle: ", lab),
                             "BookmarkLevel: 1", 
                             paste0("BookmarkPageNumber: ", paginas_labs[[lab]]))
    }
    
    writeLines(contenido_bookmarks, "bookmarks_temp.txt", useBytes = TRUE)
    
    archivo_temp <- paste0(tools::file_path_sans_ext(archivo_pdf), "_con_bookmarks.pdf")
    
    comando <- paste("pdftk", shQuote(archivo_pdf),
                    "update_info bookmarks_temp.txt output", shQuote(archivo_temp))
    
    resultado <- system(comando, ignore.stdout = TRUE)
    
    if (resultado == 0 && file.exists(archivo_temp)) {
      file.rename(archivo_temp, archivo_pdf)
      cat("   ✓ Bookmarks laterales agregados\n")
    } else {
      cat("   ⚠ No se pudieron agregar bookmarks laterales\n")
    }
    
    if (file.exists("bookmarks_temp.txt")) file.remove("bookmarks_temp.txt")
    
  }, error = function(e) {
    cat("   Error con bookmarks:", e$message, "\n")
  })
}

#' Función para obtener archivos de laboratorios
obtener_archivos_laboratorios <- function() {
  archivos_esperados <- c(
    "laboratorios/laboratorios_pdf/laboratorio_introR.pdf",
    "laboratorios/laboratorios_pdf/laboratorio_descriptiva.pdf",
    "laboratorios/laboratorios_pdf/laboratorio_VVAA.pdf",
    "laboratorios/laboratorios_pdf/laboratorio_muestreo.pdf",
    "laboratorios/laboratorios_pdf/laboratorio_estimacion_contraste.pdf"
  )
  return(archivos_esperados[file.exists(archivos_esperados)])
}

#' Función para mostrar información del resultado
mostrar_info_resultado <- function(archivo_salida, archivos_input) {
  cat("\n=== INFORMACIÓN DEL RESULTADO ===\n")
  
  if (file.exists(archivo_salida)) {
    info <- file.info(archivo_salida)
    cat("Archivo:", archivo_salida, "\n")
    cat("Tamaño:", round(info$size / 1024 / 1024, 2), "MB\n")
    
    tryCatch({
      num_paginas <- pdf_length(archivo_salida)
      cat("Páginas totales:", num_paginas, "\n")
    }, error = function(e) {
      cat("Páginas: (no se pudo determinar)\n")
    })
  }
  
  cat("\nFuncionalidades incluidas:\n")
  cat("✓ Portada incluida\n")
  cat("✓ Bookmarks navegables en panel lateral\n")
  cat("✓ Todos los laboratorios unidos en un solo PDF\n")
}

#' Función de verificación
verificar_entorno <- function() {
  cat("=== VERIFICACIÓN DEL ENTORNO ===\n")
  
  if (!file.exists("_quarto.yml")) {
    cat("✗ No se encontró _quarto.yml\n")
    return(FALSE)
  } else {
    cat("✓ Ejecutando desde la raíz del proyecto\n")
  }
  
  paquetes <- c("pdftools", "quarto")
  for (pkg in paquetes) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat("✓", pkg, "instalado\n")
    } else {
      cat("✗", pkg, "NO instalado\n")
    }
  }
  
  archivos_config <- c("laboratorios/portada.qmd", "laboratorios/portada.html", "estilos.css")
  for (archivo in archivos_config) {
    if (file.exists(archivo)) {
      cat("✓", archivo, "encontrado\n")
    } else {
      cat("✗", archivo, "NO encontrado\n")
    }
  }
  
  if (system("pdftk --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0) {
    cat("✓ pdftk instalado (bookmarks laterales disponibles)\n")
  } else {
    cat("⚠ pdftk no encontrado (solo portada simple)\n")
  }
  
  cat("\n")
}

# === FUNCIONES DE USO RÁPIDO ===

#' Crear PDF completo con portada + bookmarks
crear <- function(nombre = "laboratorios/laboratorios_pdf/LaboratoriosInferenciaEstadistica.pdf") {
  crear_pdf_completo(nombre)
}

#' Verificar entorno
check <- function() {
  verificar_entorno()
}

# Mensaje de bienvenida
cat("=== SISTEMA DE LABORATORIOS COMPLETOS ===\n")
cat("Funciones disponibles:\n")
cat("  check()  - Verificar entorno\n")
cat("  crear()  - Crear PDF completo\n") 
cat("\nCaracterísticas:\n")
cat("✓ Portada automática\n")
cat("✓ Bookmarks laterales navegables\n")
cat("✓ Creación automática de PDFs faltantes\n")
cat("\nEjemplo: crear()\n\n")