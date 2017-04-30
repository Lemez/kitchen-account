$heroku = false
require_relative('./script.rb')

@latest_data,@balance = get_data({:latest=>true})
p "#{@latest_data}, Balance: #{@balance}"
# mail(@latest_data, @balance)

# @global_data,dummy = get_data({:offline=>false})
# write_summary_data(@global_data)
# write_annual_data(@global_data)