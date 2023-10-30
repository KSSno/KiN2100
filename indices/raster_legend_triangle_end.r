		
gradient.rect_triangle_both <- function (xleft, ybottom, xright, ytop, reds, greens, blues, 
    col = NULL, nslices = 50, gradient = "x", border = par("fg")) 
{
    if (is.null(col)) 
        col <- color.gradient(reds, greens, blues, nslices)
    else nslices <- length(col)
    nrect <- max(unlist(lapply(list(xleft, ybottom, xright, ytop), 
        length)))
    oldxpd <- par(xpd = NA)
    if (nrect > 1) {
        if (length(xleft) < nrect) 
            xleft <- rep(xleft, length.out = nrect)
        if (length(ybottom) < nrect) 
            ybottom <- rep(ybottom, length.out = nrect)
        if (length(xright) < nrect) 
            xright <- rep(xright, length.out = nrect)
        if (length(ytop) < nrect) 
            ytop <- rep(ytop, length.out = nrect)
        for (i in 1:nrect) gradient.rect(xleft[i], ybottom[i], 
            xright[i], ytop[i], reds, greens, blues, col, nslices, 
            gradient, border = border)
    }
    else {
        if (gradient == "x") {
            xinc <- (xright - xleft)/nslices
            xlefts <- seq(xleft, xright - xinc, length = nslices)
            xrights <- xlefts + xinc
            rect(xlefts, ybottom, xrights, ytop, col = col, lty = 0)
            rect(xlefts[1], ybottom, xrights[nslices], ytop, 
                border = border)
        }
        else {
            yinc <- (ytop - ybottom)/nslices
            ybottoms <- seq(ybottom, ytop - yinc, length = nslices)
            ytops <- ybottoms + yinc
            rect(xleft, ybottoms[2:(nslices-1)], xright, ytops[2:(nslices-1)], col = col[2:(nslices-1)], lty = 0)
            rect(xleft, ybottoms[2], xright, ytops[nslices-1], 
                border = border)
			polygon(x = c(xleft, (xleft+xright)/2,xright),  # X-Coordinates of polygon
                    y = c(ytops[1], ybottoms[1], ytops[1]),    # Y-Coordinates of polygon
                    col = col[1])
			polygon(x = c(xleft, (xleft+xright)/2,xright),  # X-Coordinates of polygon
                    y = c(ybottoms[nslices], ytops[nslices], ybottoms[nslices]),    # Y-Coordinates of polygon
                    col = col[nslices])
        }
    }
    par(oldxpd)
    invisible(col)
}

