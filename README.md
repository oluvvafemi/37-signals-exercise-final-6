# README

## An app to analyze web pages

This exercise is about building a Rails application that analyzes web pages. Users will enter 
URLs, and the app will display:

* The page title.
* Total word count.
* Top 10 most frequent words with their count.
* The Table of Contents.

The application should keep a history of the analyzed pages and let you browse it.

We have prepared two HTML mockups with the interface to implement:

- The main screen that lists analyzed pages and let you enter new ones.
- The screen that shows the analysis results for a given page.

To view the mockups you can build the project and start the dev server with:

```
bin/setup
bin/dev
```

Then you can go to http://localhost:3000/mockups.

## Here's what you need to do

* Clone this repo and get it running. This is a fresh Rails 8 app.
* Run `bin/setup` to install dependencies.
* Start the dev server with bin/dev and visit http://localhost:3000/mockups to see the two mockups.
* Implement the app based on those mockups.
* Submit your solution by opening a pull request in this repo.

## Notes

* In your pull request, tell us about your decisions. We’re interested in your thought process and communication skills—not just your code.
* The root page of the app should be the main one that lists the pages.
* It is OK to store the HTML of the pages in the database and run the analysis on-the-fly when viewing them.
* You can use Nokogiri to analyze the HTML. It's already included in Rails.
* There is no need to expand the scope. E.g: adding authentication or reworking the simple CSS.
* The numbers in the mockup are just examples. Your output doesn’t need to match them exactly.
