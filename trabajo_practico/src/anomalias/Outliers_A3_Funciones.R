# Máster -> Detección de anomalías
# Juan Carlos Cubero. Universidad de Granada

###########################################################################
# Funciones utilizadas a lo largo del curso
###########################################################################


#rm(list=ls())
windows = function() {}


#######################################################################
# Muestra un plot básico con los outliers en rojo
# Necesita como parámetros de entrada:
# el dataset "datos", un vector de T/F indicando si el registro i-ésimo 
# de "datos" es o no un outlier (según el método aplicado) 
# y el título a aparecer en el gráfico

MiPlot_Univariate_Outliers = function (datos, indices_de_Outliers, titulo){
  numero.de.datos = nrow(as.matrix(datos))
  vectorTFoutliers =  rep(FALSE, numero.de.datos)
  vectorTFoutliers[indices_de_Outliers] = TRUE
  vector.colores.outlier = rep("black", numero.de.datos)
  vector.colores.outlier [vectorTFoutliers] = "red"
  
  cat("\nNúmero de datos: ")
  cat(numero.de.datos)
  cat("\n¿Quién es outlier?: ")
  cat(vectorTFoutliers)
  cat('\n')
  
  windows()
  plot(datos, col=vector.colores.outlier, main = titulo)
}



###########################################################################
# Calcula los outliers IQR 
# Devuelve un vector TRUE/FALSE indicando si el registro i-ésimo 
# de "datos" es o no un outlier IQR con respecto a la columna de índice "indice"
# coef es 1.5 para los outliers normales y hay que pasarle 3 para los outliers extremos

vector_es_outlier_IQR = function (datos, indice.de.columna, coef = 1.5){
  columna.datos = datos[,indice.de.columna]
  cuartil.primero = quantile(columna.datos)[2]  #quantile[1] es el mínimo y quantile[5] el máximo.
  cuartil.tercero = quantile(columna.datos)[4] 
  iqr = cuartil.tercero - cuartil.primero
  extremo.superior.outlier = (iqr * coef) + cuartil.tercero
  extremo.inferior.outlier = cuartil.primero - (iqr * coef)
  es.outlier  = columna.datos > extremo.superior.outlier |
    columna.datos < extremo.inferior.outlier
  return (es.outlier)
}

###########################################################################
# Devuelve un vector con las claves de los outliers IQR
# con respecto a la columna de índice "indice"
# coef es 1.5 para los outliers normales y hay que pasarle 3 para los outliers extremos

vector_claves_outliers_IQR = function(datos, indice, coef = 1.5){
  columna.datos = datos[,indice]
  vector.de.outliers = vector_es_outlier_IQR(datos, indice, coef)
  which(vector.de.outliers  == TRUE)
}



#######################################################################
# Devuelve los nombres de aquellas filas de datos especificadas 
# en el segundo parámetro (vector de T/F)

Nombres_de_Filas = function (datos, vector_TF_datos_a_incluir) {
  numero.de.filas = nrow(datos)
  
  if (is.null(row.names(datos)))
    row.names(datos) = rep(1:numero.de.filas)
  
  nombres.de.filas = rep("", numero.de.filas)
  nombres.de.filas[vector_TF_datos_a_incluir==TRUE] = row.names(datos)[vector_TF_datos_a_incluir==TRUE]
  nombres.de.filas
}



#######################################################################
# Calcula los outliers IQR y muestra sus etiquetas en un BoxPlot

MiBoxPlot_IQR_Univariate_Outliers = function (datos, indice.de.columna, coef = 1.5){
  # Importante: Para que aes busque los parámetros en el ámbito local, debe incluirse  environment = environment()
  
  datos = as.data.frame(datos)
  vector.TF.outliers.IQR = vector_es_outlier_IQR(datos, indice.de.columna, coef)
  nombres.de.filas = Nombres_de_Filas(datos, vector.TF.outliers.IQR)
  nombre.de.columna = names(datos)[indice.de.columna]
  
  ggboxplot = ggplot(data = datos, aes(x=factor(""), y=datos[,indice.de.columna]) , environment = environment()) + 
    xlab(nombre.de.columna) + ylab("") +
    geom_boxplot(outlier.colour = "red") + 
    geom_text(aes(label = nombres.de.filas)) #, position = position_jitter(width = 0.1))   
  
  windows()
  ggboxplot
}



#######################################################################
# Muestra de forma conjunta todos los BoxPlots de las columnas de datos
# Para ello, normaliza los datos.
# También muestra con un punto en rojo los outliers de cada columna
# Para hacerlo con ggplot, lamentablemente hay que construir antes una tabla 
# que contenga en cada fila el valor que a cada tupla le da cada variable -> paquete reshape->melt

