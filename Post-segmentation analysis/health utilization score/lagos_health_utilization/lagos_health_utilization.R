rm(list=ls())
library(haven)
library(ggplot2)
library(gridExtra)
library(reshape)
library(survival)
library(magrittr)
library(dplyr)
library(tidyr)
library(data.table)
library(survey)
library(plyr)
library(tm)
library(labelled)
library(stringr)
library(forcats)
require(doParallel)
library(foreign)
library(psych)
library(vtable)
library(corrplot)
library(haven)
library(survey)

############## Load Nigeria 2013 DHS data
NGHH <- data.table(read.dta("data/NGHR6ADT/NGHR6AFL.DTA"))
NGIR <- data.table(read.dta("data/NGIR6ADT/NGIR6AFL.DTA"))

############## read Pathways Rdat file
path <- load("clean_data_files/DHS Pathways interim segments & factors.RDat")

dhs.seg <- data.table(dhs.seg)
unique(dhs.seg$cv.regX5)

# Select out only the Nigeria segments
ng.seg <- dhs.seg[cv.regX5 %in% c("Nigeria.South"),]

# We need to re-create a caseid that can be linked to the DHS file, this requires parsing out cluster,
# HHID and Lineno separately, the putting them together with a specific number of characters
ng.seg$ID<-as.character(ng.seg$IDHSPID)
#str_length(ng.seg$IDHSPID) #23
ng.seg$cluster<-str_sub(ng.seg$ID,10,17)
ng.seg$hhid<-str_sub(ng.seg$ID,18,20)
ng.seg$hhid<-str_pad(ng.seg$hhid,3)
ng.seg$lineno<-str_sub(ng.seg$ID,21,23)
ng.seg$lineno<-str_pad(ng.seg$lineno,2)
ng.seg$caseid<-paste(ng.seg$cluster,ng.seg$hhid,ng.seg$lineno, sep = "")
ng.seg$caseid<-str_trim(ng.seg$caseid,"left")

ng.seg<- ng.seg %>% dplyr::select(caseid,segX4)

################################################### Define zero dose child
NGBR <- data.table(read.dta("data/NGBR6ADT/NGBR6AFL.DTA"))

table(NGBR$h3,useNA="always")
table(NGBR$h5,useNA="always")
table(NGBR$h7,useNA="always")

NGBR[!(is.na(h3)),dpt1:=ifelse(h3 %in% c(1,2,3),1,0)]  # lacked or received the first dose of dpt
NGBR[!(is.na(h5)),dpt2:=ifelse(h5 %in% c(1,2,3),1,0)]  # lacked or received the second dose of dpt
NGBR[!(is.na(h7)),dpt3:=ifelse(h7 %in% c(1,2,3),1,0)]  # lacked or received the third dose of dpt

###################################################
####### for this analysis, similar to Roy's analysis, I defined zero dose as dpt0 means no dose of dpt for the 10-23 motnhs old children
###################################################

NGBR[,dpt0:= ifelse((dpt1+dpt2+dpt3)==0, 1, 0)] #no dose of dpt
table(NGBR$dpt0,useNA="always")
table(NGBR$v008,useNA="always")
table(NGBR$b3,useNA="always")

NGBR[,ChildAge:= (v008-b3)] # in months
table(NGBR$b5,useNA="always")
NGBR <- NGBR[b5=="Yes",] #child is alive

NGBR$Agegrp <- ifelse(NGBR$ChildAge < 12, "<12",ifelse(NGBR$ChildAge >=12 & NGBR$ChildAge <=23, "12-23",ifelse(NGBR$ChildAge>23 &NGBR$ChildAge<=35,"24-35",
ifelse(NGBR$ChildAge>35 &NGBR$ChildAge<=59,"36-59","60+"))))

NGBR$Agegrp <- factor(NGBR$Agegrp, levels = c("<12","12-23", "24-35","36-59","60+"))

NGBR[,table(dpt0,Agegrp,useNA="always")]

NGBR$dpt0 <- ifelse(NGBR$ChildAge>9 & NGBR$ChildAge <24,NGBR$dpt0,NA)

