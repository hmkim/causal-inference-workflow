#!/usr/bin/env nextflow

/*
 * Causal Inference Workflow in R using Nextflow
 * 
 * This workflow demonstrates causal inference techniques including:
 * 1. Data generation
 * 2. Exploratory data analysis
 * 3. Propensity score matching
 * 4. Results summary and visualization
 */

nextflow.enable.dsl = 2

// Print workflow information
log.info """
    CAUSAL INFERENCE WORKFLOW
    =========================
    Output directory: ${params.outdir}
    """

/*
 * PROCESS: Generate synthetic data for causal inference
 */
process GENERATE_DATA {
    publishDir "${params.outdir}/data", mode: 'copy'
    
    output:
    path "training_data.csv"
    path "parameters.rds"
    
    script:
    """
    #!/usr/bin/env Rscript

    library(dplyr)
    library(ggplot2)

    set.seed(42)

    n <- 1000

    age <- rnorm(n, mean = 35, sd = 10)
    education <- pmax(8, pmin(20, round(rnorm(n, mean = 12, sd = 3))))
    prior_earnings <- pmax(0, rnorm(n, mean = 25000 + 1000 * education + 500 * age, sd = 8000))

    treatment_prob <- plogis(-2 + 0.05 * age + 0.2 * education - 0.00002 * prior_earnings)
    treatment <- rbinom(n, 1, treatment_prob)
    true_effect <- 3000
    post_earnings <- 20000 + 
                     true_effect * treatment + 
                     800 * education + 
                     300 * age + 
                     0.3 * prior_earnings + 
                     rnorm(n, 0, 5000)

    data <- data.frame(
      id = 1:n,
      age = age,
      education = education,
      prior_earnings = prior_earnings,
      treatment = treatment,
      post_earnings = post_earnings
    )

    write.csv(data, "training_data.csv", row.names = FALSE)

    cat("Data generation completed!\\n")
    cat("Sample size:", nrow(data), "\\n")
    cat("Treatment group size:", sum(data[['treatment']]), "\\n")
    cat("Control group size:", sum(1 - data[['treatment']]), "\\n")
    cat("True treatment effect: USD", true_effect, "\\n")

    params <- list(
      n = n,
      true_effect = true_effect,
      treatment_n = sum(data[['treatment']]),
      control_n = sum(1 - data[['treatment']])
    )

    saveRDS(params, "parameters.rds")
    """
}

/*
 * PROCESS: Exploratory data analysis
 */