MiBoxPlot_juntos  = function (datos, vector_TF_datos_a_incluir = c()){  
  # Requiere reshape
  # Importante: Para que aes busque los parámetros en el ámbito local, debe incluirse  environment = environment()
  
  nombres.de.filas = Nombres_de_Filas(datos, vector_TF_datos_a_incluir)
  
  datos = scale(datos)
  datos.melted = melt(datos)
  colnames(datos.melted)[2]="Variables"
  colnames(datos.melted)[3]="zscore"
  factor.melted = colnames(datos.melted)[1]
  columna.factor = as.factor(datos.melted[,factor.melted])
  levels(columna.factor)[!levels(columna.factor) %in% nombres.de.filas] = ""  
  
  ggplot(data = datos.melted, aes(x=Variables, y=zscore), environment = environment()) + 
    geom_boxplot(outlier.colour = "red") + 
    geom_text(aes(label = columna.factor), size = 3) 
}



#######################################################################
# Muestra de forma conjunta todos los BoxPlots de las columnas de datos
# Para ello, normaliza los datos
# También muestra las etiquetas de los outliers de cada columna


MiBoxPlot_juntos_con_etiquetas = function (datos, coef = 1.5){
  matriz.datos.TF.outliers = sapply(1:ncol(datos), function(x) vector_es_outlier_IQR(datos, x, coef))  # Aplicamos outlier IQR a cada columna
  vector.datos.TF.outliers = apply(matriz.datos.TF.outliers, 1, sum)   
  vector.datos.TF.outliers[vector.datos.TF.outliers > 1] = 1            # Si un registro es outlier en alguna columna lo incluimos
  
  MiBoxPlot_juntos(datos, vector.datos.TF.outliers)
}



#######################################################################
# Aplica el test de Grubbs e imprime los resultados

MiPlot_resultados_TestGrubbs = function(datos){
  alpha = 0.05
  
  test.de.Grubbs = grubbs.test(datos, two.sided = TRUE)
  cat('p.value: ')
  cat(test.de.Grubbs$p.value)
  cat('\n')
  
  if (test.de.Grubbs$p.value < alpha){
    indice.de.outlier.Grubbs = order(abs(datos - mean(datos)), decreasing = T)[1]
    indice.de.outlier.Grubbs
    cat('Índice de outlier: ')
    cat(indice.de.outlier.Grubbs)
    cat('\n')
    valor.de.outlier.Grubbs  = datos[indice.de.outlier.Grubbs]
    cat('Valor del outlier: ')
    cat(valor.de.outlier.Grubbs)
    MiPlot_Univariate_Outliers (datos, "Test de Grubbs", indice.de.outlier.Grubbs)
  }
  else
    cat('No hay outliers')
}


#######################################################################
# Aplica el test de Rosner e imprime los resultados

MiPlot_resultados_TestRosner = function(datos){  
  test.de.rosner = rosnerTest(datos, k=4)
  is.outlier.rosner = test.de.rosner$all.stats$Outlier
  k.mayores.desviaciones.de.la.media = test.de.rosner$all.stats$Obs.Num
  indices.de.outliers.rosner = k.mayores.desviaciones.de.la.media[is.outlier.rosner]
  valores.de.outliers.rosner = datos[indices.de.outliers.rosner]
  
  cat("\nTest de Rosner")
  cat("\nÍndices de las k-mayores desviaciones de la media: ")
  cat(k.mayores.desviaciones.de.la.media)
  cat("\nDe las k mayores desviaciones, ¿Quién es outlier? ")
  cat(is.outlier.rosner)
  cat("\nLos índices de los outliers son: ")
  cat(indices.de.outliers.rosner)
  cat("\nLos valores de los outliers son: ")
  cat(valores.de.outliers.rosner)
  
  MiPlot_Univariate_Outliers (datos, indices.de.outliers.rosner, "Test de Rosner")
}


MiBiplot = function(datos){
  PCA.model = princomp(scale(datos))
  biplot = ggbiplot(PCA.model, obs.scale = 1, var.scale=1 , varname.size = 5,alpha = 1/2) 
  windows()
  print(biplot)
}

MiBiPlot_Multivariate_Outliers = function (datos, vectorTFoutliers, titulo){
   identificadores_de_datos = rownames(datos)
   identificadores_de_datos[!vectorTFoutliers] = ''
   cat(identificadores_de_datos)
 
   PCA.model = princomp(scale(datos))
   outlier.shapes = c(".","x") #c(21,8)
   biplot = ggbiplot(PCA.model, obs.scale = 1, var.scale=1 , varname.size = 5,groups =  vectorTFoutliers, alpha = 1/2) #alpha = 1/10, 
   biplot = biplot + labs(color = "Outliers")
   biplot = biplot + scale_color_manual(values = c("black","red"))
   biplot = biplot + geom_text(label = identificadores_de_datos, stat = "identity", size = 3, hjust=0, vjust=0)
   biplot = biplot + ggtitle(titulo)
  
   windows()
   print(biplot)
}


