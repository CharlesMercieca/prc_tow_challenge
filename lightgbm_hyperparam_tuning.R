library(tidyverse)
library(tidymodels)
library(bonsai)
library(stacks)
library(bundle)

set.seed(122333)

data_cleaned <- read_csv('data/data_cleaned.csv')

#train/test split
set.seed(20241010)
split <- initial_split(data_cleaned)
train <- training(split)
test <- testing(split)

#let's try some parallel
doParallel::registerDoParallel(cores = 6)

#specify model and grid
lgb_spec <- boost_tree(
  mtry = tune(), 
  trees = 2400, 
  tree_depth = tune(), 
  learn_rate = tune(), 
  min_n = tune(), 
  loss_reduction = tune()) %>%
  set_engine("lightgbm",
             num_leaves = tune()) %>%
  set_mode("regression") %>%
  translate()


lgbm_ctrl <- control_grid(verbose = TRUE,
                          save_pred = TRUE,
                          save_workflow = TRUE)

lgbm_wf<- workflow() %>%
  add_recipe(recipe(tow ~ country_code_adep+country_code_ades+aircraft_type+wtc+airline+flight_duration+taxiout_time+flown_distance
                    +altitude_p1+altitude_p2+altitude_p3+altitude_p4+altitude_p5+altitude_p6+altitude_p7+altitude_p8+altitude_p9+altitude_p10+altitude_p11+altitude_p12+altitude_p13+altitude_p14+altitude_p15+altitude_p16+altitude_p17+altitude_p18+altitude_p19+altitude_p20+altitude_p21+altitude_p22+altitude_p23+altitude_p24+altitude_p25+altitude_p26+altitude_p27+altitude_p28+altitude_p29+altitude_p30+altitude_p31
                    
                    +speed_p1+speed_p2+speed_p3+speed_p4+speed_p5+speed_p6+speed_p7+speed_p8+speed_p9+speed_p10+speed_p11+speed_p12+speed_p13+speed_p14+speed_p15+speed_p16+speed_p17+speed_p18+speed_p19+speed_p20+speed_p21+speed_p22+speed_p23+speed_p24+speed_p25+speed_p26+speed_p27+speed_p28+speed_p29+speed_p30+speed_p31
                    
                    +specific_energy_p1+specific_energy_p2+specific_energy_p3+specific_energy_p4+specific_energy_p5+specific_energy_p6+specific_energy_p7+specific_energy_p8+specific_energy_p9+specific_energy_p10+specific_energy_p11+specific_energy_p12+specific_energy_p13+specific_energy_p14+specific_energy_p15+specific_energy_p16+specific_energy_p17+specific_energy_p18+specific_energy_p19+specific_energy_p20+specific_energy_p21+specific_energy_p22+specific_energy_p23+specific_energy_p24+specific_energy_p25+specific_energy_p26+specific_energy_p27+specific_energy_p28+specific_energy_p29+specific_energy_p30+specific_energy_p31
                    
                    +median_vs_fl10+median_vs_fl20+median_vs_fl30+median_vs_fl40+median_vs_fl50+median_vs_fl60+median_vs_fl70+median_vs_fl80+median_vs_fl90+median_vs_fl100+median_vs_fl110+median_vs_fl120+median_vs_fl130+median_vs_fl140+median_vs_fl150+median_vs_fl160+median_vs_fl170+median_vs_fl180+median_vs_fl190+median_vs_fl200+median_vs_fl210+median_vs_fl220+median_vs_fl230+median_vs_fl240+median_vs_fl250+median_vs_fl260+median_vs_fl270+median_vs_fl280+median_vs_fl290+median_vs_fl300+median_vs_fl310+median_vs_fl320+median_vs_fl330+median_vs_fl340+median_vs_fl360+median_vs_fl350+median_vs_fl0+median_vs_fl5
                    
                    +median_tas_fl10+median_tas_fl20+median_tas_fl30+median_tas_fl40+median_tas_fl50+median_tas_fl60+median_tas_fl70+median_tas_fl80+median_tas_fl90+median_tas_fl100+median_tas_fl110+median_tas_fl120+median_tas_fl130+median_tas_fl140+median_tas_fl150+median_tas_fl160+median_tas_fl170+median_tas_fl180+median_tas_fl190+median_tas_fl200+median_tas_fl210+median_tas_fl220+median_tas_fl230+median_tas_fl240+median_tas_fl250+median_tas_fl260+median_tas_fl270+median_tas_fl280+median_tas_fl290+median_tas_fl300+median_tas_fl310+median_tas_fl320+median_tas_fl330+median_tas_fl340+median_tas_fl360+median_tas_fl350+median_tas_fl0+median_tas_fl5
                    
                    +mean_temp_fl10+mean_temp_fl20+mean_temp_fl30+mean_temp_fl40+mean_temp_fl50+mean_temp_fl60+mean_temp_fl70+mean_temp_fl80+mean_temp_fl90+mean_temp_fl100+mean_temp_fl110+mean_temp_fl120+mean_temp_fl130+mean_temp_fl140+mean_temp_fl150+mean_temp_fl160+mean_temp_fl170+mean_temp_fl180+mean_temp_fl190+mean_temp_fl200+mean_temp_fl210+mean_temp_fl220+mean_temp_fl230+mean_temp_fl240+mean_temp_fl250+mean_temp_fl260+mean_temp_fl270+mean_temp_fl280+mean_temp_fl290+mean_temp_fl300+mean_temp_fl310+mean_temp_fl320+mean_temp_fl330+mean_temp_fl340+mean_temp_fl360+mean_temp_fl350+mean_temp_fl0+mean_temp_fl5
                    
                    +mean_sh_fl10+mean_sh_fl20+mean_sh_fl30+mean_sh_fl40+mean_sh_fl50+mean_sh_fl60+mean_sh_fl70+mean_sh_fl80+mean_sh_fl90+mean_sh_fl100+mean_sh_fl110+mean_sh_fl120+mean_sh_fl130+mean_sh_fl140+mean_sh_fl150+mean_sh_fl160+mean_sh_fl170+mean_sh_fl180+mean_sh_fl190+mean_sh_fl200+mean_sh_fl210+mean_sh_fl220+mean_sh_fl230+mean_sh_fl240+mean_sh_fl250+mean_sh_fl260+mean_sh_fl270+mean_sh_fl280+mean_sh_fl290+mean_sh_fl300+mean_sh_fl310+mean_sh_fl320+mean_sh_fl330+mean_sh_fl340+mean_sh_fl360+mean_sh_fl350+mean_sh_fl0+mean_sh_fl5
                    
                    +MTOW+empty_weight+mean_type_wt+sched_freq+month+doy+dow+adep_lumped+ades_lumped 
                    
                    +sqrt_auc + max_alt,
                    data=train)) %>%
  add_model(lgb_spec)

