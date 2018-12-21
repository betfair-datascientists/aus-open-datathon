# 2019 Australian Open Datathon 
## Aim
This repo aims to educate participants of the Betfair Australian Open Datathon on creating an end-to-end model to use in the competition. Whilst some experience is required, we are confident that you will be able to work through the examples with basic/intermediate R or Python experience.

## The Task
This repo will outline how the Betfair Data Scientists went about modelling the Australian Open for Betfair's Australian Open Datathon. The task is simple: we ask you to predict the winner of every possible Australian Open matchup using data which we provide.

The metric used to determine the winner will be log loss, based on the actual matchups that happen in the Open. For more information on log loss, click [here](http://wiki.fast.ai/index.php/Log_Loss).

For a detailed outline of the task, the prizes, and to sign up, click [here](https://www.betfair.com.au/hub/australian-open-datathon/).

How an outline of our methodoly and thought process, read [this](https://www.betfair.com.au/hub/betfairs-aus-open-datathon-how-to-build-a-model/) article.

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
* (R Walkthrough - HTML file. Note that this does not render in Github)[https://github.com/betfair-datascientists/aus-open-datathon/blob/master/aus-open-model-R.html]
* (R Walkthrough - Notebook. Note that this does not render in Github)[https://github.com/betfair-datascientists/aus-open-datathon/blob/master/aus-open-model-R.Rmd]
* (R Walkthrough - R Script)[https://github.com/betfair-datascientists/aus-open-datathon/blob/master/aus-open-model-script.R]
* (Python Walkthrough - Notebook)[https://github.com/betfair-datascientists/aus-open-datathon/blob/master/Betfair%20Data%20Scientists'%20Australian%20Open%20Model.ipynb]

## Sample Predictions
Our average predictions (grouped by player) are below. Note that this is not the format to submit your predictions in.

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
