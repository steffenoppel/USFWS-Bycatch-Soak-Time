#Setting up main datasets
main.data <- read.csv("data/Main_herring_2024_Catch_Bycatch.csv")
morpho.data<- read.csv("Bycatch_2024_Herring_Sampling.csv")
########################################################################################################
#Subset
sum.data<-subset(main.data, main.data$Net_group=="Sum")#sum of both nets

morpho.data<-subset(morpho.data, morpho.data$Sample_herring_FK_cm!="")#removes NAs
########################################################################################################
#Herring catch vs soak duration/time
sum.data$Total_target_catch_kg<-as.numeric(sum.data$Total_target_catch_kg)
sum.data$Total_target_catch_number<-as.numeric(sum.data$Total_target_catch_number)
sum.data$NOGA_presence<-as.numeric(sum.data$NOGA_presence)

#Descriptive stats
sum.data %>%
  group_by(Net_treatment) %>%
  get_summary_stats(Total_target_catch_number, type = "mean_sd")
 
tapply(sum.data$Total_target_catch_number, sum.data$Net_treatment, summary)

aggregate(sum.data$Total_target_catch_number, list(sum.data$Net_treatment), FUN=mean)
aggregate(sum.data$Total_target_catch_number, list(sum.data$Net_treatment), FUN=sd)

#Anova catch vs soak treatment
#Check assumptions ANOVA for Catch #
ggboxplot(sum.data, x = "Net_treatment", y = "Total_target_catch_number")#ok
m1<- lm(Total_target_catch_number~Net_treatment, data = sum.data)#parametric model
Anova(m1)#p=0.0123
emmeans(m1, list(pairwise ~ Net_treatment), adjust="fdr")#pairwise comparisons
ggqqplot(residuals(m1))#slight deviation from normal
plot(m1, 2)#slight deviations from normal
shapiro_test(residuals(m1))#p=0.0627 - acceptable
plot(m1, 3)#homogeneity of variance met
sum.data %>% levene_test(Total_target_catch_number~Net_treatment)#homogeneity of variance ok p=0.0940

#Check assumptions ANOVA for Catch #
ggboxplot(sum.data, x = "Net_treatment", y = "Total_target_catch_kg")#ok
m1<- lm(Total_target_catch_kg~Net_treatment, data = sum.data)#parametric model
Anova(m1)#p=0.008852
emmeans(m1, list(pairwise ~ Net_treatment), adjust="fdr")#pairwise comparisons
ggqqplot(residuals(m1))#slight deviation from normal
plot(m1, 2)#slight deviations from normal
shapiro_test(residuals(m1))#p=0.107 - acceptable
plot(m1, 3)#homogeneity of variance met
sum.data %>% levene_test(Total_target_catch_kg~Net_treatment)#homogeneity of variance ok p=0.0666
#ANOVA ok in both cases

