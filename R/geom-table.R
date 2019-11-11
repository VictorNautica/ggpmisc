#' Inset tables
#'
#' \code{geom_table} adds a textual table directly to the ggplot using syntax
#' similar to that of \code{\link[ggplot2]{geom_label}} while
#' \code{geom_table_npc} is similar to \code{geom_label_npc} in that \code{x}
#' and \code{y} coordinates are given in npc units.
#'
#' The "width" and "height" of the table, like for text elements are 0, so
#' stacking and dodging tables will not work by default. In addition, axis
#' limits are not automatically expanded to include the whole tables, but
#' instead only their x and y coordinates. Obviously, tables do have height and
#' width, but they are in physical units, not data units. The amount of space
#' they occupy on a plot is not constant in data units: when you resize a plot,
#' tables stay the same size, but the size of the axes changes.
#'
#' @section Alignment: You can modify table alignment with the \code{vjust} and
#'   \code{hjust} aesthetics. These can either be a number between 0
#'   (right/bottom) and 1 (top/left) or a character ("left", "middle", "right",
#'   "bottom", "center", "top").
#'
#' @section Inset size: You can modify inset table size with the \code{size}
#'   aesthetics, which determines the size of text within the table.
#'
#' @param mapping The aesthetic mapping, usually constructed with
#'   \code{\link[ggplot2]{aes}} or \code{\link[ggplot2]{aes_}}. Only needs
#'   to be set at the layer level if you are overriding the plot defaults.
#' @param data A layer specific dataset - only needed if you want to override
#'   the plot defaults.
#' @param stat The statistical transformation to use on the data for this layer,
#'   as a string.
#' @param na.rm If \code{FALSE} (the default), removes missing values with a
#'   warning.  If \code{TRUE} silently removes missing values.
#' @param position Position adjustment, either as a string, or the result of a
#'   call to a position adjustment function.
#' @param ... other arguments passed on to \code{\link[ggplot2]{layer}}. This
#'   can include aesthetics whose values you want to set, not map. See
#'   \code{\link[ggplot2]{layer}} for more details.
#' @param parse If TRUE, the labels will be parsed into expressions and
#'   displayed as described in ?plotmath.
#' @param show.legend logical. Should this layer be included in the legends?
#'   \code{NA}, the default, includes if any aesthetics are mapped. \code{FALSE}
#'   never includes, and \code{TRUE} always includes.
#' @param inherit.aes If \code{FALSE}, overrides the default aesthetics, rather
#'   than combining with them. This is most useful for helper functions that
#'   define both data and aesthetics and shouldn't inherit behaviour from the
#'   default plot specification, e.g. \code{\link[ggplot2]{borders}}.
#'
#' @note These geoms work only with tibbles as \code{data}, as they expects a
#'   list of data frames or tibbles ("tb" objects) to be mapped to the
#'   \code{label} aesthetic. Aesthetics mappings in the inset plot are
#'   independent of those in the base plot.
#'
#'   In the case of \code{geom_table()}, \code{x} and \code{y} aesthetics
#'   determine the position of the whole inset table, similarly to that of a text
#'   label, justification is interpreted as indicating the position of the table
#'   with respect to the $x$ and $y$ coordinates in the data, and \code{angle}
#'   is used to rotate the table as a whole.
#'
#'   In the case of \code{geom_table_npc()}, \code{npcx} and \code{npcy} aesthetics
#'   determine the position of the whole inset table, similarly to that of a text
#'   label, justification is interpreted as indicating the position of the table
#'   with respect to the $x$ and $y$ coordinates in "npc" units, and \code{angle}
#'   is used to rotate the table as a whole.
#'
#'   \strong{\code{annotate()} cannot be used with \code{geom = "table"}}. Use
#'   \code{\link[ggplot2]{annotation_custom}} directly when adding inset tables
#'   as annotations.
#'
#' @references This geometry is inspired on answers to two questions in
#'   Stackoverflow. In contrast to these earlier examples, the current geom
#'   obeys the grammar of graphics, and attempts to be consistent with the
#'   behaviour of 'ggplot2' geometries.
#'   \url{https://stackoverflow.com/questions/12318120/adding-table-within-the-plotting-region-of-a-ggplot-in-r}
#'   \url{https://stackoverflow.com/questions/25554548/adding-sub-tables-on-each-panel-of-a-facet-ggplot-in-r?}
#'
#' @seealso function \code{\link[gridExtra]{tableGrob}} as it is used to
#'   construct the table.
#'
#' @family Statistics for adding insets to ggplots
#'
#' @export
#'
#' @examples
#' library(dplyr)
#' library(tibble)
#'
#' mtcars %>%
#'   group_by(cyl) %>%
#'   summarize(wt = mean(wt), mpg = mean(mpg)) %>%
#'   ungroup() %>%
#'   mutate(wt = sprintf("%.2f", wt),
#'          mpg = sprintf("%.1f", mpg)) -> tb
#'
#' df <- tibble(x = 0.95, y = 0.95, tb = list(tb))
#'
#' ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
#'   geom_point() +
#'   geom_table_npc(data = df, aes(npcx = x, npcy = y, label = tb),
#'                  hjust = 1, vjust = 1)
#'
geom_table <- function(mapping = NULL, data = NULL,
                       stat = "identity", position = "identity",
                       ...,
                       parse = FALSE,
                       na.rm = FALSE,
                       show.legend = FALSE,
                       inherit.aes = FALSE) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTable,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      parse = parse,
      na.rm = na.rm,
      ...
    )
  )
}