###################################################
# Now we can link back to any of the Nigeria DHS files
Merg <- ng.seg %>% left_join(NGBR)

## ## ## ##
## ## ## ## Seek care for diarrhea and fever
## ## ## ##
table(NGBR$h12z,useNA="always")
table(NGBR$h32z ,useNA="always")

## diarrhea: medical treatment 0:No, 1:Yes
NGBR$diarr <- NGBR$h12z
## fever: medical treatment 0:No, 1:Yes
NGBR$fever <- NGBR$h32z

NGBR$diarr <- ifelse(NGBR$diarr== 9,NA,NGBR$diarr)
NGBR$fever <- ifelse(NGBR$fever== 9,NA,NGBR$fever)
table(NGBR$diarr,useNA="always")
table(NGBR$fever,useNA="always")

diar.fev <- NGBR[,list(diarr=max(diarr,na.rm=TRUE),fever=max(fever,na.rm=TRUE)),by=c("caseid")]
diar.fev$diarr <-  ifelse(diar.fev$diarr==-Inf,NA,diar.fev$diarr)
diar.fev$fever <-  ifelse(diar.fev$fever==-Inf,NA,diar.fev$fever)

table(diar.fev$fever ,useNA="always")
table(diar.fev$diarr ,useNA="always")

###################################################
# Now we can link back to any of the Nigeria DHS files
Merg <- Merg %>% left_join(diar.fev)

# Finally we need to apply the new coding for the segments
# The segment renaming come from a slide sent by Melanie specifically for the Nigeria DHS data
old<-c("RF1","RF2","RF3","RF4","RM1","RM2","RM3","UF1","UF2","UF3","UM1","UM2","UM3","UM4","UM5") # What's in the file
new<-c("RF4.2","RF3","RF4.1","RF1","RM2.1","RM4","RM2.2","UF3.1","UF3.2","UF1","UM4","UM2","UM1.1","UM3","UM1.2") # New segments
comb<-c("RF4","RF3","RF4","RF1","RM2","RM4","RM3","UF3","UF3","UF1","UM4","UM2","UM1","UM3","UM1") # Combining to be more like Pathways
new.seg<-data.frame("segX4"=old, "new.seg"=new, "comb.seg"=comb)

Merg<-Merg%>%left_join(new.seg)

# Just use the segments that also appear in the Pathways data
Merg <- Merg %>% filter(new.seg %in% c("UM1.1","UM1.2","UF1","UM3","UF3.1","UM4"))

nigeria <- Merg
#nigeria$segm1 <- nigeria$comb.seg
nigeria$segm1 <- nigeria$new.seg

table(nigeria$segm1,nigeria$dpt0,useNA="always")
table(nigeria$v024,useNA="always")


#nigeria$region <- ifelse(nigeria$v024 %in% c("North Central","North East","North West"),"north","south")
nigeria$wt<-nigeria$v005/1000000


## ## ## ## ## ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## ##
## ## ## ## ## ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## ##
## ## ## ## SCORING
## ## ## ## ## ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## ##
## ## ## ## ## ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## ##

### anc
table(nigeria$m14,useNA="always")
nigeria$anyanc <- ifelse(nigeria$m14==99,NA,ifelse(nigeria$m14==0,0,1))
table(nigeria$anyanc,useNA="always")

nigeria$anc.num2 <- ifelse(nigeria$m14 == 98,3,nigeria$m14) # Impute DNK to the mean of 3
nigeria$anc.num2 <- ifelse(nigeria$anc.num2== 99,NA,nigeria$anc.num2)
table(nigeria$anc.num2,useNA="always")

nigeria$anc.4plus2 <-ifelse(nigeria$anc.num>=4,1,0)
table(nigeria$anc.4plus2,useNA="always")

##### PNC
table(nigeria$m70,useNA="always")
nigeria[!(is.na(m70)),B.PNC := ifelse(m70==1,1,0)]
nigeria$B.PNC <- ifelse(nigeria$m70== 9,NA,nigeria$B.PNC)
table(nigeria$B.PNC,useNA="always")