#Linear figure
(catch1<-(sum.data %>%
         ggplot(aes(Date_pulling,Total_target_catch_number)) +
         geom_point(aes(group=Net_treatment, colour=Net_treatment)) +
         geom_line(aes(group = Net_treatment,color=Net_treatment), linetype = "dashed") +
         scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
         ylab("Count target catch") +
         xlab("Dates hauling")+
         theme_bw()+theme(text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(catch2<-(sum.data %>%
            ggplot(aes(Date_pulling,Total_target_catch_kg)) +
            geom_point(aes(group=Net_treatment, colour=Net_treatment)) +
            geom_line(aes(group = Net_treatment,color=Net_treatment), linetype = "dashed") +
            scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
            ylab("Target catch (kg)") +
            xlab("Dates hauling")+
            theme_bw()+theme(legend.position = "right",text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(catch1|catch2)  +
  plot_layout(guides = "collect") & theme(legend.position = 'top')

#Boxplot figures
stat.test <- sum.data %>% t_test(Total_target_catch_number ~ Net_treatment)%>%adjust_pvalue(method="BH") 
stat.test <- stat.test %>% add_xy_position(x = "Net_treatment")
(aov1<-(ggboxplot(sum.data, x = "Net_treatment", y = "Total_target_catch_number",color = "Net_treatment",shape=1,ylab = "Count target catch", xlab = "Soak treatment",add = "jitter")+
  scale_x_discrete(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"))+
  scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
  theme(legend.position = "right")+
  stat_pvalue_manual(stat.test,label = "p.adj")+
  stat_compare_means(method = "anova", label.y = 2200)))

stat.test <- sum.data %>% t_test(Total_target_catch_kg~ Net_treatment)%>%adjust_pvalue(method="BH") 
stat.test <- stat.test %>% add_xy_position(x = "Net_treatment")
(aov2<-(ggboxplot(sum.data, x = "Net_treatment", y = "Total_target_catch_kg",color = "Net_treatment",shape=1,ylab = "Target catch (kg)", xlab = "Soak treatment",add = "jitter")+
  scale_x_discrete(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"))+
  scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
  theme(legend.position = "right")+
  stat_pvalue_manual(stat.test,label = "p.adj")+
  stat_compare_means(method = "anova", label.y = 370)))

(aov1|aov2)  +
  plot_layout(guides = "collect") & theme(legend.position = 'right')

#################
#Number of NOGAs present vs catch
(noga1<-(sum.data %>%
            ggplot(aes(Total_target_catch_number,NOGA_presence)) +
            geom_point(aes(group=Net_treatment, colour=Net_treatment),alpha=10,size=3.5,shape=1) +
            geom_smooth(method = "glm.nb",color="black",alpha=0.5) +
            scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
            ylab("Count NOGA present at hauling") +
            xlab("Count target catch")+
            theme_bw()+theme(text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(noga2<-(sum.data %>%
            ggplot(aes(Total_target_catch_kg,NOGA_presence)) +
            geom_point(aes(group=Net_treatment, colour=Net_treatment),alpha=10,size=3.5,shape=1) +
            geom_smooth(method = "glm.nb",se=T,color="black",alpha=0.5) +
            scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
            ylab("Count NOGA present at hauling") +
            xlab("Target catch (kg)")+
            theme_bw()+theme(axis.title.y=element_blank(),text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(noga1|noga2)  +
  plot_layout(guides = "collect") & theme(legend.position = 'top')

#Total number of birds at haul vs catch
sum.data$Total_birds <- as.numeric(apply(sum.data[,21:36], 1, sum))

(bird1<-(sum.data %>%
           ggplot(aes(Total_target_catch_number,Total_birds)) +
           geom_point(aes(group=Net_treatment, colour=Net_treatment),alpha=10,size=3.5,shape=1) +
           geom_smooth(method = "glm.nb",color="black",alpha=0.5) +
           scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
           ylab("Count birds present at hauling") +
           xlab("Count target catch")+
           theme_bw()+theme(text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(bird2<-(sum.data %>%
           ggplot(aes(Total_target_catch_kg,Total_birds)) +
           geom_point(aes(group=Net_treatment, colour=Net_treatment),alpha=10,size=3.5,shape=1) +
           geom_smooth(method = "glm.nb",se=T,color="black",alpha=0.5) +
           scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
           ylab("Count birds present at hauling") +
           xlab("Target catch (kg)")+
           theme_bw()+theme(axis.title.y=element_blank(),text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(bird1|bird2)  +
  plot_layout(guides = "collect") & theme(legend.position = 'top')

####Fish FK and weight vs date hauling
morpho.data <- morpho.data %>% dplyr::mutate(Date_pulling = as.Date(anytime::anydate(Date_pulling)))#decrepated?

df <- transmute(morpho.data, Location = Net_treatment, Date = as.Date(as.character(cut(Date_pulling,breaks = 10))), Weight = Sample_herring_FK_cm)#Make dates readable in any format
(fk1<-(ggplot(data = df,mapping = aes(x = Date, y = Weight)) +
  stat_summary(fun = "mean",color="blue") + 
  geom_smooth(method="lm",se=T)+
  geom_jitter(aes(colour = Location),shape=1,size=3.5)+
  ylab("Fork length (cm)") +
  xlab("Dates hauling")+
  scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
  theme_bw()+theme(text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

df <- transmute(morpho.data, Location = Net_treatment, Date = as.Date(as.character(cut(Date_pulling,breaks = 10))), Weight = Sample_herring_wt_g)#Make dates readable in any format
(mass1<-(ggplot(data = df,mapping = aes(x = Date, y = Weight)) +
         stat_summary(fun = "mean",color="blue") + 
         geom_smooth(method="lm",se=T)+
         geom_jitter(aes(colour = Location),shape=1,size=3.5)+
         ylab("Mass (g)") +
         xlab("Dates hauling")+
         scale_color_manual(labels = c("12_night"="12hr night","24hr"="24hr","12_day"="12hr day"),values = c("12_night"="red","24hr"="black","12_day"="grey"),name="Soak treatment")+
         theme_bw()+theme(text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(fk1|mass1)  +
  plot_layout(guides = "collect") & theme(legend.position = 'top')
#############
#Fish FK and wt vs dates as a function of year (2018-2024)

df <- transmute(morpho.data, Location = Year, Date = as.Date(as.character(cut(Date_pulling,breaks = 17))), Weight = Sample_herring_FK_cm)#Make dates readable in any format
(fk1<-(ggplot(data = df,mapping = aes(x = Date_pulling, y = Weight,colour = Location)) +
         geom_jitter(aes(colour = Location),shape=1,size=3.5)+
         stat_summary(fun = "mean",color="blue") + 
         geom_smooth(method="lm",se=T)+
         ylab("Fork length (cm)") +
         xlab("Dates hauling")+
         theme_bw()+theme(text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

morpho.data$Year<-as.factor(morpho.data$Year)
(fk1<-(ggplot(data = morpho.data,mapping = aes(x = Date_pulling, y = Sample_herring_FK_cm,colour = Year)) +
         geom_jitter(aes(colour =Year),shape=1,size=3.5)+
         stat_summary(fun = "mean",color="blue") +
         stat_smooth(method="lm",se=T,color="blue")+
         ylab("Fork length (cm)") +
         xlab("Dates hauling")+
         theme_bw()+theme(text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(mass1<-(ggplot(data = morpho.data,mapping = aes(x = Date_pulling, y = Sample_herring_wt_g,colour = Year)) +
         geom_jitter(aes(colour =Year),shape=1,size=3.5)+
         stat_summary(fun = "mean",color="blue") +
         stat_smooth(method="lm",se=T,color="blue")+
         ylab("Mass (g)") +
         xlab("Dates hauling")+
         theme_bw()+theme(text = element_text(size=11),axis.line = element_line(colour = "black"),panel.grid.major = element_blank(),panel.grid.minor = element_blank(),panel.border = element_blank(),panel.background = element_blank())))

(fk1/mass1)  +
  plot_layout(guides = "collect") & theme(legend.position = 'right')

stat.test <- morpho.data %>% t_test(Sample_herring_FK_cm~ Year)%>%adjust_pvalue(method="BH") 
stat.test <- stat.test %>% add_xy_position(x = "Year")
(aov2<-(ggboxplot(morpho.data, x = "Year", y = "Sample_herring_FK_cm",color = "Year",shape=1,ylab = "Fork length (cm)", xlab = "Year",add = "jitter")+
          theme(legend.position = "right")+
          stat_pvalue_manual(stat.test)+
          stat_compare_means(method = "t-test")))

stat.test <- morpho.data %>% t_test(Sample_herring_wt_g~ Year)%>%adjust_pvalue(method="BH") 
stat.test <- stat.test %>% add_xy_position(x = "Year")
(aov2<-(ggboxplot(morpho.data, x = "Year", y = "Sample_herring_wt_g",color = "Year",shape=1,ylab = "Mass (g)", xlab = "Year",add = "jitter")+
          theme(legend.position = "right")+
          stat_pvalue_manual(stat.test)+
          stat_compare_means(method = "t-test")))

(aov1|aov2)  +
  plot_layout(guides = "collect") & theme(legend.position = 'right')