# Dentro de MiBiPlot_Clustering_Outliers se llama a la función ggbiplot, la cual está basada
# en la función ggplot que tiene un bug de diseño ya que dentro del parámetro aes
# sólo se pueden llamar a variables del entorno global y no del entorno local.
# Por tanto, desgraciadamente, debemos establecer variables globales que 
# son usadas dentro de nuestra función MiBiPlot_Clustering_Outliers:
# BIPLOT.isOutlier
# BIPLOT.asignaciones.clusters
# BIPLOT.cluster.colors

MiBiPlot_Clustering_Outliers = function (datos, titulo){
  PCA.model = princomp(scale(datos))
  outlier.shapes = c("o","x") #c(21,8)
  
  identificadores_de_datos = rownames(datos)
  identificadores_de_datos[!BIPLOT.isOutlier] = ''
  #cat(identificadores_de_datos)
  
  BIPLOT.asignaciones.clusters = factor(BIPLOT.asignaciones.clusters)
  
  biplot = ggbiplot(PCA.model, obs.scale = 1, var.scale=1 , varname.size = 3, alpha = 0) +              
    geom_point(aes(shape = BIPLOT.isOutlier, colour = factor(BIPLOT.asignaciones.clusters)))  +
    scale_color_manual(values = BIPLOT.cluster.colors) +
    scale_shape_manual(values = outlier.shapes) +
    ggtitle(titulo) +
    geom_text(label = identificadores_de_datos, stat = "identity", size = 3, hjust=0, vjust=0)      
  
  windows()
  print(biplot)
}


# Reset the graphical options to defaults
reset_par <- function(){
  op <- structure(list(xlog = FALSE, ylog = FALSE, adj = 0.5, ann = TRUE,
                       ask = FALSE, bg = "transparent", bty = "o", cex = 1, cex.axis = 1,
                       cex.lab = 1, cex.main = 1.2, cex.sub = 1, col = "black",
                       col.axis = "black", col.lab = "black", col.main = "black",
                       col.sub = "black", crt = 0, err = 0L, family = "", fg = "black",
                       fig = c(0, 1, 0, 1), fin = c(6.99999895833333, 6.99999895833333
                       ), font = 1L, font.axis = 1L, font.lab = 1L, font.main = 2L,
                       font.sub = 1L, lab = c(5L, 5L, 7L), las = 0L, lend = "round",
                       lheight = 1, ljoin = "round", lmitre = 10, lty = "solid",
                       lwd = 1, mai = c(1.02, 0.82, 0.82, 0.42), mar = c(5.1, 4.1,
                                                                         4.1, 2.1), mex = 1, mfcol = c(1L, 1L), mfg = c(1L, 1L, 1L,
                                                                                                                        1L), mfrow = c(1L, 1L), mgp = c(3, 1, 0), mkh = 0.001, new = FALSE,
                       oma = c(0, 0, 0, 0), omd = c(0, 1, 0, 1), omi = c(0, 0, 0,
                                                                         0), pch = 1L, pin = c(5.75999895833333, 5.15999895833333),
                       plt = c(0.117142874574832, 0.939999991071427, 0.145714307397962,
                               0.882857125425167), ps = 12L, pty = "m", smo = 1, srt = 0,
                       tck = NA_real_, tcl = -0.5, usr = c(0.568, 1.432, 0.568,
                                                           1.432), xaxp = c(0.6, 1.4, 4), xaxs = "r", xaxt = "s", xpd = FALSE,
                       yaxp = c(0.6, 1.4, 4), yaxs = "r", yaxt = "s", ylbias = 0.2), .Names = c("xlog",
                                                                                                "ylog", "adj", "ann", "ask", "bg", "bty", "cex", "cex.axis",
                                                                                                "cex.lab", "cex.main", "cex.sub", "col", "col.axis", "col.lab",
                                                                                                "col.main", "col.sub", "crt", "err", "family", "fg", "fig", "fin",
                                                                                                "font", "font.axis", "font.lab", "font.main", "font.sub", "lab",
                                                                                                "las", "lend", "lheight", "ljoin", "lmitre", "lty", "lwd", "mai",
                                                                                                "mar", "mex", "mfcol", "mfg", "mfrow", "mgp", "mkh", "new", "oma",
                                                                                                "omd", "omi", "pch", "pin", "plt", "ps", "pty", "smo", "srt",
                                                                                                "tck", "tcl", "usr", "xaxp", "xaxs", "xaxt", "xpd", "yaxp", "yaxs",
                                                                                                "yaxt", "ylbias"))
  par(op)
}