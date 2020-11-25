library(ggplot2)
theme_set(theme_bw())
theme_update(plot.title = element_text(hjust = 0.5))


Mosquito.qPCR.Summary <- read.delim("C:/Users/MatthewCannon/Desktop/031519 Mosquito Timed Extractions qPCR Summary.txt")

allqPCRDf <- read.delim("Z:/cannonm3/stoolNem/combinedBrandyHB/qPCR/qPCR_4wk_results.txt", header = T)
allqPCRDf <- subset(allqPCRDf, replicate != "H2O")
allqPCRDf$Primer <- gsub("rus_2", "rus", allqPCRDf$Primer)
allqPCRDf$Primer <- gsub("Culic", "Mosquito", allqPCRDf$Primer)

allqPCRDf$Preservation <- factor(allqPCRDf$Preservation, levels = c("None", "Ethanol", "RNAlater"))

png(filename = "Z:/cannonm3/stoolNem/combinedBrandyHB/qPCR/flaviCtPlots.png", width = 2000, height = 2000, res = 300)
ggplot(allqPCRDf, aes(x = Weeks, y = Cq, colour = Primer)) + 
  geom_jitter(width = 0.1, size = 3, shape = 4) + 
  facet_wrap(~ Preservation, ncol = 1) + 
  scale_x_continuous(breaks = c(0,2,4), minor_breaks = c(0,2,4)) +
  ggtitle("Preservation method") +
  ylab("Ct")
dev.off()

# edited the figure to replace the number 40 with "ND" because any sample without a Ct (did not amplify) was set to 40 for this purpose



