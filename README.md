# 2019 Australian Open Datathon 
## Aim
This repo aims to educate participants of the Betfair Australian Open Datathon on creating an end-to-end model to use in the competition. Whilst some experience is required, we are confident that you will be able to work through the examples with basic/intermediate R or Python experience.

## The Task
This repo will outline how the Betfair Data Scientists went about modelling the Australian Open for Betfair's Australian Open Datathon. The task is simple: we ask you to predict the winner of every possible Australian Open matchup using data which we provide.

The metric used to determine the winner will be log loss, based on the actual matchups that happen in the Open. For more information on log loss, click [here](http://wiki.fast.ai/index.php/Log_Loss).

For a detailed outline of the task, the prizes, and to sign up, click [here](https://www.betfair.com.au/hub/australian-open-datathon/).

For an outline of our methodology and thought process, read [this](https://www.betfair.com.au/hub/betfairs-aus-open-datathon-how-to-build-a-model/) article.

## Tutorials
The follow tutorials will walk you through the full process from exploring the data, to creating features, to finally modelling the problem. The tutorials are written in both R and Python
* [R Machine Learning Walkthrough - R Script](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-machine-learning-script.R)
* [R Machine Learning Walkthrough - R-Markdown. Note that this does not render in Github](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-machine-learning-walkthrough.Rmd)
* [R Machine Learning Walkthrough - HTML file. Note that this does not render in Github](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-machine-learning-walkthrough.html)
* [R Machine Learning Walkthrough - IPython Notebook - this does render in Github](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-machine-learning-walkthrough.ipynb)
* [Python Machine Learning Walkthrough - IPython Notebook](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/python-machine-learning-walkthrough.ipynb)
* [Python Machine Learning Walkthrough - HTML file. Note that this does not render in Github](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/python-machine-learning-walkthrough.html)
* [R Monte Carlo Walkthrough - R Script](https://github.com/betfair-datascientists/aus-open-datathon/blob/master/R-monte-carlo-walkthrough.R)

## Sample Predictions
Our average predictions (grouped by player) are below. Note that this is not the format to submit your predictions in.
```R
aus_open_2019_features %>% 
  select(player_1, starts_with("F_"), prob_player_1) %>%
  group_by(player_1) %>%
  summarise_all(mean) %>%
  arrange(desc(prob_player_1))
```
|player_1|F_Serve_Win_Ratio_Diff|F_Return_Win_Ratio_Diff|F_Game_Win_Percentage_Diff|F_BreakPoints_Per_Game_Diff|F_Rank_Diff|player_1_win_probability|
|-|-|-|-|-|-|-|
|Novak Djokovic|0.10632023|0.05928945|0.12587775|0.109932037|-63.33858|0.8589674|
|Karen Khachanov|0.10054146|0.06688368|0.11350589|0.056474608|-54.45669|0.8558480|
|Juan Martin del Potro|0.09863615|0.04637817|0.09084452|0.066516476|-60.70866|0.8489047|
|Rafael Nadal|0.04535057|0.05583578|0.08438023|0.089342971|-63.45669|0.8291386|
|Roger Federer|0.04840111|0.03345547|0.06099534|0.003240197|-61.58268|0.8117824|
|Kei Nishikori|0.05230278|0.02686089|0.06877195|0.003942023|-56.27559|0.8070875|

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