# Defined here to avoid a note in check --as-cran as the imports from 'broom'
# are not seen when the function is defined in-line in the ggproto object.
#' @rdname ggpmisc-ggproto
#'
#' @format NULL
#' @usage NULL
#'
gtb_draw_panel_fun <-
  function(data, panel_params, coord, parse = FALSE,
           na.rm = FALSE) {

    if (nrow(data) == 0) {
      return(grid::nullGrob())
    }

    if (!is.data.frame(data$label[[1]])) {
      warning("Skipping as object mapped to 'label' is not a list of \"tibble\" or \"data.frame\" objects.")
      return(grid::nullGrob())
    }

    # should be called only once!
    data <- coord$transform(data, panel_params)
    if (is.character(data$vjust)) {
      data$vjust <- compute_just(data$vjust, data$y)
    }
    if (is.character(data$hjust)) {
      data$hjust <- compute_just(data$hjust, data$x)
    }

    tb.grobs <- grid::gList()

    for (row.idx in 1:nrow(data)) {
      gtb <-
        gridExtra::tableGrob(
          d = data$label[[row.idx]],
          theme = gridExtra::ttheme_default(base_size = data$size * .pt,
                                            base_colour = ggplot2::alpha(data$colour, data$alpha),
                                            parse = parse),
          rows = NULL
        )

      gtb$vp <-
        grid::viewport(x = grid::unit(data$x[row.idx], "native"),
                       y = grid::unit(data$y[row.idx], "native"),
                       width = sum(gtb$widths),
                       height = sum(gtb$heights),
                       just = c(data$hjust[row.idx], data$vjust[row.idx]),
                       angle = data$angle[row.idx],
                       name = paste("geom_table.panel", data$PANEL[row.idx],
                                    "row", row.idx, sep = "."))

      # give unique name to each table
      gtb$name <- paste("table", row.idx, sep = ".")

      tb.grobs[[row.idx]] <- gtb
    }

    grid.name <- paste("geom_table.panel",
                       data$PANEL[row.idx], sep = ".")

    grid::gTree(children = tb.grobs, name = grid.name)
  }

#' @rdname ggpmisc-ggproto
#' @format NULL
#' @usage NULL
#' @export
GeomTable <-
  ggproto("GeomTable", Geom,
          required_aes = c("x", "y", "label"),

          default_aes = aes(
            colour = "black", size = 3.2, angle = 0, hjust = "inward",
            vjust = "inward", alpha = NA, family = "", fontface = 1,
            lineheight = 1.2
          ),

          draw_panel = gtb_draw_panel_fun,
          draw_key = function(...) {
            grid::nullGrob()
          }
  )

