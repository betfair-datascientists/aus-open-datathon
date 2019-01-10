# 2019 Australian Open Datathon 
## Aim
This repo aims to educate participants of the Betfair Australian Open Datathon on creating an end-to-end model to use in the competition. Whilst some experience is required, we are confident that you will be able to work through the examples with basic/intermediate R or Python experience.

## The Task
This repo will outline how the Betfair Data Scientists went about modelling the Australian Open for Betfair's Australian Open Datathon. The task is simple: we ask you to predict the winner of every possible Australian Open matchup using data which we provide.

The metric used to determine the winner will be log loss, based on the actual matchups that happen in the Open. For more information on log loss, click [here](http://wiki.fast.ai/index.php/Log_Loss).

For a detailed outline of the task, the prizes, and to sign up, click [here](https://www.betfair.com.au/hub/australian-open-datathon/).

For an outline of our methodoly and thought process, read [this](https://www.betfair.com.au/hub/betfairs-aus-open-datathon-how-to-build-a-model/) article.

## Prizes
|Place|Prize|Place|Prize|
|-|-|-|-|
|1|$5000|9|$500|
|2|$3000|10|$500|
|3|$2000|11|$200|
|4|$1000|12|$200|
|5|$750|13|$200|
|6|$500|14|$200|
|7|$500|15|$200|
|8|$500|Total|$15250|

## Submission
* To submit your model, email your final submission to datathon@betfair.com.au. Note that you don't need to email your code, just your predictions in the format that we have specified
* No submissions will be accepted prior to the Australian Open qualifying matches being completed and the final draw list being shared with registered participants (12 January 2019)
* Submissions need to include all potential match ups during the Australian Open, i.e. all possible combinations for each men's and women's tournaments (this will be provided after the draw is announced and the Australian Open qualifying matches are completed (Jan 12th 2019))
* Submissions must follow the format outlined above and shown in the 'Dummy Submission File'. Any submissions that are not in the correct format will not be accepted.
* Submissions need to include the player names for the hypothetical match up and the probability of the first player winning
i.e. player_1,player_2,probability_of_player_1_winning,
* Submissions must be in a csv format
* Only two models will be accepted per participant (one model for the men's draw, one model for the women's draw)

## Tutorials
The follow tutorials will walk you through the full process from exploring the data, to creating features, to finally modelling the problem. The tutorials are written in both R and Python
* [R Machine Learning Walkthrough - R Script](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-machine-learning-script.R)
* [R Machine Learning Walkthrough - R-Markdown. Note that this does not render in Github](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-machine-learning-walkthrough.Rmd)
* [R Machine Learning Walkthrough - HTML file. Note that this does not render in Github](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-machine-learning-walkthrough.html)
* [R Machine Learning Walkthrough - IPython Notebook - this does render in Github](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-machine-learning-walkthrough.ipynb)
* [Python Machine Learning Walkthrough - IPython Notebook](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/python-machine-learning-walkthrough.ipynb)
* [Python Machine Learning Walkthrough - HTML file. Note that this does not render in Github](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/python-machine-learning-walkthrough.html)

## Sample Predictions
Our average predictions (grouped by player) are below. Note that this is not the format to submit your predictions in.
```R
aus_open_2019_features %>% 
  select(player_1, starts_with("F_"), prob_player_1) %>%
  group_by(player_1) %>%
  summarise_all(mean) %>%
  arrange(desc(prob_player_1))
```
|player_1|F_Serve_Win_Ratio_Diff|F_Return_Win_Ratio_Diff|F_Game_Win_Percentage_Diff|F_BreakPoints_Per_Game_Diff|prob_player_1|
|-|-|-|-|-|-|
|Novak Djokovic|0.1109364627|0.076150615|0.1483970690|0.17144300|0.8616486|
|Karen Khachanov|0.0960639298|0.061436164|0.1059967623|0.04544955|0.8339594|
|Juan Martin del Potro|0.1003931993|0.042025222|0.0847985439|0.05943767|0.8218308|
|Rafael Nadal|0.0480432305|0.051531252|0.0790179917|0.08181694|0.8032543|
|Gilles Simon|0.0646937767|0.084843307|0.0901401318|0.08675350|0.7985995|
|Roger Federer|0.0452014997|0.040992497|0.0725719954|0.01817046|0.7962289|



## Requirements
There are a few requirements to run the notebook walkthroughs through the interactive tutorials on your local computer. 

If you are happy to read through the Python tutorials on Github, but not run the code yourself, you simply need to click the tutorial links and the tutorial can be viewed in your browser. However, if you are keen to be able to run the code yourself and try different things out, you will need to install the following:
* Python 
* Jupyter Notebook (Installed through the Anaconda Distribution)

If you don't already have Python installed, we advise you to install it through [Anaconda](https://www.anaconda.com/download/). This also installs Jupyter and is super convenient.

Alternatively, if you use R, you will need to install the following:
* R
* R Studio

## Disclaimer
Note that whilst predictions are fun and rewarding to create, we can't promise that your betting strategy will be profitable. If implementing your own strategies please gamble responsibly and note that you are responsible for any winnings/losses incurred.
