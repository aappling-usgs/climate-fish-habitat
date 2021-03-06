
library(dplyr)
library(yaml)

visualizeData.visualizeFutureSuitability <- function(processedFutureSuitability, outfile, ...){

  fish.sum <- processedFutureSuitability$fish.change.summary
  arrows <- processedFutureSuitability[c('arrows.1', 'arrows.2')]
  fig.data <- yaml::yaml.load_file('data/siteText.yaml')$`futureSuitability-fig`
  min.h <- 5 #px
  js.funs <- '\nvar svg = document.querySelector("svg")
  var xmax = Number(svg.getAttribute("viewBox").split(" ")[2]);
  var pt = svg.createSVGPoint();
  function init(evt){
  if ( window.svgDocument == null ) {
  svgDocument = evt.target.ownerDocument;
  }
  }
  function changeOpacity(id, val){
  \tdocument.getElementById(id).setAttribute("opacity", val);
  }
  function hovertext(text, evt){
  var tooltip = document.getElementById("tooltip");
  var tooltip_bg = document.getElementById("tooltip_bg");
  tooltip.setAttribute("text-anchor","begin");
  tooltip.setAttribute("dx","7");
  if (evt === undefined){
  tooltip.setAttribute("class","hidden");
  tooltip.firstChild.data = text;
  tooltip_bg.setAttribute("x",0);
  tooltip_bg.setAttribute("y",0);
  tooltip_bg.setAttribute("class","hidden");
  } else {
  pt = cursorPoint(evt)
  tooltip.setAttribute("x",pt.x);
  tooltip.setAttribute("y",pt.y);
  tooltip.firstChild.data = text;
  tooltip_bg.setAttribute("x",pt.x+5);
  tooltip_bg.setAttribute("y",pt.y-22);
  tooltip.setAttribute("class","shown");
  tooltip_bg.setAttribute("class","shown");
  var length = tooltip.getComputedTextLength();
  tooltip_bg.setAttribute("width", length+8);
  if (pt.x+length+8 > xmax){
  tooltip.setAttribute("text-anchor","end");
  tooltip.setAttribute("dx","-8");
  tooltip_bg.setAttribute("x",pt.x-12-length);
  }
  }}
  function cursorPoint(evt){
  pt.x = evt.clientX; pt.y = evt.clientY;
  return pt.matrixTransform(svg.getScreenCTM().inverse());
  };'
  
  types <- c('Walleye dominant', 'Coexistence', 'Bass dominant', 'Neither')
  colors <- c('Walleye dominant'='#01b29F','Coexistence'='#9932CD','Bass dominant'='#990000','Neither'='grey')
  arrow.cols <- c('Walleye'='#01b29F','Coexistence'='#9932CD','Bass'='#990000','Neither'='grey')
  to.types <- c('toWally', 'toCoexistence', 'toBass', 'toNeither')
  periods <- c('early'='X1989.2014', 'mid'='X2040.2064', 'late'='X2065.2089')
  arrow.names <- c('toWally'='Walleye dominant', 'toCoexistence'='Coexistence', 'toBass'='Bass dominant', 'toNeither'='Neither')
  period.txt <- c('1989-2014','2040-2064','2065-2089')
  
  svg_node <- dinosvg:::svg_node
  
  scale <- 0.33
  box.w <- 170
  gap.s <- 200
  box.s <- 12
  l.m <- 20
  t.m <- 20
  y <- list()
  h <- list()
  
  n.threshold <- c(40,100)
  
  svg <- dinosvg:::init_svg(14,12)
  dinosvg:::add_css(svg, '
  .hidden {
                      opacity:0;
  }
  path, .bin {
  -webkit-transition: 0.25s ease-in-out;
  -moz-transition: 0.25s ease-in-out;
  -o-transition: 0.25s ease-in-out;
  transition: 0.25s ease-in-out;
  }
  text {
  font-size: 16px;
  cursor: default;
  font-family: Tahoma, Geneva, sans-serif;
  }
  .big-text{
  font-size: 34px;
  }
  .medium-text{
  font-size: 20px;
  }
  ')
  
  dinosvg:::add_ecmascript(svg, js.funs)
  defs <- svg_node('defs', svg)
  blank.period.g <- svg_node('g',NULL, c('id'='mouseover-periods','opacity'="0"))
  for (i in 1:length(periods)){
    period.id <- names(periods)[i]
    period.name <- unname(periods[i])
    
    g <- svg_node('g',svg, c(id=period.id, transform=sprintf("translate(%s,%s)",l.m+(i-1)*(box.w+gap.s), t.m)))
    g.blank <- svg_node('g',blank.period.g, c(id=paste0(period.id,'-blank'), transform=sprintf("translate(%s,%s)",l.m+(i-1)*(box.w+gap.s), t.m)))
    y[[period.name]][1] <- 0
    t <- 1
    fish.sum.period <- fish.sum %>% filter(time.period == period.name) %>% select(-time.period)
    period.data <- unlist(fish.sum.period)
    for (type in types){
      short.name <- strsplit(type,'[ ]')[[1]][1]
      id <- paste0(period.name, '-', short.name)
      h[[period.name]][t] <- period.data[[type]]*scale
      svg_node('rect',g,c(width=box.w, class='bin', height=h[[period.name]][t], y=y[[period.name]][t], fill=colors[[type]], opacity="0.8", id=id))
      svg_node('rect',g.blank,c(width=box.w, height=h[[period.name]][t], y=y[[period.name]][t],
                                onmousemove=sprintf(paste0("hovertext('",fig.data[[short.name]],"',evt);changeOpacity('%s','1.0');"),formatC(period.data[[type]], format="d", big.mark=','),type,id),
                                onmouseout=sprintf("hovertext(' ');changeOpacity('%s','0.8');",id)))
      if (period.data[[type]] < n.threshold[1]){
        svg_node('text',g, c(x=box.w/2, y=y[[period.name]][t], dy="-3", fill='black', stroke='none', 'text-anchor'='middle'), XML::newXMLTextNode(sprintf("%s",type)))
      } else if (period.data[[type]] > n.threshold[2]){
        svg_node('text',g, c(class='medium-text', x=box.w/2, y=y[[period.name]][t]+h[[period.name]][t]/2, dy="0.33em", fill='black', stroke='none', 'text-anchor'='middle'), XML::newXMLTextNode(sprintf("%s",type)))
      } else {
        svg_node('text',g, c(x=box.w/2, y=y[[period.name]][t]+h[[period.name]][t]/2, dy="0.33em", fill='black', stroke='none', 'text-anchor'='middle'), XML::newXMLTextNode(sprintf("%s",type)))
      }
      
      y[[period.name]][t+1] <- y[[period.name]][t]+box.s+h[[period.name]][t]
      t<-t+1
    }
    svg_node('text',g, c(x=box.w/2, dy='1em', class='big-text', y=y[[period.name]][t], fill='black', stroke='none', 'text-anchor'='middle'), XML::newXMLTextNode(period.txt[i]))
    y[[period.name]] <- y[[period.name]][1:4] # get rid of the last one
  }
  
  
  
  start.arrows <- list()
  # // arrows!
  for (i in 1:(length(periods)-1)){
    
    period.from <- unname(periods[i])
    from.i <- 1
    for (from.type in types){
      
      where.type <- which(unname(unlist(from.type == arrows[[i]][1]))) # this is the "FROM" type column
      to.i <- 1
      y.0 <- 0
      for (to.type in to.types){
        h <- arrows[[i]][[to.type]][where.type]*scale
        from.y.bot <- y[[period.from]][from.i]+h+y.0
        start.arrows[[period.from]][[from.type]][[to.type]] <- c(y1=from.y.bot, h = h)
        to.i <- to.i+1
        y.0  <- y.0 + h
      }
      from.i <- from.i+1
    }
    
  }
  
  # // arrows!
  for (i in 2:length(periods)){
    
    period.to <- unname(periods[i])
    period.from <- unname(periods[i-1])
    to.i <- 1
    
    for (to.type in to.types){
      
      
      from.i <- 1
      y.0 <- 0
      for (from.type in types){
        
        where.type <- which(unname(unlist(from.type == arrows[[i-1]][1]))) # this is the "FROM" type column
        h <- arrows[[i-1]][[to.type]][where.type]*scale
        to.y.bot <- y[[period.to]][to.i]+h+y.0
        start.arrows[[period.from]][[from.type]][[to.type]]<- c(start.arrows[[period.from]][[from.type]][[to.type]], y2= to.y.bot)
        
        from.i <- from.i+1
        y.0  <- y.0 + h
      }
      to.i <- to.i+1
      
    }
  }
  
  blank.arrow.g <- svg_node('g',NULL, c('id'='mouseover-arrows','opacity'="0"))
  
  for (i in 1:2){
    period.from <- unname(periods[i])
    g <- svg_node('g',svg, c(opacity='0.7', id=paste0(period.from,'-arrow'), transform=sprintf("translate(%s,%s)",l.m+(i-1)*(box.w+gap.s), t.m)))
    g.blank <- svg_node('g', blank.arrow.g, c(id=paste0(period.from,'-arrow-blank'), transform=sprintf("translate(%s,%s)",l.m+(i-1)*(box.w+gap.s), t.m)))
    for (from.type in c('Bass dominant', 'Neither', 'Walleye dominant', 'Coexistence')){
      for (to.type in names(start.arrows[[period.from]][[from.type]])){
        stc <- start.arrows[[period.from]][[from.type]][[to.type]]
        arr.txt <- arrow.names[[to.type]]
        if (from.type == arr.txt){
          mouse.text <- sprintf("hovertext('%s lakes remain as %s',evt)",formatC(stc[['h']]/scale, format="d", big.mark=','), from.type)
        } else {
          mouse.text <- sprintf("hovertext('%s lakes shift from %s to %s',evt)",formatC(stc[['h']]/scale, format="d", big.mark=','), from.type, arr.txt)  
        }
        arr.id <- paste0(strsplit(from.type,'[ ]')[[1]][1],'-',strsplit(arr.txt,'[ ]')[[1]][1])
        id <- paste0(period.from,'-',arr.id)
        if (!is.null(fig.data[[arr.id]])){
          mouse.text <- sprintf(paste0("hovertext('",fig.data[[arr.id]],"',evt)"),formatC(stc[['h']]/scale, format="d", big.mark=','), from.type)
        }
        if (stc[['h']] > 0){
          mouser.h <- max(min.h, stc[['h']])
          svg_node('path', g, c(d = sprintf("M%s,%s L%s,%s v-%s L%s,%s", box.w, stc[['y1']], box.w+gap.s, stc[['y2']], stc[['h']], box.w, stc[['y1']]-stc[['h']]), 
                                fill=sprintf("url(#%s-grad)",arr.id ), stroke='none', opacity="0.6", id=id))
          svg_node('path', g.blank, c(d = sprintf("M%s,%s L%s,%s v-%s L%s,%s", box.w, stc[['y1']], box.w+gap.s, stc[['y2']], mouser.h, box.w, stc[['y1']]-mouser.h), 
                                      onmousemove=sprintf("%s;changeOpacity('%s','1')",mouse.text, id), onmouseout=sprintf("hovertext(' ');changeOpacity('%s','0.6');",id)))
        }
      }
    }
  }
  type.names <- unname(sapply(types,function(x) strsplit(x, '[ ]')[[1]][1]))
  for (from.type in type.names){
    for (to.type in type.names){
      lin.grad <- svg_node('linearGradient', defs, c(id=paste0(from.type,"-",to.type,"-grad"), x1="0%", y1="0%", x2="100%", y2="0%"))
      svg_node('stop', lin.grad, c(offset="0%", style=sprintf("stop-color:%s;stop-opacity:1", arrow.cols[[from.type]])))
      svg_node('stop', lin.grad, c(offset="30%", style=sprintf("stop-color:%s;stop-opacity:1", arrow.cols[[from.type]])))
      svg_node('stop', lin.grad, c(offset="70%", style=sprintf("stop-color:%s;stop-opacity:1", arrow.cols[[to.type]])))
      svg_node('stop', lin.grad, c(offset="100%", style=sprintf("stop-color:%s;stop-opacity:1", arrow.cols[[to.type]])))
    }
  }
  svg_node('rect',svg, c(id="tooltip_bg", rx="2.5", ry="2.5", width="55", height="22", fill="white", 'stroke-width'="0.5", stroke="#696969", class="hidden"))
  svg_node('text',svg, c(id="tooltip", dy="-5", stroke="none", fill="#000000", 'text-anchor'="begin", class="sub-label"), XML::newXMLTextNode(' '))
  
  XML::addChildren(svg, kids=list(blank.arrow.g, blank.period.g))
  dinosvg:::write_svg(svg, file=outfile)
  
}
