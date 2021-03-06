require 'net/smtp'
require 'mail'

if $heroku 

	$mail_options = { :address              => 'smtp.sendgrid.net',
            :port                 => 587,
            :domain               => 'auroville.org.in',
            :user_name            => $user,
            :password             => $pass,
            :authentication       => 'plain',
            :enable_starttls_auto => true  }

else
	require_relative('./secret.rb')

	$mail_options = { :address              => "smtp.gmail.com",
            :port                 => 587,
            :domain               => 'auroville.org.in',     
            :user_name            => USER,
            :password             => PASS,
            :authentication       => 'plain',
            :enable_starttls_auto => true  }
            

end



Mail.defaults do
  delivery_method :smtp, $mail_options
end

def mail(data,balance,options={:test_mail=>nil})

	formatted_data = format_data_to_html(data,balance)
	p formatted_data

	deliver_mail(formatted_data,options)
end

def format_data_to_html(data,balance=nil)

	# {"S.NO"=>"14348", "TYPE"=>"MT", "DATE"=>"01-02-2017", "ACCOUNT"=>"0373K - PT PURCHASING SERVICE", "DESCRIPTION"=>"MT 01/02/17 - BN:4 - 2017-02-1", "DEBIT"=>"-493.71", "CREDIT"=>""}
	not_necessary = ["S.NO", "TYPE"]
	headings = data[0].keys.reject{|a| not_necessary.include?(a) || a.empty?}

	html = '<table style="border-collapse:collapse;"><tbody><th><tr style="border-bottom: 1px solid #000;font-weight: 700;"><td>'+ headings.join("</td><td>") + '</td></tr></th>'

	# dates = data.reject{|line|(Date.today - 7) < Date.parse(line["DATE"]) }

	data.each_with_index do |line,i|
		i%2==0 ? rowclass='style="background-color:#FAFAD2;"' : rowclass='style="background-color:#fff;"' 
		html += '<tr ' + rowclass + '>'  
		html += "<td>" + line.values[2..-1].join("</td><td>") + "</td>"
		html += '</tr>' 
	end
	if balance

		balance_amount = balance.values.flatten.map(&:to_i).reduce(&:+)

		if balance_amount >= 0
			spaces = '</td><td>' * 4
		else
			spaces = '</td><td>' * 3
		end
			
		html += '<tr style="border: 1px solid #000;font-weight: 700;">'
			html += "<td>" 
			html += "Current balance" 
				html += spaces 
			html += balance_amount.to_s 
			html += "</td>"
		html += '</tr>'

	end

	html += '</tbody></table>'
	html
end

def deliver_mail (data,options)
	
	to_address = ( options[:test_mail] ? $my_mail : $d_mail)
	p "Delivering to #{to_address}"

	Mail.deliver do
       	to "#{to_address}"
     	from 'Kitchen Account Bot <jonathan@auroville.org.in>'
  		subject 'Kitchen account update: ' + Date.today.to_s
     	
     	text_part do
		    body 'Latest account update:'
		end

	  	html_part do
	    	content_type 'text/html; charset=UTF-8'
	    	body data
  		end
 	end
end

