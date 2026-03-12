# ==============================================================================
# ANOVA tutorial script (PlantGrowth)
# Purpose: Demonstrate one-way ANOVA workflow: visualize, check distribution,
# fit aov, review diagnostics (base R), summary, means table with SE and 95% CI,
# ==============================================================================


# 1. Setup ------------------------------------------------------------------

# Load packages. Install them first if needed: install.packages(c("tidyverse","broom"))
library(tidyverse)  # includes ggplot2, dplyr, tibble
library(broom)      # tidy model outputs
library(car)
library(emmeans)

# 2. Load example data and quick inspection ---------------------------------
# PlantGrowth is a built-in dataset in R
data("PlantGrowth")         # loads object PlantGrowth
pg <- PlantGrowth           # copy to a working object

# Inspect
str(pg)                     # structure
head(pg)                    # first rows
table(pg$group)             # sample sizes by group
View(pg)

# Ensure grouping variable is a factor and set levels if desired
pg <- pg |> mutate(group = factor(group, levels = c("ctrl", "trt1", "trt2")))


# 3. Visualize raw data ----------------------------------------------------

# Using base R
plot(weight ~ group, data = pg)

# Using ggplot2
# Try jittered boxplot with points to show raw observations by group
p_raw <- ggplot(pg, aes(x = group, y = weight, color = group)) +
  geom_boxplot() +
  geom_point() +
#  geom_jitter(width = 0.12, size = 2) +
  labs(title = "Plant weight by treatment group",
       x = "Group", y = "Weight (g)") +
  theme_bw() +
  theme(legend.position = "none")

print(p_raw)


# 4. Check distribution of response -----------------------------------------
# Histogram + density
ggplot(pg, aes(x = weight)) +
  geom_histogram(bins = 12, fill = "lightblue", color = "grey40") +
  theme_bw()


# 5. Fit ANOVA model --------------------------------------------------------
# Using aov (one-way ANOVA)
model_aov <- aov(weight ~ group, data = pg)

# Alternative: lm gives equivalent coefficients for this design
model_lm <- lm(weight ~ group, data = pg)


# 6. Base R diagnostic plots (4-panel) --------------------------------------
# These are base R plots produced from the model object.
# To display: run the next line interactively.
par(mfrow = c(2, 2))      # 2x2 layout
plot(model_aov)           # 4 standard diagnostic plots
par(mfrow = c(1, 1))      # reset layout

# Shapiro-Wilk test on residuals
# Use this for  other evidence, rather than yes/no
shapiro.test(residuals(model_aov))
leveneTest(weight ~ group, data = pg, center = median)

# There are other ways to more fully evaluate and test for violation of assumption and these are not shown here. 


# 7. Review model output ----------------------------------------------------
# Classic summary for aov
summary(model_aov)

# Tidy outputs with broom (good for scripts/reports)
broom::tidy(model_aov)
broom::glance(model_aov)


# 8. Summary table of group means with SE and 95% CI (original scale) -------
means_tbl <- pg |>
  group_by(group) |>
  summarise(
    n = n(),
    mean = mean(weight),
    sd = sd(weight),
    se = sd / sqrt(n),
    tcrit = qt(0.975, df = n - 1),
    ci_lower = mean - tcrit * se,
    ci_upper = mean + tcrit * se,
    .groups = "drop"
  )
means_tbl

# The above works fine in this case. For more complicated models, best to use a helper package called emmeans. 
emm <- emmeans(model_aov, specs = "group")
summary(emm)

# A dataframe that is nice for export.
tidy(summary(emm))


# 9. Post-hoc comparisons (Tukey HSD) ---------------------------------------

# Version 1: 
TukeyHSD(model_aov)

# Tidy Tukey output (simple conversion)
# Convert to a tibble for nicer printing and export
tukey_tbl <- as.data.frame(tukey$group) |>
  rownames_to_column("comparison") |>
  as_tibble()
tukey_tbl

emmeans::contrast(emm, method = "pairwise")


# 11. Presentation-ready plot of means with 95% CI (original scale) ---------
# Use the means_tbl computed above
ggplot(means_tbl, aes(x = group, y = mean)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.12) +
  labs(title = "Group means of plant weight with 95% CI",
       x = "Group", y = "Mean weight (g)",
       caption = "Error bars are 95% t-based confidence intervals") +
  theme_bw()


# ggsave("plant_means.png", p_means, width = 6, height = 4, dpi = 300)


# OPTION A. Robust Confidence Intervals -------------------------------------

# Use robust confidence intervals when assumption violations (non-normal residuals, heteroscedasticity, or influential outliers) are large enough that ordinary t-based CIs are likely to be misleading for your sample size and inference goals. There is no single hard cutoff. Instead use a practical decision rule based on: type and degree of violation, sample size, and whether results are sensitive to influential observations. 

library(sandwich)

# Using our model above, here are the means:
orig <- emmeans(model_aov, ~ group)
orig

# Site comparisons
contrast(orig, method = "pairwise")

# Now try robust standard errors
# Make the new robust covariance matrix
robust_vcov = sandwich::vcovHC(model_aov, type = "HC3")

# Here are the new means:
robust <- emmeans(model_aov, ~ group, 
        vcov. = robust_vcov)

# And finally the revised site contrasts
contrast(robust, method = "pairwise")