cv_folds <- vfold_cv(train, 
                     v = 2)

lgbm_res <- tune_grid(
  lgbm_wf,
  resamples = cv_folds,
  grid = 20,
  control = lgbm_ctrl,
  metrics = metric_set(rmse)
)

#See how that went
show_best(lgbm_res, metric = "rmse") 

best <- select_best(lgbm_res)

final_model <- finalize_workflow(
  lgbm_wf,
  best)

final_fit <- 
  final_model %>%
  fit(data = train)

preds <- predict(final_fit, test) %>% 
  bind_cols(test)

#Examine results
preds %>% 
  #group_by(aircraft_type) %>%
  rmse(.pred, tow)# %>% view()

preds %>% 
  group_by(airline) %>%
  rmse(.pred, tow) %>% view()

preds %>%
  mutate(difference = abs(tow-.pred)) %>%
  select(tow, 1:24, difference) %>%
  view()

preds %>%
  mutate(difference = abs(tow-.pred)) %>%
  ggplot()+
  geom_density(aes(difference, fill=wtc), alpha=0.4)+
  theme_bw()

preds %>%
  ggplot()+
  geom_density(aes(tow, fill=wtc), alpha=0.4)+
  theme_bw()+
  facet_wrap(~aircraft_type)

preds %>% 
  ggplot(aes(x=.pred, y = tow))+
  geom_point(alpha=0.1)+
  #coord_obs_pred()+
  theme_bw()+
  geom_abline()+
  facet_wrap(~aircraft_type, scales = 'free')

preds %>% 
  ggplot(aes(x=.pred, y = tow))+
  geom_point(alpha=0.1)+
  #coord_obs_pred()+
  theme_bw()+
  geom_abline()+
  facet_wrap(~airline, scales = 'free')

#export model
export_fit <- 
  final_model %>%
  fit(data = data_cleaned)

bundled_mod <- bundle(export_fit)

library(butcher)

butcher(export_fit) %>% 
  bundle() %>%
  write_rds('butchered_final_lgbm.rds')