process EXPLORATORY_ANALYSIS {
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    path data_csv
    path parameters_rds
    
    output:
    path "results/*.png"
    path "results/*.csv"
    path "results/naive_effect.rds"
    
    script:
    """
    #!/usr/bin/env Rscript

    # Exploratory Data Analysis for Causal Inference

    library(ggplot2)
    library(dplyr)
    library(tidyr)

    # Create data directory and copy files
    dir.create("data", showWarnings = FALSE)
    file.copy("${data_csv}", "data/training_data.csv")
    file.copy("${parameters_rds}", "data/parameters.rds")

    # Load data
    data <- read.csv("data/training_data.csv")

    # Create output directory
    dir.create("results", showWarnings = FALSE)

    # 1. Distribution of covariates by treatment group
    p1 <- data %>%
      select(treatment, age, education, prior_earnings) %>%
      pivot_longer(cols = -treatment, names_to = "variable", values_to = "value") %>%
      mutate(treatment = factor(treatment, labels = c("Control", "Treatment"))) %>%
      ggplot(aes(x = value, fill = treatment)) +
      geom_histogram(alpha = 0.7, position = "identity", bins = 30) +
      facet_wrap(~variable, scales = "free") +
      labs(title = "Distribution of Covariates by Treatment Group",
           x = "Value", y = "Count", fill = "Group") +
      theme_minimal()

    ggsave("results/covariate_distributions.png", p1, width = 12, height = 8, dpi = 300)

    # 2. Outcome distribution by treatment
    p2 <- ggplot(data, aes(x = factor(treatment, labels = c("Control", "Treatment")), 
                           y = post_earnings, fill = factor(treatment))) +
      geom_boxplot(alpha = 0.7) +
      geom_jitter(alpha = 0.3, width = 0.2) +
      labs(title = "Post-Training Earnings by Treatment Group",
           x = "Treatment Group", y = "Post-Training Earnings (USD)",
           fill = "Group") +
      theme_minimal() +
      theme(legend.position = "none")

    ggsave("results/outcome_by_treatment.png", p2, width = 8, height = 6, dpi = 300)

    # 3. Correlation matrix
    cor_data <- data %>%
      select(age, education, prior_earnings, treatment, post_earnings) %>%
      cor()

    # Convert correlation matrix to long format for plotting
    cor_long <- cor_data %>%
      as.data.frame() %>%
      mutate(var1 = rownames(.)) %>%
      pivot_longer(-var1, names_to = "var2", values_to = "correlation")

    p3 <- ggplot(cor_long, aes(x = var1, y = var2, fill = correlation)) +
      geom_tile() +
      scale_fill_gradient2(low = "blue", mid = "white", high = "red", 
                           midpoint = 0, limit = c(-1, 1)) +
      labs(title = "Correlation Matrix of Variables",
           x = "", y = "", fill = "Correlation") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))

    ggsave("results/correlation_matrix.png", p3, width = 8, height = 6, dpi = 300)

    # 4. Summary statistics
    summary_stats <- data %>%
      group_by(treatment) %>%
      summarise(
        n = n(),
        mean_age = mean(age),
        mean_education = mean(education),
        mean_prior_earnings = mean(prior_earnings),
        mean_post_earnings = mean(post_earnings),
        .groups = 'drop'
      )

    write.csv(summary_stats, "results/summary_statistics.csv", row.names = FALSE)

    # Naive treatment effect (without adjustment)
    naive_effect <- mean(data[['post_earnings']][data[['treatment']] == 1]) - 
                    mean(data[['post_earnings']][data[['treatment']] == 0])

    cat("Exploratory analysis completed!\\n")
    cat("Naive treatment effect (unadjusted): USD", round(naive_effect, 2), "\\n")

    # Save naive effect for comparison
    saveRDS(naive_effect, "results/naive_effect.rds")
    """
}

/*
 * PROCESS: Propensity score matching analysis
 */
