#### Shiny server file ####
shinyServer(function(input, output, session) {

  #### Logic for column 1 ####

  # Updating input elements
  observe({
    validate(need(!is.na(input$minimum1), "Value must be set!"))
    validate(need(!is.na(input$maximum1), "Value must be set!"))

    updateNumericInput(session, "attribute_num", min = input$minimum1, max = input$maximum1)

    if (input$attribute_num < input$minimum1 | input$attribute_num > input$maximum1) {
      updateNumericInput(session, "attribute_num", value = input$minimum1)
    }
  })

  observeEvent(input$attribute_num, {
    updateNumericInput(session, "probability1", value = values$attributes_prob[values$attributes_id == input$attribute_num])
  })

  # Observer to change attribute properties
  observe({
    # Change number of arributes
    values$attributes_id <- seq(input$minimum1, input$maximum1, by = 1)

    if (input$preset_go1 == 0) {
      if (length(values$attributes_id) != length(values$attributes_prob)) {
        values$attributes_prob <- dnorm(values$attributes_id, mean = 6, sd = 1)
      }
    }
  })

  # Observer for manual probability adjustments (col 1)
  # TODO: Perform check so that sum of probability approximates 1
  observeEvent(input$probability1, {
    values$attributes_prob[values$attributes_id == input$attribute_num] <- input$probability1
  })

  # Observer for presets in column 1
  observeEvent(input$preset_go1, {
    # Apply presets only if button is pressed
    if (input$preset_go1 != 0) {
      cat("pressed preset_go1 \n")
      if (input$preset_types1 == "Normal") {
        values$attributes_prob <- dnorm(values$attributes_id, mean = input$`1_norm_mean`, sd = input$`1_norm_sd`)
      } else if (input$preset_types1 == "Poisson") {
        values$attributes_prob <- dpois(values$attributes_id, lambda = input$`1_pois_lambda`)
      } else if (input$preset_types1 == "Exponential") {
        values$attributes_prob <- dexp(values$attributes_id, rate = input$`1_exp_rate`)
      } else if (input$preset_types1 == "Uniform") {
        values$attributes_prob <- dunif(values$attributes_id, min = input$minimum1 - 1, max = input$maximum1)
      }
    }
  })

  # Plot in column 1
  output$plot1 <- renderPlot({

    data <- data.frame(x = values$attributes_id,
                       y = values$attributes_prob[seq_along(values$attributes_id)],
                       mark = rep("No", length(values$attributes_id)),
                       stringsAsFactors = F)

    data$mark[data$x == input$attribute_num] <- "Yes"

    p <- ggplot(data = data, aes(x = x, weight = y, fill = mark)) +
          geom_bar(width = .1) +
          geom_text(aes(y = y, label = prettify_probs(y, 3)), nudge_y = .02) +
          scale_fill_manual(values = c(No = "black", Yes = "red2"), guide = F) +
          labs(x = "Attribute", y = "Probability") +
          scale_x_continuous(breaks = seq(1, 1000, 1)) +
          theme_bw() +
          theme(plot.background = element_rect(fill = plot_bg),
                panel.background = element_rect(fill = panel_bg))

    if (input$plot1_fixy) {
      p <- p + ylim(0, 1)
    }

    return(p)
  })

  #### Logic for column 2 ####

  # Updating input elements
  observe({
    validate(need(!is.na(input$maximum2), "Value must be set!"))

    updateNumericInput(session, "category", min = 1, max = input$maximum2)

    if (input$category > input$maximum2) {
      updateNumericInput(session, "category", value = 1)
    }
  })

  observeEvent(input$category, {
    updateNumericInput(session, "probability2", value = values$category_prob[values$category_id == input$category])
  })

  # Observer to change category properties
  observe({
    # Change number of attributes
    values$category_id <- seq(1, input$maximum2, by = 1)

    if (input$preset_go2 == 0) {
      if (length(values$category_id) != length(values$category_prob)) {
        values$category_prob <- dexp(values$category_id, rate = 0.15)
      }
    }
  })

  # Observer for manual probability adjustments (col 2)
  # TODO: Perform check so that sum of probability approximates 1
  observeEvent(input$probability2, {
    values$category_prob[values$category_id == input$category] <- input$probability2
  })

  # Observer for presets in column 1
  observeEvent(input$preset_go2, {
    # Apply presets only if button is pressed
    if (input$preset_types2 == "Normal") {
      values$category_prob <- dnorm(values$category_id, mean = input$`2_norm_mean`, sd = input$`2_norm_sd`)
    } else if (input$preset_types2 == "Poisson") {
      values$category_prob <- dpois(values$category_id, lambda = input$`2_pois_lambda`)
    } else if (input$preset_types2 == "Exponential") {
      values$category_prob <- dexp(values$category_id, rate = input$`2_exp_rate`)
    } else if (input$preset_types2 == "Uniform") {
      values$category_prob <- dunif(values$category_id, min = 1 - 1, max = input$maximum2)
    }
  })

  # Plot for column 2
  output$plot2 <- renderPlot({
    data <- data.frame(x = values$category_id,
                       y = values$category_prob,
                       mark = rep("No", length(values$category_id)),
                       stringsAsFactors = F)

    data$mark[data$x == input$category] <- "Yes"

    # x axis labels depending on number of categories
    if (input$maximum2 <= 10) {
      x_breaks <- seq(1, 10, 1)
    } else if (input$maximum2 > 10 & input$maximum2 <= 20) {
      x_breaks <- seq(1, 1000, 2)
    } else {
      x_breaks <- seq(1, 1000, 5)
    }

    p <- ggplot(data = data, aes(x = x, weight = y, fill = mark)) +
          geom_bar(width = .1)
          if (plot_repel) {
            p <- p + ggrepel::geom_text_repel(aes(y = y, label = prettify_probs(y, 4)))
          } else {
            p <- p + geom_text(aes(y = y, label = prettify_probs(y, 3)))
          }
          p <- p + scale_fill_manual(values = c(No = "black", Yes = "red2"), guide = F) +
          labs(x = "Categories", y = "Probability") +
          scale_x_continuous(breaks = x_breaks) +
          theme_bw() +
          theme(plot.background = element_rect(fill = plot_bg),
                panel.background = element_rect(fill = panel_bg))

    if (input$plot2_fixy) {
      p <- p + ylim(0, 1)
    }

    return(p)
  })

  #### Logic for column 3 ####

  observeEvent(input$sample_random, {
      values$sample_plot <- gridsampler::draw_n_person_sample(prob = isolate(values$category_prob),
                                                              n = isolate(input$sample_size),
                                                              a = isolate(values$attributes_id),
                                                              ap = isolate(values$attributes_prob)) +
                              theme_bw() +
                              theme(plot.background = element_rect(fill = plot_bg),
                                    panel.background = element_rect(fill = panel_bg))
  })

  observeEvent(input$run_button, {
    r <- sim_n_persons_x_times(prob = isolate(values$category_prob),
                               n = isolate(input$sample_size),
                               a = isolate(values$attributes_id),
                               ap = isolate(values$attributes_prob),
                               times = isolate(input$run_times))

    values$sample_plot <- expected_frequencies(r) +
                            theme_bw() +
                            theme(plot.background  = element_rect(fill = plot_bg),
                                  panel.background = element_rect(fill = panel_bg),
                                  legend.background =  element_rect(fill = "#f5f5f5"))
  })

  # Plot 1 of column 3
  output$plot3_1 <- renderPlot({

    if (input$sample_random == 0 & input$run_button == 0) {
      # Show placeholder plot if no button was pressed yet...
      p_31
    } else {
      # ...otherwise show stored plot from above
      values$sample_plot
    }
  })

  #### Bottom half of column 3
  observeEvent(input$simulate, {
    withProgress(message = "Running simulations…", {

      # This is basically a verbatim copy of sim_n_persons_x_times_many_n
      # I extracted it here because for reasons I don't understand it didn't work otherwise
      r <- list()
      n <- text_to_vector(isolate(input$sample_size2))
      for (i in seq_along(n)) {
        r[[i]] <- sim_n_persons_x_times(values$category_prob, n = n[i], a = values$attributes_id,
                                        ap = values$attributes_prob, times = isolate(input$runs_per_sample))
        incProgress(amount = 1/length(n), detail = paste("SImulation ", i))
      }
      r

      values$simulations <- r
    })
  })

  # Plot 2 of column 3
  output$plot3_2 <- renderPlot({
    input$redraw

    if (input$redraw == 0 & is.null(values$simulations)) {
      return(p_32)
    }


    N <- text_to_vector(isolate(input$sample_size2))
    M <- text_to_vector(isolate(input$mincount_m))
    p <- text_to_vector(isolate(input$proportion_k))
    d <- calc_probabilities(r = values$simulations, n = N, ms = M, min.props = p)

    draw_multiple_n_persons_x_times(d) +
      theme_bw() +
      theme(plot.background = element_rect(fill = plot_bg),
            panel.background = element_rect(fill = panel_bg),
            legend.background =  element_rect(fill = "#f5f5f5"))
  })
})