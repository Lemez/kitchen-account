namespace :mail do 
	desc "This task is called by the Heroku scheduler add-on"
	task :send_mail => :environment do
 		puts "Sending mail..."
  		send_mail
  		puts "done."
	end

	def send_mail
		@latest_data,@balance = get_data({:latest=>true})
		mail(@latest_data, options={:balance=>@balance})
	end
end