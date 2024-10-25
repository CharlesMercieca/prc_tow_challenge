## Data
Contains all of the data used to train the final model. A truncated 500 row version of each set is provided just to give an intuiton of what it looks like.

### `makedata.r`
R script that unifies the different sources and does some light feature engineering and merging. Creates `data_cleaned.csv`

### ADEP & ADES lumped
Are basically the output of the R `forcats::fct_lump()` function, with an n of 150: that is the top 150 ICAO codes get maintained, while the rest are 'Other'. They are stored to convert the prediction set in case frequency differs from train. This was a tradeoff between LightGBM's ability to handle categorical features effectively, but not to have too many levels in a single factor.

### Aircraft Type
Additional aircraft type info like MTOW and empty weight. The idea of this dataset was to allow for pooling: wake turbulence category was too broad, and the aircraft type code was too broad. This feature was intended to let the model know that a sparsely seen aircraft type e.g. a 757 is somewhere between an A321 and a 767. 

### AUC feature, climb_features_processed and climb_table_features
Datasets extracted from the trajectories as detailed in the `features_from_trajectories` directory.

### Data Cleaned
The final result of running `makedata.r`, and what is fed to the model.