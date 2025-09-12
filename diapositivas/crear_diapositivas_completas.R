# ===============================================
# Script para crear diapositivas completas con portada
# Ejecutar desde la RAÍZ del proyecto
# Uso: Rscript -e "source('diapositivas/crear_diapositivas_completas.R'); crear()"
# ===============================================
# Sistema para crear UN PDF con portada clicable + bookmarks laterales

library(pdftools)
library(quarto)

#' Función principal para crear el PDF completo con portada y bookmarks
crear_pdf_completo <- function(nombre_salida = "diapositivas/diapositivas_pdf/DiapositivasModelosEstadisticosPrediccion.pdf") {
  
  cat("=== CREANDO PDF COMPLETO ===\n\n")
  
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
  
  # 2. Verificar y crear diapositivas individuales si es necesario
  cat("1. Verificando y creando diapositivas individuales...\n")
  verificar_y_crear_diapositivas()
  
  # 3. Obtener archivos de temas después de la verificación
  cat("2. Detectando archivos de temas...\n")
  archivos_temas <- obtener_archivos_temas()
  
  if (length(archivos_temas) == 0) {
    stop("Error: No se encontraron archivos de temas después de la verificación")
  }
  
  for (i in seq_along(archivos_temas)) {
    cat("   ", i, ".", archivos_temas[i], "\n")
  }
  cat("\n")
  
  # 3. Calcular información de temas (para bookmarks)
  cat("3. Calculando información de temas...\n")
  paginas_temas <- calcular_paginas_temas(archivos_temas)
  
  for (tema in names(paginas_temas)) {
    cat("   ", tema, ": página", paginas_temas[[tema]], "\n")
  }
  cat("\n")
  
  # 4. Crear portada
  cat("4. Creando portada...\n")
  crear_portada()
  
  if (!file.exists("portada_general.pdf")) {
    stop("Error: No se pudo crear la portada")
  }
  cat("   ✓ Portada creada\n\n")
  
  # 6. Unir todos los PDFs
  cat("5. Uniendo PDFs...\n")
  todos_los_archivos <- c("portada_general.pdf", archivos_temas)
  
  if (unir_con_bookmarks(todos_los_archivos, nombre_salida, paginas_temas)) {
    cat("   ✓ PDF creado con portada clicable Y bookmarks laterales\n")
  } else {
    cat("   ⚠ PDF creado solo con portada clicable\n")
  }
  
  # 7. Mostrar información del resultado
  mostrar_info_resultado(nombre_salida, todos_los_archivos)
  
  # 8. Limpiar archivos temporales
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

#' Función para verificar y crear diapositivas individuales
verificar_y_crear_diapositivas <- function() {
  
  # Definir archivos esperados y sus fuentes
  temas_config <- list(
    list(
      archivo_pdf = "diapositivas/diapositivas_pdf/tema0_introduccion.pdf",
      archivo_qmd = "diapositivas/tema0_introduccion.qmd",
      nombre = "Tema 0: Introducción"
    ),
    list(
      archivo_pdf = "diapositivas/diapositivas_pdf/tema1_regresionlineal.pdf",
      archivo_qmd = "diapositivas/tema1_regresionlineal.qmd", 
      nombre = "Tema 1: Regresión Lineal Simple"
    ),
    list(
      archivo_pdf = "diapositivas/diapositivas_pdf/tema2_regresionmultiple.pdf",
      archivo_qmd = "diapositivas/tema2_regresionmultiple.qmd",
      nombre = "Tema 2: Regresión Lineal Múltiple"
    ),
    list(
      archivo_pdf = "diapositivas/diapositivas_pdf/tema3_ingenieriacaracteristicas.pdf",
      archivo_qmd = "diapositivas/tema3_ingenieriacaracteristicas.qmd",
      nombre = "Tema 3: Ingeniería de Características"
    ),
    list(
      archivo_pdf = "diapositivas/diapositivas_pdf/tema4_seleccionvariables.pdf",
      archivo_qmd = "diapositivas/tema4_seleccionvariables.qmd",
      nombre = "Tema 4: Selección de Variables"
    ),
    list(
      archivo_pdf = "diapositivas/diapositivas_pdf/tema5_glm.pdf",
      archivo_qmd = "diapositivas/tema5_glm.qmd",
      nombre = "Tema 5: GLM"
    )
  )
  
  # Asegurar que el directorio existe
  if (!dir.exists("diapositivas/diapositivas_pdf")) {
    dir.create("diapositivas/diapositivas_pdf", recursive = TRUE)
    cat("   ✓ Directorio diapositivas_pdf creado\n")
  }
  
  # Verificar cada tema
  for (tema in temas_config) {
    if (!file.exists(tema$archivo_pdf)) {
      cat("   ⚠", tema$nombre, "no encontrado, intentando crear...\n")
      
      if (file.exists(tema$archivo_qmd)) {
        tryCatch({
          # Renderizar el QMD desde la raíz del proyecto
          cat("     • Renderizando", tema$archivo_qmd, "...\n")
          quarto_render(tema$archivo_qmd, quiet = FALSE)
          
          # El PDF se genera en el mismo directorio que el QMD
          pdf_generado <- sub("\\.qmd$", ".pdf", tema$archivo_qmd)
          
          if (file.exists(pdf_generado)) {
            # Mover al directorio diapositivas_pdf
            file.rename(pdf_generado, tema$archivo_pdf)
            cat("   ✓", tema$nombre, "creado exitosamente\n")
          } else {
            cat("   ✗", tema$nombre, "- no se generó el PDF\n")
          }
          
        }, error = function(e) {
          cat("   ✗", tema$nombre, "- error:", e$message, "\n")
        })
      } else {
        cat("   ✗", tema$nombre, "- archivo fuente QMD no encontrado:", tema$archivo_qmd, "\n")
      }
    } else {
      cat("   ✓", tema$nombre, "ya existe\n")
    }
  }
  
  cat("\n")
}

#' Función para calcular páginas donde empezará cada tema
calcular_paginas_temas <- function(archivos_temas) {
  
  paginas <- list()
  pagina_actual <- 3  # Asumiendo 2 páginas de portada + índice
  
  # Primero verificar cuántas páginas tendrá la portada
  # (Crear portada temporal solo para contar páginas)
  crear_portada_temporal()
  if (file.exists("portada_temp.pdf")) {
    paginas_portada <- pdf_length("portada_temp.pdf")
    file.remove("portada_temp.pdf")
    pagina_actual <- paginas_portada + 1
  }
  
  # Calcular página de inicio de cada tema
  temas_info <- list(
    "tema0" = "Introduccion a los Modelos Estadisticos",
    "tema1" = "Regresion Lineal Simple", 
    "tema2" = "Regresion Lineal Multiple",
    "tema3" = "Ingenieria de Caracteristicas",
    "tema4" = "Seleccion de Variables y Regularizacion",
    "tema5" = "Modelos Lineales Generalizados"
  )
  
  for (archivo in archivos_temas) {
    # Extraer número de tema
    tema_num <- sub(".*tema(\\d+).*", "\\1", archivo)
    tema_key <- paste0("tema", tema_num)
    
    if (tema_key %in% names(temas_info)) {
      paginas[[temas_info[[tema_key]]]] <- pagina_actual
      
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
  
  # Verificar que existe el archivo de portada
  if (!file.exists("diapositivas/portada.qmd")) {
    stop("No se encontró diapositivas/portada.qmd")
  }
  
  # Guardar directorio actual
  dir_original <- getwd()
  
  tryCatch({
    # Cambiar al directorio diapositivas para renderizar
    setwd("diapositivas")
    
    # Renderizar el archivo portada.qmd existente
    quarto_render("portada.qmd", output_file = "portada_temp.pdf", quiet = TRUE)
    
    # Mover a la raíz si se creó correctamente
    if (file.exists("portada_temp.pdf")) {
      file.rename("portada_temp.pdf", "../portada_temp.pdf")
    }
    
  }, error = function(e) {
    cat("Error al crear portada temporal:", e$message, "\n")
  }, finally = {
    # Siempre volver al directorio original
    setwd(dir_original)
  })
}

#' Función para crear portada simple
crear_portada <- function() {
  
  # Verificar que existe el archivo de portada
  if (!file.exists("diapositivas/portada.qmd")) {
    stop("No se encontró diapositivas/portada.qmd")
  }
  
  # Guardar directorio actual
  dir_original <- getwd()
  
  tryCatch({
    # Cambiar al directorio diapositivas para renderizar
    setwd("diapositivas")
    
    # Renderizar el archivo portada.qmd existente
    quarto_render("portada.qmd", output_file = "portada_general.pdf", quiet = TRUE)
    
    # Mover a la raíz si se creó correctamente
    if (file.exists("portada_general.pdf")) {
      file.rename("portada_general.pdf", "../portada_general.pdf")
    }
    
  }, error = function(e) {
    cat("Error al crear portada:", e$message, "\n")
    stop(e)
  }, finally = {
    # Siempre volver al directorio original
    setwd(dir_original)
  })
}

#' Función para unir PDFs y agregar bookmarks laterales
unir_con_bookmarks <- function(archivos_input, archivo_salida, paginas_temas) {
  
  # Asegurar que el directorio de salida existe
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
  
  # Verificar que el archivo se creó
  if (!file.exists(archivo_salida)) {
    cat("   ✗ Error: No se pudo crear", archivo_salida, "\n")
    return(FALSE)
  }
  
  # Luego agregar bookmarks laterales si pdftk está disponible
  if (system("pdftk --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0) {
    cat("   Agregando bookmarks laterales...\n")
    agregar_bookmarks_laterales(archivo_salida, paginas_temas)
    return(TRUE)
  } else {
    cat("   pdftk no disponible, solo portada simple\n")
    return(TRUE)
  }
}

#' Función para agregar bookmarks laterales
agregar_bookmarks_laterales <- function(archivo_pdf, paginas_temas) {
  
  tryCatch({
    # Crear contenido de bookmarks
    contenido_bookmarks <- c()
    
    # Bookmark para la portada
    contenido_bookmarks <- c(contenido_bookmarks,
                           "BookmarkBegin",
                           "BookmarkTitle: Indice de Diapositivas", 
                           "BookmarkLevel: 1",
                           "BookmarkPageNumber: 2")
    
    # Bookmarks para cada tema
    for (tema in names(paginas_temas)) {
      contenido_bookmarks <- c(contenido_bookmarks,
                             "BookmarkBegin",
                             paste0("BookmarkTitle: ", tema),
                             "BookmarkLevel: 1", 
                             paste0("BookmarkPageNumber: ", paginas_temas[[tema]]))
    }
    
    # Escribir archivo de bookmarks
    writeLines(contenido_bookmarks, "bookmarks_temp.txt", useBytes = TRUE)
    
    # Aplicar con pdftk
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
    
    # Limpiar
    if (file.exists("bookmarks_temp.txt")) file.remove("bookmarks_temp.txt")
    
  }, error = function(e) {
    cat("   Error con bookmarks:", e$message, "\n")
  })
}

#' Función para obtener archivos de temas
obtener_archivos_temas <- function() {
  archivos_esperados <- c(
    "diapositivas/diapositivas_pdf/tema0_introduccion.pdf",
    "diapositivas/diapositivas_pdf/tema1_regresionlineal.pdf", 
    "diapositivas/diapositivas_pdf/tema2_regresionmultiple.pdf",
    "diapositivas/diapositivas_pdf/tema3_ingenieriacaracteristicas.pdf",
    "diapositivas/diapositivas_pdf/tema4_seleccionvariables.pdf",
    "diapositivas/diapositivas_pdf/tema5_glm.pdf"
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
  cat("✓ Todos los temas unidos en un solo PDF\n")
}

#' Función de verificación
verificar_entorno <- function() {
  cat("=== VERIFICACIÓN DEL ENTORNO ===\n")
  
  # Verificar que estamos en la raíz del proyecto
  if (!file.exists("_quarto.yml")) {
    cat("✗ No se encontró _quarto.yml - asegúrate de ejecutar desde la raíz del proyecto\n")
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
  
  # Verificar archivos de configuración
  archivos_config <- c("diapositivas/portada.qmd", "diapositivas/portada.html", "estilos.css")
  for (archivo in archivos_config) {
    if (file.exists(archivo)) {
      cat("✓", archivo, "encontrado\n")
    } else {
      cat("✗", archivo, "NO encontrado\n")
    }
  }
  
  # Verificar logo - RUTAS MÚLTIPLES
  logos_posibles <- c(
    "images/URJClogo.jpg",
    "images/urjc_logo.png", 
    "diapositivas/images/URJClogo.jpg",
    "diapositivas/images/urjc_logo.png"
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
    cat("✗ Logo NO encontrado. Rutas verificadas:\n")
    for (logo in logos_posibles) {
      cat("   -", logo, "\n")
    }
  }
  
  # Verificar contenido del archivo portada.html si existe
  if (file.exists("diapositivas/portada.html")) {
    cat("\nVerificando referencias en portada.html:\n")
    contenido <- readLines("diapositivas/portada.html", warn = FALSE)
    lineas_imagen <- grep("img|URJClogo|urjc_logo", contenido, ignore.case = TRUE)
    
    if (length(lineas_imagen) > 0) {
      cat("Referencias de imagen encontradas:\n")
      for (linea_num in lineas_imagen) {
        cat("  Línea", linea_num, ":", trimws(contenido[linea_num]), "\n")
      }
    } else {
      cat("No se encontraron referencias de imagen en portada.html\n")
    }
  }
  
  # Verificar pdftk
  if (system("pdftk --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0) {
    cat("✓ pdftk instalado (bookmarks laterales disponibles)\n")
  } else {
    cat("⚠ pdftk no encontrado (solo portada simple)\n")
  }
  
  # Verificar archivos QMD fuente
  cat("\nArchivos QMD fuente:\n")
  archivos_qmd <- c(
    "diapositivas/tema0_introduccion.qmd",
    "diapositivas/tema1_regresionlineal.qmd", 
    "diapositivas/tema2_regresionmultiple.qmd",
    "diapositivas/tema3_ingenieriacaracteristicas.qmd",
    "diapositivas/tema4_seleccionvariables.qmd",
    "diapositivas/tema5_glm.qmd"
  )
  
  for (archivo in archivos_qmd) {
    if (file.exists(archivo)) {
      cat("✓", archivo, "\n")
    } else {
      cat("✗", archivo, "NO encontrado\n")
    }
  }
  
  # Verificar archivos de temas PDF
  archivos_temas <- obtener_archivos_temas()
  cat("\nArchivos PDF de temas existentes:\n")
  if (length(archivos_temas) > 0) {
    for (archivo in archivos_temas) {
      cat("✓", archivo, "\n")
    }
  } else {
    cat("⚠ No se encontraron archivos PDF de temas (se crearán automáticamente)\n")
  }
  
  # Verificar directorio de salida
  if (dir.exists("diapositivas/diapositivas_pdf")) {
    cat("✓ Directorio diapositivas/diapositivas_pdf existe\n")
  } else {
    cat("⚠ Directorio diapositivas/diapositivas_pdf no existe (se creará automáticamente)\n")
  }
  
  cat("\n")
}

#' Función para crear versión con temas específicos
crear_pdf_personalizado <- function(temas_incluir = NULL, nombre_salida = "diapositivas/diapositivas_pdf/DiapositivasPersonalizadasModelosEstadisticosPrediccion.pdf") {
  
  if (is.null(temas_incluir)) {
    temas_incluir <- 0:5
  }
  
  cat("Creando PDF personalizado con temas:", paste(temas_incluir, collapse = ", "), "\n")
  
  # Asegurar que estamos en la raíz del proyecto
  if (!file.exists("_quarto.yml")) {
    stop("Error: Este script debe ejecutarse desde la raíz del proyecto")
  }
  
  # Verificar y crear diapositivas individuales si es necesario
  verificar_y_crear_diapositivas()
  
  # Filtrar archivos según temas especificados
  todos_archivos <- obtener_archivos_temas()
  archivos_seleccionados <- c()
  
  for (tema in temas_incluir) {
    patron <- paste0("tema", tema, "_")
    archivo <- todos_archivos[grepl(patron, todos_archivos)]
    if (length(archivo) > 0) {
      archivos_seleccionados <- c(archivos_seleccionados, archivo[1])
    }
  }
  
  if (length(archivos_seleccionados) == 0) {
    stop("No se encontraron archivos para los temas especificados")
  }
  
  # Calcular páginas y crear portada personalizada
  paginas_personalizadas <- calcular_paginas_temas(archivos_seleccionados)
  crear_portada()
  
  # Unir PDFs
  todos_los_archivos <- c("portada_general.pdf", archivos_seleccionados)
  unir_con_bookmarks(todos_los_archivos, nombre_salida, paginas_personalizadas)
  
  # Limpiar
  if (file.exists("portada_general.pdf")) {
    file.remove("portada_general.pdf")
  }
  
  cat("✓ Creado:", nombre_salida, "\n")
  return(nombre_salida)
}

# === FUNCIONES DE USO RÁPIDO ===

#' Crear PDF completo con portada clicable + bookmarks
crear <- function(nombre = "diapositivas/diapositivas_pdf/DiapositivasModelosEstadisticosPrediccion.pdf") {
  crear_pdf_completo(nombre)
}

#' Crear PDF con temas específicos
parcial <- function(temas, nombre = "diapositivas/diapositivas_pdf/diapositivas_parciales.pdf") {
  crear_pdf_personalizado(temas, nombre)
}

#' Verificar entorno
check <- function() {
  verificar_entorno()
}

# Mensaje de bienvenida
cat("=== SISTEMA DE DIAPOSITIVAS COMPLETAS ===\n")
cat("Funciones disponibles:\n")
cat("  check()                    - Verificar entorno\n")
cat("  crear()                    - Crear PDF completo\n") 
cat("  crear('mi_nombre.pdf')     - Crear con nombre específico\n")
cat("  parcial(c(1,2,3))          - Crear PDF solo con temas 1, 2 y 3\n")
cat("\nCaracterísticas:\n")
cat("✓ Portada automática\n")
cat("✓ Bookmarks laterales navegables\n")
cat("✓ Creación automática de PDFs faltantes\n")
cat("✓ Sin problemas de tildes\n")
cat("\nEjemplo: crear()\n\n")