# Recode FP
table(nigeria$v361 ,useNA="always")
nigeria$fp.ever <- ifelse(nigeria$v361 == "Never used",0,1)

# Recode used health services
table(nigeria$v393 ,useNA="always")
table(nigeria$v394 ,useNA="always")
nigeria$hc.chw <- ifelse(nigeria$v393 == 1,1,0)
nigeria$hc.chw <- ifelse(nigeria$v393 == 9,NA,nigeria$hc.chw)

nigeria$hc.hfac <- ifelse(nigeria$v394 == 1,1,0)
nigeria$hc.hfac <- ifelse(nigeria$v394 == 9,NA,nigeria$hc.hfac)
table(nigeria$hc.hfac,useNA="always")

# Recode home births
table(NGIR$m15_1,useNA="always")
NGIR[,hb_1:= ifelse(m15_1== 10 | m15_1== 11 | m15_1== 12 | m15_1== 96,1,0)]
NGIR[,hb_2:= ifelse(m15_2== 10 | m15_2== 11 | m15_2== 12 | m15_2== 96,1,0)]
NGIR[,hb_3:= ifelse(m15_3== 10 | m15_3== 11 | m15_3== 12 | m15_3== 96,1,0)]
NGIR[,hb_4:= ifelse(m15_4== 10 | m15_4== 11 | m15_4== 12 | m15_4== 96,1,0)]
NGIR[,hb_5:= ifelse(m15_5== 10 | m15_5== 11 | m15_5== 12 | m15_5== 96,1,0)]

NGIR$hb_1 <- ifelse(NGIR$m15_1 == 99,NA,NGIR$hb_1)
NGIR$hb_2 <- ifelse(NGIR$m15_2 == 99,NA,NGIR$hb_2)
NGIR$hb_3 <- ifelse(NGIR$m15_3 == 99,NA,NGIR$hb_3)
NGIR$hb_4 <- ifelse(NGIR$m15_4 == 99,NA,NGIR$hb_4)
NGIR$hb_5 <- ifelse(NGIR$m15_5 == 99,NA,NGIR$hb_5)

NGIR$hb_ever[(NGIR$hb_1==1 | NGIR$hb_2==1 | NGIR$hb_3==1 | NGIR$hb_4==1 | NGIR$hb_5==1)]<- 1
NGIR$hb_ever[((NGIR$hb_1==0 | is.na(NGIR$hb_1)) & (NGIR$hb_2==0 | is.na(NGIR$hb_2)) & (NGIR$hb_3==0 | is.na(NGIR$hb_3)) &
                (NGIR$hb_4==0 | is.na(NGIR$hb_4)) & (NGIR$hb_5==0 | is.na(NGIR$hb_5)))]<-0
NGIR$hb_ever <- ifelse((is.na(NGIR$hb_1))&(is.na(NGIR$hb_2))&(is.na(NGIR$hb_3))&(is.na(NGIR$hb_4))&(is.na(NGIR$hb_5)),NA,NGIR$hb_ever)

NGIR[,table(hb_ever, useNA="always")]
NGIR[,table(hb_1, useNA="always")]

NGIR$caseid<-str_trim(NGIR$caseid,"left")

nigeria <- merge(nigeria, NGIR[,c("caseid","hb_ever")], by=c("caseid"))

## ## ## ## ## ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## #### ## ## ##
table(nigeria$anyanc,useNA="always")
table(nigeria$hc.hfac,useNA="always")
table(nigeria$B.PNC,useNA="always")
table(nigeria$fp.ever,useNA="always")
table(nigeria$hb_ever,useNA="always")
table(nigeria$fever,useNA="always")
table(nigeria$diarr,useNA="always")

### woman & child health service utilization
nigeria[,HC.score4:= (anyanc+hc.hfac+B.PNC+fp.ever+diarr+fever)]
nigeria[hb_ever==0,HC.score4:= HC.score4 + 1]
nigeria[is.na(hb_ever),HC.score4:= NA]

table(nigeria$HC.score4,useNA="always")
table(nigeria[is.na(hb_ever),]$HC.score4,useNA="always")

