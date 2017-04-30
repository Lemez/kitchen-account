namespace :mail do 
	desc "This sending mail task is called by the Heroku scheduler add-on"
	task :send_mail => :environment do
 		puts "Weekly mail check"

 		day_of_the_week = Date.today.cwday

  		if day_of_the_week == 7 #it's a Sunday
  			puts "Sunday..."
  			send_mail
 
  		else 
  			puts "It's not yet Sunday"
  		end
  		
	end

	def send_mail
		@latest_data,@balance = get_data({:latest=>true})
		mail(@latest_data, options={:balance=>@balance})
	end
end