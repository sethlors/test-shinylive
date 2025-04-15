library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(here)
library(tibble)

# Load data files from the clean-data directory
status       <- read.csv("data/clean-data/status.csv")
races        <- read.csv("data/clean-data/races.csv")
drivers      <- read.csv("data/clean-data/drivers.csv")
results      <- read.csv("data/clean-data/results.csv")
constructors <- read.csv("data/clean-data/constructors.csv")
stints       <- read.csv("data/clean-data/stints.csv")
win_prob     <- read.csv("data/clean-data/win_prob.csv")

addResourcePath("assets", "assets")

# Points allocation for positions 1-10
points_table <- c(25, 18, 15, 12, 10, 8, 6, 4, 2, 1)

# Helper function to check if image exists and provide fallback
get_image_path <- function(base_path, id, default_path = "assets/default.jpg") {
  if (is.na(id) || id == "") {
    return(default_path)
  }
  full_path <- file.path(base_path, paste0(id, ".jpg"))

  if (file.exists(full_path)) {
    return(full_path)
  } else {
    message(paste("File not found:", full_path))
    return(default_path)
  }
}

# UI Definition
ui <- fluidPage(
  # Link to external CSS file in www directory
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "assets/styles.css"),
    # Include all required styles
    tags$style(HTML("
    /* Podium visualization specific styles */
    .podium-row {
      margin-top: 20px;
      margin-bottom: 30px;
    }
    .podium-box {
      position: relative;
      border-radius: 15px;
      overflow: hidden;
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
      height: 250px;
      /* Removed hover effect */
    }
    .box-gradient {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: linear-gradient(180deg, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.4) 100%);
      z-index: 1;
    }
    .glass-footer {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 60px;
      background: rgba(0, 0, 0, 0.5);
      backdrop-filter: blur(5px);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 15px;
      z-index: 2;
    }
    .driver-code {
      font-size: 24px;
      font-weight: bold;
      font-family: 'Titillium Web', sans-serif;
    }
    .position-label {
      font-size: 24px;
      font-weight: bold;
      font-family: 'Titillium Web', sans-serif;
    }
    .time-diff {
      font-size: 20px;
      font-weight: bold;
      font-family: 'Titillium Web', sans-serif;
    }
    .driver-img {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -60%);
      height: 150px;
      z-index: 1;
      border-radius: 5px;
      /* Make sure driver images don't cover controls */
      pointer-events: none;
    }
    .constructor-img {
      position: absolute;
      top: 10px;
      right: 10px;
      height: 60px;
      z-index: 2;
    }
    /* Control panel extension for year/track selectors */
    .control-panel {
      background-color: #141414;
      border-radius: 12px;
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
      padding: 22px;
      margin-bottom: 25px;
      transition: transform 0.2s, box-shadow 0.2s;
      /* Ensure the control panel has a higher z-index */
      position: relative;
      z-index: 10;
    }
    /* Add error message style */
    .error-message {
      color: #ff5555;
      text-align: center;
      padding: 20px;
      background-color: #1a1a1a;
      border-radius: 8px;
      margin: 20px 0;
    }

    /* Results table styling - NEW STYLES ADDED HERE */
    .table-custom {
      font-size: 16px !important;  /* Increase font size */
      width: 100%;
    }

    .table-custom th {
      text-align: center !important;
      font-size: 18px !important;  /* Larger header text */
      font-weight: bold;
      padding: 12px 8px !important;  /* Add more padding */
      vertical-align: middle !important;
    }

    .table-custom td {
      text-align: center !important;
      vertical-align: middle !important;
      padding: 10px 8px !important;  /* Add more padding */
    }

    /* Make sure table uses the full width */
    .table-container {
      width: 100%;
      overflow-x: auto;  /* Allow horizontal scrolling on small screens */
    }
  "))
  ),

  # App title
  div(class = "container-fluid",
      div(class = "row",
          div(class = "col-12 text-center",
              h2("F1 Race Analysis")
          )
      ),

      # Year and track selection inputs
      div(class = "row",
          div(class = "col-12",
              div(class = "control-panel",
                  div(class = "row",
                      div(class = "col-md-6",
                          selectInput("year", "Year", choices = sort(unique(races$year), decreasing = TRUE), selected = 2024)
                      ),
                      div(class = "col-md-6",
                          selectInput("track", "Track", choices = NULL)
                      )
                  )
              )
          )
      ),

      # Debug info (can be removed in production)
      verbatimTextOutput("debugInfo"),

      # Podium visualization
      uiOutput("podiumVisualization"),

      # Results table section
      div(class = "row",
          div(class = "col-12",
              h3("Race Results")
          )
      ),
      div(class = "row",
          div(class = "col-12",
              div(class = "table-container",
                  tableOutput("raceResults")
              )
          )
      ),

      # Tire strategy visualization section
      div(class = "row",
          div(class = "col-12",
              h3("Tire Strategy")
          )
      ),
      div(class = "row",
          div(class = "col-12",
              plotlyOutput("tireStrategyPlot", height = "600px")
          )
      ),
      div(class = "row",
          div(class = "col-12",
              plotlyOutput("winProbPlot")
          )
      )
  )
)