gradient.rect_triangle_bottom <- function (xleft, ybottom, xright, ytop, reds, greens, blues, 
    col = NULL, nslices = 50, gradient = "x", border = par("fg")) 
{
    if (is.null(col)) 
        col <- color.gradient(reds, greens, blues, nslices)
    else nslices <- length(col)
    nrect <- max(unlist(lapply(list(xleft, ybottom, xright, ytop), 
        length)))
    oldxpd <- par(xpd = NA)
    if (nrect > 1) {
        if (length(xleft) < nrect) 
            xleft <- rep(xleft, length.out = nrect)
        if (length(ybottom) < nrect) 
            ybottom <- rep(ybottom, length.out = nrect)
        if (length(xright) < nrect) 
            xright <- rep(xright, length.out = nrect)
        if (length(ytop) < nrect) 
            ytop <- rep(ytop, length.out = nrect)
        for (i in 1:nrect) gradient.rect(xleft[i], ybottom[i], 
            xright[i], ytop[i], reds, greens, blues, col, nslices, 
            gradient, border = border)
    }
    else {
        if (gradient == "x") {
            xinc <- (xright - xleft)/nslices
            xlefts <- seq(xleft, xright - xinc, length = nslices)
            xrights <- xlefts + xinc
            rect(xlefts, ybottom, xrights, ytop, col = col, lty = 0)
            rect(xlefts[1], ybottom, xrights[nslices], ytop, 
                border = border)
        }
        else {
            yinc <- (ytop - ybottom)/nslices
            ybottoms <- seq(ybottom, ytop - yinc, length = nslices)
            ytops <- ybottoms + yinc
            rect(xleft, ybottoms[2:(nslices-1)], xright, ytops[2:(nslices-1)], col = col[2:(nslices-1)], lty = 0)
            rect(xleft, ybottoms[2], xright, ytops[nslices-1], 
                border = border)
			polygon(x = c(xleft, (xleft+xright)/2,xright),  # X-Coordinates of polygon
                    y = c(ytops[1], ybottoms[1], ytops[1]),    # Y-Coordinates of polygon
                    col = col[1])
			        }
    }
    par(oldxpd)
    invisible(col)
}

		
gradient.rect_triangle_up <- function (xleft, ybottom, xright, ytop, reds, greens, blues, 
    col = NULL, nslices = 50, gradient = "x", border = par("fg")) 
{
    if (is.null(col)) 
        col <- color.gradient(reds, greens, blues, nslices)
    else nslices <- length(col)
    nrect <- max(unlist(lapply(list(xleft, ybottom, xright, ytop), 
        length)))
    oldxpd <- par(xpd = NA)
    if (nrect > 1) {
        if (length(xleft) < nrect) 
            xleft <- rep(xleft, length.out = nrect)
        if (length(ybottom) < nrect) 
            ybottom <- rep(ybottom, length.out = nrect)
        if (length(xright) < nrect) 
            xright <- rep(xright, length.out = nrect)
        if (length(ytop) < nrect) 
            ytop <- rep(ytop, length.out = nrect)
        for (i in 1:nrect) gradient.rect(xleft[i], ybottom[i], 
            xright[i], ytop[i], reds, greens, blues, col, nslices, 
            gradient, border = border)
    }
    else {
        if (gradient == "x") {
            xinc <- (xright - xleft)/nslices
            xlefts <- seq(xleft, xright - xinc, length = nslices)
            xrights <- xlefts + xinc
            rect(xlefts, ybottom, xrights, ytop, col = col, lty = 0)
            rect(xlefts[1], ybottom, xrights[nslices], ytop, 
                border = border)
        }
        else {
            yinc <- (ytop - ybottom)/nslices
            ybottoms <- seq(ybottom, ytop - yinc, length = nslices)
            ytops <- ybottoms + yinc
            rect(xleft, ybottoms[1:(nslices-1)], xright, ytops[1:(nslices-1)], col = col[1:(nslices-1)], lty = 0)
            rect(xleft, ybottoms[1], xright, ytops[nslices-1], 
                border = border)
			polygon(x = c(xleft, (xleft+xright)/2,xright),  # X-Coordinates of polygon
                    y = c(ybottoms[nslices], ytops[nslices], ybottoms[nslices]),    # Y-Coordinates of polygon
                    col = col[nslices])
        }
    }
    par(oldxpd)
    invisible(col)
}


color.legend_triangle_both <-                                                              
function (xl, yb, xr, yt, legend, rect.col, cex = 1, align = "lt", 
    gradient = "x", ...) 
{
    oldcex <- par("cex")
    par(xpd = TRUE, cex = cex)
    gradient.rect_triangle_both(xl, yb, xr, yt, col = rect.col, nslices = length(rect.col), 
        gradient = gradient)
    if (gradient == "x") {
        xsqueeze <- (xr - xl)/(2 * length(rect.col))
        textx <- seq(xl + xsqueeze, xr - xsqueeze, length.out = length(legend))
        if (match(align, "rb", 0)) {
            texty <- yb - 0.2 * strheight("O")
            textadj <- c(0.5, 1)
        }
        else {
            texty <- yt + 0.2 * strheight("O")
            textadj <- c(0.5, 0)
        }
    }
    else {
        ysqueeze <- (yt - yb)/(2 * length(rect.col))
        texty <- seq(yb + 2*ysqueeze, yt -2*ysqueeze, length.out = length(legend))
        if (match(align, "rb", 0)) {
            textx <- xr + 0.2 * strwidth("O")
            textadj <- c(0, 0.5)
        }
        else {
            textx <- xl - 0.2 * strwidth("O")
            textadj <- c(1, 0.5)
        }
    }
    text(textx, texty, labels = legend, adj = textadj, ...)
    segments(xr, texty, xr+(xr-xl)/5, texty)
    par(xpd = FALSE, cex = oldcex)
}