process PROPENSITY_MATCHING {
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    path data_csv
    path parameters_rds
    
    output:
    path "results/*.png"
    path "results/*.txt"
    path "results/*.csv"
    path "results/matching_results.rds"
    
    script:
    """
    #!/usr/bin/env Rscript

    # Propensity Score Matching Analysis

    library(MatchIt)
    library(cobalt)
    library(ggplot2)
    library(dplyr)
    library(broom)

    # Create data directory and copy files
    dir.create("data", showWarnings = FALSE)
    file.copy("${data_csv}", "data/training_data.csv")
    file.copy("${parameters_rds}", "data/parameters.rds")

    # Load data
    data <- read.csv("data/training_data.csv")

    # Create output directory
    dir.create("results", showWarnings = FALSE)

    # 1. Estimate propensity scores
    ps_model <- glm(treatment ~ age + education + prior_earnings, 
                    data = data, family = binomial)

    # Add propensity scores to data
    data[['propensity_score']] <- predict(ps_model, type = "response")

    # 2. Perform matching
    match_out <- matchit(treatment ~ age + education + prior_earnings,
                         data = data,
                         method = "nearest",
                         distance = "glm",
                         caliper = 0.1)

    # 3. Check balance before and after matching
    balance_before <- bal.tab(match_out, un = TRUE)
    balance_after <- bal.tab(match_out)

    # Save balance results
    capture.output(balance_before, file = "results/balance_before_matching.txt")
    capture.output(balance_after, file = "results/balance_after_matching.txt")

    # 4. Create balance plots
    p1 <- bal.plot(match_out, var.name = "age", which = "both") +
      labs(title = "Balance for Age: Before and After Matching")

    p2 <- bal.plot(match_out, var.name = "education", which = "both") +
      labs(title = "Balance for Education: Before and After Matching")

    p3 <- bal.plot(match_out, var.name = "prior_earnings", which = "both") +
      labs(title = "Balance for Prior Earnings: Before and After Matching")

    ggsave("results/balance_age.png", p1, width = 10, height = 6, dpi = 300)
    ggsave("results/balance_education.png", p2, width = 10, height = 6, dpi = 300)
    ggsave("results/balance_prior_earnings.png", p3, width = 10, height = 6, dpi = 300)

    # 5. Propensity score distribution plot
    ps_plot_data <- data %>%
      mutate(treatment_label = factor(treatment, labels = c("Control", "Treatment")))

    p4 <- ggplot(ps_plot_data, aes(x = propensity_score, fill = treatment_label)) +
      geom_histogram(alpha = 0.7, position = "identity", bins = 30) +
      labs(title = "Propensity Score Distribution by Treatment Group",
           x = "Propensity Score", y = "Count", fill = "Group") +
      theme_minimal()

    ggsave("results/propensity_score_distribution.png", p4, width = 10, height = 6, dpi = 300)

    # 6. Extract matched data and estimate treatment effect
    matched_data <- match.data(match_out)

    # Estimate treatment effect on matched data
    matched_effect <- lm(post_earnings ~ treatment + age + education + prior_earnings,
                         data = matched_data, weights = weights)

    # Get treatment effect estimate
    treatment_coef <- tidy(matched_effect) %>%
      filter(term == "treatment")

    ate_estimate <- treatment_coef[['estimate']]
    ate_se <- treatment_coef[['std.error']]
    ate_ci_lower <- ate_estimate - 1.96 * ate_se
    ate_ci_upper <- ate_estimate + 1.96 * ate_se

    # Save results
    results <- list(
      ate_estimate = ate_estimate,
      ate_se = ate_se,
      ate_ci_lower = ate_ci_lower,
      ate_ci_upper = ate_ci_upper,
      n_matched = nrow(matched_data),
      n_treated_matched = sum(matched_data[['treatment']]),
      n_control_matched = sum(1 - matched_data[['treatment']])
    )

    saveRDS(results, "results/matching_results.rds")

    # Print results
    cat("Propensity Score Matching completed!\\n")
    cat("Matched sample size:", nrow(matched_data), "\\n")
    cat("ATE estimate: USD", round(ate_estimate, 2), "\\n")
    cat("95% CI: (USD", round(ate_ci_lower, 2), ", USD", round(ate_ci_upper, 2), ")\\n")

    # Save summary
    write.csv(tidy(matched_effect), "results/matching_regression_results.csv", row.names = FALSE)
    """
}

/*
 * PROCESS: Final results summary
 */