######
nigeria2 <- nigeria[!duplicated(nigeria$caseid), ]
table(nigeria2$segm1,useNA="always")

table(nigeria2$segm1,nigeria2$anyanc,useNA="always")
table(nigeria2$segm1,nigeria2$hc.hfac,useNA="always")
table(nigeria2$segm1,nigeria2$B.PNC,useNA="always")
table(nigeria2$segm1,nigeria2$fp.ever,useNA="always")
table(nigeria2$segm1,nigeria2$diarr,useNA="always")
table(nigeria2$segm1,nigeria2$fever,useNA="always")
table(nigeria2$segm1,nigeria2$hb_ever,useNA="always")

nigeria2$anyanc <- ifelse(is.na(nigeria2$anyanc),"NA",nigeria2$anyanc)
nigeria2$hc.hfac <- ifelse(is.na(nigeria2$hc.hfac),"NA",nigeria2$hc.hfac)
nigeria2$B.PNC <- ifelse(is.na(nigeria2$B.PNC),"NA",nigeria2$B.PNC)
nigeria2$fp.ever <- ifelse(is.na(nigeria2$fp.ever),"NA",nigeria2$fp.ever)
nigeria2$diarr <- ifelse(is.na(nigeria2$diarr),"NA",nigeria2$diarr)
nigeria2$fever <- ifelse(is.na(nigeria2$fever),"NA",nigeria2$fever)
nigeria2$hb_ever <- ifelse(is.na(nigeria2$hb_ever),"NA",nigeria2$hb_ever)

table(nigeria2$hb_ever,useNA="always")
nigeria2$hf_deliv <- ifelse(nigeria2$hb_ever==0,1,ifelse(nigeria2$hb_ever==1,0,NA))
nigeria2$hf_deliv <- ifelse(is.na(nigeria2$hf_deliv),"NA",nigeria2$hf_deliv)
table(nigeria2$hf_deliv,useNA="always")


nigeria2 <- nigeria2 %>% filter(!is.na(v021))

Pathdesign<-svydesign(id=nigeria2$v021, strata= nigeria2$v023, weights=nigeria2$wt, survey.lonely.psu="adjust", nest=T, data=nigeria2)

# get totals that are represented by segment
Pathdesign<-svydesign(id=nigeria2$v021, weights=nigeria2$wt, survey.lonely.psu="adjust", nest=T, data=nigeria2)
totals <- svytotal(~segm1, design = Pathdesign)



tot <- melt(svytable(~segm1, Pathdesign))

tot <-data.table(tot)
setkey(tot,value)

# Function to compute subtracted value.y for each segment group

######## anc
seg <- melt(svytable(~segm1+anyanc, Pathdesign))
anc <- merge(seg,tot,by="segm1")

subtract_value_y <- function(data) {
  if (any(is.na(data$anyanc))) {
    na_row_value_x <- data$value.x[which(is.na(data$anyanc))]
    data$value.y <- data$value.y - na_row_value_x
  }
  return(data)
}

anc <- anc %>%
  group_by(segm1) %>%
  do(subtract_value_y(.)) %>%
  ungroup()

anc$perct <- 100*anc$value.x/anc$value.y
anc$health.service <- "anc"
names(anc)[2] <-"health.service.status"

######## visit health facility
seg <- melt(svytable(~segm1+hc.hfac, Pathdesign))
hc.hfac <- merge(seg,tot,by="segm1")

subtract_value_y <- function(data) {
  if (any(is.na(data$hc.hfac))) {
    na_row_value_x <- data$value.x[which(is.na(data$hc.hfac))]
    data$value.y <- data$value.y - na_row_value_x
  }
  return(data)
}

hc.hfac <- hc.hfac %>%
  group_by(segm1) %>%
  do(subtract_value_y(.)) %>%
  ungroup()

hc.hfac$perct <- 100*hc.hfac$value.x/hc.hfac$value.y
hc.hfac$health.service <- "hc.hfac"
names(hc.hfac)[2] <-"health.service.status"