color.legend_triangle_bottom <-                                                              
function (xl, yb, xr, yt, legend, rect.col, cex = 1, align = "lt", 
    gradient = "x", ...) 
{
    oldcex <- par("cex")
    par(xpd = TRUE, cex = cex)
    gradient.rect_triangle_bottom(xl, yb, xr, yt, col = rect.col, nslices = length(rect.col), 
        gradient = gradient)
    if (gradient == "x") {
        xsqueeze <- (xr - xl)/(2 * length(rect.col))
        textx <- seq(xl + xsqueeze, xr - xsqueeze, length.out = length(legend))
        if (match(align, "rb", 0)) {
            texty <- yb - 0.2 * strheight("O")
            textadj <- c(0.5, 1)
        }
        else {
            texty <- yt + 0.2 * strheight("O")
            textadj <- c(0.5, 0)
        }
    }
    else {
        ysqueeze <- (yt - yb)/(2 * length(rect.col))
        texty <- seq(yb + 2*ysqueeze, yt -2*ysqueeze , length.out = length(legend))
        if (match(align, "rb", 0)) {
            textx <- xr + 0.2 * strwidth("O")
            textadj <- c(0, 0.5)
        }
        else {
            textx <- xl - 0.2 * strwidth("O")
            textadj <- c(1, 0.5)
        }
    }
    text(textx, texty, labels = legend, adj = textadj, ...)
    segments(xr, texty, xr+(xr-xl)/5, texty)
    par(xpd = FALSE, cex = oldcex)
}

color.legend_triangle_up <-                                                              
function (xl, yb, xr, yt, legend, rect.col, cex = 1, align = "lt", 
    gradient = "x", ...) 
{
    oldcex <- par("cex")
    par(xpd = TRUE, cex = cex)
    gradient.rect_triangle_up(xl, yb, xr, yt, col = rect.col, nslices = length(rect.col), 
        gradient = gradient)
    if (gradient == "x") {
        xsqueeze <- (xr - xl)/(2 * length(rect.col))
        textx <- seq(xl + xsqueeze, xr - xsqueeze, length.out = length(legend))
        if (match(align, "rb", 0)) {
            texty <- yb - 0.2 * strheight("O")
            textadj <- c(0.5, 1)
        }
        else {
            texty <- yt + 0.2 * strheight("O")
            textadj <- c(0.5, 0)
        }
    }
    else {
        ysqueeze <- (yt - yb)/(2 * length(rect.col))
        texty <- seq(yb , yt -2*ysqueeze, length.out = length(legend))
        if (match(align, "rb", 0)) {
            textx <- xr + 0.2 * strwidth("O")
            textadj <- c(0, 0.5)
        }
        else {
            textx <- xl - 0.2 * strwidth("O")
            textadj <- c(1, 0.5)
        }
    }
    text(textx, texty, labels = legend, adj = textadj, ...)
    segments(xr, texty, xr+(xr-xl)/5, texty)
    par(xpd = FALSE, cex = oldcex)
}

add_space <- function(string_in, length_tot,side) {
nr_str <- length(string_in)
string_out <- rep("",nr_str)
for(i in 1:nr_str) {
nr_char <- nchar(string_in[i])

if(nr_char<length_tot) {
empty_space <-""
for(z in 1: (length_tot-nr_char)) {
empty_space=paste(empty_space," ",sep="")
}  # end z

  if(side=="left") { 
string_out[i] <- paste(empty_space,string_in[i],sep="")
} else if (side=="right") {
string_out[i] <- paste(string_in[i],empty_space,sep="")
} 

} else {
string_out[i] <- string_in[i]
}  # end if

} # end i

return(string_out)
}