process FINAL_RESULTS {
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    path parameters_rds
    path naive_effect_rds
    path matching_results_rds
    
    output:
    path "results/*.png"
    path "results/*.csv"
    path "results/*.txt"
    
    script:
    """
    #!/usr/bin/env Rscript

    # Final Results Summary and Visualization

    library(ggplot2)
    library(dplyr)

    # Create directories and copy files
    dir.create("data", showWarnings = FALSE)
    dir.create("results", showWarnings = FALSE)
    
    file.copy("${parameters_rds}", "data/parameters.rds")
    file.copy("${naive_effect_rds}", "results/naive_effect.rds")
    file.copy("${matching_results_rds}", "results/matching_results.rds")

    # Load all results
    params <- readRDS("data/parameters.rds")
    naive_effect <- readRDS("results/naive_effect.rds")
    matching_results <- readRDS("results/matching_results.rds")

    # Create comparison plot
    results_comparison <- data.frame(
      Method = c("True Effect", "Naive (Unadjusted)", "Propensity Score Matching"),
      Estimate = c(params[['true_effect']], naive_effect, matching_results[['ate_estimate']]),
      Lower_CI = c(params[['true_effect']], naive_effect, matching_results[['ate_ci_lower']]),
      Upper_CI = c(params[['true_effect']], naive_effect, matching_results[['ate_ci_upper']])
    )

    # Add standard errors (0 for true effect and naive for simplicity)
    results_comparison[['SE']] <- c(0, 0, matching_results[['ate_se']])

    p1 <- ggplot(results_comparison, aes(x = Method, y = Estimate, color = Method)) +
      geom_point(size = 4) +
      geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2, size = 1) +
      geom_hline(yintercept = params[['true_effect']], linetype = "dashed", color = "red", alpha = 0.7) +
      labs(title = "Comparison of Treatment Effect Estimates",
           subtitle = paste("True effect: USD", params[['true_effect']]),
           x = "Method", y = "Treatment Effect Estimate (USD)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            legend.position = "none") +
      scale_color_manual(values = c("red", "blue", "green"))

    ggsave("results/treatment_effect_comparison.png", p1, width = 10, height = 8, dpi = 300)

    # Create summary table
    summary_table <- results_comparison %>%
      mutate(
        CI_95 = paste0("(", round(Lower_CI, 0), ", ", round(Upper_CI, 0), ")"),
        Estimate = round(Estimate, 0)
      ) %>%
      select(Method, Estimate, CI_95) %>%
      rename(`95% CI` = CI_95)

    write.csv(summary_table, "results/final_summary_table.csv", row.names = FALSE)

    # Calculate bias and coverage
    bias_naive <- naive_effect - params[['true_effect']]
    bias_matching <- matching_results[['ate_estimate']] - params[['true_effect']]

    # Check if true effect is within CI for matching
    coverage_matching <- (params[['true_effect']] >= matching_results[['ate_ci_lower']]) & 
                         (params[['true_effect']] <= matching_results[['ate_ci_upper']])

    # Create final report
    report <- paste0(
      "CAUSAL INFERENCE ANALYSIS REPORT\\n",
      "================================\\n\\n",
      "Data Summary:\\n",
      "- Sample size: ", params[['n']], "\\n",
      "- Treatment group: ", params[['treatment_n']], "\\n",
      "- Control group: ", params[['control_n']], "\\n",
      "- True treatment effect: USD", params[['true_effect']], "\\n\\n",
      "Results:\\n",
      "1. Naive (unadjusted) estimate: USD", round(naive_effect, 2), "\\n",
      "   Bias: USD", round(bias_naive, 2), "\\n\\n",
      "2. Propensity Score Matching estimate: USD", round(matching_results[['ate_estimate']], 2), "\\n",
      "   95% CI: (USD", round(matching_results[['ate_ci_lower']], 2), ", USD", round(matching_results[['ate_ci_upper']], 2), ")\\n",
      "   Bias: USD", round(bias_matching, 2), "\\n",
      "   Coverage: ", ifelse(coverage_matching, "Yes", "No"), "\\n\\n",
      "Conclusion:\\n",
      "The propensity score matching approach provides a less biased estimate\\n",
      "of the treatment effect compared to the naive approach, demonstrating\\n",
      "the importance of adjusting for confounders in causal inference.\\n"
    )

    writeLines(report, "results/final_report.txt")

    cat("Final analysis completed!\\n")
    cat("Check the results/ directory for all outputs.\\n")
    cat("\\nSummary:\\n")
    cat(report)
    """
}

/*
 * WORKFLOW: Main workflow definition
 */
workflow {
    // Generate synthetic data
    GENERATE_DATA()
    
    // Perform exploratory analysis
    EXPLORATORY_ANALYSIS(
        GENERATE_DATA.out[0],  // training_data.csv
        GENERATE_DATA.out[1]   // parameters.rds
    )
    
    // Perform propensity score matching
    PROPENSITY_MATCHING(
        GENERATE_DATA.out[0],  // training_data.csv
        GENERATE_DATA.out[1]   // parameters.rds
    )
    
    // Generate final results
    FINAL_RESULTS(
        GENERATE_DATA.out[1],           // parameters.rds
        EXPLORATORY_ANALYSIS.out[2],   // naive_effect.rds
        PROPENSITY_MATCHING.out[3]     // matching_results.rds
    )
}

/*
 * WORKFLOW completion message
 */
workflow.onComplete {
    log.info """
    Workflow completed successfully!
    Results are available in: ${params.outdir}
    
    Key outputs:
    - Data visualizations (PNG files)
    - Statistical summaries (CSV files)
    - Final report (TXT file)
    """
}
