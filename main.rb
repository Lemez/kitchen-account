@@heroku = false
require_relative('./script.rb')

# @global_data = get_data({:offline=>false})
@latest_data,@balance = get_data({:latest=>true})
mail(@latest_data, @balance)

# write_summary_data(@global_data)
# write_annual_data(@global_data)