#' @rdname geom_table
#' @export
#'
geom_table_npc <- function(mapping = NULL, data = NULL,
                           stat = "identity", position = "identity",
                           ...,
                           parse = FALSE,
                           na.rm = FALSE,
                           show.legend = FALSE,
                           inherit.aes = FALSE) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTableNpc,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      parse = parse,
      na.rm = na.rm,
      ...
    )
  )
}

# Defined here to avoid a note in check --as-cran as the imports from 'broom'
# are not seen when the function is defined in-line in the ggproto object.
#' @rdname ggpmisc-ggproto
#'
#' @format NULL
#' @usage NULL
#'
gtbnpc_draw_panel_fun <-
  function(data, panel_params, coord, parse = FALSE,
           na.rm = FALSE) {

    if (nrow(data) == 0) {
      return(grid::nullGrob())
    }

    if (!is.data.frame(data$label[[1]])) {
      warning("Skipping as object mapped to 'label' is not a list of \"tibble\" or \"data.frame\" objects.")
      return(grid::nullGrob())
    }

    data$npcx <- compute_npcx(data$npcx)
    data$npcy <- compute_npcy(data$npcy)

    if (is.character(data$vjust)) {
      data$vjust <- compute_just(data$vjust, data$npcy)
    }
    if (is.character(data$hjust)) {
      data$hjust <- compute_just(data$hjust, data$npcx)
    }

    tb.grobs <- grid::gList()

    for (row.idx in 1:nrow(data)) {
      gtb <-
        gridExtra::tableGrob(
          d = data$label[[row.idx]],
          theme = gridExtra::ttheme_default(base_size = data$size * .pt,
                                            base_colour = ggplot2::alpha(data$colour, data$alpha),
                                            parse = parse),
          rows = NULL
        )

      gtb$vp <-
        grid::viewport(x = grid::unit(data$npcx[row.idx], "native"),
                       y = grid::unit(data$npcy[row.idx], "native"),
                       width = sum(gtb$widths),
                       height = sum(gtb$heights),
                       just = c(data$hjust[row.idx], data$vjust[row.idx]),
                       angle = data$angle[row.idx],
                       name = paste("geom_table.panel", data$PANEL[row.idx],
                                    "row", row.idx, sep = "."))

      # give unique name to each table
      gtb$name <- paste("table", row.idx, sep = ".")

      tb.grobs[[row.idx]] <- gtb
    }

    grid.name <- paste("geom_table.panel",
                       data$PANEL[row.idx], sep = ".")

    grid::gTree(children = tb.grobs, name = grid.name)
  }

#' @rdname ggpmisc-ggproto
#' @format NULL
#' @usage NULL
#' @export
GeomTableNpc <-
  ggproto("GeomTableNpc", Geom,
          required_aes = c("npcx", "npcy", "label"),

          default_aes = aes(
            colour = "black", size = 3.2, angle = 0, hjust = "inward",
            vjust = "inward", alpha = NA, family = "", fontface = 1,
            lineheight = 1.2
          ),

          draw_panel = gtbnpc_draw_panel_fun,

          draw_key = function(...) {
            grid::nullGrob()
          }
  )

# copied from geom-text.r from 'ggplot2' 3.1.0
compute_just <- function(just, x) {
  inward <- just == "inward"
  just[inward] <- c("left", "middle", "right")[just_dir(x[inward])]
  outward <- just == "outward"
  just[outward] <- c("right", "middle", "left")[just_dir(x[outward])]

  unname(c(left = 0, center = 0.5, right = 1,
           bottom = 0, middle = 0.5, top = 1)[just])
}

# copied from geom-text.r from 'ggplot2' 3.1.0
just_dir <- function(x, tol = 0.001) {
  out <- rep(2L, length(x))
  out[x < 0.5 - tol] <- 1L
  out[x > 0.5 + tol] <- 3L
  out
}