######## B.PNC
seg <- melt(svytable(~segm1+B.PNC, Pathdesign))
B.PNC <- merge(seg,tot,by="segm1")

subtract_value_y <- function(data) {
  if (any(is.na(data$B.PNC))) {
    na_row_value_x <- data$value.x[which(is.na(data$B.PNC))]
    data$value.y <- data$value.y - na_row_value_x
  }
  return(data)
}

B.PNC <- B.PNC %>%
  group_by(segm1) %>%
  do(subtract_value_y(.)) %>%
  ungroup()


B.PNC$perct <- 100*B.PNC$value.x/B.PNC$value.y
B.PNC$health.service <- "B.PNC"
names(B.PNC)[2] <-"health.service.status"

######## ever used FP
seg <- melt(svytable(~segm1+fp.ever, Pathdesign))
fp.ever <- merge(seg,tot,by="segm1")

fp.ever$perct <- 100*fp.ever$value.x/fp.ever$value.y
fp.ever$health.service <- "fp.ever"
names(fp.ever)[2] <-"health.service.status"

######## diarrhea
seg <- melt(svytable(~segm1+diarr, Pathdesign))
diarr <- merge(seg,tot,by="segm1")

subtract_value_y <- function(data) {
  if (any(is.na(data$diarr))) {
    na_row_value_x <- data$value.x[which(is.na(data$diarr))]
    data$value.y <- data$value.y - na_row_value_x
  }
  return(data)
}

diarr <- diarr %>%
  group_by(segm1) %>%
  do(subtract_value_y(.)) %>%
  ungroup()

diarr$perct <- 100*diarr$value.x/diarr$value.y
diarr$health.service <- "diarr"
names(diarr)[2] <-"health.service.status"

######## fever
seg <- melt(svytable(~segm1+fever, Pathdesign))
fever <- merge(seg,tot,by="segm1")

subtract_value_y <- function(data) {
  if (any(is.na(data$fever))) {
    na_row_value_x <- data$value.x[which(is.na(data$fever))]
    data$value.y <- data$value.y - na_row_value_x
  }
  return(data)
}

fever <- fever %>%
  group_by(segm1) %>%
  do(subtract_value_y(.)) %>%
  ungroup()

fever$perct <- 100*fever$value.x/fever$value.y
fever$health.service <- "fever"
names(fever)[2] <-"health.service.status"

######## facility delivery
seg <- melt(svytable(~segm1+hf_deliv, Pathdesign))
hf_deliv <- merge(seg,tot,by="segm1")

subtract_value_y <- function(data) {
  if (any(is.na(data$hf_deliv))) {
    na_row_value_x <- data$value.x[which(is.na(data$hf_deliv))]
    data$value.y <- data$value.y - na_row_value_x
  }
  return(data)
}

hf_deliv <- hf_deliv %>%
  group_by(segm1) %>%
  do(subtract_value_y(.)) %>%
  ungroup()

hf_deliv$perct <- 100*hf_deliv$value.x/hf_deliv$value.y
hf_deliv$health.service <- "hf_deliv"
names(hf_deliv)[2] <-"health.service.status"

health.service.lagos <- rbind(anc,hc.hfac,B.PNC,fp.ever,diarr,fever,hf_deliv)
names(health.service.lagos)[5] <- "percentage"
names(health.service.lagos)[4] <- "total_in_segment"
names(health.service.lagos)[3] <- "number"

health.service.lagos <- health.service.lagos %>% filter(!is.na(health.service.status))
health.service.lagos$segm1 <- as.character(health.service.lagos$segm1)
health.service.lagos$health.service.status <- as.character(health.service.lagos$health.service.status)

health.service.lagos <- as.data.frame(health.service.lagos)

# create averages for utilizaton

health.service.lagos.ave <- health.service.lagos %>%
  dplyr::group_by(segm1, health.service.status) %>%
  dplyr::summarise(average.utilization = mean(percentage)) %>%
  filter(health.service.status == 1)

write.csv(health.service.lagos,"heath_utilization_by_service_lagos.csv")
write.csv(health.service.lagos.ave,"heath_utilization_average_lagos.csv")


#

