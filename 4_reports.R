
p4_reports_targets_list <- list(

  # Render Markdown #
  # built in a {} fun chunk to be able to export file path and save a 'file' target

  tar_target(
    p4_markdown,
    {output_file <- '4_reports/out/watershed_extent_update_0928.html'
    rmarkdown::render(input = 'watershed_extent_update_0928.Rmd',
                      output_format = 'html_document',
                      output_file = output_file,
                      quiet = TRUE)
    return(output_file)
    },
    format = 'file')

)