$heroku = false
require_relative('./script.rb')

@latest_data,@balance = get_data({:latest=>true})
p "#{@latest_data}, Balance: #{@balance}"

# options={:test_mail=>true} send to a test mail ID, not to production mail id
mail(@latest_data, @balance, options={:test_mail=>true})

# @global_data,dummy = get_data({:offline=>false})
# write_summary_data(@global_data)
# write_annual_data(@global_data)