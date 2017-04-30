ruby './main.rb'

Email-ids ~ Heroku Config Vars

TO DO:
cronjob for *get_data({:offline=>false})*
mailling for *get_data({:offline=>false})*
-----
fix the ugly (this_month+1).times do |month_i| thing which
looks at each month since the beginning of the year
just save this data and rewrite for querying latest month only
-------
Drive-upload for *get_data({:offline=>true})*
so that can be cross-referenced with payments owed

make master online on Drive, that updates automatically once/week