# Server logic
server <- function(input, output, session) {
  # Update track dropdown when year is selected
  observeEvent(input$year, {
    updateSelectInput(session, "track", choices = NULL, selected = NULL)
    races_for_year <- races[races$year == input$year,]
    available_tracks <- setNames(races_for_year$name, paste0(races_for_year$name, " - Round ", races_for_year$round))
    updateSelectInput(session, "track", choices = available_tracks)
  })

  # Get race ID based on selected year and track
  selected_race_id <- reactive({
    req(input$year, input$track)
    selected_race <- races[races$year == input$year & races$name == input$track,]
    if (nrow(selected_race) > 0) {
      return(selected_race$raceId[1])
    } else {
      return(NULL)
    }
  })

  # Prepare race results data
  race_data <- reactive({
    req(selected_race_id())

    # Get results for the selected race and merge with driver information
    results_filtered <- results[results$raceId == selected_race_id(),]

    # Check if we have results data
    if (nrow(results_filtered) == 0) {
      return(NULL)
    }

    # Merge with driver information
    race_results <- merge(results_filtered, drivers, by = "driverId")

    # Clean up missing values
    race_results$time <- ifelse(race_results$time == "\\N", NA, race_results$time)
    race_results$position <- ifelse(race_results$position == "\\N", NA, race_results$position)

    # Add status information
    race_results <- merge(race_results, status, by = "statusId", all.x = TRUE)

    # Add constructor information including color
    race_results <- merge(race_results, constructors, by = "constructorId", all.x = TRUE)

    # Convert position to numeric - ensure proper conversion
    race_results$position <- suppressWarnings(as.numeric(as.character(race_results$position)))

    # Use status message for DNF entries
    race_results$time <- ifelse(!is.na(race_results$time), race_results$time, race_results$status)

    # Create driver full name
    race_results$Driver <- paste(race_results$forename, race_results$surname)

    # Sort by finishing position
    race_results <- race_results[order(race_results$position, na.last = TRUE),]

    # Calculate points earned
    race_results$Points <- ifelse(race_results$position >= 1 & race_results$position <= 10,
                                  points_table[race_results$position], 0)
    race_results$Points <- paste0("+", race_results$Points)

    # Handle different column name variations from merges
    constructor_col <- ifelse("name.y" %in% colnames(race_results), "name.y",
                              ifelse("name.1" %in% colnames(race_results), "name.1", "name"))

    # Use actual driver code from the data rather than generating from surname
    race_results$Driver_Code <- race_results$code

    # Format positions with ordinals (1st, 2nd, etc.) or DNF
    race_results$formatted_position <- sapply(race_results$position, function(pos) {
      if (is.na(pos)) {
        return("DNF")
      } else {
        suffix <- switch(
          as.character(pos %% 10),
          "1" = if (pos %% 100 == 11) "th" else "st",
          "2" = if (pos %% 100 == 12) "th" else "nd",
          "3" = if (pos %% 100 == 13) "th" else "rd",
          "th"
        )
        return(paste0(pos, suffix))
      }
    })

    # Add image paths for constructors and drivers with path validation
    race_results$Constructor_Image <- sapply(race_results$constructorId, function(id) {
      get_image_path("assets/constructor-images/", id, "assets/default.jpg")
    })

    race_results$Driver_Image <- sapply(race_results$driverId, function(id) {
      get_image_path("assets/driver-images/", id, "assets/default.jpg")
    })

    # Create final dataset for display
    result_subset <- data.frame(
      Position = race_results$formatted_position,
      Driver = race_results$Driver,
      Code = race_results$Driver_Code,
      Time = race_results$time,
      Constructor = race_results[[constructor_col]],
      Constructor_Image = race_results$Constructor_Image,
      Driver_Image = race_results$Driver_Image,
      Points = race_results$Points,
      driverId = race_results$driverId,
      position = race_results$position,
      constructorId = race_results$constructorId,
      constructorColor = race_results$color
    )

    return(result_subset)
  })

  # Function to adjust colors for better visibility if needed
  adjustColor <- function(hexColor) {
    # Function to adjust color brightness if needed
    if (is.na(hexColor) || hexColor == "") {
      return("#333333") # Default color if missing
    }
    return(hexColor)
  }

  # Render podium visualization with improved error handling
  output$podiumVisualization <- renderUI({
    results <- race_data()
    if (is.null(results) || nrow(results) == 0) {
      return(div(class = "error-message", "No race data available"))
    }

    # Get top 3 drivers
    podium <- results[results$position <= 3, ]

    # Check if we have enough drivers for podium
    if (nrow(podium) < 3) {
      return(div(class = "error-message", "Not enough drivers finished in top 3 positions to display podium"))
    }

    # Make sure positions are correctly ordered
    podium <- podium[order(podium$position),]

    # Check if we have exactly positions 1, 2, and 3
    expected_positions <- c(1, 2, 3)
    actual_positions <- sort(podium$position[1:3])

    if (!all(actual_positions == expected_positions)) {
      return(div(class = "error-message",
                 paste("Expected positions 1, 2, 3, but found:",
                       paste(actual_positions, collapse=", "))))
    }

    # Use natural order (1st, 2nd, 3rd) instead of traditional podium layout
    podium_order <- podium[c(1, 2, 3), ]

    # Create position labels and time differences
    position_labels <- c("P1", "P2", "P3")
    time_diffs <- c(
      ifelse(podium_order$position[1] == 1, "Leader", ""),
      paste0("+ ", ifelse(is.na(podium_order$Time[2]) || podium_order$position[2] == 1, "0.000", podium_order$Time[2])),
      paste0("+ ", ifelse(is.na(podium_order$Time[3]) || podium_order$position[3] == 1, "0.000", podium_order$Time[3]))
    )

    # Create the podium boxes
    fluidRow(
      class = "podium-row",

      # P1 - First Place (Left)
      column(4,
             div(class = "podium-box",
                 style = paste0("background-color: ", adjustColor(podium_order$constructorColor[1]), ";"),
                 div(class = "box-gradient"),
                 img(class = "driver-img", src = podium_order$Driver_Image[1]),
                 img(class = "constructor-img", src = podium_order$Constructor_Image[1]),
                 div(class = "glass-footer",
                     div(class = "driver-code", podium_order$Code[1]),
                     div(class = "position-label", position_labels[1]),
                     div(class = "time-diff", time_diffs[1])
                 )
             )
      ),

      # P2 - Second Place (Middle)
      column(4,
             div(class = "podium-box",
                 style = paste0("background-color: ", adjustColor(podium_order$constructorColor[2]), ";"),
                 div(class = "box-gradient"),
                 img(class = "driver-img", src = podium_order$Driver_Image[2]),
                 img(class = "constructor-img", src = podium_order$Constructor_Image[2]),
                 div(class = "glass-footer",
                     div(class = "driver-code", podium_order$Code[2]),
                     div(class = "position-label", position_labels[2]),
                     div(class = "time-diff", time_diffs[2])
                 )
             )
      ),

      # P3 - Third Place (Right)
      column(4,
             div(class = "podium-box",
                 style = paste0("background-color: ", adjustColor(podium_order$constructorColor[3]), ";"),
                 div(class = "box-gradient"),
                 img(class = "driver-img", src = podium_order$Driver_Image[3]),
                 img(class = "constructor-img", src = podium_order$Constructor_Image[3]),
                 div(class = "glass-footer",
                     div(class = "driver-code", podium_order$Code[3]),
                     div(class = "position-label", position_labels[3]),
                     div(class = "time-diff", time_diffs[3])
                 )
             )
      )
    )
  })

  # Render results table with formatted HTML content
  output$raceResults <- renderTable({
    results <- race_data()
    if (is.null(results) || nrow(results) == 0) return(NULL)

    # Create a formatted version for display
    display_results <- results %>%
      select(Position, Driver, Code, Constructor, Time, Points) %>%
      mutate(
        Constructor = paste0(
          '<div style="display: flex; align-items: center; justify-content: center;">',
          '<img src="', results$Constructor_Image, '" height="30" style="margin-right: 10px;"> ',
          Constructor,
          '</div>'
        )
      )

    # Return the results with HTML formatting
    display_results
  },
  sanitize.text.function = function(x) x,
  striped = TRUE,
  hover = TRUE,
  bordered = TRUE,
  align = 'c',
  width = "100%",  # Ensure table uses full width available
  class = "table-custom")  # Add a custom class for styling

  # Prepare tire strategy data
  tire_stints <- reactive({
    req(selected_race_id())

    # Get race results for driver order
    results_order <- race_data()
    if (is.null(results_order) || nrow(results_order) == 0) return(NULL)

    # Get tire stints for the selected race
    race_stints <- stints[stints$raceId == selected_race_id(),]
    if (nrow(race_stints) == 0) return(NULL)

    # Add driver information to stints
    driver_info <- merge(race_stints, drivers, by = "driverId", all.x = TRUE)
    driver_info$Driver <- paste(driver_info$forename, driver_info$surname)

    # Use actual driver code
    driver_info$Driver_Code <- driver_info$code

    # Remove rows with missing driver info
    driver_info <- driver_info[!is.na(driver_info$Driver),]

    # Identify tire changes to determine stint boundaries
    driver_info <- driver_info %>%
      arrange(driverId, lap) %>%
      group_by(driverId) %>%
      mutate(
        tire_prev = lag(tireCompound, default = "NONE"),
        new_stint = tireCompound != tire_prev | is.na(tireCompound) != is.na(tire_prev),
        stint_number = cumsum(new_stint)
      ) %>%
      ungroup()

    # Summarize stint information (start lap, end lap, compound)
    stint_summary <- driver_info %>%
      filter(!is.na(tireCompound)) %>%
      group_by(driverId, Driver, Driver_Code, stint_number, tireCompound, compoundColor) %>%
      summarise(
        start_lap = min(lap),
        end_lap = max(lap),
        laps = end_lap - start_lap + 1,
        .groups = "drop"
      )

    # Order drivers according to race finish position
    driver_levels <- rev(results_order$Driver)
    driver_codes <- rev(results_order$Code)

    # Prepare data for visualization
    stint_summary$Driver_Name <- stint_summary$Driver  # Keep full name for hover
    stint_summary$Driver <- factor(stint_summary$Driver, levels = driver_levels)  # For ordering
    stint_summary$Driver_Code <- factor(stint_summary$Driver_Code,
                                        levels = driver_codes[match(driver_levels, results_order$Driver[order(results_order$position, decreasing = TRUE)])])

    # Adjust visual properties for short stints
    stint_summary$visual_width <- pmax(stint_summary$laps, 2)  # Minimum visual width
    stint_summary$label_x_adj <- ifelse(stint_summary$laps == 1, 0.5, 0)  # Adjust label position

    return(stint_summary)
  })

  # Render tire strategy plot
  output$tireStrategyPlot <- renderPlotly({
    stints <- tire_stints()
    if (is.null(stints) || nrow(stints) == 0) {
      return(NULL)
    }

    # Define F1 tire compound colors
    tire_colors <- c(
      "HARD" = "#FFFFFF",      # White
      "MEDIUM" = "#FED218",    # Yellow
      "SOFT" = "#DD0741",      # Red
      "SUPERSOFT" = "#DA0640", # Red
      "ULTRASOFT" = "#A9479E", # Purple
      "HYPERSOFT" = "#FEB4C3", # Pink
      "INTERMEDIATE" = "#45932F", # Green
      "WET" = "#2F6ECE"        # Blue
    )

    max_lap <- max(stints$end_lap, na.rm = TRUE)

    # Create hover text for interactive display
    stints$hover_text <- paste0(
      stints$Driver_Name, "<br>",  # Use full name in the hover
      stints$tireCompound, ": ", stints$laps, " Laps<br>",
      "Laps ", stints$start_lap, "-", stints$end_lap
    )

    # Adjust visual width for short stints
    stints$visual_end_lap <- ifelse(stints$laps == 1,
                                    stints$start_lap + 1.5,  # Make 1-lap stints wider
                                    stints$end_lap + 1)      # Normal end lap + 1

    # Create strategy visualization with ggplot
    p <- ggplot(stints, aes(xmin = start_lap, xmax = visual_end_lap, y = Driver_Code, fill = tireCompound)) +
      # Draw rectangles for tire stints
      geom_rect(aes(ymin = as.numeric(Driver_Code) - 0.4,
                    ymax = as.numeric(Driver_Code) + 0.4,
                    text = hover_text),
                color = "#222222", size = 0.1) +
      # Add lap count labels
      geom_text(aes(
        x = ifelse(laps <= 2,
                   start_lap + 0.75,  # Center text for short stints
                   start_lap + (end_lap - start_lap) / 2),  # Center text for normal stints
        y = Driver_Code,
        label = laps
      ),
      color = "black", size = 3.5, fontface = "bold") +
      # Apply tire colors
      scale_fill_manual(values = tire_colors, name = "Tire Compound") +
      # Add labels
      labs(
        title = paste("Tire Strategy:", input$track, input$year),
        subtitle = "Showing number of laps per compound",
        x = "Lap",
        y = ""
      ) +
      # Apply dark theme
      theme_minimal() +
      theme(
        text = element_text(family = "Titillium Web"),
        plot.background = element_rect(fill = "#0a0a0a", color = "#0a0a0a"),
        panel.background = element_rect(fill = "#0a0a0a", color = "#0a0a0a"),
        panel.grid.major.x = element_line(color = "#333333", size = 0.2),
        panel.grid.major.y = element_line(color = "#333333", size = 0.2),
        panel.grid.minor = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 18, face = "bold", color = "white", margin = margin(b = 10)),
        plot.subtitle = element_text(hjust = 0.5, size = 12, color = "#cccccc", margin = margin(b = 20)),
        axis.text = element_text(color = "white", size = 10),
        axis.title = element_text(color = "white", size = 12),
        axis.text.y = element_text(size = 11, face = "bold", margin = margin(r = 5)),
        legend.background = element_rect(fill = "#0a0a0a"),
        legend.text = element_text(color = "white"),
        legend.title = element_text(color = "white", face = "bold"),
        legend.position = "bottom",
        legend.key = element_rect(color = NA),
        legend.key.size = unit(1, "cm"),
        plot.margin = margin(20, 20, 20, 20)
      ) +
      # Set x-axis breaks and limits - CHANGED HERE to start at lap 1
      scale_x_continuous(
        breaks = seq(1, max_lap + 5, by = 5),  # Starting from 1 instead of 0
        limits = c(1, max_lap + 2)             # Starting from 1 instead of 0
      )

    # Convert to interactive plotly visualization
    ggplotly(p, tooltip = "text") %>%
      layout(
        paper_bgcolor = "#0a0a0a",
        plot_bgcolor = "#0a0a0a",
        font = list(color = "white", family = "Titillium Web"),
        hoverlabel = list(
          bgcolor = "black",
          bordercolor = "white",
          font = list(family = "Titillium Web", size = 12, color = "white")
        ),
        legend = list(
          orientation = "h",
          y = -0.15,
          bgcolor = "rgba(20,20,20,0.7)"
        )
      ) %>%
      config(displayModeBar = FALSE)
  })

  output$winProbPlot <- renderPlotly({

    req(selected_race_id())

    win_prob_filtered <- win_prob[win_prob$raceId == selected_race_id(),]

    # Create a named vector: names are drivers, values are colors
    driver_colors <- win_prob_filtered %>%
      select(driver, team_color) %>%
      distinct() %>%
      deframe()  # turns two-column data into a named vector

    # Find the last lap for each driver
    last_lap <- win_prob_filtered %>%
      group_by(driver) %>%
      filter(lap == max(lap)) %>%
      ungroup()

    # Get order of drivers based on final prediction
    driver_order <- last_lap %>%
      arrange(desc(win_prob)) %>%  # or asc() if lower = better
      pull(driver)

    # Reorder the driver factor in your dataset
    win_prob_filtered <- win_prob_filtered %>%
      mutate(driver = factor(driver, levels = driver_order))

    # Create the win probability plot
    p <- ggplot(win_prob_filtered, aes(
      x = lap,
      y = win_prob,
      color = driver,
      group = driver,
      text = paste0("Driver: ", driver,
                    "<br>Lap: ", lap,
                    "<br>Win Prob: ", round(win_prob, 3))
    )) +
      geom_line(linewidth = 1) +
      scale_color_manual(values = driver_colors) +
      scale_x_continuous(limits = c(1, NA)) +
      scale_y_continuous(limits = c(0, 1)) +
      labs(
        title = "Random Forest Win Probability by Driver",
        x = "Lap",
        y = "Win Probability",
        color = "Driver"
      ) +
      theme_minimal()

    # Convert to a plotly interactive
    ggplotly(p, tooltip = "text") %>%
      config(displayModeBar = FALSE)

  })



}

# Start the Shiny app
shinyApp(ui = ui, server = server)