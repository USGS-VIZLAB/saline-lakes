
p4_reports_targets_list <- list(

  ## Render Markdown #
  ## built in a {} fun chunk to be able to export file path and save a 'file' target
  ## Note: the input Rmd for the rmarkdown::render() function requires that the input sits in root folder of WD, otherwise is resets the wd for you.
  ## Get crytic message - mine was that the `4_reports/out/` isn't a directory.
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