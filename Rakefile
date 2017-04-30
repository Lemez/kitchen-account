namespace :mail do 
	desc "This sending mail task is called by the Heroku scheduler add-on"

	task default: %w[send_mail]

	task :test do
	  ruby "test/unittest.rb"
	end
	
	task :send_mail => :environment do
 		puts "Weekly mail check"

 		day_of_the_week = Date.today.cwday

  		if day_of_the_week == 7 #it's a Sunday
  			puts "Sunday..."
  			ruby -r "./main.rb" -e "get_latest_and_mail_it"
  		else 
  			puts "It's not yet Sunday"
  		end
  		
	end
end